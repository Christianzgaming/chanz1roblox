--// 99 Nights in the Forest - Professional Edition //--
--// Redesigned by BLACKBOXAI for enhanced user experience //--

--region -- Core Setup and Library Loading --

-- Load Rayfield UI Library with error handling
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/Christianzgaming/chanz1roblox/refs/heads/main/99NIGHTS/source.lua'))()
end)

if not success then
    warn("Failed to load Rayfield UI Library. Please check your internet connection or the URL.")
    return
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

--endregion

--region -- Configuration System --

-- Professional Configuration System
local Config = {
    ESP = {
        ItemColor = Color3.fromRGB(0, 255, 255), -- Cyan for items
        NPCColor = Color3.fromRGB(255, 100, 0),  -- Orange for NPCs
        Distance = 500, -- Increased default distance for better visibility
        Transparency = 0.3,
        TextSize = 14,
        ShowDistance = true,
        ShowHealth = true
    },
    Aimbot = {
        Enabled = false,
        FOV = 150, -- Slightly increased default FOV
        Smoothness = 0.1, -- Smoother aiming
        CheckInterval = 0.01,
        TargetColor = Color3.fromRGB(255, 0, 0),
        TargetPart = "Head", -- Default target part
        Targets = {"Humanoid", "Zombie", "Wolf", "Bear", "Alien", "Cultist"}, -- Default target names/types
        DrawFOV = true
    },
    Performance = {
        MaxRenderDistance = 2000, -- Increased render distance for features
        UpdateInterval = 0.05 -- Faster updates for dynamic features
    },
    UI = {
        PrimaryColor = Color3.fromRGB(45, 45, 60),
        SecondaryColor = Color3.fromRGB(35, 35, 50),
        AccentColor = Color3.fromRGB(0, 120, 255),
        TextColor = Color3.fromRGB(255, 255, 255),
        WarningColor = Color3.fromRGB(255, 200, 0),
        ErrorColor = Color3.fromRGB(255, 50, 50),
        SuccessColor = Color3.fromRGB(0, 255, 100)
    },
    Farming = {
        AutoTreeFarmEnabled = false,
        AutoLogFarmEnabled = false,
        LogBagType = "Auto", -- "Old Sack", "Good Sack", "Auto"
        LogDropLocation = "Campfire", -- "Campfire" or "Grinder"
        TreeFarmTimeout = 15 -- Max seconds to farm one tree
    },
    Movement = {
        WalkSpeed = 16,
        FlySpeed = 60,
        FlyEnabled = false
    },
    AntiDeath = {
        Enabled = false,
        Radius = 75, -- Increased default radius
        TeleportLocation = CFrame.new(0, 10, 0), -- Default safe zone (Campfire)
        Threats = {
            Alien = true,
            ["Alpha Wolf"] = true,
            Wolf = true,
            ["Crossbow Cultist"] = true,
            Cultist = true,
            Bear = true,
            Zombie = true -- Added Zombie as a threat
        }
    },
    Visuals = {
        NoFog = false,
        DefaultFogStart = Lighting.FogStart,
        DefaultFogEnd = Lighting.FogEnd
    }
}

--endregion

--region -- Utility Functions --

local Utils = {}

--- Creates a Rayfield notification.
-- @param title string The title of the notification.
-- @param content string The main content/message.
-- @param duration number (optional) How long the notification stays (default 4s).
-- @param type string (optional) "info", "success", "warning", "error" (default "info").
function Utils:CreateNotification(title, content, duration, type)
    type = type or "info"
    local imageId = 4483362458 -- Default image ID for Rayfield notifications

    local colors = {
        info = Config.UI.AccentColor,
        success = Config.UI.SuccessColor,
        warning = Config.UI.WarningColor,
        error = Config.UI.ErrorColor
    }

    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 4,
        Image = imageId,
        NotificationType = type,
        Color = colors[type] or Config.UI.AccentColor -- Use configured colors
    })
end

--- Safely teleports the local player's character to a given CFrame.
-- @param cframe CFrame The target CFrame for teleportation.
-- @return boolean True if teleport successful, false otherwise.
function Utils:SafeTeleport(cframe)
    local character = LocalPlayer.Character
    if not character then
        Utils:CreateNotification("Teleport Error", "Character not found.", 3, "error")
        return false
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Utils:CreateNotification("Teleport Error", "HumanoidRootPart not found.", 3, "error")
        return false
    end

    local success, err = pcall(function()
        character:PivotTo(cframe)
    end)

    if not success then
        warn("Teleport failed:", err)
        Utils:CreateNotification("Teleport Failed", "An error occurred during teleportation: " .. err, 5, "error")
        return false
    end

    Utils:CreateNotification("Teleport Success", "Teleported to target location.", 2, "success")
    return true
end

--- Calculates the distance from the local player's HumanoidRootPart to a given position.
-- @param position Vector3 The target position.
-- @return number The distance, or math.huge if character/HRP not found.
function Utils:GetDistanceFromPlayer(position)
    local character = LocalPlayer.Character
    if not character then return math.huge end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end

    return (hrp.Position - position).Magnitude
end

--- Simulates a mouse click.
function Utils:MouseClick()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

--- Simulates a key press.
-- @param key string|Enum.KeyCode The key to press.
function Utils:PressKey(key)
    key = typeof(key) == "EnumItem" and key or Enum.KeyCode[key]
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(0.07)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

--- Finds the closest object with a given name in the workspace.
-- @param objectName string The name of the object to find.
-- @param minDistance number (optional) Minimum distance for the object to be considered (default 0).
-- @param ignoreDistanceFrom Vector3 (optional) Position to ignore objects too close to (default LocalPlayer.Character.HumanoidRootPart.Position).
-- @return Instance|nil The closest object, or nil if none found.
function Utils:GetClosestObject(objectName, minDistance, ignoreDistanceFrom)
    minDistance = minDistance or 0
    ignoreDistanceFrom = ignoreDistanceFrom or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position) or Vector3.new(0,0,0)

    local closestObj = nil
    local shortestDist = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == objectName then
            local objPos = nil
            if obj:IsA("BasePart") then
                objPos = obj.Position
            elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                    objPos = obj.PrimaryPart.Position
                else
                    -- Fallback: Find any BasePart inside the Model
                    for _, part in ipairs(obj:GetChildren()) do
                        if part:IsA("BasePart") then
                            objPos = part.Position
                            break
                        end
                    end
                end
            end

            if objPos then
                local dist = (objPos - ignoreDistanceFrom).Magnitude
                if dist >= minDistance and dist < shortestDist then
                    closestObj = obj
                    shortestDist = dist
                end
            end
        end
    end
    return closestObj
end

--endregion

--region -- ESP System --

local ESPManager = {
    Items = {},
    NPCs = {},
    ItemESPEnabled = false,
    NPCESPEnabled = false,
    RenderConnection = nil
}

--- Creates visual ESP for an item.
-- @param item Instance The item to create ESP for.
function ESPManager:CreateItemESP(item)
    if not item or (not item:IsA("Model") and not item:IsA("BasePart")) then return end

    local adorneePart = item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") or item
    if not adorneePart then return end

    if ESPManager.Items[item] then return end -- Already has ESP

    -- Create BillboardGui for text
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProfessionalESP_Billboard"
    billboard.Adornee = adorneePart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.ExtentsOffset = Vector3.new(0, adorneePart.Size.Y / 2, 0) -- Offset above the part

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = item.Name .. (Config.ESP.ShowDistance and " (" .. math.floor(Utils:GetDistanceFromPlayer(adorneePart.Position)) .. "m)" or "")
    label.BackgroundTransparency = 1
    label.TextColor3 = Config.ESP.ItemColor
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.ZIndex = 2

    -- Create Highlight for glow effect
    local highlight = Instance.new("Highlight")
    highlight.Name = "ProfessionalESP_Highlight"
    highlight.FillColor = Config.ESP.ItemColor
    highlight.OutlineColor = Config.ESP.ItemColor
    highlight.FillTransparency = Config.ESP.Transparency
    highlight.OutlineTransparency = 0
    highlight.Adornee = item
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true

    billboard.Parent = item
    highlight.Parent = item

    ESPManager.Items[item] = {
        Billboard = billboard,
        Highlight = highlight,
        LastDistance = Utils:GetDistanceFromPlayer(adorneePart.Position)
    }

    -- Cleanup on item removal
    item.AncestryChanged:Connect(function(_, parent)
        if not parent then
            ESPManager:RemoveItemESP(item)
        end
    end)
end

--- Removes item ESP visuals.
-- @param item Instance The item whose ESP to remove.
function ESPManager:RemoveItemESP(item)
    if ESPManager.Items[item] then
        if ESPManager.Items[item].Billboard then
            ESPManager.Items[item].Billboard:Destroy()
        end
        if ESPManager.Items[item].Highlight then
            ESPManager.Items[item].Highlight:Destroy()
        end
        ESPManager.Items[item] = nil
    end
end

--- Creates visual ESP for an NPC.
-- @param npc Model The NPC to create ESP for.
function ESPManager:CreateNPCESP(npc)
    if not npc or not npc:IsA("Model") then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    if ESPManager.NPCs[npc] then return end -- Already has ESP

    -- Create 3D Box ESP (using Drawing library for better performance/control)
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = Config.ESP.NPCColor
    box.Filled = false
    box.Visible = false
    box.ZIndex = 2

    -- Create name label
    local nameText = Drawing.new("Text")
    nameText.Text = npc.Name
    nameText.Color = Config.ESP.NPCColor
    nameText.Size = Config.ESP.TextSize
    nameText.Center = true
    nameText.Outline = true
    nameText.Visible = false
    nameText.Font = Drawing.Fonts.Plex
    nameText.ZIndex = 2

    -- Create health bar background
    local healthBarBG = Drawing.new("Square")
    healthBarBG.Thickness = 1
    healthBarBG.Color = Color3.fromRGB(50, 50, 50)
    healthBarBG.Filled = true
    healthBarBG.Visible = false
    healthBarBG.ZIndex = 2

    -- Create health bar
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Color = Config.UI.SuccessColor -- Green for health
    healthBar.Filled = true
    healthBar.Visible = false
    healthBar.ZIndex = 3 -- Above background

    ESPManager.NPCs[npc] = {
        Box = box,
        Name = nameText,
        HealthBarBG = healthBarBG,
        HealthBar = healthBar,
        Humanoid = humanoid,
        LastPosition = hrp.Position
    }

    -- Cleanup on NPC removal
    npc.AncestryChanged:Connect(function(_, parent)
        if not parent then
            ESPManager:RemoveNPCESP(npc)
        end
    end)
end

--- Removes NPC ESP visuals.
-- @param npc Model The NPC whose ESP to remove.
function ESPManager:RemoveNPCESP(npc)
    if ESPManager.NPCs[npc] then
        ESPManager.NPCs[npc].Box:Remove()
        ESPManager.NPCs[npc].Name:Remove()
        ESPManager.NPCs[npc].HealthBarBG:Remove()
        ESPManager.NPCs[npc].HealthBar:Remove()
        ESPManager.NPCs[npc] = nil
    end
end

--- Updates all active ESP visuals.
function ESPManager:UpdateESP()
    -- Update Item ESP
    for item, data in pairs(ESPManager.Items) do
        if not item or not item.Parent then
            ESPManager:RemoveItemESP(item)
            continue
        end
        local adorneePart = item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart") or item
        if not adorneePart then
            ESPManager:RemoveItemESP(item)
            continue
        end

        local distance = Utils:GetDistanceFromPlayer(adorneePart.Position)
        local shouldBeVisible = distance <= Config.ESP.Distance and ESPManager.ItemESPEnabled

        if data.Billboard.Visible ~= shouldBeVisible then
            data.Billboard.Visible = shouldBeVisible
            data.Highlight.Enabled = shouldBeVisible
        end

        if shouldBeVisible then
            data.Billboard.Adornee = adorneePart -- Update adornee in case part changed
            data.Highlight.Adornee = item -- Update adornee in case part changed
            data.Billboard.StudsOffset = Vector3.new(0, adorneePart.Size.Y / 2 + 0.5, 0) -- Adjust offset dynamically
            data.Billboard.Size = UDim2.new(0, 200, 0, Config.ESP.TextSize + 10) -- Adjust size based on text size
            data.Billboard.AlwaysOnTop = true
            data.Highlight.FillTransparency = Config.ESP.Transparency
            data.Highlight.OutlineTransparency = 0

            local label = data.Billboard:FindFirstChildOfClass("TextLabel")
            if label then
                label.Text = item.Name .. (Config.ESP.ShowDistance and " (" .. math.floor(distance) .. "m)" or "")
                label.TextColor3 = Config.ESP.ItemColor
                label.TextSize = Config.ESP.TextSize
            end
            data.Highlight.FillColor = Config.ESP.ItemColor
            data.Highlight.OutlineColor = Config.ESP.ItemColor
        end
    end

    -- Update NPC ESP
    for npc, data in pairs(ESPManager.NPCs) do
        if not npc or not npc.Parent or not data.Humanoid or data.Humanoid.Health <= 0 then
            ESPManager:RemoveNPCESP(npc)
            continue
        end
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if not hrp then
            ESPManager:RemoveNPCESP(npc)
            continue
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local distance = Utils:GetDistanceFromPlayer(hrp.Position)
        local shouldBeVisible = onScreen and distance <= Config.ESP.Distance and ESPManager.NPCESPEnabled

        data.Box.Visible = shouldBeVisible
        data.Name.Visible = shouldBeVisible
        data.HealthBarBG.Visible = shouldBeVisible and Config.ESP.ShowHealth
        data.HealthBar.Visible = shouldBeVisible and Config.ESP.ShowHealth

        if shouldBeVisible then
            -- Calculate 3D box dimensions and screen position
            local headPos = npc:FindFirstChild("Head") and npc.Head.Position or hrp.Position
            local bodyHeight = (hrp.Position.Y - headPos.Y) * 2 -- Approximate body height
            local bodyWidth = 2 -- Approximate body width

            local topPos = headPos + Vector3.new(0, bodyHeight / 2, 0)
            local bottomPos = hrp.Position - Vector3.new(0, hrp.Size.Y / 2, 0)

            local topScreen, topOnScreen = Camera:WorldToViewportPoint(topPos)
            local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

            if topOnScreen and bottomOnScreen then
                local height = math.abs(topScreen.Y - bottomScreen.Y)
                local width = height / 2 -- Aspect ratio for humanoid box

                data.Box.Size = Vector2.new(width, height)
                data.Box.Position = Vector2.new(bottomScreen.X - width / 2, topScreen.Y)
                data.Box.Color = Config.ESP.NPCColor

                data.Name.Text = npc.Name .. (Config.ESP.ShowDistance and " (" .. math.floor(distance) .. "m)" or "")
                data.Name.Position = Vector2.new(screenPos.X, topScreen.Y - 15)
                data.Name.Color = Config.ESP.NPCColor
                data.Name.Size = Config.ESP.TextSize

                if Config.ESP.ShowHealth then
                    local healthRatio = data.Humanoid.Health / data.Humanoid.MaxHealth
                    local healthBarHeight = height
                    local healthBarWidth = 5 -- Fixed width for health bar

                    data.HealthBarBG.Size = Vector2.new(healthBarWidth, healthBarHeight)
                    data.HealthBarBG.Position = Vector2.new(data.Box.Position.X - healthBarWidth - 2, data.Box.Position.Y)

                    data.HealthBar.Size = Vector2.new(healthBarWidth, healthBarHeight * healthRatio)
                    data.HealthBar.Position = Vector2.new(data.Box.Position.X - healthBarWidth - 2, data.Box.Position.Y + (healthBarHeight * (1 - healthRatio)))
                    data.HealthBar.Color = Color3.fromRGB(255 * (1 - healthRatio), 255 * healthRatio, 0) -- Green to Red gradient
                end
            else
                data.Box.Visible = false
                data.Name.Visible = false
                data.HealthBarBG.Visible = false
                data.HealthBar.Visible = false
            end
        end
    end
end

--- Toggles Item ESP on/off.
-- @param enabled boolean Whether to enable or disable.
function ESPManager:ToggleItemESP(enabled)
    ESPManager.ItemESPEnabled = enabled
    if enabled then
        -- Initial scan for items
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") or obj:IsA("BasePart") then
                -- Add specific item filtering here if needed, e.g., obj.Name == "Log" or obj.Name == "Trunk"
                -- For now, it will try to create ESP for all models/parts, which might be too broad.
                -- Refine this based on actual game items.
                if obj.Name == "Log" or obj.Name == "Trunk" or obj.Name == "Rock" or obj.Name == "Mushroom" then
                    ESPManager:CreateItemESP(obj)
                end
            end
        end
    else
        -- Remove all existing item ESP
        for item, _ in pairs(ESPManager.Items) do
            ESPManager:RemoveItemESP(item)
        end
    end
    Utils:CreateNotification("Item ESP", enabled and "Item ESP Enabled" or "Item ESP Disabled", 3, "info")
end

--- Toggles NPC ESP on/off.
-- @param enabled boolean Whether to enable or disable.
function ESPManager:ToggleNPCESP(enabled)
    ESPManager.NPCESPEnabled = enabled
    if enabled then
        -- Initial scan for NPCs
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                ESPManager:CreateNPCESP(obj)
            end
        end
    else
        -- Remove all existing NPC ESP
        for npc, _ in pairs(ESPManager.NPCs) do
            ESPManager:RemoveNPCESP(npc)
        end
    end
    Utils:CreateNotification("NPC ESP", enabled and "NPC ESP Enabled" or "NPC ESP Disabled", 3, "info")
end

-- Start/Stop ESP rendering loop
RunService.RenderStepped:Connect(function()
    if ESPManager.ItemESPEnabled or ESPManager.NPCESPEnabled then
        ESPManager:UpdateESP()
    end
end)

--endregion

--region -- Aimbot System --

local AimbotManager = {
    Target = nil,
    FOVCircle = nil,
    LastCheckTime = 0
}

--- Draws the FOV circle.
function AimbotManager:DrawFOV()
    if not AimbotManager.FOVCircle then
        AimbotManager.FOVCircle = Drawing.new("Circle")
        AimbotManager.FOVCircle.Radius = Config.Aimbot.FOV
        AimbotManager.FOVCircle.Color = Config.Aimbot.TargetColor
        AimbotManager.FOVCircle.Thickness = 2
        AimbotManager.FOVCircle.Filled = false
        AimbotManager.FOVCircle.Visible = false
        AimbotManager.FOVCircle.ZIndex = 4
    end
    AimbotManager.FOVCircle.Radius = Config.Aimbot.FOV
    AimbotManager.FOVCircle.Color = Config.Aimbot.TargetColor
    AimbotManager.FOVCircle.Position = UserInputService:GetMouseLocation()
    AimbotManager.FOVCircle.Visible = Config.Aimbot.DrawFOV and Config.Aimbot.Enabled
end

--- Finds the best target for aimbot.
-- @return Model|nil The best target NPC, or nil.
function AimbotManager:FindTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LocalPlayer.Character then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid.Health <= 0 then continue end

            local targetPart = obj:FindFirstChild(Config.Aimbot.TargetPart) or obj:FindFirstChild("HumanoidRootPart")
            if not targetPart then continue end

            -- Check if target is in the configured list
            local isTarget = false
            for _, targetName in ipairs(Config.Aimbot.Targets) do
                if obj.Name:lower():find(targetName:lower()) then
                    isTarget = true
                    break
                end
            end
            if not isTarget then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < shortestDistance and dist <= Config.Aimbot.FOV then
                    shortestDistance = dist
                    closestTarget = targetPart
                end
            end
        end
    end
    return closestTarget
end

--- Updates the aimbot logic.
function AimbotManager:UpdateAimbot()
    local currentTime = tick()
    if currentTime - AimbotManager.LastCheckTime < Config.Aimbot.CheckInterval then
        return
    end
    AimbotManager.LastCheckTime = currentTime

    AimbotManager:DrawFOV()

    if not Config.Aimbot.Enabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        AimbotManager.Target = nil
        if AimbotManager.FOVCircle then AimbotManager.FOVCircle.Visible = false end
        return
    end

    AimbotManager.Target = AimbotManager:FindTarget()

    if AimbotManager.Target then
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, AimbotManager.Target.Position)
        Camera.CFrame = currentCF:Lerp(targetCF, Config.Aimbot.Smoothness)
    end
end

-- Aimbot rendering loop
RunService.RenderStepped:Connect(function()
    AimbotManager:UpdateAimbot()
end)

--endregion

--region -- Farming Systems --

local FarmingManager = {
    AutoTreeFarmActive = false,
    AutoLogFarmActive = false,
    BadTrees = {}, -- Trees that timed out or caused issues
    LogDropLocations = {
        Campfire = CFrame.new(0, 10, 0),
        Grinder = CFrame.new(16.1, 4, -4.6)
    }
}

--- Gets the current bag's log pickup count.
-- @return number The number of logs the current bag can hold.
function FarmingManager:GetBagPickupCount()
    if Config.Farming.LogBagType == "Old Sack" then
        return 5
    elseif Config.Farming.LogBagType == "Good Sack" then
        return 15
    elseif Config.Farming.LogBagType == "Auto" then
        -- Attempt to detect equipped bag type
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        local character = LocalPlayer.Character
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item.Name == "Good Sack" then return 15 end
                if item.Name == "Old Sack" then return 5 end
            end
        end
        if character then
            for _, item in ipairs(character:GetChildren()) do
                if item.Name == "Good Sack" then return 15 end
                if item.Name == "Old Sack" then return 5 end
            end
        end
        Utils:CreateNotification("Auto Log Farm", "Could not detect bag type. Defaulting to 5 logs.", 3, "warning")
        return 5 -- Default if auto-detection fails
    end
    return 0
end

--- Auto Tree Farming logic.
task.spawn(function()
    while true do
        if FarmingManager.AutoTreeFarmActive then
            local trees = {}
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Trunk" and obj.Parent and obj.Parent.Name == "Small Tree" then
                    local distance = Utils:GetDistanceFromPlayer(obj.Position)
                    if distance > 5 and not FarmingManager.BadTrees[obj:GetFullName()] then -- Ensure not too close and not a bad tree
                        table.insert(trees, obj)
                    end
                end
            end

            table.sort(trees, function(a, b)
                return Utils:GetDistanceFromPlayer(a.Position) < Utils:GetDistanceFromPlayer(b.Position)
            end)

            if #trees > 0 then
                local trunk = trees[1] -- Target the closest tree
                Utils:CreateNotification("Auto Tree Farm", "Farming closest tree: " .. trunk.Name, 1, "info")

                local successTeleport = Utils:SafeTeleport(trunk.CFrame + Vector3.new(0, 3, 0))
                if not successTeleport then
                    FarmingManager.BadTrees[trunk:GetFullName()] = true -- Mark as bad if teleport fails
                    Utils:CreateNotification("Auto Tree Farm", "Failed to teleport to tree. Skipping.", 3, "warning")
                    task.wait(1)
                    continue
                end
                task.wait(0.2)

                local startTime = tick()
                while FarmingManager.AutoTreeFarmActive and trunk and trunk.Parent and trunk.Parent.Name == "Small Tree" do
                    Utils:MouseClick()
                    task.wait(0.2)
                    if tick() - startTime > Config.Farming.TreeFarmTimeout then
                        FarmingManager.BadTrees[trunk:GetFullName()] = true
                        Utils:CreateNotification("Auto Tree Farm", "Tree farming timed out for " .. trunk.Name .. ". Skipping.", 3, "warning")
                        break
                    end
                end
                task.wait(0.3)
            else
                Utils:CreateNotification("Auto Tree Farm", "No suitable trees found. Waiting...", 3, "info")
                task.wait(3) -- Wait longer if no trees are found
            end
        end
        task.wait(Config.Performance.UpdateInterval)
    end
end)

--- Auto Log Farming logic.
task.spawn(function()
    while true do
        if FarmingManager.AutoLogFarmActive then
            local pickupCount = FarmingManager:GetBagPickupCount()
            if pickupCount == 0 then
                Utils:CreateNotification("Auto Log Farm", "No sack type selected or found! Disabling.", 3, "error")
                FarmingManager.AutoLogFarmActive = false
                continue
            end

            local log = Utils:GetClosestObject("Log", 5) -- Get closest log, not too close
            if log then
                Utils:CreateNotification("Auto Log Farm", "Collecting logs from: " .. log.Name, 1, "info")
                local logPos = log.Position or (log.PrimaryPart and log.PrimaryPart.Position)
                if logPos then
                    local successTeleport = Utils:SafeTeleport(CFrame.new(logPos + Vector3.new(0, 2, 0))) -- Teleport 2 studs above log
                    if not successTeleport then
                        Utils:CreateNotification("Auto Log Farm", "Failed to teleport to log. Skipping.", 3, "warning")
                        task.wait(1)
                        continue
                    end
                    task.wait(0.5)

                    -- Move mouse to feet (approximate for interaction)
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local footPos = hrp.Position - Vector3.new(0, 3, 0)
                        local screen = Camera:WorldToScreenPoint(footPos)
                        VirtualInputManager:SendMouseMoveEvent(screen.X, screen.Y, game)
                        task.wait(0.25)
                    end

                    -- Pickup logs (F then E, x times)
                    for i = 1, pickupCount do
                        Utils:PressKey("F")
                        Utils:PressKey("E")
                        task.wait(0.13)
                    end

                    -- Teleport to drop location
                    local dropCFrame = FarmingManager.LogDropLocations[Config.Farming.LogDropLocation]
                    if dropCFrame then
                        Utils:CreateNotification("Auto Log Farm", "Teleporting to " .. Config.Farming.LogDropLocation .. " to drop logs.", 1, "info")
                        Utils:SafeTeleport(dropCFrame)
                        task.wait(2) -- Wait for logs to be processed
                    else
                        Utils:CreateNotification("Auto Log Farm", "Invalid log drop location configured.", 3, "error")
                    end
                end
            else
                Utils:CreateNotification("Auto Log Farm", "No logs found. Waiting...", 3, "info")
                task.wait(3) -- Wait longer if no logs are found
            end
        end
        task.wait(Config.Performance.UpdateInterval)
    end
end)

--endregion

--region -- Movement Systems --

local MovementManager = {
    FlyConnection = nil
}

--- Sets the player's walk speed.
-- @param speed number The desired walk speed.
function MovementManager:SetWalkSpeed(speed)
    Config.Movement.WalkSpeed = speed
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end
end

--- Starts the fly mode.
function MovementManager:StartFlying()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true -- Prevent falling
    end

    local bodyGyro = Instance.new("BodyGyro", hrp)
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = hrp.CFrame

    local bodyVelocity = Instance.new("BodyVelocity", hrp)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    MovementManager.FlyConnection = RunService.RenderStepped:Connect(function()
        local moveVec = Vector3.zero
        local camCF = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += camCF.UpVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= camCF.UpVector end
        bodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * Config.Movement.FlySpeed or Vector3.zero
        bodyGyro.CFrame = camCF
    end)
end

--- Stops the fly mode.
function MovementManager:StopFlying()
    if MovementManager.FlyConnection then
        MovementManager.FlyConnection:Disconnect()
        MovementManager.FlyConnection = nil
    end
    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in pairs(hrp:GetChildren()) do
                if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then v:Destroy() end
            end
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false -- Allow falling again
        end
    end
end

--- Toggles fly mode on/off.
-- @param state boolean Whether to enable or disable fly.
function MovementManager:ToggleFly(state)
    Config.Movement.FlyEnabled = state
    if state then
        MovementManager:StartFlying()
        Utils:CreateNotification("Fly", "Fly Enabled (WASD + Space/Shift)", 3, "success")
    else
        MovementManager:StopFlying()
        Utils:CreateNotification("Fly", "Fly Disabled", 3, "info")
    end
end

-- Apply speed on character spawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.WalkSpeed = Config.Movement.WalkSpeed
        end
    end)
end)

-- Keybind for toggling fly (Q)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        MovementManager:ToggleFly(not Config.Movement.FlyEnabled)
    end
end)

--endregion

--region -- Anti-Death System --

local AntiDeathManager = {
    DetectionCircle = nil,
    DetectionConnection = nil
}

--- Initializes the visual detection circle for Anti-Death.
function AntiDeathManager:InitDetectionCircle()
    if not AntiDeathManager.DetectionCircle then
        local circlePart = Instance.new("Part")
        circlePart.Name = "AntiDeathCircle"
        circlePart.Anchored = true
        circlePart.CanCollide = false
        circlePart.Transparency = 0.7
        circlePart.Material = Enum.Material.Neon
        circlePart.Color = Config.UI.ErrorColor
        circlePart.Parent = workspace

        local mesh = Instance.new("SpecialMesh", circlePart)
        mesh.MeshType = Enum.MeshType.Cylinder
        mesh.Scale = Vector3.new(Config.AntiDeath.Radius * 2, 0.2, Config.AntiDeath.Radius * 2)

        AntiDeathManager.DetectionCircle = circlePart
        AntiDeathManager.DetectionMesh = mesh
    end
end

--- Updates the visual detection circle's position and size.
function AntiDeathManager:UpdateDetectionCircle()
    if not AntiDeathManager.DetectionCircle then
        AntiDeathManager:InitDetectionCircle()
    end

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        AntiDeathManager.DetectionCircle.Position = Vector3.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
        AntiDeathManager.DetectionMesh.Scale = Vector3.new(Config.AntiDeath.Radius * 2, 0.2, Config.AntiDeath.Radius * 2)
        AntiDeathManager.DetectionCircle.Transparency = Config.AntiDeath.Enabled and 0.5 or 1
    else
        AntiDeathManager.DetectionCircle.Transparency = 1
    end
end

--- Anti-Death teleport logic.
task.spawn(function()
    AntiDeathManager:InitDetectionCircle() -- Ensure circle is initialized early
    while true do
        AntiDeathManager:UpdateDetectionCircle() -- Always update circle position

        if Config.AntiDeath.Enabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local playerPos = hrp.Position
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LocalPlayer.Character then
                        local npcHumanoid = obj:FindFirstChildOfClass("Humanoid")
                        local npcName = obj.Name
                        local npcHrp = obj:FindFirstChild("HumanoidRootPart")

                        if npcHumanoid and npcHumanoid.Health > 0 and npcHrp and Config.AntiDeath.Threats[npcName] then
                            local npcPos = npcHrp.Position
                            if (npcPos - playerPos).Magnitude <= Config.AntiDeath.Radius then
                                Utils:CreateNotification("Anti-Death Triggered", "Threat detected! Teleporting to safety.", 3, "warning")
                                Utils:SafeTeleport(Config.AntiDeath.TeleportLocation)
                                break -- Teleported, break and re-evaluate next tick
                            end
                        end
                    end
                end
            end
        end
        task.wait(Config.Performance.UpdateInterval)
    end
end)

--endregion

--region -- Visual Enhancements --

local VisualsManager = {}

--- Toggles fog on/off.
-- @param enabled boolean Whether to enable or disable no fog.
function VisualsManager:ToggleNoFog(enabled)
    Config.Visuals.NoFog = enabled
    if enabled then
        Lighting.FogStart = 999999
        Lighting.FogEnd = 1000000
        Utils:CreateNotification("Visuals", "No Fog Enabled", 2, "success")
    else
        Lighting.FogStart = Config.Visuals.DefaultFogStart
        Lighting.FogEnd = Config.Visuals.DefaultFogEnd
        Utils:CreateNotification("Visuals", "Fog Restored", 2, "info")
    end
end

--endregion

--region -- UI Initialization --

local Window = Rayfield:CreateWindow({
    Name = "99 Nights in the Forest - Professional Edition",
    LoadingTitle = "BLACKBOXAI",
    LoadingSubtitle = "Enhanced User Experience",
    Icon = 4483362458, -- Custom icon for the UI
    Theme = {
        PrimaryColor = Config.UI.PrimaryColor,
        SecondaryColor = Config.UI.SecondaryColor,
        AccentColor = Config.UI.AccentColor,
        TextColor = Config.UI.TextColor
    },
    ConfigurationSaving = {
        Enabled = true,
        FileName = "99Nights_Professional"
    },
    KeySystem = false -- Set to true if you want to implement a key system
})

-- Home Tab
local HomeTab = Window:CreateTab("🏠 Home", 4483362458)

HomeTab:CreateSection("Teleportation")
HomeTab:CreateButton({
    Name = "Teleport to Campfire",
    Callback = function()
        Utils:SafeTeleport(FarmingManager.LogDropLocations.Campfire)
    end
})
HomeTab:CreateButton({
    Name = "Teleport to Grinder",
    Callback = function()
        Utils:SafeTeleport(FarmingManager.LogDropLocations.Grinder)
    end
})

HomeTab:CreateSection("Movement")
HomeTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = Config.Movement.WalkSpeed,
    Callback = function(value)
        MovementManager:SetWalkSpeed(value)
    end
})
HomeTab:CreateToggle({
    Name = "Fly (Q Keybind)",
    CurrentValue = Config.Movement.FlyEnabled,
    Callback = function(value)
        MovementManager:ToggleFly(value)
    end
})

HomeTab:CreateSection("Visuals & ESP")
HomeTab:CreateToggle({
    Name = "Item ESP",
    CurrentValue = ESPManager.ItemESPEnabled,
    Callback = function(value)
        ESPManager:ToggleItemESP(value)
    end
})
HomeTab:CreateToggle({
    Name = "NPC ESP",
    CurrentValue = ESPManager.NPCESPEnabled,
    Callback = function(value)
        ESPManager:ToggleNPCESP(value)
    end
})
HomeTab:CreateToggle({
    Name = "No Fog (Clear Skies)",
    CurrentValue = Config.Visuals.NoFog,
    Callback = function(value)
        VisualsManager:ToggleNoFog(value)
    end
})

-- Farming Tab
local FarmingTab = Window:CreateTab("🌳 Farming", 4483362458)

FarmingTab:CreateSection("Auto Tree Farming")
FarmingTab:CreateToggle({
    Name = "Auto Tree Farm (Small Tree)",
    CurrentValue = FarmingManager.AutoTreeFarmActive,
    Callback = function(value)
        FarmingManager.AutoTreeFarmActive = value
        Utils:CreateNotification("Auto Tree Farm", value and "Enabled" or "Disabled", 3, "info")
    end
})
FarmingTab:CreateSlider({
    Name = "Tree Farm Timeout (s)",
    Range = {5, 60},
    Increment = 1,
    Suffix = "s",
    CurrentValue = Config.Farming.TreeFarmTimeout,
    Callback = function(value)
        Config.Farming.TreeFarmTimeout = value
        Utils:CreateNotification("Tree Farm", "Timeout set to " .. value .. " seconds.", 2, "info")
    end
})

FarmingTab:CreateSection("Auto Log Farming")
FarmingTab:CreateToggle({
    Name = "Auto Log Farm",
    CurrentValue = FarmingManager.AutoLogFarmActive,
    Callback = function(value)
        FarmingManager.AutoLogFarmActive = value
        Utils:CreateNotification("Auto Log Farm", value and "Enabled" or "Disabled", 3, "info")
    end
})
FarmingTab:CreateDropdown({
    Name = "Log Bag Type",
    Options = {"Auto", "Old Sack", "Good Sack"},
    CurrentOption = Config.Farming.LogBagType,
    Callback = function(value)
        Config.Farming.LogBagType = value
        Utils:CreateNotification("Log Farm", "Bag type set to: " .. value, 2, "info")
    end
})
FarmingTab:CreateDropdown({
    Name = "Log Drop Location",
    Options = {"Campfire", "Grinder"},
    CurrentOption = Config.Farming.LogDropLocation,
    Callback = function(value)
        Config.Farming.LogDropLocation = value
        Utils:CreateNotification("Log Farm", "Drop location set to: " .. value, 2, "info")
    end
})

-- Combat Tab
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

CombatTab:CreateSection("Aimbot Settings")
CombatTab:CreateToggle({
    Name = "Aimbot (Right Click)",
    CurrentValue = Config.Aimbot.Enabled,
    Callback = function(value)
        Config.Aimbot.Enabled = value
        Utils:CreateNotification("Aimbot", value and "Enabled - Hold Right Click to aim." or "Disabled.", 3, "info")
    end
})
CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {50, 500},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Config.Aimbot.FOV,
    Callback = function(value)
        Config.Aimbot.FOV = value
    end
})
CombatTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = Config.Aimbot.Smoothness,
    Callback = function(value)
        Config.Aimbot.Smoothness = value
    end
})
CombatTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = Config.Aimbot.TargetPart,
    Callback = function(value)
        Config.Aimbot.TargetPart = value
        Utils:CreateNotification("Aimbot", "Target part set to: " .. value, 2, "info")
    end
})
CombatTab:CreateToggle({
    Name = "Draw FOV Circle",
    CurrentValue = Config.Aimbot.DrawFOV,
    Callback = function(value)
        Config.Aimbot.DrawFOV = value
    end
})

CombatTab:CreateSection("Anti-Death System")
CombatTab:CreateToggle({
    Name = "Anti Death Teleport",
    CurrentValue = Config.AntiDeath.Enabled,
    Callback = function(value)
        Config.AntiDeath.Enabled = value
        Utils:CreateNotification("Anti Death", value and "Enabled" or "Disabled", 3, "info")
    end
})
CombatTab:CreateSlider({
    Name = "Detection Radius",
    Range = {10, 200},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = Config.AntiDeath.Radius,
    Callback = function(value)
        Config.AntiDeath.Radius = value
    end
})
CombatTab:CreateDropdown({
    Name = "Safe Teleport Location",
    Options = {"Campfire", "Grinder"},
    CurrentOption = Config.Farming.LogDropLocation, -- Reusing this config for consistency
    Callback = function(value)
        Config.AntiDeath.TeleportLocation = FarmingManager.LogDropLocations[value]
        Utils:CreateNotification("Anti Death", "Safe location set to: " .. value, 2, "info")
    end
})

CombatTab:CreateSection("Threat Management")
for npcName, _ in pairs(Config.AntiDeath.Threats) do
    CombatTab:CreateToggle({
        Name = "Avoid " .. npcName,
        CurrentValue = Config.AntiDeath.Threats[npcName],
        Callback = function(value)
            Config.AntiDeath.Threats[npcName] = value
            Utils:CreateNotification("Threat Management", (value and "Now avoiding " or "No longer avoiding ") .. npcName, 2, "info")
        end
    })
end

--endregion

--region -- Initial Setup and Cleanup --

-- Apply initial walk speed
MovementManager:SetWalkSpeed(Config.Movement.WalkSpeed)

-- Ensure detection circle is updated on UI load
AntiDeathManager:UpdateDetectionCircle()

--endregion
