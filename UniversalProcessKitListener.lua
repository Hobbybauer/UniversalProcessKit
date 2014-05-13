-- by mor2000

UniversalProcessKitListener = {}

function UniversalProcessKitListener:loadMap(name)
	--cleanup at map loaded
	for k,v in pairs(Fillable.fillTypeNameToInt) do
		UniversalProcessKit.fillTypeNameToInt[k]=v
		UniversalProcessKit.fillTypeIntToName[v]=k
	end
	for k,v in pairs(UniversalProcessKit.fillTypeNameToInt) do
		local fillabletype=Fillable.fillTypeNameToInt[k]
		if fillabletype~=nil then
			UniversalProcessKit.fillTypeNameToInt[k]=nil
			--UniversalProcessKit.fillTypeIntToName[v]=nil
		end
	end
	
	--[[ maybe later
	if _g.MapDoorTrigger~=nil then
		_m.MapDoorTrigger=_g.MapDoorTrigger.MapDoorTrigger
		_m.DoorTrigger=_g.MapDoorTrigger.DoorTrigger
	end
	--]]
end

local function emptyFunc() end
UniversalProcessKitListener.deleteMap=emptyFunc
UniversalProcessKitListener.mouseEvent=emptyFunc
UniversalProcessKitListener.keyEvent=emptyFunc
UniversalProcessKitListener.update=emptyFunc
UniversalProcessKitListener.draw=emptyFunc

addModEventListener(UniversalProcessKitListener)