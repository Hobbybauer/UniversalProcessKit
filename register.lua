-- by mor2000

local debugMode=true -- DEBUG (print a lot of messages to log)

function gmatch(str, pattern)
	local arr={}
	if type(str)=="string" then
		for v in string.gmatch(str,pattern) do
			table.insert(arr,v)
		end
	end
	return arr
end

function tobool(val)
	return not (val == nil or val == false or val == 0 or val == "0" or val == "false" )
end

function getVectorFromUserAttribute(nodeId, attribute, default)
	local str=Utils.getNoNil(getUserAttribute(nodeId, attribute), default)
	if type(str)=="string" then
		return __c({Utils.getVectorFromString(str)})
	end
	return str
end

_m=_G;_G=nil;_g=_G;_G=_m;

function _m.print(string, debug)
	if debug==nil then
		debug=debugMode
	end
	if type(string)=="string" then
		local msg=string
		if debug then
			msg='DEBUG '..msg
		end
		_g.print(' [UPK] '..msg)
	end
end

source(g_currentModDirectory.."c.lua")
source(g_currentModDirectory.."UniversalProcessKit.lua")
source(g_currentModDirectory.."UniversalProcessKitSyncEvent.lua")
source(g_currentModDirectory.."UniversalProcessKitModules.lua")
source(g_currentModDirectory.."UniversalProcessKitFillTypes.lua")
source(g_currentModDirectory.."UPK_Base.lua")
source(g_currentModDirectory.."UPK_Conveyor.lua")
source(g_currentModDirectory.."UPK_DisplayTrigger.lua")
source(g_currentModDirectory.."UPK_DumpTrigger.lua")
source(g_currentModDirectory.."UPK_FillTrigger.lua")
source(g_currentModDirectory.."UPK_Mover.lua")
source(g_currentModDirectory.."UPK_Processor.lua")
source(g_currentModDirectory.."UPK_TipTrigger.lua")
source(g_currentModDirectory.."PlaceableUPK.lua")

function InitEventClass(classObject,className)
	if _g[className]~=classObject then
		print("Error: Can't assign eventId to "..tostring(className).." (object name conflict)",true)
		return
	end
	_g.InitEventClass(classObject,className)
	if classObject.eventId==nil then
		EventIds.assignEventObjectId(classObject,className,EventIds.eventIdNext)
	end
end

InitEventClass(UniversalProcessKitSyncEvent,"UniversalProcessKitSyncEvent")

g_onCreateUtil.addOnCreateFunction("UPK", UPK_Base.onCreate)

