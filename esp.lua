local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local espEnabled = false
local flyEnabled = false
local noclipEnabled = false
local flying = false

local highlights = {}
local flyConnection
local noclipConnection

--==================================================
-- ESP
--==================================================

local function addESP(player)
    if player == LocalPlayer then
        return
    end

    local function characterAdded(character)
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end

        if not espEnabled then
            return
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = "SimpleESP"
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.Adornee = character
        highlight.Parent = character

        highlights[player] = highlight
    end

    if player.Character then
        characterAdded(player.Character)
    end

    player.CharacterAdded:Connect(characterAdded)
end

local function setESP(state)
    espEnabled = state

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if state then
                addESP(player)
            elseif highlights[player] then
                highlights[player]:Destroy()
                highlights[player] = nil
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        addESP(player)
    end
end)

--==================================================
-- FLY JUMP
--==================================================

local function stopFly()
    flying = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

local function startFly()
    if not flyEnabled then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    flying = true

    if flyConnection then
        flyConnection:Disconnect()
    end

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled or not flying then
            return
        end

        if root.Parent then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                45,
                root.AssemblyLinearVelocity.Z
            )
        end
    end)
end

local function setFly(state)
    flyEnabled = state

    if not state then
        stopFly()
    end
end

--==================================================
-- NOCLIP
--==================================================

local function restoreCollision()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            object.CanCollide = true
        end
    end
end

local function setNoclip(state)
    noclipEnabled = state

    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character

            if character then
                for _, object in ipairs(character:GetDescendants()) do
                    if object:IsA("BasePart") then
                        object.CanCollide = false
                    end
                end
            end
        end)
    else
        restoreCollision()
    end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "MobileTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

--==================================================
-- MAIN PANEL
--==================================================

local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.fromOffset(285, 310)
main.Position = UDim2.new(0.5, -142, 0.5, -155)
main.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 110, 255)
mainStroke.Thickness = 2
mainStroke.Parent = main

--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(40, 44, 70)
header.BorderSizePixel = 0
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "TEST MENU"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.fromOffset(42, 42)
hideButton.Position = UDim2.new(1, -47, 0, 3)
hideButton.BackgroundTransparency = 1
hideButton.Text = "×"
hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hideButton.TextSize = 27
hideButton.Font = Enum.Font.GothamBold
hideButton.Parent = header

--==================================================
-- TABS
--==================================================

local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -20, 0, 42)
tabs.Position = UDim2.fromOffset(10, 55)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabs

local pages = {}
local tabButtons = {}

local function createTab(name)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(82, 38)
    button.BackgroundColor3 = Color3.fromRGB(42, 45, 62)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(190, 195, 215)
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    button.Parent = tabs

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button

    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -20, 1, -110)
    page.Position = UDim2.fromOffset(10, 103)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = main

    tabButtons[name] = button
    pages[name] = page

    return button, page
end

local mainTab, mainPage = createTab("Main")
local feature1Tab, feature1Page = createTab("Feature 1")
local feature2Tab, feature2Page = createTab("Feature 2")

local function selectTab(name)
    for tabName, page in pairs(pages) do
        page.Visible = tabName == name

        if tabButtons[tabName] then
            if tabName == name then
                tabButtons[tabName].BackgroundColor3 =
                    Color3.fromRGB(90, 95, 220)

                tabButtons[tabName].TextColor3 =
                    Color3.fromRGB(255, 255, 255)
            else
                tabButtons[tabName].BackgroundColor3 =
                    Color3.fromRGB(42, 45, 62)

                tabButtons[tabName].TextColor3 =
                    Color3.fromRGB(190, 195, 215)
            end
        end
    end
end

mainTab.Activated:Connect(function()
    selectTab("Main")
end)

feature1Tab.Activated:Connect(function()
    selectTab("Feature 1")
end)

feature2Tab.Activated:Connect(function()
    selectTab("Feature 2")
end)

--==================================================
-- FEATURE BUTTON
--==================================================

local function createFeatureButton(parent, text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 45)
    button.Position = UDim2.fromOffset(0, y)
    button.BackgroundColor3 = Color3.fromRGB(45, 48, 68)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(235, 235, 245)
    button.TextSize = 15
    button.Font = Enum.Font.GothamSemibold
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 11)
    corner.Parent = button

    return button
end

local espButton =
    createFeatureButton(mainPage, "ESP        OFF", 0)

local flyButton =
    createFeatureButton(mainPage, "FLY JUMP        OFF", 52)

local noclipButton =
    createFeatureButton(mainPage, "NOCLIP        OFF", 104)

--==================================================
-- EMPTY FEATURES
--==================================================

local function emptyPage(page, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(130, 135, 155)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.Parent = page
end

emptyPage(feature1Page, "FEATURE 1\n\nComing soon...")
emptyPage(feature2Page, "FEATURE 2\n\nComing soon...")

--==================================================
-- FLY TOUCH BUTTON
--==================================================

local flyTouch = Instance.new("TextButton")
flyTouch.Name = "FlyTouch"
flyTouch.Size = UDim2.fromOffset(68, 68)
flyTouch.Position = UDim2.new(1, -88, 1, -185)
flyTouch.BackgroundColor3 = Color3.fromRGB(45, 55, 100)
flyTouch.BorderSizePixel = 0
flyTouch.Text = "↑"
flyTouch.TextColor3 = Color3.fromRGB(255, 255, 255)
flyTouch.TextSize = 31
flyTouch.Font = Enum.Font.GothamBold
flyTouch.Visible = false
flyTouch.Parent = gui

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(1, 0)
flyCorner.Parent = flyTouch

local flyStroke = Instance.new("UIStroke")
flyStroke.Color = Color3.fromRGB(100, 180, 255)
flyStroke.Thickness = 2
flyStroke.Parent = flyTouch

--==================================================
-- OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.fromOffset(58, 58)
openButton.Position = UDim2.new(0, 18, 0.5, -29)
openButton.BackgroundColor3 = Color3.fromRGB(55, 60, 105)
openButton.BorderSizePixel = 0
openButton.Text = "≡"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 27
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(120, 130, 255)
openStroke.Thickness = 2
openStroke.Parent = openButton

--==================================================
-- BUTTON EVENTS
--==================================================

espButton.Activated:Connect(function()
    setESP(not espEnabled)

    espButton.Text = espEnabled
        and "ESP        ON"
        or "ESP        OFF"

    espButton.TextColor3 = espEnabled
        and Color3.fromRGB(120, 255, 170)
        or Color3.fromRGB(235, 235, 245)
end)

flyButton.Activated:Connect(function()
    setFly(not flyEnabled)

    flyButton.Text = flyEnabled
        and "FLY JUMP        ON"
        or "FLY JUMP        OFF"

    flyButton.TextColor3 = flyEnabled
        and Color3.fromRGB(100, 210, 255)
        or Color3.fromRGB(235, 235, 245)

    flyTouch.Visible = flyEnabled
end)

noclipButton.Activated:Connect(function()
    setNoclip(not noclipEnabled)

    noclipButton.Text = noclipEnabled
        and "NOCLIP        ON"
        or "NOCLIP        OFF"

    noclipButton.TextColor3 = noclipEnabled
        and Color3.fromRGB(255, 190, 90)
        or Color3.fromRGB(235, 235, 245)
end)

--==================================================
-- HOLD FLY
--==================================================

flyTouch.InputBegan:Connect(function(input)
    if not flyEnabled then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        startFly()
    end
end)

flyTouch.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        stopFly()
    end
end)

--==================================================
-- DRAG
--==================================================

local function makeDraggable(object, handle)
    local dragging = false
    local dragStart
    local startPosition
    local dragInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = true
            dragStart = input.Position
            startPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then

            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            object.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(main, header)
makeDraggable(openButton, openButton)

--==================================================
-- HIDE / OPEN
--==================================================

hideButton.Activated:Connect(function()
    main.Visible = false
    openButton.Visible = true
end)

openButton.Activated:Connect(function()
    main.Visible = true
    openButton.Visible = false
end)

--==================================================
-- DEFAULT TAB
--==================================================

selectTab("Main")