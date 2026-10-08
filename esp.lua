--========================================================--
--                    RAHERHUB 1.0                       --
--========================================================--
-- ESP
-- NOCLIP
-- FLY JUMP
-- MOBILE GUI
-- DRAGGABLE MENU
-- DRAGGABLE FLY BUTTON
-- EKISDE KEYAUTH CLIENT API 1.0
--========================================================--

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
--                    EKISDE CONFIG                      --
--========================================================--

local OWNER_ID =
    "Y46MQF2C3L"

local PUBLIC_KEY =
    "ZsvsuSaR3FMEEiv4L9krgsZBLLdZhrlmb9iHUlVsjxo="

local VERSION =
    "1.0"

local BASE_URL =
    "https://keys.ekisde.dev"

local USER_AGENT =
    "RaherHUB/1.0"

--========================================================--
--                    HTTP REQUEST                       --
--========================================================--

local requestFunction =
    request
    or http_request
    or (syn and syn.request)

if not requestFunction then
    error("RaherHUB: HTTP request function not found.")
end

--========================================================--
--                    FILE HELPERS                       --
--========================================================--

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

    if not readfile then
        return nil
    end

    if not fileExists(path) then
        return nil
    end

    local ok, result = pcall(function()
        return readfile(path)
    end)

    if ok then
        return result
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
        return
    end

    if fileExists(path) then
        pcall(function()
            delfile(path)
        end)
    end
end

--========================================================--
--                  STABLE DEVICE ID                    --
--========================================================--

local DEVICE_FILE =
    "raherhub_device.txt"

local function getDeviceID()

    local saved = readFile(DEVICE_FILE)

    if saved and #saved >= 8 then
        return saved
    end

    local id =
        HttpService:GenerateGUID(false)

    writeFile(DEVICE_FILE, id)

    return id
end

local DEVICE_ID =
    getDeviceID()

--========================================================--
--                    RANDOM NONCE                       --
--========================================================--

local function randomNonce()

    local chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    local result = ""

    for i = 1, 32 do

        local index =
            math.random(1, #chars)

        result =
            result .. string.sub(chars, index, index)

    end

    return result
end

math.randomseed(
    os.time() +
    math.floor(os.clock() * 100000)
)

--========================================================--
--                BASE64 DECODER                         --
--========================================================--

local base64chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Decode(data)

    data =
        data:gsub("[^" .. base64chars .. "=]", "")

    local result = {}

    local buffer = 0
    local bits = 0

    for i = 1, #data do

        local c =
            string.sub(data, i, i)

        if c == "=" then
            break
        end

        local value =
            string.find(base64chars, c, 1, true)

        if value then

            value = value - 1

            buffer =
                buffer * 64 + value

            bits =
                bits + 6

            if bits >= 8 then

                bits =
                    bits - 8

                local byte =
                    math.floor(
                        buffer /
                        (2 ^ bits)
                    ) % 256

                table.insert(
                    result,
                    string.char(byte)
                )

            end

        end

    end

    return table.concat(result)
end

--========================================================--
--               ED25519 VERIFICATION                    --
--========================================================--

local function verifySignature(
    nonce,
    session,
    timestamp,
    signature,
    rawBody
)

    if not signature then
        return false
    end

    if not timestamp then
        return false
    end

    local message =
        nonce
        .. "."
        .. session
        .. "."
        .. timestamp
        .. "."
        .. rawBody

    local publicKeyBytes =
        base64Decode(PUBLIC_KEY)

    local signatureBytes =
        base64Decode(signature)

    ------------------------------------------------------
    -- Variant 1
    ------------------------------------------------------

    if crypt and crypt.verify then

        local ok, result =
            pcall(function()

                return crypt.verify(
                    signatureBytes,
                    message,
                    publicKeyBytes
                )

            end)

        if ok and result == true then
            return true
        end

        --------------------------------------------------
        -- Some executors expect base64 strings
        --------------------------------------------------

        local ok2, result2 =
            pcall(function()

                return crypt.verify(
                    signature,
                    message,
                    PUBLIC_KEY
                )

            end)

        if ok2 and result2 == true then
            return true
        end
    end

    ------------------------------------------------------
    -- Variant 2
    ------------------------------------------------------

    if crypto and crypto.verify then

        local ok, result =
            pcall(function()

                return crypto.verify(
                    signatureBytes,
                    message,
                    publicKeyBytes
                )

            end)

        if ok and result == true then
            return true
        end

        local ok2, result2 =
            pcall(function()

                return crypto.verify(
                    signature,
                    message,
                    PUBLIC_KEY
                )

            end)

        if ok2 and result2 == true then
            return true
        end
    end

    ------------------------------------------------------
    -- No Ed25519 implementation available
    ------------------------------------------------------

    return false
end

--========================================================--
--                   KEYAUTH CLIENT                     --
--========================================================--

local session = ""

local function keyAuthCall(callName, fields)

    fields =
        fields or {}

    local nonce =
        randomNonce()

    local payload = {
        owner_id = OWNER_ID,
        nonce = nonce,
        session = session
    }

    for key, value in pairs(fields) do
        payload[key] = value
    end

    local encoded =
        HttpService:JSONEncode(payload)

    local response

    local ok, err =
        pcall(function()

            response =
                requestFunction({

                    Url =
                        BASE_URL
                        .. "/api/1.0/"
                        .. callName,

                    Method = "POST",

                    Headers = {

                        ["Content-Type"] =
                            "application/json",

                        ["User-Agent"] =
                            USER_AGENT

                    },

                    Body =
                        encoded
                })

        end)

    if not ok or not response then

        return false,
            "HTTP request failed."

    end

    local rawBody =
        response.Body or ""

    local headers =
        response.Headers or {}

    local timestamp =
        headers["X-KeyAuth-Timestamp"]
        or headers["x-keyauth-timestamp"]

    local signature =
        headers["X-KeyAuth-Signature"]
        or headers["x-keyauth-signature"]

    ------------------------------------------------------
    -- Every response must be signed
    ------------------------------------------------------

    if not timestamp or not signature then

        return false,
            "Unsigned server response."

    end

    ------------------------------------------------------
    -- Timestamp validation
    ------------------------------------------------------

    local timestampNumber =
        tonumber(timestamp)

    if not timestampNumber then

        return false,
            "Invalid server timestamp."

    end

    if math.abs(
        os.time() - timestampNumber
    ) > 60 then

        return false,
            "Server response is too old."

    end

    ------------------------------------------------------
    -- Decode body
    ------------------------------------------------------

    local body

    local decodeOK =
        pcall(function()

            body =
                HttpService:JSONDecode(rawBody)

        end)

    if not decodeOK or not body then

        return false,
            "Invalid server response."

    end

    ------------------------------------------------------
    -- INIT is signed using returned session
    ------------------------------------------------------

    local signedSession =
        session

    if callName == "init" then

        signedSession =
            body.session or ""

    end

    ------------------------------------------------------
    -- Signature verification
    ------------------------------------------------------

    local verified =
        verifySignature(
            nonce,
            signedSession,
            timestamp,
            signature,
            rawBody
        )

    if not verified then

        return false,
            "Signature verification failed."

    end

    return true, body
end

--========================================================--
--                     INIT                              --
--========================================================--

local function keyAuthInit()

    local ok, data =
        keyAuthCall(
            "init",
            {
                version = VERSION
            }
        )

    if not ok then
        return false, data
    end

    if data.success ~= true then

        return false,
            data.message
            or "Init failed."

    end

    if not data.session then

        return false,
            "No session returned."

    end

    session =
        data.session

    return true, data
end

--========================================================--
--                 LOGIN DATA                           --
--========================================================--

local USER_FILE =
    "raherhub_user.txt"

local PASS_FILE =
    "raherhub_pass.txt"

local savedUsername =
    readFile(USER_FILE)

local savedPassword =
    readFile(PASS_FILE)

--========================================================--
--                 REGISTER                             --
--========================================================--

local function registerLicense(license)

    if not license
        or license == "" then

        return false,
            "Enter a license key."

    end

    local username =
        "raher_"
        .. string.sub(
            HttpService:GenerateGUID(false)
                :gsub("%-", ""),
            1,
            12
        )

    username =
        string.lower(username)

    local password =
        HttpService:GenerateGUID(false)
            :gsub("%-", "")
            .. "Aa9!"

    local ok, data =
        keyAuthCall(
            "register",
            {

                username =
                    username,

                password =
                    password,

                license =
                    license,

                hwid =
                    DEVICE_ID

            }
        )

    if not ok then

        return false, data

    end

    if data.success ~= true then

        return false,
            data.message
            or "Registration failed."

    end

    writeFile(
        USER_FILE,
        username
    )

    writeFile(
        PASS_FILE,
        password
    )

    savedUsername =
        username

    savedPassword =
        password

    return true, data
end

--========================================================--
--                    LOGIN                             --
--========================================================--

local function login()

    if not savedUsername
        or not savedPassword then

        return false,
            "No saved account."

    end

    local ok, data =
        keyAuthCall(
            "login",
            {

                username =
                    savedUsername,

                password =
                    savedPassword,

                hwid =
                    DEVICE_ID

            }
        )

    if not ok then

        return false, data

    end

    if data.success ~= true then

        return false,
            data.message
            or "Login failed."

    end

    return true, data
end

--========================================================--
--                   CHECK SESSION                      --
--========================================================--

local function checkSession()

    local ok, data =
        keyAuthCall(
            "check"
        )

    if not ok then
        return false, data
    end

    if data.success ~= true then
        return false,
            data.message
            or "Session expired."
    end

    return true, data
end

--========================================================--
--                    AUTH GUI                          --
--========================================================--

local authGui =
    Instance.new("ScreenGui")

authGui.Name =
    "RaherHubAuth"

authGui.ResetOnSpawn =
    false

authGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

pcall(function()
    authGui.Parent =
        game:GetService("CoreGui")
end)

if not authGui.Parent then
    authGui.Parent =
        LocalPlayer:WaitForChild("PlayerGui")
end

local authFrame =
    Instance.new("Frame")

authFrame.Size =
    UDim2.new(0, 340, 0, 270)

authFrame.Position =
    UDim2.new(
        0.5,
        -170,
        0.5,
        -135
    )

authFrame.BackgroundColor3 =
    Color3.fromRGB(
        18,
        18,
        27
    )

authFrame.BorderSizePixel =
    0

authFrame.Parent =
    authGui

Instance.new(
    "UICorner",
    authFrame
).CornerRadius =
    UDim.new(0, 14)

local authTitle =
    Instance.new("TextLabel")

authTitle.Size =
    UDim2.new(
        1,
        -30,
        0,
        45
    )

authTitle.Position =
    UDim2.new(
        0,
        15,
        0,
        12
    )

authTitle.BackgroundTransparency =
    1

authTitle.Text =
    "RAHERHUB"

authTitle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

authTitle.TextSize =
    24

authTitle.Font =
    Enum.Font.GothamBold

authTitle.Parent =
    authFrame

local authStatus =
    Instance.new("TextLabel")

authStatus.Size =
    UDim2.new(
        1,
        -30,
        0,
        45
    )

authStatus.Position =
    UDim2.new(
        0,
        15,
        0,
        57
    )

authStatus.BackgroundTransparency =
    1

authStatus.Text =
    "Проверка..."

authStatus.TextColor3 =
    Color3.fromRGB(
        190,
        190,
        200
    )

authStatus.TextSize =
    13

authStatus.Font =
    Enum.Font.Gotham

authStatus.TextWrapped =
    true

authStatus.Parent =
    authFrame

local keyBox =
    Instance.new("TextBox")

keyBox.Size =
    UDim2.new(
        1,
        -30,
        0,
        45
    )

keyBox.Position =
    UDim2.new(
        0,
        15,
        0,
        105
    )

keyBox.BackgroundColor3 =
    Color3.fromRGB(
        32,
        32,
        43
    )

keyBox.BorderSizePixel =
    0

keyBox.PlaceholderText =
    "License key"

keyBox.PlaceholderColor3 =
    Color3.fromRGB(
        120,
        120,
        130
    )

keyBox.Text =
    ""

keyBox.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

keyBox.TextSize =
    14

keyBox.Font =
    Enum.Font.Gotham

keyBox.ClearTextOnFocus =
    false

keyBox.Parent =
    authFrame

Instance.new(
    "UICorner",
    keyBox
).CornerRadius =
    UDim.new(0, 9)

local authButton =
    Instance.new("TextButton")

authButton.Size =
    UDim2.new(
        1,
        -30,
        0,
        45
    )

authButton.Position =
    UDim2.new(
        0,
        15,
        0,
        160
    )

authButton.BackgroundColor3 =
    Color3.fromRGB(
        75,
        120,
        255
    )

authButton.BorderSizePixel =
    0

authButton.Text =
    "ACTIVATE"

authButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

authButton.TextSize =
    14

authButton.Font =
    Enum.Font.GothamBold

authButton.Parent =
    authFrame

Instance.new(
    "UICorner",
    authButton
).CornerRadius =
    UDim.new(0, 9)

local resetButton =
    Instance.new("TextButton")

resetButton.Size =
    UDim2.new(
        1,
        -30,
        0,
        35
    )

resetButton.Position =
    UDim2.new(
        0,
        15,
        0,
        215
    )

resetButton.BackgroundTransparency =
    1

resetButton.Text =
    "RESET SAVED LOGIN"

resetButton.TextColor3 =
    Color3.fromRGB(
        145,
        145,
        155
    )

resetButton.TextSize =
    11

resetButton.Font =
    Enum.Font.Gotham

resetButton.Parent =
    authFrame

--========================================================--
--              AUTH STATUS HELPER                      --
--========================================================--

local function setStatus(text, good)

    authStatus.Text =
        tostring(text)

    if good then

        authStatus.TextColor3 =
            Color3.fromRGB(
                100,
                255,
                150
            )

    else

        authStatus.TextColor3 =
            Color3.fromRGB(
                255,
                105,
                105
            )

    end
end

--========================================================--
--                  AUTH PROCESS                        --
--========================================================--

local authenticated =
    false

local authFinished =
    false

local function doAuthentication()

    ------------------------------------------------------
    -- INIT
    ------------------------------------------------------

    setStatus(
        "Подключение к серверу...",
        true
    )

    local initOK, initData =
        keyAuthInit()

    if not initOK then

        setStatus(
            "INIT: " .. tostring(initData),
            false
        )

        authFinished =
            true

        return
    end

    ------------------------------------------------------
    -- LOGIN SAVED ACCOUNT
    ------------------------------------------------------

    if savedUsername
        and savedPassword then

        setStatus(
            "Вход в сохранённый аккаунт...",
            true
        )

        local loginOK, loginData =
            login()

        if loginOK then

            local checkOK, checkData =
                checkSession()

            if checkOK then

                authenticated =
                    true

                setStatus(
                    "Авторизация успешна",
                    true
                )

                task.wait(0.5)

                authGui:Destroy()

                authFinished =
                    true

                return

            else

                setStatus(
                    "CHECK: "
                    .. tostring(checkData),
                    false
                )

            end

        else

            setStatus(
                "LOGIN: "
                .. tostring(loginData),
                false
            )

        end

    else

        setStatus(
            "Введите ключ",
            false
        )

    end

    authFinished =
        true
end

task.spawn(
    doAuthentication
)

--========================================================--
--                 ACTIVATE BUTTON                      --
--========================================================--

authButton.MouseButton1Click:Connect(function()

    local key =
        keyBox.Text

    if not key
        or key == "" then

        setStatus(
            "Введите ключ.",
            false
        )

        return
    end

    setStatus(
        "Активация ключа...",
        true
    )

    ------------------------------------------------------
    -- If current session exists, redeem directly
    ------------------------------------------------------

    if session ~= "" then

        local ok, data =
            keyAuthCall(
                "license",
                {
                    license = key
                }
            )

        if ok and data.success == true then

            setStatus(
                "Ключ активирован",
                true
            )

            task.wait(0.5)

            authGui:Destroy()

            authenticated =
                true

            return

        end

    end

    ------------------------------------------------------
    -- Register new account
    ------------------------------------------------------

    local ok, data =
        registerLicense(key)

    if not ok then

        setStatus(
            tostring(data),
            false
        )

        return
    end

    ------------------------------------------------------
    -- Verify session
    ------------------------------------------------------

    local checkOK, checkData =
        checkSession()

    if not checkOK then

        setStatus(
            "CHECK: "
            .. tostring(checkData),
            false
        )

        return
    end

    setStatus(
        "Ключ активирован",
        true
    )

    task.wait(0.5)

    authGui:Destroy()

    authenticated =
        true

end)

keyBox.FocusLost:Connect(function(enterPressed)

    if enterPressed then
        authButton:Activate()
    end

end)

resetButton.MouseButton1Click:Connect(function()

    deleteFile(USER_FILE)
    deleteFile(PASS_FILE)

    savedUsername =
        nil

    savedPassword =
        nil

    keyBox.Text =
        ""

    setStatus(
        "Сохранённый вход сброшен. Введите ключ.",
        false
    )

end)

--========================================================--
--             WAIT FOR AUTHENTICATION                  --
--========================================================--

repeat
    task.wait(0.1)
until authenticated

--========================================================--
--                 MAIN GUI                            --
--========================================================--

local gui =
    Instance.new("ScreenGui")

gui.Name =
    "RaherHUB"

gui.ResetOnSpawn =
    false

gui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

pcall(function()
    gui.Parent =
        game:GetService("CoreGui")
end)

if not gui.Parent then
    gui.Parent =
        LocalPlayer:WaitForChild("PlayerGui")
end

--========================================================--
--                  MAIN FRAME                          --
--========================================================--

local main =
    Instance.new("Frame")

main.Size =
    UDim2.new(
        0,
        350,
        0,
        420
    )

main.Position =
    UDim2.new(
        0.5,
        -175,
        0.5,
        -210
    )

main.BackgroundColor3 =
    Color3.fromRGB(
        18,
        18,
        26
    )

main.BorderSizePixel =
    0

main.Parent =
    gui

Instance.new(
    "UICorner",
    main
).CornerRadius =
    UDim.new(0, 14)

--========================================================--
--                    TITLE                             --
--========================================================--

local title =
    Instance.new("TextLabel")

title.Size =
    UDim2.new(
        1,
        -60,
        0,
        45
    )

title.Position =
    UDim2.new(
        0,
        15,
        0,
        5
    )

title.BackgroundTransparency =
    1

title.Text =
    "RAHERHUB"

title.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

title.TextSize =
    22

title.Font =
    Enum.Font.GothamBold

title.TextXAlignment =
    Enum.TextXAlignment.Left

title.Parent =
    main

--========================================================--
--                    CLOSE                             --
--========================================================--

local closeButton =
    Instance.new("TextButton")

closeButton.Size =
    UDim2.new(
        0,
        38,
        0,
        38
    )

closeButton.Position =
    UDim2.new(
        1,
        -45,
        0,
        8
    )

closeButton.BackgroundColor3 =
    Color3.fromRGB(
        40,
        40,
        52
    )

closeButton.BorderSizePixel =
    0

closeButton.Text =
    "×"

closeButton.TextColor3 =
    Color3.fromRGB(
        255,
        100,
        100
    )

closeButton.TextSize =
    25

closeButton.Font =
    Enum.Font.GothamBold

closeButton.Parent =
    main

Instance.new(
    "UICorner",
    closeButton
).CornerRadius =
    UDim.new(0, 9)

--========================================================--
--                      TABS                            --
--========================================================--

local tabs =
    Instance.new("Frame")

tabs.Size =
    UDim2.new(
        1,
        -20,
        0,
        40
    )

tabs.Position =
    UDim2.new(
        0,
        10,
        0,
        55
    )

tabs.BackgroundTransparency =
    1

tabs.Parent =
    main

local tabLayout =
    Instance.new("UIListLayout")

tabLayout.FillDirection =
    Enum.FillDirection.Horizontal

tabLayout.HorizontalAlignment =
    Enum.HorizontalAlignment.Center

tabLayout.Padding =
    UDim.new(0, 6)

tabLayout.Parent =
    tabs

local function createTab(text)

    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(
            0,
            75,
            0,
            35
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            35,
            35,
            48
        )

    button.BorderSizePixel =
        0

    button.Text =
        text

    button.TextColor3 =
        Color3.fromRGB(
            190,
            190,
            200
        )

    button.TextSize =
        11

    button.Font =
        Enum.Font.GothamBold

    button.Parent =
        tabs

    Instance.new(
        "UICorner",
        button
    ).CornerRadius =
        UDim.new(0, 8)

    return button
end

local mainTab =
    createTab("MAIN")

local feature1Tab =
    createTab("FEATURE 1")

local flyTab =
    createTab("FLY")

local feature2Tab =
    createTab("FEATURE 2")

--========================================================--
--                    PAGES                             --
--========================================================--

local pages = {}

local function createPage()

    local page =
        Instance.new("Frame")

    page.Size =
        UDim2.new(
            1,
            -20,
            1,
            -110
        )

    page.Position =
        UDim2.new(
            0,
            10,
            0,
            100
        )

    page.BackgroundTransparency =
        1

    page.Visible =
        false

    page.Parent =
        main

    table.insert(
        pages,
        page
    )

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

mainPage.Visible =
    true

local function showPage(page)

    for _, p in ipairs(pages) do
        p.Visible =
            false
    end

    page.Visible =
        true
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

--========================================================--
--                DRAG MAIN WINDOW                      --
--========================================================--

local mainDragging =
    false

local mainDragStart
local mainStartPosition

main.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        if input.Position.Y <=
            main.AbsolutePosition.Y + 50 then

            mainDragging =
                true

            mainDragStart =
                input.Position

            mainStartPosition =
                main.Position

        end

    end

end)

UserInputService.InputChanged:Connect(function(input)

    if not mainDragging then
        return
    end

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta =
            input.Position -
            mainDragStart

        main.Position =
            UDim2.new(
                mainStartPosition.X.Scale,
                mainStartPosition.X.Offset + delta.X,
                mainStartPosition.Y.Scale,
                mainStartPosition.Y.Offset + delta.Y
            )

    end

end)

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        mainDragging =
            false

    end

end)

--========================================================--
--                      ESP                             --
--========================================================--

local espEnabled =
    false

local espObjects = {}

local function removeESP(player)

    if espObjects[player] then

        pcall(function()
            espObjects[player]:Destroy()
        end)

        espObjects[player] =
            nil

    end

end

local function createESP(player)

    if player ==
        LocalPlayer then
        return
    end

    if not player.Character then
        return
    end

    removeESP(player)

    local highlight =
        Instance.new("Highlight")

    highlight.Name =
        "RaherESP"

    highlight.Adornee =
        player.Character

    highlight.FillTransparency =
        0.65

    highlight.OutlineTransparency =
        0

    highlight.FillColor =
        Color3.fromRGB(
            255,
            70,
            70
        )

    highlight.OutlineColor =
        Color3.fromRGB(
            255,
            255,
            255
        )

    highlight.Parent =
        player.Character

    espObjects[player] =
        highlight

end

local function updateESP()

    if not espEnabled then

        for player in pairs(espObjects) do
            removeESP(player)
        end

        return
    end

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

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

--========================================================--
--                  MAIN PAGE                           --
--========================================================--

local espButton =
    Instance.new("TextButton")

espButton.Size =
    UDim2.new(
        1,
        0,
        0,
        50
    )

espButton.Position =
    UDim2.new(
        0,
        0,
        0,
        5
    )

espButton.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

espButton.BorderSizePixel =
    0

espButton.Text =
    "ESP: OFF"

espButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

espButton.TextSize =
    15

espButton.Font =
    Enum.Font.GothamBold

espButton.Parent =
    mainPage

Instance.new(
    "UICorner",
    espButton
).CornerRadius =
    UDim.new(0, 9)

espButton.MouseButton1Click:Connect(function()

    espEnabled =
        not espEnabled

    espButton.Text =
        espEnabled
        and "ESP: ON"
        or "ESP: OFF"

    updateESP()

end)

--========================================================--
--                    NOCLIP                            --
--========================================================--

local noclipEnabled =
    false

local noclipButton =
    Instance.new("TextButton")

noclipButton.Size =
    UDim2.new(
        1,
        0,
        0,
        50
    )

noclipButton.Position =
    UDim2.new(
        0,
        0,
        0,
        65
    )

noclipButton.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

noclipButton.BorderSizePixel =
    0

noclipButton.Text =
    "NOCLIP: OFF"

noclipButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

noclipButton.TextSize =
    15

noclipButton.Font =
    Enum.Font.GothamBold

noclipButton.Parent =
    mainPage

Instance.new(
    "UICorner",
    noclipButton
).CornerRadius =
    UDim.new(0, 9)

noclipButton.MouseButton1Click:Connect(function()

    noclipEnabled =
        not noclipEnabled

    noclipButton.Text =
        noclipEnabled
        and "NOCLIP: ON"
        or "NOCLIP: OFF"

end)

RunService.Stepped:Connect(function()

    if not noclipEnabled then
        return
    end

    local character =
        LocalPlayer.Character

    if not character then
        return
    end

    for _, object in ipairs(
        character:GetDescendants()
    ) do

        if object:IsA("BasePart") then
            object.CanCollide =
                false
        end

    end

end)

--========================================================--
--                      FLY                             --
--========================================================--

local flyEnabled =
    false

local flyHolding =
    false

local flySpeed =
    45

local flyButton

local function getRoot()

    local character =
        LocalPlayer.Character

    if not character then
        return nil
    end

    return character:
        FindFirstChild(
            "HumanoidRootPart"
        )

end

local function flyUp()

    local root =
        getRoot()

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

local flyToggle =
    Instance.new("TextButton")

flyToggle.Size =
    UDim2.new(
        1,
        0,
        0,
        50
    )

flyToggle.Position =
    UDim2.new(
        0,
        0,
        0,
        125
    )

flyToggle.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

flyToggle.BorderSizePixel =
    0

flyToggle.Text =
    "FLY JUMP: OFF"

flyToggle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

flyToggle.TextSize =
    15

flyToggle.Font =
    Enum.Font.GothamBold

flyToggle.Parent =
    mainPage

Instance.new(
    "UICorner",
    flyToggle
).CornerRadius =
    UDim.new(0, 9)

flyToggle.MouseButton1Click:Connect(function()

    flyEnabled =
        not flyEnabled

    flyToggle.Text =
        flyEnabled
        and "FLY JUMP: ON"
        or "FLY JUMP: OFF"

end)

--========================================================--
--                  FLY FILES                           --
--========================================================--

local FLY_X_FILE =
    "raherhub_fly_x.txt"

local FLY_Y_FILE =
    "raherhub_fly_y.txt"

local FLY_SIZE_FILE =
    "raherhub_fly_size.txt"

local function readNumber(
    path,
    default
)

    local value =
        readFile(path)

    if not value then
        return default
    end

    return tonumber(value)
        or default
end

local flyX =
    readNumber(
        FLY_X_FILE,
        0.78
    )

local flyY =
    readNumber(
        FLY_Y_FILE,
        0.48
    )

local flySize =
    readNumber(
        FLY_SIZE_FILE,
        60
    )

flySize =
    math.clamp(
        flySize,
        35,
        90
    )

--========================================================--
--                 FLOATING FLY BUTTON                 --
--========================================================--

flyButton =
    Instance.new("TextButton")

flyButton.Size =
    UDim2.new(
        0,
        flySize,
        0,
        flySize
    )

flyButton.Position =
    UDim2.new(
        flyX,
        0,
        flyY,
        0
    )

flyButton.BackgroundColor3 =
    Color3.fromRGB(
        75,
        120,
        255
    )

flyButton.BorderSizePixel =
    0

flyButton.Text =
    "↑"

flyButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

flyButton.TextSize =
    28

flyButton.Font =
    Enum.Font.GothamBold

flyButton.Parent =
    gui

Instance.new(
    "UICorner",
    flyButton
).CornerRadius =
    UDim.new(1, 0)

--========================================================--
--                    FLY HOLD                         --
--========================================================--

flyButton.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyHolding =
            true

    end

end)

flyButton.InputEnded:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyHolding =
            false

    end

end)

RunService.Heartbeat:Connect(function()

    if flyEnabled
        and flyHolding then

        flyUp()

    end

end)

--========================================================--
--                FLY BUTTON DRAG                      --
--========================================================--

local moveFlyButton =
    false

local flyDragging =
    false

local flyMoved =
    false

local flyDragStart
local flyStartPosition

local function saveFlyPosition()

    writeFile(
        FLY_X_FILE,
        flyButton.Position.X.Scale
    )

    writeFile(
        FLY_Y_FILE,
        flyButton.Position.Y.Scale
    )

end

flyButton.InputBegan:Connect(function(input)

    if not moveFlyButton then
        return
    end

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyDragging =
            true

        flyMoved =
            false

        flyDragStart =
            input.Position

        flyStartPosition =
            flyButton.Position

    end

end)

UserInputService.InputChanged:Connect(function(input)

    if not flyDragging then
        return
    end

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta =
            input.Position -
            flyDragStart

        if math.abs(delta.X) > 5
            or math.abs(delta.Y) > 5 then

            flyMoved =
                true

        end

        if flyMoved then

            flyButton.Position =
                UDim2.new(
                    flyStartPosition.X.Scale,
                    flyStartPosition.X.Offset + delta.X,
                    flyStartPosition.Y.Scale,
                    flyStartPosition.Y.Offset + delta.Y
                )

        end

    end

end)

UserInputService.InputEnded:Connect(function(input)

    if not flyDragging then
        return
    end

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        flyDragging =
            false

        if flyMoved then
            saveFlyPosition()
        end

        flyMoved =
            false

    end

end)

--========================================================--
--                 FLY SETTINGS                         --
--========================================================--

local moveFlyToggle =
    Instance.new("TextButton")

moveFlyToggle.Size =
    UDim2.new(
        1,
        0,
        0,
        50
    )

moveFlyToggle.Position =
    UDim2.new(
        0,
        0,
        0,
        5
    )

moveFlyToggle.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

moveFlyToggle.BorderSizePixel =
    0

moveFlyToggle.Text =
    "MOVE FLY BUTTON: OFF"

moveFlyToggle.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

moveFlyToggle.TextSize =
    14

moveFlyToggle.Font =
    Enum.Font.GothamBold

moveFlyToggle.Parent =
    flyPage

Instance.new(
    "UICorner",
    moveFlyToggle
).CornerRadius =
    UDim.new(0, 9)

moveFlyToggle.MouseButton1Click:Connect(function()

    moveFlyButton =
        not moveFlyButton

    moveFlyToggle.Text =
        moveFlyButton
        and "MOVE FLY BUTTON: ON"
        or "MOVE FLY BUTTON: OFF"

end)

--========================================================--
--                  FLY SIZE                           --
--========================================================--

local flySizeLabel =
    Instance.new("TextLabel")

flySizeLabel.Size =
    UDim2.new(
        1,
        0,
        0,
        35
    )

flySizeLabel.Position =
    UDim2.new(
        0,
        0,
        0,
        70
    )

flySizeLabel.BackgroundTransparency =
    1

flySizeLabel.Text =
    "FLY BUTTON SIZE: "
    .. tostring(flySize)

flySizeLabel.TextColor3 =
    Color3.fromRGB(
        220,
        220,
        230
    )

flySizeLabel.TextSize =
    14

flySizeLabel.Font =
    Enum.Font.GothamBold

flySizeLabel.Parent =
    flyPage

local minusButton =
    Instance.new("TextButton")

minusButton.Size =
    UDim2.new(
        0.48,
        -4,
        0,
        45
    )

minusButton.Position =
    UDim2.new(
        0,
        0,
        0,
        110
    )

minusButton.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

minusButton.BorderSizePixel =
    0

minusButton.Text =
    "−"

minusButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

minusButton.TextSize =
    22

minusButton.Font =
    Enum.Font.GothamBold

minusButton.Parent =
    flyPage

Instance.new(
    "UICorner",
    minusButton
).CornerRadius =
    UDim.new(0, 9)

local plusButton =
    Instance.new("TextButton")

plusButton.Size =
    UDim2.new(
        0.48,
        -4,
        0,
        45
    )

plusButton.Position =
    UDim2.new(
        0.52,
        0,
        0,
        110
    )

plusButton.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

plusButton.BorderSizePixel =
    0

plusButton.Text =
    "+"

plusButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

plusButton.TextSize =
    22

plusButton.Font =
    Enum.Font.GothamBold

plusButton.Parent =
    flyPage

Instance.new(
    "UICorner",
    plusButton
).CornerRadius =
    UDim.new(0, 9)

local function updateFlySize()

    flyButton.Size =
        UDim2.new(
            0,
            flySize,
            0,
            flySize
        )

    flySizeLabel.Text =
        "FLY BUTTON SIZE: "
        .. tostring(flySize)

    writeFile(
        FLY_SIZE_FILE,
        flySize
    )

end

minusButton.MouseButton1Click:Connect(function()

    flySize =
        math.max(
            35,
            flySize - 5
        )

    updateFlySize()

end)

plusButton.MouseButton1Click:Connect(function()

    flySize =
        math.min(
            90,
            flySize + 5
        )

    updateFlySize()

end)

--========================================================--
--              RESET FLY POSITION                     --
--========================================================--

local resetFlyPosition =
    Instance.new("TextButton")

resetFlyPosition.Size =
    UDim2.new(
        1,
        0,
        0,
        45
    )

resetFlyPosition.Position =
    UDim2.new(
        0,
        0,
        0,
        170
    )

resetFlyPosition.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        48
    )

resetFlyPosition.BorderSizePixel =
    0

resetFlyPosition.Text =
    "RESET FLY POSITION"

resetFlyPosition.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

resetFlyPosition.TextSize =
    14

resetFlyPosition.Font =
    Enum.Font.GothamBold

resetFlyPosition.Parent =
    flyPage

Instance.new(
    "UICorner",
    resetFlyPosition
).CornerRadius =
    UDim.new(0, 9)

resetFlyPosition.MouseButton1Click:Connect(function()

    flyButton.Position =
        UDim2.new(
            0.78,
            0,
            0.48,
            0
        )

    writeFile(
        FLY_X_FILE,
        0.78
    )

    writeFile(
        FLY_Y_FILE,
        0.48
    )

end)

--========================================================--
--                  FEATURE 1                         --
--========================================================--

local feature1Text =
    Instance.new("TextLabel")

feature1Text.Size =
    UDim2.new(
        1,
        0,
        0,
        100
    )

feature1Text.Position =
    UDim2.new(
        0,
        0,
        0,
        10
    )

feature1Text.BackgroundTransparency =
    1

feature1Text.Text =
    "FEATURE 1\n\nReserved for testing."

feature1Text.TextColor3 =
    Color3.fromRGB(
        190,
        190,
        200
    )

feature1Text.TextSize =
    14

feature1Text.Font =
    Enum.Font.Gotham

feature1Text.TextWrapped =
    true

feature1Text.Parent =
    feature1Page

--========================================================--
--                  FEATURE 2                         --
--========================================================--

local feature2Text =
    Instance.new("TextLabel")

feature2Text.Size =
    UDim2.new(
        1,
        0,
        0,
        100
    )

feature2Text.Position =
    UDim2.new(
        0,
        0,
        0,
        10
    )

feature2Text.BackgroundTransparency =
    1

feature2Text.Text =
    "FEATURE 2\n\nReserved for testing."

feature2Text.TextColor3 =
    Color3.fromRGB(
        190,
        190,
        200
    )

feature2Text.TextSize =
    14

feature2Text.Font =
    Enum.Font.Gotham

feature2Text.TextWrapped =
    true

feature2Text.Parent =
    feature2Page

--========================================================--
--                  OPEN BUTTON                        --
--========================================================--

local openButton =
    Instance.new("TextButton")

openButton.Size =
    UDim2.new(
        0,
        55,
        0,
        55
    )

openButton.Position =
    UDim2.new(
        0.05,
        0,
        0.45,
        0
    )

openButton.BackgroundColor3 =
    Color3.fromRGB(
        25,
        25,
        35
    )

openButton.BorderSizePixel =
    0

openButton.Text =
    "≡"

openButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

openButton.TextSize =
    28

openButton.Font =
    Enum.Font.GothamBold

openButton.Visible =
    false

openButton.Parent =
    gui

Instance.new(
    "UICorner",
    openButton
).CornerRadius =
    UDim.new(1, 0)

--========================================================--
--                  CLOSE MENU                         --
--========================================================--

closeButton.MouseButton1Click:Connect(function()

    main.Visible =
        false

    openButton.Visible =
        true

end)

--========================================================--
--             OPEN BUTTON DRAG FIX                    --
--========================================================--

local openDragging =
    false

local openMoved =
    false

local openDragStart
local openStartPosition

openButton.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        openDragging =
            true

        openMoved =
            false

        openDragStart =
            input.Position

        openStartPosition =
            openButton.Position

    end

end)

UserInputService.InputChanged:Connect(function(input)

    if not openDragging then
        return
    end

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseMovement then

        local delta =
            input.Position -
            openDragStart

        if math.abs(delta.X) > 8
            or math.abs(delta.Y) > 8 then

            openMoved =
                true

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

    if input.UserInputType ==
        Enum.UserInputType.Touch
        or
        input.UserInputType ==
        Enum.UserInputType.MouseButton1 then

        openDragging =
            false

        if not openMoved then

            main.Visible =
                true

            openButton.Visible =
                false

        end

        openMoved =
            false

    end

end)

--========================================================--
--                 RESPAWN                           --
--========================================================--

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)

    if espEnabled then
        updateESP()
    end

end)

--========================================================--
--              PERIODIC LICENSE CHECK                 --
--========================================================--

task.spawn(function()

    while task.wait(180) do

        if session == "" then
            continue
        end

        local ok, data =
            checkSession()

        if not ok then

            warn(
                "RaherHUB session ended: "
                .. tostring(data)
            )

            -- Останавливаем защищённые функции
            espEnabled =
                false

            noclipEnabled =
                false

            flyEnabled =
                false

            flyHolding =
                false

            updateESP()

            if gui then
                gui.Enabled =
                    false
            end

            break

        end

    end

end)

--========================================================--
--                       DONE                           --
--========================================================--

print(
    "RaherHUB 1.0 loaded."
)