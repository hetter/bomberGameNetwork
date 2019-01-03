local message = gettable("BM_Message");

--[[
	udp 
	{name = keepworkUsername, projectId = 900, version = 1001, editMode = true/false}
--]]
message.REQUEST_ECHO		= 1;

--[[
	udp
	{port = 8099, name = keepworkUsername}
]]
message.RESPONSE_ECHO		= 2;