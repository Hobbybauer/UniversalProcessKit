-- by mor2000

UniversalProcessKitFillEvent = {}
UniversalProcessKitFillEvent_mt = Class(UniversalProcessKitFillEvent, Event)

InitEventClass(UniversalProcessKitFillEvent, "UniversalProcessKitFillEvent")

function UniversalProcessKitFillEvent:emptyNew()
	local self = Event:new(UniversalProcessKitFillEvent_mt)
	return self
end

function UniversalProcessKitFillEvent:new(object, fill, fillDone)
	print("UniversalProcessKitFillEvent:new")
	local self = UniversalProcessKitFillEvent:emptyNew()
	self.fill = fill
	self.fillDone = fillDone
	self.object = object
	print("self.object = "..tostring(self.object))
	return self
end

function UniversalProcessKitFillEvent:readStream(streamId, connection)
	print("UniversalProcessKitFillEvent:readStream")
	local id = streamReadInt32(streamId)
	self.fill = streamReadBool(streamId)
	self.fillDone = streamReadBool(streamId)

	self.object = networkGetObject(id)
	print("id = "..tostring(id))
	print("self.object = "..tostring(self.object))
	print("self.fill = "..tostring(self.fill))
	print("self.fillDone = "..tostring(UniversalProcessKit.fillDoneIntToName[self.fillDone]))
	self:run(connection)
end

function UniversalProcessKitFillEvent:writeStream(streamId, connection)
	print("UniversalProcessKitFillEvent:writeStream")
	local id=networkGetObjectId(self.object)
	print("self.object = "..tostring(self.object))
	print("id = "..tostring(id))
	print("self.fill = "..tostring(self.fill))
	print("self.fillDone = "..tostring(UniversalProcessKit.fillDoneIntToName[self.fillDone]))
	streamWriteInt32(streamId, id)
	streamWriteBool(streamId, self.fill)
	streamWriteBool(streamId, self.fillDone)
end

function UniversalProcessKitFillEvent:run(connection)
	print("UniversalProcessKitFillEvent:run")
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	
	if self.object~=nil then
		self.object.fill=self.fill
		self.object.fillDone=self.fillDone
	end
end

function UniversalProcessKitFillEvent.sendEvent(object, fill, fillDone)
	print("calling UniversalProcessKitFillEvent.sendEvent")
	local event=UniversalProcessKitFillEvent:new(object, fill, fillDone)
	print("event = "..tostring(event))
	if g_server ~= nil then
		g_server:broadcastEvent(event, nil, nil, object)
	else
		g_client:getServerConnection():sendEvent(event)
	end
end
