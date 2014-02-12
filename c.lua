function tableShow(t, name, indent)
	local cart -- a container
	local autoref -- for self references

	--[[ counts the number of elements in a table
local function tablecount(t)
   local n = 0
   for _, _ in pairs(t) do n = n+1 end
   return n
end
]]
	-- (RiciLake) returns true if the table is empty
	local function isemptytable(t) return next(t) == nil end

	local function basicSerialize(o)
		local so = tostring(o)
		if type(o) == "function" then
			local info = debug.getinfo(o, "S")
			-- info.name is nil because o is not a calling level
			if info.what == "C" then
				return string.format("%q", so .. ", C function")
			else
				-- the information is defined through lines
				return string.format("%q", so .. ", defined in (" ..
						info.linedefined .. "-" .. info.lastlinedefined ..
						")" .. info.source)
			end
		elseif type(o) == "number" then
			return so
		else
			return string.format("%q", so)
		end
	end

	local function addtocart(value, name, indent, saved, field)
		indent = indent or ""
		saved = saved or {}
		field = field or name

		cart = cart .. indent .. field

		if type(value) ~= "table" then
			cart = cart .. " = " .. basicSerialize(value) .. ";\n"
		else
			if saved[value] then
				cart = cart .. " = {}; -- " .. saved[value]
						.. " (self reference)\n"
				autoref = autoref .. name .. " = " .. saved[value] .. ";\n"
			else
				saved[value] = name
				--if tablecount(value) == 0 then
				if isemptytable(value) then
					cart = cart .. " = {};\n"
				else
					cart = cart .. " = {\n"
					for k, v in pairs(value) do
						k = basicSerialize(k)
						local fname = string.format("%s[%s]", name, k)
						field = string.format("[%s]", k)
						-- three spaces between levels
						addtocart(v, fname, indent .. "   ", saved, field)
					end
					cart = cart .. indent .. "};\n"
				end
			end
		end
	end

	name = name or "__unnamed__"
	if type(t) ~= "table" then
		return name .. " = " .. basicSerialize(t)
	end
	cart, autoref = "", ""
	addtocart(t, name, indent)
	return cart .. autoref
end;

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
	if debug then
		if type(string)=="string" then
			local msg=string
			if debug then
				msg='DEBUG '..msg
			end
			_g.print(' [UPK] '..msg)
		end
	end
end;

function InitEventClass(classObject,className)
	if _g[className]~=classObject then
		print("Error: Can't assign eventId to "..tostring(className).." (object name conflict)",true)
		return
	end
	_g.InitEventClass(classObject,className)
	if classObject.eventId==nil then
		EventIds.assignEventObjectId(classObject,className,EventIds.eventIdNext)
	end
end;

function max(...)
	tmpmax=-math.huge
	arr=...
	if type(arr)~="table" then
		arr={...}
	end
	if #arr>0 then
		for _,v in pairs(arr) do
			if v>tmpmax then
				tmpmax=v
			end
		end
		return tmpmax
	end
	return nil
end;

function min(...)
	tmpmin=math.huge
	arr=...
	if type(arr)~="table" then
		arr={...}
	end
	if #arr>0 then
		for _,v in pairs(arr) do
			if v<tmpmin then
				tmpmin=v
			end
		end
		return tmpmin
	end
	return nil
end;

function gmatch(str, pattern)
	local arr={}
	if type(str)=="string" then
		for v in string.gmatch(str,pattern) do
			table.insert(arr,v)
		end
	end
	return arr
end;

function tobool(val)
	return not (val == nil or val == false or val == 0 or val == "0" or val == "false" )
end;

function getVectorFromUserAttribute(nodeId, attribute, default)
	local str=Utils.getNoNil(getUserAttribute(nodeId, attribute), default)
	if type(str)=="string" then
		return __c({Utils.getVectorFromString(str)})
	end
	return str
end;

UPK_Storage={}
UPK_Storage.SEPARATE=1
UPK_Storage.SINGLE=2
UPK_Storage.FIFO=3
UPK_Storage.FILO=4

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
				if type(v)=="number" then -- exclude functions
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
end;

function _g.ClassUPK(members, baseClass)
	members = members or {}
	baseClass = baseClass or UniversalProcessKit
	if baseClass==nil then
		print('Error: can\'t init class - UniversalProcessKit required')
		return nil
	end
	
	setmetatable(members, {__index = baseClass})

	local orphan={} -- default values
	orphan.storageType=UPK_Storage.SEPARATE
	orphan.capacity=math.huge
	orphan.fillType=nil
	orphan.i18nNameSpace=nil
	orphan.maxFillLevel=0

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
					if storageType==UPK_Storage.SINGLE then
						ret=t:getUniqueFillType()
						return ret
					elseif storageType==UPK_Storage.FIFO then
						return nil
					elseif storageType==UPK_Storage.FILO then
						return nil
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
			elseif k=='i18nNameSpace' then
				return (rawget(t,'parent') or orphan).i18nNameSpace
			elseif k=='maxFillLevel' then
				return (rawget(t,'parent') or orphan).maxFillLevel
			else
				return members[k]
			end
		end,
		__newindex=function(t,k,v)
			if k=='maxFillLevel' and type(rawget(t,"parent"))=="table" then
				t.parent.maxFillLevel=v
			else
				rawset(t,k,v)
			end
		end,
	}
	
	function members:print(string, debug)
		if debug==nil then
			debug=debugMode
		end
		if debug then
			if type(string)=="string" then
				local msg=string
				if debug then
					msg='DEBUG '..msg
				end
				local signature=self.className or "unknown"
				_g.print(' ['..tostring(signature)..'] '..msg)
			end
		end
	end	

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
end;
