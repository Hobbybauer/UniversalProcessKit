-- by mor2000

--------------------
-- Processor (converts and stores stuff)

-- storage stystems
-- separate - standard
-- single - allow only 1 fillType
-- fifo - layered, first in first out
-- lifo - layered, last in last out

-- convertion rule: what recipe, what recipe
-- ie: brewery
-- convertion: beer 0.05 barley 1.1 water
-- read it like: 1 beer = 0.05 x barley + 1.1 x water
-- processing: water 0, barley 0, beer 5
-- read it like: pass water to parent with 0 liter per second (=store), barley too and beer with 5 liters per second


local UPK_Processor_mt = ClassUPK(UPK_Processor,UniversalProcessKit)
InitObjectClass(UPK_Processor, "UPK_Processor")
UniversalProcessKit.addModule("processor",UPK_Processor)

function UPK_Processor:new(isServer, isClient, customMt)
	if customMt == nil then
		customMt = UPK_Processor_mt
	end
	local self = UniversalProcessKit:new(isServer, isClient, customMt)
	registerObjectClassName(self, "UPK_Processor")
	return self
end

function UPK_Processor:load(id, parent)
	if not UPK_Processor:superClass().load(self, id, parent) then
		self:print('Error: loading Processor failed',true)
		return false
	end

	self.product = unpack(UniversalProcessKit.fillTypeNameToInt(getUserAttribute(id, "product")))
	
	if self.product ~= nil and self.fillLevels[self.product]==nil then
		self:setFillLevel(0,self.product)
	end
	self.productsPerSecond = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerSecond")),0)
	self.productsPerMinute = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerMinute")),0)
	self.productsPerHour = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerHour")),0)
	self.productionHours={}
	if self.productsPerSecond>0 or self.productsPerMinute>0 or self.productsPerHour>0 then
		local productionHoursStrings = Utils.getNoNil(getUserAttribute(id, "productionHours"),"0-23")
		local productionHoursStringArr=Utils.splitString(",",productionHoursStrings)
		for _,v in pairs(productionHoursStringArr) do
			self:print(v)
			local productionHoursArr = Utils.splitString("-",v)
			local lowerHour = mathmin(mathmax(tonumber(productionHoursArr[1]),0),23)
			local upperHour = mathmin(mathmax(tonumber(productionHoursArr[2]),lowerHour),23)
			if lowerHour~=nil and upperHour~=nil then
				for i=lowerHour,upperHour do
					self:print('produce sth at hour '..tostring(i))
					self.productionHours[i]=true
				end
			end
		end
	end
	self.productsPerDay = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerDay")),0)
	
	local productionProbability=tonumber(getUserAttribute(id, "productionProbability"))
	if productionProbability~=nil then
		if productionProbability <= 0 then
			self:print('Error: productionProbability cannot be lower than or equal to 0',true)
			return false
		elseif productionProbability>1 and productionProbability<=100 then
			self:print('Warning: productionProbability is not between 0 and 1')
			productionProbability=productionProbability/100
		elseif productionProbability>100 then
			self:print('Warning: productionProbability is not between 0 and 1')
			productionProbability=1
		end
	else
		productionProbability=1
	end
	self.productionProbability = productionProbability
	
	local outcomeVariation=tonumber(getUserAttribute(id, "outcomeVariation"))
	if outcomeVariation~=nil then
		if outcomeVariation < 0 then
			self:print('Error: outcomeVariation cannot be lower than 0',true)
			return false
		elseif outcomeVariation>1 and outcomeVariation<=100 then
			self:print('Warning: outcomeVariation is not between 0 and 1')
			outcomeVariation=outcomeVariation/100
		elseif outcomeVariation>100 then
			self:print('Warning: outcomeVariation is not between 0 and 1')
			outcomeVariation=0
		end
	else
		outcomeVariation=0
	end
	self.outcomeVariation = outcomeVariation
	
	if self.outcomeVariation>0 then
		self.outcomeVariationType = Utils.getNoNil(getUserAttribute(id, "outcomeVariationType"),"equal")
		if self.outcomeVariationType=="normal" and (self.productsPerSecond>0 or self.productsPerMinute>0) then
			self:print('Warning: Its not recommended to use normal distributed outcome variation for productsPerSecond and productsPerMinute')
		end
	end
	
	self.useRessources = tobool(Utils.getNoNil(getUserAttribute(id, "useRessources"),"true")) == true
	self.bufferedProducts = 0
	
	self.hasRecipe=false
	self.recipe=__c()
	local recipeArr=gmatch(Utils.getNoNil(getUserAttribute(id, "recipe"),""),"%S+")
	for i=1,#recipeArr,2 do
		local amount=tonumber(recipeArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(recipeArr[i+1]))
		if amount~=nil and type~=nil then
			self.recipe[type]=amount
			self.hasRecipe=true
		end
	end
	
	self.hasByproducts=false
	self.byproducts=__c()
	local byproductsArr=gmatch(Utils.getNoNil(getUserAttribute(id, "byproducts"),""),"%S+")
	for i=1,#byproductsArr,2 do
		local amount=tonumber(byproductsArr[i])
		local type=unpack(UniversalProcessKit.fillTypeNameToInt(byproductsArr[i+1]))
		if amount~=nil and type~=nil then
			self.byproducts[type]=amount
			self.hasByproducts=true
		end
	end
	
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
		self.statName="other"
	end
	
	--[[
	FinanceStats.statNames = {
		"newVehiclesCost",
		"newAnimalsCost",
		"constructionCost",
		"vehicleRunningCost",
		"propertyMaintenance",
		"wagePayment",
		"harvestIncome",
		"missionIncome",
		"other",
		"loanInterest"
	}
	--]]

	if not moveMode then -- moveMode here?
		if self.isServer then
			if self.product~=nil and self.productsPerMinute>0 then
				g_currentMission.environment:addMinuteChangeListener(self)
			elseif self.product~=nil and self.productsPerHour>0 then
				g_currentMission.environment:addHourChangeListener(self)
			elseif self.product~=nil and self.productsPerDay>0 then
				g_currentMission.environment:addDayChangeListener(self)
			end
		end
	end
	
	self.dtsum=0
	
	self:print('loaded Processor successfully')
	return true
end

function UPK_Processor:delete()
	if self.product~=nil and self.productsPerMinute>0 then
		g_currentMission.environment:removeMinuteChangeListener(self)
	elseif self.product~=nil and self.productsPerHour>0 then
		g_currentMission.environment:removeHourChangeListener(self)
	elseif self.product~=nil and self.productsPerDay>0 then
		g_currentMission.environment:removeDayChangeListener(self)
	end
	UPK_Processor:superClass().delete(self)
end

function UPK_Processor:loadExtraNodes(xmlFile, key)
	self.bufferedProducts = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#bufferedProducts"),0)
	return true
end

function UPK_Processor:getSaveExtraNodes(nodeIdent)
	local nodes=""
	if self.bufferedProducts>0 then
		nodes=nodes .. " bufferedProducts=\""..tostring(mathfloor(self.bufferedProducts*1000+0.5)/1000).."\""
	end
	return nodes
end	

function UPK_Processor:update(dt)
	if self.productsPerSecond>0 then
		if self.productionHours[g_currentMission.environment.currentHour] then
			self.dtsum=self.dtsum+dt
			if self.dtsum>=1000 then
				self:produce(self.productsPerSecond*(self.dtsum/1000))
				self.dtsum=0
			end
		end
	end
end;

function UPK_Processor:minuteChanged()
	if self.productionHours[g_currentMission.environment.currentHour] then
		self:produce(self.productsPerMinute)
	end
end

function UPK_Processor:hourChanged()
	if self.productionHours[g_currentMission.environment.currentHour] then
		self:produce(self.productsPerHour)
	end
end

function UPK_Processor:dayChanged()
	self:produce(self.productsPerDay)
end

function UPK_Processor:produce(processed)
	if self.isServer and self.isEnabled then
		local produce=self.productionProbability==1
		if not produce then
			produce = mathrandom()<=self.productionProbability
		end
		if produce then
			if self.outcomeVariation~=0 then
				if self.outcomeVariationType=="normal" then -- normal distribution
					local r=mathmin(mathmax(getNormalDistributedRandomNumber(),-2),2)/2
					processed=processed+processed*self.outcomeVariation*r
				elseif self.outcomeVariationType=="equal" then -- equal distribution
					local r=2*mathrandom()-1
					processed=processed+processed*self.outcomeVariation*r
				end
			end
			if self.product~=UniversalProcessKit.FILLTYPE_MONEY then
				processed=mathmin(processed,self.capacity-self:getFillLevel(self.product))
			end
			if processed>0 then
				if self.hasRecipe then
					for k,v in pairs(self.recipe) do
						if type(v)=="number" and v>0 then
							processed=mathmin(processed,self:getFillLevel(k)/v or 0)
						end
					end
					if self.useRessources then
						local ressourcesUsed=self.recipe*processed
						for k,v in pairs(ressourcesUsed) do
							if type(v)=="number" then
								self:addFillLevel(-v,k)
							end
						end
					end
				end
				-- deal with the produced outcome
				self.bufferedProducts=self.bufferedProducts+processed
				local finalProducts=0
				if self.onlyWholeProducts then
					local wholeProducts=mathfloor(self.bufferedProducts)
					if wholeProducts>=1 then
						finalProducts=wholeProducts
						self.bufferedProducts=self.bufferedProducts-wholeProducts
					end
				else
					finalProducts=self.bufferedProducts
					self.bufferedProducts=0
				end
				self:addFillLevel(finalProducts,self.product)
				if self.hasByproducts then
					for k,v in pairs(self.byproducts) do
						if type(v)=="number" and v>0 then
							self:addFillLevel(v*finalProducts,k)
						end
					end
				end
			end
		end
	end
end