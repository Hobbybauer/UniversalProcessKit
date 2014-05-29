-- by mor2000

--------------------
-- UPK_BalerTrigger (allows balers and forage wagons to pick up grass etc. by default)

local UPK_BalerTrigger_mt = ClassUPK(UPK_BalerTrigger,UPK_FillTrigger)
InitObjectClass(UPK_BalerTrigger, "UPK_BalerTrigger")
UniversalProcessKit.addModule("balertrigger",UPK_BalerTrigger)

function UPK_BalerTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_BalerTrigger_mt)
	registerObjectClassName(self, "UPK_BalerTrigger")
	self.triggerIds={}
	return self
end

function UPK_BalerTrigger:load(id,parent)
	if not UPK_BalerTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading BalerTrigger failed',true)
		return false
	end

    self.allowTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowTrailer"), false))
    self.allowShovel = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowShovel"), false))
	self.allowSowingMachine = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSowingMachine"), false))
	self.allowWaterTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWaterTrailer"), false))
	self.allowLiquidManureTrailer=tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowLiquidManureTrailer"), false))
	self.allowSprayer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSprayer"), false))
	self.allowFuelTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelTrailer"), false))
	self.allowFuelRefill = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelRefill"), false))
	self.allowMilkTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_MILK)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowMilkTrailer"), false))
	
	self.allowForageWagon = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowForageWagon"), true))
	self.allowBaler = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowBaler"), true))

	self:print('loaded BalerTrigger successfully')
    return true
end

function UPK_BalerTrigger:delete()
	UPK_BalerTrigger:superClass().delete(self)
end

