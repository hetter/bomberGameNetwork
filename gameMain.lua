local GameMain = inherit(nil, gettable("BM_GameMain"));
local Message = gettable("BM_NetMessage");
local Desc = gettable("BM_ProtocolDesc");

function GameMain:ctor()
	self._players = {};
	self._tick_tock = 0;
	self._playerInx = 0;
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
		local myInput = _clientPlayer.input;
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
		
		if(oldDir ~= myInput.dir) or (oldPut ~= myInput.isPutBomb) then
			-- send msg
			local data =
			{
				frame = 0;
				input = packInput(myInput, self._playerInx);
			}
			
			if self._serverData.nid then
				SendNetworkSteam(self._serverData.nid, Message.CLIENT_FRAME, data);
			else
				self._serverData:addFrameData(data);
			end
		end
	end	
	
	self._tick_tock = self._tick_tock + dt;
	local interval = 1.0/30.0;
	if self._tick_tock >= interval then
		process();
		self._tick_tock = self._tick_tock - interval;
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

function GameMain:updateInput(frameData)
	if frameData then
		local inputData = unpackInput(frameData.input);
		local player = self._players[inputData.playInx + 1];
		if player then
			player.input.dir = inputData.dir;
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