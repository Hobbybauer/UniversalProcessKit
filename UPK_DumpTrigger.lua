-- by mor2000

-- DumpTrigger (for dumping stuff out of shovels and combines)

UPK_DumpTrigger={}
local UPK_DumpTrigger_mt = ClassUPK(UPK_DumpTrigger,UniversalProcessKit)
InitObjectClass(UPK_DumpTrigger, "UPK_DumpTrigger")
UniversalProcessKit.addModule("dumptrigger",UPK_DumpTrigger)

function UPK_DumpTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_DumpTrigger_mt)
	registerObjectClassName(self, "UPK_DumpTrigger")
	return self
end

function UPK_DumpTrigger:load(id, parent)
	if not UPK_DumpTrigger:superClass().load(self, id, parent) then
		print('Error: loading DumpTrigger failed',true)
		return false
	end

	-- dummies for combines
	
	self.fillRootNode=id
	self.exactFillRootNode=id
	self.fillAutoAimTargetNode=id
	self.fillLevel=0
	self.resetFillLevelIfNeeded=self.setFillType
	self.addFillLevel=self.setFillLevel
	
	print('loaded DumpTrigger successfully')
	return true
end

function UPK_DumpTrigger:delete()
	UPK_DumpTrigger:superClass().delete(self)
end

function UPK_DumpTrigger:setFillLevel(fillLevel,fillType)
	if self.parent==nil then
		print('Error: dumptrigger \"'..tostring(self.name)..'\" needs a parent')
		return 0
	end
	return self.parent:addFillLevel(fillLevel,fillType)
end

function UPK_DumpTrigger:allowFillType(fillType)
	return self.isEnabled and fillType ~= Fillable.FILLTYPE_UNKNOWN and self.acceptedFillTypes[fillType]
end

function UPK_DumpTrigger:getAllowFillFromAir()
	return self.isEnabled
end

function UPK_DumpTrigger:getIsAttachedTo(combine)
	return false
end

function UPK_DumpTrigger:addShovelFillLevel(shovel, delta, fillType)
	return self.parent:addFillLevel(delta,fillType)
end

function UPK_DumpTrigger:getAllowShovelFillType(fillType)
	return self.isEnabled and self:allowFillType(fillType) and self.fillLevels[fillType]<self.capacity
end
