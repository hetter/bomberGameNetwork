local function onClone(param)
	setActorValue("movieactor", param.obj_name);
	setActorValue("name", param.actor_name);
	local stage = param.stage;	
	local startPoint = stage.born[param.born];	
	setPos(stage.startX + startPoint.x + 0.5, stage.startY + 1, stage.startZ + startPoint.y + 0.5);	
	playLoop(0, 1000);
end
registerCloneEvent(onClone);
hide();