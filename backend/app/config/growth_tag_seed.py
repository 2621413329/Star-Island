"""默认成长标签种子（与产品文档一致）。"""

from __future__ import annotations

GROWTH_TAG_SEED: list[dict] = [
    {
        "id": "work",
        "label": "工作",
        "icon": "briefcase",
        "color": "#5C6BC0",
        "sort_order": 10,
        "tags": [
            "项目推进", "产品设计", "开发编码", "测试发布", "面试", "入职", "转正", "加班", "晋升", "创业",
        ],
    },
    {
        "id": "study",
        "label": "学习",
        "icon": "book",
        "color": "#42A5F5",
        "sort_order": 20,
        "tags": [
            "阅读", "课程学习", "英语", "编程", "备考", "考研", "考公", "技能提升", "知识整理",
        ],
    },
    {
        "id": "health",
        "label": "健康",
        "icon": "fitness_center",
        "color": "#66BB6A",
        "sort_order": 30,
        "tags": [
            "跑步", "健身", "骑行", "游泳", "睡眠", "饮食", "减肥", "增肌", "康复",
        ],
    },
    {
        "id": "social",
        "label": "人际",
        "icon": "groups",
        "color": "#AB47BC",
        "sort_order": 40,
        "tags": [
            "聚会", "恋爱", "家人", "同学", "同事", "社交", "沟通", "冲突", "和解",
        ],
    },
    {
        "id": "life",
        "label": "生活",
        "icon": "home",
        "color": "#FFA726",
        "sort_order": 50,
        "tags": [
            "日常", "购物", "旅行", "美食", "娱乐", "游戏", "电影", "休闲", "记录", "复盘",
        ],
    },
    {
        "id": "creation",
        "label": "创作",
        "icon": "palette",
        "color": "#EC407A",
        "sort_order": 60,
        "tags": [
            "写作", "绘画", "摄影", "剪辑", "音乐", "设计", "内容创作",
        ],
    },
    {
        "id": "finance",
        "label": "财务",
        "icon": "account_balance_wallet",
        "color": "#26A69A",
        "sort_order": 70,
        "tags": [
            "工资", "奖金", "投资", "理财", "消费", "储蓄",
        ],
    },
    {
        "id": "achievement",
        "label": "成就",
        "icon": "emoji_events",
        "color": "#FFD54F",
        "sort_order": 80,
        "tags": [
            "完成目标", "通过考试", "项目上线", "获奖", "晋升", "坚持打卡",
        ],
    },
    {
        "id": "emotion",
        "label": "情绪",
        "icon": "sentiment_satisfied",
        "color": "#78909C",
        "sort_order": 90,
        "tags": [
            "开心", "平静", "焦虑", "压力", "兴奋", "感动", "失落", "愤怒",
            "自我觉察", "身体关怀",
        ],
    },
    {
        "id": "inspiration",
        "label": "灵感",
        "icon": "lightbulb",
        "color": "#FFCA28",
        "sort_order": 100,
        "tags": [
            "灵感", "反思", "认知升级", "人生感悟", "未来规划", "新目标",
        ],
    },
    {
        "id": "milestone",
        "label": "特殊事件",
        "icon": "celebration",
        "color": "#EF5350",
        "sort_order": 110,
        "tags": [
            "毕业", "入职", "离职", "搬家", "结婚", "生日", "旅行", "人生转折",
        ],
    },
]
