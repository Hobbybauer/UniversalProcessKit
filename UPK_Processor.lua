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
	self.productsPerMinute = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerMinute")),0)
	self.productsPerHour = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerHour")),0)
	self.productsPerDay = Utils.getNoNil(tonumber(getUserAttribute(id, "productsPerDay")),0)
	self.onlyWholeProducts = tobool(getUserAttribute(id, "onlyWholeProducts"))
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
		nodes=nodes .. " bufferedProducts=\""..tostring(math.floor(self.bufferedProducts*1000+0.5)/1000).."\""
	end
	return nodes
end	

-- to save: bufferedProducts

function UPK_Processor:minuteChanged()
	self:produce(self.productsPerMinute)
end

function UPK_Processor:hourChanged()
	self:produce(self.productsPerHour)
end

function UPK_Processor:dayChanged()
	self:produce(self.productsPerDay)
end

function UPK_Processor:produce(processed)
	if self.isServer then
		if self.hasRecipe then
			for k,v in pairs(self.recipe) do
				if type(v)=="number" then
					processed=math.min(processed,self:getFillLevel(k)/v or 0)
				end
			end
			local ressourcesUsed=self.recipe*processed
			for k,v in pairs(ressourcesUsed) do
				if type(v)=="number" then
					self:addFillLevel(-v,k)
				end
			end
		end
		-- deal with the produced outcome
		self.bufferedProducts=self.bufferedProducts+processed
		local finalProducts=0
		if self.onlyWholeProducts then
			local wholeProducts=math.floor(self.bufferedProducts)
			if wholeProducts>=1 then
				finalProducts=wholeProducts
				self.bufferedProducts=self.bufferedProducts-wholeProducts
			end
		else
			finalProducts=self.bufferedProducts
			self.bufferedProducts=0
		end
		self:print('wanne add '..tostring(finalProducts)..' of '..tostring(self.product))
		self:addFillLevel(finalProducts,self.product)
	end
end