repeat task.wait() until game:IsLoaded()

--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RAHERHUB"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    ScreenGui.Parent = CoreGui
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- LOADING
--==================================================

local loading = Instance.new("Frame")
loading.Size = UDim2.fromScale(1, 1)
loading.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
loading.BorderSizePixel = 0
loading.Parent = ScreenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0.35, 0)
title.BackgroundTransparency = 1
title.Text = "RAHERHUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 32
title.Font = Enum.Font.GothamBold
title.Parent = loading

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 30)
subtitle.Position = UDim2.new(0, 0, 0.44, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Loading..."
subtitle.TextColor3 = Color3.fromRGB(170, 170, 180)
subtitle.TextSize = 15
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = loading

local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(0.55, 0, 0, 8)
barBack.Position = UDim2.new(0.225, 0, 0.53, 0)
barBack.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
barBack.BorderSizePixel = 0
barBack.Parent = loading

Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
bar.BorderSizePixel = 0
bar.Parent = barBack

Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local stages = {
    "Initializing...",
    "Loading interface...",
    "Preparing modules...",
    "Loading features...",
    "Almost ready..."
}

for i = 1, 100 do
    bar.Size = UDim2.new(i / 100, 0, 1, 0)

    local stageIndex = math.clamp(
        math.floor((i - 1) / 20) + 1,
        1,
        #stages
    )

    subtitle.Text = stages[stageIndex]

    task.wait(0.05)
end

TweenService:Create(
    loading,
    TweenInfo.new(0.5),
    {BackgroundTransparency = 1}
):Play()

for _, obj in ipairs(loading:GetDescendants()) do
    if obj:IsA("TextLabel") then
        TweenService:Create(
            obj,
            TweenInfo.new(0.4),
            {TextTransparency = 1}
        ):Play()
    elseif obj:IsA("Frame") then
        TweenService:Create(
            obj,
            TweenInfo.new(0.4),
            {BackgroundTransparency = 1}
        ):Play()
    end
end

task.wait(0.55)
loading:Destroy()

--==================================================
-- ACTIVATION
--==================================================

local ACTIVATION_PASSWORD = string.char(
    49,
    52,
    56,
    56
)

local activated = false

local activation = Instance.new("Frame")
activation.Size = UDim2.new(0, 320, 0, 190)
activation.Position = UDim2.new(0.5, -160, 0.5, -95)
activation.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
activation.BorderSizePixel = 0
activation.Parent = ScreenGui

Instance.new("UICorner", activation).CornerRadius = UDim.new(0, 12)

local activationTitle = Instance.new("TextLabel")
activationTitle.Size = UDim2.new(1, 0, 0, 40)
activationTitle.Position = UDim2.new(0, 0, 0, 15)
activationTitle.BackgroundTransparency = 1
activationTitle.Text = "RAHERHUB"
activationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
activationTitle.TextSize = 24
activationTitle.Font = Enum.Font.GothamBold
activationTitle.Parent = activation

local activationInfo = Instance.new("TextLabel")
activationInfo.Size = UDim2.new(1, -30, 0, 25)
activationInfo.Position = UDim2.new(0, 15, 0, 52)
activationInfo.BackgroundTransparency = 1
activationInfo.Text = "Enter activation password"
activationInfo.TextColor3 = Color3.fromRGB(170, 170, 180)
activationInfo.TextSize = 13
activationInfo.Font = Enum.Font.Gotham
activationInfo.Parent = activation

local passwordBox = Instance.new("TextBox")
passwordBox.Size = UDim2.new(1, -40, 0, 38)
passwordBox.Position = UDim2.new(0, 20, 0, 82)
passwordBox.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
passwordBox.BorderSizePixel = 0
passwordBox.PlaceholderText = "Password"
passwordBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
passwordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
passwordBox.TextSize = 15
passwordBox.Font = Enum.Font.Gotham
passwordBox.ClearTextOnFocus = false
passwordBox.Text = ""
passwordBox.Parent = activation

Instance.new("UICorner", passwordBox).CornerRadius = UDim.new(0, 8)

local activateButton = Instance.new("TextButton")
activateButton.Size = UDim2.new(1, -40, 0, 38)
activateButton.Position = UDim2.new(0, 20, 0, 128)
activateButton.BackgroundColor3 = Color3.fromRGB(70, 120, 220)
activateButton.BorderSizePixel = 0
activateButton.Text = "ACTIVATE"
activateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
activateButton.TextSize = 14
activateButton.Font = Enum.Font.GothamBold
activateButton.Parent = activation

Instance.new("UICorner", activateButton).CornerRadius = UDim.new(0, 8)

local errorLabel = Instance.new("TextLabel")
errorLabel.Size = UDim2.new(1, -30, 0, 20)
errorLabel.Position = UDim2.new(0, 15, 1, -23)
errorLabel.BackgroundTransparency = 1
errorLabel.Text = ""
errorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
errorLabel.TextSize = 12
errorLabel.Font = Enum.Font.Gotham
errorLabel.Parent = activation

activateButton.MouseButton1Click:Connect(function()
    local entered = passwordBox.Text

    entered = entered:gsub("^%s+", "")
    entered = entered:gsub("%s+$", "")

    if entered == ACTIVATION_PASSWORD then
        activated = true
        activation.Visible = false
    else
        errorLabel.Text = "Invalid password"
    end
end)

repeat task.wait() until activated

--==================================================
-- MAIN WINDOW
--==================================================

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 350, 0, 420)
main.Position = UDim2.new(0.5, -175, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
main.BorderSizePixel = 0
main.Parent = ScreenGui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

--==================================================
-- TITLE BAR
--==================================================

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 18, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "RAHERHUB"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 20
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 45, 0, 45)
closeButton.Position = UDim2.new(1, -48, 0, 3)
closeButton.BackgroundTransparency = 1
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
closeButton.TextSize = 30
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

--==================================================
-- WINDOW DRAG
--==================================================

local dragging = false
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
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

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

--==================================================
-- TABS
--==================================================

local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -20, 0, 40)
tabs.Position = UDim2.new(0, 10, 0, 58)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local pages = {}

local function createTab(text, index)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(0.25, -4, 1, 0)
    button.Position = UDim2.new((index - 1) * 0.25, 2, 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(180, 180, 190)
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = tabs

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)

    return button
end

local tabMain = createTab("MAIN", 1)
local tabFeature1 = createTab("FEATURE 1", 2)
local tabFly = createTab("FLY", 3)
local tabFeature2 = createTab("FEATURE 2", 4)

--==================================================
-- PAGES
--==================================================

local function createPage()
    local page = Instance.new("Frame")

    page.Size = UDim2.new(1, -20, 1, -112)
    page.Position = UDim2.new(0, 10, 0, 108)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = main

    table.insert(pages, page)

    return page
end

local mainPage = createPage()
local feature1Page = createPage()
local flyPage = createPage()
local feature2Page = createPage()

local function showPage(index)
    for i, page in ipairs(pages) do
        page.Visible = (i == index)
    end

    local buttons = {
        tabMain,
        tabFeature1,
        tabFly,
        tabFeature2
    }

    for i, button in ipairs(buttons) do
        if i == index then
            button.BackgroundColor3 = Color3.fromRGB(70, 120, 220)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            button.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
    end
end

tabMain.MouseButton1Click:Connect(function()
    showPage(1)
end)

tabFeature1.MouseButton1Click:Connect(function()
    showPage(2)
end)

tabFly.MouseButton1Click:Connect(function()
    showPage(3)
end)

tabFeature2.MouseButton1Click:Connect(function()
    showPage(4)
end)

--==================================================
-- ESP
--==================================================

local espEnabled = false
local espObjects = {}

local function addESP(player)
    if player == LocalPlayer then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RAHER_ESP"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.FillTransparency = 0.55
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    espObjects[player] = highlight
end

local function removeESP(player)
    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if espEnabled then
                addESP(player)
            else
                removeESP(player)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if espEnabled then
            addESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 48)
espButton.Position = UDim2.new(0, 0, 0, 5)
espButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
espButton.BorderSizePixel = 0
espButton.Text = "ESP: OFF"
espButton.TextColor3 = Color3.fromRGB(230, 230, 235)
espButton.TextSize = 14
espButton.TextXAlignment = Enum.TextXAlignment.Left
espButton.Font = Enum.Font.GothamMedium
espButton.Parent = mainPage

local espPadding = Instance.new("UIPadding")
espPadding.PaddingLeft = UDim.new(0, 15)
espPadding.Parent = espButton

Instance.new("UICorner", espButton).CornerRadius = UDim.new(0, 9)

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled

    if espEnabled then
        espButton.Text = "ESP: ON"
        espButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
    else
        espButton.Text = "ESP: OFF"
        espButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    end

    updateESP()
end)

--==================================================
-- NOCLIP
--==================================================

local noclipEnabled = false

local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(1, 0, 0, 48)
noclipButton.Position = UDim2.new(0, 0, 0, 60)
noclipButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
noclipButton.BorderSizePixel = 0
noclipButton.Text = "NOCLIP: OFF"
noclipButton.TextColor3 = Color3.fromRGB(230, 230, 235)
noclipButton.TextSize = 14
noclipButton.TextXAlignment = Enum.TextXAlignment.Left
noclipButton.Font = Enum.Font.GothamMedium
noclipButton.Parent = mainPage

local noclipPadding = Instance.new("UIPadding")
noclipPadding.PaddingLeft = UDim.new(0, 15)
noclipPadding.Parent = noclipButton

Instance.new("UICorner", noclipButton).CornerRadius = UDim.new(0, 9)

noclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled

    if noclipEnabled then
        noclipButton.Text = "NOCLIP: ON"
        noclipButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
    else
        noclipButton.Text = "NOCLIP: OFF"
        noclipButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    end
end)

RunService.Stepped:Connect(function()
    if noclipEnabled then
        local character = LocalPlayer.Character

        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

--==================================================
-- SPEED
--==================================================

local speedEnabled = false
local speedValue = 16
local normalSpeed = 16

local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(1, 0, 0, 48)
speedButton.Position = UDim2.new(0, 0, 0, 115)
speedButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
speedButton.BorderSizePixel = 0
speedButton.Text = "SPEED: OFF"
speedButton.TextColor3 = Color3.fromRGB(230, 230, 235)
speedButton.TextSize = 14
speedButton.TextXAlignment = Enum.TextXAlignment.Left
speedButton.Font = Enum.Font.GothamMedium
speedButton.Parent = mainPage

local speedPadding = Instance.new("UIPadding")
speedPadding.PaddingLeft = UDim.new(0, 15)
speedPadding.Parent = speedButton

Instance.new("UICorner", speedButton).CornerRadius = UDim.new(0, 9)

speedButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled

    if speedEnabled then
        speedButton.Text = "SPEED: ON"
        speedButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
    else
        speedButton.Text = "SPEED: OFF"
        speedButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)

        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.WalkSpeed = normalSpeed
        end
    end
end)

local speedValueLabel = Instance.new("TextLabel")
speedValueLabel.Size = UDim2.new(1, 0, 0, 25)
speedValueLabel.Position = UDim2.new(0, 0, 0, 168)
speedValueLabel.BackgroundTransparency = 1
speedValueLabel.Text = "WalkSpeed: 16"
speedValueLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
speedValueLabel.TextSize = 13
speedValueLabel.Font = Enum.Font.GothamMedium
speedValueLabel.Parent = mainPage

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1, -20, 0, 8)
sliderBack.Position = UDim2.new(0, 10, 0, 202)
sliderBack.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = mainPage

Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(70, 120, 220)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBack

Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderKnob = Instance.new("TextButton")
sliderKnob.Size = UDim2.new(0, 22, 0, 22)
sliderKnob.Position = UDim2.new(0, -11, 0.5, -11)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.Text = ""
sliderKnob.AutoButtonColor = false
sliderKnob.Parent = sliderBack

Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local minSpeed = 16
local maxSpeed = 1000
local sliderDragging = false

local function updateSpeedFromPosition(x)
    local absolutePosition = sliderBack.AbsolutePosition.X
    local absoluteSize = sliderBack.AbsoluteSize.X

    local percent = (x - absolutePosition) / absoluteSize
    percent = math.clamp(percent, 0, 1)

    speedValue = math.floor(
        minSpeed + ((maxSpeed - minSpeed) * percent)
    )

    speedValue = math.clamp(speedValue, minSpeed, maxSpeed)

    local normalized =
        (speedValue - minSpeed) /
        (maxSpeed - minSpeed)

    sliderFill.Size = UDim2.new(normalized, 0, 1, 0)

    sliderKnob.Position =
        UDim2.new(normalized, -11, 0.5, -11)

    speedValueLabel.Text =
        "WalkSpeed: " .. tostring(speedValue)

    if speedEnabled then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid then
            humanoid.WalkSpeed = speedValue
        end
    end
end

sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        sliderDragging = true
    end
end)

sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        sliderDragging = true
        updateSpeedFromPosition(input.Position.X)
    end
end)

UIS.InputChanged:Connect(function(input)
    if sliderDragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            updateSpeedFromPosition(input.Position.X)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        sliderDragging = false
    end
end)

local minLabel = Instance.new("TextLabel")
minLabel.Size = UDim2.new(0, 40, 0, 20)
minLabel.Position = UDim2.new(0, 0, 0, 215)
minLabel.BackgroundTransparency = 1
minLabel.Text = "16"
minLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
minLabel.TextSize = 11
minLabel.Font = Enum.Font.Gotham
minLabel.Parent = mainPage

local maxLabel = Instance.new("TextLabel")
maxLabel.Size = UDim2.new(0, 50, 0, 20)
maxLabel.Position = UDim2.new(1, -50, 0, 215)
maxLabel.BackgroundTransparency = 1
maxLabel.Text = "1000"
maxLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
maxLabel.TextSize = 11
maxLabel.Font = Enum.Font.Gotham
maxLabel.TextXAlignment = Enum.TextXAlignment.Right
maxLabel.Parent = mainPage

RunService.Heartbeat:Connect(function()
    if speedEnabled then
        local character = LocalPlayer.Character

        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.WalkSpeed ~= speedValue then
                humanoid.WalkSpeed = speedValue
            end
        end
    end
end)

--==================================================
-- TELEPORT POINTS
--==================================================

local teleportPoints = {}
local pointNumber = 0

local pointList = Instance.new("ScrollingFrame")
pointList.Size = UDim2.new(1, 0, 0, 245)
pointList.Position = UDim2.new(0, 0, 0, 105)
pointList.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
pointList.BorderSizePixel = 0
pointList.ScrollBarThickness = 4
pointList.CanvasSize = UDim2.new(0, 0, 0, 0)
pointList.Parent = feature1Page

Instance.new("UICorner", pointList).CornerRadius = UDim.new(0, 9)

local pointLayout = Instance.new("UIListLayout")
pointLayout.Padding = UDim.new(0, 6)
pointLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
pointLayout.SortOrder = Enum.SortOrder.LayoutOrder
pointLayout.Parent = pointList

local pointPadding = Instance.new("UIPadding")
pointPadding.PaddingTop = UDim.new(0, 7)
pointPadding.PaddingBottom = UDim.new(0, 7)
pointPadding.PaddingLeft = UDim.new(0, 7)
pointPadding.PaddingRight = UDim.new(0, 7)
pointPadding.Parent = pointList

local pointInfo = Instance.new("TextLabel")
pointInfo.Size = UDim2.new(1, 0, 0, 30)
pointInfo.Position = UDim2.new(0, 0, 0, 70)
pointInfo.BackgroundTransparency = 1
pointInfo.Text = "Saved points"
pointInfo.TextColor3 = Color3.fromRGB(160, 160, 170)
pointInfo.TextSize = 12
pointInfo.Font = Enum.Font.GothamMedium
pointInfo.Parent = feature1Page

local createPointButton = Instance.new("TextButton")
createPointButton.Size = UDim2.new(1, 0, 0, 48)
createPointButton.Position = UDim2.new(0, 0, 0, 5)
createPointButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
createPointButton.BorderSizePixel = 0
createPointButton.Text = "+ CREATE POINT"
createPointButton.TextColor3 = Color3.fromRGB(255, 255, 255)
createPointButton.TextSize = 14
createPointButton.Font = Enum.Font.GothamBold
createPointButton.Parent = feature1Page

Instance.new("UICorner", createPointButton).CornerRadius = UDim.new(0, 9)

local function updatePointCanvas()
    task.wait()

    pointList.CanvasSize = UDim2.new(
        0,
        0,
        0,
        pointLayout.AbsoluteContentSize.Y + 14
    )
end

local function createPointEntry(pointData)
    local entry = Instance.new("Frame")

    entry.Size = UDim2.new(1, 0, 0, 52)
    entry.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    entry.BorderSizePixel = 0
    entry.LayoutOrder = pointData.id
    entry.Parent = pointList

    Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 8)

    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(1, -70, 1, 0)
    teleportButton.Position = UDim2.new(0, 0, 0, 0)
    teleportButton.BackgroundTransparency = 1
    teleportButton.Text =
        "  Point " .. tostring(pointData.id)
    teleportButton.TextColor3 = Color3.fromRGB(235, 235, 240)
    teleportButton.TextSize = 13
    teleportButton.TextXAlignment = Enum.TextXAlignment.Left
    teleportButton.Font = Enum.Font.GothamMedium
    teleportButton.Parent = entry

    local deleteButton = Instance.new("TextButton")
    deleteButton.Size = UDim2.new(0, 58, 0, 38)
    deleteButton.Position = UDim2.new(1, -62, 0.5, -19)
    deleteButton.BackgroundColor3 = Color3.fromRGB(130, 45, 50)
    deleteButton.BorderSizePixel = 0
    deleteButton.Text = "×"
    deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteButton.TextSize = 20
    deleteButton.Font = Enum.Font.GothamBold
    deleteButton.Parent = entry

    Instance.new("UICorner", deleteButton).CornerRadius = UDim.new(0, 7)

    teleportButton.MouseButton1Click:Connect(function()
        local character = LocalPlayer.Character

        if not character then
            return
        end

        local root = character:FindFirstChild("HumanoidRootPart")

        if not root then
            return
        end

        root.CFrame = pointData.cframe
    end)

    deleteButton.MouseButton1Click:Connect(function()
        for i, point in ipairs(teleportPoints) do
            if point == pointData then
                table.remove(teleportPoints, i)
                break
            end
        end

        entry:Destroy()
        updatePointCanvas()
    end)

    return entry
end

createPointButton.MouseButton1Click:Connect(function()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    pointNumber += 1

    local pointData = {
        id = pointNumber,
        cframe = root.CFrame
    }

    table.insert(teleportPoints, pointData)

    createPointEntry(pointData)
    updatePointCanvas()
end)

pointLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
    updatePointCanvas
)

--==================================================
-- FLY
--==================================================

local flyEnabled = false
local flyHolding = false
local flyMoveMode = false
local flyDragging = false

local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(0, 60, 0, 60)
flyButton.Position = UDim2.new(0.78, 0, 0.48, 0)
flyButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
flyButton.BorderSizePixel = 0
flyButton.Text = "↑"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.TextSize = 28
flyButton.Font = Enum.Font.GothamBold
flyButton.Visible = true
flyButton.Parent = ScreenGui

Instance.new("UICorner", flyButton).CornerRadius = UDim.new(1, 0)

flyButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        if flyMoveMode then
            flyDragging = true
        elseif flyEnabled then
            flyHolding = true
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        flyHolding = false
        flyDragging = false
    end
end)

local flyDragStart
local flyStartPos

UIS.InputChanged:Connect(function(input)
    if flyDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        if not flyDragStart then
            flyDragStart = input.Position
            flyStartPos = flyButton.Position
        end

        local delta = input.Position - flyDragStart

        flyButton.Position = UDim2.new(
            flyStartPos.X.Scale,
            flyStartPos.X.Offset + delta.X,
            flyStartPos.Y.Scale,
            flyStartPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        flyDragStart = nil
        flyStartPos = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if flyEnabled and flyHolding and not flyMoveMode then
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")

        if root then
            local velocity = root.AssemblyLinearVelocity

            root.AssemblyLinearVelocity = Vector3.new(
                velocity.X,
                45,
                velocity.Z
            )
        end
    end
end)

--==================================================
-- FLY PAGE
--==================================================

local flyJumpButton = Instance.new("TextButton")
flyJumpButton.Size = UDim2.new(1, 0, 0, 48)
flyJumpButton.Position = UDim2.new(0, 0, 0, 5)
flyJumpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
flyJumpButton.BorderSizePixel = 0
flyJumpButton.Text = "FLY JUMP: OFF"
flyJumpButton.TextColor3 = Color3.fromRGB(230, 230, 235)
flyJumpButton.TextSize = 14
flyJumpButton.TextXAlignment = Enum.TextXAlignment.Left
flyJumpButton.Font = Enum.Font.GothamMedium
flyJumpButton.Parent = flyPage

local flyJumpPadding = Instance.new("UIPadding")
flyJumpPadding.PaddingLeft = UDim.new(0, 15)
flyJumpPadding.Parent = flyJumpButton

Instance.new("UICorner", flyJumpButton).CornerRadius = UDim.new(0, 9)

flyJumpButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled

    if flyEnabled then
        flyJumpButton.Text = "FLY JUMP: ON"
        flyJumpButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
    else
        flyJumpButton.Text = "FLY JUMP: OFF"
        flyJumpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        flyHolding = false
    end
end)

local moveFlyButton = Instance.new("TextButton")
moveFlyButton.Size = UDim2.new(1, 0, 0, 48)
moveFlyButton.Position = UDim2.new(0, 0, 0, 60)
moveFlyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
moveFlyButton.BorderSizePixel = 0
moveFlyButton.Text = "MOVE FLY BUTTON: OFF"
moveFlyButton.TextColor3 = Color3.fromRGB(230, 230, 235)
moveFlyButton.TextSize = 14
moveFlyButton.TextXAlignment = Enum.TextXAlignment.Left
moveFlyButton.Font = Enum.Font.GothamMedium
moveFlyButton.Parent = flyPage

local moveFlyPadding = Instance.new("UIPadding")
moveFlyPadding.PaddingLeft = UDim.new(0, 15)
moveFlyPadding.Parent = moveFlyButton

Instance.new("UICorner", moveFlyButton).CornerRadius = UDim.new(0, 9)

moveFlyButton.MouseButton1Click:Connect(function()
    flyMoveMode = not flyMoveMode

    if flyMoveMode then
        moveFlyButton.Text = "MOVE FLY BUTTON: ON"
        moveFlyButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
        flyHolding = false
    else
        moveFlyButton.Text = "MOVE FLY BUTTON: OFF"
        moveFlyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    end
end)

--==================================================
-- FLY SIZE
--==================================================

local flySize = 60

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(1, 0, 0, 30)
sizeLabel.Position = UDim2.new(0, 0, 0, 118)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "FLY BUTTON SIZE: 60"
sizeLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
sizeLabel.TextSize = 13
sizeLabel.Font = Enum.Font.GothamMedium
sizeLabel.Parent = flyPage

local minusButton = Instance.new("TextButton")
minusButton.Size = UDim2.new(0.48, -5, 0, 42)
minusButton.Position = UDim2.new(0, 0, 0, 150)
minusButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
minusButton.BorderSizePixel = 0
minusButton.Text = "−"
minusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minusButton.TextSize = 22
minusButton.Font = Enum.Font.GothamBold
minusButton.Parent = flyPage

Instance.new("UICorner", minusButton).CornerRadius = UDim.new(0, 8)

local plusButton = Instance.new("TextButton")
plusButton.Size = UDim2.new(0.48, -5, 0, 42)
plusButton.Position = UDim2.new(0.52, 5, 0, 150)
plusButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
plusButton.BorderSizePixel = 0
plusButton.Text = "+"
plusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
plusButton.TextSize = 22
plusButton.Font = Enum.Font.GothamBold
plusButton.Parent = flyPage

Instance.new("UICorner", plusButton).CornerRadius = UDim.new(0, 8)

local function updateFlySize()
    flyButton.Size = UDim2.new(0, flySize, 0, flySize)
    sizeLabel.Text = "FLY BUTTON SIZE: " .. tostring(flySize)
end

minusButton.MouseButton1Click:Connect(function()
    flySize = math.clamp(flySize - 10, 40, 100)
    updateFlySize()
end)

plusButton.MouseButton1Click:Connect(function()
    flySize = math.clamp(flySize + 10, 40, 100)
    updateFlySize()
end)

--==================================================
-- RESET FLY
--==================================================

local resetFlyButton = Instance.new("TextButton")
resetFlyButton.Size = UDim2.new(1, 0, 0, 45)
resetFlyButton.Position = UDim2.new(0, 0, 0, 205)
resetFlyButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
resetFlyButton.BorderSizePixel = 0
resetFlyButton.Text = "RESET FLY POSITION"
resetFlyButton.TextColor3 = Color3.fromRGB(230, 230, 235)
resetFlyButton.TextSize = 13
resetFlyButton.Font = Enum.Font.GothamBold
resetFlyButton.Parent = flyPage

Instance.new("UICorner", resetFlyButton).CornerRadius = UDim.new(0, 9)

resetFlyButton.MouseButton1Click:Connect(function()
    flyButton.Position = UDim2.new(0.78, 0, 0.48, 0)

    flySize = 60
    updateFlySize()
end)

local flyInfo = Instance.new("TextLabel")
flyInfo.Size = UDim2.new(1, 0, 0, 60)
flyInfo.Position = UDim2.new(0, 0, 0, 260)
flyInfo.BackgroundTransparency = 1
flyInfo.Text = "Hold ↑ to rise.\nRelease to stop forcing upward movement."
flyInfo.TextColor3 = Color3.fromRGB(145, 145, 155)
flyInfo.TextSize = 12
flyInfo.Font = Enum.Font.Gotham
flyInfo.TextWrapped = true
flyInfo.Parent = flyPage

--==================================================
-- FEATURE 2
--==================================================

local feature2Text = Instance.new("TextLabel")
feature2Text.Size = UDim2.new(1, 0, 0, 100)
feature2Text.Position = UDim2.new(0, 0, 0, 30)
feature2Text.BackgroundTransparency = 1
feature2Text.Text = "FEATURE 2\nReserved for future testing"
feature2Text.TextColor3 = Color3.fromRGB(170, 170, 180)
feature2Text.TextSize = 15
feature2Text.Font = Enum.Font.GothamMedium
feature2Text.TextWrapped = true
feature2Text.Parent = feature2Page

--==================================================
-- FLOATING OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")
openButton.Size = UDim2.new(0, 55, 0, 55)
openButton.Position = UDim2.new(0.05, 0, 0.5, 0)
openButton.BackgroundColor3 = Color3.fromRGB(55, 105, 190)
openButton.BorderSizePixel = 0
openButton.Text = "R"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 22
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = ScreenGui

Instance.new("UICorner", openButton).CornerRadius = UDim.new(1, 0)

--==================================================
-- CLOSE / OPEN
--==================================================

closeButton.MouseButton1Click:Connect(function()
    main.Visible = false
    openButton.Visible = true
end)

local openDragging = false
local openDragStart
local openStartPos
local openMoved = false

openButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        openDragging = true
        openMoved = false
        openDragStart = input.Position
        openStartPos = openButton.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if openDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - openDragStart

        if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
            openMoved = true
        end

        openButton.Position = UDim2.new(
            openStartPos.X.Scale,
            openStartPos.X.Offset + delta.X,
            openStartPos.Y.Scale,
            openStartPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        if openDragging and not openMoved then
            main.Visible = true
            openButton.Visible = false
        end

        openDragging = false
    end
end)

--==================================================
-- START
--==================================================

showPage(1)

main.Visible = true
openButton.Visible = false

print("RAHERHUB loaded successfully")