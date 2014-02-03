-- by mor2000

--------------------
-- Mover (changes translation, rotation and visibility of objects)

UPK_Mover={}
local UPK_Mover_mt = Class(UPK_Mover, UniversalProcessKit)
InitObjectClass(UPK_Mover, "UPK_Mover")
UniversalProcessKit.addModule("mover",UPK_Mover)

function UPK_Mover:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_Mover_mt)
	
	self.fillTypes=__c()
	self.fillTypeChoiceMax=true
	
	self.startMovingAt=0
	self.stopMovingAt=self.capacity
	
	self.posMin = __c({0,0,0})
	self.posMax = __c({0,0,0})
	self.posLower = __c({0,0,0})
	self.posHigher = __c({0,0,0})
	
	self.startRotatingAt=0
	self.stopRotatingAt=0
	
	self.rpsMin = __c({0,0,0})
	self.rpsMax = __c({0,0,0})
	self.rpsLower = __c({0,0,0})
	self.rpsHigher = __c({0,0,0})
	
	self.startVisibilityAt=0
	self.stopVisibilityAt=0
	self.visibilityType=true
	
	registerObjectClassName(self, "UPK_Mover")
	return self
end

function UPK_Mover:load(id,parent)
	if not UPK_Mover:superClass().load(self, id, parent) then
		print('  [UniversalProcessKit] Error: loading Mover failed')
		return false
	end
	
    local fillTypeString = Utils.getNoNil(getUserAttribute(id, "fillTypes"), "unknown")
	self.fillTypes = UniversalProcessKit.fillTypeNameToInt(gmatch(fillTypeString,"%S+"))
	self.fillTypeChoiceMax = Utils.getNoNil(getUserAttribute(id, "fillTypeChoice"), "max")=="max"
	
	-- move
	self.startMovingAt=Utils.getNoNil(tonumber(getUserAttribute(id, "startMovingAt")), 0)
	self.stopMovingAt=Utils.getNoNil(tonumber(getUserAttribute(id, "stopMovingAt")), self.capacity or 0)
	local posMin = getVectorFromUserAttribute(self.nodeId, "lowPosition", "0 0 0")
	self.posMin = self.pos + posMin
	local posMax = getVectorFromUserAttribute(self.nodeId, "highPosition", self.posMin)
	self.posMax = self.pos + posMax
	local posLower = getVectorFromUserAttribute(self.nodeId, "lowerPosition", self.posMin)
	local posHigher = getVectorFromUserAttribute(self.nodeId, "higherPosition", self.posMax)
	self.posLower = self.pos + posLower
	self.posHigher = self.pos + posHigher
	self.moveType = Utils.getNoNil(getUserAttribute(id, "moveType"), "linear")
	
	-- rotation
	self.startRotatingAt=Utils.getNoNil(tonumber(getUserAttribute(id, "startRotatingAt")), 0)
	self.stopRotatingAt=Utils.getNoNil(tonumber(getUserAttribute(id, "stopRotatingAt")), self.capacity or 0)
	local rpsMin = getVectorFromUserAttribute(self.nodeId, "lowRotationsPerSecond", "0 0 0")
	self.rpsMin = rpsMin*(2*math.pi)
	local rpsMax = getVectorFromUserAttribute(self.nodeId, "highRotationsPerSecond", self.rpsMin)
	self.rpsMax = rpsMax*(2*math.pi)
	local rpsLower = getVectorFromUserAttribute(self.nodeId, "lowerRotationsPerSecond", self.rpsMin)
	local rpsHigher = getVectorFromUserAttribute(self.nodeId, "higherRotationsPerSecond", self.rpsMax)
	self.rpsLower = rpsLower*(2*math.pi)
	self.rpsHigher = rpsHigher*(2*math.pi)
	self.rotationType = Utils.getNoNil(getUserAttribute(id, "rotationType"), "linear")
	
	-- visibility
	self.startVisibilityAt=Utils.getNoNil(tonumber(getUserAttribute(id, "startVisibilityAt")), 0)
	self.stopVisibilityAt=Utils.getNoNil(tonumber(getUserAttribute(id, "stopVisibilityAt")), self.capacity)
	self.visibilityType=Utils.getNoNil(getUserAttribute(id, "visibilityType"), "show")=="show"
	
    return true
end

function UPK_Mover:delete()
	UPK_Mover:superClass().delete(self)
end

function UPK_Mover:update(dt)
	--UPK_Mover:superClass().update(self,dt)
	
	if self.nodeId~=0 then
		local newFillLevel
		if self.fillTypeChoiceMax then
			newFillLevel= self.fillLevels(self.fillTypes):max() or 0
		else
			newFillLevel= self.fillLevels(self.fillTypes):min() or 0
		end
		newFillLevel=math.min(math.max(newFillLevel,0),self.capacity or 0)

		-- move only if sth changed
		if newFillLevel~=self.oldFillLevel then
			if newFillLevel<(self.startMovingAt or 0) then
				self.pos=self.posLower
			elseif newFillLevel>(self.stopMovingAt or 0) then
				self.pos=self.posHigher
			else
				local ratio=self:getRatio("pos",self.moveType,newFillLevel,self.startMovingAt,self.stopMovingAt)
				self.pos=self.posMin+(self.posMax-self.posMin)*ratio
			end
			setTranslation(self.nodeId,unpack(self.pos))
		
			-- rotation
			if newFillLevel<self.startRotatingAt then
				self.rotStep=self.rpsLower
			elseif newFillLevel>self.stopRotatingAt then
				self.rotStep=self.rpsHigher
			else
				local rotRatio=self:getRatio("rot",self.rotationType,newFillLevel,self.startRotatingAt,self.stopRotatingAt)
				self.rotStep=self.rpsMin+(self.rpsMax-self.rpsMin)*rotRatio
			end
		
			-- visibility
			setVisibility(self.nodeId,self.visibilityType==(newFillLevel>=self.startVisibilityAt and newFillLevel<=self.stopVisibilityAt))
		end

		-- rotate all the time
		rotate(self.nodeId, unpack(self.rotStep*(dt*0.001)))

		self.oldFillLevel=newFillLevel
	end
end

function UPK_Mover:getRatio(use,type,fillLevel,minFillLevel,maxFillLevel)
	if minFillLevel==nil or maxFillLevel==nil or minFillLevel<0 or maxFillLevel<0 then
		return 0
	end
	local dividend
	if self.ratioMaxFillLevel==nil then
		self.ratioMaxFillLevel={}
	end
	if self.ratioMaxFillLevel[use]== nil then
		self.ratioMaxFillLevel[use]={}
		self.ratioMaxFillLevel[use].sphere=((maxFillLevel-minFillLevel)/(4/3*math.pi))^(1/3)
		self.ratioMaxFillLevel[use].cone=((maxFillLevel-minFillLevel)/(1/3*math.pi))^(1/3)
		self.ratioMaxFillLevel[use].square=(maxFillLevel-minFillLevel)^(1/2)
		self.ratioMaxFillLevel[use].circle=((maxFillLevel-minFillLevel)/math.pi)^(1/2)
		self.ratioMaxFillLevel[use].sinus=1
		self.ratioMaxFillLevel[use].linear=maxFillLevel-minFillLevel
	end
	if type=="sphere" then
		dividend=((fillLevel-minFillLevel)/(4/3*math.pi))^(1/3)
	elseif type=="cone" then
		dividend=((fillLevel-minFillLevel)/(1/3*math.pi))^(1/3)
	elseif type=="square" then
		dividend=(fillLevel-minFillLevel)^(1/2)
	elseif type=="circle" then
		dividend=((fillLevel-minFillLevel)/math.pi)^(1/2)
	elseif type=="sinus" then
		dividend=math.sin((fillLevel-minFillLevel)/(maxFillLevel-minFillLevel)*math.pi)
	else
		type="linear"
		dividend=fillLevel-minFillLevel
	end
	return dividend/self.ratioMaxFillLevel[use][type]
end

