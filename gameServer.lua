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
	--self._frameDatas = {};
end

function Server:onEnter()
	self._netHandles._onConnectHandle = gNetworkDispatcher:addListener("connect", function(eventName, userinfo) self:onConnect(userinfo); end);
	self._netHandles._onDisconnectHandle = gNetworkDispatcher:addListener("disconnect", function(eventName, userinfo) self:onDisconnect(userinfo); end);
	
	self._netHandles._onRequestEchoHandle = gNetworkDispatcher:addListener(Message.REQUEST_ECHO, function(eventName, data, nid) self:onRequestEcho(data, nid); end);
	
	self._netHandles._onRequestLoginHandle = gNetworkDispatcher:addListener(Message.REQUEST_LOGIN, function(eventName, data, nid) self:onRequestLogin(data, nid); end);
	
	self._netHandles._onRequestLoginHandle = gNetworkDispatcher:addListener(Message.CLIENT_FRAME, function(eventName, data, nid) self:onClientFrame(data, nid); end);
	
	self._handles._onAppCloseHandle = gDispatcher:addListener("onAppClose", function(eventName) self:onAppClose(); end);
end

function Server:onRequestLogin(data, nid)
	self._clients[nid] = {};
	self._clients[nid].userName = data.keepworkUsername;
	--self._clients[nid].frameData = {};
	SendNetworkSteam(nid, Message.RESPONSE_LOGIN, {});
	
	-- test
	self:startStage();
end

function Server:startStage()
	local playerInx = 1;
	
	local nameList2 = {};
	for _, v in pairs(self._clients) do
		local nameList = {};
		nameList[#nameList + 1] = System.User.keepworkUsername;
		for __, vv in pairs(self._clients) do
			if vv.userName ~= v.userName then
				nameList[#nameList + 1] = vv.userName;
			end	
		end
		
		SendTcpSteam(v.userName, Message.READY_STAGE, {[1] = playerInx, [2] = nameList});
		playerInx = playerInx + 1;
		nameList2[#nameList2 + 1] = v.userName;
	end
	
	self._gameMain:init(self, 0, nameList2);
	self._gameMain:goStage(1);
end

function Server:onClientFrame(data, nid)
	if self._clients[nid] then
		self._clients[nid].frameData = data;
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
	for nid, client in pairs(self._clients) do
	--	for _nid, fd in pairs(self._frameDatas) do
		if self._frameDatas then
			SendNetworkSteam(nid, Message.SERVER_FRAME, self._frameDatas);
			self._frameDatas = nil;
		end
	--	end	
	end
end

function Server:addFrameData(data)
	self._frameDatas = data;
end

function Server:update(dt)
	local inputData = {};
	for _, v in pairs(self._clients) do
		self._gameMain:updateInput(v.frameData);
	end	
	self:processFrame(dt);
	self._gameMain:update(dt);
end