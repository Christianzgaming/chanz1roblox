--// 99 Nights in the Forest Script with Rayfield GUI //--
--// Upgraded UI and Professional Enhancements //--

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Christianzgaming/chanz1roblox/refs/heads/main/99NIGHTS/source.lua'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("User InputService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Configuration
local Config = {
    ScriptName = "99 Nights",
    ConfigFolderName = "99NightsConfigs",
    ConfigFileName = "99NightsSettings",
    MinItemDistance = 50,
    AimbotFOVRadius = 100,
    AimbotSmoothness = 0.2,
    AutoTreeFarmTimeout = 12,
    LogPickupCounts = {["Old Sack"] = 5, ["Good Sack"] = 15},
    DefaultWalkSpeed = 16,
    AntiDeathRadius = 50,
    AntiDeathTargets = {
        ["Alpha Wolf"] = true,
        Wolf = true,
        ["Crossbow Cultist"] = true,
        Cultist = true,
        Bear = true,
        ["Polar Bear"] = true,
        Alien = true,
    },
    DefaultFogStart = game.Lighting.FogStart,
    DefaultFogEnd = game.Lighting.FogEnd,
}

-- State
local State = {
    EspEnabled = false,
    NpcEspEnabled = false,
    AimbotEnabled = false,
    AutoTreeFarmEnabled = false,
    AutoLogFarmEnabled = false,
    AntiDeathEnabled = false,
    Flying = false,
    CurrentWalkSpeed = Config.DefaultWalkSpeed,
    LogBagType = "Old Sack",
    LogDropLocation = "Campfire",
    BadTrees = {},
    NpcEspVisuals = {},
}

-- Utility Functions
local function mouse1click()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function pressKey(key)
    key = typeof(key) == "EnumItem" and key or Enum.KeyCode[key]
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.07)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function setWalkSpeed(speed)
    State.CurrentWalkSpeed = speed
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").WalkSpeed = speed
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.WalkSpeed = State.CurrentWalkSpeed
        end
    end)
end)

-- ESP and Aimbot logic omitted for brevity (same as previous redesign)...

-- UI Window Setup with Enhanced UI
local Window = Rayfield:CreateWindow({
    Name = Config.ScriptName,
    LoadingTitle = "Loading 99 Nights Script...",
    LoadingSubtitle = "by Raygull",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = Config.ConfigFolderName,
        FileName = Config.ConfigFileName,
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true,
    },
    KeySystem = false,
})

-- Home Tab with Sections and Tooltips
local HomeTab = Window:CreateTab("🏠 Home", 4483362458)

HomeTab:CreateSection("Teleportation")
HomeTab:CreateButton({
    Name = "Teleport to Campfire 🔥",
    Tooltip = "Instantly teleport your character to the Campfire location.",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
        Rayfield:Notify({Title="Teleport", Content="Teleported to Campfire!", Duration=2, Image=4483362458})
    end
})

HomeTab:CreateButton({
    Name = "Teleport to Grinder ⚙️",
    Tooltip = "Instantly teleport your character to the Grinder location.",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(16.1,4,-4.6))
        Rayfield:Notify({Title="Teleport", Content="Teleported to Grinder!", Duration=2, Image=4483362458})
    end
})

HomeTab:CreateSection("Movement")
HomeTab:CreateSlider({
    Name = "Walk Speed",
    Range = {Config.DefaultWalkSpeed, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = Config.DefaultWalkSpeed,
    Tooltip = "Adjust your character's walking speed.",
    Callback = setWalkSpeed,
})

HomeTab:CreateToggle({
    Name = "Enable Fly (Toggle with Q)",
    CurrentValue = State.Flying,
    Tooltip = "Toggle flying mode. Use Q key to toggle fly on/off.",
    Callback = function(value)
        State.Flying = value
        if value then
            -- Start flying logic
            Rayfield:Notify({Title="Fly", Content="Fly Enabled (Press Q to toggle)", Duration=3, Image=4483362458})
        else
            -- Stop flying logic
            Rayfield:Notify({Title="Fly", Content="Fly Disabled", Duration=3, Image=4483362458})
        end
    end,
})

HomeTab:CreateSection("Visuals")
HomeTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = State.EspEnabled,
    Tooltip = "Toggle ESP for items in the world.",
    Callback = function(value)
        State.EspEnabled = value
        -- Toggle ESP logic here
        Rayfield:Notify({Title="Item ESP", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end,
})

HomeTab:CreateToggle({
    Name = "NPC ESP",
    CurrentValue = State.NpcEspEnabled,
    Tooltip = "Toggle ESP for NPCs.",
    Callback = function(value)
        State.NpcEspEnabled = value
        -- Toggle NPC ESP logic here
        Rayfield:Notify({Title="NPC ESP", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end,
})

HomeTab:CreateToggle({
    Name = "Aimbot (Hold Right Click)",
    CurrentValue = State.AimbotEnabled,
    Tooltip = "Enable aimbot. Hold right mouse button to aim.",
    Callback = function(value)
        State.AimbotEnabled = value
        Rayfield:Notify({Title="Aimbot", Content=value and "Enabled" or "Disabled", Duration=4, Image=4483362458})
    end,
})

HomeTab:CreateSection("Automation")
HomeTab:CreateToggle({
    Name = "Auto Tree Farm (Small Trees)",
    CurrentValue = State.AutoTreeFarmEnabled,
    Tooltip = "Automatically farm small trees nearby.",
    Callback = function(value)
        State.AutoTreeFarmEnabled = value
        Rayfield:Notify({Title="Auto Tree Farm", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end,
})

HomeTab:CreateToggle({
    Name = "Auto Log Farm",
    CurrentValue = State.AutoLogFarmEnabled,
    Tooltip = "Automatically farm logs and drop them at selected location.",
    Callback = function(value)
        State.AutoLogFarmEnabled = value
        Rayfield:Notify({Title="Auto Log Farm", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end,
})

HomeTab:CreateSection("Safety")
HomeTab:CreateToggle({
    Name = "Anti Death Teleport",
    CurrentValue = State.AntiDeathEnabled,
    Tooltip = "Automatically teleport away from dangerous NPCs.",
    Callback = function(value)
        State.AntiDeathEnabled = value
        Rayfield:Notify({Title="Anti Death Teleport", Content=value and "Enabled" or "Disabled", Duration=3, Image=4483362458})
    end,
})

HomeTab:CreateSlider({
    Name = "Anti Death Detection Radius",
    Range = {10, 150},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = Config.AntiDeathRadius,
    Tooltip = "Set the radius to detect dangerous NPCs for anti-death teleport.",
    Callback = function(value)
        Config.AntiDeathRadius = value
        -- Update detection circle size here
    end,
})

HomeTab:CreateToggle({
    Name = "No Fog (Clear Skies)",
    CurrentValue = false,
    Tooltip = "Toggle fog off for clear visibility.",
    Callback = function(value)
        if value then
            game.Lighting.FogStart = 999999
            game.Lighting.FogEnd = 1000000
        else
            game.Lighting.FogStart = Config.DefaultFogStart
            game.Lighting.FogEnd = Config.DefaultFogEnd
        end
        Rayfield:Notify({Title="Fog Toggle", Content=value and "No Fog Enabled" or "Fog Restored", Duration=3, Image=4483362458})
    end,
})

-- Teleport Tab with Search and Icons
local TeleTab = Window:CreateTab("🧲 Teleport", 4483362458)

-- Search box for teleport targets
local searchBox = TeleTab:CreateInput({
    Name = "Search Teleport Targets",
    PlaceholderText = "Type to search...",
    Callback = function(text)
        -- Implement search filtering logic here if desired
    end,
})

-- Teleport buttons dynamically created with icons and tooltips
local TeleportTargets = {
    "Alpha Wolf", "Alpha Wolf Pelt", "Anvil Base", "Apple", "Bandage", "Bear", "Berry",
    "Bolt", "Broken Fan", "Broken Microwave", "Bunny", "Bunny Foot", "Cake", "Carrot", "Chair Set", "Chest", "Chilli",
    "Coal", "Coin Stack", "Crossbow Cultist", "Cultist", "Cultist Gem", "Deer", "Fuel Canister", "Good Sack", "Good Axe", "Iron Body",
    "Item Chest", "Item Chest2", "Item Chest3", "Item Chest4", "Item Chest6", "Leather Body", "Log", "Lost Child",
    "Lost Child2", "Lost Child3", "Lost Child4", "Medkit", "Meat? Sandwich", "Morsel", "Old Car Engine", "Old Flashlight", "Old Radio", "Oil Barrel",
    "Revolver", "Revolver Ammo", "Rifle", "Rifle Ammo", "Riot Shield", "Sapling", "Seed Box", "Sheet Metal", "Spear",
    "Steak", "Stronghold Diamond Chest", "Tyre", "Washing Machine", "Wolf", "Wolf Corpse", "Wolf Pelt"
}

for _, itemName in ipairs(TeleportTargets) do
    TeleTab:CreateButton({
        Name = "Teleport to " .. itemName,
        Tooltip = "Teleport to the nearest " .. itemName .. " in the world.",
        Callback = function()
            -- Teleport logic as before
            Rayfield:Notify({Title="Teleport", Content="Attempting to teleport to " .. itemName, Duration=2, Image=4483362458})
            -- Implementation omitted for brevity
        end,
    })
end

-- Log Farm Tab with grouped toggles and progress bars
local LogTab = Window:CreateTab("🌳 Log Farm", 4483362458)

LogTab:CreateSection("Select Sack Type")

local OldSackToggle = LogTab:CreateToggle({
    Name = "Old Sack (5 logs)",
    Tooltip = "Use Old Sack to pick up 5 logs at a time.",
    CurrentValue = (State.LogBagType == "Old Sack"),
    Callback = function(value)
        if value then
            State.LogBagType = "Old Sack"
            Rayfield:Notify({Title="Log Farm", Content="Old Sack selected.", Duration=2, Image=4483362458})
        end
    end,
})

local GoodSackToggle = LogTab:CreateToggle({
    Name = "Good Sack (15 logs)",
    Tooltip = "Use Good Sack to pick up 15 logs at a time.",
    CurrentValue = (State.LogBagType == "Good Sack"),
    Callback = function(value)
        if value then
            State.LogBagType = "Good Sack"
            Rayfield:Notify({Title="Log Farm", Content="Good Sack selected.", Duration=2, Image=4483362458})
        end
    end,
})

LogTab:CreateSection("Select Drop Location")

local CampfireDropToggle = LogTab:CreateToggle({
    Name = "Drop at Campfire",
    Tooltip = "Drop logs at the Campfire location.",
    CurrentValue = (State.LogDropLocation == "Campfire"),
    Callback = function(value)
        if value then
            State.LogDropLocation = "Campfire"
            Rayfield:Notify({Title="Log Farm", Content="Drop location set to Campfire.", Duration=2, Image=4483362458})
        end
    end,
})

local GrinderDropToggle = LogTab:CreateToggle({
    Name = "Drop at Grinder",
    Tooltip = "Drop logs at the Grinder location.",
    CurrentValue = (State.LogDropLocation == "Grinder"),
    Callback = function(value)
        if value then
            State.LogDropLocation = "Grinder"
            Rayfield:Notify({Title="Log Farm", Content="Drop location set to Grinder.", Duration=2, Image=4483362458})
        end
    end,
})

-- Progress bars for automation (optional, requires implementation)
-- Example placeholder for Auto Tree Farm progress
local treeFarmProgress = LogTab:CreateSlider({
    Name = "Auto Tree Farm Progress",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 0,
    Disabled = true,
    Tooltip = "Shows progress of Auto Tree Farm.",
})

-- Example placeholder for Auto Log Farm progress
local logFarmProgress = LogTab:CreateSlider({
    Name = "Auto Log Farm Progress",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 0,
    Disabled = true,
    Tooltip = "Shows progress of Auto Log Farm.",
})

-- Anti Death Tab with grouped toggles and sliders
local AntiDeathTab = Window:CreateTab("🛡️ Anti Death", 4483362458)

AntiDeathTab:CreateSlider({
    Name = "Detection Radius",
    Range = {10, 150},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = Config.AntiDeathRadius,
    Tooltip = "Radius to detect dangerous NPCs.",
    Callback = function(value)
        Config.AntiDeathRadius = value
        -- Update detection circle size here
    end,
})

AntiDeathTab:CreateSection("Avoid Specific NPCs")
for npcName, _ in pairs(Config.AntiDeathTargets) do
    AntiDeathTab:CreateToggle({
        Name = "Avoid " .. npcName,
        Tooltip = "Toggle avoidance of " .. npcName,
        CurrentValue = Config.AntiDeathTargets[npcName],
        Callback = function(value)
            Config.AntiDeathTargets[npcName] = value
        end,
    })
end

-- Additional UI improvements can be added here...

-- End of redesigned script
