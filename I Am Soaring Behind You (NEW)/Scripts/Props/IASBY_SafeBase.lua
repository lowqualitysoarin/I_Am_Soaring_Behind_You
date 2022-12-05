behaviour("IASBY_SafeBase")

function IASBY_SafeBase:Start()
	--Base
	self.safeAnimator = self.gameObject.GetComponent(Animator)
	self.safeDoor = self.targets.safeDoor

	self.targetName = nil

	--Bools
	self.playerHasKey = false
	self.opened = false
	self.called = false

	--Finishing Touches
	local id1 = Random.Range(1,9)
	local id2 = Random.Range(1,9)
	local id3 = Random.Range(1,9)

	local generatedId = math.floor(id1) .. math.floor(id2) .. math.floor(id3)
	self.safeDoor.gameObject.name = self.safeDoor.gameObject.name .. generatedId
	self.targetName = self.safeDoor.gameObject.name
end

function IASBY_SafeBase:Update()
	local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	local safeCast = Physics.Spherecast(ray, 0.2, 1.5, RaycastTarget.ProjectileHit)

	if (safeCast ~= nil) then
		local isASafe = safeCast.collider.gameObject.name == self.targetName

		if (isASafe) then
			if (Input.GetKeyBindButtonDown(KeyBinds.Use) and self.playerHasKey and self.called == false) then
				self.safeAnimator.SetBool("opened", true)
				self:Opened()
				self.called = true
			end
		end
	end
end

function IASBY_SafeBase:Opened()

end
