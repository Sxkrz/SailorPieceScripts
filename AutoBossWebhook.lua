local Tweener = loadstring(game:HttpGet("https://raw.githubusercontent.com/raimlworks1-art/Rai-/refs/heads/main/Tweener.lua"))()

local SPAutoBoss_Config = {
    Item = _G.Item or Item or "True Manipulator",
    Target = _G.Target or Target or "StrongestShinobi",
    Move = _G.Move or Move or 3,
    Webhook  = _G.Webhook or Webhook or "https://discord.com/api/webhooks/",
} 

local Player = game:GetService("Players").LocalPlayer

local payload = {
    content = "@everyone",
    embeds = {
        {
            title       = "Sailor Piece Boss Notify!",
            color       = 15794175,
            fields      = {
                {
                    name   = "💀 Target Boss",
                    value  = "```"..SPAutoBoss_Config.Target.."```",
                    inline = false,
                },
                {
                    name   = "⚔️ Using Weapon",
                    value  = "```"..SPAutoBoss_Config.Item.."```",
                    inline = false,
                },
            },
            footer = {
                text = "Time Killed at "..os.date("%m-%d-%Y %H:%M:%S")
            }
        }
    }
}

local function ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local servers = {}
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local response = game:HttpGet(url)
    local data = game:GetService("HttpService"):JSONDecode(response)
    for _, server in ipairs(data.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            table.insert(servers, server.id)
        end
    end
    if #servers > 0 then
        local picked = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(game.PlaceId, picked, Player)
    else
        warn("No servers found")
    end
end

local function Find(boss)
    local BossFolder = game:GetService("Workspace").NPCs
    for _, v in ipairs(BossFolder:GetChildren()) do
        if v.Name:find(tostring(boss) .. "Boss") then
            if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                return true, v
            end
        end
    end
    return false, nil
end

local function AutoEquip(itemName)
    local backpack = Player:WaitForChild("Backpack")
    local tool = backpack:FindFirstChild(itemName) or Player.Character:FindFirstChild(itemName)
    if tool then
        Player.Character.Humanoid:EquipTool(tool)
    end
end
AutoEquip(SPAutoBoss_Config.Item)

function Main()
    local args = {
        [1] = "Toggle"
    }
    game:GetService("ReplicatedStorage").RemoteEvents.HakiRemote:FireServer(unpack(args))
    local Attempt, Mob = Find(SPAutoBoss_Config.Target)
    if Attempt and Mob then
        local TargetHRP = Mob:FindFirstChild("HumanoidRootPart")
        local CharHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if TargetHRP and CharHRP then
            local FakePart = Instance.new("Part")
            FakePart.Anchored = true
            FakePart.CanCollide = false
            FakePart.CanTouch = false
            FakePart.Transparency = 1
            FakePart.CFrame = CFrame.new(TargetHRP.Position) * CFrame.new(0, 0, 3)
            FakePart.Parent = workspace
            local Controller, Tween = Tweener:TweenTo(Player.Character, FakePart, 100, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tweenDone = false
            local mobDead = false
            task.spawn(
                function()
                    while not tweenDone do
                        if Mob.Humanoid.Health <= 0 then
                            if Controller and Controller.Stop then
                                Controller:Stop()
                            end
                            mobDead = true
                            break
                        end
                        task.wait(0.05)
                    end
                end
            )
            if Tween then
                local td = false
                Tween.Completed:Connect(
                    function()
                        td = true
                    end
                )
                while not td and not mobDead do
                    task.wait(0.05)
                end
            end
            tweenDone = true
            FakePart:Destroy()
            if not mobDead then
                local Connection =
                    game:GetService("RunService").Heartbeat:Connect(
                    function()
                        local CharHRP2 = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if CharHRP2 and TargetHRP and Mob.Parent then
                            CharHRP2.CFrame = CFrame.new(TargetHRP.Position) * CFrame.new(0, 0, 3)
                        end
                    end
                )
                task.spawn(
                    function()
                        while Mob and Mob.Parent and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 do
                            game:GetService("ReplicatedStorage").CombatSystem.Remotes.RequestHit:FireServer()
                            task.wait(0.1)
                        end
                    end
                )
                local args = {
                    [1] = tonumber(SPAutoBoss_Config.Move)
                }
                game:GetService("ReplicatedStorage").AbilitySystem.Remotes.RequestAbility:FireServer(unpack(args))
                while Mob and Mob.Parent and Mob:FindFirstChild("Humanoid") and Mob.Humanoid.Health > 0 do
                    task.wait(0.05)
                end
                Connection:Disconnect()
                request({
                    Url     = SPAutoBoss_Config.Webhook,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = game:GetService("HttpService"):JSONEncode(payload),
                })
                wait(0.1)
                ServerHop()
            else
                ServerHop()
            end
        end
    else
        ServerHop()
    end
end
Main()
