-- by mor2000

--------------------
-- Animator

local UPK_Animator_mt = ClassUPK(UPK_Animator,UniversalProcessKit)
InitObjectClass(UPK_Animator, "UPK_Animator")
UniversalProcessKit.addModule("animator",UPK_Animator)

function UPK_Animator:new(isServer, isClient, customMt)
	local self = UniversalProcessKit:new(isServer, isClient, customMt or UPK_Animator_mt)
	registerObjectClassName(self, "UPK_Animator")
	self.animTimeDirtyFlag=self:getNextDirtyFlag()
	self.animTrackEnabledDirtyFlag=self:getNextDirtyFlag()
	return self
end

function UPK_Animator:load(id, parent)
	if not UPK_Animator:superClass().load(self, id, parent) then
		self:print('Error: loading Animator failed',true)
		return false
	end
	
	self.animTime=0
	self.animTrackLoopState = Utils.getNoNil(tobool(getUserAttribute(id, "animTrackLoopState")),false)
	self.animSpeedScale = Utils.getNoNil(tonumber(getUserAttribute(id, "animSpeedScale")),1)
	self.rewindOnDisable = Utils.getNoNil(tobool(getUserAttribute(id, "rewindOnDisable")),false)
	self.animationClip = getUserAttribute(id, "animationClip")
	
	if self.animationClip~=nil then
		local function loopFunc(childId)
			self.animCharacterSet = getAnimCharacterSet(childId)
			if self.animCharacterSet ~= 0 then
				self.animClipIndex = getAnimClipIndex(self.animCharacterSet,self.animationClip)
				if self.animClipIndex >= 0 then
					self:print('everything fine')
					return false
				end
			end
			return true
		end
		if not loopThruChildren(id,loopFunc,self) then
			self:print('Error: loading Animator failed while loading animation characteristics')
			return false
		end
	end
	
	assignAnimTrackClip(self.animCharacterSet,0,self.animClipIndex)
	setAnimTrackLoopState(self.animCharacterSet,0,self.animTrackLoopState)
	self.animDuration = getAnimClipDuration(self.animCharacterSet,self.animClipIndex)

	self:print('loaded Animator successfully')
	return true
end

function UPK_Animator:readStream(streamId, connection)
	UPK_Animator:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		local animTime=streamReadFloat32(streamId) or 0
		self:setAnimTime(animTime,true)
		local animTrackEnabled=streamReadBool(streamId)
		if animTrackEnabled==true then
			self:enableAnimTrack(true)
		elseif animTrackEnabled==false then
			self:disableAnimTrack(true)
		end
	end
end;

function UPK_Animator:writeStream(streamId, connection)
	UPK_Animator:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteFloat32(streamId,self:getAnimTime())
		streamWriteBool(streamId,self.animTrackEnabled)
	end
end;

function UPK_Animator:readUpdateStream(streamId, timestamp, connection)
	UPK_Animator:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if not connection:getIsServer() then
		if bitAND(dirtyMask,self.animTimeDirtyFlag)~=0 then
			local animTime=streamReadFloat32(streamId) or 0
			self:setAnimTime(animTime,true)
		end
		if bitAND(dirtyMask,self.animTrackEnabledDirtyFlag)~=0 then
			local animTrackEnabled=streamReadBool(streamId)
			if animTrackEnabled==true then
				self:enableAnimTrack(true)
			elseif animTrackEnabled==false then
				self:disableAnimTrack(true)
			end
		end
	end
end;

function UPK_Animator:writeUpdateStream(streamId, connection, dirtyMask)
	UPK_Animator:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if connection:getIsServer() then
		if bitAND(dirtyMask,self.animTimeDirtyFlag)~=0 or syncall then
			streamWriteFloat32(streamId,self:getAnimTime())
		end
		if bitAND(dirtyMask,self.animTrackEnabledDirtyFlag)~=0 or syncall then
			streamWriteBool(streamId,self.animTrackEnabled)
		end	
	end
end;

function UPK_Animator:delete()
	UPK_Animator:superClass().delete(self)
end

function UPK_Animator:update(dt)
	if self.isServer then
		if self.isEnabled then
			self:enableAnimTrack()
		else
			self:disableAnimTrack()
		end
	end
end

function UPK_Animator:setEnable(isEnabled,alreadySent)
	UPK_Animator:superClass().setEnable(self,isEnabled,alreadySent)
	if self.isEnabled then
		self:enableAnimTrack(alreadySent)
	else
		self:disableAnimTrack(alreadySent)
	end
end;

function UPK_Animator:loadExtraNodes(xmlFile, key)
	local animTime=tonumber(getXMLString(xmlFile, key .. "#animTime"))
	self:setAnimTime(animTime,true)
	local animTrackEnabled=tobool(getXMLString(xmlFile, key .. "#animTrackEnabled"))
	if animTrackEnabled==true then
		self:enableAnimTrack(true)
	elseif animTrackEnabled==false then
		self:disableAnimTrack(true)
	end
	return true
end;

function UPK_Animator:getSaveExtraNodes(nodeIdent)
	local nodes=""
	nodes=nodes.." animTrackEnabled=\""..tostring(self.animTrackEnabled).."\" animTime=\""..tostring(self.animTime).."\""
	return nodes
end;

function UPK_Animator:setAnimTime(animTime,alreadySent)
	setAnimTrackTime(self.animCharacterSet, self.animationClip, animTime, true)
	self.animTime=animTime
	if not alreadySent then
		self:raiseDirtyFlags(self.animTimeDirtyFlag)
	end
end;

function UPK_Animator:getAnimTime()
	return getAnimTrackTime(self.animCharacterSet, self.animationClip)
end;

function UPK_Animator:enableAnimTrack(alreadySent)
	if self.animTrackEnabled==false then
		self.animTrackEnabled=true
		if self.rewindOnDisable then
			setAnimTrackSpeedScale(self.animCharacterSet, self.animationClip, self.animSpeedScale)
			enableAnimTrack(self.animCharacterSet, self.animationClip)
		else
			enableAnimTrack(self.animCharacterSet, self.animationClip)
		end
		if not alreadySent then
			self:raiseDirtyFlags(self.animTrackEnabledDirtyFlag)
		end
	end
end;

function UPK_Animator:disableAnimTrack(alreadySent)
	if self.animTrackEnabled==true then
		self.animTrackEnabled=false
		if self.rewindOnDisable then
			setAnimTrackSpeedScale(self.animCharacterSet, self.animationClip, self.animSpeedScale*(-1))
			enableAnimTrack(self.animCharacterSet, self.animationClip)
		else
			disableAnimTrack(self.animCharacterSet, self.animationClip)
		end
		if not alreadySent then
			self:raiseDirtyFlags(self.animTrackEnabledDirtyFlag)
		end
	end
end;

