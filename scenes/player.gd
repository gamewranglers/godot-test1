extends CharacterBody2D


@export var PLAYER_SPEED = 200.0

@export var EQUIPMENT_ROTATION = 15
@export var EQUIPMENT_OFFSET_X = 8

@onready var player_sprite = $Sprite2D


var facing_left = false
var holding_axe = false
    

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
    
    # TODO: check for other items
    if holding_axe:
        # double size of attack range
        attack_range.scale = Vector2(2.0, 2.0)
        
        # adjust position/rotation based on facing left/right
        var axe = get_node("./Axe")
        var adjustment = -1 if facing_left else 1
        axe.position = Vector2(EQUIPMENT_OFFSET_X * adjustment, 0)
        axe.rotation_degrees = EQUIPMENT_ROTATION * adjustment
    else:
        # reset the attack range size
        attack_range.scale = Vector2(1.0, 1.0)
        
        
func reparent_item_to_player(obj):
    # remove from current parent node
    obj.get_parent().remove_child(obj)
    # add as child of player node
    add_child(obj)


# unused for now, will be used for dropping items
func orphan_item_from_player(obj):
    # remove as child of player node
    remove_child(obj)
    # add as child of pickups node
    var pickups = get_node("../Pickups")
    pickups.add_child(obj)


func _on_axe_body_entered(body: PhysicsBody2D):
    if holding_axe:
        return
        
    if body == self:
        # TODO: abstract this so we can handle other equipment pickups
        print("player is picking up the axe!")
        var axe: Area2D = get_node("../Pickups/Axe")
        reparent_item_to_player(axe)
        # reposition the axe to the right of the player, scale it down slightly, and rotate it
        # to give off the illusion that the player is "holding" it
        axe.position = Vector2(8, 0)
        axe.scale = Vector2(0.75, 0.75)
        axe.rotation_degrees = 15
        axe.set_as_top_level(false)
        # prevent these checks from happening after pickup
        holding_axe = true
    else:
        print("uh oh, something else is picking up the axe!")
        # TODO: handle other creatures picking up the axe


func _on_attack_range_body_entered(body):
    if body.is_in_group("enemies"):
        print(body.name, " in attacking range! 🪓")


func _on_attack_range_body_exited(body):
    if body.is_in_group("enemies"):
        print(body.name, " no longer in attack range")
