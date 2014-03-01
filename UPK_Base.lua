-- by mor2000

--------------------
-- Base (root of every building, has no parent, main storage in simple buildings)


local UPK_Base_mt = ClassUPK(UPK_Base,UniversalProcessKit)
InitObjectClass(UPK_Base, "UPK_Base")
UniversalProcessKit.addModule("base",UPK_Base)

function UPK_Base.onCreate(id)
	local object = UPK_Base:new(g_server ~= nil, g_client ~= nil)
	if object:load(id) then
		g_currentMission:addOnCreateLoadedObject(object)
	else
		object:delete()
	end
end

function UPK_Base:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_Base_mt)
	registerObjectClassName(self, "UPK_Base")
	self.placeable=nil
	return self
end

function UPK_Base:load(id, placeable)
	self:print('placeable '..tostring(placeable))
	if placeable~=nil then
		self.placeable=placeable
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
	UPK_Base:superClass().delete(self)
end

function UPK_Base:executeAction(sender, action, value)
	UPK_Base:superClass().executeAction(sender, action, value)
	-- extend functionality down here (in your own modules)
end

g_onCreateUtil.addOnCreateFunction("UPK", UPK_Base.onCreate)
