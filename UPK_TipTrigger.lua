-- by mor2000

--------------------
-- TipTrigger (that trailers can tip specific fillTypes)


local UPK_TipTrigger_mt = ClassUPK(UPK_TipTrigger,UniversalProcessKit)
InitObjectClass(UPK_TipTrigger, "UPK_TipTrigger")
UniversalProcessKit.addModule("tiptrigger",UPK_TipTrigger)

function UPK_TipTrigger:new(isServer, isClient, customMt)
	if customMt == nil then
		customMt = UPK_TipTrigger_mt
	end
	local self = UniversalProcessKit:new(isServer, isClient, customMt)
	registerObjectClassName(self, "UPK_TipTrigger")
	self.addNodeObject=true
	self.isFillingDirtyFlag = self:getNextDirtyFlag()
	return self
end

function UPK_TipTrigger:load(id, parent)
	if not UPK_TipTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading TipTrigger failed',true)
		return false
	end

	self:addTrigger()
	self:registerUpkTipTrigger()
	
	self.trailers = {}
	
	self.allowTrailer = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowTrailer"), true))
	self.allowWaterTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_WATER)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWaterTrailer"), true))
	self.allowFuelTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_FUEL)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelTrailer"), true))
	self.allowLiquidManureTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_LIQUIDMANURE)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowLiquidManureTrailer"), true))
	self.allowMilkTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_MILK)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowMilkTrailer"), true))
	self.allowSprayer = rawget(self.acceptedFillTypes,Fillable.FILLTYPE_FUEL)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowSprayer"), false))
	
	self.fillLitersPerSecond = Utils.getNoNil(getUserAttribute(id, "fillLitersPerSecond"), 1500)
	-- getNoAllowedText
	
	self.getNoAllowedTextBool = tobool(getUserAttribute(self.nodeId, "showNoAllowedText"))
	
	local l10ndisplayName = getUserAttribute(self.nodeId, "l10n_displayName")
	self.displayName=""
	if l10ndisplayName~=nil and self.i18nNameSpace~=nil and (_g or {})[self.i18nNameSpace]~=nil then
		self.displayName=_g[self.i18nNameSpace].g_i18n:getText(l10ndisplayName)
	end
	
	self.notAcceptedText = g_i18n:getText(Utils.getNoNil(getUserAttribute(self.nodeId, "NotAcceptedText"), "notAcceptedHere"))
	self.capacityReachedText = g_i18n:getText(Utils.getNoNil(getUserAttribute(self.nodeId, "CapacityReachedText"), "capacityReached"))
	self.playerInRange = false
	
	self.tipTriggerActivatable = UPK_TipTriggerActivatable:new(self)

	self:print('loaded TipTrigger successfully')
	return true
end

function UPK_TipTrigger:readStream(streamId, connection)
	UPK_TipTrigger:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local nrTrailersToSync=streamReadIntN(streamId,12) or 0
		for i=1,nrTrailersToSync do
			vehicle = networkGetObject(streamReadInt32(streamId))
			isFilling = streamReadBool(streamId)
			if type(vehicle)=="table" then
				self:setIsTipTriggerFilling(isFilling, vehicle, true)
			end
		end
	end
end;

function UPK_TipTrigger:writeStream(streamId, connection)
	UPK_TipTrigger:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		local nrTrailersToSync=getTableLength(self.trailers)
		streamWriteIntN(streamId,nrTrailersToSync,12)
		for _,vehicle in pairs(self.trailers) do
			streamWriteInt32(streamId, networkGetObjectId(vehicle))
			streamWriteBool(vehicle.upk_isTipTriggerFilling)
		end
	end
end;

function UPK_TipTrigger:readUpdateStream(streamId, timestamp, connection)
	UPK_TipTrigger:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.isFillingDirtyFlag)~=0 then
			vehicle = networkGetObject(streamReadInt32(streamId))
			isFilling = streamReadBool(streamId)
			if type(vehicle)=="table" then
				self:setIsTipTriggerFilling(isFilling, vehicle, true)
			end
		end
	end
end;

function UPK_TipTrigger:writeUpdateStream(streamId, connection, dirtyMask)
	UPK_TipTrigger:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.isFillingDirtyFlag)~=0 or syncall then
			streamWriteInt32(streamId, networkGetObjectId(self.vehicleToSync))
			streamWriteBool(streamId, self.isFillingToSync)
		end
	end
end;

function UPK_TipTrigger:delete()
	self:unregisterUpkTipTrigger()
	
	--[[
	for _,vehicle in pairs(self.trailers) do
		self:setIsTipTriggerFilling(false,vehicle)
	end
	--]]
	
	g_currentMission:removeActivatableObject(self.tipTriggerActivatable)
	self.tipTriggerActivatable=nil

	self.trailers={}
	
	UPK_TipTrigger:superClass().delete(self)
end

function UPK_TipTrigger:registerUpkTipTrigger()
	table.insert(g_upkTipTrigger,self)
end

function UPK_TipTrigger:unregisterUpkTipTrigger()
	removeValueFromTable(g_upkTipTrigger,self)
end

function UPK_TipTrigger:updateTrailerTipping(trailer, fillDelta, fillType)
	if type(trailer)=="table" then
		local toomuch=0
		if fillDelta < 0 and fillType~=nil then
			toomuch=fillDelta+self:addFillLevel(-fillDelta,fillType) -- max 0
		end
		if toomuch<0 then
			trailer:onEndTip()
			trailer:setFillLevel(trailer:getFillLevel(fillType)-toomuch, fillType) -- put sth back
		end
	end
end

function UPK_TipTrigger:getTipInfoForTrailer(trailer, tipReferencePointIndex)
	if trailer.currentUpkTipTrigger==self then
		local minDistance, bestPoint = self:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
		fillType=self.fillType
		trailerFillType=trailer.currentFillType
		local isAllowed = minDistance==0 and
			(self.acceptedFillTypes[trailerFillType] and
			self.fillLevels[trailerFillType]<self.capacity) and
			(fillType==Fillable.FILLTYPE_UNKNOWN or ((fillType or trailerFillType)==trailerFillType))
		return isAllowed, minDistance, bestPoint
	end
	return false,math.huge,nil
end

function UPK_TipTrigger:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	local minDistance = math.huge
	local bestPoint=tipReferencePointIndex
	if tipReferencePointIndex ~= nil then
		minDistance=self:getTipDistance(trailer,tipReferencePointIndex)
	else
		for i, point in pairs(trailer.tipReferencePoints) do
			if minDistance>1 then
				distance=self:getTipDistance(trailer,i)
				if distance < minDistance then
					bestPoint = i
					minDistance = distance
				end
			end
		end
	end
	--self:print('return minDistance '..tostring(minDistance)..', bestPoint '..tostring(bestPoint))
	return 0, bestPoint
end

function UPK_TipTrigger:getTipDistance(trailer,tipReferencePoint)
	pointNode=trailer.tipReferencePoints[tipReferencePoint].node
	local pointNodeX, pointNodeY, pointNodeZ = getWorldTranslation(pointNode)
	local distance=math.huge
	self.raycastTriggerFound=false
	raycastAll(pointNodeX, pointNodeY+20, pointNodeZ, 0, -1, 0, "findMyNodeRaycastCallback", 21, self)
	if self.raycastTriggerFound then
		local triggerX, _, triggerZ = getWorldTranslation(self.nodeId)
		distance=Utils.vector2Length(pointNodeX-triggerX,pointNodeZ-triggerZ)
	end
	--self:print('return distance '..tostring(distance))
	return distance
end

function UPK_TipTrigger:findMyNodeRaycastCallback(transformId, x, y, z, distance)
	--self:print('UPK_TipTrigger:findMyNodeRaycastCallback')
	if transformId==self.nodeId then
		self.raycastTriggerFound=true
		return false
	end
	return true
end

-- show text if the filltype of the trailer is not accepted
function UPK_TipTrigger:getNoAllowedText(trailer)
	if self.getNoAllowedTextBool and trailer.currentFillType~=Fillable.FILLTYPE_UNKNOWN then
		if self.acceptedFillTypes[trailer.currentFillType]~=true then
			return g_i18n:getText(unpack(UniversalProcessKit.fillTypeIntToName(trailer.currentFillType))) .. self.notAcceptedText
		else
			if self.fillLevels[trailer.currentFillType]>=self.capacity then
				return self.capacityReachedText .. " " ..g_i18n:getText(unpack(UniversalProcessKit.fillTypeIntToName(trailer.currentFillType)))
			end
		end
		-- ADD capacity reached
	end
	return nil
end

function UPK_TipTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isClient and self.isEnabled then
		local vehicle=g_currentMission.objectToTrailer[otherShapeId] or {}
		if vehicle.currentUpkTipTrigger==nil or vehicle.currentUpkTipTrigger==self then
			if self.allowSowingMachine and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SOWINGMACHINE) then
				if onEnter then
					vehicle.currentUpkTipTrigger=self
				else
					if vehicle.currentUpkTipTrigger==self then
						vehicle.currentUpkTipTrigger=nil
					end
				end
			elseif self.allowSprayer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SPRAYER) then
				if onEnter then
					vehicle.currentUpkTipTrigger=self
				else
					if vehicle.currentUpkTipTrigger==self then
						vehicle.currentUpkTipTrigger=nil
					end
				end
			elseif (self.allowWaterTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER)) or
					(self.allowFuelTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER)) or
					(self.allowLiquidManureTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER)) or
					(self.allowMilkTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER)) then
				if onEnter then
					vehicle.currentUpkTipTrigger=self
					self:print('onEnter')
					self.trailersForActivatableObject=mathmax(0, (self.trailersForActivatableObject or 0)+1)
					print('self.trailersForActivatableObject='..tostring(self.trailersForActivatableObject))
					self:enableActivatableObject(vehicle,vehicle.currentFillType)
					table.insert(self.trailers,vehicle)
				elseif onLeave then
					if vehicle.currentUpkTipTrigger==self then
						vehicle.currentUpkTipTrigger=nil
					end
					self:print('onLeave')
					self.trailersForActivatableObject=mathmax(0, (self.trailersForActivatableObject or 1)-1)
					print('self.trailersForActivatableObject='..tostring(self.trailersForActivatableObject))
					self:disableActivatableObject()
					removeValueFromTable(self.trailers,vehicle)
				end
			elseif self.allowTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_TIPPER) then
				if onEnter then
					vehicle.currentUpkTipTrigger=self
					if g_currentMission.trailerTipTriggers[vehicle] == nil then
						g_currentMission.trailerTipTriggers[vehicle] = {}
					end
					table.insert(g_currentMission.trailerTipTriggers[vehicle], self)
					table.insert(self.trailers,vehicle)
				elseif onLeave then
					if vehicle.currentUpkTipTrigger==self then
						vehicle.currentUpkTipTrigger=nil
					end
					local triggers = g_currentMission.trailerTipTriggers[vehicle]
					if triggers ~= nil then
						removeValueFromTable(triggers,self)
						if table.getn(triggers) == 0 then
							g_currentMission.trailerTipTriggers[vehicle] = nil
						end
					end
					removeValueFromTable(self.trailers,vehicle)
				end
			end
		end
	end
end

function UPK_TipTrigger:updateTick(dt)
	if self.isServer and self.isEnabled then
		if self.allowWaterTrailer or self.allowFuelTrailer or self.allowLiquidManureTrailer then
			for k,vehicle in pairs(self.trailers) do
				local fillType = vehicle.currentFillType
				if vehicle.upk_isTipTriggerFilling and
					(self.allowWaterTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER)) or
					(self.allowFuelTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER)) or
					(self.allowLiquidManureTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER)) or
					(self.allowMilkTrailer and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER)) then
					local fillLevel=self:getFillLevel(fillType)
					local trailerFillLevel = vehicle:getFillLevel(fillType)
					if trailerFillLevel > 0 and fillLevel<self.capacity then
						local delta = mathmin(self.fillLitersPerSecond/1000 * dt, trailerFillLevel)
						delta=self:addFillLevel(delta, fillType)
						vehicle:setFillLevel(trailerFillLevel - delta, fillType, true)
					else
						self:setIsTipTriggerFilling(false,vehicle)
					end
				end
			end
		end
	end
end;

function UPK_TipTrigger:setIsTipTriggerFilling(isTipTriggerFilling, trailer, sendNoEvent)
	if type(trailer)=="table" and isTipTriggerFilling~=trailer.upk_isTipTriggerFilling then
		trailer.upk_isTipTriggerFilling=isTipTriggerFilling
		if not sendNoEvent then
			self.vehicleToSync=trailer
			self.isFillingToSync=isTipTriggerFilling
			self:raiseDirtyFlags(self.isFillingDirtyFlag)
		end
	end
end;

function UPK_TipTrigger:enableActivatableObject(vehicle,fillType)
	self.tipTriggerActivatable:setCurrentTrailer(vehicle)
	self.tipTriggerActivatable:setFillType(vehicle.currentFillType)
	if self.trailersForActivatableObject==1 then
		g_currentMission:addActivatableObject(self.tipTriggerActivatable)
	end
end;

function UPK_TipTrigger:disableActivatableObject()
	self:setIsTipTriggerFilling(false,self.tipTriggerActivatable.currentTrailer)
	self.tipTriggerActivatable:setCurrentTrailer(nil)
	self.tipTriggerActivatable:setFillType(nil)
	if self.trailersForActivatableObject==0 then
		g_currentMission:removeActivatableObject(self.tipTriggerActivatable)
	end
end;
	

UPK_TipTriggerActivatable = {}
local UPK_TipTriggerActivatable_mt = Class(UPK_TipTriggerActivatable)
function UPK_TipTriggerActivatable:new(upkmodule)
	local self = {}
	setmetatable(self, UPK_TipTriggerActivatable_mt)
	self.upkmodule = upkmodule or {}
	self.activateText = "unknown"
	self.currentTrailer = nil
	self.currentTrailerType = nil
	self.fillType = nil
	return self
end;
function UPK_TipTriggerActivatable:getIsActivatable()
	if self.upkmodule:getFillLevel(self.fillType) >= self.upkmodule.capacity then
		return false
	end
	if self.currentTrailer~=nil and self.currentTrailerType~=nil and self.fillType ~= nil and
		self.currentTrailer:allowFillType(self.fillType) and self.currentTrailer:getFillLevel(self.fillType)>0 then
		self:updateActivateText()
		return true
	end
	return false
end;
function UPK_TipTriggerActivatable:onActivateObject()
	if type(self.currentTrailer)=="table" then
		self.upkmodule:setIsTipTriggerFilling(not self.currentTrailer.upk_isTipTriggerFilling, self.currentTrailer)
		self:updateActivateText()
		g_currentMission:addActivatableObject(self)
	end
end;
function UPK_TipTriggerActivatable:drawActivate()
end;
function UPK_TipTriggerActivatable:setFillType(fillType)
	self.fillType = fillType
end;
function UPK_TipTriggerActivatable:setCurrentTrailer(vehicle)
	self.currentTrailer = vehicle
	if type(vehicle)=="table" then
		if UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_WATERTRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_WATERTRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SOWINGMACHINE) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_SOWINGMACHINE
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MILKTRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_MILKTRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_FUELTRAILER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_FUELTRAILER
		elseif UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_SPRAYER) then
			self.currentTrailerType=UniversalProcessKit.VEHICLE_SPRAYER
		else
			self.currentTrailerType=nil
		end
	else
		self.currentTrailerType=nil
	end
end;
function UPK_TipTriggerActivatable:updateActivateText()
	if self.currentTrailer.upk_isTipTriggerFilling then
		self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), self.upkmodule.displayName)
	else
		self.activateText = string.format(g_i18n:getText("refill_OBJECT"), self.upkmodule.displayName)
	end
end;




