local State = gettable("BM_GameState");
local Client = inherit(State, gettable("BM_GameClient"));
local Message = gettable("BM_NetMessage");
local Desc = gettable("BM_ProtocolDesc");

function Client:ctor()
	self._server = nil;
	self._handles = {};
	self._netHandles = {};
end

function Client:startSearchServer()
	
	local serverList = {};
	
	local function selectServer()
		if #serverList == 0 then
			tip("could not found server");
			gLogic:stop();
			return;
		end
		
		local t = {};
		for i = 1, #serverList do
			table.insert(t, serverList[i].data.keepworkUsername .. ":" .. serverList[i].ip .. ":" .. serverList[i].data.port);
		end
		
		ask("please select a server:", t);
		cmd("/connectLobbyClient " .. serverList[answer].ip .. " ".. serverList[answer].data.port)
	end
	
	local function onServerInfo(bSucceed, data, nid)
		if bSucceed then
			if data.keepworkUsername ~= System.User.keepworkUsername then
				local ip, _ = string.match(nid, "~udp(%d+.%d+.%d+.%d+)_(%d+)");
				table.insert(serverList, {data = data, ip = ip});
			end
		else
			gLogic:runOnNextFrame(selectServer);
		end
	end
	
	gLogic:addNetListener(Message.RESPONSE_ECHO, onServerInfo);
	
	
	local data =
	{
		messageType			= Message.REQUEST_ECHO;
		keepworkUsername	= System.User.keepworkUsername;
		--projectId			= GameLogic.options.GetProjectId();
		--version				= GameLogic.options.GetRevision();
		-- 设置为true的话用于调试时忽略版本号
		--editMode			= true;
	};
	

	-- 广播原始数据
	SendNetworkSteam(nil, Desc.request_echo, data);
end

function Client:onEnter()
	self._netHandles._onConnectHandle = gNetworkDispatcher:addListener("connect", function(eventName, userinfo) self:onConnect(userinfo); end);
	self._netHandles._onDisconnectHandle = gNetworkDispatcher:addListener("disconnect", function(eventName, userinfo) self:onDisconnect(userinfo); end);
	
	self._handles._onAppCloseHandle = gDispatcher:addListener("onAppClose", function(eventName) self:onAppClose(); end);
	

	self:startSearchServer();
end


function Client:onConnect(userinfo)
	echo("-----on onConnect")
end

function Client:onDisconnect(userinfo)
	
end

function Client:onAppClose()
	self:removeServer();
end

function Client:removeServer()
	if self._server then
		cmd(string.format("/disconnectLobbyClient %s", self._server:GetUserName()));
	end
end


function Client:onExit()
	for _, handle in pairs(self._netHandles) do
		gNetworkDispatcher:removeListener(handle);		
	end
	self._netHandles = {};
	
	self:removeServer();
	
	for _, handle in pairs(self._handles) do
		gNetworkDispatcher:removeListener(handle);		
	end
	self._handles = {};
end

function Client:update(dt)
	
end