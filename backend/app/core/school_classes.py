"""班级目录（教师端 / 学生端统一为家人测试班）。"""

DEFAULT_CLASS_NAME = "家人测试班"

CLASS_OPTIONS: tuple[str, ...] = ("家人测试班",)


def normalize_class_name(value: str) -> str:
    name = value.strip()
    if name not in CLASS_OPTIONS:
        raise ValueError(f"无效班级: {name}")
    return name
