-- by mor2000

--------------------
-- Storage


local UPK_Storage_mt = ClassUPK(UPK_Storage)
InitObjectClass(UPK_Storage, "UPK_Storage")
UniversalProcessKit.addModule("storage",UPK_Storage)

function UPK_Storage:new(isServer, isClient, customMt)
	local self = UPK_Storage:superClass().new(self, isServer, isClient, customMt or UPK_Storage_mt)
	registerObjectClassName(self, "UPK_Storage")
	return self
end

function UPK_Storage:load(id)
	if not UPK_Storage:superClass().load(self, id, nil) then
		self:print('Error: loading Storage failed',true)
		return false
	end
	for k,_ in pairs(UniversalProcessKit.fillTypeIntToName) do
		rawset(self.fillLevels,k,0)
	end
	
	self:print("self.storageType="..tostring(self.storageType))
	if self.storageType==UPK_Storage.SINGLE then
		self.fillType=unpack(UniversalProcessKit.fillTypeNameToInt(Utils.getNoNil(getUserAttribute(self.nodeId, "fillType"),"unknown")))
		self:print('self.fillType='..tostring(self.fillType))
	end

	self:print('loaded Storage successfully')
	return true
end

function UPK_Storage:delete()
	UPK_Storage:superClass().delete(self)
end

function UniversalProcessKit:loadExtraNodes(xmlFile, key)
	if self.storageType==UPK_Storage.SINGLE then
		for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
			local fillLevel = getXMLFloat(xmlFile, key .. "#" .. tostring(v))
			if fillLevel~=nil then
				self.fillType=k
				break
			end
		end
	end
	return true
end;

function UPK_Storage:getSaveExtraNodes(nodeIdent)
	local extraNodes=""
	if self.storageType==UPK_Storage.SINGLE then
		local fillLevel=self.fillLevel
		if self.fillLevel==0 then
			local fillTypeStr=UniversalProcessKit.fillTypeIntToName[self.fillType]
			if fillTypeStr~=nil then
				extraNodes = extraNodes .. " " .. tostring(fillTypeStr) .. "=\"" .. tostring(math.floor(fillLevel*1000+0.5)/1000) .. "\""
			end
		end
	end
	return extraNodes
end;
