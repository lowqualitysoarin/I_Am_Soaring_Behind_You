behaviour("IASBY_NoteReader")

function IASBY_NoteReader:Start()
	--Base
	self.noteCanvas = self.targets.canvas
	self.noteHolder = self.targets.holder.gameObject.GetComponent(Image)

	--Base
	self.isReading = false
end

function IASBY_NoteReader:Update()
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
	self.noteCanvas.SetActive(true)
	local noteScript = note.gameObject.GetComponent(ScriptedBehaviour).self
	local noteToRead = noteScript.letter

	self.noteHolder.sprite = noteToRead
end

function IASBY_NoteReader:RemoveNote()
	self.noteCanvas.SetActive(false)
end
