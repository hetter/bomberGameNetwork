local message = gettable("BM_Message");

message.MagicCode 	= "\19\85";
message.Version 	= "\10\0"; 
message.Head 		= message.MagicCode .. message.Version;

--[[
	udp 
	{name = keepworkUsername}
--]]
message.REQUEST_ECHO		= 1;

--[[
	udp
	{port = 8099, name = keepworkUsername}
]]
message.RESPONSE_ECHO		= 2;