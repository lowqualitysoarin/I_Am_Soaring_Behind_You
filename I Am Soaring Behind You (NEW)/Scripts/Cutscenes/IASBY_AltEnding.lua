behaviour("IASBY_AltEnding")

function IASBY_AltEnding:Start()
	--Base
	self.overrideCam = self.targets.cutCam.gameObject.GetComponent(Camera)
	self.cutAnimator = self.targets.animator.gameObject.GetComponent(Animator)

	self.cutAnimator.SetTrigger("startcutscene")
	PlayerCamera.OverrideActiveCamera(self.overrideCam)

	--Timer
	self.crashTimer = 0

	--Bools
	self.alreadyCalled = false

	--Stop Player From Moving and Looking
	Player.actor.speedMultiplier = 0
	Player.allowMouseLook = false
end

function IASBY_AltEnding:Update()
	self.crashTimer = self.crashTimer + 1 * Time.deltaTime
	if (self.crashTimer >= 10) then
		local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ScriptedBehaviour).self

		if (mainScript.allowCrash) then
			while (Player.actor.isDead == false) do
			end
		end

		if (self.alreadyCalled == false) then
			mainScript:AltEndingFinished()
			self.alreadyCalled = true
		end 
	end
end