behaviour("ACWS_IASBY")

function ACWS_IASBY:Start()
	--Base
	self.data = self.gameObject.GetComponent(DataContainer)

	self.allowCrash = false
	self.foggyMode = false
	self.darkMode = false
	self.fakeJordans = false

	--Enemies
	self.soar = self.targets.soar
	self.nishiki = self.targets.nishiki

	--Materials
	self.darkSkybox = self.data.GetMaterial("somethingwicked_skybox")

	--Bools
	self.alreadySetFog = false
	self.alreadySetDark = false

	self.alreadySetSoarMat = false
	self.alreadySetNishikiMat = false
	self.alreadySetJordans = false
	self.fakeJordansActive = false
	self.alreadyChoseNumber = false

	self.playerCaught = false

	--Fake Jordans
	self.chosenNumber1 = nil
	self.chosenNumber2 = nil

	self.playerVel = nil

	--HUD
	self.flashCanvas = self.targets.flashScreen

	hudScript = self.targets.hud.gameObject.GetComponent(ScriptedBehaviour).self
	self.objectivesPanel = self.targets.objectivesPanel.transform
	self.objectiveClone = self.targets.objectiveClone

	self.resultsHud = self.targets.results
	self.resultsBlackFade = self.targets.resFade.gameObject.GetComponent(Image)
	self.resultsEndText = self.targets.endText.gameObject.GetComponent(Text)
	self.resultsTimeText = self.targets.endTime.gameObject.GetComponent(Text)

	self.resultsEndText.text = ""
	self.resultsTimeText.text = ""

	self.resultsBlackFade.CrossFadeAlpha(0, 0, true)
	self.resultsEndText.CrossFadeAlpha(0, 0, true)
	self.resultsTimeText.CrossFadeAlpha(0, 0, true)

	self.showResults = false

	--Player
	playerScript = self.targets.playerScript.gameObject.GetComponent(ScriptedBehaviour).self

	--Sounds
	self.endSfx = self.targets.endSfx

	--Endings
	self.altEnding = self.targets.altEnding --Akira Nishikiyama Ending
	self.friendEnding = self.targets.friendEnding --Friend Ending

	--Warm Up
	local actors = ActorManager.actors

	for k,v in pairs(actors) do
		if (v.isPlayer == false) then
			v.Deactivate()
		end
	end

	local vehicles = ActorManager.VehiclesInRange(Player.actor.transform.position, Mathf.Infinity)

	if (#vehicles > 0) then
		for k,v in pairs(vehicles) do
			GameObject.Destroy(v.gameObject)
		end
	end

	GameEvents.onCapturePointCaptured.AddListener(self, "PointCaptured")

	local resupplyCrates = GameObject.FindObjectsOfType(ResupplyCrate)

	for k,v in pairs(resupplyCrates) do
		GameObject.Destroy(v.gameObject)
	end

	local nvGameObject = GameObject.Find("Default Night Vision Goggles")

	if (nvGameObject ~= nil) then
		nvGameObject.gameObject.SetActive(false)
	end

	--Start Scene
	self.startScene = self.targets.startScene

	--Timer
	self.timerStart = false
	self.timer = 0
	self.currentTime = nil
	self.finalTime = nil

	--Props Assets
	self.workbench = self.targets.workbench.gameObject
	self.cratesRadio = self.targets.radio.gameObject
	self.crateNote = self.targets.crateNote.gameObject
	self.tent = self.targets.tent.gameObject
	self.tentKey = self.targets.tentKey.gameObject
	self.safe = self.targets.safe.gameObject

	--Props Essentials
	self.occupiedPoints = {}

	self.alreadySpawnedWorkbench = false
	self.alreadySpawnedRadio = false
	self.alreadySpawnedCrateNote = false
	self.alreadySpawnedCrates = false
	self.alreadySpawnedTent = false
	self.alreadySpawnedTentKey = false
	self.alreadySpawnedSafe = false

	--Objectives Assets
	self.satellite = self.targets.satellite.gameObject
	self.guardPoint = self.targets.guardPoint.gameObject
	self.supplyBox = self.targets.supplyBox.gameObject

	--Objectives Essentials
	self.objectivesCompleted = 0
	self.maxObjectives = 0
	self.activeObjectives = 0

	self.generateAgain = false

	self.Objectives = {
		"GatherSupplies",
		"GuardPoint",
		"RepairSignal",
		"None"
	}

	self.ObjectivesBackup = {
		"GatherSupplies",
		"GuardPoint",
		"RepairSignal"
	}

	--Goal Manager
	self.goEmpty = self.targets.emptygoClone

	self.currentObjectives = {}
	self.objectiveClones = {}
	self.givenGoalIndex = 1

	--AI Manager
	soarin = nil
	nishiki = nil

	self.objToComplete = 0
	self.lethObjToComplete = 0

	--Crashing
	self.crashTimerStart = false
	self.crashTimer = 0

	--Listeners
	self.playerSpawned = false

	--Start Objectives
	self:SpawnProps()
	self:SpawnObjectives()
end

function ACWS_IASBY:SpawnProps()
	local spawnPoints = ActorManager.spawnPoints

	--Spawned Objects for later
	local workbench = nil
	local radio = nil
	local crateNote = nil
	local tent = nil
	local tentKey = nil
	local safe = nil

	--Spawning
	for  i = 1, 10 do
		local chosenPoint = spawnPoints[math.random(#spawnPoints)]
		local distanceToPlayer = (chosenPoint.spawnPosition - Player.actor.transform.position).magnitude

		--Start Spawning Props if possible
		--Workbench
		if (self.alreadySpawnedWorkbench == false and distanceToPlayer > 5) then
			local randomRot = Random.Range(-100, 100)
			local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))

			workbench = GameObject.Instantiate(self.workbench, chosenPoint.spawnPosition, finalRot)

			--Snapping To Ground
			self:SnapToGround(workbench)

			--Confirmation
			self.alreadySpawnedWorkbench = true
		end

		--Radio
		if (#self.occupiedPoints > 0) then
			local lastItem = self.occupiedPoints[#self.occupiedPoints]

			if ((chosenPoint.spawnPosition - lastItem).magnitude > 30) then
				if (self.alreadySpawnedRadio == false and distanceToPlayer > 40) then
					local randomRot = Random.Range(-100, 100)
					local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
		
					radio = GameObject.Instantiate(self.cratesRadio, chosenPoint.spawnPosition, finalRot)
		
					--Snapping To Ground
					self:SnapToGround(radio)
		
					--Confirmation
					self.alreadySpawnedRadio = true
					self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
				end
			end
		else
			if (self.alreadySpawnedRadio == false and distanceToPlayer > 40) then
				local randomRot = Random.Range(-100, 100)
				local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
	
				radio = GameObject.Instantiate(self.cratesRadio, chosenPoint.spawnPosition, finalRot)
	
				--Snapping To Ground
				self:SnapToGround(radio)
	
				--Confirmation
				self.alreadySpawnedRadio = true
				self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
			end
		end

		--Tent
		if (#self.occupiedPoints > 0) then
			local lastItem = self.occupiedPoints[#self.occupiedPoints]
			
			if ((chosenPoint.spawnPosition - lastItem).magnitude > 30) then
				if (self.alreadySpawnedTent == false and distanceToPlayer > 30) then
					local randomRot = Random.Range(-100, 100)
					local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
		
					tent = GameObject.Instantiate(self.tent, chosenPoint.spawnPosition, finalRot)
		
					--Snapping To Ground
					self:SnapToGround(tent)
		
					--Confirmation
					self.alreadySpawnedTent = true
					self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
				end
			end
		else
			if (self.alreadySpawnedTent == false and distanceToPlayer > 30) then
				local randomRot = Random.Range(-100, 100)
				local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
	
				tent = GameObject.Instantiate(self.tent, chosenPoint.spawnPosition, finalRot)
	
				--Snapping To Ground
				self:SnapToGround(tent)
	
				--Confirmation
				self.alreadySpawnedTent = true
				self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
			end
		end

		--Crate with a note
		if (#self.occupiedPoints > 0) then
			local lastItem = self.occupiedPoints[#self.occupiedPoints]

			if ((chosenPoint.spawnPosition - lastItem).magnitude > 40) then
				if (self.alreadySpawnedCrateNote == false and distanceToPlayer > 50) then
					local randomRot = Random.Range(-100, 100)
					local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
		
					crateNote = GameObject.Instantiate(self.crateNote, chosenPoint.spawnPosition, finalRot)
		
					--Snapping To Ground
					self:SnapToGround(crateNote)
		
					--Confirmation
					self.alreadySpawnedCrateNote = true
					self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
				end
			end
		else
			if (self.alreadySpawnedCrateNote == false and distanceToPlayer > 50) then
				local randomRot = Random.Range(-100, 100)
				local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
	
				crateNote = GameObject.Instantiate(self.crateNote, chosenPoint.spawnPosition, finalRot)
	
				--Snapping To Ground
				self:SnapToGround(crateNote)
	
				--Confirmation
				self.alreadySpawnedCrateNote = true
				self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
			end
		end

		--Tent with a key
		if (#self.occupiedPoints > 0) then
			local lastItem = self.occupiedPoints[#self.occupiedPoints]
			
			if ((chosenPoint.spawnPosition - lastItem).magnitude > 40) then
				if (self.alreadySpawnedTentKey == false and distanceToPlayer > 50 and self.alreadySpawnedCrateNote) then
					local randomRot = Random.Range(-100, 100)
					local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
		
					tentKey = GameObject.Instantiate(self.tentKey, chosenPoint.spawnPosition, finalRot)
		
					--Snapping To Ground
					self:SnapToGround(tentKey)
		
					--Confirmation
					self.alreadySpawnedTentKey = true
					self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
				end
			end
		else
			if (self.alreadySpawnedTentKey == false and distanceToPlayer > 50 and self.alreadySpawnedCrateNote) then
				local randomRot = Random.Range(-100, 100)
				local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
	
				tentKey = GameObject.Instantiate(self.tentKey, chosenPoint.spawnPosition, finalRot)
	
				--Snapping To Ground
				self:SnapToGround(tentKey)
	
				--Confirmation
				self.alreadySpawnedTentKey = true
				self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
			end
		end

		--Safe
		if (#self.occupiedPoints > 0) then
			local lastItem = self.occupiedPoints[#self.occupiedPoints]
			
			if ((chosenPoint.spawnPosition - lastItem).magnitude > 40) then
				if (self.alreadySpawnedSafe == false and distanceToPlayer > 50 and self.alreadySpawnedTentKey) then
					local randomRot = Random.Range(-100, 100)
					local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
		
					safe = GameObject.Instantiate(self.safe, chosenPoint.spawnPosition, finalRot)
		
					--Snapping To Ground
					self:SnapToGround(safe)
		
					--Confirmation
					self.alreadySpawnedSafe = true
					self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
				end
			end
		else
			if (self.alreadySpawnedSafe == false and distanceToPlayer > 50 and self.alreadySpawnedTentKey) then
				local randomRot = Random.Range(-100, 100)
				local finalRot = Quaternion.Euler(Vector3(0, randomRot, 0))
	
				safe = GameObject.Instantiate(self.safe, chosenPoint.spawnPosition, finalRot)
	
				--Snapping To Ground
				self:SnapToGround(safe)
	
				--Confirmation
				self.alreadySpawnedSafe = true
				self.occupiedPoints[#self.occupiedPoints+1] = chosenPoint.spawnPosition
			end
		end
	end

	--Checks
	self:CheckMissingSafe(tentKey, safe)
end

function ACWS_IASBY:CheckMissingSafe(tentKey, safe)
	if (tentKey == nil and safe ~= nil or tentKey ~= nil and safe == nil) then
		if (tentKey ~= nil) then
			GameObject.Destroy(tentKey)
		end

		if (safe ~= nil) then
			GameObject.Destroy(safe)
		end
	end
end

function ACWS_IASBY:SpawnObjectives()
	objScript = nil
	local capturePoints = ActorManager.capturePoints

	for k,v in pairs(capturePoints) do
		local distanceToPlayer = (v.transform.position - Player.actor.transform.position).magnitude
		local chosenObjective = self.Objectives[math.random(#self.Objectives)]
		local chosenObjectiveNew = self.ObjectivesBackup[math.random(#self.ObjectivesBackup)]

		if (distanceToPlayer > 25) then
			local objectiveToSpawn = nil

			if (chosenObjective == "GatherSupplies") then
				objectiveToSpawn = self.supplyBox
				local objectiveText = self.givenGoalIndex .. ") Gather supplies at " .. v.name .. " [Status:In Progress]"
				table.insert(self.currentObjectives, objectiveText)
			elseif (chosenObjective == "GuardPoint") then
				objectiveToSpawn = self.guardPoint
				local objectiveText = self.givenGoalIndex .. ") Check the area at " .. v.name .. " [Status:In Progress]"
				table.insert(self.currentObjectives, objectiveText)
			elseif (chosenObjective == "RepairSignal") then
				objectiveToSpawn = self.satellite
				local objectiveText = self.givenGoalIndex .. ") Repair the satellite at " .. v.name .. " [Status:In Progress]"
				table.insert(self.currentObjectives, objectiveText)
			end
	
			local randomRot = Random.Range(-100, 100)
			local finalRot = Quaternion.Euler(Vector3(0, 0, randomRot))
	
			if (chosenObjective ~= "None") then
				local objectiveSpawned = GameObject.Instantiate(objectiveToSpawn, v.transform.position, Quaternion(finalRot))
				objectiveSpawned.gameObject.name = objectiveSpawned.gameObject.name .. " " .. "ID:" .. self.givenGoalIndex
				objectiveSpawned.transform.localRotation = Quaternion(finalRot)

				self:SnapToGround(objectiveSpawned)
		
				local goalID = GameObject.Instantiate(self.goEmpty, objectiveSpawned.transform)
				goalID.gameObject.name = self.givenGoalIndex .. " " .. "{GOALID_}"
		
				local locationName = GameObject.Instantiate(self.goEmpty, objectiveSpawned.transform)
				locationName.gameObject.name = v.name .. " " .. "{LOCATION_}"
		
				local missionID = GameObject.Instantiate(self.goEmpty, objectiveSpawned.transform)
				missionID.gameObject.name = chosenObjective .. " " .. "{MISSIONTYPE_}"

				self.givenGoalIndex = self.givenGoalIndex + 1
				self.activeObjectives = self.activeObjectives + 1
			elseif (self.activeObjectives == 0 or self.generateAgain) then
				local objectiveToSpawnBackup = nil
			
				if (chosenObjectiveNew == "GatherSupplies") then
					objectiveToSpawnBackup = self.supplyBox
					local objectiveText = self.givenGoalIndex .. ") Gather supplies at " .. v.name .. " [Status:In Progress]"
					table.insert(self.currentObjectives, objectiveText)
				elseif (chosenObjectiveNew == "GuardPoint") then
					objectiveToSpawnBackup = self.guardPoint
					local objectiveText = self.givenGoalIndex .. ") Check the area at " .. v.name .. " [Status:In Progress]"
					table.insert(self.currentObjectives, objectiveText)
				elseif (chosenObjectiveNew == "RepairSignal") then
					objectiveToSpawnBackup = self.satellite
					local objectiveText = self.givenGoalIndex .. ") Repair the satellite at " .. v.name .. " [Status:In Progress]"
					table.insert(self.currentObjectives, objectiveText)
				end
			
				local randomRot = Random.Range(-100, 100)
				local finalRot = Quaternion.Euler(Vector3(0, 0, randomRot))
			
				local objectiveSpawned = GameObject.Instantiate(objectiveToSpawnBackup, v.transform.position, Quaternion(finalRot))
				objectiveSpawned.gameObject.name = objectiveSpawned.gameObject.name .. " " .. "ID:" .. self.givenGoalIndex
				objectiveSpawned.transform.localRotation = Quaternion(finalRot)

				self:SnapToGround(objectiveSpawned)
			
				local goalID = GameObject.Instantiate(self.goEmpty, objectiveSpawned.transform)
				goalID.gameObject.name = self.givenGoalIndex .. " " .. "{GOALID_}"
			
				local locationName = GameObject.Instantiate(self.goEmpty, objectiveSpawned.transform)
				locationName.gameObject.name = v.name .. " " .. "{LOCATION_}"
			
				local missionID = GameObject.Instantiate(self.goEmpty, objectiveSpawned.transform)
				missionID.gameObject.name = chosenObjectiveNew .. " " .. "{MISSIONTYPE_}"
			
				self.givenGoalIndex = self.givenGoalIndex + 1
				self.activeObjectives = self.activeObjectives + 1

				if (self.activeObjectives == #capturePoints) then
					self.generateAgain = false
				else
					self.generateAgain = true
				end
			end
		end 

		v.gameObject.SetActive(false)
	end

	for k,v in pairs(self.currentObjectives) do
		local objective = GameObject.Instantiate(self.objectiveClone, self.objectivesPanel)
		local textComponent = objective.gameObject.GetComponent(Text)

		textComponent.text = v
		table.insert(self.objectiveClones, objective.gameObject)
	end

	if (#capturePoints <= 4) then
		self.objToComplete = 1
		self.lethObjToComplete = 1
	elseif (#capturePoints >= 5 and #capturePoints <= 9) then
		self.objToComplete = 1
		self.lethObjToComplete = 2
	elseif (#capturePoints >= 10) then 
		self.objToComplete = 2
		self.lethObjToComplete = 5
	end

	self.maxObjectives = self.activeObjectives
	self.timerStart = true
end

function ACWS_IASBY:SnapToGround(object)
	if (object ~= nil) then
		local ray = Ray(object.transform.position + Vector3.up, Vector3.down)
		local raycastSnap = Physics.RaycastAll(ray, Mathf.Infinity, RaycastTarget.Default)

		for int,hit in pairs(raycastSnap) do
			object.transform.position = hit.point
			break
		end
	end
end

function ACWS_IASBY:CrashGame()
	self.flashCanvas.SetActive(true)
	Time.timeScale = 0
	Player.actor.speedMultiplier = 0

	if (self.allowCrash) then
		self.crashTimerStart = true
	end
end

function ACWS_IASBY:ObjectiveCompleted(obj)
	--I'm doing this because RF's passing/receiving values by script is fucked..
	local FindMainGameObject = GameObject.Find(obj.gameObject.name)

	local getGoalIndex = FindMainGameObject.transform.GetChild(2)
	local getLocation = FindMainGameObject.transform.GetChild(3)
	local getMissionType = FindMainGameObject.transform.GetChild(4)

	--Finishing Touches
	local finalGoalIndex = tonumber(string.gsub(getGoalIndex.gameObject.name, "{GOALID_}", ""), 10)
	local finalLocation = string.gsub(getLocation.gameObject.name, "{LOCATION_}", "")
	local finalMissionType = string.gsub(getMissionType.gameObject.name, "{MISSIONTYPE_}", "")
	local finalizedMissionType = string.gsub(finalMissionType, "%s+", "")

	local newLine = nil
	if (finalizedMissionType == "GatherSupplies") then
		newLine = finalGoalIndex .. ") Gather supplies at " .. finalLocation .. "[Status:Completed]"
	elseif (finalizedMissionType == "GuardPoint") then 
		newLine = finalGoalIndex .. ") Check the area at " .. finalLocation .. "[Status:Completed]"
	elseif (finalizedMissionType == "RepairSignal") then 
		newLine = finalGoalIndex .. ") Repair the satellite at " .. finalLocation .. "[Status:Completed]"
	end

	local objectiveToComplete = self.objectiveClones[finalGoalIndex].gameObject.GetComponent(Text)
	objectiveToComplete.text = newLine

	self.objectivesCompleted = self.objectivesCompleted + 1
	--print(self.objectivesCompleted .. "/" .. self.maxObjectives)

	--AI Trigger
	if (self.objectivesCompleted >= self.objToComplete) then
		self.soar.SetActive(true)
		self.nishiki.SetActive(true)
		soarin = self.soar.gameObject.GetComponent(IASBY_SoarAI)
		nishiki = self.nishiki.gameObject.GetComponent(IASBY_Nishiki)
	end

	if (self.objectivesCompleted >= self.lethObjToComplete) then
		soarin.startStates = true
	end

	--All Objectives Completed
	if (self.objectivesCompleted >= self.maxObjectives) then
		hudScript:TriggerObjText()
		local exitPoint = GameObject.Find("startingPivot(Clone)").gameObject.transform.GetChild(0).gameObject.GetComponent(ScriptedBehaviour).self
		
		if (exitPoint ~= nil) then
			exitPoint.allowedToLeave = true
		end

		soarin.enragedStates = true
	end
end

function ACWS_IASBY:PointCaptured()
	local vehicles = ActorManager.VehiclesInRange(Player.actor.transform.position, Mathf.Infinity)

	if (#vehicles > 0) then
		for k,v in pairs(vehicles) do
			GameObject.Destroy(v.gameObject)
		end
	end
end

function ACWS_IASBY:Update()
	--Player Stuffs
	if (self.playerSpawned) then
		self.playerVel = Player.actor.velocity.magnitude
	end

	--Stuffs
	if (Player.actor.isDead == false and self.playerSpawned == false) then
		self:CloneStartScene()
		self.playerSpawned = true
	end

	if (self.playerSpawned and Player.actor.isDead) then
		self:CrashGame()
	end

	if (self.crashTimerStart) then
		self.crashTimer = self.crashTimer + 1 * Time.unscaledDeltaTime
		if (self.crashTimer > 0.5) then
			while (Player.actor.isDead == false) do end
		end
	end

	if (self.timerStart) then
		self.timer = self.timer + 1 * Time.deltaTime
		self:Timer(self.timer)
	end

	if (soarin ~= nil or nishiki ~= nil) then
		local activeAI = soarin or nishiki

		if (activeAI ~= nil) then
			if (activeAI.playerCaught) then
				self.playerCaught = true
			else
				self.playerCaught = false
			end
		end
	end

	--Start Challenges
	if (self.foggyMode and self.alreadySetFog == false) then
		self:EnableFog()
		self.alreadySetFog = true
	end

	if (self.darkMode and self.alreadySetDark == false) then
		self:Darken()
		self.alreadySetDark = true
	end

	if (self.darkMode) then
		if (soarin ~= nil) then
			if (soarin.aiReady and self.alreadySetSoarMat == false) then
				soarin:SomethingWickedActive()
				self.alreadySetSoarMat = true
			end
		end

		if (nishiki ~= nil and self.alreadySetNishikiMat == false) then
			if (nishiki.aiReady) then
				nishiki:SomethingWickedActive()
				self.alreadySetNishikiMat = true
			end
		end
	end

	if (self.fakeJordans and self.alreadySetJordans == false) then
		self:FakeJordans()
		self.alreadySetJordans = true
	end

	--Debugging
	if (Input.GetKeyDown(KeyCode.P)) then
		--self.nishiki.SetActive(true)
		--self.soar.SetActive(true)
		--self:FriendEnding()
		--self:AltEnding()

		--[[local ray = Ray(PlayerCamera.activeCamera.transform.position, PlayerCamera.activeCamera.transform.forward)
		local rayPoint = Physics.Raycast(ray, Mathf.Infinity, RaycastTarget.ProjectileHit)

		if (rayPoint ~= nil) then
			GameObject.Instantiate(self.workbench, rayPoint.point, Quaternion.identity)
		end]]

		--[[local ray = Ray(PlayerCamera.activeCamera.transform.position, PlayerCamera.activeCamera.transform.forward)
		local rayPoint = Physics.Raycast(ray, Mathf.Infinity, RaycastTarget.ProjectileHit)

		if (rayPoint ~= nil) then
			self.nishiki.SetActive(true)
			self.nishiki.transform.position = rayPoint.point
		end]]
	end

	if (Input.GetKeyDown(KeyCode.K)) then
		--[[local ray = Ray(PlayerCamera.activeCamera.transform.position, PlayerCamera.activeCamera.transform.forward)
		local rayPoint = Physics.Raycast(ray, Mathf.Infinity, RaycastTarget.ProjectileHit)

		if (rayPoint ~= nil) then
			self.nishiki.SetActive(true)
			self.nishiki.transform.position = rayPoint.point
		end]]
	end
end

function ACWS_IASBY:LateUpdate()
	if (self.fakeJordansActive) then
		local chance1 = math.random(0, 35)
		local chance2 = math.random(0, 35)

		if (self.alreadyChoseNumber == false) then
			self.chosenNumber1 = math.random(0, 35)
			self.chosenNumber2 = math.random(0, 35)
			self.alreadyChoseNumber = true
		end

		if (self.alreadyChoseNumber) then
			if (Player.actor.isFallenOver == false) then
				if (self.playerVel ~= 0) then
					if (self.chosenNumber1 == chance1 and self.chosenNumber2 == chance2) then
						Player.actor.KnockOver(Player.actor.transform.forward)
						self.alreadyChoseNumber = false
					end
				end
			end
		end
	end
end

function ACWS_IASBY:Timer(time)
	local minutes = Mathf.FloorToInt(time / 60)
	local seconds = Mathf.FloorToInt(time % 60)

	if (seconds < 10) then
		self.currentTime = string.format("%d:0%d", minutes, seconds)
	else
		self.currentTime = string.format("%d:%d", minutes, seconds)
	end

	self.finalTime = self.currentTime
end

function ACWS_IASBY:CloneStartScene()
	GameObject.Instantiate(self.startScene.gameObject, Player.actor.transform.position, Quaternion.identity)
end

function ACWS_IASBY:LevelFinished()
	self.soar.SetActive(false)
	self.nishiki.SetActive(false)

	self.resultsHud.SetActive(true)
	self.resultsBlackFade.CrossFadeAlpha(1, 0.3, false)

	self.resultsEndText.text = "Normal Ending"
	self.resultsTimeText.text = "Objectives Finished in " .. self.finalTime

	Player.actor.speedMultiplier = 0
	self.script.StartCoroutine("PlaySounds")
	self.script.StartCoroutine("TriggerResults")
end

function ACWS_IASBY:PlaySounds()
	coroutine.yield(WaitForSeconds(0.1))
	self.endSfx.SetActive(true)
end

function ACWS_IASBY:TriggerResults()
	coroutine.yield(WaitForSeconds(1.9))
	self.resultsEndText.CrossFadeAlpha(1, 0.4, false)
	coroutine.yield(WaitForSeconds(1.5))
	self.resultsTimeText.CrossFadeAlpha(1, 0.6, false)
end

function ACWS_IASBY:AltEnding()
	self.soar.SetActive(false)
	self.nishiki.SetActive(false)

	self.altEnding.transform.position = Player.actor.transform.position
	self.altEnding.transform.localRotation = Player.actor.transform.rotation

	self.altEnding.SetActive(true)
end

function ACWS_IASBY:AltEndingFinished()
	self.resultsHud.SetActive(true)
	self.resultsBlackFade.CrossFadeAlpha(1, 0.3, false)

	self.resultsEndText.text = "Akira Nishikiyama Ending"
	self.resultsTimeText.text = "Objectives Finished in " .. self.finalTime

	self.script.StartCoroutine("TriggerResults")
end

function ACWS_IASBY:FriendEnding()
	self.soar.SetActive(false)
	self.nishiki.SetActive(false)

	self.friendEnding.transform.position = Player.actor.transform.position
	self.friendEnding.transform.localRotation = Player.actor.transform.rotation

	self.friendEnding.SetActive(true)
end

function ACWS_IASBY:FriendEndingFinished()
	self.resultsHud.SetActive(true)
	self.resultsBlackFade.CrossFadeAlpha(1, 0.3, false)

	self.resultsEndText.text = "Friend Ending"
	self.resultsTimeText.text = "Objectives Finished in " .. self.finalTime

	self.script.StartCoroutine("TriggerResults")
end

function ACWS_IASBY:EnableFog()
	RenderSettings.fog = true
	RenderSettings.fogDensity = 0.15
	RenderSettings.fogStartDistance = 100
	RenderSettings.fogEndDistance = 100
end

function ACWS_IASBY:Darken()
	--Finds light sources then destroys it
	local foundLightSources = GameObject.FindObjectsOfType(Light)
	
	for k,v in pairs(foundLightSources) do
		GameObject.Destroy(v)
	end

	--Skybox
	RenderSettings.skybox = self.darkSkybox

	--Fog
	RenderSettings.fogColor = Color.black

	--Ambient Colors and Lights
	RenderSettings.ambientEquatorColor = Color.black
	RenderSettings.ambientGroundColor = Color.black
	RenderSettings.ambientSkyColor = Color.black
	RenderSettings.ambientLight = Color.black
	RenderSettings.ambientIntensity = 0.01

	--Reflections
	RenderSettings.reflectionIntensity = 0
	RenderSettings.reflectionBounces = 0
	RenderSettings.defaultReflectionResolution = 0

	--Lights Halos
	RenderSettings.haloStrength = 0
end

function ACWS_IASBY:FakeJordans()
	playerScript.forcedOff = true

	if (self.playerCaught == false) then
		Player.actor.speedMultiplier = 0.85
	end

	self.fakeJordansActive = true
end