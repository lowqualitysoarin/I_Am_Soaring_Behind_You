behaviour("IASBY_VehicleTachoMeter")

function IASBY_VehicleTachoMeter:Start()
	--Base
	mainVehicleScript = self.targets.mainScript.gameObject.GetComponent(IASBY_VehicleMainFeatures)
	self.needle = self.targets.needle.transform

	--Steps BMW E30
	self.steps = {
		5,
		10,
		15,
		20,
		25,
		30,
		35,
	}

	--Tachometer settings
	self.speed = 0

	self.stepInt = 1
	self.lastStepInt = 1
	self.currentStep = self.steps[1]

	self.minArrowAngle = 109.967
	self.maxArrowAngle = -109.967
	self.xArrowRotation = 107.347
end

function IASBY_VehicleTachoMeter:Update()
	--Monitor the vehicle's speed and adjust rotation for the needle
	if (mainVehicleScript.playerInside and mainVehicleScript.vehicle.engine.enabled) then
		local vertical = Input.GetKeyBindAxis(KeyBinds.Vertical)

		if (vertical > 0) then
			if (self.speed <= self.steps[#self.steps]) then
				self.speed = self.speed + 1.5 * Time.deltaTime
			end
		elseif (vertical < 0) then
			if (self.speed > 0) then
				self.speed = self.speed - 1.6 * Time.deltaTime
			end
		else
			if (self.speed > 0) then
				self.speed = self.speed - 1.5 * Time.deltaTime
			end
		end
	else
		self.speed = Mathf.Lerp(self.speed, 0, Time.deltaTime * 9)
		self.stepInt = 1
		self.lastStepInt = 1
	end

	--Monitor speed
	self:MonitorSpeed()

	--Gives the current step
	self.currentStep = self.steps[self.stepInt]

	--Rotate needle and longer the steps
	self.needle.localRotation = Quaternion.Euler(Vector3(self.xArrowRotation, 0, Mathf.Lerp(self.minArrowAngle, self.maxArrowAngle, self.speed / self.currentStep)))

	if (self.speed >= self.currentStep) then		
		if (self.stepInt ~= #self.steps) then
			self.stepInt = self.stepInt + 1
			self.lastStepInt = self.stepInt - 1
		end
	end
end

function IASBY_VehicleTachoMeter:MonitorSpeed()
	if (self.stepInt > 1) then
		if (self.speed < self.steps[self.lastStepInt]) then
			self.stepInt = self.stepInt - 1
			self.lastStepInt = self.stepInt - 1
		end
	end
end
