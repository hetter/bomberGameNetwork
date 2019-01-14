local desc = gettable("BM_ProtocolDesc");
local Protocol = gettable("BM_Protocol");

include("npl/netMessage.lua");
local Message = gettable("BM_NetMessage");

local tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("keepworkUsername", Protocol.PT_MiniString),
};
local request_echo = Protocol.new();
request_echo:init(tmp);
desc[Message.REQUEST_ECHO] = request_echo;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("port", Protocol.PT_UShort),
	Protocol.defineDesc("keepworkUsername", Protocol.PT_MiniString),
};
local response_echo = Protocol.new();
response_echo:init(tmp);
desc[Message.RESPONSE_ECHO] = response_echo;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("keepworkUsername", Protocol.PT_MiniString),
};
local request_login = Protocol.new();
request_login:init(tmp);
desc[Message.REQUEST_LOGIN] = request_login;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
};
local response_login = Protocol.new();
response_login:init(tmp);
desc[Message.RESPONSE_LOGIN] = response_login;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	-- key:客户端帧数，value:客户端输入
	Protocol.defineDesc("input_map", Protocol.PT_Map(Protocol.PT_UInt, Protocol.PT_UShort)),	
};
local client_frame = Protocol.new();
client_frame:init(tmp);
desc[Message.CLIENT_FRAME] = client_frame;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("frame", Protocol.PT_UInt),
	Protocol.defineDesc("input_map_array_array", Protocol.PT_MiniArray(Protocol.PT_MiniArray(Protocol.PT_Map(Protocol.PT_UInt, Protocol.PT_UShort)))),	
};
local server_frame = Protocol.new();
server_frame:init(tmp);
desc[Message.SERVER_FRAME] = server_frame;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("frame", Protocol.PT_UInt),
};
local server_frame_confirm = Protocol.new();
server_frame_confirm:init(tmp);
desc[Message.SERVER_FRAME_CONFIRM] = server_frame_confirm;

tmp =
{
	Protocol.defineDesc("messageType", Protocol.PT_UShort),
	Protocol.defineDesc("frame", Protocol.PT_UInt),
};
local client_frame_confirm = Protocol.new();
client_frame_confirm:init(tmp);
desc[Message.CLIENT_FRAME_CONFIRM] = client_frame_confirm;


