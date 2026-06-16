from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base


class GrowthTagCategory(Base):
    """成长故事一级标签（可配置）。"""

    __tablename__ = "growth_tag_categories"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    label: Mapped[str] = mapped_column(String(32), nullable=False)
    icon: Mapped[str] = mapped_column(String(64), nullable=False, default="label")
    color: Mapped[str] = mapped_column(String(16), nullable=False, default="#78909C")
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    tags: Mapped[list["GrowthTag"]] = relationship(
        "GrowthTag", back_populates="category", cascade="all, delete-orphan"
    )


class GrowthTag(Base):
    """成长故事二级标签。"""

    __tablename__ = "growth_tags"
    __table_args__ = (
        UniqueConstraint("category_id", "label", name="uq_growth_tags_category_label"),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    category_id: Mapped[str] = mapped_column(
        String(32), ForeignKey("growth_tag_categories.id", ondelete="CASCADE"), index=True
    )
    label: Mapped[str] = mapped_column(String(32), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    category = relationship("GrowthTagCategory", back_populates="tags")
