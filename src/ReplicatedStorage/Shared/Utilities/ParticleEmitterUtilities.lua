local ParticleEmitterUtilities = {}

function ParticleEmitterUtilities.Activate(emitter)
	if emitter:GetAttribute("EmitCount") then
		ParticleEmitterUtilities.Emit(emitter)
	else
		ParticleEmitterUtilities.Enable(emitter)
	end
end

function ParticleEmitterUtilities.Deactivate(emitter)
	emitter:Clear()
	emitter.Enabled = false
end

function ParticleEmitterUtilities.Emit(emitter)
	local emitCount = emitter:GetAttribute("EmitCount")
	emitter:Emit(emitCount)
end

function ParticleEmitterUtilities.Toggle(emitter)
	emitter.Enabled = not emitter.Enabled
end

function ParticleEmitterUtilities.Enable(emitter)
	emitter.Enabled = true
end

function ParticleEmitterUtilities.EnableFor(emitter, t)
	emitter.Enabled = true
	return task.delay(t, function()
		emitter.Enabled = false
	end)
end

return ParticleEmitterUtilities
