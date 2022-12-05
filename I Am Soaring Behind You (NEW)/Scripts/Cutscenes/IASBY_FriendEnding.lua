behaviour("IASBY_FriendEnding")

function IASBY_FriendEnding:Start()
	--Base
	self.overrideCam = self.targets.cutCam.gameObject.GetComponent(Camera)
	self.cutAnimator = self.targets.animator.gameObject.GetComponent(Animator)

	self.cutAnimator.SetTrigger("play")
	PlayerCamera.OverrideActiveCamera(self.overrideCam)

	--Timers
	self.endTimer = 0

	--Bools
	self.alreadyCalled = false

	--Stop Player From Moving and Looking
	Player.actor.speedMultiplier = 0
	Player.allowMouseLook = false
end

function IASBY_FriendEnding:Update()
	self.endTimer = self.endTimer + 1 * Time.deltaTime
	if (self.endTimer >= 12) then
		local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ScriptedBehaviour).self

		if (self.alreadyCalled == false) then
			mainScript:FriendEndingFinished()
			self.alreadyCalled = true
		end 
	end
end
