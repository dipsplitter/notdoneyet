--[[
	Thanks Quenty
]]

local freeRunnerThread = nil

local function AcquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	-- The handler finished running, this runner thread is free again.
	freeRunnerThread = acquiredRunnerThread
end

local function RunEventHandlerInFreeThread(...)
	AcquireRunnerThreadAndCallEventHandler(...)
	while true do
		AcquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local function IsValidTask(taskToCleanup)
	if type(taskToCleanup) == "function" then
		return true
	elseif typeof(taskToCleanup) == "RBXScriptConnection" or typeof(taskToCleanup) == "Instance" then
		return true
	elseif type(taskToCleanup) == "table" then
		
		if type(taskToCleanup.Destroy) == "function" or type(taskToCleanup.Disconnect) == "function" then
			return true
		end
		
	end
	
	warn(`Invalid task: {taskToCleanup}`)
	return false
end

local function CleanupTask(taskToCleanup, ...)
	if type(taskToCleanup) == "function" then
		taskToCleanup(...)
	elseif typeof(taskToCleanup) == "RBXScriptConnection" then
		taskToCleanup:Disconnect()
	elseif typeof(taskToCleanup) == "Instance" then
		taskToCleanup:Destroy()
	elseif type(taskToCleanup) == "table" then
		
		if type(taskToCleanup.Destroy) == "function" then
			taskToCleanup:Destroy()
		elseif type(taskToCleanup.Disconnect) == "function" then
			taskToCleanup:Disconnect()
		end
		
	end
end

local function PerformCleanupTask(...)
	if not freeRunnerThread then
		freeRunnerThread = coroutine.create(RunEventHandlerInFreeThread)
	end
	task.spawn(freeRunnerThread, CleanupTask, ...)
end

local Cleaner = {}
Cleaner.ClassName = "Cleaner"

function Cleaner.new()
	local self = setmetatable({
		Tasks = {},
	}, Cleaner)
	
	return self
end

function Cleaner:__index(index)
	if Cleaner[index] then
		return Cleaner[index]
	end
	
	return self.Tasks[index]
end

function Cleaner:__newindex(index, newTask)
	
	local oldTask = self.Tasks[index]
	
	if oldTask == newTask then
		return
	end
	
	if IsValidTask(newTask) then
		self.Tasks[index] = newTask
	end
	
	if oldTask then
		PerformCleanupTask(oldTask)
	end
	
end

function Cleaner:Add(newTask)
	if IsValidTask(newTask) then
		table.insert(self.Tasks, newTask)
	end
end

-- Can cleanup particular keys
function Cleaner:CleanupOne(taskToClean, ...)
	if type(taskToClean) == "string" then
		if self.Tasks[taskToClean] then
			self:RemoveCleanupTask(self.Tasks[taskToClean])
			PerformCleanupTask(self.Tasks[taskToClean], ...)
		end
	else
		self:RemoveCleanupTask(taskToClean)
		PerformCleanupTask(taskToClean, ...)
	end
end

function Cleaner:RemoveCleanupTask(taskToRemove)
	local tasks = self.Tasks
	
	for k, v in pairs(tasks) do
		if v == taskToRemove then
			self.Tasks[k] = nil
		end
	end
end

function Cleaner:CleanupAll(...)
	for k, taskToClean in pairs(self.Tasks) do
		PerformCleanupTask(taskToClean, ...)
	end
	
	self.Tasks = {}
end
Cleaner.Clean = Cleaner.CleanupAll

function Cleaner:Destroy(...)
	self:CleanupAll(...)
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return Cleaner
