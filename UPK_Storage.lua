-- by mor2000

--------------------
-- Storage


local UPK_Storage_mt = ClassUPK(UPK_Storage)
InitObjectClass(UPK_Storage, "UPK_Storage")
UniversalProcessKit.addModule("storage",UPK_Storage)

function UPK_Storage:new(isServer, isClient, customMt)
	local self = UPK_Storage:superClass().new(self, isServer, isClient, customMt or UPK_Storage_mt)
	registerObjectClassName(self, "UPK_Storage")
	return self
end

function UPK_Storage:load(id, parent)
	if not UPK_Storage:superClass().load(self, id, nil) then
		self:print('Error: loading Storage failed',true)
		return false
	end
	
	self.parentForce = parent
	
	for k,_ in pairs(UniversalProcessKit.fillTypeIntToName) do
		rawset(self.fillLevels,k,0)
	end
	
	self:print("self.storageType="..tostring(self.storageType))
	if self.storageType==UPK_Storage.SINGLE then
		self.fillType=unpack(UniversalProcessKit.fillTypeNameToInt(Utils.getNoNil(getUserAttribute(self.nodeId, "fillType"),"unknown")))
		self:print('self.fillType='..tostring(self.fillType))
	end

	self.isLeaking=false

	local function getLeakArr(ArrString)
		local r={}
		for i=1,#ArrString,2 do
			local amount=tonumber(ArrString[i])
			local type=unpack(UniversalProcessKit.fillTypeNameToInt(ArrString[i+1]))
			if amount~=nil and type~=nil then
				r[type]=amount
			end
		end
		return r
	end
	
	self.leaks={}
	
	local leakingArr = gmatch(Utils.getNoNil(getUserAttribute(id, "leakPerSecond"),""),"%S+")
	if #leakingArr~=0 then
		self.leaks=getLeakArr(leakingArr)
		self.isLeaking=true
	end
	self.changeListenerType=0
	local leakingArr = gmatch(Utils.getNoNil(getUserAttribute(id, "leakPerMinute"),""),"%S+")
	if #leakingArr~=0 and self.isLeaking==false then
		self.leaks=getLeakArr(leakingArr)
		g_currentMission.environment:addMinuteChangeListener(self)
		self.changeListenerType=1
		self.isLeaking=true
	end
	local leakingArr = gmatch(Utils.getNoNil(getUserAttribute(id, "leakPerHour"),""),"%S+")
	if #leakingArr~=0 and self.isLeaking==false then
		self.leaks=getLeakArr(leakingArr)
		g_currentMission.environment:addHourChangeListener(self)
		self.changeListenerType=2
		self.isLeaking=true
	end
	local leakingArr = gmatch(Utils.getNoNil(getUserAttribute(id, "leakPerDay"),""),"%S+")
	if #leakingArr~=0 and self.isLeaking==false then
		self.leaks=getLeakArr(leakingArr)
		g_currentMission.environment:addDayChangeListener(self)
		self.changeListenerType=3
		self.isLeaking=true
	end
	
	self:print('loaded Storage successfully')
	return true
end;

function UPK_Storage:delete()
	if self.changeListenerType==1 then
		g_currentMission.environment:removeMinuteChangeListener(self)
	elseif self.changeListenerType==2 then
		g_currentMission.environment:removeHourChangeListener(self)
	elseif self.changeListenerType==3 then
		g_currentMission.environment:removeDayChangeListener(self)
	end
	UPK_Storage:superClass().delete(self)
end;

function UPK_Storage:update(dt)
	if self.isLeaking and self.changeListenerType==0 then
		for k,v in pairs(self.leaks) do
			self:addFillLevel(-self.parentForce:addFillLevel(v/1000*dt,k),k)
		end
	end
end;

function UPK_Storage:minuteChanged()
	self:leak()
end;

function UPK_Storage:hourChanged()
	self:leak()
end;

function UPK_Storage:dayChanged()
	self:leak()
end;

function UPK_Storage:leak()
	for k,v in pairs(self.leaks) do
		self:addFillLevel(-self.parentForce:addFillLevel(v,k),k)
	end
end;

function UPK_Storage:loadExtraNodes(xmlFile, key)
	--if self.storageType==UPK_Storage.SINGLE then
		for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
			local fillLevel = getXMLFloat(xmlFile, key .. "#" .. tostring(v))
			if fillLevel~=nil then
				self.fillType=k
				self.fillLevels[k]=fillLevel
				break
			end
		end
		--end
	return true
end;

function UPK_Storage:getSaveExtraNodes(nodeIdent)
	local extraNodes=""
	--if self.storageType==UPK_Storage.SINGLE then
		local fillLevel=self.fillLevel
		if self.fillLevel==0 then
			local fillTypeStr=UniversalProcessKit.fillTypeIntToName[self.fillType]
			if fillTypeStr~=nil then
				extraNodes = extraNodes .. " " .. tostring(fillTypeStr) .. "=\"" .. tostring(math.floor(fillLevel*1000+0.5)/1000) .. "\""
			end
		end
		--end
	return extraNodes
end;
