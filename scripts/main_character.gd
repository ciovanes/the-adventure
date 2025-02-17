extends CharacterBody2D

@export var speed = 100.0
@export var jump = -250

@onready var animated_sprite_2d = $AnimatedSprite2D

var is_attacking = false
var is_defending = false
var is_healing = false

func _ready():
	# Conectar la señal animation_finished a una función
	animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))

func _process(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("attack") and not is_attacking and not is_defending:
			attack()
		if Input.is_action_just_pressed("defense") and not is_attacking and not is_defending:
			defense()
		if Input.is_action_just_pressed("spell_cast"):
			heal()

func attack():
	is_attacking = true
	speed = 10
	animated_sprite_2d.play("attack")

func defense():
	is_defending = true
	speed = 10
	animated_sprite_2d.play("shield_defense")

func heal():
	is_healing = true
	speed = 0
	animated_sprite_2d.play("spell_cast")

func _physics_process(delta: float) -> void:
	# Añadir gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Manejo del salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump

	# Obtener dirección y manejar movimiento/desaceleración
	var direction := Input.get_axis("move_left", "move_right")

	# Invertir sprites
	if direction < 0:
		animated_sprite_2d.flip_h = true
	elif direction > 0:
		animated_sprite_2d.flip_h = false

	# Si el personaje no está atacando, manejar las animaciones de movimiento

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animations(direction)

func update_animations(direction) -> void:
	if not is_attacking and not is_defending and not is_healing:
		if is_on_floor():
			if direction == 0:
				animated_sprite_2d.play("idle")
			else:
				animated_sprite_2d.play("run")
		else:
			if velocity.y < 0:
				animated_sprite_2d.play("jump")


func _on_animated_sprite_2d_animation_finished() -> void:
	match animated_sprite_2d.animation:
		"attack":
			is_attacking = false
			speed = 80
		"shield_defense":
			is_defending = false
			speed = 80
		"spell_cast":
			is_healing = false
			speed = 80
