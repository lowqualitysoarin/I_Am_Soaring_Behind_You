behaviour("IASBY_Pie")

function IASBY_Pie:Start()
	--Base
	self.pie = self.targets.pie
	self.targetName = nil

	--Bools
	self.alreadyPickedUp = false

	--Finishing Touches
	local id1 = Random.Range(1,9)
	local id2 = Random.Range(1,9)
	local id3 = Random.Range(1,9)

	local generatedID = math.floor(id1) .. math.floor(id2) .. math.floor(id3)
	self.pie.gameObject.name = self.pie.gameObject.name .. generatedID
	self.targetName = self.pie.gameObject.name
end

function IASBY_Pie:Update()
	local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	local pieCast = Physics.Spherecast(ray, 0.5, 1.2, RaycastTarget.ProjectileHit)

	if (pieCast ~= nil) then
		local isAKey = pieCast.collider.gameObject.name == self.targetName

		if (isAKey) then
			if (Input.GetKeyBindButtonDown(KeyBinds.Use) and self.alreadyPickedUp == false) then
				self:Pickup()
				self.alreadyPickedUp = true
			end
		end
	end
end

function IASBY_Pie:Pickup()
	local vehicleScript = GameObject.Find("bmw3090_IASBY").gameObject.GetComponent(IASBY_Vehicle)
	vehicleScript.callEndingFriend = true
	vehicleScript:AltEndings()
	
	self.gameObject.SetActive(false)
end
