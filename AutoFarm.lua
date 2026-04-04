local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Plr = Players.LocalPlayer
local PATH = {
    Mobs = workspace:WaitForChild('NPCs'),
    InteractNPCs = workspace:WaitForChild('ServiceNPCs'),
}

local Config = {
    FarmDistance = 5, 
    MovementType = "tween", 
    FarmType = "Above",
    TweenSpeed = 160,
    M1Speed = 0.05,
    AutoQuest = true,
    SelectedMob = {["Thief"] = true},
}

local Remotes = {
    M1 = RS:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"),
    QuestAccept = RS:WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"),
    QuestAbandon = RS:WaitForChild("RemoteEvents"):WaitForChild("QuestAbandon"),
}

local Modules = {
    Quests = require(RS.Modules.QuestConfig),
}

local Shared = {
    Target = nil,
    QuestNPC = "",
    LastM1 = 0,
}

local function IsValidTarget(npc)
    if not npc or not npc.Parent then return false end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and npc:FindFirstChild("HumanoidRootPart")
end

local function GetBestMobCluster(mobNamesDictionary)
    for _, npc in pairs(PATH.Mobs:GetChildren()) do
        local cleanName = npc.Name:gsub("%d+$", "")
        if mobNamesDictionary[cleanName] and IsValidTarget(npc) then
            return npc
        end
    end
    return nil
end

local function GetBestQuestNPC()
    local playerLevel = Plr.Data.Level.Value
    local bestNPC = "QuestNPC1"
    local highestLevel = -1
    for npcId, questData in pairs(Modules.Quests.RepeatableQuests) do
        local reqLevel = questData.recommendedLevel or 0
        if playerLevel >= reqLevel and reqLevel > highestLevel then
            highestLevel = reqLevel
            bestNPC = npcId
        end
    end
    return bestNPC
end

local function UpdateQuest()
    local targetNPC = GetBestQuestNPC()
    local questUI = Plr.PlayerGui.QuestUI.Quest
    if Shared.QuestNPC ~= targetNPC or not questUI.Visible then
        Remotes.QuestAbandon:FireServer("repeatable")
        task.wait(0.2)
        Remotes.QuestAccept:FireServer(targetNPC)
        Shared.QuestNPC = targetNPC
    end
end

local function AttackLogic(target)
    local char = Plr.Character
    if not target or not char then return end

    local tool = char:FindFirstChildOfClass("Tool") or Plr.Backpack:FindFirstChildOfClass("Tool")
    if tool and tool.Parent == Plr.Backpack then
        tool.Parent = char
    end

    if tick() - Shared.LastM1 >= Config.M1Speed then
        Remotes.M1:FireServer(target.HumanoidRootPart.Position)
        Shared.LastM1 = tick()
    end
end

local function ExecuteFarmMovement(target)
    local char = Plr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not target then return end

    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end

    local targetPivot = target:GetPivot()
    local targetPos = targetPivot.Position
    local finalPos
    
    if Config.FarmType == "Above" then
        finalPos = targetPos + Vector3.new(0, Config.FarmDistance, 0)
    elseif Config.FarmType == "Below" then
        finalPos = targetPos + Vector3.new(0, -Config.FarmDistance, 0)
    else 
        finalPos = (targetPivot * CFrame.new(0, 0, Config.FarmDistance)).Position
    end

    local finalDestination = CFrame.lookAt(finalPos, targetPos)

    if Config.MovementType == "Teleport" then
        root.CFrame = finalDestination
    else
        local distance = (root.Position - finalPos).Magnitude
        TS:Create(root, TweenInfo.new(distance/Config.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = finalDestination}):Play()
    end
    
    root.AssemblyLinearVelocity = Vector3.zero
end

task.spawn(function()
    while task.wait() do
        local char = Plr.Character
        if not char then continue end

        local target = nil
        if Config.AutoQuest then
            UpdateQuest()
            local questData = Modules.Quests.RepeatableQuests[Shared.QuestNPC]
            if questData then
                target = GetBestMobCluster({[questData.requirements[1].npcType] = true})
            end
        else
            target = GetBestMobCluster(Config.SelectedMob)
        end

        if target then
            Shared.Target = target
            ExecuteFarmMovement(target)
            AttackLogic(target)
        else
            Shared.Target = nil
        end
    end
end)
