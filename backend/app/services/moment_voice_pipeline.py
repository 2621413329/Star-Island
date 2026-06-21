"""语音故事上传后的异步转写与 AI 打标。"""

from __future__ import annotations

import asyncio
import uuid
from pathlib import Path

from loguru import logger

from app.core.companion_prop_labels import ensure_visual_prop_label
from app.core.moment_content import CONTENT_TYPE_VOICE
from app.database.database import AsyncSessionLocal
from app.repositories.growth_tag_repository import GrowthTagRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.services.companion_scene_service import CompanionSceneService
from app.services.moment_analysis_service import MomentAnalysisService
from app.services.moment_transcription_service import MomentTranscriptionService


def _finalize_moment_scene(
    scene: dict,
    *,
    primary_tag: str | None,
    secondary_tags: list[str],
    growth_points: list[str],
    ai_emotion: str | None,
) -> dict:
    visual = dict(scene.get("visual_payload") or {})
    if primary_tag:
        visual["primary_tag"] = primary_tag
    if secondary_tags:
        visual["secondary_tags"] = secondary_tags
    if growth_points:
        visual["growth_points"] = growth_points
    if ai_emotion:
        visual["ai_emotion"] = ai_emotion
    ensure_visual_prop_label(visual)
    return {**scene, "visual_payload": visual}


async def schedule_voice_transcription(
    *,
    moment_id: uuid.UUID,
    user_id: uuid.UUID,
    audio_path: str,
) -> None:
    asyncio.create_task(
        _finalize_voice_moment(
            moment_id=moment_id,
            user_id=user_id,
            audio_path=audio_path,
        )
    )


async def _finalize_voice_moment(
    *,
    moment_id: uuid.UUID,
    user_id: uuid.UUID,
    audio_path: str,
) -> None:
    transcription = MomentTranscriptionService()
    analysis = MomentAnalysisService()
    scene_service = CompanionSceneService()

    speech_text: str | None = None
    speech_status = "failed"
    try:
        speech_text = await transcription.transcribe(Path(audio_path))
        speech_status = "success"
    except Exception as exc:
        logger.warning(
            "voice transcription failed moment_id={} err={}",
            moment_id,
            exc,
        )

    async with AsyncSessionLocal() as session:
        moment_repo = DailyMomentRepository(session)
        profile_repo = ProfileRepository(session)
        growth_tag_repo = GrowthTagRepository(session)

        moment = await moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment or moment.content_type != CONTENT_TYPE_VOICE:
            return

        moment.speech_text = speech_text
        moment.speech_status = speech_status

        if speech_text:
            try:
                categories = await growth_tag_repo.list_categories(active_only=True)
                result = await analysis.analyze(speech_text, categories)
                event_tags = analysis.build_event_tags(result)
                profile = await profile_repo.get_by_user_id(user_id)
                companion_style = profile.companion_style if profile else "chibi"
                scene = scene_service.build(
                    companion_style=companion_style or "chibi",
                    emotion_tag=result.legacy_emotion_tag,
                    event_tags=event_tags,
                    note=speech_text,
                )
                scene = _finalize_moment_scene(
                    scene,
                    primary_tag=result.primary_tag,
                    secondary_tags=result.secondary_tags,
                    growth_points=result.growth_points,
                    ai_emotion=result.emotion,
                )
                moment.event_tags = event_tags
                moment.emotion_tag = result.legacy_emotion_tag
                moment.primary_tag = result.primary_tag
                moment.secondary_tags = result.secondary_tags
                moment.growth_points = result.growth_points
                moment.ai_emotion = result.emotion
                moment.companion_scene = scene["companion_scene"]
                moment.companion_pose = scene["companion_pose"]
                moment.visual_payload = scene["visual_payload"]
            except Exception as exc:
                logger.warning(
                    "voice moment AI re-tag failed moment_id={} err={}",
                    moment_id,
                    exc,
                )

        await moment_repo.save(moment)
        await session.commit()
