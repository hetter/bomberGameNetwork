local desc = gettable("BM_ProtocolDesc");
local message = gettable("BM_Message");


local callbacks = {};

callbacks[message.REQUEST_ECHO] = function(stream, nid)
	local pt_reader = desc.request_echo;
	local data = pt_reader:readStream(stream);
	
	for k, v in pairs(data) do
		echo(string.format("key = %s value = %s", tostring(k), tostring(v)));
	end
end

callbacks[message.RESPONSE_ECHO] = function(stream, nid)
	local pt_reader = desc.response_echo;
	local data = pt_reader:readStream(stream);
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
	
	if head ~= message.Head then
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
	tip(msg.userinfo.keepworkUsername .. "已连接");
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
	tip(msg.userinfo.keepworkUsername .. "断开连接");
end


-- 必须等lobby server完全启动后调用这个函数， registerNetworkEvent底层检测到lobby server未启动 会开启lobby server并且打开自动扫描模式
function StartBMNetwork()
	registerNetworkEvent("__original", onNetMsg);
	registerNetworkEvent("connect", onConnect);
	registerNetworkEvent("disconnect", onDisconnect);
end


function StartSearchServer()
	
	local data =
	{
		messageType			= message.REQUEST_ECHO;
		keepworkUsername	= System.User.keepworkUsername;
		--projectId			= GameLogic.options.GetProjectId();
		--version				= GameLogic.options.GetRevision();
		-- 设置为true的话用于调试时忽略版本号
		--editMode			= true;
	};
	local pt_writer = desc.request_echo;
	
	local stream = pt_writer:createStream(data);
	local str = message.Head .. stream:ReadString(stream:GetFileSize());
	stream:close();

	-- 广播原始数据
	sendNetworkEvent(nil, nil, str);
end

wait(5);

ask({"服务器", "客户端"})

if answer == 1 then
	StartBMNetwork();
else answer == 2 then
	StartBMNetwork();
	StartSearchServer();
else
	exit();
end
