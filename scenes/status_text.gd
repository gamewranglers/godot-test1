extends Node2D


var display_time_sec = 0.3

var horizontal_adjustment = 0
var vertical_adjustment = -10


func start(
    msg: String,
    start_position: Vector2,
    color: Color = Color.WHITE,
    size: float = 1.0,
    _status_kind: String = "damage",
):
    # set starting values
    %Label.text = msg
    position = start_position
    scale = Vector2(size, size)
    %Label.add_theme_color_override("font_color", color)
    
    # set up tween to transition position/opacity
    var tween = get_parent().create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
    
    # animate upward movement with some jitter
    var end_position = start_position + Vector2(
        horizontal_adjustment + randi_range(-10, 10), 
        vertical_adjustment + randi_range(-10, 10)
    )
    tween.tween_property(self, "position", end_position, display_time_sec).set_ease(Tween.EASE_OUT)
    
    # fade opacity to zero
    tween.tween_property(%Label, "modulate:a", 0, display_time_sec).set_ease(Tween.EASE_IN)
    
    # get smaller
    tween.tween_property(%Label, "scale", Vector2(1.0, 1.0), display_time_sec).set_ease(Tween.EASE_OUT)
    
    # self-destruct once it's done
    tween.tween_callback(self.queue_free)  
