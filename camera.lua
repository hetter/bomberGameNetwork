
include("npl/data_struct.lua");
include("npl/randomCalc.lua");
include("npl/action.lua");
include("npl/config.lua");
include("npl/global.lua");
include("npl/eventDispatcher.lua");
include("npl/protocol.lua");
include("npl/desc.lua");
include("npl/netMessage.lua");
include("npl/network.lua");
include("npl/gameState.lua");
include("npl/gameServer.lua");
include("npl/gameClient.lua");
include("npl/startState.lua");
include("npl/gameLogic.lua");
include("npl/main.lua");



local function initCamera()
	
end

-- 退出时停止
registerStopEvent(function()
	gDispatcher:dispatchEvent("onAppClose");
	playMusic(); -- 停止背景音乐
end)