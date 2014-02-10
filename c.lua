-- by mor2000

-- adds arithmetic operations to tables

-- functionality for c() like in R, and a little more

-- examples:

-- same length
-- c(1) = {1}
-- c({1,2,3}) + c({4,5,6}) = {5,7,9}
-- c({1,2,3}) - c({4,5,6}) = {-3,-3,-3}
-- c({1,2,3}) * c({4,5,6}) = {4,10,18}
-- c({1,2,3}) / c({4,5,6}) = {0.25,0.4,0.5}
-- c({1,2,3}):min() = 1
-- c({1,2,3}):max() = 3

-- different length + - * /
-- c({1,2,3}) + c({2,3}) = {3,5,5}

-- with keys left (same like above with keys) + - * /
-- c({a=1,b=2,c=3}) + c({2,3}) = {a=3,b=5,c=5}

-- keys left and right (same, only take matching keys into account) + - * /
-- c({a=1,b=2,c=3}) + c({b=2,d=4}) = {b=4}

_m=_G;_G=nil;_g=_G;_G=_m;

function _m.print(string, debug)
	if debug==nil then
		debug=debugMode
	end
	if type(string)=="string" then
		local msg=string
		if debug then
			msg='DEBUG '..msg
		end
		_g.print(' [UPK] '..msg)
	end
end

function InitEventClass(classObject,className)
	if _g[className]~=classObject then
		print("Error: Can't assign eventId to "..tostring(className).." (object name conflict)",true)
		return
	end
	_g.InitEventClass(classObject,className)
	if classObject.eventId==nil then
		EventIds.assignEventObjectId(classObject,className,EventIds.eventIdNext)
	end
end

function _g.__c(arr)
	if type(arr)~="table" then
		arr={arr}
	end
	local c_mt={
		__index=function(arr,key)
			if type(key)=="number" and key>1 then
				return arr[(key-1) % #arr +1]
			end
			return nil
		end,
		__add = function(lhs,rhs)
			local arr={}
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then -- exclude functions
						arr[k]=v+rhs
					end
				end
			elseif rhs~=nil then
				if #lhs==0 then -- table has (only) keys
					local i=1
					for k,v in pairs(lhs) do
						if type(v)=="number" then -- exclude functions
							if type(rhs[k])=="number" then
								arr[k]=lhs[k]+rhs[k]
							elseif type(rhs[i])=="number" then
								arr[k]=lhs[k]+rhs[i]
								i=i+1
							end
						end
					end
				else
					for i=1,#lhs do
						if rhs[i]~=nil then
							table.insert(arr,i,lhs[i]+rhs[i])
						else
							table.insert(arr,i,lhs[i])
						end
					end
				end
			end
			return __c(arr)
		end,
		__sub = function(lhs,rhs)
			local arr={}
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then -- exclude functions
						arr[k]=v-rhs
					end
				end
			elseif rhs~=nil then
				if #lhs==0 then -- table has (only) keys
					local i=1
					for k,v in pairs(lhs) do
						if type(v)=="number" then -- exclude functions
							if type(rhs[k])=="number" then
								arr[k]=lhs[k]-rhs[k]
							elseif type(rhs[i])=="number" then
								arr[k]=lhs[k]-rhs[i]
								i=i+1
							end
						end
					end
				else
					for i=1,#lhs do
						if rhs[i]~=nil then
							table.insert(arr,i,lhs[i]-rhs[i])
						else
							table.insert(arr,i,lhs[i])
						end
					end
				end
			end
			return __c(arr)
		end,
		__mul = function(lhs,rhs)
			local arr={}
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then -- exclude functions
						arr[k]=v*rhs
					end
				end
			elseif rhs~=nil then
				if #lhs==0 then -- table has (only) keys
					local i=1
					for k,v in pairs(lhs) do
						if type(v)=="number" then -- exclude functions
							if type(rhs[k])=="number" then
								arr[k]=lhs[k]*rhs[k]
							elseif type(rhs[i])=="number" then
								arr[k]=lhs[k]*rhs[i]
								i=i+1
							end
						end
					end
				else
					for i=1,#lhs do
						if rhs[i]~=nil then
							table.insert(arr,i,lhs[i]*rhs[i])
						else
							table.insert(arr,i,nil)
						end
					end
				end
			end
			return __c(arr)
		end,
		__div = function(lhs,rhs)
			local arr={}
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then -- exclude functions
						arr[k]=v/rhs
					end
				end
			elseif rhs~=nil then
				if #lhs==0 then -- table has (only) keys
					local i=1
					for k,v in pairs(lhs) do
						if type(v)=="number" then -- exclude functions
							if type(rhs[k])=="number" then
								arr[k]=lhs[k]/rhs[k]
							elseif type(rhs[i])=="number" then
								arr[k]=lhs[k]/rhs[i]
								i=i+1
							end
						end
					end
				else
					for i=1,#lhs do
						if rhs[i]~=nil then
							table.insert(arr,i,lhs[i]/rhs[i])
						else
							table.insert(arr,i,nil)
						end
					end
				end
			end
			return __c(arr)
		end,
		__mod = function(lhs,rhs)
			local arr={}
			if type(rhs)=="number" then
				for k,v in pairs(lhs) do
					if type(v)=="number" then -- exclude functions
						arr[k]=v%rhs
					end
				end
			elseif rhs~=nil then
				if #lhs==0 then -- table has (only) keys
					local i=1
					for k,v in pairs(lhs) do
						if type(v)=="number" then -- exclude functions
							if type(rhs[k])=="number" then
								arr[k]=lhs[k]%rhs[k]
							elseif type(rhs[i])=="number" then
								arr[k]=lhs[k]%rhs[i]
								i=i+1
							end
						end
					end
				else
					for i=1,#lhs do
						if rhs[i]~=nil then
							table.insert(arr,i,lhs[i]%rhs[i])
						else
							table.insert(arr,i,nil)
						end
					end
				end
			end
			return __c(arr)
		end,
		__call = function(func, ...)
			local t={}
			local args=...
			if type(args)~="table" then
				args={...}
			end
			for k,v in pairs(args) do
				table.insert(t,k,func[v])
			end
			return __c(t)
		end,
		__concat = function(lhs,rhs) -- not consistent logic yet
			local arr=lhs
			for i=1,#rhs do
				table.insert(arr,rhs[i])
			end
			return __c(arr) 
		end,
		__len=function(t)
			count=0
			for _,v in pairs(t) do
				if type(v)~="function" then
					count=count+1
				end
			end
			return count
		end	
	}
	setmetatable(arr,c_mt)
	function arr:min()
		local nr=math.huge
		if #self>0 then
			for i=1,#self do
				nr=math.min(nr,self[i])
			end
			return nr
		elseif #self==0 then
			for k,v in pairs(self) do
				if type(self[k])=="number" then -- exclude functions
					nr=math.min(nr,v)
				end
			end
			return nr
		end
		return nil
	end
	function arr:max(returnKey)
		local nr=-math.huge
		local key
		if #self>0 then
			for i=1,#self do
				nr=math.max(nr,self[i])
				key=i
			end
		elseif #self==0 then
			for k,v in pairs(self) do
				if type(self[k])=="number" then -- exclude functions
					nr=math.max(nr,v)
					key=k
				end
			end
		end
		if #self>=0 then
			if returnKey then
				return key
			else
				return nr
			end
		end
		return nil
	end
	function arr:getValuesOf(keys)
		if type(keys)~="table" then
			keys={keys}
		end
		local values={}
		for i=1,#keys do
			values[keys[i]]=self[keys[i]]
		end
		return values
	end
	function arr:zeroToNil()
		local values=self
		for i=1,#self do
			if self[i]==0 then
				--values
			end
		end
		return values
	end
	function arr:getKeysAreTrue()
		local r={}
		for k,v in pairs(self) do
			if type(v)~="function" and v then
				table.insert(r,k)
			end
		end
		return r
	end
	return arr
end

function ClassUPK(members, baseClass)
	members = members or {}
	baseClass = baseClass or UniversalProcessKit
	
	setmetatable(members, {__index = baseClass})

	local orphan={}
	orphan.storageType=UPK_Storage.SEPARATE
	orphan.capacity=math.huge

	local mt = { __metatable = members,
		__index=function(t,k)
			if k=='storageType' then
				return (rawget(t,'parent') or orphan).storageType
			elseif k=='capacity' then
				return (rawget(t,'parent') or orphan).capacity
			elseif k=='fillType' then
				local fillType=(rawget(t,'parent') or orphan).fillType
				if fillType==nil then
					local storageType=t.storageType
					if storageType==UPK_Storage.FIFO then
						return 30
					elseif storageType==UPK_Storage.FILO then
						return 40
					else
						return Fillable.FILLTYPE_UNKNOWN
					end
				else
					return fillType
				end
			elseif k=='fillLevel' then
				local fillType=t.fillType
				if fillType==Fillable.FILLTYPE_UNKNOWN then
					return 0
				elseif fillType~=nil then
					return t.fillLevels[fillType]
				else
					return nil
				end		
			else
				return members[k]
			end
		end
	}

	do -- contains GIANTS code only
		local function new(_, init)
			return setmetatable(init or {}, mt)
		end
		local copy = function(obj, ...)
			local newobj = obj:new(unpack(arg))
			for n, v in pairs(obj) do
				newobj[n] = v
			end
			return newobj
		end
		function members:class()
			return members
		end
		function members:superClass()
			return baseClass
		end
		function members:isa(other)
			local ret = false
			local curClass = members
			while curClass ~= nil and ret == false do
				if curClass == other then
					ret = true
				else
					curClass = curClass:superClass()
				end
			end
			return ret
		end
		members.new = members.new or new
		members.copy = members.copy or copy
	end
	
	return mt
end
