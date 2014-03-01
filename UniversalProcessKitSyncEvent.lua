-- by mor2000

_g.UniversalProcessKitSyncEvent = {}
UniversalProcessKitSyncEvent_mt = Class(UniversalProcessKitSyncEvent, Event)

function UniversalProcessKitSyncEvent:emptyNew()
	local self = Event:new(UniversalProcessKitSyncEvent_mt)
	return self
end

function UniversalProcessKitSyncEvent:new(objectId)
	local self = UniversalProcessKitSyncEvent:emptyNew()
	self.objectId = objectId
	return self
end

function UniversalProcessKitSyncEvent:readStream(streamId, connection)
	self.objectId = streamReadInt32(streamId)
	self:run(connection)
end

function UniversalProcessKitSyncEvent:run(connection)
	if not connection:getIsServer() then -- should be
		if self.objectId~=nil then
			local object = networkGetObject(self.objectId)
			if object~=nil then
				g_server:finishRegisterObject(connection, object)
				object:raiseDirtyFlags(object.syncDirtyFlag)
			else
				print("Warning: no network object found to synchronize",true)
			end
		end
	end
end

function UniversalProcessKitSyncEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.objectId)
end

UniversalProcessKit.InitEventClass(UniversalProcessKitSyncEvent,"UniversalProcessKitSyncEvent")