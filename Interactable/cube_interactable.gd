extends Interactable


# Called when the node enters the scene tree for the first time.
func action_use():
	$MeshInstance3D.scale += Vector3(1,1,1)
