local function onClone(param)
	--setActorValue("movieactor", param.obj_name);
	setActorValue("name", param.actor_name);
	local startPoint = param.pos;	
	setPos(startPoint.x, startPoint.y, startPoint.z);
end
registerCloneEvent(onClone);
hide();