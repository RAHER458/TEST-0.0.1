-- RAHERHUB 0.1 | Private testing UI
-- Mobile interface, FUNCTIONS and TELEPORT
-- No registration, license checks, accounts, or external HTTP requests.
-- Intended for your own Roblox place / authorized testing.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local VERSION = "0.1"
local POINTS_FILE = "raherhub_teleport_points.json"

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
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius or 12)
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or Color3.fromRGB(70, 75, 95),
        Thickness = thickness or 1,
        Transparency = transparency or 0.2
    }, parent)
end

local function safeParentGui(gui)
    local ok = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)

    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = make("ScreenGui", {
    Name = "RAHERHUB_01",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true
})

safeParentGui(gui)

--------------------------------------------------
-- COLORS
--------------------------------------------------

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

--------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 390, 0, 540),
    BackgroundColor3 = COLORS.background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)

corner(main, 18)
stroke(main, Color3.fromRGB(74, 80, 115), 1, 0.15)

local function fitPanel()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local viewport = camera.ViewportSize
    local width = math.clamp(viewport.X - 24, 300, 430)
    local height = math.clamp(viewport.Y - 80, 390, 620)

    main.Size = UDim2.fromOffset(width, height)
end

fitPanel()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
end

--------------------------------------------------
-- HEADER
--------------------------------------------------

local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0
}, main)

corner(header, 18)

local title = make("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 16, 0, 9),
    Size = UDim2.new(1, -100, 0, 34),
    BackgroundTransparency = 1,
    Text = "RAHERHUB",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 25,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

make("TextLabel", {
    Position = UDim2.new(0, 17, 0, 43),
    Size = UDim2.new(1, -95, 0, 20),
    BackgroundTransparency = 1,
    Text = "PRIVATE BUILD  •  v" .. VERSION,
    TextColor3 = COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local minimize = make("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 13),
    Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = COLORS.button,
    BorderSizePixel = 0,
    Text = "—",
    TextColor3 = COLORS.text,
    TextSize = 22,
    Font = Enum.Font.GothamBold
}, header)

corner(minimize, 12)

--------------------------------------------------
-- RGB TITLE ANIMATION
--------------------------------------------------

local hue = 0
local rgbConnection

rgbConnection = RunService.RenderStepped:Connect(function(dt)
    if not title.Parent then
        rgbConnection:Disconnect()
        return
    end

    hue = (hue + dt * 0.22) % 1
    title.TextColor3 = Color3.fromHSV(hue, 0.68, 1)
end)

--------------------------------------------------
-- DRAG WINDOW
--------------------------------------------------

local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--------------------------------------------------
-- MINIMIZE / OPEN
--------------------------------------------------

local openButton = make("TextButton", {
    Name = "OpenButton",
    Visible = false,
    Position = UDim2.new(0, 18, 0.5, -28),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Text = "RH",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 18,
    Font = Enum.Font.GothamBlack
}, gui)

corner(openButton, 29)

minimize.Activated:Connect(function()
    main.Visible = false
    openButton.Visible = true
end)

openButton.Activated:Connect(function()
    main.Visible = true
    openButton.Visible = false
end)

--------------------------------------------------
-- TABS
--------------------------------------------------

local tabsBar = make("Frame", {
    Position = UDim2.new(0, 12, 0, 86),
    Size = UDim2.new(1, -24, 0, 44),
    BackgroundTransparency = 1
}, main)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabsBar)

local pages = {}
local tabButtons = {}
local activeTab = "MAIN"

local content = make("Frame", {
    Position = UDim2.new(0, 12, 0, 138),
    Size = UDim2.new(1, -24, 1, -150),
    BackgroundTransparency = 1
}, main)

for index, tabName in ipairs({
    "MAIN",
    "FUNCTIONS",
    "TELEPORT"
}) do

    local tab = make("TextButton", {
        Name = tabName .. "Tab",
        Size = UDim2.new(1/3, -5, 1, 0),
        BackgroundColor3 = COLORS.button,
        BorderSizePixel = 0,
        Text = tabName,
        TextColor3 = COLORS.muted,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        LayoutOrder = index
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

        tabButtons[tabName].BackgroundColor3 =
            tabName == name and COLORS.accent or COLORS.button

        tabButtons[tabName].TextColor3 =
            tabName == name and Color3.new(1, 1, 1) or COLORS.muted
    end
end

for name, button in pairs(tabButtons) do
    button.Activated:Connect(function()
        selectTab(name)
    end)
end

--------------------------------------------------
-- UI HELPERS
--------------------------------------------------

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
        Size = UDim2.new(1, -2, 0, 86),
        BackgroundColor3 = COLORS.panel,
        BorderSizePixel = 0
    }, parent)

    corner(card, 13)

    make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 10),
        Size = UDim2.new(1, -26, 0, 22),
        BackgroundTransparency = 1,
        Text = heading,
        TextColor3 = COLORS.text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, card)

    make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 35),
        Size = UDim2.new(1, -26, 0, 40),
        BackgroundTransparency = 1,
        Text = body,
        TextWrapped = true,
        TextColor3 = COLORS.muted,
        TextSize = 12,
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
    Text = "Ready. No account or license required.",
    TextColor3 = COLORS.green,
    TextSize = 12,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true
}, pages.MAIN)

corner(statusLabel, 11)

section(pages.MAIN, "OVERVIEW")

infoCard(
    pages.MAIN,
    "RAHERHUB 0.1",
    "Private testing build with a mobile-friendly interface and saved teleport points."
)

infoCard(
    pages.MAIN,
    "QUICK START",
    "Open FUNCTIONS for movement/testing controls or TELEPORT to create and revisit saved positions."
)

infoCard(
    pages.MAIN,
    "POINT STORAGE",
    "Teleport points are saved locally when file access is supported by your environment."
)

--------------------------------------------------
-- BUTTON FACTORY
--------------------------------------------------

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

    button = makeActionButton(parent, "", function()
        enabled = not enabled

        button.Text = label .. "     [" ..
            (enabled and "ON" or "OFF") .. "]"

        button.BackgroundColor3 =
            enabled and COLORS.green or COLORS.button

        callback(enabled)
    end)

    button.Text = label .. "     [" ..
        (enabled and "ON" or "OFF") .. "]"

    button.BackgroundColor3 =
        enabled and COLORS.green or COLORS.button

    return button, function(value)
        enabled = value

        button.Text = label .. "     [" ..
            (enabled and "ON" or "OFF") .. "]"

        button.BackgroundColor3 =
            enabled and COLORS.green or COLORS.button

        callback(enabled)
    end
end

--------------------------------------------------
-- FUNCTIONS
--------------------------------------------------

section(pages.FUNCTIONS, "CHARACTER TESTING")

infoCard(
    pages.FUNCTIONS,
    "Testing controls",
    "Use these only in your own place or an environment where you have permission to test."
)

--------------------------------------------------
-- ESP
--------------------------------------------------

local espEnabled = false
local espObjects = {}

local function removeESP(player)
    local object = espObjects[player]

    if object then
        pcall(function()
            object:Destroy()
        end)
    end

    espObjects[player] = nil
end

local function createESP(player)
    if not espEnabled
        or player == LocalPlayer
        or not player.Character
        or espObjects[player] then
        return
    end

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
        if espEnabled then
            createESP(player)
        else
            removeESP(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createESP(player)
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

makeToggle(pages.FUNCTIONS, "ESP", false, function(value)
    espEnabled = value
    updateESP()
end)

--------------------------------------------------
-- FLY JUMP
--------------------------------------------------

local flyEnabled = false
local flySpeed = 4
local flyHeld = false

local flyTouch = make("TextButton", {
    Name = "FlyHoldButton",
    Visible = false,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -24, 1, -95),
    Size = UDim2.fromOffset(66, 66),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    Text = "↑",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 32,
    Font = Enum.Font.GothamBold
}, gui)

corner(flyTouch, 33)

flyTouch.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyHeld = true
    end
end)

flyTouch.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyHeld = false
    end
end)

makeToggle(pages.FUNCTIONS, "FLY JUMP", false, function(value)
    flyEnabled = value
    flyTouch.Visible = main.Visible
        and activeTab == "FUNCTIONS"
        and flyEnabled

    if not value then
        flyHeld = false
    end
end)

--------------------------------------------------
-- FLY POWER SLIDER: 1–20
--------------------------------------------------

local speedLabel = make("TextLabel", {
    Size = UDim2.new(1, -2, 0, 24),
    BackgroundTransparency = 1,
    Text = "FLY POWER: 4",
    TextColor3 = COLORS.muted,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, pages.FUNCTIONS)

local speedTrack = make("Frame", {
    Size = UDim2.new(1, -2, 0, 34),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0
}, pages.FUNCTIONS)

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
    BackgroundColor3 = Color3.new(1, 1, 1),
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

    speedLabel.Text = "FLY POWER: " .. flySpeed
    speedBar.Size = UDim2.new(alpha, 0, 0, 8)
    speedKnob.Position = UDim2.new(alpha, 10, 0.5, 0)
end

speedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
        setFlySpeedFromX(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if speedDragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        setFlySpeedFromX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = false
    end
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclipEnabled = false
local originalCollision = {}

makeToggle(pages.FUNCTIONS, "NOCLIP", false, function(value)
    noclipEnabled = value

    if not value then
        for part, oldValue in pairs(originalCollision) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = oldValue
                end)
            end
        end

        table.clear(originalCollision)
    end
end)

--------------------------------------------------
-- CHARACTER MOVEMENT LOOP
--------------------------------------------------

RunService.Stepped:Connect(function()
    local character = LocalPlayer.Character
    if not character then return end

    if noclipEnabled then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCollision[part] == nil then
                    originalCollision[part] = part.CanCollide
                end

                part.CanCollide = false
            end
        end
    end

    if flyEnabled and flyHeld then
        local root = character:FindFirstChild("HumanoidRootPart")

        if root then
            local velocity = root.AssemblyLinearVelocity

            root.AssemblyLinearVelocity = Vector3.new(
                velocity.X,
                flySpeed * 10,
                velocity.Z
            )
        end
    end
end)

--------------------------------------------------
-- FLY BUTTON VISIBILITY
--------------------------------------------------

local function syncFlyButton()
    flyTouch.Visible = main.Visible
        and activeTab == "FUNCTIONS"
        and flyEnabled
end

for _, button in pairs(tabButtons) do
    button.Activated:Connect(function()
        task.defer(syncFlyButton)
    end)
end

minimize.Activated:Connect(function()
    flyTouch.Visible = false
end)

openButton.Activated:Connect(function()
    task.defer(syncFlyButton)
end)

--------------------------------------------------
-- TELEPORT POINT STORAGE
--------------------------------------------------

local teleportPoints = {}

local function canUseFiles()
    return type(readfile) == "function"
        and type(writefile) == "function"
        and type(isfile) == "function"
end

local function loadPoints()
    if not canUseFiles() then return end

    local ok, exists = pcall(isfile, POINTS_FILE)
    if not ok or not exists then return end

    local readOK, raw = pcall(readfile, POINTS_FILE)
    if not readOK or type(raw) ~= "string" then return end

    local decodeOK, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if decodeOK and type(data) == "table" then
        for _, point in ipairs(data) do
            if type(point) == "table"
                and type(point.name) == "string"
                and type(point.x) == "number"
                and type(point.y) == "number"
                and type(point.z) == "number" then

                table.insert(teleportPoints, {
                    name = point.name,
                    x = point.x,
                    y = point.y,
                    z = point.z
                })
            end
        end
    end
end

local function savePoints()
    if not canUseFiles() then
        statusLabel.Text =
            "File storage unavailable: points last only for this session."

        statusLabel.TextColor3 = Color3.fromRGB(255, 190, 90)
        return false
    end

    local ok, raw = pcall(function()
        return HttpService:JSONEncode(teleportPoints)
    end)

    if not ok then return false end

    local writeOK = pcall(writefile, POINTS_FILE, raw)
    return writeOK
end

loadPoints()

--------------------------------------------------
-- TELEPORT INTERFACE
--------------------------------------------------

section(pages.TELEPORT, "POINT MANAGER")

infoCard(
    pages.TELEPORT,
    "Saved locations",
    "Create a point at your current position, then select it later to return to those coordinates."
)

local pointNameBox = make("TextBox", {
    Size = UDim2.new(1, -2, 0, 46),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Point name (e.g. Home)",
    PlaceholderColor3 = COLORS.muted,
    TextColor3 = COLORS.text,
    TextSize = 14,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, pages.TELEPORT)

corner(pointNameBox, 12)

local pointsList = make("Frame", {
    Size = UDim2.new(1, -2, 0, 8),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1
}, pages.TELEPORT)

make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder
}, pointsList)

--------------------------------------------------
-- POINT LIST
--------------------------------------------------

local function clearPointRows()
    for _, child in ipairs(pointsList:GetChildren()) do
        if child:IsA("GuiObject")
            and not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
end

local function refreshPoints()
    clearPointRows()

    if #teleportPoints == 0 then
        local empty = make("TextLabel", {
            Size = UDim2.new(1, -2, 0, 42),
            BackgroundColor3 = COLORS.panel,
            BorderSizePixel = 0,
            Text = "No saved points yet.",
            TextColor3 = COLORS.muted,
            TextSize = 12,
            Font = Enum.Font.Gotham
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
            Text = string.format(
                "X %.1f   Y %.1f   Z %.1f",
                point.x,
                point.y,
                point.z
            ),
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
            Text = "TELEPORT",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            Font = Enum.Font.GothamBold
        }, row)

        corner(go, 8)

        go.Activated:Connect(function()
            local character = LocalPlayer.Character
            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            if not root then
                statusLabel.Text =
                    "Character is not ready. Try again."

                statusLabel.TextColor3 = COLORS.red
                return
            end

            -- Local movement for your own place / authorized tests.
            root.CFrame = CFrame.new(
                point.x,
                point.y + 3,
                point.z
            )

            statusLabel.Text = "Moved to point: " .. point.name
            statusLabel.TextColor3 = COLORS.green
        end)

        local delete = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -9, 0, 53),
            Size = UDim2.new(0.33, -5, 0, 27),
            BackgroundColor3 = COLORS.red,
            BorderSizePixel = 0,
            Text = "DELETE",
            TextColor3 = Color3.new(1, 1, 1),
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

--------------------------------------------------
-- CREATE TELEPORT POINT
--------------------------------------------------

makeActionButton(
    pages.TELEPORT,
    "+ SAVE CURRENT POSITION",
    function()
        local character = LocalPlayer.Character
        local root = character
            and character:FindFirstChild("HumanoidRootPart")

        if not root then
            statusLabel.Text =
                "Character is not ready. Try again."

            statusLabel.TextColor3 = COLORS.red
            return
        end

        local name = pointNameBox.Text
            :gsub("^%s+", "")
            :gsub("%s+$", "")

        if name == "" then
            name = "Point " .. tostring(#teleportPoints + 1)
        end

        for _, point in ipairs(teleportPoints) do
            if point.name:lower() == name:lower() then
                statusLabel.Text =
                    "A point with that name already exists."

                statusLabel.TextColor3 = COLORS.red
                return
            end
        end

        local pos = root.Position

        table.insert(teleportPoints, {
            name = name,
            x = pos.X,
            y = pos.Y,
            z = pos.Z
        })

        local saved = savePoints()

        pointNameBox.Text = ""
        refreshPoints()

        statusLabel.Text = saved
            and ("Saved point: " .. name)
            or ("Point created: " .. name .. " (session only)")

        statusLabel.TextColor3 = saved
            and COLORS.green
            or Color3.fromRGB(255, 190, 90)
    end
)

--------------------------------------------------
-- CLEAR TELEPORT POINTS
--------------------------------------------------

makeActionButton(
    pages.TELEPORT,
    "CLEAR ALL POINTS",
    function()
        table.clear(teleportPoints)
        savePoints()
        refreshPoints()

        statusLabel.Text = "All saved points cleared."
        statusLabel.TextColor3 = COLORS.muted
    end
)

--------------------------------------------------
-- START
--------------------------------------------------

refreshPoints()
selectTab("MAIN")

local function syncFlyButton()
    flyTouch.Visible = main.Visible
        and activeTab == "FUNCTIONS"
        and flyEnabled
end

for _, button in pairs(tabButtons) do
    button.Activated:Connect(function()
        task.defer(syncFlyButton)
    end)
end

minimize.Activated:Connect(function()
    flyTouch.Visible = false
end)

openButton.Activated:Connect(function()
    task.defer(syncFlyButton)
end)

print("RAHERHUB " .. VERSION .. " loaded.")