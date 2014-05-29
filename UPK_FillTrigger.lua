-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailors and/or shovels with specific fillType)

local UPK_FillTrigger_mt = ClassUPK(UPK_FillTrigger,UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")
	self.triggerIds={}
	return self
end

function UPK_FillTrigger:load(id,parent)
	if not UPK_FillTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading FillTrigger failed',true)
		return false
	end

	self:addTrigger()

	self.fill = {}
	self.siloTrailer = nil
	self.fillDone = {}
	self.isFilling = false
	
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
	self.forageWagons={}
	self.balers={}

	local fillTypeStr = Utils.getNoNil(getUserAttribute(id, "fillType"))
	if fillTypeStr~=nil then
		local fillType=UniversalProcessKit.fillTypeNameToInt[fillTypeStr]
		if type(fillType)=="number" then
			self.fillType=fillType
		else
			self:print('Error: unknown fillType \"'..tostring(fillTypeStr)..'\" ('..tostring(fillType)..')')
		end
	end
	
    self.fillLitersPerSecond = Utils.getNoNil(getUserAttribute(id, "fillLitersPerSecond"), 1500)
	self.createFillType = tobool(getUserAttribute(id, "createFillType"))
    self.pricePerLiter = Utils.getNoNil(tonumber(getUserAttribute(id, "pricePerLiter")), 0)
	self.statName=getUserAttribute(id, "statName")
	local validStatName=false
	if self.statName~=nil then
		for _,v in pairs(FinanceStats.statNames) do
			if self.statName==v then
				validStatName=true
				break
			end
		end
	end
	if not validStatName then
		self.statName="other"
	end

    self.allowTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowTrailer"), true))
    self.allowShovel = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowShovel"), true))
	self.allowSowingMachine = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSowingMachine"), false))
	self.allowWaterTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWaterTrailer"), true))
	self.allowLiquidManureTrailer=tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowLiquidManureTrailer"), true))
	self.allowSprayer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSprayer"), true))
	self.allowFuelTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelTrailer"), true))
	self.allowFuelRefill = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelRefill"), false))
	self.allowMilkTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_MILK)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowMilkTrailer"), true))
	
	self.allowForageWagon = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowForageWagon"), false))
	self.allowBaler = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowBaler"), false))
		
	self.useParticleSystem = tobool(getUserAttribute(id, "useParticleSystem"))
	
    if self.isClient and self.useParticleSystem then
        local dropParticleSystem = Utils.indexToObject(id, getUserAttribute(id, "dropParticleSystemIndex"))
        if dropParticleSystem ~= nil then
            self.dropParticleSystems = {}
            Utils.loadParticleSystemFromNode(dropParticleSystem, self.dropParticleSystems, false, true)
        end
		--[[ somebody needs this??
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
		]]--
	  
        if self.dropParticleSystems == nil then
            local particleSystem = Utils.getNoNil(getUserAttribute(self.nodeId, "particleSystem"), "wheatParticleSystemLong")
            local psData = {}
            psData.psFile = getUserAttribute(id, "particleSystemFilename")
            if psData.psFile == nil then
                local particleSystem = Utils.getNoNil(getUserAttribute(self.nodeId, "particleSystem"), "wheatParticleSystemLong")
                psData.psFile = "$data/vehicles/particleSystems/" .. particleSystem .. ".i3d"
            end
			self:print('psData.psFile: '..tostring(psData.psFile))
            psData.posX, psData.posY, psData.posZ = unpack(getVectorFromUserAttribute(self.nodeId,"particlePosition", "0 0 0"))
			psData.forceNoWorldSpace = true
            self.dropParticleSystems = {}
			-- psData.rotX, psData.rotY, psData.rotZ = unpack(self.rot*(-1))
            Utils.loadParticleSystemFromData(psData, self.dropParticleSystems, nil, false, nil, g_currentMission.baseDirectory, self.nodeId)
		end
    end

    self.useFillSound = tobool(Utils.getNoNil(getUserAttribute(id, "useFillSound"),"true"))
    if self.useFillSound then
  		local fillSoundStr = Utils.getNoNil(getUserAttribute(id, "fillSoundFilename"),"$data/maps/sounds/siloFillSound.wav")
        local fillSoundFilename = Utils.getFilename(fillSoundStr, g_currentMission.baseDirectory)
        self.siloFillSound = createAudioSource("siloFillSound", fillSoundFilename, 30, 10, 1, 0)
        link(self.nodeId, self.siloFillSound)
        setVisibility(self.siloFillSound, false)
		
    end

    self:print('loaded FillTrigger successfully')
    return true
end

function UPK_FillTrigger:delete()
	self.trailers={}
	self.shovels={}
	self.forageWagons={}
	self.balers={}
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
		--self:print("isServer")
		if self.allowTrailer then
			for k,v in pairs(self.trailers) do
				local trailer = g_currentMission.objectToTrailer[v]
				--self:print("trailer: "..tostring(type(self.parentTrailer))..", fill: "..tostring(self.fill)..", fillDone: "..tostring(self.fillDone))
				if trailer~=nil then
					fillType=self.fillType
					if trailer.currentFillType==fillType or trailer.currentFillType==Fillable.FILLTYPE_UNKNOWN then
						if self.fill[v] and not self.fillDone[v] then
							trailer:resetFillLevelIfNeeded(fillType)
							local fillLevel = trailer:getFillLevel(fillType)
							if trailer:allowFillType(fillType, false) then
								if (trailer.capacity~=nil and fillLevel==trailer.capacity) or (self.fillLevels[fillType]==0) then
									self.fill[v]=nil
									self.fillDone[v]=nil
									table.remove(self.trailers,k)
			    					self:stopFill()
								else
			    					local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
			    					if not self.createFillType then
			    						deltaFillLevel=math.min(deltaFillLevel, self:getFillLevel(fillType))
			    					end
			    					trailer:setFillLevel(fillLevel + deltaFillLevel, fillType)
			    					local newFillLevel = trailer:getFillLevel(fillType)
			    					deltaFillLevel = newFillLevel-fillLevel
			    					if(deltaFillLevel>0 and self.pricePerLiter~=0)then
			    						g_currentMission:addSharedMoney(-deltaFillLevel*self.pricePerLiter, "other")
			    					end
			    					if not self.createFillType then
			    						self:addFillLevel(-deltaFillLevel,fillType)
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
		end
		if self.allowShovel then
			for k,v in pairs(self.shovels) do
				if v then
					local shovel = g_currentMission.nodeToVehicle[k]
					if shovel ~= nil then
						self:fillShovel(shovel, dt)
					else
						self.shovels[k]=nil
					end
				end
			end
		end
		if self.allowForageWagon then
			--self:print('update: self.allowForageWagon=true')
			for k,v in pairs(self.forageWagons) do
				--self:print('checking key '..tostring(k)..' with v='..tostring(v)..' of forage wagons')
				if v then
					local trailer = g_currentMission.objectToTrailer[v] or g_currentMission.nodeToVehicle[v]
					--self:print('trailer is type '..type(trailer))
					if trailer~=nil and trailer.isTurnedOn then
						--self:print('forage wagon used in update')
						if trailer.upk_pickupNode~=nil and trailer.upk_pickupNode~=0 then
							self.raycastTriggerFound=false
							local x,y,z=getWorldTranslation(trailer.upk_pickupNode)
							raycastAll(x, y+20, z, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
							if self.raycastTriggerFound then
								self:print('raycast found trigger')
								fillType=self.fillType
								if trailer.currentFillType==fillType or trailer.currentFillType==Fillable.FILLTYPE_UNKNOWN then
									self:print('accepted filltype!')
									if self.fill[v] and not self.fillDone[v] then
										trailer:resetFillLevelIfNeeded(fillType)
										local fillLevel = trailer:getFillLevel(fillType)
										self:print('fillLevel of forage wagon is '..tostring(fillLevel))
										if trailer:allowFillType(fillType, false) then
											self:print('fillType allowed!')
											if (trailer.capacity~=nil and fillLevel==trailer.capacity) or (self.fillLevels[fillType]==0) then
												self.fill[v]=nil
												self.fillDone[v]=nil
												table.remove(self.forageWagons,k)
						    					self:stopFill()
											else
						    					local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
						    					if not self.createFillType then
						    						deltaFillLevel=math.min(deltaFillLevel, self:getFillLevel(fillType))
						    					end
						    					trailer:setFillLevel(fillLevel + deltaFillLevel, fillType)
						    					local newFillLevel = trailer:getFillLevel(fillType)
						    					deltaFillLevel = newFillLevel-fillLevel
						    					if(deltaFillLevel>0 and self.pricePerLiter~=0)then
						    						g_currentMission:addSharedMoney(-deltaFillLevel*self.pricePerLiter, "other")
						    					end
						    					if not self.createFillType then
						    						self:addFillLevel(-deltaFillLevel,fillType)
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
					end
				end
			end
		end
		if self.allowBaler then
			--self:print('update: self.allowForageWagon=true')
			for k,v in pairs(self.balers) do
				--self:print('checking key '..tostring(k)..' with v='..tostring(v)..' of forage wagons')
				if v then
					local trailer = g_currentMission.objectToTrailer[v] or g_currentMission.nodeToVehicle[v]
					--self:print('trailer is type '..type(trailer))
					if trailer~=nil and trailer.isTurnedOn then
						if trailer.upk_pickupNode~=nil and trailer.upk_pickupNode~=0 then
							self.raycastTriggerFound=false
							local x,y,z=getWorldTranslation(trailer.upk_pickupNode)
							raycastAll(x, y+20, z, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
							if self.raycastTriggerFound then
								self:print('raycast found trigger')
								fillType=self.fillType
								if trailer.currentFillType==fillType or trailer.currentFillType==Fillable.FILLTYPE_UNKNOWN then
									if self.fill[v] and not self.fillDone[v] then
										trailer:resetFillLevelIfNeeded(fillType)
										local fillLevel = trailer:getFillLevel(fillType)
										if trailer:allowFillType(fillType, false) then
											if trailer.capacity~=nil and fillLevel>=trailer.capacity and trailer.baleTypes ~= nil then
										
												do -- GIANTS code
													if trailer.baleAnimCurve ~= nil then
														local restDeltaFillLevel=0.000001
														trailer:setFillLevel(0, fillType)
														trailer:createBale(fillType, trailer.capacity)
														local numBales = length(trailer.bales)
														local bale = trailer.bales[numBales]
														trailer:moveBale(numBales, trailer:getTimeFromLevel(restDeltaFillLevel), true)
														g_server:broadcastEvent(BalerCreateBaleEvent:new(trailer, fillType, bale.time), nil, nil, trailer)
													elseif trailer.baleUnloadAnimationName ~= nil then
														trailer:createBale(fillType, trailer.capacity)
														g_server:broadcastEvent(BalerCreateBaleEvent:new(trailer, fillType, 0), nil, nil, trailer)
													end
												end
										
										
												--[[
												self.fill[v]=nil
												self.fillDone[v]=nil
												table.remove(self.balers,k)
						    					self:stopFill()
												]]--
											elseif self.fillLevels[fillType]==0 then
												self.fill[v]=nil
												self.fillDone[v]=nil
												table.remove(self.balers,k)
						    					self:stopFill()
											elseif trailer:allowPickingUp() then
						    					local deltaFillLevel = self.fillLitersPerSecond * 0.001 * dt
						    					if not self.createFillType then
						    						deltaFillLevel=mathmin(deltaFillLevel, self:getFillLevel(fillType))
						    					end
						    					trailer:setFillLevel(fillLevel + deltaFillLevel, fillType)
						    					local newFillLevel = trailer:getFillLevel(fillType)
						    					deltaFillLevel = newFillLevel-fillLevel
						    					if(deltaFillLevel>0 and self.pricePerLiter~=0)then
						    						g_currentMission:addSharedMoney(-deltaFillLevel*self.pricePerLiter, "other")
						    					end
						    					if not self.createFillType then
						    						self:addFillLevel(-deltaFillLevel,fillType)
						    					end
						    					if fillLevel ~= newFillLevel then
						    						self:startFill()
												end
											end
										else
											--warning
											local fillTypeName=g_i18n:getText(UniversalProcessKit.fillTypeIntToName(fillType))
											local forageWagonCollectWarning=g_i18n:getText("forage_wagon_cant_collect")
											local text=string.format(forageWagonCollectWarning,fillTypeName)
											g_currentMission:addWarning(text, 0.018, 0.033)
					    				end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function UPK_FillTrigger:findMyNodeRaycastCallback(transformId, x, y, z, distance)
	--self:print('UPK_FillTrigger:findMyNodeRaycastCallback')
	if transformId==self.nodeId then
		self.raycastTriggerFound=true
		return false
	end
	return true
end

function UPK_FillTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isServer and self.isEnabled then
		local vehicle=g_currentMission.objectToTrailer[otherShapeId] or g_currentMission.nodeToVehicle[otherShapeId]
		if vehicle~=nil then
			
			--[[
			self:print("decide what")
			--self:print("self.allowSowingMachine: "..tostring(self.allowSowingMachine))
			--self:print("vehicle.addSowingMachineFillTrigger: "..tostring(vehicle.addSowingMachineFillTrigger~=nil))
			--self:print("self.allowWaterTrailer: "..tostring(self.allowWaterTrailer))
			--self:print("vehicle.addWaterTrailerFillTrigger: "..tostring(vehicle.addWaterTrailerFillTrigger~=nil))
			self:print("self.allowSprayer: "..tostring(self.allowSprayer))
			self:print("vehicle.addSprayerFillTrigger: "..tostring(vehicle.addSprayerFillTrigger~=nil))
			--self:print("self.allowFuelTrailer: "..tostring(self.allowFuelTrailer))
			--self:print("vehicle.addFuelFillTrigger: "..tostring(vehicle.addFuelFillTrigger~=nil))
			--self:print("vehicle.setFuelFillLevel: "..tostring(vehicle.setFuelFillLevel~=nil))
			--self:print("self.allowShovel: "..tostring(self.allowShovel))
			--self:print("vehicle.getAllowFillShovel: "..tostring(vehicle.getAllowFillShovel~=nil))
			--self:print("self.allowTrailer: "..tostring(self.allowTrailer))
			self:print('self.allowLiquidManureTrailer'..tostring(self.allowLiquidManureTrailer))
			self:print('vehicle.currentFillType '..tostring(vehicle.currentFillType))
			self:print('vehicle.addSprayerFillTrigger ~= nil '..tostring(vehicle.addSprayerFillTrigger ~= nil))
			self:print('vehicle.removeSprayerFillTrigger ~= nil '..tostring(vehicle.removeSprayerFillTrigger ~= nil))
			self:print('vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) '..tostring(vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE)))
			self:print('vehicle:allowFillType(Fillable.FILLTYPE_FERTILIZER) '..tostring(vehicle:allowFillType(Fillable.FILLTYPE_FERTILIZER)))
			self:print('vehicle:allowFillType(Fillable.FILLTYPE_WATER) '..tostring(vehicle:allowFillType(Fillable.FILLTYPE_WATER)))
			]]--
			if UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SOWINGMACHINE) then
				if self.allowSowingMachine then
					if onEnter then
						vehicle:addSowingMachineFillTrigger(self)
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_SOWINGMACHINE
						table.insert(self.sowingMachines,otherShapeId)
					else
						vehicle:removeSowingMachineFillTrigger(self)
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.sowingMachines,otherShapeId)
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER) then
				if self.allowWaterTrailer then
					if onEnter then
						vehicle:addWaterTrailerFillTrigger(self)
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_WATERTRAILER
						table.insert(self.waterTrailers,otherShapeId)
					else
						vehicle:removeWaterTrailerFillTrigger(self)
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.waterTrailers,otherShapeId)
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER) then
				if self.allowLiquidManureTrailer then
					if onEnter then
						vehicle:addSprayerFillTrigger(self)
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER
						table.insert(self.sprayers,otherShapeId)
					else
						vehicle:removeSprayerFillTrigger(self)
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.sprayers,otherShapeId)
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SPRAYER) then
				if self.allowSprayer then
					if onEnter then
						vehicle:addSprayerFillTrigger(self)
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_SPRAYER
						table.insert(self.sprayers,otherShapeId)
					else
						vehicle:removeSprayerFillTrigger(self)
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.sprayers,otherShapeId)
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER) then
				if self.allowFuelTrailer or (self.allowFuelRefill and vehicle.setFuelFillLevel ~= nil) then
					if onEnter then
						vehicle:addFuelFillTrigger(self)
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_FUELTRAILER
						table.insert(self.fuelTrailers,otherShapeId)
					else
						vehicle:removeFuelFillTrigger(self)
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.fuelTrailers,otherShapeId)
					end
				end
			-- milk
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SHOVEL) then
				if self.allowShovel then
					if onEnter then
						self.shovels[otherShapeId]=true
					else
						self.shovels[otherShapeId]=nil
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FORAGEWAGON) then
				if self.allowForageWagon then
					if onEnter then
						if vehicle.upk_pickupNode==nil and vehicle.upk_pickupNode~=0 then
							self:print('configFile: '..tostring(vehicle.configFileName))
							local xmlFile = loadXMLFile("TempConfig", vehicle.configFileName)
							if not hasXMLProperty(xmlFile, "vehicle.pickupAnimation") then
								vehicle.upk_pickupNode=0
								self:print('no pickup animation!')
							else
								local pickupAnimationName = Utils.getNoNil(getXMLString(xmlFile, "vehicle.pickupAnimation#name"), "")
								self:print('pickupAnimationName: '..tostring(pickupAnimationName))
								if pickupAnimationName~="" then
									local i = 0
									while true do
										local key = string.format("vehicle.animations.animation(%d)", i)
										if not hasXMLProperty(xmlFile, key) then
											break
										end
										if getXMLString(xmlFile, key .. "#name")==pickupAnimationName then
											local keyNode = key..'.part'
											self:print('keyNode '..tostring(keyNode))
											local index=getXMLString(xmlFile, keyNode .. "#node")
											vehicle.upk_pickupNode = Utils.getNoNil(Utils.indexToObject(vehicle.components, index), 0)
											self:print('vehicle.upk_pickupNode '..tostring(vehicle.upk_pickupNode))
											break
										end
										i = i + 1
									end
								end
							end
							delete(xmlFile)
						end
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_FORAGEWAGON
						table.insert(self.fill,otherShapeId,true)
						table.insert(self.forageWagons,otherShapeId)
					elseif onLeave then
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.forageWagons,otherShapeId)
					end
				end
			elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_BALER) then
				if self.allowBaler then
					if onEnter then
						if vehicle.upk_pickupNode==nil and vehicle.upk_pickupNode~=0 then
							self:print('configFile: '..tostring(vehicle.configFileName))
							local xmlFile = loadXMLFile("TempConfig", vehicle.configFileName)
							if not hasXMLProperty(xmlFile, "vehicle.pickupAnimation") then
								vehicle.upk_pickupNode=0
								self:print('no pickup animation!')
							else
								local pickupAnimationName = Utils.getNoNil(getXMLString(xmlFile, "vehicle.pickupAnimation#name"), "")
								self:print('pickupAnimationName: '..tostring(pickupAnimationName))
								if pickupAnimationName~="" then
									local i = 0
									while true do
										local key = string.format("vehicle.animations.animation(%d)", i)
										if not hasXMLProperty(xmlFile, key) then
											break
										end
										if getXMLString(xmlFile, key .. "#name")==pickupAnimationName then
											local keyNode = key..'.part'
											self:print('keyNode '..tostring(keyNode))
											local index=getXMLString(xmlFile, keyNode .. "#node")
											vehicle.upk_pickupNode = Utils.getNoNil(Utils.indexToObject(vehicle.components, index), 0)
											self:print('vehicle.upk_pickupNode '..tostring(vehicle.upk_pickupNode))
											break
										end
										i = i + 1
									end
								end
							end
							delete(xmlFile)
						end
						vehicle.upk_vehicleType=UniversalProcessKit.VEHICLE_BALER
						table.insert(self.fill,otherShapeId,true)
						table.insert(self.balers,otherShapeId)
					elseif onLeave then
						vehicle.upk_vehicleType=nil
						removeValueFromTable(self.balers,otherShapeId)
					end
				end
			elseif self.allowTrailer then
				if onEnter then
					table.insert(self.fill,otherShapeId,true)
					table.insert(self.trailers,otherShapeId)
				elseif onLeave then
					self.fill[otherShapeId] = nil
					self.fillDone[otherShapeId] = nil
					removeValueFromTable(self.trailers,otherShapeId)
					self:stopFill(otherShapeId)
				end
			end
		end
	end
end

function UPK_FillTrigger:setFillType(fillType)
	self:print('anybody?')
	local oldFillType=self.fillType
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
	--self:print("UPK_FillTrigger:getIsActivatable")
	if type(vehicle)=="table" then
		local fillType=self.fillType
		local notEmpty=(self.fillLevels[fillType] > 0 or self.createFillType)
		--self:print('vehicle.upk_vehicleType '..tostring(vehicle.upk_vehicleType))
		if self.allowSowingMachine and vehicle.upk_vehicleType==UniversalProcessKit.VEHICLE_SOWINGMACHINE then
			return (self.createFillType or (fillType==FruitUtil.fruitTypeToFillType[vehicle.seeds[vehicle.currentSeed]] and self:getFillLevel(fillType)>0))
		elseif self.allowWaterTrailer and vehicle.upk_vehicleType==UniversalProcessKit.VEHICLE_WATERTRAILER then
			return (fillType==Fillable.FILLTYPE_WATER and notEmpty)
		elseif self.allowLiquidManureTrailer and vehicle.upk_vehicleType==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER then
			return (fillType==Fillable.FILLTYPE_LIQUIDMANURE and notEmpty)	
		elseif self.allowSprayer and vehicle.upk_vehicleType==UniversalProcessKit.VEHICLE_SPRAYER then
			return (fillType==Fillable.FILLTYPE_FERTILIZER and notEmpty)
		elseif (self.allowFuelTrailer or self.allowFuelRefill) and vehicle.upk_vehicleType==UniversalProcessKit.VEHICLE_FUELTRAILER then
			return (fillType==Fillable.FILLTYPE_FUEL and notEmpty)
		end
	end
	return false
end

function UPK_FillTrigger:startFill()
	SiloTrigger.startFill(self)
end

function UPK_FillTrigger:stopFill()
	local trailercount=0
	for _ in pairs(self.trailers) do
		trailercount=trailercount+1
	end	
	if trailercount==0 then
		SiloTrigger.stopFill(self)
	end
end

-- Shovels

function UPK_FillTrigger:fillShovel(shovel, dt)
	fillType=self.fillType
	if not shovel:allowFillType(fillType, false) then
		return 0
	end
	if shovel~=nil and shovel.fillShovelFromTrigger~=nil and fillType~=Fillable.FILLTYPE_UNKNOWN then
		local oldFillLevel=shovel:getFillLevel(fillType)
		local delta = math.min(self.fillLitersPerSecond * 0.001 * dt, self.fillLevels[fillType])
		local newFillLevel=shovel:fillShovelFromTrigger(self, delta, fillType, dt)
		delta=shovel:getFillLevel(fillType) - oldFillLevel
		if delta>0 then
			if self.pricePerLiter ~= 0 then
				local price = delta * self.pricePerLiter
				g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
				g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
				g_currentMission:addSharedMoney(-price, "other")
			end
			if not self.createFillType then
				delta=-self:addFillLevel(-delta,fillType)
			end
		end
	end
	return delta
end

-- for sowingMachines

function UPK_FillTrigger:fillSowingMachine(vehicle, delta)
	return self:fillVehicle(vehicle, delta, Fillable.FILLTYPE_SEEDS)
end

function UPK_FillTrigger:fillWater(vehicle, delta)
	return self:fillVehicle(vehicle, delta, Fillable.FILLTYPE_WATER)
end

function UPK_FillTrigger:fillSprayer(vehicle, delta)
	local fillType=Fillable.FILLTYPE_FERTILIZER
	if vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) then
		fillType=Fillable.FILLTYPE_LIQUIDMANURE
	end
	return self:fillVehicle(vehicle, delta, fillType)
end

function UPK_FillTrigger:fillFuel(vehicle, delta)
	if self.isServer and self.isEnabled then
		fillType=Fillable.FILLTYPE_FUEL
		if not self.createFillType then
			delta=-self:addFillLevel(-delta,fillType)
		end
		local delta2=delta
		if self.allowFuelRefill and vehicle.setFuelFillLevel ~= nil then
			local oldFillLevel = vehicle.fuelFillLevel
			vehicle:setFuelFillLevel(oldFillLevel + delta)
			delta2 = vehicle.fuelFillLevel - oldFillLevel
		else
			local oldFillLevel = vehicle:getFillLevel(Fillable.FILLTYPE_FUEL)
			vehicle:setFillLevel(oldFillLevel + delta, Fillable.FILLTYPE_FUEL, true)
			delta2=vehicle:getFillLevel(Fillable.FILLTYPE_FUEL) - oldFillLevel
		end
		if not self.createFillType and (delta-delta2)>0 then
			self:addFillLevel(delta-delta2,fillType)
		end
		if self.pricePerLiter ~= 0 then
			local price = delta2 * self.pricePerLiter
			g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
			g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
			g_currentMission:addSharedMoney(-price, self.statName)
		end
		return delta2
	end
end

function UPK_FillTrigger:fillVehicle(vehicle, delta, fillTypeTrailer)
	if self.isServer and self.isEnabled then
		local oldFillLevel = vehicle:getFillLevel(fillTypeTrailer)
		if not self.createFillType then
			delta=-self:addFillLevel(-delta,fillTypeTrailer)
		end
		vehicle:setFillLevel(oldFillLevel + delta, fillTypeTrailer, true)
		delta2=vehicle:getFillLevel(fillTypeTrailer) - oldFillLevel
		if not self.createFillType and (delta-delta2)>0 then
			self:addFillLevel(delta-delta2,fillTypeTrailer)
		end
		if self.pricePerLiter ~= 0 then
			local price = delta2 * self.pricePerLiter
			g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + price
			g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + price
			g_currentMission:addSharedMoney(-price, self.statName)
		end
		return delta2
	end
end

