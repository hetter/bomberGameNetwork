local base = inherit(nil, {});

function base:ctor()
		
end

function base:create(...)
	return self:new():init(...);
end

function base:stop()
	self._isStop = true;
end

function base:isStop()
	return self._isStop == true;
end

--[[ 这写函数是子类必须实现的函数
function base:clone()
	return nil;
end

function base:run()
	return false;
end

function base:init()
	return self;
end

]]


local delayTime = inherit(base, {});

function delayTime:init(t)
	self._t = t;
	return self;
end

function delayTime:clone()
	return delayTime:create(self._t);
end

function delayTime:run()
	if self._t <= 0 then
		return false;
	end
			
	if not self._endTime then
		self._endTime = getTimer() + self._t;
		return true;
	end
			
	return getTimer() < self._endTime;
end

local sequence = inherit(base, {});

function sequence:init(...)
	self._actions = {...};
	return self;
end


function sequence:push_actions(...)
	local arg = {...};
	for i, action in ipairs(arg) do
		table.insert(self._actions, action);
	end
end

function sequence:clone()
	local arg = {};
	for i, action in ipairs(self._actions) do
		table.insert(arg, action:clone());
	end
	
	-- luajit在unpack时定义跟lua5.1有区别， 用table.maxn统一2者的区别
	return sequence:create(unpack(self._actions, 1, table.maxn(self._actions)));
end


function sequence:run()
	if #self._actions == 0 then
		return false;
	else
		local action = self._actions[1];
				
		if not action:run() then
			table.remove(self._actions, 1);
		end
				
		return #self._actions > 0;
	end
end

local spawn = inherit(sequence, {});

function spawn:run()
	if #self._actions == 0 then
		return false;
	else
		local index = 1;
		local action;
		
		while(index <= #self._actions) do
			action = self._actions[index];
			if action:run() then
				index = index + 1;
			else
				table.remove(self._actions, index);
			end
		end
	
		return #self._actions > 0;
	end
end


local callFunction = inherit(base, {});

function callFunction:init(func)
	self._func = func;
	return self;
end


function callFunction:run()
	self._func();
	return false;
end

function callFunction:clone()
	return self;
end


local repeatAction = inherit(base, {});

-- times = 0xffffffff 为永久
function repeatAction:init(action, times)
	self._action = action;
	self._runAction = action:clone();
	self._times = times;
	self._curTimes = times;
	return self;
end

function repeatAction:run()
	if self._times == 0xffffffff then
		if not self._runAction:run() then
			self._runAction = self._action:clone();
		end
		
		return true;
	else
		if self._curTimes > 0 then
			if not self._runAction:run() then
				self._curTimes = self._curTimes - 1;
				if self._curTimes == 0 then
					return false;
				else
					self._runAction = self._action:clone();
					return true;
				end
			end
		else
			return false;
		end
	end
end


function repeatAction:clone()
	return repeatAction:create(self._action, self._times);
end


-- 内置的moveTo不支持绝对路径 而且很卡， 所以自己实现
local moveTo = inherit(base, {});

function moveTo:init(startPos, endPos, delay, setPosFunc)
	self._startPos = startPos;
	self._endPos = 	endPos;
	self._delay = delay;
	
	self._xdir = endPos.x - startPos.x;
	self._ydir = endPos.y - startPos.y;
	self._zdir = endPos.z - startPos.z;
	
	self._endTime = nil;
	
	self._setPosFunc =  setPosFunc or setPos;
	
	return self;
end

function moveTo:clone()
	return moveTo:create(self._startPos, self._endPos, self._delay, self._setPosFunc);
end

function moveTo:run()
	local endPos = self._endPos;

	if self._delay <= 0 then
		self._setPosFunc(endPos.x, endPos.y, endPos.z);
		return false;
	end
	
	local curTime = getTimer();
	local startPos = self._startPos;

	if not self._endTime then
		self._endTime = curTime + self._delay;
		self._setPosFunc(startPos.x, startPos.y , startPos.z);
		return true;
	end
	
	-- 跑完时间了
	if (curTime >= self._endTime) then
		self._setPosFunc(endPos.x, endPos.y, endPos.z);
		return false;
	end
	
	local per = 1 - ((self._endTime - curTime) / self._delay);
	
	local x = startPos.x + self._xdir * per;
	local y = startPos.y + self._ydir * per;
	local z = startPos.z + self._zdir * per;
	
	self._setPosFunc(x, y, z);
	
	return true;
end

local moveToActor = inherit(base, {});

function moveToActor:init(startPos, actor, delay, setPosFunc)
	local actorName = actor;
	if type(actorName) ~= "string" then
		actorName = actor:GetActorValue("name");
	else
		actor = getActor(actorName);
	end
	
	self._startPos = startPos;
	self._endPos = {x = actor:GetActorValue("x")
				, y = actor:GetActorValue("y")
				, z = actor:GetActorValue("y")};
				
	self._dstActorName = actorName;
				
	self._delay = delay;

	self._endTime = nil;
	
	self._setPosFunc =  setPosFunc or setPos;
	
	return self;
end

function moveToActor:clone()
	return moveToActor:create(self._startPos, self._dstActorName, self._delay, self._setPosFunc);
end

function moveToActor:run()
	local endPos = self._endPos;

	local actor = getActor(self._dstActorName);
	
	if actor then
		endPos = {x = actor:GetActorValue("x")
				, y = actor:GetActorValue("y")
				, z = actor:GetActorValue("z")};
	end	
	

	if not actor or self._delay <= 0 then
		self._setPosFunc(endPos.x, endPos.y, endPos.z);
		return false;
	end
	
	local curTime = getTimer();
	local startPos = self._startPos;

	if not self._endTime then
		self._endTime = curTime + self._delay;
		self._setPosFunc(startPos.x, startPos.y, startPos.z);
		return true;
	end
	
	-- 跑完时间了
	if (curTime >= self._endTime) then
		self._setPosFunc(endPos.x, endPos.y, endPos.z);
		return false;
	end
	
	local per = 1 - ((self._endTime - curTime) / self._delay);
	
	local xdir = endPos.x - startPos.x;
	local ydir = endPos.y - startPos.y;
	local zdir = endPos.z - startPos.z;
	
	local x = startPos.x + xdir * per;
	local y = startPos.y + ydir * per;
	local z = startPos.z + zdir * per;
	
	self._setPosFunc(x, y, z);
	
	return true;
end


local actions = gettable("BM_Actions");
local Vctor = gettable("BM_Vctor");

actions.DelayTime 		= delayTime;
actions.Sequence 		= sequence;
actions.Spawn 			= spawn;
actions.CallFunction 	= callFunction;
actions.MoveTo			= moveTo;
actions.MoveToActor		= moveToActor;
actions.Repeat			= repeatAction;

-- action宿主
local actionHost = inherit(nil, gettable("BM_ActionHost"));

function actionHost:ctor()
	self._actionVector = Vctor.new();
end

function actionHost:runAction(action)
	self._actionVector:push_back(action);
end

function actionHost:update()
	local index = 1;
	local action;
	local actionVector = self._actionVector;
	
	while(index <= actionVector:size()) do
		action = actionVector:fast_get(index);
		if (not action:isStop() and action:run()) then
			index = index + 1;
		else
			actionVector:fast_remove(index);
		end
	end
end

