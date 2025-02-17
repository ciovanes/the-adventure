extends CharacterBody2D

@export var speed = 80.0
@export var jump = -250

@onready var animated_sprite_2d = $AnimatedSprite2D

var is_attacking = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

func attack():
	is_attacking = true
	animated_sprite_2d.play("attack")
	is_attacking = false

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
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite_2d.play("idle")
			else:
				animated_sprite_2d.play("run")
		else:
			if velocity.y < 0:
				animated_sprite_2d.play("jump")

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
