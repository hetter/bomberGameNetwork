local Random = inherit(nil, gettable("BM_random"));

                   
function Random:_schrage_next()
	local a = 16807;		
	local c = 0;
	local m = 2147483647;  
	local q = m / a;      
	local r = m % a;        
	local _z = a * (self._z % q) - r * math.floor((self._z / q) + c); 
	if(_z < 0)then
		_z = _z + m; 
	end
	self._z = _z;
	return self_.z;
end

function Random:ctor()
	self._z = 123;
end

function Random:srand(seed)
	self._z = seed;
end

function Random:rand(var1, var2)
	return var1 + math.floor(self:_schrage_next() % (var2 - var1));
end

gRandom = Random.new();