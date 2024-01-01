extends Node


func spawn_mob():
    var new_mob = preload("res://scenes/mob.tscn").instantiate()
    
    # find a random step along the path
    %PathFollow2D.progress_ratio = randf()
    new_mob.global_position = %PathFollow2D.global_position
    
    add_child(new_mob)


func _on_enemy_spawn_timer_timeout():
    spawn_mob()
