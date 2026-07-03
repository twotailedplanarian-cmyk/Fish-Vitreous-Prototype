extends AnimatedSprite2D

@onready var animated_sprite_2d: AnimatedSprite2D = $"."

func change_to_animation1():
	animated_sprite_2d.play("Animation1")
	await animated_sprite_2d.animation_finished

func change_to_animation2():
	animated_sprite_2d.play("Animation2")
	await animated_sprite_2d.animation_finished
