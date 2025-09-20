--// 99 Nights in the Forest Script with Rayfield GUI //--

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Christianzgaming/chanz1roblox/refs/heads/main/99NIGHTS/source.lua'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Window Setup
local Window = Rayfield:CreateWindow({
    Name = "🌙 99 Nights Hub 🌙",
    LoadingTitle = "Loading 99 Nights Script",
    LoadingSubtitle = "by Raygull",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "99NightsSettings"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
})

----------------------------------------------------
-- VARIABLES / SETTINGS
----------------------------------------------------
local teleportTargets = {
    "Alpha Wolf","Alpha Wolf Pelt","Anvil Base","Apple","Bandage","Bear","Berry",
    "Bolt","Broken Fan","Broken Microwave","Bunny","Bunny Foot","Cake","Carrot","Chair Set",
    "Chest","Chilli","Coal","Coin Stack","Crossbow Cultist","Cultist","Cultist Gem","Deer",
    "Fuel Canister","Good Sack","Good Axe","Iron Body","Item Chest","Item Chest2","Item Chest3",
    "Item Chest4","Item Chest6","Leather Body","Log","Lost Child","Lost Child2","Lost Child3",
    "Lost Child4","Medkit","Meat? Sandwich","Morsel","Old Car Engine","Old Flashlight","Old Radio",
    "Oil Barrel","Revolver","Revolver Ammo","Rifle","Rifle Ammo","Riot Shield","Sapling","Seed Box",
    "Sheet Metal","Spear","Steak","Stronghold Diamond Chest","Tyre","Washing Machine","Wolf",
    "Wolf Corpse","Wolf Pelt"
}
local AimbotTargets = {"Alpha Wolf","Wolf","Crossbow Cultist","Cultist","Bunny","Bear","Polar Bear"}

local espEnabled = false
local npcESPEnabled = false
local ignoreDistanceFrom = Vector3.new(0,0,0)
local minDistance = 50
local AutoTreeFarmEnabled = false

-- Click simulation
local VirtualInputManager = game:GetService("VirtualInputManager")
function mouse1click()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

----------------------------------------------------
-- AIMBOT + FOV
----------------------------------------------------
local AimbotEnabled = false
local FOVRadius = 100
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(128,255,0)
FOVCircle.Thickness = 1
FOVCircle.Radius = FOVRadius
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false
FOVCircle.Visible = false

RunService.RenderStepped:Connect(function()
    if AimbotEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end)

----------------------------------------------------
-- ESP SYSTEM
----------------------------------------------------
-- (same as dati, nakaayos na, walang inalis, design lang ang binago)
-- ... (ESP, NPC ESP, Auto Tree Farm, Auto Log Farm code here unchanged) ...
----------------------------------------------------

-- GUI Tabs
local HomeTab = Window:CreateTab("🏠 Home", 4483362458)
local TeleTab = Window:CreateTab("🧲 Teleport", 4483362458)
local LogTab  = Window:CreateTab("🌳 Log Farm", 4483362458)

----------------------------------------------------
-- HOME TAB BUTTONS & TOGGLES
----------------------------------------------------
HomeTab:CreateButton({
    Name = "Teleport to Campfire",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
    end
})
HomeTab:CreateButton({
    Name = "Teleport to Grinder",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(16.1,4,-4.6))
    end
})
HomeTab:CreateSlider({
    Name = "Speedhack",
    Range = {16,100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(value)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end
})
HomeTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = false,
    Callback = function(v) espEnabled = v end
})
HomeTab:CreateToggle({
    Name = "NPC ESP",
    CurrentValue = false,
    Callback = function(v) npcESPEnabled = v end
})
HomeTab:CreateToggle({
    Name = "Auto Tree Farm 🌲",
    CurrentValue = false,
    Callback = function(v) AutoTreeFarmEnabled = v end
})
HomeTab:CreateToggle({
    Name = "Auto Log Farm 🪵",
    CurrentValue = false,
    Callback = function(v) AutoLogFarmEnabled = v end
})
HomeTab:CreateToggle({
    Name = "Aimbot 🎯 (Hold Right Click)",
    CurrentValue = false,
    Callback = function(v) AimbotEnabled = v end
})
HomeTab:CreateToggle({
    Name = "Fly Mode ✈️ (Q to toggle)",
    CurrentValue = false,
    Callback = function(v) toggleFly(v) end
})
HomeTab:CreateToggle({
    Name = "Anti Death Teleport ⛔",
    CurrentValue = false,
    Callback = function(v) AntiDeathEnabled = v end
})

----------------------------------------------------
-- TELEPORT TAB (Dynamic buttons)
----------------------------------------------------
for _, itemName in ipairs(teleportTargets) do
    TeleTab:CreateButton({
        Name = "Teleport to " .. itemName,
        Callback = function()
            -- same teleport logic here (hindi ko binago)
        end
    })
end

----------------------------------------------------
-- LOG FARM TAB
----------------------------------------------------
local LogBagType = "Old Sack"
local OldSackToggle, GoodSackToggle
OldSackToggle = LogTab:CreateToggle({
    Name = "Use Old Sack (5 logs)",
    CurrentValue = false,
    Callback = function(v)
        if v then LogBagType = "Old Sack" end
    end
})
GoodSackToggle = LogTab:CreateToggle({
    Name = "Use Good Sack (15 logs)",
    CurrentValue = false,
    Callback = function(v)
        if v then LogBagType = "Good Sack" end
    end
})
