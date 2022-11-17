behaviour("IASBY_SafeKey")

function IASBY_SafeKey:Start()
	--Base
	self.key = self.targets.key

	self.targetName = nil

	--Bools
	self.alreadyPickedUp = false

	--Finishing Touches
	local id1 = Random.Range(1,9)
	local id2 = Random.Range(1,9)
	local id3 = Random.Range(1,9)

	local generatedID = math.floor(id1) .. math.floor(id2) .. math.floor(id3)
	self.key.gameObject.name = self.key.gameObject.name .. generatedID
	self.targetName = self.key.gameObject.name
end

function IASBY_SafeKey:Update()
	local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	local keyCast = Physics.Spherecast(ray, 0.5, 1.2, RaycastTarget.ProjectileHit)

	if (keyCast ~= nil) then
		local isAKey = keyCast.collider.gameObject.name == self.targetName

		if (isAKey) then
			if (Input.GetKeyBindButtonDown(KeyBinds.Use) and self.alreadyPickedUp == false) then
				self:Pickup()
				self.alreadyPickedUp = true
			end
		end
	end
end

function IASBY_SafeKey:Pickup()
	local safeScript = GameObject.Find("PieSafe(Clone)").gameObject.GetComponent(IASBY_SafeBase)
	safeScript.playerHasKey = true
	self.gameObject.SetActive(false)
end
