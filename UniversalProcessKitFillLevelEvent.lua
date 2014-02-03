-- by mor2000

UniversalProcessKitFillLevelEvent = {}
UniversalProcessKitFillLevelEvent_mt = Class(UniversalProcessKitFillLevelEvent, Event)

InitEventClass(UniversalProcessKitFillLevelEvent, "UniversalProcessKitFillLevelEvent")

function UniversalProcessKitFillLevelEvent:emptyNew()
	local self = Event:new(UniversalProcessKitFillLevelEvent_mt)
	return self
end

function UniversalProcessKitFillLevelEvent:new(objectId, fillLevel, fillType)
	local self = UniversalProcessKitFillLevelEvent:emptyNew()
	self.fillLevel = fillLevel
	self.fillType = fillType
	self.objectId = objectId
	return self
end

function UniversalProcessKitFillLevelEvent:readStream(streamId, connection)
	self.objectId = streamReadInt32(streamId)
	self.fillLevel = streamReadInt32(streamId)
	self.fillType = streamReadInt8(streamId)
	self:run(connection)
end

function UniversalProcessKitFillLevelEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.objectId)
	streamWriteInt32(streamId, self.fillLevel)
	streamWriteInt8(streamId, self.fillType)
end

function UniversalProcessKitFillLevelEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, nil)
	end
	
	if self.objectId~=nil then
		local object = networkGetObject(self.objectId)
		if object~=nil then
			object.fillLevels[self.fillType]=self.fillLevel
		end
	end
end

function UniversalProcessKitFillLevelEvent.sendEvent(objectId, fillLevel, fillType)
	local event=UniversalProcessKitFillLevelEvent:new(objectId, fillLevel, fillType)
	if g_server ~= nil then
		g_server:broadcastEvent(event, nil, nil, nil)
	else
		g_client:getServerConnection():sendEvent(event)
	end
end
