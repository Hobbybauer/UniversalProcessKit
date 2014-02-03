-- by mor2000

UniversalProcessKit.ModuleTypes={}

function UniversalProcessKit.addModule(name,class)
	if type(name)=="string" then
		if UniversalProcessKit.ModuleTypes[name]~=nil then
			print('  [UPK] Error: Module with this name already in use')
		elseif _g[name]~=nil and _g[name]~=class then
			print('  [UPK] Error: Class for module already exists')
		else
			_g[name]=class
			UniversalProcessKit.ModuleTypes[name]=class
		end
	else
		print('  [UPK] Error: Cant add module without name')
	end
end