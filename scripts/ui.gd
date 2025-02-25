extends CanvasLayer

@onready var health_label: Label = $PlayerHealthLabel
@onready var mana_label: Label = $PlayerMana

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func update_health(new_health: int) -> void:
	health_label.text = "%d/3" % new_health

func update_mana(new_mana: int) -> void:
	mana_label.text = "%d" % new_mana


func _on_main_character_health_updated(new_health: Variant) -> void:
	update_health(new_health)

func _on_main_character_mana_updated(new_mana: Variant) -> void:
	update_mana(new_mana)
