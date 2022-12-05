behaviour("IASBY_Flashlight")

function IASBY_Flashlight:Start()
	--Base
    self.audioBank = self.targets.soundBank.gameObject.GetComponent(SoundBank)
    self.flashlight = self.targets.flashlight
    self.pivot = self.targets.flashlightPivot

    self.flashlight.SetActive(false)
    self.flashOn = false
end

function IASBY_Flashlight:Update()
	if (Player.actor.isDead == false) then
        self.pivot.transform.position = PlayerCamera.activeCamera.transform.position
        self.pivot.transform.rotation = PlayerCamera.activeCamera.transform.rotation

        if (Input.GetKeyDown(KeyCode.T) and Player.actor.activeVehicle == nil) then
            self.flashOn = not self.flashOn

            if (self.flashOn) then
                self.flashlight.SetActive(true)
                self.audioBank.PlaySoundBank(0)
            else
                self.flashlight.SetActive(false)
                self.audioBank.PlaySoundBank(1)
            end
        end

        if (Player.actor.activeVehicle ~= nil) then
            self.flashOn = false
            self.flashlight.SetActive(false)
        end
    end
end
