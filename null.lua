if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local plrgui = plr.PlayerGui

local events = ReplicatedStorage.Events

local spawnPart = workspace.Spawn
local items = workspace.ItemPools
local gifts = items.NormalGifts
local goldengifts = items.GoldenGifts
local tripmines = items.Tripmines
local skullp = items.SkullProjectile
local vskullp = items.Skull2Projectile
local fleshp = items.FleshProjectile
local enemies = workspace.Enemies
local giftEsp = workspace.Showlocation
local tripEsp = workspace.ShowlocationTrip
local giftsLabel = plrgui.GUI.Gifts
local selection = workspace:FindFirstChild("Select")
local collectGift: RemoteEvent = events.GiftCollected
local currentRooms = workspace.CurrentRooms


local tweening = false

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

local function getAvailableGifts()
    local availableNormalGifts = {}
    local availableGoldenGifts = {}

    local function trackGift(gift, giftTable)
        if gift.Transparency ~= 1 then
            table.insert(giftTable, gift)

            gift:GetPropertyChangedSignal("Transparency"):Connect(function()
                if gift.Transparency == 1 then
                    for i, g in ipairs(giftTable) do
                        if g == gift then
                            table.remove(giftTable, i)
                            break
                        end
                    end
                end
            end)
        end
    end

    for _, gift in ipairs(gifts:GetChildren()) do
        trackGift(gift, availableNormalGifts)
    end

    for _, gift in ipairs(goldengifts:GetChildren()) do
        trackGift(gift, availableGoldenGifts)
    end

    return availableNormalGifts, availableGoldenGifts
end

local function getActiveTripmines()
    local active = {}
    for _, mine in ipairs(tripmines:GetChildren()) do
        if mine.Transparency ~= 1 then
            table.insert(active, mine)
        end
    end
    return active
end

local function getActiveEnemies()
    local active = {}
    for _, enemy in ipairs(enemies:GetChildren()) do
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

    for _, mine in ipairs(activeTripmines) do
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
    for _, enemy in ipairs(activeEnemies) do
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

local function getClosestGift(gifts, activeTripmines, activeEnemies)
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

    return closest
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

local function disableEnemy(enemyName, touchPart)
    local enemy = enemies[enemyName]
    if not enemy then notif("No enemy with name:", enemyName) return end
    
    disableFunction = {
        Basic = function()
            local n = 0
            for _, sameenemy in enemies:GetChildren() do
                if sameenemy.Name  ~= enemyName or sameenemy:HasTag(".Disabled") then continue end
                local touch = sameenemy:FindFirstChild("TouchInterest", true)
                if touch then
                    touch:Destroy()
                    sameenemy:AddTag(".Disabled")
                    n += 1
                else
                    notif(enemyName.." currently cannot be disabled or still loading.")
                    continue
                end
            end
            if n > 0 then
                notif(tostring(n).." "..enemyName.."(s) disabled.")
            end
        end,
        Skinwalker = function()
            local skinwalkers = workspace.Skinwalkers
            local isFollowing = false
            if #skinwalkers:GetChildren() == 0 then
                notif("Skinwalker isn't following you yet.")
                return
            end

            for i, skinwalker in skinwalkers:GetChildren() do
                if enemy:HasTag(".Disabled") then isFollowing = true return end

                local root = getRoot(skinwalker)
                local touch = root and root:FindFirstChildOfClass("TouchTransmitter")
                if touch then
                    touch:Destroy()
                end
                isFollowing = true
            end

            if isFollowing then
                enemy:AddTag(".Disabled")
                notif("Skinwalker disabled.")
            end
        end,
        Flesh = function()
            for _, b in fleshp:GetChildren() do
                b:Destroy()
            end
            disableFunction.Basic()
        end,
        Guardian = function()
            for _, b in skullp:GetChildren() do
                b:Destroy()
            end
        end,
        ShadowGuardian = function()
            for _, b in vskullp:GetChildren() do
                b:Destroy()
            end
        end,
        Springer = function()
            if enemy:HasTag(".Disabled") then return end
            local shockwave = enemy:FindFirstChild("SpringerShockwave")
            if shockwave then
                shockwave:Destroy()
                notif("Springer shockwave disabled. Smashing cannot be disabled.")
            end
        end
    }

    if disableFunction[enemyName] then
        disableFunction[enemyName]()
    else
        disableFunction.Basic()
    end
end

---------------------collection
local function collect(which)
    local activeTripmines = getActiveTripmines()
    local activeEnemies = getActiveEnemies()

    local function collectGolden()
        if tweening then notif("Already collecting.") return end
        tweening = true

        local _, goldenGifts = getAvailableGifts()
        while true do
            local root = getRoot(getChar(plr))
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end

            local gift = getClosestGift(goldenGifts, activeTripmines, activeEnemies)
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
        local activeGifts,_ = getAvailableGifts()
        while true do
            local root = getRoot(getChar(plr))
            if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end

            local gift = getClosestGift(activeGifts, activeTripmines, activeEnemies)
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
    if not activeEnemies or #activeEnemies == 0 then return end

    for _, enemy in ipairs(activeEnemies) do
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
            disableEnemy(enemy)
        end
    else
        notif("No Enemy Selected")
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
        selectedEnemies = updateEnemySelection()
        task.wait()
        disableSelected()
    end
})

mainTab:CreateSection("Altars")
local altarVal = {}
local selectedAltar
local selectedPrompt: ProximityPrompt
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
    local options = {}
    for _, p in ipairs(getAltarPrompts()) do
        local text = p.Text
        altarVal[text] = p.Prompt
        table.insert(options, text)
    end

    selectAltars:Refresh(options)
end
updateAltarSelection()

local function activateAltar()
    if selectedAltar and selectedPrompt then
        local pPart:BasePart = selectedPrompt.Parent
        if not pPart then notif("Selected Altar does not have a prompt. (Activated already?)") return end
        local pos = pPart.CFrame + Vector3.new(0,0,3)
        local root = getRoot(getChar(plr))
        if root then
            local prev = root.CFrame
            task.wait()
            root.CFrame = pos
            task.wait(.1)
            selectedPrompt:InputHoldBegin()
            task.wait(selectedPrompt.HoldDuration)
            selectedPrompt.InputHoldEnd()
            root.CFrame = prev
        end
    else
        notif("No Altar Selected")
    end
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
visualTab:CreateButton({
    Name = "Visible Hitbox",
    Callback = function()
        local root, hitbox = getRoot(getChar(plr))
        if hitbox then
            hitbox.Transparency = 0
        else
            notif("You have no hitbox. (Dead?)")
        end
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
        collect("all")
    end
})
keyTab:CreateKeybind({
    Name = "Disable All Enemies",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Callback = function(key)
        selectedEnemies = updateEnemySelection()
        task.wait()
        disableSelected()
    end
})
keyTab:CreateKeybind({
    Name = "Teleport to Spawn",
    CurrentKeybind = "Home",
    HoldToInteract = false,
    Callback = function()
        local root, hitbox = getRoot(getChar(plr))
        pos = spawnPart.Position + Vector3.new(0,4,0)
        root.Position = pos
        hitbox.Position = pos
    end
})

---------connections!

enemies.ChildAdded:Connect(updateEnemySelection)
enemies.ChildRemoved:Connect(updateEnemySelection)
currentRooms.ChildAdded:Connect(updateAltarSelection)
currentRooms.ChildRemoved:Connect(updateAltarSelection)