"""AI 分析用户故事内容，自动打一级/二级标签与情绪。"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass

from loguru import logger

from app.models.growth_tag import GrowthTagCategory
from app.rag.qwen_provider import QwenLLMProvider
from app.schemas.growth_tag import MomentAnalysisResult

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
        self.llm = llm or QwenLLMProvider()

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
            note=cleaned[:800],
        )
        try:
            raw = await self.llm.generate(
                prompt,
                temperature=0.2,
                max_tokens=512,
            )
            data = self._parse_json(raw)
            return self._normalize(data, catalog)
        except Exception as exc:
            logger.warning("moment analysis AI failed: {}", exc)
            return self._rule_based(cleaned, catalog)

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
        return json.loads(text)

    def _normalize(self, data: dict, catalog: _TagCatalog) -> MomentAnalysisResult:
        primary = str(data.get("primary_tag") or "").strip()
        if primary not in catalog.primary_labels:
            primary = self._guess_primary(primary, catalog) or "生活"

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

    def _guess_primary(self, value: str, catalog: _TagCatalog) -> str | None:
        if value in catalog.primary_labels:
            return value
        for label in catalog.primary_labels:
            if label in value or value in label:
                return label
        return None

    def _rule_based(self, note: str, catalog: _TagCatalog) -> MomentAnalysisResult:
        rules: list[tuple[str, str, list[str]]] = [
            (r"工作|项目|上班|加班|面试|创业|职场|代码|开发|产品", "工作", ["项目推进"]),
            (r"学|读|课|考|研|英语|编程|备考", "学习", ["课程学习"]),
            (r"跑|健身|泳|睡|饮食|运动|锻炼", "健康", ["跑步"]),
            (r"朋友|同事|家人|聚会|恋爱|社交|沟通", "人际", ["社交"]),
            (r"旅行|美食|电影|游戏|购物|娱乐", "生活", ["日常"]),
            (r"写|画|摄影|剪辑|音乐|设计|创作", "创作", ["内容创作"]),
            (r"工资|理财|投资|消费|储蓄|奖金", "财务", ["消费"]),
            (r"完成|上线|获奖|目标|晋升|打卡", "成就", ["完成目标"]),
            (r"毕业|入职|离职|搬家|结婚|生日|转折", "特殊事件", ["人生转折"]),
            (r"想法|感悟|反思|规划|灵感|目标", "灵感", ["反思"]),
            (r"开心|焦虑|压力|感动|失落|愤怒|情绪", "情绪", ["平静"]),
        ]
        for pattern, primary, defaults in rules:
            if primary not in catalog.primary_labels:
                continue
            if re.search(pattern, note):
                allowed = catalog.secondary_by_primary.get(primary, set())
                secondary = [defaults[0]] if defaults[0] in allowed else (
                    [sorted(allowed)[0]] if allowed else []
                )
                emotion = "平静"
                if re.search(r"开心|高兴|满足|兴奋", note):
                    emotion = "开心"
                elif re.search(r"焦虑|压力|担心", note):
                    emotion = "焦虑"
                elif re.search(r"难过|失落|沮丧", note):
                    emotion = "失落"
                elif re.search(r"怒|气|烦", note):
                    emotion = "愤怒"
                return MomentAnalysisResult(
                    primary_tag=primary,
                    secondary_tags=secondary,
                    emotion=emotion,
                    growth_points=self._sanitize_growth_points(
                        self._infer_growth_points(note),
                        catalog,
                        primary=primary,
                        exclude=secondary,
                    ),
                    legacy_emotion_tag=AI_EMOTION_TO_LEGACY.get(emotion, "calm"),
                )
        return self._fallback("生活", catalog)

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
    def _infer_growth_points(note: str) -> list[str]:
        points: list[str] = []
        mapping = [
            (r"坚持|持续|打卡", "坚持"),
            (r"完成|搞定|上线", "执行力"),
            (r"沟通|交流|表达", "沟通"),
            (r"学习|掌握|进步", "成长"),
            (r"反思|总结|感悟", "反思力"),
        ]
        for pattern, label in mapping:
            if re.search(pattern, note) and label not in points:
                points.append(label)
        return points[:3]

    @staticmethod
    def build_event_tags(analysis: MomentAnalysisResult) -> list[str]:
        tags = [analysis.primary_tag, *analysis.secondary_tags]
        return tags[:8]

    @staticmethod
    def scene_for_primary(primary_tag: str) -> str:
        return PRIMARY_TAG_SCENE.get(primary_tag, "stargaze")
