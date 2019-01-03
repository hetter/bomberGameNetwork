cmd("/stopLobbyServer");
-- 开启lobyy server 并且不使用自动扫描模式
cmd("/startLobbyServer false");

-- 这里接收的都是原始数据流， 只有udp才能使用， 所以isUDP永远是true
local function onNetMsg(msg)
	--[[
		msg.isUDP = true;
		msg.nid = "~udp10.27.3.5_8099";
		msg.data = stream string;
	]]
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
end


-- 必须等lobby server完全启动后调用这个函数， registerNetworkEvent底层检测到lobby server未启动 会开启lobby server并且打开自动扫描模式
function StartBMNetwork()
	registerNetworkEvent("__original", onNetMsg);
	registerNetworkEvent("connect", onConnect);
	registerNetworkEvent("disconnect", onDisconnect);
end