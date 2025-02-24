extends CharacterBody2D


@export var speed: float = 150.0
@export var jump_force: float = -300.0
@export var gravity: float = 800.0
@export var air_resistance: float = 0.8  
@export var ground_friction: float = 0.9
@export var max_fall_speed: float = 500.0
@export var hard_landing_threshold: float = 300.0 

@export var max_health: int = 3
var health: int = max_health
var is_dead: bool = false
signal health_updated(new_health)

var mana: int = 100
signal mana_updated(new_mana)


@export var attack_damage: int = 10

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var hitbox = $Hitbox/CollisionShape2D
@onready var attack_timer = $attack_timer
@onready var hurtbox = $Hurtbox/CollisionShape2D
@onready var collision_shape = $CollisionShape2D


var is_facing_right: bool = true
var coyote_time: float = 0.1  # Time to jump after leaving the ground 
var coyote_timer: float = 0.0
var jump_buffer_time: float = 0.1  # Time to buffer a jump before touching the ground 
var jump_buffer_timer: float = 0.0

# Character states
enum State { IDLE, RUNNING, JUMPING, FALLING, LANDING, ATTACKING, SLIDING, DEFENDING, HEALING, TAKING_DAMAGE }
var current_state = State.IDLE
const BUSY_STATES = [State.ATTACKING, State.DEFENDING, State.HEALING, State.LANDING, State.SLIDING, State.TAKING_DAMAGE]

var last_y_velocity = 0.0
var was_in_air = false


#func _ready():
	#animated_sprite_2d.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))

func _process(delta: float) -> void:
	if is_on_floor() and current_state not in BUSY_STATES:
		handle_input()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump(delta)
	handle_movement(delta)
	update_animations()
	move_and_slide()
	
	if not is_on_floor():
		last_y_velocity = velocity.y

	if is_on_floor() and was_in_air:
		if last_y_velocity > hard_landing_threshold:
			set_state(State.LANDING)
		else:
			set_state(State.IDLE)
		
	was_in_air = not is_on_floor() 

func handle_input() -> void:
	if Input.is_action_just_pressed("attack"):
		set_state(State.ATTACKING)
	elif Input.is_action_just_pressed("defense"):
		set_state(State.DEFENDING)
	elif Input.is_action_just_pressed("spell_cast"):
		set_state(State.HEALING)
	elif Input.is_action_just_pressed("slide"):
		if current_state != State.IDLE:
			set_state(State.SLIDING)

func set_state(new_state: State) -> void:
	current_state = new_state
	
	match new_state:
		State.SLIDING:
			slide()
		State.LANDING:
			land()
		State.ATTACKING:
			attack()
		State.DEFENDING:
			defense()
		State.HEALING:
			heal()
		_:
			reset_speed()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)  # Limit fall velocity 

func handle_jump(delta: float) -> void:
	# Coyote timer
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0 and coyote_timer > 0 and current_state not in BUSY_STATES:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		set_state(State.JUMPING)

func handle_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0 and current_state != State.SLIDING:
		is_facing_right = direction > 0
		animated_sprite_2d.flip_h = !is_facing_right
		
		if is_facing_right:
			hitbox.position.x = abs(hitbox.position.x)
		else:
			hitbox.position.x = -abs(hitbox.position.x)

	if current_state != State.SLIDING:
		if direction:
			velocity.x = direction * speed
		else:
			# Apply friction in the ground or resistance in the air
			if is_on_floor():
				velocity.x *= ground_friction
			else:
				velocity.x *= air_resistance

func update_animations() -> void:
	if current_state not in BUSY_STATES:
		if is_on_floor():
			if abs(velocity.x) > 10:
				set_state(State.RUNNING)
				animated_sprite_2d.play("run")
			else:
				set_state(State.IDLE)
				animated_sprite_2d.play("idle")
		else:
			if velocity.y < 0:
				set_state(State.JUMPING)
				animated_sprite_2d.play("jump")
			else:
				set_state(State.FALLING)
				animated_sprite_2d.play("fall")

func slide() -> void:
	velocity.x = speed * 0.9 * (1 if is_facing_right else -1)
	animated_sprite_2d.play("slide")

func land() -> void:
	speed = 10
	animated_sprite_2d.play("land")

func attack() -> void:
	speed = 0
	animated_sprite_2d.play("attack")
	attack_timer.start()

func defense() -> void:
	speed = 10
	animated_sprite_2d.play("shield_defense")
	hurtbox.disabled = true 

func heal() -> void:
	if health == max_health or mana < 100:
		current_state = State.IDLE
		return
		
	mana -= 100
	mana_updated.emit(mana)
	health += 1
	health_updated.emit(health)
	speed = 0
	animated_sprite_2d.play("spell_cast")

func reset_speed() -> void:
	speed = 150.0

func reset_combat_boxes(animation: String):
	if animation == "shield_defense":
		await get_tree().create_timer(0.5).timeout
		
	hitbox.disabled = true
	hurtbox.disabled = false

# Finalización de animaciones
func _on_animated_sprite_2d_animation_finished() -> void:
	var busy_animations = ["land", "attack", "shield_defense", "spell_cast", "slide", "take_damage"]
	
	if animated_sprite_2d.animation in busy_animations:
		set_state(State.IDLE)
		reset_combat_boxes(animated_sprite_2d.animation)


func _on_timer_timeout() -> void:
	hitbox.disabled = false
	
func die() -> void:
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	hurtbox.disabled = true
	set_physics_process(false)
	animated_sprite_2d.play("death")
	
func take_damage(damage: int):
	if current_state != State.DEFENDING:
		health -= damage
		health_updated.emit(health)
		print("Current health :", health)
		if health <= 0: 
			die()
		else:
			current_state = State.TAKING_DAMAGE
			animated_sprite_2d.play("take_damage")


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		area.get_parent().take_damage(attack_damage)
		mana += 10
		mana_updated.emit(mana)
