--[[
    Nullscape GUI — juanitahaxx UI Library Port
    Original script by John Nullscape (Ali)
    UI Library: juanitahaxx by samet (joestar._3) | design by eskolzz
    Ported & integrated with config system support.
]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- ── Executor Compatibility ────────────────────────────────────────────────────

local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))
local fSignal        = missing("function", firesignal)

local function notif(text, title, dur)
    -- Defined below after Library initialization
end

local function toClipboard(txt)
    if everyClipboard then
        everyClipboard(tostring(txt))
        notif("Copied to clipboard", "Clipboard")
    else
        notif("Your exploit doesn't support clipboard", "Clipboard")
    end
end

local function fireSig(signal, args)
    if fSignal then
        fSignal(signal, args)
    else
        notif("Your exploit doesn't support firesignal.", "firesignal")
    end
end

-- ── Roblox Services ───────────────────────────────────────────────────────────

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local StarterGui       = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local SoundService     = game:GetService("SoundService")
local PlaceId, JobId   = game.PlaceId, game.JobId

-- ── Duplicate Execution Safeguard ─────────────────────────────────────────────

if ReplicatedStorage:FindFirstChild("DESTROYNULLGUI") then
    ReplicatedStorage:FindFirstChild("DESTROYNULLGUI"):Destroy()
    StarterGui:SetCore("SendNotification", {
        Title    = "NULL GUI PRE-EXECUTE",
        Text     = "Null GUI already executed! Destroying old GUI...",
        Duration = 3
    })
    task.wait(1.5)
end

-- ── Game References ───────────────────────────────────────────────────────────

local plr              = Players.LocalPlayer
local events           = ReplicatedStorage.Events
local Camera           = workspace.CurrentCamera
local spawnPart        = workspace.Spawn
local items            = workspace.Item_Pools
local gifts            = items.Gift
local goldengifts      = items.GoldenGift
local tripmines        = items.Tripmine
local goldentripmines  = items:FindFirstChild("GoldTripmines")
local enemies          = workspace.Enemies
local selection        = workspace:FindFirstChild("Select")
local currentRooms     = workspace.CurrentRooms
local pads             = workspace.JumpPads
local code             = ReplicatedStorage.CodeVal
local music            = ReplicatedStorage.MusicVal
local curses           = ReplicatedStorage.CurseFolder.Curses
local gcurses          = ReplicatedStorage.GreaterCurseFolder.Curses
local enemiesFolder    = ReplicatedStorage.EnemyFolder
local upgrades         = ReplicatedStorage.UpgradeFolder.Upgrades
local beacons          = workspace.Beacons
local destroyFolder    = workspace.DestroyFolder
local bullets          = items.Bullet
local counters         = ReplicatedStorage.GiftCounters
local magnet           = events.MovementGiftMagnet

-- ── Protection Folders & Visual Instances ─────────────────────────────────────

local tripmineprots = Instance.new("Folder")
tripmineprots.Parent = workspace
tripmineprots.Name = "Tripmine Protection (NULL GUI)"

local bulletprots = Instance.new("Folder")
bulletprots.Parent = workspace
bulletprots.Name = "Guardian Bullets Protection (NULL GUI)"

local velocityPart = Instance.new("Part")
velocityPart.Name = "VelocityVisualizer"
velocityPart.Anchored = true
velocityPart.CanCollide = false
velocityPart.CanTouch = false
velocityPart.Material = Enum.Material.Air
velocityPart.Color = Color3.new(1,1,1)
velocityPart.Size = Vector3.new(0.1,0.1,1)
velocityPart.Parent = workspace
local vpBox = Instance.new("BoxHandleAdornment")
vpBox.Color3 = Color3.new(1,1,1)
vpBox.AlwaysOnTop = true
vpBox.ZIndex = 0
vpBox.Adornee = velocityPart
vpBox.Parent = velocityPart

-- ── State Flags ───────────────────────────────────────────────────────────────

local notifOn         = true
local destroying      = false
local tweening        = false
local cesp            = false
local mesp            = false
local visibleHitbox   = false
local canInstaGrapple = false
local canGoHome       = true
local canGoBeacon     = true
local canEzDisableAll = true
local canEzDisableAllC= true
local canEzCollectNormal = true
local canEzCollectGolden = true
local canEzCollectMedal  = true
local canFullReset    = true
local canBringPad     = true
local canBringTria    = true
local canGliderBoost  = false
local canCancelTween  = false
local av              = false
local noice           = false
local noflesh         = false
local instrumentesp   = false
local pt              = false
local pb              = false
local dvi             = false
local dsm             = false
local dso             = false
local velov           = false
local nrb             = false
local nfb             = false
local gliderBoost     = false
local connections     = {}

local clientenemies = { "Kolona","Voidbreaker","Skinwalker","Operator","Scrapmaw" }

local tracers              = {}
local availableNormalGifts = {}
local availableGoldenGifts = {}
local newInstances         = {}
local cgb, mb

-- ── Load juanitahaxx Library ──────────────────────────────────────────────────

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/kee-67/juanitahaxx-modified/refs/heads/main/Library.lua"))()

function notif(text, title, dur)
    if not notifOn then return end
    Library:Notification(
        (title and ("[" .. title .. "] ") or "") .. (text or ""),
        dur or 5,
        Library.Theme.Accent
    )
end

-- ── Window & Pages ────────────────────────────────────────────────────────────

local Window      = Library:Window({ Name = "Nullscape GUI" })
local Watermark   = Window:Watermark({ Name = "Nullscape GUI" })
local KeybindList = Window:KeybindList()

local mainPage    = Window:Page({ Name = "Main" })
local upgradePage = Window:Page({ Name = "Upgrades" })
local enemyPage   = Window:Page({ Name = "Enemy" })
local mapPage     = Window:Page({ Name = "Map" })
local plrPage     = Window:Page({ Name = "Player" })
local visualPage  = Window:Page({ Name = "Visual" })
local keyPage     = Window:Page({ Name = "Keybinds" })
local musicPage   = Window:Page({ Name = "Music" })
local debugPage   = Window:Page({ Name = "Debug" })

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

local function getChar(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function getHuman(char)
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char, humanoid)
    if not char then return nil end
    if not humanoid then humanoid = getHuman(char) end
    return char:FindFirstChild("HumanoidRootPart") or (humanoid and humanoid.RootPart),
           char:FindFirstChild("Hitbox")
end

local function isDead(target)
    if target:IsA("Player") then
        local char = target.Character
        local humanoid = char and getHuman(char)
        return char and (humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Dead or humanoid.Health <= 0))
            or char == nil
    elseif target:IsA("Model") then
        local humanoid = target and getHuman(target)
        return humanoid and (humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Dead or humanoid.Health <= 0))
            or target == nil
    else
        return target == nil
    end
end

-- ── Drawing Lines ─────────────────────────────────────────────────────────────

local closestGiftTracer = Drawing.new("Line")
closestGiftTracer.Visible   = false
closestGiftTracer.Thickness = 2
closestGiftTracer.Color     = Color3.new(1, 1, 0)
closestGiftTracer.Transparency = 1

local medalTracer = Drawing.new("Line")
medalTracer.Visible     = false
medalTracer.Thickness   = 2
medalTracer.Color       = Color3.new(0.75, 0.75, 0.75)
medalTracer.Transparency = 1

-- ── Gift Scanning System ──────────────────────────────────────────────────────

local lastRefresh  = 0
local scanIndex    = 1
local scanIndexTwo = 1
local SCAN_SIZE    = 200
local normalList   = {}
local goldenList   = {}

local function updateGiftLists()
    normalList = gifts:GetChildren()
    goldenList = goldengifts:GetChildren()
end

table.insert(connections, gifts.ChildAdded:Connect(updateGiftLists))
table.insert(connections, gifts.ChildRemoved:Connect(updateGiftLists))
table.insert(connections, goldengifts.ChildAdded:Connect(updateGiftLists))
table.insert(connections, goldengifts.ChildRemoved:Connect(updateGiftLists))
updateGiftLists()

local function refreshGifts(skip, golden)
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return end
    local rootPos = root.Position

    if skip then
        table.clear(availableNormalGifts)
        table.clear(availableGoldenGifts)
        for _, gift in ipairs(normalList) do
            if gift and gift.Parent and gift.Transparency ~= 1 and gift:FindFirstChild("Collect", true) then
                if (rootPos - gift.Position).Magnitude <= 500 then
                    table.insert(availableNormalGifts, gift)
                end
            end
        end
        for _, gift in ipairs(goldenList) do
            if gift and gift.Parent and gift.Transparency ~= 1 and gift:FindFirstChild("Collect", true) then
                if (rootPos - gift.Position).Magnitude <= 500 then
                    table.insert(availableGoldenGifts, gift)
                end
            end
        end
        return
    end

    local currentAvailableGifts = #availableNormalGifts
    if #availableNormalGifts == 0 or golden then
        currentAvailableGifts = #availableGoldenGifts
    end
    local REFRESH_RATE = (currentAvailableGifts > 5000 and 1/0.25) or (currentAvailableGifts > 3000 and 1/1) or
                         (currentAvailableGifts > 1500 and 1/3)  or (currentAvailableGifts > 1000 and 1/5) or
                         (currentAvailableGifts > 500  and 1/12.5) or 1/25

    if tick() - lastRefresh < REFRESH_RATE then return end
    lastRefresh = tick()

    for i = 1, SCAN_SIZE do
        local gift = normalList[scanIndex]
        if not gift then scanIndex = 1 break end
        if gift and gift.Parent and gift.Transparency ~= 1 and gift:FindFirstChild("Collect", true) then
            if (rootPos - gift.Position).Magnitude <= 500 then
                table.insert(availableNormalGifts, gift)
            end
        end
        scanIndex += 1
    end

    for i = 1, SCAN_SIZE do
        local gift = goldenList[scanIndexTwo]
        if not gift then scanIndexTwo = 1 break end
        if gift and gift.Parent and gift.Transparency ~= 1 and gift:FindFirstChild("Collect", true) then
            if (rootPos - gift.Position).Magnitude <= 500 then
                table.insert(availableGoldenGifts, gift)
            end
        end
        scanIndexTwo += 1
    end
end

local function getActiveTripmines()
    local active = {}
    for _, mine in tripmines:GetChildren() do
        if mine.Transparency ~= 1 then table.insert(active, mine) end
    end
    if goldentripmines then
        for _, mine in goldentripmines:GetChildren() do
            if mine.Transparency ~= 1 then table.insert(active, mine) end
        end
    end
    return active
end

local function pathBlocked(targetPos, activeTripmines, activeEnemies)
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return true end
    local rootPos = root.Position
    local fakeSize = Vector3.new(2,5,2)
    local minX = math.min(rootPos.X - fakeSize.X/2, targetPos.X - fakeSize.X/2)
    local minY = math.min(rootPos.Y - fakeSize.Y/2, targetPos.Y - fakeSize.Y/2)
    local minZ = math.min(rootPos.Z - fakeSize.Z/2, targetPos.Z - fakeSize.Z/2)
    local maxX = math.max(rootPos.X + fakeSize.X/2, targetPos.X + fakeSize.X/2)
    local maxY = math.max(rootPos.Y + fakeSize.Y/2, targetPos.Y + fakeSize.Y/2)
    local maxZ = math.max(rootPos.Z + fakeSize.Z/2, targetPos.Z + fakeSize.Z/2)
    for _, mine in activeTripmines do
        local pos = mine.Position; local size = mine.Size
        if maxX >= pos.X-size.X/2 and minX <= pos.X+size.X/2 and
           maxY >= pos.Y-size.Y/2 and minY <= pos.Y+size.Y/2 and
           maxZ >= pos.Z-size.Z/2 and minZ <= pos.Z+size.Z/2 then return true end
    end
    for _, enemy in activeEnemies do
        local pos = enemy.Position; local size = enemy.Size
        if maxX >= pos.X-size.X/2 and minX <= pos.X+size.X/2 and
           maxY >= pos.Y-size.Y/2 and minY <= pos.Y+size.Y/2 and
           maxZ >= pos.Z-size.Z/2 and minZ <= pos.Z+size.Z/2 then return true end
    end
    return false
end

local function getClosestGift(giftList)
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return nil, math.huge end
    local rootPos = root.Position
    local closest, shortest = nil, math.huge

    for i = #giftList, 1, -1 do
        local gift = giftList[i]
        if not gift or not gift.Parent or gift.Transparency == 1 or not gift:FindFirstChild("Collect", true) then
            table.remove(giftList, i)
        else
            local dist = (gift.Position - rootPos).Magnitude
            if dist < shortest then
                shortest = dist
                closest = gift
            end
        end
    end
    return closest, shortest
end

local function getClosestAnyGift()
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return end
    local rootPos = root.Position
    local closest, shortest = nil, math.huge
    local function check(list)
        for i = #list, 1, -1 do
            local gift = list[i]
            if gift and gift.Parent and gift.Transparency == 0 and gift:FindFirstChild("Collect") ~= nil then
                local dist = (gift.Position - rootPos).Magnitude
                if dist < shortest then shortest = dist; closest = gift end
            end
        end
    end
    check(availableNormalGifts)
    check(availableGoldenGifts)
    return closest
end

local function createTracer(obj)
    local line = Drawing.new("Line")
    line.Visible = true; line.Thickness = 2
    line.Color = Color3.new(0,0,1); line.Transparency = 1
    tracers[obj] = line
end

-- ── Movement / Tween ──────────────────────────────────────────────────────────

local function goTo(part, activeTripmines, activeEnemies)
    if not activeEnemies then activeEnemies = enemies:GetChildren() end
    if not part then return end
    local char = getChar(plr)
    local root, hitbox = getRoot(char)
    local rootPos = root and root.Position
    if not root or not hitbox then return end

    local pos = part:IsA("Model") and part:GetPivot().Position or part.Position
    if part.Name == "Spawn" then pos = pos + Vector3.new(0,4,0) end
    local diff = pos - rootPos
    local dist = diff.Magnitude
    if dist == 0 or dist >= 10000 then return end

    local direction = diff.Unit
    root.CFrame = CFrame.new(root.Position, root.Position + direction) * CFrame.Angles(0, math.rad(90), 0)

    local blocked = pathBlocked(pos, activeTripmines, activeEnemies)
    if blocked and (part.Name == "Gift" or part.Name == "GoldenGift") then
        root.Position = pos; task.wait(.3); return
    end

    local info  = TweenInfo.new(dist / 120, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(root, info, {Position = pos})
    tween:Play()
    TweenService:Create(hitbox, info, {Position = pos}):Play()

    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if pathBlocked(pos, activeTripmines, activeEnemies) then tween:Cancel() break end
            task.wait(0.05)
        end
    end)
    tween.Completed:Once(function() hitbox.Position = root.Position end)
    return tween
end

-- ── Altar & Pylon Helpers ─────────────────────────────────────────────────────

local function getAltarPrompts()
    local prompts = {}
    for _, p in currentRooms:GetDescendants() do
        if p.Name == "Prompt" and p:IsA("ProximityPrompt") then
            table.insert(prompts, { Prompt = p, Text = p.ObjectText })
        end
    end
    return prompts
end

-- ── Protection ────────────────────────────────────────────────────────────────

local function protectTripmine(trip)
    if not trip:GetAttribute("uuid") then trip:SetAttribute("uuid", HttpService:GenerateGUID(false)) end
    local id = trip:GetAttribute("uuid")
    if tripmineprots:FindFirstChild(id) then return end
    local sizeoffset = trip.Size.X + 3
    local p = Instance.new("Part")
    p.Name = id; p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(sizeoffset,sizeoffset,sizeoffset)
    p.Position = trip.Position; p.Anchored = true
    p.CanCollide = true; p.Transparency = 0
    p.Parent = tripmineprots
    trip:GetPropertyChangedSignal("Transparency"):Once(function() p:Destroy() end)
end

local function protectBullet(b)
    if not b:GetAttribute("uuid") then b:SetAttribute("uuid", HttpService:GenerateGUID(false)) end
    local id = b:GetAttribute("uuid")
    if bulletprots:FindFirstChild(id) then return end
    local sizeoffset = b.Size.X + 5
    local p = Instance.new("Part")
    p.Name = id; p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(sizeoffset,sizeoffset,sizeoffset)
    p.Position = b.Position; p.Anchored = true
    p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
    p.Transparency = 0.35; p.Parent = bulletprots
    b:GetPropertyChangedSignal("Transparency"):Once(function() p:Destroy() end)
end

local function isdirectionsafetopushfromguardianbullet(pos, direction)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {plr.Character}
    local result = workspace:Raycast(pos, direction * 6, rayParams)
    return result ~= nil and result.Instance and result.Instance.CanCollide == true
end

local function GetClosestPad()
    local localChar = getChar(plr)
    if not localChar then return nil end
    local root = getRoot(localChar)
    if not root then return nil end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {localChar}
    local badColor = Color3.fromRGB(152, 24, 24)
    local closest, dist = nil, 100
    for _, part in pads:GetChildren() do
        if part.Color == badColor then continue end
        local mag = (root.Position - part.Position).Magnitude
        if mag > dist then continue end
        local result = workspace:Raycast(root.Position, part.Position - root.Position, rayParams)
        if result and result.Instance:IsDescendantOf(pads) then
            dist = mag; closest = part
        end
    end
    return closest
end

-- ── Collection System ─────────────────────────────────────────────────────────

local magSlider -- forward declaration

local function collect(which)
    local activeTripmines = getActiveTripmines()
    if magSlider then magSlider:Set(5) end

    local function collectGolden()
        if tweening then notif("Already collecting.", "Collection System") return end
        tweening = true
        refreshGifts(true, true)

        local tween
        local retryCount = 0
        while tweening do
            local char = getChar(plr); local root = getRoot(char)
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
            refreshGifts(true, true)
            local gift = getClosestGift(availableGoldenGifts)
            if not gift then
                retryCount += 1
                if retryCount > 3 then
                    notif("No golden gifts found nearby.", "Gift Not Found")
                    break
                end
                task.wait(0.4)
                continue
            end
            retryCount = 0
            tween = goTo(gift, activeTripmines, enemies:GetChildren())
            if tween then tween.Completed:Wait() end
            task.wait(.02)
        end
        if tween then tween:Cancel() end
        tweening = false
        local humanoid = getHuman(getChar(plr))
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Landed) end
    end

    local function collectNormal()
        if tweening then notif("Already collecting.", "Collection System") return end
        tweening = true
        refreshGifts(true, false)

        local tween
        local retryCount = 0
        while tweening do
            local char = getChar(plr); local root = getRoot(char)
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
            refreshGifts(true, false)
            local gift = getClosestGift(availableNormalGifts)
            if not gift then
                retryCount += 1
                if retryCount > 3 then
                    notif("No gifts found nearby.", "Gift Not Found")
                    break
                end
                task.wait(0.4)
                continue
            end
            retryCount = 0
            tween = goTo(gift, activeTripmines, enemies:GetChildren())
            if tween then tween.Completed:Wait() end
            task.wait(.02)
        end
        if tween then tween:Cancel() end
        tweening = false
        local humanoid = getHuman(getChar(plr))
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Landed) end
    end

    if which == "normal" then collectNormal()
    elseif which == "golden" then collectGolden() end
end

-- ── Enemy Disable System ──────────────────────────────────────────────────────

local function disableEnemy(enemyName, willDestroy, willBreakAI, failNotif)
    if failNotif == nil then failNotif = true end
    if willBreakAI == nil then willBreakAI = false end

    local function loopEnemies(name, remove, list)
        list = list or enemies; remove = remove or "TouchInterest"
        local n, total, enemiesFound = 0, 0, {}
        for _, sameenemy in list:GetChildren() do
            if sameenemy.Name ~= name then continue end
            local loaded = sameenemy:FindFirstChild(remove, true) or
                           sameenemy:FindFirstChild(name.."_ClientAI", true) or
                           sameenemy:GetAttribute("Disabled") == true
            if not loaded then continue end
            total += 1; table.insert(enemiesFound, sameenemy)
            if sameenemy:GetAttribute("Disabled") == true then n += 1; continue end
            local disabledThisEnemy = false
            for _, part in sameenemy:GetDescendants() do
                if part.Name == remove then part:Destroy(); disabledThisEnemy = true end
            end
            if disabledThisEnemy then sameenemy:SetAttribute("Disabled", true); n += 1 end
        end
        return n, total, enemiesFound
    end

    local function destroyEnemy(name, list)
        list = list or enemies
        for _, sameenemy in list:GetChildren() do
            if sameenemy.Name == name then sameenemy:Destroy() end
        end
        notif(name.." disabled. (destroyed)", "Enemy")
        return true
    end

    local function doBreakAI(enemyInst, scriptName)
        local clientScript = enemyInst:FindFirstChild(scriptName)
        if not clientScript then return end
        if clientScript.Enabled == false and not enemyInst:GetAttribute("Disabled") then
            local c
            c = clientScript:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not clientScript.Parent or not enemyInst.Parent then c:Disconnect() return end
                if clientScript.Enabled == true then
                    task.defer(function()
                        if clientScript.Parent and enemyInst.Parent then clientScript.Enabled = false end
                    end)
                    c:Disconnect()
                end
            end)
        end
        clientScript.Enabled = false
        enemyInst:SetAttribute("Disabled", true)
    end

    local disableFunction = {
        Basic = function(name, willDestroy, willBreakAI)
            if not name then return end
            if willDestroy then return destroyEnemy(name) end
            local n, total, enemiesFound = loopEnemies(name)
            if total > 0 and n >= total then
                notif(tostring(n).." "..name.."(s) disabled.", "Enemy")
                if willBreakAI then
                    for _, e in pairs(enemiesFound) do doBreakAI(e, name.."_ClientAI") end
                end
                return true
            else
                if failNotif then notif(name.." cannot be fully disabled yet.", "Enemy") end
                return false
            end
        end,
        Skinwalker = function(name, willDestroy)
            local skinwalkers = workspace.Skinwalkers
            if #skinwalkers:GetChildren() == 0 then
                if failNotif then notif("Husk isn't following you yet.", "Enemy") end
                return false
            end
            if willDestroy then destroyEnemy(name); return destroyEnemy(name, skinwalkers) end
            local n, total = 0, 0
            local a, b
            a,b = loopEnemies("Skinwalker","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("TallSkinwalker","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("Skinwalker1","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("Skinwalker2","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("Skinwalker3","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("Skinwalker4","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("CrayonSkinwalker","TouchInterest",skinwalkers); n+=a; total+=b
            a,b = loopEnemies("TallCrayonSkinwalker","TouchInterest",skinwalkers); n+=a; total+=b
            if total > 0 and n >= total then notif(tostring(n).." Husk(s) disabled.", "Enemy"); return true end
            return false
        end,
        Springer = function(name, willDestroy, willBreakAI)
            if willDestroy then return destroyEnemy(name) end
            loopEnemies(name, "SpringerShockwave")
            loopEnemies(name, "DemonShockwave")
            local n, total, enemiesFound = loopEnemies(name, "Kill")
            if total > 0 and n >= total then
                notif(tostring(n).." Springer(s) disabled.", "Enemy")
                if willBreakAI then
                    for _, s in pairs(enemiesFound) do doBreakAI(s, "Springer_ClientAI") end
                end
                return true
            end
            return false
        end,
        ICBM = function(name, willDestroy)
            if willDestroy then return destroyEnemy(name) end
            local enemiesFound = {}
            for _, e in enemies:GetChildren() do
                if e.Name == name or e.Name == "ICBM" then table.insert(enemiesFound, e) end
            end
            if #enemiesFound > 0 then
                local n = 0
                for _, s in pairs(enemiesFound) do doBreakAI(s, "ICBM_ClientAI"); n+=1 end
                return n >= #enemiesFound
            end
            return false
        end,
        Celestial = function(name, willDestroy)
            if willDestroy then return destroyEnemy(name) end
            local n, total, enemiesFound = loopEnemies(name)
            if n > 0 then
                notif("Celestial disabled. Go Collect.", "Enemy")
                for _, s in pairs(enemiesFound) do doBreakAI(s, "Celestial_ClientAI") end
                return true
            end
            return false
        end,
        Sigil       = function(name) return destroyEnemy(name) end,
        Kolona      = function(name) return destroyEnemy(name) end,
        Operator    = function(name) return destroyEnemy(name) end,
        Voidbreaker = function(name) return destroyEnemy(name) end,
        Scrapmaw    = function(name) return destroyEnemy(name) end,
    }

    print("disabling:", enemyName, "(NULL GUI)")
    if disableFunction[enemyName] then
        return disableFunction[enemyName](enemyName, willDestroy, willBreakAI)
    else
        return disableFunction.Basic(enemyName, willDestroy, willBreakAI)
    end
end

local function disableAll(willDestroy, client, willBreakAI)
    willDestroy = if willDestroy == nil then false else willDestroy
    client      = if client      == nil then false else client
    willBreakAI = if willBreakAI == nil then false else willBreakAI
    local allenemies = enemies:GetChildren()
    if not allenemies or #allenemies == 0 then
        notif("No enemies available.", "Not found"); return
    end
    if client then
        for _, enemy in clientenemies do
            if not enemies:FindFirstChild(enemy) then continue end
            disableEnemy(enemy, willDestroy, willBreakAI)
        end
        return
    end
    for _, enemy in allenemies do
        disableEnemy(enemy.Name, willDestroy, willBreakAI)
    end
end

-- ── Auto-Handle Settings ──────────────────────────────────────────────────────

local auto_disable = {Bell=false,Mart=false,Skinwalker=false,Springer=false,Baby=false,Flesh=false,Telefragger=false,ShadowBaby=false,Cadence=false}
local auto_break   = {Bell=false,Mart=false,Skinwalker=false,Springer=false,ICBM=false,Baby=false,Flesh=false,Telefragger=false,ShadowBaby=false,Celestial=false,Cadence=false}
local auto_destroy = {Bell=false,Mart=false,Skinwalker=false,Springer=false,ICBM=false,Baby=false,Flesh=false,Operator=false,Kolona=false,Telefragger=false,Sigil=false,ShadowBaby=false,Voidbreaker=false,Cadence=false,Scrapmaw=false,RealityBreak=false,Celestial=false}

local function handleEnemy(enemy)
    local name = enemy.Name
    local waitingTime = 25
    if name == "ICBM" or name == "Telefragger" or name:find("Baby") then waitingTime = 75 end

    if auto_destroy[name] then
        local start = tick(); local didDestroy
        repeat
            if tick()-start >= waitingTime then break end
            didDestroy = disableEnemy(name, true, false, false)
            task.wait(.2)
        until didDestroy == true
    elseif auto_break[name] then
        if name == "Mart" and curses:FindFirstChild("MartSlide") then
            notif("Destroy Mart instead of breaking.", "MART SLIDE DETECTED")
        end
        local start = tick(); local didBreak
        repeat
            if tick()-start >= waitingTime then break end
            didBreak = disableEnemy(name, false, true, false)
            task.wait(.2)
        until didBreak == true
    elseif auto_disable[name] then
        if name == "Mart" and curses:FindFirstChild("MartSlide") then
            notif("Destroy Mart instead of disabling.", "MART SLIDE DETECTED")
        end
        local start = tick(); local didDisable
        repeat
            if tick()-start >= waitingTime then break end
            didDisable = disableEnemy(name, false, false, false)
            task.wait(.2)
        until didDisable == true
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  MAIN PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local mainLeftSec  = mainPage:Section({ Name = "Gift Collection", Side = 1 })
    local mainRightSec = mainPage:Section({ Name = "Gift Counters",   Side = 2 })

    mainLeftSec:Button({
        Name = "Collect Normal Gifts",
        Callback = function()
            task.spawn(function() collect("normal") end)
        end
    })
    mainLeftSec:Button({
        Name = "Collect Golden Gifts",
        Callback = function()
            task.spawn(function() collect("golden") end)
        end
    })
    mainLeftSec:Button({ Name = "Cancel Collecting", Callback = function() if tweening then tweening = false end end })

    magSlider = mainLeftSec:Slider({
        Name     = "Gift Collection Range",
        Flag     = "GiftCollectionRange",
        Min      = 1, Max = 30, Default = 1, Decimals = 1,
        Callback = function(v) magnet:Fire({ Add = v }) end
    })
    mainLeftSec:Button({
        Name = "Reset Collection Range",
        Callback = function() magSlider:Set(1); magnet:Fire({ Reset = 1 }) end
    })

    local giftCounter     = counters.Gift
    local goldgiftCounter = counters.GoldenGift
    local passageCounter  = counters.PassageGift
    local tripmineCounter = counters.Tripmine

    local function counterStr(c, label)
        return label..": "..tostring(c:GetAttribute("Collected")).."/"..tostring(c:GetAttribute("MaxGifts")).." | Needed: "..tostring(c.Value)
    end
    local function tripmineStr(c)
        return "Tripmines: "..tostring(c:GetAttribute("Collected")).."/"..tostring(c:GetAttribute("MaxGifts")).." | Remaining: "..tostring(c.Value)
    end

    local giftCountLabel    = mainRightSec:Label({ Name = counterStr(giftCounter, "Gifts") })
    local goldCountLabel    = mainRightSec:Label({ Name = counterStr(goldgiftCounter, "Golden Gifts") })
    local passageCountLabel = mainRightSec:Label({ Name = counterStr(passageCounter, "Passage Golden Gifts") })
    local tripmineCountLabel= mainRightSec:Label({ Name = tripmineStr(tripmineCounter) })

    table.insert(connections, giftCounter.Changed:Connect(function()
        giftCountLabel:SetText(counterStr(giftCounter, "Gifts"))
    end))
    table.insert(connections, goldgiftCounter.Changed:Connect(function()
        goldCountLabel:SetText(counterStr(goldgiftCounter, "Golden Gifts"))
    end))
    table.insert(connections, passageCounter.Changed:Connect(function()
        passageCountLabel:SetText(counterStr(passageCounter, "Passage Golden Gifts"))
    end))
    table.insert(connections, tripmineCounter.Changed:Connect(function()
        tripmineCountLabel:SetText(tripmineStr(tripmineCounter))
    end))
end

-- ═══════════════════════════════════════════════════════════════════════
--  UPGRADES PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local upgradeLeftSec  = upgradePage:Section({ Name = "Client Upgrades", Side = 1 })
    local upgradeRightSec = upgradePage:Section({ Name = "Info",            Side = 2 })

    if fSignal then
        upgradeRightSec:Label({ Name = "Your exploit can add upgrades." })
    else
        upgradeRightSec:Label({ Name = "Your exploit doesn't support firesignal." })
    end
    upgradeRightSec:Label({ Name = "Upgrades are temporary. Some may not have an effect past their limit." })

    local clientUpgrades = {
        "MatrixTetrahedron","Adrenaline","HighlightGifts","AdvancedGravityCoil","SportShoes",
        "TheOrb","RealWings","GraceWings","RadarPlayer","RadarInstruments","HighlightTripmines",
        "IceSkates","SwiftnessRing","GiftMagnet","SharkTail","EnemyOnTop","PocketBell",
        "NinjaBelt","Helmet","DoubleJump","RadarAltars"
    }

    local function addUpgrade(name)
        local intv = upgrades:FindFirstChild(name)
        if intv then
            intv.Value += 1
            fireSig(events.UpgradesChanged.OnClientEvent, {[name] = intv.Value})
        else
            fireSig(events.UpgradesChanged.OnClientEvent, {[name] = 1})
            intv = Instance.new("IntValue")
            intv.Value = 1; intv.Name = name; intv.Parent = upgrades
            getHuman(getChar(plr)).RootPart.Destroying:Once(function() intv:Destroy() end)
        end
    end
    local function subUpgrade(name)
        local intv = upgrades:FindFirstChild(name)
        if intv and intv.Value > 1 then
            intv.Value -= 1
            fireSig(events.UpgradesChanged.OnClientEvent, {[name] = intv.Value})
        elseif intv then
            intv:Destroy()
        else
            fireSig(events.UpgradesChanged.OnClientEvent, {[name] = 0})
        end
    end

    for _, u in clientUpgrades do
        upgradeLeftSec:Button({ Name = "Add "..u,    Callback = function() addUpgrade(u) end })
        upgradeLeftSec:Button({ Name = "Remove "..u, Callback = function() subUpgrade(u) end })
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  ENEMY PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local enemyAllSec    = enemyPage:Section({ Name = "All Enemies",          Side = 1 })
    local enemyClientSec = enemyPage:Section({ Name = "Client-sided Enemies", Side = 2 })
    local enemyWhySec    = enemyPage:Section({ Name = "Add Enemies (WHY)",    Side = 2 })

    enemyAllSec:Button({ Name = "Disable All",  Callback = function() disableAll() end })
    enemyAllSec:Button({ Name = "Break All AI", Callback = function() disableAll(false,false,true) end })
    enemyAllSec:Button({ Name = "Destroy All",  Callback = function() disableAll(true) end })

    enemyClientSec:Button({ Name = "Disable Client-sided Only", Callback = function() disableAll(false,true) end })
    enemyClientSec:Button({ Name = "Destroy Client-sided Only", Callback = function() disableAll(true,true) end })

    local function makeAddEnemyButton(enemyName, display)
        display = display or enemyName
        enemyWhySec:Button({
            Name = "Add "..display.." This/Next Round",
            Callback = function()
                local folder = enemiesFolder.Enemies
                if not folder:FindFirstChild(enemyName) then
                    notif(display.." template not found.", "Enemy"); return
                end
                if not enemiesFolder.ActiveEnemies:FindFirstChild(enemyName) then
                    local int = Instance.new("IntValue")
                    int.Name = enemyName; int.Value = 1
                    int.Parent = enemiesFolder.ActiveEnemies
                    newInstances[enemyName.."Val"] = int

                    local function spawnIt()
                        local e = folder[enemyName]:Clone()
                        e.Parent = enemies
                        local ai = e:FindFirstChild(enemyName.."_AI")
                        if ai then ai.Enabled = true end
                        newInstances[enemyName] = e
                        connections[enemyName] = ReplicatedStorage.InRound.Changed:Once(function()
                            newInstances[enemyName] = nil; e:Destroy()
                            newInstances[enemyName.."Val"] = nil; int:Destroy()
                            connections[enemyName] = nil
                        end)
                    end

                    if ReplicatedStorage.InRound.Value then
                        spawnIt()
                        events.NotifyBindable:Fire('<font color="#ff0000">WHY</font>', display..' <font color="#ff0000">added</font>.')
                    else
                        connections[enemyName] = ReplicatedStorage.InRound.Changed:Once(function() task.wait(.1) spawnIt() end)
                        events.NotifyBindable:Fire('<font color="#ff0000">WHY</font>', display..' added <font color="#ff0000">next round</font>.')
                    end
                else
                    notif(display.." is already here or destroyed.", "Enemy")
                end
            end
        })
    end

    makeAddEnemyButton("Skinwalker", "One Husk")
    makeAddEnemyButton("Kolona")
    makeAddEnemyButton("Operator")
    makeAddEnemyButton("Voidbreaker")
    makeAddEnemyButton("Scrapmaw")

    local function makeEnemySection(name, displayName, hasDisable, hasBreak, hasDestroy)
        local sec = enemyPage:Section({ Name = displayName or name, Side = 1 })
        if hasDisable then
            sec:Toggle({
                Name = "Auto Disable", Flag = "AutoDisable_"..name, Default = false,
                Callback = function(v)
                    auto_disable[name] = v
                    local e = enemies:FindFirstChild(name)
                    if e then handleEnemy(e) end
                end
            })
        end
        if hasBreak then
            sec:Toggle({
                Name = "Auto Break AI", Flag = "AutoBreak_"..name, Default = false,
                Callback = function(v)
                    auto_break[name] = v
                    local e = enemies:FindFirstChild(name)
                    if e then handleEnemy(e) end
                end
            })
        end
        if hasDestroy then
            sec:Toggle({
                Name = "Auto Destroy", Flag = "AutoDestroy_"..name, Default = false,
                Callback = function(v)
                    auto_destroy[name] = v
                    local e = enemies:FindFirstChild(name)
                    if e then handleEnemy(e) end
                end
            })
        end
    end

    makeEnemySection("Bell",         "Bell",                  true,  true,  true)
    makeEnemySection("Mart",         "Mart",                  true,  true,  true)
    makeEnemySection("Skinwalker",   "Husk",                  true,  false, true)
    makeEnemySection("Springer",     "Springer",              true,  true,  true)
    makeEnemySection("ICBM",         "ICBM",                  false, true,  true)
    makeEnemySection("Baby",         "Baby",                  true,  true,  true)
    makeEnemySection("Flesh",        "Flesh",                 true,  true,  true)
    makeEnemySection("Telefragger",  "Telefragger",           true,  true,  true)
    makeEnemySection("Operator",     "Operator",              false, false, true)
    makeEnemySection("Kolona",       "Kolona",                false, false, true)
    makeEnemySection("Sigil",        "Sigil",                 false, false, true)
    makeEnemySection("Voidbreaker",  "Voidbreaker",           false, false, true)
    makeEnemySection("Cadence",      "Cadence",               true,  true,  true)
    makeEnemySection("ShadowBaby",   "Voidbound Baby",        true,  true,  true)
    makeEnemySection("Scrapmaw",     "Scrapmaw",              false, false, true)
    makeEnemySection("RealityBreak", "Reality Break",         false, false, true)
    makeEnemySection("Celestial",    "Celestial",             false, true,  true)

    local guardianSec = enemyPage:Section({ Name = "Guardian (CANNOT BE DISABLED)", Side = 1 })
    guardianSec:Toggle({
        Name = "Bullet Protection", Flag = "BulletProtection", Default = false,
        Callback = function(v)
            pb = v
            if not v then bulletprots:ClearAllChildren() end
        end
    })
end

-- ═══════════════════════════════════════════════════════════════════════
--  MAP PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local mapVoidSec   = mapPage:Section({ Name = "Void",    Side = 1 })
    local mapAltarSec  = mapPage:Section({ Name = "Altars",  Side = 2 })
    local mapHazardSec = mapPage:Section({ Name = "Hazards", Side = 1 })
    local mapTileSec   = mapPage:Section({ Name = "Tiles",   Side = 2 })
    local mapBloomSec  = mapPage:Section({ Name = "Bloom (Pylons)", Side = 1 })

    local antiVoidSelection = 1
    local lp = 500

    mapVoidSec:Toggle({
        Name = "Anti Void", Flag = "AntiVoid", Default = false,
        Callback = function(v) av = v end
    })
    mapVoidSec:Dropdown({
        Name = "Anti Void Mode", Flag = "AntiVoidMode",
        Items   = {"1. Teleport to Spawn","2. Launch Up","3. Closest Gift"},
        Default = "1. Teleport to Spawn", Multi = false,
        Callback = function(v)
            antiVoidSelection = tonumber(string.split(v, ".")[1])
        end
    })
    mapVoidSec:Slider({
        Name = "Launch Power", Flag = "AntiVoidLaunchPower",
        Min = 10, Max = 1000, Default = 500, Decimals = 1,
        Callback = function(v) lp = v end
    })
    mapVoidSec:Toggle({
        Name = "Visible Void", Flag = "VisibleVoid", Default = false,
        Callback = function(v)
            workspace.KillVoid.Transparency = v and 0 or 1
        end
    })

    -- Altars
    local altarVal = {}
    local selectedAltar, selectedPrompt
    local activating = false

    local selectAltars = mapAltarSec:Dropdown({
        Name = "Select Altar", Flag = "SelectedAltar",
        Items = {}, Default = "", Multi = false,
        Callback = function(v)
            selectedAltar  = v
            selectedPrompt = altarVal[v]
        end
    })

    local function updateAltarSelection()
        altarVal = {}
        local n, options = 1, {}
        for _, p in getAltarPrompts() do
            local text = n..". "..p.Text
            altarVal[text] = p.Prompt
            table.insert(options, text)
            n += 1
        end
        selectAltars:Set("")
        for _, opt in options do selectAltars:Add(opt) end
    end

    local function activateAltar(justTeleport)
        if activating and justTeleport == false then return end
        justTeleport = if justTeleport == nil then false else justTeleport
        if not justTeleport then activating = true end
        if not selectedPrompt or not selectedPrompt.Parent then
            notif("Altar no longer exists.", "Not found"); activating = false; return
        end
        local pPart = selectedPrompt.Parent
        local char = getChar(plr)
        local root, hitbox = getRoot(char)
        if not root or not hitbox then activating = false; return end
        local prev = root.CFrame
        local pos  = pPart.CFrame + pPart.CFrame.LookVector * -3
        Camera.CFrame = pos; root.CFrame = pos; hitbox.CFrame = pos
        local start = tick()
        repeat
            task.wait(.05)
            Camera.CFrame = pos; root.CFrame = pos; hitbox.CFrame = pos
        until (root.Position - pPart.Position).Magnitude < 6 or tick()-start >= 3
        if justTeleport then return end
        fireproximityprompt(selectedPrompt)
        task.wait(selectedPrompt.HoldDuration)
        root.CFrame = prev; hitbox.CFrame = prev
        activating = false
    end

    mapAltarSec:Button({ Name = "Activate Selected Altar",    Callback = function() activateAltar() end })
    mapAltarSec:Button({ Name = "Teleport to Selected Altar", Callback = function() activateAltar(true) end })
    mapAltarSec:Button({ Name = "Find Altars",                Callback = function() updateAltarSelection() end })
    updateAltarSelection()

    -- Hazards
    mapHazardSec:Toggle({
        Name = "Tripmine Protection (LAGGY ON HIGH LEVELS)", Flag = "TripmineProtection", Default = false,
        Callback = function(v) pt = v; if not v then tripmineprots:ClearAllChildren() end end
    })
    mapHazardSec:Toggle({
        Name = "Disable Void Implosions", Flag = "DisableVoidImplosions", Default = false,
        Callback = function(v)
            dvi = v
            if connections["dfca"] then connections["dfca"]:Disconnect(); connections["dfca"] = nil end
            local vic = gcurses:FindFirstChild("VoidImplosions")
            if dvi and vic then
                connections["dfca"] = destroyFolder.ChildAdded:Connect(function(child)
                    if child.Name == "VoidExplosion" then child:Destroy() end
                end)
            end
        end
    })
    mapHazardSec:Toggle({
        Name = "Disable Seamines", Flag = "DisableSeamines", Default = false,
        Callback = function(v)
            dsm = v
            if dsm then
                local n = 0
                for _, sm in pads:GetChildren() do
                    if sm.Name == "Seamine" then
                        local ti = sm:FindFirstChild("TouchInterest")
                        local ls = sm:FindFirstChild("ClientMine")
                        if ti then ti:Destroy(); n+=1 end
                        if ls then ls.Enabled = false end
                    end
                end
                if n > 0 then notif("Disabled "..n.." Seamine(s).", "Success")
                else notif("No Seamines found or all already disabled.", "Erm") end
            end
        end
    })
    mapHazardSec:Toggle({
        Name = "Disable Oblivion", Flag = "DisableOblivion", Default = false,
        Callback = function(v)
            dso = v
            if dso and enemies:FindFirstChild("Oblivion") then enemies.Oblivion:Destroy() end
        end
    })
    mapHazardSec:Toggle({
        Name = "Destroy Fake Beacons", Flag = "DestroyFakeBeacons", Default = false,
        Callback = function(v)
            nfb = v
            if nfb then
                for _, b in beacons:GetChildren() do
                    if b.Name == "BeaconMirage" then b:Destroy() end
                end
            end
        end
    })

    -- Tiles
    local partsConnected = {}

    mapTileSec:Label({ Name = "Press after each new level loads." })
    mapTileSec:Button({
        Name = "Create Tile Connections (LAGS ON PRESS)",
        Callback = function()
            for p, c in pairs(partsConnected) do c:Disconnect(); partsConnected[p] = nil end
            if #currentRooms:GetChildren() == 0 then notif("Level not loaded yet.", "Erm"); return end
            for _, p in ipairs(currentRooms:GetDescendants()) do
                if p:IsA("BasePart") and partsConnected[p] == nil then
                    partsConnected[p] = p:GetPropertyChangedSignal("Material"):Connect(function()
                        if (p.Material == Enum.Material.Ice and noice) or
                           (p.Material == Enum.Material.CorrodedMetal and noflesh) then
                            p.Material = Enum.Material.Air
                        end
                    end)
                    p.Destroying:Once(function() partsConnected[p]:Disconnect(); partsConnected[p] = nil end)
                    if noice   and p.Material == Enum.Material.Ice           then p.Material = Enum.Material.Air end
                    if noflesh and p.Material == Enum.Material.CorrodedMetal then p.Material = Enum.Material.Air end
                end
            end
        end
    })
    mapTileSec:Toggle({
        Name = "Auto Remove Ice Tiles", Flag = "RemoveIceTiles", Default = false,
        Callback = function(v)
            noice = v
            if partsConnected and noice then
                for p in pairs(partsConnected) do
                    if p.Material == Enum.Material.Ice then p.Material = Enum.Material.Air end
                end
            end
        end
    })
    mapTileSec:Toggle({
        Name = "Auto Remove Flesh Tiles", Flag = "RemoveFleshTiles", Default = false,
        Callback = function(v) noflesh = v end
    })

    -- Bloom / Pylons
    local selectedPylon; local pylonVal = {}
    local selectPylons = mapBloomSec:Dropdown({
        Name = "Select Pylon", Flag = "SelectedPylon",
        Items = {}, Default = "", Multi = false,
        Callback = function(v) selectedPylon = pylonVal[v] end
    })

    local function updatePylonSelection()
        pylonVal = {}; local n, options = 1, {}
        for _, p in currentRooms:GetChildren() do
            if p.Name == "CellPlatform" then
                local text = n..". Pylon"
                pylonVal[text] = p
                table.insert(options, text)
                n += 1
            end
        end
        selectPylons:Set("")
        for _, opt in options do selectPylons:Add(opt) end
    end

    local function teleportPylon()
        if not selectedPylon or not selectedPylon.Parent then
            notif("Pylon doesn't exist.", "Not found"); return
        end
        local pPart = selectedPylon.SpiralBase
        local char = getChar(plr); local root, hitbox = getRoot(char)
        if not root or not hitbox then return end
        local pos = pPart.CFrame + pPart.CFrame.LookVector * -3
        Camera.CFrame = pos; root.CFrame = pos; hitbox.CFrame = pos
        local start = tick()
        repeat
            task.wait(.05)
            Camera.CFrame = pos; root.CFrame = pos; hitbox.CFrame = pos
        until (root.Position - pPart.Position).Magnitude < 6 or tick()-start >= 3
    end

    mapBloomSec:Label({ Name = "RealityBreak — see Enemy page." })
    mapBloomSec:Button({ Name = "Teleport to Selected Pylon", Callback = function() teleportPylon() end })
    mapBloomSec:Button({ Name = "Find Pylons",                Callback = function() updatePylonSelection() end })
end

-- ═══════════════════════════════════════════════════════════════════════
--  PLAYER PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local plrHumanSec = plrPage:Section({ Name = "Humanoid", Side = 1 })
    local plrCharSec  = plrPage:Section({ Name = "Character", Side = 2 })

    local ew = false; local ej = false; local ws = 16; local jp = 35

    plrHumanSec:Toggle({
        Name = "Enable WalkSpeed Override", Flag = "EnableWalkSpeed", Default = false,
        Callback = function(v)
            ew = v
            local h = getHuman(getChar(plr))
            if h then h.WalkSpeed = ws end
        end
    })
    plrHumanSec:Toggle({
        Name = "Enable JumpPower Override", Flag = "EnableJumpPower", Default = false,
        Callback = function(v)
            ej = v
            local h = getHuman(getChar(plr))
            if h then h.JumpPower = jp end
        end
    })
    plrHumanSec:Slider({
        Name = "WalkSpeed", Flag = "WalkSpeedValue",
        Min = 5, Max = 200, Default = 16, Decimals = 1,
        Callback = function(v)
            ws = v
            local h = getHuman(getChar(plr))
            if h then h.WalkSpeed = ws end
        end
    })
    plrHumanSec:Slider({
        Name = "JumpPower", Flag = "JumpPowerValue",
        Min = 25, Max = 100, Default = 35, Decimals = 1,
        Callback = function(v)
            jp = v
            local h = getHuman(getChar(plr))
            if h then h.JumpPower = jp end
        end
    })

    plrCharSec:Toggle({
        Name = "Visible Hitbox", Flag = "VisibleHitbox", Default = false,
        Callback = function(v)
            visibleHitbox = v
            if not v then
                local root, hitbox = getRoot(getChar(plr))
                if root and hitbox then hitbox.Transparency = 1 end
            end
        end
    })
    plrCharSec:Toggle({
        Name = "Destroy Razorbloom (VISIBLE TO OTHERS)", Flag = "DestroyRazorbloom", Default = false,
        Callback = function(v) nrb = v end
    })
end

-- ═══════════════════════════════════════════════════════════════════════
--  VISUAL PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local visualEspSec = visualPage:Section({ Name = "ESP",        Side = 1 })
    local visualCamSec = visualPage:Section({ Name = "Camera",     Side = 2 })
    local visualVelSec = visualPage:Section({ Name = "Visualizer", Side = 2 })

    visualEspSec:Toggle({
        Name = "Closest Gift Tracer ESP (LAGGY)", Flag = "ClosestGiftESP", Default = false,
        Callback = function(v) cesp = v; closestGiftTracer.Visible = v end
    })
    visualEspSec:Toggle({
        Name = "Medal ESP", Flag = "MedalESP", Default = false,
        Callback = function(v) mesp = v; medalTracer.Visible = v end
    })
    visualEspSec:Toggle({
        Name = "Cadence Instrument ESP", Flag = "InstrumentESP", Default = false,
        Callback = function(v)
            instrumentesp = v
            if not v then for obj, line in pairs(tracers) do line:Destroy(); tracers[obj] = nil end end
        end
    })
    visualCamSec:Slider({
        Name = "Field of View", Flag = "CameraFOV",
        Min = 1, Max = 120, Default = math.floor(Camera.FieldOfView), Decimals = 1,
        Callback = function(v) workspace.CurrentCamera.FieldOfView = v end
    })
    visualVelSec:Toggle({
        Name = "Velocity Visualizer", Flag = "VelocityVisualizer", Default = false,
        Callback = function(v) velov = v end
    })
end

-- ═══════════════════════════════════════════════════════════════════════
--  KEYBINDS PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local keyActionSec = keyPage:Section({ Name = "Action Keybinds", Side = 1 })
    local keyEnableSec = keyPage:Section({ Name = "Enable Keybinds", Side = 2 })

    local canPress = true

    keyActionSec:Label({ Name = "Collect Normal Gifts" }):Keybind({
        Flag = "KB_CollectNormal", Default = Enum.KeyCode.Nine, Mode = "Toggle",
        Callback = function() if canEzCollectNormal then task.spawn(function() collect("normal") end) end end
    })
    keyActionSec:Label({ Name = "Collect Golden Gifts" }):Keybind({
        Flag = "KB_CollectGolden", Default = Enum.KeyCode.Zero, Mode = "Toggle",
        Callback = function() if canEzCollectGolden then task.spawn(function() collect("golden") end) end end
    })
    keyActionSec:Label({ Name = "Get Medal" }):Keybind({
        Flag = "KB_GetMedal", Default = Enum.KeyCode.Eight, Mode = "Toggle",
        Callback = function()
            if not canEzCollectMedal then return end
            local medal = beacons:FindFirstChild("Medal")
            local root, hitbox = getRoot(getChar(plr))
            if medal and root and not isDead(plr) then
                local sp = root.Position; root.Position = medal.Position
                task.wait(.2); root.Position = sp
            end
        end
    })
    keyActionSec:Label({ Name = "Disable All Enemies" }):Keybind({
        Flag = "KB_DisableAll", Default = Enum.KeyCode.H, Mode = "Toggle",
        Callback = function() if canEzDisableAll then disableAll(false,false,false) end end
    })
    keyActionSec:Label({ Name = "Disable Client-sided Enemies Only" }):Keybind({
        Flag = "KB_DisableClientOnly", Default = Enum.KeyCode.J, Mode = "Toggle",
        Callback = function() if canEzDisableAllC then disableAll(false,true) end end
    })
    keyActionSec:Label({ Name = "Reset Double Jumps / Ability" }):Keybind({
        Flag = "KB_FullReset", Default = Enum.KeyCode.T, Mode = "Toggle",
        Callback = function()
            if not canFullReset then return end
            local char = getChar(plr); local humanoid = char and getHuman(char)
            if char and humanoid and not isDead(plr) then
                humanoid:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end
    })
    keyActionSec:Label({ Name = "Bring Jump Pad" }):Keybind({
        Flag = "KB_BringPad", Default = Enum.KeyCode.Y, Mode = "Toggle",
        Callback = function()
            if not canBringPad then return end
            local pad = pads:FindFirstChild("JumpPad"); local root = getRoot(getChar(plr))
            if pad and root and not isDead(plr) then
                local pos = pad.Position; pad.Position = root.Position; task.wait(.01); pad.Position = pos
            end
        end
    })
    keyActionSec:Label({ Name = "Bring Tria Orb" }):Keybind({
        Flag = "KB_BringTria", Default = Enum.KeyCode.Two, Mode = "Toggle",
        Callback = function()
            if not canBringTria then return end
            local pad = pads:FindFirstChild("TriaOrb"); local root = getRoot(getChar(plr))
            if pad and root and not isDead(plr) then
                local pos = pad.Position; pad.Position = root.Position; task.wait(.01); pad.Position = pos
            end
        end
    })
    keyActionSec:Label({ Name = "Instant Grapple to Nearest Pad" }):Keybind({
        Flag = "KB_InstaGrapple", Default = Enum.KeyCode.Q, Mode = "Toggle",
        Callback = function()
            if not canInstaGrapple or not canPress then return end
            canPress = false
            local target = GetClosestPad()
            if not target then canPress = true; return end
            local cf = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = cf
            local sending = true
            task.spawn(function() while sending do Camera.CFrame = cf; task.wait() end end)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.01); sending = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            task.delay(0.05, function() canPress = true end)
        end
    })
    keyActionSec:Label({ Name = "Glider Boost / Fly (HOLD)" }):Keybind({
        Flag = "KB_GliderBoost", Default = Enum.KeyCode.Q, Mode = "Hold",
        Callback = function(holding)
            if not holding then gliderBoost = false; return end
            if canGliderBoost then gliderBoost = holding end
        end
    })
    keyActionSec:Label({ Name = "Teleport to Spawn" }):Keybind({
        Flag = "KB_GoHome", Default = Enum.KeyCode.Home, Mode = "Toggle",
        Callback = function()
            if not canGoHome then return end
            local root, hitbox = getRoot(getChar(plr))
            local pos = spawnPart.Position + Vector3.new(0,4,0)
            if root then root.Position = pos end
            if hitbox then hitbox.Position = pos end
        end
    })
    keyActionSec:Label({ Name = "Teleport to Beacon" }):Keybind({
        Flag = "KB_GoBeacon", Default = Enum.KeyCode.Insert, Mode = "Toggle",
        Callback = function()
            if not canGoBeacon then return end
            local root, hitbox = getRoot(getChar(plr))
            local pos = workspace.Beacon.Position + Vector3.new(0,4,0)
            if root then root.Position = pos end
            if hitbox then hitbox.Position = pos end
        end
    })
    keyActionSec:Label({ Name = "Cancel Collecting" }):Keybind({
        Flag = "KB_CancelTween", Default = Enum.KeyCode.End, Mode = "Toggle",
        Callback = function() if canCancelTween and tweening then tweening = false end end
    })

    local function makeEnableToggle(label, flag, setter)
        keyEnableSec:Toggle({
            Name = label.." Keybind", Flag = "KBEnable_"..flag, Default = true,
            Callback = setter
        })
    end

    makeEnableToggle("Collect Normal",      "CollectNormal",  function(v) canEzCollectNormal = v end)
    makeEnableToggle("Collect Golden",      "CollectGolden",  function(v) canEzCollectGolden = v end)
    makeEnableToggle("Get Medal",           "GetMedal",       function(v) canEzCollectMedal  = v end)
    makeEnableToggle("Disable All",         "DisableAll",     function(v) canEzDisableAll    = v end)
    makeEnableToggle("Disable Client Only", "DisableClient",  function(v) canEzDisableAllC   = v end)
    makeEnableToggle("Reset Ability",       "FullReset",      function(v) canFullReset        = v end)
    makeEnableToggle("Bring Jump Pad",      "BringPad",       function(v) canBringPad         = v end)
    makeEnableToggle("Bring Tria Orb",      "BringTria",      function(v) canBringTria        = v end)
    makeEnableToggle("Instant Grapple",     "InstaGrapple",   function(v) canInstaGrapple     = v end)
    makeEnableToggle("Glider Boost",        "GliderBoost",    function(v) canGliderBoost      = v end)
    makeEnableToggle("Teleport to Spawn",   "GoHome",         function(v) canGoHome           = v end)
    makeEnableToggle("Teleport to Beacon",  "GoBeacon",       function(v) canGoBeacon         = v end)
    makeEnableToggle("Cancel Collecting",   "CancelTween",    function(v) canCancelTween      = v end)
end

-- ═══════════════════════════════════════════════════════════════════════
--  MUSIC PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local musicFolder   = SoundService:FindFirstChild("MusicFolder")
    local currentCustom = nil
    local customPlaying = false

    local musicControlSec = musicPage:Section({ Name = "Controls", Side = 2 })
    local musicListSec    = musicPage:Section({ Name = "Tracks",   Side = 1 })

    local function stopCurrentMusic()
        if musicFolder then
            for _, s in musicFolder:GetDescendants() do
                if s:IsA("Sound") and s.Playing then s:Stop() end
            end
        end
        if music.Value then music.Value:Stop() end
        music.Value = nil; currentCustom = nil; customPlaying = false
    end

    local function playMusic(themusic)
        stopCurrentMusic()
        customPlaying = true; themusic:Play()
        music.Value = themusic; currentCustom = themusic
    end

    musicControlSec:Button({ Name = "Stop Current Music", Callback = function() stopCurrentMusic() end })

    if musicFolder then
        for _, sof in musicFolder:GetChildren() do
            if sof:IsA("Sound") then
                musicListSec:Button({ Name = "Play "..sof.Name, Callback = function() playMusic(sof) end })
            elseif sof:IsA("Folder") and sof.Name ~= "Intermission" then
                local nm = sof:FindFirstChild("Name")
                local n  = sof:FindFirstChild("MainSong")
                local c  = sof:FindFirstChild("EscapeSong")
                if nm then musicListSec:Label({ Name = nm.Value }) end
                if n  then musicListSec:Button({ Name = "Play Normal",   Callback = function() playMusic(n) end }) end
                if c  then musicListSec:Button({ Name = "Play Collapse", Callback = function() playMusic(c) end }) end
            end
        end
    else
        musicListSec:Label({ Name = "MusicFolder not found in SoundService." })
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  DEBUG PAGE (SCOPED IN DO...END BLOCK)
-- ═══════════════════════════════════════════════════════════════════════
do
    local debugUtilSec = debugPage:Section({ Name = "Utilities", Side = 1 })
    local debugMiscSec = debugPage:Section({ Name = "Misc",      Side = 2 })

    debugUtilSec:Button({
        Name = "Copy Lobby Code",
        Callback = function()
            if not code.Value or code.Value == "" or code.Value == " " then
                notif("You are in solo or code not found.", "Code"); return
            end
            toClipboard(code.Value)
        end
    })
    debugUtilSec:Toggle({
        Name = "Enable Reset Button", Flag = "EnableResetButton", Default = true,
        Callback = function(v) StarterGui:SetCore("ResetButtonCallback", v) end
    })
    StarterGui:SetCore("ResetButtonCallback", true)
    debugUtilSec:Toggle({
        Name = "Enable All Notifications", Flag = "NotificationsEnabled", Default = true,
        Callback = function(v) notifOn = v end
    })
    debugUtilSec:Button({
        Name = "Kill Character (Respawns in Intermission)",
        Callback = function()
            events.Died:FireServer("Void", shared.LeftGroundWithinBellMethod, game.ReplicatedStorage.Level.Value)
        end
    })

    debugMiscSec:Button({
        Name = "Rejoin (may not work)",
        Callback = function()
            if #Players:GetPlayers() <= 1 then
                Players.LocalPlayer:Kick("\nRejoining...")
                wait(); TeleportService:Teleport(PlaceId, plr)
            else
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId, plr)
            end
        end
    })
    debugMiscSec:Button({
        Name = "Destroy GUI / Panic",
        Callback = function() destroyGui() end
    })
end

-- ═══════════════════════════════════════════════════════════════════════
--  CONNECTIONS & LOOPS
-- ═══════════════════════════════════════════════════════════════════════

for _, enemy in ipairs(enemies:GetChildren()) do task.spawn(handleEnemy, enemy) end

table.insert(connections, workspace.Skinwalkers.ChildAdded:Connect(function(enemy)
    enemy.Name = "Skinwalker"; handleEnemy(enemy)
end))
table.insert(connections, enemies.ChildAdded:Connect(function(enemy)
    if enemy.Name == "Oblivion" and dso then enemy:Destroy(); return end
    if enemy.Name == "RealityBreak2" then enemy.Name = "RealityBreak" end
    task.spawn(function() handleEnemy(enemy) end)
end))
table.insert(connections, pads.ChildAdded:Connect(function(child)
    if dsm and child.Name == "Seamine" then
        task.wait(3)
        local ti = child:FindFirstChild("TouchInterest")
        local ls = child:FindFirstChild("ClientMine")
        if ti then ti:Destroy() end
        if ls then ls.Enabled = false end
    end
end))
table.insert(connections, music.Changed:Connect(function()
    if customPlaying and currentCustom and music.Value ~= currentCustom then
        music.Value:Stop(); music.Value = currentCustom
    end
end))

-- Heartbeat
local runLoop = RunService.Heartbeat:Connect(function()
    if (tweening or cesp) and not isDead(plr) then refreshGifts() end
    if isDead(plr) then return end

    local char = getChar(plr)
    local root, hitbox = getRoot(char)
    local h = getHuman(char)
    Camera = Camera or workspace.CurrentCamera

    if visibleHitbox and root and hitbox then
        hitbox.Transparency = 0
    end

    if av and root then
        local pos = spawnPart.Position + Vector3.new(0,4,0)
        if root.Position.Y <= workspace.KillVoid.Position.Y + 75 then
            if antiVoidSelection == 1 then
                root.Position = pos
            elseif antiVoidSelection == 2 then
                local alv = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(alv.X, lp, alv.Z)
            elseif antiVoidSelection == 3 then
                local giftList = #availableNormalGifts > 0 and availableNormalGifts or availableGoldenGifts
                local gift = getClosestGift(giftList)
                if gift then root.Position = gift.Position
                else root.Position = pos; notif("No gift nearby! Falling back to spawn.", "Anti Void") end
            end
            if hitbox then hitbox.Position = root.Position end
        end
    end

    if root and hitbox then
        if velov then
            local velocity = root.AssemblyLinearVelocity * Vector3.new(1,0.5,1)
            local speed    = velocity.Magnitude
            if speed > 0 then
                local direction = velocity.Unit
                local length    = math.clamp(speed * 0.5, 0.5, 150)
                local t         = math.clamp(speed / 75, 0, 1)
                local startPos  = root.Position
                local endPos    = startPos + direction * length
                velocityPart.Size  = Vector3.new(0.2, 0.2, length)
                velocityPart.CFrame = CFrame.lookAt((startPos+endPos)/2, endPos)
                velocityPart.Color = Color3.new(1, 1-t, 1-t)
                velocityPart.Transparency = 0
                vpBox.Size  = velocityPart.Size
                vpBox.Color3 = velocityPart.Color
                vpBox.Transparency = 0.25
            else
                velocityPart.Transparency = 1; vpBox.Transparency = 1
            end
        end
    end

    if h and not h:GetAttribute("loop") then
        h:SetAttribute("loop", true)
        connections["walkloop"] = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if h.WalkSpeed ~= ws and ew then h.WalkSpeed = ws end
        end)
        connections["jumploop"] = h:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if h.JumpPower ~= jp and ej then h.JumpPower = jp end
        end)
    end

    if nrb then
        local rb = char:FindFirstChild("Razorbloom")
        if rb then rb:Destroy(); notif("Razorbloom destroyed.", "Success") end
    end

    if nfb then
        for _, b in beacons:GetChildren() do
            if b.Name == "BeaconMirage" then b:Destroy() end
        end
    end
end)

-- Glider / Fly loop
local LV
task.spawn(function()
    local root = getRoot(getChar(plr))
    LV = root:FindFirstChild("LV_NULLGUI")
    if not LV then
        LV = Instance.new("LinearVelocity")
        LV.Name = "LV_NULLGUI"
        LV.Attachment0 = root.RootAttachment
        LV.RelativeTo  = Enum.ActuatorRelativeTo.World
        LV.MaxForce    = math.huge
        LV.VectorVelocity = Vector3.zero
        LV.Enabled = false; LV.Parent = root
    end
    while task.wait() do
        if gliderBoost then
            root = getRoot(getChar(plr))
            LV = root:FindFirstChild("LV_NULLGUI")
            if not LV then
                LV = Instance.new("LinearVelocity")
                LV.Name = "LV_NULLGUI"
                LV.Attachment0 = root.RootAttachment
                LV.RelativeTo  = Enum.ActuatorRelativeTo.World
                LV.MaxForce    = math.huge
                LV.VectorVelocity = Vector3.zero
                LV.Enabled = false; LV.Parent = root
            end
            Camera = workspace.CurrentCamera
            local lookVector = Camera.CFrame.LookVector
            if not isDead(plr) then
                LV.Enabled = true
                LV.VectorVelocity = lookVector * 100
                local targetCF = CFrame.lookAt(root.Position, root.Position + lookVector)
                root.CFrame = root.CFrame:Lerp(targetCF, 0.15)
            end
        else
            LV.Enabled = false; LV.VectorVelocity = Vector3.zero
        end
        if destroying then break end
    end
end)

-- Drawing / ESP
local lastUpdate = 0
local RATE       = 1/30

RunService:BindToRenderStep("NULLGUI_DRAWING", Enum.RenderPriority.Camera.Value + 1, function()
    if isDead(plr) then
        for obj, line in pairs(tracers) do line:Destroy(); tracers[obj] = nil end
        return
    end
    local now = tick()
    if now - lastUpdate < RATE then return end
    lastUpdate = now
    Camera = Camera or workspace.CurrentCamera

    if instrumentesp then
        local cadence = enemies:FindFirstChild("Cadence")
        if cadence then
            for _, co in cadence:GetChildren() do
                if co.Name == "ClonedOrb" then
                    if not co:FindFirstChild("BoxHandleAdornment") then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Size = co.Size; box.Adornee = co
                        box.AlwaysOnTop = true; box.ZIndex = 0
                        box.Color3 = Color3.new(0,0,1); box.Transparency = 0.75
                        box.Parent = co
                    end
                    if not tracers[co] then createTracer(co) end
                    local screenPos, visible = Camera:WorldToViewportPoint(co.Position)
                    local tracer = tracers[co]
                    if tracer then
                        local vp = Camera.ViewportSize
                        local from = Vector2.new(vp.X/2, vp.Y/2)
                        local to = visible and Vector2.new(screenPos.X, screenPos.Y)
                                           or Vector2.new(math.clamp(screenPos.X,0,vp.X), math.clamp(screenPos.Y,0,vp.Y))
                        tracer.Visible = true; tracer.From = from; tracer.To = to
                    end
                end
            end
        end
    else
        for obj, line in pairs(tracers) do line:Destroy(); tracers[obj] = nil end
    end

    for obj, line in pairs(tracers) do
        if not obj or not obj:IsDescendantOf(workspace) then line:Destroy(); tracers[obj] = nil end
    end

    if cesp then
        local gift = getClosestAnyGift()
        if gift then
            local screenPos, visible = Camera:WorldToViewportPoint(gift.Position)
            local vp = Camera.ViewportSize
            local from = Vector2.new(vp.X/2, vp.Y/2)
            local camCF = Camera.CFrame
            local dot = camCF.LookVector:Dot((gift.Position - camCF.Position).Unit)
            if not gift:FindFirstChild("BoxHandleAdornment") then
                local box = cgb or Instance.new("BoxHandleAdornment")
                cgb = box; box.Size = gift.Size; box.Adornee = gift
                box.AlwaysOnTop = true; box.ZIndex = 0
                box.Color3 = Color3.new(1,1,0); box.Transparency = 0.5; box.Parent = gift
            end
            local to
            if visible and dot > 0 then
                to = Vector2.new(screenPos.X, screenPos.Y)
            elseif dot < 0 then
                local center = Vector2.new(vp.X/2, vp.Y/2)
                local dir = (Vector2.new(screenPos.X, screenPos.Y) - center).Unit
                to = center + dir * math.max(vp.X, vp.Y)
            else
                to = Vector2.new(math.clamp(screenPos.X,0,vp.X), math.clamp(screenPos.Y,0,vp.Y))
            end
            closestGiftTracer.Visible = true; closestGiftTracer.From = from; closestGiftTracer.To = to
        else
            closestGiftTracer.Visible = false
            if cgb then cgb.Transparency = 1 end
        end
    else
        closestGiftTracer.Visible = false
        if cgb then cgb.Transparency = 1 end
    end

    if mesp then
        local medalUpgrade = upgrades:FindFirstChild("Medal")
        if medalUpgrade and medalUpgrade.Value == 1 then
            local medal = beacons:FindFirstChild("Medal")
            if medal then
                local screenPos, visible = Camera:WorldToViewportPoint(medal.Position)
                local vp = Camera.ViewportSize
                local from = Vector2.new(vp.X/2, vp.Y/2)
                local camCF = Camera.CFrame
                local dot = camCF.LookVector:Dot((medal.Position - camCF.Position).Unit)
                if not medal:FindFirstChild("BoxHandleAdornment") then
                    local box = mb or Instance.new("BoxHandleAdornment")
                    mb = box; box.Size = medal.Size; box.Adornee = medal
                    box.AlwaysOnTop = true; box.ZIndex = 0
                    box.Color3 = Color3.new(1,1,1); box.Transparency = 0.75; box.Parent = medal
                end
                local to
                if visible and dot > 0 then
                    to = Vector2.new(screenPos.X, screenPos.Y)
                elseif dot < 0 then
                    local center = Vector2.new(vp.X/2, vp.Y/2)
                    local dir = (Vector2.new(screenPos.X, screenPos.Y) - center).Unit
                    to = center + dir * math.max(vp.X, vp.Y)
                else
                    to = Vector2.new(math.clamp(screenPos.X,0,vp.X), math.clamp(screenPos.Y,0,vp.Y))
                end
                medalTracer.Visible = true; medalTracer.From = from; medalTracer.To = to
            else
                medalTracer.Visible = false
            end
        else
            medalTracer.Visible = false
        end
    else
        medalTracer.Visible = false
    end
end)

-- Hazard render step
RunService:BindToRenderStep("NULLGUI_HAZARD", Enum.RenderPriority.Last.Value + 2, function()
    if isDead(plr) then return end
    local char = getChar(plr); local root = getRoot(char)
    if not char or not root then return end

    if pt then
        for _, trip in getActiveTripmines() do
            if trip.Transparency ~= 1 then
                protectTripmine(trip)
                local uuid = trip:GetAttribute("uuid")
                if uuid then
                    local p = tripmineprots:FindFirstChild(uuid)
                    if p then p.Position = trip.Position end
                end
            end
        end
    end

    if pb and root then
        for _, b in bullets:GetChildren() do
            if b.Transparency ~= 1 then
                protectBullet(b)
                local uuid = b:GetAttribute("uuid")
                if uuid then
                    local p = bulletprots:FindFirstChild(uuid)
                    if p then p.Position = b.Position end
                end
            end
        end
        for _, p in bulletprots:GetChildren() do
            if p:IsA("BasePart") then
                local offset  = root.Position - p.Position
                local dist    = offset.Magnitude
                local radius  = p.Size.X / 2
                local pushDir = offset.Unit
                if dist < radius and isdirectionsafetopushfromguardianbullet(root.Position, pushDir) then
                    root.CFrame = root.CFrame + pushDir * 3
                elseif dist < radius then
                    local altDir = Vector3.new(-pushDir.Z, 0, pushDir.X)
                    if isdirectionsafetopushfromguardianbullet(root.Position, altDir) then
                        root.CFrame = root.CFrame + altDir * 3
                    else
                        root.Position = p.Position + Vector3.new(0, 10, 0)
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  DESTROY / PANIC UNLOAD
-- ═══════════════════════════════════════════════════════════════════════

function destroyGui()
    if destroying then return end
    destroying = true
    notif("Destroying GUI...", "Nullscape GUI")

    runLoop:Disconnect()
    RunService:UnbindFromRenderStep("NULLGUI_DRAWING")
    RunService:UnbindFromRenderStep("NULLGUI_HAZARD")

    tripmineprots:Destroy()
    bulletprots:Destroy()

    for obj, line in pairs(tracers) do line:Destroy(); tracers[obj] = nil end
    closestGiftTracer:Destroy()
    medalTracer:Destroy()
    if cgb then cgb:Destroy() end
    if mb  then mb:Destroy()  end

    for key, c in pairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = nil

    for p, c in pairs(partsConnected) do c:Disconnect() end
    partsConnected = nil

    for _, i in pairs(newInstances) do
        pcall(function() i:Destroy() end)
    end
    newInstances = nil

    tweening      = false
    gliderBoost   = false
    if LV then LV:Destroy() end
    velocityPart:Destroy()

    magnet:Fire({ Reset = math.huge })

    local marker = ReplicatedStorage:FindFirstChild("DESTROYNULLGUI")
    if marker then marker:Destroy() end

    task.wait(.2)
    Library:Exit()
end

-- ═══════════════════════════════════════════════════════════════════════
--  FINALIZE
-- ═══════════════════════════════════════════════════════════════════════

local destroyMarker = Instance.new("Part")
destroyMarker.Name   = "DESTROYNULLGUI"
destroyMarker.Parent = ReplicatedStorage
destroyMarker.Destroying:Once(destroyGui)

refreshGifts(true)

Window:Init()

notif("Null GUI Executed Successfully!", "Nullscape GUI")
