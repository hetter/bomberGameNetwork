local pool = gettable("BM_ObjPool");

local s_seed = 0;
function getSeed()
	s_seed = s_seed + 1;
	return s_seed;
end

pool.objs = {};

function pool:createObj(type, num)
	pool.objs[type] = pool.objs[type] or {};
	
	local objs = pool.objs[type];

	local name;
	for i = 1, num do
		name = type .. "_" .. getSeed();
		clone(type, {name = name, isShow = false, type = type});
		table.insert(objs, name);
	end
end

function pool:getObj(type)
	pool.objs[type] = pool.objs[type] or {};
	
	local objs = pool.objs[type];
	local obj;
	if #objs > 0 then
		obj = objs[#objs];
		table.remove(objs);
		runForActor(obj, show);
	else
		obj = name = type .. "_" .. getSeed();
		clone(type, {name = name, isShow = true, type = type});
	end

	return obj;
end

function pool:releaseObj(obj)
	local actor = getActor(obj);
	if actor then
		local type = actor:GetActorValue("ObjType");
		pool.objs[type] = pool.objs[type] or {};
		local objs = pool.objs[type];
		table.insert(objs, obj);
		
		runForActor(obj, hide);
	else
		assert(false, "无效的池对象 : " .. tostring(obj));
	end
end