extends CharacterBody2D


@export var SPEED = 200.0
@onready var sprite_2d = $Sprite2D

var facing_left = false

func _physics_process(delta):
	var direction_y = Input.get_axis("move_up", "move_down")
	if direction_y:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	var direction_x = Input.get_axis("move_left", "move_right")
	if direction_x:
		velocity.x = direction_x * SPEED
		# toggle facing right/left based on last movement direction
		facing_left = velocity.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	sprite_2d.flip_h = facing_left
	
