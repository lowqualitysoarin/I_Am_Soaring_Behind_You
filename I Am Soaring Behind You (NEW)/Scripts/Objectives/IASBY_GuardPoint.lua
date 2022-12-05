behaviour("IASBY_GuardPoint")

function IASBY_GuardPoint:Start()
	--Base
	self.data = self.gameObject.GetComponent(DataContainer)
	self.guardPivot = self.targets.guardPivot.transform
	self.audioSource = self.targets.audSrc

	self.guardTime = 20
	self.guardTimer = 0
	self.guarded = false

	self.guardRange = Random.Range(10, 20)

	--HUD
	self.hud = self.targets.hud
	self.objText = self.targets.objText.gameObject.GetComponent(Text)
	self.dialogueText = self.targets.dialogueText.gameObject.GetComponent(Text)

	self.objText.text = "Guard around this area until you are allowed to go."
	self.dialogueText.text = ""
	self.dialogueText.CrossFadeAlpha(0, 0, false)

	--Dialogue
	self.dialogueCDStart = false
	self.dialogueCD = 0.25
	self.dialogueTimer = 0

	self.moveOutDialogues = self.data.GetStringArray("moveOut")
	self.holdStillDialogues = self.data.GetStringArray("holdArea")
	self.getBackDialogues = self.data.GetStringArray("getBack")

	self.dialogueHoldStillCDStart = false
	self.dialogueHoldStillTime = 15
	self.dialogueHoldStillTimer = 0

	self.alreadyCalledHold = false
	self.alreadyCalledBack = false
	self.alreadyEnteredArea = false

	--Bools
	self.playerInRange = false
	self.guarding = false
	self.guarded = false
end

function IASBY_GuardPoint:Update()
	--Check if Player in range
	local actorsInRange = (self.guardPivot.position - Player.actor.transform.position).magnitude

	if (actorsInRange < self.guardRange) then
		self.playerInRange = true
	else
		self.playerInRange = false
	end

	--Guarding
	self.guardTime = Random.Range(6, 16)

	if (self.playerInRange and Player.actor.activeVehicle == nil) then
		self.guarding = true
		if (self.guarding and self.guarded == false) then
			self.guardTimer = self.guardTimer + 1 * Time.deltaTime
			self:ActivateHUD()
			if (self.guardTimer > self.guardTime) then
				self.guarded = true
				self.guardTimer = 0
				self:DeactivateHUD()
				self:MoveOut()
				self:Guarded()
				self.guarding = false
			end
		end

		if (self.alreadyCalledHold == false and self.guarded == false) then
			self:HoldArea()
			self.alreadyCalledHold = true
			self.alreadyCalledBack = false
		end

		self.alreadyEnteredArea = true
	else
		self:DeactivateHUD()
		self.guarding = false

		if (self.guarded == false) then
			if (self.alreadyCalledBack == false and self.alreadyEnteredArea) then
				self:ReturnToArea()
				self.alreadyCalledBack = true
				self.alreadyCalledHold = false
			end
		end 
	end
end

function IASBY_GuardPoint:ActivateHUD()
	self.objText.gameObject.SetActive(true)
end

function IASBY_GuardPoint:DeactivateHUD()
	self.objText.gameObject.SetActive(false)
end

function IASBY_GuardPoint:Guarded()
	local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ScriptedBehaviour).self
	mainScript:ObjectiveCompleted(self.gameObject)
end

function IASBY_GuardPoint:ReturnToArea()
	local dialogueToSpeak = self.getBackDialogues[math.random(#self.getBackDialogues)]
	self.dialogueText.text = dialogueToSpeak

	self.dialogueText.CrossFadeAlpha(1, 0.9, false)
	self.script.StartCoroutine("CloseDialogue")
end

function IASBY_GuardPoint:HoldArea()
	local dialogueToSpeak = self.holdStillDialogues[math.random(#self.holdStillDialogues)]
	self.dialogueText.text = dialogueToSpeak

	self.dialogueText.CrossFadeAlpha(1, 0.9, false)
	self.script.StartCoroutine("CloseDialogue")
end

function IASBY_GuardPoint:MoveOut()
	local dialogueToSpeak = self.moveOutDialogues[math.random(#self.moveOutDialogues)]
	self.dialogueText.text = dialogueToSpeak

	self.dialogueText.CrossFadeAlpha(1, 0.9, false)
	self.script.StartCoroutine("CloseDialogue")
end

function IASBY_GuardPoint:CloseDialogue()
	coroutine.yield(WaitForSeconds(1.8))
	self.dialogueText.CrossFadeAlpha(0, 0.9, false)
end
