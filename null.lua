if not game:IsLoaded() then game.Loaded:Wait() end

----------------------some IY funcs (just clipboard ig)
function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set))

function toClipboard(txt)
	if everyClipboard then
		everyClipboard(tostring(txt))
		notif("Copied to clipboard", "Clipboard")
	else
		notif("Your exploit doesn't have the ability to use the clipboard", "Clipboard")
	end
end
--------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local PlaceId, JobId = game.PlaceId, game.JobId

local plr = Players.LocalPlayer

local events = ReplicatedStorage.Events

local Camera = workspace.CurrentCamera
local spawnPart = workspace.Spawn
local items = workspace.Item_Pools
local gifts = items.NormalGifts
local goldengifts = items.GoldenGifts
local tripmines = items.Tripmines
local goldentripmines = items.GoldTripmines
local enemies = workspace.Enemies
local giftEsp = workspace.Showlocation
local tripEsp = workspace.TripmineShowlocation
local selection = workspace:FindFirstChild("Select")
local collectGift: RemoteEvent = events.GiftCollected
local currentRooms = workspace.CurrentRooms
local pads = workspace.JumpPads
local code = ReplicatedStorage.CodeVal
local curses = ReplicatedStorage.CurseFolder.Curses
local gcurses = ReplicatedStorage.GreaterCurseFolder.Curses
local upgrades = ReplicatedStorage.UpgradeFolder.Upgrades
local beacons = workspace.Beacons
local destroyFolder = workspace.DestroyFolder
local bullets = items.Bullet

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
velocityPart.Color = Color3.new(1, 1, 1)
velocityPart.Size = Vector3.new(0.1, 0.1, 1)
velocityPart.Parent = workspace
local vpBox = Instance.new("BoxHandleAdornment")
vpBox.Color3 = Color3.new(1,1,1)
vpBox.AlwaysOnTop = true
vpBox.ZIndex = 0
vpBox.Adornee = velocityPart
vpBox.Parent = velocityPart

local tweening = false
local currentTween:tween = nil
local aura = false
local cesp = false
local mesp = false
local visibleHitbox = false
local canInstaGrapple = false
local canToggleAura = true
local canGoHome = true
local canEzDisableAll = true
local canEzDisableAllC = true
local canEzCollectNormal = true
local canEzCollectGolden = true
local canEzCollectMedal = true
local av = false
local noice = false
local noflesh = false
local instrumentesp = false
local pt = false
local pb = false
local dvi = false
local dsm = false
local dso = false
local velov = false
local nrb = false
local nfb = false
local connections = {}

local clientenemies = {
    "Kolona",
    "Voidbreaker",
    "Skinwalker",
    "Operator",
}


local tracers = {}
local availableNormalGifts = {}
local availableGoldenGifts = {}
local cgb
local mb

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Nullscape GUI",
   LoadingTitle = "Loading Nullscape GUI",
   LoadingSubtitle = "by John Nullscape (Ali)",
   ShowText = "Null!",

   ToggleUIKeybind = "K"
})

function notif(text: string, title: string, dur: number)
    Rayfield:Notify({
        Title = title or "Notification",
        Content = text or "Forgot to add text idiot",
        Duration = dur or 5
    })
end

local mainTab = Window:CreateTab("Main")
local enemyTab = Window:CreateTab("Enemy")
local mapTab = Window:CreateTab("Map")
local plrTab = Window:CreateTab("Player")
local visualTab = Window:CreateTab("Visual")
local keyTab = Window:CreateTab("Keybinds")
local debugTab = Window:CreateTab("Debug")

local function safeFind(root, path)
    local current = root

    for _, name in ipairs(path) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end

    return current
end

local function getChar(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function getHuman(char)
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char, humanoid)
    if not char then return nil end
    if not humanoid then humanoid = getHuman(char) end
    return char:FindFirstChild("HumanoidRootPart") or (humanoid and humanoid.RootPart), char:FindFirstChild("Hitbox")
end

local function isDead(target: Player? | Model?)
    if target:IsA("Player") then
        local char = target.Character
        local humanoid: Humanoid = char and getHuman(char)
        return char and (humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Dead or humanoid.Health <= 0))
            or char == nil
    elseif target:IsA("Model") then
        local humanoid = target and getHuman(target)
        return humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Dead or humanoid.Health <= 0)
            or target == nil
    else
        return target == nil
    end
end

local enemyimage = "rbxassetid://90968042204988"
local curseimage = "rbxassetid://71252790926685"
local upgradeimage = "rbxassetid://109624131383272"

local function checkIntermissionType()
    selection = selection or workspace:FindFirstChild("Select")
    local currentType = "ENEMIES"

    if selection then
        local imagelabel = safeFind(selection, {
            "Sign",
            "Billboard",
            "ImageLabel"
        })

        if imagelabel then
            if imagelabel.Image == enemyimage then
                currentType = "ENEMIES"
            elseif imagelabel.Image == curseimage then
                currentType = "CURSES"
            elseif imagelabel.Image == upgradeimage then
                currentType = "UPGRADES"
            end
        end
    end

    return currentType
end

local closestGiftTracer = Drawing.new("Line")
closestGiftTracer.Visible = false
closestGiftTracer.Thickness = 2
closestGiftTracer.Color = Color3.new(1, 1, 0)
closestGiftTracer.Transparency = 1

local medalTracer = Drawing.new("Line")
medalTracer.Visible = false
medalTracer.Thickness = 2
medalTracer.Color = Color3.new(0.75, 0.75, 0.75)
medalTracer.Transparency = 1

local function getClosestAnyGift()
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return end

    local rootPos = root.Position
    local closest, shortest = nil, math.huge

    local function check(list)
        for _, gift in ipairs(list) do
            if gift and gift.Transparency == 0 and gift:FindFirstChild("Collect") ~= nil then
                task.spawn(function()
                    local diff = gift.Position - rootPos
                    local dist = diff.Magnitude
                
                    if dist < shortest then
                        shortest = dist
                        closest = gift
                    end
                end)
            end
        end
    end

    check(availableNormalGifts)
    check(availableGoldenGifts)

    return closest
end

local function createTracer(obj)
    local line = Drawing.new("Line")
    line.Visible = true
    line.Thickness = 2
    line.Color = Color3.new(0, 0, 1)
    line.Transparency = 1

    tracers[obj] = line
end

local function removeTracer(obj)
    if tracers[obj] then
        tracers[obj]:Destroy()
        tracers[obj] = nil
    end
end

local lastRefresh = 0
local scanIndex = 1
local scanIndexTwo = 1
local SCAN_SIZE = 100
local normalList = {}
local goldenList = {}

local function updateGiftLists()
    normalList = gifts:GetChildren()
    goldenList = goldengifts:GetChildren()
end

local gca = gifts.ChildAdded:Connect(updateGiftLists)
local gcr = gifts.ChildRemoved:Connect(updateGiftLists)
local ggca = goldengifts.ChildAdded:Connect(updateGiftLists)
local ggcr = goldengifts.ChildRemoved:Connect(updateGiftLists)
table.insert(connections, gca)
table.insert(connections, gcr)
table.insert(connections, ggca)
table.insert(connections, ggcr)

updateGiftLists()

local function refreshGifts(skip, golden)
    local currentAvailableGifts = #availableNormalGifts
    if #availableNormalGifts == 0 or golden then
        currentAvailableGifts = #availableGoldenGifts
    end
    local REFRESH_RATE = (currentAvailableGifts > 5000 and 1/0.25) or (currentAvailableGifts > 3000 and 1/1) or (currentAvailableGifts > 1500 and 1/3) or (currentAvailableGifts > 1000 and 1/5) or (currentAvailableGifts > 500 and 1/12.5) or 1/25

    if not skip then
        if tick() - lastRefresh < REFRESH_RATE then return end
        lastRefresh = tick()
    end

    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return end

    local rootPos = root.Position

    for i = 1, SCAN_SIZE do
        task.spawn(function()
            local gift = normalList[scanIndex]
            if not gift then
                scanIndex = 1
                return
            end

            if gift.Transparency ~= 1 and gift:FindFirstChild("Collect") then
                local dist = (rootPos - gift.Position).Magnitude

                if dist <= 500 then
                    availableNormalGifts[#availableNormalGifts+1] = gift
                end
            end

            scanIndex += 1
        end)
    end

    for i = 1, SCAN_SIZE do
        task.spawn(function()
            local gift = goldenList[scanIndexTwo]
            if not gift then
                scanIndexTwo = 1
                return
            end

            if gift.Transparency ~= 1 and gift:FindFirstChild("Collect") then
                local dist = (rootPos - gift.Position).Magnitude

                if dist <= 500 then
                    availableGoldenGifts[#availableGoldenGifts+1] = gift
                end
            end

            scanIndexTwo += 1
        end)
    end
end

local function getActiveTripmines()
    local active = {}
    for _, mine in tripmines:GetChildren() do
        if mine.Transparency ~= 1 then
            table.insert(active, mine)
        end
    end
    for _, mine in goldentripmines:GetChildren() do
        if mine.Transparency ~= 1 then
            table.insert(active, mine)
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
        local pos = mine.Position
        local size = mine.Size
        local minMx, maxMx = pos.X - size.X/2, pos.X + size.X/2
        local minMy, maxMy = pos.Y - size.Y/2, pos.Y + size.Y/2
        local minMz, maxMz = pos.Z - size.Z/2, pos.Z + size.Z/2

        local overlapX = maxX >= minMx and minX <= maxMx
        local overlapY = maxY >= minMy and minY <= maxMy
        local overlapZ = maxZ >= minMz and minZ <= maxMz

        if overlapX and overlapY and overlapZ then
            return true
        end
    end
    for _, enemy in activeEnemies do
        if enemy:HasTag(".Disabled") then continue end
        local pos = enemy.Position
        local size = enemy.Size
        local minMx, maxMx = pos.X - size.X/2, pos.X + size.X/2
        local minMy, maxMy = pos.Y - size.Y/2, pos.Y + size.Y/2
        local minMz, maxMz = pos.Z - size.Z/2, pos.Z + size.Z/2

        local overlapX = maxX >= minMx and minX <= maxMx
        local overlapY = maxY >= minMy and minY <= maxMy
        local overlapZ = maxZ >= minMz and minZ <= maxMz

        if overlapX and overlapY and overlapZ then
            return true
        end
    end

    return false
end

local function getClosestGift(giftList)
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return end

    local rootPos = root.Position
    local closest, shortest = nil, math.huge

    for _, gift in ipairs(giftList) do
        if gift and gift.Transparency == 0 and gift:FindFirstChild("Collect") then 
            local diff = gift.Position - rootPos
            local dist = diff.Magnitude

            if dist < shortest then
                shortest = dist
                closest = gift
            end
        end
    end

    return closest, shortest
end

local function protectTripmine(trip)
    if not trip:GetAttribute("uuid") then
        trip:SetAttribute("uuid", HttpService:GenerateGUID(false))
    end

    local id = trip:GetAttribute("uuid")

    if tripmineprots:FindFirstChild(id) then return end

    local startPos = trip.Position

    local sizeoffset = trip.Size.X + 3

    local p = Instance.new("Part")
    p.Name = id
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(sizeoffset, sizeoffset, sizeoffset)
    p.Position = startPos
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 0
    p.Parent = tripmineprots

    trip:GetPropertyChangedSignal("Transparency"):Once(function()
        p:Destroy()
    end)
end

local function protectBullet(b)
    if not b:GetAttribute("uuid") then
        b:SetAttribute("uuid", HttpService:GenerateGUID(false))
    end

    local id = b:GetAttribute("uuid")

    if bulletprots:FindFirstChild(id) then return end

    local startPos = b.Position

    local sizeoffset = b.Size.X + 5

    local p = Instance.new("Part")
    p.Name = id
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(sizeoffset, sizeoffset, sizeoffset)
    p.Position = startPos
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Transparency = 0.35
    p.Parent = bulletprots

    b:GetPropertyChangedSignal("Transparency"):Once(function()
        p:Destroy()
    end)
end

local function goTo(part, activeTripmines, activeEnemies)
    if not activeEnemies then activeEnemies = enemies:GetChildren() end
    if not part then return end
    local char = getChar(plr)
    local root, hitbox = getRoot(char)
    local rootPos = root and root.Position
    if not root or not hitbox then return end

    local pos = part:IsA("Model") and part:GetPivot().Position or part.Position
    if part.Name == "Spawn" then pos += Vector3.new(0,4,0) end
    local diff = pos - rootPos
    local dist = diff.Magnitude
    if dist == 0 then return end

    local direction = diff.Unit
    root.CFrame = CFrame.new(root.Position, root.Position + direction) * CFrame.Angles(0, math.rad(90), 0)

    local blocked = pathBlocked(pos, activeTripmines, activeEnemies)
    if blocked and (part.Name == "Gift" or part.Name == "GoldGift") then
        root.Position = pos
        hitbox.Position = pos
        task.wait(.3)
        return
    end

    local info = TweenInfo.new(dist / 120, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(root, info, {Position = pos})
    tween:Play()
    TweenService:Create(hitbox, info, {Position = pos}):Play()

    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if pathBlocked(pos, activeTripmines, activeEnemies) then
                tween:Cancel()
                break
            end
            task.wait(0.05)
        end
    end)
    tween.Completed:Once(function()
        hitbox.Position = root.Position
    end)

    return tween
end



local function getAltarPrompts()
    local prompts = {}
    for _, p in currentRooms:GetDescendants() do
        if p.Name == "Prompt" and p:IsA("ProximityPrompt") then
            table.insert(prompts, {
                Prompt = p,
                Text = p.ObjectText
            })
        end
    end

    return prompts
end

local function disableEnemy(enemyName, willDestroy, willBreakAI, failNotif)
    if failNotif == nil then
        failNotif = true
    end
    if willBreakAI == nil then
        willBreakAI = false
    end
    
    local function loopEnemies(name, remove, list)
        list = list or enemies
        remove = remove or "TouchInterest"
        local n = 0

        local enemiesFound = {}

        for _, sameenemy in list:GetChildren() do
            if sameenemy.Name ~= name then continue end

            for _, part in sameenemy:GetChildren() do
                if part.Name == remove then
                    part:Destroy()
                    n += 1
                end
            end
                    
            if not sameenemy:HasTag(".Disabled") then
               sameenemy:AddTag(".Disabled")
            end

            table.insert(enemiesFound, sameenemy)
        end

        return n, enemiesFound
    end
    local function destroyEnemy(name, list)
        list = list or enemies

        for _,sameenemy in list:GetChildren() do
            if sameenemy.Name == name then
                sameenemy:Destroy()
            end
        end

        notif(name.." disabled. (destroyed)", "Enemy")
        return true
    end

    local disableFunction = {
        Basic = function(name, willDestroy, willBreakAI)
            if not name then return end --how the fuck is there no names
            if willDestroy then
                return destroyEnemy(name)
            end
            local n, enemiesFound = loopEnemies(name)

            if n > 0 then
                notif(tostring(n).." "..name.."(s) disabled.", "Enemy")

                if willBreakAI then
                        for _, e in pairs(enemiesFound) do
                        local clientScript = e:FindFirstChild(name.."_ClientAI")
                    
                        if clientScript then
                            clientScript.Enabled = false
                        end
                    end
                end

                return true
            else
                if failNotif == true then
                    print(failNotif)
                    notif(name.." cannot be disabled, or already disabled.", "Enemy")
                end
                return false
            end
        end,
        Bell = function(name, willDestroy, willBreakAI)
            if willDestroy then
                return destroyEnemy(name)
            end
            local n, enemiesFound = loopEnemies(name)

            if n > 0 then
                notif(tostring(n).." Bell(s) disabled.", "Enemy")

                if willBreakAI then
                        for _, b in pairs(enemiesFound) do
                        local clientScript = b:FindFirstChild(name.."_ClientAI")
                    
                        if clientScript then
                            clientScript.Enabled = false
                        end
                    end
                end

                return true
            else
                if failNotif == true then
                    notif("Bell cannot be disabled, or already disabled.", "Enemy")
                end
                return false
            end

        end,
        Skinwalker = function(name, willDestroy, willBreakAI)
            local skinwalkers = workspace.Skinwalkers
            if #skinwalkers:GetChildren() == 0 then
                if failNotif then
                    notif("Husk isn't following you yet.", "Enemy")
                end
                return false
            end
            if willDestroy then
                return destroyEnemy(name, skinwalkers)
            end

            local n = loopEnemies("Skinwalker", "TouchInterest", skinwalkers)
            n += loopEnemies("TallSkinwalker", "TouchInterest", skinwalkers)
            n += loopEnemies("Skinwalker1", "TouchInterest", skinwalkers)

            if n > 0 then
                notif(tostring(n).." Husk(s) disabled.", "Enemy")
                return true
            else
                if failNotif == true then
                    notif("Husks are already disabled.", "Enemy")
                end
                return true
            end
        end,
        Springer = function(name, willDestroy, willBreakAI)
            if not willDestroy then
                loopEnemies(name, "SpringerShockwave")
                local n, enemiesFound = loopEnemies(name, "DemonShockwave")

                if n > 0 then
                    notif(tostring(n).." Springer(s) disabled.", "Enemy")

                    if willBreakAI then
                            for _, s in pairs(enemiesFound) do
                            local clientScript = s:FindFirstChild("Springer_ClientAI")

                            if clientScript then
                                clientScript.Enabled = false
                            end
                        end
                    end

                    return true
                else
                    if failNotif == true then
                        notif("No Springers left to disable.", "Enemy")
                    end
                    return true
                end
            else
                return destroyEnemy(name)
            end
        end,
        ICBM = function(name, willDestroy, willBreakAI)
            if not willDestroy then
                local _, enemiesFound = loopEnemies(name)

                if #enemiesFound > 0 then
                    local n = 0

                    for _, s in pairs(enemiesFound) do
                        local clientScript = s:FindFirstChild("ICBM_ClientAI")

                        if clientScript and clientScript.Enabled == true then
                            clientScript.Enabled = false
                            n += 1
                        end
                    end

                    if n > 0 then
                        notif(tostring(n).." ICBM(s) disabled.", "Enemy")
                    elseif failNotif == true then
                        notif("No ICBMs left to disable.", "Enemy")
                    end
                    return true
                end
            else
                return destroyEnemy(name)
            end
        end,
        Kolona = function(name, willDestroy, willBreakAI)
           return destroyEnemy(name)
        end,
        Operator = function(name, willDestroy, willBreakAI)
           return destroyEnemy(name)
        end,
        Voidbreaker = function(name, willDestroy, willBreakAI)
           return destroyEnemy(name)
        end,
        Scrapmaw = function(name, willDestroy, willBreakAI)
            return destroyEnemy(name)
        end
    }

    if disableFunction[enemyName] then
        return disableFunction[enemyName](enemyName, willDestroy, willBreakAI)
    else
        return disableFunction.Basic(enemyName, willDestroy, willBreakAI)
    end
end

local function GetClosestPad()
    local localChar = getChar(plr)
    if not localChar then return nil end

    local root,hitbox = getRoot(localChar)
    if not root then return nil end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {localChar}

    local badColor = Color3.fromRGB(152, 24, 24)
    local closest = nil
    local dist = 100

    for _, part in pads:GetChildren() do
        if part.Color == badColor then print("bad color") continue end
        local mag = (root.Position - part.Position).Magnitude
        if mag > dist then print(mag, ">", dist, "part too far") continue end

        local origin = root.Position
        local direction = part.Position - origin

        local result = workspace:Raycast(origin, direction, rayParams)
        local visible = false

        if result then
            local hit = result.Instance
            if hit:IsDescendantOf(pads) then
                visible = true
            else
                visible = false
            end
        end

        if visible then
            dist = mag
            closest = part
        end
    end

    return closest
end

local function getSeamines()
    local seamines = {}

    for _, sm in pads:GetChildren() do
        if sm.Name == "Seamine" then
            table.insert(seamines, sm)
        end
    end

    return seamines
end

local function isdirectionsafetopushfromguardianbullet(pos, direction)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}

    local result = workspace:Raycast(pos, direction * 6, rayParams)
    return result ~= nil and result.Instance and result.Instance.CanCollide == true
end

---------------------collection
local function collect(which)
    local activeTripmines = getActiveTripmines()

    local function collectGolden()
        if tweening then notif("Already collecting.", "Collection System") return end
        tweening = true
        local startRefreshing

        while tweening do
            local char = getChar(plr)
            local root = getRoot(char)
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end

            if not startRefreshing then
                refreshGifts(true, true)
            elseif tick() - startRefreshing >= 15 then
                startRefreshing = tick()
                refreshGifts(true, true)
            end

            local gift = getClosestGift(availableGoldenGifts)
            if not gift then
                notif("no golden gifts, or currently finding golden gifts", "Gift Not Found")
                break
            end
            if not startRefreshing then
                startRefreshing = tick()
            end

            local tween = goTo(gift, activeTripmines, enemies:GetChildren())
            if tween then tween.Completed:Wait() end

            task.wait(.02)
        end
        tweening = false
    end

    local function collectNormal(getGoldenAfter)
        if tweening then notif("Already collecting.", "Collection System") return end
        tweening = true
        local startRefreshing

        while tweening do
            local char = getChar(plr)
            local root = getRoot(char)
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end

            if not startRefreshing then
                refreshGifts(true, true)
            elseif tick() - startRefreshing >= 15 then
                startRefreshing = tick()
                refreshGifts(true, true)
            end

            local gift = getClosestGift(availableNormalGifts)
            if not gift then
                notif("no gifts, or currently finding gifts", "Gift Not Found")
                break
            end
            if not startRefreshing then
                startRefreshing = tick()
            end

            local tween = goTo(gift, activeTripmines, enemies:GetChildren())
            if tween then tween.Completed:Wait() end

            task.wait(.02)
        end
        tweening = false
        if getGoldenAfter then task.wait(3) collectGolden() end
    end

    if which == "normal" then
        collectNormal()
    elseif which == "golden" then
        collectGolden()
    end
end

---------button
mainTab:CreateSection("Gifts")
mainTab:CreateParagraph({
    Title = "NOTE",
    Content = "Currently, finding gifts are slow. Spam the Collect Normal and Golden Gifts button to start collecting."
})
mainTab:CreateButton({
    Name = "Collect Normal Gifts",
    Callback = function()
        collect("normal")
    end
})
mainTab:CreateButton({
    Name = "Collect Golden Gifts",
    Callback = function()
        collect("golden")
    end
})
-- local ga = mainTab:CreateToggle({
--     Name = "Collect Aura (LAGGY ON HIGHER LEVELS)",
--     CurrentValue = aura,
--     Callback = function(Value)
--         aura = Value
--     end
-- })


enemyTab:CreateSection("All Enemies") ----------------------------------------------------------------------------------------------
local selectedEnemies = {}

local selectEnemies = enemyTab:CreateDropdown({
   Name = "Select Enemy",
   Options = {},
   CurrentOption = {},
   MultipleOptions = true,
   Callback = function(Options)
        selectedEnemies = Options
   end,
})

local function updateEnemySelection()
    local enemiesactive = {}
    local seen = {}

    local activeEnemies = enemies:GetChildren()
    if #activeEnemies == 0 then
        selectEnemies:Refresh({})
        selectEnemies:Set({})
        return {}
    end

    for _, enemy in activeEnemies do
        if not seen[enemy.Name] then
            seen[enemy.Name] = true
            table.insert(enemiesactive, enemy.Name)
        end
    end

    selectEnemies:Refresh(enemiesactive)
    return enemiesactive
end
updateEnemySelection()

local function disableSelected(willDestroy: boolean, willBreakAi: boolean)
    if selectedEnemies then
        for _, enemy in selectedEnemies do
            task.spawn(function()
                disableEnemy(enemy, willDestroy, willBreakAi)
            end)
        end
    else
        notif("No Enemy Selected", "Not found")
    end
end
local function disableAll(willDestroy: boolean, client: boolean, willBreakAi: boolean)
    local allenemies = updateEnemySelection()
    if not allenemies or #allenemies == 0 then
        notif("No enemies available.", "Not found")
        return
    end

    if client then
        for _, enemy in clientenemies do
            if not enemies:FindFirstChild(enemy) then continue end
            disableEnemy(enemy, willDestroy, willBreakAi)
        end

        return
    end

    for _, enemy in allenemies do
        disableEnemy(enemy, willDestroy, willBreakAi)
    end
end

enemyTab:CreateButton({
    Name = "Disable Client-sided Enemies Only",
    Callback = function()
        disableAll(false, true)
    end
})
enemyTab:CreateButton({
    Name = "Break Client-sided Enemies Only",
    Callback = function()
        disableAll(false, true, true)
    end
})
enemyTab:CreateButton({
    Name = "Disable Selected Enemies",
    Callback = function()
        disableSelected()
    end
})
enemyTab:CreateButton({
    Name = "Disable All",
    Callback = function()
        disableAll()
    end
})
enemyTab:CreateButton({
    Name = "Break Selected Enemies",
    Callback = function()
        disableSelected(false, true)
    end
})
enemyTab:CreateButton({
    Name = "Break All",
    Callback = function()
        disableAll(false, false, true)
    end
})
enemyTab:CreateButton({
    Name = "Destroy Selected Enemies",
    Callback = function()
        disableSelected(true)
    end
})
enemyTab:CreateButton({
    Name = "Destroy All",
    Callback = function()
        disableAll(true)
    end
})
enemyTab:CreateDivider()


local auto_disable = {}
auto_disable.Bell = false
auto_disable.Mart = false
auto_disable.Skinwalker = false
auto_disable.Springer = false
auto_disable.Baby = false
auto_disable.Flesh = false
auto_disable.nilEnemy = false
auto_disable.Telefragger = false
auto_disable.ShadowBaby = false

local auto_break = {}
auto_break.Bell = false
auto_break.Mart = false
auto_break.Skinwalker = false
auto_break.Springer = false
auto_break.ICBM = false
auto_break.Baby = false
auto_break.Flesh = false
auto_break.nilEnemy = false
auto_break.Telefragger = false
auto_break.ShadowBaby = false

local auto_destroy = {}
auto_destroy.Bell = false
auto_destroy.Mart = false
auto_destroy.Skinwalker = false
auto_destroy.Springer = false
auto_destroy.ICBM = false
auto_destroy.Baby = false
auto_destroy.Flesh = false
auto_destroy.Operator = false
auto_destroy.Kolona = false
auto_destroy.nilEnemy = false
auto_destroy.Telefragger = false
auto_destroy.ShadowBaby = false
auto_destroy.Voidbreaker = false
auto_destroy.Cadence = false
auto_destroy.Scrapmaw = false

local function handleEnemy(enemy)
    local name = enemy.Name
    local waitingTime = 7.5

    if name == "ICBM" or name == "Telefragger" then
        waitingTime = 35
    end
    if name == "Springer" then
        waitingTime = 10
    end

    if auto_destroy[name] then
        local start = tick()
        local didDestroy = disableEnemy(name, true, false, false)

        repeat
            if tick() - start >= waitingTime then break end
            didDestroy = disableEnemy(name, true, false, false)
            disableEnemy(enemyName, willDestroy, willBreakAi, failNotif)
            task.wait(1)
        until didDestroy == true
    elseif auto_break[name] then
        if name == "Mart" and curses:FindFirstChild("MartSlide") then
            notif("Destroy Mart instead of breaking.", "MART SLIDE DETECTED")
        end

        local start = tick()
        local didBreak = disableEnemy(name, false, true, false)

        repeat
            if tick() - start >= waitingTime then break end
            didBreak = disableEnemy(name, false, true, false)
            task.wait(1)
        until didBreak == true
    elseif auto_disable[name] then
        if name == "Mart" and curses:FindFirstChild("MartSlide") then
            notif("Destroy Mart instead of disabling.", "MART SLIDE DETECTED")
        end

        local start = tick()
        local didDisable = disableEnemy(name, false, false, false)

        repeat
            if tick() - start >= waitingTime then break end
            didDisable = disableEnemy(name, false, false, false)
            task.wait(1)
        until didDisable == true
    end

end


enemyTab:CreateSection("Bell")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Bell,
    Callback = function(v)
        auto_disable.Bell = v
        local bell = enemies:FindFirstChild("Bell") 
        if bell then
            handleEnemy(bell)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Bell,
    Callback = function(v)
        auto_break.Bell = v
        local bell = enemies:FindFirstChild("Bell") 
        if bell then
            handleEnemy(bell)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Bell,
    Callback = function(v)
        auto_destroy.Bell = v
        local bell = enemies:FindFirstChild("Bell") 
        if bell then
            handleEnemy(bell)
        end
    end
})

enemyTab:CreateSection("Mart")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Mart,
    Callback = function(v)
        auto_disable.Mart = v
        local mart = enemies:FindFirstChild("Mart") 
        if mart then
            handleEnemy(mart)
        end

        if curses:FindFirstChild("MartSlide") then
            notif("Destroy Mart instead of disabling.", "MART SLIDE DETECTED")
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Mart,
    Callback = function(v)
        auto_break.Mart = v
        local Mart = enemies:FindFirstChild("Mart") 
        if Mart then
            handleEnemy(Mart)
        end
        
        if curses:FindFirstChild("MartSlide") then
            notif("Destroy Mart instead of breaking.", "MART SLIDE DETECTED")
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Mart,
    Callback = function(v)
        auto_destroy.Mart = v
        local mart = enemies:FindFirstChild("Mart") 
        if mart then
            handleEnemy(mart)
        end
    end
})

enemyTab:CreateSection("Husk")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Skinwalker,
    Callback = function(v)
        auto_disable.Skinwalker = v
        local husk = enemies:FindFirstChild("Skinwalker") 
        if husk then
            handleEnemy(husk)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Skinwalker,
    Callback = function(v)
        auto_destroy.Skinwalker = v
        local husk = enemies:FindFirstChild("Skinwalker") 
        if husk then
            handleEnemy(husk)
        end
    end
})

enemyTab:CreateSection("Springer")
enemyTab:CreateToggle({
    Name = "Auto Disable Shockwaves",
    CurrentValue = auto_disable.Springer,
    Callback = function(v)
        auto_disable.Springer = v
        local springer = enemies:FindFirstChild("Springer") 
        if springer then
            handleEnemy(springer)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Springer,
    Callback = function(v)
        auto_break.Springer = v
        local Springer = enemies:FindFirstChild("Springer") 
        if Springer then
            handleEnemy(Springer)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Springer,
    Callback = function(v)
        auto_destroy.Springer = v
        local springer = enemies:FindFirstChild("Springer") 
        if springer then
            handleEnemy(springer)
        end
    end
})

enemyTab:CreateSection("ICBM")
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.ICBM,
    Callback = function(v)
        auto_break.ICBM = v
        local ICBM = enemies:FindFirstChild("ICBM") 
        if ICBM then
            handleEnemy(ICBM)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.ICBM,
    Callback = function(v)
        auto_destroy.ICBM = v
        local ICBM = enemies:FindFirstChild("ICBM") 
        if ICBM then
            handleEnemy(ICBM)
        end
    end
})

enemyTab:CreateSection("Baby")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Baby,
    Callback = function(v)
        auto_disable.Baby = v
        local baby = enemies:FindFirstChild("Baby") 
        if baby then
            handleEnemy(baby)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Baby,
    Callback = function(v)
        auto_break.Baby = v
        local Baby = enemies:FindFirstChild("Baby") 
        if Baby then
            handleEnemy(Baby)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Baby,
    Callback = function(v)
        auto_destroy.Baby = v
        local baby = enemies:FindFirstChild("Baby") 
        if baby then
            handleEnemy(baby)
        end
    end
})

enemyTab:CreateSection("Flesh")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Flesh,
    Callback = function(v)
        auto_disable.Flesh = v
        local flesh = enemies:FindFirstChild("Flesh") 
        if flesh then
            handleEnemy(flesh)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Flesh,
    Callback = function(v)
        auto_break.Flesh = v
        local Flesh = enemies:FindFirstChild("Flesh") 
        if Flesh then
            handleEnemy(Flesh)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Flesh,
    Callback = function(v)
        auto_destroy.Flesh = v
        local flesh = enemies:FindFirstChild("Flesh") 
        if flesh then
            handleEnemy(flesh)
        end
    end
})

enemyTab:CreateSection("Guardian (CANNOT BE DISABLED)")
local bpt = enemyTab:CreateToggle({
    Name = "Create Protection",
    CurrentValue = pb,
    Callback = function(Value)
        pb = Value
        if not Value then
            bulletprots:ClearAllChildren()
        end
    end
})

enemyTab:CreateSection("Operator")
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Operator,
    Callback = function(v)
        auto_destroy.Operator = v
        local Operator = enemies:FindFirstChild("Operator") 
        if Operator then
            handleEnemy(Operator)
        end
    end
})

enemyTab:CreateSection("Kolona")
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Kolona,
    Callback = function(v)
        auto_destroy.Kolona = v
        local Kolona = enemies:FindFirstChild("Kolona") 
        if Kolona then
            handleEnemy(Kolona)
        end
    end
})

enemyTab:CreateSection("Nil")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.nilEnemy,
    Callback = function(v)
        auto_disable.nilEnemy = v
        local nilEnemy = enemies:FindFirstChild("nilEnemy") 
        if nilEnemy then
            handleEnemy(nilEnemy)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.nilEnemy,
    Callback = function(v)
        auto_break.nilEnemy = v
        local nilEnemy = enemies:FindFirstChild("nilEnemy") 
        if nilEnemy then
            handleEnemy(nilEnemy)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.nilEnemy,
    Callback = function(v)
        auto_destroy.nilEnemy = v
        local nilEnemy = enemies:FindFirstChild("nilEnemy") 
        if nilEnemy then
            handleEnemy(nilEnemy)
        end
    end
})

enemyTab:CreateSection("Telefragger")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Telefragger,
    Callback = function(v)
        auto_disable.Telefragger = v
        local Telefragger = enemies:FindFirstChild("Telefragger") 
        if Telefragger then
            handleEnemy(Telefragger)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Telefragger,
    Callback = function(v)
        auto_break.Telefragger = v
        local Telefragger = enemies:FindFirstChild("Telefragger") 
        if Telefragger then
            handleEnemy(Telefragger)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Telefragger,
    Callback = function(v)
        auto_destroy.Telefragger = v
        local Telefragger = enemies:FindFirstChild("Telefragger") 
        if Telefragger then
            handleEnemy(Telefragger)
        end
    end
})

enemyTab:CreateSection("Voidbreaker")
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Voidbreaker,
    Callback = function(v)
        auto_destroy.Voidbreaker = v
        local Voidbreaker = enemies:FindFirstChild("Voidbreaker") 
        if Voidbreaker then
            handleEnemy(Voidbreaker)
        end
    end
})

enemyTab:CreateSection("Cadence")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.Cadence,
    Callback = function(v)
        auto_disable.Cadence = v
        local Cadence = enemies:FindFirstChild("Cadence") 
        if Cadence then
            handleEnemy(Cadence)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.Cadence,
    Callback = function(v)
        auto_break.Cadence = v
        local Cadence = enemies:FindFirstChild("Cadence") 
        if Cadence then
            handleEnemy(Cadence)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Cadence,
    Callback = function(v)
        auto_destroy.Cadence = v
        local Cadence = enemies:FindFirstChild("Cadence") 
        if Cadence then
            handleEnemy(Cadence)
        end
    end
})

enemyTab:CreateSection("Voidbound Baby")
enemyTab:CreateToggle({
    Name = "Auto Disable",
    CurrentValue = auto_disable.ShadowBaby,
    Callback = function(v)
        auto_disable.ShadowBaby = v
        local ShadowBaby = enemies:FindFirstChild("ShadowBaby") 
        if ShadowBaby then
            handleEnemy(ShadowBaby)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Break AI",
    CurrentValue = auto_break.ShadowBaby,
    Callback = function(v)
        auto_break.ShadowBaby = v
        local ShadowBaby = enemies:FindFirstChild("ShadowBaby") 
        if ShadowBaby then
            handleEnemy(ShadowBaby)
        end
    end
})
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.ShadowBaby,
    Callback = function(v)
        auto_destroy.ShadowBaby = v
        local ShadowBaby = enemies:FindFirstChild("ShadowBaby") 
        if ShadowBaby then
            handleEnemy(ShadowBaby)
        end
    end
})

enemyTab:CreateSection("Voidbound Guardian")
enemyTab:CreateLabel("Cannot be disabled.")

enemyTab:CreateSection("Scrapmaw")
enemyTab:CreateToggle({
    Name = "Auto Destroy",
    CurrentValue = auto_destroy.Scrapmaw,
    Callback = function(v)
        auto_destroy.Scrapmaw = v
        local Scrapmaw = enemies:FindFirstChild("Scrapmaw") 
        if Scrapmaw then
            handleEnemy(Scrapmaw)
        end
    end
})

enemyTab:CreateSection("")
enemyTab:CreateSection("")
enemyTab:CreateSection("")
enemyTab:CreateSection("")
enemyTab:CreateSection("")

enemyTab:CreateSection("Blossom") ------------just for fun!!!!!!!!!!!!!!!!!!!!!
enemyTab:CreateToggle({
    Name = "???",
    CurrentValue = false,
    Callback = function()
        notif("bloom", "Celestial")
        warn("doom")
    end
})
enemyTab:CreateToggle({
    Name = "???",
    CurrentValue = false,
    Callback = function()
        notif("bloom", "Celestial")
        warn("doom")
    end
})

--------------map

mapTab:CreateSection("Void")
local antiVoidSelection = 1

local avt = mapTab:CreateToggle({
    Name = "Anti Void",
    CurrentValue = av,
    Callback = function(Value)
        av = Value
    end
})
local avs = mapTab:CreateDropdown({
    Name = "Anti Void Setting",
    Options = {
        "1. Teleport to Spawn",
        "2. Launch Up",
        "3. Closest Gift"
    },
    CurrentOption = {"1. Teleport to Spawn"},
    MultipleOptions = false,
    Callback = function(Options)
        antiVoidSelection = tonumber(string.split(Options[1], ".")[1])
    end
})
local lp = 500
mapTab:CreateSlider({
    Name = "Launch Power",
    Range = {10, 1000},
    Increment = 10,
    CurrentValue = lp,
    Callback = function(Value)
        lp = Value
    end
})

local vv = mapTab:CreateToggle({
    Name = "Visible Void",
    CurrentValue = false,
    Callback = function(Value)
        if not Value then
            workspace.KillVoid.Transparency = 1
        else
            workspace.KillVoid.Transparency = 0
        end
    end
})

mapTab:CreateSection("Altars")
local altarVal = {}
local selectedAltar
local selectedPrompt
local activating = false

local selectAltars = mapTab:CreateDropdown({
   Name = "Select Altar",
   Options = {},
   CurrentOption = {},
   MultipleOptions = false,
   Callback = function(Options)
        selectedAltar = Options[1]
        selectedPrompt = altarVal[selectedAltar]
   end
})

local function updateAltarSelection()
    altarVal = {}

    local n = 1
    local options = {}

    for _, p in getAltarPrompts() do
        local text = n..". "..p.Text
        altarVal[text] = p.Prompt
        table.insert(options, text)
        n += 1
    end
    selectAltars:Set("")
    selectAltars:Refresh(options)
end

updateAltarSelection()

local function activateAltar(justTeleport)
    if activating and justTeleport == false then return end
    if justTeleport == nil then
        justTeleport = false
    end

    if not justTeleport then
        activating = true
    end

    if not selectedPrompt or not selectedPrompt.Parent then
        notif("Altar no longer exists.", "Not found")
        activating = false
        return
    end

    local pPart = selectedPrompt.Parent
    local char = getChar(plr)
    local root, hitbox = getRoot(char)
    if not root or not hitbox then
        activating = false
        return
    end

    local prev = root.CFrame
    local pos = pPart.CFrame + pPart.CFrame.LookVector * -3
    Camera.CFrame = pos
    root.CFrame = pos
    hitbox.CFrame = pos

    local start = tick()
    repeat
        task.wait(.05)
        Camera.CFrame = pos
        root.CFrame = pos
        hitbox.CFrame = pos
    until (root.Position - pPart.Position).Magnitude < 6 or tick() - start >= 3

    if justTeleport then return end

    fireproximityprompt(selectedPrompt)

    task.wait(selectedPrompt.HoldDuration)

    root.CFrame = prev
    hitbox.CFrame = prev
    activating = false
end
mapTab:CreateButton({
    Name = "Activate Selected Altar",
    Callback = function()
        activateAltar()
    end
})
mapTab:CreateButton({
    Name = "Teleport to Selected Altar",
    Callback = function()
        activateAltar(true)
    end
})
mapTab:CreateButton({
    Name = "Find Altars",
    Callback = function()
        updateAltarSelection()
    end
})

mapTab:CreateSection("Hazards")
local tpt = mapTab:CreateToggle({
    Name = "Tripmine Protection",
    CurrentValue = pt,
    Callback = function(Value)
        pt = Value
        if not Value then
            tripmineprots:ClearAllChildren()
        end
    end
})
local dfca
local nvi = mapTab:CreateToggle({
    Name = "Disable Void Implosions (LAGGY)",
    CurrentValue = dvi,
    Callback = function(Value)
        dvi = Value

        local vic = gcurses:FindFirstChild("VoidImplosions")

        if dfca then
            dfca:Disconnect()
            connections["dfca"] = nil
            dfca = nil
        end

        if dvi and vic then
            dfca = destroyFolder.ChildAdded:Connect(function(child)
                if child.Name == "VoidExplosion" then
                    child:Destroy()
                end
            end)
            connections["dfca"] = dfca
        end
    end
})
local nsm = mapTab:CreateToggle({
    Name = "Disable Seamines",
    CurrentValue = dsm,
    Callback = function(Value)
        dsm = Value

        if dsm and #pads:GetChildren() > 0 then
            local n = 0

            for _, sm in pads:GetChildren() do
                if sm.Name == "Seamine" then
                    local ti = sm:FindFirstChild("TouchInterest")
                    local ls = sm:FindFirstChild("ClientMine")

                    if ti then
                        ti:Destroy()
                        n += 1
                    end
                    if ls then
                        ls.Enabled = false
                    end
                end
            end

            if n > 0 then
                notif("Disabled "..n.." Seamine(s).", "Success")
            else
                notif("No Seamines found or all Seamines already disabled!.", "Erm")
            end
        end
    end
})
local nso = mapTab:CreateToggle({
    Name = "Disable Oblivion",
    CurrentValue = dso,
    Callback = function(Value)
        dso = Value

        if dso and enemies:FindFirstChild("Oblivion") then
            enemies.Oblivion:Destroy()
        end
    end
})

local dfb = mapTab:CreateToggle({
    Name = "Destroy Fake Beacons",
    CurrentValue = nfb,
    Callback = function(Value)
        nfb = Value

        if nfb and beacons:FindFirstChild("Beacon") then
            for _, b in beacons:GetChildren() do
                if b.Name == "Beacon" then
                    b:Destroy()
                end
            end
        end
    end
})

mapTab:CreateSection("Tiles")

local partsConnected = {}

mapTab:CreateParagraph({
    Title = "NOTE:",
    Content = "Button below creates tile connections, toggle auto remove ice/flesh tiles will not do anything unless you create tile connections first. Press it every time a new level is done generating. No need to press more times."
})
mapTab:CreateButton({
    Name = "Create Tile Connections (LAGS ON PRESS)",
    Callback = function()
        for p, c in pairs(partsConnected) do
            c:Disconnect()
            partsConnected[p] = nil
        end

        if #currentRooms:GetChildren() == 0 then
            notif("Level is not loaded in yet.", "Erm")
            return
        end

        for _, p in ipairs(currentRooms:GetDescendants()) do
            if p:IsA("BasePart") and partsConnected[p] == nil then
                local pmc = p:GetPropertyChangedSignal("Material"):Connect(function()
                    if (p.Material == Enum.Material.Ice and noice)
                    or(p.Material == Enum.Material.CorrodedMetal and noflesh) then
                        p.Material = Enum.Material.Air
                    end
                end)

                partsConnected[p] = pmc

                p.Destroying:Once(function()
                    pmc:Disconnect()
                    partsConnected[p] = nil
                end)

                if noice and p.Material == Enum.Material.Ice then
                    p.Material = Enum.Material.Air
                end
                if noflesh and p.Material == Enum.Material.CorrodedMetal then
                    p.Material = Enum.Material.Air
                end
            end
        end
    end
})

local ni = mapTab:CreateToggle({
    Name = "Auto Remove Ice Tiles",
    CurrentValue = noice,
    Callback = function(Value)
        noice = Value

        if partsConnected ~= nil and #partsConnected > 0 and noice then
            for p, _ in pairs(partsConnected) do
                if p.Material == Enum.Material.Ice then
                    p.Material = Enum.Material.Air
                end
            end
        end
    end
})
local nf = mapTab:CreateToggle({
    Name = "Auto Remove Flesh Tiles",
    CurrentValue = noflesh,
    Callback = function(Value)
        noflesh = Value
    end
})

---------------player
plrTab:CreateSection("Humanoid")
local ew = false
local ej = false
local ws = 16
local jp = 35
plrTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = ew,
    Callback = function(Value)
        ew = Value
        local h = getHuman(getChar(plr))
        if h then h.WalkSpeed = ws end
    end
})
plrTab:CreateToggle({
    Name = "Enable JumpPower",
    CurrentValue = ej,
    Callback = function(Value)
        ej = Value
        local h = getHuman(getChar(plr))
        if h then h.JumpPower = jp end
    end
})
plrTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {5, 200},
    Increment = 1,
    CurrentValue = ws,
    Callback = function(Value)
        ws = Value
        local h = getHuman(getChar(plr))
        if h then h.WalkSpeed = ws end
    end
})
plrTab:CreateSlider({
    Name = "JumpPower",
    Range = {25, 100},
    Increment = 1,
    CurrentValue = jp,
    Callback = function(Value)
        jp = Value
        local h = getHuman(getChar(plr))
        if h then h.JumpPower = jp end
    end
})
plrTab:CreateSection("Character")
local vh = plrTab:CreateToggle({
    Name = "Visible Hitbox",
    CurrentValue = visibleHitbox,
    Callback = function(Value)
        visibleHitbox = Value
        if not Value then
            local root, hitbox = getRoot(getChar(plr))
            if root and hitbox then
                hitbox.Transparency = 1
            end
        end
    end
})

local drb = plrTab:CreateToggle({
    Name = "Destroy Razorbloom (VISIBLE TO OTHERS)",
    CurrentValue = nrb,
    Callback = function(Value)
        nrb = Value
    end
})

---------------visual

visualTab:CreateSection("Better ESP Upgrades")
visualTab:CreateButton({
    Name = "Enable Better Gift ESP",
    Callback = function()
        giftEsp.Enabled = true
        giftEsp.FillColor = Color3.new(1,1,1)
        giftEsp.FillTransparency = 0.75
        giftEsp.OutlineTransparency = 0
    end
})
visualTab:CreateButton({
    Name = "Enable Better Tripmine ESP",
    Callback = function()
        tripEsp.Enabled = true
        tripEsp.FillTransparency = 0.75
        tripEsp.OutlineTransparency = 0
    end
})

visualTab:CreateSection("ESP")
local cge = visualTab:CreateToggle({
    Name = "Closest Gift Tracer ESP (LAGGY)",
    CurrentValue = cesp,
    Callback = function(Value)
        cesp = Value
        closestGiftTracer.Visible = cesp
    end
})
local me = visualTab:CreateToggle({
    Name = "Medal ESP",
    CurrentValue = mesp,
    Callback = function(Value)
        mesp = Value
        medalTracer.Visible = mesp
    end
})
local iet = visualTab:CreateToggle({
    Name = "Cadence Instrument ESP",
    CurrentValue = instrumentesp,
    Callback = function(Value)
        instrumentesp = Value
        if not Value then
            for obj, line in pairs(tracers) do
                line:Destroy()
                tracers[obj] = nil
            end
        end
    end
})

visualTab:CreateSection("Camera")
local fov = visualTab:CreateSlider({
    Name = "FOV",
    Range = {1, 120},
    Increment = 1,
    CurrentValue = Camera.FieldOfView,
    Callback = function(Value)
        workspace.CurrentCamera.FieldOfView = Value
    end
})

visualTab:CreateSection("Visualizer")
local tvelov = visualTab:CreateToggle({
    Name = "Velocity Visualizer",
    CurrentValue = velov,
    Callback = function(Value)
        velov = Value
    end
})

----------------key
keyTab:CreateKeybind({
    Name = "Collect Normal Gifts",
    CurrentKeybind = "Nine",
    HoldToInteract = false,
    Callback = function(key)
        if not canEzCollectNormal then return end
        collect("normal")
    end
})
keyTab:CreateKeybind({
    Name = "Collect Golden Gifts",
    CurrentKeybind = "Zero",
    HoldToInteract = false,
    Callback = function(key)
        if not canEzCollectGolden then return end
        collect("golden")
    end
})
keyTab:CreateKeybind({
    Name = "Get Medal",
    CurrentKeybind = "Eight",
    HoldToInteract = false,
    Callback = function(key)
        if not canEzCollectMedal then return end
        local medal = beacons:FindFirstChild("Medal")
        local root, hitbox = getRoot(getChar(plr))

        if medal and root and not isDead(plr) then
            local sp = root.Position
            root.Position = medal.Position
            task.wait(.2)
            root.Position = sp
        end
    end
})
keyTab:CreateKeybind({
    Name = "Disable All Enemies",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Callback = function(key)
        if not canEzDisableAll then return end
        selectedEnemies = updateEnemySelection()
        task.wait()
        disableSelected()
    end
})
keyTab:CreateKeybind({
    Name = "Disable All Client-sided Enemies Only",
    CurrentKeybind = "J",
    HoldToInteract = false,
    Callback = function(key)
        if not canEzDisableAllC then return end
        disableAll(false, true)
    end
})
local canPress = true
keyTab:CreateKeybind({
    Name = "Instantly Grapple to Nearest Jump Pad (Grappler Class Needed)",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Callback = function(key)
        if not canInstaGrapple then return end
        local sendingEvent = false

        if canPress then
            canPress = false
            local target = GetClosestPad()
            if not target then
                canPress = true
                return
            end
            local cf = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = cf
            sendingEvent = true
            task.spawn(function()
                while sendingEvent do
                    if not sendingEvent then break end
                    Camera.CFrame = cf
                    task.wait()
                end
            end)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.01)
            sendingEvent = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            task.delay(0.05, function()
                canPress = true
            end)
        end
    end
})
keyTab:CreateKeybind({
    Name = "Teleport to Spawn/Beacon",
    CurrentKeybind = "Home",
    HoldToInteract = false,
    Callback = function()
        if not canGoHome then return end
        local root, hitbox = getRoot(getChar(plr))
        local pos = spawnPart.Position + Vector3.new(0,4,0)
        root.Position = pos
        hitbox.Position = pos
    end
})
-- keyTab:CreateKeybind({
--     Name = "Toggle Collect Aura",
--     CurrentKeybind = "Insert",
--     HoldToInteract = false,
--     Callback = function()
--         if not canToggleAura then return end
--         if aura then
--             ga:Set(false)  
--             notif("Collect Aura Off.")
--         else
--             ga:Set(true)
--             notif("Collect Aura On.")
--         end
--     end
-- })

keyTab:CreateSection("Enable Keybinds")
keyTab:CreateToggle({
    Name = "Collect Normal Gifts Keybind",
    CurrentValue = canEzCollectNormal,
    Callback = function(Value)
        canEzCollectNormal = Value
    end
})
keyTab:CreateToggle({
    Name = "Collect Golden Gifts Keybind",
    CurrentValue = canEzCollectGolden,
    Callback = function(Value)
        canEzCollectGolden = Value
    end
})
keyTab:CreateToggle({
    Name = "Get Medal Keybind",
    CurrentValue = canEzCollectMedal,
    Callback = function(Value)
        canEzCollectMedal = Value
    end
})
keyTab:CreateToggle({
    Name = "Disable All Enemies Keybind",
    CurrentValue = canEzDisableAll,
    Callback = function(Value)
        canEzDisableAll = Value
    end
})
keyTab:CreateToggle({
    Name = "Disable All Client-sided Enemies Only Keybind",
    CurrentValue = canEzDisableAllC,
    Callback = function(Value)
        canEzDisableAllC = Value
    end
})
keyTab:CreateToggle({
    Name = "Instant Grapple Keybind",
    CurrentValue = canInstaGrapple,
    Callback = function(Value)
        canInstaGrapple = Value
    end
})
keyTab:CreateToggle({
    Name = "Teleport to Spawn/Beacon Keybind",
    CurrentValue = canGoHome,
    Callback = function(Value)
        canGoHome = Value
    end
})
-- keyTab:CreateToggle({
--     Name = "Toggle Collect Aura Keybind",
--     CurrentValue = canToggleAura,
--     Callback = function(Value)
--         canToggleAura = Value
--     end
-- })

--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-- debug
debugTab:CreateButton({
    Name = "Copy Lobby Code",
    Callback = function()
        if code.Value == nil or code.Value == " " or code.Value == "" then
            notif("You are in solo or code not found.", "Code")
            return
        end
        toClipboard(code.Value)
    end
})
local er = debugTab:CreateToggle({
    Name = "Enable Reset",
    CurrentValue = true,
    Callback = function(Value)
        StarterGui:SetCore("ResetButtonCallback", Value)
    end
})
StarterGui:SetCore("ResetButtonCallback", true)
debugTab:CreateButton({
    Name = "Rejoin (might not work)",
    Callback = function()
	    if #Players:GetPlayers() <= 1 then
	    	Players.LocalPlayer:Kick("\nRejoining...")
	    	wait()
	    	TeleportService:Teleport(PlaceId, plr)
	    else
	    	TeleportService:TeleportToPlaceInstance(PlaceId, JobId, plr)
	    end
    end
})
debugTab:CreateButton({
    Name = "Destroy GUI/Panic",
    Callback = function()
        destroyGui()
    end
})

---------connections!

for _, enemy in ipairs(enemies:GetChildren()) do
    task.spawn(handleEnemy, enemy, 5)
end
local skwca = workspace.Skinwalkers.ChildAdded:Connect(function(enemy)
    enemy.Name = "Skinwalker"

    handleEnemy(enemy)
end)
table.insert(connections, skwca)
local eca = enemies.ChildAdded:Connect(function(enemy)
    if enemy.Name == "Oblivion" and dso then
        enemy:Destroy()
    end

    updateEnemySelection()
    handleEnemy(enemy)
end)
table.insert(connections, eca)
local ecr = enemies.ChildRemoved:Connect(updateEnemySelection)
table.insert(connections, ecr)
local pca = pads.ChildAdded:Connect(function(child)
    if dsm then
        if child.Name == "Seamine" then
            task.wait(3)
            local ti = sm:FindFirstChild("TouchInterest")
            local ls = sm:FindFirstChild("ClientMine")

            if ti then
                ti:Destroy()
                n += 1
            end
            if ls then
                ls.Enabled = false
            end
        end
    end
end)
table.insert(connections, pca)

----loops!
local loopClosest
local giftSelection = {}

local lastAura = 0
local auraRATE = 1/45

local runLoop = RunService.Heartbeat:Connect(function()
    if (aura or tweening or cesp) and not isDead(plr) then
        refreshGifts()
    end

    local plrdead = isDead(plr)
    if plrdead then return end
    
    local char = getChar(plr)
    local root, hitbox = getRoot(char)
    local h = getHuman(char)
    Camera = Camera or workspace.CurrentCamera

--[[local auranow = tick()
    if aura and auranow - lastAura > auraRATE then
        lastAura = auranow

        if #availableNormalGifts == 0 then
            giftSelection = availableGoldenGifts
        elseif #availableGoldenGifts == 0 then
            giftSelection = availableNormalGifts
        end

        local newClose = getClosestGift(giftSelection)

        if newClose then
            local dist = (root.Position - newClose.Position).Magnitude

            if dist <= 7.5 then
                loopClosest = newClose
                collectGift:FireServer(loopClosest)
            end
        end
     end]]

    if visibleHitbox then
        if root and hitbox then
            hitbox.Transparency = 0
        end
    end

    if av then
        local pos = spawnPart.Position + Vector3.new(0,4,0)

        if root and root.Position.Y <= workspace.KillVoid.Position.Y + 75 then
            if antiVoidSelection == 1 then
                root.Position = pos
            elseif antiVoidSelection == 2 then
                local alv = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(alv.X,lp,alv.Z)
            elseif antiVoidSelection == 3 then
                local availableGifts = availableNormalGifts
                if #availableGifts == 0 then availableGifts = availableGoldenGifts end
                local gift = getClosestGift(availableGifts)
                if gift then
                    root.Position = gift.Position
                else
                    root.Position = pos
                    notif("No gift! Automatically doing Teleport to Spawn", "Anti Void")
                end
            end

            hitbox.Position = root.Position
        end
    end

    if root and hitbox then
        hitbox.Position = root.Position --teleporting hitbox and root together sometimes doesnt work
        if h and root.Position.Y <= workspace.KillVoid.Position.Y and h.Health > 0 then
            h:ChangeState(Enum.HumanoidStateType.Dead)
        end

        if velov then
            local velocity = root.AssemblyLinearVelocity * Vector3.new(1,0.5,1)
            local speed = velocity.Magnitude

            if speed > 0 then
               local direction = velocity.Unit

                local length = math.clamp(speed * 0.5, 0.5, 150)
                local t = math.clamp(speed / 75, 0, 1)

                local startPos = root.Position
                local endPos = startPos + direction * length
                local midPos = (startPos + endPos) / 2

                velocityPart.Size = Vector3.new(0.2, 0.2, length)
                velocityPart.CFrame = CFrame.lookAt(midPos, endPos)
                velocityPart.Color = Color3.new(1, 1 - t, 1 - t)
                velocityPart.Transparency = 0
                vpBox.Size = velocityPart.Size
                vpBox.Color3 = velocityPart.Color
                vpBox.Transparency = 0.25
            else
                velocityPart.Transparency = 1
                vpBox.Transparency = 1
            end
        end
    end

    if h then
        if not h:HasTag("loop") then
            h:AddTag("loop")
            local wsc = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                local cs = h.WalkSpeed
                if cs == ws or not ew then return end

                h.WalkSpeed = ws
            end)
            connections["walkloop"] = wsc
            local jpc = h:GetPropertyChangedSignal("JumpPower"):Connect(function()
                local cp = h.JumpPower
                if cp == jp or not ej then return end

                h.JumpPower = jp
            end)
            connections["jumploop"] = jpc
        end
    end

    if nrb then
        local rb = char:FindFirstChild("Razorbloom")
        if rb then
            rb:Destroy()
            notif("Razorbloom destroyed.", "Success")
        end
    end
    
    if nfb and beacons:FindFirstChild("Beacon") then
        for _, b in beacons:GetChildren() do
            if b.Name == "Beacon" then
                b:Destroy()
            end
        end
    end
end)

local lastUpdate = 0
local RATE = 1/30

RunService:BindToRenderStep("DRAWING", Enum.RenderPriority.Camera.Value + 1, function()
    local plrdead = isDead(plr)

    if plrdead then
        for obj, line in pairs(tracers) do
            line:Destroy()
            tracers[obj] = nil
        end
        return
    end

    local now = tick()
    if now - lastUpdate < RATE then return end
    lastUpdate = now
    Camera = Camera or workspace.CurrentCamera


    if instrumentesp then
        local camPos = Camera.ViewportSize

        if enemies:FindFirstChild("Cadence") then
            local cadence = enemies:FindFirstChild("Cadence")

            for i, co in cadence:GetChildren() do
                if co.Name == "ClonedOrb" then
                
                    if not co:FindFirstChild("BoxHandleAdornment") then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Size = co.Size
                        box.Adornee = co
                        box.AlwaysOnTop = true
                        box.ZIndex = 0
                        box.Color3 = Color3.new(0,0,1)
                        box.Transparency = 0.75
                        box.Parent = co
                    end

                    if not tracers[co] then
                        createTracer(co)
                    end

                    local screenPos, visible = Camera:WorldToViewportPoint(co.Position)

                    local tracer = tracers[co]
                    if tracer then
                        local viewport = Camera.ViewportSize
                        local from = Vector2.new(viewport.X / 2, viewport.Y / 2)

                        local to

                        if visible then
                            to = Vector2.new(screenPos.X, screenPos.Y)
                        else
                            local x = math.clamp(screenPos.X, 0, viewport.X)
                            local y = math.clamp(screenPos.Y, 0, viewport.Y)

                            to = Vector2.new(x, y)
                        end

                        tracer.Visible = true
                        tracer.From = from
                        tracer.To = to
                    end
                end
            end
        end
    else
        for obj, line in pairs(tracers) do
            line:Destroy()
            tracers[obj] = nil
        end
    end

    for obj, line in pairs(tracers) do
        if not obj or not obj:IsDescendantOf(workspace) or not obj.Parent then
            line:Destroy()
            tracers[obj] = nil
        end
    end

    if cesp then
        local gift = getClosestAnyGift()

        if gift then
            local screenPos, visible = Camera:WorldToViewportPoint(gift.Position)
            local viewport = Camera.ViewportSize

            local from = Vector2.new(viewport.X / 2, viewport.Y / 2)
            local to
            local camCF = Camera.CFrame
            local camPos = camCF.Position
            local camLook = camCF.LookVector
            local direction = (gift.Position - camPos).Unit
            local dot = camLook:Dot(direction)

            if not gift:FindFirstChild("BoxHandleAdornment") then
                local box = cgb or Instance.new("BoxHandleAdornment")
                cgb = box
                box.Size = gift.Size
                box.Adornee = gift
                box.AlwaysOnTop = true
                box.ZIndex = 0
                box.Color3 = Color3.new(1, 1, 0)
                box.Transparency = 0.5
                box.Parent = gift
            end

            if visible and dot > 0 then
                to = Vector2.new(screenPos.X, screenPos.Y)
            else
                local x = math.clamp(screenPos.X, 0, viewport.X)
                local y = math.clamp(screenPos.Y, 0, viewport.Y)

                if dot < 0 then
                    local center = Vector2.new(viewport.X/2, viewport.Y/2)
                    local dir = (Vector2.new(screenPos.X, screenPos.Y) - center).Unit
                    to = center + dir * math.max(viewport.X, viewport.Y)
                else
                    to = Vector2.new(x, y)
                end
            end

            closestGiftTracer.Visible = true
            closestGiftTracer.From = from
            closestGiftTracer.To = to
        else
            closestGiftTracer.Visible = false
            if cgb then
                cgb.Transparency = 1
            end
        end
    else
        closestGiftTracer.Visible = false
        if cgb then
            cgb.Transparency = 1
        end
    end

    if mesp then
        local medalUpgrade = upgrades:FindFirstChild("Medal")

        if medalUpgrade and medalUpgrade.Value == 1 then
            local medal = beacons:FindFirstChild("Medal")

            if medal then
                local screenPos, visible = Camera:WorldToViewportPoint(medal.Position)
                local viewport = Camera.ViewportSize

                local from = Vector2.new(viewport.X / 2, viewport.Y / 2)
                local to
                local camCF = Camera.CFrame
                local camPos = camCF.Position
                local camLook = camCF.LookVector
                local direction = (medal.Position - camPos).Unit
                local dot = camLook:Dot(direction)

                if not medal:FindFirstChild("BoxHandleAdornment") then
                    local box = mb or Instance.new("BoxHandleAdornment")
                    mb = box
                    box.Size = medal.Size
                    box.Adornee = medal
                    box.AlwaysOnTop = true
                    box.ZIndex = 0
                    box.Color3 = Color3.new(1, 1, 1)
                    box.Transparency = 0.75
                    box.Parent = medal
                end

                if visible and dot > 0 then
                    to = Vector2.new(screenPos.X, screenPos.Y)
                else
                    local x = math.clamp(screenPos.X, 0, viewport.X)
                    local y = math.clamp(screenPos.Y, 0, viewport.Y)

                    if dot < 0 then
                        local center = Vector2.new(viewport.X/2, viewport.Y/2)
                        local dir = (Vector2.new(screenPos.X, screenPos.Y) - center).Unit
                        to = center + dir * math.max(viewport.X, viewport.Y)
                    else
                        to = Vector2.new(x, y)
                    end
                end

                medalTracer.Visible = true
                medalTracer.From = from
                medalTracer.To = to
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

RunService:BindToRenderStep("Hazard", Enum.RenderPriority.Last.Value + 2, function()
    if isDead(plr) then return end

    local char = getChar(plr)
    local root = getRoot(char)
    if not char or not root then return end

    if pt then
        for _, trip in getActiveTripmines() do
            if trip.Transparency ~= 1 then
                protectTripmine(trip)

                local uuid = trip:GetAttribute("uuid")
                if uuid then
                    local p = tripmineprots:FindFirstChild(uuid)
                    if p then
                        p.Position = trip.Position
                    end
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
                    if p then
                        p.Position = b.Position
                    end
                end
            end
        end

        for _, p in bulletprots:GetChildren() do
            if p:IsA("BasePart") then
                local offset = root.Position - p.Position
                local dist = offset.Magnitude
                local radius = p.Size.X / 2
                local pushDir = offset.Unit

                if dist < radius and isdirectionsafetopushfromguardianbullet(root.Position, pushDir) then
                    root.CFrame += pushDir * 3
                elseif dist < radius then --do perpendicular
                    local altDir = Vector3.new(-pushDir.Z, 0, pushDir.X)

                    if isdirectionsafetopushfromguardianbullet(root.Position, altDir) then
                        root.CFrame += altDir * 3
                    else
                        root.Position = p.Position + Vector3.new(0, 10, 0) --fuck it
                    end
                end
            end
        end
    end
end)

---- destroy
function destroyGui()
    notif("Destroying...", "Nullscape GUI:")

    runLoop:Disconnect()
    print("run loop disconnected")

    RunService:UnbindFromRenderStep("DRAWING")
    print("drawing loop unbinded")

    RunService:UnbindFromRenderStep("Hazard")
    print("hazards unbinded")

    tripmineprots:Destroy()
    tpt:Set(false)
    print("tripmine protection off")

    bulletprots:Destroy()
    bpt:Set(false)
    print("bullet protection off")

    local tn = 0
    for obj, line in pairs(tracers) do
        line:Destroy()
        tracers[obj] = nil
        tn += 1
    end
    closestGiftTracer:Destroy(); tn += 1
    medalTracer:Destroy(); tn += 1
    if cgb then cgb:Destroy() end
    if mb then mb:Destroy() end
    print("Destroyed", tn, "tracer drawings and/or esp boxes")

    print("disconnecting "..#connections.." connections")
    for _, c in connections do
        c:Disconnect()
    end
    connections = nil

    print("disconnecting "..#partsConnected.." tile connections")
    for _, c in pairs(partsConnected) do
        c:Disconnect()
    end
    partsConnected = nil

    vh:Set(false)
    print("visible hitbox off")

    vv:Set(false)
    print("visible void off")

    iet:Set(false)
    print("instrument esp off")

    tvelov:Set(false)
    velocityPart:Destroy()
    print("velocity visualizer off and destroyed")

    avt:Set(false)
    print("anti void off")

    er:Set(false)
    print("reset off")

    ni:Set(false)
    print("no ice off")

    nf:Set(false)
    print("no flesh off")

    nvi:Set(false)
    print("void implosions back")

    nsm:Set(false)
    print("seamines back")

    tweening = false
    print("stopped tweening")

    print("destroying rayfield...")
    task.wait(.2)
    Rayfield:Destroy()
end

refreshGifts(true)

notif("Null GUI Executed", "Null GUI")
