-- RAHERHUB | TEST MENU
-- Ekisde authentication + ESP + FLY JUMP + NOCLIP
-- Для собственной Roblox-карты / тестирования

local OWNER_ID = "Y46MQF2C3L"
local PUBLIC_KEY = "ZsvsuSaR3FMEEiv4L9krgsZBLLdZhrlmb9iHUlVsjxo="
local VERSION = "1.0"
local BASE_URL = "https://keys.ekisde.dev"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- HTTP
--------------------------------------------------

local httpRequest =
    request
    or http_request
    or (syn and syn.request)

if not httpRequest then
    LocalPlayer:Kick("HTTP request is not supported")
    return
end

local function httpPost(path, body)
    local ok, response = pcall(function()
        return httpRequest({
            Url = BASE_URL .. path,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "RaherHUB/1.0"
            },
            Body = HttpService:JSONEncode(body)
        })
    end)

    if not ok or not response then
        return nil, "HTTP request failed"
    end

    local statusCode =
        response.StatusCode
        or response.status_code

    local raw =
        response.Body
        or response.body

    if not raw or raw == "" then
        return nil, "Empty server response"
    end

    local decodeOK, data =
        pcall(function()
            return HttpService:JSONDecode(raw)
        end)

    if not decodeOK then
        return nil, "Invalid JSON response"
    end

    if type(data) ~= "table" then
        return nil, "Invalid server data"
    end

    if statusCode and tonumber(statusCode) and tonumber(statusCode) >= 400 then
        return nil, data.message or data.error or ("HTTP " .. tostring(statusCode))
    end

    return data
end

--------------------------------------------------
-- LOCAL STORAGE
--------------------------------------------------

local DEVICE_FILE = "raherhub_device.txt"
local USER_FILE = "raherhub_user.txt"
local PASS_FILE = "raherhub_pass.txt"

local function safeIsFile(path)
    if not isfile then
        return false
    end

    local ok, result = pcall(function()
        return isfile(path)
    end)

    return ok and result == true
end

local function safeRead(path)
    if not readfile or not safeIsFile(path) then
        return nil
    end

    local ok, result = pcall(function()
        return readfile(path)
    end)

    if ok and result and tostring(result) ~= "" then
        return tostring(result)
    end

    return nil
end

local function safeWrite(path, value)
    if not writefile then
        return false
    end

    local ok = pcall(function()
        writefile(path, tostring(value))
    end)

    return ok
end

local function safeDelete(path)
    if not delfile then
        return false
    end

    if not safeIsFile(path) then
        return true
    end

    local ok = pcall(function()
        delfile(path)
    end)

    return ok
end

--------------------------------------------------
-- DEVICE ID
--------------------------------------------------

local function getInstallId()
    local saved = safeRead(DEVICE_FILE)

    if saved then
        return saved
    end

    local newId = HttpService:GenerateGUID(false)

    safeWrite(DEVICE_FILE, newId)

    return newId
end

local hwid = getInstallId()

--------------------------------------------------
-- SAVED ACCOUNT
--------------------------------------------------

local function getSavedAccount()
    local username = safeRead(USER_FILE)
    local password = safeRead(PASS_FILE)

    if username and password then
        return username, password
    end

    return nil, nil
end

local function saveAccount(username, password)
    local a = safeWrite(USER_FILE, username)
    local b = safeWrite(PASS_FILE, password)

    return a and b
end

local function clearSavedAccount()
    safeDelete(USER_FILE)
    safeDelete(PASS_FILE)
end

--------------------------------------------------
-- RANDOM
--------------------------------------------------

math.randomseed(
    os.time()
    + math.floor(os.clock() * 100000)
)

local function randomString(length)
    local chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    local result = {}

    for i = 1, length do
        local n = math.random(1, #chars)
        result[i] = chars:sub(n, n)
    end

    return table.concat(result)
end

--------------------------------------------------
-- EKISDE API
--------------------------------------------------

local session = ""

local function ekisdeCall(name, fields)
    local payload = {
        owner_id = OWNER_ID,
        nonce = randomString(24),
        session = session
    }

    for k, v in pairs(fields or {}) do
        payload[k] = v
    end

    local data, err =
        httpPost("/api/1.0/" .. name, payload)

    if not data then
        return false, err
    end

    if data.session then
        session = tostring(data.session)
    end

    if data.success == false then
        return false,
            data.message
            or data.error
            or "Request failed"
    end

    return true, data
end

--------------------------------------------------
-- AUTH GUI
--------------------------------------------------

local authGui =
    Instance.new("ScreenGui")

authGui.Name = "RaherAuth"
authGui.ResetOnSpawn = false
authGui.Parent = game:GetService("CoreGui")

local authFrame =
    Instance.new("Frame")

authFrame.Size =
    UDim2.new(0, 330, 0, 220)

authFrame.Position =
    UDim2.new(0.5, -165, 0.5, -110)

authFrame.BackgroundColor3 =
    Color3.fromRGB(20, 20, 25)

authFrame.BorderSizePixel = 0
authFrame.Parent = authGui

local authCorner =
    Instance.new("UICorner")

authCorner.CornerRadius =
    UDim.new(0, 14)

authCorner.Parent = authFrame

--------------------------------------------------
-- TITLE
--------------------------------------------------

local authTitle =
    Instance.new("TextLabel")

authTitle.Size =
    UDim2.new(1, 0, 0, 45)

authTitle.BackgroundTransparency = 1
authTitle.Text = "RAHERHUB"
authTitle.TextColor3 =
    Color3.fromRGB(255, 255, 255)

authTitle.TextSize = 24
authTitle.Font =
    Enum.Font.GothamBold

authTitle.Parent = authFrame

--------------------------------------------------
-- STATUS
--------------------------------------------------

local statusLabel =
    Instance.new("TextLabel")

statusLabel.Size =
    UDim2.new(1, -20, 0, 28)

statusLabel.Position =
    UDim2.new(0, 10, 0, 40)

statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Checking saved account..."

statusLabel.TextColor3 =
    Color3.fromRGB(170, 170, 170)

statusLabel.TextSize = 13
statusLabel.Font =
    Enum.Font.Gotham

statusLabel.Parent = authFrame

--------------------------------------------------
-- KEY BOX
--------------------------------------------------

local keyBox =
    Instance.new("TextBox")

keyBox.Size =
    UDim2.new(1, -30, 0, 42)

keyBox.Position =
    UDim2.new(0, 15, 0, 73)

keyBox.BackgroundColor3 =
    Color3.fromRGB(32, 32, 40)

keyBox.BorderSizePixel = 0

keyBox.PlaceholderText =
    "License key — first activation only"

keyBox.PlaceholderColor3 =
    Color3.fromRGB(100, 100, 110)

keyBox.Text = ""

keyBox.TextColor3 =
    Color3.fromRGB(255, 255, 255)

keyBox.TextSize = 14
keyBox.Font =
    Enum.Font.Gotham

keyBox.ClearTextOnFocus = false

keyBox.Parent = authFrame

local keyCorner =
    Instance.new("UICorner")

keyCorner.CornerRadius =
    UDim.new(0, 9)

keyCorner.Parent = keyBox

--------------------------------------------------
-- LOGIN / ACTIVATE BUTTON
--------------------------------------------------

local checkButton =
    Instance.new("TextButton")

checkButton.Size =
    UDim2.new(1, -150, 0, 40)

checkButton.Position =
    UDim2.new(0, 15, 0, 124)

checkButton.BackgroundColor3 =
    Color3.fromRGB(55, 125, 255)

checkButton.BorderSizePixel = 0

checkButton.Text =
    "LOGIN"

checkButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

checkButton.TextSize = 14

checkButton.Font =
    Enum.Font.GothamBold

checkButton.Parent = authFrame

local checkCorner =
    Instance.new("UICorner")

checkCorner.CornerRadius =
    UDim.new(0, 9)

checkCorner.Parent = checkButton

--------------------------------------------------
-- RESET BUTTON
--------------------------------------------------

local resetButton =
    Instance.new("TextButton")

resetButton.Size =
    UDim2.new(0, 115, 0, 40)

resetButton.Position =
    UDim2.new(1, -130, 0, 124)

resetButton.BackgroundColor3 =
    Color3.fromRGB(70, 70, 80)

resetButton.BorderSizePixel = 0

resetButton.Text =
    "RESET ACCOUNT"

resetButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

resetButton.TextSize = 11

resetButton.Font =
    Enum.Font.GothamBold

resetButton.Parent = authFrame

local resetCorner =
    Instance.new("UICorner")

resetCorner.CornerRadius =
    UDim.new(0, 9)

resetCorner.Parent = resetButton

--------------------------------------------------
-- DEVICE INFO
--------------------------------------------------

local deviceLabel =
    Instance.new("TextLabel")

deviceLabel.Size =
    UDim2.new(1, -20, 0, 18)

deviceLabel.Position =
    UDim2.new(0, 10, 1, -22)

deviceLabel.BackgroundTransparency = 1

deviceLabel.Text =
    "Device ID: " .. hwid:sub(1, 8) .. "..."

deviceLabel.TextColor3 =
    Color3.fromRGB(100, 100, 110)

deviceLabel.TextSize = 10

deviceLabel.Font =
    Enum.Font.Gotham

deviceLabel.Parent = authFrame

--------------------------------------------------
-- AUTH STATE
--------------------------------------------------

local authenticated = false
local authenticating = false
local hasSavedAccount = false

local function setStatus(message, good)
    statusLabel.Text =
        tostring(message)

    if good then
        statusLabel.TextColor3 =
            Color3.fromRGB(100, 255, 130)
    else
        statusLabel.TextColor3 =
            Color3.fromRGB(255, 100, 100)
    end
end

--------------------------------------------------
-- LOGIN
--------------------------------------------------

local function tryLogin(username, password)
    if not username or not password then
        return false, "Saved account is incomplete"
    end

    local ok, result =
        ekisdeCall("login", {
            username = username,
            password = password,
            hwid = hwid
        })

    if ok then
        return true, result
    end

    return false, result
end

--------------------------------------------------
-- AUTHENTICATE
--------------------------------------------------

local function authenticate()
    if authenticating or authenticated then
        return
    end

    authenticating = true

    checkButton.Text =
        "CHECKING..."

    --------------------------------------------------
    -- INIT
    --------------------------------------------------

    setStatus(
        "Connecting to server...",
        false
    )

    local initOK, initResult =
        ekisdeCall("init", {
            version = VERSION
        })

    if not initOK then
        setStatus(
            "Init error: " .. tostring(initResult),
            false
        )

        checkButton.Text =
            hasSavedAccount
            and "LOGIN"
            or "ACTIVATE"

        authenticating = false
        return
    end

    --------------------------------------------------
    -- SAVED ACCOUNT
    --------------------------------------------------

    local savedUsername,
          savedPassword =
        getSavedAccount()

    if savedUsername and savedPassword then

        hasSavedAccount = true

        keyBox.Visible = false

        resetButton.Visible = true

        checkButton.Text =
            "LOGIN"

        setStatus(
            "Saved account found. Logging in...",
            false
        )

        local loginOK,
              loginResult =
            tryLogin(
                savedUsername,
                savedPassword
            )

        if loginOK then

            authenticated = true

            setStatus(
                "Access granted",
                true
            )

            checkButton.Text =
                "ACCESS GRANTED"

            task.wait(0.5)

            authGui:Destroy()

            return
        end

        --------------------------------------------------
        -- IMPORTANT:
        -- DO NOT ASK FOR A NEW KEY AUTOMATICALLY.
        --------------------------------------------------

        setStatus(
            "Login failed: "
            .. tostring(loginResult),
            false
        )

        checkButton.Text =
            "LOGIN"

        authenticating = false

        return
    end

    --------------------------------------------------
    -- NO ACCOUNT YET
    --------------------------------------------------

    hasSavedAccount = false

    keyBox.Visible = true

    resetButton.Visible = false

    checkButton.Text =
        "ACTIVATE"

    local license =
        keyBox.Text:gsub("%s+", "")

    if license == "" then

        setStatus(
            "Enter your license key",
            false
        )

        checkButton.Text =
            "ACTIVATE"

        authenticating = false

        return
    end

    --------------------------------------------------
    -- CREATE ACCOUNT
    --------------------------------------------------

    setStatus(
        "Activating license...",
        false
    )

    local username =
        "rah_" .. randomString(12)

    local password =
        randomString(32)

    --------------------------------------------------
    -- SAVE BEFORE REGISTER
    --------------------------------------------------

    local saved =
        saveAccount(
            username,
            password
        )

    if not saved then
        setStatus(
            "Could not save local account files",
            false
        )

        authenticating = false
        return
    end

    --------------------------------------------------
    -- REGISTER
    --------------------------------------------------

    local registerOK,
          registerResult =
        ekisdeCall("register", {
            username = username,
            password = password,
            license = license,
            hwid = hwid
        })

    if registerOK then

        authenticated = true

        setStatus(
            "License activated",
            true
        )

        checkButton.Text =
            "ACCESS GRANTED"

        task.wait(0.7)

        authGui:Destroy()

        return
    end

    --------------------------------------------------
    -- REGISTER FAILED
    --------------------------------------------------

    local errorText =
        tostring(registerResult)

    local lowerError =
        errorText:lower()

    --------------------------------------------------
    -- KEY ALREADY USED
    --------------------------------------------------

    if lowerError:find(
        "already been used",
        1,
        true
    )
    or lowerError:find(
        "already used",
        1,
        true
    )
    or lowerError:find(
        "used",
        1,
        true
    ) then

        setStatus(
            "Key already used. Trying saved account...",
            false
        )

        local recoveryOK,
              recoveryResult =
            tryLogin(
                username,
                password
            )

        if recoveryOK then

            authenticated = true

            setStatus(
                "Account recovered",
                true
            )

            checkButton.Text =
                "ACCESS GRANTED"

            task.wait(0.7)

            authGui:Destroy()

            return
        end

        setStatus(
            "Key used. Login failed: "
            .. tostring(recoveryResult),
            false
        )

        checkButton.Text =
            "ACTIVATE"

        authenticating = false

        return
    end

    --------------------------------------------------
    -- OTHER ERROR
    --------------------------------------------------

    setStatus(
        errorText,
        false
    )

    checkButton.Text =
        "ACTIVATE"

    authenticating = false
end

--------------------------------------------------
-- RESET ACCOUNT
--------------------------------------------------

resetButton.MouseButton1Click:Connect(function()

    if authenticating then
        return
    end

    clearSavedAccount()

    hasSavedAccount = false

    keyBox.Visible = true
    keyBox.Text = ""

    resetButton.Visible = false

    checkButton.Text =
        "ACTIVATE"

    setStatus(
        "Local account reset. Enter a license.",
        false
    )
end)

--------------------------------------------------
-- LOGIN BUTTON
--------------------------------------------------

checkButton.MouseButton1Click:Connect(
    authenticate
)

keyBox.FocusLost:Connect(
    function(enterPressed)

        if enterPressed then
            authenticate()
        end

    end
)

--------------------------------------------------
-- AUTOMATIC FIRST AUTH CHECK
--------------------------------------------------

task.spawn(function()

    task.wait(0.2)

    local username,
          password =
        getSavedAccount()

    if username and password then

        hasSavedAccount = true

        keyBox.Visible = false
        resetButton.Visible = true

        authenticate()

    else

        hasSavedAccount = false

        keyBox.Visible = true
        resetButton.Visible = false

        setStatus(
            "Enter your license key",
            false
        )

        checkButton.Text =
            "ACTIVATE"
    end

end)

--------------------------------------------------
-- WAIT FOR AUTH
--------------------------------------------------

repeat
    task.wait()
until authenticated

--------------------------------------------------
-- MAIN GUI
--------------------------------------------------

local gui =
    Instance.new("ScreenGui")

gui.Name =
    "RaherHUB"

gui.ResetOnSpawn = false
gui.Parent =
    game:GetService("CoreGui")

--------------------------------------------------
-- MAIN FRAME
--------------------------------------------------

local main =
    Instance.new("Frame")

main.Size =
    UDim2.new(0, 300, 0, 280)

main.Position =
    UDim2.new(
        0.5,
        -150,
        0.5,
        -140
    )

main.BackgroundColor3 =
    Color3.fromRGB(18, 18, 24)

main.BorderSizePixel = 0
main.Parent = gui

local mainCorner =
    Instance.new("UICorner")

mainCorner.CornerRadius =
    UDim.new(0, 14)

mainCorner.Parent = main

--------------------------------------------------
-- HEADER
--------------------------------------------------

local header =
    Instance.new("Frame")

header.Size =
    UDim2.new(1, 0, 0, 48)

header.BackgroundColor3 =
    Color3.fromRGB(30, 30, 40)

header.BorderSizePixel = 0
header.Parent = main

local headerCorner =
    Instance.new("UICorner")

headerCorner.CornerRadius =
    UDim.new(0, 14)

headerCorner.Parent = header

local title =
    Instance.new("TextLabel")

title.Size =
    UDim2.new(1, -60, 1, 0)

title.Position =
    UDim2.new(0, 15, 0, 0)

title.BackgroundTransparency = 1

title.Text =
    "RAHERHUB"

title.TextColor3 =
    Color3.fromRGB(255, 255, 255)

title.TextSize = 19

title.Font =
    Enum.Font.GothamBold

title.TextXAlignment =
    Enum.TextXAlignment.Left

title.Parent = header

--------------------------------------------------
-- HIDE BUTTON
--------------------------------------------------

local hideButton =
    Instance.new("TextButton")

hideButton.Size =
    UDim2.new(0, 42, 0, 34)

hideButton.Position =
    UDim2.new(1, -48, 0, 7)

hideButton.BackgroundColor3 =
    Color3.fromRGB(50, 50, 60)

hideButton.BorderSizePixel = 0

hideButton.Text =
    "×"

hideButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

hideButton.TextSize = 23

hideButton.Font =
    Enum.Font.GothamBold

hideButton.Parent = header

local hideCorner =
    Instance.new("UICorner")

hideCorner.CornerRadius =
    UDim.new(0, 8)

hideCorner.Parent = hideButton

--------------------------------------------------
-- TABS
--------------------------------------------------

local tabs =
    Instance.new("Frame")

tabs.Size =
    UDim2.new(1, -20, 0, 38)

tabs.Position =
    UDim2.new(0, 10, 0, 58)

tabs.BackgroundTransparency = 1

tabs.Parent = main

local function makeTab(text, x)
    local b =
        Instance.new("TextButton")

    b.Size =
        UDim2.new(0, 85, 0, 34)

    b.Position =
        UDim2.new(0, x, 0, 0)

    b.BackgroundColor3 =
        Color3.fromRGB(42, 42, 52)

    b.BorderSizePixel = 0

    b.Text = text

    b.TextColor3 =
        Color3.fromRGB(230, 230, 230)

    b.TextSize = 12

    b.Font =
        Enum.Font.GothamBold

    b.Parent = tabs

    local c =
        Instance.new("UICorner")

    c.CornerRadius =
        UDim.new(0, 8)

    c.Parent = b

    return b
end

local mainTab =
    makeTab("MAIN", 0)

local feature1Tab =
    makeTab("FEATURE 1", 92)

local feature2Tab =
    makeTab("FEATURE 2", 184)

--------------------------------------------------
-- PAGE CONTAINERS
--------------------------------------------------

local mainPage =
    Instance.new("Frame")

mainPage.Size =
    UDim2.new(1, -20, 1, -108)

mainPage.Position =
    UDim2.new(0, 10, 0, 102)

mainPage.BackgroundTransparency = 1

mainPage.Parent = main

local feature1Page =
    Instance.new("Frame")

feature1Page.Size =
    mainPage.Size

feature1Page.Position =
    mainPage.Position

feature1Page.BackgroundTransparency = 1

feature1Page.Visible = false

feature1Page.Parent = main

local feature2Page =
    Instance.new("Frame")

feature2Page.Size =
    mainPage.Size

feature2Page.Position =
    mainPage.Position

feature2Page.BackgroundTransparency = 1

feature2Page.Visible = false

feature2Page.Parent = main

--------------------------------------------------
-- DRAG MAIN WINDOW
--------------------------------------------------

local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = main.Position

    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not dragging then
        return
    end

    if input.UserInputType ==
        Enum.UserInputType.MouseMovement
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        local delta =
            input.Position - dragStart

        main.Position =
            UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
    end
end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1
        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = false

    end
end)

--------------------------------------------------
-- TOGGLE CREATOR
--------------------------------------------------

local function makeToggle(text, y)

    local b =
        Instance.new("TextButton")

    b.Size =
        UDim2.new(1, 0, 0, 42)

    b.Position =
        UDim2.new(0, 0, 0, y)

    b.BackgroundColor3 =
        Color3.fromRGB(38, 38, 48)

    b.BorderSizePixel = 0

    b.Text =
        text .. "  [OFF]"

    b.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    b.TextSize = 14

    b.Font =
        Enum.Font.GothamBold

    b.Parent = mainPage

    local c =
        Instance.new("UICorner")

    c.CornerRadius =
        UDim.new(0, 9)

    c.Parent = b

    return b
end

--------------------------------------------------
-- ESP
--------------------------------------------------

local espEnabled = false

local function removeESP(player)

    if not player.Character then
        return
    end

    local highlight =
        player.Character:FindFirstChild(
            "RaherESP"
        )

    if highlight then
        highlight:Destroy()
    end
end

local function createESP(player)

    if player == LocalPlayer then
        return
    end

    if not player.Character then
        return
    end

    if player.Character:FindFirstChild(
        "RaherESP"
    ) then
        return
    end

    local highlight =
        Instance.new("Highlight")

    highlight.Name =
        "RaherESP"

    highlight.FillTransparency =
        0.55

    highlight.OutlineTransparency =
        0

    highlight.Parent =
        player.Character
end

local function updateESP()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if espEnabled then
            createESP(player)
        else
            removeESP(player)
        end

    end
end

Players.PlayerAdded:Connect(function(player)

    player.CharacterAdded:Connect(
        function()

            task.wait(0.5)

            if espEnabled then
                createESP(player)
            end

        end
    )

end)

Players.PlayerRemoving:Connect(
    removeESP
)

local espButton =
    makeToggle(
        "ESP",
        0
    )

espButton.MouseButton1Click:Connect(
    function()

        espEnabled =
            not espEnabled

        if espEnabled then

            espButton.Text =
                "ESP  [ON]"

        else

            espButton.Text =
                "ESP  [OFF]"

        end

        updateESP()

    end
)

--------------------------------------------------
-- FLY JUMP
--------------------------------------------------

local flyEnabled = false
local flyUp = false

local flyButton =
    makeToggle(
        "FLY JUMP",
        52
    )

flyButton.MouseButton1Click:Connect(
    function()

        flyEnabled =
            not flyEnabled

        if flyEnabled then

            flyButton.Text =
                "FLY JUMP  [ON]"

        else

            flyButton.Text =
                "FLY JUMP  [OFF]"

            flyUp = false

        end

    end
)

--------------------------------------------------
-- FLY BUTTON
--------------------------------------------------

local flyFloat =
    Instance.new("TextButton")

flyFloat.Size =
    UDim2.new(0, 55, 0, 55)

flyFloat.Position =
    UDim2.new(
        1,
        -75,
        0.65,
        0
    )

flyFloat.BackgroundColor3 =
    Color3.fromRGB(50, 130, 255)

flyFloat.BorderSizePixel = 0

flyFloat.Text =
    "↑"

flyFloat.TextColor3 =
    Color3.fromRGB(255, 255, 255)

flyFloat.TextSize = 28

flyFloat.Font =
    Enum.Font.GothamBold

flyFloat.Visible = true

flyFloat.Parent = gui

local flyCorner =
    Instance.new("UICorner")

flyCorner.CornerRadius =
    UDim.new(1, 0)

flyCorner.Parent = flyFloat

flyFloat.MouseButton1Down:Connect(
    function()

        if flyEnabled then
            flyUp = true
        end

    end
)

flyFloat.MouseButton1Up:Connect(
    function()
        flyUp = false
    end
)

flyFloat.InputEnded:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.Touch then

            flyUp = false

        end

    end
)

RunService.RenderStepped:Connect(
    function()

        if not flyEnabled then
            return
        end

        if not flyUp then
            return
        end

        local character =
            LocalPlayer.Character

        if not character then
            return
        end

        local root =
            character:FindFirstChild(
                "HumanoidRootPart"
            )

        if not root then
            return
        end

        root.AssemblyLinearVelocity =
            Vector3.new(
                root.AssemblyLinearVelocity.X,
                35,
                root.AssemblyLinearVelocity.Z
            )

    end
)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclipEnabled = false

local noclipButton =
    makeToggle(
        "NOCLIP",
        104
    )

noclipButton.MouseButton1Click:Connect(
    function()

        noclipEnabled =
            not noclipEnabled

        if noclipEnabled then

            noclipButton.Text =
                "NOCLIP  [ON]"

        else

            noclipButton.Text =
                "NOCLIP  [OFF]"

        end

    end
)

RunService.Stepped:Connect(
    function()

        if not noclipEnabled then
            return
        end

        local character =
            LocalPlayer.Character

        if not character then
            return
        end

        for _, part in ipairs(
            character:GetDescendants()
        ) do

            if part:IsA("BasePart") then
                part.CanCollide = false
            end

        end

    end
)

--------------------------------------------------
-- EMPTY FEATURE PAGES
--------------------------------------------------

local empty1 =
    Instance.new("TextLabel")

empty1.Size =
    UDim2.new(1, 0, 0, 40)

empty1.BackgroundTransparency = 1

empty1.Text =
    "FEATURE 1"

empty1.TextColor3 =
    Color3.fromRGB(150, 150, 160)

empty1.TextSize = 15

empty1.Font =
    Enum.Font.GothamBold

empty1.Parent =
    feature1Page

local empty2 =
    Instance.new("TextLabel")

empty2.Size =
    UDim2.new(1, 0, 0, 40)

empty2.BackgroundTransparency = 1

empty2.Text =
    "FEATURE 2"

empty2.TextColor3 =
    Color3.fromRGB(150, 150, 160)

empty2.TextSize = 15

empty2.Font =
    Enum.Font.GothamBold

empty2.Parent =
    feature2Page

--------------------------------------------------
-- TABS
--------------------------------------------------

mainTab.MouseButton1Click:Connect(
    function()

        mainPage.Visible = true
        feature1Page.Visible = false
        feature2Page.Visible = false

    end
)

feature1Tab.MouseButton1Click:Connect(
    function()

        mainPage.Visible = false
        feature1Page.Visible = true
        feature2Page.Visible = false

    end
)

feature2Tab.MouseButton1Click:Connect(
    function()

        mainPage.Visible = false
        feature1Page.Visible = false
        feature2Page.Visible = true

    end
)

--------------------------------------------------
-- FLOATING OPEN BUTTON
--------------------------------------------------

local openButton =
    Instance.new("TextButton")

openButton.Size =
    UDim2.new(0, 58, 0, 58)

openButton.Position =
    UDim2.new(
        0,
        20,
        0.5,
        -29
    )

openButton.BackgroundColor3 =
    Color3.fromRGB(35, 105, 230)

openButton.BorderSizePixel = 0

openButton.Text =
    "≡"

openButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

openButton.TextSize = 30

openButton.Font =
    Enum.Font.GothamBold

openButton.Visible = false

openButton.Parent = gui

local openCorner =
    Instance.new("UICorner")

openCorner.CornerRadius =
    UDim.new(1, 0)

openCorner.Parent = openButton

--------------------------------------------------
-- HIDE
--------------------------------------------------

hideButton.MouseButton1Click:Connect(
    function()

        main.Visible = false
        openButton.Visible = true

    end
)

--------------------------------------------------
-- DRAG OPEN BUTTON
--------------------------------------------------

local openDragging = false
local openDragStart
local openStartPos

openButton.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            openDragging = true

            openDragStart =
                input.Position

            openStartPos =
                openButton.Position

        end

    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if not openDragging then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            local delta =
                input.Position
                - openDragStart

            openButton.Position =
                UDim2.new(
                    openStartPos.X.Scale,
                    openStartPos.X.Offset
                        + delta.X,

                    openStartPos.Y.Scale,
                    openStartPos.Y.Offset
                        + delta.Y
                )

        end

    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            openDragging = false

        end

    end
)

--------------------------------------------------
-- OPEN BUTTON
--------------------------------------------------

openButton.MouseButton1Click:Connect(
    function()

        if openDragging then
            return
        end

        main.Visible = true
        openButton.Visible = false

    end
)

--------------------------------------------------
-- CHARACTER RESPAWN SUPPORT
--------------------------------------------------

LocalPlayer.CharacterAdded:Connect(
    function()

        task.wait(1)

        if noclipEnabled then

            local character =
                LocalPlayer.Character

            if character then

                for _, part in ipairs(
                    character:GetDescendants()
                ) do

                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end

                end

            end

        end

    end
)

--------------------------------------------------
-- READY
--------------------------------------------------

print(
    "[RAHERHUB] Loaded successfully"
)