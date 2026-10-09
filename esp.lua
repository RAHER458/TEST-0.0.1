-- RAHERHUB 0.2 | NPC-ONLY TRIGGERBOT BUILD | Private testing UI
-- Intended for use in your own Roblox place / authorized test environment.
-- No registration, license checks, accounts, or external HTTP requests.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local VERSION = "0.2-COMPAT"
local SETTINGS_KEY = "RAHERHUB_02_SETTINGS"
_G[SETTINGS_KEY] = _G[SETTINGS_KEY] or _G["RAHERHUB_01_SETTINGS"] or {}
local savedUI = _G[SETTINGS_KEY]
savedUI.flySize = savedUI.flySize or 66
savedUI.flyOpacity = savedUI.flyOpacity or 0.12
savedUI.flyPosition = savedUI.flyPosition or {x = -24, y = -150}
savedUI.rhPosition = savedUI.rhPosition or {x = 18, y = 300}
local POINTS_FILE = "raherhub_teleport_points.json"
local CONFIG_FILE = "raherhub_02_config.json"

-- Remove an older copy if the script is re-run.
pcall(function()
    local core = game:GetService("CoreGui")
    local old = core:FindFirstChild("RAHERHUB_01")
    if old then old:Destroy() end
    local oldESP = core:FindFirstChild("RAHERHUB_ESP_OVERLAY")
    if oldESP then oldESP:Destroy() end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local oldPlayerESP = playerGui:FindFirstChild("RAHERHUB_ESP_OVERLAY")
        if oldPlayerESP then oldPlayerESP:Destroy() end
    end
    -- BillboardGui boxes live beside ScreenGui in CoreGui/PlayerGui, so clean
    -- those siblings too when the script is rerun.
    for _, container in ipairs({core, playerGui}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child.Name:match("^RaherESPBox_") then pcall(function() child:Destroy() end) end
            end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local oldChams = character and character:FindFirstChild("RaherESPChams")
        if oldChams then pcall(function() oldChams:Destroy() end) end
    end
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
    BackgroundTransparency = 1, Text = "ВЕРСИЯ 0.2 • MULTI-TOOL HUB", TextColor3 = Color3.fromRGB(160, 165, 190),
    TextSize = 12, Font = Enum.Font.GothamMedium, ZIndex = 1001
}, loadingFrame)
local loadingTrack = make("Frame", {
    Size = UDim2.new(0.7, 0, 0, 10), Position = UDim2.new(0.15, 0, 0.56, 0),
    BackgroundColor3 = Color3.fromRGB(39, 42, 58), BorderSizePixel = 0, ZIndex = 1001
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
    BackgroundTransparency = 1, Text = "Подготавливаем интерфейс...", TextColor3 = Color3.fromRGB(160, 165, 190),
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
    background = Color3.fromRGB(13, 15, 22),
    panel = Color3.fromRGB(21, 24, 34),
    panel2 = Color3.fromRGB(29, 33, 46),
    button = Color3.fromRGB(37, 42, 57),
    text = Color3.fromRGB(244, 246, 255),
    muted = Color3.fromRGB(155, 163, 184),
    accent = Color3.fromRGB(105, 115, 255),
    green = Color3.fromRGB(48, 170, 112),
    red = Color3.fromRGB(220, 75, 88)
}

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.92, 0, 0.78, 0),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)
main.Size = UDim2.fromOffset(350, 440)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
corner(main, 18)
stroke(main, Color3.fromRGB(74, 80, 115), 1, 0.15)

-- Compact-first mobile layout. The compact switch makes the whole window smaller,
-- not merely narrower, and the layout remains scrollable on small screens.
local compactMode = false
local function fitPanel()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if compactMode then
        main.Size = UDim2.fromOffset(math.min(252, viewport.X - 20), math.min(326, viewport.Y - 60))
    else
        main.Size = UDim2.fromOffset(math.min(350, viewport.X - 20), math.min(440, viewport.Y - 60))
    end
end
fitPanel()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
end

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0
}, main)
corner(header, 18)

local title = make("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 11, 0, 5),
    Size = UDim2.new(1, -112, 0, 29),
    BackgroundTransparency = 1,
    Text = "RAHERHUB",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 21,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local subtitle = make("TextLabel", {
    Position = UDim2.new(0, 12, 0, 33),
    Size = UDim2.new(1, -105, 0, 16),
    BackgroundTransparency = 1,
    Text = "ЛИЧНАЯ СБОРКА  •  версия " .. VERSION,
    TextColor3 = COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local minimize = make("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 9),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = COLORS.button,
    BorderSizePixel = 0,
    Text = "—",
    TextColor3 = COLORS.text,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, header)
corner(minimize, 10)

local compactButton = make("TextButton", {
    Name = "CompactMode",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -48, 0, 9),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = COLORS.button,
    BorderSizePixel = 0,
    Text = "▣",
    TextColor3 = COLORS.text,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, header)
corner(compactButton, 10)

-- Tiny performance overlay shown when the main menu is collapsed.
-- Tapping the overlay restores the full RAHERHUB menu.
local statsOverlay = make("TextButton", {
    Name = "PerformanceOverlay",
    Visible = false,
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(18, 300),
    Size = UDim2.fromOffset(156, 26),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Text = "FPS --  |  PING --",
    TextColor3 = COLORS.text,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextWrapped = false,
    AutoButtonColor = true,
    ZIndex = 50
}, gui)
corner(statsOverlay, 8)
stroke(statsOverlay, COLORS.accent, 1, 0.1)

local statsService = game:GetService("Stats")
local fpsFrames, fpsElapsed, currentFPS = 0, 0, 0
local function readPing()
    local ping = nil
    pcall(function()
        ping = statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if typeof(ping) == "number" then
        return math.max(0, math.floor(ping + 0.5))
    end
    pcall(function()
        local valueText = statsService.Network.ServerStatsItem["Data Ping"]:GetValueString()
        ping = tonumber(string.match(valueText, "%d+%.?%d*"))
    end)
    return typeof(ping) == "number" and math.max(0, math.floor(ping + 0.5)) or nil
end

RunService.RenderStepped:Connect(function(dt)
    fpsFrames += 1
    fpsElapsed += dt
    if fpsElapsed >= 0.5 then
        currentFPS = math.floor(fpsFrames / fpsElapsed + 0.5)
        local frameDelay = currentFPS > 0 and (1000 / currentFPS) or 0
        local ping = readPing()
        statsOverlay.Text = string.format("%d FPS  |  %s PING", currentFPS, ping and tostring(ping) or "--")
        fpsFrames, fpsElapsed = 0, 0
    end
end)

-- The minimized performance overlay can be moved around the screen.
-- A short tap opens the full menu; dragging only moves the overlay.
local overlayDrag = {
    active = false,
    input = nil,
    startPointer = nil,
    startPosition = nil,
    moved = false,
}
local OVERLAY_DRAG_THRESHOLD = 8
local openMainFromLauncher

local function clampOverlayPosition(x, y)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
    local size = statsOverlay.AbsoluteSize
    x = math.clamp(x, 0, math.max(0, viewport.X - size.X))
    y = math.clamp(y, 0, math.max(0, viewport.Y - size.Y))
    return x, y
end

local function finishOverlayGesture()
    if not overlayDrag.active then return end
    local wasMoved = overlayDrag.moved
    overlayDrag.active = false
    overlayDrag.input = nil
    overlayDrag.startPointer = nil
    overlayDrag.startPosition = nil
    overlayDrag.moved = false

    savedUI.rhPosition = {
        x = statsOverlay.Position.X.Offset,
        y = statsOverlay.Position.Y.Offset,
    }

    if not wasMoved then
        statsOverlay.Visible = false
        if openMainFromLauncher then task.spawn(openMainFromLauncher) else main.Visible = true end
    end
end

statsOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        overlayDrag.active = true
        overlayDrag.input = input
        overlayDrag.startPointer = input.Position
        overlayDrag.startPosition = Vector2.new(statsOverlay.Position.X.Offset, statsOverlay.Position.Y.Offset)
        overlayDrag.moved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not overlayDrag.active then return end
    local isMouseMove = overlayDrag.input and overlayDrag.input.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseMovement
    local isTouchMove = overlayDrag.input and overlayDrag.input.UserInputType == Enum.UserInputType.Touch
        and input == overlayDrag.input
    if not (isMouseMove or isTouchMove) then return end

    local delta = input.Position - overlayDrag.startPointer
    if delta.Magnitude >= OVERLAY_DRAG_THRESHOLD then
        overlayDrag.moved = true
    end
    if overlayDrag.moved then
        local x, y = clampOverlayPosition(overlayDrag.startPosition.X + delta.X, overlayDrag.startPosition.Y + delta.Y)
        statsOverlay.Position = UDim2.fromOffset(x, y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not overlayDrag.active then return end
    local touchEnded = overlayDrag.input and overlayDrag.input.UserInputType == Enum.UserInputType.Touch
        and input == overlayDrag.input
    local mouseEnded = overlayDrag.input and overlayDrag.input.UserInputType == Enum.UserInputType.MouseButton1
        and input.UserInputType == Enum.UserInputType.MouseButton1
    if touchEnded or mouseEnded then
        finishOverlayGesture()
    end
end)

local tabsBar, content, tabLayout, pages, tabButtons
local function applyMenuLayout()
    fitPanel()
    header.Size = UDim2.new(1, 0, 0, compactMode and 50 or 58)
    title.Position = UDim2.new(0, 11, 0, 5)
    title.Size = UDim2.new(1, -112, 0, 29)
    title.TextSize = compactMode and 18 or 21
    subtitle.Visible = not compactMode
    compactButton.Position = UDim2.new(1, compactMode and -45 or -48, 0, compactMode and 7 or 9)
    minimize.Position = UDim2.new(1, compactMode and -7 or -8, 0, compactMode and 7 or 9)
    compactButton.Size = UDim2.fromOffset(compactMode and 31 or 34, compactMode and 31 or 34)
    minimize.Size = UDim2.fromOffset(compactMode and 31 or 34, compactMode and 31 or 34)
    compactButton.Text = compactMode and "↗" or "▣"
    -- Persistent left navigation rail: category names stay in one place on every page.
    tabsBar.Position = UDim2.new(0, 8, 0, compactMode and 58 or 66)
    tabsBar.Size = UDim2.new(0, 78, 1, compactMode and -66 or -76)
    content.Position = UDim2.new(0, 94, 0, compactMode and 58 or 66)
    content.Size = UDim2.new(1, -98, 1, compactMode and -66 or -76)
    tabLayout.Padding = UDim.new(0, 4)
    tabsBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabsBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    for _, button in pairs(tabButtons or {}) do
        button.Size = UDim2.new(1, -5, 0, compactMode and 35 or 39)
        button.TextSize = compactMode and 20 or 22
        button.TextXAlignment = Enum.TextXAlignment.Center
    end
    for _, page in pairs(pages or {}) do
        local layout = page:FindFirstChildOfClass("UIListLayout")
        if layout then layout.Padding = UDim.new(0, compactMode and 5 or 7) end
    end
end
local menuAnimating = false
compactButton.Activated:Connect(function()
    if menuAnimating then return end
    menuAnimating = true
    -- Animate the panel down into the draggable performance overlay.
    local shrink = TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1
    })
    shrink:Play(); shrink.Completed:Wait()
    main.Visible = false
    main.BackgroundTransparency = 0
    statsOverlay.Position = UDim2.fromOffset(savedUI.rhPosition.x or 18, savedUI.rhPosition.y or 300)
    statsOverlay.Size = UDim2.fromOffset(112, 22)
    statsOverlay.Visible = true
    menuAnimating = false
end)

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

-- Circular RAHERHUB launcher portrait. Upload the generated neon logo to Roblox
-- and replace the placeholder ID below with the uploaded image asset ID.
local LAUNCHER_IMAGE = "rbxassetid://126952267001309" -- uploaded RH CHEAT neon logo
local openButton = make("ImageButton", {
    Name = "OpenButton",
    Visible = false,
    Position = UDim2.fromOffset(savedUI.rhPosition.x or 18, savedUI.rhPosition.y or 300),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = Color3.fromRGB(10, 8, 24),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Image = LAUNCHER_IMAGE,
    ScaleType = Enum.ScaleType.Crop,
    AutoButtonColor = true,
    ZIndex = 60
}, gui)
corner(openButton, 29)
local launcherOutline = stroke(openButton, Color3.fromRGB(190, 60, 255), 2, 0)
launcherOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local function closeMainToLauncher()
    if menuAnimating or not main.Visible then return end
    menuAnimating = true
    local tween = TweenService:Create(main, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1
    })
    tween:Play(); tween.Completed:Wait()
    main.Visible = false
    main.BackgroundTransparency = 0
    openButton.Visible = true
    menuAnimating = false
end
openMainFromLauncher = function()
    if menuAnimating then return end
    menuAnimating = true
    openButton.Visible = false
    fitPanel()
    main.Size = UDim2.fromOffset(40, 40)
    main.BackgroundTransparency = 1
    main.Visible = true
    local targetSize = compactMode and UDim2.fromOffset(252, 326) or UDim2.fromOffset(310, 440)
    local camera = workspace.CurrentCamera
    if camera then targetSize = UDim2.fromOffset(math.min(targetSize.X.Offset, camera.ViewportSize.X - 20), math.min(targetSize.Y.Offset, camera.ViewportSize.Y - 60)) end
    local tween = TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize, BackgroundTransparency = 0
    })
    tween:Play(); tween.Completed:Wait()
    menuAnimating = false
end
minimize.Activated:Connect(function()
    task.spawn(closeMainToLauncher)
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
            if not rhMoved then task.spawn(openMainFromLauncher) end
            rhDragging = false
        end
    end)
end

tabsBar = make("ScrollingFrame", {
    Position = UDim2.new(0, 8, 0, 66),
    Size = UDim2.new(0, 78, 1, -76),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.accent,
    ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
}, main)
tabLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabsBar)

pages = {}
tabButtons = {}
local activeTab = "HOME"
content = make("Frame", {
    Position = UDim2.new(0, 12, 0, 138),
    Size = UDim2.new(1, -24, 1, -150),
    BackgroundTransparency = 1
}, main)

local tabNames = {"HOME", "MOVE", "VISUAL", "TELEPORT", "COMPAT", "EDIT", "SETTINGS", "ABOUT"}
local tabCaptions = {HOME = "⌂", MOVE = "↕", VISUAL = "◉", TELEPORT = "➤", COMPAT = "✓", EDIT = "✚", SETTINGS = "⚙", ABOUT = "i"}
for tabIndex, tabName in ipairs(tabNames) do
    local tab = make("TextButton", {
        Name = tabName .. "Tab",
        Size = UDim2.new(1, -5, 0, 39),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Text = tabCaptions[tabName] or tabName,
        TextColor3 = COLORS.muted,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        LayoutOrder = tabIndex
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
        Padding = UDim.new(0, 6),
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

local pageTween
local function selectTab(name)
    if not pages[name] then return end
    activeTab = name
    if pageTween then pageTween:Cancel() end
    for tabName, page in pairs(pages) do
        local selected = tabName == name
        page.Visible = selected
        tabButtons[tabName].BackgroundColor3 = selected and COLORS.accent or COLORS.button
        tabButtons[tabName].TextColor3 = selected and Color3.new(1,1,1) or COLORS.muted
        if selected then
            page.Position = UDim2.fromOffset(7, 0)
            pageTween = TweenService:Create(page, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(0, 0)})
            pageTween:Play()
        else
            page.Position = UDim2.fromOffset(0, 0)
        end
    end
end
for name, button in pairs(tabButtons) do
    button.Activated:Connect(function() selectTab(name) end)
end
applyMenuLayout()

-- Soft hover/press feedback for navigation and controls.
local function animateButton(button)
    if not button:IsA("TextButton") then return end
    local original = button.BackgroundColor3
    button.MouseEnter:Connect(function()
        if button.Parent == tabsBar and activeTab == button.Name:gsub("Tab$", "") then return end
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.panel2}):Play()
    end)
    button.MouseLeave:Connect(function()
        if button.Parent == tabsBar then
            local key = button.Name:gsub("Tab$", "")
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = key == activeTab and COLORS.accent or COLORS.button}):Play()
        else
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = original}):Play()
        end
    end)
end
for _, button in pairs(tabButtons) do animateButton(button) end

local function section(parent, text)
    return make("TextLabel", {
        Size = UDim2.new(1, -2, 0, 19),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.muted,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    }, parent)
end

local function infoCard(parent, heading, body)
    local card = make("Frame", {
        Size = UDim2.new(1, -2, 0, 54),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0
    }, parent)
    corner(card, 13)
    make("TextLabel", {
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 17),
        BackgroundTransparency = 1,
        Text = heading,
        TextColor3 = COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, card)
    make("TextLabel", {
        Position = UDim2.new(0, 10, 0, 24),
        Size = UDim2.new(1, -20, 0, 25),
        BackgroundTransparency = 1,
        Text = body,
        TextWrapped = true,
        TextColor3 = COLORS.muted,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, card)
    return card
end

local statusLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 30),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Text = "RAHERHUB 0.2  |  MULTI-TOOL HUB  |  PRIVATE ALPHA",
    TextColor3 = COLORS.green,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true
}, pages["HOME"])
corner(statusLabel, 11)

section(pages["HOME"], "ПАНЕЛЬ УПРАВЛЕНИЯ")
infoCard(pages["HOME"], "RAHERHUB 0.2 — MULTI-TOOL HUB", "Личная сборка с интерфейсом для телефона и сохранением точек телепорта.")
infoCard(pages["HOME"], "БЫСТРЫЙ СТАРТ", "Используйте левое меню: MOVE — движение, VISUAL — подсветка, TP — точки, EDIT — размещение кнопки FLY.")
infoCard(pages["HOME"], "ХРАНЕНИЕ ТОЧЕК", "Точки сохраняются на устройстве, если среда поддерживает работу с файлами.")

-- Toggle/button factories.
local function makeActionButton(parent, text, callback, height)
    local button = make("TextButton", {
        Size = UDim2.new(1, -2, 0, height or 31),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.text,
        TextSize = 10,
        TextWrapped = true,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, parent)
    corner(button, 12)
    button.Activated:Connect(function(...)
        callback(...)
    end)
    return button
end

local toggleRegistry = {}
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
    local function setValue(value)
        enabled = value and true or false
        paint()
        if callback then callback(enabled) end
    end
    table.insert(toggleRegistry, {label = label, get = function() return enabled end, set = setValue})
    return button, setValue
end

section(pages["MOVE"], "ДВИЖЕНИЕ И ПЕРЕМЕЩЕНИЕ")
infoCard(pages["MOVE"], "Инструменты тестирования", "Используйте инструменты только в своей игре или там, где у вас есть разрешение.")

-- Скорость ходьбы: диапазон 16–1000
local speedEnabled = false
local walkSpeed = 16
local walkSpeedLabel, walkSpeedTrack
local function applyWalkSpeed()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.WalkSpeed = speedEnabled and walkSpeed or 16 end
end
makeToggle(pages["MOVE"], "Ускорение ходьбы", false, function(value)
    speedEnabled = value
    applyWalkSpeed()
    if walkSpeedLabel then walkSpeedLabel.Visible = value end
    if walkSpeedTrack then walkSpeedTrack.Visible = value end
end)
walkSpeedLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 18), BackgroundTransparency = 1,
    Text = "СКОРОСТЬ: " .. walkSpeed, TextColor3 = COLORS.muted,
    TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left
}, pages["MOVE"])
walkSpeedTrack = make("Frame", {
    Size = UDim2.new(1, -2, 0, 22), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0
}, pages["MOVE"])
corner(walkSpeedTrack, 11)
walkSpeedLabel.Visible = false
walkSpeedTrack.Visible = false
local walkSpeedBar = make("Frame", {
    Position = UDim2.new(0, 9, 0.5, -2), Size = UDim2.new(0, 0, 0, 4),
    BackgroundColor3 = COLORS.accent, BorderSizePixel = 0
}, walkSpeedTrack)
corner(walkSpeedBar, 5)
local walkSpeedKnob = make("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
    Size = UDim2.fromOffset(17, 17), BackgroundColor3 = Color3.new(1,1,1),
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
    walkSpeedBar.Size = UDim2.new(alpha, 0, 0, 4)
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

-- ESP suite: screen-space boxes that scale with the character's projected bounds.
-- Box/line colors are deliberately independent from the chams palette.
local espEnabled = false
local espObjects = {}
local espCharacterConnections = {}
local espVisuals = {}
-- NPC/model ESP is kept separate from Player ESP so the stable player path stays intact.
local espNpcVisuals = {}
local espNpcHighlights = {}
local espBoxesEnabled = false
local espLinesEnabled = false
local espChamsEnabled = false
local espColorIndex = 1
local BOX_COLOR = Color3.fromRGB(75, 255, 120)
local LINE_COLOR = Color3.fromRGB(245, 245, 255)
local espPalette = {
    {name = "КРАСНЫЙ", color = Color3.fromRGB(255, 65, 85)},
    {name = "ЗЕЛЁНЫЙ", color = Color3.fromRGB(55, 255, 125)},
    {name = "ГОЛУБОЙ", color = Color3.fromRGB(40, 210, 255)},
    {name = "ФИОЛЕТОВЫЙ", color = Color3.fromRGB(190, 85, 255)},
    {name = "ЖЁЛТЫЙ", color = Color3.fromRGB(255, 220, 55)},
    {name = "БЕЛЫЙ", color = Color3.fromRGB(245, 245, 255)},
}
local function currentESPColor()
    return espPalette[espColorIndex].color
end

local espGui = make("ScreenGui", {
    Name = "RAHERHUB_ESP_OVERLAY", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 100000
})
safeParentGui(espGui)

local function removeESP(player)
    local object = espObjects[player]
    if object then pcall(function() object:Destroy() end) end
    espObjects[player] = nil
end
local function removeESPVisual(player)
    local visual = espVisuals[player]
    if visual then
        if visual.boxFrame then pcall(function() visual.boxFrame:Destroy() end) end
        if visual.line then pcall(function() visual.line:Destroy() end) end
    end
    espVisuals[player] = nil
end
local function ensureESPVisual(player)
    if player == LocalPlayer then return nil end
    local visual = espVisuals[player]
    if visual and visual.boxFrame and visual.boxFrame.Parent and visual.line and visual.line.Parent then return visual end
    removeESPVisual(player)

    local boxFrame = make("Frame", {
        Name = "RaherESPBox_" .. tostring(player.UserId),
        AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false, Active = false, ZIndex = 100001
    }, espGui)
    local boxStroke = stroke(boxFrame, BOX_COLOR, 1, 0)
    local line = make("Frame", {
        Name = "RaherESPLine_" .. tostring(player.UserId),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = LINE_COLOR, BorderSizePixel = 0,
        Visible = false, Active = false, ZIndex = 100000
    }, espGui)
    visual = {boxFrame = boxFrame, boxStroke = boxStroke, line = line}
    espVisuals[player] = visual
    return visual
end
local function isPlayerCharacterModel(model)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character == model then return true end
    end
    return false
end

-- Friendly-fire filter. Prefer explicit Team/TeamColor data; for NPCs also
-- recognize common faction/team attributes and BoolValue markers.
local function getTeamIdentity(instance)
    if not instance then return nil end
    local team = instance:FindFirstChild("Team")
    if team and team:IsA("ObjectValue") and team.Value then
        return "team:" .. team.Value.Name
    elseif team and (team:IsA("StringValue") or team:IsA("IntValue") or team:IsA("NumberValue")) then
        return "team:" .. tostring(team.Value)
    end
    for _, key in ipairs({"Team", "TeamName", "Faction", "FactionName", "Side", "Camp"}) do
        local value = instance:GetAttribute(key)
        if value ~= nil and tostring(value) ~= "" then
            return string.lower(key) .. ":" .. tostring(value)
        end
    end
    return nil
end
local function hasFriendlyMarker(model)
    if not model then return false end
    for _, key in ipairs({"IsAlly", "IsFriendly", "Friendly", "Ally", "IsTeammate"}) do
        if model:GetAttribute(key) == true then return true end
        local marker = model:FindFirstChild(key, true)
        if marker and marker:IsA("BoolValue") and marker.Value then return true end
    end
    return false
end
local function isAllyPlayer(player)
    if not player or player == LocalPlayer then return true end
    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return true end
    -- TeamColor is only trusted when both players are assigned to non-neutral teams.
    if not LocalPlayer.Neutral and not player.Neutral
        and LocalPlayer.TeamColor and player.TeamColor
        and LocalPlayer.TeamColor == player.TeamColor then return true end
    local mine, theirs = getTeamIdentity(LocalPlayer), getTeamIdentity(player)
    return mine ~= nil and theirs ~= nil and mine == theirs
end
local function isAllyNPC(model)
    if hasFriendlyMarker(model) then return true end
    local mine, theirs = getTeamIdentity(LocalPlayer), getTeamIdentity(model)
    if mine ~= nil and theirs ~= nil and mine == theirs then return true end
    -- A humanoid model may carry its team/faction marker on a descendant.
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ObjectValue") and descendant.Name == "Team" and descendant.Value then
            local team = LocalPlayer.Team
            if team and descendant.Value == team then return true end
            if team and descendant.Value.Name == team.Name then return true end
        elseif (descendant:IsA("StringValue") or descendant:IsA("IntValue"))
            and (descendant.Name == "Team" or descendant.Name == "Faction" or descendant.Name == "Side") then
            local value = tostring(descendant.Value)
            local localValue = getTeamIdentity(LocalPlayer)
            if localValue and string.lower(localValue) == string.lower(descendant.Name .. ":" .. value) then return true end
        end
    end
    return false
end
local function getModelRoot(model)
    if not model or not model:IsA("Model") then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model:FindFirstChildWhichIsA("BasePart")
end
-- Stable 2D box based on character head/root, rather than GetBoundingBox corners.
-- GetBoundingBox may briefly return incomplete/rotated bounds while rigs stream or animate.
local function projectModelRect(model, root, humanoid, camera, viewport)
    if not model or not root or not humanoid or not camera then return nil end
    local head = model:FindFirstChild("Head")
    local topWorld
    if head and head:IsA("BasePart") then
        topWorld = head.Position + Vector3.new(0, head.Size.Y * 0.55, 0)
    else
        topWorld = root.Position + Vector3.new(0, math.max(2.5, humanoid.HipHeight + root.Size.Y * 1.8), 0)
    end
    local bottomWorld = root.Position - Vector3.new(0, math.max(1, humanoid.HipHeight + root.Size.Y * 0.5), 0)
    local top = camera:WorldToViewportPoint(topWorld)
    local bottom = camera:WorldToViewportPoint(bottomWorld)
    if top.Z <= 0 or bottom.Z <= 0 then return nil end
    local height = math.abs(bottom.Y - top.Y)
    if height < 4 then return nil end
    local width = math.max(3, height * 0.42)
    local centerX = (top.X + bottom.X) * 0.5
    local minX, maxX = centerX - width * 0.5, centerX + width * 0.5
    local minY, maxY = math.min(top.Y, bottom.Y), math.max(top.Y, bottom.Y)
    if maxX < 0 or minX > viewport.X or maxY < 0 or minY > viewport.Y then return nil end
    minX, maxX = math.clamp(minX, 0, viewport.X), math.clamp(maxX, 0, viewport.X)
    minY, maxY = math.clamp(minY, 0, viewport.Y), math.clamp(maxY, 0, viewport.Y)
    if maxX <= minX or maxY <= minY then return nil end
    return minX, minY, maxX, maxY
end
local function removeNPCESP(model)
    local visual = espNpcVisuals[model]
    if visual then
        if visual.boxFrame then pcall(function() visual.boxFrame:Destroy() end) end
        if visual.line then pcall(function() visual.line:Destroy() end) end
        espNpcVisuals[model] = nil
    end
    local highlight = espNpcHighlights[model]
    if highlight then pcall(function() highlight:Destroy() end) end
    espNpcHighlights[model] = nil
end
local function ensureNPCVisual(model)
    local visual = espNpcVisuals[model]
    if visual and visual.boxFrame and visual.boxFrame.Parent and visual.line and visual.line.Parent then return visual end
    if visual then removeNPCESP(model) end
    local suffix = tostring(model:GetFullName()):gsub("[^%w]", "")
    local boxFrame = make("Frame", {
        Name = "RaherESPBox_NPC_" .. suffix, AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
        Active = false, ZIndex = 100001
    }, espGui)
    local boxStroke = stroke(boxFrame, BOX_COLOR, 1, 0)
    local line = make("Frame", {
        Name = "RaherESPLine_NPC_" .. suffix, AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = LINE_COLOR, BorderSizePixel = 0, Visible = false,
        Active = false, ZIndex = 100000
    }, espGui)
    visual = {boxFrame = boxFrame, boxStroke = boxStroke, line = line}
    espNpcVisuals[model] = visual
    return visual
end
local function refreshESPColors()
    local color = currentESPColor()
    -- The palette controls chams only. Boxes and tracers stay visually distinct.
    for _, highlight in pairs(espObjects) do
        if highlight and highlight.Parent then
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.Enabled = espEnabled and espChamsEnabled
        end
    end
    for _, highlight in pairs(espNpcHighlights) do
        if highlight and highlight.Parent then
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.Enabled = espEnabled and espChamsEnabled
        end
    end
end
local function createESP(player)
    if not espEnabled or player == LocalPlayer then return end
    if isAllyPlayer(player) then
        removeESP(player)
        local oldVisual = espVisuals[player]
        if oldVisual then
            if oldVisual.boxFrame then oldVisual.boxFrame.Visible = false end
            if oldVisual.line then oldVisual.line.Visible = false end
        end
        return
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not character.Parent or not root or not humanoid or humanoid.Health <= 0 then
        removeESP(player)
        local oldVisual = espVisuals[player]
        if oldVisual then
            if oldVisual.boxFrame then oldVisual.boxFrame.Visible = false end
            if oldVisual.line then oldVisual.line.Visible = false end
        end
        return
    end

    ensureESPVisual(player)
    if espChamsEnabled then
        local existing = espObjects[player]
        if not (existing and existing.Parent and existing.Adornee == character) then
            removeESP(player)
            local highlight = Instance.new("Highlight")
            highlight.Name = "RaherESPChams"
            highlight.FillColor = currentESPColor()
            highlight.OutlineColor = currentESPColor()
            highlight.FillTransparency = 0.48
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Enabled = true
            highlight.Parent = espGui
            espObjects[player] = highlight
        else
            existing.Enabled = true
            existing.FillColor = currentESPColor()
            existing.OutlineColor = currentESPColor()
        end
    else
        removeESP(player)
    end
end
local function bindESPPlayer(player)
    if player == LocalPlayer or espCharacterConnections[player] then return end
    espCharacterConnections[player] = player.CharacterAdded:Connect(function(character)
        task.spawn(function()
            for _ = 1, 40 do
                if not espEnabled or player.Parent ~= Players then return end
                if player.Character == character and character.Parent
                    and character:FindFirstChild("HumanoidRootPart")
                    and character:FindFirstChildOfClass("Humanoid") then
                    createESP(player)
                    return
                end
                task.wait(0.25)
            end
        end)
    end)
    if player.Character then task.defer(function() createESP(player) end) end
end
local function updateESP()
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                bindESPPlayer(player)
                createESP(player)
            end
        end
    else
        for player in pairs(espObjects) do removeESP(player) end
        for _, visual in pairs(espVisuals) do
            if visual.boxFrame then visual.boxFrame.Visible = false end
            if visual.line then visual.line.Visible = false end
        end
    end
end
Players.PlayerAdded:Connect(function(player)
    bindESPPlayer(player)
    if espEnabled then task.defer(function() createESP(player) end) end
end)
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    removeESPVisual(player)
    local connection = espCharacterConnections[player]
    if connection then connection:Disconnect() end
    espCharacterConnections[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do bindESPPlayer(player) end

-- Project the real 3D character bounds every frame. This makes boxes shrink with distance.
local lastESPReconcile = 0
RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not espEnabled or not camera then
        for _, visual in pairs(espVisuals) do
            if visual.boxFrame then visual.boxFrame.Visible = false end
            if visual.line then visual.line.Visible = false end
        end
        return
    end
    local viewport = camera.ViewportSize
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if isAllyPlayer(player) then
                removeESP(player)
                local friendlyVisual = espVisuals[player]
                if friendlyVisual then
                    if friendlyVisual.boxFrame then friendlyVisual.boxFrame.Visible = false end
                    if friendlyVisual.line then friendlyVisual.line.Visible = false end
                end
            else
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local visual = ensureESPVisual(player)
            if visual then
                local valid = root and humanoid and humanoid.Health > 0 and character.Parent
                local showBox, showLine = false, false
                if valid and espBoxesEnabled then
                    local minX, minY, maxX, maxY = projectModelRect(character, root, humanoid, camera, viewport)
                    if minX then
                        visual.boxFrame.Position = UDim2.fromOffset(minX, minY)
                        visual.boxFrame.Size = UDim2.fromOffset(math.max(1, maxX - minX), math.max(1, maxY - minY))
                        visual.boxFrame.Visible = true
                        visual.boxStroke.Color = BOX_COLOR
                        showBox = true
                    end
                end
                if not showBox then visual.boxFrame.Visible = false end
                if valid and espLinesEnabled then
                    local point = camera:WorldToViewportPoint(root.Position)
                    showLine = point.Z > 0 and point.X >= 0 and point.X <= viewport.X and point.Y >= 0 and point.Y <= viewport.Y
                    if showLine then
                        local fromX, fromY = viewport.X / 2, viewport.Y - 2
                        local toX, toY = point.X, point.Y
                        local dx, dy = toX - fromX, toY - fromY
                        visual.line.Position = UDim2.fromOffset((fromX + toX) / 2, (fromY + toY) / 2)
                        visual.line.Size = UDim2.fromOffset(math.max(1, math.sqrt(dx*dx + dy*dy)), 1)
                        visual.line.Rotation = math.deg(math.atan2(dy, dx))
                        visual.line.BackgroundColor3 = LINE_COLOR
                    end
                end
                visual.line.Visible = showLine
            end
            end -- not an ally
        end
    end
    -- NPC/model targets: scan Workspace periodically, excluding all actual Player characters.
    if os.clock() - lastESPReconcile > 1 then
        lastESPReconcile = os.clock()
        updateESP()
        if espEnabled then
            local seen = {}
            for _, descendant in ipairs(workspace:GetDescendants()) do
                if descendant:IsA("Model") and descendant.Parent and not isPlayerCharacterModel(descendant)
                    and not isAllyNPC(descendant) then
                    local humanoid = descendant:FindFirstChildOfClass("Humanoid")
                    local root = getModelRoot(descendant)
                    if humanoid and humanoid.Health > 0 and root then
                        seen[descendant] = true
                        local visual = ensureNPCVisual(descendant)
                        if espChamsEnabled then
                            local highlight = espNpcHighlights[descendant]
                            if not (highlight and highlight.Parent and highlight.Adornee == descendant) then
                                if highlight then pcall(function() highlight:Destroy() end) end
                                highlight = Instance.new("Highlight")
                                highlight.Name = "RaherESPChams_NPC"
                                highlight.Adornee = descendant
                                highlight.FillColor = currentESPColor()
                                highlight.OutlineColor = currentESPColor()
                                highlight.FillTransparency = 0.48
                                highlight.OutlineTransparency = 0
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.Parent = espGui
                                espNpcHighlights[descendant] = highlight
                            end
                            highlight.Enabled = true
                        else
                            local highlight = espNpcHighlights[descendant]
                            if highlight then pcall(function() highlight:Destroy() end) end
                            espNpcHighlights[descendant] = nil
                        end
                    end
                end
            end
            for model in pairs(espNpcVisuals) do
                if not seen[model] or not model.Parent then removeNPCESP(model) end
            end
            for model in pairs(espNpcHighlights) do
                if not seen[model] or not model.Parent then
                    pcall(function() espNpcHighlights[model]:Destroy() end)
                    espNpcHighlights[model] = nil
                end
            end
        else
            for model in pairs(espNpcVisuals) do removeNPCESP(model) end
            for model in pairs(espNpcHighlights) do
                pcall(function() espNpcHighlights[model]:Destroy() end)
                espNpcHighlights[model] = nil
            end
        end
    end
    -- Update NPC screen-space visuals every frame using model bounds.
    for model, visual in pairs(espNpcVisuals) do
        local humanoid = model and model.Parent and model:FindFirstChildOfClass("Humanoid")
        local root = getModelRoot(model)
        local valid = espEnabled and humanoid and humanoid.Health > 0 and root
        local showBox, showLine = false, false
        if valid and espBoxesEnabled then
            local minX, minY, maxX, maxY = projectModelRect(model, root, humanoid, camera, viewport)
            if minX then
                visual.boxFrame.Position = UDim2.fromOffset(minX, minY)
                visual.boxFrame.Size = UDim2.fromOffset(math.max(1, maxX-minX), math.max(1, maxY-minY))
                visual.boxFrame.Visible = true
                visual.boxStroke.Color = BOX_COLOR
                showBox = true
            end
        end
        if not showBox then visual.boxFrame.Visible = false end
        if valid and espLinesEnabled then
            local point = camera:WorldToViewportPoint(root.Position)
            showLine = point.Z > 0 and point.X >= 0 and point.X <= viewport.X and point.Y >= 0 and point.Y <= viewport.Y
            if showLine then
                local fromX, fromY = viewport.X/2, viewport.Y-2
                local dx, dy = point.X-fromX, point.Y-fromY
                visual.line.Position = UDim2.fromOffset((fromX+point.X)/2,(fromY+point.Y)/2)
                visual.line.Size = UDim2.fromOffset(math.max(1,math.sqrt(dx*dx+dy*dy)),1)
                visual.line.Rotation = math.deg(math.atan2(dy,dx)); visual.line.BackgroundColor3 = LINE_COLOR
            end
        end
        visual.line.Visible = showLine
    end
end)

makeToggle(pages["VISUAL"], "ESP — ВКЛЮЧИТЬ ВСЁ", false, function(value)
    espEnabled = value
    updateESP()
end)
local espBoxesToggleButton, espLinesToggleButton, espChamsToggleButton
local espBoxesToggleSetter, espLinesToggleSetter, espChamsToggleSetter
espBoxesToggleButton, espBoxesToggleSetter = makeToggle(pages["VISUAL"], "ESP: БОКСЫ", false, function(value)
    espBoxesEnabled = value
    for _, visual in pairs(espVisuals) do if visual.boxFrame then visual.boxFrame.Visible = espEnabled and value end end
end)
espLinesToggleButton, espLinesToggleSetter = makeToggle(pages["VISUAL"], "ESP: ЛИНИИ К ИГРОКАМ", false, function(value)
    espLinesEnabled = value
    if not value then for _, visual in pairs(espVisuals) do if visual.line then visual.line.Visible = false end end end
end)
espChamsToggleButton, espChamsToggleSetter = makeToggle(pages["VISUAL"], "ESP: ЧАМСЫ / ПОДСВЕТКА", false, function(value)
    espChamsEnabled = value
    if not value then
        for player in pairs(espObjects) do removeESP(player) end
        for model in pairs(espNpcHighlights) do pcall(function() espNpcHighlights[model]:Destroy() end); espNpcHighlights[model] = nil end
    elseif espEnabled then
        updateESP()
    end
end)
local espColorButton
local function paintESPColorButton()
    if espColorButton then
        espColorButton.Text = "ЦВЕТ ESP: " .. espPalette[espColorIndex].name .. "  ›"
        espColorButton.BackgroundColor3 = currentESPColor()
        espColorButton.TextColor3 = (espColorIndex == 2 or espColorIndex == 5 or espColorIndex == 6) and Color3.fromRGB(20,20,25) or Color3.new(1,1,1)
    end
end
espColorButton = makeActionButton(pages["VISUAL"], "", function()
    espColorIndex = espColorIndex % #espPalette + 1
    paintESPColorButton()
    refreshESPColors()
end, 34)
paintESPColorButton()
infoCard(pages["VISUAL"], "НАСТРОЙКА ESP", "Выбери цвет кнопкой выше. Боксы обводят персонажа, линии ведут от нижней части экрана, чамсы подсвечивают модель.")

-- Triggerbot for testing: fires the equipped Tool when the center-screen ray
-- hits a living NPC or another Player character. Player characters are allowed
-- even if they are teammates, so a friend can be used for private testing.
local triggerBotEnabled = false
local triggerBotLastShot = 0
local triggerBotCooldown = 0.14
local triggerBotRange = 1000
local triggerBotToggleSetter
local _, triggerBotToggleSetterLocal = makeToggle(pages["VISUAL"], "TRIGGERBOT: ИГРОКИ + БОТЫ", false, function(value)
    triggerBotEnabled = value
    triggerBotLastShot = 0
end)
triggerBotToggleSetter = triggerBotToggleSetterLocal
infoCard(pages["VISUAL"], "TRIGGERBOT", "Автоматически активирует экипированное оружие при наведении по центру экрана на живого игрока или NPC. Игроки, включая союзников, тоже являются целями для тестирования.")

RunService.Heartbeat:Connect(function()
    if not triggerBotEnabled then return end
    local now = os.clock()
    if now - triggerBotLastShot < triggerBotCooldown then return end

    local camera = workspace.CurrentCamera
    if not camera then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local tool
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then tool = child break end
    end
    if not tool then return end

    local viewport = camera.ViewportSize
    local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.IgnoreWater = true
    local result = workspace:Raycast(ray.Origin, ray.Direction * triggerBotRange, params)
    if not result or not result.Instance then return end

    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if not model or not model.Parent then return end
    local isPlayerTarget = isPlayerCharacterModel(model)
    if not isPlayerTarget and isAllyNPC(model) then return end
    local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then return end

    -- Tool:Activate() is the standard Roblox client-side tool activation path.
    -- Games that fire through custom remotes may require their own weapon adapter.
    local ok = pcall(function() tool:Activate() end)
    if ok then triggerBotLastShot = now end
end)

local coordinateHud = make("TextLabel", {
    Name = "CoordinateHUD", Visible = false, AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(18, 334), Size = UDim2.fromOffset(190, 24),
    BackgroundColor3 = COLORS.panel, BackgroundTransparency = 0.08, BorderSizePixel = 0,
    Text = "X --  Y --  Z --", TextColor3 = COLORS.text, TextSize = 10,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 49
}, gui)
corner(coordinateHud, 8)
stroke(coordinateHud, COLORS.accent, 1, 0.12)
local coordsEnabled = false
makeToggle(pages["VISUAL"], "Координаты персонажа", false, function(value)
    coordsEnabled = value
    coordinateHud.Visible = value
end)
local lastCoordsUpdate = 0
RunService.RenderStepped:Connect(function()
    if not coordsEnabled or os.clock() - lastCoordsUpdate < 0.15 then return end
    lastCoordsUpdate = os.clock()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local p = root.Position
        coordinateHud.Text = string.format("X %.1f   Y %.1f   Z %.1f", p.X, p.Y, p.Z)
    else
        coordinateHud.Text = "Координаты недоступны"
    end
end)

-- FLY: one floating button. Hold to rise; release to fall. Drag it in edit mode.
local flyTouch
local flyEditMode = false
local flyHeld = false
local flyEnabled = false
local flySpeed = 4
local speedLabel, speedTrack
local flyDragState = {dragging = false, start = nil, startPos = nil, input = nil}

makeToggle(pages["MOVE"], "Полёт (удерживать для подъёма)", false, function(value)
    flyEnabled = value
    if not value then flyHeld = false end
    if speedLabel then speedLabel.Visible = value end
    if speedTrack then speedTrack.Visible = value end
    if flyTouch then
        flyTouch.Visible = flyEditMode or flyEnabled
    end
end)

speedLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 18),
    BackgroundTransparency = 1,
    Text = "СИЛА ПОЛЁТА: 4",
    TextColor3 = COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, pages["MOVE"])
speedTrack = make("Frame", {
    Size = UDim2.new(1, -2, 0, 22),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0
}, pages["MOVE"])
corner(speedTrack, 11)
speedLabel.Visible = false
speedTrack.Visible = false
local speedBar = make("Frame", {
    Position = UDim2.new(0, 10, 0.5, -4),
    Size = UDim2.new((flySpeed - 1) / 19, 0, 0, 4),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0
}, speedTrack)
corner(speedBar, 5)
local speedKnob = make("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new((flySpeed - 1) / 19, 10, 0.5, 0),
    Size = UDim2.fromOffset(17, 17),
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
    speedBar.Size = UDim2.new(alpha, 0, 0, 4)
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

section(pages["MOVE"], "БЫСТРЫЕ ПРОФИЛИ")
local presetRow = make("Frame", {Size = UDim2.new(1, -2, 0, 34), BackgroundTransparency = 1}, pages["MOVE"])
local presetLayout = make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, presetRow)
local function movementPreset(label, walk, fly)
    local button = make("TextButton", {Size = UDim2.new(1/3, -4, 1, 0), BackgroundColor3 = COLORS.button, BorderSizePixel = 0, Text = label, TextColor3 = COLORS.text, TextSize = 9, Font = Enum.Font.GothamBold}, presetRow)
    corner(button, 9)
    button.Activated:Connect(function()
        walkSpeed = walk
        flySpeed = fly
        if walkSpeedLabel then walkSpeedLabel.Text = "СКОРОСТЬ: " .. walkSpeed end
        if speedLabel then speedLabel.Text = "СИЛА ПОЛЁТА: " .. flySpeed end
        if walkSpeedBar and walkSpeedTrack then
            local a = (walkSpeed - 16) / (1000 - 16)
            walkSpeedBar.Size = UDim2.new(a, 0, 0, 4)
            walkSpeedKnob.Position = UDim2.new(a, 10, 0.5, 0)
        end
        if speedBar and speedKnob then
            local a = (flySpeed - 1) / 19
            speedBar.Size = UDim2.new(a, 0, 0, 4)
            speedKnob.Position = UDim2.new(a, 10, 0.5, 0)
        end
        if speedEnabled then applyWalkSpeed() end
    end)
end
movementPreset("SLOW", 32, 3)
movementPreset("NORMAL", 80, 8)
movementPreset("FAST", 160, 16)

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

local _, setFlyEditToggle = makeToggle(pages["EDIT"], "Редактировать кнопку FLY", false, function(value)
    flyEditMode = value
    flyHeld = false
    if flyTouch then
        flyTouch.Text = value and "ПЕРЕМЕСТИ" or "FLY"
        flyTouch.Visible = value or flyEnabled
    end
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
makeToggle(pages["MOVE"], "Проход сквозь объекты (Noclip)", false, function(value)
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

-- Keep the single FLY button visible across every tab and while the menu is minimized, as long as FLY is enabled or edit mode is active.
local function updateFlyButton()
    if not flyTouch then return end
    flyTouch.Visible = flyEditMode or flyEnabled
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
        return false
    end
    local ok, raw = pcall(function() return HttpService:JSONEncode(teleportPoints) end)
    if not ok then return false end
    local writeOK = pcall(writefile, POINTS_FILE, raw)
    return writeOK
end
loadPoints()

local lastTeleportCFrame = nil
local function teleportToPosition(position)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    lastTeleportCFrame = root.CFrame
    root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    return true
end

section(pages["TELEPORT"], "УПРАВЛЕНИЕ ТОЧКАМИ")
infoCard(pages["TELEPORT"], "Сохранённые места", "Сохраните текущее место, чтобы позже вернуться к нему.")
makeActionButton(pages["TELEPORT"], "↩ TELEPORT BACK — ВЕРНУТЬСЯ", function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and lastTeleportCFrame then
        local current = root.CFrame
        root.CFrame = lastTeleportCFrame
        lastTeleportCFrame = current
    end
end)
local pointNameBox = make("TextBox", {
    Size = UDim2.new(1, -2, 0, 34),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Название точки (например, Дом)",
    PlaceholderColor3 = COLORS.muted,
    TextColor3 = COLORS.text,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, pages["TELEPORT"])
corner(pointNameBox, 12)

local pointsList = make("Frame", {
    Size = UDim2.new(1, -2, 0, 8),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1
}, pages["TELEPORT"])
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, pointsList)

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
            Size = UDim2.new(1, -2, 0, 70),
            BackgroundColor3 = COLORS.panel,
            BorderSizePixel = 0,
            LayoutOrder = index
        }, pointsList)
        corner(row, 12)
        make("TextLabel", {
            Position = UDim2.new(0, 11, 0, 8),
            Size = UDim2.new(1, -22, 0, 17),
            BackgroundTransparency = 1,
            Text = point.name,
            TextColor3 = COLORS.text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, row)
        make("TextLabel", {
            Position = UDim2.new(0, 11, 0, 25),
            Size = UDim2.new(1, -22, 0, 13),
            BackgroundTransparency = 1,
            Text = string.format("X %.1f   Y %.1f   Z %.1f", point.x, point.y, point.z),
            TextColor3 = COLORS.muted,
            TextSize = 10,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)
        local go = make("TextButton", {
            Position = UDim2.new(0, 9, 0, 43),
            Size = UDim2.new(0.67, -8, 0, 22),
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
                return
            end
            -- Local character movement: use only in your own place / authorized tests.
            lastTeleportCFrame = root.CFrame
            root.CFrame = CFrame.new(point.x, point.y + 3, point.z)
        end)
        local delete = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -9, 0, 43),
            Size = UDim2.new(0.33, -5, 0, 22),
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
        return
    end
    local name = pointNameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "Точка " .. tostring(#teleportPoints + 1) end
    for _, point in ipairs(teleportPoints) do
        if point.name:lower() == name:lower() then
            return
        end
    end
    local pos = root.Position
    table.insert(teleportPoints, {name = name, x = pos.X, y = pos.Y, z = pos.Z})
    local saved = savePoints()
    pointNameBox.Text = ""
    refreshPoints()
end)

makeActionButton(pages["TELEPORT"], "УДАЛИТЬ ВСЕ ТОЧКИ", function()
    table.clear(teleportPoints)
    savePoints()
    refreshPoints()
end)

-- SETTINGS: customize both independently draggable flight controls.
makeActionButton(pages["EDIT"], "СБРОСИТЬ ПОЗИЦИЮ FLY", function()
    savedUI.flyPosition = {x = -24, y = -150}
    flyTouch.Position = UDim2.new(1, -24, 1, -150)
end)

makeActionButton(pages["EDIT"], "ГОТОВО — ВЫЙТИ ИЗ РЕДАКТОРА", function()
    flyEditMode = false
    flyTouch.Text = "FLY"
    if setFlyEditToggle then setFlyEditToggle(false) end
    updateFlyButton()
end)

section(pages["SETTINGS"], "ВНЕШНИЙ ВИД")
infoCard(pages["SETTINGS"], "Настройка кнопок FLY", "Изменяйте размер и прозрачность кнопки FLY. Позиция настраивается во вкладке EDIT.")

local function createSettingSlider(parent, titleText, minValue, maxValue, initialValue, formatter, onChange)
    local wrap = make("Frame", {
        Size = UDim2.new(1, -2, 0, 54),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0
    }, parent)
    corner(wrap, 12)

    local label = make("TextLabel", {
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 0, 17),
        BackgroundTransparency = 1,
        Text = titleText .. ": " .. formatter(initialValue),
        TextColor3 = COLORS.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, wrap)

    local track = make("Frame", {
        Position = UDim2.new(0, 10, 0, 32),
        Size = UDim2.new(1, -20, 0, 7),
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
    local function setValue(value)
        value = math.clamp(math.floor(value + 0.5), minValue, maxValue)
        local ratio = (value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        label.Text = titleText .. ": " .. formatter(value)
        onChange(value)
    end
    local function setValueFromX(x)
        local left = track.AbsolutePosition.X
        local width = math.max(1, track.AbsoluteSize.X)
        local ratio = math.clamp((x - left) / width, 0, 1)
        setValue(math.floor(minValue + ratio * (maxValue - minValue) + 0.5))
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
    return setValue
end

local function applyFlyAppearance()
    flyTouch.Size = UDim2.fromOffset(savedUI.flySize, savedUI.flySize)
    flyTouch.TextSize = math.floor(savedUI.flySize * 0.25)
    flyTouch.BackgroundTransparency = savedUI.flyOpacity
end

local setFlySizeSetting = createSettingSlider(pages["SETTINGS"], "Размер кнопки FLY", 44, 110, savedUI.flySize, function(v) return tostring(v) .. " px" end, function(value)
    savedUI.flySize = value
    applyFlyAppearance()
end)

local setFlyOpacitySetting = createSettingSlider(pages["SETTINGS"], "Прозрачность кнопки FLY", 0, 85, math.floor(savedUI.flyOpacity * 100 + 0.5), function(v) return tostring(v) .. "%" end, function(value)
    savedUI.flyOpacity = value / 100
    applyFlyAppearance()
end)

makeActionButton(pages["SETTINGS"], "СБРОСИТЬ РАЗМЕР И ПРОЗРАЧНОСТЬ", function()
    savedUI.flySize = 66
    savedUI.flyOpacity = 0.12
    applyFlyAppearance()
end)

section(pages["EDIT"], "РЕДАКТОР ЭЛЕМЕНТОВ")
infoCard(pages["EDIT"], "Перемещение кнопки FLY", "Включи режим редактирования, затем перетащи кнопку FLY в удобное место. Отключи режим, чтобы снова использовать полёт.")
section(pages["ABOUT"], "О ПРОЕКТЕ")
infoCard(pages["ABOUT"], "RAHERHUB 0.2 — MULTI-TOOL HUB", "Личная сборка. Стабильная сборка №3.")

-- Developer contact card: Telegram icon, link, copy action, and mobile fallback.
local TELEGRAM_LINK = "https://t.me/generalvaneska2024"
local TELEGRAM_ICON = "rbxassetid://138727397408628"
local contactCard = make("Frame", {
    Name = "DeveloperContactCard",
    Size = UDim2.new(1, -2, 0, 112),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, pages["ABOUT"])
corner(contactCard, 13)
stroke(contactCard, COLORS.accent, 1.2, 0.12)

local telegramIcon = make("ImageLabel", {
    Name = "TelegramIcon",
    Position = UDim2.fromOffset(10, 12),
    Size = UDim2.fromOffset(34, 34),
    BackgroundTransparency = 1,
    Image = TELEGRAM_ICON,
    ScaleType = Enum.ScaleType.Fit
}, contactCard)

make("TextLabel", {
    Position = UDim2.fromOffset(52, 9),
    Size = UDim2.new(1, -62, 0, 18),
    BackgroundTransparency = 1,
    Text = "TELEGRAM",
    TextColor3 = COLORS.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, contactCard)
make("TextLabel", {
    Position = UDim2.fromOffset(52, 26),
    Size = UDim2.new(1, -62, 0, 16),
    BackgroundTransparency = 1,
    Text = "CONTACT THE DEVELOPER",
    TextColor3 = COLORS.muted,
    TextSize = 8,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, contactCard)

local telegramUrlBox = make("TextBox", {
    Name = "TelegramLink",
    Position = UDim2.fromOffset(10, 52),
    Size = UDim2.new(1, -112, 0, 27),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    Text = TELEGRAM_LINK,
    TextColor3 = Color3.fromRGB(170, 185, 255),
    TextSize = 9,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center,
    ClearTextOnFocus = false,
    TextEditable = true,
    TextTruncate = Enum.TextTruncate.AtEnd
}, contactCard)
corner(telegramUrlBox, 8)
stroke(telegramUrlBox, COLORS.accent, 1, 0.45)

local copyTelegramButton = make("TextButton", {
    Name = "CopyTelegramLink",
    Position = UDim2.new(1, -94, 0, 52),
    Size = UDim2.fromOffset(84, 27),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Text = "COPY LINK",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, contactCard)
corner(copyTelegramButton, 8)

local telegramToast = make("TextLabel", {
    Name = "TelegramStatus",
    Position = UDim2.fromOffset(10, 84),
    Size = UDim2.new(1, -20, 0, 18),
    BackgroundTransparency = 1,
    Text = "Tap the link to select and copy manually if needed.",
    TextColor3 = COLORS.muted,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true
}, contactCard)

local telegramToastToken = 0
local function showTelegramStatus(message, color)
    telegramToastToken += 1
    local token = telegramToastToken
    telegramToast.Text = message
    telegramToast.TextColor3 = color or COLORS.muted
    telegramToast.TextTransparency = 0
    task.delay(3, function()
        if token == telegramToastToken and telegramToast.Parent then
            TweenService:Create(telegramToast, TweenInfo.new(0.2), {TextTransparency = 0.35}):Play()
        end
    end)
end

copyTelegramButton.Activated:Connect(function()
    local copied = false
    -- Clipboard functions are executor-specific; try only if the environment exposes one.
    local clipboardFunctions = {}
    if type(setclipboard) == "function" then table.insert(clipboardFunctions, setclipboard) end
    if type(toclipboard) == "function" then table.insert(clipboardFunctions, toclipboard) end
    local okGetEnv, env = pcall(function()
        if type(getgenv) == "function" then return getgenv() end
        return _G
    end)
    if okGetEnv and type(env) == "table" then
        if type(env.setclipboard) == "function" then table.insert(clipboardFunctions, env.setclipboard) end
        if type(env.toclipboard) == "function" then table.insert(clipboardFunctions, env.toclipboard) end
    end
    for _, clipboardFunction in ipairs(clipboardFunctions) do
        local ok = pcall(clipboardFunction, TELEGRAM_LINK)
        if ok then copied = true break end
    end

    if copied then
        showTelegramStatus("TELEGRAM LINK COPIED!", COLORS.green)
    else
        telegramUrlBox:CaptureFocus()
        telegramUrlBox.CursorPosition = #TELEGRAM_LINK + 1
        telegramUrlBox.SelectionStart = 1
        showTelegramStatus("Select the link above and copy it manually.", COLORS.accent)
    end
    TweenService:Create(copyTelegramButton, TweenInfo.new(0.08), {BackgroundColor3 = COLORS.green}):Play()
    task.delay(0.18, function()
        if copyTelegramButton.Parent then
            TweenService:Create(copyTelegramButton, TweenInfo.new(0.16), {BackgroundColor3 = COLORS.accent}):Play()
        end
    end)
end)

infoCard(pages["ABOUT"], "Навигация", "HOME — быстрые действия; MOVE — движение; VISUAL — HUD/FOV/ESP; TELEPORT — точки; SETTINGS — профили.")
infoCard(pages["ABOUT"], "Совместимость", "Некоторые функции зависят от доступных возможностей среды и прав в текущем Roblox-проекте.")

-- Camera FOV control; restores the original FOV when disabled/reset.
local cameraFovOriginal = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70
local cameraFovEnabled = false
makeToggle(pages["VISUAL"], "Настройка угла обзора (FOV)", false, function(value)
    cameraFovEnabled = value
    local camera = workspace.CurrentCamera
    if camera then camera.FieldOfView = value and (savedUI.cameraFov or 80) or cameraFovOriginal end
end)
local setFovSetting = createSettingSlider(pages["SETTINGS"], "Угол обзора FOV", 50, 120, savedUI.cameraFov or 80, function(v) return tostring(v) .. "°" end, function(value)
    savedUI.cameraFov = value
    if cameraFovEnabled and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = value end
end)

section(pages["SETTINGS"], "ПРОФИЛЬ И БЕЗОПАСНЫЙ СБРОС")
local function setAllToggles(value)
    for _, entry in ipairs(toggleRegistry) do
        pcall(entry.set, value)
    end
end
makeActionButton(pages["HOME"], "PANIC BUTTON — ВЫКЛЮЧИТЬ ВСЁ", function()
    setAllToggles(false)
    speedEnabled = false
    noclipEnabled = false
    flyEnabled = false
    flyHeld = false
    espEnabled = false
    coordsEnabled = false
    cameraFovEnabled = false
    if coordinateHud then coordinateHud.Visible = false end
    if flyTouch then flyTouch.Visible = flyEditMode end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = cameraFovOriginal end
    for part, oldValue in pairs(originalCollision) do
        if part and part.Parent then pcall(function() part.CanCollide = oldValue end) end
    end
    table.clear(originalCollision)
    updateESP()
end)

makeActionButton(pages["SETTINGS"], "ПОЛНЫЙ СБРОС ДО ЗАВОДСКИХ", function()
    -- Disable every feature first and restore any modified character/camera state.
    setAllToggles(false)
    speedEnabled, noclipEnabled, flyEnabled, flyHeld = false, false, false, false
    espEnabled, coordsEnabled, cameraFovEnabled = false, false, false
    if coordinateHud then coordinateHud.Visible = false end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = cameraFovOriginal end
    for part, oldValue in pairs(originalCollision) do
        if part and part.Parent then pcall(function() part.CanCollide = oldValue end) end
    end
    table.clear(originalCollision)
    updateESP()

    -- Restore factory movement and visual values.
    walkSpeed = 16
    flySpeed = 4
    walkSpeedLabel.Text = "СКОРОСТЬ: 16"
    walkSpeedBar.Size = UDim2.new(0, 0, 0, 4)
    walkSpeedKnob.Position = UDim2.new(0, 10, 0.5, 0)
    speedLabel.Text = "СИЛА ПОЛЁТА: 4"
    speedBar.Size = UDim2.new(3 / 19, 0, 0, 4)
    speedKnob.Position = UDim2.new(3 / 19, 10, 0.5, 0)
    savedUI.flySize = 66
    savedUI.flyOpacity = 0.12
    savedUI.flyPosition = {x = -24, y = -150}
    savedUI.rhPosition = {x = 18, y = 300}
    savedUI.cameraFov = 80
    if flyTouch then
        flyTouch.Position = UDim2.new(1, -24, 1, -150)
        applyFlyAppearance()
        updateFlyButton()
    end
    if openButton then openButton.Position = UDim2.fromOffset(18, 300) end
    if statsOverlay then statsOverlay.Position = UDim2.fromOffset(18, 300) end
    if setFlySizeSetting then setFlySizeSetting(66) end
    if setFlyOpacitySetting then setFlyOpacitySetting(12) end
    if setFovSetting then setFovSetting(80) end
    -- Remove the saved settings profile too, so old values cannot be reloaded later.
    pcall(function()
        if type(isfile) == "function" and type(delfile) == "function" and isfile(CONFIG_FILE) then
            delfile(CONFIG_FILE)
        end
    end)
end)

section(pages["HOME"], "ПОИСК ФУНКЦИЙ")
local functionBox = make("TextBox", {Size = UDim2.new(1, -2, 0, 32), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0, Text = "", PlaceholderText = "Например: скорость, FOV, координаты…", PlaceholderColor3 = COLORS.muted, TextColor3 = COLORS.text, TextSize = 10, Font = Enum.Font.Gotham, ClearTextOnFocus = false}, pages["HOME"])
corner(functionBox, 10)
local searchResults = make("Frame", {Size = UDim2.new(1, -2, 0, 4), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, pages["HOME"])
make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, searchResults)
local function searchPageText(page, query)
    for _, child in ipairs(page:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            local fragments = {child.Name}
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then table.insert(fragments, child.Text) end
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then table.insert(fragments, desc.Text) end
            end
            local haystack = table.concat(fragments, " "):lower()
            if string.find(haystack, query, 1, true) then return true end
        end
    end
    return false
end
local function refreshSearch()
    for _, child in ipairs(searchResults:GetChildren()) do if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end end
    local query = functionBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then return end
    local found = 0
    for _, tabName in ipairs(tabNames) do
        if tabName ~= "HOME" and searchPageText(pages[tabName], query) then
            found += 1
            local result = make("TextButton", {Size = UDim2.new(1, -2, 0, 27), BackgroundColor3 = COLORS.button, BorderSizePixel = 0, Text = "Открыть раздел  ›  " .. tabName, TextColor3 = COLORS.text, TextSize = 10, Font = Enum.Font.GothamBold}, searchResults)
            corner(result, 8)
            result.Activated:Connect(function() selectTab(tabName) end)
            if found >= 5 then break end
        end
    end
    if found == 0 then
        local none = make("TextLabel", {Size = UDim2.new(1, -2, 0, 25), BackgroundTransparency = 1, Text = "Ничего не найдено", TextColor3 = COLORS.muted, TextSize = 10, Font = Enum.Font.Gotham}, searchResults)
    end
end
functionBox:GetPropertyChangedSignal("Text"):Connect(refreshSearch)

-- Named profiles are stored together in one JSON file. The profile name is a key,
-- not a filename, so arbitrary path characters cannot escape the config file.
local profileNameBox = make("TextBox", {
    Name = "ProfileName", Size = UDim2.new(1, -2, 0, 34),
    BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
    Text = "Мой профиль", PlaceholderText = "Название профиля",
    PlaceholderColor3 = COLORS.muted, TextColor3 = COLORS.text,
    TextSize = 11, Font = Enum.Font.Gotham, ClearTextOnFocus = false
}, pages["SETTINGS"])
corner(profileNameBox, 10)
local profileStatus = make("TextLabel", {
    Name = "ProfileStatus", Size = UDim2.new(1, -2, 0, 38),
    BackgroundTransparency = 1, Text = "Профили хранятся в файле настроек.",
    TextColor3 = COLORS.muted, TextSize = 10, Font = Enum.Font.Gotham,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left
}, pages["SETTINGS"])
local function profileMessage(message, success)
    profileStatus.Text = message
    profileStatus.TextColor3 = success and COLORS.green or COLORS.muted
end
local function readProfileStore()
    if not canUseFiles() then return nil, "Среда не поддерживает работу с файлами." end
    local existsOK, exists = pcall(isfile, CONFIG_FILE)
    if not existsOK or not exists then return {version = VERSION, profiles = {}}, nil end
    local readOK, raw = pcall(readfile, CONFIG_FILE)
    if not readOK or type(raw) ~= "string" then return nil, "Не удалось прочитать файл профилей." end
    local decodeOK, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not decodeOK or type(data) ~= "table" then return nil, "Файл профилей повреждён." end
    -- Migrate the old single-profile format without discarding its settings.
    if type(data.profiles) ~= "table" then
        local legacy = data
        data = {version = VERSION, profiles = {}}
        if type(legacy.toggles) == "table" then data.profiles["Мой профиль"] = legacy end
    end
    return data, nil
end
local function writeProfileStore(store)
    local encodeOK, raw = pcall(function() return HttpService:JSONEncode(store) end)
    if not encodeOK then return false end
    local writeOK = pcall(writefile, CONFIG_FILE, raw)
    return writeOK
end
local function currentSettingsData()
    local data = {
        version = VERSION, toggles = {}, walkSpeed = walkSpeed,
        flySpeed = flySpeed, flySize = savedUI.flySize,
        flyOpacity = savedUI.flyOpacity, cameraFov = savedUI.cameraFov,
        flyPosition = savedUI.flyPosition, launcherPosition = savedUI.rhPosition,
        espColorIndex = espColorIndex, espBoxesEnabled = espBoxesEnabled,
        espLinesEnabled = espLinesEnabled, espChamsEnabled = espChamsEnabled
    }
    for _, entry in ipairs(toggleRegistry) do data.toggles[entry.label] = entry.get() end
    return data
end
local function cleanProfileName()
    local name = profileNameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if #name > 32 then name = name:sub(1, 32) end
    return name
end
local function listProfileNames()
    local store, err = readProfileStore()
    if not store then profileMessage(err, false); return end
    local names = {}
    for name in pairs(store.profiles) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    profileMessage(#names > 0 and ("Профили: " .. table.concat(names, " • ")) or "Сохранённых профилей пока нет.", #names > 0)
end
local function applySettingsData(data)
    if type(data.espColorIndex) == "number" then espColorIndex = math.clamp(math.floor(data.espColorIndex), 1, #espPalette); paintESPColorButton(); refreshESPColors() end
    if type(data.espBoxesEnabled) == "boolean" and espBoxesToggleSetter then espBoxesToggleSetter(data.espBoxesEnabled) end
    if type(data.espLinesEnabled) == "boolean" and espLinesToggleSetter then espLinesToggleSetter(data.espLinesEnabled) end
    if type(data.espChamsEnabled) == "boolean" and espChamsToggleSetter then espChamsToggleSetter(data.espChamsEnabled) end
    if espEnabled then updateESP() end
    if type(data.toggles) == "table" then
        for _, entry in ipairs(toggleRegistry) do
            if type(data.toggles[entry.label]) == "boolean" then pcall(entry.set, data.toggles[entry.label]) end
        end
    end
    if type(data.walkSpeed) == "number" then
        walkSpeed = math.clamp(data.walkSpeed, 16, 1000)
        if walkSpeedLabel then walkSpeedLabel.Text = "СКОРОСТЬ: " .. walkSpeed end
        if walkSpeedTrack then
            local alpha = (walkSpeed - 16) / (1000 - 16)
            walkSpeedBar.Size = UDim2.new(alpha, 0, 0, 4)
            walkSpeedKnob.Position = UDim2.new(alpha, 10, 0.5, 0)
        end
        if speedEnabled then applyWalkSpeed() end
    end
    if type(data.flySpeed) == "number" then
        flySpeed = math.clamp(data.flySpeed, 1, 20)
        if speedLabel then speedLabel.Text = "СИЛА ПОЛЁТА: " .. flySpeed end
        local alpha = (flySpeed - 1) / 19
        speedBar.Size = UDim2.new(alpha, 0, 0, 4)
        speedKnob.Position = UDim2.new(alpha, 10, 0.5, 0)
    end
    if type(data.flySize) == "number" then savedUI.flySize = math.clamp(data.flySize, 44, 110); if setFlySizeSetting then setFlySizeSetting(savedUI.flySize) end; applyFlyAppearance() end
    if type(data.flyOpacity) == "number" then savedUI.flyOpacity = math.clamp(data.flyOpacity, 0, 0.85); if setFlyOpacitySetting then setFlyOpacitySetting(math.floor(savedUI.flyOpacity * 100 + 0.5)) end; applyFlyAppearance() end
    if type(data.cameraFov) == "number" then savedUI.cameraFov = math.clamp(data.cameraFov, 50, 120); if setFovSetting then setFovSetting(savedUI.cameraFov) end; if cameraFovEnabled and workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = savedUI.cameraFov end end
    if type(data.flyPosition) == "table" and type(data.flyPosition.x) == "number" and type(data.flyPosition.y) == "number" then
        savedUI.flyPosition = {x = data.flyPosition.x, y = data.flyPosition.y}
        if flyTouch then flyTouch.Position = UDim2.new(1, data.flyPosition.x, 1, data.flyPosition.y) end
    end
    if type(data.launcherPosition) == "table" and type(data.launcherPosition.x) == "number" and type(data.launcherPosition.y) == "number" then
        savedUI.rhPosition = {x = data.launcherPosition.x, y = data.launcherPosition.y}
        if openButton then openButton.Position = UDim2.fromOffset(data.launcherPosition.x, data.launcherPosition.y) end
        if statsOverlay then statsOverlay.Position = UDim2.fromOffset(data.launcherPosition.x, data.launcherPosition.y) end
    end
end
-- Profile picker: opens as a separate compact panel with selectable saved profiles.
local selectedProfileName = nil
local profilePicker = make("Frame", {
    Name = "ProfilePicker", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.86, 0, 0.68, 0),
    BackgroundColor3 = COLORS.background or Color3.fromRGB(14, 16, 25),
    BorderSizePixel = 0, Visible = false, ZIndex = 300
}, gui)
profilePicker.Size = UDim2.new(0.86, 0, 0, 350)
corner(profilePicker, 14)
stroke(profilePicker, COLORS.accent or Color3.fromRGB(255, 70, 190), 1.5, 0.1)
local pickerTitle = make("TextLabel", {
    Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -52, 0, 28),
    BackgroundTransparency = 1, Text = "ВЫБОР ПРОФИЛЯ", TextColor3 = COLORS.text,
    TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 301
}, profilePicker)
local pickerClose = make("TextButton", {
    Position = UDim2.new(1, -38, 0, 7), Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = COLORS.button, BorderSizePixel = 0, Text = "×",
    TextColor3 = COLORS.text, TextSize = 20, Font = Enum.Font.GothamBold, ZIndex = 301
}, profilePicker)
corner(pickerClose, 9)
local pickerHint = make("TextLabel", {
    Position = UDim2.new(0, 12, 0, 38), Size = UDim2.new(1, -24, 0, 28),
    BackgroundTransparency = 1, Text = "Выбери профиль во вкладке: можно загрузить или удалить.",
    TextColor3 = COLORS.muted, TextSize = 9, Font = Enum.Font.Gotham,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 301
}, profilePicker)
local profileList = make("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 70), Size = UDim2.new(1, -20, 1, -130),
    BackgroundColor3 = COLORS.panel, BorderSizePixel = 0, ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 301
}, profilePicker)
corner(profileList, 9)
local profileListLayout = make("UIListLayout", {
    Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder
}, profileList)
make("UIPadding", {
    PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)
}, profileList)
local pickerLoad = make("TextButton", {
    Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(0.5, -13, 0, 38),
    BackgroundColor3 = COLORS.green or Color3.fromRGB(60, 190, 130), BorderSizePixel = 0,
    Text = "ЗАГРУЗИТЬ", TextColor3 = Color3.new(1, 1, 1), TextSize = 10,
    Font = Enum.Font.GothamBold, ZIndex = 301
}, profilePicker)
corner(pickerLoad, 10)
local pickerDelete = make("TextButton", {
    Position = UDim2.new(0.5, 3, 1, -50), Size = UDim2.new(0.5, -13, 0, 38),
    BackgroundColor3 = COLORS.button, BorderSizePixel = 0, Text = "УДАЛИТЬ",
    TextColor3 = COLORS.text, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 301
}, profilePicker)
corner(pickerDelete, 10)
local function refreshProfilePicker()
    for _, child in ipairs(profileList:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    local store, err = readProfileStore()
    if not store then
        local row = make("TextLabel", {
            Size = UDim2.new(1, -4, 0, 42), BackgroundTransparency = 1,
            Text = err or "Не удалось прочитать профили.", TextColor3 = COLORS.muted,
            TextSize = 10, Font = Enum.Font.Gotham, TextWrapped = true, ZIndex = 302
        }, profileList)
        selectedProfileName = nil
        return
    end
    local names = {}
    for name in pairs(store.profiles) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    if #names == 0 then
        make("TextLabel", {
            Size = UDim2.new(1, -4, 0, 42), BackgroundTransparency = 1,
            Text = "Сохранённых профилей нет. Сначала сохрани профиль в настройках.",
            TextColor3 = COLORS.muted, TextSize = 10, Font = Enum.Font.Gotham,
            TextWrapped = true, ZIndex = 302
        }, profileList)
        selectedProfileName = nil
        pickerHint.Text = "Список сохранённых профилей пуст."
        return
    end
    if not selectedProfileName or store.profiles[selectedProfileName] == nil then
        selectedProfileName = names[1]
    end
    pickerHint.Text = "Выбрано: " .. selectedProfileName
    for index, name in ipairs(names) do
        local isSelected = name == selectedProfileName
        local row = make("TextButton", {
            Name = "Profile_" .. tostring(index), Size = UDim2.new(1, -4, 0, 34),
            BackgroundColor3 = isSelected and (COLORS.accent or Color3.fromRGB(120, 65, 190)) or COLORS.button,
            BorderSizePixel = 0, Text = (isSelected and "✓  " or "    ") .. name,
            TextColor3 = COLORS.text, TextSize = 10, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 302, LayoutOrder = index
        }, profileList)
        corner(row, 8)
        row.Activated:Connect(function()
            selectedProfileName = name
            refreshProfilePicker()
        end)
    end
end
local function openProfilePicker()
    refreshProfilePicker()
    profilePicker.Visible = true
end
pickerClose.Activated:Connect(function() profilePicker.Visible = false end)
pickerLoad.Activated:Connect(function()
    if not selectedProfileName then
        pickerHint.Text = "Сначала выбери профиль из списка."
        return
    end
    local store, err = readProfileStore()
    if not store then profileMessage(err, false); pickerHint.Text = err; return end
    local data = store.profiles[selectedProfileName]
    if type(data) ~= "table" then
        pickerHint.Text = "Профиль больше не найден. Обновляю список…"
        refreshProfilePicker()
        return
    end
    applySettingsData(data)
    profileMessage("Профиль «" .. selectedProfileName .. "» загружен.", true)
    profilePicker.Visible = false
end)
pickerDelete.Activated:Connect(function()
    if not selectedProfileName then pickerHint.Text = "Сначала выбери профиль для удаления."; return end
    local store, err = readProfileStore()
    if not store then profileMessage(err, false); pickerHint.Text = err; return end
    if store.profiles[selectedProfileName] == nil then
        refreshProfilePicker()
        return
    end
    local deletedName = selectedProfileName
    store.profiles[deletedName] = nil
    if writeProfileStore(store) then
        selectedProfileName = nil
        profileMessage("Профиль «" .. deletedName .. "» удалён.", true)
        refreshProfilePicker()
    else
        pickerHint.Text = "Не удалось обновить файл профилей."
    end
end)

makeActionButton(pages["SETTINGS"], "СОХРАНИТЬ ПРОФИЛЬ С НАЗВАНИЕМ", function()
    local name = cleanProfileName()
    if name == "" then profileMessage("Сначала введи название профиля.", false); return end
    local store, err = readProfileStore()
    if not store then profileMessage(err, false); return end
    store.profiles[name] = currentSettingsData()
    if writeProfileStore(store) then profileMessage("Профиль «" .. name .. "» сохранён.", true)
    else profileMessage("Не удалось сохранить профиль в файл.", false) end
end)
makeActionButton(pages["SETTINGS"], "ОТКРЫТЬ СПИСОК ПРОФИЛЕЙ", openProfilePicker)

-- UNIVERSAL COMPATIBILITY DIAGNOSTICS
-- Observes client-visible state only. It does not bypass server authority or anti-cheat.
section(pages["COMPAT"], "ПРОВЕРКА СОВМЕСТИМОСТИ")
infoCard(pages["COMPAT"], "Диагностика проекта", "Проверяет доступные объекты и состояние функций. Серверные ограничения нельзя достоверно определить только с клиента.")
local compatSummary = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 36), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
    Text = "Проверка ожидает запуска…", TextColor3 = COLORS.green, TextSize = 10,
    Font = Enum.Font.GothamBold, TextWrapped = true
}, pages["COMPAT"])
corner(compatSummary, 10)
local compatRows = {}
local compatRowLayoutOrder = 0
local function compatRow(key, label)
    compatRowLayoutOrder += 1
    local row = make("Frame", {
        Name = "Compat_" .. key, Size = UDim2.new(1, -2, 0, 31),
        BackgroundColor3 = COLORS.panel, BorderSizePixel = 0, LayoutOrder = compatRowLayoutOrder
    }, pages["COMPAT"])
    corner(row, 9)
    make("TextLabel", {
        Position = UDim2.new(0, 9, 0, 0), Size = UDim2.new(0.56, -9, 1, 0),
        BackgroundTransparency = 1, Text = label, TextColor3 = COLORS.text, TextSize = 9,
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    local value = make("TextLabel", {
        Position = UDim2.new(0.56, 0, 0, 0), Size = UDim2.new(0.44, -8, 1, 0),
        BackgroundTransparency = 1, Text = "WAITING", TextColor3 = COLORS.muted, TextSize = 9,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, row)
    compatRows[key] = value
end
compatRow("character", "Персонаж")
compatRow("humanoid", "Humanoid")
compatRow("root", "Корневая часть")
compatRow("speed", "Скорость")
compatRow("fly", "Fly")
compatRow("teleport", "Сохранённые точки")
compatRow("visual", "Визуальный интерфейс")
compatRow("resolver", "Данные для анализа")
compatRow("files", "Файловое API")
compatRow("respawn", "Возрождение")
infoCard(pages["COMPAT"], "Как читать статусы", "WORKING — объект доступен; LIMITED — функция включена, но результат не гарантирован; BLOCKED — нужный объект отсутствует; WAITING — пока нет данных.")
local compatLastCharacter = nil
local compatLastRoot = nil
local compatRespawnSeen = false
local function setCompat(key, value, color)
    local label = compatRows[key]
    if not label then return end
    label.Text = value
    label.TextColor3 = color or COLORS.muted
end
local function refreshCompatibility()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local green = COLORS.green
    local yellow = Color3.fromRGB(255, 190, 70)
    local red = Color3.fromRGB(255, 95, 110)
    setCompat("character", character and "WORKING" or "WAITING", character and green or yellow)
    setCompat("humanoid", humanoid and "WORKING" or (character and "BLOCKED" or "WAITING"), humanoid and green or red)
    setCompat("root", root and "WORKING" or (character and "BLOCKED" or "WAITING"), root and green or red)
    if humanoid then
        if speedEnabled then
            local actual = humanoid.WalkSpeed
            local delta = math.abs(actual - walkSpeed)
            setCompat("speed", delta < 0.5 and ("WORKING · " .. tostring(math.floor(actual + 0.5))) or ("LIMITED · " .. tostring(math.floor(actual + 0.5))), delta < 0.5 and green or yellow)
        else
            setCompat("speed", "OFF · " .. tostring(math.floor(humanoid.WalkSpeed + 0.5)), COLORS.muted)
        end
    else
        setCompat("speed", "WAITING", yellow)
    end
    if flyEnabled then
        setCompat("fly", root and "LIMITED · client" or "BLOCKED", root and yellow or red)
    else
        setCompat("fly", "OFF", COLORS.muted)
    end
    local pointCount = 0
    if type(teleportPoints) == "table" then for _ in pairs(teleportPoints) do pointCount += 1 end end
    setCompat("teleport", tostring(pointCount) .. " точек", pointCount > 0 and green or COLORS.muted)
    setCompat("visual", gui and gui.Parent and "WORKING" or "BLOCKED", gui and gui.Parent and green or red)
    setCompat("resolver", root and humanoid and "WORKING · client data" or "WAITING", root and humanoid and green or yellow)
    local fileAPI = type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
    setCompat("files", fileAPI and "WORKING" or "LIMITED · no file API", fileAPI and green or yellow)
    if character and character ~= compatLastCharacter then
        if compatLastCharacter ~= nil then compatRespawnSeen = true end
        compatLastCharacter = character
    end
    setCompat("respawn", compatRespawnSeen and "WORKING · detected" or (character and "READY" or "WAITING"), compatRespawnSeen and green or COLORS.muted)
    if not character then
        compatSummary.Text = "Ожидание персонажа. Проверьте, что игра завершила загрузку."
        compatSummary.TextColor3 = yellow
    elseif not humanoid or not root then
        compatSummary.Text = "Персонаж загружен не полностью: часть функций недоступна."
        compatSummary.TextColor3 = red
    elseif speedEnabled and math.abs(humanoid.WalkSpeed - walkSpeed) >= 0.5 then
        compatSummary.Text = "Обнаружено отличие WalkSpeed от заданного значения. Возможны ограничения проекта или другой локальный скрипт."
        compatSummary.TextColor3 = yellow
    elseif flyEnabled then
        compatSummary.Text = "Fly включён. Клиентская проверка не может подтвердить принятие перемещения сервером."
        compatSummary.TextColor3 = yellow
    else
        compatSummary.Text = "Базовые объекты доступны. Для проверки движения включите нужную функцию в MOVE."
        compatSummary.TextColor3 = green
    end
    compatLastRoot = root
end
makeActionButton(pages["COMPAT"], "ОБНОВИТЬ ПРОВЕРКУ", refreshCompatibility)
makeActionButton(pages["COMPAT"], "СБРОСИТЬ СТАТУС ВОЗРОЖДЕНИЯ", function()
    compatLastCharacter = LocalPlayer.Character
    compatRespawnSeen = false
    refreshCompatibility()
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    refreshCompatibility()
end)
task.spawn(function()
    while gui and gui.Parent do
        pcall(refreshCompatibility)
        task.wait(0.75)
    end
end)

refreshPoints()
refreshCompatibility()
selectTab("HOME")

-- Keep touch fly control visible independently of selected page and menu state.
local function syncFlyButton()
    updateFlyButton()
end
for _, button in pairs(tabButtons) do button.Activated:Connect(function() task.defer(syncFlyButton) end) end
minimize.Activated:Connect(syncFlyButton)
openButton.Activated:Connect(function() task.defer(syncFlyButton) end)

print("RAHERHUB " .. VERSION .. " MULTI-TOOL HUB запущен.")
