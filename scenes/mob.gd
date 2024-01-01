extends CharacterBody2D


@onready var mob_sprite = $Sprite2D

@export var MOB_SPEED = 50.0
var health_points = 100
var max_health_points = 100

var damage = 1

var kill_experience = 5

var facing_left = false

@onready var player = get_node("/root/Game/Player")


func _ready():
    add_to_group("enemies")


func _physics_process(delta):
    %HealthBar.value = health_points
    %HealthBar.max_value = max_health_points
    
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
    
    
func hit():
    return damage


func take_damage(damage_amount: int):
    health_points -= damage_amount
    # TODO: add some kind of hit indicator/animation
    print("%s took %s point(s) of damage (%s/%s)" % [self, damage_amount, health_points, max_health_points])
    
    if health_points <= 0:
        print(self, " died! ☠️")
        queue_free()
        # TODO: add some death indicator/animation
        return kill_experience
        
    return 0
    
