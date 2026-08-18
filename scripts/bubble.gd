extends GPUParticles2D

func _ready():
	self.emitting = false

func _process(delta):
	await get_tree().create_timer(2.0).timeout
	self.emitting = true
	await get_tree().create_timer(1.0).timeout
	self.emitting = false
	await get_tree().create_timer(25.0).timeout
	self.emitting = true
	await get_tree().create_timer(1.0).timeout
	self.emitting = false
