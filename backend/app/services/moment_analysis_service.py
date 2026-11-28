"""AI 分析用户故事内容，自动打一级/二级标签与情绪。"""

from __future__ import annotations

import asyncio
import json
import re
from dataclasses import dataclass

from loguru import logger

from app.core.config import settings
from app.exceptions.business import BusinessException
from app.models.growth_tag import GrowthTagCategory
from app.rag.qwen_provider import QwenLLMProvider
from app.schemas.growth_tag import MomentAnalysisResult

AI_CALL_TIMEOUT_SEC = 12.0

AI_EMOTION_TO_LEGACY = {
    "开心": "happy",
    "兴奋": "happy",
    "满足": "happy",
    "感动": "happy",
    "平静": "calm",
    "焦虑": "thinking",
    "压力": "thinking",
    "思考": "thinking",
    "失落": "sad",
    "难过": "sad",
    "愤怒": "angry",
    "生气": "angry",
    "自我觉察": "thinking",
    "身体关怀": "calm",
}

PRIMARY_TAG_SCENE = {
    "工作": "study",
    "学习": "study",
    "健康": "sport",
    "人际": "friendship",
    "生活": "family",
    "创作": "hobby",
    "财务": "stargaze",
    "成就": "stargaze",
    "情绪": "stargaze",
    "灵感": "stargaze",
    "特殊事件": "stargaze",
}

# 用户口语和岛屿展示名。模型常把这些词原样写进 primary_tag，种子标签里没有。
PRIMARY_LABEL_ALIASES: dict[str, tuple[str, ...]] = {
    "财务": ("财富", "理财"),
    "学习": ("学业",),
    "情绪": ("情感",),
    "特殊事件": ("重要事件",),
    "创作": ("创造",),
}

ANALYSIS_PROMPT = """你是成长记录平台的分类助手。根据用户今天写下的一段故事，自动分类并提取成长关键词。
只输出 JSON，不要 Markdown。字段：
- primary_tag: 一级标签（必须从给定列表中选一个）
- secondary_tags: 二级标签数组（1~3 个，必须从对应二级列表中选择）
- emotion: 用户此刻主要情绪（中文，如 满足、焦虑、开心）
- growth_points: 成长关键词数组（1~3 个，如 坚持、执行力、沟通）

说法对照：财富、理财归入财务；学业归入学习；情感归入情绪；重要事件归入特殊事件；创造归入创作。
正文明显在说某一类时，不要因为拿不准就选「生活」。

一级与二级标签列表：
{tag_catalog}

用户故事：
{note}
"""


@dataclass
class _TagCatalog:
    primary_labels: set[str]
    secondary_by_primary: dict[str, set[str]]
    label_to_category_id: dict[str, str]


class MomentAnalysisService:
    def __init__(self, llm: QwenLLMProvider | None = None):
        self._llm = llm

    def _llm_client(self) -> QwenLLMProvider:
        if self._llm is None:
            self._llm = QwenLLMProvider()
        return self._llm

    def build_catalog(self, categories: list[GrowthTagCategory]) -> _TagCatalog:
        primary_labels: set[str] = set()
        secondary_by_primary: dict[str, set[str]] = {}
        label_to_category_id: dict[str, str] = {}
        for category in categories:
            if not category.is_active:
                continue
            primary_labels.add(category.label)
            label_to_category_id[category.label] = category.id
            secondary_by_primary[category.label] = {
                tag.label for tag in category.tags if tag.is_active
            }
        return _TagCatalog(primary_labels, secondary_by_primary, label_to_category_id)

    async def analyze(
        self, note: str, categories: list[GrowthTagCategory]
    ) -> MomentAnalysisResult:
        catalog = self.build_catalog(categories)
        cleaned = (note or "").strip()
        if not cleaned:
            return self._align_with_note(
                self._fallback("生活", catalog, emotion="平静"),
                cleaned,
                catalog,
            )

        prompt = ANALYSIS_PROMPT.format(
            tag_catalog=self._format_catalog(catalog),
            note=cleaned[:500],
        )
        try:
            raw = await asyncio.wait_for(
                self._llm_client().generate(
                    prompt,
                    model=settings.QWEN_FAST_MODEL,
                    temperature=0.15,
                    max_tokens=512,
                    response_format={"type": "json_object"},
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            data = self._parse_json(raw)
            return self._align_with_note(self._normalize(data, catalog), cleaned, catalog)
        except TimeoutError as exc:
            logger.warning(
                "moment analysis AI timeout after {}s",
                AI_CALL_TIMEOUT_SEC,
            )
            raise BusinessException("故事分析超时，请稍后重试", 504) from exc
        except json.JSONDecodeError:
            logger.warning(
                "moment analysis returned invalid JSON: {}",
                (raw[:400] if "raw" in locals() else ""),
            )
            return self._align_with_note(self._fallback("生活", catalog), cleaned, catalog)
        except BusinessException as exc:
            logger.opt(exception=exc).warning(
                "moment analysis AI failed type={} code={} message={} raw={}",
                type(exc).__name__,
                exc.code,
                exc.message,
                (raw[:400] if "raw" in locals() else ""),
            )
            return self._align_with_note(self._fallback("生活", catalog), cleaned, catalog)
        except Exception as exc:
            logger.opt(exception=exc).warning(
                "moment analysis AI failed type={} repr={} raw={}",
                type(exc).__name__,
                repr(exc),
                (raw[:400] if "raw" in locals() else ""),
            )
            return self._align_with_note(self._fallback("生活", catalog), cleaned, catalog)

    def _format_catalog(self, catalog: _TagCatalog) -> str:
        lines: list[str] = []
        for primary in sorted(catalog.primary_labels):
            secondaries = sorted(catalog.secondary_by_primary.get(primary, set()))
            lines.append(f"- {primary}: {', '.join(secondaries)}")
        return "\n".join(lines)

    def _parse_json(self, raw: str) -> dict:
        text = (raw or "").strip()
        if text.startswith("```"):
            text = re.sub(r"^```(?:json)?\s*", "", text)
            text = re.sub(r"\s*```$", "", text)
        blob = self._first_json_object(text)
        if blob is None:
            raise json.JSONDecodeError("No JSON object found", text, 0)
        blob = re.sub(r",\s*([}\]])", r"\1", blob)
        return json.loads(blob)

    @staticmethod
    def _first_json_object(text: str) -> str | None:
        start = text.find("{")
        if start < 0:
            return None
        depth = 0
        in_string = False
        escape = False
        for index in range(start, len(text)):
            char = text[index]
            if in_string:
                if escape:
                    escape = False
                elif char == "\\":
                    escape = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    return text[start : index + 1]
        return None

    def _canonicalize_primary(self, raw: str, catalog: _TagCatalog) -> str | None:
        text = (raw or "").strip()
        if text in catalog.primary_labels:
            return text
        for label, aliases in PRIMARY_LABEL_ALIASES.items():
            if label not in catalog.primary_labels:
                continue
            if text in aliases:
                return label
        return None

    def _keyword_score(
        self, note: str, label: str, catalog: _TagCatalog
    ) -> tuple[int, int]:
        strong_words = [label, *PRIMARY_LABEL_ALIASES.get(label, ())]
        strong = sum(note.count(word) for word in strong_words if len(word) >= 2)
        weak = 0
        for word in catalog.secondary_by_primary.get(label, set()):
            if len(word) < 2 or word in strong_words:
                continue
            weak += note.count(word)
        return strong, weak

    def _best_keyword(
        self, note: str, catalog: _TagCatalog
    ) -> tuple[str | None, int, int]:
        best_label: str | None = None
        best_score = (0, 0)
        tied = False
        for label in catalog.primary_labels:
            score = self._keyword_score(note, label, catalog)
            if score == (0, 0):
                continue
            if best_label is None or score > best_score:
                best_label = label
                best_score = score
                tied = False
            elif score == best_score:
                tied = True
        if tied or best_label is None:
            return None, 0, 0
        return best_label, best_score[0], best_score[1]

    def _align_with_note(
        self,
        result: MomentAnalysisResult,
        note: str,
        catalog: _TagCatalog,
    ) -> MomentAnalysisResult:
        """正文里的类别说法优先于「生活」兜底，避免财富这类记录掉进主岛。"""
        primary = self._canonicalize_primary(result.primary_tag, catalog) or result.primary_tag
        if primary not in catalog.primary_labels:
            primary = "生活" if "生活" in catalog.primary_labels else primary
        hinted, strong, _weak = self._best_keyword(note, catalog)
        if hinted and hinted in catalog.primary_labels and hinted != primary:
            model_strong, _model_weak = self._keyword_score(note, primary, catalog)
            repeated_name = strong >= 2 and strong > model_strong
            generic_miss = primary == "生活" and hinted != "生活"
            if repeated_name or generic_miss:
                primary = hinted
        if primary == result.primary_tag:
            return result
        return self._retarget_primary(result, primary, note, catalog)

    def _retarget_primary(
        self,
        result: MomentAnalysisResult,
        primary: str,
        note: str,
        catalog: _TagCatalog,
    ) -> MomentAnalysisResult:
        allowed = catalog.secondary_by_primary.get(primary, set())
        secondary = [label for label in result.secondary_tags if label in allowed]
        for label in sorted(allowed):
            if label in note and label not in secondary:
                secondary.append(label)
        if not secondary and allowed:
            secondary.append(sorted(allowed)[0])
        growth_points = [
            label
            for label in result.growth_points
            if label in allowed and label not in secondary
        ]
        return result.model_copy(
            update={
                "primary_tag": primary,
                "secondary_tags": secondary[:3],
                "growth_points": growth_points[:3],
            }
        )

    def _normalize(self, data: dict, catalog: _TagCatalog) -> MomentAnalysisResult:
        raw_primary = str(data.get("primary_tag") or "").strip()
        primary = self._canonicalize_primary(raw_primary, catalog) or raw_primary
        if primary not in catalog.primary_labels:
            primary = "生活" if "生活" in catalog.primary_labels else next(
                iter(sorted(catalog.primary_labels)), "生活"
            )

        allowed = catalog.secondary_by_primary.get(primary, set())
        secondary: list[str] = []
        for item in data.get("secondary_tags") or []:
            label = str(item).strip()
            if label in allowed and label not in secondary:
                secondary.append(label)
        if not secondary and allowed:
            secondary.append(sorted(allowed)[0])

        emotion = str(data.get("emotion") or "平静").strip() or "平静"
        growth_points = self._sanitize_growth_points(
            [
                str(x).strip()
                for x in (data.get("growth_points") or [])
                if str(x).strip()
            ],
            catalog,
            primary=primary,
            exclude=secondary,
        )

        legacy = AI_EMOTION_TO_LEGACY.get(emotion, "calm")
        return MomentAnalysisResult(
            primary_tag=primary,
            secondary_tags=secondary,
            emotion=emotion,
            growth_points=growth_points,
            legacy_emotion_tag=legacy,
        )

    def _fallback(
        self, primary: str, catalog: _TagCatalog, *, emotion: str = "平静"
    ) -> MomentAnalysisResult:
        allowed = catalog.secondary_by_primary.get(primary, set())
        secondary = [sorted(allowed)[0]] if allowed else []
        return MomentAnalysisResult(
            primary_tag=primary if primary in catalog.primary_labels else "生活",
            secondary_tags=secondary,
            emotion=emotion,
            growth_points=[],
            legacy_emotion_tag=AI_EMOTION_TO_LEGACY.get(emotion, "calm"),
        )

    def _sanitize_growth_points(
        self,
        points: list[str],
        catalog: _TagCatalog,
        *,
        primary: str,
        exclude: list[str],
    ) -> list[str]:
        all_secondary: set[str] = set()
        for secs in catalog.secondary_by_primary.values():
            all_secondary.update(secs)
        cleaned: list[str] = []
        blocked = set(exclude)
        for label in points:
            if label in blocked or label not in all_secondary:
                continue
            if label not in cleaned:
                cleaned.append(label)
            if len(cleaned) >= 3:
                break
        return cleaned

    @staticmethod
    def build_event_tags(analysis: MomentAnalysisResult) -> list[str]:
        tags = [analysis.primary_tag, *analysis.secondary_tags]
        return tags[:8]

    @staticmethod
    def scene_for_primary(primary_tag: str) -> str:
        return PRIMARY_TAG_SCENE.get(primary_tag, "stargaze")
