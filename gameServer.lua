local State = gettable("BM_GameState");
local Server = inherit(State, gettable("BM_GameServer"));
local Message = gettable("BM_NetMessage");
local Desc = gettable("BM_ProtocolDesc");
local GameMain = gettable("BM_GameMain");

function Server:ctor()
	self._clients = {};
	self._handles = {};
	self._netHandles = {};
	self._gameMain = GameMain.new();
	self._tick_tock = 0;
	self._serverFrame = 0;
	self._sendDataPool = {};
	self._isInStage = false;
end

function Server:onEnter()
	self._netHandles._onConnectHandle = gNetworkDispatcher:addListener("connect", function(eventName, userinfo) self:onConnect(userinfo); end);
	self._netHandles._onDisconnectHandle = gNetworkDispatcher:addListener("disconnect", function(eventName, userinfo) self:onDisconnect(userinfo); end);
	
	self._netHandles._onRequestEchoHandle = gNetworkDispatcher:addListener(Message.REQUEST_ECHO, function(eventName, data, nid) self:onRequestEcho(data, nid); end);
	
	self._netHandles._onRequestLoginHandle = gNetworkDispatcher:addListener(Message.REQUEST_LOGIN, function(eventName, data, nid) self:onRequestLogin(data, nid); end);
	
	self._netHandles._onRequestLoginHandle = gNetworkDispatcher:addListener(Message.CLIENT_FRAME, function(eventName, data, nid) self:onClientFrame(data, nid); end);

	self._netHandles._onRequestLoginHandle = gNetworkDispatcher:addListener(Message.SERVER_FRAME_CONFIRM, function(eventName, data, nid) self:onFrameConfirm(data, nid); end);
	
	self._handles._onAppCloseHandle = gDispatcher:addListener("onAppClose", function(eventName) self:onAppClose(); end);
	
	registerBroadcastEvent("StageGo", function() self:startStage(1); end);
	
	runForActor("UI_BtnHallStart", function()
		show();
	end)
	
end

function Server:onRequestLogin(data, nid)
	self._clients[nid] = {};
	self._clients[nid].userName = data.keepworkUsername;
	self._clients[nid].clientConfirmFrame = 0;
	self._clients[nid].serverConfirmFrame = 0;
	self._clients[nid].frameDataList = {};
	SendNetworkSteam(nid, Message.RESPONSE_LOGIN, {});

	
	runForActor("UI_HallNameList", function()
		local uiList_tb = getActorValue("_tb");
		uiList_tb.addPlayer(data.keepworkUsername);
	end)
	
	--[[
	if not self.testCCC then
		self.testCCC = 0;
	end	
	self.testCCC = self.testCCC + 1;
	if self.testCCC >= 2 then
		self:startStage(1);
	end	
	]]
end

function Server:startStage(stageId)
	if next(self._clients) == nil then
		tip("less client!!")
		return;
	end
	
	-- self client
	self._clients[0] = {};
	self._clients[0].userName = System.User.keepworkUsername;
	self._clients[0].clientConfirmFrame = 0;
	self._clients[0].serverConfirmFrame = 0;
	self._clients[0].frameDataList = {};		
	
	--
	local myNameList = {};
		
	local playerInx = 1;
	for nid, v in pairs(self._clients) do
		local nameList = {};
		for __, vv in pairs(self._clients) do
			if vv.userName ~= v.userName then
				nameList[#nameList + 1] = vv.userName;
			end	
		end
		if nid == 0 then
			myNameList = nameList;
		else	
			SendTcpSteam(v.userName, Message.READY_STAGE, {[1] = playerInx, [2] = nameList});
			playerInx = playerInx + 1;
		end	
	end
	
	self._gameMain:init(self, 0, myNameList);
	self._gameMain:goStage(stageId);
	
	self._isInStage = true;
end

function Server:onClientFrame(data, nid)
	local c = self._clients[nid];
	if c then
		local maxFrame = - 1;
		for f, _ in pairs(data.input_map) do
			if f > maxFrame then
				maxFrame = f;
			end
		end
		if(maxFrame > c.clientConfirmFrame) then
			c.frameDataList[#c.frameDataList + 1] = data.input_map;
			c.clientConfirmFrame = maxFrame;
			
			if nid == 0 then
				self._gameMain:onFrameConfirm(c.clientConfirmFrame);
			else	
				SendNetworkSteam(nid, Message.CLIENT_FRAME_CONFIRM, {frame = c.clientConfirmFrame});
			end	
		end	
	end
end	

function Server:onFrameConfirm(data, nid)
	if self._clients[nid] then
		self._clients[nid].serverConfirmFrame = data.frame;
	end	
end	
	
function Server:onRequestEcho(data, nid)

	if System.User.keepworkUsername == data.keepworkUsername then
		-- 相同帐号直接不理
		return;
	end
	
	local info = GameLogic.options.GetNetworkInfo();
	
	local data =
	{
		--messageType			= Message.RESPONSE_ECHO;
		keepworkUsername	= System.User.keepworkUsername;
		port				= tonumber(info.TCP_PORT);
	};
	
	SendNetworkSteam(nid, Message.RESPONSE_ECHO, data);
end

function Server:onConnect(userinfo)	
	SendTcpSteam(userinfo.keepworkUsername, Message.LOGIN_INFO, {})
end

function Server:onDisconnect(userinfo)
	
end

function Server:onAppClose()
	self:removeAllClients();
end

function Server:onExit()
	for _, handle in pairs(self._netHandles) do
		gNetworkDispatcher:removeListener(handle);		
	end
	self._netHandles = {};

	
	self:removeAllClients();
	
	for _, handle in pairs(self._handles) do
		gNetworkDispatcher:removeListener(handle);		
	end
	self._handles = {};
	
	
end

function Server:removeAllClients()

	for k, v in pairs(self._clients) do
		cmd(string.format("/disconnectLobbyClient %s", k));
	end
	
	self._clients = {};
end

function Server:processFrame(dt)
	if self._isInStage == false then
		return;
	end	
	
	local function process()
		local input_map_array = {};
		for nid, client in pairs(self._clients) do
			local fd = client.frameDataList;
			local inputMap = {};
			for i = 1, #fd do
				for ff, inp in pairs(fd[i]) do
					inputMap[ff] = inp;
				end
			end
			input_map_array[#input_map_array + 1] = inputMap;
		end
		self._sendDataPool[#self._sendDataPool + 1] = input_map_array;
		if #self._sendDataPool > Constant.SERVER_SEND_QUEUE_SIZE then
			table.remove(self._sendDataPool, 1);
		end

		for nid, client in pairs(self._clients) do
			local input_map_array_array = {};
			
			local subFrame = self._serverFrame - client.serverConfirmFrame;
			
			if subFrame <= #self._sendDataPool then
				for i = 0, subFrame - 1 do
					input_map_array_array[#input_map_array_array + 1] = self._sendDataPool[#self._sendDataPool - i];
				end
			end
			
			local sendDatas = 
			{
				frame = self._serverFrame;
				input_map_array_array = input_map_array_array;
			};
			
			if nid == 0 then
				self._gameMain:receiveServerFrameMsg(sendDatas);
			else
				SendNetworkSteam(nid, Message.SERVER_FRAME, sendDatas);
			end	
		end	
	end	
	
	self._tick_tock = self._tick_tock + dt;
	local interval = 1.0 / Constant.SERVER_FPS;
	if self._tick_tock >= interval then
		self._serverFrame = self._serverFrame + 1;
		process();
		self._tick_tock = self._tick_tock - interval;
	end
end

function Server:update(dt)
	local inputData = {};
	for _, v in pairs(self._clients) do
		self._gameMain:updateInput(v.frameData);
	end	
	self:processFrame(dt);
	self._gameMain:update(dt);
end