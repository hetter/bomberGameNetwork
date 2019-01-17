local Protocol = inherit(nil, gettable("BM_Protocol"));

-- 数据类型
Protocol.PT_MIN			= 1;
-- bool，1字节
Protocol.PT_Bool 		= 1;
-- 无符号uchar
Protocol.PT_UChar 		= 2;
-- 有符号char，1字节
Protocol.PT_Char 		= 3;
-- 有符号short，2字节
Protocol.PT_Short 		= 4;
-- 无符号ushort，2字节
Protocol.PT_UShort 		= 5;
-- 有符号int，4字节
Protocol.PT_Int 		= 6;
-- 无符号uint，4字节
Protocol.PT_UInt 		= 7;
-- 浮点数，4字节
Protocol.PT_Float 		= 8;
-- 长整形，int64，8字节,  保存的时候还是double，超过48位会出现误差
Protocol.PT_LLong 		= 9;
-- 双精度浮点数
Protocol.PT_Double 		= 10;
-- 字符串，使用UTF8编码，先保存1字节长度，再保存字符串数据
Protocol.PT_MiniString	= 11;
-- 字符串，使用UTF8编码，先保存2字节长度，再保存字符串数据
Protocol.PT_String		= 12;
-- 字符串，使用UTF8编码，先保存4字节长度，再保存字符串数据
Protocol.PT_LargeString	= 13;
-- zlib压缩的数据流, 估计不会用到， 用到了再实现洛
Protocol.PT_MAX 		= 13;

function Protocol._readBool(stream)
	return (stream:ReadByte() == 1);
end

function Protocol._writeBool(stream, writeValue)
	if writeValue then
		stream:WriteByte(1);
	else	
		stream:WriteByte(0);
	end
end

-- 定义描述类型
function Protocol.defineDesc(name, valueType, default, isLocal, checkValue)
	assert(name, "key值不能为空");
	return {name = name; valueType = valueType; default = default; isLocal = isLocal, checkValue = checkValue};
end

-- 自定义类型
function Protocol.PT_Custom(name, readFunc, customData, writeFunc)
	assert(name, "key值不能为空");
	assert(readFunc, "readFunc不能为空");
	assert(customData, "customData不能为空");
	return {name = name; readFunc = readFunc; writeFunc = writeFunc; customData = customData};
end

-- map
function Protocol.PT_Map(keyType, valueType)
	local function readFunc(stream, customData, name, isDebug)
		local result = {};
		local len = stream:ReadUShort();
		
		for i = 1, len do
			local key = Protocol._readStream(stream, customData.keyType, name, isDebug, true);
			local value = Protocol._readStream(stream, customData.valueType, name, isDebug, true);
			result[key] = value;
		end
		
		return result;
	end
	
	local function writeFunc(stream, customData, writeValue)
		local mapArray = {};
		for key, value in pairs(writeValue) do
			mapArray[#mapArray + 1] = {key = key, value = value};
		end
		
		local len = #mapArray;
		stream:WriteUShort(len);
		for i = 1, len do
			local _t = mapArray[i];
			Protocol._writeStream(stream, customData.keyType, _t.key)
			Protocol._writeStream(stream, customData.valueType, _t.value)
		end	
	end	
	return Protocol.PT_Custom("PT_Map", readFunc, {keyType = keyType; valueType = valueType}, writeFunc);
end

-- array
function Protocol.PT_Array(valueType)
	local function readFunc(stream, customData, name, isDebug)
		local result = {};
		local len = stream:ReadUShort();
		
		for i = 1, len do
			local value = Protocol._readStream(stream, customData.valueType, name, isDebug, true);
			table.insert(result, value);
		end
		
		return result;
	end
	
	local function writeFunc(stream, customData, writeValue)
		local len = #writeValue;
		stream:WriteUShort(len);
		for i = 1, len do
			local aeWriteValue = writeValue[i];
			Protocol._writeStream(stream, customData.valueType, aeWriteValue)
		end
	end
	return Protocol.PT_Custom("PT_Array", readFunc, {valueType = valueType}, writeFunc);
end

-- 短数组
function Protocol.PT_MiniArray(valueType)
	local function readFunc(stream, customData, name, isDebug)
		local result = {};
		local len = stream:ReadByte();
		
		for i = 1, len do
			local value = Protocol._readStream(stream, customData.valueType, name, isDebug, true);
			table.insert(result, value);
		end
		
		return result;
	end
	
	local function writeFunc(stream, customData, writeValue)
		local len = #writeValue;
		stream:WriteByte(len);
		for i = 1, len do
			local aeWriteValue = writeValue[i];
			Protocol._writeStream(stream, customData.valueType, aeWriteValue)
		end
	end	
	return Protocol.PT_Custom("PT_MiniArray", readFunc, {valueType = valueType}, writeFunc);
end


function try(args)
	if type(args) ~= "table" then
		commonlib.echo("try block use error!")
		commonlib.echo(commonlib.debugstack(2, 5, 1))
		return
	end
	
	if type(args[2]) ~= "function" then
		commonlib.echo("the catch function is nil!")
		commonlib.echo(commonlib.debugstack(2, 5, 1))
		return		
	end
	local __errorhandler = #args >= 2 and args[2];
	args.catch = args.catch or __errorhandler
	local _,ret = xpcall(args[1],args.catch)
	return ret
end

function Protocol:init(desc, dymanicType)
	self.mDesc = desc;
	self.mDymanicType = dymanicType;
end

function Protocol:readStream(stream, isDebug, notTop)
	local result = {};
	local desc = self.mDesc;
	local bitMark;
	if self.mDymanicType then
		bitMark = Protocol._readStream(stream, self.mDymanicType, "bitMark", isDebug, true);
	end
	
	for index, v in ipairs(desc) do
		local bStop = false;
		
		repeat
			if self.mDymanicType then
				--local bit = mathlib.bit;
				local writeMark = bit.lshift(1,index);
				if bit.band(bitMark, writeMark) == 0 then
					break;
				end
			end
		
			local valueType = v.valueType;
			local name = v.name;
			local value = v.default;
		
			if isDebug then
				commonlib.echo(string.format("start read [%s] data", tostring(name)));
			end
		
			if not v.isLocal then
				
					try 
					{
						function()
							value = Protocol._readStream(stream, valueType, name, isDebug, true);
						end;
						
						function()
							try
							{
								function()
									stream:seek(0);
									self:readStream(stream, true);
								end;
								
								function(msg)
									__G__TRACKBACK__(msg);
									bStop = true;
								end
							}
						end
					};
			end

			result[name] = value;
		
		until true
		
		if v.checkValue and v.checkValue ~= value then
			break;
		end
		
		if bStop then
			break;
		end
	end
	
	return result;
end

function Protocol:sendStream(writeTable)
	local stream = self:createStream(writeTable);
	local sendDecode;
	if stream then
		sendDecode = stream:GetText(0, -1);
		-- to do
		stream:close();
	end
end


function Protocol:createStream(writeTable)
	local stream = ParaIO.open("<memory>", "w");
	if(stream:IsValid()) then	
		self:writeStream(stream, writeTable);
		stream:seek(0);
		return stream;
	end
end

function Protocol:writeStream(stream, writeTable)
	local function doWrite(stream, valueType, wv)
		if notTop or isDebug then
			Protocol._writeStream(stream, valueType, wv);
		else
			try 
			{
				function()
					Protocol._writeStream(stream, valueType, wv);
				end;
				
				function()
					try
					{									
						function(msg)
							__G__TRACKBACK__(msg);
							bStop = true;
						end
					}
				end
			};
		end
	end	
	
	local desc = self.mDesc;
	local bitMark = 0;
	local writeList = {};
	for index, v in ipairs(desc) do
		local valueType = v.valueType;
		local name = v.name;
		local bStop = false;
		
		if (writeTable[name]) then
			if self.mDymanicType then
				--local bit = mathlib.bit;
				local writeMark = bit.lshift(1,index);
				bitMark = bit.bxor(bitMark, writeMark);
				writeList[#writeList + 1] = {tt = valueType, ww = writeTable[name]};
			else	
				if not v.isLocal then
					doWrite(stream, valueType, writeTable[name]);
				end	
			end				
		else
			if not self.mDymanicType then
				commonlib.echo("mDymanicTypemDymanicTypemDymanicTypemDymanicTypemDymanicType:" .. name)
				bStop = true;
			end	
		end
		
		if bStop then
			commonlib.echo("bStopbStopbStopbStopbStopbStopbStopbStop:" .. name)
			stream:close();
			return nil;
		end
	end
	
	if self.mDymanicType then
		Protocol._writeStream(stream, self.mDymanicType, bitMark);
		for index, v in ipairs(writeList) do
			Protocol._writeStream(stream, v.tt, v.ww);
		end
	end
end	


function Protocol._readStream(stream, valueType, name, isDebug, notTop)
		
	--print("开始读取字段 [" .. tostring(name) .. "]");
	
	local value;
	if type(valueType) == "number" then
		assert(valueType >= Protocol.PT_MIN and valueType <= Protocol.PT_MAX
						, "未知的valueType [" .. tostring(name) .. "]");
						
		value = Protocol._readValue(stream, valueType, name);
	elseif type(valueType) == "table" then
		if valueType.name then
			value = Protocol._readCustom(stream, valueType, name, isDebug);
		elseif valueType.readStream then
			value = valueType:readStream(stream, isDebug, notTop);
		else
			assert(false, "未知的数据类型[" .. tostring(name) .. "]");
		end
	end
	
	return value;
end


-- 读取自定义
function Protocol._readCustom(stream, valueType, name, isDebug)
	return valueType.readFunc(stream, valueType.customData, name, isDebug);
end

function Protocol._writeCustom(stream, valueType, writeValue)
	return valueType.writeFunc(stream, valueType.customData, writeValue);
end

-- 读取一个64位整型
function Protocol._readLLong(stream)
	assert(false, "暂时没实现， 到时再说");
end

function Protocol._writeLLong(stream)
	assert(false, "-------------------");
end


-- 读取一个值
function Protocol._readValue(stream, valueType, name)
	if valueType == Protocol.PT_Bool then
		return Protocol._readBool(stream);
	elseif valueType == Protocol.PT_UChar then
		return stream:ReadByte();
	elseif valueType == Protocol.PT_Char then
		return stream:ReadByte();
	elseif valueType == Protocol.PT_Short then
		return stream:ReadShort();
	elseif valueType == Protocol.PT_UShort then
		return stream:ReadUShort();
	elseif valueType == Protocol.PT_Int  then
		return stream:ReadInt();
	elseif valueType == Protocol.PT_UInt then
		return stream:ReadUInt(); 
	elseif valueType == Protocol.PT_Float then
		return stream:ReadFloat();
	elseif valueType == Protocol.PT_LLong then
		return Protocol._readLLong(stream); 
	elseif valueType == Protocol.PT_Double then
		return stream:ReadDouble();
	elseif valueType == Protocol.PT_MiniString then
		local len = stream:ReadByte();
		return stream:ReadString(len);
	elseif valueType == Protocol.PT_String then
		local len = stream:ReadShort();
		return stream:ReadString(len);
	elseif valueType == Protocol.PT_LargeString then
		local len = stream:ReadUInt();
		return stream:ReadString(len);
	end
end

function Protocol._writeStream(stream, valueType, writeValue)
	if valueType == Protocol.PT_Bool then
		return Protocol._writeBool(stream, writeValue);
	elseif valueType == Protocol.PT_UChar then
		return stream:WriteByte(writeValue);
	elseif valueType == Protocol.PT_Char then
		return stream:WriteByte(writeValue);
	elseif valueType == Protocol.PT_Short then
		return stream:WriteShort(writeValue);
	elseif valueType == Protocol.PT_UShort then
		return stream:WriteUShort(writeValue);
	elseif valueType == Protocol.PT_Int  then
		return stream:WriteInt(writeValue);
	elseif valueType == Protocol.PT_UInt then
		return stream:WriteUInt(writeValue); 
	elseif valueType == Protocol.PT_Float then
		return stream:WriteDouble(writeValue);
	elseif valueType == Protocol.PT_LLong then
		return Protocol._writeLLong(stream); 
	elseif valueType == Protocol.PT_Double then
		return stream:WriteDouble(writeValue);
	elseif valueType == Protocol.PT_MiniString then
		stream:WriteByte(#writeValue);
		return stream:WriteString(writeValue);
	elseif valueType == Protocol.PT_String then
		stream:WriteShort(#writeValue);
		return stream:WriteString(writeValue);
	elseif valueType == Protocol.PT_LargeString then
		stream:WriteUInt(#writeValue);
		return stream:WriteString(writeValue);
	elseif type(valueType) == "table" then
		if valueType.name then
			value = Protocol._writeCustom(stream, valueType, writeValue);
		elseif valueType.writeStream then
			valueType.writeStream(valueType, stream, writeValue);	
		end	
	end	
end

return Protocol;