behaviour("IASBY_CarLights")

function IASBY_CarLights:Start()
	--Data
	self.data = self.gameObject.GetComponent(DataContainer)

	--Lights
	--Closed
	self.closedFogLights = self.data.GetMaterial("closedFogLights")
	self.closedHeadlights = self.data.GetMaterial("closedHeadlights")
	self.closedSignalLights = self.data.GetMaterial("closedSignalLights")
	self.closedRearLights = self.data.GetMaterial("closedRearLights")

	--Opened
	self.openedFogLights = self.data.GetMaterial("openedFogLights")
	self.openedHeadlights = self.data.GetMaterial("openedHeadlights")
	self.openedSignalLights = self.data.GetMaterial("openedSignalLights")
	self.openedRearLights = self.data.GetMaterial("openedRearLights")

	--Dashboard
	self.closedNeedle = self.data.GetMaterial("closedNeedle")
	self.openedNeedle = self.data.GetMaterial("openedNeedle")

	self.lowBeam = self.targets.lowBeam
	self.longBeam = self.targets.longBeam

	--Headlights
	self.headlightsBase = self.targets.headlight.gameObject.GetComponent(Light)

	self.hlNormalRange = 25
	self.hlLongRange = 45

	self.hlHoldTimer = 0

	self.longLights = false
	self.justOpened = false

	--Stopping
	self.stoppingRearLights = self.data.GetMaterial("rearLightsStopping")

	--Sounds
	self.lightsSoundBank = self.gameObject.GetComponent(SoundBank)

	--Main
	self.vehicle = self.targets.vehicle.gameObject.GetComponent(Vehicle)
	self.vehicleMesh = self.targets.vehicleMesh.gameObject.GetComponent(MeshRenderer)
	self.lightsAnimator = self.gameObject.GetComponent(Animator)

	self.dashNeedle = self.targets.dashNeedle.gameObject.GetComponent(Renderer)
	self.speedoNeedle = self.targets.speedoNeedle.gameObject.GetComponent(Renderer)
	self.tachoNeedle = self.targets.tachoNeedle.gameObject.GetComponent(Renderer)

	vehicleMain = self.vehicle.gameObject.GetComponentInChildren(IASBY_VehicleMainFeatures)

	self.velocity = 0
	self.movingForwards = false
	self.movingBackwards = false
	self.stopped = false

	self.lights = self.data.GetGameObjectArray("light")
	self.lightOn = false
	self.alreadyApplied = false
	self.alreadyAppliedDead = false
end

function IASBY_CarLights:Update()
	if (self.vehicle.playerIsInside and Player.actor.isDriver) then
		--Checks the velocity
	    self:CheckVelocity()
		
		--Trigger Lights
		--Main Lights
		if (Input.GetKeyDown(KeyCode.T) and not self.lightOn) then
			if (not vehicleMain.disabledBattery) then
				self.lightOn = true
			end

			if (self.lightOn) then
				if (not vehicleMain.disabledBattery) then
					self:LightsOn()
				end
			end

			if (not self.lightOn and vehicleMain.disabledBattery) then
				self.lightsSoundBank.PlaySoundBank(0)
			end
		end

		if (Input.GetKeyDown(KeyCode.T) and self.lightOn) then
			self.longLights = not self.longLights

			if (not self.justOpened) then
				self.longLights = false
				self.justOpened = true
			end

			if (self.longLights) then
				self.lightsSoundBank.PlaySoundBank(0)
				self.headlightsBase.range = self.hlLongRange

				self.lowBeam.gameObject.SetActive(true)
				self.longBeam.gameObject.SetActive(true)
			else
				self.lightsSoundBank.PlaySoundBank(0)
				self.headlightsBase.range = self.hlNormalRange

				self.lowBeam.gameObject.SetActive(true)
				self.longBeam.gameObject.SetActive(false)
			end
		end

		if (Input.GetKey(KeyCode.T) and self.lightOn) then
			self.hlHoldTimer = self.hlHoldTimer + 1 * Time.deltaTime
			if (self.hlHoldTimer >= 0.75) then
				self:LightsOff()
				self.lightsSoundBank.PlaySoundBank(1)
				self.lightOn = false
				self.longLights = false
				self.justOpened = false
				self.hlHoldTimer = 0
			end
		elseif (Input.GetKeyUp(KeyCode.T) and self.lightOn) then
			self.hlHoldTimer = 0
		end

		--Rearlights
		self:RearLights()
		self.alreadyApplied = false
	else
		if (not self.alreadyApplied) then
			if (self.lightOn) then
				local oldMatArray = self.vehicleMesh.sharedMaterials
				oldMatArray[6] = self.openedRearLights
	
				self.vehicleMesh.sharedMaterials = oldMatArray
			else
				local oldMatArray = self.vehicleMesh.sharedMaterials
				oldMatArray[6] = self.closedRearLights
	
				self.vehicleMesh.sharedMaterials = oldMatArray
			end

			self.alreadyApplied = true
		end
	end

	if (self.vehicle.isDead and not self.alreadyAppliedDead) then
		self:LightsOff()
		self.alreadyAppliedDead = true
	end
end

function IASBY_CarLights:CheckVelocity()
	--The velocity
	self.velocity = Input.GetKeyBindAxis(KeyBinds.Vertical)

	--Bool triggers
	if (self.velocity > 0) then
		self.movingForwards = true
		self.movingBackwards = false
		self.stopped = false
	elseif (self.velocity < 0) then
		self.movingForwards = false
		self.movingBackwards = true
		self.stopped = false
	else
		self.movingForwards = false
		self.movingBackwards = false
		self.stopped = true
	end
end

function IASBY_CarLights:RearLights()
	--Makes the rearlights brighter when stoppping
	local verticalAxisRaw = Input.GetAxisRaw("Vertical")

	if (verticalAxisRaw == -1 and not self.vehicle.inReverseGear or verticalAxisRaw == 1 and self.vehicle.inReverseGear) then
		local oldMatArray = self.vehicleMesh.sharedMaterials
		oldMatArray[6] = self.stoppingRearLights

		self.vehicleMesh.sharedMaterials = oldMatArray
	else
		if (self.lightOn) then
			local oldMatArray = self.vehicleMesh.sharedMaterials
			oldMatArray[6] = self.openedRearLights

			self.vehicleMesh.sharedMaterials = oldMatArray
		else
			local oldMatArray = self.vehicleMesh.sharedMaterials
			oldMatArray[6] = self.closedRearLights

			self.vehicleMesh.sharedMaterials = oldMatArray
		end
	end
end

function IASBY_CarLights:LightsOn()
	--Changes the materials
	local oldMatArray = self.vehicleMesh.sharedMaterials

	oldMatArray[6] = self.openedRearLights
	oldMatArray[3] = self.openedFogLights
	oldMatArray[7] = self.openedHeadlights
	oldMatArray[5] = self.openedSignalLights

	self.vehicleMesh.sharedMaterials = oldMatArray

	--For the dashboard
	local oldDashMatArray = self.dashNeedle.materials
	oldDashMatArray[2] = self.openedNeedle

	self.speedoNeedle.material = self.openedNeedle
	self.tachoNeedle.material = self.openedNeedle

	self.dashNeedle.materials = oldDashMatArray

	--Trigger Animator
	self.lightsAnimator.SetBool("lightsOn", true)
end

function IASBY_CarLights:LightsOff()
	--Changes the materials
	local oldMatArray = self.vehicleMesh.sharedMaterials

	oldMatArray[6] = self.closedRearLights
	oldMatArray[3] = self.closedFogLights
	oldMatArray[7] = self.closedHeadlights
	oldMatArray[5] = self.closedSignalLights

	self.vehicleMesh.sharedMaterials = oldMatArray

	--For the dashboard
	local oldDashMatArray = self.dashNeedle.materials
	oldDashMatArray[2] = self.closedNeedle

	self.speedoNeedle.material = self.closedNeedle
	self.tachoNeedle.material = self.closedNeedle

	self.dashNeedle.materials = oldDashMatArray

	self.lowBeam.gameObject.SetActive(false)
	self.longBeam.gameObject.SetActive(false)

	--Trigger Animator
	self.lightsAnimator.SetBool("lightsOn", false)
end

function IASBY_CarLights:ShutDownLights()
	self:LightsOff()

	self.lightOn = false
	self.longLights = false
	self.justOpened = false
end