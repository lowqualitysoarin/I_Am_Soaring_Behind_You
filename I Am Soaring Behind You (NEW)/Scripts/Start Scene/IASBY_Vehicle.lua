behaviour("IASBY_Vehicle")

function IASBY_Vehicle:Start()
    --Identifier
    self.thisIsACar = true

    --Base
    vehicleFeatures = self.targets.vehFeatures.gameObject.GetComponent(IASBY_VehicleMainFeatures)

    self.allowedToLeave = false
    self.playerInRange = false

    self.playerLookingAtVehicle = false
    self.alreadyTriggeredSub = false

    --Alternative Ending
    self.altEnding = false
    self.altPlayerInRange = false
    self.altAlreadyCalled = false

    --Friend Ending
    self.friendEnding = false

    --Endings Essentials
    self.callEndingAlt = false
    self.callEndingFriend = false
    self.activeEndings = false

    --HUD
    self.textSub = self.targets.subtitle.gameObject.GetComponent(Text)
    self.textSub.CrossFadeAlpha(0, 0, true)
    self.textSub.text = ""

    self.notAllowedToLeave = "I'm not allowed to leave yet. But I could use my car to traverse this area..."
end

function IASBY_Vehicle:Update()
    if (self.activeEndings) then
        if (self.allowedToLeave) then
            local actorInRange = (self.transform.position - Player.actor.transform.position).magnitude

            if (actorInRange < 7.5) then
                self.altPlayerInRange = true
            else
                self.altPlayerInRange = false
            end
    
            if (self.altPlayerInRange) then
                if (self.altAlreadyCalled == false) then
                    self:Leave()
                    self.altAlreadyCalled = true
                end
            end
        end
    end

    local actorInRange = ActorManager.AliveActorsInRange(self.gameObject.transform.position, 3.5)

    for k,v in pairs(actorInRange) do
        if (v.isPlayer) then
            self.playerInRange = true
        else
            self.playerInRange = false
        end
    end

    if (self.playerInRange) then
        if (vehicleFeatures.playerInside) then
            if (self.allowedToLeave) then
                self:Leave()
            else
                if (self.alreadyTriggeredSub == false) then
                    self:TriggerSub()
                    self.alreadyTriggeredSub = true
                end
            end
        end
    end

    --Debugging
    if (Input.GetKeyDown(KeyCode.P)) then
        --self.activeEndings = true
        
        --self.friendEnding = true
        --self.altEnding = true

        --self.allowedToLeave = true
    end
end

function IASBY_Vehicle:Leave()
    local hudScript = GameObject.Find("IASBY_HUD_Base").gameObject.GetComponent(ScriptedBehaviour).self
    local mainScript = GameObject.Find("IASBY_MG").gameObject.GetComponentInParent(ScriptedBehaviour).self

    mainScript.timerStart = false
    hudScript:CloseObjText()
    hudScript.forceClose = true

    if (self.altEnding) then
        mainScript:AltEnding()
    elseif (self.friendEnding) then
        mainScript:FriendEnding()
    else
        mainScript:LevelFinished()
        vehicleFeatures:DisableEngine()
    end
end

function IASBY_Vehicle:AltEndings()
    if (self.callEndingAlt and self.friendEnding == false) then
        self.altEnding = true
        --print("Akira Nishikiyama Ending")
    elseif (self.callEndingFriend and self.altEnding == false) then
        self.friendEnding = true
        --print("Friend Ending")
    end

    self.activeEndings = true
end

function IASBY_Vehicle:TriggerSub()
    self.textSub.text = self.notAllowedToLeave
    self.textSub.CrossFadeAlpha(1, 0.7, false)
    self.script.StartCoroutine("CloseSub")
end

function IASBY_Vehicle:CloseSub()
    coroutine.yield(WaitForSeconds(1.8))
    self.textSub.CrossFadeAlpha(0, 0.7, false)
end

