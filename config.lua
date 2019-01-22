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
	-- 炸弹
	GRID_BOMB = 4;	
	
	--
	ITEM_TYPE_BOMB = 0;
	ITEM_TYPE_RANGE = 1;
	
	-- 玩家控制键
	KEY_PLAYER_FORWARD			= "up";
	KEY_PLAYER_BACK			    = "down";
	KEY_PLAYER_LEFT			    = "left";
	KEY_PLAYER_RIGHT			= "right";
	KEY_PLAYER_BOMBER			= "space";
	
	PLAYER_MOVE_GRID_TIME = 0.1;
	
	MOV_DIR_NULL 		= 0;
	MOV_DIR_FORWARD 	= 1;
	MOV_DIR_BACK		= 2;
	MOV_DIR_LEFT 		= 3;
	MOV_DIR_RIGHT 		= 4;
};