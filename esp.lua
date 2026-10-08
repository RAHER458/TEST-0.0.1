-- RAHERHUB 0.1 | Private testing UI
-- Intended for use in your own Roblox place / authorized test environment.
-- No registration, license checks, accounts, or external HTTP requests.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local VERSION = "0.1"
local SETTINGS_KEY = "RAHERHUB_01_SETTINGS"
_G[SETTINGS_KEY] = _G[SETTINGS_KEY] or {}
local savedUI = _G[SETTINGS_KEY]
savedUI.flySize = savedUI.flySize or 66
savedUI.flyOpacity = savedUI.flyOpacity or 0.12
savedUI.flyPosition = savedUI.flyPosition or {x = -24, y = -150}
savedUI.rhPosition = savedUI.rhPosition or {x = 18, y = 300}
local POINTS_FILE = "raherhub_teleport_points.json"

-- Remove an older copy if the script is re-run.
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("RAHERHUB_01")
    if old then old:Destroy() end
end)

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or Color3.fromRGB(70, 75, 95),
        Thickness = thickness or 1,
        Transparency = transparency or 0.2
    }, parent)
end

local function safeParentGui(gui)
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local gui = make("ScreenGui", {
    Name = "RAHERHUB_01",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
})
safeParentGui(gui)

-- Five-second animated loading screen
local loadingFrame = make("Frame", {
    Name = "LoadingScreen", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(10, 11, 18), BorderSizePixel = 0,
    ZIndex = 1000
}, gui)
local loadingTitle = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 50), Position = UDim2.new(0, 0, 0.36, 0),
    BackgroundTransparency = 1, Text = "RAHERHUB", TextColor3 = Color3.fromRGB(255, 80, 190),
    TextSize = 31, Font = Enum.Font.GothamBlack, ZIndex = 1001
}, loadingFrame)
local loadingSubtitle = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0.36, 45),
    BackgroundTransparency = 1, Text = "NEON SYSTEM  •  VERSION 0.1", TextColor3 = Color3.fromRGB(210, 216, 235),
    TextSize = 12, Font = Enum.Font.GothamMedium, ZIndex = 1001
}, loadingFrame)
local loadingTrack = make("Frame", {
    Size = UDim2.new(0.7, 0, 0, 10), Position = UDim2.new(0.15, 0, 0.56, 0),
    BackgroundColor3 = Color3.fromRGB(66, 74, 100), BorderSizePixel = 0, ZIndex = 1001
}, loadingFrame)
corner(loadingTrack, 6)
local loadingFill = make("Frame", {
    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 70, 190),
    BorderSizePixel = 0, ZIndex = 1002
}, loadingTrack)
corner(loadingFill, 6)
local loadingPercent = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0.56, 16),
    BackgroundTransparency = 1, Text = "0%", TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13, Font = Enum.Font.GothamBold, ZIndex = 1001
}, loadingFrame)
local loadingHint = make("TextLabel", {
    Size = UDim2.new(1, -30, 0, 26), Position = UDim2.new(0, 15, 0.68, 0),
    BackgroundTransparency = 1, Text = "Подготавливаем интерфейс...", TextColor3 = Color3.fromRGB(210, 216, 235),
    TextSize = 12, Font = Enum.Font.Gotham, ZIndex = 1001
}, loadingFrame)
task.spawn(function()
    local started = os.clock()
    while loadingFrame.Parent and os.clock() - started < 5 do
        local elapsed = math.min(os.clock() - started, 5)
        local progress = elapsed / 5
        loadingFill.Size = UDim2.new(progress, 0, 1, 0)
        loadingPercent.Text = tostring(math.floor(progress * 100)) .. "%"
        loadingTitle.TextColor3 = Color3.fromHSV((elapsed * 0.22) % 1, 0.7, 1)
        task.wait(0.03)
    end
end)
task.wait(5)
if loadingFrame then loadingFrame:Destroy() end

local COLORS = {
    background = Color3.fromRGB(58, 65, 84),
    panel = Color3.fromRGB(75, 84, 108),
    panel2 = Color3.fromRGB(91, 103, 132),
    button = Color3.fromRGB(105, 119, 151),
    text = Color3.fromRGB(245, 248, 255),
    muted = Color3.fromRGB(235, 240, 255),
    accent = Color3.fromRGB(0, 220, 255),
    green = Color3.fromRGB(58, 235, 164),
    red = Color3.fromRGB(255, 77, 119)
}

local main = make("CanvasGroup", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.92, 0, 0.78, 0),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)
main.Size = UDim2.new(0, 350, 0, 430)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.GroupTransparency = 0
corner(main, 18)
local mainStroke = stroke(main, Color3.fromRGB(0, 220, 255), 1.5, 0.08)
make("UIGradient", {
    Rotation = 115,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 88, 116)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(62, 73, 99)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(86, 61, 103))
    })
}, main)

-- Fit the panel to small screens while keeping a comfortable touch layout.
local miniMode, microMode = false, false
local function fitPanel()
    local camera = workspace.CurrentCamera
    if not camera then return end
    if miniMode or microMode then return end
    local viewport = camera.ViewportSize
    -- Compact by default: never occupy almost the entire phone screen.
    local width = math.clamp(viewport.X - 36, 280, 370)
    local height = math.clamp(viewport.Y - 150, 300, 470)
    main.Size = UDim2.fromOffset(width, height)
end
fitPanel()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
end

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0
}, main)
corner(header, 18)
local rgbStrip = make("Frame", {
    Name = "RGBAccent",
    Position = UDim2.new(0, 12, 0, 59),
    Size = UDim2.new(1, -24, 0, 2),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    ZIndex = 5
}, main)
corner(rgbStrip, 2)
local rgbGradient = make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 230, 255)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(150, 70, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 55, 190)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 160))
    })
}, rgbStrip)

local title = make("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 15, 0, 5),
    Size = UDim2.new(1, -150, 0, 30),
    BackgroundTransparency = 1,
    Text = "RAHERHUB",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 22,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local subtitle = make("TextLabel", {
    Position = UDim2.new(0, 16, 0, 34),
    Size = UDim2.new(1, -150, 0, 16),
    BackgroundTransparency = 1,
    Text = "NEON INTERFACE  /  PRIVATE BUILD " .. VERSION,
    TextColor3 = COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local minimize = make("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 9),
    Size = UDim2.fromOffset(38, 38),
    BackgroundColor3 = COLORS.button,
    BorderSizePixel = 0,
    Text = "—",
    TextColor3 = COLORS.text,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, header)
corner(minimize, 12)

local miniModeButton = make("TextButton", {
    Name = "MiniMode",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -54, 0, 9),
    Size = UDim2.fromOffset(32, 38),
    BackgroundColor3 = COLORS.button,
    BorderSizePixel = 0,
    Text = "▣",
    TextColor3 = COLORS.text,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, header)
corner(miniModeButton, 10)
local microModeButton = make("TextButton", {
    Name = "MicroMode",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -92, 0, 9),
    Size = UDim2.fromOffset(32, 38),
    BackgroundColor3 = COLORS.button,
    BorderSizePixel = 0,
    Text = "· · ·",
    TextColor3 = COLORS.text,
    TextSize = 14,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = true
}, header)
corner(microModeButton, 10)
local miniPanel
local mainScale = make("UIScale", {Scale = 1}, main)
local openCloseTween
local function animateMain(show)
    if openCloseTween then pcall(function() openCloseTween:Cancel() end) end
    if show then
        main.Visible = true
        main.GroupTransparency = 1
        mainScale.Scale = 0.92
        openCloseTween = TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {GroupTransparency = 0})
        TweenService:Create(mainScale, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        openCloseTween:Play()
    else
        openCloseTween = TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
        TweenService:Create(mainScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.92}):Play()
        openCloseTween:Play()
        openCloseTween.Completed:Once(function()
            if main and main.Parent and main.GroupTransparency >= 0.99 then main.Visible = false end
        end)
    end
end

-- Rainbow title animation.
local hue = 0
local rgbConnection
rgbConnection = RunService.RenderStepped:Connect(function(dt)
    if not title.Parent then
        if rgbConnection then rgbConnection:Disconnect() end
        return
    end
    hue = (hue + dt * 0.22) % 1
    title.TextColor3 = Color3.fromHSV(hue, 0.68, 1)
    mainStroke.Color = Color3.fromHSV((hue + 0.12) % 1, 0.82, 1)
    if openButtonStroke then openButtonStroke.Color = Color3.fromHSV((hue + 0.3) % 1, 0.82, 1) end
    if rgbGradient then rgbGradient.Rotation = (rgbGradient.Rotation + dt * 38) % 360 end
end)

-- Drag by the header on mouse or touch.
local dragging, dragStart, startPos = false, nil, nil
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local openButton = make("TextButton", {
    Name = "OpenButton",
    Visible = false,
    Position = UDim2.fromOffset(savedUI.rhPosition.x or 18, savedUI.rhPosition.y or 300),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Text = "RH",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 18,
    Font = Enum.Font.GothamBlack
}, gui)
corner(openButton, 29)
local openButtonStroke = stroke(openButton, Color3.fromRGB(0, 220, 255), 2, 0.05)

minimize.Activated:Connect(function()
    animateMain(false)
    task.delay(0.2, function() if openButton and openButton.Parent then openButton.Visible = true end end)
end)
do
    local rhDragging, rhStart, rhStartPos, rhInput, rhMoved = false, nil, nil, nil, false
    openButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            rhDragging = true; rhMoved = false; rhStart = input.Position; rhStartPos = openButton.Position; rhInput = input
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then rhDragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if rhDragging and rhStart and (input == rhInput or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - rhStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then rhMoved = true end
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(800,600)
            local x = math.clamp(rhStartPos.X.Offset + delta.X, 0, viewport.X - openButton.AbsoluteSize.X)
            local y = math.clamp(rhStartPos.Y.Offset + delta.Y, 0, viewport.Y - openButton.AbsoluteSize.Y)
            openButton.Position = UDim2.fromOffset(x, y)
            savedUI.rhPosition = {x = x, y = y}
        end
    end)
    openButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not rhMoved then animateMain(true); openButton.Visible = false end
            rhDragging = false
        end
    end)
end

local tabsBar = make("Frame", {
    Position = UDim2.new(0, 10, 0, 69),
    Size = UDim2.new(1, -20, 0, 34),
    BackgroundTransparency = 1
}, main)
local tabLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabsBar)

local pages = {}
local tabButtons = {}
local activeTab = "MAIN"
local content = make("Frame", {
    Position = UDim2.new(0, 10, 0, 112),
    Size = UDim2.new(1, -20, 1, -122),
    BackgroundTransparency = 1
}, main)

local tabCaptions = {MAIN = "HOME", FUNCTIONS = "FUNCS", TELEPORT = "TP", SETTINGS = "STYLE", ["COMING SOON"] = "MORE"}
for _, tabName in ipairs({"MAIN", "FUNCTIONS", "TELEPORT", "SETTINGS", "COMING SOON"}) do
    local tab = make("TextButton", {
        Name = tabName .. "Tab",
        Size = UDim2.new(1/5, -6, 1, 0),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Text = tabCaptions[tabName] or tabName,
        TextColor3 = COLORS.muted,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        LayoutOrder = #tabButtons + 1
    }, tabsBar)
    corner(tab, 10)
    tabButtons[tabName] = tab
    local page = make("ScrollingFrame", {
        Name = tabName .. "Page",
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false
    }, content)
    make("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 4)
    }, page)
    pages[tabName] = page
end

local function selectTab(name)
    activeTab = name
    for tabName, page in pairs(pages) do
        page.Visible = tabName == name
        tabButtons[tabName].BackgroundColor3 = tabName == name and Color3.fromRGB(69, 88, 124) or COLORS.button
        tabButtons[tabName].TextColor3 = tabName == name and Color3.fromRGB(0, 230, 255) or COLORS.muted
    end
end
for name, button in pairs(tabButtons) do
    button.Activated:Connect(function() selectTab(name) end)
end

local function section(parent, text)
    return make("TextLabel", {
        Size = UDim2.new(1, -2, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.muted,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

local function infoCard(parent, heading, body)
    local card = make("Frame", {
        Size = UDim2.new(1, -2, 0, 76),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0
    }, parent)
    corner(card, 13)
    make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1,
        Text = heading,
        TextColor3 = COLORS.text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)
    make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -24, 0, 38),
        BackgroundTransparency = 1,
        Text = body,
        TextWrapped = true,
        TextColor3 = COLORS.muted,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, card)
    return card
end

local statusLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 36),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Text = "Готово. Регистрация не требуется.",
    TextColor3 = COLORS.green,
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true
}, pages["MAIN"])
corner(statusLabel, 11)

section(pages["MAIN"], "OVERVIEW")
infoCard(pages["MAIN"], "RAHERHUB 0.1", "Личная сборка с интерфейсом для телефона и сохранением точек телепорта.")
infoCard(pages["MAIN"], "БЫСТРЫЙ СТАРТ", "Откройте «Функции» для управления персонажем или «Телепорт» для сохранения мест.")
infoCard(pages["MAIN"], "ХРАНЕНИЕ ТОЧЕК", "Точки сохраняются на устройстве, если среда поддерживает работу с файлами.")

local liveStatus = make("TextLabel", {
    Name = "LiveStatusPanel",
    Size = UDim2.new(1, -2, 0, 58),
    BackgroundColor3 = COLORS.panel2,
    BorderSizePixel = 0,
    Text = "СТАТУС  •  Загрузка...",
    TextColor3 = COLORS.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center
}, pages["MAIN"])
corner(liveStatus, 11)
make("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8)}, liveStatus)

-- Toggle/button factories.
local function makeActionButton(parent, text, callback, height)
    local button = make("TextButton", {
        Size = UDim2.new(1, -2, 0, height or 46),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, parent)
    corner(button, 12)
    button.Activated:Connect(callback)
    return button
end

local function makeToggle(parent, label, initial, callback)
    local enabled = initial or false
    local button
    local function paint()
        button.Text = label .. "     [" .. (enabled and "ВКЛ" or "ВЫКЛ") .. "]"
        button.BackgroundColor3 = enabled and COLORS.green or COLORS.button
    end
    button = makeActionButton(parent, "", function()
        enabled = not enabled
        paint()
        if callback then callback(enabled) end
    end)
    paint()
    return button, function(value)
        enabled = value and true or false
        paint()
        if callback then callback(enabled) end
    end
end

section(pages["FUNCTIONS"], "УПРАВЛЕНИЕ ПЕРСОНАЖЕМ")
infoCard(pages["FUNCTIONS"], "Инструменты тестирования", "Используйте инструменты только в своей игре или там, где у вас есть разрешение.")

-- Скорость ходьбы: диапазон 16–1000
local speedEnabled = false
local walkSpeed = 16
local function applyWalkSpeed()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = speedEnabled and walkSpeed or 16 end
end
local _, setSpeedToggle = makeToggle(pages["FUNCTIONS"], "Ускорение ходьбы", false, function(value)
    speedEnabled = value
    applyWalkSpeed()
end)
local walkSpeedLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 24), BackgroundTransparency = 1,
    Text = "СКОРОСТЬ: " .. walkSpeed, TextColor3 = COLORS.muted,
    TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left
}, pages["FUNCTIONS"])
local walkSpeedTrack = make("Frame", {
    Size = UDim2.new(1, -2, 0, 36), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0
}, pages["FUNCTIONS"])
corner(walkSpeedTrack, 11)
local walkSpeedBar = make("Frame", {
    Position = UDim2.new(0, 10, 0.5, -4), Size = UDim2.new(0, 0, 0, 8),
    BackgroundColor3 = COLORS.accent, BorderSizePixel = 0
}, walkSpeedTrack)
corner(walkSpeedBar, 5)
local walkSpeedKnob = make("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
    Size = UDim2.fromOffset(25, 25), BackgroundColor3 = Color3.new(1,1,1),
    BorderSizePixel = 0, Text = "", AutoButtonColor = false
}, walkSpeedTrack)
corner(walkSpeedKnob, 13)
local walkSpeedDragging = false
local function setWalkSpeedFromX(x)
    local left = walkSpeedTrack.AbsolutePosition.X + 10
    local width = math.max(1, walkSpeedTrack.AbsoluteSize.X - 20)
    local alpha = math.clamp((x - left) / width, 0, 1)
    walkSpeed = math.floor(16 + alpha * (1000 - 16) + 0.5)
    walkSpeedLabel.Text = "СКОРОСТЬ: " .. walkSpeed
    walkSpeedBar.Size = UDim2.new(alpha, 0, 0, 8)
    walkSpeedKnob.Position = UDim2.new(alpha, 10, 0.5, 0)
    if speedEnabled then applyWalkSpeed() end
end
walkSpeedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        walkSpeedDragging = true; setWalkSpeedFromX(input.Position.X)
    end
end)
walkSpeedKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        walkSpeedDragging = true; setWalkSpeedFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if walkSpeedDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        setWalkSpeedFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then walkSpeedDragging = false end
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if speedEnabled then applyWalkSpeed() end
end)

-- ESP highlight state.
local espEnabled = false
local espObjects = {}
local function removeESP(player)
    local object = espObjects[player]
    if object then pcall(function() object:Destroy() end) end
    espObjects[player] = nil
end
local function createESP(player)
    if not espEnabled or player == LocalPlayer or not player.Character or espObjects[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "RaherESP"
    highlight.FillColor = Color3.fromRGB(255, 75, 95)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.48
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    espObjects[player] = highlight
end
local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if espEnabled then createESP(player) else removeESP(player) end
    end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createESP(player)
    end)
end)
Players.PlayerRemoving:Connect(removeESP)
local _, setESPToggle = makeToggle(pages["FUNCTIONS"], "Подсветка игроков (ESP)", false, function(value)
    espEnabled = value
    updateESP()
end)

-- FLY: one floating button. Hold to rise; release to fall. Drag it in edit mode.
local flyTouch
local flyEditMode = false
local flyHeld = false
local flyEnabled = false
local flySpeed = 4
local flyDragState = {dragging = false, start = nil, startPos = nil, input = nil}

local _, setFlyToggle = makeToggle(pages["FUNCTIONS"], "Полёт (удерживать для подъёма)", false, function(value)
    flyEnabled = value
    if not value then flyHeld = false end
    if flyTouch then
        flyTouch.Visible = flyEditMode or (main.Visible and ((miniMode and flyEnabled) or (not miniMode and activeTab == "FUNCTIONS" and flyEnabled)))
    end
end)

local speedLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 24),
    BackgroundTransparency = 1,
    Text = "СИЛА ПОЛЁТА: 4",
    TextColor3 = COLORS.muted,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, pages["FUNCTIONS"])
local speedTrack = make("Frame", {
    Size = UDim2.new(1, -2, 0, 34),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0
}, pages["FUNCTIONS"])
corner(speedTrack, 11)
local speedBar = make("Frame", {
    Position = UDim2.new(0, 10, 0.5, -4),
    Size = UDim2.new((flySpeed - 1) / 19, 0, 0, 8),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0
}, speedTrack)
corner(speedBar, 5)
local speedKnob = make("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new((flySpeed - 1) / 19, 10, 0.5, 0),
    Size = UDim2.fromOffset(25, 25),
    BackgroundColor3 = Color3.new(1,1,1),
    BorderSizePixel = 0,
    Text = "",
    AutoButtonColor = false
}, speedTrack)
corner(speedKnob, 13)
local speedDragging = false
local function setFlySpeedFromX(x)
    local left = speedTrack.AbsolutePosition.X + 10
    local width = math.max(1, speedTrack.AbsoluteSize.X - 20)
    local alpha = math.clamp((x - left) / width, 0, 1)
    flySpeed = math.floor(1 + alpha * 19 + 0.5)
    speedLabel.Text = "СИЛА ПОЛЁТА: " .. flySpeed
    speedBar.Size = UDim2.new(alpha, 0, 0, 8)
    speedKnob.Position = UDim2.new(alpha, 10, 0.5, 0)
end
speedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
        setFlySpeedFromX(input.Position.X)
    end
end)
speedKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
        setFlySpeedFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if speedDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        setFlySpeedFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then speedDragging = false end
end)

local flyPos = savedUI.flyPosition
flyTouch = make("TextButton", {
    Name = "FlyHoldButton",
    Visible = false,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, flyPos.x, 1, flyPos.y),
    Size = UDim2.fromOffset(savedUI.flySize, savedUI.flySize),
    BackgroundColor3 = COLORS.accent,
    BackgroundTransparency = savedUI.flyOpacity,
    BorderSizePixel = 0,
    Text = "FLY",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = math.floor(savedUI.flySize * 0.25),
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    ZIndex = 100
}, gui)
corner(flyTouch, 100)
stroke(flyTouch, Color3.fromRGB(255,255,255), 1, 0.35)

local _, setFlyEditToggle = makeToggle(pages["FUNCTIONS"], "Редактировать кнопку FLY", false, function(value)
    flyEditMode = value
    flyHeld = false
    if flyTouch then
        flyTouch.Text = value and "ПЕРЕМЕСТИ" or "FLY"
        flyTouch.Visible = value or (main.Visible and activeTab == "FUNCTIONS" and flyEnabled)
    end
    statusLabel.Text = value and "Перетащи кнопку FLY пальцем. Нажатие в этом режиме не запускает полёт." or "Режим редактирования FLY выключен."
    statusLabel.TextColor3 = value and COLORS.accent or COLORS.green
end)

flyTouch.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if flyEditMode then
        flyDragState.dragging = true
        flyDragState.start = input.Position
        flyDragState.startPos = flyTouch.Position
        flyDragState.input = input
    elseif flyEnabled then
        flyHeld = true
    end
end)

local function releaseFly()
    if not flyHeld then return end
    flyHeld = false
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(velocity.X, -2, velocity.Z)
    end
end

flyTouch.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if flyEditMode then
            flyDragState.dragging = false
            savedUI.flyPosition = {x = flyTouch.Position.X.Offset, y = flyTouch.Position.Y.Offset}
        else
            releaseFly()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if flyEditMode and flyDragState.dragging and flyDragState.start
        and (input == flyDragState.input or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - flyDragState.start
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        local size = flyTouch.AbsoluteSize
        local x = math.clamp(flyDragState.startPos.X.Offset + delta.X, -viewport.X + size.X, 0)
        local y = math.clamp(flyDragState.startPos.Y.Offset + delta.Y, -viewport.Y + size.Y, 0)
        flyTouch.Position = UDim2.new(1, x, 1, y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if flyEditMode and flyDragState.dragging then
            flyDragState.dragging = false
            savedUI.flyPosition = {x = flyTouch.Position.X.Offset, y = flyTouch.Position.Y.Offset}
        elseif flyHeld then
            releaseFly()
        end
    end
end)

local noclipEnabled = false
local originalCollision = {}
local _, setNoclipToggle = makeToggle(pages["FUNCTIONS"], "Проход сквозь объекты (Noclip)", false, function(value)
    noclipEnabled = value
    if not value then
        for part, oldValue in pairs(originalCollision) do
            if part and part.Parent then pcall(function() part.CanCollide = oldValue end) end
        end
        table.clear(originalCollision)
    end
end)

RunService.Stepped:Connect(function()
    if speedEnabled then applyWalkSpeed() end
    local character = LocalPlayer.Character
    if not character then return end
    if noclipEnabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCollision[part] == nil then originalCollision[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end
    if flyEnabled and flyHeld then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local velocity = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(velocity.X, flySpeed * 10, velocity.Z)
        end
    end
end)

-- Show the single FLY button while the feature is enabled or being edited.
local function updateFlyButton()
    if not flyTouch then return end
    flyTouch.Visible = flyEditMode or (main.Visible and ((miniMode and flyEnabled) or (not miniMode and activeTab == "FUNCTIONS" and flyEnabled)))
end
for _, button in pairs(tabButtons) do
    button.Activated:Connect(function() task.defer(updateFlyButton) end)
end
minimize.Activated:Connect(updateFlyButton)
openButton.Activated:Connect(updateFlyButton)

-- Saved teleport points.
local teleportPoints = {}
local function canUseFiles()
    return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
end
local function loadPoints()
    if not canUseFiles() then return end
    local ok, exists = pcall(isfile, POINTS_FILE)
    if not ok or not exists then return end
    local readOK, raw = pcall(readfile, POINTS_FILE)
    if not readOK or type(raw) ~= "string" then return end
    local decodeOK, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if decodeOK and type(data) == "table" then
        for _, point in ipairs(data) do
            if type(point) == "table" and type(point.name) == "string" and type(point.x) == "number" and type(point.y) == "number" and type(point.z) == "number" then
                table.insert(teleportPoints, {name = point.name, x = point.x, y = point.y, z = point.z})
            end
        end
    end
end
local function savePoints()
    if not canUseFiles() then
        statusLabel.Text = "Файловое сохранение недоступно: точки останутся до конца сессии."
        statusLabel.TextColor3 = Color3.fromRGB(255, 190, 90)
        return false
    end
    local ok, raw = pcall(function() return HttpService:JSONEncode(teleportPoints) end)
    if not ok then return false end
    local writeOK = pcall(writefile, POINTS_FILE, raw)
    return writeOK
end
loadPoints()

section(pages["TELEPORT"], "УПРАВЛЕНИЕ ТОЧКАМИ")
infoCard(pages["TELEPORT"], "Сохранённые места", "Сохраните текущее место, чтобы позже вернуться к нему.")
local pointNameBox = make("TextBox", {
    Size = UDim2.new(1, -2, 0, 46),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Название точки (например, Дом)",
    PlaceholderColor3 = COLORS.muted,
    TextColor3 = COLORS.text,
    TextSize = 14,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, pages["TELEPORT"])
corner(pointNameBox, 12)

local pointsList = make("Frame", {
    Size = UDim2.new(1, -2, 0, 8),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1
}, pages["TELEPORT"])
make("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, pointsList)

local function clearPointRows()
    for _, child in ipairs(pointsList:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end
    end
end
local function refreshPoints()
    clearPointRows()
    if #teleportPoints == 0 then
        local empty = make("TextLabel", {
            Size = UDim2.new(1, -2, 0, 42),
            BackgroundColor3 = COLORS.panel,
            BorderSizePixel = 0,
            Text = "Сохранённых точек пока нет.",
            TextColor3 = COLORS.muted,
            TextSize = 12,
            Font = Enum.Font.Gotham,
        }, pointsList)
        corner(empty, 10)
        return
    end
    for index, point in ipairs(teleportPoints) do
        local row = make("Frame", {
            Size = UDim2.new(1, -2, 0, 88),
            BackgroundColor3 = COLORS.panel,
            BorderSizePixel = 0,
            LayoutOrder = index
        }, pointsList)
        corner(row, 12)
        make("TextLabel", {
            Position = UDim2.new(0, 11, 0, 8),
            Size = UDim2.new(1, -22, 0, 21),
            BackgroundTransparency = 1,
            Text = point.name,
            TextColor3 = COLORS.text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, row)
        make("TextLabel", {
            Position = UDim2.new(0, 11, 0, 30),
            Size = UDim2.new(1, -22, 0, 16),
            BackgroundTransparency = 1,
            Text = string.format("X %.1f   Y %.1f   Z %.1f", point.x, point.y, point.z),
            TextColor3 = COLORS.muted,
            TextSize = 10,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)
        local go = make("TextButton", {
            Position = UDim2.new(0, 9, 0, 53),
            Size = UDim2.new(0.67, -8, 0, 27),
            BackgroundColor3 = COLORS.accent,
            BorderSizePixel = 0,
            Text = "ПЕРЕМЕСТИТЬСЯ",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 11,
            Font = Enum.Font.GothamBold
        }, row)
        corner(go, 8)
        go.Activated:Connect(function()
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then
                statusLabel.Text = "Персонаж ещё не готов. Попробуйте снова."
                statusLabel.TextColor3 = COLORS.red
                return
            end
            -- Local character movement: use only in your own place / authorized tests.
            root.CFrame = CFrame.new(point.x, point.y + 3, point.z)
            statusLabel.Text = "Перемещение к точке: " .. point.name
            statusLabel.TextColor3 = COLORS.green
        end)
        local delete = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -9, 0, 53),
            Size = UDim2.new(0.33, -5, 0, 27),
            BackgroundColor3 = COLORS.red,
            BorderSizePixel = 0,
            Text = "УДАЛИТЬ",
            TextColor3 = Color3.new(1,1,1),
            TextSize = 11,
            Font = Enum.Font.GothamBold
        }, row)
        corner(delete, 8)
        delete.Activated:Connect(function()
            table.remove(teleportPoints, index)
            savePoints()
            refreshPoints()
        end)
    end
end

makeActionButton(pages["TELEPORT"], "+ СОХРАНИТЬ ТЕКУЩЕЕ МЕСТО", function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        statusLabel.Text = "Персонаж ещё не готов. Попробуйте снова."
        statusLabel.TextColor3 = COLORS.red
        return
    end
    local name = pointNameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "Точка " .. tostring(#teleportPoints + 1) end
    for _, point in ipairs(teleportPoints) do
        if point.name:lower() == name:lower() then
            statusLabel.Text = "Точка с таким названием уже существует."
            statusLabel.TextColor3 = COLORS.red
            return
        end
    end
    local pos = root.Position
    table.insert(teleportPoints, {name = name, x = pos.X, y = pos.Y, z = pos.Z})
    local saved = savePoints()
    pointNameBox.Text = ""
    refreshPoints()
    statusLabel.Text = saved and ("Точка сохранена: " .. name) or ("Точка создана: " .. name .. " (session only)")
    statusLabel.TextColor3 = saved and COLORS.green or Color3.fromRGB(255, 190, 90)
end)

makeActionButton(pages["TELEPORT"], "УДАЛИТЬ ВСЕ ТОЧКИ", function()
    table.clear(teleportPoints)
    savePoints()
    refreshPoints()
    statusLabel.Text = "Все сохранённые точки удалены."
    statusLabel.TextColor3 = COLORS.muted
end)

-- SETTINGS: customize both independently draggable flight controls.
section(pages["SETTINGS"], "INTERFACE SETTINGS")
infoCard(pages["SETTINGS"], "Настройка кнопок FLY", "Изменяйте размер и прозрачность обеих кнопок. Позиции кнопок сохраняются отдельно.")

local function createSettingSlider(parent, titleText, minValue, maxValue, initialValue, formatter, onChange)
    local wrap = make("Frame", {
        Size = UDim2.new(1, -2, 0, 68),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0
    }, parent)
    corner(wrap, 12)

    local label = make("TextLabel", {
        Position = UDim2.new(0, 12, 0, 7),
        Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1,
        Text = titleText .. ": " .. formatter(initialValue),
        TextColor3 = COLORS.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, wrap)

    local track = make("Frame", {
        Position = UDim2.new(0, 12, 0, 39),
        Size = UDim2.new(1, -24, 0, 8),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0
    }, wrap)
    corner(track, 5)

    local alpha = (initialValue - minValue) / (maxValue - minValue)
    local fill = make("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = COLORS.accent,
        BorderSizePixel = 0
    }, track)
    corner(fill, 5)

    local knob = make("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, track)
    corner(knob, 11)

    local dragging = false
    local function setValueFromX(x)
        local left = track.AbsolutePosition.X
        local width = math.max(1, track.AbsoluteSize.X)
        local ratio = math.clamp((x - left) / width, 0, 1)
        local value = math.floor(minValue + ratio * (maxValue - minValue) + 0.5)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        label.Text = titleText .. ": " .. formatter(value)
        onChange(value)
    end

    local function begin(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setValueFromX(input.Position.X)
        end
    end
    track.InputBegan:Connect(begin)
    knob.InputBegan:Connect(begin)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            setValueFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return wrap
end

local function applyFlyAppearance()
    flyTouch.Size = UDim2.fromOffset(savedUI.flySize, savedUI.flySize)
    flyTouch.TextSize = math.floor(savedUI.flySize * 0.25)
    flyTouch.BackgroundTransparency = savedUI.flyOpacity
end

createSettingSlider(pages["SETTINGS"], "Размер кнопки FLY", 44, 110, savedUI.flySize, function(v) return tostring(v) .. " px" end, function(value)
    savedUI.flySize = value
    applyFlyAppearance()
end)

createSettingSlider(pages["SETTINGS"], "Прозрачность кнопки FLY", 0, 85, math.floor(savedUI.flyOpacity * 100 + 0.5), function(v) return tostring(v) .. "%" end, function(value)
    savedUI.flyOpacity = value / 100
    applyFlyAppearance()
end)

makeActionButton(pages["SETTINGS"], "СБРОСИТЬ ПОЗИЦИЮ FLY", function()
    savedUI.flyPosition = {x = -24, y = -150}
    flyTouch.Position = UDim2.new(1, -24, 1, -150)
    statusLabel.Text = "Позиция кнопки FLY сброшена."
    statusLabel.TextColor3 = COLORS.green
end)

makeActionButton(pages["SETTINGS"], "СБРОСИТЬ РАЗМЕР И ПРОЗРАЧНОСТЬ", function()
    savedUI.flySize = 66
    savedUI.flyOpacity = 0.12
    applyFlyAppearance()
    statusLabel.Text = "Размер и прозрачность кнопок сброшены."
    statusLabel.TextColor3 = COLORS.green
end)

makeActionButton(pages["SETTINGS"], "ГОТОВО / ВЫЙТИ ИЗ РЕДАКТИРОВАНИЯ", function()
    flyEditMode = false
    flyTouch.Text = "FLY"
    statusLabel.Text = "Настройки применены."
    statusLabel.TextColor3 = COLORS.green
    updateFlyButton()
end)

section(pages["COMING SOON"], "COMING SOON")
infoCard(pages["COMING SOON"], "В разработке", "Здесь появятся новые функции RAHERHUB. Версия остаётся 0.1 до начала альфа-тестирования.")
infoCard(pages["COMING SOON"], "Следующие улучшения", "Дополнительные настройки интерфейса, удобства управления и новые инструменты для тестирования.")

-- Optional UI click sounds. Sound playback is guarded because some launch environments block asset audio.
local uiSoundsEnabled = false
local uiClickSound = make("Sound", {
    Name = "RAHERHUB_UIClick",
    SoundId = "rbxassetid://6895079853",
    Volume = 0.25
}, SoundService)
local function playUIClick()
    if not uiSoundsEnabled then return end
    pcall(function()
        uiClickSound:Stop()
        uiClickSound.TimePosition = 0
        SoundService:PlayLocalSound(uiClickSound)
    end)
end
makeToggle(pages["SETTINGS"], "Звуки интерфейса", false, function(value)
    uiSoundsEnabled = value
    statusLabel.Text = value and "Звуки интерфейса включены (если доступны)." or "Звуки интерфейса выключены."
    statusLabel.TextColor3 = value and COLORS.accent or COLORS.green
    playUIClick()
end)

-- Compact mini mode: responsive controls with expandable inline sliders.
miniPanel = make("Frame", {
    Name = "MiniPanel",
    Position = UDim2.new(0, 10, 0, 68),
    Size = UDim2.new(1, -20, 0, 120),
    BackgroundTransparency = 1,
    Visible = false
}, main)
local microPanel = make("Frame", {
    Name = "MicroPanel",
    Position = UDim2.new(0, 10, 0, 68),
    Size = UDim2.new(1, -20, 0, 48),
    BackgroundColor3 = COLORS.panel2,
    BorderSizePixel = 0,
    Visible = false
}, main)
corner(microPanel, 12)
stroke(microPanel, COLORS.accent, 1, 0.2)
local microStatus = make("TextLabel", {
    Position = UDim2.new(0, 10, 0, 0),
    Size = UDim2.new(1, -20, 1, 0),
    BackgroundTransparency = 1,
    Text = "RAHERHUB  •  READY",
    TextColor3 = COLORS.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextWrapped = true
}, microPanel)
local miniStatus = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    Text = "SPD 16  |  SPEED OFF  |  FLY OFF",
    TextColor3 = COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, miniPanel)
local miniButtonsRow = make("Frame", {
    Position = UDim2.new(0, 0, 0, 27),
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1
}, miniPanel)
make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, miniButtonsRow)

local miniExpanded = nil
local miniSpeedCard, miniFlyCard
local miniSpeedLabel, miniFlyLabel
local miniSpeedTrack, miniSpeedBar, miniSpeedKnob
local miniFlyTrack, miniFlyBar, miniFlyKnob
local miniSpeedDragging, miniFlyDragging = false, false

local function miniCard(title, y)
    local card = make("Frame", {
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = COLORS.panel2,
        BorderSizePixel = 0,
        Visible = false
    }, miniPanel)
    corner(card, 10)
    stroke(card, COLORS.accent, 1, 0.55)
    local label = make("TextLabel", {
        Position = UDim2.new(0, 10, 0, 2),
        Size = UDim2.new(1, -20, 0, 17),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = COLORS.text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)
    local track = make("Frame", {
        Position = UDim2.new(0, 12, 0, 27),
        Size = UDim2.new(1, -24, 0, 6),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Active = true
    }, card)
    corner(track, 4)
    local bar = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = COLORS.accent,
        BorderSizePixel = 0
    }, track)
    corner(bar, 4)
    local knob = make("TextButton", {
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = COLORS.text,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false
    }, track)
    corner(knob, 8)
    stroke(knob, COLORS.accent, 1, 0.1)
    return card, label, track, bar, knob
end

miniSpeedCard, miniSpeedLabel, miniSpeedTrack, miniSpeedBar, miniSpeedKnob = miniCard("WALK SPEED: " .. walkSpeed, 72)
miniFlyCard, miniFlyLabel, miniFlyTrack, miniFlyBar, miniFlyKnob = miniCard("FLY POWER: " .. flySpeed, 72)

local function updateMiniSliderVisuals()
    local speedAlpha = math.clamp((walkSpeed - 16) / (1000 - 16), 0, 1)
    miniSpeedLabel.Text = "WALK SPEED: " .. walkSpeed
    miniSpeedBar.Size = UDim2.new(speedAlpha, 0, 1, 0)
    miniSpeedKnob.Position = UDim2.new(speedAlpha, 0, 0.5, 0)
    local flyAlpha = math.clamp((flySpeed - 1) / 19, 0, 1)
    miniFlyLabel.Text = "FLY POWER: " .. flySpeed
    miniFlyBar.Size = UDim2.new(flyAlpha, 0, 1, 0)
    miniFlyKnob.Position = UDim2.new(flyAlpha, 0, 0.5, 0)
end

local function layoutMiniControls()
    miniSpeedCard.Visible = miniExpanded == "SPEED" and speedEnabled
    miniFlyCard.Visible = miniExpanded == "FLY" and flyEnabled
    local expanded = miniSpeedCard.Visible or miniFlyCard.Visible
    miniPanel.Size = UDim2.new(1, -20, 0, expanded and 130 or 72)
    main.Size = UDim2.fromOffset(math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 390) - 70, 240, 300), expanded and 218 or 150)
    updateMiniSliderVisuals()
end

local function miniButton(label, callback)
    local button = make("TextButton", {
        Size = UDim2.new(1/3, -6, 1, 0),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, miniButtonsRow)
    corner(button, 10)
    stroke(button, COLORS.accent, 1, 0.72)
    button.Activated:Connect(function()
        playUIClick()
        callback()
        layoutMiniControls()
    end)
    return button
end
miniButton("SPEED", function()
    if speedEnabled then
        setSpeedToggle(false)
        miniExpanded = nil
    else
        setSpeedToggle(true)
        miniExpanded = "SPEED"
    end
end)
miniButton("FLY", function()
    if flyEnabled then
        setFlyToggle(false)
        miniExpanded = nil
    else
        setFlyToggle(true)
        miniExpanded = "FLY"
    end
end)
miniButton("NOCLIP", function() setNoclipToggle(not noclipEnabled) end)

local function miniSetSpeedFromX(x)
    local left = miniSpeedTrack.AbsolutePosition.X
    local width = math.max(1, miniSpeedTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - left) / width, 0, 1)
    walkSpeed = math.floor(16 + alpha * (1000 - 16) + 0.5)
    updateMiniSliderVisuals()
    if speedEnabled then applyWalkSpeed() end
end
local function miniSetFlyFromX(x)
    local left = miniFlyTrack.AbsolutePosition.X
    local width = math.max(1, miniFlyTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - left) / width, 0, 1)
    flySpeed = math.floor(1 + alpha * 19 + 0.5)
    updateMiniSliderVisuals()
end
local function beginMiniDrag(input, which)
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if which == "SPEED" then miniSpeedDragging = true; miniSetSpeedFromX(input.Position.X)
    else miniFlyDragging = true; miniSetFlyFromX(input.Position.X) end
end
miniSpeedTrack.InputBegan:Connect(function(input) beginMiniDrag(input, "SPEED") end)
miniSpeedKnob.InputBegan:Connect(function(input) beginMiniDrag(input, "SPEED") end)
miniFlyTrack.InputBegan:Connect(function(input) beginMiniDrag(input, "FLY") end)
miniFlyKnob.InputBegan:Connect(function(input) beginMiniDrag(input, "FLY") end)
UserInputService.InputChanged:Connect(function(input)
    if miniSpeedDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then miniSetSpeedFromX(input.Position.X) end
    if miniFlyDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then miniSetFlyFromX(input.Position.X) end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        miniSpeedDragging, miniFlyDragging = false, false
    end
end)

local function enterFullMode()
    miniMode = false
    microMode = false
    tabsBar.Visible = true
    content.Visible = true
    miniPanel.Visible = false
    microPanel.Visible = false
    main.Size = UDim2.fromOffset(350, 430)
    fitPanel()
    miniModeButton.Text = "▣"
    microModeButton.Text = "· · ·"
end

local function enterMiniMode()
    miniMode = true
    microMode = false
    tabsBar.Visible = false
    content.Visible = false
    miniPanel.Visible = true
    microPanel.Visible = false
    miniModeButton.Text = "□"
    microModeButton.Text = "· · ·"
    layoutMiniControls()
end

local function enterMicroMode()
    miniMode = false
    microMode = true
    tabsBar.Visible = false
    content.Visible = false
    miniPanel.Visible = false
    microPanel.Visible = true
    main.Size = UDim2.fromOffset(math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 390) - 100, 190, 230), 112)
    miniModeButton.Text = "▣"
    microModeButton.Text = "•••"
end

miniModeButton.Activated:Connect(function()
    playUIClick()
    if miniMode then enterFullMode() else enterMiniMode() end
    updateFlyButton()
end)

microModeButton.Activated:Connect(function()
    playUIClick()
    if microMode then enterFullMode() else enterMicroMode() end
    updateFlyButton()
end)

-- Keep the live status panel current without depending on a particular tab.
task.spawn(function()
    while gui.Parent do
        local actualSpeed = 16
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then actualSpeed = math.floor(humanoid.WalkSpeed + 0.5) end
        local function flag(value) return value and "ON" or "OFF" end
        if liveStatus and liveStatus.Parent then
            liveStatus.Text = string.format("СТАТУС\nSPEED %s  •  %d\nFLY %s  •  NOCLIP %s  •  ESP %s",
                flag(speedEnabled), actualSpeed, flag(flyEnabled), flag(noclipEnabled), flag(espEnabled))
        end
        if miniStatus and miniStatus.Parent then
            miniStatus.Text = string.format("SPD %d  |  SPEED %s  |  FLY %s  |  NC %s",
                actualSpeed, flag(speedEnabled), flag(flyEnabled), flag(noclipEnabled))
        end
        if microStatus and microStatus.Parent then
            microStatus.Text = string.format("RH  •  SPD %d  •  %s  •  %s", actualSpeed, speedEnabled and "SPD ON" or "SPD OFF", flyEnabled and "FLY ON" or "FLY OFF")
        end
        task.wait(0.25)
    end
end)

-- Route common button presses through the optional click sound.
for _, obj in ipairs(gui:GetDescendants()) do
    if obj:IsA("TextButton") and obj ~= openButton then
        obj.Activated:Connect(playUIClick)
    end
end

refreshPoints()
selectTab("MAIN")

-- Keep touch fly control visibility in sync with the selected page and minimized state.
local function syncFlyButton()
    updateFlyButton()
end
for _, button in pairs(tabButtons) do button.Activated:Connect(function() task.defer(syncFlyButton) end) end
minimize.Activated:Connect(syncFlyButton)
openButton.Activated:Connect(function() task.defer(syncFlyButton) end)

main.GroupTransparency = 0
mainScale.Scale = 0.94
TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
TweenService:Create(mainScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
print("RAHERHUB " .. VERSION .. " запущен.")