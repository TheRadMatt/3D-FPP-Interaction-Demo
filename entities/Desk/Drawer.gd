
extends RigidBody

var can_change = true

var open = false

func interact(relate):
	if can_change:
		can_change = false
		if open:
			open = false
			get_node("../../anim").play_backwards("slide")
		else:
			get_node("../../anim").play("slide")
			open = true

func _on_anim_animation_finished(anim_name):
	can_change = true
