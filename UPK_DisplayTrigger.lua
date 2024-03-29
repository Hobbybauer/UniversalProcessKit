-- by mor2000

--------------------
-- DisplayTrigger (shows sth in the top left hud)

local UPK_DisplayTrigger_mt = ClassUPK(UPK_DisplayTrigger,UniversalProcessKit)
InitObjectClass(UPK_DisplayTrigger, "UPK_DisplayTrigger")
UniversalProcessKit.addModule("displaytrigger",UPK_DisplayTrigger)

function UPK_DisplayTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_DisplayTrigger_mt)
	registerObjectClassName(self, "UPK_DisplayTrigger")
	self.addNodeObject=true
	return self
end

function UPK_DisplayTrigger:load(id, parent)
	if not UPK_DisplayTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading DisplayTrigger failed',true)
		return false
	end

	self.playerInRange=false
	self.vehiclesInRange={}

	self.onlyFilled = tobool(getUserAttribute(id, "onlyFilled"))
	self.showFillLevel = tobool(Utils.getNoNil(getUserAttribute(id, "showFillLevel"),true))
	self.showPercentage = tobool(getUserAttribute(id, "showPercentage"))

	self:addTrigger()

	self:print('loaded DisplayTrigger successfully')
	return true
end

function UPK_DisplayTrigger:delete()
	UPK_DisplayTrigger:superClass().delete(self)
end

function UPK_DisplayTrigger:update(dt)
	if self.isClient then
		if self:getShowInfo() then
			local fluid_unit_short=g_i18n:getText("fluid_unit_short")
			for _,v in pairs(self:getAcceptedFillTypes()) do
				local fillLevel=self.fillLevels[v]
				if fillLevel>0 or not self.onlyFilled then
					local i18n_key=UniversalProcessKit.fillTypeIntToName[v]
					local text=""
					if self.i18nNameSpace~=nil and (_g or {})[self.i18nNameSpace]~=nil and _g[self.i18nNameSpace].g_i18n:hasText(i18n_key) then
						text=_g[self.i18nNameSpace].g_i18n:getText(i18n_key)
					elseif g_i18n:hasText(i18n_key) then
						text=g_i18n:getText(i18n_key)
					end
					if text~="" then
						text=text..": "
					end
					if self.showFillLevel then
						text=text..math.max(0,math.floor(fillLevel+0.5)) .. "[" .. fluid_unit_short .. "]"
					end
					if self.showPercentage then
						text=text.." "..math.max(0,math.ceil(fillLevel/self.capacity*100)) .. "%"
					end
	    			g_currentMission:addExtraPrintText(text)
				end
			end
		end
	end
end

function UPK_DisplayTrigger:getShowInfo()
	local r=false
	if self.playerInRange then
		r=g_currentMission.controlPlayer or false
	else
		for v in pairs(self.vehiclesInRange or {}) do
			if v:getIsActiveForInput() then
				r=true
				break
			end
		end
	end
	--print('UPK_DisplayTrigger:getShowInfo() = '..tostring(r))
	return r
end

function UPK_DisplayTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	-- use these numbers for the collisionMask (or a combination/ sum of it)
	-- http://gdn.giants-software.com/thread.php?categoryId=16&threadId=677
	-- player = 2^20 = 1048576
	-- tractors = 2^21 = 2097152
	-- combines = 2^22 = 4194304
	-- fillables = 2^23 = 8388608
	-- all = 15728640
	if self.isEnabled and (onEnter or onLeave) then
		if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			self.playerInRange = onEnter==true
		else
			local vehicle = g_currentMission.objectToTrailer[otherShapeId] or g_currentMission.nodeToVehicle[otherShapeId]
			if vehicle ~= nil then
				if onEnter then
					self.vehiclesInRange[vehicle] = true
				else
					self.vehiclesInRange[vehicle] = nil
				end
			end
		end
	end
end