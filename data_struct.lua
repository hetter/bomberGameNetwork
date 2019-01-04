local Vctor = inherit(nil, gettable("BM_Vctor"));

function Vctor:ctor()
	self._data = {};
end

function Vctor:size()
	return #self._data;
end

function Vctor:set(index, ele)
	if index >= 1 and index <= #self._data then
		self._data[index] = ele;
	end
end

function Vctor:get(index)
	if index >= 1 and index <= #self._data then
		return self._data[index];
	end
end

function Vctor:fast_get(index)
	return self._data[index];
end

function Vctor:fast_remove(index)
	table.remove(self._data, index);
end

function Vctor:remove(index)
	if index  then
		if  index >= 1 and index <= #self._data then
			table.remove(self._data, index);
		end
	else	
		table.remove(self._data);
	end
end

function Vctor:push_back(ele)
	table.insert(self._data, ele);
end

function Vctor:pop_back()
	table.remove(self._data);
end


function Vctor:back()
	return self._data[#self._data];
end

function Vctor:empty()
	return #self._data == 0;
end

function Vctor:front()
	return self._data[1];
end

function Vctor:pop_front()
	table.remove(self._data, 1);
end

function Vctor:pairs()
	local i = 0;
	return function()
			i = i + 1;
			if i > #self._data then
				return nil;
			else
				return i,self._data[i];
			end
		end;
end

