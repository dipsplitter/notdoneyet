model = game.Workspace.LostTemple
messageText = "Regenerating Lost Temple..."

message = Instance.new("Message")
message.Text = messageText
backup = model:clone()

while true do
	wait(script.Parent.RegenerationTime.Value*(1-math.random()*0.8))

	message.Parent = game.Workspace
	model:remove()

	wait(script.Parent.RegenerationDelay.Value)

	model = backup:clone()
	model.Parent = game.Workspace
	model:makeJoints()
	message.Parent = nil
end
