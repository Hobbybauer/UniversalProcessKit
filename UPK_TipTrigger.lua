-- by mor2000

--------------------
-- TipTrigger (that trailors can tip specific fillTypes)

UPK_TipTrigger={}
local UPK_TipTrigger_mt = ClassUPK(UPK_TipTrigger,UniversalProcessKit)
InitObjectClass(UPK_TipTrigger, "UPK_TipTrigger")
UniversalProcessKit.addModule("tiptrigger",UPK_TipTrigger)

function UPK_TipTrigger:new(isServer, isClient, customMt)
	if customMt == nil then
		customMt = UPK_TipTrigger_mt
	end
	local self = UniversalProcessKit:new(isServer, isClient, customMt)
	registerObjectClassName(self, "UPK_TipTrigger")
	self.setIsWaterTankFilling=GreenhousePlaceable.setIsWaterTankFilling
	self.addWaterTrailer=GreenhousePlaceable.addWaterTrailer
	self.removeWaterTrailer=GreenhousePlaceable.removeWaterTrailer
	return self
end

function UPK_TipTrigger:load(id, parent)
	if not UPK_TipTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading TipTrigger failed',true)
		return false
	end
	
	table.insert(self.triggerIds,id)
	addTrigger(id, "triggerCallback", self)
	
	self.waterTrailers = {}
	self.isWaterTankFilling = false
	self.waterTankFillTrailer = nil
	self.allowWaterTrailor=false
	
	if self.acceptedFillTypes[Fillable.FILLTYPE_WATER] then
		self.allowWaterTrailor=true
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

function UPK_TipTrigger:delete()
	if self.waterTrailerActivatable~=nil then
		g_currentMission:removeActivatableObject(self.waterTrailerActivatable)
		self.waterTrailers={}
	end
	UPK_TipTrigger:superClass().delete(self)
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
	local distance=Utils.vector2Length(trailerX - x, trailerZ - z)
	if(distance<0)then distance=0 end
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
	if self.isEnabled then
		if onEnter then
			local trailer = g_currentMission.objectToTrailer[otherShapeId]
			if self.allowWaterTrailor and trailer ~= nil and trailer.addWaterTrailerFillTrigger ~= nil then -- waterTrailer
				self:addWaterTrailer(trailer)
			elseif trailer ~= nil and trailer.allowTipDischarge then
				if g_currentMission.trailerTipTriggers[trailer] == nil then
					g_currentMission.trailerTipTriggers[trailer] = {}
				end
				table.insert(g_currentMission.trailerTipTriggers[trailer], self)
			end
		else
			local trailer = g_currentMission.objectToTrailer[otherShapeId]
			if self.allowWaterTrailor and trailer ~= nil and trailer.addWaterTrailerFillTrigger ~= nil then -- waterTrailer
				self:removeWaterTrailer(trailer)
			elseif trailer ~= nil and trailer.allowTipDischarge then
				local triggers = g_currentMission.trailerTipTriggers[trailer]
				if triggers ~= nil then
					for i = 1, table.getn(triggers) do
						if triggers[i] == self then
							table.remove(triggers, i)
							if table.getn(triggers) == 0 then
								g_currentMission.trailerTipTriggers[trailer] = nil
							end
							break
						end
					end
				end
			end
		end
	end
end

-- waterTrailor

function UPK_TipTrigger:updateTick(dt)
	--[[
	if self.isServer then
		if self.fillLevels[Fillable.FILLTYPE_WATER] ~= self.sentWaterTankFillLevel then
			self:raiseDirtyFlags(self.myDirtyFlag) -- needs update
			self.sentWaterTankFillLevel = self.fillLevels[Fillable.FILLTYPE_WATER]
		end
		if self.isWaterTankFilling then
			local disableFilling = false
			local waterFillLevel = self.waterTankFillTrailer:getFillLevel(Fillable.FILLTYPE_WATER)
			if waterFillLevel > 0 then
				local oldFillLevel = self.fillLevels[Fillable.FILLTYPE_WATER]
				local delta = self.fillLitersPerSecond * dt * 0.001
				delta = math.min(delta, waterFillLevel)
				self:setWaterTankFillLevel(self.fillLevels[Fillable.FILLTYPE_WATER] + delta)
				local delta = self.fillLevels[Fillable.FILLTYPE_WATER] - oldFillLevel
				disableFilling = delta <= 0
				self.waterTankFillTrailer:setFillLevel(waterFillLevel - delta, Fillable.FILLTYPE_WATER, true)
			else
				disableFilling = true
			end
			if disableFilling then
				self:setIsWaterTankFilling(false)
			end
		end
	end
	]]--
end

UPK_WaterTankActivatable = {}
local UPK_WaterTankActivatable_mt = Class(UPK_WaterTankActivatable,GreenhousePlaceableWaterTankActivatable)
function UPK_WaterTankActivatable:getIsActivatable()
	self.currentTrailer = nil
	if self.greenhouse.fillLevels[Fillable.FILLTYPE_WATER] >= self.greenhouse.capacity then
		return false
	end
	for _, trailer in pairs(self.greenhouse.waterTrailers) do
		if trailer:getIsActiveForInput() and trailer:getFillLevel(Fillable.FILLTYPE_WATER) > 0 then
			self.currentTrailer = trailer
			self:updateActivateText()
			return true
		end
	end
	return false
end
function UPK_WaterTankActivatable:updateActivateText()
	if self.greenhouse.isWaterTankFilling then
		self.activateText = string.format(g_i18n:getText("stop_refill_OBJECT"), "LALA")
	else
		self.activateText = string.format(g_i18n:getText("refill_OBJECT"), "BLABLA")
	end
end
