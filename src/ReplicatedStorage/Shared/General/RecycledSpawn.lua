local freeThread: thread? -- Thread reusage

local function Passer(fn: (...unknown) -> (), ...): ()
	local acquiredThread = freeThread
	freeThread = nil
	fn(...)
	freeThread = acquiredThread
end

local function Yielder(): ()
	while true do
		Passer(coroutine.yield())
	end
end

return function(fn: (...any) -> (), ...): ()
	if freeThread == nil then
		freeThread = coroutine.create(Yielder)
		task.spawn(freeThread :: thread)
	end
	task.spawn(freeThread :: thread, fn, ...)
end
