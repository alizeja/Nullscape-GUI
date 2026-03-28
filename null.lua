if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local plr = Players.LocalPlayer

local events = ReplicatedStorage.Events

local Camera = workspace.CurrentCamera
local spawnPart = workspace.Spawn
local items = workspace.ItemPools
local gifts = items.NormalGifts
local goldengifts = items.GoldenGifts
local tripmines = items.Tripmines
local fleshp = items.FleshProjectile
local enemies = workspace.Enemies
local giftEsp = workspace.Showlocation
local tripEsp = workspace.ShowlocationTrip
local selection = workspace:FindFirstChild("Select")
local collectGift: RemoteEvent = events.GiftCollected
local currentRooms = workspace.CurrentRooms
local pads = workspace.JumpPads

local tweening = false
local aura = false
local visibleHitbox = false
local canInstaGrapple = false
local canToggleAura = true
local canEzCollectAll = true
local canGoHome = true
local canEzDisableAll = true
local giftConnections = {}
local connections = {}

local dangerlevels = {
    Bell = 0.5,
    Mart = 0.75,
    Springer = 1.2,
    Dozer = 1.4,
    ICBM = 1.7,
    Nil = 1.9,
    Flesh = 2,
    Guardian = 2.1,
    Kookoo = 2.4,
    Skinwalker = 2.6,
    ["Voidbound Guardian"] = 2.9,
    Baby = 3,
    Telefragger = 3.3,
    ["Voidbound Baby"] = 3.5,
    Voidbreaker = 3.6,
    Cadence = 5
}
local balancelevels = {
    ["Lower Gravity"] = 0.1,
    ["Stairs... Stairs..."] = 0.4,
    ["Savory Ring"] = 0.5,
    ["Random Spawn"] = 0.8,
    ["Ice Tiles"] = 1.3,
    ["Fragile Gifts"] = 1.5,
    ["Weaker Jumppads"] = 1.6,
    ["Tweaked Odds"] = 2,
    ["High Roller"] = 2.3,
    Minefield = 2.4,
    Barotrauma = 2.6,
    ["Scattered Gifts"] = 2.7,
    ["Beacon Mirage"] = 2.9,
    ["More Tripmines"] = 3.1,
    ["Bigger Tripmines"] = 3.3,
    Tripnuke = 3.5,
    ["LAP 2"] = 3.6,
    Delusion = 3.8,
    Crayonify = 4,
    ["Fake Count"] = 4.3,
    ["Nothing?"] = 4.5
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Nullscape GUI",
   LoadingTitle = "Loading Nullscape GUI",
   LoadingSubtitle = "by John Nullscape (Ali)",
   ShowText = "Null!",

   ToggleUIKeybind = "K"
})

local function notif(text: string, title: string, dur: number)
    Rayfield:Notify({
        Title = title or "Notification",
        Content = text or "Forgot to add text idiot",
        Duration = dur or 5
    })
end

local mainTab = Window:CreateTab("Main")
local visualTab = Window:CreateTab("Visual")
local keyTab = Window:CreateTab("Keybinds")
local debugTab = Window:CreateTab("Debug")

local function getChar(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function getHuman(char)
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char, humanoid)
    if not humanoid then humanoid = getHuman(char) end
    return char:FindFirstChild("HumanoidRootPart") or (humanoid and humanoid.RootPart), char:FindFirstChild("Hitbox")
end

local availableNormalGifts = {}
local availableGoldenGifts = {}
local function getAvailableGifts()
    local function trackGift(gift, giftTable)
        if gift.Transparency ~= 1 then
            table.insert(giftTable, gift)
        end
        local gtc = gift:GetPropertyChangedSignal("Transparency"):Connect(function()
            if gift.Transparency == 1 then
                for i, g in ipairs(giftTable) do
                    if g == gift then
                        table.remove(giftTable, i)
                        break
                    end
                end
            elseif gift.Transparency == 0 then
                table.insert(giftTable, gift)
            end
        end)
        table.insert(giftConnections, gtc)
    end

    for _, gift in gifts:GetChildren() do
        trackGift(gift, availableNormalGifts)
    end

    for _, gift in goldengifts:GetChildren() do
        trackGift(gift, availableGoldenGifts)
    end
end
getAvailableGifts()

local function getActiveTripmines()
    local active = {}
    for _, mine in tripmines:GetChildren() do
        if mine.Transparency ~= 1 then
            table.insert(active, mine)
        end
    end
    return active
end

local function getActiveEnemies()
    local active = {}
    for _, enemy in enemies:GetChildren() do
        table.insert(active, enemy)
    end
    return active
end

local function pathBlocked(targetPos, activeTripmines, activeEnemies)
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return true end

    local rootPos = root.Position
    local fakeSize = Vector3.new(1,3,1)
    
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

local function getClosestGift(gifts)
    local char = getChar(plr)
    local root = getRoot(char)
    if not root then return end

    local giftsList = gifts
    local closest = nil
    local shortest = math.huge

    for _, gift in ipairs(giftsList) do
        if gift and gift.Parent then
            local pos = gift.Position
            local dist = (pos - root.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = gift
            end
        end
    end

    return closest, shortest
end

local function goTo(part, activeTripmines, activeEnemies)
    if not part then return end
    local char = getChar(plr)
    local root, hitbox = getRoot(char)
    if not root or not hitbox then return end

    local pos = part:IsA("Model") and part:GetPivot().Position or part.Position
    if part.Name == "Spawn" then pos += Vector3.new(0,4,0) end
    local dist = (pos - root.Position).Magnitude
    if dist == 0 then return end

    local direction = (pos - root.Position).Unit
    root.CFrame = CFrame.new(root.Position, root.Position + direction) * CFrame.Angles(0, math.rad(90), 0)

    local blocked = pathBlocked(pos, activeTripmines, activeEnemies)
    if blocked and (part.Name == "Gift" or part.Name == "GoldGift") then
        root.Position = pos
        hitbox.Position = pos
        task.wait(.1)
        collectGift:FireServer(part)
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
    tween.Completed:Connect(function()
        hitbox.Position = root.Position
    end)

    return tween
end

local function findBestSelection()
    selection = workspace:FindFirstChild("Select")
    if not selection then return end
    local intermission = selection.Sign.Billboard.TextLabel.Text

    local bestchoice
    local danger = 10
    local worst = 0

    for i, choice in selection:getChildren() do
        if choice.Name == "Reroll" or choice.Name == "Sign" then continue end
        local name = choice.ProximityPrompt.ActionText

        if intermission == "ENEMIES" then
            if not dangerlevels[name] then continue end
            if dangerlevels[name] < danger then
                bestchoice = choice
                danger = dangerlevels[name]
            end
        elseif intermission == "CURSES" then
            if not balancelevels[name] then continue end
            if balancelevels[name] < danger then
                bestchoice = choice
                danger = balancelevels[name]
            end
        end
    end

    return bestchoice.ProximityPrompt.ActionText
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

local function disableEnemy(enemyName)
    local function loopEnemies(name, remove, list)
        list = list or enemies
        local n = 0

        for _, sameenemy in list:GetChildren() do
            if sameenemy.Name ~= name then continue end

            local part = sameenemy:FindFirstChild(remove, true)
            if part then
                part:Destroy()
                n += 1
            end
        end

        return n
    end

    local disableFunction = {
        Basic = function(name)
            local n = loopEnemies(name, "TouchInterest")

            if n > 0 then
                notif(tostring(n).." "..name.."(s) disabled.")
            else
                notif(name.." cannot be disabled, or already disabled.")
            end
        end,

        Skinwalker = function()
            local skinwalkers = workspace.Skinwalkers
            if #skinwalkers:GetChildren() == 0 then
                notif("Skinwalker isn't following you yet.")
                return
            end

            local n = loopEnemies("Skinwalker", "TouchInterest", skinwalkers)

            if n > 0 then
                notif(tostring(n).." Skinwalker(s) disabled.")
            else
                notif("Skinwalkers already disabled.")
            end
        end,

        Flesh = function()
            for _, b in fleshp:GetChildren() do
                b:Destroy()
            end

            disableFunction.Basic("Flesh", "TouchInterest")
        end,

        Springer = function()
            local n = loopEnemies("Springer", "SpringerShockwave")

            if n > 0 then
                notif(tostring(n).." Springer(s) shockwaves disabled. Cannot disable smashing.")
            else
                notif("No Springers left to be disabled.")
            end
        end
    }

    if disableFunction[enemyName] then
        disableFunction[enemyName](enemyName)
    else
        disableFunction.Basic(enemyName)
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
            print("it's visible. dist:",mag)
            dist = mag
            closest = part
        end
    end

    return closest
end

---------------------collection
local function collect(which)
    local activeTripmines = getActiveTripmines()
    local activeEnemies = getActiveEnemies()

    local function collectGolden()
        if tweening then notif("Already collecting.") return end
        tweening = true

        while true do
            local root = getRoot(getChar(plr))
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end

            local gift = getClosestGift(availableGoldenGifts, activeTripmines, activeEnemies)
            if not gift then break end

            local tween = goTo(gift, activeTripmines, activeEnemies)
            if tween then tween.Completed:Wait() end

            task.wait(.02)
        end
        goTo(spawnPart, activeTripmines, activeEnemies)
        tweening = false
    end

    local function collectNormal(getGoldenAfter)
        if tweening then notif("Already collecting.") return end
        tweening = true
        while true do
            local root = getRoot(getChar(plr))
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end

            local gift = getClosestGift(availableNormalGifts, activeTripmines, activeEnemies)
            if not gift then break end

            local tween = goTo(gift, activeTripmines, activeEnemies)
            if tween then tween.Completed:Wait() end

            task.wait(.02)
        end
        tweening = false
        if getGoldenAfter then task.wait(1) collectGolden() end
    end

    if which == "normal" then
        collectNormal()
    elseif which == "golden" then
        collectGolden()
    elseif which == "all" then
        collectNormal(true)
    end
end

---------button
mainTab:CreateSection("Gifts")
mainTab:CreateButton({
    Name = "Collect ALL Gifts",
    Callback = function()
        collect("all")
    end
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
local ga = mainTab:CreateToggle({
    Name = "Collect Aura",
    CurrentValue = false,
    Callback = function(Value)
        aura = Value
    end
})

mainTab:CreateSection("Enemies")
local selectedEnemies = {}

local selectEnemies = mainTab:CreateDropdown({
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

    local activeEnemies = getActiveEnemies()
    if not activeEnemies or #activeEnemies == 0 then
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

local function disableSelected()
    if selectedEnemies then
        for _, enemy in selectedEnemies do
            task.spawn(function()
                disableEnemy(enemy)
            end)
        end
    else
        notif("No Enemy Selected")
    end
end
local function disableAll()
    local allenemies = updateEnemySelection()
    if not allenemies or #allenemies == 0 then
        notif("No enemies available.")
        return
    end

    for _, enemy in allenemies do
        disableEnemy(enemy)
    end
end

mainTab:CreateButton({
    Name = "Disable Selected Enemies",
    Callback = function()
        disableSelected()
    end
})
mainTab:CreateButton({
    Name = "Disable All",
    Callback = function()
        disableAll()
    end
})

mainTab:CreateSection("Altars")
local altarVal = {}
local selectedAltar
local selectedPrompt
local activating = false

local selectAltars = mainTab:CreateDropdown({
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

local function activateAltar()
    if activating then return end
    activating = true

    if not selectedPrompt or not selectedPrompt.Parent then
        notif("Altar no longer exists.")
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
    root.CFrame = pos
    hitbox.CFrame = pos

    repeat task.wait()
    until (root.Position - pPart.Position).Magnitude < 6

    fireproximityprompt(selectedPrompt)

    task.wait(0.1)

    root.CFrame = prev
    hitbox.CFrame = prev
    activating = false
end
mainTab:CreateButton({
    Name = "Activate Selected Altar",
    Callback = function()
        activateAltar()
    end
})

mainTab:CreateSection("Intermission")

mainTab:CreateButton({
    Name = "Find Best Choice (BIAS)",
    Callback = function()
        notif(tostring(findBestSelection()), "Best Choice:")
    end
})

---------------visual

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
visualTab:CreateDivider()
local vh = visualTab:CreateToggle({
    Name = "Visible Hitbox",
    CurrentValue = false,
    Callback = function(Value)
        visibleHitbox = Value
    end
})
visualTab:CreateButton({
    Name = "Visible Void",
    Callback = function()
        workspace.KillVoid.Transparency = 0
    end
})

----------------key

keyTab:CreateKeybind({
    Name = "Collect All Gifts",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Callback = function(key)
        if not canEzCollectAll then return end
        collect("all")
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
local canPress = true
keyTab:CreateKeybind({
    Name = "Instantly Grapple to Nearest Jump Pad (Grappler Class Needed)",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Callback = function(key)
        if not canInstaGrapple then return end
        local sendingEvent = false

        if canPress then
            print("can press, now disabling...")
            canPress = false
            local target = GetClosestPad()
            if not target then
                print("no target")
                canPress = true
                return
            end
            local cf = CFrame.new(Camera.CFrame.Position, target.Position)
            print("setting camera cframe:", cf)
            Camera.CFrame = cf
            print("sending key event")
            sendingEvent = true
            task.spawn(function()
                while sendingEvent do
                    if not sendingEvent then break end
                    Camera.CFrame = cf
                    task.wait()
                end
            end)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            print("unsending key event")
            task.wait(0.01)
            sendingEvent = false
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            print("enable pressing")
            task.delay(0.05, function()
                canPress = true
            end)
        end
    end
})
keyTab:CreateKeybind({
    Name = "Teleport to Spawn",
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
keyTab:CreateKeybind({
    Name = "Toggle Collect Aura",
    CurrentKeybind = "Insert",
    HoldToInteract = false,
    Callback = function()
        if not canToggleAura then return end
        if aura then
            ga:Set(false)  
            notif("Collect Aura Off.")
        else
            ga:Set(true)
            notif("Collect Aura On.")
        end
    end
})

keyTab:CreateSection("Enable Keybinds")
keyTab:CreateToggle({
    Name = "Collect All Gifts Keybind",
    CurrentValue = true,
    Callback = function(Value)
        canEzCollectAll = Value
    end
})
keyTab:CreateToggle({
    Name = "Disable All Enemies Keybind",
    CurrentValue = true,
    Callback = function(Value)
        canEzDisableAll = Value
    end
})
keyTab:CreateToggle({
    Name = "Instant Grapple Keybind",
    CurrentValue = false,
    Callback = function(Value)
        canInstaGrapple = Value
    end
})
keyTab:CreateToggle({
    Name = "Teleport to Spawn Keybind",
    CurrentValue = true,
    Callback = function(Value)
        canGoHome = Value
    end
})
keyTab:CreateToggle({
    Name = "Toggle Collect Aura Keybind",
    CurrentValue = true,
    Callback = function(Value)
        canToggleAura = Value
    end
})

--------------------------
debugTab:CreateButton({
    Name = "Destroy GUI/Panic",
    Callback = function()
        destroyGui()
    end
})

---------connections!

local eca = enemies.ChildAdded:Connect(updateEnemySelection)
table.insert(connections, eca)
local ecr = enemies.ChildRemoved:Connect(updateEnemySelection)
table.insert(connections, ecr)
local crca = currentRooms.ChildAdded:Connect(updateAltarSelection)
table.insert(connections, crca)
local crcr = currentRooms.ChildRemoved:Connect(updateAltarSelection)
table.insert(connections, crcr)

----loops!
local loopClosest
local giftSelection = {}

local runLoop = RunService.Heartbeat:Connect(function()
    if aura then
        if #availableNormalGifts == 0 then
            giftSelection = availableGoldenGifts
        elseif #availableGoldenGifts == 0 then
            giftSelection = availableNormalGifts
        end

        local newClose = getClosestGift(giftSelection)

        if newClose then
            loopClosest = newClose
            collectGift:FireServer(loopClosest)
        end
    end

    if visibleHitbox then
        local root, hitbox = getRoot(getChar(plr))
        if root and hitbox then
            hitbox.Transparency = 0
        end
    end
end)

---- destroy
function destroyGui()
    notif("Destroying...", "Nullscape GUI:")
    runLoop:Disconnect()
    print("run loop disconnected")
    task.spawn(function()
        local n = #giftConnections
        for i = 1, n do
            giftConnections[i]:Disconnect()
            giftConnections[i] = nil
            if i % 500 == 0 then
                print(i.." gift connections disconnected...")
            end
        end

        print(n.." gift connections disconnected! (background)")
    end)
    for _, c in connections do
        c:Disconnect()
    end
    vh:Set(false)
    print("visible hitbox off")
    print("destroying rayfield...")
    task.wait(.2)
    Rayfield:Destroy()
end