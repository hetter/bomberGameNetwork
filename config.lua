-- 常量
Constant = 
{
	-- 游戏名称
	GAME_NAME 					= "炸弹人";
	
	-- 服务器发送队列大小
	SERVER_SEND_QUEUE_SIZE		= 9;
	-- 服务器逻辑fps
	SERVER_FPS					= 30;
	-- 客户端发送队列大小
	CLIENT_SEND_QUEUE_SIZE		= 9;
	-- 客户端逻辑fps
	CLIENT_FPS					= 30;
	
	-- 起始点方块ID
	START_POINT = {
					[23] = true; --红色
					[137] = true; -- 绿色
					[21] = true; -- 蓝色
					[27] = true; -- 黄色
					};
					
	-- 可通过方块ID
	CROSS_BLOCK = {
					[91] = true; -- 云衫树叶
					[92] = true; -- 樱花
					[129] = true; -- 白桦树叶
					};
					
	-- 可通行				
	GRID_WAY = 0;				
	-- 出生点
	GRID_BORN = 1;
	-- 可破坏
	GRID_BREAK = 2;
	-- 堵塞
	GRID_BLOCK = 3;
	
};