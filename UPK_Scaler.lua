-- by mor2000

--------------------
-- Scaler (changes scaling)

local UPK_Scaler_mt = ClassUPK(UPK_Scaler)
InitObjectClass(UPK_Scaler, "UPK_Scaler")
UniversalProcessKit.addModule("scaler",UPK_Scaler)

function UPK_Scaler:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_Scaler_mt)
	self.getRatio=UPK_Mover.getRatio

	self.fillTypes=__c()
	self.fillTypeChoiceMax=true
	
	registerObjectClassName(self, "UPK_Scaler")
	return self
end

function UPK_Scaler:load(id,parent)
	if not UPK_Scaler:superClass().load(self, id, parent) then
		self:print('Error: loading Scaler failed',true)
		return false
	end
	
    local fillTypeString = Utils.getNoNil(getUserAttribute(id, "fillTypes"))
	if fillTypeString==nil then
		self.fillTypes=self.acceptedFillTypes
	else
		self.fillTypes = UniversalProcessKit.fillTypeNameToInt(Utils.splitString(" ",fillTypeString))
	end
	self.fillTypeChoiceMax = Utils.getNoNil(getUserAttribute(id, "fillTypeChoice"), "max")=="max"
	
	-- scale
	self.startScalingAt=Utils.getNoNil(tonumber(getUserAttribute(id, "startScalingAt")), 0)
	self.stopScalingAt=Utils.getNoNil(tonumber(getUserAttribute(id, "stopScalingAt")), self.capacity)
	local scaleMin = getVectorFromUserAttribute(self.nodeId, "lowScale", "1 1 1")
	self.scaleMin = scaleMin
	local scaleMax = getVectorFromUserAttribute(self.nodeId, "highScale", scaleMin)
	self.scaleMax = scaleMax
	local scaleLower = getVectorFromUserAttribute(self.nodeId, "lowerScale", scaleMin)
	local scaleHigher = getVectorFromUserAttribute(self.nodeId, "higherScale", scaleMax)
	self.scaleLower = scaleLower
	self.scaleHigher = scaleHigher
	self.scaleType = Utils.getNoNil(getUserAttribute(id, "scaleType"), "linear")

	self:print('loaded Scaler successfully')
    return true
end

function UPK_Scaler:delete()
	UPK_Scaler:superClass().delete(self)
end

function UPK_Scaler:update(dt)
	UPK_Scaler:superClass().update(self,dt)
	
	if self.isClient and self.nodeId~=0 then
		local newFillLevel=nil
		local fillTypes=self:getAcceptedFillTypes()
		if #fillTypes>0 then
			if self.fillTypeChoiceMax then
				newFillLevel= self.maxFillLevel
			else
				newFillLevel= min(self.fillLevels(fillTypes))
			end
			newFillLevel=min(max(newFillLevel,0),self.capacity)
			-- move only if sth changed
			if newFillLevel~=nil and newFillLevel~=self.oldFillLevel then
				if newFillLevel<=(self.startScalingAt) then -- startMovingAt included in posLower
					self.scale=self.scaleLower
				elseif newFillLevel>(self.stopScalingAt) then
					self.scale=self.scaleHigher
				else
					local ratio=self:getRatio("scale",self.scaleType,newFillLevel,self.startScalingAt,self.stopScalingAt)
					self.scale=self.scaleMin+(self.scaleMax-self.scaleMin)*ratio
				end
				
				local sx,sy,sz=unpack(self.scale)
				print('set scale to '..tostring(sx).." "..tostring(sy).." "..tostring(sz))
				setScale(self.nodeId,sx,sy,sz)
				setTranslation(self.nodeId,unpack(self.pos))
			end
		end

		self.oldFillLevel=newFillLevel
	end
end


