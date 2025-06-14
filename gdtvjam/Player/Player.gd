extends CharacterBody2D
class_name player

#region variables
@export var movement_speed: float = 175
@export var push_strength: float = 400

@export var normal_tiles: TileMapLayer
@export var shrunk_tiles: TileMapLayer

@export var feedback_dialogue: DialogueResource
@export var animation_player: AnimationPlayer

@onready var camera: Camera2D = %Camera
@onready var shrink_sfx: AudioStreamPlayer2D = $ShrinkSFX
@onready var grow_sfx: AudioStreamPlayer2D = $GrowSFX

var block_is_child: bool = false

var is_zoomed_out: bool = false

var default_movement_speed: float
#endregion

func _ready() -> void:
	default_movement_speed = movement_speed
	if GameManager.room_reset and GameManager.first_room_reset:
		GameManager.first_room_reset = false
		DialogueManager.show_example_dialogue_balloon(feedback_dialogue, "LevelReset")
	

#region Move Block
func _physics_process(_delta: float) -> void:
	check_collision()

func check_collision() -> void:
	var collision: KinematicCollision2D = get_last_slide_collision()

	if (collision):
		var block = collision.get_collider()
		if (block.is_in_group("block")):
			move_block(block, collision)

func move_block(block: Object, collision: KinematicCollision2D) -> void:
		push_pushable(block, collision)


func push_pushable(pushable: RigidBody2D, collision: KinematicCollision2D):
	pushable.apply_central_force(-collision.get_normal() * push_strength)
#endregion
#region Tile Map Checker

func _process(_delta: float) -> void:
	if normal_tiles or shrunk_tiles:
		check_normal_tiles()
	if (GameManager.current_player_size == GameManager.character_size.NORMAL):
		set_physics_process(true) #Able to push the damn block
	else:
		set_physics_process(false) #Unable to push the damn block
	
	adjust_player()

func check_normal_tiles() -> void:
	var normal_cell := normal_tiles.local_to_map(position)
	var normal_data: TileData = normal_tiles.get_cell_tile_data(normal_cell)
	var shrunk_cell := shrunk_tiles.local_to_map(position)
	var shrunk_data: TileData = shrunk_tiles.get_cell_tile_data(shrunk_cell)
	
	var walkable: bool = normal_data.get_custom_data("walkable") if normal_data != null else false
	var shrink_tile: bool = normal_data.get_custom_data("shrink_tile") if normal_data != null else false
	var grow_tile: bool = normal_data.get_custom_data("grow_tile") if normal_data != null else false
	var walkable_small: bool = shrunk_data.get_custom_data("walkable_small") if shrunk_data != null else false
	
	#Too Big
	if ((walkable_small && GameManager.current_player_size == GameManager.character_size.NORMAL)):
		reset_level()
		return
	#Not Walkable Period
	if(walkable_small && GameManager.current_player_size == GameManager.character_size.SMALL): 
		return
	if (!walkable):
		#DialogueManager.show_example_dialogue_balloon(feedback_dialogue, "NotWalkable")
		reset_level()
		return
	if (shrink_tile && GameManager.current_player_size == GameManager.character_size.NORMAL):
		if GameManager.first_shrink:
			GameManager.first_shrink = false
			DialogueManager.show_example_dialogue_balloon(feedback_dialogue, "Shrink")
		shrink_sfx.play()
		turn_on_shader()
		animation_player.play("shrink_animation")
		set_collision_mask_value(4, true) #Enables the small collision mask
		movement_speed = 100;
		GameManager.current_player_size = GameManager.character_size.SMALL
		return
	if (grow_tile && GameManager.current_player_size == GameManager.character_size.SMALL):
		if GameManager.first_grow:
			GameManager.first_grow = false
			DialogueManager.show_example_dialogue_balloon(feedback_dialogue, "Grow")
		grow_sfx.play()
		animation_player.play("grow_animation")
		set_collision_mask_value(4, false)
		movement_speed = default_movement_speed;
		GameManager.current_player_size = GameManager.character_size.NORMAL
		return
		
func _input(_event: InputEvent) -> void:
	if (Input.is_action_pressed("zoom_out")):
		is_zoomed_out = true
		GameManager.is_zoomed = true
	if (Input.is_action_just_released("zoom_out")):
		is_zoomed_out = false
		GameManager.is_zoomed = false

func adjust_player() -> void:
	if animation_player.is_playing():
		return
	if (GameManager.current_player_size == GameManager.character_size.SMALL && is_zoomed_out):
		camera.zoom = Vector2(2, 2)
	elif (GameManager.current_player_size == GameManager.character_size.SMALL):
		camera.zoom = Vector2 (6, 6)
		scale = Vector2(0.1, 0.1)
	elif (GameManager.current_player_size == GameManager.character_size.NORMAL):
		camera.zoom = Vector2.ONE
		scale = Vector2.ONE

func reset_level(death_type:GameManager.death_type = GameManager.death_type.NONE) -> void:
	if (death_type != GameManager.death_type.NONE):
		pass
	AudioManager.rewind_sfx.play()
	GameManager.room_reset = true
	get_tree().call_deferred("reload_current_scene")

func cant_move() -> void:
	GameManager.can_move = false

func can_move() -> void:
	GameManager.can_move = true

func turn_on_shader() -> void:
	$Sprite.material.set_shader_parameter("distortion_strength",0.018)

func turn_off_shader() -> void:
	$Sprite.material.set_shader_parameter("distortion_strength",0.0)
#endregion
