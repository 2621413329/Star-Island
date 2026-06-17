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

AI_CALL_TIMEOUT_SEC = 6.0

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

ANALYSIS_PROMPT = """你是成长记录平台的分类助手。根据用户今天写下的一段故事，自动分类并提取成长关键词。
只输出 JSON，不要 Markdown。字段：
- primary_tag: 一级标签（必须从给定列表中选一个）
- secondary_tags: 二级标签数组（1~3 个，必须从对应二级列表中选择）
- emotion: 用户此刻主要情绪（中文，如 满足、焦虑、开心）
- growth_points: 成长关键词数组（1~3 个，如 坚持、执行力、沟通）

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
            return self._fallback("生活", catalog, emotion="平静")

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
                    max_tokens=280,
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            data = self._parse_json(raw)
            return self._normalize(data, catalog)
        except TimeoutError as exc:
            logger.warning(
                "moment analysis AI timeout after {}s",
                AI_CALL_TIMEOUT_SEC,
            )
            raise BusinessException("故事分析超时，请稍后重试", 504) from exc
        except json.JSONDecodeError as exc:
            logger.warning("moment analysis returned invalid JSON")
            raise BusinessException("故事分析结果无效，请稍后重试", 502) from exc
        except BusinessException:
            raise
        except Exception as exc:
            logger.warning("moment analysis AI failed: {}", exc)
            raise BusinessException("故事分析失败，请稍后重试", 502) from exc

    def _format_catalog(self, catalog: _TagCatalog) -> str:
        lines: list[str] = []
        for primary in sorted(catalog.primary_labels):
            secondaries = sorted(catalog.secondary_by_primary.get(primary, set()))
            lines.append(f"- {primary}: {', '.join(secondaries)}")
        return "\n".join(lines)

    def _parse_json(self, raw: str) -> dict:
        text = raw.strip()
        if text.startswith("```"):
            text = re.sub(r"^```(?:json)?\s*", "", text)
            text = re.sub(r"\s*```$", "", text)
        match = re.search(r"\{[\s\S]*\}", text)
        if not match:
            raise json.JSONDecodeError("No JSON object found", text, 0)
        return json.loads(match.group())

    def _normalize(self, data: dict, catalog: _TagCatalog) -> MomentAnalysisResult:
        primary = str(data.get("primary_tag") or "").strip()
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
