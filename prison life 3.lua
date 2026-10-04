--[[
    ✨ AURA HUB v10 — MY UI EDITION ✨
    Все функции встроены в библиотеку my ui v3
    Всё сохраняется в конфигах автоматически
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if LocalPlayer.PlayerGui:FindFirstChild("AlphaHub") then
    LocalPlayer.PlayerGui.AlphaHub:Destroy()
end

-- ==================================================
-- ПРОВЕРКИ
-- ==================================================
local HAS_DRAWING = false
pcall(function()
    if Drawing and Drawing.new then
        local t = Drawing.new("Square"); t:Remove(); HAS_DRAWING = true
    end
end)

local HAS_FILE = false
pcall(function()
    if writefile and readfile and isfile then HAS_FILE = true end
end)

local HAS_HOOK = false
pcall(function()
    if hookfunction and getgc then HAS_HOOK = true end
end)

local HAS_FILTERGC = false
pcall(function()
    if filtergc then local f = filtergc("function", {Name = "castRay"}, true); HAS_FILTERGC = f ~= nil end
end)

local HAS_GETCONNECTIONS = false
pcall(function()
    if getconnections then HAS_GETCONNECTIONS = true end
end)

local camera = Workspace.CurrentCamera
while not camera do RunService.RenderStepped:Wait(); camera = Workspace.CurrentCamera end
local defaultFOV = camera.FieldOfView

-- ==================================================
-- REMOTES
-- ==================================================
local remotes = {}
pcall(function()
    local GunRemotes = ReplicatedStorage:FindFirstChild("GunRemotes")
    if GunRemotes then
        remotes.remote = GunRemotes:FindFirstChild("ShootEvent")
        remotes.tasedremote = GunRemotes:FindFirstChild("PlayerTased")
    end
    local Rem = ReplicatedStorage:FindFirstChild("Remotes")
    if Rem then remotes.arrestremote = Rem:FindFirstChild("ArrestPlayer") end
    remotes.meleeremote = ReplicatedStorage:FindFirstChild("meleeEvent")
end)

-- ==================================================
-- ЦВЕТА UI
-- ==================================================
local BG = Color3.fromRGB(16, 16, 18)
local BG2 = Color3.fromRGB(22, 22, 26)
local BG3 = Color3.fromRGB(30, 30, 35)
local SIDEBAR = Color3.fromRGB(14, 14, 16)
local ACCENT = Color3.fromRGB(0, 180, 255)
local TEXT = Color3.fromRGB(245, 245, 250)
local TEXT2 = Color3.fromRGB(130, 130, 135)
local BORDER = Color3.fromRGB(35, 35, 40)

-- ==================================================
-- СОСТОЯНИЕ
-- ==================================================
local pages = {}
local sideButtonsList = {}
local currentSideTab = "Movement"
local allCardsList = {}
local favoriteClonesList = {}
local configState = {}
local currentTarget = nil

-- WalkSpeed / Jump
local walkSpeedEnabled = false
local currentWalkSpeedVal = 16
local DEFAULT_WALKSPEED = 16
local jumpPowerEnabled = false
local currentJumpPowerVal = 50
local DEFAULT_JUMPPOWER = 50
local infiniteJumpEnabled = false
local infiniteJumpConn = nil
local watchdogConn = nil

-- Spin
local spinEnabled = false
local spinSpeedVal = 10
local spinConnection = nil
local savedHumanoidSettings = nil

-- ESP
local espTeamCheck = true
local espBoxesEnabled = false
local espNamesEnabled = false
local espLinesEnabled = false
local espBoxesConn = nil
local espNamesConn = nil
local espLinesConn = nil
local ESP_BOXES, ESP_NAMES, ESP_LINES = {}, {}, {}

-- Spider
local spiderEnabled = false
local spiderConn = nil
local lastWallHit = false
local spiderClimbSpeed = 0.28
local spiderBoost = 22

-- Anti-Taze
local antiTazeEnabled = false
local antiTazeConnections = {}

-- Auto Keycard
local autoKeycardEnabled = false
local autoKeycardConn = nil
local autoKeycardRange = 20

-- Item Giver
local gettingGun = false
local autoGetGunEnabled = false
local autoGetGunConn = nil
local selectedGuns = {["M4A1"] = false, ["Remington 870"] = false, ["AK-47"] = false, ["MP5"] = false}

-- Silent Aim
local silentAimEnabled = false
local silentAimTeamCheck = true
local silentAimWallCheck = true
local silentAimFOV = 100
local silentAimMaxRange = 300
local silentAimAimPart = "Head"
local silentAimHitChance = 100
local silentAimIgnoreFriends = false
local silentAimIgnoreGuards = false
local silentAimIgnoreCriminals = false
local silentAimIgnoreInnocent = false
local silentAimIgnoreForceField = false
local silentAimHooked = false
local oldCastRay = nil
local friendCache = {}

-- Hitbox
local hitboxEnabled = false
local hitboxSize = 3
local hitboxVisual = true
local hitboxTeamCheck = false
local hitboxIgnoreFriends = false
local hitboxIgnoreGuards = false
local hitboxIgnoreCriminals = false
local hitboxIgnoreInnocent = false
local hitboxConn = nil
local savedHitboxSizes = {}

-- Aura
local arrestAuraEnabled = false
local arrestAuraRange = 7.5
local arrestIgnoreFriends = false
local arrestAuraConn = nil
local meleeAuraEnabled = false
local meleeAuraRange = 4
local meleeIgnoreFriends = false
local meleeAuraConn = nil

-- Camera / Lighting
local fovEnabled = false
local fovValue = 70
local fovConn = nil
local fullbrightEnabled = false
local fullbrightConn = nil
local savedLighting = {}
local vehicleSpeedEnabled = false
local vehicleSpeedValue = 100
local vehicleSpeedConn = nil

-- Weapons
local infiniteAmmoEnabled = false
local rapidFireEnabled = false
local instantReloadEnabled = false
local weaponHacksConn = nil

-- ==================================================
-- ХЕЛПЕРЫ
-- ==================================================
local function isFriends(userId)
    if friendCache[userId] ~= nil then return friendCache[userId] end
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(userId) end)
    friendCache[userId] = ok and res or false
    return friendCache[userId]
end

local function IsHostile(Char)
    local ok, Val = pcall(function() return Char:GetAttribute("Hostile") end)
    if ok and Val ~= nil then return Val == true end
    return false
end

local function IsTrespassing(Char)
    local ok, Val = pcall(function() return Char:GetAttribute("Trespassing") end)
    if ok and Val ~= nil then return Val == true end
    return false
end

-- ==================================================
-- WATCHDOG
-- ==================================================
local function startWatchdog()
    if watchdogConn then watchdogConn:Disconnect() watchdogConn = nil end
    watchdogConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if walkSpeedEnabled and hum.WalkSpeed ~= currentWalkSpeedVal then
            hum.WalkSpeed = currentWalkSpeedVal
        end
        if jumpPowerEnabled then
            if hum.UseJumpPower then
                if hum.JumpPower ~= currentJumpPowerVal then hum.JumpPower = currentJumpPowerVal end
            else
                local targetHeight = currentJumpPowerVal / 7.5
                if math.abs(hum.JumpHeight - targetHeight) > 0.1 then hum.JumpHeight = targetHeight end
            end
        end
    end)
end

-- ==================================================
-- WEAPON HACKS
-- ==================================================
local function getWeaponTools()
    local tools = {}
    local char = LocalPlayer.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end
    return tools
end

local function applyWeaponHacks(tool)
    if not tool or not tool:IsA("Tool") then return end
    local gunStates = tool:FindFirstChild("GunStates")
    if not gunStates then return end
    pcall(function()
        local env = getsenv(gunStates)
        if not env then return end
        if infiniteAmmoEnabled then env.MaxAmmo = math.huge; env.StoredAmmo = math.huge end
        if rapidFireEnabled then env.FireRate = 0.0001; env.AutoFire = true end
        if instantReloadEnabled then env.ReloadTime = 0.0001 end
    end)
    for _, obj in ipairs(tool:GetDescendants()) do
        pcall(function()
            if obj:IsA("NumberValue") then
                local n = obj.Name:lower()
                if infiniteAmmoEnabled and (n:find("ammo") or n:find("clip")) then obj.Value = 9999 end
                if rapidFireEnabled and n:find("firerate") then obj.Value = 0.0001 end
                if instantReloadEnabled and n:find("reload") then obj.Value = 0.0001 end
            end
        end)
    end
end

local function startWeaponHacks()
    if weaponHacksConn then weaponHacksConn:Disconnect() weaponHacksConn = nil end
    if not (infiniteAmmoEnabled or rapidFireEnabled or instantReloadEnabled) then return end
    local function applyAll()
        for _, tool in ipairs(getWeaponTools()) do applyWeaponHacks(tool) end
    end
    applyAll()
    weaponHacksConn = RunService.Heartbeat:Connect(applyAll)
end

-- ==================================================
-- ITEM GIVER
-- ==================================================
local function getGun(toolName)
    if gettingGun then return end
    gettingGun = true
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and root) then gettingGun = false return end
    if char:FindFirstChild("ForceField") then gettingGun = false return end
    if LocalPlayer.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName) then gettingGun = false return end
    local giver
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "TouchGiver" and v:GetAttribute("ToolName") == toolName then
            giver = v:FindFirstChildWhichIsA("BasePart"); break
        end
    end
    if not giver then gettingGun = false return end
    local origGiverCF = giver.CFrame
    local oldCharCF = root.CFrame
    local underground = origGiverCF - Vector3.new(0, 15.5, 0)
    giver.CanTouch = true
    giver.CFrame = underground
    char:PivotTo(underground + Vector3.new(0, 5, 0))
    task.wait(0.25)
    pcall(function() firetouchinterest(giver, root, 0) end)
    task.wait(0.3)
    pcall(function() firetouchinterest(giver, root, 1) end)
    task.wait(0.05)
    giver.CFrame = origGiverCF
    char:PivotTo(oldCharCF)
    task.wait(0.1)
    gettingGun = false
end

local function startAutoGetGun()
    if autoGetGunConn then task.cancel(autoGetGunConn) autoGetGunConn = nil end
    if not autoGetGunEnabled then return end
    autoGetGunConn = task.spawn(function()
        while autoGetGunEnabled do
            task.wait(1)
            for name, enabled in pairs(selectedGuns) do
                if enabled then getGun(name) end
            end
        end
    end)
end

-- ==================================================
-- ARREST AURA
-- ==================================================
local function isArrestable(P)
    if not P.Character then return false end
    local hum = P.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local display = hum.DisplayName
    if P.Team and P.Team.Name == "Criminals" then return true end
    if display:find("🔗", 1, true) or display:find("💢", 1, true) then return true end
    return false
end

local function startArrestAura()
    if arrestAuraConn then arrestAuraConn:Disconnect() arrestAuraConn = nil end
    if not arrestAuraEnabled or not remotes.arrestremote then return end
    arrestAuraConn = RunService.Heartbeat:Connect(function()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _, P in ipairs(Players:GetPlayers()) do
            if P == LocalPlayer or not P.Character then continue end
            if arrestIgnoreFriends and isFriends(P.UserId) then continue end
            if isArrestable(P) then
                local hrp = P.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (myRoot.Position - hrp.Position).Magnitude <= arrestAuraRange then
                    pcall(function() remotes.arrestremote:InvokeServer(P) end)
                end
            end
        end
    end)
end

-- ==================================================
-- MELEE AURA
-- ==================================================
local function startMeleeAura()
    if meleeAuraConn then meleeAuraConn:Disconnect() meleeAuraConn = nil end
    if not meleeAuraEnabled or not remotes.meleeremote then return end
    meleeAuraConn = RunService.Heartbeat:Connect(function()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        for _, P in ipairs(Players:GetPlayers()) do
            if P == LocalPlayer or not P.Character then continue end
            if meleeIgnoreFriends and isFriends(P.UserId) then continue end
            local hrp = P.Character:FindFirstChild("HumanoidRootPart")
            local hum = P.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and (myRoot.Position - hrp.Position).Magnitude <= meleeAuraRange then
                pcall(function() remotes.meleeremote:FireServer(P) end)
            end
        end
    end)
end

-- ==================================================
-- ANTI-TAZE
-- ==================================================
local function enableAntiTaze()
    if not HAS_GETCONNECTIONS or not remotes.tasedremote then return end
    pcall(function()
        for _, conn in pairs(getconnections(remotes.tasedremote.OnClientEvent)) do
            pcall(function() conn:Disable() table.insert(antiTazeConnections, conn) end)
        end
    end)
end

local function disableAntiTaze()
    for _, conn in ipairs(antiTazeConnections) do pcall(function() conn:Enable() end) end
    antiTazeConnections = {}
end

local function startAntiTaze()
    if antiTazeEnabled then enableAntiTaze() else disableAntiTaze() end
end

-- ==================================================
-- SILENT AIM
-- ==================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(tPart, org)
    if not tPart then return false end
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(org, tPart.Position - org, rayParams)
    return (not result) or result.Instance:IsDescendantOf(tPart.Parent)
end

local function canTargetAim(P)
    local Char = P.Character
    if not Char then return false end
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    if silentAimIgnoreForceField and Char:FindFirstChild("ForceField") then return false end
    if silentAimIgnoreFriends and isFriends(P.UserId) then return false end
    if silentAimTeamCheck and LocalPlayer.Team and P.Team == LocalPlayer.Team then return false end
    local team = P.Team and P.Team.Name or ""
    local hostile = IsHostile(Char)
    local trespass = IsTrespassing(Char)
    if silentAimIgnoreGuards and team == "Guards" then return false end
    if silentAimIgnoreCriminals and team == "Criminals" then return false end
    if silentAimIgnoreInnocent and team == "Inmates" and (not hostile and not trespass) then return false end
    return true
end

local function getClosestTarget()
    local best, bestDist = nil, silentAimFOV
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local origin = camera.CFrame.Position
    for _, P in ipairs(Players:GetPlayers()) do
        if P == LocalPlayer then continue end
        if not canTargetAim(P) then continue end
        local Char = P.Character
        local part = Char:FindFirstChild(silentAimAimPart) or Char:FindFirstChild("Head")
        if not part then continue end
        if silentAimMaxRange and (origin - part.Position).Magnitude > silentAimMaxRange then continue end
        local pos, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if (part.Position - origin):Dot(camera.CFrame.LookVector) <= 0 then continue end
        if silentAimWallCheck and not isVisible(part, origin) then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < bestDist then bestDist = dist; best = P end
    end
    return best
end

local function didHit()
    return math.random(1, 100) <= silentAimHitChance
end

local function getMissOffset(partPos, origin)
    local distance = (partPos - origin).Magnitude
    local scale = math.clamp(distance / 3, 3, 4)
    return Vector3.new(
        math.random(-scale * 10, scale * 10) / 10,
        math.random(-scale * 10, scale * 10) / 10,
        math.random(-scale * 10, scale * 10) / 10
    )
end

local function installSilentAim()
    if silentAimHooked then return end
    if not HAS_HOOK then return end
    local castRayF
    if HAS_FILTERGC then
        pcall(function() castRayF = filtergc("function", {Name = "castRay"}, true) end)
    end
    if not castRayF then
        pcall(function()
            for _, f in next, getgc(true) do
                if type(f) == "function" then
                    local info = debug.getinfo(f, "nS")
                    if info and info.name == "castRay" then castRayF = f; break end
                end
            end
        end)
    end
    if not castRayF then return end
    silentAimHooked = true
    pcall(function()
        oldCastRay = hookfunction(castRayF, function(...)
            local args = {...}
            if silentAimEnabled and currentTarget and currentTarget.Character then
                local part = currentTarget.Character:FindFirstChild(silentAimAimPart)
                if part then
                    if didHit() then
                        args[2] = part.Position
                    else
                        local origin = args[1]
                        local missPart = currentTarget.Character:FindFirstChild("LeftLeg")
                            or currentTarget.Character:FindFirstChild("RightLeg")
                        if missPart and typeof(origin) == "Vector3" then
                            args[2] = missPart.Position + getMissOffset(missPart.Position, origin)
                        end
                    end
                end
            end
            return oldCastRay(table.unpack(args))
        end)
    end)
end

RunService.Heartbeat:Connect(function()
    if silentAimEnabled then currentTarget = getClosestTarget() end
end)

-- ==================================================
-- SPIN
-- ==================================================
local function startSpinLoop()
    if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not spinEnabled then
        if hum and savedHumanoidSettings then
            hum.AutoRotate = savedHumanoidSettings.AutoRotate
            hum.CameraOffset = savedHumanoidSettings.CameraOffset
            savedHumanoidSettings = nil
        end
        return
    end
    if hum then
        savedHumanoidSettings = {AutoRotate = hum.AutoRotate, CameraOffset = hum.CameraOffset}
        hum.AutoRotate = false
    end
    spinConnection = RunService.Stepped:Connect(function(_, dt)
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if h and h.AutoRotate then h.AutoRotate = false end
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeedVal), 0)
    end)
end

-- ==================================================
-- ESP
-- ==================================================
local function createBoxFor(t)
    if not HAS_DRAWING or t == LocalPlayer or ESP_BOXES[t] then return end
    local b = Drawing.new("Square")
    b.Thickness = 1.5; b.Color = ACCENT; b.Filled = false; b.Visible = false; b.Transparency = 1
    ESP_BOXES[t] = b
end
local function removeBoxFor(t) if ESP_BOXES[t] then pcall(function() ESP_BOXES[t]:Remove() end) end ESP_BOXES[t] = nil end

local function startBoxesLoop()
    if espBoxesConn then espBoxesConn:Disconnect() espBoxesConn = nil end
    if not espBoxesEnabled or not HAS_DRAWING then for t in pairs(ESP_BOXES) do removeBoxFor(t) end return end
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createBoxFor(p) end end
    espBoxesConn = RunService.RenderStepped:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local b = ESP_BOXES[p]; if not b then createBoxFor(p) continue end
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local show = true
            if espTeamCheck and LocalPlayer.Team and p.Team == LocalPlayer.Team then show = false end
            if show and hrp and head and hum and hum.Health > 0 then
                local hs, hOn = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local fs, fOn = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                if hOn and fOn then
                    local h = math.abs(hs.Y - fs.Y); local w = h / 2
                    b.Size = Vector2.new(w, h); b.Position = Vector2.new(hs.X - w/2, hs.Y); b.Visible = true
                else b.Visible = false end
            else b.Visible = false end
        end
    end)
end

local function createNameFor(t)
    if not HAS_DRAWING or t == LocalPlayer or ESP_NAMES[t] then return end
    local n = Drawing.new("Text")
    n.Size = 14; n.Center = true; n.Outline = true; n.Color = Color3.fromRGB(255, 255, 255)
    n.OutlineColor = Color3.fromRGB(0, 0, 0); n.Visible = false; n.Font = 2; n.Text = t.Name
    ESP_NAMES[t] = n
end
local function removeNameFor(t) if ESP_NAMES[t] then pcall(function() ESP_NAMES[t]:Remove() end) end ESP_NAMES[t] = nil end

local function startNamesLoop()
    if espNamesConn then espNamesConn:Disconnect() espNamesConn = nil end
    if not espNamesEnabled or not HAS_DRAWING then for t in pairs(ESP_NAMES) do removeNameFor(t) end return end
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createNameFor(p) end end
    espNamesConn = RunService.RenderStepped:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local n = ESP_NAMES[p]; if not n then createNameFor(p) continue end
            local char = p.Character
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local show = true
            if espTeamCheck and LocalPlayer.Team and p.Team == LocalPlayer.Team then show = false end
            if show and head and hum and hum.Health > 0 then
                local hs, hOn = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                if hOn then
                    n.Position = Vector2.new(hs.X, hs.Y - 18)
                    n.Text = string.format("%s [%d]", p.Name, math.floor(hum.Health))
                    n.Visible = true
                else n.Visible = false end
            else n.Visible = false end
        end
    end)
end

local function createLineFor(t)
    if not HAS_DRAWING or t == LocalPlayer or ESP_LINES[t] then return end
    local l = Drawing.new("Line")
    l.Thickness = 1; l.Color = Color3.fromRGB(170, 100, 255); l.Visible = false
    ESP_LINES[t] = l
end
local function removeLineFor(t) if ESP_LINES[t] then pcall(function() ESP_LINES[t]:Remove() end) end ESP_LINES[t] = nil end

local function startLinesLoop()
    if espLinesConn then espLinesConn:Disconnect() espLinesConn = nil end
    if not espLinesEnabled or not HAS_DRAWING then for t in pairs(ESP_LINES) do removeLineFor(t) end return end
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createLineFor(p) end end
    espLinesConn = RunService.RenderStepped:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local l = ESP_LINES[p]; if not l then createLineFor(p) continue end
            local char = p.Character
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local show = true
            if espTeamCheck and LocalPlayer.Team and p.Team == LocalPlayer.Team then show = false end
            if show and head and hum and hum.Health > 0 then
                local hs, hOn = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                if hOn then
                    l.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                    l.To = Vector2.new(hs.X, hs.Y); l.Visible = true
                else l.Visible = false end
            else l.Visible = false end
        end
    end)
end

-- ==================================================
-- SPIDER
-- ==================================================
local function startSpiderLoop()
    if spiderConn then spiderConn:Disconnect() spiderConn = nil end
    if not spiderEnabled then lastWallHit = false return end
    spiderConn = RunService.PreRender:Connect(function()
        local char = LocalPlayer.Character
        if not char then lastWallHit = false return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then lastWallHit = false return end
        if hum.MoveDirection.Magnitude <= 0.1 then lastWallHit = false return end
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {char}; rp.FilterType = Enum.RaycastFilterType.Exclude
        local dir = hrp.CFrame.LookVector * 2.5
        if Workspace:Raycast(hrp.Position, dir, rp) or Workspace:Raycast(hrp.Position - hrp.CFrame.RightVector * 1.1, dir, rp) or Workspace:Raycast(hrp.Position + hrp.CFrame.RightVector * 1.1, dir, rp) then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, spiderClimbSpeed, 0) + (hrp.CFrame.LookVector * 0.05)
            if hrp.AssemblyLinearVelocity.Y < 0 then hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 2, hrp.AssemblyLinearVelocity.Z) end
            lastWallHit = true
        else
            if lastWallHit then
                lastWallHit = false
                local fwd = hrp.CFrame.LookVector
                hrp.AssemblyLinearVelocity = Vector3.new(fwd.X * spiderBoost * 0.68, spiderBoost, fwd.Z * spiderBoost * 0.68)
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 1.5, 0) + (fwd * 0.5)
            end
        end
    end)
end

-- ==================================================
-- AUTO KEYCARD
-- ==================================================
local function hasKeycard()
    local char = LocalPlayer.Character
    if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("keycard") then return true end end end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("keycard") then return true end end end
    return false
end

local function amICriminal()
    local n = LocalPlayer.Team and LocalPlayer.Team.Name or ""
    local l = n:lower()
    return l:find("prisoner") or l:find("inmate") or l:find("criminal") or l:find("convict")
end

local function startAutoKeycard()
    if autoKeycardConn then autoKeycardConn:Disconnect() autoKeycardConn = nil end
    if not autoKeycardEnabled then return end
    autoKeycardConn = RunService.Heartbeat:Connect(function()
        if not amICriminal() or hasKeycard() then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") or obj:IsA("BasePart") or obj:IsA("Model") then
                local name = obj.Name:lower()
                if name:find("keycard") or name:find("key card") or name:find("key_card") then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - hrp.Position).Magnitude < autoKeycardRange then
                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end)
end

-- ==================================================
-- HITBOX
-- ==================================================
local function getHitboxParts(char)
    if not char then return {} end
    local parts = {}
    for _, name in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso"}) do
        local p = char:FindFirstChild(name); if p then table.insert(parts, p) end
    end
    return parts
end

local function shouldApplyHitbox(P)
    local Char = P.Character
    if not Char then return false end
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    if not Hum or Hum.Health <= 0 then return false end
    if hitboxIgnoreFriends and isFriends(P.UserId) then return false end
    if hitboxTeamCheck and LocalPlayer.Team and P.Team == LocalPlayer.Team then return false end
    local team = P.Team and P.Team.Name or ""
    if hitboxIgnoreGuards and team == "Guards" then return false end
    if hitboxIgnoreCriminals and team == "Criminals" then return false end
    if hitboxIgnoreInnocent and team == "Inmates" and (not IsHostile(Char) and not IsTrespassing(Char)) then return false end
    return true
end

local function applyHitbox(P)
    local char = P.Character; if not char then return end
    for _, part in ipairs(getHitboxParts(char)) do
        if not savedHitboxSizes[part] then
            savedHitboxSizes[part] = {Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide, Material = part.Material, Color = part.Color}
        end
        part.Size = savedHitboxSizes[part].Size * hitboxSize
        part.CanCollide = false
        if hitboxVisual then part.Transparency = 0.5; part.Material = Enum.Material.Neon; part.Color = Color3.fromRGB(255, 100, 100) end
    end
end

local function removeHitbox(P)
    local char = P.Character; if not char then return end
    for _, part in ipairs(getHitboxParts(char)) do
        local s = savedHitboxSizes[part]
        if s then part.Size = s.Size; part.Transparency = s.Transparency; part.CanCollide = s.CanCollide; part.Material = s.Material; part.Color = s.Color; savedHitboxSizes[part] = nil end
    end
end

local function updateHitboxVisual(P)
    local char = P.Character
    if not char or not char.Parent then return end
    if hitboxEnabled and shouldApplyHitbox(P) then
        if not char:FindFirstChild("HitboxHighlight") then
            local hl = Instance.new("Highlight")
            hl.Name = "HitboxHighlight"; hl.FillColor = Color3.fromRGB(255, 80, 80); hl.FillTransparency = 0.7
            hl.OutlineColor = Color3.fromRGB(255, 150, 150); hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char
        end
    else
        local ex = char:FindFirstChild("HitboxHighlight"); if ex then ex:Destroy() end
    end
end

local function startHitboxLoop()
    if hitboxConn then hitboxConn:Disconnect() hitboxConn = nil end
    if not hitboxEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            removeHitbox(p)
            local c = p.Character; if c and c:FindFirstChild("HitboxHighlight") then c.HitboxHighlight:Destroy() end
        end
        savedHitboxSizes = {}
        return
    end
    hitboxConn = RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if shouldApplyHitbox(p) then applyHitbox(p) else removeHitbox(p) end
            updateHitboxVisual(p)
        end
    end)
end

-- ==================================================
-- FOV / FULLBRIGHT / VEHICLE
-- ==================================================
local function startFOVLoop()
    if fovConn then fovConn:Disconnect() fovConn = nil end
    if not fovEnabled then Workspace.CurrentCamera.FieldOfView = defaultFOV return end
    Workspace.CurrentCamera.FieldOfView = fovValue
    fovConn = Workspace.CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if fovEnabled and Workspace.CurrentCamera.FieldOfView ~= fovValue then Workspace.CurrentCamera.FieldOfView = fovValue end
    end)
end

local function startFullbright()
    if fullbrightConn then fullbrightConn:Disconnect() fullbrightConn = nil end
    if not fullbrightEnabled then
        for prop, val in pairs(savedLighting) do pcall(function() Lighting[prop] = val end) end
        savedLighting = {}
        return
    end
    savedLighting = {Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows}
    fullbrightConn = RunService.Heartbeat:Connect(function()
        if not fullbrightEnabled then return end
        Lighting.Ambient = Color3.fromRGB(200, 200, 200); Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 3; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.FogStart = 100000; Lighting.GlobalShadows = false
    end)
end

local function startVehicleSpeed()
    if vehicleSpeedConn then vehicleSpeedConn:Disconnect() vehicleSpeedConn = nil end
    if not vehicleSpeedEnabled then return end
    vehicleSpeedConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local seat = hum.SeatPart
        if seat then
            local vehicle = seat:FindFirstAncestorOfClass("Model") or seat.Parent
            if vehicle then
                for _, obj in ipairs(vehicle:GetDescendants()) do
                    if obj:IsA("VehicleSeat") or obj:IsA("Seat") then
                        pcall(function() obj.MaxSpeed = vehicleSpeedValue; obj.Torque = vehicleSpeedValue * 100 end)
                    end
                end
            end
        end
    end)
end

-- ==================================================
-- CONFIG SYSTEM (переписан под JSON файлы)
-- ==================================================
local function getCurrentConfigData()
    return {
        walkSpeedEnabled = walkSpeedEnabled, currentWalkSpeedVal = currentWalkSpeedVal,
        jumpPowerEnabled = jumpPowerEnabled, currentJumpPowerVal = currentJumpPowerVal,
        infiniteJumpEnabled = infiniteJumpEnabled,
        spinEnabled = spinEnabled, spinSpeedVal = spinSpeedVal,
        espTeamCheck = espTeamCheck, espBoxesEnabled = espBoxesEnabled, espNamesEnabled = espNamesEnabled, espLinesEnabled = espLinesEnabled,
        spiderEnabled = spiderEnabled, spiderClimbSpeed = spiderClimbSpeed, spiderBoost = spiderBoost,
        antiTazeEnabled = antiTazeEnabled,
        autoKeycardEnabled = autoKeycardEnabled, autoKeycardRange = autoKeycardRange,
        autoGetGunEnabled = autoGetGunEnabled, selectedGuns = selectedGuns,
        silentAimEnabled = silentAimEnabled, silentAimTeamCheck = silentAimTeamCheck, silentAimWallCheck = silentAimWallCheck,
        silentAimFOV = silentAimFOV, silentAimMaxRange = silentAimMaxRange, silentAimAimPart = silentAimAimPart,
        silentAimHitChance = silentAimHitChance, silentAimIgnoreFriends = silentAimIgnoreFriends,
        silentAimIgnoreGuards = silentAimIgnoreGuards, silentAimIgnoreCriminals = silentAimIgnoreCriminals,
        silentAimIgnoreInnocent = silentAimIgnoreInnocent, silentAimIgnoreForceField = silentAimIgnoreForceField,
        hitboxEnabled = hitboxEnabled, hitboxSize = hitboxSize, hitboxVisual = hitboxVisual,
        hitboxTeamCheck = hitboxTeamCheck, hitboxIgnoreFriends = hitboxIgnoreFriends,
        hitboxIgnoreGuards = hitboxIgnoreGuards, hitboxIgnoreCriminals = hitboxIgnoreCriminals, hitboxIgnoreInnocent = hitboxIgnoreInnocent,
        arrestAuraEnabled = arrestAuraEnabled, arrestAuraRange = arrestAuraRange, arrestIgnoreFriends = arrestIgnoreFriends,
        meleeAuraEnabled = meleeAuraEnabled, meleeAuraRange = meleeAuraRange, meleeIgnoreFriends = meleeIgnoreFriends,
        fovEnabled = fovEnabled, fovValue = fovValue, fullbrightEnabled = fullbrightEnabled,
        vehicleSpeedEnabled = vehicleSpeedEnabled, vehicleSpeedValue = vehicleSpeedValue,
        infiniteAmmoEnabled = infiniteAmmoEnabled, rapidFireEnabled = rapidFireEnabled, instantReloadEnabled = instantReloadEnabled,
    }
end

local function applyConfigData(data)
    if not data then return end
    walkSpeedEnabled = data.walkSpeedEnabled or false; currentWalkSpeedVal = data.currentWalkSpeedVal or 16
    jumpPowerEnabled = data.jumpPowerEnabled or false; currentJumpPowerVal = data.currentJumpPowerVal or 50
    infiniteJumpEnabled = data.infiniteJumpEnabled or false
    spinEnabled = data.spinEnabled or false; spinSpeedVal = data.spinSpeedVal or 10
    espTeamCheck = data.espTeamCheck ~= false
    espBoxesEnabled = data.espBoxesEnabled or false; espNamesEnabled = data.espNamesEnabled or false; espLinesEnabled = data.espLinesEnabled or false
    spiderEnabled = data.spiderEnabled or false; spiderClimbSpeed = data.spiderClimbSpeed or 0.28; spiderBoost = data.spiderBoost or 22
    antiTazeEnabled = data.antiTazeEnabled or false
    autoKeycardEnabled = data.autoKeycardEnabled or false; autoKeycardRange = data.autoKeycardRange or 20
    autoGetGunEnabled = data.autoGetGunEnabled or false; selectedGuns = data.selectedGuns or selectedGuns
    silentAimEnabled = data.silentAimEnabled or false; silentAimTeamCheck = data.silentAimTeamCheck ~= false
    silentAimWallCheck = data.silentAimWallCheck ~= false; silentAimFOV = data.silentAimFOV or 100
    silentAimMaxRange = data.silentAimMaxRange or 300; silentAimAimPart = data.silentAimAimPart or "Head"
    silentAimHitChance = data.silentAimHitChance or 100
    silentAimIgnoreFriends = data.silentAimIgnoreFriends or false; silentAimIgnoreGuards = data.silentAimIgnoreGuards or false
    silentAimIgnoreCriminals = data.silentAimIgnoreCriminals or false; silentAimIgnoreInnocent = data.silentAimIgnoreInnocent or false
    silentAimIgnoreForceField = data.silentAimIgnoreForceField or false
    hitboxEnabled = data.hitboxEnabled or false; hitboxSize = data.hitboxSize or 3; hitboxVisual = data.hitboxVisual ~= false
    hitboxTeamCheck = data.hitboxTeamCheck or false; hitboxIgnoreFriends = data.hitboxIgnoreFriends or false
    hitboxIgnoreGuards = data.hitboxIgnoreGuards or false; hitboxIgnoreCriminals = data.hitboxIgnoreCriminals or false
    hitboxIgnoreInnocent = data.hitboxIgnoreInnocent or false
    arrestAuraEnabled = data.arrestAuraEnabled or false; arrestAuraRange = data.arrestAuraRange or 7.5
    arrestIgnoreFriends = data.arrestIgnoreFriends or false
    meleeAuraEnabled = data.meleeAuraEnabled or false; meleeAuraRange = data.meleeAuraRange or 4
    meleeIgnoreFriends = data.meleeIgnoreFriends or false
    fovEnabled = data.fovEnabled or false; fovValue = data.fovValue or 70; fullbrightEnabled = data.fullbrightEnabled or false
    vehicleSpeedEnabled = data.vehicleSpeedEnabled or false; vehicleSpeedValue = data.vehicleSpeedValue or 100
    infiniteAmmoEnabled = data.infiniteAmmoEnabled or false; rapidFireEnabled = data.rapidFireEnabled or false
    instantReloadEnabled = data.instantReloadEnabled or false

    startSpinLoop(); startSpiderLoop(); startBoxesLoop(); startNamesLoop(); startLinesLoop()
    startAntiTaze(); startAutoKeycard(); startHitboxLoop(); startArrestAura(); startMeleeAura(); startAutoGetGun()
    startFOVLoop(); startFullbright(); startVehicleSpeed(); startWeaponHacks()
    if silentAimEnabled then installSilentAim() end
end

local function saveToFile()
    if not HAS_FILE then return end
    pcall(function() writefile("AuraHub_Settings.json", HttpService:JSONEncode(getCurrentConfigData())) end)
    pcall(function() writefile("AuraHub_Configs.json", HttpService:JSONEncode(configState)) end)
end

local function loadFromFile()
    if not HAS_FILE then return end
    if isfile("AuraHub_Settings.json") then
        pcall(function() applyConfigData(HttpService:JSONDecode(readfile("AuraHub_Settings.json"))) end)
    end
    if isfile("AuraHub_Configs.json") then
        pcall(function() configState = HttpService:JSONDecode(readfile("AuraHub_Configs.json")) end)
    end
end

-- ==================================================
-- UI (твоя библиотека my ui v3)
-- ==================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AlphaHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "AlphaHubMain"
MainFrame.Size = UDim2.new(0, 680, 0, 410)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -205)
MainFrame.BackgroundColor3 = BG; MainFrame.BorderSizePixel = 0; MainFrame.ZIndex = 5
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 8); MainCorner.Parent = MainFrame
local MainStroke = Instance.new("UIStroke"); MainStroke.Color = BORDER; MainStroke.Thickness = 1.2; MainStroke.Parent = MainFrame

local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = inp.Position; startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 75, 1, 0); Sidebar.BackgroundColor3 = SIDEBAR; Sidebar.BorderSizePixel = 0; Sidebar.ZIndex = 6; Sidebar.Parent = MainFrame
local SideCorner = Instance.new("UICorner"); SideCorner.CornerRadius = UDim.new(0, 8); SideCorner.Parent = Sidebar
local SidebarCover = Instance.new("Frame"); SidebarCover.Size = UDim2.new(0, 15, 1, 0); SidebarCover.Position = UDim2.new(1, -15, 0, 0)
SidebarCover.BackgroundColor3 = SIDEBAR; SidebarCover.BorderSizePixel = 0; SidebarCover.ZIndex = 6; SidebarCover.Parent = Sidebar

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -10, 0, 45); HeaderTitle.Position = UDim2.new(0, 5, 0, 10)
HeaderTitle.BackgroundTransparency = 1; HeaderTitle.Text = "Alpha Hub"; HeaderTitle.TextColor3 = TEXT
HeaderTitle.Font = Enum.Font.GothamBold; HeaderTitle.TextSize = 12; HeaderTitle.TextWrapped = true
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Center; HeaderTitle.ZIndex = 7; HeaderTitle.Parent = Sidebar

local SideButtonsFrame = Instance.new("ScrollingFrame")
SideButtonsFrame.Size = UDim2.new(1, 0, 1, -60); SideButtonsFrame.Position = UDim2.new(0, 0, 0, 55)
SideButtonsFrame.BackgroundTransparency = 1; SideButtonsFrame.ScrollBarThickness = 0; SideButtonsFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
SideButtonsFrame.ZIndex = 7; SideButtonsFrame.Parent = Sidebar

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6); SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideLayout.Parent = SideButtonsFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28); CloseBtn.Position = UDim2.new(1, -38, 0, 12); CloseBtn.BackgroundColor3 = BG2
CloseBtn.Text = "✕"; CloseBtn.TextColor3 = TEXT; CloseBtn.TextSize = 12; CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = 20; CloseBtn.Parent = MainFrame
local CloseCorner = Instance.new("UICorner"); CloseCorner.CornerRadius = UDim.new(0, 6); CloseCorner.Parent = CloseBtn
local CloseStroke = Instance.new("UIStroke"); CloseStroke.Color = BORDER; CloseStroke.Thickness = 1; CloseStroke.Parent = CloseBtn
CloseBtn.MouseEnter:Connect(function() CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40); CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255); CloseStroke.Color = Color3.fromRGB(255, 100, 100) end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.BackgroundColor3 = BG2; CloseBtn.TextColor3 = TEXT; CloseStroke.Color = BORDER end)

local TopTabLabel = Instance.new("TextLabel")
TopTabLabel.Size = UDim2.new(0, 200, 0, 28); TopTabLabel.Position = UDim2.new(0, 95, 0, 12)
TopTabLabel.BackgroundTransparency = 1; TopTabLabel.Text = "Movement"; TopTabLabel.TextColor3 = TEXT
TopTabLabel.Font = Enum.Font.GothamBold; TopTabLabel.TextSize = 15; TopTabLabel.TextXAlignment = Enum.TextXAlignment.Left
TopTabLabel.ZIndex = 6; TopTabLabel.Parent = MainFrame

local PagesContainer = Instance.new("Frame")
PagesContainer.Size = UDim2.new(1, -105, 1, -60); PagesContainer.Position = UDim2.new(0, 95, 0, 48)
PagesContainer.BackgroundTransparency = 1; PagesContainer.ZIndex = 6; PagesContainer.Parent = MainFrame

local Tooltip = Instance.new("Frame")
Tooltip.Size = UDim2.new(0, 90, 0, 22); Tooltip.BackgroundColor3 = Color3.fromRGB(24, 24, 28); Tooltip.BorderSizePixel = 0
Tooltip.ZIndex = 30; Tooltip.Visible = false; Tooltip.Parent = ScreenGui
local TooltipCorner = Instance.new("UICorner"); TooltipCorner.CornerRadius = UDim.new(0, 4); TooltipCorner.Parent = Tooltip
local TooltipStroke = Instance.new("UIStroke"); TooltipStroke.Color = BORDER; TooltipStroke.Thickness = 1; TooltipStroke.Parent = Tooltip
local TooltipText = Instance.new("TextLabel")
TooltipText.Size = UDim2.new(1, 0, 1, 0); TooltipText.BackgroundTransparency = 1; TooltipText.TextColor3 = TEXT
TooltipText.TextSize = 10; TooltipText.Font = Enum.Font.GothamSemibold; TooltipText.ZIndex = 30; TooltipText.Parent = Tooltip

local TabletButton = Instance.new("Frame")
TabletButton.Size = UDim2.new(0, 140, 0, 36); TabletButton.Position = UDim2.new(0.5, -70, 0, 15); TabletButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TabletButton.BackgroundTransparency = 0.3; TabletButton.ZIndex = 25; TabletButton.Visible = false; TabletButton.Parent = ScreenGui
local TabCorner = Instance.new("UICorner"); TabCorner.CornerRadius = UDim.new(0, 18); TabCorner.Parent = TabletButton
local TabStroke = Instance.new("UIStroke"); TabStroke.Color = Color3.fromRGB(80, 80, 80); TabStroke.Thickness = 1; TabStroke.Parent = TabletButton
local TabletIcon = Instance.new("TextLabel")
TabletIcon.Size = UDim2.new(0, 24, 1, 0); TabletIcon.Position = UDim2.new(0, 12, 0, 0); TabletIcon.BackgroundTransparency = 1
TabletIcon.Text = "⌇"; TabletIcon.TextColor3 = TEXT; TabletIcon.TextSize = 16; TabletIcon.Font = Enum.Font.GothamBold
TabletIcon.ZIndex = 25; TabletIcon.Parent = TabletButton
local TabletText = Instance.new("TextLabel")
TabletText.Size = UDim2.new(1, -45, 1, 0); TabletText.Position = UDim2.new(0, 36, 0, 0); TabletText.BackgroundTransparency = 1
TabletText.Text = "Alpha Hub"; TabletText.TextColor3 = TEXT; TabletText.TextSize = 13; TabletText.Font = Enum.Font.GothamBold
TabletText.TextXAlignment = Enum.TextXAlignment.Left; TabletText.ZIndex = 25; TabletText.Parent = TabletButton
local TabletClick = Instance.new("TextButton")
TabletClick.Size = UDim2.new(1, 0, 1, 0); TabletClick.BackgroundTransparency = 1; TabletClick.Text = ""
TabletClick.ZIndex = 26; TabletClick.Parent = TabletButton

local tDragging, tDragStart, tStartPos
TabletClick.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        tDragging = true; tDragStart = inp.Position; tStartPos = TabletButton.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if tDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - tDragStart
        TabletButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        if tDragging then
            tDragging = false
            local delta = inp.Position - tDragStart
            if delta.Magnitude < 5 then TabletButton.Visible = false; MainFrame.Visible = true end
        end
    end
end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; TabletButton.Visible = true end)

local function arrangeGrid(pageData)
    if not pageData or not pageData.Cards or not pageData.Frame then return end
    local cards = {}
    for _, card in ipairs(pageData.Cards) do if card and card.Parent == pageData.Frame then table.insert(cards, card) end end
    local cardWidth = 180; local paddingX = 10; local paddingY = 10; local startX = 5; local startY = 5
    local colHeights = {0, 0, 0}
    for _, cardFrame in ipairs(cards) do
        local minCol = 1; local minHeight = colHeights[1]
        for col = 2, 3 do if colHeights[col] < minHeight then minHeight = colHeights[col]; minCol = col end end
        local posX = startX + (minCol - 1) * (cardWidth + paddingX)
        local posY = startY + minHeight
        cardFrame.Position = UDim2.new(0, posX, 0, posY)
        colHeights[minCol] = minHeight + cardFrame.AbsoluteSize.Y + paddingY
    end
    local maxHeight = colHeights[1]
    for col = 2, 3 do if colHeights[col] > maxHeight then maxHeight = colHeights[col] end end
    pageData.Frame.CanvasSize = UDim2.new(0, 0, 0, startY + maxHeight + 20)
end

local function updateVisibility()
    TopTabLabel.Text = currentSideTab
    for name, pageData in pairs(pages) do
        if pageData and pageData.Frame then
            pageData.Frame.Visible = (name == currentSideTab)
            if name == currentSideTab then
                for _, card in ipairs(pageData.Cards) do if card then card.Visible = true end end
                arrangeGrid(pageData)
            end
        end
    end
    for name, btn in pairs(sideButtonsList) do
        local img = btn:FindFirstChildOfClass("ImageLabel")
        local str = btn:FindFirstChildOfClass("UIStroke")
        if name == currentSideTab then
            btn.BackgroundColor3 = BG3
            if str then str.Color = ACCENT end
            if img then img.ImageColor3 = ACCENT end
        else
            btn.BackgroundColor3 = BG2
            if str then str.Color = BORDER end
            if img then img.ImageColor3 = TEXT2 end
        end
    end
end

local buttonIcons = {
    ["Movement"] = "rbxassetid://10723345709",
    ["Player"] = "rbxassetid://10723395906",
    ["Combat"] = "rbxassetid://10723345709",
    ["Prison Life"] = "rbxassetid://10734950349",
    ["Favorite"] = "rbxassetid://10723345709",
    ["Config"] = "rbxassetid://10723345709",
    ["Players"] = "rbxassetid://10734963570",
    ["Settings"] = "rbxassetid://10723345709"
}

local function createPageGrid(name)
    local pf = Instance.new("ScrollingFrame")
    pf.Size = UDim2.new(1, 0, 1, 0); pf.BackgroundTransparency = 1; pf.ScrollBarThickness = 4
    pf.ScrollBarImageColor3 = Color3.fromRGB(45, 45, 50); pf.Visible = false; pf.ZIndex = 6; pf.Parent = PagesContainer
    pages[name] = {Frame = pf, Cards = {}}
    return pages[name]
end

local function syncFavoritesTab()
    local favPage = pages["Favorite"]
    if not favPage then return end
    for _, cloneFrame in ipairs(favoriteClonesList) do cloneFrame:Destroy() end
    favoriteClonesList = {}
    favPage.Cards = {}
    for _, cardInfo in ipairs(allCardsList) do
        if cardInfo.starActive then
            local clone = cardInfo.frame:Clone()
            clone.Visible = true
            clone.Parent = favPage.Frame
            local header = clone:FindFirstChild("HeaderFrame")
            if header then
                local starCont = header:FindFirstChild("StarContainer")
                if starCont then
                    local starBtn = starCont:FindFirstChild("StarButton")
                    if starBtn then
                        starBtn.MouseButton1Click:Connect(function()
                            cardInfo.starActive = false
                            cardInfo.refreshStarUI()
                            syncFavoritesTab()
                            local originPage = pages[cardInfo.origPage]
                            if originPage then arrangeGrid(originPage) end
                        end)
                    end
                end
                local collapseBtn = header:FindFirstChild("CollapseButton")
                if collapseBtn then
                    local content = clone:FindFirstChild("ContentContainer")
                    collapseBtn.MouseButton1Click:Connect(function()
                        cardInfo.isCollapsed = not cardInfo.isCollapsed
                        if cardInfo.isCollapsed then
                            if content then content.Visible = false content.Active = false end
                            clone.Size = UDim2.new(0, 180, 0, 36); collapseBtn.Text = "▼"
                        else
                            clone.Size = UDim2.new(0, 180, 0, 165)
                            if content then content.Visible = true content.Active = true end
                            collapseBtn.Text = "▲"
                        end
                        arrangeGrid(favPage)
                    end)
                end
            end
            table.insert(favPage.Cards, clone)
            table.insert(favoriteClonesList, clone)
        end
    end
    if currentSideTab == "Favorite" then arrangeGrid(favPage) end
end

local function createFunctionalCard(pageData, title, originalTabName)
    local parentPage = pageData.Frame
    local CardFrame = Instance.new("Frame")
    CardFrame.Name = title .. "Card"
    CardFrame.Size = UDim2.new(0, 180, 0, 165)
    CardFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
    CardFrame.BorderSizePixel = 0; CardFrame.ClipsDescendants = true; CardFrame.ZIndex = 7; CardFrame.Parent = parentPage
    table.insert(pageData.Cards, CardFrame)
    local cardRef = {frame = CardFrame, name = title, origPage = originalTabName, currentHome = pageData,
        dropdowns = {}, sliders = {}, toggles = {}, starActive = false, isCollapsed = false}
    table.insert(allCardsList, cardRef)
    local CardCorner = Instance.new("UICorner"); CardCorner.CornerRadius = UDim.new(0, 6); CardCorner.Parent = CardFrame
    local CardStroke = Instance.new("UIStroke"); CardStroke.Thickness = 1; CardStroke.Color = Color3.fromRGB(30, 30, 35)
    CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; CardStroke.Parent = CardFrame

    local HeaderFrame = Instance.new("Frame"); HeaderFrame.Name = "HeaderFrame"
    HeaderFrame.Size = UDim2.new(1, 0, 0, 36); HeaderFrame.BackgroundTransparency = 1; HeaderFrame.ZIndex = 7; HeaderFrame.Parent = CardFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -75, 1, 0); TitleLabel.Position = UDim2.new(0, 10, 0, 0); TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title; TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 250); TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 10; TitleLabel.TextWrapped = true; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 7; TitleLabel.Parent = HeaderFrame

    local StarContainer = Instance.new("Frame")
    StarContainer.Name = "StarContainer"; StarContainer.Size = UDim2.new(0, 16, 0, 16); StarContainer.Position = UDim2.new(1, -64, 0, 10)
    StarContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 28); StarContainer.BorderSizePixel = 0; StarContainer.ZIndex = 7; StarContainer.Parent = HeaderFrame
    local StarContainerCorner = Instance.new("UICorner"); StarContainerCorner.CornerRadius = UDim.new(0, 4); StarContainerCorner.Parent = StarContainer
    local StarContainerStroke = Instance.new("UIStroke"); StarContainerStroke.Thickness = 1; StarContainerStroke.Color = Color3.fromRGB(45, 45, 50); StarContainerStroke.Parent = StarContainer
    local StarButton = Instance.new("TextButton")
    StarButton.Name = "StarButton"; StarButton.Size = UDim2.new(1, 0, 1, 0); StarButton.BackgroundTransparency = 1
    StarButton.Text = "★"; StarButton.Font = Enum.Font.GothamBold; StarButton.TextSize = 10; StarButton.TextColor3 = Color3.fromRGB(80, 80, 85)
    StarButton.ZIndex = 8; StarButton.Parent = StarContainer

    local ToggleSlider = Instance.new("TextButton")
    ToggleSlider.Name = "ToggleSlider"; ToggleSlider.Size = UDim2.new(0, 24, 0, 14); ToggleSlider.Position = UDim2.new(1, -44, 0, 11)
    ToggleSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 35); ToggleSlider.Text = ""; ToggleSlider.AutoButtonColor = false
    ToggleSlider.ZIndex = 8; ToggleSlider.Parent = HeaderFrame
    local TSCorner = Instance.new("UICorner"); TSCorner.CornerRadius = UDim.new(1, 0); TSCorner.Parent = ToggleSlider
    local TSStroke = Instance.new("UIStroke"); TSStroke.Thickness = 1; TSStroke.Color = Color3.fromRGB(45, 45, 50); TSStroke.Parent = ToggleSlider
    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"; ToggleCircle.Size = UDim2.new(0, 8, 0, 8); ToggleCircle.Position = UDim2.new(0, 2, 0.5, -4)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(130, 130, 135); ToggleCircle.BorderSizePixel = 0; ToggleCircle.ZIndex = 8; ToggleCircle.Parent = ToggleSlider
    local TCCorner = Instance.new("UICorner"); TCCorner.CornerRadius = UDim.new(1, 0); TCCorner.Parent = ToggleCircle

    local CollapseButton = Instance.new("TextButton")
    CollapseButton.Name = "CollapseButton"; CollapseButton.Size = UDim2.new(0, 18, 0, 18); CollapseButton.Position = UDim2.new(1, -18, 0, 9)
    CollapseButton.BackgroundTransparency = 1; CollapseButton.Text = "▲"; CollapseButton.Font = Enum.Font.GothamBold
    CollapseButton.TextSize = 8; CollapseButton.TextColor3 = Color3.fromRGB(200, 200, 205); CollapseButton.ZIndex = 8; CollapseButton.Parent = HeaderFrame

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"; ContentContainer.Size = UDim2.new(1, -20, 1, -44); ContentContainer.Position = UDim2.new(0, 10, 0, 38)
    ContentContainer.BackgroundTransparency = 1; ContentContainer.ZIndex = 7; ContentContainer.Parent = CardFrame
    local ListLayout = Instance.new("UIListLayout"); ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 6); ListLayout.Parent = ContentContainer

    local function refreshStarUI()
        if cardRef.starActive then
            StarButton.TextColor3 = Color3.fromRGB(255, 255, 255); StarContainerStroke.Color = Color3.fromRGB(255, 255, 255)
        else
            StarButton.TextColor3 = Color3.fromRGB(80, 80, 85); StarContainerStroke.Color = Color3.fromRGB(45, 45, 50)
        end
    end
    cardRef.refreshStarUI = refreshStarUI
    StarButton.MouseButton1Click:Connect(function()
        cardRef.starActive = not cardRef.starActive; refreshStarUI(); syncFavoritesTab()
    end)

    local function setCollapseState(collapsed)
        cardRef.isCollapsed = collapsed
        if cardRef.isCollapsed then
            ContentContainer.Visible = false; ContentContainer.Active = false
            CardFrame.Size = UDim2.new(0, 180, 0, 36); CollapseButton.Text = "▼"
        else
            CardFrame.Size = UDim2.new(0, 180, 0, 165); ContentContainer.Visible = true; ContentContainer.Active = true
            CollapseButton.Text = "▲"
        end
    end

    CollapseButton.MouseButton1Click:Connect(function()
        cardRef.isCollapsed = not cardRef.isCollapsed
        ContentContainer.Visible = false; ContentContainer.Active = false
        local targetHeight = cardRef.isCollapsed and 36 or 165
        CardFrame.Size = UDim2.new(0, 180, 0, targetHeight)
        if not cardRef.isCollapsed then
            ContentContainer.Visible = true; ContentContainer.Active = true; CollapseButton.Text = "▲"
        else CollapseButton.Text = "▼" end
        arrangeGrid(cardRef.currentHome)
    end)

    local isFunctionActive = false
    local toggleCallback = nil
    local function setToggleState(active)
        isFunctionActive = active
        if isFunctionActive then
            ToggleSlider.BackgroundColor3 = Color3.fromRGB(240, 240, 245); TSStroke.Color = Color3.fromRGB(255, 255, 255)
            ToggleCircle.Position = UDim2.new(1, -10, 0.5, -4); ToggleCircle.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        else
            ToggleSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 35); TSStroke.Color = Color3.fromRGB(45, 45, 50)
            ToggleCircle.Position = UDim2.new(0, 2, 0.5, -4); ToggleCircle.BackgroundColor3 = Color3.fromRGB(130, 130, 135)
        end
        if toggleCallback then pcall(toggleCallback, isFunctionActive) end
    end
    ToggleSlider.MouseButton1Click:Connect(function() setToggleState(not isFunctionActive) end)

    local cardExporter = {}
    function cardExporter:SetToggleCallback(cb) toggleCallback = cb end
    cardRef.setToggleState = setToggleState

    function cardExporter:AddDropdown(id, text, options, default, callback)
        local DropdownFrame = Instance.new("Frame"); DropdownFrame.Size = UDim2.new(1, 0, 0, 32)
        DropdownFrame.BackgroundTransparency = 1; DropdownFrame.ZIndex = 9; DropdownFrame.Parent = ContentContainer
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 10); Label.BackgroundTransparency = 1; Label.Text = text
        Label.TextColor3 = Color3.fromRGB(130, 130, 135); Label.Font = Enum.Font.GothamMedium; Label.TextSize = 9
        Label.TextXAlignment = Enum.TextXAlignment.Left; Label.ZIndex = 9; Label.Parent = DropdownFrame
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(1, 0, 0, 18); Button.Position = UDim2.new(0, 0, 0, 14); Button.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
        Button.Font = Enum.Font.GothamMedium; Button.Text = " " .. default; Button.TextColor3 = Color3.fromRGB(210, 210, 215)
        Button.TextSize = 10; Button.TextXAlignment = Enum.TextXAlignment.Left; Button.BorderSizePixel = 0
        Button.ZIndex = 10; Button.Parent = DropdownFrame
        local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(0, 4); BtnCorner.Parent = Button
        local Arrow = Instance.new("TextLabel")
        Arrow.Size = UDim2.new(0, 16, 1, 0); Arrow.Position = UDim2.new(1, -16, 0, 0); Arrow.BackgroundTransparency = 1
        Arrow.Text = "▼"; Arrow.TextColor3 = Color3.fromRGB(100, 100, 105); Arrow.TextSize = 6; Arrow.ZIndex = 10; Arrow.Parent = Button
        local ListFrame = Instance.new("Frame")
        ListFrame.Name = "ListFrame"; ListFrame.Size = UDim2.new(1, 0, 0, 0); ListFrame.Position = UDim2.new(0, 0, 1, 2)
        ListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24); ListFrame.BorderSizePixel = 0; ListFrame.ClipsDescendants = true
        ListFrame.ZIndex = 15; ListFrame.Parent = Button
        local ListCorner = Instance.new("UICorner"); ListCorner.CornerRadius = UDim.new(0, 4); ListCorner.Parent = ListFrame
        local ListStroke = Instance.new("UIStroke"); ListStroke.Thickness = 1; ListStroke.Color = Color3.fromRGB(40, 40, 45); ListStroke.Parent = ListFrame
        local DropdownLayout = Instance.new("UIListLayout"); DropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder; DropdownLayout.Parent = ListFrame
        local currentVal = default
        local dropdownOpen = false
        local function toggleDropdown()
            dropdownOpen = not dropdownOpen
            if dropdownOpen then
                CardFrame.ClipsDescendants = false; Arrow.Text = "▲"
                ListFrame.Size = UDim2.new(1, 0, 0, #options * 16)
            else
                Arrow.Text = "▼"; ListFrame.Size = UDim2.new(1, 0, 0, 0); CardFrame.ClipsDescendants = true
            end
        end
        Button.MouseButton1Click:Connect(toggleDropdown)
        local function populate(items)
            for _, child in pairs(ListFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            if type(items) == "table" then
                for _, option in ipairs(items) do
                    local OptButton = Instance.new("TextButton")
                    OptButton.Size = UDim2.new(1, 0, 0, 16); OptButton.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
                    OptButton.BackgroundTransparency = 1; OptButton.Font = Enum.Font.GothamMedium; OptButton.Text = " " .. option
                    OptButton.TextColor3 = Color3.fromRGB(180, 180, 185); OptButton.TextSize = 9
                    OptButton.TextXAlignment = Enum.TextXAlignment.Left; OptButton.BorderSizePixel = 0; OptButton.ZIndex = 16; OptButton.Parent = ListFrame
                    OptButton.MouseEnter:Connect(function() OptButton.BackgroundTransparency = 0; OptButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35) end)
                    OptButton.MouseLeave:Connect(function() OptButton.BackgroundTransparency = 1 end)
                    OptButton.MouseButton1Click:Connect(function()
                        currentVal = option; Button.Text = " " .. option; toggleDropdown(); pcall(callback, option)
                    end)
                end
            end
        end
        populate(options)
        cardRef.dropdowns[id] = {
            Set = function(v) currentVal = v; Button.Text = " " .. v; pcall(callback, v) end,
            Get = function() return currentVal end,
            Refresh = function(newItems) populate(newItems) end
        }
        return cardRef.dropdowns[id]
    end

    local activeSliderID = nil
    function cardExporter:AddSlider(id, text, min, max, default, callback)
        local SliderFrame = Instance.new("Frame"); SliderFrame.Size = UDim2.new(1, 0, 0, 26)
        SliderFrame.BackgroundTransparency = 1; SliderFrame.ZIndex = 8; SliderFrame.Parent = ContentContainer
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, 0, 0, 10); Label.BackgroundTransparency = 1; Label.Text = text
        Label.TextColor3 = Color3.fromRGB(130, 130, 135); Label.Font = Enum.Font.GothamMedium; Label.TextSize = 9
        Label.TextXAlignment = Enum.TextXAlignment.Left; Label.ZIndex = 8; Label.Parent = SliderFrame
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(0.4, 0, 0, 10); ValueLabel.Position = UDim2.new(0.6, 0, 0, 0); ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = string.format("%.2f", default); ValueLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
        ValueLabel.Font = Enum.Font.GothamBold; ValueLabel.TextSize = 9; ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.ZIndex = 8; ValueLabel.Parent = SliderFrame
        local SliderBar = Instance.new("TextButton")
        SliderBar.Size = UDim2.new(1, 0, 0, 4); SliderBar.Position = UDim2.new(0, 0, 0, 16); SliderBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        SliderBar.Text = ""; SliderBar.AutoButtonColor = false; SliderBar.BorderSizePixel = 0; SliderBar.ZIndex = 8; SliderBar.Parent = SliderFrame
        local BarCorner = Instance.new("UICorner"); BarCorner.CornerRadius = UDim.new(1, 0); BarCorner.Parent = SliderBar
        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new(0, 0, 1, 0); SliderFill.BackgroundColor3 = Color3.fromRGB(240, 240, 245); SliderFill.BorderSizePixel = 0
        SliderFill.ZIndex = 8; SliderFill.Parent = SliderBar
        local FillCorner = Instance.new("UICorner"); FillCorner.CornerRadius = UDim.new(1, 0); FillCorner.Parent = SliderFill
        local SliderTrigger = Instance.new("Frame")
        SliderTrigger.Size = UDim2.new(0, 10, 0, 10); SliderTrigger.Position = UDim2.new(0, 0, 0.5, -5); SliderTrigger.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SliderTrigger.BorderSizePixel = 0; SliderTrigger.ZIndex = 9; SliderTrigger.Parent = SliderBar
        local TriggerCorner = Instance.new("UICorner"); TriggerCorner.CornerRadius = UDim.new(1, 0); TriggerCorner.Parent = SliderTrigger
        local currentVal = default
        local function updateVisuals(val)
            local pct = math.clamp((val - min) / (max - min), 0, 1)
            SliderFill.Size = UDim2.new(pct, 0, 1, 0); SliderTrigger.Position = UDim2.new(pct, -5, 0.5, -5)
            ValueLabel.Text = string.format("%.2f", val)
        end
        local function updateFromInput(input)
            local offset = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            currentVal = min + (max - min) * offset; updateVisuals(currentVal); pcall(callback, currentVal)
        end
        SliderBar.InputBegan:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and activeSliderID == nil then
                activeSliderID = id; updateFromInput(input)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if activeSliderID == id and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and activeSliderID == id then
                activeSliderID = nil
            end
        end)
        updateVisuals(default)
        cardRef.sliders[id] = {
            Set = function(v) currentVal = math.clamp(v, min, max); updateVisuals(currentVal); pcall(callback, currentVal) end,
            Get = function() return currentVal end
        }
    end

    function cardExporter:AddButton(text, callback)
        local btnElement = Instance.new("TextButton")
        btnElement.Size = UDim2.new(1, 0, 0, 22); btnElement.BackgroundColor3 = BG3; btnElement.Text = text
        btnElement.TextColor3 = TEXT; btnElement.Font = Enum.Font.GothamBold; btnElement.TextSize = 10; btnElement.Parent = ContentContainer
        local BtnCorner = Instance.new("UICorner"); BtnCorner.CornerRadius = UDim.new(0, 4); BtnCorner.Parent = btnElement
        local BtnStroke = Instance.new("UIStroke"); BtnStroke.Color = BORDER; BtnStroke.Thickness = 1; BtnStroke.Parent = btnElement
        btnElement.MouseButton1Click:Connect(function() pcall(callback) end)
    end

    cardRef.toggles.Main = {Set = setToggleState, Get = function() return isFunctionActive end}
    cardRef.toggles.Collapse = {Set = setCollapseState, Get = function() return cardRef.isCollapsed end}
    cardRef.toggles.Star = {Set = function(v) cardRef.starActive = v refreshStarUI() syncFavoritesTab() end, Get = function() return cardRef.starActive end}
    return cardExporter
end

-- ==================================================
-- ВКЛАДКИ
-- ==================================================
local sideTabsTabs = {"Movement", "Player", "Combat", "Prison Life", "Players", "Favorite", "Config", "Settings"}
local sideTabsOrderTabs = {}
for i, v in ipairs(sideTabsTabs) do sideTabsOrderTabs[v] = i end

for _, name in ipairs(sideTabsTabs) do
    createPageGrid(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 32); btn.BackgroundColor3 = BG2; btn.BorderSizePixel = 0; btn.Text = ""
    btn.LayoutOrder = sideTabsOrderTabs[name]; btn.Parent = SideButtonsFrame
    local BC = Instance.new("UICorner"); BC.CornerRadius = UDim.new(0, 5); BC.Parent = btn
    local BS = Instance.new("UIStroke"); BS.Color = BORDER; BS.Thickness = 1; BS.Parent = btn
    sideButtonsList[name] = btn
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 18, 0, 18); img.Position = UDim2.new(0.5, -9, 0.5, -9); img.BackgroundTransparency = 1
    img.Image = buttonIcons[name] or "rbxassetid://10723345709"; img.ImageColor3 = TEXT2; img.Parent = btn
    btn.MouseEnter:Connect(function()
        btn.Position = UDim2.new(0, 0, 0, -2); TooltipText.Text = name; Tooltip.Visible = true
        local targetX = btn.AbsolutePosition.X + btn.AbsoluteSize.X + 8
        local targetY = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2) - (Tooltip.AbsoluteSize.Y / 2)
        Tooltip.Position = UDim2.new(0, targetX, 0, targetY)
    end)
    btn.MouseLeave:Connect(function() btn.Position = UDim2.new(0, 0, 0, 0); Tooltip.Visible = false end)
    btn.MouseButton1Click:Connect(function() currentSideTab = name; updateVisibility() end)
end

-- ==================================================
-- КАРТОЧКИ ФУНКЦИЙ
-- ==================================================

-- MOVEMENT
local flyCard = createFunctionalCard(pages["Movement"], "Walk Speed", "Movement")
flyCard:AddSlider(1, "Speed Value", 1, 500, 16, function(val) currentWalkSpeedVal = val; if walkSpeedEnabled then local c = LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = val end end end)
flyCard:SetToggleCallback(function(state)
    walkSpeedEnabled = state
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed = state and currentWalkSpeedVal or DEFAULT_WALKSPEED end
    startWatchdog(); saveToFile()
end)

local jumpCard = createFunctionalCard(pages["Movement"], "Jump Power", "Movement")
jumpCard:AddSlider(2, "Power Value", 1, 500, 50, function(val) currentJumpPowerVal = val; if jumpPowerEnabled then local c = LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = val end end end)
jumpCard:SetToggleCallback(function(state)
    jumpPowerEnabled = state
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("Humanoid") then c.Humanoid.JumpPower = state and currentJumpPowerVal or DEFAULT_JUMPPOWER end
    startWatchdog(); saveToFile()
end)

local spiderCard = createFunctionalCard(pages["Movement"], "Spider", "Movement")
spiderCard:AddSlider(3, "Climb Speed", 1, 20, 3, function(val) spiderClimbSpeed = val / 10 end)
spiderCard:SetToggleCallback(function(state) spiderEnabled = state; startSpiderLoop(); saveToFile() end)

local infJumpCard = createFunctionalCard(pages["Movement"], "Infinite Jump", "Movement")
infJumpCard:SetToggleCallback(function(state)
    infiniteJumpEnabled = state
    if state and not infiniteJumpConn then
        infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
            if not infiniteJumpEnabled then return end
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    saveToFile()
end)

local vehicleCard = createFunctionalCard(pages["Movement"], "Vehicle Speed", "Movement")
vehicleCard:AddSlider(4, "Speed", 50, 500, 100, function(val) vehicleSpeedValue = val end)
vehicleCard:SetToggleCallback(function(state) vehicleSpeedEnabled = state; startVehicleSpeed(); saveToFile() end)

-- PLAYER (ESP + FOV + Fullbright + Spin)
local espBoxesCard = createFunctionalCard(pages["Player"], "ESP Boxes", "Player")
espBoxesCard:SetToggleCallback(function(state) espBoxesEnabled = state; startBoxesLoop(); saveToFile() end)

local espNamesCard = createFunctionalCard(pages["Player"], "ESP Names", "Player")
espNamesCard:SetToggleCallback(function(state) espNamesEnabled = state; startNamesLoop(); saveToFile() end)

local espLinesCard = createFunctionalCard(pages["Player"], "ESP Lines", "Player")
espLinesCard:SetToggleCallback(function(state) espLinesEnabled = state; startLinesLoop(); saveToFile() end)

local espTeamCard = createFunctionalCard(pages["Player"], "ESP Team Check", "Player")
espTeamCard:SetToggleCallback(function(state) espTeamCheck = state; saveToFile() end)

local fovCard = createFunctionalCard(pages["Player"], "FOV Changer", "Player")
fovCard:AddSlider(5, "FOV", 30, 120, 70, function(val) fovValue = val; if fovEnabled then Workspace.CurrentCamera.FieldOfView = val end end)
fovCard:SetToggleCallback(function(state) fovEnabled = state; startFOVLoop(); saveToFile() end)

local fullbrightCard = createFunctionalCard(pages["Player"], "Fullbright", "Player")
fullbrightCard:SetToggleCallback(function(state) fullbrightEnabled = state; startFullbright(); saveToFile() end)

local spinCard = createFunctionalCard(pages["Player"], "Spin", "Player")
spinCard:AddSlider(6, "Spin Rate", 1, 50, 10, function(val) spinSpeedVal = val end)
spinCard:SetToggleCallback(function(state) spinEnabled = state; startSpinLoop(); saveToFile() end)

-- COMBAT
local silentAimCard = createFunctionalCard(pages["Combat"], "Silent Aim", "Combat")
silentAimCard:AddSlider(7, "FOV", 30, 360, 100, function(val) silentAimFOV = val end)
silentAimCard:AddDropdown(1, "Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"}, "Head", function(val) silentAimAimPart = val end)
silentAimCard:AddSlider(8, "Hit Chance", 1, 100, 100, function(val) silentAimHitChance = val end)
silentAimCard:SetToggleCallback(function(state) silentAimEnabled = state; if state then installSilentAim() end; saveToFile() end)

local silentTeamCard = createFunctionalCard(pages["Combat"], "Silent Team Check", "Combat")
silentTeamCard:SetToggleCallback(function(state) silentAimTeamCheck = state; saveToFile() end)

local silentWallCard = createFunctionalCard(pages["Combat"], "Silent Wall Check", "Combat")
silentWallCard:SetToggleCallback(function(state) silentAimWallCheck = state; saveToFile() end)

local silentFriendsCard = createFunctionalCard(pages["Combat"], "Silent Ignore Friends", "Combat")
silentFriendsCard:SetToggleCallback(function(state) silentAimIgnoreFriends = state; saveToFile() end)

local hitboxCard = createFunctionalCard(pages["Combat"], "Hitbox Expander", "Combat")
hitboxCard:AddSlider(9, "Size x", 1, 10, 3, function(val) hitboxSize = val end)
hitboxCard:SetToggleCallback(function(state) hitboxEnabled = state; startHitboxLoop(); saveToFile() end)

local hitboxTeamCard = createFunctionalCard(pages["Combat"], "Hitbox Team Check", "Combat")
hitboxTeamCard:SetToggleCallback(function(state) hitboxTeamCheck = state; saveToFile() end)

local hitboxFriendsCard = createFunctionalCard(pages["Combat"], "Hitbox Ignore Friends", "Combat")
hitboxFriendsCard:SetToggleCallback(function(state) hitboxIgnoreFriends = state; saveToFile() end)

local hitboxVisualCard = createFunctionalCard(pages["Combat"], "Hitbox Visual", "Combat")
hitboxVisualCard:SetToggleCallback(function(state) hitboxVisual = state; if hitboxEnabled then startHitboxLoop() end; saveToFile() end)

local infiniteAmmoCard = createFunctionalCard(pages["Combat"], "Infinite Ammo", "Combat")
infiniteAmmoCard:SetToggleCallback(function(state) infiniteAmmoEnabled = state; startWeaponHacks(); saveToFile() end)

local rapidFireCard = createFunctionalCard(pages["Combat"], "Rapid Fire", "Combat")
rapidFireCard:SetToggleCallback(function(state) rapidFireEnabled = state; startWeaponHacks(); saveToFile() end)

local instantReloadCard = createFunctionalCard(pages["Combat"], "Instant Reload", "Combat")
instantReloadCard:SetToggleCallback(function(state) instantReloadEnabled = state; startWeaponHacks(); saveToFile() end)

-- PRISON LIFE
local autoKeycardCard = createFunctionalCard(pages["Prison Life"], "Auto Keycard", "Prison Life")
autoKeycardCard:AddSlider(10, "Range", 10, 100, 20, function(val) autoKeycardRange = val end)
autoKeycardCard:SetToggleCallback(function(state) autoKeycardEnabled = state; startAutoKeycard(); saveToFile() end)

local arrestAuraCard = createFunctionalCard(pages["Prison Life"], "Arrest Aura", "Prison Life")
arrestAuraCard:AddSlider(11, "Range", 1, 15, 7.5, function(val) arrestAuraRange = val end)
arrestAuraCard:SetToggleCallback(function(state) arrestAuraEnabled = state; startArrestAura(); saveToFile() end)

local meleeAuraCard = createFunctionalCard(pages["Prison Life"], "Melee Aura", "Prison Life")
meleeAuraCard:AddSlider(12, "Range", 1, 9, 4, function(val) meleeAuraRange = val end)
meleeAuraCard:SetToggleCallback(function(state) meleeAuraEnabled = state; startMeleeAura(); saveToFile() end)

local antiTazeCard = createFunctionalCard(pages["Prison Life"], "Anti-Taze", "Prison Life")
antiTazeCard:SetToggleCallback(function(state) antiTazeEnabled = state; startAntiTaze(); saveToFile() end)

local autoGetGunCard = createFunctionalCard(pages["Prison Life"], "Auto Get Gun", "Prison Life")
autoGetGunCard:SetToggleCallback(function(state) autoGetGunEnabled = state; startAutoGetGun(); saveToFile() end)

local itemGiverCard = createFunctionalCard(pages["Prison Life"], "Item Giver", "Prison Life")
itemGiverCard:AddButton("Получить M4A1", function() getGun("M4A1") end)
itemGiverCard:AddButton("Получить Remington 870", function() getGun("Remington 870") end)
itemGiverCard:AddButton("Получить AK-47", function() getGun("AK-47") end)
itemGiverCard:AddButton("Получить MP5", function() getGun("MP5") end)

-- TELEPORTS
local tpCard = createFunctionalCard(pages["Prison Life"], "Teleports", "Prison Life")
local teleports = {
    ["Оружейная"] = Vector3.new(826.20, 101.46, 2294.85),
    ["Кафетерий"] = Vector3.new(924.52, 101.48, 2227.59),
    ["База преступников"] = Vector3.new(-975.03, 109.82, 2057.95),
    ["Секретная комната"] = Vector3.new(701.45, 101.45, 2354.30),
    ["Двор"] = Vector3.new(795.78, 99.65, 2541.00),
    ["Внутри тюрьмы"] = Vector3.new(915.29, 101.49, 2388.00),
}
for name, pos in pairs(teleports) do
    tpCard:AddButton("📍 " .. name, function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
    end)
end

-- PLAYERS (список)
local playersCard = createFunctionalCard(pages["Players"], "Teleport to Player", "Players")
local playerList = {"No Players"}
local playerDropdown
playerDropdown = playersCard:AddDropdown(2, "Select Player", playerList, "No Players", function(val) currentTarget = val end)
playersCard:AddButton("🔄 Refresh List", function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    if #list == 0 then list = {"No Players"} end
    playerDropdown.Refresh(list)
end)
playersCard:AddButton("📍 Teleport", function()
    if currentTarget and currentTarget ~= "No Players" then
        local target = Players:FindFirstChild(currentTarget)
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHRP then myHRP.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0)) end
        end
    end
end)

-- CONFIG
local configCard = createFunctionalCard(pages["Config"], "Configuration", "Config")
configCard:AddButton("💾 Save Default Config", function()
    configState.Default = HttpService:JSONEncode(getCurrentConfigData())
    saveToFile()
end)
configCard:AddButton("📂 Load Default Config", function()
    if configState.Default then
        local ok, data = pcall(function() return HttpService:JSONDecode(configState.Default) end)
        if ok then applyConfigData(data) end
    end
end)

-- SETTINGS
local settingsCard = createFunctionalCard(pages["Settings"], "Settings", "Settings")
settingsCard:AddButton("🔄 Reset UI", function() MainFrame.Position = UDim2.new(0.5, -340, 0.5, -205) end)

-- ==================================================
-- СТАРТ
-- ==================================================
loadFromFile()

task.spawn(function()
    task.wait(0.3)
    for _, tabName in ipairs(sideTabsTabs) do
        if pages[tabName] then arrangeGrid(pages[tabName]) end
    end
    updateVisibility()
end)

local function onCharacterAdded(char)
    char:WaitForChild("Humanoid", 5)
    task.wait(0.3)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if walkSpeedEnabled then hum.WalkSpeed = currentWalkSpeedVal end
    if jumpPowerEnabled then
        if hum.UseJumpPower then hum.JumpPower = currentJumpPowerVal
        else hum.JumpHeight = currentJumpPowerVal / 7.5 end
    end
    if spinEnabled then startSpinLoop() end
    if spiderEnabled then startSpiderLoop() end
    if espBoxesEnabled then startBoxesLoop() end
    if espNamesEnabled then startNamesLoop() end
    if espLinesEnabled then startLinesLoop() end
    if antiTazeEnabled then startAntiTaze() end
    if autoKeycardEnabled then startAutoKeycard() end
    if arrestAuraEnabled then startArrestAura() end
    if meleeAuraEnabled then startMeleeAura() end
    if autoGetGunEnabled then startAutoGetGun() end
    if hitboxEnabled then startHitboxLoop() end
    if fovEnabled then startFOVLoop() end
    if fullbrightEnabled then startFullbright() end
    if vehicleSpeedEnabled then startVehicleSpeed() end
    if infiniteAmmoEnabled or rapidFireEnabled or instantReloadEnabled then startWeaponHacks() end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then task.spawn(onCharacterAdded, LocalPlayer.Character) end

startWatchdog()

task.spawn(function()
    while true do
        task.wait(10)
        saveToFile()
    end
end)

print("✨ Aura Hub v10 — My UI Edition загружено!")