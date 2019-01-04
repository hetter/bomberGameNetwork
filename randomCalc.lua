local Random = inherit(nil, gettable("BM_random"));

Random.z = 123;                     
local function schrage_next()
	local a = 16807;		
	local c = 0;
	local m = 2147483647;  
	local q = m / a;      
	local r = m % a;        
	local _z = a * (Random.z % q) - r * math.floor((Random.z / q) + c); 
	if(_z < 0)then
		_z = _z + m; 
	end
	Random.z = _z;
	return Random.z;
end

function Random.srand(seed)
	Random.z = seed;
end

function Random.rand(var1, var2)
	return var1 + math.floor(schrage_next() % (var2 - var1));
end