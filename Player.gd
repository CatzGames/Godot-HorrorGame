# extendsは現在のクラスで拡張するクラスを定義。
extends CharacterBody3D

#******* 変数 *******#
@onready var camera = $Camera3D
@onready var origCamPos : Vector3 = camera.position
@onready var floorcast = $FloorDetectRayCast

#ここでマウスのセンサーを変数宣言
var mouse_sens := 0.15
#これはプレイヤーの方向入力検知
var direction
#プレイヤーの移動速度
var speed := 2.8
#ジャンプ力ゥ...ですかねぇ...
var jump := 10.0
#これは重力
const Gravity = 1.5

var _delta := 0.0
var camBobSpeed := 7 #10
var camBobUpDown := .5 #.5

#関数(C#でいうclass)を定義し、_ready():はGodotが決めたタイミングで自動的に呼ばれる関数。
func _ready():
	#Input.set_mouse_modeはマウスの状態を変化させる。
	#MOUSE_MODE_CAPTUREDは非表示かつゲーム画面から出ないようにする。
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#プレイヤーの物体が見えなくなるようにする
	$MeshInstance3D.visible = false


func _input(event):
	#モーション情報を取得する
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

#カメラで呼吸の動きを表す
func _process(delta):
	process_camBob(delta)
	
	if floorcast.is_colliding():
		var walkingTerrain = floorcast.get_collider().get_parent()
		if walkingTerrain != null:
			var terrainggroup = walkingTerrain.get_groups()[0]
			print(terrainggroup)
			
			
			
	
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
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump
		
	if !is_on_floor():
		velocity.y -= Gravity
	
	move_and_slide()

func process_camBob(delta):
	_delta += delta
	
	var cam_bob #Speed
	var objCam #カメラの上下の移動量
	if direction != Vector3.ZERO: #プレイヤーが動いている時
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
	else: #プレイヤーが動いていない時
		cam_bob = floor(abs(1) + abs(1)) * _delta * .8
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown * .1
	
	camera.position = camera.position.lerp(objCam,delta)
