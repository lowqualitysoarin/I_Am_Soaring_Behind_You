behaviour("IASBY_MainMenu")

function IASBY_MainMenu:Start()
	--Base
	iasby = nil

	self.theGame = self.targets.iasby
	self.fade = self.targets.fade.gameObject.GetComponent(Image)
	self.mainMenu = self.targets.mainMenu
	self.emptyObject = self.targets.null

	self.mainMenuFade = self.mainMenu.gameObject.GetComponent(CanvasGroup)

	--Audio
	self.mainTheme = self.targets.musicAudSrc.gameObject.GetComponent(AudioSource)

	--Interactables
	self.playButton = self.targets.playButton.gameObject.GetComponent(Button)
	self.crashCheck = self.targets.crashToggle.gameObject.GetComponent(Toggle)
	self.shotInTheFog = self.targets.shotInTheFog.gameObject.GetComponent(Toggle)
	self.somethingWicked = self.targets.shotInTheDark.gameObject.GetComponent(Toggle)
	self.fakeJordans = self.targets.fakeJordans.gameObject.GetComponent(Toggle)

	--Listeners
	self.playButton.onClick.AddListener(self, "PlayGame")

	--Finishing Touches
	self.fade.CrossFadeAlpha(0, 0, true)
	self.mainMenuFade.alpha = 0
	self.fade.gameObject.SetActive(false)

	--Bools
	self.alreadySpawned = false
	self.inMainMenu = true
	self.fadeMusic = false

	--Disable Spawn UI
	SpawnUi.SetLoadoutVisible(false)
	SpawnUi.SetMinimapVisible(false)
	SpawnUi.SetLoadoutOverride(self.emptyObject)
	SpawnUi.SetMinimapOverride(self.emptyObject)
	SpawnUi.playerCanSelectSpawnPoint = false
	GameObject.Destroy(GameObject.Find("Background Panel"))

	Screen.UnlockCursor()

	self.fadeInMenu = true
end

function IASBY_MainMenu:PlayGame()
	self.inMainMenu = false
	self.fadeMusic = true
	Screen.LockCursor()
	SpawnUi.Close()
	self.fade.gameObject.SetActive(true)
	self.fade.CrossFadeAlpha(1, 0.9, false)
	self.script.StartCoroutine("StartGame")
end

function IASBY_MainMenu:StartGame()
	coroutine.yield(WaitForSeconds(2.5))
	if (self.alreadySpawned == false) then
		local pointToSpawn = ActorManager.spawnPoints[math.random(#ActorManager.spawnPoints)]
		Player.actor.SpawnAt(pointToSpawn.spawnPosition)
		Screen.LockCursor()

		Player.actor.RemoveWeapon(0)
		Player.actor.RemoveWeapon(1)
		Player.actor.RemoveWeapon(2)
		Player.actor.RemoveWeapon(3)
		Player.actor.RemoveWeapon(4)

		self.mainMenu.SetActive(false)
		self.fade.gameObject.SetActive(false)

		self.theGame.SetActive(true)
		self.alreadySpawned = true
	end
end

function IASBY_MainMenu:Update()
	if (self.fadeMusic) then
		self.mainTheme.volume = Mathf.Lerp(self.mainTheme.volume, 0, Time.deltaTime * 9)
	end

	if (self.fadeInMenu) then
		self.mainMenuFade.alpha = Mathf.Lerp(self.mainMenuFade.alpha, 1, Time.deltaTime * 0.9)
	end

	if (self.alreadySpawned) then
		iasby = self.theGame.gameObject.GetComponent(ScriptedBehaviour).self

		if (self.crashCheck.isOn) then
			iasby.allowCrash = true
		else
			iasby.allowCrash = false
		end

		if (self.shotInTheFog.isOn) then
			iasby.foggyMode = true
		else
			iasby.foggyMode = false
		end

		if (self.somethingWicked.isOn) then
			iasby.darkMode = true
		else
			iasby.darkMode = false
		end

		if (self.fakeJordans.isOn) then
			iasby.fakeJordans = true
		else
			iasby.fakeJordans = false
		end
	end

	PlayerHud.hudGameModeEnabled = false
	PlayerHud.hudPlayerEnabled = false
	PlayerHud.killCameraEnabled = false
end