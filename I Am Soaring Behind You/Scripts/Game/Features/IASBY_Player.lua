behaviour("IASBY_Player")

function IASBY_Player:Start()
	self.forcedOff = false
end

function IASBY_Player:Update()
	if (self.forcedOff == false) then
		Player.actor.balance = 10000
	end
end
