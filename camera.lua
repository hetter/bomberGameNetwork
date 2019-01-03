cmd("/stopLobbyServer");
-- 开启lobyy server 并且不使用自动扫描模式
cmd("/startLobbyServer false");

include("npl/protocol.lua");
include("npl/desc.lua");
include("npl/netMessage.lua");
include("npl/network.lua");

