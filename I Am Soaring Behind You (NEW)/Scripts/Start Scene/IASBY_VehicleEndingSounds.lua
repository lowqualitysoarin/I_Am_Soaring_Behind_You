behaviour("IASBY_VehicleEndingSounds")

function IASBY_VehicleEndingSounds:Start()
	--Base
	self.engine = self.targets.engine
	self.engineLoop = self.targets.drive.gameObject.GetComponent(AudioSource)
	self.engineLoop.volume = 0

	--Timers
	self.driveTimer = 0
	self.fadeAudioTimer = 0

	--Bools
	self.alreadySet = false
	self.fading = false

	--Start
	self.engine.SetActive(true)
end

function IASBY_VehicleEndingSounds:Update()
	self.driveTimer = self.driveTimer + 1 * Time.deltaTime
	if (self.driveTimer >= 0.8) then
		self.engineLoop.gameObject.SetActive(true)
		if (self.fading == false) then
			self.engineLoop.volume = Mathf.Lerp(self.engineLoop.volume, 100, Time.deltaTime * 3)
		end
		self.fadeAudioTimer = self.fadeAudioTimer + 1 * Time.deltaTime
		if (self.fadeAudioTimer > 3.9) then
			self.fading = true
			self.engineLoop.volume = Mathf.Lerp(self.engineLoop.volume, 0, Time.deltaTime * 6)
		end
	end
end
