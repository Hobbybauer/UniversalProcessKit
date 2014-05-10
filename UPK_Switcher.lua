-- by mor2000

--------------------
-- Switcher


local UPK_Switcher_mt = ClassUPK(UPK_Switcher)
InitObjectClass(UPK_Switcher, "UPK_Switcher")
UniversalProcessKit.addModule("switcher",UPK_Switcher)

function UPK_Switcher:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_Switcher_mt)
	registerObjectClassName(self, "UPK_Switcher")
	return self
end

function UPK_Switcher:load(id,parent)
	if not UPK_Switcher:superClass().load(self, id, parent) then
		self:print('Error: loading Switcher failed',true)
		return false
	end
	
	self.shapePositions={}
	self.hidingPosition = getVectorFromUserAttribute(self.nodeId, "hidingPosition", "0 0 0")
	
	-- accepted fillTypes or fillTypes to store
	self.switchAtFillTypes={}
	local acceptedFillTypesString = getUserAttribute(self.nodeId, "fillTypes")
	if acceptedFillTypesString~=nil then
		for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(gmatch(acceptedFillTypesString, "%S+"))) do
			table.insert(self.switchAtFillTypes,v)
		end
	end
	
	self.fillTypeChoiceMax = Utils.getNoNil(getUserAttribute(id, "fillTypeChoice"), "max")=="max"
	
	self.switchFillTypes={}
	self.useFillTypes=false
    local fillTypeString = Utils.getNoNil(getUserAttribute(id, "switchFillTypes"))
	if fillTypeString~=nil then
		local fillTypesPerShape=Utils.splitString(",",fillTypeString)
		local numChildren = getNumOfChildren(self.nodeId)
		for i=1,mathmin(numChildren,#fillTypesPerShape) do
			local childId = getChildAt(self.nodeId, i-1)
			setVisibility(childId,false)
			self.shapePositions[childId]=__c({getTranslation(childId)})
			setTranslation(childId,unpack(self.shapePositions[childId]+self.hidingPosition))
			local fillTypesInShape=gmatch(fillTypesPerShape[i], "%S+")
			for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(fillTypesInShape)) do
				self:print("assigning "..tostring(UniversalProcessKit.fillTypeIntToName[v])..' ('..tostring(v)..") to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
				self.switchFillTypes[v]=childId
				self.useFillTypes=true
			end
		end
	end
	
	self.switchFillLevels={}
	self.maxfillLevelPerShape={}
	self.useFillLevels=false
    local fillLevelString = Utils.getNoNil(getUserAttribute(id, "switchFillLevels"))
	if fillLevelString~=nil then
		for _,v in pairs(Utils.splitString(" ",fillLevelString)) do
			local maxFillLevel=tonumber(v)
			if maxFillLevel~=nil then
				table.insert(self.maxfillLevelPerShape,maxFillLevel)
			else
				self:print('Warning: couldn\'t convert \"'..tostring(v)..'\" to number')
			end
		end
		table.insert(self.maxfillLevelPerShape,math.huge)
		local numChildren = getNumOfChildren(self.nodeId)
		for i=1,numChildren do
			local childId = getChildAt(self.nodeId, i-1)
			setVisibility(childId,false)
			self.shapePositions[childId]=__c({getTranslation(childId)})
			setTranslation(childId,unpack(self.shapePositions[childId]+self.hidingPosition))
			table.insert(self.switchFillLevels,childId)
			self:print("assigning max fillLevel of "..tostring(self.maxfillLevelPerShape[i]).." to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
			self.useFillLevels=true
		end
	end
	
	if (self.useFillTypes and self.useFillLevels) or (not self.useFillTypes and not self.useFillLevels) then
		self:print('Error: switcher requires to set either switchFillTypes or switchFillLevels')
		return false
	end
	
	local modeStr = getUserAttribute(self.nodeId, "mode")
	if modeStr=="stack" then
		self.mode=modeStr
	else
		self.mode="switch"
	end
	
	self.oldFillType=nil
	self.oldFillLevel=nil
	self.oldShapeToShow=nil

	self:print('loaded Switcher successfully')
    return true
end

function UPK_Switcher:delete()
	UPK_Switcher:superClass().delete(self)
end

function UPK_Switcher:update(dt)
	UPK_Switcher:superClass().update(self,dt)

	if self.isClient and self.isEnabled then
		if self.useFillTypes then
			local fillType=self.fillType
			local shapeToShow=nil
			if fillType~=nil and fillType~=Fillable.FILLTYPE_UNKNOWN and fillType~=self.oldFillType then
				shapeToShow=self.switchFillTypes[fillType]
			end
			if shapeToShow~=nil and shapeToShow~=self.oldShapeToShow then
				if self.oldShapeToShow~=nil then
					setVisibility(self.oldShapeToShow,false)
					setTranslation(self.oldShapeToShow,unpack((self.shapePositions[self.oldShapeToShow]+self.hidingPosition) or {}))
				end
				setVisibility(shapeToShow,true)
				local x,y,z=unpack(self.shapePositions[shapeToShow] or {})
				if x~=nil and y~=nil and z~=nil then
					setTranslation(shapeToShow,x,y,z)
				end
				self.oldShapeToShow=shapeToShow
			end
			self.oldFillType=fillType
		elseif self.useFillLevels then
			local shapeToShow=nil
			local fillLevel=nil
			local shapeToShowIndex=nil
			local fillTypes=self.switchAtFillTypes
			if self.fillTypeChoiceMax then
				fillLevel=self.fillLevel or max(self.fillLevels(fillTypes)) or 0
			else
				fillLevel= min(self.fillLevels(fillTypes))
			end
			fillLevel=min(max(fillLevel,0),self.capacity)
			if fillLevel~=self.oldFillLevel then
				for k,v in pairs(self.maxfillLevelPerShape) do
					if fillLevel<v then
						shapeToShow=self.switchFillLevels[k]
						shapeToShowIndex=k
						break
					end
				end
			end
			if shapeToShow~=nil and shapeToShow~=self.oldShapeToShow then
				local oldShapeToShowIndex=nil
				for k,v in pairs(self.switchFillLevels) do
					if v==self.oldShapeToShow then
						oldShapeToShowIndex=k
						break
					end
				end
				if self.mode=="stack" then
					if oldShapeToShowIndex~=nil then
						if oldShapeToShowIndex>shapeToShowIndex then
							for i=(shapeToShowIndex+1),oldShapeToShowIndex do
								setVisibility(self.switchFillLevels[i],false)
								setTranslation(self.switchFillLevels[i],unpack((self.shapePositions[self.switchFillLevels[i]]+self.hidingPosition) or {}))
							end
						else
							for i=(oldShapeToShowIndex+1),shapeToShowIndex do
								setVisibility(self.switchFillLevels[i],true)
								setTranslation(self.switchFillLevels[i],unpack(self.shapePositions[self.switchFillLevels[i]] or {}))
							end
						end
					end
				else
					if self.oldShapeToShow~=nil then
						setVisibility(self.oldShapeToShow,false)
						setTranslation(self.oldShapeToShow,unpack((self.shapePositions[self.oldShapeToShow]+self.hidingPosition) or {}))
					end
					setVisibility(shapeToShow,true)
					setTranslation(shapeToShow,unpack(self.shapePositions[shapeToShow] or {}))
				end
				
				self.oldShapeToShow=shapeToShow
				self.oldFillLevel=fillLevel
			end
		end
	end
end