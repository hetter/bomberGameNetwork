local State = gettable("BM_GameState");
local GameStart = inherit(State, gettable("BM_GameStart"));


function GameStart:ctor()
end

function GameStart:onEnter()
	ask("模式", {"服务器", "客户端"});
	
	local function doAnswer()
		if answer == 1 then
			local StateS = gettable("BM_GameServer"); 
			gLogic:changeState(StateS.new());
		elseif answer == 2 then
			local StateC = gettable("BM_GameClient"); 
			gLogic:changeState(StateC.new());
		else
			gLogic:stop();
		end
	end
	
	gLogic:runOnNextFrame(doAnswer);
end

function GameStart:onExit()
end

