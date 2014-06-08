-- by mor2000

--------------------
-- EntityTrigger (enables modules if vehicle or walker is present)


local UPK_EntityTrigger_mt = ClassUPK(UPK_EntityTrigger,UniversalProcessKit)
InitObjectClass(UPK_EntityTrigger, "UPK_EntityTrigger")
UniversalProcessKit.addModule("entitytrigger",UPK_EntityTrigger)

function UPK_EntityTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_EntityTrigger_mt)
	registerObjectClassName(self, "UPK_EntityTrigger")
	self.addNodeObject=true
	return self
end

function UPK_EntityTrigger:load(id, parent)
	if not UPK_EntityTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading EntityTrigger failed',true)
		return false
	end

	self:addTrigger()
	self:registerUpkTipTrigger()
	
	self.entities = {}
	
	self.allowWalker = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWalker"), true))
	
	self.enableOnEmpty = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "enableOnEmpty"), false))
	
	self.allowedVehicles={}
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowMotorized"), true))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFillable"), true))
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowTrailer"), false))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowShovel"), false))

	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWaterTrailer"), false))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelTrailer"), false))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowLiquidManureTrailer"), false))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowMilkTrailer"), false))
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSowingMachine"), false))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSprayer"), false))
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowForageWagon"), false))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER] = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowBaler"), false))
	
	self:print('loaded EntityTrigger successfully')
	return true
end

function UPK_EntityTrigger:delete()
	self.entities={}
	self.allowedVehicles={}
	UPK_EntityTrigger:superClass().delete(self)
end

function UPK_EntityTrigger:updateTick()
	if self.isServer then
		local isEnabled
		if self.enableOnEmpty then
			isEnabled=length(self.entities)==0
		else
			isEnabled=length(self.entities)~=0
		end
		if isEnabled~=self.isEnabled then
			self:setEnable(isEnabled)
		end
	end
end

function UPK_EntityTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	-- use these numbers for the collisionMask (or a combination/ sum of it)
	-- http://gdn.giants-software.com/thread.php?categoryId=16&threadId=677
	-- player = 2^20 = 1048576
	-- tractors = 2^21 = 2097152
	-- combines = 2^22 = 4194304
	-- fillables = 2^23 = 8388608
	-- all = 15728640

	if self.isServer then
		local vehicle=g_currentMission.objectToTrailer[otherShapeId] or g_currentMission.nodeToVehicle[otherShapeId]
		if vehicle~=nil then
			for k,v in pairs(self.allowedVehicles) do
				if v and UniversalProcessKit.isVehicleType(vehicle,k) then
					if onEnter then
						self.entities[otherShapeId]=true
					else
						self.entities[otherShapeId]=nil
					end
				end
			end
		end
		if self.allowWalker and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
			if onEnter then
				self.entities[otherActorId]=true
			else
				self.entities[otherActorId]=nil
			end
		end
	end
end



