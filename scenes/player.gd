extends CharacterBody2D

@onready var player_sprite = $Sprite2D

@export var PLAYER_SPEED = 200.0

var health_points = 100
var max_health_points = 100

var experience = 0

var held_weapon = null
var recently_dropped_weapon = false

var facing_left = false

@export var EQUIPMENT_OFFSET_X = 8
@export var EQUIPMENT_OFFSET_Y = -5
@export var EQUIPMENT_ROTATION = 15


func _physics_process(delta: float):
    %HealthBar.value = health_points
    %HealthBar.max_value = max_health_points
    
    handle_movement(delta)
    
    adjust_held_weapon()
    adjust_attack_range()

    handle_attack_input()
    handle_enemy_damage()

            
func handle_movement(delta):
    # check for vertical movement
    var direction_y = Input.get_axis("move_up", "move_down")
    if direction_y:
        velocity.y = direction_y * PLAYER_SPEED
    else:
        velocity.y = move_toward(velocity.y, 0, PLAYER_SPEED)
        
    # check for horizontal movement
    var direction_x = Input.get_axis("move_left", "move_right")
    if direction_x:
        velocity.x = direction_x * PLAYER_SPEED
        # toggle facing right/left based on last movement direction
        facing_left = velocity.x < 0
    else:
        velocity.x = move_toward(velocity.x, 0, PLAYER_SPEED)

    move_and_slide()
    
    # if the player last moved left, make sure they stay facing left
    # if the player last moved right, make sure they stay facing right
    player_sprite.flip_h = facing_left
    
    if held_weapon:
        held_weapon.facing_left = facing_left
    
    

func handle_attack_input():
    if Input.is_action_just_pressed("primary_attack"):
        if held_weapon != null:
            # reset any current attack animation before re-triggering
            %WeaponPivotPoint.rotation_degrees = 0
            held_weapon.attack()
            
            var enemies_in_range = %AttackRange.get_overlapping_bodies()
            # TODO: determine whether player is attacking one enemy or multiple
            for enemy in enemies_in_range:
                var damage_amount = held_weapon.hit()
                var experience_gained = enemy.take_damage(damage_amount)
                experience += experience_gained
                
            print("player xp: %s" % experience)
        else:
            print("no weapon to attack with, and we haven't implemented punching yet!")
    
    
func adjust_held_weapon():
    if held_weapon == null:
        return
    # adjust position/rotation based on facing left/right
    var adjustment = -1 if facing_left else 1
    held_weapon.position = Vector2(EQUIPMENT_OFFSET_X * adjustment, EQUIPMENT_OFFSET_Y)
    held_weapon.rotation_degrees = EQUIPMENT_ROTATION * adjustment
    
    
func adjust_attack_range():
    if held_weapon != null:
        # double size of attack range
        %AttackRange.scale = Vector2(2.0, 2.0)
    else:
        # reset the attack range size
        %AttackRange.scale = Vector2(1.0, 1.0)
        
        
func reparent_item_to_player(obj: Area2D):
    # remove from current parent node
    var pickups = get_node("../Pickups")
    pickups.call_deferred("remove_child", obj)
    
    # add as child of the weapon pivot/anchor
    %WeaponPivotPoint.call_deferred("add_child", obj)
    obj.call_deferred("set_as_top_level", false)
    
    # reposition the weapon to the right of the player, scale it down slightly, and rotate it
    # to give off the illusion that the player is "holding" it
    obj.scale = Vector2(0.75, 0.75)
    
    # NOTE: when attacking, movement will be relative to the weapon pivot point instead of the
    # weapon node's center position
    # TODO: make these weapon properties, not hard-coded values
    obj.position = %WeaponPivotPoint.position + Vector2(EQUIPMENT_OFFSET_X, EQUIPMENT_OFFSET_Y)
    obj.rotation_degrees = 15
    

func orphan_item_from_player(obj: Area2D):
    # Defer removing the item as a child to ensure it's not during physics processing
    %WeaponPivotPoint.call_deferred("remove_child", obj)
    
    # Defer adding as a child of the pickups node
    var pickups = get_node("../Pickups")
    pickups.call_deferred("add_child", obj)
    obj.call_deferred("set_as_top_level", true)
    
    # Reset scaling/rotation - these can typically be done immediately
    obj.scale = Vector2(1.0, 1.0)
    obj.rotation_degrees = 0
    
    # Drop it at the player's current position and prevent immediate pickup
    obj.position = position
    recently_dropped_weapon = true


# ITEM PICKUPS
func handle_weapon_pickup(weapon_name):        
    if held_weapon != null:
        if held_weapon.name == weapon_name:
            return
        # already holding a weapon; drop it to pick up the new one
        orphan_item_from_player(held_weapon)
        held_weapon = null

    var weapon: Area2D = get_node("../Pickups/%s" % weapon_name)
    # if we just dropped the weapon, we can't pick it back up just yet
    if recently_dropped_weapon:
        print("can't pick up %s yet" % weapon.name)
        return
        
    reparent_item_to_player(weapon)
    
    # prevent these checks from happening after pickup
    held_weapon = weapon

func handle_potion_pickup():
    pass


# PLAYER->ENEMY 
func _on_attack_range_body_entered(body):
    if body.is_in_group("enemies"):
        print("%s in attacking range! 🪓" % body)

func _on_attack_range_body_exited(body):
    if body.is_in_group("enemies"):
        print("%s no longer in attack range" % body)


# PLAYER->ITEM
func _on_item_body_entered(item_name: String, body):
    if body != self:
        return
        
    var obj = get_node("../Pickups/%s" % item_name)
    if not obj:
        return
    if obj.is_in_group("potions"):
        handle_potion_pickup()
    elif obj.is_in_group("weapons"):
        handle_weapon_pickup(item_name)

func _on_item_body_exited(item_name: String, body):
    if body != self:
        return
        
    var obj = get_node("../Pickups/%s" % item_name)
    if not obj:
        return
    if obj.is_in_group("weapons"):
        # if the player walks away from the weapon, it's fair game to pick back up now
        recently_dropped_weapon = false

# ENEMY->PLAYER
func _on_hitbox_body_entered(body):
    if body.is_in_group("enemies"):
        print("%s hit player!" % body)
    

func handle_enemy_damage():
    var overlapping_enemies = %Hitbox.get_overlapping_bodies()
    for enemy in overlapping_enemies:
        var damage_amount = enemy.hit()
        take_damage(damage_amount)


func take_damage(damage_amount: int):
    health_points -= damage_amount
    print("%s took %s point(s) of damage (%s/%s)" % [self, damage_amount, health_points, max_health_points])
    
    if health_points <= 0:
        print("player died! ☠️")
        # queue_free()
        # TODO: transition to some "game over" state
