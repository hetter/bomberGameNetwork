local Desc = gettable("BM_ProtocolDesc");
local Message = gettable("BM_NetMessage");
local eventDispatcher = gettable("BM_EventDispatcher");

-- 用于派发网络事件
gNetworkDispatcher = eventDispatcher.new();

local callbacks = {};

callbacks[Message.REQUEST_ECHO] = function(stream, nid)
	if gNetworkDispatcher:hasEvent(Message.REQUEST_ECHO) then
		local pt_reader = Desc.request_echo;
		local data = pt_reader:readStream(stream);
		
		gNetworkDispatcher:dispatchEvent(Message.REQUEST_ECHO, data, nid);
	end
end

callbacks[Message.RESPONSE_ECHO] = function(stream, nid)
	if gNetworkDispatcher:hasEvent(Message.RESPONSE_ECHO) then
		local pt_reader = Desc.response_echo;
		local data = pt_reader:readStream(stream);
		
		gNetworkDispatcher:dispatchEvent(Message.RESPONSE_ECHO, data, nid);
	end
end

-- 这里接收的都是原始数据流， 只有udp才能使用， 所以isUDP永远是true
local function onNetMsg(msg)
	--[[
		msg.isUDP = true;
		msg.nid = "~udp10.27.3.5_8099";
		msg.data = stream string;
	]]
	local stream = ParaIO.open(msg.data, "buffer");
	-- 对data进行引用 以防data被释放
	stream.__data = msg.data;
	
	local head = stream:ReadString(4);
	
	if head ~= Message.Head then
		return;
	end
	
	local msgType = stream:ReadUShort();
	stream:seek(4);
	local cb = callbacks[msgType];
	if cb then
		cb(stream, msg.nid);
	end
	
	stream:close();
end

local function onConnect(msg)
	--[[
		msg.userinfo = 
		{
			keepworkUsername = "kkvskkkk";
			nickname = "kkvskkkk";
			nid = "LobbyServer_kkvskkkk";
		};
	]]
	--tip(msg.userinfo.keepworkUsername .. "已连接");
	
	gNetworkDispatcher:dispatchEvent("connect", msg.userinfo);
end

local function onDisconnect(msg)
	--[[
		msg.userinfo = 
		{
			keepworkUsername = "kkvskkkk";
			nickname = "kkvskkkk";
			nid = "LobbyServer_kkvskkkk";
		};
	]]
	
	gNetworkDispatcher:dispatchEvent("disconnect", msg.userinfo);
end

function SendNetworkSteam(addr, writer, data)
	local stream = writer:createStream(data);
	local str = Message.Head .. stream:ReadString(stream:GetFileSize());
	stream:close();
	sendNetworkEvent(addr, nil, str);
end


-- 必须等lobby server完全启动后调用这个函数， registerNetworkEvent底层检测到lobby server未启动 会开启lobby server并且打开自动扫描模式
function StartBMNetwork()
	registerNetworkEvent("__original", onNetMsg);
	registerNetworkEvent("connect", onConnect);
	registerNetworkEvent("disconnect", onDisconnect);
end



