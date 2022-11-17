behaviour("IASBY_Satellite")

function IASBY_Satellite:Start()
	--Base
	self.satAnimator = self.gameObject.GetComponent(Animator)
	self.satPivot = self.targets.pivot.transform
	self.satNeck = self.targets.neck.transform

	self.activateTime = 25
	self.activateTimer = 0
	self.activated = false

	--HUD
	self.hud = self.targets.hud
	self.barFill = self.targets.barFill.gameObject.GetComponent(Image)
	self.objText = self.targets.objText.gameObject.GetComponent(Text)

	self.objText.text = "Repairing..."
	self.hud.SetActive(false)

	--Bools
	self.playerInRange = false
	self.alreadyRepaired = false
	self.canRepair = true
	self.repairing = false
	self.lookingAtSatellite = false

	--Fixing
	local randomizedID1 = Random.Range(1, 9)
	local randomizedID2 = Random.Range(1, 9)
	local randomizedID3 = Random.Range(1, 9)

	local flooredVal1 = math.floor(randomizedID1)
	local flooredVal2 = math.floor(randomizedID2)
	local flooredVal3 = math.floor(randomizedID3)

	self.targetName = self.transform.GetChild(0).gameObject.name .. flooredVal1 .. flooredVal2 .. flooredVal3
	self.transform.GetChild(0).gameObject.name = self.targetName

	--Idle Active
	self.lookAtPosSet = false
	self.cooldown = 10
	self.cooldownTimer = 0

	self.posToLookAt = nil
end

function IASBY_Satellite:Update()
	--Check if Player in range
	local actorInRange = ActorManager.AliveActorsInRange(self.satPivot.position, 2.5)

	for k,v in pairs(actorInRange) do
		if (v.isPlayer == true) then
			self.playerInRange = true
		else
			self.playerInRange = false
		end
	end

	--Repairing
	if (self.playerInRange) then
		local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
		local rayHit = Physics.Spherecast(ray, 0.5, 1.7, RaycastTarget.ProjectileHit)

		if (rayHit ~= nil) then
			self.lookingAtSatellite = rayHit.collider.gameObject.name == self.targetName

			if (self.lookingAtSatellite) then
				if (self.alreadyRepaired == false) then
					self.canRepair = true
				end
			else
				self:DeactivateHUD()
				self.repairing = false
				self.canRepair = false
			end
		else
			self:DeactivateHUD()
			self.repairing = false
			self.canRepair = false
		end

		if (self.canRepair) then
			if (Input.GetKeyBindButtonDown(KeyBinds.Use)) then
				self.repairing = true
			end

			if (self.repairing) then
				self.activateTimer = self.activateTimer + 1 * Time.deltaTime
				self:ActivateHUD()
				if (self.activateTimer > self.activateTime) then
					self.activateTimer = 0
					self.alreadyRepaired = true
					self.canRepair = false
					self:Repaired()
					self:DeactivateHUD()
					self.repairing = false
				end
			end
		end
	else
		self:DeactivateHUD()
		self.repairing = false
		self.canRepair = false
	end

	if (self.alreadyRepaired) then
		self.satAnimator.SetBool("active", true)

		local randomY = Random.Range(-100, 100)

		if (self.lookAtPosSet == false) then
			self.posToLookAt = Quaternion.Euler(Vector3(0, 0, randomY))
			self.lookAtPosSet = true
		end

		if (self.lookAtPosSet) then
			self.cooldownTimer = self.cooldownTimer + 1 * Time.deltaTime
			if (self.cooldownTimer > self.cooldown) then
				self.cooldownTimer = 0
				self.lookAtPosSet = false
			end
		end

		self.satNeck.localRotation = Quaternion.Lerp(self.satNeck.localRotation, self.posToLookAt, Time.deltaTime * 1)
	else
		self.satAnimator.SetBool("active", false)
	end
end

function IASBY_Satellite:ActivateHUD()
	self.hud.SetActive(true)
	self.barFill.fillAmount = self.activateTimer / self.activateTime
end

function IASBY_Satellite:DeactivateHUD()
	self.hud.SetActive(false)
	self.barFill.fillAmount = 0
end

function IASBY_Satellite:Repaired()
	local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ScriptedBehaviour).self
	mainScript:ObjectiveCompleted(self.gameObject)
	--print("Satellite Repaired")
end