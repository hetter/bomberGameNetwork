local eventDispatcher = inherit(nil, gettable("BM_EventDispatcher"));

function eventDispatcher:ctor()
	self._listener = {};
	
	-- 用来生成句柄的自增标识符
	self._GUID = 1;
end

function eventDispatcher:hasEvent(eventName)
	return self._listener[eventName] and true or false;
end

--[[
	@local function handleFunc(eventName, data)
	@	return true/false;  -- 返回后自动取消监听/返回后继续监听
	@end
	
	@return 监听句柄
]]
function eventDispatcher:addListener(eventName, handleFunc)
	local l = self._listener[eventName];
	
	if not l then
		l = {};
		self._listener[eventName] = l;
	end
	
	local handle = self._GUID;
	self._GUID = handle + 1;
	l[handle] = handleFunc;
	
	return handle;
end

-- 取消监听
-- @handleToRemove 监听句柄
-- @eventName 可为空， 不为空时效率高一点
function eventDispatcher:removeListener(handleToRemove, eventName)
	if eventName then
		local listenersForEvent = self._listener[eventName]
		if listenersForEvent then
			if listenersForEvent[handleToRemove] then
				listenersForEvent[handleToRemove] = nil;
				local k, v = next(listenersForEvent);
				if not k then
					self._listener[eventName] = nil;
				end
			end
		end
	else

		for eventName, listenersForEvent in pairs(self._listener) do 
			if listenersForEvent[handleToRemove] then
				listenersForEvent[handleToRemove] = nil;
				local k, v = next(listenersForEvent);
				if not k then
					self._listener[eventName] = nil;
				end
				
				return;
			end
		end
	end
end

-- 派发消息
-- @param ... : 原封不动的传给listener
function eventDispatcher:dispatchEvent(eventName, ...)

	local param = {...}
	local l = self._listener[eventName];
	if not l then
		return;
	end
	local removeList = {};
		
	for handle, listener in pairs(l) do
		local bRemove =  listener(eventName, unpack(param));
			
		if bRemove then
			table.insert(removeList, handle);
		end
	end
		
	for k, v in pairs(removeList) do
		l[v] = nil;
	end
	
	if not next(l) then
		self._listener[eventName] = nil;
	end
end

gDispatcher = eventDispatcher.new();
