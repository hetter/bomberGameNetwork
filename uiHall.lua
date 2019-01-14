registerCloneEvent(function()
	local _tb = {};
	
	_tb.showText = [[
		font(14);
		color("#ffcccc");
		rect(-50,0,150, %d);
	]];
	
	_tb.height = 0;
	
	_tb.inx = 0;
	
	_tb.addPlayer = function(userName)
		_tb.showText = _tb.showText .. string.format([[color("#ff0000");text("player:%s", -45, %d);]], userName, _tb.height );
		local rc = string.format(_tb.showText, _tb.height + 20);
		setActorValue("rendercode", rc);
		_tb.inx = _tb.inx + 1;		
		_tb.height = _tb.height + 20;
	end
	setActorValue("name", "UI_HallNameList");
	setActorValue("_tb", _tb);
	setPos(0, 0, 0);
	setActorValue("rendercode", [[text("");]]);
	--_tb.addPlayer("sadsasd")
	--_tb.addPlayer("sadsasd3")
	--_tb.addPlayer("sadsasd5")
end)

registerClickEvent(function()
    if getActorValue("name") == "UI_BtnHallStart" then
        --
		broadcast("StageGo");
		hide();
		
		local uiList = getActor("UI_HallNameList");
		runForActor(uiList, function()
			hide();
		end)
    end
end)
setActorValue("name", "UI_BtnHallStart");
hide();
clone("uiHall");