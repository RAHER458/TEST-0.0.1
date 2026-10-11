--[[
    RH-HUB v0.0.4-alpha (Steal an Egg)
    Сборка: UI от ChatGPT + Ядро KerryHub
    Executor: Delta (iOS)
    Файл: esp.lua
    Репозиторий: RAHER458/TEST-0.0.1
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Remote-переменные
local RF = ReplicatedStorage:WaitForChild("Remotes", 10) or ReplicatedStorage
local RE = ReplicatedStorage:WaitForChild("RemoteEvents", 10) or ReplicatedStorage

local K = RF:WaitForChild("EggWorld"):WaitForChild("AskPlaceEgg")
local c = RF:WaitForChild("EggWorld"):WaitForChild("AskLiveSnapshot")
local v = RF:WaitForChild("Homestead"):WaitForChild("AskState")
local i = RF:WaitForChild("EggWorld"):WaitForChild("AskFieldEggCarry")
local R = RF:WaitForChild("EggWorld"):WaitForChild("AskFieldEggSnapshot")
local g = RF:WaitForChild("EggWorld"):WaitForChild("AskHatch")
local Q = RF:WaitForChild("EggWorld"):WaitForChild("AskFinishHatch")
local P = RE:WaitForChild("GuardPatrol"):WaitForChild("ForestStrike")
local N = RE:WaitForChild("GuardPatrol"):WaitForChild("SpeedTollOffer")
local U = RF:WaitForChild("Treadmill"):WaitForChild("AskDoff")
local l = RF:WaitForChild("Treadmill"):WaitForChild("AskDon")
local D = RF:WaitForChild("Treadmill"):WaitForChild("AskTierRaise")
local C = RF:WaitForChild("Trailwear"):WaitForChild("AskPurchase")
local q = RF:WaitForChild("Trailwear"):WaitForChild("AskChoose")
local n = RF:WaitForChild("Trailwear"):WaitForChild("AskDoff")

-- Константы
local f = { ["Light Dark"]=1300, ["Titan Temple"]=1100, ["Cherry Blossom"]=1000, ["Cosmic"]=900, ["Prehistoric"]=800, ["Abyss Ocean"]=700, ["Volcano"]=600, ["Snow"]=500, ["Jungle"]=400, ["Desert"]=300, ["Lake"]=200, ["Forest"]=100 }
local M = { "Light Dark", "Titan Temple", "Cherry Blossom", "Cosmic", "Prehistoric", "Abyss Ocean", "Volcano", "Snow", "Jungle", "Desert", "Lake", "Forest" }
local I = { ["Light Dark"]=420, ["Titan Temple"]=380, ["Cherry Blossom"]=330, ["Cosmic"]=280, ["Prehistoric"]=240, ["Abyss Ocean"]=200, ["Volcano"]=180, ["Snow"]=160, ["Jungle"]=140, ["Desert"]=130, ["Lake"]=125, ["Forest"]=125 }

local L = -360
local E = 525
local b = 620
local A = 130
local S = CFrame.new(4773.76, 70.39, -315.74)

-- Таблица состояния
local h = {
    farmMode = "NONE",
    selectedZones = {},
    selectedRarities = {},
    currentTarget = nil,
    currentEgg = nil,
    savedWalkSpeed = 16,
    savedJumpPower = 50,
    savedJumpHeight = 7.2,
    savedHipHeight = 2,
    godmodeActive = false,
    logs = {},
    stopRequested = false,
    isFarming = false,
}

-- Утилиты
function h.Log(msg)
    local entry = string.format("[%s] %s", os.date("%H:%M:%S"), tostring(msg))
    table.insert(h.logs, entry)
    if #h.logs > 200 then table.remove(h.logs, 1) end
    print(entry)
end

function h.GetDiagnosticLogs() return h.logs end
function h.ClearLogs() h.logs = {} end

function h.IsAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

function h.GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function h.GetRoot()
    local char = LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

function h.TweenTo(targetCFrame, duration)
    local root = h.GetRoot()
    if not root then return false end
    TweenService:Create(root, TweenInfo.new(duration or 1, Enum.EasingStyle.Linear), { CFrame = targetCFrame }):Play()
    return true
end

function h.FullRestore()
    local hum = h.GetHumanoid()
    if hum then
        hum.WalkSpeed = h.savedWalkSpeed or 16
        hum.JumpPower = h.savedJumpPower or 50
        hum.JumpHeight = h.savedJumpHeight or 7.2
        hum.HipHeight = h.savedHipHeight or 2
    end
    h.godmodeActive = false
    h.isFarming = false
    h.Log("FULL_RESTORE: состояния восстановлены")
end

-- Заглушки Farm
Farm = Farm or {}
function Farm.SetFarmMode(mode)
    h.farmMode = mode
    h.Log("Farm mode -> " .. tostring(mode))
    if mode == "NONE" then
        h.stopRequested = true
        h.FullRestore()
    else
        h.stopRequested = false
        h.isFarming = true
    end
end
function Farm.GetFarmMode() return h.farmMode end
function Farm.SetZones(zones) h.selectedZones = zones or {}; h.Log("Zones: " .. tostring(#h.selectedZones)) end
function Farm.SetRarities(rarities) h.selectedRarities = rarities or {}; h.Log("Rarities: " .. tostring(#h.selectedRarities)) end
function Farm.StopAll() Farm.SetFarmMode("NONE"); h.Log("STOP ALL") end

-- ==========================================================
-- ЧАСТЬ 2: ЯДРО ФАРМА (KerryHub, очищенное)
-- ==========================================================

-- Заглушки для логов ядра (в оригинале H и t)
local function H(...) h.Log(table.concat({...}, " ")) end
local function t(...) h.Log("[ERR] " .. table.concat({...}, " ")) end

-- Проверка: является ли Tool яйцом
local function m(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = string.lower(tool.Name)
    if string.find(name, "sword") or string.find(name, "radar") or string.find(name, "basket") or string.find(name, "punch") then return false end
    if tool:GetAttribute("EggUid") or tool:GetAttribute("UID") or string.find(name, "egg") or tool:GetAttribute("Category") or tool:GetAttribute("ItemType") == "Egg" then return true end
    return false
end

-- e4: получить яйцо в руках
local function e4()
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if m(tool) then
                local uid = tool:GetAttribute("UID") or tool:GetAttribute("EggUid")
                return tool, uid or tool.Name
            end
        end
    end
    return nil, nil
end

-- r4: получить яйцо в backpack
local function r4()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if m(tool) then
                local uid = tool:GetAttribute("UID") or tool:GetAttribute("EggUid")
                return tool, uid or tool.Name
            end
        end
    end
    return nil, nil
end

-- y4: подсчёт яиц
local function y4()
    local count = 0
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if m(tool) then count = count + 1 end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if m(tool) then count = count + 1 end
        end
    end
    return count
end

-- u4: сбросить все инструменты в backpack
local function u4(force)
    if not force and not (h.farmMode == "TWEEN" or h.farmMode == "WARP") then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if hum then pcall(function() hum:UnequipTools() end) end
    if char and bp then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then pcall(function() tool.Parent = bp end) end
        end
    end
end

-- w4: проверка "яйцо у меня"
local function w4(uid)
    if (h.farmMode == "TWEEN" or h.farmMode == "WARP") and not h.holdingEggForGuard then
        local tool = e4()
        if tool then pcall(u4) end
        return false
    end
    local tool, toolUid = e4()
    if tool then
        if uid then
            if toolUid == uid or not toolUid then return true end
        else
            return true
        end
    end
    return false
end

-- j4: проверка "яйцо в backpack"
local function j4(uid)
    local tool, toolUid = e4()
    if tool then
        if not uid or toolUid == uid or not toolUid then return true end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if m(tool) then
                local u = tool:GetAttribute("UID") or tool:GetAttribute("EggUid")
                if not uid or u == uid or tool.Name == tostring(uid) then return true end
            end
        end
    end
    return false
end

-- k4: проверка доступности яйца (CarriedBySelf / CarriedByOther)
local function k4(uid)
    if not uid then return false, "NoUid" end
    -- Упрощённая версия: проверяем через e4/r4
    if w4(uid) then return true, "CarriedBySelf" end
    if j4(uid) then return true, "CarriedBySelf" end
    return true, "Unchecked"
end

-- d4: fire proximity prompts
local function d4(model, position)
    if model then
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function()
                    d.RequiresLineOfSight = false
                    d.HoldDuration = 0
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(d, 0)
                        fireproximityprompt(d)
                    end
                end)
            end
        end
    end
    local slots = Workspace:FindFirstChild("AreaEggSlotsClient")
    if slots and position then
        for _, slot in ipairs(slots:GetChildren()) do
            local part = slot:FindFirstChildWhichIsA("BasePart") or slot.PrimaryPart
            if part and ((part.Position - position)).Magnitude <= 18 then
                for _, d in ipairs(slot:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        pcall(function()
                            d.RequiresLineOfSight = false
                            d.HoldDuration = 0
                            if typeof(fireproximityprompt) == "function" then
                                fireproximityprompt(d, 0)
                                fireproximityprompt(d)
                            end
                        end)
                    end
                end
            end
        end
    end
end

-- S4: rigid joints (anti-ragdoll база)
local function S4(char)
    char = char or LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or root
    if not torso then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") or d:IsA("NoCollisionConstraint") then
            pcall(function() d:Destroy() end)
        end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Motor6D") and d.Part0 and d.Part1 then
            d.Enabled = true
            local weldName = "RigidJointWeld_" .. d.Name
            if not d.Part1:FindFirstChild(weldName) then
                local weld = Instance.new("WeldConstraint")
                weld.Name = weldName
                weld.Part0 = d.Part0
                weld.Part1 = d.Part1
                weld.Parent = d.Part1
            end
        end
    end
end

-- Z4: anti-ragdoll + отключение состояний
local function Z4(char)
    if h.onTreadmill then return end
    char = char or LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit then hum.Sit = false end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("LocalScript") and (string.find(string.lower(d.Name), "ragdoll") or string.find(string.lower(d.Name), "fall")) then
            d.Disabled = true
        end
    end
    S4(char)
end

-- z4: постоянный anti-ragdoll
local function z4(char)
    if not char then return end
    Z4(char)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Motor6D") then
            d:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not d.Enabled then d.Enabled = true end
            end)
        end
    end
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") or d:IsA("NoCollisionConstraint") then
            task.defer(function() pcall(function() d:Destroy() end); Z4(char) end)
        elseif d:IsA("LocalScript") and (string.find(string.lower(d.Name), "ragdoll") or string.find(string.lower(d.Name), "fall")) then
            d.Disabled = true
        end
    end)
end

-- A4: swap humanoid (desync godmode)
local function A4()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return false end
    pcall(function()
        hum.BreakJointsOnDeath = false
        local clone = hum:Clone()
        clone.Parent = char
        hum:Destroy()
        if not clone:FindFirstChildOfClass("Animator") then
            local anim = Instance.new("Animator")
            anim.Parent = clone
        end
        Camera.CameraSubject = clone
        local animate = char:FindFirstChild("Animate")
        if animate and animate:IsA("LocalScript") then
            animate.Disabled = true
            task.defer(function() task.wait(0.05); animate.Disabled = false end)
        end
        clone:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        clone:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        clone:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        clone:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        clone.JumpPower = math.max(50, clone.JumpPower)
        clone.JumpHeight = math.max(7.2, clone.JumpHeight)
        clone:ChangeState(Enum.HumanoidStateType.Running)
    end)
    h.swapped = true
    if h.godmode then b4(true) end
    z4(char)
    return true
end

-- b4: desync godmode
local function b4(state)
    h.godmode = state
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not state)
        if state and hum.Health < 100 then hum.Health = 100 end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and state then
            d.CanTouch = false
            d.CanCollide = false
        end
    end
    Z4(char)
end

-- D4: сброс состояний
local function D4()
    h.onTreadmill = false
    h.teleporting = false
    h.glidingToTarget = false
    h.securingEgg = false
    h.isReturning = false
    h.delivering = false
    h.holdingEggForGuard = false
    h.currentTargetModel = nil
    h.targetPosition = nil
    h.stateTime = os.clock()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function()
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    pcall(function() if Z4 and char then Z4(char) end end)
    pcall(function() if u4 then u4() end end)
end

-- N4: выбор цели
local function N4()
    local function formatMoney(n)
        n = tonumber(n) or 0
        if n >= 1e12 then return string.format("%.1fT", n/1e12) end
        if n >= 1e9 then return string.format("%.1fB", n/1e9) end
        if n >= 1e6 then return string.format("%.1fM", n/1e6) end
        if n >= 1e3 then return string.format("%.1fK", n/1e3) end
        return string.format("%.0f", n)
    end

    local function getAreaFromX(x)
        x = tonumber(x) or 0
        if x >= 5200 then return "Light Dark"
        elseif x >= 4750 then return "Titan Temple"
        elseif x >= 4000 then return "Cherry Blossom"
        elseif x >= 3350 then return "Cosmic"
        elseif x >= 2780 then return "Prehistoric"
        elseif x >= 2250 then return "Abyss Ocean"
        elseif x >= 1850 then return "Volcano"
        elseif x >= 1450 then return "Snow"
        elseif x >= 1150 then return "Jungle"
        elseif x >= 920 then return "Desert"
        elseif x >= 720 then return "Lake"
        else return "Forest" end
    end

    local function getRarityTier(rarity)
        rarity = string.lower(tostring(rarity or ""))
        if string.find(rarity, "divine") then return 6, "Divine" end
        if string.find(rarity, "eternal") then return 5, "Eternal" end
        if string.find(rarity, "secret") then return 4, "Secret" end
        if string.find(rarity, "cosmic") then return 3, "Cosmic" end
        if string.find(rarity, "mythic") then return 2, "Mythic" end
        if string.find(rarity, "legendary") then return 1, "Legendary" end
        if string.find(rarity, "epic") then return 0.5, "Epic" end
        if string.find(rarity, "rare") then return 0.3, "Rare" end
        if string.find(rarity, "uncommon") then return 0.1, "Uncommon" end
        return 0, "Common"
    end

    -- Упрощённая версия: сканируем AreaEggSlotsClient
    local root = h.GetRoot()
    if not root then return nil end
    local myPos = root.Position
    local slots = Workspace:FindFirstChild("AreaEggSlotsClient")
    if not slots then return nil end

    local candidates = {}
    for _, slot in ipairs(slots:GetChildren()) do
        local part = slot:FindFirstChildWhichIsA("BasePart") or slot.PrimaryPart
        if part then
            local pos = part.Position
            if pos.X >= 530 then
                local area = getAreaFromX(pos.X)
                local rarity = slot:GetAttribute("Rarity") or slot:GetAttribute("RarityTier") or "Common"
                local tier, rarityName = getRarityTier(rarity)
                local isSelectedZone = h.selectedZones and h.selectedZones[area] == true
                local isSelectedRarity = h.selectedRarities and h.selectedRarities[rarityName] == true
                local isSecretPlus = tier >= 4
                if isSecretPlus or (isSelectedZone and isSelectedRarity) then
                    table.insert(candidates, {
                        Uid = slot.Name,
                        Area = area,
                        Rarity = rarityName,
                        RarityTier = tier,
                        CFrame = part.CFrame,
                        Position = pos,
                        Distance = (myPos - pos).Magnitude,
                        Model = slot,
                    })
                end
            end
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b)
        if a.RarityTier ~= b.RarityTier then return a.RarityTier > b.RarityTier end
        if a.Distance ~= b.Distance then return a.Distance < b.Distance end
        return a.Area > b.Area
    end)
    return candidates[1]
end

-- wk: полёт к цели (Tween)
local function wk(targetCFrame, speed, uid, session)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if hum then hum.AutoRotate = false end
    speed = math.max(60, speed or h.glideSpeed or 350)
    local targetPos = targetCFrame.Position
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    h.glidingToTarget = true
    h.stateTime = os.clock()
    local timeout = os.clock() + 15
    while h.alive and h.glidingToTarget and os.clock() < timeout do
        if session and session ~= h.sessionId then
            if hum then hum.AutoRotate = true end
            h.glidingToTarget = false
            return false
        end
        if h.farmMode ~= "TWEEN" and h.farmMode ~= "WARP" then
            if hum then hum.AutoRotate = true end
            h.glidingToTarget = false
            return false
        end
        local pos = root.Position
        local dist = (targetPos - pos).Magnitude
        if dist <= 6 then break end
        local dt = RunService.Heartbeat:Wait()
        pos = root.Position
        local dir = (targetPos - pos)
        if dir.Magnitude > 0.05 then
            local step = dir.Unit * math.min(dir.Magnitude, speed * dt)
            local newPos = pos + step
            root.CFrame = CFrame.lookAt(newPos, newPos + dir.Unit)
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        h.statusText = string.format("Gliding -> Egg (%.0f studs)", dist)
    end
    root.CFrame = targetCFrame * CFrame.new(0, 0.4, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if hum then hum.AutoRotate = true end
    h.glidingToTarget = false
    return true
end

-- R4: полёт к цели с выходом из базы
local function R4(targetCFrame, speed, uid, session)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local myX = root.Position.X
        local targetX = targetCFrame.Position.X
        if myX <= 535 and targetX > 510 then
            local waypoint = CFrame.new(500, 70, -364)
            if (root.Position - waypoint.Position).Magnitude > 5 then
                h.statusText = "[AutoSteal] Exiting Base -> Waypoint..."
                if not wk(waypoint, speed, uid, session) then return false end
                task.wait(0.04)
            end
        end
    end
    return wk(targetCFrame, speed, uid, session)
end

-- Q4: возврат на Safe Line X=525
local function Q4(speed, session)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if hum then hum.AutoRotate = false end
    local laneZ = h.laneZ or L
    local targetPos = Vector3.new(E - 10, 70, laneZ)
    speed = math.max(100, speed or h.glideSpeed or 350)
    h.isReturning = true
    h.stateTime = os.clock()
    pcall(u4)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    local timeout = os.clock() + 15
    while h.alive and h.isReturning and os.clock() < timeout do
        if session and session ~= h.sessionId then
            if hum then hum.AutoRotate = true end
            h.isReturning = false
            return false
        end
        if h.farmMode ~= "TWEEN" and h.farmMode ~= "WARP" then
            if hum then hum.AutoRotate = true end
            h.isReturning = false
            return false
        end
        local pos = root.Position
        local dist = (targetPos - pos).Magnitude
        if pos.X <= E + 10 or dist <= 6 then
            u4()
            break
        end
        local dt = RunService.Heartbeat:Wait()
        pos = root.Position
        local dir = targetPos - pos
        if dir.Magnitude > 0.05 then
            local step = dir.Unit * math.min(dir.Magnitude, speed * dt)
            local newPos = pos + step
            root.CFrame = CFrame.lookAt(newPos, newPos + dir.Unit)
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        h.statusText = string.format("Tweening to Safe Line (%.0f studs)", dist)
    end
    root.CFrame = CFrame.new(E, math.max(68, root.Position.Y), laneZ)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if hum then hum.AutoRotate = true end
    u4()
    h.isReturning = false
    h.delivering = false
    h.statusText = "Arrived at Safe Line (X=525)!"
    return true
end

-- g4: возврат домой (Tween по корридору)
local function g4(speed, session, skipCheck)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if hum then hum.AutoRotate = false end
    local targetPos = Vector3.new(464.7, 71.7, -304)
    speed = math.max(100, speed or h.glideSpeed or 600)
    h.isReturning = true
    h.stateTime = os.clock()
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    local timeout = os.clock() + 25
    while h.alive and h.isReturning and os.clock() < timeout do
        if session and session ~= h.sessionId then
            if hum then hum.AutoRotate = true end
            h.isReturning = false
            return false
        end
        if not skipCheck and h.farmMode ~= "TWEEN" and h.farmMode ~= "WARP" then
            if hum then hum.AutoRotate = true end
            h.isReturning = false
            return false
        end
        local pos = root.Position
        local dist = (targetPos - pos).Magnitude
        if dist <= 6 then break end
        local dt = RunService.Heartbeat:Wait()
        pos = root.Position
        local dir = targetPos - pos
        if dir.Magnitude > 0.05 then
            local step = dir.Unit * math.min(dir.Magnitude, speed * dt)
            local newPos = pos + step
            root.CFrame = CFrame.lookAt(newPos, newPos + dir.Unit)
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        h.statusText = string.format("Tweening Home (%.0f studs)", dist)
    end
    root.CFrame = CFrame.new(targetPos)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if hum then hum.AutoRotate = true end
    u4()
    h.isReturning = false
    h.delivering = false
    h.statusText = "Arrived at Base PetArea!"
    return true
end

-- U4: Guard Strike (3 фазы) — КЛЮЧЕВАЯ ФУНКЦИЯ
local function U4(uid, cframe, model, session)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return false end
    h.securingEgg = true
    h.isReturning = false
    h.stateTime = os.clock()
    h.holdingEggForGuard = true
    local targetPos = cframe.Position
    h.currentTargetModel = model
    h.targetPosition = targetPos
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    Z4(char)
    pcall(function() LocalPlayer:RequestStreamAroundAsync(targetPos) end)

    if not model then
        local slots = Workspace:FindFirstChild("AreaEggSlotsClient")
        if slots then
            for _, slot in ipairs(slots:GetChildren()) do
                local part = slot:FindFirstChildWhichIsA("BasePart") or slot.PrimaryPart
                if part and (part.Position - targetPos).Magnitude <= 16 then
                    model = slot
                    h.currentTargetModel = slot
                    break
                end
            end
        end
    end

    -- ФАЗА 1: поднять яйцо
    h.statusText = "[1/4] Lifting Egg to Trigger Guard..."
    H("[GuardStrike] Step 1: Lifting target egg (" .. tostring(uid) .. ")...")
    local timeout1 = os.clock() + 3.5
    local lastCheck = 0
    while not w4() and os.clock() < timeout1 and h.alive and h.securingEgg do
        if session and session ~= h.sessionId then break end
        if h.farmMode ~= "TWEEN" and h.farmMode ~= "WARP" then break end
        char:PivotTo(cframe * CFrame.new(0, 0.4, 0))
        d4(model, targetPos)
        if uid and i then
            task.spawn(function()
                pcall(function()
                    if i:IsA("RemoteFunction") then
                        i:InvokeServer({Uid = uid})
                        i:InvokeServer(uid)  -- ДВОЙНОЙ ВЫЗОВ!
                    end
                end)
            end)
        end
        RunService.Heartbeat:Wait()
    end
    if not w4() then
        t("[GuardStrike] Initial egg pickup timed out")
        if uid then h.cooldown[uid] = os.clock() + 2 end
        h.currentTargetModel = nil
        h.targetPosition = nil
        h.securingEgg = false
        h.holdingEggForGuard = false
        return false
    end

    -- ФАЗА 2: Guard Strike
    h.statusText = "[2/4] Waiting for Guard Strike..."
    H("[GuardStrike] Step 2: Egg lifted! Triggering guard strike...")
    local timeout2 = os.clock() + 4.5
    local struck = false
    while w4() and os.clock() < timeout2 and h.alive and h.securingEgg do
        if session and session ~= h.sessionId then break end
        if h.farmMode ~= "TWEEN" and h.farmMode ~= "WARP" then break end
        char:PivotTo(cframe * CFrame.new(0, 0.4, 0))
        if P and not struck then
            task.spawn(function()
                pcall(function()
                    if P:IsA("RemoteFunction") then
                        P:InvokeServer()
                    else
                        P:FireServer()
                    end
                end)
            end)
            struck = true
        end
        RunService.Heartbeat:Wait()
    end

    -- ФАЗА 3: перезахват
    h.statusText = "[3/4] Re-grabbing Egg..."
    H("[GuardStrike] Step 3: Guard struck! Re-grabbing egg...")
    local timeout3 = os.clock() + 3
    while not w4() and os.clock() < timeout3 and h.alive and h.securingEgg do
        if session and session ~= h.sessionId then break end
        if h.farmMode ~= "TWEEN" and h.farmMode ~= "WARP" then break end
        char:PivotTo(cframe * CFrame.new(0, 0.4, 0))
        d4(model, targetPos)
        if uid and i then
            task.spawn(function()
                pcall(function()
                    if i:IsA("RemoteFunction") then
                        i:InvokeServer({Uid = uid})
                        i:InvokeServer(uid)
                    end
                end)
            end)
        end
        RunService.Heartbeat:Wait()
    end
    local ok = j4(uid)
    if not ok then
        task.wait(0.12)
        ok = j4(uid)
    end
    h.currentTargetModel = nil
    h.targetPosition = nil
    h.securingEgg = false
    h.holdingEggForGuard = false
    if session and session ~= h.sessionId then return false end
    if ok then
        pcall(u4)
        H("[GuardStrike] Egg successfully secured!")
        h.statusText = "Egg Secured! Tweening along Z=-360..."
    else
        t("[-] Failed to re-grab egg after guard strike")
        h.statusText = "[-] Failed to re-grab egg"
        if uid then h.cooldown[uid] = os.clock() + 2 end
    end
    return ok
end

-- T4: переключение режима
local function T4(mode)
    if h.farmMode == mode then return end
    h.sessionId = (h.sessionId or 0) + 1
    local session = h.sessionId
    h.farmMode = "SWITCHING"
    pcall(D4)
    pcall(u4)
    task.delay(0.06, function()
        if h.sessionId == session then
            h.farmMode = mode
            if mode == "TWEEN" then
                h.Log("[FarmController] TWEEN mode ACTIVATED")
            elseif mode == "WARP" then
                h.Log("[FarmController] WARP mode ACTIVATED")
            else
                h.Log("[FarmController] All farms DEACTIVATED")
            end
        end
    end)
end

-- ==========================================================
-- ЧАСТЬ 3: ГЛАВНЫЕ ЦИКЛЫ И ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (единый блок)
-- ==========================================================

-- Дополняем таблицу h полями (если их нет)
h.sessionId = h.sessionId or 0
h.cooldown = h.cooldown or {}
h.statusText = h.statusText or "Ready"
h.laneZ = h.laneZ or L
h.autoGlide = h.autoGlide ~= false
h.autoHatch = h.autoHatch ~= false
h.autoTreadmill = h.autoTreadmill ~= false
h.autoUpgradeTreadmill = h.autoUpgradeTreadmill ~= false
h.autoBuyTrails = h.autoBuyTrails ~= false
h.autoPlaceEvery5 = h.autoPlaceEvery5 == true
h.batchStealCount = h.batchStealCount or 0
h.isBatchPlacing = h.isBatchPlacing or false
h.isHatching = h.isHatching or false
h.swapped = h.swapped or false
h.hatched = h.hatched or 0
h.glideSpeed = h.glideSpeed or 600
h.onTreadmill = h.onTreadmill or false
h.lastTreadmillMount = h.lastTreadmillMount or 0
h.plot = h.plot or nil
h.pen = h.pen or nil
h.origin = h.origin or nil
h.tread = h.tread or nil
h.alive = h.alive ~= false
h.plotVerified = h.plotVerified or false
h.holdingEggForGuard = h.holdingEggForGuard or false
h.teleporting = h.teleporting or false
h.glidingToTarget = h.glidingToTarget or false
h.securingEgg = h.securingEgg or false
h.isReturning = h.isReturning or false
h.delivering = h.delivering or false
h.currentTargetModel = h.currentTargetModel or nil
h.targetPosition = h.targetPosition or nil
h.stateTime = h.stateTime or os.clock()
h.autoFarmLoop = h.autoFarmLoop or false
h.pureTweenFarm = h.pureTweenFarm or false
h.godmode = h.godmode ~= false

-- ==========================================================
-- i4: hitbox-обнаружение (для облёта ловушек)
-- ==========================================================
local function i4()
    local hitboxes = {}
    local debris = Workspace:FindFirstChild("__DEBRIS")
    if debris then
        for _, d in ipairs(debris:GetChildren()) do
            local hb = d:FindFirstChild("Hitbox")
            if hb and hb:IsA("BasePart") then
                table.insert(hitboxes, hb)
            elseif d:IsA("BasePart") and string.find(string.lower(d.Name), "hitbox") then
                table.insert(hitboxes, d)
            end
        end
    end
    local boss = Workspace:FindFirstChild("BossArenaTeleport")
    if boss then
        local b = boss:FindFirstChild("Hitbox") or boss:FindFirstChildWhichIsA("BasePart") or (boss:IsA("BasePart") and boss)
        if b and b:IsA("BasePart") then
            table.insert(hitboxes, b)
        end
    end
    return hitboxes
end

-- ==========================================================
-- t4, s4, p4: работа с plot'ом
-- ==========================================================
local function t4()
    if h.plot and h.plot.Parent and h.pen and h.origin and h.plotVerified then
        return h.plot, h.pen, h.origin
    end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil, nil, nil end

    local userId = LocalPlayer.UserId
    local userName = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local plot = nil
    local verified = false

    if v then
        local ok, data = pcall(function() return v:InvokeServer() end)
        if ok and type(data) == "table" and type(data.OwnersBySlot) == "table" then
            for slot, owner in pairs(data.OwnersBySlot) do
                if owner == userId or tostring(owner) == tostring(userId) or owner == userName then
                    plot = plots:FindFirstChild(tostring(slot))
                    if plot then verified = true; break end
                end
            end
        end
    end

    if not plot and c then
        local ok, data = pcall(function() return c:InvokeServer() end)
        if ok and type(data) == "table" then
            for slot, info in pairs(data) do
                if type(info) == "table" and (info.OwnerUserId == userId or tostring(info.OwnerUserId) == tostring(userId)) then
                    local s = info.Slot or slot
                    plot = plots:FindFirstChild(tostring(s)) or plots:FindFirstChild(tostring(slot))
                    if plot then verified = true; break end
                end
            end
        end
    end

    if not plot then
        for _, p in ipairs(plots:GetChildren()) do
            local owner = p:GetAttribute("Owner") or p:GetAttribute("OwnerUserId") or p:GetAttribute("UserId") or p:GetAttribute("OwnerId") or p:GetAttribute("Player")
            if owner and (owner == userId or tostring(owner) == tostring(userId) or owner == userName or tostring(owner) == userName or owner == displayName) then
                plot = p; verified = true; break
            end
            for _, attrName in ipairs({"Owner", "OwnerUserId", "OwnerId", "UserId", "Player", "PlayerName"}) do
                local attr = p:FindFirstChild(attrName)
                if attr and (attr.Value == userId or tostring(attr.Value) == tostring(userId) or attr.Value == userName or attr.Value == displayName) then
                    plot = p; verified = true; break
                end
            end
            if plot then break end
        end
    end

    if not plot then
        local root = h.GetRoot()
        if root and root.Position.X <= E + 30 then
            local nearest, nearestDist = nil, 999999
            for _, p in ipairs(plots:GetChildren()) do
                local center = p:FindFirstChild("CenterPoint") or p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
                if center then
                    local d = (root.Position - center.Position).Magnitude
                    if d < nearestDist then nearestDist = d; nearest = p end
                end
            end
            if nearest and nearestDist < 160 then plot = nearest end
        end
    end

    if not plot then
        plot = plots:FindFirstChild("2") or plots:FindFirstChild("1") or (plots:GetChildren())[1]
    end
    if not plot then return nil, nil, nil end

    h.plot = plot
    h.plotVerified = verified
    h.origin = plot:FindFirstChild("CenterPoint")
    local toUpdate = plot:FindFirstChild("ToUpdate")
    h.pen = (toUpdate and toUpdate:FindFirstChild("PetArea")) or plot:FindFirstChild("PetArea")
    h.tread = plot:FindFirstChild("TreadmillBottom")

    if not h.pen and toUpdate then
        for _, d in ipairs(toUpdate:GetChildren()) do
            if d:IsA("BasePart") and string.find(string.lower(d.Name), "pet") then
                h.pen = d; break
            end
        end
    end
    if not h.origin then h.origin = plot:FindFirstChild("CenterPoint") or h.pen or plot.PrimaryPart end
    if not h.pen then h.pen = h.origin end
    return h.plot, h.pen, h.origin
end

local function s4()
    local _, pen, origin = t4()
    if pen then return pen.Position + Vector3.new(0, 3.5, 0) end
    if origin then return origin.Position + Vector3.new(0, 3.5, 0) end
    return Vector3.new(464.7, 71.7, -304)
end

local function p4(existingPositions)
    local _, pen = t4()
    if not pen then return nil end
    local size = pen.Size
    local rangeX = math.max(4, size.X / 2 - 5)
    local rangeZ = math.max(4, size.Z / 2 - 5)
    for _ = 1, 60 do
        local ox = math.random(-math.floor(rangeX), math.floor(rangeX))
        local oz = math.random(-math.floor(rangeZ), math.floor(rangeZ))
        local pos = pen.CFrame * CFrame.new(ox, size.Y / 2 + 1, oz)
        local free = true
        for _, p in ipairs(existingPositions or {}) do
            if (p - pos.Position).Magnitude < 5.5 then free = false; break end
        end
        if free then return pos end
    end
    return pen.CFrame * CFrame.new(math.random(-8, 8), size.Y / 2 + 1, math.random(-8, 8))
end

-- ==========================================================
-- B4: размещение яиц в PetArea
-- ==========================================================
local function B4()
    local _, _, origin = t4()
    if not origin or not K then return 0 end
    local placed = 0
    local placedPositions = {}

    if c then
        local ok, data = pcall(function() return c:InvokeServer() end)
        if ok and type(data) == "table" then
            local myRecords = {}
            for _, info in pairs(data) do
                if type(info) == "table" and info.OwnerUserId == LocalPlayer.UserId then
                    for k, rec in pairs(info.Records or {}) do myRecords[k] = rec end
                end
            end
            for uid, rec in pairs(myRecords) do
                if rec.Placement and rec.Placement.LocalCFrame then
                    table.insert(placedPositions, (origin.CFrame * rec.Placement.LocalCFrame).Position)
                else
                    local pos = p4(placedPositions)
                    if pos then
                        local localCF = origin.CFrame:ToObjectSpace(pos)
                        local ok2 = pcall(function() return K:InvokeServer({Uid = uid, LocalCFrame = localCF}) end)
                        if ok2 then
                            placed = placed + 1
                            table.insert(placedPositions, pos.Position)
                        end
                    end
                end
            end
        end
    end

    local tools = {}
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if m(tool) then table.insert(tools, tool) end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if m(tool) then table.insert(tools, tool) end
        end
    end

    for _, tool in ipairs(tools) do
        if not h.alive then break end
        local uid = tool:GetAttribute("UID") or tool:GetAttribute("EggUid") or tool.Name
        local pos = p4(placedPositions)
        if pos then
            local localCF = origin.CFrame:ToObjectSpace(pos)
            local ok = pcall(function() return K:InvokeServer({Uid = uid, LocalCFrame = localCF}) end)
            if ok then
                placed = placed + 1
                table.insert(placedPositions, pos.Position)
                H(string.format("[PlaceEgg] Placed %s", tostring(uid)))
            end
            task.wait(0.04)
        end
    end
    return placed
end

-- ==========================================================
-- J4: авто-вылупление
-- ==========================================================
local function J4(force)
    if (not force and not h.autoHatch) or not g or not Q or not c then return 0 end
    if h.isHatching then return 0 end
    h.isHatching = true

    local ok, data = pcall(function() return c:InvokeServer() end)
    if not ok or type(data) ~= "table" then h.isHatching = false; return 0 end

    local myRecords = {}
    for _, info in pairs(data) do
        if type(info) == "table" and info.OwnerUserId == LocalPlayer.UserId then
            for k, rec in pairs(info.Records or {}) do myRecords[k] = rec end
        end
    end

    local ready = {}
    local serverTime = Workspace:GetServerTimeNow()
    for uid, rec in pairs(myRecords) do
        if rec.Placement then
            local placedAt = rec.Placement.PlacedAt or rec.Placement.Time or 0
            local growthTime = 30
            local speedMult = math.max(0.01, rec.GrowthSpeedMultiplier or 1)
            if (serverTime - placedAt) >= (growthTime / speedMult) then
                table.insert(ready, {uid = uid, category = rec.AssetCategory or "Egg"})
            end
        end
    end

    if #ready == 0 then h.isHatching = false; return 0 end
    H(string.format("[AutoHatch] Found %d eggs ready!", #ready))
    local hatched = 0
    for _, egg in ipairs(ready) do
        task.spawn(function()
            local ok1 = pcall(function()
                if g:IsA("RemoteFunction") then return g:InvokeServer(egg.uid) end
                g:FireServer(egg.uid); return true
            end)
            if ok1 then
                task.wait(0.9)
                local ok2 = pcall(function()
                    if Q:IsA("RemoteFunction") then return Q:InvokeServer(egg.uid) end
                    Q:FireServer(egg.uid); return true
                end)
                if ok2 then
                    hatched = hatched + 1
                    h.hatched = (h.hatched or 0) + 1
                    H(string.format("[+] Hatched %s (UID: %s)", egg.category, tostring(egg.uid)))
                end
            end
        end)
        task.wait(0.04)
    end
    task.wait(0.95)
    h.isHatching = false
    H(string.format("[AutoHatch] Finished! Hatched %d eggs.", hatched))
    return hatched
end

-- ==========================================================
-- Дорожка: jk, I4, f4, L4, M4
-- ==========================================================
local function jk(plot)
    if not plot then return nil end
    local bottom = plot:FindFirstChild("TreadmillBottom")
    if bottom and bottom:IsA("BasePart") then return bottom end
    bottom = plot:FindFirstChild("TreadmillBottom", true)
    if bottom and bottom:IsA("BasePart") then return bottom end
    local upgrade = plot:FindFirstChild("TreadmillUpgrade", true)
    if upgrade then
        for _, name in ipairs({"TreadmillBottom", "Belt", "RunArea", "Run", "Platform", "Pad", "Floor", "Base"}) do
            local part = upgrade:FindFirstChild(name, true)
            if part and part:IsA("BasePart") then return part end
        end
        if upgrade.PrimaryPart then return upgrade.PrimaryPart end
        return upgrade:FindFirstChildWhichIsA("BasePart", true)
    end
    for _, d in ipairs(plot:GetDescendants()) do
        if d:IsA("BasePart") and string.find(string.lower(d.Name), "treadmill") then return d end
    end
    return nil
end

local function I4()
    local plot = t4()
    if h.tread and h.tread.Parent then return h.tread end
    local tread = plot and jk(plot)
    if not tread then
        local plots = Workspace:FindFirstChild("Plots")
        if plots then
            local name = string.lower(LocalPlayer.Name)
            for _, p in ipairs(plots:GetChildren()) do
                local t = jk(p)
                if t then
                    local found = false
                    for _, d in ipairs(p:GetDescendants()) do
                        if d:IsA("TextLabel") and d.Text ~= "" then
                            if string.find(string.lower(d.Text), name, 1, true) then
                                found = true; break
                            end
                        end
                    end
                    if found then
                        h.plot = p; h.plotVerified = true; tread = t; break
                    end
                end
            end
            if not tread and plot then tread = jk(plot) end
        end
    end
    h.tread = tread
    return tread
end

function L4()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local tread = I4()
    if tread then
        local p = tread.Position + Vector3.new(0, 1.8, 0)
        if (root.Position - p).Magnitude > 6 then h.onTreadmill = false; return false end
    else
        if root.Position.X > 535 then h.onTreadmill = false; return false end
    end
    if h.onTreadmill then return true end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local anim = track.Animation
            local id = anim and anim.AnimationId or ""
            local n = string.lower(track.Name or "")
            if string.find(id, "10921259953") or string.find(n, "treadmill") or string.find(n, "run") then
                return true
            end
        end
    end
    return false
end

function M4()
    h.onTreadmill = false
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if U then task.spawn(function() pcall(function() U:InvokeServer() end) end) end
    if hum then
        pcall(function()
            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                local anim = track.Animation
                local id = anim and anim.AnimationId or ""
                if string.find(id, "10921259953") or string.find(string.lower(track.Name or ""), "treadmill") or string.find(string.lower(track.Name or ""), "run") then
                    track:Stop(0)
                end
            end
            hum.PlatformStand = false
            hum.Sit = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local anim = pg:FindFirstChild("SpeedGainAnimation")
        if anim then pcall(function() anim:Destroy() end) end
    end
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    Z4(char)
end

q4 = M4

local function f4(session)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return false end
    if hum.PlatformStand then hum.PlatformStand = false end
    if hum.Sit then hum.Sit = false end
    hum:ChangeState(Enum.HumanoidStateType.Running)
    local plot = t4()
    local tread = I4()
    if not tread then
        t("[AutoTreadmill] Treadmill not found! Retry...")
        return false
    end
    pcall(function()
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = false end
        end
    end)
    pcall(function()
        tread.CanTouch = true
        tread.CanCollide = true
        if tread.Parent and tread.Parent:IsA("Model") then
            for _, d in ipairs(tread.Parent:GetDescendants()) do
                if d:IsA("BasePart") then d.CanTouch = true; d.CanCollide = true end
            end
        end
    end)
    local targetPos = tread.Position + Vector3.new(0, 1.8, 0)
    if root.Position.X > 535 then
        h.statusText = "[AutoTreadmill] Returning to base..."
        Q4(h.glideSpeed, session)
        if session and session ~= h.sessionId then return false end
        if root.Position.X > 535 then return false end
    end
    if session and session ~= h.sessionId then return false end
    local distH = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
    if distH > 4 then
        h.statusText = "[AutoTreadmill] Flying to treadmill..."
        local flyTimeout = os.clock() + 4
        while h.alive and (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude > 4 and os.clock() < flyTimeout do
            if session and session ~= h.sessionId then return false end
            local dt = RunService.Heartbeat:Wait()
            local pos = root.Position
            local dir = (Vector3.new(targetPos.X, 70, targetPos.Z) - pos)
            local step = dir.Unit * math.min(dir.Magnitude, 400 * dt)
            local newPos = pos + step
            root.CFrame = CFrame.lookAt(newPos, newPos + (dir.Magnitude > 0.05 and dir.Unit or root.CFrame.LookVector))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if hum.PlatformStand then hum.PlatformStand = false end
            if hum.Sit then hum.Sit = false end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
    if session and session ~= h.sessionId then return false end
    local yTimeout = os.clock() + 1.5
    while h.alive and math.abs(root.Position.Y - targetPos.Y) > 2 and os.clock() < yTimeout do
        if session and session ~= h.sessionId then return false end
        local dt = RunService.Heartbeat:Wait()
        local pos = root.Position
        local dir = targetPos - pos
        local step = dir.Unit * math.min(dir.Magnitude, 150 * dt)
        root.CFrame = CFrame.new(pos + step)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    root.CFrame = CFrame.new(targetPos)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    local dist = (root.Position - targetPos).Magnitude
    if dist <= 6 then
        pcall(function()
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(root, tread, 0)
                task.wait(0.02)
                firetouchinterest(root, tread, 1)
            end
        end)
        pcall(function()
            for _, d in ipairs(tread:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Enabled and typeof(fireproximityprompt) == "function" then
                    fireproximityprompt(d)
                end
            end
            if tread.Parent then
                for _, d in ipairs(tread.Parent:GetDescendants()) do
                    if d:IsA("ProximityPrompt") and d.Enabled and typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(d)
                    end
                end
            end
        end)
        if l then pcall(function() l:InvokeServer() end) end
        h.onTreadmill = true
        h.lastTreadmillMount = os.clock()
        h.statusText = "[AutoTreadmill] Running (Waiting for eggs...)"
        return true
    else
        h.onTreadmill = false
        t(string.format("[AutoTreadmill] Not at treadmill (dist=%.1f)", dist))
        return false
    end
end

-- ==========================================================
-- K4, c4: авто-размещение каждые 5 краж
-- ==========================================================
local AUTO_PLACE_COUNT = 5

local function K4(mode)
    if h.isBatchPlacing then return end
    h.isBatchPlacing = true
    H(string.format("[AutoPlace] %d steals done! Batch placing (%s)...", AUTO_PLACE_COUNT, tostring(mode)))
    local session = h.sessionId
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local basePos = s4()
    local dist = root and (root.Position - basePos).Magnitude or 999
    if dist > 8 then
        h.statusText = "[AutoPlace] Tweening home..."
        g4(h.glideSpeed or 600, session, true)
    end
    if root then
        root.CFrame = CFrame.new(basePos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    task.spawn(function()
        pcall(B4)
        pcall(J4, true)
    end)
    u4()
    h.isReturning = false
    h.delivering = false
    h.glidingToTarget = false
    h.securingEgg = false
    h.teleporting = false
    h.currentTargetModel = nil
    h.targetPosition = nil
    for i = 5, 1, -1 do
        if not h.alive then break end
        h.statusText = string.format("[AutoPlace] Resuming in %ds...", i)
        task.wait(1)
    end
    h.isBatchPlacing = false
    if h.alive and h.sessionId == session then
        H(string.format("[AutoPlace] Done! Continuing %s farm.", mode))
        h.statusText = string.format("[AutoPlace] Resuming %s farm...", mode)
        if mode == "TWEEN" then
            h.pureTweenFarm = true; h.autoFarmLoop = false
        elseif mode == "WARP" then
            h.autoFarmLoop = true; h.pureTweenFarm = false
        end
        h.farmMode = mode
    end
end

local function c4(mode)
    if not h.autoPlaceEvery5 then return false end
    h.batchStealCount = (h.batchStealCount or 0) + 1
    H(string.format("[AutoPlace] Steal trip %d / %d", h.batchStealCount, AUTO_PLACE_COUNT))
    if h.batchStealCount >= AUTO_PLACE_COUNT then
        h.batchStealCount = 0
        task.spawn(function() K4(mode) end)
        return true
    end
    return false
end

-- ==========================================================
-- Ck: главный цикл TWEEN-фарма
-- ==========================================================
task.spawn(function()
    while h.alive do
        local ok, err = pcall(function()
            if h.farmMode == "TWEEN" and not h.isBatchPlacing and not h.teleporting and not h.glidingToTarget and not h.securingEgg and not h.delivering and not h.isReturning then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    pcall(u4)
                    if not w4() then
                        local session = h.sessionId
                        local target = N4()
                        if target and h.farmMode == "TWEEN" and h.sessionId == session then
                            if h.onTreadmill or L4() then
                                h.statusText = "[AutoSteal] Target found! Off treadmill..."
                                M4()
                                task.wait(0.08)
                            end
                            local available, reason = k4(target.Uid)
                            if not available and reason ~= "CarriedBySelf" then
                                H(string.format("[AutoSteal] Egg %s already taken (%s). Switching...", tostring(target.Uid), tostring(reason)))
                                h.cooldown[target.Uid] = os.clock() + 5
                                task.wait(0.12)
                                return
                            end
                            h.currentTargetModel = target.Model
                            h.targetPosition = target.Position
                            h.glidingToTarget = true
                            h.stateTime = os.clock()
                            local scaleInfo = (target.Scale and target.Scale > 1.05) and string.format(" | %.1fx", target.Scale) or ""
                            h.statusText = string.format("[AutoSteal] Flying to %s (%s%s)...", tostring(target.Category or "Egg"), tostring(target.Area or "Field"), scaleInfo)
                            H(string.format("[AutoSteal] Flying to %s | Zone: %s%s | Rank: %d", tostring(target.Category or "Egg"), tostring(target.Area or "Field"), scaleInfo, tonumber(target.Rank) or 1))
                            if not h.swapped then A4() end
                            if not h.godmode then b4(true) end
                            Z4(char)
                            pcall(function() LocalPlayer:RequestStreamAroundAsync(target.Position) end)
                            local targetCF = target.CFrame * CFrame.new(0, 0.4, 0)
                            local reached = R4(targetCF, h.glideSpeed, target.Uid, session)
                            h.glidingToTarget = false
                            if h.sessionId ~= session or h.farmMode ~= "TWEEN" then return end
                            if not reached then
                                t("[AutoSteal] Egg was taken during flight. Switching...")
                                h.cooldown[target.Uid] = os.clock() + 5
                                D4()
                                return
                            end
                            if h.farmMode == "TWEEN" and ((root.Position - target.Position).Magnitude <= 22) then
                                local secured = U4(target.Uid, targetCF, target.Model, session)
                                if not secured and w4() then secured = true end
                                if h.sessionId ~= session or h.farmMode ~= "TWEEN" then return end
                                if secured then
                                    pcall(u4)
                                    if h.autoGlide then
                                        h.statusText = "[AutoSteal] Secured! Tweening to Safe Line..."
                                        H("[AutoSteal] Egg secured! Returning to Safe Line X=525...")
                                        Q4(h.glideSpeed, session)
                                        pcall(u4)
                                        local total = y4()
                                        h.statusText = string.format("Stashed in Bag (%d eggs). Next steal...", total)
                                        H(string.format("[AutoSteal] Egg stashed (%d total). Next...", total))
                                    else
                                        h.statusText = "[AutoSteal] Secured! (Auto Return OFF)"
                                        H("[AutoSteal] Egg secured! Staying at target (Auto Return OFF).")
                                    end
                                    pcall(u4)
                                    h.isReturning = false
                                    h.delivering = false
                                    h.glidingToTarget = false
                                    h.securingEgg = false
                                    h.currentTargetModel = nil
                                    h.targetPosition = nil
                                    if c4("TWEEN") then return end
                                else
                                    if h.sessionId == session and h.farmMode == "TWEEN" then
                                        t("[AutoSteal] Guard Strike failed. Next egg...")
                                        h.cooldown[target.Uid] = os.clock() + 5
                                        D4()
                                    end
                                end
                            else
                                h.currentTargetModel = nil
                                h.targetPosition = nil
                                h.glidingToTarget = false
                            end
                        else
                            if os.clock() - (h._lastCooldownClear or 0) > 5 then
                                h.cooldown = {}
                                h._lastCooldownClear = os.clock()
                            end
                            if h.autoTreadmill and not h.isBatchPlacing and not h.isHatching then
                                if not h.onTreadmill and not L4() then
                                    h.statusText = "[AutoTreadmill] No targets. Mounting..."
                                    f4(session)
                                else
                                    h.statusText = "[AutoTreadmill] Running (Waiting for eggs...)"
                                end
                            else
                                h.statusText = "[AutoSteal] Scanning for targets..."
                            end
                        end
                    end
                end
            end
        end)
        if not ok then
            t("[TWEEN Loop Recovered]:", tostring(err))
            pcall(D4)
        end
        task.wait(0.08)
    end
end)

-- ==========================================================
-- qk: главный цикл WARP-фарма
-- ==========================================================
task.spawn(function()
    while h.alive do
        local ok, err = pcall(function()
            if h.farmMode == "WARP" and not h.isBatchPlacing and not h.teleporting and not h.glidingToTarget and not h.securingEgg and not h.delivering and not h.isReturning then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    pcall(u4)
                    if not w4() then
                        local session = h.sessionId
                        local target = N4()
                        if target and h.farmMode == "WARP" and h.sessionId == session then
                            if h.onTreadmill or L4() then
                                h.statusText = "[SnipeLoop] Target found! Off treadmill..."
                                M4()
                                task.wait(0.08)
                            end
                            local scaleInfo = (target.Scale and target.Scale > 1.05) and string.format(" | %.1fx", target.Scale) or ""
                            H(string.format("[SnipeLoop] Warp Snipe: %s | Zone: %s%s (Rank %d)", tostring(target.Category or "Egg"), tostring(target.Area or "Field"), scaleInfo, tonumber(target.Rank) or 1))
                            h.statusText = string.format("[SnipeLoop] Warping for %s%s...", tostring(target.Category or "Egg"), scaleInfo)
                            local targetCF = target.CFrame * CFrame.new(0, 0.4, 0)
                            if not h.swapped then A4() end
                            if not h.godmode then b4(true) end
                            Z4(char)
                            pcall(function() LocalPlayer:RequestStreamAroundAsync(target.Position) end)
                            char:PivotTo(targetCF)
                            task.wait(0.05)
                            local secured = U4(target.Uid, targetCF, target.Model, session)
                            if h.sessionId ~= session or h.farmMode ~= "WARP" then return end
                            if secured then
                                pcall(u4)
                                if h.autoGlide then
                                    h.statusText = "[SnipeLoop] Secured! Tweening to Safe Line..."
                                    Q4(h.glideSpeed, session)
                                    pcall(u4)
                                    local total = y4()
                                    h.statusText = string.format("Stashed in Bag (%d eggs). Next snipe...", total)
                                    H(string.format("[SnipeLoop] Egg stashed (%d total). Next...", total))
                                else
                                    h.statusText = "[SnipeLoop] Secured! (Auto Return OFF)"
                                    H("[SnipeLoop] Snipe successful! Staying (Auto Return OFF).")
                                end
                                pcall(u4)
                                h.isReturning = false
                                h.delivering = false
                                if c4("WARP") then return end
                            else
                                if h.sessionId == session and h.farmMode == "WARP" then
                                    t("[SnipeLoop] Snipe failed. Resetting...")
                                    if target.Uid then h.cooldown[target.Uid] = os.clock() + 5 end
                                    pcall(D4)
                                end
                            end
                        else
                            if os.clock() - (h._lastCooldownClearW or 0) > 5 then
                                h.cooldown = {}
                                h._lastCooldownClearW = os.clock()
                            end
                            if h.autoTreadmill and not h.isBatchPlacing and not h.isHatching then
                                if not h.onTreadmill and not L4() then
                                    h.statusText = "[AutoTreadmill] No targets. Mounting..."
                                    f4(session)
                                else
                                    h.statusText = "[AutoTreadmill] Running (Waiting for eggs...)"
                                end
                            else
                                h.statusText = "[SnipeLoop] Searching for targets..."
                            end
                        end
                    end
                end
            end
        end)
        if not ok then
            t("[WARP Loop Recovered]:", tostring(err))
            pcall(D4)
        end
        task.wait(0.08)
    end
end)

-- ==========================================================
-- Фоновые циклы
-- ==========================================================
task.spawn(function()
    while h.alive do
        if h.autoHatch and not h.securingEgg and not h.teleporting and not h.isHatching then
            pcall(function() J4(false) end)
        end
        task.wait(4)
    end
end)

task.spawn(function()
    while h.alive do
        if h.autoUpgradeTreadmill and D then
            pcall(function()
                local plot = t4()
                if plot then
                    local up = plot:FindFirstChild("TreadmillUpgrade", true)
                    if up then
                        for _, d in ipairs(up:GetDescendants()) do
                            if d:IsA("ProximityPrompt") and d.Enabled and typeof(fireproximityprompt) == "function" then
                                fireproximityprompt(d)
                            end
                        end
                        pcall(function() D:InvokeServer() end)
                    end
                end
            end)
        end
        task.wait(10)
    end
end)

task.spawn(function()
    while h.alive do
        if h.autoBuyTrails and q then
            pcall(function()
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                local shop = pg and (pg:FindFirstChild("TrailShop") or pg:FindFirstChild("TrailShop", true))
                if shop then
                    local sf = shop:FindFirstChild("ScrollingFrame", true)
                    if sf then
                        for _, item in ipairs(sf:GetChildren()) do
                            if item:IsA("GuiObject") then
                                for _, btn in ipairs(item:GetDescendants()) do
                                    if btn:IsA("TextButton") then
                                        local txt = string.lower(btn.Text or "")
                                        if string.find(txt, "equip") and not string.find(txt, "unequip") then
                                            pcall(function()
                                                if typeof(firesignal) == "function" and btn.Activated then
                                                    firesignal(btn.Activated)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(8)
    end
end)

task.spawn(function()
    while h.alive do
        pcall(function()
            if h.autoTreadmill and h.farmMode == "NONE" and not h.isBatchPlacing and not h.isHatching and not h.teleporting and not h.glidingToTarget and not h.securingEgg and not h.delivering and not h.isReturning then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root and not w4() then
                    if not h.onTreadmill and not L4() then
                        h.statusText = "[AutoTreadmill] Idle. Mounting..."
                        f4()
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

-- ==========================================================
-- Heartbeat: защита от падения и авто-возврат
-- ==========================================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if hum and not h.onTreadmill then
        if hum.PlatformStand then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
        if hum.Sit and (h.pureTweenFarm or h.autoFarmLoop or h.isReturning or h.glidingToTarget) then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
    local pos = root.Position
    if pos.Y < 45 then
        root.CFrame = CFrame.new(pos.X, 72, pos.Z)
        root.AssemblyLinearVelocity = Vector3.zero
        return
    end
    if h.farmMode == "NONE" and h.autoGlide and w4() and pos.X > E then
        task.spawn(function()
            Q4(h.glideSpeed)
            u4()
            h.isReturning = false
            h.delivering = false
        end)
    end
end)

-- ==========================================================
-- ЧАСТЬ 4: UI + СВЯЗКА С ЯДРОМ
-- ==========================================================

-- Сначала оборачиваем все функции ядра в объект Farm
Farm = {}

function Farm.SetFarmMode(mode)
    if not mode or (mode ~= "TWEEN" and mode ~= "WARP" and mode ~= "NONE") then
        mode = "NONE"
    end
    T4(mode)
end

function Farm.GetFarmMode()
    return h.farmMode
end

function Farm.SetZones(zones)
    h.selectedZones = zones or {}
    h.Log("Zones updated: " .. tostring(#h.selectedZones))
end

function Farm.SetRarities(rarities)
    h.selectedRarities = rarities or {}
    h.Log("Rarities updated: " .. tostring(#h.selectedRarities))
end

function Farm.StopAll()
    T4("NONE")
    D4()
    pcall(function() if M4 then M4() end end)
    pcall(function() if u4 then u4(true) end end)
    h.FullRestore()
    h.Log("STOP ALL triggered")
end

function Farm.GetDiagnosticLogs()
    return h.logs
end

function Farm.ClearLogs()
    h.logs = {}
end

function Farm.GetStatus()
    return h.statusText or "Ready"
end

function Farm.GetEggCount()
    if y4 then return y4() end
    return 0
end

function Farm.SetAutoGlide(state)
    h.autoGlide = state and true or false
end

function Farm.SetAutoHatch(state)
    h.autoHatch = state and true or false
end

function Farm.SetAutoTreadmill(state)
    h.autoTreadmill = state and true or false
end

function Farm.SetAutoPlace(state)
    h.autoPlaceEvery5 = state and true or false
    if not state then h.batchStealCount = 0 end
end

function Farm.SetGlideSpeed(value)
    h.glideSpeed = tonumber(value) or 600
end

function Farm.SetGodmode(state)
    b4(state and true or false)
end

-- ==========================================================
-- СОЗДАНИЕ GUI
-- ==========================================================
local player = LocalPlayer
local parentGui = (pcall(function() return gethui() end) and gethui()) or CoreGui

local old = parentGui:FindFirstChild("KerryHubScreenGui")
if old then old:Destroy() end

-- Список зон (совпадает с M из Части 1)
local zonesList = M

-- Список редкостей (совпадает с X из KerryHub)
local raritiesList = {
    "Divine", "Eternal", "Secret", "Cosmic", "Mythic",
    "Legendary", "Epic", "Rare", "Uncommon", "Common",
}

-- Начальное состояние UI (синхронизируем с h)
local uiState = {
    selectedZones = {},
    selectedRarities = {},
    modeA = false, -- TWEEN
    modeB = false, -- WARP
}

-- По умолчанию: первые 3 зоны + топ-5 редкостей (если у h пусто)
if not next(h.selectedZones) then
    h.selectedZones["Light Dark"] = true
    h.selectedZones["Titan Temple"] = true
    h.selectedZones["Cherry Blossom"] = true
end
if not next(h.selectedRarities) then
    h.selectedRarities["Divine"] = true
    h.selectedRarities["Eternal"] = true
    h.selectedRarities["Secret"] = true
    h.selectedRarities["Cosmic"] = true
    h.selectedRarities["Mythic"] = true
end

for zone, v in pairs(h.selectedZones) do uiState.selectedZones[zone] = v end
for rar, v in pairs(h.selectedRarities) do uiState.selectedRarities[rar] = v end

-- Локальная таблица логов для UI
local logLines = {}
local MAX_LOG_LINES = 100

local function log(message)
    local line = os.date("%H:%M:%S") .. "  " .. tostring(message)
    table.insert(logLines, line)
    while #logLines > MAX_LOG_LINES do table.remove(logLines, 1) end
end

-- ==========================================================
-- ScreenGui
-- ==========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "KerryHubScreenGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parentGui

-- ==========================================================
-- Кнопка HUB
-- ==========================================================
local hubButton = Instance.new("TextButton")
hubButton.Name = "HubButton"
hubButton.Size = UDim2.fromOffset(72, 32)
hubButton.Position = UDim2.new(0, 16, 0, 16)
hubButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
hubButton.BorderSizePixel = 0
hubButton.Text = "HUB"
hubButton.TextColor3 = Color3.new(1, 1, 1)
hubButton.TextSize = 14
hubButton.Font = Enum.Font.GothamBold
hubButton.Parent = gui

local hubCorner = Instance.new("UICorner")
hubCorner.CornerRadius = UDim.new(0, 8)
hubCorner.Parent = hubButton

-- ==========================================================
-- Главное окно
-- ==========================================================
local window = Instance.new("Frame")
window.Name = "MainWindow"
window.Size = UDim2.fromOffset(420, 520)
window.Position = UDim2.new(0, 16, 0, 58)
window.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
window.BorderSizePixel = 0
window.Visible = false
window.Parent = gui

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 12)
winCorner.Parent = window

local winStroke = Instance.new("UIStroke")
winStroke.Color = Color3.fromRGB(60, 60, 75)
winStroke.Thickness = 1
winStroke.Parent = window

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 0, 34)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "RH-HUB • Steal an Egg"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = window

-- Кнопка закрытия
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 28)
close.Position = UDim2.new(1, -34, 0, 3)
close.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.Gotham
close.TextSize = 13
close.Parent = window

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = close

-- Скролл-контейнер
local body = Instance.new("ScrollingFrame")
body.Name = "Controls"
body.Position = UDim2.fromOffset(10, 40)
body.Size = UDim2.new(1, -20, 1, -164)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 5
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.new()
body.Parent = window

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 6)
padding.Parent = body

-- ==========================================================
-- Компоненты UI
-- ==========================================================
local function sectionLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = body
    return label
end

-- Тоггл, связанный с колбэком
local function addToggle(text, key, callback, initialState)
    local state = initialState and true or false
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -4, 0, 28)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Parent = body

    local function refresh()
        button.Text = (state and "[ON]  " or "[OFF] ") .. text
        button.BackgroundColor3 = state
            and Color3.fromRGB(55, 90, 55) or Color3.fromRGB(45, 45, 45)
    end

    button.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        log(text .. ": " .. (state and "ON" or "OFF"))
        if callback then pcall(callback, state) end
    end)

    refresh()
    return {
        Set = function(s)
            state = s and true or false
            refresh()
        end,
        Get = function() return state end,
    }
end

-- Мультивыбор
local function addMultiSelect(titleText, options, selectedMap, callback)
    sectionLabel(titleText)
    for _, option in ipairs(options) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -4, 0, 25)
        button.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.Gotham
        button.TextSize = 12
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Parent = body

        local function refresh()
            button.Text = (selectedMap[option] and "[x]  " or "[ ]  ") .. option
            button.BackgroundColor3 = selectedMap[option]
                and Color3.fromRGB(55, 75, 55) or Color3.fromRGB(42, 42, 42)
        end

        button.MouseButton1Click:Connect(function()
            selectedMap[option] = not selectedMap[option]
            refresh()
            log(titleText .. ": " .. option .. (selectedMap[option] and " selected" or " cleared"))
            if callback then pcall(callback, selectedMap) end
        end)

        refresh()
    end
end

-- Слайдер
local function addSlider(text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -4, 0, 44)
    container.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
    container.BorderSizePixel = 0
    container.Parent = body

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -55, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 12
    valueLabel.Parent = container

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 6)
    track.Position = UDim2.new(0, 8, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    track.BorderSizePixel = 0
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local value = default
    local dragging = false

    local function update(input)
        local posX = input.Position.X - track.AbsolutePosition.X
        local pct = math.clamp(posX / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * pct)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = tostring(value)
        if callback then pcall(callback, value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Get = function() return value end,
        Set = function(v)
            value = math.clamp(v, min, max)
            local pct = (value - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            valueLabel.Text = tostring(value)
        end,
    }
end

-- ==========================================================
-- СЕКЦИЯ: MODES
-- ==========================================================
sectionLabel("MODES")

local toggleTween = addToggle("Mode 1 — Tween Farm", "tween", function(state)
    if state then
        if toggleWarp then toggleWarp.Set(false) end
        Farm.SetFarmMode("TWEEN")
    else
        if h.farmMode == "TWEEN" then Farm.SetFarmMode("NONE") end
    end
end, h.farmMode == "TWEEN")

local toggleWarp = addToggle("Mode 2 — Warp Farm", "warp", function(state)
    if state then
        if toggleTween then toggleTween.Set(false) end
        Farm.SetFarmMode("WARP")
    else
        if h.farmMode == "WARP" then Farm.SetFarmMode("NONE") end
    end
end, h.farmMode == "WARP")

-- ==========================================================
-- СЕКЦИЯ: ФИЛЬТРЫ
-- ==========================================================
addMultiSelect("ZONES — MULTI-SELECT", zonesList, uiState.selectedZones, function(map)
    h.selectedZones = map
    Farm.SetZones(map)
end)

addMultiSelect("RARITIES — MULTI-SELECT", raritiesList, uiState.selectedRarities, function(map)
    h.selectedRarities = map
    Farm.SetRarities(map)
end)

-- ==========================================================
-- СЕКЦИЯ: НАСТРОЙКИ ФАРМА
-- ==========================================================
sectionLabel("FARM SETTINGS")

addToggle("Auto Return (Safe Line)", "autoreturn", function(state)
    Farm.SetAutoGlide(state)
end, h.autoGlide ~= false)

addToggle("Auto Hatch", "autohatch", function(state)
    Farm.SetAutoHatch(state)
end, h.autoHatch ~= false)

addToggle("Auto Place (Every 5)", "autoplace", function(state)
    Farm.SetAutoPlace(state)
end, h.autoPlaceEvery5 == true)

addToggle("Auto Treadmill", "autotreadmill", function(state)
    Farm.SetAutoTreadmill(state)
end, h.autoTreadmill ~= false)

addToggle("Desync Godmode", "godmode", function(state)
    Farm.SetGodmode(state)
end, h.godmode ~= false)

addSlider("Flight Speed", 100, 1000, h.glideSpeed or 600, function(val)
    Farm.SetGlideSpeed(val)
end)

-- ==========================================================
-- Кнопка STOP ALL
-- ==========================================================
local stopAll = Instance.new("TextButton")
stopAll.Name = "StopAll"
stopAll.Size = UDim2.new(1, -20, 0, 30)
stopAll.Position = UDim2.new(0, 10, 1, -154)
stopAll.BackgroundColor3 = Color3.fromRGB(120, 45, 45)
stopAll.BorderSizePixel = 0
stopAll.Text = "STOP ALL"
stopAll.TextColor3 = Color3.new(1, 1, 1)
stopAll.Font = Enum.Font.GothamBold
stopAll.TextSize = 13
stopAll.Parent = window

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopAll

stopAll.MouseButton1Click:Connect(function()
    Farm.StopAll()
    if toggleTween then toggleTween.Set(false) end
    if toggleWarp then toggleWarp.Set(false) end
    log("STOP ALL pressed")
end)

-- ==========================================================
-- КОНСОЛЬ
-- ==========================================================
local console = Instance.new("ScrollingFrame")
console.Name = "Console"
console.Position = UDim2.new(0, 10, 1, -116)
console.Size = UDim2.new(1, -20, 0, 106)
console.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
console.BorderSizePixel = 0
console.ScrollBarThickness = 4
console.CanvasSize = UDim2.new()
console.AutomaticCanvasSize = Enum.AutomaticSize.Y
console.Parent = window

local consoleCorner = Instance.new("UICorner")
consoleCorner.CornerRadius = UDim.new(0, 8)
consoleCorner.Parent = console

local consoleLayout = Instance.new("UIListLayout")
consoleLayout.Padding = UDim.new(0, 2)
consoleLayout.SortOrder = Enum.SortOrder.LayoutOrder
consoleLayout.Parent = console

local function refreshConsole()
    for _, child in ipairs(console:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    for _, line in ipairs(logLines) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -8, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Text = line
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 10
        lbl.Parent = console
    end
    task.defer(function()
        console.CanvasPosition = Vector2.new(0, math.max(0, console.AbsoluteCanvasSize.Y - console.AbsoluteSize.Y))
    end)
end

-- Перехватываем h.Log, чтобы логи шли и в UI
local originalLog = h.Log
h.Log = function(msg)
    originalLog(msg)
    local line = os.date("%H:%M:%S") .. "  " .. tostring(msg)
    table.insert(logLines, line)
    while #logLines > MAX_LOG_LINES do table.remove(logLines, 1) end
    refreshConsole()
end

-- Стартовое сообщение
h.Log("RH-HUB UI loaded. Ready.")

-- ==========================================================
-- Открытие/закрытие, драг
-- ==========================================================
hubButton.MouseButton1Click:Connect(function()
    window.Visible = not window.Visible
end)
close.MouseButton1Click:Connect(function() window.Visible = false end)

local dragging = false
local dragStart, startPosition
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
        local ended
        ended = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                ended:Disconnect()
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================================
-- Обновление статуса в консоли (раз в 2 секунды)
-- ==========================================================
task.spawn(function()
    while h.alive and gui and gui.Parent do
        task.wait(2)
        local status = h.statusText or "Ready"
        local eggs = 0
        if y4 then eggs = y4() end
        local line = string.format("[STATUS] %s | Bag: %d eggs | Mode: %s", status, eggs, tostring(h.farmMode))
        -- добавляем в лог, но не спамим print
        table.insert(logLines, line)
        while #logLines > MAX_LOG_LINES do table.remove(logLines, 1) end
        refreshConsole()
    end
end)