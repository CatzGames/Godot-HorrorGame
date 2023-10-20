# extendsは現在のクラスで拡張するクラスを定義。
extends CharacterBody3D

#******* 変数 *******#
@onready var camera = $Camera3D
@onready var origCamPos : Vector3 = camera.position
@onready var floorcast = $FloorDetectRayCast
@onready var player_footstep_sound = $PlayerFootstepSound
@onready var interact_cast = $Camera3D/InteractRayCast

#ここでマウスのセンサーを変数宣言
var mouse_sens := 0.15

#これはプレイヤーの方向入力検知
var direction
var isRunning := false
#プレイヤーの移動速度
var speed := 2.1
#ジャンプ力ゥ...ですかねぇ...
var jump := 0.0
#これは重力
const Gravity = 1.5
var playFootStep := 5 #音を早く再生したいなら数値を低くする
var distanceFootstep := 0.0


var _delta := 0.0
var camBobSpeed := 10 #10
var camBobUpDown := .5 #.5

#関数(C#でいうclass)を定義し、_ready():はGodotが決めたタイミングで自動的に呼ばれる関数。
func _ready():
	#Input.set_mouse_modeはマウスの状態を変化させる。
	#MOUSE_MODE_CAPTUREDは非表示かつゲーム画面から出ないようにする。
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#プレイヤーの物体が見えなくなるようにする
	$MeshInstance3D.visible = false


func _input(event):
	#カメラが動く
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	if Input.is_action_just_pressed("run"):
		isRunning = true
	if Input.is_action_just_released("run"):
		isRunning = false
	
	if Input.is_action_just_pressed("interact"):
		var interacted = interact_cast.get_collider()
		if interacted != null and interacted.is_in_group("Interactable") and interacted.has_method("action_use"):
			interacted.action_use()

#カメラで呼吸の動きを表す
func _process(delta):
	process_camBob(delta)
	
	if floorcast.is_colliding():
		var walkingTerrain = floorcast.get_collider().get_parent()
		if walkingTerrain != null and walkingTerrain.get_groups().size() > 0:
			var terrainggroup = walkingTerrain.get_groups()[0]
			processGroundSounds(terrainggroup)


func processGroundSounds(group : String):
	#プレイヤーが走っているかしゃがんでいるかに応じて、サウンドを速く、または遅く再生する。
	if isRunning:
		playFootStep = 2.5
	else:
		playFootStep = 4
	
	
	if playFootStep != 100 and (int(velocity.x) != 0) || int(velocity.z) != 0:
		distanceFootstep +=.1
		
		if distanceFootstep > playFootStep and is_on_floor():
			match group:
				"WoodTerrain":
					player_footstep_sound.stream = load("res://Player/SoundsFootsteps/wood/1.ogg")
				"Grass":
					player_footstep_sound.stream = load("res://Player/SoundsFootsteps/grass/1.ogg")
			
			player_footstep_sound.pitch_scale = randf_range(.8,1.2)
			player_footstep_sound.play()
			distanceFootstep = 0.0

	#print(floorcast.get_collider())

#キャラクターの操作のスクリプトが書かれている
func _physics_process(delta):
	process_movement(delta)

func process_movement(delta):
	direction = Vector3.ZERO
	
	var h_rot = global_transform.basis.get_euler().y
	
	#Ui leftのアクション強度を取得することによってdirection.xの値が0になる(-1と1の間)
	direction.x = -Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
	direction.z = -Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	direction = Vector3(direction.x,0,direction.z).rotated(Vector3.UP,h_rot).normalized()

	var actualSpeed = speed if !isRunning else speed * 1.8
	velocity.x = direction.x * actualSpeed
	velocity.z = direction.z * actualSpeed
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump
		
	if !is_on_floor():
		velocity.y -= Gravity
	
	move_and_slide()

#Cameraの動き
func process_camBob(delta):
	_delta += delta
	
	var cam_bob #Speed
	var objCam #カメラの上下の移動量
	
	if isRunning:
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed * 1.5
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
		
	elif direction != Vector3.ZERO: #プレイヤーが動いている時
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
	else: #プレイヤーが動いていない時
		cam_bob = floor(abs(1) + abs(1)) * _delta * .8
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown * .1
	
	camera.position = camera.position.lerp(objCam,delta)
