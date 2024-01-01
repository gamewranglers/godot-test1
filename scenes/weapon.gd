extends Area2D


var weapon_type = "UNK"
var facing_left = false

var is_attacking = false

# base properties
var damage = 1
var knockback_amount = 0

# attack transform properties / movement per frame
var attack_speed = 150
var attack_progress = 0
var attack_progress_max = 50


signal item_body_entered(item_name, body)
signal item_body_exited(item_name, body)


func _ready():
    add_to_group("weapons")

    connect("body_entered", _on_body_entered)
    connect("body_exited", _on_body_exited)
    # check if player is loaded and connect signals dynamically
    var player = get_node("/root/Game/Player")
    if player:
        # this would only be null if a weapon spawned before the player node, which shouldn't happen
        connect("item_body_entered", player._on_item_body_entered)
        connect("item_body_exited", player._on_item_body_exited)
        
    # called by subscenes to update properties and handle other behavior
    # without overwriting (and breaking) `_ready()`
    _post_ready()

func _post_ready():
    # overwrite this in subscenes
    pass

# extend body_entered/_exited to provide item name
func _on_body_entered(body):
    emit_signal("item_body_entered", name, body)

func _on_body_exited(body):
    emit_signal("item_body_exited", name, body)


func attack():
    is_attacking = true
    attack_progress = 0


func hit():
    # TODO: add some randomness and hit/miss stats
    return damage


func knockback():
    return knockback_amount
