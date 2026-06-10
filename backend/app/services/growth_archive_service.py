from __future__ import annotations

import uuid
from datetime import date, timedelta

from app.models.teacher_follow_up import TeacherFollowUp
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_follow_up_repository import TeacherFollowUpRepository
from app.services.growth_insight_service import ATTENTION_TAG_LABELS, GrowthInsightService
from app.services.growth_observation_analysis_service import GrowthObservationAnalysisService
from app.services.moment_story_service import format_moment_story_detail, moment_category_label

TREND_METRIC_LABEL = "情绪正向指数（越高表示积极情绪占比越高，范围 0–1）"


class GrowthArchiveService:
    def __init__(
        self,
        report_repo: DailyMoodReportRepository,
        moment_repo: DailyMomentRepository,
        profile_repo: ProfileRepository,
        student_repo: StudentRepository,
        follow_up_repo: TeacherFollowUpRepository,
    ):
        self.report_repo = report_repo
        self.moment_repo = moment_repo
        self.profile_repo = profile_repo
        self.student_repo = student_repo
        self.follow_up_repo = follow_up_repo
        self.insight_svc = GrowthInsightService()
        self.observation_svc = GrowthObservationAnalysisService(self.insight_svc)

    async def get_archive(
        self, student_id: uuid.UUID, *, class_name: str, days: int = 7
    ) -> dict:
        student = await self.student_repo.get_by_id(student_id)
        if not student or student.class_name != class_name:
            from app.exceptions.business import BusinessException

            raise BusinessException("学生不存在或不在本班", 404)

        since = date.today() - timedelta(days=max(days - 1, 0))
        reports = await self.report_repo.list_by_student_since(
            student_id, since, class_name=class_name
        )
        profile = await self.profile_repo.get_by_student_id(student_id)
        moments: list = []
        if profile:
            moments = await self.moment_repo.list_by_user_since(profile.user_id, since)

        insight = self._merge_insight(reports, moments)
        observation = await self.observation_svc.analyze_period_with_ai(
            reports,
            moments,
            anchor_date=date.today(),
            days=days,
            skip_ai=any(
                self.insight_svc.moment_note_is_critical(m, self.insight_svc.dismissed_ids(
                    next((r for r in reports if r.report_date == m.moment_date), None)
                ))
                for m in moments
            ),
        )
        ai_summary = self._archive_ai_summary(reports, moments)
        trend_points = self._trend_points(reports)
        mood_counts, category = self._aggregate_counts(reports)
        mood_counts_by_category = self._mood_counts_by_category(moments)
        attention_tags = self._attention_tag_counts(reports, moments)
        daily_records = self._build_daily_records(moments, reports)
        timeline = self._build_timeline(moments, reports)
        risk_exposures = self._risk_exposures(moments, reports)
        follow_ups = [
            {
                "id": item.id,
                "action": item.action,
                "note": item.note,
                "created_at": item.created_at,
            }
            for item in await self.follow_up_repo.list_by_student(student_id)
        ]

        return {
            "student_id": student_id,
            "student_name": student.name,
            "class_name": student.class_name,
            "ai_summary": ai_summary,
            "insight": insight,
            "observation": observation,
            "trend_metric_label": TREND_METRIC_LABEL,
            "trend_points": trend_points,
            "mood_counts": mood_counts,
            "category_breakdown": category,
            "mood_counts_by_category": mood_counts_by_category,
            "attention_tags": attention_tags,
            "daily_records": daily_records,
            "timeline": timeline,
            "risk_exposures": risk_exposures,
            "follow_ups": follow_ups,
        }

    async def add_follow_up(
        self,
        student_id: uuid.UUID,
        teacher_id: uuid.UUID,
        *,
        class_name: str,
        action: str,
        note: str | None,
    ) -> dict:
        student = await self.student_repo.get_by_id(student_id)
        if not student or student.class_name != class_name:
            from app.exceptions.business import BusinessException

            raise BusinessException("学生不存在或不在本班", 404)
        record = await self.follow_up_repo.create(
            TeacherFollowUp(
                student_id=student_id,
                teacher_id=teacher_id,
                action=action,
                note=note,
            )
        )
        return {
            "id": record.id,
            "action": record.action,
            "note": record.note,
            "created_at": record.created_at,
        }

    def _merge_insight(self, reports, moments) -> dict:
        if reports:
            latest = reports[0]
            day_moments = [m for m in moments if m.moment_date == latest.report_date]
            return self.insight_svc.resolve_for_report(latest, day_moments)
        return self.insight_svc.build_from_moments(moments)

    def _archive_ai_summary(self, reports, moments) -> str:
        summaries = []
        for r in reports[:7]:
            ins = self.insight_svc.from_stored(r)
            if ins and ins.get("summary"):
                summaries.append(str(ins["summary"]))
        if summaries:
            return summaries[0] if len(summaries) == 1 else "；".join(dict.fromkeys(summaries))[:200]
        return self.insight_svc.build_archive_summary(reports, moments)

    def _trend_points(self, reports) -> list[dict]:
        points = []
        for r in sorted(reports, key=lambda x: x.report_date):
            total = sum((r.mood_counts or {}).values()) or 1
            neg = (r.mood_counts or {}).get("sad", 0) + (r.mood_counts or {}).get("angry", 0)
            score = round(1.0 - neg / total, 2)
            points.append(
                {
                    "date": r.report_date.isoformat(),
                    "mood_score": score,
                    "record_count": r.moment_count,
                }
            )
        return points

    def _mood_counts_from_moments(self, moments, category_id: str | None) -> dict[str, int]:
        mood: dict[str, int] = {}
        for m in moments:
            tag = m.event_tags[0] if m.event_tags else "其它"
            if category_id and tag != category_id:
                continue
            mood[m.emotion_tag] = mood.get(m.emotion_tag, 0) + 1
        return mood

    def _mood_counts_by_category(self, moments) -> dict[str, dict[str, int]]:
        keys = ["all", "学习", "朋友", "运动", "家庭", "兴趣", "其它"]
        return {k: self._mood_counts_from_moments(moments, None if k == "all" else k) for k in keys}

    def _aggregate_counts(self, reports) -> tuple[dict, dict]:
        mood: dict[str, int] = {}
        cat: dict[str, int] = {}
        for r in reports:
            for k, v in (r.mood_counts or {}).items():
                mood[k] = mood.get(k, 0) + v
            for k, v in (r.category_breakdown or {}).items():
                cat[k] = cat.get(k, 0) + v
        return mood, cat

    def _attention_tag_counts(self, reports, moments) -> list[dict]:
        counts: dict[str, int] = {}
        for r in reports:
            day_moments = [m for m in moments if m.moment_date == r.report_date]
            ins = self.insight_svc.resolve_for_report(r, day_moments)
            for t in self.insight_svc.filter_focus_tags(
                ins.get("focus_tags") or [], need_attention=ins.get("need_attention", False)
            ):
                counts[t] = counts.get(t, 0) + 1
        return [
            {"code": k, "label": ATTENTION_TAG_LABELS.get(k, k), "count": v}
            for k, v in counts.items()
        ]

    def _reports_by_date(self, reports) -> dict:
        return {r.report_date: r for r in reports}

    def _risk_exposures(self, moments, reports) -> list[dict]:
        by_date = self._reports_by_date(reports)
        items: list[dict] = []
        seen: set[str] = set()
        for m in sorted(moments, key=lambda x: (x.moment_date, x.created_at), reverse=True):
            report = by_date.get(m.moment_date)
            dismissed = self.insight_svc.dismissed_ids(report)
            if not self.insight_svc.moment_note_is_critical(m, dismissed):
                continue
            mid = str(m.id)
            if mid in seen:
                continue
            seen.add(mid)
            items.append(
                {
                    "moment_id": m.id,
                    "date": m.moment_date.isoformat(),
                    "emotion_tag": m.emotion_tag,
                    "note": "",
                    "can_dismiss": True,
                }
            )
        return items

    def _moment_day_counts(self, day_moments) -> tuple[dict, dict]:
        mood: dict[str, int] = {}
        cat: dict[str, int] = {}
        for m in day_moments:
            mood[m.emotion_tag] = mood.get(m.emotion_tag, 0) + 1
            if m.event_tags:
                key = m.event_tags[0]
                cat[key] = cat.get(key, 0) + 1
        return mood, cat

    def _day_ai_summary(self, report, insight: dict) -> str:
        if report:
            stored = self.insight_svc.from_stored(report)
            if stored and stored.get("summary"):
                return str(stored["summary"])[:200]
            if insight.get("summary"):
                return str(insight["summary"])[:200]
            fuzzy = (report.fuzzy_analysis or "").strip()
            if fuzzy:
                return fuzzy[:200]
        if insight.get("summary"):
            return str(insight["summary"])[:200]
        return "当日暂无 AI 成长分析，持续观察中。"

    def _build_danger_records(self, day_moments, report) -> list[dict]:
        dismissed = self.insight_svc.dismissed_ids(report)
        records: list[dict] = []
        for m in sorted(day_moments, key=lambda x: x.created_at, reverse=True):
            if not self.insight_svc.moment_note_is_critical(m, dismissed):
                continue
            records.append(
                {
                    "moment_id": m.id,
                    "date": m.moment_date.isoformat(),
                    "category_tag": m.event_tags[0] if m.event_tags else None,
                    "category_label": moment_category_label(m),
                    "story_detail": format_moment_story_detail(m),
                    "note": "",
                    "emotion_tag": m.emotion_tag,
                    "can_dismiss": True,
                }
            )
        return records

    def _build_day_entries(self, day_moments, report) -> list[dict]:
        return self._build_danger_records(day_moments, report)

    def _build_daily_records(self, moments, reports) -> list[dict]:
        by_date = self._reports_by_date(reports)
        dates: set[date] = set(by_date.keys())
        for m in moments:
            dates.add(m.moment_date)

        records: list[dict] = []
        for day in sorted(dates, reverse=True):
            day_moments = [m for m in moments if m.moment_date == day]
            report = by_date.get(day)
            entries = self._build_danger_records(day_moments, report)
            if not entries:
                continue

            if report:
                ins = self.insight_svc.resolve_for_report(report, day_moments)
                mood_counts = dict(report.mood_counts or {})
                category = dict(report.category_breakdown or {})
                moment_count = report.moment_count
                has_report = True
            elif day_moments:
                ins = self.insight_svc.build_from_moments(day_moments)
                mood_counts, category = self._moment_day_counts(day_moments)
                moment_count = len(day_moments)
                has_report = False
            else:
                continue

            total = sum(mood_counts.values()) or 1
            neg = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)
            mood_score = round(1.0 - neg / total, 2)

            records.append(
                {
                    "date": day.isoformat(),
                    "ai_summary": self._day_ai_summary(report, ins),
                    "insight": ins,
                    "moment_count": moment_count,
                    "mood_counts": mood_counts,
                    "category_breakdown": category,
                    "mood_score": mood_score,
                    "has_report": has_report,
                    "danger_records": entries,
                    "entries": entries,
                }
            )
        return records[:30]

    @staticmethod
    def _flatten_entries(daily_records: list[dict]) -> list[dict]:
        flat: list[dict] = []
        for day in daily_records:
            flat.extend(day.get("entries") or [])
        return flat

    def _build_timeline(self, moments, reports) -> list[dict]:
        by_date = self._reports_by_date(reports)
        items = []
        for m in sorted(moments, key=lambda x: (x.moment_date, x.created_at), reverse=True):
            report = by_date.get(m.moment_date)
            dismissed = self.insight_svc.dismissed_ids(report)
            concern = report.concern_level if report else "normal"
            ins = self.insight_svc.build_from_moments([m], concern_level=concern, dismissed_ids=dismissed)
            if not self.insight_svc.should_show_in_timeline(ins):
                continue
            expose = self.insight_svc.moment_note_is_critical(m, dismissed)
            tags = self.insight_svc.filter_focus_tags(
                ins.get("focus_tags") or [], need_attention=ins.get("need_attention", False)
            )
            items.append(
                {
                    "moment_id": m.id,
                    "date": m.moment_date.isoformat(),
                    "emotion_tag": m.emotion_tag,
                    "category_tag": m.event_tags[0] if m.event_tags else None,
                    "category_label": moment_category_label(m),
                    "story_detail": format_moment_story_detail(m),
                    "note": None,
                    "note_exposed": False,
                    "can_dismiss": expose,
                    "ai_tags": [ATTENTION_TAG_LABELS.get(t, t) for t in tags],
                }
            )
        return items[:30]
