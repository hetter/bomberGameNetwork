local message = gettable("BM_NetMessage");

message.MagicCode 	= "\19\85";
message.Version 	= "\10\0"; 
message.Head 		= message.MagicCode .. message.Version;

--[[
	udp 
	{keepworkUsername = keepworkUsername}
--]]
message.REQUEST_ECHO		= 1;

--[[
	udp
	{port = 8099, keepworkUsername = keepworkUsername}
]]
message.RESPONSE_ECHO		= 2;

--[[
	udp
]]
message.CLIENT_FRAME		= 3;

--[[
	udp
]]
message.SERVER_FRAME		= 4;

--[[
	udp
]]
message.CLIENT_FRAME_CONFIRM		= 5;

--[[
	udp
]]
message.SERVER_FRAME_CONFIRM		= 6;

--[[
	udp
]]
message.REQUEST_LOGIN		= 7;

--[[
	udp
]]
message.RESPONSE_LOGIN		= 8;

---------------------------------------------

--[[
	tcp
]]
message.LOGIN_INFO = 101;

--[[
	tcp
]]
message.READY_STAGE = 102;