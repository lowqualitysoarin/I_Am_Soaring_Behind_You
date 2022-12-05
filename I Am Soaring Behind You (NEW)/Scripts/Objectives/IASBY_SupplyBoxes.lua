behaviour("IASBY_SupplyBoxes")

function IASBY_SupplyBoxes:Start()
	--Base
	self.boxPivot = self.targets.boxPivot.transform

	self.collectTime = 20
	self.collectTimer = 0
	self.collected = false

	--HUD
	self.hud = self.targets.hud
	self.barFill = self.targets.barFill.gameObject.GetComponent(Image)
	self.objText = self.targets.objText.gameObject.GetComponent(Text)

	self.objText.text = "Gathering Supplies..."
	self.hud.SetActive(false)

	--Fixing
	local randomizedID1 = Random.Range(1, 9)
	local randomizedID2 = Random.Range(1, 9)
	local randomizedID3 = Random.Range(1, 9)

	local flooredVal1 = math.floor(randomizedID1)
	local flooredVal2 = math.floor(randomizedID2)
	local flooredVal3 = math.floor(randomizedID3)

	self.targetName = self.transform.GetChild(0).gameObject.name .. flooredVal1 .. flooredVal2 .. flooredVal3
	self.transform.GetChild(0).gameObject.name = self.targetName

	--Bools
	self.playerInRange = false
	self.alreadyCollected = false
	self.canCollect = false
	self.collecting = false
	self.lookingAtBox = false
end

function IASBY_SupplyBoxes:Update()
	--Check if Player in range
	local actorsInRange = (self.boxPivot.position - Player.actor.transform.position).magnitude

	if (actorsInRange < 2.5) then
		self.playerInRange = true
	else
		self.playerInRange = false
	end

	--Collecting
	if (self.playerInRange) then
		local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
		local rayHit = Physics.Spherecast(ray, 0.5, 1.7, RaycastTarget.ProjectileHit)

		if (rayHit ~= nil) then
			self.lookingAtBox = rayHit.collider.gameObject.name == self.targetName

			if (self.lookingAtBox) then
				if (self.alreadyCollected == false) then
					self.canCollect = true
				end
			else
				self:DeactivateHUD()
				self.collecting = false
				self.canCollect = false
			end
		else
			self:DeactivateHUD()
			self.collecting = false
			self.canCollect = false
		end

		if (self.canCollect) then
			if (Input.GetKeyBindButtonDown(KeyBinds.Use)) then
				self.collecting = true
			end

			if (self.collecting) then
				self.collectTimer = self.collectTimer + 1 * Time.deltaTime
				self:ActivateHUD()
				if (self.collectTimer > self.collectTime) then
					self.collectTimer = 0
					self.alreadyCollected = true
					self.canCollect = false
					self:DeactivateHUD()
					self:Collected()
					self.collecting = false
				end
			end
		end
	else
		self:DeactivateHUD()
		self.collecting = false
		self.canCollect = false
	end
end

function IASBY_SupplyBoxes:ActivateHUD()
	self.hud.SetActive(true)
	self.barFill.fillAmount = self.collectTimer / self.collectTime
end

function IASBY_SupplyBoxes:DeactivateHUD()
	self.hud.SetActive(false)
	self.barFill.fillAmount = 0
end

function IASBY_SupplyBoxes:Collected()
	local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ScriptedBehaviour).self
	mainScript:ObjectiveCompleted(self.gameObject)
end