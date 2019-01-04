cmd("/stopLobbyServer");
cmd("/autowait false");

function OnSignedIn(strSucceed)

	if strSucceed == "true" then
		-- 开启lobyy server 并且不使用自动扫描模式
		cmd("/startLobbyServer -callback OnLobbyServerStarted false");
	else
		tip("运行" .. Constant.GAME_NAME .. "需要登录keepwork");
		exit();
	end
end

function OnLobbyServerStarted(strSucceed)
	if strSucceed == "true" then
		StartBMNetwork();
		local GameStart = gettable("BM_GameStart");
		gLogic:changeState(GameStart.new());
		gLogic:run();
		exit();
	else
		tip("运行" .. Constant.GAME_NAME .. "需要开启lobby server");
		exit();
	end
end

registerBroadcastEvent("OnSignedIn", OnSignedIn);
registerBroadcastEvent("OnLobbyServerStarted", OnLobbyServerStarted);

cmd("/signin -t 请先登录 -callback OnSignedIn");
