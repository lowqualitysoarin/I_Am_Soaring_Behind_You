behaviour("IASBY_HUDmain")

function IASBY_HUDmain:Start()
	self:DisableDefaultHUD()

	--Base
	self.mainCanvas = self.targets.mainCanvas
	self.objectivesList = self.targets.objectivesList.gameObject.GetComponent(Text)
	self.objectivesPanel = self.targets.objPanel

	self.objText = self.targets.objText.gameObject.GetComponent(Text)

	--Deactivating
	self.objectivesList.text = ""
	self.objText.text = "Objectives Complete, return to your Vehicle."

	self.objText.gameObject.SetActive(false)
	self.objectivesPanel.SetActive(false)
	self.objPanelOpen = false

	--Bools
	self.forceClose = false
	self.hudEnabled = true
end

function IASBY_HUDmain:DisableDefaultHUD()
	GameObject.Find("Ingame UI Container(Clone)").Find("Ingame UI/Panel").gameObject.GetComponent(Image).color = Color(0,0,0,0)
	GameObject.Find("Current Ammo Text").gameObject.SetActive(false)
	GameObject.Find("Spare Ammo Text").gameObject.SetActive(false)
	GameObject.Find("Vehicle Health Background").gameObject.SetActive(false)
	GameObject.Find("Resupply Health").gameObject.SetActive(false)
	GameObject.Find("Resupply Ammo").gameObject.SetActive(false)
	GameObject.Find("Squad Text").gameObject.GetComponent(Text).color = Color(0,0,0,0)
	GameObject.Find("Sight Text").gameObject.SetActive(false)
	GameObject.Find("Weapon Image").gameObject.SetActive(false)
	GameObject.Find("Health Text").gameObject.transform.parent.gameObject.SetActive(false)
end

function IASBY_HUDmain:Update()
	if (Input.GetKeyDown(KeyCode.L)) then
		self.objPanelOpen = not self.objPanelOpen

		if (self.objPanelOpen) then
			self.objectivesPanel.SetActive(true)
		else
			self.objectivesPanel.SetActive(false)
		end
	end

	if (Input.GetKeyDown(KeyCode.O)) then
		self.hudEnabled = not self.hudEnabled

		if (self.hudEnabled) then
			self.mainCanvas.SetActive(true)
		else
			self.mainCanvas.SetActive(false)
		end
	end

	if (self.forceClose) then
		self.mainCanvas.SetActive(false)
	end
end

function IASBY_HUDmain:TriggerObjText()
	self.objText.gameObject.SetActive(true)
end

function IASBY_HUDmain:CloseObjText()
	self.objText.gameObject.SetActive(false)
end
