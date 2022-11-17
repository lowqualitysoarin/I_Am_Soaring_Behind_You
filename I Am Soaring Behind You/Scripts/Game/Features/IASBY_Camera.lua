behaviour("IASBY_Camera")

function IASBY_Camera:Start()
	--Detection
	self.movingForward = false
	self.movingBackward = false
	self.movingRight = false
	self.movingLeft = false

	--Cam Movements
	self.tiltFreq = 3
	self.stepAmpli = 0.035
	self.stepFreq = 10.0

	--Essentials
	self.footStepPos = Vector3.zero
end

function IASBY_Camera:Update()
	self:MonitorMovements()
	self:CamMovements()
end

function IASBY_Camera:MonitorMovements()
	local inputVector = (Vector3.forward * Input.GetKeyBindAxis(KeyBinds.Vertical)) + (Vector3.right * Input.GetKeyBindAxis(KeyBinds.Horizontal))
    local vel = Player.actor.transform.parent.transform.InverseTransformDirection(inputVector)

	--Main
    if(vel.z > 0) then
		self.movingForward = true
		self.movingBackward = false
    elseif(vel.z < 0) then
		self.movingBackward = true
		self.movingForward = false
    end

    if(vel.x > 0) then
		self.movingRight = true
		self.movingLeft = false
    elseif(vel.x < 0) then
		self.movingLeft = true
		self.movingRight = false
    end

	--Reset
	if (vel.x == 0) then
		self.movingRight = false
		self.movingLeft = false
	end

	if (vel.z == 0) then
		self.movingForward = false
		self.movingBackward = false
	end
end

function IASBY_Camera:CamMovements()
	local tiltRight = Quaternion.Euler(Vector3(0, 0, self.tiltFreq))
	local tiltLeft = Quaternion.Euler(Vector3(0, 0, -self.tiltFreq))
	local reset = Quaternion.Euler(Vector3.zero)

	if (self.movingRight) then
		PlayerCamera.fpCameraLocalRotation = Quaternion.Lerp(PlayerCamera.fpCameraLocalRotation, tiltRight, Time.deltaTime * 7)
	elseif (self.movingLeft) then
		PlayerCamera.fpCameraLocalRotation = Quaternion.Lerp(PlayerCamera.fpCameraLocalRotation, tiltLeft, Time.deltaTime * 7)
	else
		PlayerCamera.fpCameraLocalRotation = Quaternion.Lerp(PlayerCamera.fpCameraLocalRotation, reset, Time.deltaTime * 7)
	end

	if (self.movingForward or self.movingBackward) then
		self:FootStepMotion()
		PlayerCamera.fpCameraLocalPosition = Vector3.Lerp(PlayerCamera.fpCameraLocalPosition, self.footStepPos, Time.deltaTime * 10)
	else
		self:ResetStepMotion()
	end
end

function IASBY_Camera:FootStepMotion()
	self.footStepPos.y = Mathf.Sin(Time.time * self.stepFreq) * self.stepAmpli
	self.footStepPos.x = Mathf.Sin(Time.time * self.stepFreq / 2) * self.stepAmpli * 2
	return self.footStepPos
end

function IASBY_Camera:ResetStepMotion()
	PlayerCamera.fpCameraLocalPosition = Vector3.Lerp(PlayerCamera.fpCameraLocalPosition, Vector3.zero, Time.deltaTime * 5)
end
