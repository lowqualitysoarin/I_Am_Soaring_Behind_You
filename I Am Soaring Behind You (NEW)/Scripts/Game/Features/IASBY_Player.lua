behaviour("IASBY_Player")

function IASBY_Player:Start()
	--Checks
	self.forcedOff = false
end

function IASBY_Player:Update()
	--Config bools
	if (self.forcedOff == false) then
		Player.actor.balance = 10000
	end

	--Setups
	PlayerCamera.activeCamera.current.nearClipPlane = 0.01
end
