extends CharacterBody2D

@onready var player_sprite = $Sprite2D
@export var PLAYER_SPEED = 200.0

var held_weapon = null
var recently_dropped_weapon = false

var facing_left = false

@export var EQUIPMENT_ROTATION = 15
@export var EQUIPMENT_OFFSET_X = 8


func _physics_process(delta: float):
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
    
    var attack_range = get_node("./AttackRange")
    
    if held_weapon:
        # double size of attack range
        attack_range.scale = Vector2(2.0, 2.0)
        # adjust position/rotation based on facing left/right
        var weapon = get_node(held_weapon)
        if weapon:
            var adjustment = -1 if facing_left else 1
            weapon.position = Vector2(EQUIPMENT_OFFSET_X * adjustment, 0)
            weapon.rotation_degrees = EQUIPMENT_ROTATION * adjustment
    else:
        # reset the attack range size
        attack_range.scale = Vector2(1.0, 1.0)
        
        
func reparent_item_to_player(obj: Area2D):
    print("player is picking up ", obj.name)
    # remove from current parent node
    obj.get_parent().remove_child(obj)
    # add as child of player node
    add_child(obj)


func orphan_item_from_player(obj: Area2D):
    print("player is dropping ", obj.name)
    # remove as child of player node
    remove_child(obj)
    # add as child of pickups node
    var pickups = get_node("/root/Game/Pickups")
    pickups.add_child(obj)
    obj.set_as_top_level(true)
    # drop it at the player's current position and prevent immediate pickup
    obj.position = position + Vector2(15, 15)
    recently_dropped_weapon = true


# ITEM PICKUPS
func handle_weapon_pickup(weapon_name):
    if held_weapon == weapon_name:
        return
        
    if held_weapon != null:
        # already holding a weapon; drop it to pick up the new one
        var current_weapon: Area2D = get_node("/root/Game/Player/%s" % held_weapon)
        if current_weapon:
            orphan_item_from_player(current_weapon)

    var weapon: Area2D = get_node("/root/Game/Pickups/%s" % weapon_name)
    # if we just dropped the weapon, we can't pick it back up just yet
    if recently_dropped_weapon:
        print("can't pick up %s yet" % weapon.name)
        return
        
    reparent_item_to_player(weapon)
    
    # reposition the weapon to the right of the player, scale it down slightly, and rotate it
    # to give off the illusion that the player is "holding" it
    weapon.position = Vector2(8, 0)
    weapon.scale = Vector2(0.75, 0.75)
    weapon.rotation_degrees = 15
    weapon.set_as_top_level(false)
    
    # prevent these checks from happening after pickup
    held_weapon = weapon_name


func handle_potion_pickup():
    pass


# PLAYER->ENEMY 
func _on_attack_range_body_entered(body):
    if body.is_in_group("enemies"):
        print(body.name, " in attacking range! 🪓")


func _on_attack_range_body_exited(body):
    if body.is_in_group("enemies"):
        print(body.name, " no longer in attack range")


# PLAYER->ITEM
func _on_item_body_entered(item_name: String, body):
    if body != self:
        return
        
    var obj = get_node("/root/Game/Pickups/%s" % item_name)
    if obj.is_in_group("potions"):
        handle_potion_pickup()
    elif obj.is_in_group("weapons"):
        handle_weapon_pickup(item_name)

func _on_item_body_exited(item_name: String, body):
    if body != self:
        return
        
    var obj = get_node("/root/Game/Pickups/%s" % item_name)
    if not obj:
        return
    if obj.is_in_group("weapons"):
        # if the player walks away from the weapon, it's fair game to pick back up now
        recently_dropped_weapon = false
