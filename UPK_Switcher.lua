-- by mor2000

--------------------
-- Switcher

UPK_Switcher={}
local UPK_Switcher_mt = ClassUPK(UPK_Switcher,UniversalProcessKit)
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
	
	self.switchFillTypes={}
	self.useFillTypes=false
    local fillTypeString = Utils.getNoNil(getUserAttribute(id, "switchFillTypes"))
	if fillTypeString~=nil then
		local fillTypesPerShape=Utils.splitString(",",fillTypeString)
		local numChildren = getNumOfChildren(self.nodeId)
		for i=1,math.min(numChildren,#fillTypesPerShape) do
			local childId = getChildAt(self.nodeId, i-1)
			setVisibility(childId,false)
			local fillTypesInShape=gmatch(fillTypesPerShape[i], "%S+")
			for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(fillTypesInShape)) do
				self:print("assigning "..tostring(UniversalProcessKit.fillTypeIntToName[v])..' ('..tostring(v)..") to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
				table.insert(self.switchFillTypes,v,childId)
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
		for i=1,math.min(numChildren,#self.maxfillLevelPerShape) do
			local childId = getChildAt(self.nodeId, i-1)
			setVisibility(childId,false)
			table.insert(self.switchFillLevels,childId)
			self:print("assigning max fillLevel of "..tostring(self.maxfillLevelPerShape[i]).." to ".."\""..tostring(getName(childId)).."\" ("..tostring(childId)..")")
			self.useFillLevels=true
		end
	end
	
	if (self.useFillTypes and self.useFillLevels) or (not self.useFillTypes and not self.useFillLevels) then
		self:print('Error: switcher requires to set either switchFillTypes or switchFillLevels')
		return false
	end
	
	self.hidingPosition = getVectorFromUserAttribute(self.nodeId, "hidingPosition", "0 0 0")
	
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
	
	local shapeToShow=nil
	local fillType=nil
	local fillLevel=nil

	if self.useFillTypes then
		fillType=self.fillType
		if fillType~=self.oldFillType then
			shapeToShow=self.switchFillTypes[fillType]
			self:print('use shape '..tostring(shapeToShow))
		end
	elseif self.useFillLevels then
		fillLevel=self.maxFillLevel
		if fillLevel~=self.oldFillLevel then
			for k,v in pairs(self.maxfillLevelPerShape) do
				if fillLevel<v then
					shapeToShow=self.switchFillLevels[k]
					break
				end
			end
		end
	end
	
	if shapeToShow~=nil and shapeToShow~=self.oldShapeToShow then
		if self.oldShapeToShow~=nil then
			setVisibility(self.oldShapeToShow,false)
			setTranslation(self.oldShapeToShow,unpack(self.pos+self.hidingPosition))
		end
		self:print('show shape '..tostring(shapeToShow))
		setVisibility(shapeToShow,true)
		setTranslation(shapeToShow,unpack(self.pos))
		self.oldShapeToShow=shapeToShow
	end
	
	if self.useFillTypes then
		self.oldFillType=fillType
	elseif self.useFillLevels then
		self.oldFillLevel=fillLevel
	end
end