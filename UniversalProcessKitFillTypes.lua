-- by mor2000

-- enables more fillTypes, ie. bales, animals or including dummies
-- works on the fly, just use UniversalProcessKit.fillTypeNameToInt("yourFillType") to initialize fillType

UniversalProcessKit.fillTypeNameToInt={}
UniversalProcessKit.fillTypeIntToName={}

for k,v in pairs(Fillable.fillTypeNameToInt) do
	UniversalProcessKit.fillTypeNameToInt[k]=v
	UniversalProcessKit.fillTypeIntToName[v]=k
end
UniversalProcessKit.NUM_FILLTYPES = Fillable.NUM_FILLTYPES

local fillTypeNameToInt_mt={
	__call=function(func,...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			local type=type(v)
			if type=="string" then
				if rawget(UniversalProcessKit.fillTypeNameToInt,v)==nil then
					UniversalProcessKit.addFillType(v) -- add fillTypes as used
				end
				table.insert(t,UniversalProcessKit.fillTypeNameToInt[v])
			end
		end
		return t
		end,
	__newindex=function(t,k,v)
		UniversalProcessKit.addFillType(v)
		end
	}

local fillTypeIntToName_mt={
	__call=function(func,...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			local type=type(v)
			if type=="number" then
				if UniversalProcessKit.fillTypeIntToName[v]~=nil then
					table.insert(t,UniversalProcessKit.fillTypeIntToName[v])
				end
			end
		end
		return t
		end
	}

setmetatable(UniversalProcessKit.fillTypeNameToInt,fillTypeNameToInt_mt)
setmetatable(UniversalProcessKit.fillTypeIntToName,fillTypeIntToName_mt)

function UniversalProcessKit.addFillType(name,index)
	if type(name)=="table" then
		for k,v in pairs(name) do
			UniversalProcessKit.addFillType(v)
		end
	elseif type(name)=="string" then
		local fillType=rawget(Fillable.fillTypeNameToInt,name)
		if fillType~=nil then
			oldFillTypeName=UniversalProcessKit.fillTypeIntToName[fillType]
			rawset(UniversalProcessKit.fillTypeIntToName,fillType,name)
			rawset(UniversalProcessKit.fillTypeNameToInt,name,fillType)
			
			if oldFillTypeName~=nil then -- spot at fillType is already used
				UniversalProcessKit.addFillType(oldFillTypeName)
			end
		else
			local index=index or Fillable.NUM_FILLTYPES
			if UniversalProcessKit.fillTypeIntToName[index]~=nil then
				UniversalProcessKit.addFillType(name,index+1)
			else
				if name~="money" then
					print(" [UniversalProcessKit] Notice: Filltype labeled \""..tostring(name).."\" is not part of the game economy")
				else
					UniversalProcessKit.FILLTYPE_MONEY=index
				end
				print(" [UniversalProcessKit] Notice: adding "..tostring(name).." ("..tostring(index)..") to fillTypes")
				rawset(UniversalProcessKit.fillTypeIntToName,index,name)
				rawset(UniversalProcessKit.fillTypeNameToInt,name,index)
				UniversalProcessKit.NUM_FILLTYPES=UniversalProcessKit.NUM_FILLTYPES+1
			end
		end
	end
end

function UniversalProcessKit.registerFillType(name, hudFilename)
	Fillable.registerFillType(name, nil, nil, true, hudFilename)
	UniversalProcessKit.addFillType(name)
end

-- special fillType "money"
UniversalProcessKit.addFillType("money")
