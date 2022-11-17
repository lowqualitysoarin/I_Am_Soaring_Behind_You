--Soarin's AI
behaviour("IASBY_SoarAI")

local minSpawnDist = 145

local closeDistance = 2.5
local chaseDistance = 12

local minJumpscareDist = 3
local maxJumpscareDist = 6

local decisionDist = 70
local vanishableDist = 60

local currentSpeed = nil

local caughtTimerStart = false
local caughtTimer = 0


function IASBY_SoarAI:Start()
	--Bases
	self.data = self.gameObject.GetComponent(DataContainer)

	self.soarBase = self.targets.soarBase
	self.soarPos = self.soarBase.gameObject.transform
	self.soarLookPivot = self.targets.soarLookPivot.transform
	
	self.soarPlane = self.targets.soarPlane
	self.soarRenderer = self.soarPlane.gameObject.GetComponent(Renderer)
	self.rayCastGuide = self.targets.raycastGuide.transform

	mainScript = self.targets.mainScript.gameObject.GetComponent(ACWS_IASBY)

	--Challenge Support
	self.normalMat = self.data.GetMaterial("soarin_normal")
	self.darkMat = self.data.GetMaterial("soarin_somethingwicked")

	self.somethingWicked = false

	--Respawning
	self.isRespawning = false
	self.aiReady = false

	--Movements
	self.canMove = true

	--Lives
	self.timesLookedAt = 0
	self.stillLooking = false

	--Weaknesses
	self.vanished = false
	self.canBeVanished = false
	self.hasBeenSeen = false
	self.startRespawn = false
	self.vanishTimer = 0
	self.respawnTimer = 0

	--Attacks
	self.lookAtPart = self.targets.lookAtPart.transform
	self.playerCaught = false
	self.canAttack = true

	self.fakeJumpscareTimerStart = false
	self.startFakeJumpscareTimer = 0

	self.fakeJumpscareActive = false
	self.fakeJumpscareLifetime = 25
	self.fakeJumpscareTimer = 0

	--Jumpscares
	self.jumpscareTimerStart = false
	self.jumpscareTimer = 0

	self.lowJumpscareTimerStart = false
	self.lowJumpscareTimer = 0

	self.dashTowardActive = false
	self.dashSpeed = 57

	self.popupActive = false
	self.popupLifetime = 20
	self.popupTimer = 0

	self.fakeChaseActive = false
	self.fakeChaseLifetime = 25
	self.fakeChaseTimer = 0

	--Speed
	self.speed = 50
	self.chaseSpeed = 6.5

	currentSpeed = self.speed

	--Spawn Fixing
	self.findPointAgainFaking = false

	--States
	self.startStates = false
	self.states = {
		"Chase",
		"Jumpscare",
		"FakeJumpscare",
		"Normal"
	}

	self.currentState = "LowJumpscares"

	--Fixing
	currentSpeed = nil
	
	caughtTimerStart = false
	caughtTimer = 0

	--Other AI Support
	--Akira Nishikiyama
	nishiki = self.targets.nishiki.gameObject.GetComponent(IASBY_Nishiki)

	--Spawn
	self:Respawn()
end

function IASBY_SoarAI:SomethingWickedActive()
	--When something wicked challenge is active
	self.somethingWicked = true
	self.soarPlane.gameObject.GetComponent(MeshRenderer).material = self.darkMat
end

function IASBY_SoarAI:DecideState()
	--Soarin's decision states
	if (self.startStates and not nishiki.chased) then
		self.currentState = self.states[math.random(#self.states)]
	end

	--If the player was being chased by Nishiki
	if (nishiki.chased and self.startStates) then
		local chasedStates = {
			self.states[1],
			self.states[2],
			self.states[3]
		}

		self.currentState = chasedStates[math.random(#chasedStates)]
	end

	if (self.currentState == "Jumpscare") then
		self.jumpscareTimerStart = true
	elseif (self.currentState == "FakeJumpscare") then
		self.fakeJumpscareTimerStart = true
	elseif (self.currentState == "Normal") then
		self:DisableJumpscareFunctions()
	elseif (self.currentState == "Chase") then
		self:DisableJumpscareFunctions()
	elseif (self.currentState == "LowJumpscares") then
		self.lowJumpscareTimerStart = true
	end

 	--print("Soarin's Current State is " .. self.currentState)
end

function IASBY_SoarAI:DisableJumpscareFunctions()
	--Disables jumpscares stuff when not used to fix some bugs
	self.fakeJumpscareActive = false
	self.dashTowardActive = false
	self.fakeChaseActive = false

	self.fakeJumpscareTimerStart = false
	
	self.fakeChaseTimer = 0
	self.startFakeJumpscareTimer = 0
end

function IASBY_SoarAI:SpawnPos()
	--Choose a random node to spawn Soarin. Restarts when it doesn't find a suitable one
	local spawnPoints = Pathfinding.FindNodes(Player.actor.transform.position, 500, PathfindingNodeType.Infantry, false)
	local chosenPoint = spawnPoints[math.random(#spawnPoints)]

	local distance = (chosenPoint.position - Player.actor.transform.position).magnitude

	if (distance > minSpawnDist) then
		self.soarPos.position = chosenPoint.position
		if (self.soarRenderer.isVisible) then
			return function()
			end
		end
	else
		return function()
		end
	end
end

function IASBY_SoarAI:Update()
	--Important Stuff
	local playerCam = PlayerCamera.activeCamera.transform
	self.soarLookPivot.LookAt(Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).transform.position)

	--Lives Essentials
	local randomLookAt = Random.Range(3, 5)
	local lookAtLives = math.floor(randomLookAt)


	--Main
	if (Player.actor.isDead == false) then
		local distanceToPlayer = (self.soarPos.position - Player.actor.transform.position).magnitude

		--AI States
		if (self.currentState == "Jumpscare") then
			self.canAttack = false
			self.canMove = false

			if (self.jumpscareTimerStart) then
				self.jumpscareTimer = self.jumpscareTimer + 1 * Time.deltaTime
				self.soarPlane.SetActive(false)
				if (self.jumpscareTimer > Random.Range(5, 20)) then
					self:StartJumpscare()
					self.jumpscareTimer = 0
					self.jumpscareTimerStart = false
				end
			end
		end

		if (self.currentState == "LowJumpscares") then
			self.canAttack = false
			self.canMove = false

			if (self.lowJumpscareTimerStart) then
				self.lowJumpscareTimer = self.lowJumpscareTimer + 1 * Time.deltaTime
				self.soarPlane.SetActive(false)
				if (self.lowJumpscareTimer > Random.Range(10, 20)) then
					self:StartJumpscare()
					self.lowJumpscareTimer = 0
					self.lowJumpscareTimerStart = false
				end
			end
		end

		if (self.currentState == "FakeJumpscare") then
			self.canMove = false

			if (self.fakeJumpscareTimerStart) then
				self.startFakeJumpscareTimer = self.startFakeJumpscareTimer + 1 * Time.deltaTime
				self.soarPlane.SetActive(false)
				if (self.startFakeJumpscareTimer > Random.Range(8, 20)) then
					self:FakeJumpscareStart()
					self.startFakeJumpscareTimer = 0
					self.fakeJumpscareTimerStart = false
				end
			end
		end

		--Weaknesses
		if (Player.actor.isFallenOver == false) then
			if (self.soarRenderer.isVisible and self.vanished == false) then
				if (self.currentState == "Normal") then
					if (distanceToPlayer < vanishableDist) then
						self.hasBeenSeen = true
					end
				elseif (self.currentState == "Chase") then
					if (distanceToPlayer < vanishableDist) then
						if (self.stillLooking == false) then
							self.timesLookedAt = self.timesLookedAt + 1
							if (self.timesLookedAt >= lookAtLives) then
								self.hasBeenSeen = true
								self.timesLookedAt = 0
							end
							self.stillLooking = true
						end
					end
				elseif (self.currentState == "Jumpscare" or self.currentState == "LowJumpscares") then
					if (self.canBeVanished) then
						self.hasBeenSeen = true
						self.canBeVanished = false
					end
				end
			else
				self.stillLooking = false
			end
		end

		--Movements
		if (self.vanished == false) then
			if (self.currentState ~= "Jumpscare") then
				if (self.currentState ~= "FakeJumpscare") then
					if (self.currentState ~= "LowJumpscares") then
						if (distanceToPlayer <= closeDistance) then
							self.canMove = false
						else
							self.canMove = true
						end
					end
				end
			end
		end

		if (self.currentState == "Chase") then
			if (distanceToPlayer < chaseDistance) then
				currentSpeed = self.chaseSpeed
			else
				currentSpeed = self.speed
			end
		else
			currentSpeed = self.speed
		end

		if (self.canMove) then
			self.soarPos.position = Vector3.MoveTowards(self.soarPos.position, Player.actor.transform.position, Time.deltaTime * currentSpeed)
		end

		--Attacks
		if (distanceToPlayer <= closeDistance) then
			if (self.canAttack) then
				self:PlayerCaught()
			end
		end

		if (self.playerCaught) then
			playerCam.LookAt(self.lookAtPart.position)
		end

		if (self.fakeJumpscareActive) then
			if (distanceToPlayer < Random.Range(3.99, 7.98)) then
				self.soarPos.position = Vector3.MoveTowards(self.soarPos.position, Player.actor.transform.position, Time.deltaTime * self.speed)
			end

			if (distanceToPlayer < closeDistance) then
				self.canMove = false
				self.fakeJumpscareActive = false
			end
		end

		--Jumpscares
		if (self.dashTowardActive) then
			self.soarPos.position = Vector3.MoveTowards(self.soarPos.position, Player.actor.transform.position, Time.deltaTime * self.dashSpeed)

			if (distanceToPlayer < closeDistance) then
				self.hasBeenSeen = true
				self.dashTowardActive = false
			end
		end

		if (self.fakeChaseActive) then
			if (distanceToPlayer < Random.Range(3.99, 7.98)) then
				self.soarPos.position = Vector3.MoveTowards(self.soarPos.position, Player.actor.transform.position, Time.deltaTime * self.speed)
			end

			if (distanceToPlayer < closeDistance) then
				self.hasBeenSeen = true
				self.fakeChaseActive = false
			end
		end

		--Timers
		if (self.hasBeenSeen and self.playerCaught == false) then
			self.vanishTimer = self.vanishTimer + 1 * Time.deltaTime
			if (self.vanishTimer > 0.12) then
				self:Vanish()
				self.vanishTimer = 0
				self.hasBeenSeen = false
			end
		end

		if (self.startRespawn) then
			self.respawnTimer = self.respawnTimer + 1 * Time.deltaTime
			self.soarPlane.SetActive(false)
			if (self.respawnTimer > Random.Range(8, 20)) then
				self:Respawn()
				self.respawnTimer = 0
				self.startRespawn = false
			end
		end

		if (caughtTimerStart) then
			caughtTimer = caughtTimer + 1 * Time.unscaledDeltaTime
			if (caughtTimer > 0.6) then
				mainScript:CrashGame()
			end
		end

		if (self.popupActive) then
			self.popupTimer = self.popupTimer + 1 * Time.deltaTime
			if (self.popupTimer > self.popupLifetime) then
				self.hasBeenSeen = true
				self.popupTimer = 0
				self.popupActive = false
			end
		end

		if (self.fakeChaseActive) then
			self.fakeChaseTimer = self.fakeChaseTimer + 1 * Time.deltaTime
			if (self.fakeChaseTimer > self.fakeChaseLifetime) then
				self.hasBeenSeen = true
				self.fakeChaseTimer = 0
				self.fakeChaseActive = false
			end
		end

		if (self.fakeJumpscareActive) then
			self.fakeJumpscareTimer = self.fakeJumpscareTimer + 1 * Time.deltaTime
			if (self.fakeJumpscareTimer > self.fakeJumpscareLifetime) then
				self.hasBeenSeen = true
				self.fakeJumpscareTimer = 0
				self.fakeJumpscareActive = false
			end
		end
	end
end

function IASBY_SoarAI:StartJumpscare()
	--Chooses a random jumpscare type
	local chosenJumpscare = "Popup"
	local jumpscares = {
		"Popup",
		"DashTowards",
		"FakeChase"
	}

	if (self.startStates) then
		chosenJumpscare = jumpscares[math.random(#jumpscares)]
        --print(chosenJumpscare)
	end

	if (chosenJumpscare == "Popup") then
		self:PopupJumpscare()
	elseif (chosenJumpscare == "DashTowards") then
		self:DashTowardJumpscare()
	elseif (chosenJumpscare == "FakeChase") then
		self:FakeChase()
	end
end

function IASBY_SoarAI:PopupJumpscare()
	--Soarin pops up possible in front or behind the player
	self.soarPlane.SetActive(true)
	local playerTrans = Player.actor.transform

	local RandX = Random.Range(-10, 10)
	local RandZ = Random.Range(-10, 10)

	local point = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	self.soarPos.position = point

	local ray = Ray(self.rayCastGuide.position + Vector3.up, Vector3.down)
	local raycastSnap = Physics.RaycastAll(ray, Mathf.Infinity, RaycastTarget.Default)

	for int,hit in pairs(raycastSnap) do
		self.soarPos.position = hit.point
		break
	end

	self.canBeVanished = true
	self.popupActive = true
	
	--Disable Unrelated
	self.fakeChaseActive = false
	self.fakeChaseTimer = 0

	self.dashTowardActive = false
end

function IASBY_SoarAI:DashTowardJumpscare()
	--Soarin dashes towards the player (Not really perfect)
	self.soarPlane.SetActive(true)
	local playerTrans = Player.actor.transform

	local RandX = Random.Range(-50, 50)
	local RandZ = Random.Range(-50, 50)

	local point = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	self.soarPos.position = point

	local ray = Ray(self.rayCastGuide.position + Vector3.up, Vector3.down)
	local raycastSnap = Physics.RaycastAll(ray, Mathf.Infinity, RaycastTarget.Default)

	for int,hit in pairs(raycastSnap) do
		self.soarPos.position = hit.point
		break
	end

	self.dashTowardActive = true

	--Disable Unrelated
	self.canBeVanished = false
	self.popupActive = false
	self.popupTimer = 0

	self.fakeChaseActive = false
	self.fakeChaseTimer = 0
end

function IASBY_SoarAI:FakeChase()
	--Soarin stands still and waits for the player to come close. If the player does he dashes towards the player
	self.soarPlane.SetActive(true)
	local playerTrans = Player.actor.transform

	local RandX = Random.Range(-35, 35)
	local RandZ = Random.Range(-35, 35)

	local point = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	self.soarPos.position = point

	if (self.soarRenderer.isVisible) then
		self:GetANewPoint("FakeChase")
	end

	local ray = Ray(self.rayCastGuide.position + Vector3.up, Vector3.down)
	local raycastSnap = Physics.RaycastAll(ray, Mathf.Infinity, RaycastTarget.Default)

	for int,hit in pairs(raycastSnap) do
		self.soarPos.position = hit.point
		break
	end

	self.fakeChaseActive = true

	--Disable Unrelated
	self.canBeVanished = false
	self.popupActive = false
	self.popupTimer = 0

	self.dashTowardActive = false
end

function IASBY_SoarAI:FakeJumpscareStart()
	--Similar to fake chase but Soarin kills the player
	self.soarPlane.SetActive(true)
	local playerTrans = Player.actor.transform

	local RandX = Random.Range(-35, 35)
	local RandZ = Random.Range(-35, 35)

	local point = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	self.soarPos.position = point

	if (self.soarRenderer.isVisible) then
		self:GetANewPoint("FakeJumpscare")
	end

	local ray = Ray(self.rayCastGuide.position + Vector3.up, Vector3.down)
	local raycastSnap = Physics.RaycastAll(ray, Mathf.Infinity, RaycastTarget.Default)

	for int,hit in pairs(raycastSnap) do
		self.soarPos.position = hit.point
		break
	end

	self.fakeJumpscareActive = true
end

function IASBY_SoarAI:GetANewPoint(type)
	--Get a new point for jumpscares if it doesn't find a suitable one
	local playerTrans = Player.actor.transform

	local RandX = Random.Range(-35, 35)
	local RandZ = Random.Range(-35, 35)

	local point = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	self.soarPos.position = point

	if (type == "FakeJumpscare" or type == "FakeChase" or  self.findPointAgainFaking) then
		if (self.soarRenderer.isVisible) then
			self.findPointAgainFaking = true
			return function()
			end
		else
			self.findPointAgainFaking = false
		end
	end
end

function IASBY_SoarAI:PlayerCaught()
	--When the player gets caught
	self.playerCaught = true
	Time.timeScale = 0
	Player.actor.speedMultiplier = 0

	if (self.somethingWicked) then
		self.soarPlane.gameObject.GetComponent(MeshRenderer).material = self.normalMat
	end

	if (Player.actor.activeWeapon ~= nil) then
		Player.actor.activeWeapon.gameObject.SetActive(false)
	end
	
	caughtTimerStart = true
end

function IASBY_SoarAI:Vanish()
	--Vanish stuff
	self.vanished = true
	self.canAttack = false
	self.canMove = false
	self.soarPlane.SetActive(false)
	self:ResetTimers()

	self.startRespawn = true

	--print("vanished")
end

function IASBY_SoarAI:Respawn()
	--Respawn stuff
	self.aiReady = true
	self.vanished = false
	self:SpawnPos()
	self:DecideState()
	self.soarPlane.SetActive(true)
	self.canMove = true
	self.canAttack = true

	--print("respawned")
end

function IASBY_SoarAI:ResetTimers()
	--Resets jumpscare timers
	--Popup
	self.popupTimer = 0

	--Fake Chase
	self.fakeChaseTimer = 0
end

--[Takayuki Yagami Jumpscare]
