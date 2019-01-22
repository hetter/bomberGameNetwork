local function onClone(param)
	if param.obj_name == "eff_fire" then
		setActorValue("movieactor", param.obj_name);
		setPos(param.x, param.y, param.z);
		wait(0.5);
		delete();
	elseif param.obj_name == "eff_item_range" then
		setActorValue("name", param.actor_name);
		setActorValue("movieactor", param.obj_name);
		setPos(param.x, param.y, param.z);
	end
end
registerCloneEvent(onClone);

delete();