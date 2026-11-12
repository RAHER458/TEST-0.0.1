--[[
    RH-SCRIPT
    Universal Roblox UI framework
    Version: 0.1.4 (Speed Sliders)

    This file is independent from LAUNCHER.lua.
    Gameplay modules are intentionally not implemented yet.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Name = "RH-SCRIPT",
    Version = "0.1.4",
    Background = Color3.fromRGB(13, 17, 31),
    Panel = Color3.fromRGB(24, 31, 54),
    PanelLight = Color3.fromRGB(34, 44, 73),
    PanelHover = Color3.fromRGB(47, 59, 96),
    Accent = Color3.fromRGB(139, 92, 246),
    AccentBlue = Color3.fromRGB(56, 189, 248),
    Text = Color3.fromRGB(239, 241, 255),
    Muted = Color3.fromRGB(164, 179, 210),
    Border = Color3.fromRGB(57, 73, 112),
    Green = Color3.fromRGB(88, 214, 160),
}

local oldGui
pcall(function()
    oldGui = (gethui and gethui():FindFirstChild("RH_SCRIPT_UI")) or nil
end)
if not oldGui then
    pcall(function()
        oldGui = CoreGui:FindFirstChild("RH_SCRIPT_UI")
    end)
end
if not oldGui and LocalPlayer then
    pcall(function()
        oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("RH_SCRIPT_UI")
    end)
end
if oldGui then
    oldGui:Destroy()
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function stroke(parent, color, transparency)
    make("UIStroke", {
        Color = color or CONFIG.Border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function label(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or CONFIG.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.None,
    }, parent)
end

local ScreenGui = make("ScreenGui", {
    Name = "RH_SCRIPT_UI",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
}, nil)

local guiParent
local parentOk = pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)
if not parentOk or not guiParent then
    local coreOk = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not coreOk then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
else
    ScreenGui.Parent = guiParent
end

local Window = make("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(480, 460),
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
round(Window, 15)
stroke(Window, CONFIG.Border, 0.12)

local WindowScale = make("UIScale", {Scale = 1}, Window)

local minimized = false
local expandedSize = UDim2.fromOffset(480, 460)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize

    -- Keep the expanded size fitted to the current viewport.
    local fittedWidth = math.max(1, math.min(480, viewport.X - 20))
    local fittedHeight = math.max(1, math.min(460, viewport.Y - 60))
    expandedSize = UDim2.fromOffset(fittedWidth, fittedHeight)

    WindowScale.Scale = 1
    Window.Size = minimized and UDim2.fromOffset(fittedWidth, 58) or expandedSize
end
updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local Header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, Window)

local HeaderLine = make("Frame", {
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = CONFIG.Border,
    BorderSizePixel = 0,
}, Header)

local Logo = make("Frame", {
    Position = UDim2.fromOffset(17, 11),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = CONFIG.Accent,
    BorderSizePixel = 0,
}, Header)
round(Logo, 10)
make("UIGradient", {
    Color = ColorSequence.new(CONFIG.Accent, CONFIG.AccentBlue),
    Rotation = 35,
}, Logo)
local LogoText = label(Logo, "RH", 15, Color3.new(1, 1, 1), Enum.Font.GothamBold)
LogoText.Size = UDim2.fromScale(1, 1)
LogoText.TextXAlignment = Enum.TextXAlignment.Center

local Brand = label(Header, "RH-SCRIPT", 15, CONFIG.Text, Enum.Font.GothamBold)
Brand.Position = UDim2.fromOffset(64, 10)
Brand.Size = UDim2.fromOffset(180, 20)

local SubBrand = label(Header, "UNIVERSAL TOOLKIT  •  BETA", 9, CONFIG.Muted, Enum.Font.GothamMedium)
SubBrand.Position = UDim2.fromOffset(65, 30)
SubBrand.Size = UDim2.fromOffset(220, 15)

local Version = label(Header, "v" .. CONFIG.Version, 10, CONFIG.Muted)
Version.AnchorPoint = Vector2.new(1, 0.5)
Version.Position = UDim2.new(1, -88, 0.5, 0)
Version.Size = UDim2.fromOffset(65, 20)
Version.TextXAlignment = Enum.TextXAlignment.Right

local function headerButton(text, xOffset, color)
    local button = make("TextButton", {
        Position = UDim2.new(1, xOffset, 0, 16),
        Size = UDim2.fromOffset(27, 26),
        BackgroundColor3 = CONFIG.PanelLight,
        Text = text,
        TextColor3 = color or CONFIG.Muted,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, Header)
    round(button, 8)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.PanelHover}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.PanelLight}):Play()
    end)
    return button
end

local MinButton = headerButton("—", -67)
local CloseButton = headerButton("×", -34, Color3.fromRGB(255, 112, 130))

local Body = make("Frame", {
    Name = "Body",
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
}, Window)

local Sidebar = make("Frame", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(0, 174, 1, 0),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, Body)

local SideDivider = make("Frame", {
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = CONFIG.Border,
    BorderSizePixel = 0,
}, Sidebar)

local NavCaption = label(Sidebar, "NAVIGATION", 9, CONFIG.Muted, Enum.Font.GothamBold)
NavCaption.Position = UDim2.fromOffset(17, 17)
NavCaption.Size = UDim2.new(1, -30, 0, 18)

local NavHolder = make("Frame", {
    Position = UDim2.fromOffset(10, 43),
    Size = UDim2.new(1, -20, 0, 300),
    BackgroundTransparency = 1,
}, Sidebar)
make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, NavHolder)

local SideFooter = make("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 10, 1, -12),
    Size = UDim2.new(1, -20, 0, 48),
    BackgroundColor3 = CONFIG.PanelLight,
    BorderSizePixel = 0,
}, Sidebar)
round(SideFooter, 9)
local FooterDot = make("Frame", {
    Position = UDim2.fromOffset(11, 18),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = CONFIG.Green,
    BorderSizePixel = 0,
}, SideFooter)
round(FooterDot, 8)
local FooterText = label(SideFooter, "Interface loaded", 10, CONFIG.Muted)
FooterText.Position = UDim2.fromOffset(25, 0)
FooterText.Size = UDim2.new(1, -30, 1, 0)

local Content = make("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(174, 0),
    Size = UDim2.new(1, -174, 1, 0),
    BackgroundTransparency = 1,
}, Body)

local PageTitle = label(Content, "MAIN", 21, CONFIG.Text, Enum.Font.GothamBold)
PageTitle.Position = UDim2.fromOffset(25, 19)
PageTitle.Size = UDim2.new(1, -50, 0, 29)

local PageDescription = label(Content, "Your universal Roblox workspace", 11, CONFIG.Muted)
PageDescription.Position = UDim2.fromOffset(26, 49)
PageDescription.Size = UDim2.new(1, -50, 0, 20)

local PageContainer = make("ScrollingFrame", {
    Name = "PageContainer",
    Position = UDim2.fromOffset(25, 82),
    Size = UDim2.new(1, -50, 1, -105),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
    ScrollingEnabled = true,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = CONFIG.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Content)

local pages = {
    MAIN = "Welcome to RH-SCRIPT. Your workspace is ready.",
    AIM = "Aim tools will be configured here in a future update.",
    WH = "WH module placeholder. No gameplay functions are active.",
    ESP = "ESP module placeholder. No gameplay functions are active.",
    MISC = "Extra tools and utilities will appear in this section.",
    SETTINGS = "Interface preferences and script options.",
}

local function createInfoCard(parent, title, description, height)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 94),
        BackgroundColor3 = CONFIG.Panel,
        BorderSizePixel = 0,
    }, parent)
    round(card, 11)
    stroke(card, CONFIG.Border, 0.12)
    make("UIGradient", {
        Color = ColorSequence.new(CONFIG.Panel, CONFIG.PanelLight),
        Rotation = 25,
    }, card)

    local accent = make("Frame", {
        Position = UDim2.fromOffset(0, 13),
        Size = UDim2.new(0, 3, 0, 34),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
    }, card)
    round(accent, 3)

    local titleLabel = label(card, title, 13, CONFIG.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.fromOffset(16, 13)
    titleLabel.Size = UDim2.new(1, -32, 0, 21)

    local descLabel = label(card, description, 10, CONFIG.Muted)
    descLabel.Position = UDim2.fromOffset(16, 39)
    descLabel.Size = UDim2.new(1, -32, 0, 36)
    descLabel.TextWrapped = true
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    return card
end

local function clearPage()
    for _, child in ipairs(PageContainer:GetChildren()) do
        child:Destroy()
    end
end


-- Movement utilities (client-side; games may enforce their own server movement rules).
local RunService = game:GetService("RunService")
local speedEnabled = false
local speedMode = "WalkSpeed"
local speedValues = {WalkSpeed = 32, Tween = 32, CFrame = 32}
local speedConnection
local flightActive = false
local flightVelocity
local flightCharacter
local flightEditMode = false
local flightLocked = false
local flightDragging = false
local flightDragStart
local flightButtonStart
local flightPosition = UDim2.new(1, -92, 1, -210)
local flightButton

local function getCharacterParts()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and root then return character, humanoid, root end
end

local function stopSpeed()
    speedEnabled = false
    if speedConnection then speedConnection:Disconnect(); speedConnection = nil end
    local _, humanoid = getCharacterParts()
    if humanoid then humanoid.WalkSpeed = 16 end
end

local function startSpeed()
    stopSpeed()
    local character, humanoid, root = getCharacterParts()
    if not character then return false end
    speedEnabled = true
    if speedMode == "WalkSpeed" then
        humanoid.WalkSpeed = speedValues[speedMode]
    else
        speedConnection = RunService.Heartbeat:Connect(function(dt)
            if not speedEnabled then return end
            local currentCharacter, currentHumanoid, currentRoot = getCharacterParts()
            if not currentCharacter or currentCharacter ~= character then stopSpeed(); return end
            local direction = currentHumanoid.MoveDirection
            if direction.Magnitude > 0 then
                local distance = speedValues[speedMode] * dt
                if speedMode == "Tween" then
                    local target = currentRoot.CFrame + direction * distance
                    local tween = TweenService:Create(currentRoot, TweenInfo.new(math.max(dt, 0.03), Enum.EasingStyle.Linear), {CFrame = target})
                    tween:Play()
                elseif speedMode == "CFrame" then
                    currentRoot.CFrame = currentRoot.CFrame + direction * distance
                end
            end
        end)
    end
    return true
end

local function stopFlight()
    flightActive = false
    if flightVelocity then flightVelocity:Destroy(); flightVelocity = nil end
    local _, humanoid = getCharacterParts()
    if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
    flightButton.Text = "↑"
    flightButton.BackgroundColor3 = CONFIG.Accent
end

local function beginFlight()
    local character, humanoid, root = getCharacterParts()
    if not character then return end
    if flightVelocity then flightVelocity:Destroy() end
    flightCharacter = character
    flightVelocity = Instance.new("BodyVelocity")
    flightVelocity.Name = "RH_HoldFlight"
    flightVelocity.MaxForce = Vector3.new(0, math.huge, 0)
    flightVelocity.P = 18000
    flightVelocity.Velocity = Vector3.new(0, 42, 0)
    flightVelocity.Parent = root
    flightActive = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    flightButton.Text = "▲"
    flightButton.BackgroundColor3 = CONFIG.AccentBlue
end

flightButton = make("TextButton", {
    Name = "RH_FlightButton",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = flightPosition,
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = CONFIG.Accent,
    Text = "↑",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 25,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    BorderSizePixel = 0,
    Visible = true,
    ZIndex = 120,
}, ScreenGui)
round(flightButton, 29)
stroke(flightButton, CONFIG.AccentBlue, 0.08)
make("UIGradient", {Color = ColorSequence.new(CONFIG.Accent, CONFIG.AccentBlue), Rotation = 35}, flightButton)

flightButton.InputBegan:Connect(function(input)
    if flightEditMode and not flightLocked and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        flightDragging = true
        flightDragStart = input.Position
        flightButtonStart = flightButton.Position
        return
    end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        beginFlight()
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if flightDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - flightDragStart
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local x = math.clamp(flightButtonStart.X.Offset + delta.X, 37, viewport.X - 37)
        local y = math.clamp(flightButtonStart.Y.Offset + delta.Y, 37, viewport.Y - 37)
        flightButton.Position = UDim2.fromOffset(x, y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if flightDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        flightDragging = false
    elseif flightActive and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
        stopFlight()
    end
end)

local currentPage = "MAIN"
local navButtons = {}

local function renderPage(pageName)
    currentPage = pageName
    PageTitle.Text = pageName
    PageDescription.Text = pageName == "MAIN" and "Your universal Roblox workspace" or "RH-SCRIPT  /  " .. pageName
    clearPage()

    if pageName == "MAIN" then
        local welcome = createInfoCard(
            PageContainer,
            "Welcome back",
            "RH-SCRIPT interface preview is running. Choose a section on the left to explore the layout.",
            105
        )
        local status = createInfoCard(
            PageContainer,
            "SYSTEM STATUS",
            "UI: ONLINE     •     GAME MODULES: NOT ADDED",
            82
        )
        status.Position = UDim2.fromOffset(0, 118)
        local note = createInfoCard(
            PageContainer,
            "DEVELOPMENT BUILD",
            "This is the visual foundation. Individual modules and their settings will be added separately.",
            82
        )
        note.Position = UDim2.fromOffset(0, 212)
    elseif pageName == "MISC" then
        local speedCard = make("Frame", {Size = UDim2.new(1, 0, 0, 310), BackgroundColor3 = CONFIG.Panel, BorderSizePixel = 0}, PageContainer)
        round(speedCard, 11); stroke(speedCard, CONFIG.Border, 0.12)
        local speedTitle = label(speedCard, "SPEEDHACK", 13, CONFIG.Text, Enum.Font.GothamBold)
        speedTitle.Position = UDim2.fromOffset(14, 9); speedTitle.Size = UDim2.new(1, -28, 0, 22)
        local modeLabel = label(speedCard, "Активный режим: " .. speedMode, 10, CONFIG.Muted)
        modeLabel.Position = UDim2.fromOffset(14, 34); modeLabel.Size = UDim2.new(1, -28, 0, 18)
        local modeButton = make("TextButton", {Position = UDim2.fromOffset(12, 55), Size = UDim2.new(1, -24, 0, 27), BackgroundColor3 = CONFIG.PanelLight, Text = "Сменить активный режим", TextColor3 = CONFIG.Text, TextSize = 10, Font = Enum.Font.GothamBold, BorderSizePixel = 0, AutoButtonColor = false}, speedCard)
        round(modeButton, 7)
        modeButton.MouseButton1Click:Connect(function()
            local modes = {"WalkSpeed", "Tween", "CFrame"}
            local index = table.find(modes, speedMode) or 1
            speedMode = modes[index % #modes + 1]
            modeLabel.Text = "Активный режим: " .. speedMode
            if speedEnabled then startSpeed() end
        end)
        local sliderRows = {}
        local function setSpeed(mode, value)
            speedValues[mode] = math.clamp(math.floor(value + 0.5), 0, 500)
            local row = sliderRows[mode]
            if row then
                row.value.Text = tostring(speedValues[mode])
                row.fill.Size = UDim2.new(speedValues[mode] / 500, 0, 1, 0)
                row.knob.Position = UDim2.new(speedValues[mode] / 500, -6, 0.5, -6)
            end
            if speedEnabled and speedMode == mode then startSpeed() end
        end
        for i, mode in ipairs({"WalkSpeed", "Tween", "CFrame"}) do
            local y = 91 + (i - 1) * 53
            local name = label(speedCard, mode, 10, CONFIG.Text, Enum.Font.GothamBold)
            name.Position = UDim2.fromOffset(14, y); name.Size = UDim2.fromOffset(105, 18)
            local value = label(speedCard, tostring(speedValues[mode]), 10, CONFIG.AccentBlue, Enum.Font.GothamBold)
            value.Position = UDim2.new(1, -48, 0, y); value.Size = UDim2.fromOffset(34, 18); value.TextXAlignment = Enum.TextXAlignment.Right
            local track = make("TextButton", {Position = UDim2.fromOffset(14, y + 25), Size = UDim2.new(1, -28, 0, 8), BackgroundColor3 = CONFIG.PanelLight, Text = "", BorderSizePixel = 0, AutoButtonColor = false}, speedCard)
            round(track, 5)
            local fill = make("Frame", {Size = UDim2.new(speedValues[mode] / 500, 0, 1, 0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0}, track)
            round(fill, 5)
            local knob = make("Frame", {Size = UDim2.fromOffset(12, 12), Position = UDim2.new(speedValues[mode] / 500, -6, 0.5, -6), BackgroundColor3 = CONFIG.Text, BorderSizePixel = 0, ZIndex = 3}, track)
            round(knob, 6)
            sliderRows[mode] = {value = value, fill = fill, knob = knob}
            local dragging = false
            local function updateFromInput(input)
                local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                setSpeed(mode, ratio * 500)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateFromInput(input) end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end
        local toggle = make("TextButton", {Position = UDim2.fromOffset(12, 258), Size = UDim2.new(1, -24, 0, 32), BackgroundColor3 = CONFIG.Accent, Text = speedEnabled and "ВЫКЛЮЧИТЬ" or "ВКЛЮЧИТЬ", TextColor3 = Color3.new(1,1,1), TextSize = 9, Font = Enum.Font.GothamBold, BorderSizePixel = 0}, speedCard)
        round(toggle, 7)
        toggle.MouseButton1Click:Connect(function()
            if speedEnabled then stopSpeed() else startSpeed() end
            toggle.Text = speedEnabled and "ВЫКЛЮЧИТЬ" or "ВКЛЮЧИТЬ"
        end)

        local flyCard = make("Frame", {Position = UDim2.fromOffset(0, 202), Size = UDim2.new(1, 0, 0, 126), BackgroundColor3 = CONFIG.Panel, BorderSizePixel = 0}, PageContainer)
        round(flyCard, 11); stroke(flyCard, CONFIG.Border, 0.12)
        local flyTitle = label(flyCard, "HOLD FLIGHT", 13, CONFIG.Text, Enum.Font.GothamBold)
        flyTitle.Position = UDim2.fromOffset(14, 9); flyTitle.Size = UDim2.new(1, -28, 0, 20)
        local flyDesc = label(flyCard, "Удерживай плавающую кнопку — летишь вверх. Отпусти — падаешь.", 9, CONFIG.Muted)
        flyDesc.Position = UDim2.fromOffset(14, 32); flyDesc.Size = UDim2.new(1, -28, 0, 32); flyDesc.TextWrapped = true
        local editButton = make("TextButton", {Position = UDim2.fromOffset(12, 73), Size = UDim2.new(1, -24, 0, 30), BackgroundColor3 = CONFIG.PanelLight, Text = flightEditMode and "ПЕРЕМЕЩЕНИЕ: ВКЛ" or "ЗАФИКСИРОВАТЬ КНОПКУ", TextColor3 = CONFIG.Text, TextSize = 9, Font = Enum.Font.GothamBold, BorderSizePixel = 0}, flyCard)
        round(editButton, 7)
        editButton.MouseButton1Click:Connect(function()
            flightEditMode = not flightEditMode
            flightLocked = not flightEditMode
            editButton.Text = flightEditMode and "ПЕРЕМЕЩАЙ КНОПКУ ПО ЭКРАНУ" or "ЗАФИКСИРОВАТЬ КНОПКУ"
            flightButton.BackgroundColor3 = flightEditMode and CONFIG.PanelHover or CONFIG.Accent
        end)
        local hint = createInfoCard(PageContainer, "УПРАВЛЕНИЕ", "Кнопка полёта находится справа внизу рядом с мобильным управлением Roblox. Перемещение доступно после разблокировки в MISC.", 75)
        hint.Position = UDim2.fromOffset(0, 338)
    else
        createInfoCard(PageContainer, pageName .. " MODULE", pages[pageName], 105)
        local note = createInfoCard(PageContainer, "COMING LATER", "This section is reserved for future features. The interface is ready for expansion.", 82)
        note.Position = UDim2.fromOffset(0, 118)
    end

    for name, button in pairs(navButtons) do
        local selected = name == pageName
        local target = selected and CONFIG.PanelHover or CONFIG.Panel
        TweenService:Create(button, TweenInfo.new(0.16), {
            BackgroundColor3 = target,
            TextColor3 = selected and CONFIG.Text or CONFIG.Muted,
        }):Play()
        local indicator = button:FindFirstChild("ActiveIndicator")
        if indicator then
            indicator.BackgroundTransparency = selected and 0 or 1
        end
    end
end

local navItems = {
    {name = "MAIN", icon = "⌂"},
    {name = "AIM", icon = "◎"},
    {name = "WH", icon = "◈"},
    {name = "ESP", icon = "◇"},
    {name = "MISC", icon = "✳"},
    {name = "SETTINGS", icon = "⚙"},
}

for index, item in ipairs(navItems) do
    local button = make("TextButton", {
        Name = item.name .. "Button",
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = CONFIG.Panel,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = index,
    }, NavHolder)
    round(button, 8)

    local indicator = make("Frame", {
        Name = "ActiveIndicator",
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(0, 3, 0, 23),
        BackgroundColor3 = CONFIG.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, button)
    round(indicator, 3)

    local iconLabel = label(button, item.icon, 16, CONFIG.Muted, Enum.Font.GothamBold)
    iconLabel.Position = UDim2.fromOffset(12, 0)
    iconLabel.Size = UDim2.fromOffset(22, 39)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local textLabel = label(button, item.name, 11, CONFIG.Muted, Enum.Font.GothamBold)
    textLabel.Position = UDim2.fromOffset(43, 0)
    textLabel.Size = UDim2.new(1, -50, 1, 0)

    navButtons[item.name] = button
    button.MouseButton1Click:Connect(function()
        renderPage(item.name)
    end)
    button.MouseEnter:Connect(function()
        if currentPage ~= item.name then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = CONFIG.PanelLight}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if currentPage ~= item.name then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = CONFIG.Panel}):Play()
        end
    end)
end

renderPage("MAIN")

-- Compact floating RH bubble shown while the main window is minimized.
local MiniBubble = make("TextButton", {
    Name = "RH_MiniBubble",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = Window.Position,
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = CONFIG.Accent,
    Text = "RH",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    Visible = false,
    BorderSizePixel = 0,
    ZIndex = 100,
}, ScreenGui)
round(MiniBubble, 27)
stroke(MiniBubble, CONFIG.AccentBlue, 0.05)
make("UIGradient", {
    Color = ColorSequence.new(CONFIG.Accent, CONFIG.AccentBlue),
    Rotation = 35,
}, MiniBubble)

local bubbleDragging = false
local bubbleMoved = false
local bubbleStart
local bubbleStartPosition
local bubbleInput
MiniBubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bubbleDragging = true
        bubbleMoved = false
        bubbleStart = input.Position
        bubbleStartPosition = MiniBubble.Position
        bubbleInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if bubbleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - bubbleStart
        if delta.Magnitude > 7 then bubbleMoved = true end
        if bubbleMoved then
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local half = MiniBubble.AbsoluteSize / 2
            local margin = 8
            local centerX = math.clamp(
                bubbleStartPosition.X.Offset + delta.X,
                half.X + margin,
                math.max(half.X + margin, viewport.X - half.X - margin)
            )
            local centerY = math.clamp(
                bubbleStartPosition.Y.Offset + delta.Y,
                half.Y + margin,
                math.max(half.Y + margin, viewport.Y - half.Y - margin)
            )
            MiniBubble.Position = UDim2.fromOffset(centerX, centerY)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if bubbleDragging and (input == bubbleInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        bubbleDragging = false
        if not bubbleMoved then
            minimized = false
            MiniBubble.Visible = false
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
            local half = expandedSize.X.Offset / 2
            local halfY = expandedSize.Y.Offset / 2
            local margin = 8
            local centerX = math.clamp(
                MiniBubble.Position.X.Offset,
                half + margin,
                math.max(half + margin, viewport.X - half - margin)
            )
            local centerY = math.clamp(
                MiniBubble.Position.Y.Offset,
                halfY + margin,
                math.max(halfY + margin, viewport.Y - halfY - margin)
            )
            Window.Position = UDim2.fromOffset(centerX, centerY)
            Window.Visible = true
            Window.Size = expandedSize
        end
        bubbleInput = nil
    end
end)

MinButton.MouseButton1Click:Connect(function()
    minimized = true
    Window.Visible = false
    MiniBubble.Position = Window.Position
    MiniBubble.Visible = true
end)

CloseButton.MouseButton1Click:Connect(function()
    stopSpeed()
    stopFlight()
    ScreenGui:Destroy()
end)

-- Dragging support for mouse and touch.
local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

print("[RH-SCRIPT] Interface " .. CONFIG.Version .. " loaded.")
