local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- ESP
--==================================================

local espEnabled = false
local highlights = {}

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
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "MobileTestMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = PlayerGui

--==================================================
-- Основная панель
--==================================================

local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.fromOffset(230, 155)
main.Position = UDim2.new(0.5, -115, 0.5, -78)
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
-- Заголовок
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
-- Кнопка скрытия
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
-- Кнопка ESP
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

--==================================================
-- Будущие функции
--==================================================

local futureText = Instance.new("TextLabel")
futureText.Size = UDim2.new(1, -30, 0, 30)
futureText.Position = UDim2.fromOffset(15, 112)
futureText.BackgroundTransparency = 1
futureText.Text = "More functions coming..."
futureText.TextColor3 = Color3.fromRGB(120, 120, 130)
futureText.TextSize = 12
futureText.Font = Enum.Font.Gotham
futureText.Parent = main

--==================================================
-- ESP кнопка
--==================================================

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
-- Плавающая кнопка
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
-- Универсальное перетаскивание пальцем
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

-- Панель двигается за верхнюю часть
makeDraggable(main, header)

-- Плавающая кнопка тоже двигается
makeDraggable(openButton, openButton)

--==================================================
-- Скрытие / открытие
--==================================================

hideButton.Activated:Connect(function()
    main.Visible = false
    openButton.Visible = true
end)

openButton.Activated:Connect(function()
    main.Visible = true
    openButton.Visible = false
end)