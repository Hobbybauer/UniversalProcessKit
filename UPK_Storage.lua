-- by mor2000

--------------------
-- Storage


local UPK_Storage_mt = ClassUPK(UPK_Storage,UniversalProcessKit)
InitObjectClass(UPK_Storage, "UPK_Storage")
UniversalProcessKit.addModule("storage",UPK_Storage)

function UPK_Storage:new(isServer, isClient, customMt)
	local self = UPK_Storage:superClass().new(self, isServer, isClient, customMt or UPK_Storage_mt)
	registerObjectClassName(self, "UPK_Storage")
	return self
end

function UPK_Storage:load(id)
	if not UPK_Storage:superClass().load(self, id, nil) then
		print('Error: loading Storage failed',true)
		return false
	end
	for k,_ in pairs(UniversalProcessKit.fillTypeIntToName) do
		rawset(self.fillLevels,k,0)
	end
	table.insert(UniversalProcessKit.modulesToSync,self)
	print('loaded Base successfully')
	return true
end

function UPK_Storage:delete()
	UPK_Storage:superClass().delete(self)
end