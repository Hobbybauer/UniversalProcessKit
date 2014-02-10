-- by mor2000

_g.UniversalProcessKit = {}
local UniversalProcessKit_mt = ClassUPK(UniversalProcessKit, Object)
InitObjectClass(UniversalProcessKit, "UniversalProcessKit")

UniversalProcessKit.modulesToSync={}

function UniversalProcessKit:new(isServer, isClient, customMt)
	local self = Object:new(isServer, isClient, customMt or UniversalProcessKit_mt)
	registerObjectClassName(self, "UniversalProcessKit")

	self.rootNode = 0
	self.triggerId = 0
	self.nodeId = 0

	self.parent=nil
	self.kids={}
	self.type=nil

	self.i18nNameSpace=nil

	self.syncDirtyFlag = self:getNextDirtyFlag()
	self.fillLevelDirtyFlag = self:getNextDirtyFlag()
	self.enabledDirtyFlag = self:getNextDirtyFlag()
	self.maphotspotDirtyFlag = self:getNextDirtyFlag()

	-- lets make things easy dealing with fillLevels, parents and stuff

	self.fillLevels={}
	setmetatable(self.fillLevels, {
		__index = function(t,k)
			if k==UniversalProcessKit.FILLTYPE_MONEY then
				return g_currentMission:getTotalMoney()
			end
			local fillLevel=rawget(self.fillLevels,k)
			if fillLevel==nil and type(rawget(self,"parent"))=="table" then
				fillLevel=self.parent.fillLevels[k]
			end
			return fillLevel or 0
		end,
		__newindex=function(t,k,v)
			if type(rawget(self,"parent"))=="table" then
				self.parent.fillLevels[k]=v
			else
				rawset(self.fillLevels,k,v) -- if not initialized yet
			end
		end,
		__call=function(func,...)
			local t={}
			local args=...
			if type(args)~="table" then
				args={...}
			end
			for k,v in pairs(args) do
				local type=type(v)
				if type=="number" then
					if self.fillLevels[v]~=nil then
						table.insert(t,self.fillLevels[v])
					end
				end
			end
			return __c(t)
		end	
	})
	
	-- self.capacities not quite implemented yet
	--[[
	self.capacities={}
	setmetatable(self.capacities, {
		__index = function(t,k)
			local capacity=rawget(t,k)
			if capacity==nil and type(rawget(self,"parent"))=="table" then
				capacity=self.parent.capacities[k]
			end
			return capacity
		end,
		__newindex=function(t,k,v)
			if rawget(t,k)==nil and type(rawget(self,"parent"))=="table" then
				self.parent.capacities[k]=v
			else
				rawset(t,k,v)
				--self:rawSetFillLevel(v,k)
			end
		end,
		__call=function(func,...)
			local t={}
			local args=...
			if type(args)~="table" then
				args={...}
			end
			for _,v in pairs(args) do
				if type(v)=="number" then
					table.insert(t,v,self.capacities[v])
				end
			end
			return __c(t)
		end	
	})
	self.capacities.FILLTYPE_UNKNOWN=math.huge
	--]]

	self.acceptedFillTypes={}
	setmetatable(self.acceptedFillTypes, {
		__index = function(t,k)
			local acceptedFillType=rawget(t,k)
			if acceptedFillType==nil then
				if type(rawget(self,"parent"))=="table" then
					acceptedFillType=self.parent.acceptedFillTypes[k]
				end
			end
			return acceptedFillType
		end,
		__newindex=function(t,k,v)
			if rawget(t,k)==nil and type(rawget(self,"parent"))=="table" then
				self.parent.acceptedFillTypes[k]=v
			else
				rawset(t,k,v)
			end
		end,
		__len=function(t)
			local len=0
			for i=1,UniversalProcessKit.NUM_FILLTYPES do
				if t[i]~=nil then
					len=len+1
				end
			end
			return len
		end,
		__call=function(func,...)
			local t={}
			local args=...
			if type(args)~="table" then
				args={...}
			end
			for k,v in pairs(args) do
				local type=type(v)
				if type=="number" then
					local acceptedFillTypes=self.acceptedFillTypes[v]
					if acceptedFillTypes~=nil then
						table.insert(t,acceptedFillTypes)
					end
				end
			end
			return __c(t)
		end	
	})

	self.pos=__c({0,0,0})
	self.wpos=__c({0,0,0})
	self.rot=__c({0,0,0})

	self.triggerIds={}

	self.kids={}

	self.name=""
	self.type=""

	self.isEnabled=true

	--registerObjectClassName(self, "UniversalProcessKit")
	return self
end

function UniversalProcessKit:load(id,parent)
	self.rootNode = id
	self.triggerId = id
	self.nodeId = id
	
	self.sumdt=0
	
	self.parent = parent
	
	self.x,self.y,self.z = getTranslation(self.nodeId)
	self.pos = __c({self.x,self.y,self.z})
	self.wpos = __c({getWorldTranslation(self.nodeId)})
	self.rot = __c({getRotation(self.nodeId)})
	
	self.fillTypesToSync={}
	
	-- accepted fillTypes or fillTypes to store
	local acceptedFillTypesString = getUserAttribute(self.nodeId, "fillTypes")
	for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(gmatch(acceptedFillTypesString, "%S+"))) do
		rawset(self.acceptedFillTypes,v,true)
	end
	
	-- capacity
	
	self.capacity=getUserAttribute(self.nodeId, "capacity")

	-- self.capacity = tonumber(Utils.getNoNil(getUserAttribute(self.nodeId, "capacity"),math.huge))
	-- self.capacities not quite implemented yet
	--[[
	for k,v in pairs(self.acceptedFillTypes) do
		if type(v)=="boolean" then
			local fillType=UniversalProcessKit.fillTypeIntToName[k]
			if type(fillType)=="string" and #fillType>0 then
				local attributeStr="capacity"..fillType:sub(1,1):upper()..fillType:sub(2)
				print("setting capacity for "..tostring(attributeStr))
				local capacity = tonumber(getUserAttribute(self.nodeId, attributeStr))
				if capacity~=nil then
					rawset(self.capacities,k,capacity)
				end
			end
		end
	end
	]]--

	-- loading kids (according to known types of modules)
	-- kids are loading their kids and so on..
	
	
	self:findChildren(id,1)

	
	-- enable processing of stuff
	
	self.name = getName(self.nodeId)
	self.type = getUserAttribute(self.nodeId, "type")
	self.isEnabled = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "isEnabled"), "true"))

	-- MapHotspot
	
	self.MapHotspotName = getUserAttribute(self.nodeId, "MapHotspot")
	local mapHotspotIcons = { TipPlace = "dataS2/missions/hud_pda_spot_tipPlaceGold.png" }
	if self.MapHotspotName~=nil and mapHotspotIcons[self.MapHotspotName]~=nil then
		self.MapHotspotIcon = mapHotspotIcons[self.MapHotspotName]
	else
		self.MapHotspotIcon = mapHotspotIcons["TipPlace"]
	end

	if self.MapHotspotName~=nil then
		self:showMapHotspot(self.appearsOnPDA)
	end
	
	-- i18nNameSpace
	
	self.i18nNameSpace=getUserAttribute(self.nodeId, "i18nNameSpace")
	if self.i18nNameSpace==nil and self.parent~=nil then
		self.i18nNameSpace=self.parent.i18nNameSpace
	end
	
	g_currentMission:addNodeObject(self.nodeId, self)

	return true
end

function UniversalProcessKit:readStream(streamId, connection)
	UniversalProcessKit:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local serverId=streamReadInt32(streamId)
		g_client:finishRegisterObject(self, serverId)
		local nrFillLevelsToSync=streamReadInt8(streamId)
		for i=1,nrFillLevelsToSync do
			fillType=streamReadInt8(streamId)
			fillLevel=streamReadFloat32(streamId)
			self.fillLevels[fillType]=fillLevel
		end
		local isEnabled=streamReadBool(streamId)
		self:setEnable(isEnabled,true)
		local showMapHostspot=streamReadBool(streamId)
		self:showMapHotspot(showMapHostspot,true)
		for k,v in pairs(self.kids) do
			v:readStream(streamId, connection)
		end
	end
end

function UniversalProcessKit:writeStream(streamId, connection)
	UniversalProcessKit:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteInt32(streamId, self.id)
		local nrFillLevelsToSync=0
		local fillLevelsToSync={}
		for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
			fillLevel=rawget(self.fillLevels,k)
			if fillLevel~=nil and fillLevel~=0 then
				table.insert(fillLevelsToSync,k,fillLevel)
				nrFillLevelsToSync=nrFillLevelsToSync+1
			end
		end
		streamWriteInt8(streamId,nrFillLevelsToSync) -- max 256 fillTypes
		for k,v in pairs(fillLevelsToSync) do
			streamWriteInt8(streamId,k)
			streamWriteFloat32(streamId,v)
		end
		streamWriteBool(streamId,self.isEnabled)
		streamWriteBool(streamId,self.mapHotspot~=nil)
		for k,v in pairs(self.kids) do
			v:writeStream(streamId, connection)
		end
	end
end

function UniversalProcessKit:readUpdateStream(streamId, timestamp, connection)
	UniversalProcessKit:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		local dirtyMask=streamReadInt8(streamId)
		local syncall=bitAND(dirtyMask,self.syncDirtyFlag)~=0
		
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillTypesToSync=streamReadInt8(streamId)
			for i=1,nrFillTypesToSync do
				fillType=streamReadInt8(streamId)
				fillLevel=streamReadFloat32(streamId)
				self.fillLevels[fillType]=fillLevel
			end
		end
		
		if bitAND(dirtyMask,self.enabledDirtyFlag)~=0 or syncall then
			local isEnabled=streamReadBool(streamId)
			self:setEnable(isEnabled,true)
		end
		
		if bitAND(dirtyMask,self.maphotspotDirtyFlag)~=0 or syncall then
			local showMapHostspot=streamReadBool(streamId)
			self:showMapHotspot(showMapHostspot,true)
		end

	end
end

function UniversalProcessKit:writeUpdateStream(streamId, connection, dirtyMask)
	UniversalProcessKit:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		streamWriteInt8(streamId,dirtyMask) -- max 8 dirtyFlags, 4 already used by default
		local syncall=bitAND(dirtyMask,self.syncDirtyFlag)~=0
		
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			local nrFillTypesToSync=0
			for k,v in pairs(self.fillTypesToSync) do
				if v then
					nrFillTypesToSync=nrFillTypesToSync+1
				end
			end
			streamWriteInt8(streamId,nrFillTypesToSync) -- max 256 fillTypes
			for k,v in pairs(self.fillTypesToSync) do
				if v then
					streamWriteInt8(streamId,k)
					streamWriteFloat32(streamId,self.fillLevels[k])
				end
			end
			self.fillTypesToSync={}
		end
		
		if bitAND(dirtyMask,self.enabledDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId,self.isEnabled)
		end
		
		if bitAND(dirtyMask,self.maphotspotDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId,self.mapHotspot~=nil)
		end
		
		-- you know how to sync your modules by now, right?
	end
end

function UniversalProcessKit:register()
	if self.isServer then
		g_server:addObject(self, self.id)
		self.isManuallyReplicated = true
		self.isRegistered = true
	else
		g_client:addObject(self, self.id)
		g_client:registerObject(self, true)
		g_client:finishRegisterObject(self,self.id)
		g_client:getServerConnection():sendEvent(UniversalProcessKitSyncEvent:new(self.id))
	end
end

function UniversalProcessKit:findChildren(id,numKids)
	local numChildren = getNumOfChildren(id)
	for i=1,numChildren do
		local childId = getChildAt(id, i-1)
		if childId~=nil or childId~=0 then
			local scriptCallback = getUserAttribute(childId, "scriptCallback")
			if scriptCallback==nil then
				local type = getUserAttribute(childId, "type")
				if type~=nil and UniversalProcessKit.ModuleTypes[type]~=nil then
					childName=Utils.getNoNil(getName(childId),"")
					print('found module '..childName..' of type '..tostring(type)..' and id '..tostring(childId))
					self.kids[numKids]=UniversalProcessKit.ModuleTypes[type]:new(self.isServer,self.isClient)
					if self.kids[numKids]~=nil then
						self.kids[numKids]:load(childId,self)
						self.kids[numKids]:register(true)
						self.kids[numKids].name=childName
						numKids=numKids+1
					end
				else
					self:findChildren(childId,numKids)
				end
			end
		end
	end
end

function UniversalProcessKit:delete()
	for _,v in pairs(self.kids) do
		v:delete(v)
	end
	for _,v in pairs(self.triggerIds) do
		removeTrigger(v)
	end
	if self.mapHotspot ~= nil then
		g_currentMission.missionPDA:deleteMapHotspot(self.mapHotspot)
	end
	
	if self.isRegistered then
		if self.isServer then
			g_server:unregisterObject(self,true)
			--g_server:removeObject(self, self.id)
		else
			g_client:unregisterObject(self,true)
			--g_client:removeObject(self, self.id)
		end
	end
	
	if self.nodeId ~= 0 then
		g_currentMission:removeNodeObject(self.nodeId)
	end
	
	unregisterObjectClassName(self)
	
	UniversalProcessKit:superClass().delete(self)
end

function UniversalProcessKit:update(dt)
	-- do sth with time (ms)
end

function UniversalProcessKit:getFillType()
	return self.fillType
end

function UniversalProcessKit:setFillType(fillType)
	if fillType~=nil then
		self.fillType = fillType
		--self.capacity=self.capacities[self.fillType]
	else
		self.fillType = Fillable.FILLTYPE_UNKNOWN
		--self.capacity=self.capacities.FILLTYPE_UNKNOWN
	end	
end

function UniversalProcessKit:getFillLevel(fillType)
	return self.fillLevels[fillType]
end

function UniversalProcessKit:setFillLevel(fillLevel, fillType)
	local currentFillType=self.fillType
	fillType=fillType or currentFillType
	if fillType==currentFillType or currentFillType==Fillable.FILLTYPE_UNKNOWN then
		if fillLevel~=nil and fillType~=nil and fillType~=UniversalProcessKit.FILLTYPE_MONEY then
			local newFillLevel=math.min(math.max(fillLevel,0),self.capacity)
			self.fillLevels[fillType]=fillLevel
			self.fillTypesToSync[fillType]=true
			self:raiseDirtyFlags(self.fillLevelDirtyFlag)
			return newFillLevel-fillLevel
		elseif fillType==UniversalProcessKit.FILLTYPE_MONEY then
			-- can't set money
			return 0
		end
	end
	return nil
end

function UniversalProcessKit:addFillLevel(deltaFillLevel, fillType)
	if deltaFillLevel~=nil and deltaFillLevel~=0 then
		if fillType==UniversalProcessKit.FILLTYPE_MONEY then
			if deltaFillLevel<0 then
				deltaFillLevel=-math.min(g_currentMission:getTotalMoney(),-deltaFillLevel)
			end
			if self.isServer then
				g_currentMission:addMoney(deltaFillLevel, 1, self.statName or "other")
			end
			return deltaFillLevel
		end
		-- how much of deltaFillLevel was added to the fillLevel?
		return deltaFillLevel-self:setFillLevel(self.fillLevels[fillType]+deltaFillLevel, fillType)
	end
	return 0
end

-- show or hide an icon on the pda map
function UniversalProcessKit:showMapHotspot(on,alreadySent)
	if alreadySent==nil or not alreadySent then
		self:raiseDirtyFlags(self.maphotspotDirtyFlag)
	end
	if on==true and self.mapHotspot == nil then
		local iconSize = g_currentMission.missionPDA.pdaMapWidth / 15
		local x,_,z = unpack(self.pos)
		self.mapHotspot = g_currentMission.missionPDA:createMapHotspot(self.MapHotspotName, self.MapHotspotIcon, x, z, iconSize, iconSize * 1.3333333333333333, false, false, false, 0, true)
	end
	if on==false and self.mapHotspot ~= nil then
		g_currentMission.missionPDA:deleteMapHotspot(self.mapHotspot)
	end
	for _,v in pairs(self.kids) do
		v:showMapHotspot(on,alreadySent)
	end
end

function UniversalProcessKit:setEnable(isEnabled,alreadySent)
	self.isEnabled=isEnabled
	if alreadySent==nil or not alreadySent then
		self:raiseDirtyFlags(self.enabledDirtyFlag)
	end
	for _,v in pairs(self.kids) do
		v:setEnable(isEnabled,alreadySent)
	end
end

function UniversalProcessKit:loadFromAttributesAndNodes(xmlFile, key)
	key=key.."."..self.name
	
	local fillType=getXMLFloat(xmlFile, key .. "#fillType")
	if fillType~=nil then
		self:setFillType(unpack(UniversalProcessKit.fillTypeNameToInt(fillType)))
	end
	if getXMLFloat(xmlFile, key .. "#isEnabled")=="false" then
		self:setEnable(false)
	end
	if getXMLFloat(xmlFile, key .. "#showMapHotspot")=="false" then
		self:showMapHotspot(false)
	end
	
	for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
		local fillLevel = getXMLFloat(xmlFile, key .. "#" .. tostring(v))
		if fillLevel~=nil then
			self:setFillLevel(fillLevel,k,true)
		end
	end
	
	for k,v in pairs(self.kids) do
		v:loadFromAttributesAndNodes(xmlFile, key)
	end

	return self:loadExtraNodes(xmlFile, key)
end

function UniversalProcessKit:getSaveAttributesAndNodes(nodeIdent)
	local attributes=""
	
	local nodes = "\t<"..tostring(self.name)

	nodes=nodes.." fillType=\""..tostring(UniversalProcessKit.fillTypeIntToName[self.fillType]).."\""
	if not self.isEnabled then
		nodes=nodes.." isEnabled=\"false\""
	end
	if self.mapHotspot~=nil then
		nodes=nodes.." showMapHotspot=\"true\""
	end
	
	local extraNodes=""
	for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
		local fillLevel=rawget(self.fillLevels,k)
		if fillLevel~=nil and fillLevel>=0.001 then
			extraNodes = extraNodes .. " " .. tostring(v) .. "=\"" .. tostring(math.floor(fillLevel*1000+0.5)/1000) .. "\""
		end
	end

	extraNodes=extraNodes..self:getSaveExtraNodes(nodeIdent)
	
	local nodesKids=""
	for k,v in pairs(self.kids) do
		local attributesKid, nodesKid = v:getSaveAttributesAndNodes(nodeIdent)
		attributes = attributes .. attributesKid
		if nodesKid~="" then
			nodesKids = nodesKids .. nodesKid
		end
	end
	
	if nodesKids=="" then
		if extraNodes=="" then
			nodes=""
		else
			nodes = nodes .. extraNodes .. " />\n"
		end
	else
		nodes = nodes .. extraNodes ..">\n" .. string.gsub(nodesKids,"\n","\n\t") .. "\n\t</"..tostring(self.name)..">"
	end
	
	return attributes, nodes
end

-- use this function to load your extra Nodes (YourClass:loadExtraNodes)
function UniversalProcessKit:loadExtraNodes(xmlFile, key)
	return true
end

-- use this function to save your own values (YourClass:getSaveExtraNodes)
function UniversalProcessKit:getSaveExtraNodes(nodeIdent)
	return ""
end

-- to communicate orders between modules
-- possible receivers
-- ALL: all modules and base execute the action (if they have it)
-- ALL_TYPE: all modules of type TYPE execute the action (ie ALL_FILLTRIGGER)
-- name: a specific module with name
-- NOT TESTED, NOT IMPLEMENTED

--[[

function UniversalProcessKit:getType()
	return self.type
end

function UniversalProcessKit:getName()
	return self.name
end

function UniversalProcessKit:induceAction(sender, receiverName, transmitter, action, value)
	if receiverName.sub(1,4)=="ALL_" and receiverName.sub(5)==string.upper(self.type) then
		self:induceActionToParent(sender, receiverName, transmitter, action, value)
		self:induceActionToKids(sender, receiverName, transmitter, action, value)
		self:executeAction(action, value)
	elseif receiverName=="ALL" then
		self:induceActionToParent(sender, receiverName, transmitter, action, value)
		self:induceActionToKids(sender, receiverName, transmitter, action, value)
		self:executeAction(action, value)
	elseif receiverName==self.name then
		self:executeAction(sender, action, value)
	end	
end

function UniversalProcessKit:induceActionToParent(sender, receiverName, transmitter, action, value)
	if self.parent~=nil and self.parent~=transmitter then
		self.parent:induceAction(sender, receiverName, self, action, value)
	end
end

function UniversalProcessKit:induceActionToKids(sender, receiverName, transmitter, action, value)
	for i in #self.kids do
		if self.kids[i].getType~=nil and self.kids[i]:getType()~=nil and self.kids[i]~=transmitter then
			self.kids[i]:induceAction(sender, receiverName, self, action, value)
		end
	end
end

-- modify this function in modules to respond to action calls of other modules
function UniversalProcessKit:executeAction(sender, action, value)
	-- yet missing: sendEvent to synchronize - UniversalProcessKitEvent
end

--]]
