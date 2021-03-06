local GameScene = inherit(nil, gettable("BM_GameScene"));

local ObjOffX = 0.5;
local ObjOffY = 0.5;
local ObjOffZ = 0.5;

local bombPoolNums = 50;

local MOVE_CHANGE = 
{
	[Constant.MOV_DIR_FORWARD] = {0, 1};
	[Constant.MOV_DIR_BACK] = {0, -1};
	[Constant.MOV_DIR_LEFT] = {-1, 0};
	[Constant.MOV_DIR_RIGHT] = {1, 0};
}

function GameScene:ctor()
	self._players = {};
	self._stageMap = {};
	self._stageStartX = 0;
	self._stageStartY = 0;
	self._stageStartZ = 0;
	self._isInit = false;
	
	self._objRecorder = {};
	
	self._bomerPool = {};
	self._bombInx = 1;
end

function GameScene:_2dTo3dPos(px, py)
	local objX = self._stageStartX + px + ObjOffX;
	local objY = self._stageStartY + ObjOffY;
	local objZ = self._stageStartZ + py + ObjOffZ;			
	return objX, objY, objZ;
end	

function GameScene:saveBlockMark(objX, objY, objZ)
	local idMark = getBlock(objX, objY, objZ);
	local reBuildMark = loadWorldData("reBuildMark");
	
	local reInx = #reBuildMark + 1;
	reBuildMark[reInx] = {};
	reBuildMark[reInx].x = objX;
	reBuildMark[reInx].y = objY;
	reBuildMark[reInx].z = objZ;
	reBuildMark[reInx].id = idMark;
	
	saveWorldData("reBuildMark", reBuildMark);
end	

function GameScene:_createPlayer(actorName, startX, startY)
	local player = {};
	player.name = actorName;
	player.pos = {};		
	player.pos.x = startX;
	player.pos.y = startY;		
	player.bomers = 0;
	player.bomerLimit = 4;
	player.bomerRange = 1;	
	player.input = {};
	player.input.dir = Constant.MOV_DIR_NULL;
	player.input.isPutBomb = 0;
	return player;
end

function GameScene:_createBomb(posX, posY, playerInx, range)
	local bomb = {};
	bomb.itemType = Constant.ITEM_TYPE_BOMB;
	bomb.range = range;
	bomb.inx = self._bombInx;
	bomb.playerInx = playerInx;
	bomb.name = "bomb_" .. bomb.inx;
	bomb.posX = posX;
	bomb.posY = posY;
	bomb.life = 5.0;
	
	runForActor(bomb.name, function()	
		setPos(self:_2dTo3dPos(posX, posY))
		playLoop(0, 1000);
		show();
	end)
	
	self._bombInx = self._bombInx + 1;
	if self._bombInx > bombPoolNums then
		self._bombInx = 1;
	end
	return bomb;
end

function GameScene:_createItem(posX, posY)
	local item = {};
	item.itemType = Constant.ITEM_TYPE_RANGE;
	item.name = "item_" .. os.clock();		
	local objX, objY, objZ = self:_2dTo3dPos(posX, posY);
	clone("effect", {obj_name = "eff_item_range", actor_name = item.name, x = objX, y = objY + 1, z = objZ});	

	return item;
end	

function GameScene:init(playerList, stageData)	
	for inx, userName in ipairs(playerList) do
		local actorName = userName .. "_p";
		self._stageStartX = stageData.startX;
		self._stageStartY = stageData.startY;
		self._stageStartZ = stageData.startZ;
		local startPoint = stageData.born[inx];
		local player = self:_createPlayer(actorName, startPoint.x, startPoint.y);
		self._players[inx] = player;
		clone("player", {actor_name = actorName, obj_name = "0" .. inx, stage = stageData, born = inx});		
	end	
	
	for xx, ys in pairs(stageData.map) do
		self._stageMap[xx] = {};
		for yy, mapInfo in pairs(ys) do
			self._stageMap[xx][yy] = mapInfo;
		end
	end
	
	for i = 1, bombPoolNums do
		local poolInx = i;
		local acName = "bomb_" .. poolInx;
		clone("bomb", {actor_name = acName, pos = {x = 0, y = 0, z = 0}});
	end
	
	for i = 1, bombPoolNums do
		local poolInx = i;
		local acName = "bomb_" .. poolInx;
		clone("bomb", {actor_name = acName, pos = {x = 0, y = 0, z = 0}});
	end	
	
	local reBuildMark = loadWorldData("reBuildMark");
	if reBuildMark then
		for _, v in ipairs(reBuildMark) do
			setBlock(v.x, v.y, v.z, v.id);
		end
	end
	saveWorldData("reBuildMark", {});
	
	self._isInit = true;
	
end

function GameScene:setRecordObject(px, py, obj)
	if not self._objRecorder[px] then
		self._objRecorder[px] = {};
	end
	
	self._objRecorder[px][py] = obj;
end	

function GameScene:getRecordObject(px, py)
	if not self._objRecorder[px] then
		return nil;
	end
	
	return self._objRecorder[px][py];
end	

function GameScene:updatePlayerInput(inputData)
	local player;
	if inputData then
		player = self._players[inputData.playInx + 1];
		if player then
			player.input.dir = inputData.dir;
			player.input.isPutBomb = inputData.isPutBomb;
		end	
	end	
	
	if player == nil then
		return;
	end
	
	if player.dirPos then
		return;
	end	
	
	if player.input.dir ~= Constant.MOV_DIR_NULL then
		if player.dirData == nil then
			local nowDir = MOVE_CHANGE[player.input.dir];
			local changePos = {player.pos.x + nowDir[1], player.pos.y + nowDir[2]}
			
			--is block
			local mapX = changePos[1];
			local mapY = changePos[2];
			local mapInfo = self._stageMap[mapX][mapY];
			if (mapInfo == Constant.GRID_BREAK or 
				mapInfo == Constant.GRID_BLOCK or 
				mapInfo == Constant.GRID_BOMB) then
				return;
			end
		
			player.dirData = {}
			player.dirData.dest = changePos;
			local vecX = MOVE_CHANGE[player.input.dir][1]/Constant.PLAYER_MOVE_GRID_TIME;
			local vecY = MOVE_CHANGE[player.input.dir][2]/Constant.PLAYER_MOVE_GRID_TIME;
			player.dirData.vec = {vecX, vecY};
			player.dirData.time = 0;
		end
	end
	
	if player.input.isPutBomb == 1 and player.bomers < player.bomerLimit then
		local bomb = self:_createBomb(player.pos.x, player.pos.y, inputData.playInx, player.bomerRange);
		self._bomerPool[bomb.inx] = bomb;
		player.bomers = player.bomers + 1;
		self._stageMap[bomb.posX][bomb.posY] = Constant.GRID_BOMB;
		self:setRecordObject(bomb.posX, bomb.posY, bomb);
	end
end

function GameScene:playEffect(posX, posY)
	local objX, objY, objZ = self:_2dTo3dPos(posX, posY);
	clone("effect", {obj_name = "eff_fire", x = objX, y = objY + 1, z = objZ});
end

function GameScene:checkPlayersHit(posX, posY)
	for pInx = 1, #self._players do
		local player = self._players[pInx];
		if posX == player.pos.x and posY == player.pos.y then
			runForActor(player.name, function()
				delete();
			end)			
			return true;
		end
	end	
	return false;
end

function GameScene:checkBlockHit(posX, posY)
	local objX, objY, objZ = self:_2dTo3dPos(posX, posY);
	objY = objY + 1;
	self:saveBlockMark(objX, objY, objZ);
	setBlock(objX, objY, objZ, 0);
	
	-- if random then
		local item = self:_createItem(posX, posY);
		self:setRecordObject(posX, posY, item);
	--end	
end	

function GameScene:checkItemHit(player)
	local item = self:getRecordObject(player.pos.x, player.pos.y);
	if item and item.itemType == Constant.ITEM_TYPE_RANGE then
		runForActor(item.name, function()
			delete();
		end)
		
		player.bomerRange = player.bomerRange + 1;
	end
end	

function GameScene:update(dt)
	for pInx = 1, #self._players do
		local player = self._players[pInx];
		if player.dirData then
			player.dirData.time	= player.dirData.time + dt;		
			runForActor(player.name, function()
				if (player.dirData.time >= Constant.PLAYER_MOVE_GRID_TIME) then				
					local destX = player.dirData.dest[1];
					local destY = player.dirData.dest[2];
					setPos(self:_2dTo3dPos(destX, destY));
					player.pos.x = destX;
					player.pos.y = destY;
					player.dirData = nil;
					
					self:checkItemHit(player);
				else
					local x, y, z = getPos();
					local xOffset = player.dirData.vec[1] * dt;
					local zOffset = player.dirData.vec[2] * dt;
					x = x + xOffset;
					z = z + zOffset;
					setPos(x, y, z);
				end		
			end)
		end	
	end
	
	for inx, bomb in pairs(self._bomerPool) do
		bomb.life = bomb.life - dt;
		if(bomb.life <= 0)then
			-- raise event
			local function raiseBomb(px, py)
				local bomb = self:getRecordObject(px, py);
				if bomb and bomb.itemType == Constant.ITEM_TYPE_BOMB then
					local function doBoom(posX, posY)
						if posX < 1 or posX > #self._stageMap or posY < 1 or posY > #self._stageMap[posX] then
							return false;
						elseif self._stageMap[posX][posY] == Constant.GRID_BLOCK then
							return false;
						end
						
						self:checkPlayersHit(posX, posY);
						
						self:playEffect(posX, posY);
						if self._stageMap[posX][posY] == Constant.GRID_BREAK then
							self._stageMap[posX][posY] = Constant.GRID_WAY;
							self:checkBlockHit(posX, posY);
							return true;
						elseif self._stageMap[posX][posY] == Constant.GRID_BOMB then	
							raiseBomb(posX, posY);
							return true;
						end
						
						return false;
					end

					-- play eff
					runForActor(bomb.name, function()
						setPos(0, 0, 0);
						playLoop(0, 0);
						hide();
					end)
					
					-- do logic
					self:setRecordObject(bomb.posX, bomb.posY, nil);
					self._bomerPool[bomb.inx] = nil;					
					self._stageMap[bomb.posX][bomb.posY] = Constant.GRID_WAY;
					local player = self._players[bomb.playerInx + 1];
					if player then
						player.bomers = player.bomers - 1;
					end					
						
					local dirChange = {{1,0},{-1,0},{0,1},{0,-1}}; 
					for dirInx = 1, 4 do
						local dir = dirChange[dirInx];
						for i = 1, bomb.range do
							local posX = bomb.posX + dir[1] * i;
							local posY = bomb.posY + dir[2] * i;
							if(doBoom(posX, posY)) then
								break;
							end
						end
					end
				end	
			end
			
			raiseBomb(bomb.posX, bomb.posY);
		end
	end
end

