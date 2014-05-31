-- by mor2000

UniversalProcessKit.VEHICLE_SOWINGMACHINE=1
UniversalProcessKit.VEHICLE_WATERTRAILER=2
UniversalProcessKit.VEHICLE_SPRAYER=4
UniversalProcessKit.VEHICLE_FUELTRAILER=8
UniversalProcessKit.VEHICLE_MILKTRAILER=16
UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER=32
UniversalProcessKit.VEHICLE_SHOVEL=64
UniversalProcessKit.VEHICLE_TIPPER=128
UniversalProcessKit.VEHICLE_FORAGEWAGON=256
UniversalProcessKit.VEHICLE_BALER=512
UniversalProcessKit.VEHICLE_MOTORIZED=1024

function UniversalProcessKit.getVehicleType(vehicle)
	local vehicleType=0
	if type(vehicle)~="table" then
		return 0
	end
	if vehicle.addSowingMachineFillTrigger ~= nil and vehicle.removeSowingMachineFillTrigger ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SOWINGMACHINE
	end
	if vehicle.addWaterTrailerFillTrigger ~= nil and vehicle.removeWaterTrailerFillTrigger ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_WATERTRAILER
	end
	if vehicle.addSprayerFillTrigger ~= nil and vehicle.removeSprayerFillTrigger ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SPRAYER
	end
	if vehicle.addFuelFillTrigger ~= nil and vehicle.removeFuelFillTrigger ~= nil and vehicle.startMotor==nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FUELTRAILER
	end
	if vehicle.allowFillType~=nil and vehicle:allowFillType(Fillable.FILLTYPE_MILK) then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MILKTRAILER
	end
	if vehicle.allowFillType~=nil and vehicle:allowFillType(Fillable.FILLTYPE_LIQUIDMANURE) then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER
	end
	if vehicle.getAllowFillShovel ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_SHOVEL
	end
	if vehicle.allowTipDischarge ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_TIPPER
	end
	if vehicle.forageWgnSoundEnabled ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_FORAGEWAGON
	end
	if vehicle.hasBaler ~= nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_BALER
	end
	if vehicle.addFuelFillTrigger ~= nil and vehicle.removeFuelFillTrigger ~= nil and vehicle.startMotor~=nil then
		vehicleType=vehicleType+UniversalProcessKit.VEHICLE_MOTORIZED
	end

	return vehicleType
end;

function UniversalProcessKit.isVehicleType(vehicle, vehicleTypeTest)
	local vehicleType=UniversalProcessKit.getVehicleType(vehicle)
	if bitAND(vehicleType,vehicleTypeTest)~=0 then
		return true
	end
	return false
end;