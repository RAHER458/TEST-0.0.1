local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local espEnabled = false
local flyJumpEnabled = false
local flyingUp = false

local highlights = {}

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

local flyConnection

local function startFly()
    if not flyJumpEnabled then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        return
    end

    flyingUp = true

    if flyConnection then
        flyConnection:Disconnect()
    end

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyJumpEnabled or not flyingUp then
            return
        end

        if root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                45,
                root.AssemblyLinearVelocity.Z
            )
        end
    end)
end

local function stopFly()
    flyingUp = false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

local function setFlyJump(state)
    flyJumpEnabled = state

    if not state then
        stopFly()
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
main.Size = UDim2.fromOffset(235, 205)
main.Position = UDim2.new(0.5, -117, 0.5, -102)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 80)
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = main

--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Text = "TEST MENU"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

--==================================================
-- HIDE
--==================================================

local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.fromOffset(40, 40)
hideButton.Position = UDim2.new(1, -45, 0, 3)
hideButton.BackgroundTransparency = 1
hideButton.Text = "—"
hideButton.TextColor3 = Color3.fromRGB(200, 200, 205)
hideButton.TextSize = 24
hideButton.Font = Enum.Font.GothamBold
hideButton.Parent = header

--==================================================
-- ESP BUTTON
--==================================================

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, -30, 0, 48)
espButton.Position = UDim2.fromOffset(15, 55)
espButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
espButton.BorderSizePixel = 0
espButton.Text = "ESP     OFF"
espButton.TextColor3 = Color3.fromRGB(230, 230, 235)
espButton.TextSize = 16
espButton.Font = Enum.Font.GothamSemibold
espButton.Parent = main

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 10)
espCorner.Parent = espButton

espButton.Activated:Connect(function()
    setESP(not espEnabled)

    if espEnabled then
        espButton.Text = "ESP     ON"
        espButton.TextColor3 = Color3.fromRGB(120, 255, 150)
    else
        espButton.Text = "ESP     OFF"
        espButton.TextColor3 = Color3.fromRGB(230, 230, 235)
    end
end)

--==================================================
-- FLY JUMP BUTTON
--==================================================

local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(1, -30, 0, 48)
flyButton.Position = UDim2.fromOffset(15, 112)
flyButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
flyButton.BorderSizePixel = 0
flyButton.Text = "FLY JUMP     OFF"
flyButton.TextColor3 = Color3.fromRGB(230, 230, 235)
flyButton.TextSize = 16
flyButton.Font = Enum.Font.GothamSemibold
flyButton.Parent = main

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 10)
flyCorner.Parent = flyButton

flyButton.Activated:Connect(function()
    setFlyJump(not flyJumpEnabled)

    if flyJumpEnabled then
        flyButton.Text = "FLY JUMP     ON"
        flyButton.TextColor3 = Color3.fromRGB(120, 200, 255)
    else
        flyButton.Text = "FLY JUMP     OFF"
        flyButton.TextColor3 = Color3.fromRGB(230, 230, 235)
    end
end)

--==================================================
-- OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.fromOffset(55, 55)
openButton.Position = UDim2.new(0, 20, 0.5, -27)
openButton.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
openButton.BorderSizePixel = 0
openButton.Text = "≡"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 25
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(90, 90, 100)
openStroke.Thickness = 1
openStroke.Parent = openButton

--==================================================
-- FLY UP TOUCH BUTTON
--==================================================

local flyTouch = Instance.new("TextButton")
flyTouch.Name = "FlyTouch"
flyTouch.Size = UDim2.fromOffset(65, 65)
flyTouch.Position = UDim2.new(1, -85, 1, -180)
flyTouch.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
flyTouch.BorderSizePixel = 0
flyTouch.Text = "↑"
flyTouch.TextColor3 = Color3.fromRGB(255, 255, 255)
flyTouch.TextSize = 30
flyTouch.Font = Enum.Font.GothamBold
flyTouch.Visible = false
flyTouch.Parent = gui

local flyTouchCorner = Instance.new("UICorner")
flyTouchCorner.CornerRadius = UDim.new(1, 0)
flyTouchCorner.Parent = flyTouch

local flyTouchStroke = Instance.new("UIStroke")
flyTouchStroke.Color = Color3.fromRGB(90, 90, 100)
flyTouchStroke.Thickness = 1
flyTouchStroke.Parent = flyTouch

--==================================================
-- HOLD TO FLY
--==================================================

flyTouch.InputBegan:Connect(function(input)
    if not flyJumpEnabled then
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
-- DRAG SYSTEM
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

    if flyJumpEnabled then
        flyTouch.Visible = true
    end
end)

openButton.Activated:Connect(function()
    main.Visible = true
    openButton.Visible = false

    if flyJumpEnabled then
        flyTouch.Visible = true
    end
end)

-- Показываем кнопку сразу после включения FLY JUMP
flyButton:GetPropertyChangedSignal("Text"):Connect(function()
    flyTouch.Visible = flyJumpEnabled
end)