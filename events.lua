
local addon, ns = ...
local frame = CreateFrame("Frame")
local type,ipairs,tremove = type,ipairs,tremove
local events = {}

function ns.event(event,name,func)
	if func then
		local functions = events[event]
		if not functions then
			functions = {}
			events[event]=functions
			frame:RegisterEvent(event)
		end
		tinsert(functions,{name=name,func=func})
	elseif name then
		for index, entry in ipairs(events[event]) do
			if entry.name == name then
				tremove(events[event],index)
				break
			end
		end
		if #events[event]==0 then
			frame:UnregisterEvent(event)
			events[event]=nil
		end
	end
end

frame:SetScript("OnEvent",function(_,event,...)
	if type(events[event])=="table" then
		for _, entry in ipairs(events[event]) do
			entry.func(...)
			if entry.deleteMe then
				ns.event(event,entry.name)
			end
		end
	end
end)
