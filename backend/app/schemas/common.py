from typing import Generic, TypeVar
from pydantic import BaseModel, ConfigDict
T = TypeVar("T")
class ResponseModel(BaseModel, Generic[T]):
    code: int = 200
    message: str = "success"
    data: T | None = None
class Pagination(BaseModel):
    total: int
    page: int
    page_size: int
    items: list
    model_config = ConfigDict(from_attributes=True)
