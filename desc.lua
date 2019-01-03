local desc = gettable("BM_ProtocolDesc");
local Protocol = gettable("BM_Protocol");

local tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("keepworkUsername", Protocol.PT_MiniString),
};
desc.request_echo = Protocol.new();
desc.request_echo:init(tmp);


tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("port", Protocol.PT_UShort),
	Protocol.defineDesc("keepworkUsername", Protocol.PT_MiniString),
};
desc.response_echo = Protocol.new();
desc.response_echo:init(tmp);




