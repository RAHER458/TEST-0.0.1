--==================================================
-- RAHERHUB
-- ESP / FLY JUMP / NOCLIP
-- EKISDE AUTH
-- MOBILE GUI
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

--==================================================
-- CONFIG
--==================================================

local OWNER_ID = "Y46MQF2C3L"
local PUBLIC_KEY = "ZsvsuSaR3FMEEiv4L9krgsZBLLdZhrlmb9iHUlVsjxo="
local VERSION = "1.0"
local BASE_URL = "https://keys.ekisde.dev"

--==================================================
-- FILES
--==================================================

local DEVICE_FILE = "raherhub_device.txt"
local USER_FILE = "raherhub_user.txt"
local PASS_FILE = "raherhub_pass.txt"

local FLY_X_FILE = "raherhub_fly_x.txt"
local FLY_Y_FILE = "raherhub_fly_y.txt"
local FLY_SIZE_FILE = "raherhub_fly_size.txt"

--==================================================
-- SAFE FILE FUNCTIONS
--==================================================

local function fileExists(path)
    if not isfile then
        return false
    end

    local ok, result = pcall(function()
        return isfile(path)
    end)

    return ok and result == true
end

local function readFile(path)
    if not readfile or not fileExists(path) then
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

local function writeFile(path, value)
    if not writefile then
        return false
    end

    local ok = pcall(function()
        writefile(path, tostring(value))
    end)

    return ok
end

local function deleteFile(path)
    if not delfile then
        return false
    end

    if not fileExists(path) then
        return true
    end

    local ok = pcall(function()
        delfile(path)
    end)

    return ok
end

--==================================================
-- DEVICE ID
--==================================================

local function getDeviceId()

    local saved = readFile(DEVICE_FILE)

    if saved then
        return saved
    end

    local id = HttpService:GenerateGUID(false)

    writeFile(DEVICE_FILE, id)

    return id
end

local hwid = getDeviceId()

--==================================================
-- HTTP
--==================================================

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

    local status =
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
        return nil, "Invalid server response"
    end

    if status and tonumber(status) and tonumber(status) >= 400 then
        return nil,
            data.message
            or data.error
            or ("HTTP " .. tostring(status))
    end

    return data
end

--==================================================
-- EKISDE
--==================================================

local session = ""

local function ekisdeCall(name, fields)

    local payload = {
        owner_id = OWNER_ID,
        nonce = HttpService:GenerateGUID(false),
        session = session
    }

    for k, v in pairs(fields or {}) do
        payload[k] = v
    end

    local data, err =
        httpPost(
            "/api/1.0/" .. name,
            payload
        )

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

--==================================================
-- RANDOM
--==================================================

math.randomseed(
    os.time()
    + math.floor(os.clock() * 100000)
)

local function randomString(length)

    local chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    local result = {}

    for i = 1, length do

        local n =
            math.random(1, #chars)

        result[i] =
            chars:sub(n, n)

    end

    return table.concat(result)
end

--==================================================
-- AUTH GUI
--==================================================

local authGui =
    Instance.new("ScreenGui")

authGui.Name =
    "RaherAuth"

authGui.ResetOnSpawn = false
authGui.Parent = CoreGui

local authFrame =
    Instance.new("Frame")

authFrame.Size =
    UDim2.new(0, 330, 0, 220)

authFrame.Position =
    UDim2.new(
        0.5,
        -165,
        0.5,
        -110
    )

authFrame.BackgroundColor3 =
    Color3.fromRGB(20, 20, 25)

authFrame.BorderSizePixel = 0
authFrame.Parent = authGui

local authCorner =
    Instance.new("UICorner")

authCorner.CornerRadius =
    UDim.new(0, 14)

authCorner.Parent = authFrame

local authTitle =
    Instance.new("TextLabel")

authTitle.Size =
    UDim2.new(1, 0, 0, 45)

authTitle.BackgroundTransparency = 1

authTitle.Text =
    "RAHERHUB"

authTitle.TextColor3 =
    Color3.fromRGB(255, 255, 255)

authTitle.TextSize = 24

authTitle.Font =
    Enum.Font.GothamBold

authTitle.Parent = authFrame

local statusLabel =
    Instance.new("TextLabel")

statusLabel.Size =
    UDim2.new(1, -20, 0, 28)

statusLabel.Position =
    UDim2.new(0, 10, 0, 40)

statusLabel.BackgroundTransparency = 1

statusLabel.Text =
    "Checking saved account..."

statusLabel.TextColor3 =
    Color3.fromRGB(170, 170, 170)

statusLabel.TextSize = 13

statusLabel.Font =
    Enum.Font.Gotham

statusLabel.Parent = authFrame

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

local authButton =
    Instance.new("TextButton")

authButton.Size =
    UDim2.new(1, -150, 0, 40)

authButton.Position =
    UDim2.new(0, 15, 0, 124)

authButton.BackgroundColor3 =
    Color3.fromRGB(55, 125, 255)

authButton.BorderSizePixel = 0

authButton.Text =
    "LOGIN"

authButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

authButton.TextSize = 14

authButton.Font =
    Enum.Font.GothamBold

authButton.Parent = authFrame

local authButtonCorner =
    Instance.new("UICorner")

authButtonCorner.CornerRadius =
    UDim.new(0, 9)

authButtonCorner.Parent = authButton

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

resetButton.Visible = false

resetButton.Parent = authFrame

local resetCorner =
    Instance.new("UICorner")

resetCorner.CornerRadius =
    UDim.new(0, 9)

resetCorner.Parent = resetButton

local deviceLabel =
    Instance.new("TextLabel")

deviceLabel.Size =
    UDim2.new(1, -20, 0, 18)

deviceLabel.Position =
    UDim2.new(0, 10, 1, -22)

deviceLabel.BackgroundTransparency = 1

deviceLabel.Text =
    "Device ID: "
    .. hwid:sub(1, 8)
    .. "..."

deviceLabel.TextColor3 =
    Color3.fromRGB(100, 100, 110)

deviceLabel.TextSize = 10

deviceLabel.Font =
    Enum.Font.Gotham

deviceLabel.Parent = authFrame

--==================================================
-- AUTH FUNCTIONS
--==================================================

local authenticated = false
local authenticating = false

local function setAuthStatus(text, good)

    statusLabel.Text =
        tostring(text)

    if good then

        statusLabel.TextColor3 =
            Color3.fromRGB(
                100,
                255,
                130
            )

    else

        statusLabel.TextColor3 =
            Color3.fromRGB(
                255,
                100,
                100
            )

    end

end

local function getSavedAccount()

    local username =
        readFile(USER_FILE)

    local password =
        readFile(PASS_FILE)

    if username and password then
        return username, password
    end

    return nil, nil
end

local function saveAccount(username, password)

    local a =
        writeFile(
            USER_FILE,
            username
        )

    local b =
        writeFile(
            PASS_FILE,
            password
        )

    return a and b
end

local function clearAccount()

    deleteFile(USER_FILE)
    deleteFile(PASS_FILE)

end

local function login(username, password)

    return ekisdeCall(
        "login",
        {
            username = username,
            password = password,
            hwid = hwid
        }
    )

end

--==================================================
-- AUTHENTICATE
--==================================================

local function authenticate()

    if authenticating or authenticated then
        return
    end

    authenticating = true

    authButton.Text =
        "CHECKING..."

    setAuthStatus(
        "Connecting...",
        false
    )

    local initOK, initResult =
        ekisdeCall(
            "init",
            {
                version = VERSION
            }
        )

    if not initOK then

        setAuthStatus(
            "Init error: "
            .. tostring(initResult),
            false
        )

        authButton.Text =
            "LOGIN"

        authenticating = false

        return
    end

    --==================================================
    -- SAVED ACCOUNT
    --==================================================

    local username,
          password =
        getSavedAccount()

    if username and password then

        keyBox.Visible = false
        resetButton.Visible = true

        setAuthStatus(
            "Saved account found...",
            false
        )

        local ok, result =
            login(
                username,
                password
            )

        if ok then

            authenticated = true

            setAuthStatus(
                "Access granted",
                true
            )

            authButton.Text =
                "ACCESS GRANTED"

            task.wait(0.5)

            authGui:Destroy()

            return
        end

        setAuthStatus(
            "Login failed: "
            .. tostring(result),
            false
        )

        authButton.Text =
            "LOGIN"

        authenticating = false

        return
    end

    --==================================================
    -- FIRST ACTIVATION
    --==================================================

    keyBox.Visible = true
    resetButton.Visible = false

    local license =
        keyBox.Text:gsub("%s+", "")

    if license == "" then

        setAuthStatus(
            "Enter your license key",
            false
        )

        authButton.Text =
            "ACTIVATE"

        authenticating = false

        return
    end

    setAuthStatus(
        "Activating license...",
        false
    )

    local newUsername =
        "rah_" .. randomString(12)

    local newPassword =
        randomString(32)

    saveAccount(
        newUsername,
        newPassword
    )

    local registerOK,
          registerResult =
        ekisdeCall(
            "register",
            {
                username = newUsername,
                password = newPassword,
                license = license,
                hwid = hwid
            }
        )

    if registerOK then

        authenticated = true

        setAuthStatus(
            "License activated",
            true
        )

        task.wait(0.5)

        authGui:Destroy()

        return
    end

    local errorText =
        tostring(registerResult)

    if errorText:lower():find(
        "used",
        1,
        true
    ) then

        setAuthStatus(
            "Key already used. Recovering...",
            false
        )

        local recoverOK,
              recoverResult =
            login(
                newUsername,
                newPassword
            )

        if recoverOK then

            authenticated = true

            setAuthStatus(
                "Account recovered",
                true
            )

            task.wait(0.5)

            authGui:Destroy()

            return
        end

        setAuthStatus(
            "Recovery failed: "
            .. tostring(recoverResult),
            false
        )

        authButton.Text =
            "LOGIN"

        authenticating = false

        return
    end

    setAuthStatus(
        errorText,
        false
    )

    authButton.Text =
        "ACTIVATE"

    authenticating = false

end

resetButton.MouseButton1Click:Connect(
    function()

        if authenticating then
            return
        end

        clearAccount()

        keyBox.Visible = true
        resetButton.Visible = false

        keyBox.Text = ""

        authButton.Text =
            "ACTIVATE"

        setAuthStatus(
            "Local account reset",
            false
        )

    end
)

authButton.MouseButton1Click:Connect(
    authenticate
)

keyBox.FocusLost:Connect(
    function(enterPressed)

        if enterPressed then
            authenticate()
        end

    end
)

task.spawn(function()

    task.wait(0.2)

    local username,
          password =
        getSavedAccount()

    if username and password then

        keyBox.Visible = false
        resetButton.Visible = true

        authenticate()

    else

        keyBox.Visible = true
        resetButton.Visible = false

        authButton.Text =
            "ACTIVATE"

        setAuthStatus(
            "Enter your license key",
            false
        )

    end

end)

repeat
    task.wait()
until authenticated

--==================================================
-- MAIN GUI
--==================================================

local gui =
    Instance.new("ScreenGui")

gui.Name =
    "RaherHUB"

gui.ResetOnSpawn = false
gui.Parent = CoreGui

--==================================================
-- FLY SETTINGS STORAGE
--==================================================

local function getNumber(path, default)

    local value =
        tonumber(readFile(path))

    if value then
        return value
    end

    return default
end

local flyX =
    getNumber(
        FLY_X_FILE,
        0.78
    )

local flyY =
    getNumber(
        FLY_Y_FILE,
        0.48
    )

local flySize =
    getNumber(
        FLY_SIZE_FILE,
        55
    )

--==================================================
-- MAIN FRAME
--==================================================

local main =
    Instance.new("Frame")

main.Size =
    UDim2.new(
        0,
        310,
        0,
        300
    )

main.Position =
    UDim2.new(
        0.5,
        -155,
        0.5,
        -150
    )

main.BackgroundColor3 =
    Color3.fromRGB(
        18,
        18,
        24
    )

main.BorderSizePixel = 0

main.Parent = gui

local mainCorner =
    Instance.new("UICorner")

mainCorner.CornerRadius =
    UDim.new(0, 14)

mainCorner.Parent = main

--==================================================
-- HEADER
--==================================================

local header =
    Instance.new("Frame")

header.Size =
    UDim2.new(
        1,
        0,
        0,
        48
    )

header.BackgroundColor3 =
    Color3.fromRGB(
        30,
        30,
        40
    )

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
    UDim2.new(
        1,
        -60,
        1,
        0
    )

title.Position =
    UDim2.new(
        0,
        15,
        0,
        0
    )

title.BackgroundTransparency = 1

title.Text =
    "RAHERHUB"

title.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

title.TextSize = 19

title.Font =
    Enum.Font.GothamBold

title.TextXAlignment =
    Enum.TextXAlignment.Left

title.Parent = header

--==================================================
-- CLOSE
--==================================================

local hideButton =
    Instance.new("TextButton")

hideButton.Size =
    UDim2.new(
        0,
        42,
        0,
        34
    )

hideButton.Position =
    UDim2.new(
        1,
        -48,
        0,
        7
    )

hideButton.BackgroundColor3 =
    Color3.fromRGB(
        50,
        50,
        60
    )

hideButton.BorderSizePixel = 0

hideButton.Text =
    "×"

hideButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

hideButton.TextSize = 23

hideButton.Font =
    Enum.Font.GothamBold

hideButton.Parent = header

local hideCorner =
    Instance.new("UICorner")

hideCorner.CornerRadius =
    UDim.new(0, 8)

hideCorner.Parent = hideButton

--==================================================
-- TABS
--==================================================

local tabs =
    Instance.new("Frame")

tabs.Size =
    UDim2.new(
        1,
        -20,
        0,
        38
    )

tabs.Position =
    UDim2.new(
        0,
        10,
        0,
        58
    )

tabs.BackgroundTransparency = 1
tabs.Parent = main

local function createTab(text, x, width)

    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(
            0,
            width,
            0,
            34
        )

    button.Position =
        UDim2.new(
            0,
            x,
            0,
            0
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            42,
            42,
            52
        )

    button.BorderSizePixel = 0

    button.Text = text

    button.TextColor3 =
        Color3.fromRGB(
            230,
            230,
            230
        )

    button.TextSize = 11

    button.Font =
        Enum.Font.GothamBold

    button.Parent = tabs

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 8)

    corner.Parent = button

    return button
end

local mainTab =
    createTab(
        "MAIN",
        0,
        70
    )

local feature1Tab =
    createTab(
        "FEATURE 1",
        76,
        82
    )

local flySettingsTab =
    createTab(
        "FLY",
        164,
        60
    )

local feature2Tab =
    createTab(
        "FEATURE 2",
        230,
        70
    )

--==================================================
-- PAGES
--==================================================

local function createPage()

    local page =
        Instance.new("Frame")

    page.Size =
        UDim2.new(
            1,
            -20,
            1,
            -108
        )

    page.Position =
        UDim2.new(
            0,
            10,
            0,
            102
        )

    page.BackgroundTransparency = 1

    page.Parent = main

    return page
end

local mainPage =
    createPage()

local feature1Page =
    createPage()

local flyPage =
    createPage()

local feature2Page =
    createPage()

feature1Page.Visible = false
flyPage.Visible = false
feature2Page.Visible = false

--==================================================
-- MAIN DRAG
--==================================================

local mainDragging = false
local mainDragStart
local mainStartPosition

header.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            mainDragging = true

            mainDragStart =
                input.Position

            mainStartPosition =
                main.Position

        end

    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if not mainDragging then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or input.UserInputType ==
            Enum.UserInputType.Touch then

            local delta =
                input.Position
                - mainDragStart

            main.Position =
                UDim2.new(
                    mainStartPosition.X.Scale,
                    mainStartPosition.X.Offset
                        + delta.X,

                    mainStartPosition.Y.Scale,
                    mainStartPosition.Y.Offset
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

            mainDragging = false

        end

    end
)

--==================================================
-- TOGGLE
--==================================================

local function createToggle(parent, text, y)

    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(
            1,
            0,
            0,
            42
        )

    button.Position =
        UDim2.new(
            0,
            0,
            0,
            y
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            38,
            38,
            48
        )

    button.BorderSizePixel = 0

    button.Text =
        text .. "  [OFF]"

    button.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )

    button.TextSize = 14

    button.Font =
        Enum.Font.GothamBold

    button.Parent = parent

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 9)

    corner.Parent = button

    return button
end

--==================================================
-- ESP
--==================================================

local espEnabled = false

local function removeESP(player)

    if not player.Character then
        return
    end

    local h =
        player.Character:FindFirstChild(
            "RaherESP"
        )

    if h then
        h:Destroy()
    end

end

local function addESP(player)

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

    local h =
        Instance.new("Highlight")

    h.Name =
        "RaherESP"

    h.FillTransparency =
        0.55

    h.OutlineTransparency =
        0

    h.Parent =
        player.Character

end

local function updateESP()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if espEnabled then
            addESP(player)
        else
            removeESP(player)
        end

    end

end

local espButton =
    createToggle(
        mainPage,
        "ESP",
        0
    )

espButton.MouseButton1Click:Connect(
    function()

        espEnabled =
            not espEnabled

        espButton.Text =
            "ESP  ["
            .. (espEnabled and "ON" or "OFF")
            .. "]"

        updateESP()

    end
)

Players.PlayerAdded:Connect(
    function(player)

        player.CharacterAdded:Connect(
            function()

                task.wait(0.5)

                if espEnabled then
                    addESP(player)
                end

            end
        )

    end
)

Players.PlayerRemoving:Connect(
    removeESP
)

--==================================================
-- FLY
--==================================================

local flyEnabled = false
local flyUp = false

local flyButton =
    createToggle(
        mainPage,
        "FLY JUMP",
        52
    )

flyButton.MouseButton1Click:Connect(
    function()

        flyEnabled =
            not flyEnabled

        flyButton.Text =
            "FLY JUMP  ["
            .. (flyEnabled and "ON" or "OFF")
            .. "]"

        if not flyEnabled then
            flyUp = false
        end

    end
)

--==================================================
-- NOCLIP
--==================================================

local noclipEnabled = false

local noclipButton =
    createToggle(
        mainPage,
        "NOCLIP",
        104
    )

noclipButton.MouseButton1Click:Connect(
    function()

        noclipEnabled =
            not noclipEnabled

        noclipButton.Text =
            "NOCLIP  ["
            .. (noclipEnabled and "ON" or "OFF")
            .. "]"

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

--==================================================
-- FLY BUTTON
--==================================================

local flyFloat =
    Instance.new("TextButton")

flyFloat.Size =
    UDim2.new(
        0,
        flySize,
        0,
        flySize
    )

flyFloat.Position =
    UDim2.new(
        flyX,
        0,
        flyY,
        0
    )

flyFloat.BackgroundColor3 =
    Color3.fromRGB(
        50,
        130,
        255
    )

flyFloat.BorderSizePixel = 0

flyFloat.Text =
    "↑"

flyFloat.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

flyFloat.TextSize =
    math.floor(flySize * 0.5)

flyFloat.Font =
    Enum.Font.GothamBold

flyFloat.Parent = gui

local flyCorner =
    Instance.new("UICorner")

flyCorner.CornerRadius =
    UDim.new(1, 0)

flyCorner.Parent = flyFloat

--==================================================
-- FLY HOLD
--==================================================

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

        if not flyEnabled or not flyUp then
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

--==================================================
-- FLY SETTINGS PAGE
--==================================================

local settingsTitle =
    Instance.new("TextLabel")

settingsTitle.Size =
    UDim2.new(
        1,
        0,
        0,
        30
    )

settingsTitle.BackgroundTransparency = 1

settingsTitle.Text =
    "FLY BUTTON SETTINGS"

settingsTitle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

settingsTitle.TextSize = 16

settingsTitle.Font =
    Enum.Font.GothamBold

settingsTitle.Parent =
    flyPage

--==================================================
-- MOVE MODE
--==================================================

local moveMode = false

local moveButton =
    Instance.new("TextButton")

moveButton.Size =
    UDim2.new(
        1,
        0,
        0,
        42
    )

moveButton.Position =
    UDim2.new(
        0,
        0,
        0,
        38
    )

moveButton.BackgroundColor3 =
    Color3.fromRGB(
        38,
        38,
        48
    )

moveButton.BorderSizePixel = 0

moveButton.Text =
    "MOVE FLY BUTTON  [OFF]"

moveButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

moveButton.TextSize = 13

moveButton.Font =
    Enum.Font.GothamBold

moveButton.Parent =
    flyPage

local moveCorner =
    Instance.new("UICorner")

moveCorner.CornerRadius =
    UDim.new(0, 9)

moveCorner.Parent =
    moveButton

moveButton.MouseButton1Click:Connect(
    function()

        moveMode =
            not moveMode

        moveButton.Text =
            "MOVE FLY BUTTON  ["
            .. (moveMode and "ON" or "OFF")
            .. "]"

        if moveMode then

            flyFloat.BackgroundColor3 =
                Color3.fromRGB(
                    80,
                    180,
                    255
                )

        else

            flyFloat.BackgroundColor3 =
                Color3.fromRGB(
                    50,
                    130,
                    255
                )

        end

    end
)

--==================================================
-- FLY SIZE
--==================================================

local sizeLabel =
    Instance.new("TextLabel")

sizeLabel.Size =
    UDim2.new(
        1,
        0,
        0,
        28
    )

sizeLabel.Position =
    UDim2.new(
        0,
        0,
        0,
        90
    )

sizeLabel.BackgroundTransparency = 1

sizeLabel.Text =
    "SIZE: "
    .. tostring(math.floor(flySize))

sizeLabel.TextColor3 =
    Color3.fromRGB(
        210,
        210,
        220
    )

sizeLabel.TextSize = 13

sizeLabel.Font =
    Enum.Font.GothamBold

sizeLabel.Parent =
    flyPage

--==================================================
-- SIZE MINUS
--==================================================

local minusButton =
    Instance.new("TextButton")

minusButton.Size =
    UDim2.new(
        0.48,
        -4,
        0,
        42
    )

minusButton.Position =
    UDim2.new(
        0,
        0,
        0,
        120
    )

minusButton.BackgroundColor3 =
    Color3.fromRGB(
        38,
        38,
        48
    )

minusButton.BorderSizePixel = 0

minusButton.Text =
    "−"

minusButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

minusButton.TextSize = 22

minusButton.Font =
    Enum.Font.GothamBold

minusButton.Parent =
    flyPage

local minusCorner =
    Instance.new("UICorner")

minusCorner.CornerRadius =
    UDim.new(0, 9)

minusCorner.Parent =
    minusButton

--==================================================
-- SIZE PLUS
--==================================================

local plusButton =
    Instance.new("TextButton")

plusButton.Size =
    UDim2.new(
        0.48,
        -4,
        0,
        42
    )

plusButton.Position =
    UDim2.new(
        0.52,
        0,
        0,
        120
    )

plusButton.BackgroundColor3 =
    Color3.fromRGB(
        38,
        38,
        48
    )

plusButton.BorderSizePixel = 0

plusButton.Text =
    "+"

plusButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

plusButton.TextSize = 22

plusButton.Font =
    Enum.Font.GothamBold

plusButton.Parent =
    flyPage

local plusCorner =
    Instance.new("UICorner")

plusCorner.CornerRadius =
    UDim.new(0, 9)

plusCorner.Parent =
    plusButton

local function applyFlySize()

    flyFloat.Size =
        UDim2.new(
            0,
            flySize,
            0,
            flySize
        )

    flyFloat.TextSize =
        math.floor(
            flySize * 0.5
        )

    sizeLabel.Text =
        "SIZE: "
        .. tostring(math.floor(flySize))

    writeFile(
        FLY_SIZE_FILE,
        flySize
    )

end

minusButton.MouseButton1Click:Connect(
    function()

        flySize =
            math.max(
                35,
                flySize - 5
            )

        applyFlySize()

    end
)

plusButton.MouseButton1Click:Connect(
    function()

        flySize =
            math.min(
                90,
                flySize + 5
            )

        applyFlySize()

    end
)

--==================================================
-- RESET POSITION
--==================================================

local resetFlyButton =
    Instance.new("TextButton")

resetFlyButton.Size =
    UDim2.new(
        1,
        0,
        0,
        42
    )

resetFlyButton.Position =
    UDim2.new(
        0,
        0,
        0,
        174
    )

resetFlyButton.BackgroundColor3 =
    Color3.fromRGB(
        55,
        55,
        65
    )

resetFlyButton.BorderSizePixel = 0

resetFlyButton.Text =
    "RESET FLY POSITION"

resetFlyButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

resetFlyButton.TextSize = 13

resetFlyButton.Font =
    Enum.Font.GothamBold

resetFlyButton.Parent =
    flyPage

local resetFlyCorner =
    Instance.new("UICorner")

resetFlyCorner.CornerRadius =
    UDim.new(0, 9)

resetFlyCorner.Parent =
    resetFlyButton

resetFlyButton.MouseButton1Click:Connect(
    function()

        flyX = 0.78
        flyY = 0.48

        flyFloat.Position =
            UDim2.new(
                flyX,
                0,
                flyY,
                0
            )

        writeFile(
            FLY_X_FILE,
            flyX
        )

        writeFile(
            FLY_Y_FILE,
            flyY
        )

    end
)

--==================================================
-- FLY DRAG MODE
--==================================================

local flyDragging = false
local flyDragStart
local flyStartPosition
local flyMoved = false

flyFloat.InputBegan:Connect(
    function(input)

        if not moveMode then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.Touch
            or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            flyDragging = true
            flyMoved = false

            flyDragStart =
                input.Position

            flyStartPosition =
                flyFloat.Position

        end

    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if not flyDragging then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.Touch
            or input.UserInputType ==
            Enum.UserInputType.MouseMovement then

            local delta =
                input.Position
                - flyDragStart

            if math.abs(delta.X) > 4
                or math.abs(delta.Y) > 4 then

                flyMoved = true

            end

            flyFloat.Position =
                UDim2.new(
                    flyStartPosition.X.Scale,
                    flyStartPosition.X.Offset
                        + delta.X,

                    flyStartPosition.Y.Scale,
                    flyStartPosition.Y.Offset
                        + delta.Y
                )

        end

    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if not flyDragging then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.Touch
            or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            flyDragging = false

            if flyMoved then

                local camera =
                    workspace.CurrentCamera

                local viewport =
                    camera.ViewportSize

                local absolute =
                    flyFloat.AbsolutePosition

                flyX =
                    math.clamp(
                        absolute.X
                        / viewport.X,
                        0,
                        0.95
                    )

                flyY =
                    math.clamp(
                        absolute.Y
                        / viewport.Y,
                        0,
                        0.95
                    )

                flyFloat.Position =
                    UDim2.new(
                        flyX,
                        0,
                        flyY,
                        0
                    )

                writeFile(
                    FLY_X_FILE,
                    flyX
                )

                writeFile(
                    FLY_Y_FILE,
                    flyY
                )

            end

        end

    end
)

--==================================================
-- OTHER PAGES
--==================================================

local feature1Text =
    Instance.new("TextLabel")

feature1Text.Size =
    UDim2.new(
        1,
        0,
        0,
        40
    )

feature1Text.BackgroundTransparency = 1

feature1Text.Text =
    "FEATURE 1"

feature1Text.TextColor3 =
    Color3.fromRGB(
        150,
        150,
        160
    )

feature1Text.TextSize = 15

feature1Text.Font =
    Enum.Font.GothamBold

feature1Text.Parent =
    feature1Page

local feature2Text =
    Instance.new("TextLabel")

feature2Text.Size =
    UDim2.new(
        1,
        0,
        0,
        40
    )

feature2Text.BackgroundTransparency = 1

feature2Text.Text =
    "FEATURE 2"

feature2Text.TextColor3 =
    Color3.fromRGB(
        150,
        150,
        160
    )

feature2Text.TextSize = 15

feature2Text.Font =
    Enum.Font.GothamBold

feature2Text.Parent =
    feature2Page

--==================================================
-- TAB SWITCH
--==================================================

local function showPage(page)

    mainPage.Visible = false
    feature1Page.Visible = false
    flyPage.Visible = false
    feature2Page.Visible = false

    page.Visible = true

end

mainTab.MouseButton1Click:Connect(
    function()
        showPage(mainPage)
    end
)

feature1Tab.MouseButton1Click:Connect(
    function()
        showPage(feature1Page)
    end
)

flySettingsTab.MouseButton1Click:Connect(
    function()
        showPage(flyPage)
    end
)

feature2Tab.MouseButton1Click:Connect(
    function()
        showPage(feature2Page)
    end
)

--==================================================
-- OPEN BUTTON
--==================================================

local openButton =
    Instance.new("TextButton")

openButton.Size =
    UDim2.new(
        0,
        58,
        0,
        58
    )

openButton.Position =
    UDim2.new(
        0,
        20,
        0.5,
        -29
    )

openButton.BackgroundColor3 =
    Color3.fromRGB(
        35,
        105,
        230
    )

openButton.BorderSizePixel = 0

openButton.Text =
    "≡"

openButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

openButton.TextSize = 30

openButton.Font =
    Enum.Font.GothamBold

openButton.Visible = false

openButton.Parent = gui

local openCorner =
    Instance.new("UICorner")

openCorner.CornerRadius =
    UDim.new(1, 0)

openCorner.Parent =
    openButton

--==================================================
-- OPEN BUTTON DRAG
--==================================================

local openDragging = false
local openMoved = false
local openDragStart
local openStartPosition

openButton.InputBegan:Connect(
    function(input)

        if input.UserInputType ==
            Enum.UserInputType.Touch
            or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            openDragging = true
            openMoved = false

            openDragStart =
                input.Position

            openStartPosition =
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
            Enum.UserInputType.Touch
            or input.UserInputType ==
            Enum.UserInputType.MouseMovement then

            local delta =
                input.Position
                - openDragStart

            if math.abs(delta.X) > 5
                or math.abs(delta.Y) > 5 then

                openMoved = true

            end

            openButton.Position =
                UDim2.new(
                    openStartPosition.X.Scale,
                    openStartPosition.X.Offset
                        + delta.X,

                    openStartPosition.Y.Scale,
                    openStartPosition.Y.Offset
                        + delta.Y
                )

        end

    end
)

UserInputService.InputEnded:Connect(
    function(input)

        if not openDragging then
            return
        end

        if input.UserInputType ==
            Enum.UserInputType.Touch
            or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            openDragging = false

        end

    end
)

--==================================================
-- OPEN BUTTON CLICK
--==================================================

openButton.MouseButton1Click:Connect(
    function()

        if openMoved then
            openMoved = false
            return
        end

        main.Visible = true
        openButton.Visible = false

    end
)

--==================================================
-- CLOSE MENU
--==================================================

hideButton.MouseButton1Click:Connect(
    function()

        main.Visible = false
        openButton.Visible = true

    end
)

--==================================================
-- RESPAWN SUPPORT
--==================================================

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

--==================================================
-- READY
--==================================================

print(
    "[RAHERHUB] Loaded successfully"
)