behaviour("IASBY_Notes")

function IASBY_Notes:Start()
	--Base
	self.thisIsANote = true

	self.data = self.gameObject.GetComponent(DataContainer)
	self.letter = self.data.GetSprite("note")
end
