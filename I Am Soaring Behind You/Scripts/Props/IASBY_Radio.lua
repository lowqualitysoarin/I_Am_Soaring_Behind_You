behaviour("IASBY_Radio")

function IASBY_Radio:Start()
	--Base
	self.radio = self.targets.radio
	self.radioAnimator = self.gameObject.GetComponent(Animator)

	self.targetName = nil

	--Soundbank
	self.sb = self.gameObject.GetComponent(SoundBank)

	--Bools
	self.isOn = false
	self.alreadyCalledAlt = false
	
	--Events
	self.nishikiMusic = self.targets.nishiki
	self.warnNishiki = false

	--Finsihing Touches
	local id1 = Random.Range(1, 9)
	local id2 = Random.Range(1, 9)
	local id3 = Random.Range(1, 9)

	local finalID = id1 .. id2 .. id3
	self.radio.gameObject.name = self.radio.gameObject.name .. finalID
	self.targetName = self.radio.gameObject.name
end

function IASBY_Radio:Update()
	local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	local cast = Physics.Spherecast(ray, 0.5, 1.2, RaycastTarget.ProjectileHit)

	if (cast ~= nil) then
		local isRadio = cast.collider.gameObject.name == self.targetName

		if (isRadio) then
			--print("its a radio")
			if (Input.GetKeyBindButtonDown(KeyBinds.Use)) then
				self.isOn = not self.isOn

				if (self.isOn) then
					self.radioAnimator.SetBool("active", true)
					
					local soundToPlay = self.sb.clips[math.random(#self.sb.clips)]
					self.sb.audioSource.clip = soundToPlay
					self.sb.audioSource.Play()

					self:CheckEvent(soundToPlay)
				else
					self.sb.audioSource.Stop()
					self.radioAnimator.SetBool("active", false)
				end
			end
		end
	end

	if (self.warnNishiki and self.alreadyCalledAlt == false) then
		self:ActivateAltEnding()
		self.alreadyCalledAlt = true
	end

	if (self.isOn) then
		if (self.sb.audioSource.isPlaying == false) then
			local soundToPlay = self.sb.clips[math.random(#self.sb.clips)]
			self.sb.audioSource.clip = soundToPlay
			self.sb.audioSource.Play()

			self:CheckEvent(soundToPlay)
		end
	end
end

function IASBY_Radio:ActivateAltEnding()
	local script = GameObject.Find("bmw3090_IASBY").gameObject.GetComponent(ScriptedBehaviour).self
	script.callEndingAlt = true
	script:AltEndings()
end

function IASBY_Radio:CheckEvent(clip)
	if (clip == self.nishikiMusic) then
		self.warnNishiki = true
	end
end
