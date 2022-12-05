behaviour("IASBY_Notes")

function IASBY_Notes:Start()
	--Base
	self.thisIsANote = true

	self.data = self.gameObject.GetComponent(DataContainer)
	self.letter = self.data.GetSprite("note")

	self.isSoarinNote = self.data.GetBool("soarinNote")
	self.isNishikiNote = self.data.GetBool("nishikiNote")
	self.isSafeNote = self.data.GetBool("safeNote")
	self.isKeyNote = self.data.GetBool("keyNote")
end
