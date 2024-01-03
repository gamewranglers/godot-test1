extends CharacterBody2D

# settings
@export var AUTO_ATTACK = false

# player basics
@onready var player_sprite = $Sprite2D

@export var is_dead = false
var level = 1
var experience = 0
var experience_to_next_level = 100

# player stats
var health_points = 100
var max_health_points = 100

var strength = 5.0
var dexterity = 5.0

var armor = 1.0

var movement_speed = 200.0

# primary attack state + cooldown
var attacking = false
var last_attack_time = 0
var attack_cooldown_sec = 0.35
@export var KNOCKBACK_MODIFIER = 1.0

# pickup/drop weapon info
var held_weapon = null
var recently_dropped_weapon = false

# general positioning
var facing_left = false
@export var EQUIPMENT_OFFSET_X = 8
@export var EQUIPMENT_OFFSET_Y = -5
@export var EQUIPMENT_ROTATION = 15
@export var HELD_ITEM_SCALE = 0.8
@export var HELD_WEAPON_RANGE_SCALE = 1.0

var status_text_scene = preload("res://scenes/status_text.tscn")


func _physics_process(delta: float):    
    update_health_bars()
    
    if is_dead:
        player_sprite.modulate = Color.DARK_RED
        return
    
    handle_movement(delta)
    
    adjust_held_weapon()
    adjust_attack_range()

    if AUTO_ATTACK:
        attack()
    else:
        handle_attack_input()
    handle_enemy_damage()


func update_health_bars():
    # over the player sprite
    %HealthBar.value = health_points
    %HealthBar.max_value = max_health_points
    if health_points < max_health_points and not is_dead:
        # display the health bar over the player if any damage was taken
        %HealthBar.visible = true
    else:
        %HealthBar.visible = false

    # in the UI
    var ui_health_bar = get_node("/root/Game/UI/HealthBar/PlayerHealthBar")
    ui_health_bar.value = health_points
    ui_health_bar.max_value = max_health_points
    var ui_health_bar_values = get_node("/root/Game/UI/HealthBar/PlayerHealthValues")
    ui_health_bar_values.text = "%s/%s" % [health_points, max_health_points]
    
            
func handle_movement(delta):
    # check for vertical movement
    var direction_y = Input.get_axis("move_up", "move_down")
    if direction_y:
        velocity.y = direction_y * movement_speed
    else:
        velocity.y = move_toward(velocity.y, 0, movement_speed)
        
    # check for horizontal movement
    var direction_x = Input.get_axis("move_left", "move_right")
    if direction_x:
        velocity.x = direction_x * movement_speed
        # toggle facing right/left based on last movement direction
        facing_left = velocity.x < 0
    else:
        velocity.x = move_toward(velocity.x, 0, movement_speed)

    move_and_slide()
    
    # if the player last moved left, make sure they stay facing left
    # if the player last moved right, make sure they stay facing right
    player_sprite.flip_h = facing_left
    
    if held_weapon:
        held_weapon.facing_left = facing_left
    

func handle_attack_input():
    if Input.is_action_just_pressed("primary_attack"):
        attacking = true
    elif Input.is_action_just_released("primary_attack"):
        attacking = false
        
    if attacking:
        attack()


func attack():
    var attack_off_cooldown = Time.get_ticks_msec() - last_attack_time > attack_cooldown_sec * 1000
    if not attack_off_cooldown:
        return
        
    if held_weapon != null:
        # reset any current attack animation before re-triggering
        %WeaponPivotPoint.rotation_degrees = 0
        held_weapon.attack()
        
        var enemies_in_range = %AttackRange.get_overlapping_bodies()
        # TODO: determine whether player is attacking one enemy or multiple
        for enemy in enemies_in_range:
            enemy.take_knockback(held_weapon.knockback() * KNOCKBACK_MODIFIER)
            var hit_damage = calculate_hit_damage(held_weapon.damage)
            if hit_damage:
                var experience_gained = enemy.take_damage(hit_damage)
                add_experience(experience_gained)

    last_attack_time = Time.get_ticks_msec()


func calculate_hit_damage(weapon_damage):
    # TODO: make this better if dexterity is going to increase on level_up
    var miss_chance = (100.0 - dexterity) / 100.0
    var chance_to_hit = randf()
    #print("miss_chance: %s, chance_to_hit: %s" % [miss_chance, chance_to_hit])
    if miss_chance < chance_to_hit:
        show_damage_text("Miss")
        return 0
        
    var strength_adjustment = 1.0 + (strength / 100.0)
    #print("strength_adjustment: %s" % strength_adjustment)
    return weapon_damage * strength_adjustment


func show_damage_text(
    msg: String, 
    color: Color = Color.WHITE,
    duration: float = 0.3,
    size: float = 1.0,
    persist: bool = false,
):
    var popup = status_text_scene.instantiate()
    popup.display_time_sec = duration
    get_parent().add_child(popup)
    popup.start(msg, global_position, color, size, persist)
    

func add_experience(xp: int):
    if xp <= 0:
        return
    
    experience += xp
    if experience >= experience_to_next_level:
        level_up()
        
    var ui_xp_bar = get_node("/root/Game/UI/XPBar/PlayerXPBar")
    ui_xp_bar.value = experience
    ui_xp_bar.max_value = experience_to_next_level
    var ui_xp_bar_values = get_node("/root/Game/UI/XPBar/PlayerXPValues")
    ui_xp_bar_values.text = "%s/%s" % [experience, experience_to_next_level]
        
        
func level_up():
    show_damage_text("Level Up!", Color.AQUAMARINE, 1.5, 2.0)
    
    level += 1
    # also update level indicator
    var ui_level_text = get_node("/root/Game/UI/PlayerLevelLabel")
    ui_level_text.text = "LVL %s" % level
    
    # reset experience and increase amount to next level
    experience = 0
    experience_to_next_level = int(experience_to_next_level * 1.5)
    
    # replenish health
    max_health_points += 5.0
    health_points = max_health_points
    
    # stronger attacks!
    strength += 5.0
    # faster attacks!
    attack_cooldown_sec *= 0.95
    # longer range!
    HELD_ITEM_SCALE += 0.25
    # bigger weapon!
    EQUIPMENT_OFFSET_X += 1
    EQUIPMENT_OFFSET_X += 1
    HELD_WEAPON_RANGE_SCALE += 0.05
    # longer knockbacks!
    KNOCKBACK_MODIFIER += 0.2
    if held_weapon:
        held_weapon.scale = Vector2(HELD_ITEM_SCALE, HELD_ITEM_SCALE)
    
    # spawn enemies faster
    var enemy_spawner = get_node("/root/Game/EnemySpawner/EnemySpawnTimer")
    enemy_spawner.wait_time *= 0.95
    #print("enemy_spawner.wait_time: %s" % enemy_spawner.wait_time)
    
    # spawn more enemies
    var game_node = get_node("/root/Game")
    game_node.spawn_rate += 1
    #print("game_node.spawn_rate: %s" % game_node.spawn_rate)

    
    
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
        %AttackRange.scale = Vector2(
            held_weapon.attack_range * HELD_WEAPON_RANGE_SCALE,
            held_weapon.attack_range * HELD_WEAPON_RANGE_SCALE,
        )
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
    obj.scale = Vector2(HELD_ITEM_SCALE, HELD_ITEM_SCALE)
    
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
func handle_enemy_damage():
    var overlapping_enemies = %Hurtbox.get_overlapping_bodies()
    for enemy in overlapping_enemies:
        var damage_amount = enemy.hit()
        # check attack cooldown so player doesn't take rapid-fire damage
        var attack_off_cooldown = Time.get_ticks_msec() - enemy.last_attack_time > enemy.attack_cooldown_sec * 1000
        if attack_off_cooldown:
            take_damage(damage_amount)
            enemy.last_attack_time = Time.get_ticks_msec()

# ENEMY->PLAYER
func take_damage(damage_amount: int):
    player_sprite.modulate = Color.RED
    %HurtFlashTimer.start()
    
    show_damage_text(str(damage_amount), Color.RED)
    
    if health_points <= 0:
        # TODO: transition to some "game over" state
        game_over()
        return

    health_points -= damage_amount
    
    
func game_over():
    is_dead = true

    # disable attacking
    AUTO_ATTACK = false
    attacking = false
    
    # disable enemy spawning
    var game_node = get_node("/root/Game")
    game_node.spawn_rate = 0
    
    show_damage_text("DEATH", Color.DARK_RED, 1.5, 3.0, true)


# EFFECTS FROM UI
func _on_auto_attack_toggle_toggled(toggled_on):
    AUTO_ATTACK = toggled_on


func _on_hurt_flash_timer_timeout():
    if not is_dead:
        player_sprite.modulate = Color.WHITE

