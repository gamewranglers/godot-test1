extends CharacterBody2D


@onready var mob_sprite = $Sprite2D

@export var MOB_SPEED = 50.0
var health_points = 10
var max_health_points = 10

var damage = 5
var status_text_scene = preload("res://scenes/status_text.tscn")

var last_attack_time = 0
var attack_cooldown_sec = 0.5

var is_getting_knocked_back = false
var knockback_time = 0
var knockback_amount = 0
var knockback_cooldown_sec = 0.15

var kill_experience = 5

var facing_left = false

var WANDER_X = 0.0
var WANDER_Y = 0.0


func _ready():
    add_to_group("enemies")


func _physics_process(delta):
    update_health_bars()
    
    var direction = Vector2(0, 0)
    
    var player = get_node("/root/Game/Player")
    if not player.is_dead:
        # head to the player
        direction = global_position.direction_to(player.global_position)
    else:
        # wander around
        var wander_pos = Vector2(WANDER_X, WANDER_Y)
        direction = global_position.direction_to(wander_pos)
    
    # flip the sprite if the player is to the left of the mob instance
    if direction.x < 0:
        facing_left = true
    else:
        facing_left = false
    mob_sprite.flip_h = facing_left
    
    
    if Time.get_ticks_msec() - knockback_time > knockback_cooldown_sec * 1000:
        # stop the knockback adjustment
        is_getting_knocked_back = false
        
    if is_getting_knocked_back:
        # face away from the player and push back slightly faster than normal movement speed
        velocity = -direction * MOB_SPEED * knockback_amount
    else:
        velocity = direction * MOB_SPEED
    
    move_and_slide()
    
    
func update_health_bars():
    # over the player sprite
    %HealthBar.value = health_points
    %HealthBar.max_value = max_health_points
    if health_points < max_health_points:
        # display the health bar over the player if any damage was taken
        %HealthBar.visible = true
    else:
        %HealthBar.visible = false
    
    
func hit():
    return damage


func take_knockback(amount: int):
    is_getting_knocked_back = true
    knockback_time = Time.get_ticks_msec()
    knockback_amount = amount


func take_damage(amount: int):
    health_points -= amount
    #print("%s took %s point(s) of damage (%s/%s)" % [self, amount, health_points, max_health_points])
    
    mob_sprite.modulate = Color.RED
    %HurtFlashTimer.start()
    
    # display damage numbers
    var popup = status_text_scene.instantiate()
    get_parent().add_child(popup)
    popup.start(str(amount), global_position)
    
    if health_points <= 0:
        #print(self, " died! ☠️")
        queue_free()
        # TODO: add some death indicator/animation
        return kill_experience
    
    return 0


func _on_hit_flash_timer_timeout():
    mob_sprite.modulate = Color.WHITE


func _on_wander_timer_timeout():
    var player = get_node("/root/Game/Player")
    if player.is_dead:
        WANDER_X = randi_range(-500, 1600)
        WANDER_Y = randi_range(-500, 1600)
        # adjust how long until next wander position change
        %WanderTimer.wait_time = randf_range(0.2, 5.0)
        MOB_SPEED = randf_range(0.0, 65.0)
