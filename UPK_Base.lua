-- by mor2000

--------------------
-- Base (root of every building, has no parent, main storage in simple buildings)


local UPK_Base_mt = ClassUPK(UPK_Base)
InitObjectClass(UPK_Base, "UPK_Base")
UniversalProcessKit.addModule("base",UPK_Base)

function UPK_Base:new(isServer, isClient, customMt)
	self:print('UPK_Base:new')
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_Base_mt)
	registerObjectClassName(self, "UPK_Base")
	self.placeable=nil
	return self
end

function UPK_Base:load(id, placeable)
	if placeable~=nil then
		self.placeable=placeable
	end
	
	if self.builtIn then
		self:print('wantToSave UPK_Base')
		g_currentMission:addOnCreateLoadedObjectToSave(self)
	end
	
	local upk=ModsUtil.modNameToMod["AAA_UniversalProcessKit"]
	if upk==nil then
		print('ERROR (YOUR FAULT): DO NOT RENAME THE UniversalProcessKit MOD FILE - NOTHING WILL WORK - it has to be "AAA_UniversalProcessKit"')
		return false
	end
	
	local UPKversion = getUserAttribute(id, "UPKversion")
	if UPKversion~=nil then
		local reqversion={}
		for _,v in pairs(gmatch(UPKversion,"[0-9]+")) do
			table.insert(reqversion,v)
		end;
		local upk_version={}
		for _,v in pairs(gmatch(upk.version,"[0-9]+")) do
			table.insert(upk_version,v)
		end;
		for k,v in pairs(upk_version) do
			if v>(reqversion[k] or 0) then
				break
			elseif v<(reqversion[k] or 0) then
				print('Error (your fault): the required upk version of this mod ('..tostring(UPKversion)..') doesnt fit your upk mod ('..tostring(upk.version)..')', true)
				return false
			end
		end
	end
	
	if not UPK_Base:superClass().load(self, id, nil) then
		self:print('Error: loading Base failed',true)
		return false
	end

	for k,_ in pairs(UniversalProcessKit.fillTypeIntToName) do
		rawset(self.fillLevels,k,0)
	end
	
	rawset(self,'maxFillLevel',0)

	self:print('loaded Base successfully')
	return true
end

function UPK_Base:delete()
	if self.builtIn then
		g_currentMission:removeOnCreateLoadedObjectToSave(self)
		if self.nodeId ~= 0 then
	        g_currentMission:removeNodeObject(self.nodeId)
	    end
	end
	UPK_Base:superClass().delete(self)
end

function UPK_Base:update(dt)
	if self.placeable==nil and not self.builtIn then
		self:delete()
	end
end
