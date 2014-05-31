-- by mor2000

UniversalProcessKit=_g.UniversalProcessKit
local UniversalProcessKit_mt = ClassUPK(UniversalProcessKit, Object);
InitObjectClass(UniversalProcessKit, "UniversalProcessKit");

function UniversalProcessKit:onCreate(id)
	local object = UPK_Base:new(g_server ~= nil, g_client ~= nil)
	object.builtIn=true
	if object:load(id) then
		g_currentMission:addOnCreateLoadedObject(object)
		object:register(true)
	else
		object:delete()
	end
end;

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
				if type(v)=="number" then
					t[v]=self.fillLevels[v]
				end
			end
			return t
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
			return ((rawget(self,'parent') or {}).acceptedFillTypes or {})[k]
		end,
		__newindex=function(t,k,v)
			if type(rawget(self,"parent"))=="table" then
				self.parent.acceptedFillTypes[k]=v
			else
				rawset(t,k,v)
			end
		end,
		__len=function(t)
			local len=0
			for i=1,UniversalProcessKit.NUM_FILLTYPES do  --fillTypes used: 1-max. 64, 1025-sth
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
			return t
		end	
	})

	self.pos=__c({0,0,0})
	self.wpos=__c({0,0,0})
	self.rot=__c({0,0,0})
	self.scale=__c({1,1,1})

	self.kids={}

	self.name=""
	self.type=""

	self.isEnabled=true

	--registerObjectClassName(self, "UniversalProcessKit")
	return self
end;

function UniversalProcessKit:load(id,parent)
	self.rootNode = id
	self.nodeId = id
	
	self.sumdt=0
	
	self.parent = parent
	self.onCreates = {}
	
	self.x,self.y,self.z = getTranslation(self.nodeId)
	self.pos = __c({self.x,self.y,self.z})
	self.wpos = __c({getWorldTranslation(self.nodeId)})
	self.rot = __c({getRotation(self.nodeId)})
	self.wrot = __c({getWorldRotation(self.nodeId)})
	self.scale = __c({getScale(self.nodeId)})
	
	self.fillTypesToSync={}
	
	-- accepted fillTypes or fillTypes to store
	local acceptedFillTypesString = getUserAttribute(self.nodeId, "fillTypes")
	if acceptedFillTypesString~=nil then
		for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(gmatch(acceptedFillTypesString, "%S+"))) do
			rawset(self.acceptedFillTypes,v,true)
			--self:print('accepted fillType: '..tostring(UniversalProcessKit.fillTypeIntToName[v])..' ('..tostring(v)..') '..tostring(self.acceptedFillTypes[v]))
		end
	end
	
	-- capacity
	
	self.capacity=tonumber(getUserAttribute(self.nodeId, "capacity"))

	-- self.capacity = tonumber(Utils.getNoNil(getUserAttribute(self.nodeId, "capacity"),math.huge))
	-- self.capacities not quite implemented yet
	--[[
	for k,v in pairs(self.acceptedFillTypes) do
		if type(v)=="boolean" then
			local fillType=UniversalProcessKit.fillTypeIntToName[k]
			if type(fillType)=="string" and #fillType>0 then
				local attributeStr="capacity"..fillType:sub(1,1):upper()..fillType:sub(2)
				self:print("setting capacity for "..tostring(attributeStr))
				local capacity = tonumber(getUserAttribute(self.nodeId, attributeStr))
				if capacity~=nil then
					rawset(self.capacities,k,capacity)
				end
			end
		end
	end
	]]--


	-- storageType
	
	local storageTypeStr=getUserAttribute(self.nodeId, "storageType")
	if storageTypeStr~=nil then
		if storageTypeStr=="single" then
			self:print('storageType is single')
			self.storageType=UPK_Storage.SINGLE
		elseif storageTypeStr=="fifo" then
			self.storageType=UPK_Storage.FIFO
		elseif storageTypeStr=="filo" then
			self.storageType=UPK_Storage.FILO
		end
	end
	
	-- addNodeObject
	if self.addNodeObject and getRigidBodyType(self.nodeId) ~= "NoRigidBody" then
		g_currentMission:addNodeObject(self.nodeId, self)
	end
	
	-- i18nNameSpace
	
	self.i18nNameSpace=getUserAttribute(self.nodeId, "i18nNameSpace")
	
	-- enable processing of stuff
	
	self.name = getName(self.nodeId)
	self.type = getUserAttribute(self.nodeId, "type")
	self.isEnabled = tobool(Utils.getNoNil(getUserAttribute(self.nodeId, "isEnabled"), "true"))

	-- MapHotspot
	
	self.appearsOnPDA = tobool(getUserAttribute(self.nodeId, "appearsOnPDA"))
	self.MapHotspotName = getUserAttribute(self.nodeId, "MapHotspot")
	local mapHotspotIcons={
		Bank="$dataS2/missions/hud_pda_spot_bank.png",
		Shop="$dataS2/missions/hud_pda_spot_shop.png",
		Phone="$dataS2/missions/hud_pda_spot_phone.png",
		Eggs="$dataS/missions/hud_pda_spot_eggs.png",
		TipPlace="$dataS2/missions/hud_pda_spot_tipPlace.png",
		Cows="$dataS2/missions/hud_pda_spot_cows.png",
		Sheep="$dataS2/missions/hud_pda_spot_sheep.png",
		Chickens="$dataS2/missions/hud_pda_spot_chickens.png"}
	
	if self.MapHotspotName~=nil then
		if mapHotspotIcons[self.MapHotspotName]~=nil then
			self.MapHotspotIcon = Utils.getFilename(mapHotspotIcons[self.MapHotspotName], getAppBasePath())
		else
			local iconStr = getUserAttribute(self.nodeId, "MapHotspotIcon")
			if iconStr~=nil then
				if self.i18nNameSpace==nil then
					self:print('you need to set the i18nNameSpace to use MapHotspotIcon')
				else
					self.MapHotspotIcon = g_modNameToDirectory[self.i18nNameSpace]..iconStr
					--self:print('using \"'..tostring(self.MapHotspotIcon)..'\" as MapHotspotIcon')
				end
			end
		end
	end

	if self.MapHotspotName~=nil then
		self:showMapHotspot(self.appearsOnPDA)
	end
	
	-- placeable object
	
	if self.type~="base" and self.parent~=nil then
		self.placeable=self.parent.placeable
	end
	
	self:print('self.placeable '..tostring(self.placeable))

	-- loading kids (according to known types of modules)
	-- kids are loading their kids and so on..
	
	print('loading module '..tostring(self.name)..' with id '..tostring(self.id))
	
	self:findChildren(id)
	
	return true
end;

function UniversalProcessKit:readStream(streamId, connection)
	UniversalProcessKit:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local serverId=streamReadInt32(streamId)
		g_client:finishRegisterObject(self, serverId)
		local nrFillLevelsToSync=streamReadInt8(streamId)
		for i=1,nrFillLevelsToSync do
			fillType=streamReadInt8(streamId)
			fillLevel=streamReadFloat32(streamId)
			if fillType~=nil then
				self.fillLevels[fillType]=fillLevel
			end
		end
		local isEnabled=streamReadBool(streamId)
		self:setEnable(isEnabled,true)
		local showMapHostspot=streamReadBool(streamId)
		self:showMapHotspot(showMapHostspot,true)
		for k,v in pairs(self.kids) do
			v:readStream(streamId, connection)
		end
	end
end;

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
end;

function UniversalProcessKit:readUpdateStream(streamId, timestamp, connection)
	UniversalProcessKit:superClass().readUpdateStream(self, streamId, timestamp, connection)
	
	local dirtyMask=streamReadIntN(streamId,12)
	local syncall=bitAND(dirtyMask,self.syncDirtyFlag)~=0
	
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			nrFillTypesToSync=streamReadIntN(streamId,12) or 0
			for i=1,nrFillTypesToSync do
				fillType=streamReadIntN(streamId,12)
				fillLevel=streamReadFloat32(streamId)
				self.fillLevels[fillType]=fillLevel
			end
			self.maxFillLevel=streamReadFloat32(streamId)
		end
		
		if bitAND(dirtyMask,self.enabledDirtyFlag)~=0 or syncall then
			local isEnabled=streamReadBool(streamId)
			self:setEnable(isEnabled,true)
		end
		
		if bitAND(dirtyMask,self.maphotspotDirtyFlag)~=0 or syncall then
			self.appearsOnPDA=streamReadBool(streamId)
			self:showMapHotspot(self.appearsOnPDA,true)
		end
	end
end;

function UniversalProcessKit:writeUpdateStream(streamId, connection, dirtyMask)
	UniversalProcessKit:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	
	streamWriteIntN(streamId,dirtyMask,12) -- max 12 dirtyFlags, 4 already used by default
	local syncall=bitAND(dirtyMask,self.syncDirtyFlag)~=0
	
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.fillLevelDirtyFlag)~=0 or syncall then
			local nrFillTypesToSync=0
			for k,v in pairs(self.fillTypesToSync) do
				if v then
					nrFillTypesToSync=nrFillTypesToSync+1
				end
			end
			streamWriteIntN(streamId,nrFillTypesToSync,12) -- max 2048 fillTypes
			for k,v in pairs(self.fillTypesToSync) do
				if v then
					streamWriteIntN(streamId,k,12)
					streamWriteFloat32(streamId,self.fillLevels[k])
				end
			end
			streamWriteFloat32(streamId,self.maxFillLevel)
			self.fillTypesToSync={}
		end
		
		if bitAND(dirtyMask,self.enabledDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId,self.isEnabled)
		end
		
		if bitAND(dirtyMask,self.maphotspotDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId,self.appearsOnPDA)
		end
	end
	
	-- you know how to sync your modules by now, right?
end;

function UniversalProcessKit:register()
	print('register module '..tostring(self.name)..' with id '..tostring(self.id))
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
end;

function UniversalProcessKit:unregister(alreadySent)
	print('unregister module '..tostring(self.name)..' with id '..tostring(self.id))
	if self.isServer then
		g_server:removeObject(self, self.id)
		self.isRegistered = false
		--g_server:unregisterObject(self,alreadySent)
	else
		g_client:removeObject(self, self.id)
		self.isRegistered = false
		--g_client:unregisterObject(self,alreadySent)
	end
end

function UniversalProcessKit:findChildren(id)
	local numChildren = getNumOfChildren(id)
	if type(numChildren)=="number" and numChildren>0 then
		for i=1,numChildren do
			local childId = getChildAt(id, i-1)
			if childId~=nil or childId~=0 then
				if tobool(getUserAttribute(childId, "adjustToTerrainHeight")) then
					self:adjustToTerrainHeight(childId)
				end
				local type = getUserAttribute(childId, "type")
				if type~=nil and UniversalProcessKit.ModuleTypes[type]~=nil then
					childName=Utils.getNoNil(getName(childId),"")
					self:print('found module '..childName..' of type '..tostring(type)..' and id '..tostring(childId))
					local module=UniversalProcessKit.ModuleTypes[type]:new(self.isServer,self.isClient)
					if module~=nil then
						module:load(childId,self)
						module:register(true)
						table.insert(self.kids,module)
					end
				else
					--[[ maybe later
					local onCreate=getUserAttribute(childId, "onCreate")
					if self.placeable~=nil and onCreate~=nil then
						if onCreate=="modOnCreate.DoorOnCreate" and (_g or {})['MapDoorTrigger']~=nil then
							local instance = DoorTrigger:new(self.isServer, self.isClient)
							g_currentMission:addNodeObject(childId, instance)
							instance:load(childId)
							instance:register(true)
							table.insert(self.onCreates,instance)
						end	
					end
					--]]
					self:findChildren(childId)
				end
				
			end
		end
	end
end;

function UniversalProcessKit:findChildrenShapes(id,childrenShapes)
	local numChildren = getNumOfChildren(id)
	if type(numChildren)=="number" and numChildren>0 then
		for i=1,numChildren do
			local childId = getChildAt(id, i-1)
			if childId~=nil or childId~=0 then
				table.insert(childrenShapes,childId)
				self:findChildrenShapes(childId,childrenShapes)
			end
		end
	end
end;

function UniversalProcessKit:adjustToTerrainHeight(id)
	local childrenShapes={}
	local staticShapes={}
	local rigidBodyType=getRigidBodyType(id)
	if rigidBodyType=="Static" then
		table.insert(staticShapes,id)
	end
	self:findChildrenShapes(id,childrenShapes)
	for _,v in pairs(childrenShapes) do
		local rigidBodyType=getRigidBodyType(v)
		if rigidBodyType=="Static" then
			table.insert(staticShapes,v)
		end
	end
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Kinematic")
	end
	local x,_,z=getWorldTranslation(id)
	local y=getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
	Utils.setWorldTranslation(id, x, y, z)
	for _,v in pairs(staticShapes) do
		setRigidBodyType(v,"Static")
	end
end;

function UniversalProcessKit:delete()
	--[[ maybe later
	for k,v in pairs(self.onCreates) do
		local id=v.nodeId
		v:delete()
		g_currentMission:removeNodeObject(id)
	end
	--]]
	
	print('delete module '..tostring(self.name)..' with id '..tostring(self.id))
	print('registered? '..tostring(self.isRegistered==true))
	self:unregister(true)
	print('successful? '..tostring(self.isRegistered==false))
	
	for _,v in pairs(self.kids) do
		v:removeTrigger()
		v:delete()
	end
	
	self.kids={}

	if self.addNodeObject and self.nodeId ~= 0 then
		g_currentMission:removeNodeObject(self.nodeId)
	end
	
	unregisterObjectClassName(self)
end;

function UniversalProcessKit:addTrigger()
	self.triggerId=self.nodeId
	addTrigger(self.triggerId, "triggerCallback", self)
end

function UniversalProcessKit:removeTrigger()
	if self.triggerId~=nil and self.triggerId~=0 then
		removeTrigger(self.triggerId)
		self.triggerId = 0
	end
end

function UniversalProcessKit:update(dt)
	-- do sth with time (ms)
end;

function UniversalProcessKit:getFillType()
	return self.fillType
end;

function UniversalProcessKit:setFillType(fillType)
	if fillType~=nil then
		self.fillType = fillType
		--self.capacity=self.capacities[self.fillType]
	else
		self.fillType = nil
		--self.capacity=self.capacities.FILLTYPE_UNKNOWN
	end	
end;

function UniversalProcessKit:getFillLevel(fillType)
	return self.fillLevels[fillType or self.fillType]
end;

function UniversalProcessKit:setFillLevel(fillLevel, fillType)
	self:print('UniversalProcessKit:setFillLevel('..tostring(fillLevel)..', '..tostring(fillType)..')')
	local currentFillType=self.fillType or Fillable.FILLTYPE_UNKNOWN
	fillType=fillType or currentFillType
	if fillType==currentFillType or currentFillType==Fillable.FILLTYPE_UNKNOWN then
		if fillType==UniversalProcessKit.FILLTYPE_MONEY or fillType==UniversalProcessKit.FILLTYPE_VOID then
			-- can't set money, delete void
			return 0
		elseif fillLevel~=nil and fillType~=nil then
			local newFillLevel=mathmin(mathmax(fillLevel,0),self.capacity)
			self.fillLevels[fillType]=newFillLevel
			self.fillTypesToSync[fillType]=true
			if self.isServer then
				self.maxFillLevel=max(unpack(self.fillLevels(self:getAcceptedFillTypes())))
			end
			self:raiseDirtyFlags(self.fillLevelDirtyFlag)
			return newFillLevel-fillLevel
		end
	end
	return 0
end;

function UniversalProcessKit:addFillLevel(deltaFillLevel, fillType)
	self:print('UniversalProcessKit:addFillLevel('..tostring(deltaFillLevel)..', '..tostring(fillType)..')')
	if fillType==UniversalProcessKit.FILLTYPE_MONEY then
		if deltaFillLevel<0 then
			deltaFillLevel=-mathmin(g_currentMission:getTotalMoney(),-deltaFillLevel)
		end
		if self.isServer then
			g_currentMission:addMoney(deltaFillLevel, 1, self.statName or "other")
		end
		return deltaFillLevel
	end
	local currentFillType=self.fillType or Fillable.FILLTYPE_UNKNOWN
	if (fillType==currentFillType or currentFillType==Fillable.FILLTYPE_UNKNOWN) and deltaFillLevel~=nil and deltaFillLevel~=0 then
		-- how much of deltaFillLevel was added to the fillLevel?
		local added=self:setFillLevel(self.fillLevels[fillType]+deltaFillLevel, fillType)
		return added+deltaFillLevel
	end
	return 0
end;

function UniversalProcessKit:getUniqueFillType()
	local currentFillType=Fillable.FILLTYPE_UNKNOWN
	for _,v in pairs(self:getAcceptedFillTypes()) do
		fillLevel=self.fillLevels[v]
		if fillLevel~=nil and fillLevel>0 then
			return v
		end
	end
	return currentFillType
end;

function UniversalProcessKit:getAcceptedFillTypes()
	local r={}
	for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
		if self.acceptedFillTypes[k] then
			table.insert(r,k)
		end
	end
	return r
end;

-- show or hide an icon on the pda map
function UniversalProcessKit:showMapHotspot(on,alreadySent)
	self.appearsOnPDA=on
	if on==true and self.mapHotspot == nil then
		local iconSize = g_currentMission.missionPDA.pdaMapWidth / 15
		local x,_,z = unpack(self.wpos)
		self.mapHotspot = g_currentMission.missionPDA:createMapHotspot(self.MapHotspotName, self.MapHotspotIcon, x, z, iconSize, iconSize * 4 / 3, false, false, false, 0, true)
	end
	if on==false and type(self.mapHotspot)=="table" and self.mapHotspot.delete~=nil then
		g_currentMission.missionPDA:deleteMapHotspot(self.mapHotspot)
		self.mapHotspot=nil
	end
	if not alreadySent then
		self:raiseDirtyFlags(self.maphotspotDirtyFlag)
	end
end;

function UniversalProcessKit:setEnable(isEnabled,alreadySent)
	self.isEnabled=isEnabled
	if alreadySent==nil or not alreadySent then
		self:raiseDirtyFlags(self.enabledDirtyFlag)
	end
	for _,v in pairs(self.kids) do
		v:setEnable(isEnabled,alreadySent)
	end
end;

function UniversalProcessKit:loadFromAttributesAndNodes(xmlFile, key)
	self:print('calling UniversalProcessKit:loadFromAttributesAndNodes for id '..tostring(self.nodeId))
	key=key.."."..self.name
	
	--local fillType=getXMLFloat(xmlFile, key .. "#fillType")
	--if fillType~=nil then
	--	self:setFillType(unpack(UniversalProcessKit.fillTypeNameToInt(fillType)))
	--end
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
end;

function UniversalProcessKit:getSaveAttributesAndNodes(nodeIdent)
	self:print('calling UniversalProcessKit:getSaveAttributesAndNodes for id '..tostring(self.nodeId))
	local attributes=""
	
	local nodes = "\t<"..tostring(self.name)

	--nodes=nodes.." fillType=\""..tostring(UniversalProcessKit.fillTypeIntToName[self.fillType]).."\""
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
			extraNodes = extraNodes .. " " .. tostring(v) .. "=\"" .. tostring(mathfloor(fillLevel*1000+0.5)/1000) .. "\""
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
end;

-- use this function to load your extra Nodes (YourClass:loadExtraNodes)
function UniversalProcessKit:loadExtraNodes(xmlFile, key)
	return true
end;

-- use this function to save your own values (YourClass:getSaveExtraNodes)
function UniversalProcessKit:getSaveExtraNodes(nodeIdent)
	return ""
end;

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
