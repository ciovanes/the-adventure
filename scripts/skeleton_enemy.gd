extends CharacterBody2D


# Collisions and Areas
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var death_timer: Timer = $DeathTimer
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var detection_area: Area2D = $DetectionArea

# Status
var health: int = 30
var attack_damage = 1
var is_dead: bool = false
var is_facing_right: bool = true
var speed: float = 40.0

# States
enum State { IDLE, CHASING, ATTACKING, TAKING_DAMAGE }
var current_state: State = State.IDLE
const BUSY_STATES = [State.ATTACKING, State.TAKING_DAMAGE]

# Pahtfinding
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
var target: Node2D = null
var player_in_attack_area: bool = false
var can_attack: bool = false 

# Sounds
@onready var attack_sound = $Sounds/AttackSound


func _physics_process(delta: float) -> void:
	update_animations()
	
	if target and current_state not in BUSY_STATES:
		handle_chasing()

func handle_chasing():
	current_state = State.CHASING
	
	var target_position = Vector2(target.global_position.x, global_position.y)
	navigation_agent.target_position = target_position
	var next_position = navigation_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	is_facing_right = direction.x >= 0
	animated_sprite_2d.flip_h = !is_facing_right

	if is_facing_right:
		hitbox_collision.position.x = abs(hitbox_collision.position.x)
	else:
		hitbox_collision.position.x = -abs(hitbox_collision.position.x)
	
	velocity.x = direction.x * speed
	
	move_and_slide()

func update_animations():
	match current_state:
		State.IDLE: 
			animated_sprite_2d.play("idle")
		State.CHASING: 
			animated_sprite_2d.play("chase")
		State.ATTACKING: 
			animated_sprite_2d.play("attack")

func take_damage(damage: int) -> void:
	if is_dead: 
		return
		
	health -= damage
	current_state = State.TAKING_DAMAGE
	animated_sprite_2d.play("take_damage")
	
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	
	collision_shape.set_deferred("disabled", true)
	hurtbox_collision.disabled = true
	hurtbox.monitoring = false
	
	set_physics_process(false)
	
	animated_sprite_2d.play("death")
	death_timer.start()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		target = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target: 
		target = null

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation in ["take_damage", "attack"]:
		await get_tree().create_timer(0.2).timeout
		current_state = State.IDLE

func attack():
	if can_attack and player_in_attack_area:
		can_attack = false
		current_state = State.ATTACKING
		
		animated_sprite_2d.play("attack")
		attack_sound.play()
	
		await get_tree().create_timer(0.5).timeout
		
		if current_state == State.ATTACKING and not is_dead:
			hitbox_collision.disabled = false
			
		attack_cooldown.start()

func _on_attacking_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		can_attack = true
		player_in_attack_area = true
		attack()

func _on_attacking_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = false

func _on_attack_cooldown_timeout() -> void:
	hitbox_collision.disabled = true
	can_attack = true 
	
	if player_in_attack_area and not is_dead:
		attack()
	else:
		current_state = State.IDLE

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox") and current_state == State.ATTACKING:
		area.get_parent().take_damage(attack_damage)

func _on_death_timer_timeout() -> void:
	queue_free()
