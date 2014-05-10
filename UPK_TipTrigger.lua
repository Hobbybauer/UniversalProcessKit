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
	self.waterFillingDirtyFlag = self:getNextDirtyFlag()
	return self
end

function UPK_TipTrigger:load(id, parent)
	if not UPK_TipTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading TipTrigger failed',true)
		return false
	end

	self:addTrigger()
	self:registerUpkTipTrigger()
	
	-- water
	self.waterTrailers = {}
	self.allowWaterTrailer=tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "allowWaterTrailer"),"true"))
	if rawget(self.acceptedFillTypes,Fillable.FILLTYPE_WATER) and self.allowWaterTrailer then
		self.waterTrailerActivatable = UPK_WaterTankActivatable:new(self)
	end
	
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
		local nrWaterTrailerToSync=streamReadIntN(streamId,12) or 0
		for i=1,nrWaterTrailerToSync do
			vehicle = networkGetObject(streamReadInt32(streamId))
			isFilling = streamReadBool(streamId)
			if type(vehicle)=="array" then
				table.insert(self.waterTrailers,vehicle)
				vehicle.upk_isWaterTankFilling=isFilling
			end
		end
	end
end;

function UPK_TipTrigger:writeStream(streamId, connection)
	UPK_TipTrigger:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		local nrWaterTrailerToSync=getTableLength(self.waterTrailers)
		streamWriteIntN(streamId,nrWaterTrailerToSync,12)
		for k,v in pairs(self.waterTrailers) do
			streamWriteInt32(streamId, networkGetObjectId(v))
			streamWriteBool(v.upk_isWaterTankFilling)
		end
	end
end;

function UPK_TipTrigger:readUpdateStream(streamId, timestamp, connection)
	UPK_TipTrigger:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.waterFillingDirtyFlag)~=0 then
			local nrWaterTrailerToSync=streamReadIntN(streamId,12) or 0
			for i=1,nrWaterTrailerToSync do
				vehicle = networkGetObject(streamReadInt32(streamId))
				isFilling = streamReadBool(streamId)
				if type(vehicle)=="array" then
					table.insert(self.waterTrailers,vehicle)
					vehicle.upk_isWaterTankFilling=isFilling
				end
			end
		end
	end
end;

function UPK_TipTrigger:writeUpdateStream(streamId, connection, dirtyMask)
	UPK_TipTrigger:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.waterFillingDirtyFlag)~=0 or syncall then
			local nrWaterTrailerToSync=getTableLength(self.waterTrailers)
			streamWriteIntN(streamId,nrWaterTrailerToSync,12)
			for k,v in pairs(self.waterTrailers) do
				streamWriteInt32(streamId, networkGetObjectId(v))
				streamWriteBool(v.upk_isWaterTankFilling)
			end
		end
	end
end;

function UPK_TipTrigger:delete()
	self:unregisterUpkTipTrigger()
	
	if self.waterTrailerActivatable~=nil then
		g_currentMission:removeActivatableObject(self.waterTrailerActivatable)
		self.waterTrailers={}
	end
	
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
		elseif self.allowWaterTrailer and vehicle.addWaterTrailerFillTrigger ~= nil and vehicle.removeWaterTrailerFillTrigger ~= nil then
			if onEnter then
				self:print('UPK_TipTrigger:triggerCallback Enter')
				vehicle.currentUpkFillTrigger=self
				g_currentMission:addActivatableObject(self.waterTrailerActivatable)
				table.insert(self.waterTrailers,vehicle)
			else
				self:print('UPK_TipTrigger:triggerCallback Leave')
				if vehicle.currentUpkFillTrigger==self then
					vehicle.currentUpkFillTrigger=nil
				end
				removeValueFromTable(self.waterTrailers,vehicle)
				if getTableLength(self.waterTrailers)==0 then
					self:print('no other water trailers')
					self:setIsWaterTankFilling(false,vehicle)
					g_currentMission:removeActivatableObject(self.waterTrailerActivatable)
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
		elseif self.allowFuelTrailer and vehicle.addFuelFillTrigger ~= nil and vehicle.removeFuelFillTrigger ~= nil then
			if onEnter then
				vehicle.currentUpkFillTrigger=self
			else
				if vehicle.currentUpkFillTrigger==self then
					vehicle.currentUpkFillTrigger=nil
				end
			end
		elseif vehicle ~= nil and vehicle.allowTipDischarge then
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

-- waterTrailer

function UPK_TipTrigger:updateTick(dt)
	if self.isServer and self.isEnabled then
		if self.waterTrailerActivatable~=nil then
			local fillLevel=self:getFillLevel(Fillable.FILLTYPE_WATER)
			for k,vehicle in pairs(self.waterTrailers) do
				if vehicle.upk_isWaterTankFilling then
					local waterFillLevel = vehicle:getFillLevel(Fillable.FILLTYPE_WATER)
					if waterFillLevel > 0 and fillLevel<self.capacity then
						local delta = mathmin(self.fillLitersPerSecond/1000 * dt, waterFillLevel)
						delta=self:addFillLevel(delta, Fillable.FILLTYPE_WATER)
						vehicle:setFillLevel(waterFillLevel - delta, Fillable.FILLTYPE_WATER, true)
					else
						vehicle.upk_isWaterTankFilling=false
					end
				end
			end
		end
	end
end

function UPK_TipTrigger:setIsWaterTankFilling(isWaterTankFilling, trailer, noEventSend)
	if isWaterTankFilling~=trailer.upk_isWaterTankFilling then
		trailer.upk_isWaterTankFilling=isWaterTankFilling
		self:raiseDirtyFlags(self.waterFillingDirtyFlag)
	end
end

UPK_WaterTankActivatable = {}
local UPK_WaterTankActivatable_mt = Class(UPK_WaterTankActivatable,GreenhousePlaceableWaterTankActivatable)
function UPK_WaterTankActivatable:new(upkmodule)
	local self = {}
	setmetatable(self, UPK_WaterTankActivatable_mt)
	self.upkmodule = upkmodule
	self.activateText = "unknown"
	self.currentTrailer = nil
	return self
end
function UPK_WaterTankActivatable:getIsActivatable()
	self.currentTrailer = nil
	
	if self.upkmodule:getFillLevel(Fillable.FILLTYPE_WATER) >= self.upkmodule.capacity then
		return false
	end
	for _, trailer in pairs(self.upkmodule.waterTrailers) do
		if trailer:getIsActiveForInput() and trailer:getFillLevel(Fillable.FILLTYPE_WATER) > 0 then
			self.currentTrailer = trailer
			self:updateActivateText()
			return true
		end
	end
	return false
end
function UPK_WaterTankActivatable:onActivateObject()
	self.upkmodule:setIsWaterTankFilling(not self.currentTrailer.upk_isWaterTankFilling, self.currentTrailer)
	self:updateActivateText()
	g_currentMission:addActivatableObject(self)
end
function UPK_WaterTankActivatable:drawActivate()
end
function UPK_WaterTankActivatable:updateActivateText()
	if self.currentTrailer.upk_isWaterTankFilling then
		self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), "TextToReplace1")
	else
		self.activateText = string.format(g_i18n:getText("refill_OBJECT"), "TextToReplace2")
	end
end
