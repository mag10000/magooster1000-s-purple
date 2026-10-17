extends Control
## 示例场景脚本 / Example Scene Script
## 演示 CardFan 插件的各种交互功能

@onready var card_set: Control = $CardSet

func _ready():
	card_set.debug_logging = true
	card_set.joystick_enabled = true

	# 连接信号 / Connect signals
	card_set.card_played.connect(_on_card_played)
	card_set.card_clicked.connect(_on_card_clicked)

	$VBoxContainer/Title.text = "🃏 CardFan 卡牌扇演示"
	$VBoxContainer/Hint.text = "双击/上滑/摇杆释放: 出牌\n长按拖拽: 排序\n+ / -: 加牌/减牌"

func _on_card_played(card):
	$VBoxContainer/Status.text = "出牌: " + card.get_card_name()

func _on_card_clicked(card):
	$VBoxContainer/Status.text = "点击: " + card.get_card_name()
