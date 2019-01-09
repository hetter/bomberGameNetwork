-- 逻辑帧控制函数
g_waitOneFrame = function()
	wait(1 / 100);
end

local s_seed = 0;
function g_getSeed()
	s_seed = s_seed + 1;
	return s_seed;
end

function g_getTimer()
	return os.clock();
end