behaviour("IASBY_DiaryButton")

function IASBY_DiaryButton:Start()
	--Base
	noteReader = self.targets.noteReader.gameObject.GetComponent(IASBY_NoteReader)

	--Buttons
	self.basicContButton = self.targets.controlsButton.gameObject.GetComponent(Button)
	self.vehicleButton = self.targets.vehicleButton.gameObject.GetComponent(Button)
	self.vehicleMulfuncButton = self.targets.malfuncButton.gameObject.GetComponent(Button)
	self.soarinButton = self.targets.soarinButton.gameObject.GetComponent(Button)
	self.nishikiButton = self.targets.nishikiButton.gameObject.GetComponent(Button)
	self.keyButton = self.targets.keyButton.gameObject.GetComponent(Button)
	self.pieButton =self.targets.pieButton.gameObject.GetComponent(Button)

	--Diary
	self.controlsDiary = self.targets.controlsDiary
	self.vehicleDiary = self.targets.vehicleDiary
	self.malfunctionsDiary = self.targets.malfunctionsDiary
	self.soarinDiary = self.targets.soarinDiary
	self.nishikiDiary = self.targets.nishikiDiary
	self.keyDiary = self.targets.keyDiary
	self.pieDiary = self.targets.pieDiary

	--Listeners
	self.basicContButton.onClick.AddListener(self, "BasicControls")
	self.vehicleButton.onClick.AddListener(self, "Vehicle")
	self.vehicleMulfuncButton.onClick.AddListener(self, "VehicleMalfunctions")
	self.soarinButton.onClick.AddListener(self, "Soarin")
	self.nishikiButton.onClick.AddListener(self, "AkiraNishikiyama")
	self.keyButton.onClick.AddListener(self, "TheKey")
	self.pieButton.onClick.AddListener(self, "ThePie")

	--Finishing touches
	self.soarinButton.gameObject.SetActive(false)
	self.nishikiButton.gameObject.SetActive(false)
	self.keyButton.gameObject.SetActive(false)
	self.pieButton.gameObject.SetActive(false)
end

function IASBY_DiaryButton:Update()
	if (noteReader ~= nil) then
		if (noteReader.soarinDiary) then
			self.soarinButton.gameObject.SetActive(true)
		end

		if (noteReader.nishikiyamaDiary) then
			self.nishikiButton.gameObject.SetActive(true)
		end

		if (noteReader.safeDiary) then
			self.pieButton.gameObject.SetActive(true)
		end

		if (noteReader.keyDiary) then
			self.keyButton.gameObject.SetActive(true)
		end
	end
end

function IASBY_DiaryButton:BasicControls()
	self.controlsDiary.SetActive(true)
	self.vehicleDiary.SetActive(false)
	self.malfunctionsDiary.SetActive(false)
	self.soarinDiary.SetActive(false)
	self.nishikiDiary.SetActive(false)
	self.keyDiary.SetActive(false)
	self.pieDiary.SetActive(false)
end

function IASBY_DiaryButton:Vehicle()
	self.controlsDiary.SetActive(false)
	self.vehicleDiary.SetActive(true)
	self.malfunctionsDiary.SetActive(false)
	self.soarinDiary.SetActive(false)
	self.nishikiDiary.SetActive(false)
	self.keyDiary.SetActive(false)
	self.pieDiary.SetActive(false)
end

function IASBY_DiaryButton:VehicleMalfunctions()
	self.controlsDiary.SetActive(false)
	self.vehicleDiary.SetActive(false)
	self.malfunctionsDiary.SetActive(true)
	self.soarinDiary.SetActive(false)
	self.nishikiDiary.SetActive(false)
	self.keyDiary.SetActive(false)
	self.pieDiary.SetActive(false)
end

function IASBY_DiaryButton:Soarin()
	self.controlsDiary.SetActive(false)
	self.vehicleDiary.SetActive(false)
	self.malfunctionsDiary.SetActive(false)
	self.soarinDiary.SetActive(true)
	self.nishikiDiary.SetActive(false)
	self.keyDiary.SetActive(false)
	self.pieDiary.SetActive(false)
end

function IASBY_DiaryButton:AkiraNishikiyama()
	self.controlsDiary.SetActive(false)
	self.vehicleDiary.SetActive(false)
	self.malfunctionsDiary.SetActive(false)
	self.soarinDiary.SetActive(false)
	self.nishikiDiary.SetActive(true)
	self.keyDiary.SetActive(false)
	self.pieDiary.SetActive(false)
end

function IASBY_DiaryButton:TheKey()
	self.controlsDiary.SetActive(false)
	self.vehicleDiary.SetActive(false)
	self.malfunctionsDiary.SetActive(false)
	self.soarinDiary.SetActive(false)
	self.nishikiDiary.SetActive(false)
	self.keyDiary.SetActive(true)
	self.pieDiary.SetActive(false)
end

function IASBY_DiaryButton:ThePie()
	self.controlsDiary.SetActive(false)
	self.vehicleDiary.SetActive(false)
	self.malfunctionsDiary.SetActive(false)
	self.soarinDiary.SetActive(false)
	self.nishikiDiary.SetActive(false)
	self.keyDiary.SetActive(false)
	self.pieDiary.SetActive(true)
end
