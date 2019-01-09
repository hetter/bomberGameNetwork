include("npl/global.lua");

local Logic = inherit(nil, gettable("BM_GameLogic"));
local actionHost = gettable("BM_ActionHost");
local actions = gettable("BM_Actions");

function Logic:ctor()
	self._state = nil;
	self._bRun = true;
	
	self._actionHost = actionHost.new();
end

function Logic:changeState(state)
	
	
	local old = self._state;
		
	if old then
		old:onExit();
	end
		
	state:onEnter();
	self._state = state;
end

function Logic:getCurrentState()
	return self._state;
end

function Logic:stop()
	self._bRun = false;
	if self._state then
		self._state:onExit();
	end
end

function Logic:run()
	local currentTime = g_getTimer();
	local oldTime;
	while(self._bRun) do
		oldTime = currentTime;
		currentTime = g_getTimer();
		self._state:update(currentTime - oldTime);
		self._actionHost:update();
		g_waitOneFrame();
	end
end

function Logic:runAction(action)
	self._actionHost:runAction(action);
end

-- 在下一帧运行
function Logic:runOnNextFrame(cb)
	local delayTime = actions.DelayTime:create(0.01);
	local callFunction = actions.CallFunction:create(cb);
	action = actions.Sequence:create(delayTime, callFunction);
	self:runAction(action);
end

-- 监听n次网络事件， 直到超时， 如果超时或者次数执行完了则直接调用cb(false)
function Logic:addNetListener(eventName, cb, times, timeOut)
	timeOut = timeOut or 5;
	times = times or 1;
	
	local handle;
	local action;
	local function _cb(eventName, ...)
		cb(true, unpack{...});
		times = times - 1;
		
		if times == 0 then
			action:stop();
			cb(false);
			return true;
		else
			return false;
		end
	end
	
	handle = gNetworkDispatcher:addListener(eventName, _cb);
	
	local function onTimeout()
		gNetworkDispatcher:removeListener(handle, eventName);
		cb(false);
	end
	
	local delayTime = actions.DelayTime:create(timeOut);
	local callFunction = actions.CallFunction:create(onTimeout);
	action = actions.Sequence:create(delayTime, callFunction);
	self:runAction(action);
end


gLogic = Logic.new();