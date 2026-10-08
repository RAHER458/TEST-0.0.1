-- RAHERHUB | TEST MENU
-- Ekisde + HWID + AUTO LOGIN + ESP + FLY JUMP + NOCLIP
-- Own Roblox map / testing

local OWNER_ID = "Y46MQF2C3L"
local PUBLIC_KEY = "ZsvsuSaR3FMEEiv4L9krgsZBLLdZhrlmb9iHUlVsjxo="
local VERSION = "1.0"
local BASE_URL = "https://keys.ekisde.dev"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

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
        return nil, "No response"
    end

    local raw = response.Body or response.body

    if not raw then
        return nil, "Empty response"
    end

    local decodeOK, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not decodeOK then
        return nil, "Invalid JSON response"
    end

    return data
end

--------------------------------------------------
-- FILE HELPERS
--------------------------------------------------

local function fileExists(path)
    if type(isfile) ~= "function" then
        return false
    end

    local ok, result = pcall(function()
        return isfile(path)
    end)

    return ok and result == true
end

local function readText(path)
    if type(readfile) ~= "function" then
        return nil
    end

    local ok, result = pcall(function()
        return readfile(path)
    end)

    if ok and result and #result > 0 then
        return result
    end

    return nil
end

local function writeText(path, value)
    if type(writefile) ~= "function" then
        return false
    end

    local ok = pcall(function()
        writefile(path, value)
    end)

    return ok
end

--------------------------------------------------
-- HWID
--------------------------------------------------

local function getHWID()
    local functions = {
        "gethwid",
        "get_hwid"
    }

    for _, name in ipairs(functions) do
        local fn = getgenv and getgenv()[name] or _G[name]

        if type(fn) == "function" then
            local ok, result = pcall(fn)

            if ok and result then
                result = tostring(result)

                if result ~= "" then
                    return result
                end
            end
        end
    end

    if type(getexecutor) == "function" then
        -- Executor name is NOT a HWID.
        -- This is deliberately not used as a fallback.
    end

    return nil
end

local hwid = getHWID()

if not hwid then
    LocalPlayer:Kick(
        "HWID is not supported by this executor"
    )
    return
end

--------------------------------------------------
-- AUTH FILES
--------------------------------------------------

local USER_FILE = "raherhub_user.txt"
local PASS_FILE = "raherhub_pass.txt"

local savedUsername = readText(USER_FILE)
local savedPassword = readText(PASS_FILE)

--------------------------------------------------
-- KEYAUTH / EKISDE
--------------------------------------------------

local session = ""

local function randomString(length)
    local chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    local result = ""

    for i = 1, length do
        local n = math.random(1, #chars)
        result = result .. chars:sub(n, n)
    end

    return result
end

math.randomseed(
    os.time() +
    math.floor(os.clock() * 100000)
)

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
        session = data.session
    end

    if data.success == false then
        return false,
            data.message or "Request failed"
    end

    return true, data
end

--------------------------------------------------
-- AUTH GUI
--------------------------------------------------

local authGui = Instance.new("ScreenGui")
authGui.Name = "RaherAuth"
authGui.ResetOnSpawn = false
authGui.Parent = CoreGui

local authFrame = Instance.new("Frame")
authFrame.Size = UDim2.new(0, 330, 0, 190)
authFrame.Position =
    UDim2.new(0.5, -165, 0.5, -95)
authFrame.BackgroundColor3 =
    Color3.fromRGB(20, 20, 25)
authFrame.BorderSizePixel = 0
authFrame.Parent = authGui

local authCorner = Instance.new("UICorner")
authCorner.CornerRadius =
    UDim.new(0, 14)
authCorner.Parent = authFrame

local authTitle = Instance.new("TextLabel")
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

local authSub = Instance.new("TextLabel")
authSub.Size =
    UDim2.new(1, -20, 0, 25)
authSub.Position =
    UDim2.new(0, 10, 0, 40)
authSub.BackgroundTransparency = 1
authSub.TextColor3 =
    Color3.fromRGB(170, 170, 170)
authSub.TextSize = 14
authSub.Font =
    Enum.Font.Gotham
authSub.Parent = authFrame

local keyBox = Instance.new("TextBox")
keyBox.Size =
    UDim2.new(1, -30, 0, 42)
keyBox.Position =
    UDim2.new(0, 15, 0, 72)
keyBox.BackgroundColor3 =
    Color3.fromRGB(32, 32, 40)
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText =
    "Enter license key"
keyBox.PlaceholderColor3 =
    Color3.fromRGB(100, 100, 110)
keyBox.Text = ""
keyBox.TextColor3 =
    Color3.fromRGB(255, 255, 255)
keyBox.TextSize = 15
keyBox.Font =
    Enum.Font.Gotham
keyBox.ClearTextOnFocus = false
keyBox.Parent = authFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius =
    UDim.new(0, 9)
keyCorner.Parent = keyBox

local checkButton = Instance.new("TextButton")
checkButton.Size =
    UDim2.new(1, -30, 0, 40)
checkButton.Position =
    UDim2.new(0, 15, 0, 122)
checkButton.BackgroundColor3 =
    Color3.fromRGB(55, 125, 255)
checkButton.BorderSizePixel = 0
checkButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)
checkButton.TextSize = 15
checkButton.Font =
    Enum.Font.GothamBold
checkButton.Parent = authFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius =
    UDim.new(0, 9)
buttonCorner.Parent = checkButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Size =
    UDim2.new(1, -20, 0, 22)
statusLabel.Position =
    UDim2.new(0, 10, 1, -25)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 =
    Color3.fromRGB(255, 100, 100)
statusLabel.TextSize = 12
statusLabel.Font =
    Enum.Font.Gotham
statusLabel.Parent = authFrame

--------------------------------------------------
-- AUTH MODE
--------------------------------------------------

local hasSavedAccount =
    savedUsername ~= nil
    and savedPassword ~= nil

if hasSavedAccount then
    authSub.Text =
        "Checking saved account..."
    keyBox.Visible = false
    checkButton.Position =
        UDim2.new(0, 15, 0, 85)
    checkButton.Text =
        "LOGIN"
else
    authSub.Text =
        "Enter your license key"
    keyBox.Visible = true
    checkButton.Text =
        "CHECK KEY"
end

--------------------------------------------------
-- AUTHENTICATION
--------------------------------------------------

local authenticated = false
local authenticating = false

local function finishAuthentication()
    authenticated = true

    statusLabel.Text =
        "Access granted"
    statusLabel.TextColor3 =
        Color3.fromRGB(100, 255, 130)

    checkButton.Text =
        "ACCESS GRANTED"

    task.wait(0.5)

    authGui:Destroy()
end

local function authenticate()
    if authenticating or authenticated then
        return
    end

    authenticating = true

    checkButton.Text =
        "CHECKING..."

    statusLabel.Text =
        "Connecting..."
    statusLabel.TextColor3 =
        Color3.fromRGB(170, 170, 170)

    --------------------------------------------------
    -- INIT
    --------------------------------------------------

    local initOK, initResult =
        ekisdeCall("init", {
            version = VERSION
        })

    if not initOK then
        statusLabel.Text =
            tostring(initResult)

        checkButton.Text =
            hasSavedAccount
            and "LOGIN"
            or "CHECK KEY"

        authenticating = false
        return
    end

    --------------------------------------------------
    -- EXISTING ACCOUNT
    --------------------------------------------------

    if hasSavedAccount then

        local loginOK, loginResult =
            ekisdeCall("login", {
                username = savedUsername,
                password = savedPassword,
                hwid = hwid
            })

        if not loginOK then
            statusLabel.Text =
                tostring(loginResult)

            checkButton.Text =
                "LOGIN"

            authenticating = false
            return
        end

        finishAuthentication()
        return
    end

    --------------------------------------------------
    -- FIRST ACTIVATION
    --------------------------------------------------

    local license =
        keyBox.Text:gsub("%s+", "")

    if license == "" then
        statusLabel.Text =
            "Enter a license key"

        checkButton.Text =
            "CHECK KEY"

        authenticating = false
        return
    end

    local username =
        "rah_" .. randomString(12)

    local password =
        randomString(32)

    local registerOK, registerResult =
        ekisdeCall("register", {
            username = username,
            password = password,
            license = license,
            hwid = hwid
        })

    if not registerOK then
        statusLabel.Text =
            tostring(registerResult)

        checkButton.Text =
            "CHECK KEY"

        authenticating = false
        return
    end

    --------------------------------------------------
    -- SAVE ACCOUNT
    --------------------------------------------------

    local userSaved =
        writeText(
            USER_FILE,
            username
        )

    local passSaved =
        writeText(
            PASS_FILE,
            password
        )

    if not userSaved or not passSaved then
        statusLabel.Text =
            "Activated, but account could not be saved"

        checkButton.Text =
            "ACCESS GRANTED"

        authenticated = true

        task.wait(0.8)
        authGui:Destroy()

        return
    end

    finishAuthentication()
end

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
-- WAIT FOR AUTH
--------------------------------------------------

repeat
    task.wait()
until authenticated

--------------------------------------------------
-- MAIN GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "RaherHUB"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size =
    UDim2.new(0, 300, 0, 280)
main.Position =
    UDim2.new(0.5, -150, 0.5, -140)
main.BackgroundColor3 =
    Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius =
    UDim.new(0, 14)
mainCorner.Parent = main

--------------------------------------------------
-- HEADER
--------------------------------------------------

local header = Instance.new("Frame")
header.Size =
    UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 =
    Color3.fromRGB(30, 30, 40)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius =
    UDim.new(0, 14)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size =
    UDim2.new(1, -55, 1, 0)
title.Position =
    UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "RAHERHUB"
title.TextColor3 =
    Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font =
    Enum.Font.GothamBold
title.TextXAlignment =
    Enum.TextXAlignment.Left
title.Parent = header

local hideButton = Instance.new("TextButton")
hideButton.Size =
    UDim2.new(0, 45, 0, 45)
hideButton.Position =
    UDim2.new(1, -47, 0, 1)
hideButton.BackgroundTransparency = 1
hideButton.Text = "×"
hideButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)
hideButton.TextSize = 28
hideButton.Font =
    Enum.Font.GothamBold
hideButton.Parent = header

--------------------------------------------------
-- MAIN MENU DRAG
--------------------------------------------------

local dragging = false
local dragStart
local startPos

header.InputBegan:Connect(
    function(input)
        if
            input.UserInputType ==
                Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
                Enum.UserInputType.Touch
        then

            dragging = true
            dragStart = input.Position
            startPos = main.Position

            input.Changed:Connect(
                function()
                    if
                        input.UserInputState ==
                            Enum.UserInputState.End
                    then
                        dragging = false
                    end
                end
            )
        end
    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if not dragging then
            return
        end

        if
            input.UserInputType ==
                Enum.UserInputType.MouseMovement
            or
            input.UserInputType ==
                Enum.UserInputType.Touch
        then

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
    end
)

--------------------------------------------------
-- TABS
--------------------------------------------------

local tabs = Instance.new("Frame")
tabs.Size =
    UDim2.new(1, -20, 0, 38)
tabs.Position =
    UDim2.new(0, 10, 0, 55)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local function makeTab(text, x)

    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(0, 85, 1, 0)

    button.Position =
        UDim2.new(0, x, 0, 0)

    button.BackgroundColor3 =
        Color3.fromRGB(38, 38, 48)

    button.BorderSizePixel = 0
    button.Text = text

    button.TextColor3 =
        Color3.fromRGB(220, 220, 220)

    button.TextSize = 13
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
    makeTab("Main", 0)

local feature1Tab =
    makeTab("Feature 1", 90)

local feature2Tab =
    makeTab("Feature 2", 180)

local content =
    Instance.new("Frame")

content.Size =
    UDim2.new(1, -20, 1, -105)

content.Position =
    UDim2.new(0, 10, 0, 100)

content.BackgroundTransparency = 1
content.Parent = main

--------------------------------------------------
-- BUTTON FACTORY
--------------------------------------------------

local function makeToggle(text, y)

    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(1, 0, 0, 42)

    button.Position =
        UDim2.new(0, 0, 0, y)

    button.BackgroundColor3 =
        Color3.fromRGB(35, 35, 45)

    button.BorderSizePixel = 0
    button.Text =
        text .. "  [OFF]"

    button.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    button.TextSize = 15
    button.Font =
        Enum.Font.GothamBold
    button.Parent = content

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 9)

    corner.Parent = button

    return button
end

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

    if not espEnabled then
        return
    end

    if not player.Character then
        return
    end

    if espObjects[player] then
        return
    end

    local highlight =
        Instance.new("Highlight")

    highlight.Name =
        "RaherESP"

    highlight.FillColor =
        Color3.fromRGB(255, 70, 70)

    highlight.OutlineColor =
        Color3.fromRGB(255, 255, 255)

    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0

    highlight.Adornee =
        player.Character

    highlight.Parent =
        player.Character

    espObjects[player] =
        highlight
end

local function updateESP()

    for _, player in
        ipairs(Players:GetPlayers()) do

        if espEnabled then
            createESP(player)
        else
            removeESP(player)
        end
    end
end

Players.PlayerAdded:Connect(
    function(player)

        player.CharacterAdded:Connect(
            function()

                task.wait(1)

                if espEnabled then
                    createESP(player)
                end
            end
        )
    end
)

Players.PlayerRemoving:Connect(
    removeESP
)

local espButton =
    makeToggle("ESP", 0)

espButton.MouseButton1Click:Connect(
    function()

        espEnabled =
            not espEnabled

        if espEnabled then

            espButton.Text =
                "ESP  [ON]"

            espButton.BackgroundColor3 =
                Color3.fromRGB(45, 125, 70)

        else

            espButton.Text =
                "ESP  [OFF]"

            espButton.BackgroundColor3 =
                Color3.fromRGB(35, 35, 45)
        end

        updateESP()
    end
)

--------------------------------------------------
-- FLY JUMP
--------------------------------------------------

local flyEnabled = false
local flySpeed = 4
local flyTouchHeld = false

local flyButton =
    makeToggle("FLY JUMP", 52)

flyButton.MouseButton1Click:Connect(
    function()

        flyEnabled =
            not flyEnabled

        if flyEnabled then

            flyButton.Text =
                "FLY JUMP  [ON]"

            flyButton.BackgroundColor3 =
                Color3.fromRGB(45, 125, 70)

        else

            flyButton.Text =
                "FLY JUMP  [OFF]"

            flyButton.BackgroundColor3 =
                Color3.fromRGB(35, 35, 45)
        end
    end
)

local flyTouch =
    Instance.new("TextButton")

flyTouch.Size =
    UDim2.new(0, 62, 0, 62)

flyTouch.Position =
    UDim2.new(1, -85, 1, -150)

flyTouch.BackgroundColor3 =
    Color3.fromRGB(45, 125, 255)

flyTouch.BorderSizePixel = 0
flyTouch.Text = "↑"

flyTouch.TextColor3 =
    Color3.fromRGB(255, 255, 255)

flyTouch.TextSize = 30
flyTouch.Font =
    Enum.Font.GothamBold

flyTouch.Visible = true
flyTouch.Parent = gui

local flyCorner =
    Instance.new("UICorner")

flyCorner.CornerRadius =
    UDim.new(1, 0)

flyCorner.Parent =
    flyTouch

flyTouch.InputBegan:Connect(
    function(input)

        if
            input.UserInputType ==
                Enum.UserInputType.Touch
            or
            input.UserInputType ==
                Enum.UserInputType.MouseButton1
        then

            flyTouchHeld = true
        end
    end
)

flyTouch.InputEnded:Connect(
    function(input)

        if
            input.UserInputType ==
                Enum.UserInputType.Touch
            or
            input.UserInputType ==
                Enum.UserInputType.MouseButton1
        then

            flyTouchHeld = false
        end
    end
)

--------------------------------------------------
-- NOCLIP
--------------------------------------------------

local noclipEnabled = false

local noclipButton =
    makeToggle("NOCLIP", 104)

noclipButton.MouseButton1Click:Connect(
    function()

        noclipEnabled =
            not noclipEnabled

        if noclipEnabled then

            noclipButton.Text =
                "NOCLIP  [ON]"

            noclipButton.BackgroundColor3 =
                Color3.fromRGB(45, 125, 70)

        else

            noclipButton.Text =
                "NOCLIP  [OFF]"

            noclipButton.BackgroundColor3 =
                Color3.fromRGB(35, 35, 45)
        end
    end
)

--------------------------------------------------
-- MOVEMENT LOOP
--------------------------------------------------

RunService.Stepped:Connect(
    function()

        local character =
            LocalPlayer.Character

        if not character then
            return
        end

        if noclipEnabled then

            for _, part in
                ipairs(character:GetDescendants()) do

                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end

        if
            flyEnabled
            and flyTouchHeld
        then

            local root =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if root then

                root.Velocity =
                    Vector3.new(
                        root.Velocity.X,
                        flySpeed * 10,
                        root.Velocity.Z
                    )
            end
        end
    end
)

--------------------------------------------------
-- TABS
--------------------------------------------------

local function clearContent()

    for _, child in
        ipairs(content:GetChildren()) do

        child.Visible = false
    end
end

mainTab.MouseButton1Click:Connect(
    function()

        for _, child in
            ipairs(content:GetChildren()) do

            child.Visible = true
        end
    end
)

feature1Tab.MouseButton1Click:Connect(
    function()
        clearContent()
    end
)

feature2Tab.MouseButton1Click:Connect(
    function()
        clearContent()
    end
)

--------------------------------------------------
-- HIDE / OPEN BUTTON
--------------------------------------------------

local openButton =
    Instance.new("TextButton")

openButton.Size =
    UDim2.new(0, 58, 0, 58)

openButton.Position =
    UDim2.new(0, 20, 0.5, -29)

openButton.BackgroundColor3 =
    Color3.fromRGB(35, 105, 230)

openButton.BorderSizePixel = 0
openButton.Text = "≡"

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

openCorner.Parent =
    openButton

--------------------------------------------------
-- OPEN BUTTON DRAG
--------------------------------------------------

local openDragging = false
local openDragStart
local openStartPos
local openMoved = false

openButton.InputBegan:Connect(
    function(input)

        if
            input.UserInputType ==
                Enum.UserInputType.Touch
            or
            input.UserInputType ==
                Enum.UserInputType.MouseButton1
        then

            openDragging = true
            openMoved = false

            openDragStart =
                input.Position

            openStartPos =
                openButton.Position

            input.Changed:Connect(
                function()

                    if
                        input.UserInputState ==
                            Enum.UserInputState.End
                    then

                        openDragging = false
                    end
                end
            )
        end
    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if not openDragging then
            return
        end

        if
            input.UserInputType ==
                Enum.UserInputType.Touch
            or
            input.UserInputType ==
                Enum.UserInputType.MouseMovement
        then

            local delta =
                input.Position -
                openDragStart

            if math.abs(delta.X) > 5
                or math.abs(delta.Y) > 5 then

                openMoved = true
            end

            openButton.Position =
                UDim2.new(
                    openStartPos.X.Scale,
                    openStartPos.X.Offset + delta.X,
                    openStartPos.Y.Scale,
                    openStartPos.Y.Offset + delta.Y
                )
        end
    end
)

--------------------------------------------------
-- HIDE MENU
--------------------------------------------------

hideButton.MouseButton1Click:Connect(
    function()

        main.Visible = false
        openButton.Visible = true
    end
)

--------------------------------------------------
-- OPEN MENU
--------------------------------------------------

openButton.MouseButton1Click:Connect(
    function()

        if openMoved then
            return
        end

        main.Visible = true
        openButton.Visible = false
    end
)

--------------------------------------------------
-- END
--------------------------------------------------

print("RAHERHUB loaded successfully")