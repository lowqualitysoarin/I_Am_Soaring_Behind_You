behaviour("IASBY_NoteReader")

function IASBY_NoteReader:Start()
	--Base
	self.noteCanvas = self.targets.canvas
	self.diary = self.targets.diaryMain
	self.noteHolder = self.targets.holder.gameObject.GetComponent(Image)

	--Progresses
	self.soarinDiary = false
	self.nishikiyamaDiary = false
	self.safeDiary = false
	self.keyDiary = false

	--Base
	self.isReading = false
	self.diaryOpen = false
end

function IASBY_NoteReader:Update()
	--Note Reader
	self:NoteReader()

	--Diary
	self:Diary()
end

function IASBY_NoteReader:Diary()
	if (Input.GetKeyBindButtonDown(KeyBinds.ThirdPersonToggle)) then
		self.diaryOpen = not self.diaryOpen

		if (self.diaryOpen) then
			Screen.UnlockCursor()
			self.diary.SetActive(true)
		else
			Screen.LockCursor()
			self.diary.SetActive(false)
		end
	end
end

function IASBY_NoteReader:NoteReader()
	local ray = PlayerCamera.activeCamera.ViewportPointToRay(Vector3(0.5, 0.5, 0))
	local noteCast = Physics.Raycast(ray, 2, RaycastTarget.ProjectileHit)

	if (noteCast ~= nil) then
		if (noteCast.collider.gameObject.GetComponent(ScriptedBehaviour) ~= nil) then
			local getScript = noteCast.collider.gameObject.GetComponent(ScriptedBehaviour).self

			if (getScript.thisIsANote ~= nil) then
				--print("its a note")

				if (Input.GetKeyBindButtonDown(KeyBinds.Use)) then
					self.isReading = not self.isReading

					if (self.isReading) then
						self:ReadNote(noteCast.collider.gameObject)
					else
						self:RemoveNote()
					end
				end
			else
				self:RemoveNote()
			end
		else
			self:RemoveNote()
		end
	else
		self:RemoveNote()
	end
end

function IASBY_NoteReader:ReadNote(note)
	--Read the note
	self.noteCanvas.SetActive(true)
	local noteScript = note.gameObject.GetComponent(IASBY_Notes)
	local noteToRead = noteScript.letter

	self.noteHolder.sprite = noteToRead

	--Checks the note topic
	self.soarinDiary = noteScript.isSoarinNote
	self.nishikiyamaDiary = noteScript.isNishikiNote
	self.safeDiary = noteScript.isSafeNote
	self.keyDiary = noteScript.isKeyNote
end

function IASBY_NoteReader:RemoveNote()
	self.noteCanvas.SetActive(false)
end