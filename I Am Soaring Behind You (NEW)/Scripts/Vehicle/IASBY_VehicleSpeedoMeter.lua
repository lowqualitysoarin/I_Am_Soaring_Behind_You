behaviour("IASBY_VehicleSpeedoMeter")

function IASBY_VehicleSpeedoMeter:Start()
	--Base
	mainVehicleScript = self.targets.mainScript.gameObject.GetComponent(IASBY_VehicleMainFeatures)
	self.needle = self.targets.needle.transform

	self.speed = 0
	self.maxSpeed = 120

	self.minArrowAngle = 134.726
	self.maxArrowAngle = -134.726

	self.xArrowRotation = 107.347
end

function IASBY_VehicleSpeedoMeter:Update()
	--Modify the speed for the needle rotation
	if (mainVehicleScript.playerInside and mainVehicleScript.vehicle.engine.enabled) then
		self.speed = mainVehicleScript.vehicleVelocity * 3.6
	else
		self.speed = Mathf.Lerp(self.speed, 0, Time.deltaTime * 9)
	end

	--Rotate needle
	self.needle.localRotation = Quaternion.Euler(Vector3(self.xArrowRotation, 0, Mathf.Lerp(self.minArrowAngle, self.maxArrowAngle, self.speed / self.maxSpeed)))
end
