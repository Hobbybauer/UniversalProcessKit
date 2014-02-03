-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailors and/or shovels with specific fillType)

UPK_FillTrigger={}
local UPK_FillTrigger_mt = Class(UPK_FillTrigger, UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")
	self.fillSowingMachine=UPK_FillTrigger.fillVehicle
	self.fillWater=UPK_FillTrigger.fillVehicle
	self.fillSprayer=UPK_FillTrigger.fillVehicle
	self.fillFuel=UPK_FillTrigger.fillVehicle
	self.triggerIds={}
	self.siloTriggerDirtyFlag=self:getNextDirtyFlag()
	return self
end

function UPK_FillTrigger:load(id,parent)
	if not UPK_FillTrigger:superClass().load(self, id, parent) then
		print('  [UniversalProcessKit] Error: loading FillTrigger failed')
		return false
	end
 
	table.insert(self.triggerIds,id)
	addTrigger(id, "triggerCallback", self)
	--self:register(true)

	self.fill = {}
	self.siloTrailer = nil
	self.fillDone = {}
	self.isFilling = {}
	
	-- find shapes to show fillType
	self.fillTypeShapes={}
	local numChildren = getNumOfChildren(id)
	for i=1,numChildren do
		local childId = getChildAt(id, i-1)
		local typeStr = getUserAttribute(childId, "fillType")
		if typeStr~=nil then
			fillType=UniversalProcessKit.fillTypeNameToInt(typeStr)
			if type(fillType)=="number" then
				self.fillTypeShapes[fillType]=childId
			end
		end
	end
	
	self.trailers={}
	self.shovels={}
	self.sowingMachines={}
	self.waterTrailers={}
	self.sprayers={}
	self.fuelTrailers={}

	self.fillType = Fillable.FILLTYPE_UNKNOWN
    local fillTypeString = Utils.getNoNil(getUserAttribute(id, "fillType"), "unknown")
	local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(fillTypeString))
	if type(fillType)=="number" then
		self.fillType=fillType
	end

	
	
    self.fillLitersPerSecond = Utils.getNoNil(getUserAttribute(id, "fillLitersPerSecond"), 1500)
	self.createFillType = tobool(getUserAttribute(id, "createFillType"))
    self.pricePerLiter = Utils.getNoNil(tonumber(getUserAttribute(id, "pricePerLiter")), 0)
	if self.pricePerLiter~=0 then
		self.createFillType = true
	end

    self.allowTrailer = tobool(Utils.getNoNil(getUserAttribute(id, "allowTrailer"), "true"))
    self.allowShovel = tobool(Utils.getNoNil(getUserAttribute(id, "allowShovel"), "true"))
	self.allowSowingMachine = tobool(Utils.getNoNil(getUserAttribute(id, "allowSowingMachine"), "true"))
	self.allowWaterTrailer = tobool(Utils.getNoNil(getUserAttribute(id, "allowWaterTrailer"), "true"))
	self.allowSprayer = tobool(Utils.getNoNil(getUserAttribute(id, "allowSprayer"), "true"))
	self.allowFuelTrailer = tobool(Utils.getNoNil(getUserAttribute(id, "allowFuelTrailer"), "true"))
	
	self.useParticleSystem = tobool(getUserAttribute(id, "useParticleSystem"))
	
    if self.isClient and self.useParticleSystem then
      local dropParticleSystem = Utils.indexToObject(id, getUserAttribute(id, "dropParticleSystemIndex"))
      if dropParticleSystem ~= nil then
        self.dropParticleSystems = {}
        Utils.loadParticleSystemFromNode(dropParticleSystem, self.dropParticleSystems, false, true)
      end
      local lyingParticleSystem = Utils.indexToObject(id, getUserAttribute(id, "lyingParticleSystemIndex"))
      if lyingParticleSystem ~= nil then
        self.lyingParticleSystems = {}
        Utils.loadParticleSystemFromNode(lyingParticleSystem, self.lyingParticleSystems, true, true)
        for _, ps in ipairs(self.lyingParticleSystems) do
          local lifespan = getParticleSystemLifespan(ps.geometry)
          addParticleSystemSimulationTime(ps.geometry, lifespan)
        end
        Utils.setParticleSystemTimeScale(self.lyingParticleSystems, 0)
      end
	  
      if self.dropParticleSystems == nil then
        local particleSystem = Utils.getNoNil(getUserAttribute(id, "particleSystem"), "wheatParticleSystemLong")
        local psData = {}
        psData.psFile = getUserAttribute(id, "particleSystemFilename")
        if psData.psFile == nil then
          local particleSystem = Utils.getNoNil(getUserAttribute(id, "particleSystem"), "wheatParticleSystemLong")
          psData.psFile = "$data/vehicles/particleSystems/" .. particleSystem .. ".i3d"
        end
        psData.posX, psData.posY, psData.posZ = unpack(self.pos+getVectorFromUserAttribute("particlePosition", "0 0 0"))
        psData.forceNoWorldSpace = true
        self.dropParticleSystems = {}
        Utils.loadParticleSystemFromData(psData, self.dropParticleSystems, nil, false, nil, g_currentMission.baseDirectory, getParent(id))
      end
    
	
      local fillSoundFilename = Utils.getFilename("$data/maps/sounds/siloFillSound.wav", g_currentMission.baseDirectory)
  	--print('Set fillSoundFilename to '..tostring(fillSoundFilename))
      self.siloFillSound = createAudioSource("siloFillSound", fillSoundFilename, 30, 10, 1, 0)
  	--print('self.siloFillSound is '..tostring(self.siloFillSound))
      link(id, self.siloFillSound)
      setVisibility(self.siloFillSound, false)
  end
  return true
end

function UPK_FillTrigger:delete()
	self.trailers={}
	self.shovels={}
	for _,v in pairs(self.sowingMachines or {}) do
		local sowingMachine = g_currentMission.objectToTrailer[v]
		if sowingMachine ~= nil and sowingMachine.removeSowingMachineFillTrigger ~= nil then
			sowingMachine:removeSowingMachineFillTrigger(self)
		end
	end
	for _,v in pairs(self.waterTrailers or {}) do
		local waterTrailer = g_currentMission.objectToTrailer[v]
		if waterTrailer~=nil and waterTrailer.removeWaterTrailerFillTrigger ~= nil then
			waterTrailer:removeWaterTrailerFillTrigger(self)
		end
	end
	for _,v in pairs(self.sprayers or {}) do
		local sprayer = g_currentMission.objectToTrailer[v]
		if sprayer~=nil and sprayer.removeSprayerFillTrigger ~= nil then
			sprayer:removeSprayerFillTrigger(self)
			--sprayer:removeReFillTrigger(self)
		end
	end
	for _,v in pairs(self.fuelTrailers or {}) do
		local vehicle = g_currentMission.objectToTrailer[v]
		if vehicle~=nil and vehicle.removeFuelFillTrigger ~= nil then
			vehicle:removeFuelFillTrigger(self)
		end
	end
	UPK_FillTrigger:superClass().delete(self)
end

function UPK_FillTrigger:update(dt)
	if self.isServer then
		--print("isServer")
		if self.allowTrailer then
			for _,v in pairs(self.trailers) do
				local trailer = g_currentMission.objectToTrailer[v]
				--print("trailer: "..tostring(type(self.parentTrailer))..", fill: "..tostring(self.fill)..", fillDone: "..tostring(self.fillDone))
				if trailer~=nil then
					if trailer.currentFillType==self.fillType or trailer.currentFillType==Fillable.FILLTYPE_UNKNOWN then
						if self.fill[v] and not self.fillDone[v] then
							trailer:resetFillLevelIfNeeded(self.fillType)
							local fillLevel = trailer:getFillLevel(self.fillType)
							if trailer:allowFillType(self.fillType, false) then
								if trailer.capacity~=nil and fillLevel==trailer.capacity then
									self.fill[v]=nil
									self.fillDone[v]=nil
			    					self:stopFill()
									table.remove(self.trailers,v)
								else
			    					local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
			    					if not self.createFillType then
			    						deltaFillLevel=math.min(deltaFillLevel, self:getFillLevel(self.fillType))
			    					end
			    					trailer:setFillLevel(fillLevel + deltaFillLevel, self.fillType)
			    					local newFillLevel = trailer:getFillLevel(self.fillType)
			    					deltaFillLevel = newFillLevel-fillLevel
			    					if(deltaFillLevel>0 and self.pricePerLiter~=0)then
			    						g_currentMission:addSharedMoney(-deltaFillLevel*self.pricePerLiter, "other")
			    					end
			    					if not self.createFillType then
			    						self:addFillLevel(-deltaFillLevel,self.fillType)
			    					end
			    					if fillLevel ~= newFillLevel then
			    						self:startFill()
									end
								end
		    				end
						end
					end
				end
			end
		elseif self.allowShovel then
			for _,v in pairs(self.shovels) do
				local shovel = g_currentMission.objectToTrailer[v]
				if shovel ~= nil then
					self:fillShovel(shovel, dt)
				else
					table.remove(self.shovels,v)
				end
			end
		end
	end
end

function UPK_FillTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isServer and self.isEnabled then
		local vehicle = g_currentMission.objectToTrailer[otherShapeId]
		if vehicle~=nil then
			--[[
			print("decide what")
			print("self.allowSowingMachine: "..tostring(self.allowSowingMachine))
			print("vehicle.addSowingMachineFillTrigger: "..tostring(vehicle.addSowingMachineFillTrigger~=nil))
			print("self.allowWaterTrailer: "..tostring(self.allowWaterTrailer))
			print("vehicle.addWaterTrailerFillTrigger: "..tostring(vehicle.addWaterTrailerFillTrigger~=nil))
			print("self.allowSprayer: "..tostring(self.allowSprayer))
			print("vehicle.addSprayerFillTrigger: "..tostring(vehicle.addSprayerFillTrigger~=nil))
			print("self.allowFuelTrailer: "..tostring(self.allowFuelTrailer))
			print("vehicle.addFuelFillTrigger: "..tostring(vehicle.addSprayerFillTrigger~=nil))
			print("self.allowShovel: "..tostring(self.allowShovel))
			print("vehicle.getAllowFillShovel: "..tostring(vehicle.getAllowFillShovel~=nil))
			print("self.allowTrailer: "..tostring(self.allowTrailer))
			]]--
			if self.allowSowingMachine and vehicle.addSowingMachineFillTrigger ~= nil and vehicle.removeSowingMachineFillTrigger ~= nil then
				if onEnter then
					vehicle:addSowingMachineFillTrigger(self)
					table.insert(self.sowingMachines,otherShapeId)
				else
					vehicle:removeSowingMachineFillTrigger(self)
					table.remove(self.sowingMachines,otherShapeId)
				end
			elseif self.allowWaterTrailer and vehicle.addWaterTrailerFillTrigger ~= nil and vehicle.removeWaterTrailerFillTrigger ~= nil then
				if onEnter then
					vehicle:addWaterTrailerFillTrigger(self)
					table.insert(self.waterTrailers,otherShapeId)
				else
					vehicle:removeWaterTrailerFillTrigger(self)
					table.remove(self.waterTrailers,otherShapeId)
				end
			elseif self.allowSprayer and vehicle.addSprayerFillTrigger ~= nil and vehicle.removeSprayerFillTrigger ~= nil then
				if onEnter then
					vehicle:addSprayerFillTrigger(self)
					table.insert(self.sprayers,otherShapeId)
				else
					vehicle:removeSprayerFillTrigger(self)
					table.remove(self.sprayers,otherShapeId)
				end
			elseif self.allowFuelTrailer and vehicle.addFuelFillTrigger ~= nil and vehicle.removeFuelFillTrigger ~= nil then
				if onEnter then
					vehicle:addFuelFillTrigger(self)
					table.insert(self.fuelTrailers,otherShapeId)
				else
					vehicle:removeFuelFillTrigger(self)
					table.remove(self.fuelTrailers,otherShapeId)
				end
			end
			if self.allowShovel and vehicle.getAllowFillShovel ~= nil then
				if onEnter then
					table.insert(self.shovels,otherShapeId)
				else
					table.remove(self.shovels,otherShapeId)
				end
			elseif self.allowTrailer then
				if onEnter then
					table.insert(self.fill,otherShapeId,true)
					table.insert(self.trailers,otherShapeId)
				elseif onLeave then
					self.fill[otherShapeId] = nil
					self.fillDone[otherShapeId] = nil
					table.remove(self.trailers,otherShapeId)
					self:stopFill(otherShapeId)
				end
			end
		end
	end
end

function UPK_FillTrigger:setFillType(fillType)
	local oldFillLevel=self.fillLevel
	if fillType~=nil then
		if self.fillTypeShapes[oldFillType]~=nil then
			setVisibility(oldFillLevel,false)
		end
		if self.fillTypeShapes[fillType]~=nil then
			setVisibility(fillType,true)
		end
		self.fillType = fillType
	else
		self.fillType = Fillable.FILLTYPE_UNKNOWN
	end	
end

function UPK_FillTrigger:getIsActivatable(vehicle)
	--print("UPK_FillTrigger:getIsActivatable")
	if self.allowSowingMachine and vehicle.addSowingMachineFillTrigger ~= nil and vehicle:allowFillType(Fillable.FILLTYPE_SEEDS, false) and (self.fillLevels[Fillable.FILLTYPE_SEEDS] > 0 or self.createFillType) then
		return true
	elseif self.allowWaterTrailer and vehicle.addWaterTrailerFillTrigger ~= nil and vehicle:allowFillType(Fillable.FILLTYPE_WATER, false) and (self.fillLevels[Fillable.FILLTYPE_WATER] > 0 or self.createFillType) then
		return true
	elseif self.allowSprayer and vehicle.addSprayerFillTrigger ~= nil and vehicle:allowFillType(Fillable.FILLTYPE_FERTILIZER, false) and (self.fillLevels[Fillable.FILLTYPE_FERTILIZER] > 0 or self.createFillType) then
		return true
	elseif self.allowFuelTrailer and vehicle.addFuelFillTrigger ~= nil and vehicle:allowFillType(Fillable.FILLTYPE_FUEL, false) and (self.fillLevels[Fillable.FILLTYPE_FUEL] > 0 or self.createFillType) then
		return true
	end
	return false
end

function UPK_FillTrigger:startFill()
	SiloTrigger:startFill(self)
end

function UPK_FillTrigger:stopFill()
	local trailercount=0
	for _ in pairs(self.trailers) do
		trailercount=trailercount+1
	end	
	if trailercount==0 then
		SiloTrigger:stopFill(self)
	end
end

-- Shovels

function UPK_FillTrigger:fillShovel(shovel, dt)
	if not shovel:allowFillType(self.fillType, false) then
		return 0
	end
	if shovel~=nil and shovel.fillShovelFromTrigger~=nil and self.fillType~=Fillable.FILLTYPE_UNKNOWN then
		local oldFillLevel=shovel:getFillLevel(self.fillType)
		local delta = self.fillLitersPerSecond * 0.001 * dt
		local newFillLevel=shovel:fillShovelFromTrigger(self, delta, self.fillType, dt)
		delta=shovel:getFillLevel(self.fillType) - oldFillLevel
		if delta>0 then
			if self.pricePerLiter ~= 0 then
				local price = delta * self.pricePerLiter
				g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
				g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
				g_currentMission:addSharedMoney(-price, "other")
			end
			if not self.createFillType then
				delta=-self:addFillLevel(-delta,self.fillType)
			end
		end
	end
	return delta
end

-- for sowingMachines, waterTrailers and sprayers

function UPK_FillTrigger:fillVehicle(vehicle, delta)
	if not vehicle:allowFillType(self.fillType, false) then
		return 0
	end
	local oldFillLevel = vehicle:getFillLevel(self.fillType)
	vehicle:setFillLevel(oldFillLevel + delta, self.fillType, true)
	delta=vehicle:getFillLevel(self.fillType) - oldFillLevel
	if delta>0 then
		if self.pricePerLiter ~= 0 then
			local price = delta * self.pricePerLiter
			g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
			g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
			g_currentMission:addSharedMoney(-price, "other")
		end
		if not self.createFillType then
			delta=-self:addFillLevel(-delta,self.fillType)
		end
	end
	return delta
end

