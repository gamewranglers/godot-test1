extends CharacterBody2D


@export var MOB_SPEED = 100.0
@onready var mob_sprite = $Sprite2D

@onready var player = get_node("/root/Game/Player")

var facing_left = false


func _ready():
    add_to_group("enemies")


func _physics_process(delta):
    var direction = global_position.direction_to(player.global_position)
    
    # flip the sprite if the player is to the left of the mob instance
    if direction.x < 0:
        facing_left = true
    else:
        facing_left = false
    mob_sprite.flip_h = facing_left
    
    # don't set as new variable, otherwise no movement happens
    velocity = direction * MOB_SPEED
    
    move_and_slide()
