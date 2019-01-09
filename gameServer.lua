local State = gettable("BM_GameState");
local Server = inherit(State, gettable("BM_GameServer"));
local Message = gettable("BM_NetMessage");
local Desc = gettable("BM_ProtocolDesc");

function Server:ctor()
	self._clients = {};
	self._handles = {};
	self._netHandles = {};
end

function Server:onEnter()
	self._netHandles._onConnectHandle = gNetworkDispatcher:addListener("connect", function(eventName, userinfo) self:onConnect(userinfo); end);
	self._netHandles._onDisconnectHandle = gNetworkDispatcher:addListener("disconnect", function(eventName, userinfo) self:onDisconnect(userinfo); end);
	
	self._netHandles._onRequestEchoHandle = gNetworkDispatcher:addListener(Message.REQUEST_ECHO, function(eventName, data, nid) self:onRequestEcho(data, nid); end);
	
	self._netHandles._onRequestLoginHandle = gNetworkDispatcher:addListener(Message.REQUEST_LOGIN, function(eventName, data, nid) self:onRequestLogin(data, nid); end);
	
	self._handles._onAppCloseHandle = gDispatcher:addListener("onAppClose", function(eventName) self:onAppClose(); end);
end

function Server:onRequestLogin(data, nid)
	self._clients[data.keepworkUsername] = {};
	self._clients[data.keepworkUsername].nid = nid;
	SendNetworkSteam(nid, Message.RESPONSE_LOGIN, {});
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
	sendNetworkEvent(userinfo.keepworkUsername, "onLogin", {});
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