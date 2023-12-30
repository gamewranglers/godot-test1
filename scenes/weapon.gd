extends Area2D


var weapon_type = "UNK"

# base properties
var damage = 10
var weapon_range = 50


signal item_body_entered(item_name, body)
signal item_body_exited(item_name, body)


func _ready():
    add_to_group("weapons")

    connect("body_entered", _on_body_entered)
    connect("body_exited", _on_body_exited)
    # check if player is loaded and connect signals dynamically
    var player = get_node("/root/Game/Player")
    if player:
        connect("item_body_entered", player._on_item_body_entered)
        connect("item_body_exited", player._on_item_body_exited)


# extend body_entered/_exited to provide item name
func _on_body_entered(body):
    emit_signal("item_body_entered", name, body)

func _on_body_exited(body):
    emit_signal("item_body_exited", name, body)
