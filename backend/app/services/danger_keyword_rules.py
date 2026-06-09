from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class DangerKeywordMatch:
    level: str
    category: str
    term: str

    @property
    def concern_level(self) -> str:
        return "urgent" if self.level in {"critical", "high", "medium_high"} else "watch"

    @property
    def risk_level(self) -> str:
        return "critical" if self.level in {"critical", "high", "medium_high"} else "elevated"

    @property
    def label(self) -> str:
        return f"{self.category}：{self.term}"


DANGER_KEYWORDS: list[tuple[str, str, tuple[str, ...]]] = [
    (
        "critical",
        "极高危险",
        (
            "动刀",
            "捅人",
            "砍人",
            "扎人",
            "下死手",
            "弄死你",
            "杀人",
            "放火",
            "纵火",
            "炸东西",
            "爆炸",
            "下毒",
            "投毒",
            "勒人",
            "掐脖子",
            "活埋",
            "坠楼",
            "跳下去",
            "同归于尽",
            "玩命",
            "拼命",
            "拿命抵",
            "肢解",
            "伤人致残",
            "打断手脚",
            "捅刀子",
            "挥刀相向",
            "放火烧屋",
        ),
    ),
    (
        "high",
        "高危险",
        (
            "打人",
            "揍人",
            "群殴",
            "围殴",
            "打架",
            "拳打脚踢",
            "扇巴掌",
            "锁起来",
            "关起来",
            "绑人",
            "绑票",
            "劫持",
            "挟持",
            "抓人",
            "扣人",
            "软禁",
            "堵人",
            "围堵",
            "追打",
            "追杀",
            "威胁",
            "恐吓",
            "报复",
            "收拾你",
            "搞垮你",
            "找人算账",
            "动粗",
            "拳脚相加",
            "拦路截人",
            "强行拖拽",
        ),
    ),
    (
        "medium_high",
        "中高危险",
        (
            "抢钱",
            "抢东西",
            "拦路抢",
            "入室抢",
            "撬门抢劫",
            "讹钱",
            "敲竹杠",
            "逼债",
            "强行要钱",
            "抢包",
            "抢手机",
            "劫道",
            "勒索财物",
            "逼转账",
            "不给钱就动手",
            "抢店铺",
            "抢车辆",
        ),
    ),
    (
        "medium",
        "中等危险",
        (
            "偷东西",
            "入室偷",
            "扒窃",
            "顺手牵羊",
            "撬锁",
            "翻东西",
            "骗钱",
            "骗货",
            "设圈套",
            "下套",
            "忽悠坑人",
            "宰客",
            "骗走财物",
            "碰瓷",
            "故意碰瓷",
            "掉包",
            "造假骗钱",
            "偷车",
            "偷电瓶",
            "溜门撬锁",
        ),
    ),
    (
        "security",
        "治安风险",
        (
            "耍流氓",
            "耍横",
            "耍无赖",
            "调戏",
            "骚扰",
            "咸猪手",
            "聚众闹事",
            "起哄闹事",
            "砸东西",
            "打砸",
            "掀摊子",
            "砸场子",
            "拉帮结派",
            "结伙作恶",
            "街头闹事",
            "故意挑事",
            "惹事生非",
            "横行霸道",
            "欺负人",
            "霸凌",
            "校园霸凌",
            "堵校门",
            "围堵同学",
        ),
    ),
    (
        "illegal",
        "违法违规",
        (
            "赌博",
            "赌钱",
            "赌局",
            "出老千",
            "吸毒",
            "贩毒",
            "卖违禁品",
            "走私",
            "嫖妓",
            "拉皮条",
            "收黑钱",
            "拿回扣",
            "行贿",
            "受贿",
            "走歪路",
            "干黑活",
            "做黑生意",
            "倒卖违禁物",
            "私自买卖危险品",
        ),
    ),
    (
        "threat",
        "言语威胁",
        (
            "弄死全家",
            "让你不好过",
            "找人打你",
            "半路堵你",
            "跟你没完",
            "走着瞧",
            "弄死对方",
            "废了你",
            "整死你",
            "找人收拾",
            "上门找麻烦",
            "上门闹事",
            "堵家门口",
        ),
    ),
    (
        "other",
        "其他危险行为",
        (
            "割腕",
            "自残",
            "割手",
            "喝药",
            "上吊",
            "跳河",
            "摸电线",
            "玩火",
            "乱碰危险品",
            "高空抛物",
            "扔重物",
            "开车撞人",
            "酒驾撞人",
            "飙车撞人",
        ),
    ),
]


def detect_danger_keywords(text: str | None) -> list[DangerKeywordMatch]:
    normalized = (text or "").strip()
    if not normalized:
        return []

    candidates: list[DangerKeywordMatch] = []
    for level, category, terms in DANGER_KEYWORDS:
        for term in terms:
            if term in normalized:
                candidates.append(
                    DangerKeywordMatch(level=level, category=category, term=term)
                )

    matches: list[DangerKeywordMatch] = []
    seen: set[str] = set()
    for match in sorted(candidates, key=lambda item: len(item.term), reverse=True):
        if match.term in seen:
            continue
        if any(match.term in kept.term for kept in matches):
            continue
        seen.add(match.term)
        matches.append(match)
    return matches
