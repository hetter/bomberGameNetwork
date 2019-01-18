include("npl/config.lua");

local sLocalX, sLocalY, sLocalZ = codeblock:GetEntity():GetBlockPos();

local sEdgeId = 69;
do
	local dir = {}
	dir[#dir + 1] = getBlock(sLocalX, sLocalY, sLocalZ + 1);
	dir[#dir + 1] = getBlock(sLocalX, sLocalY, sLocalZ - 1);
	dir[#dir + 1] = getBlock(sLocalX - 1, sLocalY, sLocalZ);
	dir[#dir + 1] = getBlock(sLocalX + 1, sLocalY, sLocalZ);
	
	for i = 1, #dir do
		local blockId = dir[i];
		if (blockId ~= 219 and blockId ~= 228 and blockId ~= 0) then
			sEdgeId = blockId;
			break;
		end
	end
end

--echo("sEdgeId:" .. sEdgeId)

local sCheckHalfWidth = 25;
local sCheckHigh = 50;

local function findAABB()
	local startPoint, endPoint;
	for i = 1, sCheckHigh do
		local isStop;
		
		local isLeft = true;
		local checkLeftWidth = 0;
		local checkRightWidth = 0;
	
		while(checkLeftWidth > -sCheckHalfWidth and checkRightWidth < sCheckHalfWidth) do
			local j;
			if isLeft then				
				checkLeftWidth = checkLeftWidth - 1;
				j = checkLeftWidth;
			else				
				checkRightWidth = checkRightWidth + 1;
				j = checkRightWidth;
			end
			isLeft = not isLeft;
			
			local cx = sLocalX + j;
			local cy = sLocalY;
			local cz = sLocalZ + 1 + i;
			
			if (getBlock(cx, cy, cz) == sEdgeId) then
				if not startPoint then
					startPoint = {};
					startPoint.x = cx;
					startPoint.y = cy;
					startPoint.z = cz;
				elseif not endPoint then
					endPoint = {};
					endPoint.x = cx;
					endPoint.y = cy;
					endPoint.z = cz;
				end
				
				if startPoint and endPoint then
					isStop = true;
					break;
				end	
			end			
		end
		
		if isStop then
			break;
		end	
	end

	return startPoint, endPoint;
end

local aa, bb = findAABB();
cmd("/echo " .. (string.format("aa:%s %s %s bb:%s %s %s", aa.x, aa.y, aa.z, bb.x, bb.y, bb.z)))

local sRecorder = {};
local function findRecorder(aa, bb)
	local isSkip = false;
	for j = aa.x, bb.x do
		if isSkip then
			isSkip = false;
		else 
			local cx = j;
			local cy = sLocalY;
			local cz = sLocalZ + 2;
			
			local blockId = getBlock(cx, cy, cz);
			if blockId ~= 0 then
				cmd("/echo --------------record id:" .. tostring(blockId));
				sRecorder[blockId] = {};
				sRecorder[blockId].top = getBlock(cx, cy + 1, cz);
				sRecorder[blockId].replace = getBlock(cx + 1, cy, cz);
				
				isSkip = true;
			end	
		end	
	end

end

findRecorder(aa, bb);

local function saveStageTable(aa, bb)
	local retTable = {};
	local yy = aa.y;
	for zz = aa.z + 1, bb.z - 1 do
		for xx = aa.x + 1, bb.x - 1 do
			local recordId;
			local extData;
			
			local blockId = getBlock(xx, yy, zz);
			local blockIdUp = getBlock(xx, yy + 1, zz);
			
			if sRecorder[blockId] ~= nil then
				recordId = blockId;
				extData = sRecorder[blockId];
			elseif Constant.START_POINT[blockId] ~= nil then
				recordId = blockId;
			elseif blockIdUp ~= 0 and Constant.CROSS_BLOCK[blockIdUp] == nil then
				recordId = Constant.GRID_BLOCK;				
			end			
			
			if recordId ~= nil then
				local gridMsg = {};
				
				local addX = xx - aa.x;
				local addZ = zz - aa.z;
			
				gridMsg.x = addX;
				gridMsg.y = yy;
				gridMsg.z = addZ;
				gridMsg.id = recordId;
				gridMsg.extData = extData;
				retTable[#retTable + 1] = gridMsg;
			end			
		end
	end
	return retTable;
end

local stageTable = saveStageTable(aa, bb)

local function createScene(stageTable, aa, bb, newAA)
	local tmpId;
	
	local yy = aa.y;
	for zz = aa.z + 1, bb.z - 1 do
		for xx = aa.x + 1, bb.x - 1 do
			local blockId = getBlock(xx, yy, zz);
			
			--
			local addX = xx - aa.x;
			local addZ = zz - aa.z;
			
			--echo("-x:" .. addX .. ",z:" .. addZ)
			tmpId = getBlock(newAA.x + addX, yy, newAA.z + addZ);
			if(tmpId ~= blockId) then
				setBlock(newAA.x + addX, yy, newAA.z + addZ, blockId);
			end
			
			local copyUp = 1;
			local upBlock = getBlock(xx, yy + copyUp, zz);
			while(upBlock ~= 0) do
				tmpId = getBlock(newAA.x + addX, yy + copyUp, newAA.z + addZ);
				if(tmpId ~= upBlock)then
					setBlock(newAA.x + addX, yy + copyUp, newAA.z + addZ, upBlock);
				end	
				copyUp = copyUp + 1;
				upBlock = getBlock(xx, yy + copyUp, zz);
			end	
		end
	end
	
	for i = 1, #stageTable do
		local gridMsg = stageTable[i]
		--echo("gridMsg.id:" .. gridMsg.id)
		if gridMsg.id ~= Constant.GRID_BLOCK then
			if gridMsg.extData and gridMsg.extData.replace ~= 0 then
				tmpId = getBlock(newAA.x + gridMsg.x, gridMsg.y, newAA.z + gridMsg.z);
				if(tmpId ~= gridMsg.extData.replace)then
					setBlock(newAA.x + gridMsg.x, gridMsg.y, newAA.z + gridMsg.z, gridMsg.extData.replace)
				end	
			end
			
			if gridMsg.extData and gridMsg.extData.top ~= 0 then
				tmpId = getBlock(newAA.x + gridMsg.x, gridMsg.y + 1, newAA.z + gridMsg.z);
				if(tmpId ~= gridMsg.extData.top)then
					setBlock(newAA.x + gridMsg.x, gridMsg.y + 1, newAA.z + gridMsg.z, gridMsg.extData.top)
				end	
			end;	
		end
	end
end

local x, y, z;
if buildPos == nil then
	ask("请输入开始坐标")
	x, y, z = string.match(answer, "(%d+) (%d+) (%d+)");
	while(x == nil)do
		ask("请输入正确格式（数字坐标x 数字坐标y 数字坐标z）")
		x, y, z = string.match(answer, "(%d+) (%d+) (%d+)");
	end
else
	x, y, z = string.match(buildPos, "(%d+) (%d+) (%d+)");
	if (x == nil) then
		tip("err input!!!")
		return;
	end	
end	

--[[
local oldStage = loadWorldData(getActorValue("name"));
if oldStage then
	if oldStage.startX and oldStage.startY and oldStage.startZ and oldStage.width and oldStage.height then
		cmd(string.format("/setblock %d %d %d(%d %d %d)0", 
					oldStage.startX, oldStage.startY, oldStage.startZ, 
					oldStage.width, 50, oldStage.height));
	end				
end	
--]]				

createScene(stageTable, aa, bb, {x=x, z=z})

--- save work
local saveTable = {};
saveTable.startX = x;
saveTable.startY = y;
saveTable.startZ = z;
saveTable.width = bb.x - aa.x;
saveTable.height = bb.z - aa.z;
saveTable.map = {};
saveTable.born = {};

for xx = 1, saveTable.width do
	saveTable.map[xx] = {};
	for yy = 1, saveTable.height do
		saveTable.map[xx][yy] = Constant.GRID_WAY;
	end
end

for i = 1, #stageTable do
	local gridMsg = stageTable[i]
	--echo("gridMsg.id:" .. gridMsg.id)
	if gridMsg.id == Constant.GRID_BLOCK then
		saveTable.map[gridMsg.x][gridMsg.z] = Constant.GRID_BLOCK;
	elseif Constant.START_POINT[gridMsg.id] ~= nil then
		saveTable.map[gridMsg.x][gridMsg.z] = Constant.GRID_BORN;
		saveTable.born[#saveTable.born + 1] = {x = gridMsg.x, y = gridMsg.z};
	else
		saveTable.map[gridMsg.x][gridMsg.z] = Constant.GRID_BREAK;
	end
end
local st = saveWorldData(getActorValue("name"), saveTable);