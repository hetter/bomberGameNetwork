local State = gettable("BM_GameState");
local GameStart = inherit(State, gettable("BM_GameStart"));


function GameStart:ctor()
end

function GameStart:onEnter()
	ask("模式", {"服务器", "客户端"});
	
	if answer == 1 then
		local State = gettable("BM_GameServer"); 
		gLogic:changeState(State.new());
	elseif answer == 2 then
		local State = gettable("BM_GameClient"); 
		gLogic:changeState(State.new());
	else
		gLogic:stop();
	end
end

function GameStart:onExit()
end

