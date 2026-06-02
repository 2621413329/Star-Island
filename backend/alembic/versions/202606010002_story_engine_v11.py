from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202606010002"
down_revision: str | None = "202606010001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "story_rules",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.Column("dsl", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("priority", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_story_rules_name"), "story_rules", ["name"], unique=True)

    op.create_table(
        "story_templates",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("style", sa.String(length=32), nullable=False),
        sa.Column("system_prompt", sa.Text(), nullable=False),
        sa.Column("user_prompt_template", sa.Text(), nullable=False),
        sa.Column("output_schema", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("version", sa.String(length=32), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_story_templates_name"), "story_templates", ["name"], unique=False)
    op.create_index(op.f("ix_story_templates_style"), "story_templates", ["style"], unique=False)

    op.create_table(
        "stories",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("source_record_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("rule_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("template_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("title", sa.String(length=128), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("emotion_flow", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("sections", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("scene_prompt", sa.Text(), nullable=True),
        sa.Column("image_style", sa.String(length=64), nullable=True),
        sa.Column("visual_payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["rule_id"], ["story_rules.id"]),
        sa.ForeignKeyConstraint(["source_record_id"], ["observation_records.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["template_id"], ["story_templates.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_stories_created_by"), "stories", ["created_by"], unique=False)
    op.create_index(op.f("ix_stories_source_record_id"), "stories", ["source_record_id"], unique=False)
    op.create_index(op.f("ix_stories_status"), "stories", ["status"], unique=False)
    op.create_index(op.f("ix_stories_student_id"), "stories", ["student_id"], unique=False)

    op.create_table(
        "story_generation_runs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("story_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("record_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("matched_rules", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("plan", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("prompt", sa.Text(), nullable=True),
        sa.Column("llm_response", sa.Text(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("latency_ms", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["story_id"], ["stories.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_story_generation_runs_status"), "story_generation_runs", ["status"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_story_generation_runs_status"), table_name="story_generation_runs")
    op.drop_table("story_generation_runs")
    op.drop_index(op.f("ix_stories_student_id"), table_name="stories")
    op.drop_index(op.f("ix_stories_status"), table_name="stories")
    op.drop_index(op.f("ix_stories_source_record_id"), table_name="stories")
    op.drop_index(op.f("ix_stories_created_by"), table_name="stories")
    op.drop_table("stories")
    op.drop_index(op.f("ix_story_templates_style"), table_name="story_templates")
    op.drop_index(op.f("ix_story_templates_name"), table_name="story_templates")
    op.drop_table("story_templates")
    op.drop_index(op.f("ix_story_rules_name"), table_name="story_rules")
    op.drop_table("story_rules")
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202606010002"
down_revision: str | None = "202606010001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "story_rules",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("dsl", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("priority", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_story_rules_name"), "story_rules", ["name"], unique=True)

    op.create_table(
        "story_templates",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("style", sa.String(length=32), nullable=False),
        sa.Column("system_prompt", sa.Text(), nullable=False),
        sa.Column("user_prompt_template", sa.Text(), nullable=False),
        sa.Column("output_schema", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("version", sa.String(length=32), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_story_templates_name"), "story_templates", ["name"], unique=False)
    op.create_index(op.f("ix_story_templates_style"), "story_templates", ["style"], unique=False)

    op.create_table(
        "stories",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("source_record_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("rule_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("template_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("title", sa.String(length=128), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("emotion_flow", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("sections", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("scene_prompt", sa.Text(), nullable=True),
        sa.Column("image_style", sa.String(length=64), nullable=True),
        sa.Column("visual_payload", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["rule_id"], ["story_rules.id"]),
        sa.ForeignKeyConstraint(["source_record_id"], ["observation_records.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["template_id"], ["story_templates.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_stories_created_by"), "stories", ["created_by"], unique=False)
    op.create_index(op.f("ix_stories_source_record_id"), "stories", ["source_record_id"], unique=False)
    op.create_index(op.f("ix_stories_status"), "stories", ["status"], unique=False)
    op.create_index(op.f("ix_stories_student_id"), "stories", ["student_id"], unique=False)

    op.create_table(
        "story_generation_runs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("story_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("record_snapshot", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("matched_rules", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("plan", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("prompt", sa.Text(), nullable=True),
        sa.Column("llm_response", sa.Text(), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("latency_ms", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["story_id"], ["stories.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_story_generation_runs_status"), "story_generation_runs", ["status"], unique=False)
    op.create_index(op.f("ix_story_generation_runs_story_id"), "story_generation_runs", ["story_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_story_generation_runs_story_id"), table_name="story_generation_runs")
    op.drop_index(op.f("ix_story_generation_runs_status"), table_name="story_generation_runs")
    op.drop_table("story_generation_runs")
    op.drop_index(op.f("ix_stories_student_id"), table_name="stories")
    op.drop_index(op.f("ix_stories_status"), table_name="stories")
    op.drop_index(op.f("ix_stories_source_record_id"), table_name="stories")
    op.drop_index(op.f("ix_stories_created_by"), table_name="stories")
    op.drop_table("stories")
    op.drop_index(op.f("ix_story_templates_style"), table_name="story_templates")
    op.drop_index(op.f("ix_story_templates_name"), table_name="story_templates")
    op.drop_table("story_templates")
    op.drop_index(op.f("ix_story_rules_name"), table_name="story_rules")
    op.drop_table("story_rules")
