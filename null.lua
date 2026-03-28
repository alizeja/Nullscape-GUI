if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
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
local av = false
local noice = false
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
local balancelevels = { --THESE ARE EXTREMELY BIASED OR INACCURATE, PLEASE BEAR WITH ME
    ["Further Skinwalker"] = 0.6,
    Idiotware = .9,
    ["Lower Gravity"] = 1,
    ["Stairs... Stairs..."] = 1.2,
    ["Savory Ring"] = 1.3,
    Camouflage = 1.4,
    ["Random Spawn"] = 1.5,
    ["Ice Tiles"] = 1.7,
    ["Tweaked Odds"] = 1.8,
    ["High Roller"] = 2.0,
    Minefield = 2.1,
    Barotrauma = 2.3,
    ["Scattered Gifts"] = 2.4,
    ["Fragile Gifts"] = 2.5,
    ["Weaker Jumppads"] = 2.6,
    ["Mart Infection"] = 2.7,
    ["Bigger Blast"] = 2.8,
    Shotgun = 2.9,
    ["Closer Skinwalker"] = 3,
    ["Taller Skinwalker"] = 3.1,
    ["Bloodier Meat"] = 3.2,
    ["Beacon Mirage"] = 3.3,
    Cheeseware = 3.4,
    ["Conga Line"] = 3.5,
    ["Missile Silo"] = 3.6,
    ["Mighty Chivalry"] = 3.7,
    ["Random Skinwalker"] = 3.8,
    ["More Tripmines"] = 3.9,
    ["Bigger Tripmines"] = 4,
    Springloaded = 4.2,
    ["Problem Child"] = 4.3,
    Delusion = 4.6,
    Pacifier = 4.8,
    ["Fake Count"] = 5,
    Crayonify = 5.1,
    ["More Ringing"] = 5.4,
    Telestabber = 5.6,
    ["Mart Slide"] = 5.8,
    ["[CONTENT REMOVED]"] = 6.2,
    ["[REDACTED]"]= 6.4,
    Tripnuke = 7,
    ["LAP 2"] = 7.2,
    ["Nothing?"] = 7.5
}
local greaterBalanceLevels = {
    ["Trap Card"] = 1.6,
    ["Void Implosions"] = 2.2,
    Run = 2.4,
    ["Hollow Tiles"] = 2.8,
    Doombringer = 3,
    ["One Less Choice"] = 3.1,
    ["Blade Bombardment"] = 3.6,
    ["Ballet of Blades"] = 3.8,
    Rebirth = 4,
    Muted = 4.2,
    Sorrow = 4.4,
    Tantrum = 5,
    ["Inverse Destruction"] = 5.3
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
local mapTab = Window:CreateTab("Map")
local plrTab = Window:CreateTab("Player")
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
    local selection = workspace:FindFirstChild("Select")
    if not selection then return end

    local intermission = selection.Sign.Billboard.TextLabel.Text

    local bestchoice
    local danger = math.huge

    for _, choice in selection:GetChildren() do
        if choice.Name == "Reroll" or choice.Name == "Sign" then continue end

        local prompt = choice:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then continue end

        local name = prompt.ActionText
        if not name then continue end

        if intermission == "ENEMIES" then
            local val = dangerlevels[name]
            print(val)
            print("is "..tostring(val).." less than "..danger.."?")
            if val and val < danger then
                print("yes")
                bestchoice = choice
                danger = val
            end
        elseif intermission == "CURSES" then
            local val = balancelevels[name]
            print(val)
            print("is "..tostring(val).." less than "..danger.."?")
            if val and val < danger then
                print("yes")
                bestchoice = choice
                danger = val
            end
        elseif intermission == "GREATER CURSES" then
            local val = greaterBalanceLevels[name]
            print(val)
            print("is "..tostring(val).." less than "..danger.."?")
            if val and val < danger then
                print("yes")
                bestchoice = choice
                danger = val
            end
        elseif intermission == "UPGRADES" then
            return "It is your choice."
        end
    end

    if bestchoice then
        return bestchoice.ProximityPrompt.ActionText
    end
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

local function disableEnemy(enemyName, willDestroy)
    local function loopEnemies(name, remove, list)
        list = list or enemies
        local n = 0

        for _, sameenemy in list:GetChildren() do
            if sameenemy.Name ~= name then continue end

            local part = sameenemy:FindFirstChild(remove, true)
            if part then
                part:Destroy()
                sameenemy:AddTag(".Disabled")
                n += 1
            else
                if not sameenemy:HasTag(".Disabled") then
                    sameenemy:AddTag(".Disabled")
                end
            end
        end

        return n
    end
    local function destroyEnemy(name, list)
        list = list or enemies

        for _,sameenemy in list:GetChildren() do
            if sameenemy.Name == name then
                sameenemy:Destroy()
            end
        end

        notif(name.." disabled. (destroyed)")
    end

    local disableFunction = {
        Basic = function(name, willDestroy)
            if willDestroy then
                destroyEnemy(name)
                return
            end
            local n = loopEnemies(name, "TouchInterest")

            if n > 0 then
                notif(tostring(n).." "..name.."(s) disabled.")
            else
                notif(name.." cannot be disabled, or already disabled.")
            end
        end,
        Skinwalker = function(name, willDestroy)
            local skinwalkers = workspace.Skinwalkers
            if #skinwalkers:GetChildren() == 0 then
                notif("Skinwalker isn't following you yet.")
                return
            end
            if willDestroy then
                destroyEnemy(name, skinwalkers)
                return
            end

            local n = loopEnemies("Skinwalker", "TouchInterest", skinwalkers)

            if n > 0 then
                notif(tostring(n).." Skinwalker(s) disabled.")
            else
                notif("Skinwalkers already disabled.")
            end
        end,
        Flesh = function(name, willDestroy)
            for _, b in fleshp:GetChildren() do
                b:Destroy()
            end
            if willDestroy then
                destroyEnemy(name)
                return
            end

            disableFunction.Basic("Flesh", "TouchInterest")
        end,
        Springer = function(name, willDestroy)
            if willDestroy then
                destroyEnemy(name)
                return
            end
            local n = loopEnemies("Springer", "SpringerShockwave")

            if n > 0 then
                notif(tostring(n).." Springer(s) shockwaves disabled. Cannot disable smashing.")
            else
                notif("No Springers left to be disabled.")
            end
        end,
        KooKoo = function(name, willDestroy)
           destroyEnemy(name)
        end,
        Dozer = function(name, willDestroy)
           destroyEnemy(name)
        end,
        Voidbreaker = function(name, willDestroy)
           destroyEnemy(name)
        end,
    }

    if disableFunction[enemyName] then
        disableFunction[enemyName](enemyName, willDestroy)
    else
        disableFunction.Basic(enemyName, willDestroy)
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
    CurrentValue = aura,
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

local function disableSelected(willDestroy: boolean)
    if selectedEnemies then
        for _, enemy in selectedEnemies do
            task.spawn(function()
                disableEnemy(enemy, willDestroy)
            end)
        end
    else
        notif("No Enemy Selected")
    end
end
local function disableAll(willDestroy: boolean)
    local allenemies = updateEnemySelection()
    if not allenemies or #allenemies == 0 then
        notif("No enemies available.")
        return
    end

    for _, enemy in allenemies do
        disableEnemy(enemy, willDestroy)
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
mainTab:CreateButton({
    Name = "Destroy Selected Enemies",
    Callback = function()
        disableSelected(true)
    end
})
mainTab:CreateButton({
    Name = "Destroy All",
    Callback = function()
        disableAll(true)
    end
})

mainTab:CreateSection("Intermission")

mainTab:CreateButton({
    Name = "Find Best Choice (BIAS)",
    Callback = function()
        notif(tostring(findBestSelection()), "Best Choice:")
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
    Suffix = "Power",
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
    selectedPrompt:InputHoldBegin()

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

mapTab:CreateSection("Tiles")
local ni = mapTab:CreateToggle({
    Name = "No Ice Tiles",
    CurrentValue = noice,
    Callback = function(Value)
        noice = Value
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
local infjumpdb = false
local infJump
plrTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        if not Value then
            if infJump then infJump:Disconnect() table.remove(connections, "inf") end
            infjumpdb = false
            return
        end

	    if infJump then infJump:Disconnect() table.remove(connections, "inf") end

	    infJump = UserInputService.JumpRequest:Connect(function()
	    	if not infjumpdb then
                local h = getHuman(getChar(plr))
	    		infjumpdb = true
	    		h:ChangeState(Enum.HumanoidStateType.Jumping)
	    		task.wait(.1)
	    		infjumpdb = false
	    	end
	    end)
        table.insert(connections, "inf", infJump)
    end
})
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
    CurrentValue = canEzCollectAll,
    Callback = function(Value)
        canEzCollectAll = Value
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
    Name = "Instant Grapple Keybind",
    CurrentValue = canInstaGrapple,
    Callback = function(Value)
        canInstaGrapple = Value
    end
})
keyTab:CreateToggle({
    Name = "Teleport to Spawn Keybind",
    CurrentValue = canGoHome,
    Callback = function(Value)
        canGoHome = Value
    end
})
keyTab:CreateToggle({
    Name = "Toggle Collect Aura Keybind",
    CurrentValue = canToggleAura,
    Callback = function(Value)
        canToggleAura = Value
    end
})

-------------------------- debug
local er = debugTab:CreateToggle({
    Name = "Enable Reset",
    CurrentValue = false,
    Callback = function(Value)
        StarterGui:SetCore("ResetButtonCallback", Value)
    end
})
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

    if noice then
        if #currentRooms:GetChildren() ~= 0 then
            for _, part in currentRooms:GetDescendants() do
                if part:IsA("BasePart") and part.Material == Enum.Material.Ice then
                    part.Material = Enum.Material.Air
                end
            end
        end
    end

    if av then
        local root:BasePart, hitbox = getRoot(getChar(plr))

        if root and root.Position.Y <= -550 then
            if antiVoidSelection == 1 then
                local pos = spawnPart.Position + Vector3.new(0,4,0)
                root.Position = pos
            elseif antiVoidSelection == 2 then
                local alv = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(alv.X,lp,alv.Z)
            elseif antiVoidSelection == 3 then
                local gifts = availableNormalGifts
                if #gifts == 0 then gifts = availableGoldenGifts end
                local gift = getClosestGift(gifts)

                if gift then
                    root.Position = gift.Position
                else
                    antiVoidSelection = 1
                    avs:Set({"1. Teleport to Spawn"})
                    notif("No gift! Automatically doing Teleport to Spawn", "Anti Void")
                end
            end

            hitbox.Position = root.Position
        end
    end
    local root, hitbox = getRoot(getChar(plr))
    local h = getHuman(getChar(plr))
    if root and hitbox then
        hitbox.Position = root.Position --teleporting hitbox and root together sometimes doesnt work
        if root.Position.Y <= -610.5 and h.Health > 0 then
            getChar(plr):BreakJoints()
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
            connections["walkloop"] = jpc
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
    print("disconnecting "..#connections.." connections")
    for _, c in connections do
        c:Disconnect()
    end
    vh:Set(false)
    print("visible hitbox off")
    vv:Set(false)
    print("visible void off")
    avt:Set(false)
    print("anti void off")
    er:Set(false)
    print("reset off")
    ni:Set(false)
    print("no ice off")
    print("destroying rayfield...")
    task.wait(.2)
    Rayfield:Destroy()
end