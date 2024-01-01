extends "res://scenes/weapon.gd"


func _process(delta):
    if is_attacking:
        var rotation_step = attack_speed * delta 
        
        var weapon_pivot = get_node("/root/Game/Player/WeaponPivotPoint")
        if facing_left:
            weapon_pivot.rotation_degrees -= rotation_step * 10
        else:
            weapon_pivot.rotation_degrees += rotation_step * 10
        
        attack_progress += abs(rotation_step)
        if attack_progress >= attack_progress_max:
            is_attacking = false
            # reset position
            weapon_pivot.rotation_degrees = 0
