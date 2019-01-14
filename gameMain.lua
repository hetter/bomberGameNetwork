local GameMain = inherit(nil, gettable("BM_GameMain"));
local Message = gettable("BM_NetMessage");
local Desc = gettable("BM_ProtocolDesc");
function GameMain:ctor()
	self._players = {};
	self._tick_tock = 0;
	self._playerInx = 0;
	
	self._myInput = {};
	self._myInput.dir = Constant.MOV_DIR_NULL;
	self._myInput.isPutBomb = 0;	

	self._clientConfirmFrame = 0; 	-- 服务器确认过的客户端帧
	self._serverConfirmFrame = 0;	-- 当前的服务器确认帧
	self._clientFrame = 0; 			-- 当前客户端帧
	self._sendDataPool = {};
end

function GameMain:init(serverData, playerInx, playerList)
	self._serverData = serverData;
	self._playerInx = playerInx;
	self._playerList = playerList;
	table.insert(self._playerList, playerInx + 1, System.User.keepworkUsername)
end

function GameMain:onConnect(userinfo)

end

function GameMain:onDisconnect(userinfo)
	
end

function GameMain:onFrameConfirm(confirmFrame)
	self._clientConfirmFrame = confirmFrame;
end

local function packInput(myInput, playerInx)
	local inputMsg = 0;
	
	inputMsg = bit.bor(inputMsg, myInput.dir);
	
	if myInput.isPutBomb == 1 then
		inputMsg = bit.bor(inputMsg, 16); -- 0000 1000
	else
		inputMsg = bit.band(inputMsg, 247);-- 1111 0111
	end
	
	inputMsg = bit.bor(inputMsg, bit.lshift(playerInx, 4));
	
	return inputMsg;
end

local function unpackInput(inputMsg)
	local dir = bit.band(inputMsg, 7);-- 0000 0111
	local isPutBomb = bit.band(inputMsg,8);-- 0000 1000
	local playInx = bit.band(inputMsg, 240);-- 1111 0000
	playInx = bit.rshift(playInx, 4);
	return {playInx = playInx, dir = dir, isPutBomb = isPutBomb};
end


function GameMain:processInput(dt)
	local function process()
		local _clientPlayer = self._players[self._playerInx + 1]
		if _clientPlayer == nil then
			return
		end	
		local myInput = self._myInput;--_clientPlayer.input;
		local oldDir = myInput.dir;
		local oldPut = myInput.isPutBomb;
		if isKeyPressed(Constant.KEY_PLAYER_FORWARD) then
			myInput.dir = Constant.MOV_DIR_FORWARD;
		elseif isKeyPressed(Constant.KEY_PLAYER_BACK) then
			myInput.dir = Constant.MOV_DIR_BACK;
		elseif isKeyPressed(Constant.KEY_PLAYER_LEFT) then
			myInput.dir = Constant.MOV_DIR_LEFT;
		elseif isKeyPressed(Constant.KEY_PLAYER_RIGHT) then
			myInput.dir = Constant.MOV_DIR_RIGHT;
		else
			myInput.dir = Constant.MOV_DIR_NULL;
		end
		
		if isKeyPressed(Constant.KEY_PLAYER_BOMBER) then
			myInput.isPutBomb = 1;
		else
			myInput.isPutBomb = 0;
		end	
		
		self._clientFrame = self._clientFrame + 1;
		
		local frameInput;
		if(oldDir ~= myInput.dir) or (oldPut ~= myInput.isPutBomb) then			
			frameInput = packInput(myInput, self._playerInx);
			self._sendDataPool[#self._sendDataPool + 1] = {frame = self._clientFrame, input = frameInput};
			if #self._sendDataPool > Constant.CLIENT_SEND_QUEUE_SIZE then
				table.remove(self._sendDataPool, 1);
			end
		end

		-- send msg
		local subFrame = self._clientFrame - self._clientConfirmFrame;
		local inputMap = {};
		for _, v in ipairs(self._sendDataPool) do
			if v.frame > self._clientConfirmFrame then
				inputMap[v.frame] = v.input;
			end
		end
	
		if(next(inputMap))then
			local data =
			{
				input_map	= inputMap;
			}			
			if self._serverData.nid then				
				SendNetworkSteam(self._serverData.nid, Message.CLIENT_FRAME, data);
			else
				self._serverData:onClientFrame(data, 0);
			end	
		end
	end	
	
	self._tick_tock = self._tick_tock + dt;
	local interval = 1.0 / Constant.CLIENT_FPS;
	if self._tick_tock >= interval then
		process();
		self._tick_tock = self._tick_tock - interval;
	end
end

function GameMain:receiveServerFrameMsg(frameData)
	if(frameData.frame > self._serverConfirmFrame) then
		local subFrame = frameData.frame - self._serverConfirmFrame;
		local processInputs = {};
		for i = 0, subFrame - 1 do
			processInputs[frameData.frame - i] = frameData.input_map_array_array[i + 1];
		end	
		
		self._serverConfirmFrame = frameData.frame;
		
		local data =
		{
			frame	= frameData.frame;
		}			
		if self._serverData.nid then	
			SendNetworkSteam(self._serverData.nid, Message.SERVER_FRAME_CONFIRM, data);
		else
			self._serverData:onFrameConfirm(data, 0);
		end	
		
		self:updateServerInputs(processInputs);
	end

end	

function GameMain:updateServerInputs(processInputs)
	local function pairsByKeys(t)
		local a = {}
		for n in pairs(t) do a[#a + 1] = n end
		table.sort(a)
		local i = 0
		return function ()
			i = i + 1
			return a[i], t[a[i]]
		end
	end
	
	for serverFrame, input_map_array in pairsByKeys(processInputs) do
		local input_map_array = processInputs[serverFrame];
		for _, input_map in ipairs(input_map_array) do
			for clientFrame, inputData in pairsByKeys(input_map) do
				self:updateInput(inputData);
			end
		end
	end
	
end

function GameMain:updateInput(inputData)
	if inputData then
		local inputT = unpackInput(inputData);
		local player = self._players[inputT.playInx + 1];
		if player then
			player.input.dir = inputT.dir;
		end			
	end
end

function GameMain:updatePlayer(dt)
	for _, player in ipairs(self._players) do
		if player.input.dir ~= Constant.MOV_DIR_NULL then
			local playerObj = getActor(player.name);
			runForActor(playerObj, function()
				local x, y, z = getPos();
				local vec = Constant.PLAYER_MOV_SPD * dt;
				if(player.input.dir == Constant.MOV_DIR_FORWARD)then
					turnTo(270)
					setPos(x, y, z + vec)
				elseif(player.input.dir == Constant.MOV_DIR_BACK)then
					turnTo(90)
					setPos(x, y, z - vec)
				elseif(player.input.dir == Constant.MOV_DIR_LEFT)then
					turnTo(180)
					setPos(x - vec, y, z)
				elseif(player.input.dir == Constant.MOV_DIR_RIGHT)then	
					turnTo(0)
					setPos(x + vec, y, z)
				end	
			end)
		end
	end
end

function GameMain:update(dt)
	self:processInput(dt);
	self:updatePlayer(dt);
end

local function _createPlayer(actorName)
	local player = {};
	player.name = actorName;
	player.input = {};
	player.input.dir = Constant.MOV_DIR_NULL;
	player.input.isPutBomb = 0;
	return player;
end	

function GameMain:goStage(stageId)
	local stage = loadWorldData("stage" .. stageId);
		
	initCamera(stage);
	
	for inx, userName in ipairs(self._playerList) do
		local actorName = userName .. "_p";
		local player = _createPlayer(actorName);
		self._players[inx] = player;
		clone("player", {actor_name = actorName, obj_name = "0" .. inx, stage = stage, born = inx});		
	end
end