behaviour("IASBY_Map")

function IASBY_Map:Start()
	self.scriptReady = true

	--Base
	self.mapBase = self.targets.mapBase.gameObject.GetComponent(RawImage)
	self.mapTransform = self.targets.mapBase.transform
	self.mapRect = self.mapBase.gameObject.GetComponent(RectTransform).rect

	--Map POI
	self.objMark = self.targets.objectivesDot

	--Render Map
	self.renderedMap = Minimap.Render()
	self.renderMapTexture = Minimap.texture

	self.mapBase.texture = self.renderMapTexture
end

function IASBY_Map:GenerateMapObjectives()
	--I am going insane. Ravenscript is soo broken lmao so I have to reference these again to stop recognizing it as a nil
	self.mapBase = self.targets.mapBase.gameObject.GetComponent(RawImage)
	self.mapTransform = self.targets.mapBase.transform
	self.objMark = self.targets.objectivesDot
	self.mapRect = self.mapBase.gameObject.GetComponent(RectTransform).rect

	--Finds active objectives in scene (I'm doing this because passing tables or values is fucked)
	local foundObjectives = {}

	local satelliteMissions = GameObject.FindObjectsOfType(IASBY_Satellite)
	local guardMissions = GameObject.FindObjectsOfType(IASBY_GuardPoint)
	local supplyMissions = GameObject.FindObjectsOfType(IASBY_SupplyBoxes)

	if (#satelliteMissions > 0) then
		for key,st in pairs(satelliteMissions) do
			foundObjectives[#foundObjectives+1] = st.gameObject.transform.position
		end
	end

	if (#guardMissions > 0) then
		for key,gm in pairs(guardMissions) do
			foundObjectives[#foundObjectives+1] = gm.gameObject.transform.position
		end
	end
	
	if (#supplyMissions > 0) then
		for key,sb in pairs(supplyMissions) do
			foundObjectives[#foundObjectives+1] = sb.gameObject.transform.position
		end
	end

	print(#foundObjectives)

	--Start tagging objectives on map
	for _,objectivePos in pairs(foundObjectives) do
		local mapOffset = Vector3(self.mapRect.size.x / 2, self.mapRect.size.y / 2, 0)
		local normalizedPos = Minimap.camera.WorldToViewportPoint(objectivePos)
		local finalPos = Vector3(-normalizedPos.x * self.mapRect.size.x, -normalizedPos.y * self.mapRect.size.y, 0)

		local objDot = GameObject.Instantiate(self.objMark, self.mapTransform)
		objDot.transform.localPosition = Vector3(finalPos.x + mapOffset.x, finalPos.y + mapOffset.y, 0)
		objDot.transform.localScale = Vector3(0.1, 0.1, 0.1)
	end
end