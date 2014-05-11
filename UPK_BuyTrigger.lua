-- by mor2000

--------------------
-- BuyTrigger


local UPK_BuyTrigger_mt = ClassUPK(UPK_BuyTrigger,UniversalProcessKit)
InitObjectClass(UPK_BuyTrigger, "UPK_BuyTrigger")
UniversalProcessKit.addModule("buytrigger",UPK_BuyTrigger)

function UPK_BuyTrigger:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_BuyTrigger_mt)
	registerObjectClassName(self, "UPK_BuyTrigger")
	self.getShowInfo=UPK_DisplayTrigger.getShowInfo
	self.addNodeObject=true
	self.isBoughtDirtyFlag=self:getNextDirtyFlag()
	return self
end

function UPK_BuyTrigger:load(id, parent)
	if not UPK_HeapDisplayTrigger:superClass().load(self, id, parent) then
		self:print('Error: loading BuyTrigger failed',true)
		return false
	end
	
	self.playerInRange=false
	self.vehiclesInRange={}
	
	self.isBought=false
	self.rentDue=0
	
	self.isBought = tobool(Utils.getNoNil(getUserAttribute(id, "isBought"),"false"))
	self.sellable = tobool(Utils.getNoNil(getUserAttribute(id, "sellable"),"true"))
	self.buyable = tobool(Utils.getNoNil(getUserAttribute(id, "buyable"),"true"))
	
	local mode = getUserAttribute(id, "mode")
	if mode~="buy" or mode~="rent" then
		mode="buy"
	end
	self.mode=mode
	
	self.cost = Utils.getNoNil(tonumber(getUserAttribute(id, "cost")),0)
	self.revenues = Utils.getNoNil(tonumber(getUserAttribute(id, "revenues")),0)
	
	self.dailyRent = Utils.getNoNil(tonumber(getUserAttribute(id, "dailyRent")),0)
	
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
		self.statName="constructionCost"
	end
	
	self.l10n_objectName = getUserAttribute(id, "objectName")
	
	self.buyTriggerActivatable = UPK_BuyTriggerActivatable:new(self)
	
	self:addTrigger()
	
	self:print('loaded BuyTrigger successfully')
	return true
end

function UPK_BuyTrigger:readStream(streamId, connection)
	UPK_BuyTrigger:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local isBought=streamReadBool(streamId) or false
		self:setIsBought(isBought,true)
		self.rentDue=streamReadInt8(streamId)
	end
end;

function UPK_BuyTrigger:writeStream(streamId, connection)
	UPK_BuyTrigger:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteBool(streamId,self.isBought)
		streamWriteInt8(streamId,self.rentDue)
	end
end;

function UPK_BuyTrigger:readUpdateStream(streamId, timestamp, connection)
	UPK_BuyTrigger:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.isBoughtDirtyFlag)~=0 then
			local isBought=streamReadBool(streamId) or false
			self:setIsBought(isBought,true)
			self.rentDue=streamReadInt8(streamId)
		end
	end
end;

function UPK_BuyTrigger:writeUpdateStream(streamId, connection, dirtyMask)
	UPK_BuyTrigger:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.isBoughtDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId,self.isBought)
			streamWriteInt8(streamId,self.rentDue)
		end
	end
end;

function UPK_BuyTrigger:delete()
	if self.mode=="rent" and self.isBought then
		g_currentMission.environment:removeHourChangeListener(self)
	end
	self.buyTriggerActivatable=nil
	UPK_BuyTrigger:superClass().delete(self)
end

function UPK_BuyTrigger:update(dt)
	if self.isClient and self.mode=="rent" and self:getIsBought() then
		if self:getShowInfo() then
			local remainingTime=(self.rentDue+24-g_currentMission.environment.currentHour) % 24
			setfenv(1,_g['AAA_UniversalProcessKit']); dummy=g_i18n:getText('buytrigger_remaining_time');
			g_currentMission:addExtraPrintText(string.format(dummy, remainingTime))
		end
	end
end

function UPK_BuyTrigger:getIsBought()
	return self.isBought
end;

function UPK_BuyTrigger:setIsBought(isBought,alreadySent)
	self.isBought=isBought
	if self.mode=="buy" then
		if self.isBought then
			self:addFillLevel(-self.cost,UniversalProcessKit.FILLTYPE_MONEY)
		else
			self:addFillLevel(self.revenues,UniversalProcessKit.FILLTYPE_MONEY)
		end
	elseif self.mode=="rent" then
		if self.isBought then
			self.rentDue=g_currentMission.environment.currentHour
			g_currentMission.environment:addHourChangeListener(self)
		else
			g_currentMission.environment:removeHourChangeListener(self)
		end
	end
	if alreadySent==nil or not alreadySent then
		self:raiseDirtyFlags(self.isBoughtDirtyFlag)
	end
	for _,v in pairs(self.kids) do
		v:setEnable(isBought,alreadySent)
	end
end;

function UPK_BuyTrigger:hourChanged()
	if self.isServer and self.isEnabled and self.rentDue==g_currentMission.environment.currentHour then
		self:addFillLevel(-self.dailyRent,UniversalProcessKit.FILLTYPE_MONEY)
	end
end

function UPK_BuyTrigger:loadExtraNodes(xmlFile, key)
	local isBought=tobool(getXMLString(xmlFile, key .. "#isBought"))
	self:setIsBought(isBought,true)
	self.rentDue=tonumber(getXMLString(xmlFile, key .. "#rentDue"))
	return true
end;

function UPK_BuyTrigger:getSaveExtraNodes(nodeIdent)
	local nodes=""
	nodes=nodes.." isBought=\""..tostring(self.isBought).."\" rentDue=\""..tostring(self.rentDue).."\""
	return nodes
end;

function UPK_BuyTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	-- use these numbers for the collisionMask (or a combination/ sum of it)
	-- http://gdn.giants-software.com/thread.php?categoryId=16&threadId=677
	-- player = 2^20 = 1048576
	-- tractors = 2^21 = 2097152
	-- combines = 2^22 = 4194304
	-- fillables = 2^23 = 8388608
	-- all = 15728640
	if self.isEnabled and (onEnter or onLeave) then
		if g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
			if onEnter then
				self.playerInRange = true
				g_currentMission:addActivatableObject(self.buyTriggerActivatable)
			else
				self.playerInRange = false
				g_currentMission:removeActivatableObject(self.buyTriggerActivatable)
			end
		else
			local vehicle = g_currentMission.objectToTrailer[otherShapeId] or g_currentMission.nodeToVehicle[otherShapeId]
			if vehicle ~= nil then
				if onEnter then
					self.vehiclesInRange[vehicle] = true
					g_currentMission:addActivatableObject(self.buyTriggerActivatable)
				else
					self.vehiclesInRange[vehicle] = nil
					g_currentMission:removeActivatableObject(self.buyTriggerActivatable)
				end
			end
		end
	end
end

UPK_BuyTriggerActivatable = {}
local UPK_BuyTriggerActivatable_mt = Class(UPK_BuyTriggerActivatable)
function UPK_BuyTriggerActivatable:new(upkmodule)
	local self = {}
	setmetatable(self, UPK_BuyTriggerActivatable_mt)
	self.upkmodule = upkmodule
	self.activateText = "unknown"
	return self
end
function UPK_BuyTriggerActivatable:getIsActivatable()
	if self.upkmodule.mode=="buy" then
		if (self.upkmodule:getIsBought() and self.upkmodule.sellable) or
			 (not self.upkmodule:getIsBought() and self.upkmodule.buyable) then
			self:updateActivateText()
			return true
		end
	elseif self.upkmodule.mode=="rent" then
		return true
	end
	return false
end
function UPK_BuyTriggerActivatable:onActivateObject()
	self.upkmodule:setIsBought(not self.upkmodule:getIsBought())
	self:updateActivateText()
	g_currentMission:addActivatableObject(self)
end
function UPK_BuyTriggerActivatable:drawActivate()
end
function UPK_BuyTriggerActivatable:updateActivateText()
	local objectName=""
	if self.i18nNameSpace~=nil and _g[self.i18nNameSpace]~=nil then
		setfenv(1,_g[self.i18nNameSpace]); objectName=g_i18n:getText(self.l10n_objectName);
	end
	if self.upkmodule.mode=="buy" then
		if self.upkmodule:getIsBought() then
			setfenv(1,_g['AAA_UniversalProcessKit']); dummy=g_i18n:getText('buytrigger_sell_OBJECT');
			self.activateText = string.format(dummy, objectName)
		else
			setfenv(1,_g['AAA_UniversalProcessKit']); dummy=g_i18n:getText('buytrigger_buy_OBJECT');
			self.activateText = string.format(dummy, objectName)
		end
	elseif self.upkmodule.mode=="rent" then
		if self.upkmodule:getIsBought() then
			setfenv(1,_g['AAA_UniversalProcessKit']); dummy=g_i18n:getText('buytrigger_stop_rent_OBJECT');
			self.activateText = string.format(dummy, objectName)
		else
			setfenv(1,_g['AAA_UniversalProcessKit']); dummy=g_i18n:getText('buytrigger_start_rent_OBJECT');
			self.activateText = string.format(dummy, objectName)
		end
	end
end
