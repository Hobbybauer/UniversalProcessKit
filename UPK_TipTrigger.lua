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
	
	self.allowWaterTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_WATER)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWaterTrailer"),"true"))
	self.allowFuelTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_FUEL)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowFuelTrailer"),"true"))
	self.allowLiquidManureTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_LIQUIDMANURE)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowLiquidManureTrailer"),"true"))
	self.allowMilkTrailer=rawget(self.acceptedFillTypes,Fillable.FILLTYPE_MILK)==true and tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowMilkTrailer"),"true"))
	
	
	self.fillLitersPerSecond = Utils.getNoNil(getUserAttribute(id, "fillLitersPerSecond"), 1500)
	-- getNoAllowedText
	
	self.getNoAllowedTextBool = tobool(getUserAttribute(self.nodeId, "showNoAllowedText"))
	self.notAcceptedText = g_i18n:getText(Utils.getNoNil(getUserAttribute(self.nodeId, "NotAcceptedText"), "notAcceptedHere"))
	self.capacityReachedText = g_i18n:getText(Utils.getNoNil(getUserAttribute(self.nodeId, "CapacityReachedText"), "capacityReached"))
	self.playerInRange = false

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
				table.insert(self.trailers,vehicle)
				vehicle.upk_isTipTriggerFilling=isFilling
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
			local nrTrailersToSync=streamReadIntN(streamId,12) or 0
			for i=1,nrTrailersToSync do
				vehicle = networkGetObject(streamReadInt32(streamId))
				isFilling = streamReadBool(streamId)
				if type(vehicle)=="table" then
					table.insert(self.trailers,vehicle)
					vehicle.upk_isTipTriggerFilling=isFilling
				end
			end
		end
	end
end;

function UPK_TipTrigger:writeUpdateStream(streamId, connection, dirtyMask)
	UPK_TipTrigger:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.isFillingDirtyFlag)~=0 or syncall then
			local nrTrailersToSync=getTableLength(self.trailers)
			streamWriteIntN(streamId,nrTrailersToSync,12)
			for _,vehicle in pairs(self.trailers) do
				streamWriteInt32(streamId, networkGetObjectId(vehicle))
				streamWriteBool(vehicle.upk_isTipTriggerFilling)
			end
		end
	end
end;

function UPK_TipTrigger:delete()
	self:unregisterUpkTipTrigger()
	
	for _,vehicle in pairs(self.trailers) do
		self:setIsTipTriggerFilling(false,vehicle)
		g_currentMission:removeActivatableObject(vehicle.upk_tipTriggerActivatable)
		vehicle.upk_tipTriggerActivatable=nil
	end
	self.trailers={}
	
	UPK_TipTrigger:superClass().delete(self)
end

function UPK_TipTrigger:registerUpkTipTrigger()
	table.insert(g_upkTipTrigger,self)
end

function UPK_TipTrigger:unregisterUpkTipTrigger()
	for k,v in pairs(g_upkTipTrigger) do
		if(v==self)then
			table.remove(g_upkTipTrigger,k)
			break
		end
	end
end

function UPK_TipTrigger:updateTrailerTipping(trailer, fillDelta, fillType)
	local toomuch=0
	if fillDelta < 0 and fillType~=nil then
		toomuch=fillDelta+self:addFillLevel(-fillDelta,fillType) -- max 0
	end
	if toomuch<0 then
		trailer:onEndTip()
		trailer:setFillLevel(trailer:getFillLevel(fillType)-toomuch, fillType) -- put sth back
	end
end

function UPK_TipTrigger:getTipInfoForTrailer(trailer, tipReferencePointIndex)
	local _, bestPoint = self:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	fillType=self.fillType
	trailerFillType=trailer.currentFillType
	local isAllowed = (self.acceptedFillTypes[trailerFillType] and
		self.fillLevels[trailerFillType]<self.capacity) and
		(fillType==Fillable.FILLTYPE_UNKNOWN or ((fillType or trailerFillType)==trailerFillType))
	return isAllowed, 0, bestPoint
end

function UPK_TipTrigger:getTipDistanceFromTrailer(trailer, tipReferencePointIndex)
	local minDistance = math.huge
	if tipReferencePointIndex ~= nil then
		minDistance=self:getTipDistance(trailer.tipReferencePoints[tipReferencePointIndex].node)
		bestPoint=tipReferencePointIndex
	else
		for i, point in pairs(trailer.tipReferencePoints) do
			distance=self:getTipDistance(point.node)
			if distance < minDistance then
				bestPoint = i
				minDistance = distance
			end
		end
	end
	return minDistance, bestPoint
end

function UPK_TipTrigger:getTipDistance(trailerId)
	local trailerX, _, trailerZ = getWorldTranslation(trailerId)
	local x,_,z = unpack(self.pos)
	local distance=mathmax(Utils.vector2Length(trailerX - x, trailerZ - z),0)
	return distance
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
		if self.allowSowingMachine and vehicle.addSowingMachineFillTrigger ~= nil and vehicle.removeSowingMachineFillTrigger ~= nil then
			if onEnter then
				vehicle.currentUpkFillTrigger=self
			else
				if vehicle.currentUpkFillTrigger==self then
					vehicle.currentUpkFillTrigger=nil
				end
			end
		elseif self.allowSprayer and vehicle.addSprayerFillTrigger ~= nil and vehicle.removeSprayerFillTrigger ~= nil then
			if onEnter then
				vehicle.currentUpkFillTrigger=self
			else
				if vehicle.currentUpkFillTrigger==self then
					vehicle.currentUpkFillTrigger=nil
				end
			end
		elseif (self.allowWaterTrailer and vehicle.currentFillType==Fillable.FILLTYPE_WATER) or
				(self.allowFuelTrailer and vehicle.currentFillType==Fillable.FILLTYPE_FUEL) or
				(self.allowLiquidManureTrailer and vehicle.currentFillType==Fillable.FILLTYPE_LIQUIDMANURE) or
				(self.allowMilkTrailer and vehicle.currentFillType==Fillable.FILLTYPE_MILK) then
			if onEnter then
				vehicle.currentUpkFillTrigger=self
				vehicle.upk_tipTriggerActivatable = UPK_TipTriggerActivatable:new(self,vehicle.currentFillType)
				g_currentMission:addActivatableObject(vehicle.upk_tipTriggerActivatable)
				table.insert(self.trailers,vehicle)
			else
				if vehicle.currentUpkFillTrigger==self then
					vehicle.currentUpkFillTrigger=nil
				end
				removeValueFromTable(self.trailers,vehicle)
				self:setIsTipTriggerFilling(false,vehicle)
				g_currentMission:removeActivatableObject(vehicle.upk_tipTriggerActivatable)
				vehicle.upk_tipTriggerActivatable=nil
			end
		elseif vehicle.allowTipDischarge then
			if onEnter then
				if g_currentMission.trailerTipTriggers[vehicle] == nil then
					g_currentMission.trailerTipTriggers[vehicle] = {}
				end
				table.insert(g_currentMission.trailerTipTriggers[vehicle], self)
			else
				local triggers = g_currentMission.trailerTipTriggers[vehicle]
				if triggers ~= nil then
					for i = 1, table.getn(triggers) do
						if triggers[i] == self then
							table.remove(triggers, i)
							if table.getn(triggers) == 0 then
								g_currentMission.trailerTipTriggers[vehicle] = nil
							end
							break
						end
					end
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
					((self.allowWaterTrailer and fillType==Fillable.FILLTYPE_WATER) or
					(self.allowFuelTrailer and fillType==Fillable.FILLTYPE_FUEL) or
					(self.allowLiquidManureTrailer and fillType==Fillable.FILLTYPE_LIQUIDMANURE) or
					(self.allowMilkTrailer and fillType==Fillable.FILLTYPE_MILK)) then
					local fillLevel=self:getFillLevel(fillType)
					local trailerFillLevel = vehicle:getFillLevel(fillType)
					if trailerFillLevel > 0 and fillLevel<self.capacity then
						local delta = mathmin(self.fillLitersPerSecond/1000 * dt, trailerFillLevel)
						delta=self:addFillLevel(delta, fillType)
						vehicle:setFillLevel(trailerFillLevel - delta, fillType, true)
					else
						vehicle.upk_isTipTriggerFilling=false
					end
				end
			end
		end
	end
end

function UPK_TipTrigger:setIsTipTriggerFilling(isTipTriggerFilling, trailer, noEventSend)
	if isTipTriggerFilling~=trailer.upk_isTipTriggerFilling then
		trailer.upk_isTipTriggerFilling=isTipTriggerFilling
		self:raiseDirtyFlags(self.isFillingDirtyFlag)
	end
end

UPK_TipTriggerActivatable = {}
local UPK_TipTriggerActivatable_mt = Class(UPK_TipTriggerActivatable)
function UPK_TipTriggerActivatable:new(upkmodule,fillType)
	local self = {}
	setmetatable(self, UPK_TipTriggerActivatable_mt)
	self.upkmodule = upkmodule
	self.activateText = "unknown"
	self.currentTrailer = nil
	self.fillType = fillType
	return self
end
function UPK_TipTriggerActivatable:getIsActivatable()
	self.currentTrailer = nil
	if self.upkmodule:getFillLevel(self.fillType) >= self.upkmodule.capacity then
		return false
	end
	for _, trailer in pairs(self.upkmodule.trailers) do
		if trailer:getIsActiveForInput() and trailer:getFillLevel(self.fillType) > 0 then
			self.currentTrailer = trailer
			self:updateActivateText()
			return true
		end
	end
	return false
end
function UPK_TipTriggerActivatable:onActivateObject()
	self.upkmodule:setIsTipTriggerFilling(not self.currentTrailer.upk_isTipTriggerFilling, self.currentTrailer)
	self:updateActivateText()
	g_currentMission:addActivatableObject(self)
end
function UPK_TipTriggerActivatable:drawActivate()
end
function UPK_TipTriggerActivatable:updateActivateText()
	if self.currentTrailer.upk_isTipTriggerFilling then
		self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), "TextToReplace1")
	else
		self.activateText = string.format(g_i18n:getText("refill_OBJECT"), "TextToReplace2")
	end
end
