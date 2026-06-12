from app.core.companion_prop_labels import companion_prop_label, ensure_visual_prop_label


def test_game_prop_label():
    assert companion_prop_label("game") == "游戏"
    assert companion_prop_label("game_controller") == "游戏"


def test_stored_label_has_priority():
    assert companion_prop_label("game", stored_label="棋盘游戏") == "棋盘游戏"


def test_ensure_visual_prop_label_writes_label():
    visual = {"prop": "game_controller"}
    ensure_visual_prop_label(visual)
    assert visual["prop_label"] == "游戏"
