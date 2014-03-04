-- by mor2000

-- DumpTrigger (for dumping stuff out of shovels and combines)


local UPK_DumpTrigger_mt = ClassUPK(UPK_DumpTrigger,UniversalProcessKit)
InitObjectClass(UPK_DumpTrigger, "UPK_DumpTrigger")
UniversalProcessKit.addModule("dumptrigger",UPK_DumpTrigger)

function UPK_DumpTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_DumpTrigger_mt)
	registerObjectClassName(self, "UPK_DumpTrigger")
	self.addNodeObject=true
	return self
end

function UPK_DumpTrigger:load(id, parent)
	if not UPK_DumpTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading DumpTrigger failed',true)
		return false
	end

	-- dummies for combines
	
	self.fillRootNode=id
	self.exactFillRootNode=id
	self.fillAutoAimTargetNode=id
	self.exactFillRootNode=id
	self.allowFillFromAir=true
	g_currentMission.nodeToVehicle[self.nodeId]=self

	self.fillLevel=0
	self.resetFillLevelIfNeeded=self.setFillType
	self.addFillLevel=self.setFillLevel
	
	for k,v in pairs(self.acceptedFillTypes) do
		self:print('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[v])..' ('..tostring(v)..')')
	end
	
	self:print('accepting sugarBeet? '..tostring(self.acceptedFillTypes[UniversalProcessKit.fillTypeNameToInt["sugarBeet"]]))
	
	self:print('loaded DumpTrigger successfully')
	return true
end

function UPK_DumpTrigger:delete()
	g_currentMission.nodeToVehicle[self.nodeId]=nil
	UPK_DumpTrigger:superClass().delete(self)
end

function UPK_DumpTrigger:setFillLevel(fillLevel,fillType)
	if self.parent==nil then
		self:print('Error: dumptrigger \"'..tostring(self.name)..'\" needs a parent')
		return 0
	end
	return self.parent:addFillLevel(fillLevel,fillType)
end

function UPK_DumpTrigger:allowFillType(fillType)
	local r=self.isEnabled and fillType ~= Fillable.FILLTYPE_UNKNOWN and self.acceptedFillTypes[fillType]
	--self:print('UPK_DumpTrigger:allowFillType('..tostring(filltype)..') = '..tostring(r))
	return r
end

function UPK_DumpTrigger:getAllowFillFromAir()
	--self:print('UPK_DumpTrigger:getAllowFillFromAir')
	return self.isEnabled
end

function UPK_DumpTrigger:getIsAttachedTo(combine)
	return false
end

function UPK_DumpTrigger:addShovelFillLevel(shovel, delta, fillType)
	local r=self.parent:addFillLevel(delta,fillType)
	--self:print('UPK_DumpTrigger:addShovelFillLevel('..tostring(shovel)..', '..tostring(delta)..', '..tostring(fillType)..') = '..tostring(r))
	return r
end

function UPK_DumpTrigger:getAllowShovelFillType(fillType)
	local r=self.isEnabled and self:allowFillType(fillType) and self.fillLevels[fillType]<self.capacity
	--self:print('UPK_DumpTrigger:getAllowShovelFillType('..tostring(filltype)..') = '..tostring(r))
	return r
end
