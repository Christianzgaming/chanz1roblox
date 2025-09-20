--// 99 Nights in the Forest Script with Rayfield GUI //--
--// Redesigned for improved code organization, UI, and features //--

-- Load Rayfield UI Library
-- Centralized loading for better management
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/Christianzgaming/chanz1roblox/refs/heads/main/99NIGHTS/source.lua'))()

-- Services
-- Grouping service acquisition for clarity
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager") -- Moved here for better organization

-- Configuration
-- Centralized configuration for easy modification
local Config = {
    ScriptName = "99 Nights",
    ScriptLoadingTitle = "99 Nights Script",
    ScriptLoadingSubtitle = "by Raygull",
    ConfigFolderName = "99NightsConfigs", -- Dedicated folder for configurations
    ConfigFileName = "99NightsSettings",
    EnableDiscordIntegration = false, -- Toggle for Discord features
    DiscordInvite = "",
    DiscordRememberJoins = true,
    EnableKeySystem = false, -- Toggle for Key System
    MinItemDistance = 50, -- Minimum distance for item ESP/teleport
    AimbotFOVRadius = 100,
    AimbotSmoothness = 0.2,
    AutoTreeFarmTimeout = 12, -- Timeout in seconds for tree farming
    LogPickupCounts = { -- Define log pickup counts by sack type
        ["Old Sack"] = 5,
        ["Good Sack"] = 15
    },
    DefaultWalkSpeed = 16,
    AntiDeathRadius = 50,
    AntiDeathTargets = { -- Configurable Anti-Death targets
        ["Alpha Wolf"] = true,
        Wolf = true,
        ["Crossbow Cultist"] = true,
        Cultist = true,
        Bear = true,
        ["Polar Bear"] = true,
        Alien = true,
    },
    DefaultFogStart = game.Lighting.FogStart, -- Store default fog values
    DefaultFogEnd = game.Lighting.FogEnd,
}

-- UI Window Setup
-- Enhanced window styling and configuration
local Window = Rayfield:CreateWindow({
    Name = Config.ScriptName,
    LoadingTitle = Config.ScriptLoadingTitle,
    LoadingSubtitle = Config.ScriptLoadingSubtitle,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = Config.ConfigFolderName,
        FileName = Config.ConfigFileName
    },
    Discord = {
        Enabled = Config.EnableDiscordIntegration,
        Invite = Config.DiscordInvite,
        RememberJoins = Config.DiscordRememberJoins
    },
    KeySystem = Config.EnableKeySystem,
})

-- Global State Variables
-- Grouping related state variables
local State = {
    EspEnabled = false,
    NpcEspEnabled = false,
    AimbotEnabled = false,
    AutoTreeFarmEnabled = false,
    AutoLogFarmEnabled = false,
    AntiDeathEnabled = false,
    Flying = false,
    CurrentWalkSpeed = Config.DefaultWalkSpeed,
    LogBagType = "Old Sack", -- Default log bag type
    LogDropLocation = "Campfire", -- Default log drop location
    BadTrees = {}, -- Trees that timed out during farming
    NpcEspVisuals = {}, -- Stores NPC ESP drawing objects
}

-- Utility Functions
-- Encapsulating common actions
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

-- Auto-apply walk speed on character spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.WalkSpeed = State.CurrentWalkSpeed
        end
    end)
end)

-- Teleport Targets (Items)
-- Defined as a constant list
local TeleportTargets = {
    "Alpha Wolf", "Alpha Wolf Pelt", "Anvil Base", "Apple", "Bandage", "Bear", "Berry",
    "Bolt", "Broken Fan", "Broken Microwave", "Bunny", "Bunny Foot", "Cake", "Carrot", "Chair Set", "Chest", "Chilli",
    "Coal", "Coin Stack", "Crossbow Cultist", "Cultist", "Cultist Gem", "Deer", "Fuel Canister", "Good Sack", "Good Axe", "Iron Body",
    "Item Chest", "Item Chest2", "Item Chest3", "Item Chest4", "Item Chest6", "Leather Body", "Log", "Lost Child",
    "Lost Child2", "Lost Child3", "Lost Child4", "Medkit", "Meat? Sandwich", "Morsel", "Old Car Engine", "Old Flashlight", "Old Radio", "Oil Barrel",
    "Revolver", "Revolver Ammo", "Rifle", "Rifle Ammo", "Riot Shield", "Sapling", "Seed Box", "Sheet Metal", "Spear",
    "Steak", "Stronghold Diamond Chest", "Tyre", "Washing Machine", "Wolf", "Wolf Corpse", "Wolf Pelt"
}

-- Aimbot Targets (NPCs)
-- Defined as a constant list
local AimbotTargets = {"Alpha Wolf", "Wolf", "Crossbow Cultist", "Cultist", "Bunny", "Bear", "Polar Bear"}

-- ESP System
-- Encapsulated ESP logic for items and NPCs
local function createItemESP(item)
    local adorneePart
    if item:IsA("Model") then
        if item:FindFirstChildWhichIsA("Humanoid") then return end -- Avoid humanoids for item ESP
        adorneePart = item:FindFirstChildWhichIsA("BasePart")
    elseif item:IsA("BasePart") then
        adorneePart = item
    else
        return
    end

    if not adorneePart then return end

    local distance = (adorneePart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if distance < Config.MinItemDistance then return end -- Only show ESP for items beyond min distance

    if not item:FindFirstChild("ESP_Billboard") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Adornee = adorneePart
        billboard.Size = UDim2.new(0, 50, 0, 20)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 2, 0)

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = item.Name
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        label.TextScaled = true
        billboard.Parent = item
    end

    if not item:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.25
        highlight.OutlineTransparency = 0
        highlight.Adornee = item:IsA("Model") and item or adorneePart
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = item
    end
end

local function toggleItemESP(state)
    State.EspEnabled = state
    for _, item in pairs(workspace:GetDescendants()) do
        if table.find(TeleportTargets, item.Name) then
            if State.EspEnabled then
                createItemESP(item)
            else
                if item:FindFirstChild("ESP_Billboard") then item.ESP_Billboard:Destroy() end
                if item:FindFirstChild("ESP_Highlight") then item.ESP_Highlight:Destroy() end
            end
        end
    end
end

-- Auto-create ESP for newly added items
workspace.DescendantAdded:Connect(function(desc)
    if State.EspEnabled and table.find(TeleportTargets, desc.Name) then
        task.wait(0.1)
        createItemESP(desc)
    end
end)

local function createNPCESP(npc)
    if not npc:IsA("Model") or npc:FindFirstChild("HumanoidRootPart") == nil then return end

    local root = npc:FindFirstChild("HumanoidRootPart")
    if State.NpcEspVisuals[npc] then return end -- Already has ESP

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Transparency = 1
    box.Color = Color3.fromRGB(255, 85, 0)
    box.Filled = false
    box.Visible = true

    local nameText = Drawing.new("Text")
    nameText.Text = npc.Name
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Size = 16
    nameText.Center = true
    nameText.Outline = true
    nameText.Visible = true

    State.NpcEspVisuals[npc] = {box = box, name = nameText}

    -- Cleanup on remove
    npc.AncestryChanged:Connect(function(_, parent)
        if not parent and State.NpcEspVisuals[npc] then
            State.NpcEspVisuals[npc].box:Remove()
            State.NpcEspVisuals[npc].name:Remove()
            State.NpcEspVisuals[npc] = nil
        end
    end)
end

local function toggleNPCESP(state)
    State.NpcEspEnabled = state
    if not state then
        for npc, visuals in pairs(State.NpcEspVisuals) do
            if visuals.box then visuals.box:Remove() end
            if visuals.name then visuals.name:Remove() end
        end
        State.NpcEspVisuals = {}
    else
        -- Show NPC ESP for already existing NPCs
        for _, obj in ipairs(workspace:GetDescendants()) do
            if table.find(AimbotTargets, obj.Name) and obj:IsA("Model") then
                createNPCESP(obj)
            end
        end
    end
end

-- Auto-create NPC ESP for newly added NPCs
workspace.DescendantAdded:Connect(function(desc)
    if table.find(AimbotTargets, desc.Name) and desc:IsA("Model") then
        task.wait(0.1)
        if State.NpcEspEnabled then
            createNPCESP(desc)
        end
    end
end)

-- RenderStepped for updating NPC ESP positions
RunService.RenderStepped:Connect(function()
    for npc, visuals in pairs(State.NpcEspVisuals) do
        local box = visuals.box
        local name = visuals.name

        if npc and npc:FindFirstChild("HumanoidRootPart") then
            local hrp = npc.HumanoidRootPart
            local size = Vector2.new(60, 80) -- Fixed size for consistency
            local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
                box.Size = size
                box.Visible = true

                name.Position = Vector2.new(screenPos.X, screenPos.Y - size.Y / 2 - 15)
                name.Visible = true
            else
                box.Visible = false
                name.Visible = false
            end
        else
            -- Clean up visuals if NPC is no longer valid
            box:Remove()
            name:Remove()
            State.NpcEspVisuals[npc] = nil
        end
    end
end)

-- Aimbot System
-- FOV Circle visualization and aim logic
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(128, 255, 0)
FOVCircle.Thickness = 1
FOVCircle.Radius = Config.AimbotFOVRadius
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false
FOVCircle.Visible = false

RunService.RenderStepped:Connect(function()
    if State.AimbotEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not State.AimbotEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        FOVCircle.Visible = false
        return
    end

    local mousePos = UserInputService:GetMouseLocation()
    local closestTarget = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if table.find(AimbotTargets, obj.Name) and obj:IsA("Model") then
            local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") -- Fallback to HRP
            if head then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDistance and dist <= Config.AimbotFOVRadius then
                        shortestDistance = dist
                        closestTarget = head
                    end
                end
            end
        end
    end

    if closestTarget then
        local currentCF = camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, closestTarget.Position)
        camera.CFrame = currentCF:Lerp(targetCF, Config.AimbotSmoothness)
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end)

-- Auto Tree Farm
-- Logic for automated tree farming with timeout
task.spawn(function()
    while true do
        if State.AutoTreeFarmEnabled then
            local trees = {}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Trunk" and obj.Parent and obj.Parent.Name == "Small Tree" then
                    local distance = (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if distance > Config.MinItemDistance and not State.BadTrees[obj:GetFullName()] then
                        table.insert(trees, obj)
                    end
                end
            end

            table.sort(trees, function(a, b)
                return (a.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)

            for _, trunk in ipairs(trees) do
                if not State.AutoTreeFarmEnabled then break end
                LocalPlayer.Character:PivotTo(trunk.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.2)
                local startTime = tick()
                while State.AutoTreeFarmEnabled and trunk and trunk.Parent and trunk.Parent.Name == "Small Tree" do
                    mouse1click()
                    task.wait(0.2)
                    if tick() - startTime > Config.AutoTreeFarmTimeout then
                        State.BadTrees[trunk:GetFullName()] = true
                        break
                    end
                end
                task.wait(0.3)
            end
        end
        task.wait(1.5)
    end
end)

-- Auto Log Farm
-- Logic for automated log farming with sack type and drop location
local function getBagPickupCount()
    return Config.LogPickupCounts[State.LogBagType] or 0
end

local function getClosestLog()
    local minDist = math.huge
    local closest = nil
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Log" then
            local pos = nil
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                    pos = obj.PrimaryPart.Position
                else
                    for _, part in ipairs(obj:GetChildren()) do
                        if part:IsA("BasePart") then
                            pos = part.Position
                            break
                        end
                    end
                end
            end
            if pos then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = obj
                    end
                end
            end
        end
    end
    return closest
end

task.spawn(function()
    while true do
        if State.AutoLogFarmEnabled then
            local pickupCount = getBagPickupCount()
            if pickupCount == 0 then
                Rayfield:Notify({Title="Auto Log Farm", Content="No valid sack type selected!", Duration=3})
                State.AutoLogFarmEnabled = false
                continue
            end

            local log = getClosestLog()
            if log then
                local pos = log.Position or (log.PrimaryPart and log.PrimaryPart.Position)
                if pos then
                    LocalPlayer.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 2, 0)))
                    task.wait(0.5)

                    local footPos = LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0, 3, 0)
                    local screen = camera:WorldToScreenPoint(footPos)
                    VirtualInputManager:SendMouseMoveEvent(screen.X, screen.Y, game)
                    task.wait(0.25)

                    for i=1, pickupCount do
                        pressKey("F")
                        pressKey("E")
                        task.wait(0.13)
                    end

                    if State.LogDropLocation == "Campfire" then
                        LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
                    else -- Grinder
                        LocalPlayer.Character:PivotTo(CFrame.new(16.1,4,-4.6))
                    end
                    task.wait(2)
                end
            else
                Rayfield:Notify({Title="Auto Log Farm", Content="No log found!", Duration=3})
                task.wait(3)
            end
        end
        task.wait(1)
    end
end)

-- Fly System
-- Toggleable fly with WASD + Space + Shift controls
local flyConnection = nil
local flySpeed = 60

local function startFlying()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bodyGyro = Instance.new("BodyGyro", hrp)
    local bodyVelocity = Instance.new("BodyVelocity", hrp)
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    flyConnection = RunService.RenderStepped:Connect(function()
        local moveVec = Vector3.zero
        local camCF = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += camCF.UpVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= camCF.UpVector end
        bodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = camCF
    end)
end

local function stopFlying()
    if flyConnection then flyConnection:Disconnect() end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
        end
    end
end

local function toggleFly(state)
    State.Flying = state
    if State.Flying then startFlying() else stopFlying() end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then -- Q to toggle fly
        toggleFly(not State.Flying)
    end
end)

-- Anti-Death Teleport
-- Automatically teleports player away from dangerous NPCs
local detectionCircle = Instance.new("Part")
detectionCircle.Name = "AntiDeathCircle"
detectionCircle.Anchored = true
detectionCircle.CanCollide = false
detectionCircle.Transparency = 0.7
detectionCircle.Material = Enum.Material.Neon
detectionCircle.Color = Color3.fromRGB(255, 0, 0)
detectionCircle.Parent = workspace

local mesh = Instance.new("SpecialMesh", detectionCircle)
mesh.MeshType = Enum.MeshType.Cylinder
mesh.Scale = Vector3.new(Config.AntiDeathRadius * 2, 0.2, Config.AntiDeathRadius * 2)

local function updateDetectionCircle()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        detectionCircle.Position = Vector3.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
        mesh.Scale = Vector3.new(Config.AntiDeathRadius * 2, 0.2, Config.AntiDeathRadius * 2)
        detectionCircle.Transparency = State.AntiDeathEnabled and 0.5 or 1
    else
        detectionCircle.Transparency = 1
    end
end

RunService.RenderStepped:Connect(function()
    updateDetectionCircle()
end)

task.spawn(function()
    while true do
        if State.AntiDeathEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = hrp.Position
                for _, npc in ipairs(workspace:GetDescendants()) do
                    if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and Config.AntiDeathTargets[npc.Name] then
                        local npcPos = npc.HumanoidRootPart.Position
                        if (npcPos - pos).Magnitude <= Config.AntiDeathRadius then
                            LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0)) -- Teleport to campfire
                            Rayfield:Notify({Title="Anti Death", Content="Teleported to safety!", Duration=3})
                            break
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- GUI Tabs
-- Organized tabs with professional styling and enhanced features
local HomeTab = Window:CreateTab("🏠 Home", 4483362458) -- Icon ID for home

HomeTab:CreateButton({
    Name = "Teleport to Campfire",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(0, 10, 0))
        Rayfield:Notify({Title="Teleport", Content="Teleported to Campfire!", Duration=2})
    end
})

HomeTab:CreateButton({
    Name = "Teleport to Grinder",
    Callback = function()
        LocalPlayer.Character:PivotTo(CFrame.new(16.1,4,-4.6))
        Rayfield:Notify({Title="Teleport", Content="Teleported to Grinder!", Duration=2})
    end
})

HomeTab:CreateSlider({
    Name = "Speedhack",
    Range = {Config.DefaultWalkSpeed, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = Config.DefaultWalkSpeed,
    Callback = setWalkSpeed
})

HomeTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = State.EspEnabled,
    Callback = function(value)
        toggleItemESP(value)
        Rayfield:Notify({
            Title = "Item ESP",
            Content = value and "Item ESP Enabled" or "Item ESP Disabled",
            Duration = 3,
        })
    end
})

HomeTab:CreateToggle({
    Name = "NPC ESP",
    CurrentValue = State.NpcEspEnabled,
    Callback = function(value)
        toggleNPCESP(value)
        Rayfield:Notify({
            Title = "NPC ESP",
            Content = value and "NPC ESP Enabled" or "NPC ESP Disabled",
            Duration = 3,
        })
    end
})

HomeTab:CreateToggle({
    Name = "Auto Tree Farm (Small Tree)",
    CurrentValue = State.AutoTreeFarmEnabled,
    Callback = function(value)
        State.AutoTreeFarmEnabled = value
        Rayfield:Notify({
            Title = "Auto Tree Farm",
            Content = value and "Auto Tree Farm Enabled" or "Auto Tree Farm Disabled",
            Duration = 3,
        })
    end
})

HomeTab:CreateToggle({
    Name = "Auto Log Farm",
    CurrentValue = State.AutoLogFarmEnabled,
    Callback = function(value)
        State.AutoLogFarmEnabled = value
        Rayfield:Notify({Title="Auto Log Farm", Content=value and "Enabled" or "Disabled", Duration=3})
    end
})

HomeTab:CreateToggle({
    Name = "Aimbot (Right Click)",
    CurrentValue = State.AimbotEnabled,
    Callback = function(value)
        State.AimbotEnabled = value
        Rayfield:Notify({
            Title = "Aimbot",
            Content = value and "Enabled - Hold Right Click to aim." or "Disabled.",
            Duration = 4,
        })
    end
})

HomeTab:CreateToggle({
    Name = "Fly (Q to toggle)",
    CurrentValue = State.Flying,
    Callback = function(value)
        toggleFly(value)
        Rayfield:Notify({
            Title = "Fly",
            Content = value and "Fly Enabled (Q to toggle)" or "Fly Disabled",
            Duration = 4,
        })
    end
})

HomeTab:CreateToggle({
    Name = "Anti Death Teleport",
    CurrentValue = State.AntiDeathEnabled,
    Callback = function(value)
        State.AntiDeathEnabled = value
        Rayfield:Notify({
            Title = "Anti Death Teleport",
            Content = value and "Enabled" or "Disabled",
            Duration = 4,
        })
    end
})

HomeTab:CreateToggle({
    Name = "No Fog (Clear Skies)",
    CurrentValue = false,
    Callback = function(value)
        if value then
            game.Lighting.FogStart = 999999
            game.Lighting.FogEnd = 1000000
        else
            game.Lighting.FogStart = Config.DefaultFogStart
            game.Lighting.FogEnd = Config.DefaultFogEnd
        end
        Rayfield:Notify({
            Title = "Fog Toggle",
            Content = value and "No Fog Enabled" or "Fog Restored",
            Duration = 3,
        })
    end
})

-- Teleport Tab
local TeleTab = Window:CreateTab("🧲 Teleport", 4483362458) -- Icon ID for magnet
for _, itemName in ipairs(TeleportTargets) do
    TeleTab:CreateButton({
        Name = "Teleport to " .. itemName,
        Callback = function()
            local closest, shortest = nil, math.huge
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == itemName and obj:IsA("Model") then
                    local cf = nil
                    if pcall(function() cf = obj:GetPivot() end) then
                        -- success
                    else
                        local part = obj:FindFirstChildWhichIsA("BasePart")
                        if part then cf = part.CFrame end
                    end
                    if cf then
                        local dist = (cf.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        if dist >= Config.MinItemDistance and dist < shortest then
                            closest = obj
                            shortest = dist
                        end
                    end
                end
            end
            if closest then
                local cf = nil
                if pcall(function() cf = closest:GetPivot() end) then
                    -- success
                else
                    local part = closest:FindFirstChildWhichIsA("BasePart")
                    if part then cf = part.CFrame end
                end
                if cf then
                    LocalPlayer.Character:PivotTo(cf + Vector3.new(0, 5, 0))
                    Rayfield:Notify({Title="Teleport", Content="Teleported to " .. itemName .. "!", Duration=2})
                else
                    Rayfield:Notify({
                        Title = "Teleport Failed",
                        Content = "Could not find a valid position to teleport.",
                        Duration = 3,
                    })
                end
            else
                Rayfield:Notify({
                    Title = "Item Not Found",
                    Content = itemName .. " not found or too close.",
                    Duration = 3,
                })
            end
        end
    })
end

-- Log Farm Tab
local LogTab = Window:CreateTab("🌳 Log Farm", 4483362458) -- Icon ID for tree
local OldSackToggle, GoodSackToggle, AutoSackToggle
local CampfireDropToggle, GrinderDropToggle

LogTab:CreateSection("Sack Type")

OldSackToggle = LogTab:CreateToggle({
    Name = "Use Old Sack (" .. Config.LogPickupCounts["Old Sack"] .. " logs)",
    CurrentValue = (State.LogBagType == "Old Sack"),
    Callback = function(value)
        if value then
            State.LogBagType = "Old Sack"
            if GoodSackToggle then GoodSackToggle.Set(false) end
            if AutoSackToggle then AutoSackToggle.Set(false) end
            Rayfield:Notify({Title="Log Farm", Content="Selected Old Sack.", Duration=2})
        end
    end
})

GoodSackToggle = LogTab:CreateToggle({
    Name = "Use Good Sack (" .. Config.LogPickupCounts["Good Sack"] .. " logs)",
    CurrentValue = (State.LogBagType == "Good Sack"),
    Callback = function(value)
        if value then
            State.LogBagType = "Good Sack"
            if OldSackToggle then OldSackToggle.Set(false) end
            if AutoSackToggle then AutoSackToggle.Set(false) end
            Rayfield:Notify({Title="Log Farm", Content="Selected Good Sack.", Duration=2})
        end
    end
})

-- Auto Sack Type (if applicable, requires inventory check)
-- For now, keeping it simple as per original script's `getBagType` was not defined.
-- If `getBagType` function is implemented, this can be enabled.
--[[
AutoSackToggle = LogTab:CreateToggle({
    Name = "Auto Detect Sack Type",
    CurrentValue = (State.LogBagType == "Auto"),
    Callback = function(value)
        if value then
            State.LogBagType = "Auto"
            if OldSackToggle then OldSackToggle.Set(false) end
            if GoodSackToggle then GoodSackToggle.Set(false) end
            Rayfield:Notify({Title="Log Farm", Content="Auto detecting sack type.", Duration=2})
        end
    end
})
]]

LogTab:CreateSection("Log Drop Location")

CampfireDropToggle = LogTab:CreateToggle({
    Name = "Drop at Campfire",
    CurrentValue = (State.LogDropLocation == "Campfire"),
    Callback = function(value)
        if value then
            State.LogDropLocation = "Campfire"
            if GrinderDropToggle then GrinderDropToggle.Set(false) end
            Rayfield:Notify({Title="Log Farm", Content="Logs will be dropped at Campfire.", Duration=2})
        end
    end
})

GrinderDropToggle = LogTab:CreateToggle({
    Name = "Drop at Grinder",
    CurrentValue = (State.LogDropLocation == "Grinder"),
    Callback = function(value)
        if value then
            State.LogDropLocation = "Grinder"
            if CampfireDropToggle then CampfireDropToggle.Set(false) end
            Rayfield:Notify({Title="Log Farm", Content="Logs will be dropped at Grinder.", Duration=2})
        end
    end
})

-- Anti Death Settings Tab
local AntiDeathTab = Window:CreateTab("🛡️ Anti Death", 4483362458) -- Icon ID for shield

AntiDeathTab:CreateSlider({
    Name = "Detection Radius",
    Range = {10, 150},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = Config.AntiDeathRadius,
    Callback = function(value)
        Config.AntiDeathRadius = value
        updateDetectionCircle()
    end
})

AntiDeathTab:CreateSection("Avoid Specific NPCs")
for npcName, _ in pairs(Config.AntiDeathTargets) do
    AntiDeathTab:CreateToggle({
        Name = "Avoid " .. npcName,
        CurrentValue = Config.AntiDeathTargets[npcName],
        Callback = function(value)
            Config.AntiDeathTargets[npcName] = value
        end
    })
end
