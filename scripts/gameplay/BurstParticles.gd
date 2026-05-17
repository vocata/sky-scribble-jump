extends Node2D
class_name BurstParticles

const SPARKLE_TEXTURE := preload("res://assets/art/effects/sparkle.png")

var particles: Array[Sprite2D] = []


func clear_particles() -> void:
	for particle in particles:
		if is_instance_valid(particle):
			particle.queue_free()
	particles.clear()


func spawn_burst(origin: Vector2, rng: RandomNumberGenerator, amount: int = 10, force: float = 1.0) -> void:
	for i in amount:
		var dot := Sprite2D.new()
		dot.texture = SPARKLE_TEXTURE
		dot.position = origin
		dot.rotation = rng.randf_range(0.0, TAU)
		dot.scale = Vector2.ONE * rng.randf_range(0.45, 1.05) * force
		dot.z_index = 30
		add_child(dot)
		dot.set_meta("velocity", Vector2(rng.randf_range(-120.0, 120.0), rng.randf_range(-180.0, -30.0)) * force)
		dot.set_meta("life", rng.randf_range(0.35, 0.7))
		particles.append(dot)


func update_particles(delta: float, gravity: float) -> void:
	for index in range(particles.size() - 1, -1, -1):
		var dot: Sprite2D = particles[index]
		if not is_instance_valid(dot):
			particles.remove_at(index)
			continue

		var velocity: Vector2 = dot.get_meta("velocity")
		var life: float = dot.get_meta("life")
		velocity.y += gravity * 0.45 * delta
		life -= delta
		dot.position += velocity * delta
		dot.rotation += delta * 5.0
		dot.modulate.a = clamp(life * 2.2, 0.0, 1.0)
		dot.set_meta("velocity", velocity)
		dot.set_meta("life", life)

		if life <= 0.0:
			dot.queue_free()
			particles.remove_at(index)
