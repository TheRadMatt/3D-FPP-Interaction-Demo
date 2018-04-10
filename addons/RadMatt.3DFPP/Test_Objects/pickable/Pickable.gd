
extends RigidBody

var picked_up

var holder

func pick_up(player):
	holder = player

	if picked_up:
		leave()
	else:
		carry()

func _process(delta):
	if picked_up:
		set_global_transform(holder.get_node("Yaw/Camera/pickup_pos").get_global_transform())

func carry():
	$CollisionShape.set_disabled(true)
	holder.carried_object = self
	self.set_mode(1)
	picked_up = true

func leave():
	$CollisionShape.set_disabled(false)
	holder.carried_object = null
	self.set_mode(0)
	picked_up = false



func throw(power):
	leave()
	apply_impulse(Vector3(), holder.look_vector * Vector3(power, power, power))
