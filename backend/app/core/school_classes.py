"""班级目录默认值（数据库 school_classes 表为权威来源）。"""

DEFAULT_CLASS_NAME = "测试班"

# 离线/启动兜底；运行时以数据库激活班级列表为准。
CLASS_OPTIONS: tuple[str, ...] = ("测试班",)
