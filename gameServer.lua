local State = gettable("BM_GameState");
local Server = inherit(State, gettable("BM_GameServer"));

function Server:ctor()
	self._clients = {};
	self._handles = {};
	self._netHandles = {};
end

function Server:onEnter()
	self._netHandles._onConnectHandle = gNetworkDispatcher:addListener("connect", function(eventName, userinfo) self:onConnect(userinfo); end);
	self._netHandles._onDisconnectHandle = gNetworkDispatcher:addListener("disconnect", function(eventName, userinfo) self:onDisconnect(userinfo); end);
	
	self._netHandles._onRequestEchoHandle = gNetworkDispatcher:addListener(Message.REQUEST_ECHO, function(eventName, data) self:onRequestEcho(data); end);
	
	self._handles._onAppCloseHandle = gDispatcher:addListener("onAppClose", function(eventName) self:onAppClose(); end);
end

function Server:onRequestEcho(data)
	if System.User.keepworkUsername == data.keepworkUsername then
		-- 相同帐号直接不理
		return;
	end
	
	local info = GameLogic.options.GetNetworkInfo();
end

function Server:onConnect(userinfo)
	
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

function Server:update(dt)
	
end