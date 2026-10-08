repeat task.wait() until game:IsLoaded()

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "RAHERHUB"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    gui.Parent = CoreGui
end)

if not gui.Parent then
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--==================================================
-- LOADING SCREEN
--==================================================

local loading = Instance.new("Frame")
loading.Size = UDim2.new(1, 0, 1, 0)
loading.Position = UDim2.new(0, 0, 0, 0)
loading.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
loading.BorderSizePixel = 0
loading.Parent = gui

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(1, 0, 0, 60)
loadingTitle.Position = UDim2.new(0, 0, 0.37, 0)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "RAHERHUB"
loadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingTitle.TextSize = 38
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.Parent = loading

local loadingSubtitle = Instance.new("TextLabel")
loadingSubtitle.Size = UDim2.new(1, 0, 0, 30)
loadingSubtitle.Position = UDim2.new(0, 0, 0.46, 0)
loadingSubtitle.BackgroundTransparency = 1
loadingSubtitle.Text = "Initializing..."
loadingSubtitle.TextColor3 = Color3.fromRGB(150, 150, 165)
loadingSubtitle.TextSize = 15
loadingSubtitle.Font = Enum.Font.Gotham
loadingSubtitle.Parent = loading

local barBackground = Instance.new("Frame")
barBackground.Size = UDim2.new(0, 280, 0, 8)
barBackground.Position = UDim2.new(0.5, -140, 0.54, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
barBackground.BorderSizePixel = 0
barBackground.Parent = loading

local barBackgroundCorner = Instance.new("UICorner")
barBackgroundCorner.CornerRadius = UDim.new(1, 0)
barBackgroundCorner.Parent = barBackground

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
bar.BorderSizePixel = 0
bar.Parent = barBackground

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = bar

local percent = Instance.new("TextLabel")
percent.Size = UDim2.new(1, 0, 0, 25)
percent.Position = UDim2.new(0, 0, 0.57, 0)
percent.BackgroundTransparency = 1
percent.Text = "0%"
percent.TextColor3 = Color3.fromRGB(180, 180, 195)
percent.TextSize = 13
percent.Font = Enum.Font.Gotham
percent.Parent = loading

local loadingStages = {
    "Initializing...",
    "Loading interface...",
    "Preparing modules...",
    "Loading features...",
    "Almost ready..."
}

for i = 0, 100 do
    local progress = i / 100

    bar.Size = UDim2.new(progress, 0, 1, 0)
    percent.Text = tostring(i) .. "%"

    local stageIndex = math.clamp(
        math.floor(progress * #loadingStages) + 1,
        1,
        #loadingStages
    )

    loadingSubtitle.Text = loadingStages[stageIndex]

    task.wait(0.05)
end

loadingSubtitle.Text = "Ready"
task.wait(0.25)

local fadeInfo = TweenInfo.new(
    0.45,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

for _, object in ipairs(loading:GetDescendants()) do
    if object:IsA("TextLabel") then
        TweenService:Create(
            object,
            fadeInfo,
            {TextTransparency = 1}
        ):Play()

    elseif object:IsA("Frame") then
        TweenService:Create(
            object,
            fadeInfo,
            {BackgroundTransparency = 1}
        ):Play()
    end
end

TweenService:Create(
    loading,
    fadeInfo,
    {BackgroundTransparency = 1}
):Play()

task.wait(0.5)
loading:Destroy()

--==================================================
-- ACTIVATION
--==================================================

local function decodePart(data, key)
    local result = {}

    for i = 1, #data do
        result[i] = string.char(data[i] - key)
    end

    return table.concat(result)
end

-- 1 / 4 / 8 / 8
local partA = decodePart({50}, 1)
local partB = decodePart({55}, 3)
local partC = decodePart({56}, 8)
local partD = decodePart({56}, 8)

local ACTIVATION_PASSWORD =
    partA .. partB .. partC .. partD

local activation = Instance.new("Frame")
activation.Size = UDim2.new(0, 320, 0, 190)
activation.Position = UDim2.new(0.5, -160, 0.5, -95)
activation.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
activation.BorderSizePixel = 0
activation.Parent = gui

local activationCorner = Instance.new("UICorner")
activationCorner.CornerRadius = UDim.new(0, 14)
activationCorner.Parent = activation

local activationStroke = Instance.new("UIStroke")
activationStroke.Color = Color3.fromRGB(80, 80, 100)
activationStroke.Thickness = 1
activationStroke.Parent = activation

local activationTitle = Instance.new("TextLabel")
activationTitle.Size = UDim2.new(1, -20, 0, 40)
activationTitle.Position = UDim2.new(0, 10, 0, 10)
activationTitle.BackgroundTransparency = 1
activationTitle.Text = "RAHERHUB"
activationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
activationTitle.TextSize = 24
activationTitle.Font = Enum.Font.GothamBold
activationTitle.Parent = activation

local activationSubtitle = Instance.new("TextLabel")
activationSubtitle.Size = UDim2.new(1, -20, 0, 25)
activationSubtitle.Position = UDim2.new(0, 10, 0, 48)
activationSubtitle.BackgroundTransparency = 1
activationSubtitle.Text = "Введите пароль активации"
activationSubtitle.TextColor3 = Color3.fromRGB(170, 170, 180)
activationSubtitle.TextSize = 14
activationSubtitle.Font = Enum.Font.Gotham
activationSubtitle.Parent = activation

local passwordBox = Instance.new("TextBox")
passwordBox.Size = UDim2.new(1, -40, 0, 42)
passwordBox.Position = UDim2.new(0, 20, 0, 78)
passwordBox.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
passwordBox.BorderSizePixel = 0
passwordBox.PlaceholderText = "Пароль"
passwordBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
passwordBox.Text = ""
passwordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
passwordBox.TextSize = 17
passwordBox.Font = Enum.Font.Gotham
passwordBox.ClearTextOnFocus = false
passwordBox.Parent = activation

local passwordCorner = Instance.new("UICorner")
passwordCorner.CornerRadius = UDim.new(0, 9)
passwordCorner.Parent = passwordBox

local activateButton = Instance.new("TextButton")
activateButton.Size = UDim2.new(1, -40, 0, 38)
activateButton.Position = UDim2.new(0, 20, 0, 130)
activateButton.BackgroundColor3 = Color3.fromRGB(55, 120, 255)
activateButton.BorderSizePixel = 0
activateButton.Text = "АКТИВИРОВАТЬ"
activateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
activateButton.TextSize = 15
activateButton.Font = Enum.Font.GothamBold
activateButton.Parent = activation

local activateCorner = Instance.new("UICorner")
activateCorner.CornerRadius = UDim.new(0, 9)
activateCorner.Parent = activateButton

local activationError = Instance.new("TextLabel")
activationError.Size = UDim2.new(1, -40, 0, 20)
activationError.Position = UDim2.new(0, 20, 1, -25)
activationError.BackgroundTransparency = 1
activationError.Text = ""
activationError.TextColor3 = Color3.fromRGB(255, 90, 90)
activationError.TextSize = 12
activationError.Font = Enum.Font.Gotham
activationError.Parent = activation

local activated = false

local function checkPassword()
    if passwordBox.Text == ACTIVATION_PASSWORD then
        activated = true

        activationError.TextColor3 =
            Color3.fromRGB(80, 220, 120)

        activationError.Text = "Активация успешна"

        task.wait(0.3)

        activation.Visible = false

        return true
    end

    activationError.TextColor3 =
        Color3.fromRGB(255, 90, 90)

    activationError.Text = "Неверный пароль"
    passwordBox.Text = ""

    return false
end

activateButton.Activated:Connect(checkPassword)

passwordBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        checkPassword()
    end
end)

repeat
    task.wait()
until activated

activation:Destroy()

--==================================================
-- MAIN GUI
--==================================================

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 350, 0, 420)
main.Position = UDim2.new(0.5, -175, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 70, 90)
mainStroke.Thickness = 1
mainStroke.Parent = main

--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 45)
title.Position = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.Text = "RAHERHUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 23
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 38, 0, 38)
closeButton.Position = UDim2.new(1, -45, 0, 8)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 26
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = main

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeButton

--==================================================
-- TABS
--==================================================

local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(1, -20, 0, 42)
tabs.Position = UDim2.new(0, 10, 0, 52)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabs

local function makeTab(text)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 78, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 43)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(210, 210, 220)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.Parent = tabs

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    return button
end

local mainTab = makeTab("MAIN")
local feature1Tab = makeTab("FEATURE 1")
local flyTab = makeTab("FLY")
local feature2Tab = makeTab("FEATURE 2")

--==================================================
-- PAGES
--==================================================

local pages = Instance.new("Frame")
pages.Size = UDim2.new(1, -20, 1, -105)
pages.Position = UDim2.new(0, 10, 0, 100)
pages.BackgroundTransparency = 1
pages.Parent = main

local function makePage()
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = pages

    return page
end

local pageMain = makePage()
local pageFeature1 = makePage()
local pageFly = makePage()
local pageFeature2 = makePage()

pageMain.Visible = true

local function switchPage(page)
    pageMain.Visible = false
    pageFeature1.Visible = false
    pageFly.Visible = false
    pageFeature2.Visible = false

    page.Visible = true
end

mainTab.Activated:Connect(function()
    switchPage(pageMain)
end)

feature1Tab.Activated:Connect(function()
    switchPage(pageFeature1)
end)

flyTab.Activated:Connect(function()
    switchPage(pageFly)
end)

feature2Tab.Activated:Connect(function()
    switchPage(pageFeature2)
end)

--==================================================
-- TOGGLE CREATOR
--==================================================

local function makeToggle(parent, text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 48)
    button.Position = UDim2.new(0, 0, 0, y)
    button.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    button.BorderSizePixel = 0
    button.Text = text .. " : OFF"
    button.TextColor3 = Color3.fromRGB(230, 230, 235)
    button.TextSize = 15
    button.Font = Enum.Font.GothamBold
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    return button
end

--==================================================
-- ESP
--==================================================

local espEnabled = false
local highlights = {}

local function addESP(player)
    if player == LocalPlayer then
        return
    end

    if highlights[player] then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RAHER_ESP"
    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.Parent = gui

    highlights[player] = highlight
end

local function removeESP(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
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

local espButton = makeToggle(pageMain, "ESP", 10)

espButton.Activated:Connect(function()
    espEnabled = not espEnabled

    if espEnabled then
        espButton.Text = "ESP : ON"
        espButton.BackgroundColor3 =
            Color3.fromRGB(45, 130, 75)
    else
        espButton.Text = "ESP : OFF"
        espButton.BackgroundColor3 =
            Color3.fromRGB(34, 34, 42)
    end

    updateESP()
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if espEnabled then
            addESP(player)
        end
    end)
end)

--==================================================
-- NOCLIP
--==================================================

local noclipEnabled = false

local noclipButton =
    makeToggle(pageMain, "NOCLIP", 68)

noclipButton.Activated:Connect(function()
    noclipEnabled = not noclipEnabled

    if noclipEnabled then
        noclipButton.Text = "NOCLIP : ON"
        noclipButton.BackgroundColor3 =
            Color3.fromRGB(45, 130, 75)
    else
        noclipButton.Text = "NOCLIP : OFF"
        noclipButton.BackgroundColor3 =
            Color3.fromRGB(34, 34, 42)
    end
end)

RunService.Stepped:Connect(function()
    if not noclipEnabled then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

--==================================================
-- FLY VARIABLES
--==================================================

local flyEnabled = false
local flyHolding = false

local flyMoveMode = false
local flyDragging = false
local flyDragStart
local flyStartPosition

local flyButtonSize = 60

--==================================================
-- FLY BUTTON
--==================================================

local flyButton = Instance.new("TextButton")
flyButton.Name = "FlyButton"
flyButton.Size =
    UDim2.new(0, flyButtonSize, 0, flyButtonSize)

flyButton.Position =
    UDim2.new(0.78, 0, 0.48, 0)

flyButton.AnchorPoint =
    Vector2.new(0.5, 0.5)

flyButton.BackgroundColor3 =
    Color3.fromRGB(55, 120, 255)

flyButton.BorderSizePixel = 0
flyButton.Text = "↑"
flyButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

flyButton.TextSize = 30
flyButton.Font = Enum.Font.GothamBold
flyButton.Visible = true
flyButton.Parent = gui

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(1, 0)
flyCorner.Parent = flyButton

local flyStroke = Instance.new("UIStroke")
flyStroke.Color = Color3.fromRGB(255, 255, 255)
flyStroke.Thickness = 1
flyStroke.Transparency = 0.5
flyStroke.Parent = flyButton

local function updateFlyButton()
    flyButton.Size =
        UDim2.new(0, flyButtonSize, 0, flyButtonSize)
end

--==================================================
-- FLY TOGGLE
--==================================================

local flyToggle =
    makeToggle(pageMain, "FLY JUMP", 126)

flyToggle.Activated:Connect(function()
    flyEnabled = not flyEnabled

    if flyEnabled then
        flyToggle.Text = "FLY JUMP : ON"

        flyToggle.BackgroundColor3 =
            Color3.fromRGB(45, 130, 75)

        flyButton.Visible = true
    else
        flyToggle.Text = "FLY JUMP : OFF"

        flyToggle.BackgroundColor3 =
            Color3.fromRGB(34, 34, 42)

        flyHolding = false
    end
end)

--==================================================
-- FLY HOLD
--==================================================

flyButton.InputBegan:Connect(function(input)
    if flyMoveMode then
        return
    end

    if not flyEnabled then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyHolding = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyHolding = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not flyEnabled then
        return
    end

    if not flyHolding then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    local root =
        character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local velocity = root.AssemblyLinearVelocity

    root.AssemblyLinearVelocity =
        Vector3.new(
            velocity.X,
            45,
            velocity.Z
        )
end)

--==================================================
-- FLY SETTINGS
--==================================================

local flyMoveToggle =
    makeToggle(
        pageFly,
        "ПЕРЕМЕЩЕНИЕ КНОПКИ",
        10
    )

flyMoveToggle.Activated:Connect(function()
    flyMoveMode = not flyMoveMode

    if flyMoveMode then
        flyMoveToggle.Text =
            "ПЕРЕМЕЩЕНИЕ : ON"

        flyMoveToggle.BackgroundColor3 =
            Color3.fromRGB(55, 120, 255)
    else
        flyMoveToggle.Text =
            "ПЕРЕМЕЩЕНИЕ : OFF"

        flyMoveToggle.BackgroundColor3 =
            Color3.fromRGB(34, 34, 42)
    end
end)

--==================================================
-- FLY BUTTON DRAG
--==================================================

flyButton.InputBegan:Connect(function(input)
    if not flyMoveMode then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyDragging = true
        flyDragStart = input.Position
        flyStartPosition = flyButton.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not flyDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta =
            input.Position - flyDragStart

        flyButton.Position =
            UDim2.new(
                flyStartPosition.X.Scale,
                flyStartPosition.X.Offset + delta.X,

                flyStartPosition.Y.Scale,
                flyStartPosition.Y.Offset + delta.Y
            )
    end
end)

UIS.InputEnded:Connect(function(input)
    if not flyDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyDragging = false
    end
end)

--==================================================
-- FLY SIZE
--==================================================

local sizeMinus = Instance.new("TextButton")
sizeMinus.Size = UDim2.new(0.48, 0, 0, 45)
sizeMinus.Position = UDim2.new(0, 0, 0, 68)
sizeMinus.BackgroundColor3 =
    Color3.fromRGB(34, 34, 42)

sizeMinus.BorderSizePixel = 0
sizeMinus.Text = "−"
sizeMinus.TextColor3 =
    Color3.fromRGB(255, 255, 255)

sizeMinus.TextSize = 25
sizeMinus.Font = Enum.Font.GothamBold
sizeMinus.Parent = pageFly

local sizeMinusCorner = Instance.new("UICorner")
sizeMinusCorner.CornerRadius = UDim.new(0, 9)
sizeMinusCorner.Parent = sizeMinus

local sizePlus = Instance.new("TextButton")
sizePlus.Size = UDim2.new(0.48, 0, 0, 45)
sizePlus.Position = UDim2.new(0.52, 0, 0, 68)
sizePlus.BackgroundColor3 =
    Color3.fromRGB(34, 34, 42)

sizePlus.BorderSizePixel = 0
sizePlus.Text = "+"
sizePlus.TextColor3 =
    Color3.fromRGB(255, 255, 255)

sizePlus.TextSize = 25
sizePlus.Font = Enum.Font.GothamBold
sizePlus.Parent = pageFly

local sizePlusCorner = Instance.new("UICorner")
sizePlusCorner.CornerRadius = UDim.new(0, 9)
sizePlusCorner.Parent = sizePlus

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(1, 0, 0, 25)
sizeLabel.Position = UDim2.new(0, 0, 0, 118)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Размер: 60"
sizeLabel.TextColor3 =
    Color3.fromRGB(200, 200, 210)

sizeLabel.TextSize = 14
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.Parent = pageFly

sizeMinus.Activated:Connect(function()
    flyButtonSize =
        math.max(40, flyButtonSize - 5)

    sizeLabel.Text =
        "Размер: " .. flyButtonSize

    updateFlyButton()
end)

sizePlus.Activated:Connect(function()
    flyButtonSize =
        math.min(100, flyButtonSize + 5)

    sizeLabel.Text =
        "Размер: " .. flyButtonSize

    updateFlyButton()
end)

--==================================================
-- RESET FLY BUTTON
--==================================================

local resetFly = Instance.new("TextButton")
resetFly.Size = UDim2.new(1, 0, 0, 45)
resetFly.Position = UDim2.new(0, 0, 0, 155)
resetFly.BackgroundColor3 =
    Color3.fromRGB(34, 34, 42)

resetFly.BorderSizePixel = 0
resetFly.Text = "СБРОСИТЬ ПОЗИЦИЮ"
resetFly.TextColor3 =
    Color3.fromRGB(230, 230, 235)

resetFly.TextSize = 14
resetFly.Font = Enum.Font.GothamBold
resetFly.Parent = pageFly

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 9)
resetCorner.Parent = resetFly

resetFly.Activated:Connect(function()
    flyButton.Position =
        UDim2.new(0.78, 0, 0.48, 0)

    flyButtonSize = 60

    sizeLabel.Text = "Размер: 60"

    updateFlyButton()
end)

local flyInfo = Instance.new("TextLabel")
flyInfo.Size = UDim2.new(1, 0, 0, 70)
flyInfo.Position = UDim2.new(0, 0, 0, 215)
flyInfo.BackgroundTransparency = 1

flyInfo.Text =
    "Включи FLY JUMP на вкладке MAIN.\n" ..
    "Зажми ↑ — персонаж поднимается.\n" ..
    "Отпусти — персонаж падает."

flyInfo.TextColor3 =
    Color3.fromRGB(155, 155, 165)

flyInfo.TextSize = 13
flyInfo.Font = Enum.Font.Gotham
flyInfo.TextWrapped = true
flyInfo.Parent = pageFly

--==================================================
-- FEATURE 1
--==================================================

local feature1Text = Instance.new("TextLabel")
feature1Text.Size = UDim2.new(1, 0, 0, 100)
feature1Text.Position = UDim2.new(0, 0, 0, 30)
feature1Text.BackgroundTransparency = 1
feature1Text.Text = "FEATURE 1\nПока свободно"
feature1Text.TextColor3 =
    Color3.fromRGB(180, 180, 190)

feature1Text.TextSize = 18
feature1Text.Font = Enum.Font.GothamBold
feature1Text.Parent = pageFeature1

--==================================================
-- FEATURE 2
--==================================================

local feature2Text = Instance.new("TextLabel")
feature2Text.Size = UDim2.new(1, 0, 0, 100)
feature2Text.Position = UDim2.new(0, 0, 0, 30)
feature2Text.BackgroundTransparency = 1
feature2Text.Text = "FEATURE 2\nПока свободно"
feature2Text.TextColor3 =
    Color3.fromRGB(180, 180, 190)

feature2Text.TextSize = 18
feature2Text.Font = Enum.Font.GothamBold
feature2Text.Parent = pageFeature2

--==================================================
-- OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.new(0, 55, 0, 55)
openButton.Position = UDim2.new(0.15, 0, 0.5, 0)
openButton.AnchorPoint = Vector2.new(0.5, 0.5)

openButton.BackgroundColor3 =
    Color3.fromRGB(55, 120, 255)

openButton.BorderSizePixel = 0
openButton.Text = "R"
openButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

openButton.TextSize = 22
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton

local openStroke = Instance.new("UIStroke")
openStroke.Color = Color3.fromRGB(255, 255, 255)
openStroke.Transparency = 0.5
openStroke.Parent = openButton

--==================================================
-- CLOSE MENU
--==================================================

closeButton.Activated:Connect(function()
    main.Visible = false
    openButton.Visible = true
end)

--==================================================
-- OPEN BUTTON DRAG + CLICK
--==================================================

local openDragging = false
local openMoved = false

local openDragStart
local openStartPosition

openButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        openDragging = true
        openMoved = false

        openDragStart = input.Position
        openStartPosition = openButton.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not openDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta =
            input.Position - openDragStart

        if math.abs(delta.X) > 8
            or math.abs(delta.Y) > 8 then

            openMoved = true
        end

        if openMoved then
            openButton.Position =
                UDim2.new(
                    openStartPosition.X.Scale,
                    openStartPosition.X.Offset + delta.X,

                    openStartPosition.Y.Scale,
                    openStartPosition.Y.Offset + delta.Y
                )
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if not openDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        openDragging = false

        if not openMoved then
            main.Visible = true
            openButton.Visible = false
        end

        openMoved = false
    end
end)

--==================================================
-- MAIN WINDOW DRAG
--==================================================

local mainDragging = false
local mainDragStart
local mainStartPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        mainDragging = true

        mainDragStart = input.Position
        mainStartPosition = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not mainDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta =
            input.Position - mainDragStart

        main.Position =
            UDim2.new(
                mainStartPosition.X.Scale,
                mainStartPosition.X.Offset + delta.X,

                mainStartPosition.Y.Scale,
                mainStartPosition.Y.Offset + delta.Y
            )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        mainDragging = false
    end
end)

--==================================================
-- START
--==================================================

main.Visible = true
openButton.Visible = false

print("RAHERHUB loaded successfully")