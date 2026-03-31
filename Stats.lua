local Stats = {
    Race = game:GetService("Players").LocalPlayer.PlayerGui.StatsPanelUI.MainFrame.Frame.Content.SideFrame.UserStats.RaceEquipped.StatName,
    --=====> game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use", "Race Reroll", 1, false)
    Clan = game:GetService("Players").LocalPlayer.PlayerGui.StatsPanelUI.MainFrame.Frame.Content.SideFrame.UserStats.ClanEquipped.StatName,
    --=====> game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use", "Clan Reroll", 1, false)
    --=====> game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use", "Clan Reroll (Untradeable)", 1, false)
    Trait = game:GetService("Players").LocalPlayer.PlayerGui.StatsPanelUI.MainFrame.Frame.Content.SideFrame.UserStats.TraitEquipped.StatName,
    --=====> game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TraitReroll"):FireServer()
}

a = Instance.new("ScreenGui")
b = Instance.new("Frame")

a.Name = "ScreenGui"
a.ResetOnSpawn = false
a.Enabled = true
a.Parent = game:GetService("CoreGui")

b.Size = UDim2.fromScale(0.12, 0.12)
b.AnchorPoint = Vector2.new(1, 1)
b.Position = UDim2.fromScale(0.98, 0.875)
b.BackgroundTransparency = 1
b.Parent = a

c = Stats.Race

d = c:Clone()
d.Name = "TextLabel"
d.Text = c.Text
d.Parent = b

c:GetPropertyChangedSignal("Text"):Connect(function()
    d.Text = c.Text
end)
