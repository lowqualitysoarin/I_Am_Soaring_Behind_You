behaviour("IASBY_Intro")

function IASBY_Intro:Start()
	--Base
	self.mainMenu = self.targets.mainMenu

	--Start Timer
	self.startTime = 16
	self.startTimer = 0
	self.startTimerStart = true
end

function IASBY_Intro:Update()
	if (self.startTimer) then
		self.startTimer = self.startTimer + 1 * Time.deltaTime
		if (self.startTimer >= self.startTime) then
			self.mainMenu.SetActive(true)
			if (self.startTimer >= 18) then
				self.gameObject.SetActive(false)
				self.startTimer = 0
			end
		end
	end

	if (Input.anyKey and self.startTimer < self.startTime) then
		self.startTimer = 19
	end
end
