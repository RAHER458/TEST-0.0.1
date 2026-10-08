--// RaherHUB 1.0
--// Full version
--// ESP / FLY JUMP / NOCLIP / Fly Button Settings
--// Mobile friendly

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- AUTH
--------------------------------------------------

local OWNER_ID = "Y46MQF2C3L"
local PUBLIC_KEY = "ZsvsuSaR3FMEEiv4L9krgsZBLLdZhrlmb9iHUlVsjxo="
local VERSION = "1.0"

local BASE_URL = "https://keys.ekisde.dev"

local requestFunc =
    request
    or http_request
    or (syn and syn.request)

local DEVICE_FILE = "raherhub_device.txt"
local USER_FILE = "raherhub_user.txt"
local PASS_FILE = "raherhub_pass.txt"

local function fileExists(path)
    if not isfile then
        return false
    end

    local result = false

    pcall(function()
        result = isfile(path)
    end)

    return result
end

local function safeRead(path)
    if not readfile then
        return nil
    end

    if not fileExists(path) then
        return nil
    end

    local result

    pcall(function()
        result = readfile(path)
    end)

    return result
end

local function safeWrite(path, value)
    if not writefile then
        return
    end

    pcall(function()
        writefile(path, tostring(value))
    end)
end

local function safeDelete(path)
    if not delfile then
        return
    end

    if fileExists(path) then
        pcall(function()
            delfile(path)
        end)
    end
end

--------------------------------------------------
-- INSTALL ID
--------------------------------------------------

local function getInstallId()
    local saved = safeRead(DEVICE_FILE)

    if saved and #saved > 0 then
        return saved
    end

    local newId = HttpService:GenerateGUID(false)

    safeWrite(DEVICE_FILE, newId)

    return newId
end

local hwid = getInstallId()

--------------------------------------------------
-- AUTH REQUEST
--------------------------------------------------

local function authRequest(endpoint, body)
    if not requestFunc then
        return false, "HTTP request function is unavailable."
    end

    local success, response = pcall(function()
        return requestFunc({
            Url = BASE_URL .. endpoint,
            Method = "POST",

            Headers = {
                ["Content-Type"] = "application/json"
            },

            Body = HttpService:JSONEncode(body)
        })
    end)

    if not success or not response then
        return false, "Connection error."
    end

    local responseBody = response.Body or ""

    local decoded

    pcall(function()
        decoded = HttpService:JSONDecode(responseBody)
    end)

    if not decoded then
        return false, responseBody ~= "" and responseBody or "Invalid server response."
    end

    return true, decoded
end

--------------------------------------------------
-- GUI HELPERS
--------------------------------------------------

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties) do
        object[property] = value
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function round(object, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, object)
end

local function stroke(object, transparency)
    create("UIStroke", {
        Transparency = transparency or 0
    }, object)
end

--------------------------------------------------
-- AUTH GUI
--------------------------------------------------

local authGui = create("ScreenGui", {
    Name = "RaherHubAuth",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

pcall(function()
    authGui.Parent = CoreGui
end)

if not authGui.Parent then
    authGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local authFrame = create("Frame", {
    Size = UDim2.new(0, 330, 0, 260),
    Position = UDim2.new(0.5, -165, 0.5, -130),
    BackgroundColor3 = Color3.fromRGB(20, 20, 28),
    BorderSizePixel = 0
}, authGui)

round(authFrame, 14)
stroke(authFrame, 0.65)

local authTitle = create("TextLabel", {
    Size = UDim2.new(1, -30, 0, 45),
    Position = UDim2.new(0, 15, 0, 10),
    BackgroundTransparency = 1,
    Text = "RaherHUB",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 25,
    Font = Enum.Font.GothamBold
}, authFrame)

local authStatus = create("TextLabel", {
    Size = UDim2.new(1, -30, 0, 30),
    Position = UDim2.new(0, 15, 0, 55),
    BackgroundTransparency = 1,
    Text = "Введите ключ",
    TextColor3 = Color3.fromRGB(180, 180, 190),
    TextSize = 14,
    Font = Enum.Font.Gotham
}, authFrame)

local keyBox = create("TextBox", {
    Size = UDim2.new(1, -30, 0, 45),
    Position = UDim2.new(0, 15, 0, 95),
    BackgroundColor3 = Color3.fromRGB(32, 32, 43),
    BorderSizePixel = 0,
    PlaceholderText = "License Key",
    PlaceholderColor3 = Color3.fromRGB(120, 120, 130),
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false
}, authFrame)

round(keyBox, 9)

local authButton = create("TextButton", {
    Size = UDim2.new(1, -30, 0, 45),
    Position = UDim2.new(0, 15, 0, 150),
    BackgroundColor3 = Color3.fromRGB(75, 120, 255),
    BorderSizePixel = 0,
    Text = "ACTIVATE",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold
}, authFrame)

round(authButton, 9)

local resetButton = create("TextButton", {
    Size = UDim2.new(1, -30, 0, 35),
    Position = UDim2.new(0, 15, 0, 205),
    BackgroundTransparency = 1,
    Text = "RESET SAVED ACCOUNT",
    TextColor3 = Color3.fromRGB(150, 150, 160),
    TextSize = 12,
    Font = Enum.Font.Gotham
}, authFrame)

--------------------------------------------------
-- AUTH RESULT
--------------------------------------------------

local authenticated = false

local function hideAuth()
    authGui.Enabled = false
end

local function showAuth()
    authGui.Enabled = true
end

local function setAuthStatus(text, success)
    authStatus.Text = text

    if success then
        authStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        authStatus.TextColor3 = Color3.fromRGB(255, 110, 110)
    end
end

--------------------------------------------------
-- LOGIN SAVED ACCOUNT
--------------------------------------------------

local savedUser = safeRead(USER_FILE)
local savedPass = safeRead(PASS_FILE)

local function tryLogin()
    if not savedUser or not savedPass then
        return false
    end

    local ok, data = authRequest(
        "/api/1.0/" .. HttpService:UrlEncode(savedUser),
        {
            type = "login",
            username = savedUser,
            password = savedPass,
            hwid = hwid,
            version = VERSION
        }
    )

    if not ok then
        return false
    end

    if data.success == true then
        authenticated = true
        return true
    end

    return false
end

if savedUser and savedPass then
    setAuthStatus("Проверка аккаунта...", true)

    if tryLogin() then
        hideAuth()
    else
        setAuthStatus("Введите новый ключ", false)
    end
end

--------------------------------------------------
-- REGISTER
--------------------------------------------------

local function registerKey(key)
    if key == "" then
        setAuthStatus("Введите ключ", false)
        return
    end

    setAuthStatus("Проверка ключа...", true)

    local username =
        "raher_" ..
        string.sub(
            HttpService:GenerateGUID(false):gsub("%-", ""),
            1,
            10
        )

    local password =
        HttpService:GenerateGUID(false):gsub("%-", "")

    local ok, data = authRequest(
        "/api/1.0/" .. HttpService:UrlEncode(username),
        {
            type = "register",
            username = username,
            password = password,
            license = key,
            hwid = hwid,
            version = VERSION
        }
    )

    if not ok then
        setAuthStatus(tostring(data), false)
        return
    end

    if data.success == true then
        safeWrite(USER_FILE, username)
        safeWrite(PASS_FILE, password)

        authenticated = true

        setAuthStatus("Ключ активирован", true)

        task.wait(0.7)

        hideAuth()
        return
    end

    local message =
        data.message
        or data.error
        or "Ключ недействителен."

    setAuthStatus(tostring(message), false)
end

authButton.MouseButton1Click:Connect(function()
    registerKey(keyBox.Text)
end)

keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        registerKey(keyBox.Text)
    end
end)

resetButton.MouseButton1Click:Connect(function()
    safeDelete(USER_FILE)
    safeDelete(PASS_FILE)

    savedUser = nil
    savedPass = nil

    keyBox.Text = ""

    setAuthStatus("Сохранённый аккаунт сброшен", false)
end)

--------------------------------------------------
-- WAIT AUTH
--------------------------------------------------

if not authenticated then
    repeat
        task.wait(0.1)
    until authenticated
end

authGui:Destroy()

--------------------------------------------------
-- MAIN GUI
--------------------------------------------------

local gui = create("ScreenGui", {
    Name = "RaherHUB",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

pcall(function()
    gui.Parent = CoreGui
end)

if not gui.Parent then
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--------------------------------------------------
-- MAIN FRAME
--------------------------------------------------

local main = create("Frame", {
    Size = UDim2.new(0, 350, 0, 420),
    Position = UDim2.new(0.5, -175, 0.5, -210),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel = 0
}, gui)

round(main, 14)
stroke(main, 0.55)

--------------------------------------------------
-- TITLE
--------------------------------------------------

local title = create("TextLabel", {
    Size = UDim2.new(1, -60, 0, 45),
    Position = UDim2.new(0, 15, 0, 5),
    BackgroundTransparency = 1,
    Text = "RAHERHUB",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, main)

--------------------------------------------------
-- CLOSE BUTTON
--------------------------------------------------

local closeButton = create("TextButton", {
    Size = UDim2.new(0, 38, 0, 38),
    Position = UDim2.new(1, -45, 0, 8),
    BackgroundColor3 = Color3.fromRGB(40, 40, 52),
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextSize = 25,
    Font = Enum.Font.GothamBold
}, main)

round(closeButton, 9)

--------------------------------------------------
-- TABS
--------------------------------------------------

local tabs = create("Frame", {
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.new(0, 10, 0, 55),
    BackgroundTransparency = 1
}, main)

local tabLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 6)
}, tabs)

local function createTab(text)
    local button = create("TextButton", {
        Size = UDim2.new(0, 75, 0, 35),
        BackgroundColor3 = Color3.fromRGB(35, 35, 48),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.fromRGB(190, 190, 200),
        TextSize = 11,
        Font = Enum.Font.GothamBold
    }, tabs)

    round(button, 8)

    return button
end

local mainTab = createTab("MAIN")
local feature1Tab = createTab("FEATURE 1")
local flyTab = createTab("FLY")
local feature2Tab = createTab("FEATURE 2")

--------------------------------------------------
-- PAGES
--------------------------------------------------

local pages = {}

local function createPage()
    local page = create("Frame", {
        Size = UDim2.new(1, -20, 1, -110),
        Position = UDim2.new(0, 10, 0, 100),
        BackgroundTransparency = 1,
        Visible = false
    }, main)

    table.insert(pages, page)

    return page
end

local mainPage = createPage()
local feature1Page = createPage()
local flyPage = createPage()
local feature2Page = createPage()

mainPage.Visible = true

local function showPage(page)
    for _, p in ipairs(pages) do
        p.Visible = false
    end

    page.Visible = true
end

mainTab.MouseButton1Click:Connect(function()
    showPage(mainPage)
end)

feature1Tab.MouseButton1Click:Connect(function()
    showPage(feature1Page)
end)

flyTab.MouseButton1Click:Connect(function()
    showPage(flyPage)
end)

feature2Tab.MouseButton1Click:Connect(function()
    showPage(feature2Page)
end)

--------------------------------------------------
-- DRAG MAIN WINDOW
--------------------------------------------------

local dragging = false
local dragStart
local startPosition

main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        if input.Position.Y <= main.AbsolutePosition.Y + 50 then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - dragStart

        main.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = false
    end
end)

--------------------------------------------------
-- ESP
--------------------------------------------------

local espEnabled = false
local espObjects = {}

local function removeESP(player)
    if espObjects[player] then
        pcall(function()
            espObjects[player]:Destroy()
        end)

        espObjects[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer then
        return
    end

    if not player.Character then
        return
    end

    removeESP(player)

    local highlight = Instance.new("Highlight")

    highlight.Name = "RaherESP"
    highlight.Adornee = player.Character
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 70, 70)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

    highlight.Parent = player.Character

    espObjects[player] = highlight
end

local function updateESP()
    if not espEnabled then
        for player in pairs(espObjects) do
            removeESP(player)
        end

        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)

        if espEnabled then
            createESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

--------------------------------------------------
-- MAIN PAGE
--------------------------------------------------

local espButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 5),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "ESP: OFF",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold
}, mainPage)

round(espButton, 9)

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled

    espButton.Text =
        espEnabled and "ESP: ON" or "ESP: OFF"

    if espEnabled then
        updateESP()
    else
        updateESP()
    end
end)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclipEnabled = false

local noclipButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 65),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "NOCLIP: OFF",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold
}, mainPage)

round(noclipButton, 9)

noclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled

    noclipButton.Text =
        noclipEnabled and "NOCLIP: ON" or "NOCLIP: OFF"
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

--------------------------------------------------
-- FLY
--------------------------------------------------

local flyEnabled = false
local flyHolding = false

local flyButton

local flySpeed = 45

local function getRoot()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function flyUp()
    local root = getRoot()

    if not root then
        return
    end

    root.AssemblyLinearVelocity =
        Vector3.new(
            root.AssemblyLinearVelocity.X,
            flySpeed,
            root.AssemblyLinearVelocity.Z
        )
end

local flyToggle = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 125),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "FLY JUMP: OFF",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
    Font = Enum.Font.GothamBold
}, mainPage)

round(flyToggle, 9)

flyToggle.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled

    flyToggle.Text =
        flyEnabled and "FLY JUMP: ON" or "FLY JUMP: OFF"
end)

--------------------------------------------------
-- FLY BUTTON FILES
--------------------------------------------------

local FLY_X_FILE = "raherhub_fly_x.txt"
local FLY_Y_FILE = "raherhub_fly_y.txt"
local FLY_SIZE_FILE = "raherhub_fly_size.txt"

local function readNumber(path, default)
    local value = safeRead(path)

    if not value then
        return default
    end

    local number = tonumber(value)

    return number or default
end

local flyX = readNumber(FLY_X_FILE, 0.78)
local flyY = readNumber(FLY_Y_FILE, 0.48)
local flySize = readNumber(FLY_SIZE_FILE, 60)

flySize = math.clamp(flySize, 35, 90)

--------------------------------------------------
-- FLOATING FLY BUTTON
--------------------------------------------------

flyButton = create("TextButton", {
    Size = UDim2.new(0, flySize, 0, flySize),
    Position = UDim2.new(flyX, 0, flyY, 0),
    BackgroundColor3 = Color3.fromRGB(75, 120, 255),
    BorderSizePixel = 0,
    Text = "↑",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    Visible = true,
    AutoButtonColor = true
}, gui)

round(flyButton, 100)

--------------------------------------------------
-- FLY BUTTON HOLD
--------------------------------------------------

flyButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyHolding = true
    end
end)

flyButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyHolding = false
    end
end)

RunService.Heartbeat:Connect(function()
    if flyEnabled and flyHolding then
        flyUp()
    end
end)

--------------------------------------------------
-- FLY BUTTON DRAG MODE
--------------------------------------------------

local moveFlyButton = false

local flyDragging = false
local flyDragStart
local flyStartPosition
local flyMoved = false

local function saveFlyPosition()
    safeWrite(FLY_X_FILE, flyButton.Position.X.Scale)
    safeWrite(FLY_Y_FILE, flyButton.Position.Y.Scale)
end

flyButton.InputBegan:Connect(function(input)
    if not moveFlyButton then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyDragging = true
        flyMoved = false

        flyDragStart = input.Position
        flyStartPosition = flyButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not flyDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then

        local delta = input.Position - flyDragStart

        if math.abs(delta.X) > 5
            or math.abs(delta.Y) > 5 then

            flyMoved = true
        end

        flyButton.Position =
            UDim2.new(
                flyStartPosition.X.Scale,
                flyStartPosition.X.Offset + delta.X,
                flyStartPosition.Y.Scale,
                flyStartPosition.Y.Offset + delta.Y
            )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not flyDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyDragging = false

        if flyMoved then
            saveFlyPosition()
        end

        flyMoved = false
    end
end)

--------------------------------------------------
-- FLY SETTINGS PAGE
--------------------------------------------------

local moveFlyToggle = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 5),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "MOVE FLY BUTTON: OFF",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold
}, flyPage)

round(moveFlyToggle, 9)

moveFlyToggle.MouseButton1Click:Connect(function()
    moveFlyButton = not moveFlyButton

    moveFlyToggle.Text =
        moveFlyButton
        and "MOVE FLY BUTTON: ON"
        or "MOVE FLY BUTTON: OFF"
end)

--------------------------------------------------
-- FLY SIZE
--------------------------------------------------

local flySizeLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 35),
    Position = UDim2.new(0, 0, 0, 70),
    BackgroundTransparency = 1,
    Text = "FLY BUTTON SIZE: " .. flySize,
    TextColor3 = Color3.fromRGB(220, 220, 230),
    TextSize = 14,
    Font = Enum.Font.GothamBold
}, flyPage)

local minusButton = create("TextButton", {
    Size = UDim2.new(0.48, -4, 0, 45),
    Position = UDim2.new(0, 0, 0, 110),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "−",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Enum.Font.GothamBold
}, flyPage)

round(minusButton, 9)

local plusButton = create("TextButton", {
    Size = UDim2.new(0.48, -4, 0, 45),
    Position = UDim2.new(0.52, 0, 0, 110),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "+",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Enum.Font.GothamBold
}, flyPage)

round(plusButton, 9)

local function updateFlySize()
    flyButton.Size =
        UDim2.new(
            0,
            flySize,
            0,
            flySize
        )

    flySizeLabel.Text =
        "FLY BUTTON SIZE: " .. tostring(flySize)

    safeWrite(FLY_SIZE_FILE, flySize)
end

minusButton.MouseButton1Click:Connect(function()
    flySize = math.max(35, flySize - 5)
    updateFlySize()
end)

plusButton.MouseButton1Click:Connect(function()
    flySize = math.min(90, flySize + 5)
    updateFlySize()
end)

--------------------------------------------------
-- RESET FLY POSITION
--------------------------------------------------

local resetFlyPosition = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 45),
    Position = UDim2.new(0, 0, 0, 170),
    BackgroundColor3 = Color3.fromRGB(35, 35, 48),
    BorderSizePixel = 0,
    Text = "RESET FLY POSITION",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    Font = Enum.Font.GothamBold
}, flyPage)

round(resetFlyPosition, 9)

resetFlyPosition.MouseButton1Click:Connect(function()
    flyButton.Position =
        UDim2.new(
            0.78,
            0,
            0.48,
            0
        )

    safeWrite(FLY_X_FILE, 0.78)
    safeWrite(FLY_Y_FILE, 0.48)
end)

--------------------------------------------------
-- FEATURE 1 PAGE
--------------------------------------------------

local feature1Text = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 100),
    Position = UDim2.new(0, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "FEATURE 1\n\nReserved for testing.",
    TextColor3 = Color3.fromRGB(190, 190, 200),
    TextSize = 14,
    Font = Enum.Font.Gotham,
    TextWrapped = true
}, feature1Page)

--------------------------------------------------
-- FEATURE 2 PAGE
--------------------------------------------------

local feature2Text = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 100),
    Position = UDim2.new(0, 0, 0, 10),
    BackgroundTransparency = 1,
    Text = "FEATURE 2\n\nReserved for testing.",
    TextColor3 = Color3.fromRGB(190, 190, 200),
    TextSize = 14,
    Font = Enum.Font.Gotham,
    TextWrapped = true
}, feature2Page)

--------------------------------------------------
-- HIDE / OPEN MENU
--------------------------------------------------

local openButton = create("TextButton", {
    Size = UDim2.new(0, 55, 0, 55),
    Position = UDim2.new(0.05, 0, 0.45, 0),
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 0,
    Text = "≡",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    Visible = false,
    AutoButtonColor = true
}, gui)

round(openButton, 100)
stroke(openButton, 0.55)

--------------------------------------------------
-- CLOSE MENU
--------------------------------------------------

closeButton.MouseButton1Click:Connect(function()
    main.Visible = false
    openButton.Visible = true
end)

--------------------------------------------------
-- OPEN BUTTON DRAG + CLICK
-- FIXED VERSION
--------------------------------------------------

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

UserInputService.InputChanged:Connect(function(input)
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

UserInputService.InputEnded:Connect(function(input)
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

--------------------------------------------------
-- CHARACTER RESPAWN
--------------------------------------------------

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    if noclipEnabled then
        local character = LocalPlayer.Character

        if character then
            for _, object in ipairs(character:GetDescendants()) do
                if object:IsA("BasePart") then
                    object.CanCollide = false
                end
            end
        end
    end

    if espEnabled then
        updateESP()
    end
end)

--------------------------------------------------
-- FINAL
--------------------------------------------------

print("RaherHUB loaded successfully.")