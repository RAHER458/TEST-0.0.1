repeat task.wait() until game:IsLoaded()

--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--// GUI
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
loading.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
loading.BorderSizePixel = 0
loading.ZIndex = 100
loading.Parent = gui

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(1, 0, 0, 50)
loadingTitle.Position = UDim2.new(0, 0, 0.35, 0)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "RAHERHUB"
loadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingTitle.TextSize = 34
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.ZIndex = 101
loadingTitle.Parent = loading

local loadingSubtitle = Instance.new("TextLabel")
loadingSubtitle.Size = UDim2.new(1, 0, 0, 30)
loadingSubtitle.Position = UDim2.new(0, 0, 0.43, 0)
loadingSubtitle.BackgroundTransparency = 1
loadingSubtitle.Text = "Initializing..."
loadingSubtitle.TextColor3 = Color3.fromRGB(170, 170, 180)
loadingSubtitle.TextSize = 16
loadingSubtitle.Font = Enum.Font.Gotham
loadingSubtitle.ZIndex = 101
loadingSubtitle.Parent = loading

local barBackground = Instance.new("Frame")
barBackground.Size = UDim2.new(0, 280, 0, 8)
barBackground.Position = UDim2.new(0.5, -140, 0.51, 0)
barBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
barBackground.BorderSizePixel = 0
barBackground.ZIndex = 101
barBackground.Parent = loading

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBackground

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 0, 1, 0)
bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bar.BorderSizePixel = 0
bar.ZIndex = 102
bar.Parent = barBackground

local barCorner2 = Instance.new("UICorner")
barCorner2.CornerRadius = UDim.new(1, 0)
barCorner2.Parent = bar

local percent = Instance.new("TextLabel")
percent.Size = UDim2.new(1, 0, 0, 25)
percent.Position = UDim2.new(0, 0, 0.54, 0)
percent.BackgroundTransparency = 1
percent.Text = "0%"
percent.TextColor3 = Color3.fromRGB(150, 150, 160)
percent.TextSize = 13
percent.Font = Enum.Font.Gotham
percent.ZIndex = 101
percent.Parent = loading

local loadingStages = {
    "Initializing...",
    "Loading interface...",
    "Preparing modules...",
    "Loading features...",
    "Almost ready..."
}

for i = 0, 100 do
    bar.Size = UDim2.new(i / 100, 0, 1, 0)
    percent.Text = tostring(i) .. "%"

    local stageIndex = math.clamp(
        math.floor(i / 20) + 1,
        1,
        #loadingStages
    )

    loadingSubtitle.Text = loadingStages[stageIndex]

    task.wait(0.05)
end

task.wait(0.2)

local fadeInfo = TweenInfo.new(
    0.45,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

TweenService:Create(
    loadingTitle,
    fadeInfo,
    {TextTransparency = 1}
):Play()

TweenService:Create(
    loadingSubtitle,
    fadeInfo,
    {TextTransparency = 1}
):Play()

TweenService:Create(
    percent,
    fadeInfo,
    {TextTransparency = 1}
):Play()

TweenService:Create(
    barBackground,
    fadeInfo,
    {BackgroundTransparency = 1}
):Play()

TweenService:Create(
    bar,
    fadeInfo,
    {BackgroundTransparency = 1}
):Play()

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

local activated = false

-- Пароль: 1488
local ACTIVATION_PASSWORD = string.char(
    49, -- 1
    52, -- 4
    56, -- 8
    56  -- 8
)

local activation = Instance.new("Frame")
activation.Size = UDim2.new(0, 320, 0, 190)
activation.Position = UDim2.new(0.5, -160, 0.5, -95)
activation.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
activation.BorderSizePixel = 0
activation.ZIndex = 50
activation.Parent = gui

local activationCorner = Instance.new("UICorner")
activationCorner.CornerRadius = UDim.new(0, 12)
activationCorner.Parent = activation

local activationTitle = Instance.new("TextLabel")
activationTitle.Size = UDim2.new(1, -20, 0, 35)
activationTitle.Position = UDim2.new(0, 10, 0, 12)
activationTitle.BackgroundTransparency = 1
activationTitle.Text = "RAHERHUB"
activationTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
activationTitle.TextSize = 23
activationTitle.Font = Enum.Font.GothamBold
activationTitle.ZIndex = 51
activationTitle.Parent = activation

local activationSubtitle = Instance.new("TextLabel")
activationSubtitle.Size = UDim2.new(1, -20, 0, 25)
activationSubtitle.Position = UDim2.new(0, 10, 0, 47)
activationSubtitle.BackgroundTransparency = 1
activationSubtitle.Text = "Введите пароль активации"
activationSubtitle.TextColor3 = Color3.fromRGB(160, 160, 170)
activationSubtitle.TextSize = 14
activationSubtitle.Font = Enum.Font.Gotham
activationSubtitle.ZIndex = 51
activationSubtitle.Parent = activation

local passwordBox = Instance.new("TextBox")
passwordBox.Size = UDim2.new(1, -40, 0, 38)
passwordBox.Position = UDim2.new(0, 20, 0, 78)
passwordBox.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
passwordBox.BorderSizePixel = 0
passwordBox.PlaceholderText = "Пароль..."
passwordBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
passwordBox.Text = ""
passwordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
passwordBox.TextSize = 15
passwordBox.Font = Enum.Font.Gotham
passwordBox.ClearTextOnFocus = false
passwordBox.ZIndex = 51
passwordBox.Parent = activation

local passwordCorner = Instance.new("UICorner")
passwordCorner.CornerRadius = UDim.new(0, 8)
passwordCorner.Parent = passwordBox

local activateButton = Instance.new("TextButton")
activateButton.Size = UDim2.new(1, -40, 0, 38)
activateButton.Position = UDim2.new(0, 20, 0, 123)
activateButton.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
activateButton.BorderSizePixel = 0
activateButton.Text = "АКТИВИРОВАТЬ"
activateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
activateButton.TextSize = 14
activateButton.Font = Enum.Font.GothamBold
activateButton.ZIndex = 51
activateButton.Parent = activation

local activateCorner = Instance.new("UICorner")
activateCorner.CornerRadius = UDim.new(0, 8)
activateCorner.Parent = activateButton

local errorLabel = Instance.new("TextLabel")
errorLabel.Size = UDim2.new(1, -40, 0, 20)
errorLabel.Position = UDim2.new(0, 20, 0, 164)
errorLabel.BackgroundTransparency = 1
errorLabel.Text = ""
errorLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
errorLabel.TextSize = 12
errorLabel.Font = Enum.Font.Gotham
errorLabel.ZIndex = 51
errorLabel.Parent = activation


local function checkPassword()

    local entered = passwordBox.Text

    entered = entered:gsub("^%s+", "")
    entered = entered:gsub("%s+$", "")

    if entered == ACTIVATION_PASSWORD then

        activated = true

        errorLabel.TextColor3 = Color3.fromRGB(100, 255, 130)
        errorLabel.Text = "Активация успешна"

        task.wait(0.3)

        activation.Visible = false

    else

        errorLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
        errorLabel.Text = "Неверный пароль"

    end
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


--==================================================
-- MAIN GUI
--==================================================

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 350, 0, 420)
main.Position = UDim2.new(0.5, -175, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
main.BorderSizePixel = 0
main.Active = true
main.ZIndex = 10
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main


--==================================================
-- TITLE
--==================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 45)
title.Position = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.Text = "RAHERHUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 11
title.Parent = main


--==================================================
-- CLOSE BUTTON
--==================================================

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 38, 0, 38)
closeButton.Position = UDim2.new(1, -45, 0, 8)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 25
closeButton.Font = Enum.Font.GothamBold
closeButton.ZIndex = 12
closeButton.Parent = main

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton


--==================================================
-- TABS
--==================================================

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -20, 0, 40)
tabFrame.Position = UDim2.new(0, 10, 0, 50)
tabFrame.BackgroundTransparency = 1
tabFrame.ZIndex = 11
tabFrame.Parent = main

local tabs = {}
local pages = {}

local tabNames = {
    "MAIN",
    "FEATURE 1",
    "FLY",
    "FEATURE 2"
}

for i, tabName in ipairs(tabNames) do

    local tab = Instance.new("TextButton")

    tab.Size = UDim2.new(0.25, -4, 1, 0)
    tab.Position = UDim2.new((i - 1) * 0.25, 0, 0, 0)

    tab.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    tab.BorderSizePixel = 0
    tab.Text = tabName
    tab.TextColor3 = Color3.fromRGB(180, 180, 190)
    tab.TextSize = 11
    tab.Font = Enum.Font.GothamBold
    tab.ZIndex = 12
    tab.Parent = tabFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = tab

    tabs[i] = tab

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -20, 1, -105)
    page.Position = UDim2.new(0, 10, 0, 100)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ZIndex = 11
    page.Parent = main

    pages[i] = page
end


local function showPage(index)

    for i, page in ipairs(pages) do

        page.Visible = (i == index)

        if i == index then
            tabs[i].BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            tabs[i].TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            tabs[i].BackgroundColor3 = Color3.fromRGB(32, 32, 42)
            tabs[i].TextColor3 = Color3.fromRGB(180, 180, 190)
        end

    end

end


for i, tab in ipairs(tabs) do

    tab.Activated:Connect(function()
        showPage(i)
    end)

end


--==================================================
-- MAIN PAGE
--==================================================

local mainPage = pages[1]

local mainInfo = Instance.new("TextLabel")
mainInfo.Size = UDim2.new(1, 0, 0, 35)
mainInfo.Position = UDim2.new(0, 0, 0, 0)
mainInfo.BackgroundTransparency = 1
mainInfo.Text = "Main features"
mainInfo.TextColor3 = Color3.fromRGB(170, 170, 180)
mainInfo.TextSize = 13
mainInfo.Font = Enum.Font.Gotham
mainInfo.TextXAlignment = Enum.TextXAlignment.Left
mainInfo.ZIndex = 12
mainInfo.Parent = mainPage


--==================================================
-- ESP
--==================================================

local espEnabled = false
local highlights = {}

local function addESP(player)

    if player == LocalPlayer then
        return
    end

    if not player.Character then
        return
    end

    if highlights[player] then
        highlights[player]:Destroy()
    end

    local highlight = Instance.new("Highlight")

    highlight.Name = "RAHER_ESP"
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(255, 70, 70)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0

    highlight.Parent = player.Character

    highlights[player] = highlight

end


local function removeESP(player)

    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end

end


local function updateESP()

    if espEnabled then

        for _, player in ipairs(Players:GetPlayers()) do

            if player ~= LocalPlayer then
                addESP(player)
            end

        end

    else

        for player in pairs(highlights) do
            removeESP(player)
        end

    end

end


local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 45)
espButton.Position = UDim2.new(0, 0, 0, 45)
espButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
espButton.BorderSizePixel = 0
espButton.Text = "ESP  [OFF]"
espButton.TextColor3 = Color3.fromRGB(230, 230, 235)
espButton.TextSize = 14
espButton.Font = Enum.Font.GothamBold
espButton.ZIndex = 12
espButton.Parent = mainPage

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 8)
espCorner.Parent = espButton


espButton.Activated:Connect(function()

    espEnabled = not espEnabled

    if espEnabled then
        espButton.Text = "ESP  [ON]"
        espButton.BackgroundColor3 = Color3.fromRGB(60, 80, 65)
    else
        espButton.Text = "ESP  [OFF]"
        espButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
    end

    updateESP()

end)


Players.PlayerAdded:Connect(function(player)

    player.CharacterAdded:Connect(function()

        task.wait(1)

        if espEnabled then
            addESP(player)
        end

    end)

end)


Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)


--==================================================
-- NOCLIP
--==================================================

local noclipEnabled = false

local noclipButton = Instance.new("TextButton")
noclipButton.Size = UDim2.new(1, 0, 0, 45)
noclipButton.Position = UDim2.new(0, 0, 0, 100)
noclipButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
noclipButton.BorderSizePixel = 0
noclipButton.Text = "NOCLIP  [OFF]"
noclipButton.TextColor3 = Color3.fromRGB(230, 230, 235)
noclipButton.TextSize = 14
noclipButton.Font = Enum.Font.GothamBold
noclipButton.ZIndex = 12
noclipButton.Parent = mainPage

local noclipCorner = Instance.new("UICorner")
noclipCorner.CornerRadius = UDim.new(0, 8)
noclipCorner.Parent = noclipButton


noclipButton.Activated:Connect(function()

    noclipEnabled = not noclipEnabled

    if noclipEnabled then
        noclipButton.Text = "NOCLIP  [ON]"
        noclipButton.BackgroundColor3 = Color3.fromRGB(60, 80, 65)
    else
        noclipButton.Text = "NOCLIP  [OFF]"
        noclipButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
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

    for _, object in ipairs(character:GetDescendants()) do

        if object:IsA("BasePart") then
            object.CanCollide = false
        end

    end

end)


--==================================================
-- FLY
--==================================================

local flyEnabled = false
local flyHolding = false
local flyMoveMode = false
local flyDragging = false

local flyDragStart
local flyStartPosition

local flyButtonSize = 60


local flyButton = Instance.new("TextButton")

flyButton.Size = UDim2.new(0, flyButtonSize, 0, flyButtonSize)
flyButton.Position = UDim2.new(0.78, 0, 0.48, 0)

flyButton.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
flyButton.BorderSizePixel = 0
flyButton.Text = "↑"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.TextSize = 30
flyButton.Font = Enum.Font.GothamBold
flyButton.ZIndex = 100
flyButton.Parent = gui

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(1, 0)
flyCorner.Parent = flyButton


flyButton.InputBegan:Connect(function(input)

    if flyMoveMode then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyHolding = true

    end

end)


UIS.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

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

    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local velocity = root.AssemblyLinearVelocity

    root.AssemblyLinearVelocity = Vector3.new(
        velocity.X,
        45,
        velocity.Z
    )

end)


--==================================================
-- FLY SETTINGS
--==================================================

local flyPage = pages[3]

local flyTitle = Instance.new("TextLabel")
flyTitle.Size = UDim2.new(1, 0, 0, 35)
flyTitle.BackgroundTransparency = 1
flyTitle.Text = "FLY SETTINGS"
flyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
flyTitle.TextSize = 16
flyTitle.Font = Enum.Font.GothamBold
flyTitle.TextXAlignment = Enum.TextXAlignment.Left
flyTitle.ZIndex = 12
flyTitle.Parent = flyPage


local flyToggle = Instance.new("TextButton")
flyToggle.Size = UDim2.new(1, 0, 0, 45)
flyToggle.Position = UDim2.new(0, 0, 0, 45)
flyToggle.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
flyToggle.BorderSizePixel = 0
flyToggle.Text = "FLY JUMP  [OFF]"
flyToggle.TextColor3 = Color3.fromRGB(230, 230, 235)
flyToggle.TextSize = 14
flyToggle.Font = Enum.Font.GothamBold
flyToggle.ZIndex = 12
flyToggle.Parent = flyPage

local flyToggleCorner = Instance.new("UICorner")
flyToggleCorner.CornerRadius = UDim.new(0, 8)
flyToggleCorner.Parent = flyToggle


flyToggle.Activated:Connect(function()

    flyEnabled = not flyEnabled

    if flyEnabled then

        flyToggle.Text = "FLY JUMP  [ON]"
        flyToggle.BackgroundColor3 = Color3.fromRGB(60, 80, 65)

    else

        flyToggle.Text = "FLY JUMP  [OFF]"
        flyToggle.BackgroundColor3 = Color3.fromRGB(32, 32, 42)

        flyHolding = false

    end

end)


--==================================================
-- MOVE FLY BUTTON
--==================================================

local moveButton = Instance.new("TextButton")
moveButton.Size = UDim2.new(1, 0, 0, 45)
moveButton.Position = UDim2.new(0, 0, 0, 100)
moveButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
moveButton.BorderSizePixel = 0
moveButton.Text = "MOVE FLY BUTTON  [OFF]"
moveButton.TextColor3 = Color3.fromRGB(230, 230, 235)
moveButton.TextSize = 13
moveButton.Font = Enum.Font.GothamBold
moveButton.ZIndex = 12
moveButton.Parent = flyPage

local moveCorner = Instance.new("UICorner")
moveCorner.CornerRadius = UDim.new(0, 8)
moveCorner.Parent = moveButton


moveButton.Activated:Connect(function()

    flyMoveMode = not flyMoveMode

    if flyMoveMode then

        moveButton.Text = "MOVE FLY BUTTON  [ON]"
        moveButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)

    else

        moveButton.Text = "MOVE FLY BUTTON  [OFF]"
        moveButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)

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
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

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
        or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - flyDragStart

        flyButton.Position = UDim2.new(
            flyStartPosition.X.Scale,
            flyStartPosition.X.Offset + delta.X,
            flyStartPosition.Y.Scale,
            flyStartPosition.Y.Offset + delta.Y
        )

    end

end)


UIS.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyDragging = false

    end

end)


--==================================================
-- SIZE
--==================================================

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(0.5, 0, 0, 35)
sizeLabel.Position = UDim2.new(0, 0, 0, 155)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Button size: 60"
sizeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
sizeLabel.TextSize = 13
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.ZIndex = 12
sizeLabel.Parent = flyPage


local minusButton = Instance.new("TextButton")
minusButton.Size = UDim2.new(0, 45, 0, 35)
minusButton.Position = UDim2.new(0.62, 0, 0, 155)
minusButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
minusButton.BorderSizePixel = 0
minusButton.Text = "−"
minusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minusButton.TextSize = 20
minusButton.Font = Enum.Font.GothamBold
minusButton.ZIndex = 12
minusButton.Parent = flyPage

local minusCorner = Instance.new("UICorner")
minusCorner.CornerRadius = UDim.new(0, 7)
minusCorner.Parent = minusButton


local plusButton = Instance.new("TextButton")
plusButton.Size = UDim2.new(0, 45, 0, 35)
plusButton.Position = UDim2.new(0.78, 0, 0, 155)
plusButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
plusButton.BorderSizePixel = 0
plusButton.Text = "+"
plusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
plusButton.TextSize = 20
plusButton.Font = Enum.Font.GothamBold
plusButton.ZIndex = 12
plusButton.Parent = flyPage

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 7)
plusCorner.Parent = plusButton


local function updateFlySize()

    flyButton.Size = UDim2.new(
        0,
        flyButtonSize,
        0,
        flyButtonSize
    )

    sizeLabel.Text = "Button size: " .. tostring(flyButtonSize)

end


minusButton.Activated:Connect(function()

    flyButtonSize = math.max(
        40,
        flyButtonSize - 10
    )

    updateFlySize()

end)


plusButton.Activated:Connect(function()

    flyButtonSize = math.min(
        100,
        flyButtonSize + 10
    )

    updateFlySize()

end)


--==================================================
-- RESET FLY POSITION
--==================================================

local resetFlyButton = Instance.new("TextButton")
resetFlyButton.Size = UDim2.new(1, 0, 0, 42)
resetFlyButton.Position = UDim2.new(0, 0, 0, 205)
resetFlyButton.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
resetFlyButton.BorderSizePixel = 0
resetFlyButton.Text = "RESET FLY POSITION"
resetFlyButton.TextColor3 = Color3.fromRGB(230, 230, 235)
resetFlyButton.TextSize = 13
resetFlyButton.Font = Enum.Font.GothamBold
resetFlyButton.ZIndex = 12
resetFlyButton.Parent = flyPage

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetFlyButton


resetFlyButton.Activated:Connect(function()

    flyButton.Position = UDim2.new(
        0.78,
        0,
        0.48,
        0
    )

    flyButtonSize = 60

    updateFlySize()

end)


local flyInfo = Instance.new("TextLabel")
flyInfo.Size = UDim2.new(1, 0, 0, 70)
flyInfo.Position = UDim2.new(0, 0, 0, 260)
flyInfo.BackgroundTransparency = 1
flyInfo.Text =
    "Hold ↑ to rise\nRelease to fall\nMove mode allows dragging the button"
flyInfo.TextColor3 = Color3.fromRGB(130, 130, 140)
flyInfo.TextSize = 12
flyInfo.Font = Enum.Font.Gotham
flyInfo.TextWrapped = true
flyInfo.TextXAlignment = Enum.TextXAlignment.Left
flyInfo.TextYAlignment = Enum.TextYAlignment.Top
flyInfo.ZIndex = 12
flyInfo.Parent = flyPage


--==================================================
-- FEATURE 1
--==================================================

local feature1Page = pages[2]

local feature1Title = Instance.new("TextLabel")
feature1Title.Size = UDim2.new(1, 0, 0, 40)
feature1Title.BackgroundTransparency = 1
feature1Title.Text = "FEATURE 1"
feature1Title.TextColor3 = Color3.fromRGB(255, 255, 255)
feature1Title.TextSize = 18
feature1Title.Font = Enum.Font.GothamBold
feature1Title.TextXAlignment = Enum.TextXAlignment.Left
feature1Title.ZIndex = 12
feature1Title.Parent = feature1Page

local feature1Info = Instance.new("TextLabel")
feature1Info.Size = UDim2.new(1, 0, 0, 80)
feature1Info.Position = UDim2.new(0, 0, 0, 50)
feature1Info.BackgroundTransparency = 1
feature1Info.Text = "Feature 1\nReserved for future testing"
feature1Info.TextColor3 = Color3.fromRGB(150, 150, 160)
feature1Info.TextSize = 13
feature1Info.Font = Enum.Font.Gotham
feature1Info.TextXAlignment = Enum.TextXAlignment.Left
feature1Info.ZIndex = 12
feature1Info.Parent = feature1Page


--==================================================
-- FEATURE 2
--==================================================

local feature2Page = pages[4]

local feature2Title = Instance.new("TextLabel")
feature2Title.Size = UDim2.new(1, 0, 0, 40)
feature2Title.BackgroundTransparency = 1
feature2Title.Text = "FEATURE 2"
feature2Title.TextColor3 = Color3.fromRGB(255, 255, 255)
feature2Title.TextSize = 18
feature2Title.Font = Enum.Font.GothamBold
feature2Title.TextXAlignment = Enum.TextXAlignment.Left
feature2Title.ZIndex = 12
feature2Title.Parent = feature2Page

local feature2Info = Instance.new("TextLabel")
feature2Info.Size = UDim2.new(1, 0, 0, 80)
feature2Info.Position = UDim2.new(0, 0, 0, 50)
feature2Info.BackgroundTransparency = 1
feature2Info.Text = "Feature 2\nReserved for future testing"
feature2Info.TextColor3 = Color3.fromRGB(150, 150, 160)
feature2Info.TextSize = 13
feature2Info.Font = Enum.Font.Gotham
feature2Info.TextXAlignment = Enum.TextXAlignment.Left
feature2Info.ZIndex = 12
feature2Info.Parent = feature2Page


--==================================================
-- OPEN BUTTON
--==================================================

local openButton = Instance.new("TextButton")

openButton.Size = UDim2.new(0, 55, 0, 55)
openButton.Position = UDim2.new(0.15, 0, 0.5, 0)

openButton.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
openButton.BorderSizePixel = 0
openButton.Text = "R"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 24
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.ZIndex = 100
openButton.Parent = gui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(1, 0)
openCorner.Parent = openButton


--==================================================
-- CLOSE / OPEN MENU
--==================================================

closeButton.Activated:Connect(function()

    main.Visible = false
    openButton.Visible = true

end)


local openDragging = false
local openMoved = false
local openDragStart
local openStartPosition


openButton.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

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
        or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - openDragStart

        if math.abs(delta.X) > 8
            or math.abs(delta.Y) > 8 then

            openMoved = true

        end

        if openMoved then

            openButton.Position = UDim2.new(
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
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

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
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

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
        or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - mainDragStart

        main.Position = UDim2.new(
            mainStartPosition.X.Scale,
            mainStartPosition.X.Offset + delta.X,
            mainStartPosition.Y.Scale,
            mainStartPosition.Y.Offset + delta.Y
        )

    end

end)


UIS.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        mainDragging = false

    end

end)


--==================================================
-- START
--==================================================

showPage(1)

main.Visible = true
openButton.Visible = false

print("RAHERHUB loaded successfully")