behaviour("IASBY_VehicleMainFeatures")

function IASBY_VehicleMainFeatures:Start()
	--Base
	self.vehicle = self.targets.vehicle.gameObject.GetComponent(Vehicle)
	self.vehicleMesh = self.targets.vehicleMesh.gameObject.GetComponent(MeshRenderer)
	self.fpCamera = self.targets.fpCamera.gameObject.GetComponent(Camera)

	self.seatsGO = self.targets.seats.gameObject.GetComponent(BoxCollider)
	self.interiorLight = self.targets.interiorLight
	self.doorFR = self.targets.doorFR.gameObject
	self.doorFL = self.targets.doorFL.gameObject

	self.spawnPos = self.vehicle.transform.position
	self.spawnRot = self.vehicle.transform.rotation

	vehicleLights = self.vehicle.gameObject.GetComponentInChildren(IASBY_CarLights)

	--Defaults
	self.defaultTopSpeed = self.vehicle.topSpeed
	self.defaultAcceleSpeed = self.vehicle.acceleration
	self.defaultReverseSpeed = self.vehicle.reverseAcceleration
	self.defaultSteeringDrag = self.vehicle.groundSteeringDrag
	self.defaultTurnTorque = self.vehicle.baseTurnTorque
	self.defaultSpeedTurnTorque = self.vehicle.speedTurnTorque

	--Camera Zoom
	self.defaultCamFOV = self.fpCamera.fieldOfView
	self.fovZoom = 25

	self.alreadyAppliedDefault = false

	--AI Manager
	soarin = nil
	nishiki = nil

	self.alreadyGotSoarin = false
	self.alreadyGotNishiki = false

	self.soarinTeleportPoint = self.targets.soarinTeleportPoint.transform
	self.soarinTeleportPointDash = self.targets.soarinTeleportPointDash.transform

	--Main
	self.playerInside = false
	self.playerWasInsideBefore = false

	self.drownTimerStart = false
	self.drownTimer = 0

	self.teleportTimerStart = false
	self.teleportTimer = 0

	self.uprightTimerStart = false
	self.uprightTimer = 0

	self.vehicleVelocity = 0
	self.distanceToPlayer = 0

	--Doors
	--Bools and Floats
	self.lookingAtDoorFR = false
	self.lookingAtDoorFL = false

	self.doorFROpen = false
	self.doorFLOpen = false

	self.doorDistanceToPlayer = 0

	--Animators
	self.doorFRAnim = self.doorFR.GetComponent(Animator)
	self.doorFLAnim = self.doorFL.GetComponent(Animator)

	--Target Names
	self.doorFRTargetName = nil
	self.doorFLTargetName = nil

	--ID Generation (Avoiding overlaps)
	local generatedFirstId = false

	local id1 = nil
	local id2 = nil

	for i = 1, 2 do
		local randomizedID1 = Random.Range(1, 9)
	    local randomizedID2 = Random.Range(1, 9)
	    local randomizedID3 = Random.Range(1, 9)

	    local flooredVal1 = math.floor(randomizedID1)
	    local flooredVal2 = math.floor(randomizedID2)
	    local flooredVal3 = math.floor(randomizedID3)

		if (generatedFirstId == false) then
			id1 = flooredVal1 .. flooredVal2 .. flooredVal3
			generatedFirstId = true
		else
			id2 = flooredVal1 .. flooredVal2 .. flooredVal3
		end
	end

	self.doorFR.name = self.doorFR.name .. id1
	self.doorFL.name = self.doorFL.name .. id2

	self.doorFRTargetName = self.doorFR.name
	self.doorFLTargetName = self.doorFL.name

	--Engine Interaction
	self.engineOn = false
	self.alreadyStartedEngine = false

	self.startedEngineTimerStart = false
	self.startedEngineTimer = 0

	--Malfunctions
	--Battery
	self.batteryAmount = 100
	self.batteryCurrentAmount = self.batteryAmount

	self.batteryLightsConsumeAmount = 0.095
	self.batteryRechargeAmount = 0.25

	self.batteryRechargeTimeStart = 10
	self.batteryRechargeStartTimer = 0

	self.alreadyDisabledBattery = false

	--Electromagnetic Pulsed
	self.disabledBattery = false
	self.canBeDisabled = true

	self.disabledCooldownTimer = 0
	self.enableTimer = 0

	--Stalling
	self.startStalling = false
	self.stallTimer = 0

	--Dashboard
	self.doorAjar = self.targets.doorAjar
	self.checkBattery = self.targets.checkBattery
	self.electricalFault = self.targets.electricalFault

	--Patches
	--Fixes why the ignition clip is playing despite engine is disabled
	self.extraEngineAudSrc = self.targets.extraEngAud.gameObject.GetComponent(AudioSource)

	--Finishing Touches
	--Change the vehicle color
	local random1 = Random.Range(0, 1)
	local random2 = Random.Range(0, 1)
	local random3 = Random.Range(0, 1)

	local chosenColorCode = Color(random1, random2, random3, 1)

	self.vehicleMesh.materials[1].color = chosenColorCode
	self.doorFR.GetComponent(Renderer).materials[1].color = chosenColorCode
	self.doorFL.GetComponent(Renderer).materials[1].color = chosenColorCode

	--Lock the vehicle
	self.allowToInteract = true
	self.interactTimer = 0

	self.unlockTimerTriggered = false
	self.unlockVehicle = false
	self.unlockTimer = 0

	self.seatsGO.enabled = false
end

function IASBY_VehicleMainFeatures:Update()
	--Doors
	self:CarDoors()

	--Engine Interaction
	self:EngineInteraction()

	--Checks
	self:Checks()

	--Timers
	self:Timers()

	--Invincibility
	self:Invincibility()

	--Malfunctions
	self:Malfunctions()

	--AI Manager
	self:AIManager()

	--FP Camera Zoom
	self:FPZoom()

	--Patching
	self:Patching()
end

function IASBY_VehicleMainFeatures:EngineInteraction()
	--For manual engine startup
	if (Input.GetKeyDown(KeyCode.I) and not self.disabledBattery) then
		self.engineOn = not self.engineOn

		if (self.engineOn) then
			self:StartVehicle()
		else
			self.alreadyStartedEngine = false
		end
	end

	--Keeps the engine disabled until the player starts the engine manually again and keeps the engine on until the player turns it off
	if (not self.engineOn) then
		self:TurnOffEngine()
	else
		self.vehicle.engine.enabled = true
	end
end

function IASBY_VehicleMainFeatures:Patching()
	--Trying to stop playing the ignition clip and other engine sounds to play despite the battery is disabled
	if (self.disabledBattery or not self.engineOn) then
		self.extraEngineAudSrc.Stop()
	end

	--Same thing from above but this one stops the engine start from playing again when entering the vehicle despite its already started
	if (self.alreadyStartedEngine) then
		self.extraEngineAudSrc.Stop()
	end
end

function IASBY_VehicleMainFeatures:FPZoom()
	--Self explanatory, its for vehicle zoom thing since I use a custom fp camera
	if (self.playerInside) then
		if (Input.GetKeyBindButton(KeyBinds.Aim)) then
			self.fpCamera.fieldOfView = Mathf.Lerp(self.fpCamera.fieldOfView, self.fovZoom, Time.deltaTime * 8)
			self.alreadyAppliedDefault = false
		end

		if (Input.GetKeyBindButton(KeyBinds.Aim) == false and not self.alreadyAppliedDefault) then
			self.fpCamera.fieldOfView = Mathf.Lerp(self.fpCamera.fieldOfView, self.defaultCamFOV, Time.deltaTime * 8)

			if (self.fpCamera.fieldOfView == self.defaultCamFOV) then
				self.alreadyAppliedDefault = true
			end
		end
	end
end

function IASBY_VehicleMainFeatures:Malfunctions()
	--Battery Properties
	--Drain the battery when the lights are on and recharge it when off
	if (vehicleLights.lightOn and self.batteryCurrentAmount > 0) then
		self.batteryCurrentAmount = self.batteryCurrentAmount - self.batteryLightsConsumeAmount * Time.deltaTime
		self.batteryRechargeStartTimer = 0
	elseif (not vehicleLights.lightOn and self.batteryCurrentAmount < self.batteryAmount) then
		self.batteryRechargeStartTimer = self.batteryRechargeStartTimer + 1 * Time.deltaTime

		if (self.batteryRechargeStartTimer > self.batteryRechargeTimeStart) then
			self.batteryCurrentAmount = self.batteryCurrentAmount + self.batteryRechargeAmount * Time.deltaTime
		end
	end

	--When the battery percentage drains under 35 percent then it'll start stalling
	if (self.batteryCurrentAmount < 35) then
		self.startStalling = true
		self.alreadyDisabledBattery = false
		self.checkBattery.gameObject.SetActive(true)
	else
		self.startStalling = false
		self.alreadyDisabledBattery = false
		self.checkBattery.gameObject.SetActive(false)
	end

	--Disabled Car Battery
	if (self.disabledBattery) then
		self.enableTimer = self.enableTimer + 1 * Time.deltaTime

		self.vehicle.engine.enabled = false
		self.checkBattery.gameObject.SetActive(true)
		self.electricalFault.gameObject.SetActive(true)

		if (self.enableTimer > Random.Range(30, 60)) then 
			self:StartVehicle()
			self.checkBattery.gameObject.SetActive(false)
		    self.electricalFault.gameObject.SetActive(false)

			self.enableTimer = 0
			self.disabledBattery = false
		end
	end

	--Disable Cooldown (So Soarin' doesn't always disable your vehicle lmao)
	if (not self.canBeDisabled) then
		self.disabledCooldownTimer = self.disabledCooldownTimer + 1 * Time.deltaTime
		if (self.disabledCooldownTimer > Random.Range(85, 260)) then
			self.disabledCooldownTimer = 0
			self.canBeDisabled = true
		end
	else
		self.disabledCooldownTimer = 0
	end

	--Stalling
	if (self.startStalling) then
		self.stallTimer = self.stallTimer + 1 * Time.deltaTime
		if (self.stallTimer > Random.Range(30, 60)) then
			if (self.engineOn) then
				self:Stall()
			end
			self.stallTimer = 0
		end
	else
		self.stallTimer = 0
	end
end

function IASBY_VehicleMainFeatures:AIManager()
	--Soarin'
	--Try to detect if Soarin' is active
	local getSoarin = GameObject.Find("Soarin'")

	if (getSoarin ~= nil) then
		local isReallyIsSoarin = getSoarin.GetComponent(IASBY_SoarAI)

		if (isReallyIsSoarin and not self.alreadyGotSoarin) then
			soarin = isReallyIsSoarin
			self.alreadyGotSoarin = true
		end
	end

	if (soarin ~= nil) then
		--Soarin' will EMP the player's vehicle when the player tries to ram him or when the player gets close
		soarin.playerInVehicle = self.playerInside
	
		--Gives Soarin' the custom jumpscare/teleport position
		soarin.vehicleTeleportPoint = self.soarinTeleportPoint.position
		soarin.vehicleTeleportPointDash = self.soarinTeleportPointDash.position
	
		--Notifies Soarin' if the player's vehicle is disabled
		soarin.vehicleIsDisabled = self.disabledBattery

		--Notifies Soarin' if the player's vehicle engine is on
		soarin.vehicleEngineOn = self.engineOn
	end

	--Akira Nishikiyama
	--Try to detect if Nishiki is active
	local getNishiki = GameObject.Find("Akira Nishikiyama")

	if (getNishiki ~= nil) then
		local isReallyIsNishiki = getNishiki.GetComponent(IASBY_Nishiki)

		if (isReallyIsNishiki and not self.alreadyGotNishiki) then
			nishiki = isReallyIsNishiki
			self.alreadyGotNishiki = true
		end
	end

	if (nishiki ~= nil) then
		--Notifies Nishikiyama if the player is inside the vehicle
		nishiki.playerInVehicle = self.playerInside

		--Notifies Nishikiyama if the player's vehicle lights is turned on
		nishiki.vehicleLightsOn = vehicleLights.lightOn

		--Notifies Nishikiyama if the player's engine is on
		nishiki.vehicleEngineOn = self.engineOn
	end
end

function IASBY_VehicleMainFeatures:Checks()
	--Check if the player is inside. Doing the dirty way because the easy one may cause overlapping issues
	if (self.vehicle.playerIsInside) then
		self.playerInside = true
	else
		self.playerInside = false
	end

	--Drowns the player if he is inside the vehicle and in underwater or teleports back to the spawn pos if the player wasn't
	if (self.vehicle.isInWater and self.playerInside) then
		self.drownTimerStart = true

		self.teleportTimerStart = false
		self.teleportTimer = 0
	elseif (self.vehicle.isInWater and not self.playerInside) then
		self.teleportTimerStart = true

		self.drownTimerStart = false
		self.drownTimer = 0
	else
		self.drownTimerStart = false
		self.drownTimer = 0

		self.teleportTimerStart = false
		self.teleportTimer = 0
	end

	--Checks if the vehicle is upside down
	if (Vector3.Dot(self.vehicle.transform.up, Vector3.down) > 0) then
		self.uprightTimerStart = true
	else
		self.uprightTimerStart = false
		self.uprightTimer = 0
	end

	--Gets the vehicle's velocity
	self.vehicleVelocity = self.vehicle.rigidbody.velocity.magnitude

	--Gets distancse between the player and the x
	self.distanceToPlayer = (Player.actor.transform.position - self.vehicle.transform.position).magnitude
	self.doorDistanceToPlayer = (Player.actor.transform.position - self.doorFL.transform.position).magnitude
end

function IASBY_VehicleMainFeatures:Timers()
	--Drown Timer
	if (self.drownTimerStart) then
		self.drownTimer = self.drownTimer + 1 * Time.unscaledDeltaTime
		if (self.drownTimer > 0.85) then
			self:DrownedUnderwater()
			self.drownTimer = 0
			self.drownTimerStart = false
		end
	end

	--Teleport Timer
	if (self.teleportTimerStart) then
		self.teleportTimer = self.teleportTimer + 1 * Time.deltaTime
		if (self.teleportTimer > 2.85) then
			self:TeleportToNormalPos()
			self.teleportTimer = 0
			self.teleportTimerStart = false
		end
	end

	--Upright Timer
	if (self.uprightTimerStart) then
		self.uprightTimer = self.uprightTimer + 1 * Time.deltaTime
		if (self.uprightTimer > 1.85) then
			self:UprightVehicle()
			self.uprightTimer = 0
			self.uprightTimerStart = false
		end
	end

	--Unlock Timer
	if (self.unlockVehicle) then
		self.unlockTimer = self.unlockTimer + 1 * Time.deltaTime
		if (self.unlockTimer >= 0.65) then
			self.seatsGO.enabled = true
			self.unlockTimerTriggered = true
			self.unlockTimer = 0
			self.unlockVehicle = false
		end
	else
		self.unlockTimer = 0
		self.unlockVehicle = false
	end

	if (not self.allowToInteract) then
		self.interactTimer = self.interactTimer + 1 * Time.deltaTime
		if (self.interactTimer >= 1.2) then
			self.interactTimer = 0
			self.allowToInteract = true
		end
	else
		self.interactTimer = 0
	end

	--Started Engine Timer
	if (self.startedEngineTimerStart) then
		self.startedEngineTimer = self.startedEngineTimer + 1 * Time.deltaTime
		if (self.startedEngineTimer >= 2.5) then
			self.alreadyStartedEngine = true
			self.startedEngineTimer = 0
			self.startedEngineTimerStart = false
		end
	else
		self.startedEngineTimer = 0
	end
end

function IASBY_VehicleMainFeatures:Invincibility()
	--Soo the vehicle won't die when ignored for a long time
	self.vehicle.health = self.vehicle.maxHealth
end

function IASBY_VehicleMainFeatures:CarDoors()
	--Again for the car doors
	--Raycasts to detect for interaction
	local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	local rayHit = Physics.Spherecast(ray, 0.09, 1.2, RaycastTarget.ProjectileHit)

	--Initiate raycast detect what door is the player looking at
	if (not self.playerInside) then
		if (rayHit ~= nil) then
			--Local bools
			local isDoorFR = rayHit.collider.gameObject.name == self.doorFRTargetName
			local isDoorFL = rayHit.collider.gameObject.name == self.doorFLTargetName
	
			--If the player is looking at the front right door
			if (isDoorFR) then
				self.lookingAtDoorFR = true
			else
				self.lookingAtDoorFR = false
			end

			--If the player is looking at the front left door
			if (isDoorFL) then
				self.lookingAtDoorFL = true
			else
				self.lookingAtDoorFl = false
			end
		else
			--If none
			self.lookingAtDoorFL = false
			self.lookingAtDoorFR = false
		end
	end

	--If the player is looking at the front right door and hits the use key then open the door
	if (self.lookingAtDoorFR) then
		if (Input.GetKeyBindButtonDown(KeyBinds.Use)) then
			self.doorFROpen = not self.doorFROpen

			if (self.doorFROpen) then
				self.doorFRAnim.SetBool("open", true)
			else
				self.doorFRAnim.SetBool("open", false)
			end
		end
	end

	--Else if the player is looking at the front left door and hits the use key then open the door
	if (self.lookingAtDoorFL) then
		if (Input.GetKeyBindButtonDown(KeyBinds.Use) and self.allowToInteract) then
			self.doorFLOpen = not self.doorFLOpen

			if (self.doorFLOpen) then
				self.allowToInteract = false
				self.doorFLAnim.SetBool("open", true)
				self.unlockVehicle = true
			else
				self.doorFLAnim.SetBool("open", false)
				self.seatsGO.enabled = false
				self.unlockTimerTriggered = false
				self.unlockVehicle = false
			end
		end
	end

	--This is for patching when the player is far away from the drivers seat then it will disable the seats
	if (self.doorFLOpen and self.unlockTimerTriggered) then
		if (self.doorDistanceToPlayer < 2) then
			self.seatsGO.enabled = true
		else
			self.seatsGO.enabled = false
		end
	end

	--Instantly closes the front left door when the player is outside else it will open again if the player exits the vehicle
	if (self.playerInside) then
		if (self.doorFLOpen) then
			self.doorFLAnim.SetBool("open", false)
			self.doorFLOpen = false
		end
		self.playerWasInsideBefore = true
	elseif (not self.playerInside and self.playerWasInsideBefore) then
		self.doorFLOpen = true
		self.doorFLAnim.SetBool("open", true)
		self.playerWasInsideBefore = false
	end

	--Vehicle interior lights and the door ajar indicator
	if (not self.disabledBattery) then
		if (self.doorFLOpen or self.doorFROpen) then
			self.interiorLight.gameObject.SetActive(true)
			self.doorAjar.gameObject.SetActive(true)
		else
			self.interiorLight.gameObject.SetActive(false)
			self.doorAjar.gameObject.SetActive(false)
		end
	else
		self.interiorLight.gameObject.SetActive(false)
		self.doorAjar.gameObject.SetActive(false)
	end
end

function IASBY_VehicleMainFeatures:DisableEngine()
	--Just disables engine sounds
	self.vehicle.engine.enabled = false
end

function IASBY_VehicleMainFeatures:DrownedUnderwater()
	--If the players drowns with the vehicle underwater
	local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ACWS_IASBY)

	if (mainScript ~= nil) then
		mainScript:CrashGame()
	end

	Time.timeScale = 0
	Player.actor.speedMultiplier = 0
end

function IASBY_VehicleMainFeatures:TeleportToNormalPos()
	--Teleports to the normal spawn position when the vehicle drowns without the player
	self.vehicle.transform.position = self.spawnPos
	self.vehicle.transform.rotation = self.spawnRot
end

function IASBY_VehicleMainFeatures:UprightVehicle()
	--Uprights the vehicle when it flips upside down
	self.vehicle.transform.localRotation = Quaternion.FromToRotation(self.vehicle.transform.up, Vector3.up) * self.vehicle.transform.rotation
end

function IASBY_VehicleMainFeatures:ShockVehicle()
	--When the vehicle was EMP'ied by Soarin'
	if (self.canBeDisabled) then
		--I'm fucking using rngs for this can't you believe it??
		local isUnlucky = false

		local luckShot = Random.Range(0, 100)
		local unluckyShot = Random.Range(0, 100)
	
		local greaterOrLess = math.random(1, 2)
	
		if (greaterOrLess == 1) then
			if (luckShot > unluckyShot) then
				isUnlucky = true
			end
		elseif (greaterOrLess == 2) then
			if (luckShot < unluckyShot) then
				isUnlucky = true
			end
		end
	
		--Disable the vehicle if possible
		if (self.vehicleVelocity > Random.Range(17, 27) or self.vehicleVelocity < Random.Range(-17, -27) or isUnlucky) then
			if (not self.disabledBattery) then
				self.engineOn = false
				self.alreadyStartedEngine = false

				self.vehicle.topSpeed = 0
				self.vehicle.acceleration = 0
				self.vehicle.reverseAcceleration = 0
				self.vehicle.groundSteeringDrag = 0
				self.vehicle.baseTurnTorque = 0
				self.vehicle.speedTurnTorque = 0
				self.vehicle.engine.enabled = false
		
				vehicleLights:ShutDownLights()
		
				self.disabledBattery = true
				self.canBeDisabled = false
			end
		end
	end
end

function IASBY_VehicleMainFeatures:StartVehicle()
	--Starts the vehicle

	self.vehicle.topSpeed = self.defaultTopSpeed
	self.vehicle.acceleration = self.defaultAcceleSpeed
	self.vehicle.reverseAcceleration = self.defaultReverseSpeed
	self.vehicle.groundSteeringDrag = self.defaultSteeringDrag
	self.vehicle.baseTurnTorque = self.defaultTurnTorque
	self.vehicle.speedTurnTorque = self.defaultSpeedTurnTorque

	if (self.engineOn) then
		self.vehicle.engine.PlayIgnitionSound()
		self.vehicle.engine.enabled = true
		self.startedEngineTimerStart = true
	end
end

function IASBY_VehicleMainFeatures:TurnOffEngine()
	--Shuts down the vehicle

	self.vehicle.topSpeed = 0
	self.vehicle.acceleration = 0
	self.vehicle.reverseAcceleration = 0
	self.vehicle.groundSteeringDrag = 0
	self.vehicle.baseTurnTorque = 0
	self.vehicle.speedTurnTorque = 0
	self.vehicle.engine.enabled = false
end

function IASBY_VehicleMainFeatures:Stall()
	--Stalling when the vehicle is low on battery
	self.engineOn = false
	self.alreadyStartedEngine = false

	--Rolls a dice if the stall should shut down the lights
	local shutDownLights = false

	local rollADice = math.random(1, 6)
	local shot = math.random(1, 6)
	local lessOrGreater = math.random(1, 2)

	if (lessOrGreater == 1) then
		if (rollADice > shot) then
			shutDownLights = true
		end
	elseif (lessOrGreater == 2) then
		if (rollADice < shot) then
			shutDownLights = true
		end
	end

	if (shutDownLights) then
		vehicleLights:ShutDownLights()
	end
end