--Akira Nishikiyama's AI
behaviour("IASBY_Nishiki")

function IASBY_Nishiki:Start()
    --Bases
	self.data = self.gameObject.GetComponent(DataContainer)

    self.nishikiBase = self.targets.nishiki
    self.nishikiPos = self.nishikiBase.transform
    self.nishikiLookPos = self.targets.nishikiLook.transform
	self.nishikiPlane = self.targets.nishikiPlane.gameObject.GetComponent(MeshRenderer)

	self.nishikiRB = self.gameObject.GetComponent(Rigidbody)

	mainScript = self.targets.mainScript.gameObject.GetComponent(ACWS_IASBY)

	--Challenge Support
	self.normalMat = self.data.GetMaterial("nishiki_normal")
	self.darkMat = self.data.GetMaterial("nishiki_somethingwicked")

	self.somethingWicked = false

    --Movement
	self.targetPosition = Vector3.zero

    self.currentSpeed = nil
    self.walkSpeed = 2.5
    self.runSpeed = 5.5

    self.canMove = true

	--Unstuck System
	self.currentPos = Vector3.zero
	self.prevPos = Vector3.zero

	self.prevPosSetTime = 2.5
	self.prevPosTimer = 0

	self.stuckTime = 10
	self.stuckTimer = 0

    --Distances
    self.distanceToPlayer = nil

    --Restrictions
    self.closeDistance = 1.5
	self.triggerSpotDist = 12

    --States
    self.states = {
		"Wander", 
		"Chase",
		"Searching",
		"CatchingUp",
		"Distracted"
	}

    self.currentState = self.states[1]

	--Wandering
	self.newPointTime = 18
	self.newPointTimer = 0
	self.farNewPointTime = 10
	self.farNewPointTimer = 0
	self.tpNewPointTime = 100
	self.tpNewPointTimer = 0

	self.justSpawned = true

    --Attacks
    self.canAttack = true
    self.alreadyAttacked = false
	self.playerCaught = false
	self.crashTimerStart = false
	self.crashTimer = 0

	--Vision
	self.visionPos = self.targets.visionRay.transform

	self.playerInSight = false
	self.lostPlayer = false
	self.giveUpSearching = false

	self.searchTime = 35
	self.searchTimer = 0
	self.searchPointTime = 10
	self.searchPointTimer = 0

	--Chase
	self.lastPlayerPos = Vector3.zero
	self.reachedLastPos = false

	self.teleportToLastPosTime = 17
	self.teleportPosTimer = 0

	self.chased = false

	--Ground Detection
	self.groundTeleportTime = 18
	self.groundTeleportTimer = 0

	--Voices
	self.killSound = self.targets.killSound
	self.spottedSound = self.targets.spotted.gameObject.GetComponent(SoundBank)
	self.chaseTheme = self.targets.chaseTheme
	self.chaseAudSrc = self.chaseTheme.gameObject.GetComponent(AudioSource)
	self.killSound.gameObject.GetComponent(AudioSource).SetOutputAudioMixer(AudioMixer.Master)

	self.alreadySaidSpot = false

	--Other AI Support
	--Soarin'
	soarin = self.targets.soarin.gameObject.GetComponent(IASBY_SoarAI)

    --Spawn
	self:Spawn()
	self.aiReady = true
end

function IASBY_Nishiki:SomethingWickedActive()
	--When something wicked challenge is active
	self.somethingWicked = true
	self.nishikiPlane.material = self.darkMat
end

function IASBY_Nishiki:Spawn()
	--Spawns him on a random spawnpoint nearby capture flags
	local spawns = ActorManager.spawnPoints

	for _,point in pairs(spawns) do
		local chosenPoint = spawns[math.random(#spawns)]
		local distanceToPlayer = (chosenPoint.spawnPosition - Player.actor.transform.position).magnitude

		if (distanceToPlayer > 40) then
			local randomX = Random.Range(-10, 10)
			local randomZ = Random.Range(-10, 10)

			local spawnPoint = Vector3(chosenPoint.spawnPosition.x + randomX, chosenPoint.spawnPosition.y, chosenPoint.spawnPosition.z + randomZ)
			self.nishikiPos.position = spawnPoint
			break
		end
	end
end

function IASBY_Nishiki:LateUpdate()
	--Teleport when stuck
	if (self.currentState == "Chase") then
		self.prevPosTimer = self.prevPosTimer + 1 * Time.deltaTime
		if (self.prevPosTimer > self.prevPosSetTime) then
			self.prevPos = self.nishikiPos.position
			self.prevPosTimer = 0
		end
	end
end

function IASBY_Nishiki:Update()
    --Base
    if (Player.actor.isDead == false) then
        --Important Stuff
        self.distanceToPlayer = (self.nishikiPos.position - Player.actor.transform.position).magnitude
        self.nishikiLookPos.LookAt(Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).transform.position)

        --Movements
		--Speed
		if (self.currentState == "Wander") then
			self.currentSpeed = self.walkSpeed
		elseif (self.currentState == "Chase") then
			self.currentSpeed = self.runSpeed
		end

        --Restrictions
        if (self.currentState ~= "Wander") then
            if (self.distanceToPlayer <= self.closeDistance) then
                self.canMove = false
            else
                self.canMove = true
                self.alreadyAttacked = false
				self.killSound.SetActive(false)
            end
        end

		--Main
		if (self.canMove) then
			self.nishikiPos.position = Vector3.MoveTowards(self.nishikiPos.position, self.targetPosition, Time.deltaTime * self.currentSpeed)
		end

		--Ground Detection
		self:GroundDetect()

		--Wander
		if (self.currentState == "Wander") then
			self:Wander()
		end

        --Chase
        if (self.currentState == "Chase") then
			self:Chase()
        end

		--Search
		if (self.currentState == "Searching") then
			self:Search()
		end

		--Catch Up
		if (self.currentState == "CatchingUp") then
			self:CatchUpPlayer()
		end

		--Timers
		--Kill timer
		if (self.crashTimerStart) then
			self.crashTimer = self.crashTimer + 1 * Time.unscaledDeltaTime
			if (self.crashTimer > 0.6) then
				mainScript:CrashGame()
			end
		end

		--Attacks
		--Caught
		if (self.playerCaught) then
			PlayerCamera.activeCamera.transform.LookAt(self.nishikiLookPos.position)
		end
    end
end

function IASBY_Nishiki:Wander()
	--Resets vars
	self:RestartVar()

	--Get player transform for the wander target point
	local playerTrans = Player.actor.transform

	--Wander points
	if (self.distanceToPlayer < 50) then
		if (self.canMove and self.justSpawned == false) then
			self.newPointTimer = self.newPointTimer + 1 * Time.deltaTime
			if (self.newPointTimer > self.newPointTime) then
				--Set new target point
				self:SetWalkPoint()
				self.newPointTimer = 0
			end
		end
	end

	--Vision stuff
	if (self.distanceToPlayer < 30) then
		local focusPoint = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).transform.position
		local visionRay = Physics.Linecast(self.visionPos.position, focusPoint, RaycastTarget.ProjectileHit)
	
		if (visionRay ~= nil) then
			--Confirmation
			local playerInSight = visionRay.collider.gameObject.GetComponentInParent(Actor)
	
			if (playerInSight ~= nil) then
				if (playerInSight.isPlayer) then
					self.currentState = self.states[2]
				end
			end
		end
	end

	--Set point when spawned for the first time
	if (self.justSpawned) then
		--Set a random target point when spawned
		self:SetWalkPoint()
		self.justSpawned = false
	end

	--Teleports Nishiki to a random point by time
	if (self.currentState == "Wander") then
		self.tpNewPointTimer = self.tpNewPointTimer + 1 * Time.deltaTime
		if (self.tpNewPointTimer > self.tpNewPointTime) then
			self:Spawn()
			self.tpNewPointTimer = 0
		end
	else
		self.tpNewPointTimer = 0
	end
end

function IASBY_Nishiki:TrackPlayer()
	--Sets points where the player goes while chasing
	self.lastPlayerPos = Player.actor.transform.position
end

function IASBY_Nishiki:CatchUpPlayer()
	--Nishiki will try to catch up the player when lost visual
	self.lostPlayer = true
	local lastPlayerPosDist = (self.nishikiPos.position - self.lastPlayerPos).magnitude

	if (self.reachedLastPos == false) then
		if (lastPlayerPosDist < 1) then
			self.teleportPosTimer = 0
			self.currentState = self.states[3]
			self.reachedLastPos = true
		else
			self.targetPosition = self.lastPlayerPos
		end
	end
	
	--I am fucking lazy soo he is just going to teleport when he can't get to the last player position
	self.teleportPosTimer = self.teleportPosTimer + 1 * Time.deltaTime
	if (self.teleportPosTimer > self.teleportToLastPosTime) then
		self.nishikiPos.position = self.lastPlayerPos
		self.teleportPosTimer = 0
	end

	--Vision stuff again lmfaooo
	if (self.distanceToPlayer < 40) then
		local focusPoint = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).transform.position
		local visionRay = Physics.Linecast(self.visionPos.position, focusPoint, RaycastTarget.ProjectileHit)
	
		if (visionRay ~= nil) then
			--Confirmation
			local playerInSight = visionRay.collider.gameObject.GetComponentInParent(Actor)
	
			if (playerInSight ~= nil) then
				if (playerInSight.isPlayer) then
					self.currentState = self.states[2]
				end
			end
		end
	end

	--Lower chase volume
	if (self.playerCaught == false) then
		self.script.StartCoroutine("LowerChaseVol")
	end
end

function IASBY_Nishiki:Chase()
	--Get player pos for the target point and current pos for the unstuck system
	self.currentPos = self.nishikiPos.position

	--For the unstuck system (not really though)
	local stuckDist = (self.currentPos - self.prevPos).magnitude

	--Chase vision stuff idk
	local focusPoint = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).transform.position
	local visionRay = Physics.Linecast(self.visionPos.position, focusPoint, RaycastTarget.ProjectileHit)
	
	if (self.distanceToPlayer < 35) then
		if (visionRay ~= nil) then
			--Confirmation
			local playerInSight = visionRay.collider.gameObject.GetComponentInParent(Actor)
	
			if (playerInSight ~= nil) then
				if (playerInSight.isPlayer) then
					self.playerInSight = true
					self.giveUpSearching = false
					self.teleportPosTimer = 0
				else
					self.playerInSight = false
				end
			else
				self.playerInSight = false
			end
		end
	else
		self.playerInSight = false
	end

	--Triggers when player is in sight or not
	if (self.playerInSight) then
		self.targetPosition = Player.actor.transform.position
		self.chased = true
		self:TrackPlayer()
	else
		self.targetPosition = self.lastPlayerPos
		self.chased = false
		self.currentState = self.states[4]
	end

	--Triggers if the Nishiki spots the player
	if (self.distanceToPlayer < self.triggerSpotDist) then
		if (self.alreadySaidSpot == false) then
			self.spottedSound.PlayRandom()
			self.alreadySaidSpot = true
		end
		
		if (self.playerCaught == false) then
			self.chaseTheme.SetActive(true)
			self.script.StartCoroutine("TriggerChaseTheme")
		end 
	end

	--Ten years in the joint made you a fucking pussy (Attack)
	if (self.distanceToPlayer <= self.closeDistance and self.alreadyAttacked == false) then
		self.killSound.SetActive(true)
		self:PlayerCaught()
		self.alreadyAttacked = true
	end

	--Making this because Nishiki just get fucking stuck when chasing the player
	if (stuckDist <= 1 or self.currentPos == self.prevPos) then
		self.stuckTimer = self.stuckTimer + 1 * Time.deltaTime
		if (self.stuckTimer > self.stuckTime) then
			self:Unstuck()
			self.prevPos = Vector3.zero
			self.stuckTimer = 0
		end
	else
		self.stuckTimer = 0
	end
end

function IASBY_Nishiki:Search()
	--Restarting the spot voice here lol
	self.alreadySaidSpot = false
	
	--Nishiki will start searching around the nearby area where he last seen the player
	self.searchTimer = self.searchTimer + 1 * Time.deltaTime
	if (self.searchTimer > self.searchTime) then
		self.giveUpSearching = true
		self.lostPlayer = false
		self.currentState = self.states[1]
		self.searchTimer = 0
	end

	--Nishiki will start searching until he gives up
	if (self.giveUpSearching == false) then
		self.searchPointTimer = self.searchPointTimer + 1 * Time.deltaTime
		if (self.searchPointTimer > self.searchPointTime) then
			--Sets new search point
			self:SetSearchPoint()
			self.searchPointTimer = 0
		end
	else
		self.searchPointTimer = 0
	end

	--Vision stuff
	if (self.distanceToPlayer < 40) then
		local focusPoint = Player.actor.GetHumanoidTransformRagdoll(HumanBodyBones.Chest).transform.position
		local visionRay = Physics.Linecast(self.visionPos.position, focusPoint, RaycastTarget.ProjectileHit)
	
		if (visionRay ~= nil) then
			--Confirmation
			local playerInSight = visionRay.collider.gameObject.GetComponentInParent(Actor)
	
			if (playerInSight ~= nil) then
				if (playerInSight.isPlayer) then
					self.currentState = self.states[2]
				end
			end
		end
	end

	--Close chase theme
	if (self.playerCaught == false) then
		self.script.StartCoroutine("CloseChaseTheme")
	end
end

function IASBY_Nishiki:Unstuck()
	--Self explanatory, its Nishiki's unstuck system
	local playerTrans = Player.actor.transform
	local point = Vector3.zero

	if (self.lostPlayer == false) then
		local RandX = Random.Range(-15, 15)
		local RandZ = Random.Range(-15, 15)

		point = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	else
		local RandX = Random.Range(-5, 5)
		local RandZ = Random.Range(-5, 5)

		point = Vector3(self.lastPlayerPos.x + RandX, self.lastPlayerPos.y, self.lastPlayerPos.z + RandZ)
	end

	self.nishikiPos.position = point

	local ray = Ray(self.nishikiPos.position + Vector3.up, Vector3.down)
	local raycastSnap = Physics.RaycastAll(ray, Mathf.Infinity, RaycastTarget.Default)

	for int,hit in pairs(raycastSnap) do
		self.nishikiPos.position = hit.point
		break
	end
end

function IASBY_Nishiki:PlayerCaught()
	--Triggers when the player gets caught
	self.playerCaught = true

	self.chaseTheme.SetActive(false)
	Time.timeScale = 0
	Player.actor.speedMultiplier = 0

	if (self.somethingWicked) then
		self.nishikiPlane.material = self.normalMat
	end

	if (Player.actor.activeWeapon ~= nil) then
		Player.actor.activeWeapon.gameObject.SetActive(false)
	end

	self.crashTimerStart = true
end

function IASBY_Nishiki:RestartVar()
	--Resets variables after losing the player
	self.alreadySaidSpot = false
	self.reachedLastPos = false

	self.alreadySaidSpot = false
	self.chaseTheme.SetActive(false)

	self.searchTimer = 0
	self.searchPointTimer = 0
	self.teleportPosTimer = 0
end

function IASBY_Nishiki:GroundDetect()
	--Teleports Nishiki back on his foot when he fell out of the map
	local ray = Ray(self.nishikiPos.position, -self.nishikiPos.up)
	local groundDetection = Physics.Raycast(ray, Mathf.Infinity, RaycastTarget.Opaque)

	if (groundDetection == nil) then
		self.groundTeleportTimer = self.groundTeleportTimer + 1 * Time.deltaTime
		if (self.groundTeleportTimer > self.groundTeleportTime) then
			self:Spawn()
			self.groundTeleportTimer = 0
		end
	else
		self.groundTeleportTimer = 0
	end
end

function IASBY_Nishiki:SetWalkPoint()
	local RandX = Random.Range(-30, 30)
	local RandZ = Random.Range(-30, 30)

	local point = Vector3(self.nishikiPos.position.x + RandX, self.nishikiPos.position.y, self.nishikiPos.position.z + RandZ)
	self.targetPosition = point
end

function IASBY_Nishiki:SetSearchPoint()
	local playerTrans = Player.actor.transform

	local RandX = Random.Range(-15, 15)
	local RandZ = Random.Range(-15, 15)

	local searchPoint = Vector3(playerTrans.position.x + RandX, playerTrans.position.y, playerTrans.position.z + RandZ)
	self.targetPosition = searchPoint
end

function IASBY_Nishiki:TriggerChaseTheme()
	--Triggers his chase theme
	coroutine.yield(WaitForSeconds(0.85))
	self.chaseAudSrc.volume = Mathf.Lerp(self.chaseAudSrc.volume, 1, Time.deltaTime * 8)
end

function IASBY_Nishiki:LowerChaseVol()
	--Lowers the chase theme volume when out of sight
	coroutine.yield(WaitForSeconds(0.85))
	self.chaseAudSrc.volume = Mathf.Lerp(self.chaseAudSrc.volume, 0.5, Time.deltaTime * 8)
end

function IASBY_Nishiki:CloseChaseTheme()
	--Closes the chase theme
	coroutine.yield(WaitForSeconds(0.85))
	self.chaseAudSrc.volume = Mathf.Lerp(self.chaseAudSrc.volume, 0, Time.deltaTime * 8)
	coroutine.yield(WaitForSeconds(1))
	self.chaseTheme.SetActive(false)
end
