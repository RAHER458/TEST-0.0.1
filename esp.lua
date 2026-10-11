--[[
    RH-HUB
    Standalone Roblox Multi-Tool Hub
    Version: 0.0.3-alpha
    Platform: Roblox / Delta Executor / iOS
]]

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    VERSION     = "0.0.3-alpha",
    NAME        = "RH-HUB",
    API_BASE    = "https://raherauth.raher458.workers.dev",
    TOKEN_FILE  = "RH_HUB_TOKEN.dat",
    DEVICE_FILE = "RH_HUB_DEVICE.dat",
    CONFIG_FILE = "RH_HUB_CONFIG.dat",
    TG_LINK     = "https://t.me/generalvaneska2024",
    WINDOW_W    = 340,
    WINDOW_H    = 440,
    RETRY_MAX   = 3,
    RETRY_DELAY = 1.5,
}

local C = {
    bg      = Color3.fromRGB(11, 12, 18),
    surface = Color3.fromRGB(20, 23, 32),
    surface2= Color3.fromRGB(28, 32, 45),
    surface3= Color3.fromRGB(36, 41, 55),
    button  = Color3.fromRGB(36, 41, 55),
    input   = Color3.fromRGB(24, 27, 36),
    border  = Color3.fromRGB(58, 64, 88),
    text    = Color3.fromRGB(242, 244, 255),
    muted   = Color3.fromRGB(150, 158, 180),
    accent  = Color3.fromRGB(105, 115, 255),
    pink    = Color3.fromRGB(255, 80, 190),
    green   = Color3.fromRGB(60, 210, 140),
    red     = Color3.fromRGB(230, 80, 95),
    yellow  = Color3.fromRGB(255, 195, 80),
}

pcall(function()
    local core = game:GetService("CoreGui")
    for _, name in ipairs({"RH_HUB_GUI", "RH_HUB_AUTH_GUI", "RH_HUB_OVERLAY", "RH_HUB_CIRCLE", "RH_HUB_RUSH"}) do
        local old = core:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, name in ipairs({"RH_HUB_GUI", "RH_HUB_AUTH_GUI", "RH_HUB_OVERLAY", "RH_HUB_CIRCLE", "RH_HUB_RUSH"}) do
            local old = playerGui:FindFirstChild(name)
            if old then old:Destroy() end
        end
    end
end)

local STATE = {
    authed   = false,
    token    = nil,
    deviceId = nil,
    busy     = false,
    mode     = "window",
}

local FarmApi = nil

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or C.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.2,
    }, parent)
end

local function safeParent(guiObj)
    local ok = pcall(function() guiObj.Parent = game:GetService("CoreGui") end)
    if not ok or not guiObj.Parent then
        guiObj.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function hasFileAPI()
    return type(readfile) == "function"
       and type(writefile) == "function"
       and type(isfile) == "function"
end

local savedCfg = {
    rushBtnPos = { x = -70, y = -140 },
}

local function loadConfig()
    if not hasFileAPI() then return end
    local ok, result = pcall(function()
        if isfile(CONFIG.CONFIG_FILE) then
            local raw = readfile(CONFIG.CONFIG_FILE)
            if type(raw) == "string" and raw ~= "" then
                local dec = HttpService:JSONDecode(raw)
                if type(dec) == "table" then return dec end
            end
        end
        return nil
    end)
    if ok and type(result) == "table" then
        for k, v in pairs(result) do savedCfg[k] = v end
    end
end

local function saveConfig()
    if not hasFileAPI() then return end
    pcall(function()
        local raw = HttpService:JSONEncode(savedCfg)
        writefile(CONFIG.CONFIG_FILE, raw)
    end)
end

loadConfig()

-- ============ DEVICE ID ============
local function generateDeviceId()
    return "RH-" .. HttpService:GenerateGUID(false)
end

local function loadDeviceId()
    if hasFileAPI() then
        local ok, result = pcall(function()
            if isfile(CONFIG.DEVICE_FILE) then
                local val = readfile(CONFIG.DEVICE_FILE)
                if type(val) == "string" and #val >= 16 then
                    return tostring(val):gsub("%s+", "")
                end
            end
            local val = generateDeviceId()
            writefile(CONFIG.DEVICE_FILE, val)
            return val
        end)
        if ok and type(result) == "string" then return result end
    end
    return generateDeviceId()
end

STATE.deviceId = loadDeviceId()

local function saveToken(token)
    if hasFileAPI() then
        pcall(writefile, CONFIG.TOKEN_FILE, tostring(token))
    end
end

local function loadToken()
    if not hasFileAPI() then return nil end
    local ok, result = pcall(function()
        if isfile(CONFIG.TOKEN_FILE) then
            local val = readfile(CONFIG.TOKEN_FILE)
            if type(val) == "string" and #val >= 16 then
                return tostring(val):gsub("%s+", "")
            end
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local function clearToken()
    if hasFileAPI() and type(delfile) == "function" then
        pcall(function()
            if isfile(CONFIG.TOKEN_FILE) then
                delfile(CONFIG.TOKEN_FILE)
            end
        end)
    end
end

local function getRequestFn()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    return nil
end

local function api(path, body)
    local req = getRequestFn()
    if not req then return nil, "Executor не поддерживает HTTP-запросы" end

    local payload
    local encOK, encErr = pcall(function()
        payload = HttpService:JSONEncode(body or {})
    end)
    if not encOK then return nil, "Ошибка JSON: " .. tostring(encErr) end

    local response = nil
    local requestDone = false

    task.spawn(function()
        local callOK, res = pcall(function()
            return req({
                Url = CONFIG.API_BASE .. path,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json",
                },
                Body = payload,
            })
        end)

        if callOK then
            response = res
        else
            response = { __error = tostring(res) }
        end
        requestDone = true
    end)

    local startTime = os.clock()
    while not requestDone and os.clock() - startTime < 15 do
        task.wait(0.1)
    end

    if not requestDone then
        return nil, "Таймаут запроса (сервер не отвечает)"
    end

    if not response or type(response) ~= "table" then
        return nil, "Не удалось выполнить запрос"
    end

    if response.__error then
        return nil, response.__error
    end

    local status = tonumber(response.StatusCode or response.Status or 0) or 0
    local raw = response.Body or response.body or ""

    local decOK, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if status < 200 or status >= 300 then
        local message
        if decOK and type(decoded) == "table" then
            message = decoded.error or decoded.message
        end
        if not message and raw ~= "" then
            message = tostring(raw):sub(1, 120)
        end
        return nil, tostring(message or ("HTTP " .. status))
    end

    if not decOK or type(decoded) ~= "table" then
        return nil, "Некорректный ответ"
    end

    return decoded
end

local function apiWithRetry(path, body, maxAttempts, delay)
    maxAttempts = maxAttempts or CONFIG.RETRY_MAX
    delay = delay or CONFIG.RETRY_DELAY

    local lastErr = nil

    for attempt = 1, maxAttempts do
        local result, err = api(path, body)
        if result then return result, nil, attempt end

        lastErr = err
        local errText = tostring(err or ""):lower()

        if errText:find("таймаут") or errText:find("timeout") then
            if attempt < maxAttempts then
                task.wait(delay)
            end
        else
            return nil, err, attempt
        end
    end

    return nil, lastErr, maxAttempts
end

local function makeToast(parentFrame)
    local container = create("Frame", {
        Position = UDim2.new(0, 0, 1, -180),
        Size = UDim2.new(1, 0, 0, 170),
        BackgroundTransparency = 1,
        ZIndex = 200,
    }, parentFrame)

    create("UIListLayout", {
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, container)

    create("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
    }, container)

    local n = 0
    return function(text, kind)
        n = n + 1
        local col = kind == "ok" and C.green
                or kind == "err" and C.red
                or kind == "warn" and C.yellow
                or C.accent

        local t = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundColor3 = C.surface2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = n,
        }, container)
        corner(t, 10)
        create("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = col,
            BorderSizePixel = 0,
        }, t)
        create("TextLabel", {
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = tostring(text),
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, t)

        TweenService:Create(t, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 38),
        }):Play()

        task.delay(3.2, function()
            if t.Parent then
                TweenService:Create(t, TweenInfo.new(0.2), {
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                }):Play()
                task.wait(0.2)
                t:Destroy()
            end
        end)
    end
end

local authGui = create("ScreenGui", {
    Name = "RH_HUB_AUTH_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 99999,
})
safeParent(authGui)

local authBg = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    BackgroundTransparency = 0.15,
}, authGui)

local authMain = create("Frame", {
    Name = "AuthWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(320, 400),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, authGui)
corner(authMain, 18)
stroke(authMain, C.border, 1, 0.15)

local function authFit()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local w = math.min(320, vp.X - 24)
    local h = math.min(400, vp.Y - 60)
    authMain.Size = UDim2.fromOffset(w, h)
end
authFit()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(authFit)
end

local authHeader = create("Frame", {
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, authMain)
corner(authHeader, 18)
create("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, authHeader)

local authTitle = create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 10),
    Size = UDim2.new(1, -40, 0, 36),
    BackgroundTransparency = 1,
    Text = "RH-HUB",
    TextColor3 = C.pink,
    TextSize = 28,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authHeader)

create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 46),
    Size = UDim2.new(1, -40, 0, 14),
    BackgroundTransparency = 1,
    Text = "ВВЕДИТЕ КЛЮЧ ДОСТУПА",
    TextColor3 = C.muted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authHeader)

task.spawn(function()
    local hue = 0
    while authGui.Parent do
        hue = (hue + 0.008) % 1
        if authTitle.Parent then
            authTitle.TextColor3 = Color3.fromHSV(hue, 0.7, 1)
        end
        task.wait(0.05)
    end
end)

create("TextLabel", {
    Position = UDim2.new(0.5, -12, 0, 78),
    Size = UDim2.fromOffset(24, 24),
    BackgroundTransparency = 1,
    Text = "🔒",
    TextColor3 = C.text,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authMain)

create("TextLabel", {
    Position = UDim2.new(0, 22, 0, 106),
    Size = UDim2.new(1, -44, 0, 34),
    BackgroundTransparency = 1,
    Text = "Получите ключ у администратора.\nОдин ключ = одно устройство.",
    TextColor3 = C.muted,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Top,
}, authMain)

create("TextLabel", {
    Position = UDim2.new(0, 22, 0, 144),
    Size = UDim2.new(1, -44, 0, 14),
    BackgroundTransparency = 1,
    Text = "КЛЮЧ ДОСТУПА",
    TextColor3 = C.muted,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authMain)

local authInputWrap = create("Frame", {
    Position = UDim2.new(0, 22, 0, 162),
    Size = UDim2.new(1, -44, 0, 42),
    BackgroundColor3 = C.input,
    BorderSizePixel = 0,
}, authMain)
corner(authInputWrap, 11)
local authInputStroke = stroke(authInputWrap, C.border, 1.5, 0.1)

local authKeyBox = create("TextBox", {
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -52, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "RAH-XXXXXXXXXXXXXXXX",
    PlaceholderColor3 = C.muted,
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.Code,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authInputWrap)

local authPasteBtn = create("TextButton", {
    Position = UDim2.new(1, -40, 0, 5),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "📋",
    TextColor3 = C.text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, authInputWrap)
corner(authPasteBtn, 9)

authKeyBox.Focused:Connect(function()
    TweenService:Create(authInputStroke, TweenInfo.new(0.15), {
        Color = C.accent, Transparency = 0,
    }):Play()
end)
authKeyBox.FocusLost:Connect(function()
    TweenService:Create(authInputStroke, TweenInfo.new(0.15), {
        Color = C.border, Transparency = 0.1,
    }):Play()
end)

local authActBtn = create("TextButton", {
    Position = UDim2.new(0, 22, 0, 214),
    Size = UDim2.new(1, -44, 0, 44),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
    Text = "✨  АКТИВИРОВАТЬ",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, authMain)
corner(authActBtn, 12)

local authTgBtn = create("TextButton", {
    Position = UDim2.new(0, 22, 0, 266),
    Size = UDim2.new(1, -44, 0, 40),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "📱  ПОЛУЧИТЬ КЛЮЧ",
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, authMain)
corner(authTgBtn, 11)
stroke(authTgBtn, C.pink, 1, 0.3)

local authStatus = create("TextLabel", {
    Position = UDim2.new(0, 22, 1, -36),
    Size = UDim2.new(1, -44, 0, 28),
    BackgroundTransparency = 1,
    Text = "Ожидание ввода...",
    TextColor3 = C.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
}, authMain)

local function setStatus(text, kind)
    authStatus.Text = tostring(text)
    if kind == "ok" then
        authStatus.TextColor3 = C.green
    elseif kind == "err" then
        authStatus.TextColor3 = C.red
    elseif kind == "warn" then
        authStatus.TextColor3 = C.yellow
    else
        authStatus.TextColor3 = C.muted
    end
end

local authToast = makeToast(authGui)
_G.RH_HUB_TOAST = function(text, kind) authToast(text, kind) end

local function setBusy(busy)
    STATE.busy = busy
    if busy then
        authActBtn.Text = "⏳  ПРОВЕРКА..."
        authActBtn.BackgroundColor3 = C.surface2
    else
        authActBtn.Text = "✨  АКТИВИРОВАТЬ"
        authActBtn.BackgroundColor3 = C.accent
    end
end

authPasteBtn.MouseButton1Click:Connect(function()
    if STATE.busy then return end

    local value = nil
    if type(getclipboard) == "function" then
        local ok, v = pcall(getclipboard)
        if ok and type(v) == "string" and v ~= "" then value = v end
    end
    if not value and type(getClipboard) == "function" then
        local ok, v = pcall(getClipboard)
        if ok and type(v) == "string" and v ~= "" then value = v end
    end

    if value and value ~= "" then
        value = value:gsub("%s+", "")
        authKeyBox.Text = value
        setStatus("Ключ вставлен", "ok")
        authToast("Ключ вставлен", "ok")
    else
        authToast("Буфер обмена пуст", "warn")
        setStatus("Не удалось прочитать буфер", "warn")
    end
end)

local tgCooldown = false

authTgBtn.MouseButton1Click:Connect(function()
    if tgCooldown then return end
    tgCooldown = true

    local copied = false
    if type(setclipboard) == "function" then
        copied = pcall(setclipboard, CONFIG.TG_LINK)
    elseif type(toclipboard) == "function" then
        copied = pcall(toclipboard, CONFIG.TG_LINK)
    end

    if copied then
        authToast("Ссылка скопирована! Вставьте в браузер", "ok")
        setStatus("Ссылка в буфере", "ok")
    else
        authToast("Скопируйте вручную", "warn")
        setStatus("Ссылка: " .. CONFIG.TG_LINK, "warn")
    end

    task.delay(2.5, function()
        tgCooldown = false
    end)
end)

local onAuthSuccess

local function activateKey(rawKey)
    local key = tostring(rawKey or ""):gsub("%s+", "")

    if key == "" then
        setStatus("Введите ключ доступа", "warn")
        authToast("Ключ пустой", "warn")
        return
    end

    if STATE.busy then return end
    setBusy(true)
    setStatus("Активация ключа...", nil)

    task.spawn(function()
        if type(STATE.deviceId) ~= "string" or STATE.deviceId == "" then
            STATE.deviceId = generateDeviceId()
        end

        local body = { key = key, install_hash = STATE.deviceId }

        local result, err, attempts = apiWithRetry("/activate", body, CONFIG.RETRY_MAX, CONFIG.RETRY_DELAY)

        if attempts > 1 and result then
            setStatus("Попытка " .. attempts .. " успешна", "ok")
        end

        if not result then
            setBusy(false)
            local msg = tostring(err or "неизвестная ошибка")
            local low = msg:lower()

            if low:find("invalid license") then
                setStatus("❌ Неверный ключ", "err")
                authToast("Неверный ключ", "err")
            elseif low:find("bound to another") then
                setStatus("❌ Ключ привязан к другому устройству", "err")
                authToast("Ключ занят другим устройством", "err")
            elseif low:find("expired") then
                setStatus("❌ Ключ истёк", "err")
                authToast("Ключ истёк", "err")
            elseif low:find("таймаут") or low:find("timeout") then
                setStatus("❌ Сервер не отвечает. Попробуй позже.", "err")
                authToast("Сервер не отвечает", "err")
            else
                setStatus("❌ " .. msg, "err")
                authToast(msg, "err")
            end
            return
        end

        if type(result.token) ~= "string" or result.token == "" then
            setBusy(false)
            setStatus("❌ Сервер не выдал токен", "err")
            authToast("Пустой ответ", "err")
            return
        end

        setBusy(false)
        onAuthSuccess(result.token)
    end)
end

local function verifySavedToken(token)
    if type(token) ~= "string" or token == "" then
        return false, "no_token"
    end

    local result, err = api("/verify", { token = token })

    if not result then
        local errText = tostring(err or ""):lower()
        if errText:find("expired") then
            clearToken()
            return false, "expired"
        end
        return false, "request_failed"
    end

    if result.valid ~= true then
        return false, "invalid"
    end

    return true, "ok"
end

authActBtn.MouseButton1Click:Connect(function()
    if STATE.busy then return end
    activateKey(authKeyBox.Text)
end)

authKeyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and not STATE.busy then
        activateKey(authKeyBox.Text)
    end
end)

task.spawn(function()
    task.wait(0.3)

    local saved = loadToken()
    if not saved then
        setStatus("Введите ключ доступа", nil)
        return
    end

    setStatus("Проверка сессии...", nil)
    setBusy(true)

    local valid, reason = verifySavedToken(saved)

    if valid then
        setBusy(false)
        onAuthSuccess(saved)
    else
        setBusy(false)
        if reason == "expired" then
            setStatus("⏱ Ключ истёк", "warn")
            authToast("Нужен новый ключ", "warn")
        elseif reason == "invalid" then
            clearToken()
            setStatus("Сессия недействительна", "warn")
        else
            setStatus("Введите ключ доступа", nil)
        end
    end
end)
-- ============ ГЛОБАЛЬНЫЕ ЭКСПОРТЫ ============
_G.RH_HUB_IS_WALKSPEED_ON = function() return false end
_G.RH_HUB_IS_RUSH_ON = function() return false end
_G.RH_HUB_RUSH_ACTIVE = function() return false end
_G.RH_HUB_SET_RUSH_VISIBLE = function(v) end
_G.RH_HUB_SET_RUSH_SPEED = function(v) end
_G.RH_HUB_SET_RUSH_HEIGHT = function(v) end
_G.RH_HUB_ENTER_RUSH_EDIT = function(v) end
_G.RH_HUB_RUSH_SPEED = 200
_G.RH_HUB_RUSH_HEIGHT = 5

-- ============ MAIN GUI ============
local mainGui = create("ScreenGui", {
    Name = "RH_HUB_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    Enabled = false,
})
safeParent(mainGui)

local WIN_W = CONFIG.WINDOW_W
local WIN_H = CONFIG.WINDOW_H

local main = create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, mainGui)
corner(main, 16)
stroke(main, C.border, 1, 0.15)

local function fitMain()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local w = math.min(WIN_W, vp.X - 20)
    local h = math.min(WIN_H, vp.Y - 60)
    main.Size = UDim2.fromOffset(w, h)
end
fitMain()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMain)
end

-- ============ HEADER ============
local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
}, main)
corner(header, 16)
create("Frame", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 1, -18),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
}, header)

local titleLabel = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 6),
    Size = UDim2.new(1, -180, 0, 24),
    BackgroundTransparency = 1,
    Text = "RH-HUB",
    TextColor3 = C.pink,
    TextSize = 18,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

create("TextLabel", {
    Position = UDim2.new(0, 13, 0, 28),
    Size = UDim2.new(1, -180, 0, 12),
    BackgroundTransparency = 1,
    Text = "MULTI-TOOL  •  v" .. CONFIG.VERSION,
    TextColor3 = C.muted,
    TextSize = 8,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local timerLabel = create("TextLabel", {
    Position = UDim2.new(1, -170, 0, 8),
    Size = UDim2.new(0, 90, 0, 30),
    BackgroundTransparency = 1,
    Text = "⏱ --",
    TextColor3 = C.muted,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextYAlignment = Enum.TextYAlignment.Center,
}, header)

task.spawn(function()
    local hue = 0
    while mainGui.Parent do
        hue = (hue + 0.008) % 1
        if titleLabel.Parent then
            titleLabel.TextColor3 = Color3.fromHSV(hue, 0.65, 1)
        end
        task.wait(0.05)
    end
end)

local minimizeBtn = create("TextButton", {
    Position = UDim2.new(1, -76, 0, 8),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "—",
    TextColor3 = C.text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, header)
corner(minimizeBtn, 8)

local circleBtn = create("TextButton", {
    Position = UDim2.new(1, -42, 0, 8),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "⌄",
    TextColor3 = C.text,
    TextSize = 18,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, header)
corner(circleBtn, 8)

-- ============ NAV TABS ============
local navBar = create("Frame", {
    Position = UDim2.new(0, 8, 0, 52),
    Size = UDim2.new(1, -16, 0, 34),
    BackgroundTransparency = 1,
}, main)

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 3),
}, navBar)

local content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 8, 0, 92),
    Size = UDim2.new(1, -16, 1, -100),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, main)

local pages = {}
local navButtons = {}

local TABS = {
    {id = "HOME",     name = "HOME"},
    {id = "GAMES",    name = "GAMES"},
    {id = "MOVE",     name = "MOVE"},
    {id = "VISUAL",   name = "VISUAL"},
    {id = "TELEPORT", name = "TP"},
    {id = "SETTINGS", name = "SET"},
    {id = "ABOUT",    name = "INFO"},
}

local function createPage(name)
    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 4),
    }, page)

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, page)

    pages[name] = page
    return page
end

local activeTab = "HOME"

local function selectTab(name)
    if not pages[name] then return end
    activeTab = name

    for tabName, page in pairs(pages) do
        page.Visible = tabName == name
    end

    for tabId, btn in pairs(navButtons) do
        local sel = tabId == name
        btn.BackgroundColor3 = sel and C.accent or C.button
        btn.TextColor3 = sel and C.text or C.muted
    end
end

local function makeNavButton(id, label, order)
    local b = create("TextButton", {
        Name = id,
        Size = UDim2.new(1/#TABS, -3, 1, 0),
        BackgroundColor3 = C.button,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = C.muted,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        LayoutOrder = order,
    }, navBar)
    corner(b, 8)

    b.MouseButton1Click:Connect(function()
        selectTab(id)
    end)

    navButtons[id] = b
    return b
end

for i, tab in ipairs(TABS) do
    makeNavButton(tab.id, tab.name, i)
end

local homePage     = createPage("HOME")
local gamesPage    = createPage("GAMES")
local movePage     = createPage("MOVE")
local visualPage   = createPage("VISUAL")
local tpPage       = createPage("TELEPORT")
local settingsPage = createPage("SETTINGS")
local aboutPage    = createPage("ABOUT")

-- ============ UI COMPONENTS ============
local function section(parent, text)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function infoCard(parent, heading, body)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,
    }, parent)
    corner(frame, 10)

    create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 8),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = heading,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 26),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundTransparency = 1,
        Text = body,
        TextColor3 = C.muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, frame)

    return frame
end

local function soonCard(parent)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 120),
        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,
    }, parent)
    corner(frame, 12)

    create("TextLabel", {
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = "🚧",
        TextColor3 = C.text,
        TextSize = 32,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, frame)

    create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 68),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        Text = "Скоро появится",
        TextColor3 = C.text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, frame)

    create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 90),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = "Функционал в разработке",
        TextColor3 = C.muted,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, frame)

    return frame
end

-- ============ GAMES: КОНТЕЙНЕРЫ ============
-- gamesMenuContainer — список игр
-- gamesFarmContainer — UI автофарма (заполняется в initFarm)
local gamesMenuContainer = create("Frame", {
    Name = "GamesMenu",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = true,
}, gamesPage)
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, gamesMenuContainer)

local gamesFarmContainer = create("ScrollingFrame", {
    Name = "GamesFarm",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false,
    ClipsDescendants = true,
}, gamesPage)
create("UIPadding", {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 2),
    PaddingRight = UDim.new(0, 4),
}, gamesFarmContainer)
create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, gamesFarmContainer)

-- ============ HOME ============
section(homePage, "ГЛАВНАЯ")
infoCard(homePage, "RH-HUB  •  МУЛЬТИ-ИНСТРУМЕНТ", "Добро пожаловать. Используй вкладки для перехода к функциям.")
infoCard(homePage, "АВТОРИЗАЦИЯ ПРОЙДЕНА", "Твой токен сохранён. При следующем запуске вход автоматический.")
infoCard(homePage, "ТАЙМЕР КЛЮЧА", "Справа вверху видно оставшееся время действия ключа.")
infoCard(homePage, "ИГРЫ", "Вкладка GAMES — список игр с автофармом. Сейчас доступен Steal an Egg.")

-- ============ GAMES: МЕНЮ ============
section(gamesMenuContainer, "ДОСТУПНЫЕ ИГРЫ")

local function makeGameCard(parent, title, subtitle, onClick)
    local card = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, parent)
    corner(card, 12)
    stroke(card, C.accent, 1, 0.5)

    create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -28, 0, 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 32),
        Size = UDim2.new(1, -28, 0, 16),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = C.muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    create("TextLabel", {
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 30, 1, 0),
        BackgroundTransparency = 1,
        Text = "›",
        TextColor3 = C.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, card)

    card.MouseButton1Click:Connect(function()
        local ok, err = pcall(onClick)
        if not ok then warn("[RH-HUB] Game click error: " .. tostring(err)) end
    end)

    return card
end

local function showGamesMenu()
    gamesMenuContainer.Visible = true
    gamesFarmContainer.Visible = false
end

local function showGamesFarm()
    gamesMenuContainer.Visible = false
    gamesFarmContainer.Visible = true
end

makeGameCard(gamesMenuContainer, "🥚  Steal an Egg", "Автофарм яиц — 11 зон, авто-возврат, дорожка", function()
    showGamesFarm()
end)

_G.RH_HUB_SHOW_GAMES_MENU = showGamesMenu

-- ============ MOVE ============
section(movePage, "ДВИЖЕНИЕ И СКОРОСТЬ")

local walkSpeedEnabled = false
local stealthEnabled = false
local walkSpeedValue = 100
local rushModeEnabled = false
local rushSpeedValue = 200
local rushHeightValue = 5

_G.RH_HUB_IS_WALKSPEED_ON = function() return walkSpeedEnabled end
_G.RH_HUB_IS_RUSH_ON = function() return rushModeEnabled end
_G.RH_HUB_RUSH_SPEED = rushSpeedValue
_G.RH_HUB_RUSH_HEIGHT = rushHeightValue

local currentHumanoid = nil
local currentHRP = nil
local currentLinearVelocity = nil
local currentBodyVelocity = nil
local currentAttachment = nil

-- ===== UI: TOGGLE WALKSPEED =====
local walkSpeedToggleWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
}, movePage)
corner(walkSpeedToggleWrap, 10)

create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -80, 1, 0),
    BackgroundTransparency = 1,
    Text = "Ускорение ходьбы",
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, walkSpeedToggleWrap)

local walkSpeedToggleTrack = create("Frame", {
    Position = UDim2.new(1, -62, 0.5, -12),
    Size = UDim2.new(0, 46, 0, 24),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
}, walkSpeedToggleWrap)
corner(walkSpeedToggleTrack, 12)

local walkSpeedToggleKnob = create("Frame", {
    Position = UDim2.new(0, 2, 0, 2),
    Size = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, walkSpeedToggleTrack)
corner(walkSpeedToggleKnob, 10)

local walkSpeedToggleBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
}, walkSpeedToggleWrap)

-- ===== UI: SLIDER WALKSPEED =====
local sliderWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    Visible = false,
}, movePage)
corner(sliderWrap, 10)

local sliderLabel = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 6),
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    Text = "Скорость: " .. walkSpeedValue,
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sliderWrap)

local sliderTrack = create("Frame", {
    Position = UDim2.new(0, 12, 0, 32),
    Size = UDim2.new(1, -24, 0, 8),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
}, sliderWrap)
corner(sliderTrack, 4)

local sliderFill = create("Frame", {
    Size = UDim2.new((walkSpeedValue - 16) / (500 - 16), 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, sliderTrack)
corner(sliderFill, 4)

local sliderKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new((walkSpeedValue - 16) / (500 - 16), 0, 0.5, 0),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, sliderTrack)
corner(sliderKnob, 9)

-- ===== UI: STEALTH TOGGLE =====
local stealthToggleWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundColor3 = C.surface,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
}, movePage)
corner(stealthToggleWrap, 10)
local stealthToggleStroke = create("UIStroke", {
    Color = C.border,
    Thickness = 1,
    Transparency = 0.4,
}, stealthToggleWrap)

local stealthToggleLabel = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -80, 0, 16),
    BackgroundTransparency = 1,
    Text = "Stealth Mode (beta) 🔒",
    TextColor3 = C.muted,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, stealthToggleWrap)

local stealthToggleHint = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 26),
    Size = UDim2.new(1, -80, 0, 14),
    BackgroundTransparency = 1,
    Text = "Включи ускорение, чтобы разблокировать",
    TextColor3 = C.muted,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, stealthToggleWrap)

local stealthToggleTrack = create("Frame", {
    Position = UDim2.new(1, -62, 0.5, -12),
    Size = UDim2.new(0, 46, 0, 24),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
}, stealthToggleWrap)
corner(stealthToggleTrack, 12)

local stealthToggleKnob = create("Frame", {
    Position = UDim2.new(0, 2, 0, 2),
    Size = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, stealthToggleTrack)
corner(stealthToggleKnob, 10)

local stealthToggleBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
}, stealthToggleWrap)

-- ===== UI: RUSH TOGGLE =====
local rushToggleWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundColor3 = C.surface,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
}, movePage)
corner(rushToggleWrap, 10)
local rushToggleStroke = create("UIStroke", {
    Color = C.border,
    Thickness = 1,
    Transparency = 0.4,
}, rushToggleWrap)

local rushToggleLabel = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -80, 0, 16),
    BackgroundTransparency = 1,
    Text = "⚡ Teleport Rush 🔒",
    TextColor3 = C.muted,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rushToggleWrap)

local rushToggleHint = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 26),
    Size = UDim2.new(1, -80, 0, 14),
    BackgroundTransparency = 1,
    Text = "Включи ускорение, чтобы разблокировать",
    TextColor3 = C.muted,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rushToggleWrap)

local rushToggleTrack = create("Frame", {
    Position = UDim2.new(1, -62, 0.5, -12),
    Size = UDim2.new(0, 46, 0, 24),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
}, rushToggleWrap)
corner(rushToggleTrack, 12)

local rushToggleKnob = create("Frame", {
    Position = UDim2.new(0, 2, 0, 2),
    Size = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, rushToggleTrack)
corner(rushToggleKnob, 10)

local rushToggleBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
}, rushToggleWrap)

-- ===== UI: RUSH SETTINGS =====
local rushSettingsWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 110),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    Visible = false,
}, movePage)
corner(rushSettingsWrap, 10)

local rushSpeedLabel = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 6),
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    Text = "⚡ Скорость: " .. rushSpeedValue,
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rushSettingsWrap)

local rushSpeedTrack = create("Frame", {
    Position = UDim2.new(0, 12, 0, 28),
    Size = UDim2.new(1, -24, 0, 8),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
}, rushSettingsWrap)
corner(rushSpeedTrack, 4)

local rushSpeedFill = create("Frame", {
    Size = UDim2.new(rushSpeedValue / 500, 0, 1, 0),
    BackgroundColor3 = C.pink,
    BorderSizePixel = 0,
}, rushSpeedTrack)
corner(rushSpeedFill, 4)

local rushSpeedKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(rushSpeedValue / 500, 0, 0.5, 0),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, rushSpeedTrack)
corner(rushSpeedKnob, 9)

local rushHeightLabel = create("TextLabel", {
    Position = UDim2.new(0, 12, 0, 54),
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    Text = "⚡ Высота: " .. rushHeightValue .. " стадов",
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rushSettingsWrap)

local rushHeightTrack = create("Frame", {
    Position = UDim2.new(0, 12, 0, 76),
    Size = UDim2.new(1, -24, 0, 8),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
}, rushSettingsWrap)
corner(rushHeightTrack, 4)

local rushHeightFill = create("Frame", {
    Size = UDim2.new(rushHeightValue / 10, 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
}, rushHeightTrack)
corner(rushHeightFill, 4)

local rushHeightKnob = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(rushHeightValue / 10, 0, 0.5, 0),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = C.text,
    BorderSizePixel = 0,
}, rushHeightTrack)
corner(rushHeightKnob, 9)

-- ===== UI: EDIT BUTTON =====
local rushEditWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    Visible = false,
}, movePage)
corner(rushEditWrap, 10)

local rushEditBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "📐  РЕДАКТИРОВАТЬ ПОЗИЦИЮ ⚡",
    TextColor3 = C.text,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
}, rushEditWrap)

-- ===== ЛОГИКА WALKSPEED =====
local function applyWalkSpeed()
    local char = LocalPlayer.Character
    if not char then return end
    currentHumanoid = char:FindFirstChildOfClass("Humanoid")
    currentHRP = char:FindFirstChild("HumanoidRootPart")
end

local function cleanupStealthObjects()
    if currentLinearVelocity then pcall(function() currentLinearVelocity:Destroy() end) end
    if currentBodyVelocity then pcall(function() currentBodyVelocity:Destroy() end) end
    if currentAttachment then pcall(function() currentAttachment:Destroy() end) end
    currentLinearVelocity = nil
    currentBodyVelocity = nil
    currentAttachment = nil
end

local function updateSpeedState()
    applyWalkSpeed()
    if not currentHumanoid then return end

    if walkSpeedEnabled and not stealthEnabled then
        cleanupStealthObjects()
        currentHumanoid.WalkSpeed = walkSpeedValue
    elseif walkSpeedEnabled and stealthEnabled then
        currentHumanoid.WalkSpeed = 16

        if not currentHRP then return end

        if not currentLinearVelocity and not currentBodyVelocity then
            local ok = pcall(function()
                currentAttachment = Instance.new("Attachment")
                currentAttachment.Parent = currentHRP

                currentLinearVelocity = Instance.new("LinearVelocity")
                currentLinearVelocity.Attachment0 = currentAttachment
                currentLinearVelocity.MaxForce = math.huge
                currentLinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
                currentLinearVelocity.Parent = currentHRP
            end)

            if not ok or not currentLinearVelocity then
                cleanupStealthObjects()
                pcall(function()
                    currentBodyVelocity = Instance.new("BodyVelocity")
                    currentBodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
                    currentBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    currentBodyVelocity.Parent = currentHRP
                end)
            end
        end
    else
        cleanupStealthObjects()
        currentHumanoid.WalkSpeed = 16
    end
end

RunService.RenderStepped:Connect(function()
    if not walkSpeedEnabled then return end
    if _G.RH_HUB_RUSH_ACTIVE and _G.RH_HUB_RUSH_ACTIVE() then return end

    local char = LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    if stealthEnabled then
        humanoid.WalkSpeed = 16

        local moveDir = humanoid.MoveDirection
        local velocity = moveDir.Magnitude > 0
            and moveDir.Unit * walkSpeedValue
            or Vector3.new(0, 0, 0)

        if currentLinearVelocity and currentLinearVelocity.Parent then
            currentLinearVelocity.VectorVelocity = velocity
        elseif currentBodyVelocity and currentBodyVelocity.Parent then
            currentBodyVelocity.Velocity = velocity
        end
    else
        humanoid.WalkSpeed = walkSpeedValue
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyWalkSpeed()
    if walkSpeedEnabled then
        cleanupStealthObjects()
        updateSpeedState()
    end
end)

local function updateChildStates()
    if walkSpeedEnabled then
        stealthToggleWrap.BackgroundTransparency = 0
        stealthToggleStroke.Transparency = 0.2
        stealthToggleLabel.TextColor3 = C.text
        stealthToggleLabel.Text = "Stealth Mode (beta)"
        stealthToggleHint.Text = "Сервер не видит изменение скорости"
    else
        stealthToggleWrap.BackgroundTransparency = 0.5
        stealthToggleStroke.Transparency = 0.5
        stealthToggleLabel.TextColor3 = C.muted
        stealthToggleLabel.Text = "Stealth Mode (beta) 🔒"
        stealthToggleHint.Text = "Включи ускорение, чтобы разблокировать"
    end

    if walkSpeedEnabled then
        rushToggleWrap.BackgroundTransparency = 0
        rushToggleStroke.Transparency = 0.2
        rushToggleLabel.TextColor3 = C.text
        rushToggleLabel.Text = "⚡ Teleport Rush"
        rushToggleHint.Text = "Зажми ⚡ на экране для рывка"
    else
        rushToggleWrap.BackgroundTransparency = 0.5
        rushToggleStroke.Transparency = 0.5
        rushToggleLabel.TextColor3 = C.muted
        rushToggleLabel.Text = "⚡ Teleport Rush 🔒"
        rushToggleHint.Text = "Включи ускорение, чтобы разблокировать"
    end

    rushSettingsWrap.Visible = walkSpeedEnabled and rushModeEnabled
    rushEditWrap.Visible = walkSpeedEnabled and rushModeEnabled
end

walkSpeedToggleBtn.MouseButton1Click:Connect(function()
    walkSpeedEnabled = not walkSpeedEnabled

    TweenService:Create(walkSpeedToggleTrack, TweenInfo.new(0.2), {
        BackgroundColor3 = walkSpeedEnabled and C.accent or C.button,
    }):Play()
    TweenService:Create(walkSpeedToggleKnob, TweenInfo.new(0.2), {
        Position = walkSpeedEnabled and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
    }):Play()

    sliderWrap.Visible = walkSpeedEnabled

    if not walkSpeedEnabled then
        if stealthEnabled then
            stealthEnabled = false
            TweenService:Create(stealthToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = C.button }):Play()
            TweenService:Create(stealthToggleKnob, TweenInfo.new(0.2), { Position = UDim2.new(0, 2, 0, 2) }):Play()
        end
        if rushModeEnabled then
            rushModeEnabled = false
            TweenService:Create(rushToggleTrack, TweenInfo.new(0.2), { BackgroundColor3 = C.button }):Play()
            TweenService:Create(rushToggleKnob, TweenInfo.new(0.2), { Position = UDim2.new(0, 2, 0, 2) }):Play()
            _G.RH_HUB_SET_RUSH_VISIBLE(false)
        end
    end

    updateChildStates()
    updateSpeedState()
end)

local sliderDragging = false

local function updateSliderFromX(x)
    local left = sliderTrack.AbsolutePosition.X
    local width = math.max(1, sliderTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - left) / width, 0, 1)
    local value = math.floor((16 + alpha * (500 - 16)) / 5 + 0.5) * 5
    value = math.clamp(value, 16, 500)
    walkSpeedValue = value

    sliderLabel.Text = "Скорость: " .. walkSpeedValue

    local newAlpha = (walkSpeedValue - 16) / (500 - 16)
    TweenService:Create(sliderFill, TweenInfo.new(0.08), { Size = UDim2.new(newAlpha, 0, 1, 0) }):Play()
    TweenService:Create(sliderKnob, TweenInfo.new(0.08), { Position = UDim2.new(newAlpha, 0, 0.5, 0) }):Play()

    updateSpeedState()
end

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
        updateSliderFromX(input.Position.X)
    end
end)
sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
        updateSliderFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateSliderFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
    end
end)

stealthToggleBtn.MouseButton1Click:Connect(function()
    if not walkSpeedEnabled then return end

    stealthEnabled = not stealthEnabled

    TweenService:Create(stealthToggleTrack, TweenInfo.new(0.2), {
        BackgroundColor3 = stealthEnabled and C.accent or C.button,
    }):Play()
    TweenService:Create(stealthToggleKnob, TweenInfo.new(0.2), {
        Position = stealthEnabled and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
    }):Play()

    updateSpeedState()
end)

rushToggleBtn.MouseButton1Click:Connect(function()
    if not walkSpeedEnabled then return end

    rushModeEnabled = not rushModeEnabled

    TweenService:Create(rushToggleTrack, TweenInfo.new(0.2), {
        BackgroundColor3 = rushModeEnabled and C.accent or C.button,
    }):Play()
    TweenService:Create(rushToggleKnob, TweenInfo.new(0.2), {
        Position = rushModeEnabled and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
    }):Play()

    updateChildStates()

    _G.RH_HUB_SET_RUSH_VISIBLE(rushModeEnabled)
end)

local rushSpeedDragging = false

local function updateRushSpeedFromX(x)
    local left = rushSpeedTrack.AbsolutePosition.X
    local width = math.max(1, rushSpeedTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - left) / width, 0, 1)
    local value = math.floor(alpha * 500 / 5 + 0.5) * 5
    value = math.clamp(value, 0, 500)
    rushSpeedValue = value

    rushSpeedLabel.Text = "⚡ Скорость: " .. rushSpeedValue

    local newAlpha = rushSpeedValue / 500
    TweenService:Create(rushSpeedFill, TweenInfo.new(0.08), { Size = UDim2.new(newAlpha, 0, 1, 0) }):Play()
    TweenService:Create(rushSpeedKnob, TweenInfo.new(0.08), { Position = UDim2.new(newAlpha, 0, 0.5, 0) }):Play()

    _G.RH_HUB_SET_RUSH_SPEED(rushSpeedValue)
end

rushSpeedTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushSpeedDragging = true
        updateRushSpeedFromX(input.Position.X)
    end
end)
rushSpeedKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushSpeedDragging = true
        updateRushSpeedFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if rushSpeedDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateRushSpeedFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushSpeedDragging = false
    end
end)

local rushHeightDragging = false

local function updateRushHeightFromX(x)
    local left = rushHeightTrack.AbsolutePosition.X
    local width = math.max(1, rushHeightTrack.AbsoluteSize.X)
    local alpha = math.clamp((x - left) / width, 0, 1)
    local value = math.floor(alpha * 10 + 0.5)
    value = math.clamp(value, 0, 10)
    rushHeightValue = value

    rushHeightLabel.Text = "⚡ Высота: " .. rushHeightValue .. " стадов"

    local newAlpha = rushHeightValue / 10
    TweenService:Create(rushHeightFill, TweenInfo.new(0.08), { Size = UDim2.new(newAlpha, 0, 1, 0) }):Play()
    TweenService:Create(rushHeightKnob, TweenInfo.new(0.08), { Position = UDim2.new(newAlpha, 0, 0.5, 0) }):Play()

    _G.RH_HUB_SET_RUSH_HEIGHT(rushHeightValue)
end

rushHeightTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushHeightDragging = true
        updateRushHeightFromX(input.Position.X)
    end
end)
rushHeightKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushHeightDragging = true
        updateRushHeightFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if rushHeightDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateRushHeightFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushHeightDragging = false
    end
end)

local rushEditActive = false

rushEditBtn.MouseButton1Click:Connect(function()
    if not rushEditActive then
        rushEditActive = true
        rushEditBtn.Text = "✓  СОХРАНИТЬ ПОЗИЦИЮ ⚡"
        rushEditBtn.TextColor3 = C.green
        _G.RH_HUB_ENTER_RUSH_EDIT(true)
    else
        rushEditActive = false
        rushEditBtn.Text = "📐  РЕДАКТИРОВАТЬ ПОЗИЦИЮ ⚡"
        rushEditBtn.TextColor3 = C.text
        _G.RH_HUB_ENTER_RUSH_EDIT(false)
    end
end)

updateChildStates()

-- ============ VISUAL ============
section(visualPage, "ВИЗУАЛИЗАЦИЯ")
soonCard(visualPage)

-- ============ TELEPORT ============
section(tpPage, "ТЕЛЕПОРТ")
soonCard(tpPage)

-- ============ SETTINGS ============
section(settingsPage, "НАСТРОЙКИ")
infoCard(settingsPage, "КНОПКА ВЫХОДА", "Выход из аккаунта — сброс сохранённого токена.")

local logoutBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "🔓  ВЫЙТИ ИЗ АККАУНТА",
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, settingsPage)
corner(logoutBtn, 10)
stroke(logoutBtn, C.red, 1, 0.4)

logoutBtn.MouseButton1Click:Connect(function()
    clearToken()
    STATE.authed = false
    STATE.token = nil

    if FarmApi then pcall(FarmApi.Shutdown) end

    if mainGui and mainGui.Parent then
        pcall(function() mainGui:Destroy() end)
    end

    local ok, err = pcall(function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/RAHER458/TEST-0.0.1/main/esp.lua?t=" .. os.time()
        ))()
    end)
    if not ok then
        warn("[RH-HUB] Перезапуск не удался: " .. tostring(err))
    end
end)

-- ============ ABOUT ============
section(aboutPage, "О ПРОЕКТЕ")
infoCard(aboutPage, "RH-HUB", "Standalone Roblox Multi-Tool Hub")
infoCard(aboutPage, "ВЕРСИЯ", CONFIG.VERSION)
infoCard(aboutPage, "РАЗРАБОТЧИК", "Telegram: t.me/generalvaneska2024")
-- ============ DRAG MAIN WINDOW ============
local dragMain = { active = false, input = nil, startPointer = nil, startPos = nil }

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMain.active = true
        dragMain.input = input
        dragMain.startPointer = input.Position
        dragMain.startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragMain.active then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local d = input.Position - dragMain.startPointer
    main.Position = UDim2.new(
        dragMain.startPos.X.Scale, dragMain.startPos.X.Offset + d.X,
        dragMain.startPos.Y.Scale, dragMain.startPos.Y.Offset + d.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMain.active = false
        dragMain.input = nil
    end
end)

-- ============ OVERLAY ============
local overlayGui = create("ScreenGui", {
    Name = "RH_HUB_OVERLAY",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 99998,
    Enabled = false,
})
safeParent(overlayGui)

local overlayFrame = create("TextButton", {
    Name = "Overlay",
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(20, 300),
    Size = UDim2.fromOffset(150, 26),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    Text = "RH  |  FPS --  |  PING --",
    TextColor3 = C.text,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, overlayGui)
corner(overlayFrame, 8)
stroke(overlayFrame, C.accent, 1, 0.2)

local statsService = game:GetService("Stats")
local fpsFrames, fpsElapsed = 0, 0

local function readPing()
    local ping = nil
    pcall(function()
        ping = statsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if typeof(ping) == "number" then
        return math.max(0, math.floor(ping + 0.5))
    end
    return nil
end

RunService.RenderStepped:Connect(function(dt)
    fpsFrames += 1
    fpsElapsed += dt
    if fpsElapsed >= 0.5 then
        local currentFPS = math.floor(fpsFrames / fpsElapsed + 0.5)
        local ping = readPing()
        overlayFrame.Text = string.format("RH  |  FPS %d  |  PING %s",
            currentFPS,
            ping and tostring(ping) or "--"
        )
        fpsFrames, fpsElapsed = 0, 0
    end
end)

local dragOverlay = { active = false, input = nil, startPointer = nil, startPos = nil, moved = false }
local OVERLAY_THRESHOLD = 6

overlayFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragOverlay.active = true
        dragOverlay.input = input
        dragOverlay.startPointer = input.Position
        dragOverlay.startPos = Vector2.new(overlayFrame.Position.X.Offset, overlayFrame.Position.Y.Offset)
        dragOverlay.moved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragOverlay.active then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local d = input.Position - dragOverlay.startPointer
    if math.abs(d.X) > OVERLAY_THRESHOLD or math.abs(d.Y) > OVERLAY_THRESHOLD then
        dragOverlay.moved = true
    end

    if dragOverlay.moved then
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        local x = math.clamp(dragOverlay.startPos.X + d.X, 0, vp.X - overlayFrame.AbsoluteSize.X)
        local y = math.clamp(dragOverlay.startPos.Y + d.Y, 0, vp.Y - overlayFrame.AbsoluteSize.Y)
        overlayFrame.Position = UDim2.fromOffset(x, y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragOverlay.active = false
    end
end)

-- ============ CIRCLE ============
local circleGui = create("ScreenGui", {
    Name = "RH_HUB_CIRCLE",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 99999,
    Enabled = false,
})
safeParent(circleGui)

local circleButton = create("TextButton", {
    Name = "CircleBtn",
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(20, 360),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0,
    Text = "HUB",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 13,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
}, circleGui)
corner(circleButton, 27)
stroke(circleButton, C.pink, 1.5, 0.2)

local pulseRunning = false
local function startCirclePulse()
    if pulseRunning then return end
    pulseRunning = true
    task.spawn(function()
        while circleGui.Enabled do
            TweenService:Create(circleButton, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Size = UDim2.fromOffset(58, 58) }):Play()
            task.wait(0.9)
            if not circleGui.Enabled then break end
            TweenService:Create(circleButton, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Size = UDim2.fromOffset(54, 54) }):Play()
            task.wait(0.9)
        end
        pulseRunning = false
    end)
end

local dragCircle = { active = false, input = nil, startPointer = nil, startPos = nil, moved = false }
local CIRCLE_THRESHOLD = 6

circleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragCircle.active = true
        dragCircle.input = input
        dragCircle.startPointer = input.Position
        dragCircle.startPos = Vector2.new(circleButton.Position.X.Offset, circleButton.Position.Y.Offset)
        dragCircle.moved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragCircle.active then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local d = input.Position - dragCircle.startPointer
    if math.abs(d.X) > CIRCLE_THRESHOLD or math.abs(d.Y) > CIRCLE_THRESHOLD then
        dragCircle.moved = true
    end

    if dragCircle.moved then
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        local x = math.clamp(dragCircle.startPos.X + d.X, 0, vp.X - circleButton.AbsoluteSize.X)
        local y = math.clamp(dragCircle.startPos.Y + d.Y, 0, vp.Y - circleButton.AbsoluteSize.Y)
        circleButton.Position = UDim2.fromOffset(x, y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not dragCircle.active then return end
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragCircle.active = false

        if not dragCircle.moved then
            circleGui.Enabled = false
            mainGui.Enabled = true
            STATE.mode = "window"
        end
    end
end)

-- ============ MINIMIZE / CIRCLE / OVERLAY ============
local function setMode(newMode)
    if STATE.mode == newMode then return end

    mainGui.Enabled = false
    overlayGui.Enabled = false
    circleGui.Enabled = false

    if newMode == "window" then
        mainGui.Enabled = true
    elseif newMode == "overlay" then
        overlayGui.Enabled = true
    elseif newMode == "circle" then
        circleGui.Enabled = true
        startCirclePulse()
    end

    STATE.mode = newMode
end

minimizeBtn.MouseButton1Click:Connect(function()
    if STATE.mode == "window" then
        setMode("overlay")
    elseif STATE.mode == "overlay" then
        setMode("window")
    end
end)

circleBtn.MouseButton1Click:Connect(function()
    if STATE.mode == "window" then
        setMode("circle")
    end
end)

local lastOverlayTap = 0
overlayFrame.MouseButton1Click:Connect(function()
    local now = os.clock()
    if now - lastOverlayTap < 0.6 then
        setMode("window")
    end
    lastOverlayTap = now
end)

-- ============ ⚡ RUSH — ГЛОБАЛЬНАЯ КНОПКА ============
local rushGui = create("ScreenGui", {
    Name = "RH_HUB_RUSH",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 99997,
    Enabled = true,
})
safeParent(rushGui)

local rushBtn = create("TextButton", {
    Name = "RushBtn",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, savedCfg.rushBtnPos.x, 1, savedCfg.rushBtnPos.y),
    Size = UDim2.fromOffset(64, 64),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Text = "⚡",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 28,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    Visible = false,
}, rushGui)
corner(rushBtn, 32)
local rushStroke = stroke(rushBtn, C.pink, 2, 0.15)

-- ============ HOOK WALKSPEED ============
local hookInstalled = false
local hookActive = false

local function setupWalkSpeedHook()
    if hookInstalled then return end
    if type(hookmetamethod) ~= "function" or type(newcclosure) ~= "function" then
        return
    end

    local oldIndex, oldNewIndex

    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if key == "WalkSpeed" and hookActive then
            local char = LocalPlayer.Character
            if char and self == char:FindFirstChildOfClass("Humanoid") then
                return 16
            end
        end
        return oldIndex(self, key)
    end))

    oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
        if key == "WalkSpeed" and hookActive then
            local char = LocalPlayer.Character
            if char and self == char:FindFirstChildOfClass("Humanoid") then
                return oldNewIndex(self, key, 16)
            end
        end
        return oldNewIndex(self, key, value)
    end))

    hookInstalled = true
end

setupWalkSpeedHook()

-- ============ ⚡ RUSH — ЛОГИКА ============
local rushActive = false
local rushEditMode = false

_G.RH_HUB_RUSH_ACTIVE = function() return rushActive end

local function activateRush()
    if rushActive then return end
    if not _G.RH_HUB_IS_WALKSPEED_ON() then return end
    if not _G.RH_HUB_IS_RUSH_ON() then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    hookActive = true

    local height = _G.RH_HUB_RUSH_HEIGHT or 5
    hrp.CFrame = hrp.CFrame + Vector3.new(0, height, 0)

    rushActive = true
end

local function deactivateRush()
    if not rushActive then return end
    rushActive = false
    hookActive = false

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { char }

    local origin = hrp.Position
    local direction = Vector3.new(0, -1000, 0)

    local result = workspace:Raycast(origin, direction, rayParams)

    if result then
        local groundY = result.Position.Y + 3
        hrp.CFrame = CFrame.new(hrp.Position.X, groundY, hrp.Position.Z)
    end
end

RunService.RenderStepped:Connect(function(dt)
    if not rushActive then return end
    if rushEditMode then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    local moveDir = humanoid.MoveDirection

    if moveDir.Magnitude > 0 then
        local speed = _G.RH_HUB_RUSH_SPEED or 200
        local step = moveDir.Unit * (speed / 60)
        hrp.CFrame = hrp.CFrame + step
    end
end)

rushBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    if rushEditMode then return end

    activateRush()
end)

rushBtn.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    if rushEditMode then return end

    deactivateRush()
end)

local rushDrag = { active = false, input = nil, startPointer = nil, startPos = nil }
local RUSH_DRAG_THRESHOLD = 4

rushBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    if not rushEditMode then return end

    rushDrag.active = true
    rushDrag.input = input
    rushDrag.startPointer = input.Position
    rushDrag.startPos = Vector2.new(rushBtn.Position.X.Offset, rushBtn.Position.Y.Offset)
end)

UserInputService.InputChanged:Connect(function(input)
    if not rushDrag.active then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local d = input.Position - rushDrag.startPointer

    if math.abs(d.X) > RUSH_DRAG_THRESHOLD or math.abs(d.Y) > RUSH_DRAG_THRESHOLD then
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
        local x = math.clamp(rushDrag.startPos.X + d.X, -vp.X + rushBtn.AbsoluteSize.X, 0)
        local y = math.clamp(rushDrag.startPos.Y + d.Y, -vp.Y + rushBtn.AbsoluteSize.Y, 0)
        rushBtn.Position = UDim2.new(1, x, 1, y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not rushDrag.active then return end
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rushDrag.active = false
    end
end)

_G.RH_HUB_SET_RUSH_VISIBLE = function(visible)
    if rushEditMode then
        rushBtn.Visible = true
        return
    end
    rushBtn.Visible = visible
end

_G.RH_HUB_SET_RUSH_SPEED = function(speed)
    _G.RH_HUB_RUSH_SPEED = speed
end

_G.RH_HUB_SET_RUSH_HEIGHT = function(height)
    _G.RH_HUB_RUSH_HEIGHT = height
end

_G.RH_HUB_ENTER_RUSH_EDIT = function(enter)
    rushEditMode = enter

    if enter then
        rushBtn.Visible = true
        rushBtn.BackgroundTransparency = 0.5
        rushBtn.Text = "✥"
        rushBtn.TextSize = 26
        rushStroke.Transparency = 0.5
    else
        savedCfg.rushBtnPos = {
            x = rushBtn.Position.X.Offset,
            y = rushBtn.Position.Y.Offset,
        }
        saveConfig()

        rushBtn.BackgroundTransparency = 0.15
        rushBtn.Text = "⚡"
        rushBtn.TextSize = 28
        rushStroke.Transparency = 0.15

        if not _G.RH_HUB_IS_RUSH_ON() then
            rushBtn.Visible = false
        end
    end
end

-- ============ FARM: ENGINE + UI (внутри gamesFarmContainer) ============
-- Таблица требований скорости по зонам (Speed из leaderstats)
local ZONE_SPEED_REQ = {
    ["Lake"]              = 900,
    ["Desert"]            = 10000,
    ["Jungle"]            = 40000,
    ["Snow"]              = 170000,
    ["Volcano"]           = 700000,
    ["Abyss Ocean"]       = 2500000,
    ["Prehistoric"]       = 18000000,
    ["Cosmic"]            = 700000000,
    ["Cherry Blossom"]    = 2500000000,
    ["Titan Temple"]      = 7000000000,
    ["Angels and Demons"] = 20000000000,
}

-- Красивый формат для отображения числа скорости
local function formatSpeed(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.0fT", n / 1e12) end
    if n >= 1e9  then
        local v = n / 1e9
        if v % 1 == 0 then return string.format("%dB", v) end
        return string.format("%.1fB", v)
    end
    if n >= 1e6  then
        local v = n / 1e6
        if v % 1 == 0 then return string.format("%dM", v) end
        return string.format("%.1fM", v)
    end
    if n >= 1e3  then
        local v = n / 1e3
        if v % 1 == 0 then return string.format("%dK", v) end
        return string.format("%.1fK", v)
    end
    return tostring(math.floor(n))
end

-- Читатель текущей Speed игрока из leaderstats
local function getPlayerSpeed()
    local lp = LocalPlayer
    local ls = lp:FindFirstChild("leaderstats")
    if not ls then return 0 end
    local spd = ls:FindFirstChild("Speed")
    if not spd then return 0 end
    return tonumber(spd.Value) or 0
end

local function initFarm()
    if FarmApi then return end

    local Farm = (function()
        local e=game:GetService( "Players" )
        local r=game:GetService( "Workspace" )
        local y=game:GetService( "RunService" )
        local u=game:GetService( "TweenService" )
        local w=game:GetService( "UserInputService" )
        local j=game:GetService( "ReplicatedStorage" )
        local k=game:GetService( "ProximityPromptService" )
        local a=game:GetService( "HttpService" )
        local TeleportService=game:GetService( "TeleportService" )
        local o=e.LocalPlayer
        local Window=nil
        local currentLang="EN"
        local executorCheckCaller=typeof(checkcaller)=="function" and checkcaller or function() return false end
        local safeNewCClosure=typeof(newcclosure)=="function" and newcclosure or function(fn) return fn end

        local diagnosticLogs = {}
        local MAX_DIAGNOSTIC_LOGS = 300
        local function diagnosticString(...)
            local out = {}
            for i = 1, select("#", ...) do
                local value = select(i, ...)
                out[#out + 1] = tostring(value)
            end
            return table.concat(out, " ")
        end
        local function addDiagnosticLog(level, ...)
            local ok, message = pcall(diagnosticString, ...)
            message = ok and message or "[log formatting failed]"
            local stamp = os.date("%H:%M:%S")
            diagnosticLogs[#diagnosticLogs + 1] = string.format("[%s] [%s] %s", stamp, tostring(level), message)
            while #diagnosticLogs > MAX_DIAGNOSTIC_LOGS do
                table.remove(diagnosticLogs, 1)
            end
        end
        local H=function(...) addDiagnosticLog("INFO", ...) end
        local t=function(...) addDiagnosticLog("DEBUG", ...) end
        local s=nil pcall(function(...) s=require((j:WaitForChild( "Client" , 5 )):WaitForChild( "EggState" , 5 ))
        end
        )
        if not s then
            pcall(function(...) s=require(j.Client.EggState )
            end
            )
        end
        local p=nil pcall(function(...) p=require(((j:WaitForChild( "Shared" , 5 )):WaitForChild( "Util" , 5 )):WaitForChild( "AssetItems" , 5 ))
        end
        )
        if not p then
            pcall(function(...) p=require(j.Shared.Util .AssetItems )
            end
            )
        end
        local B=nil pcall(function(...) B=require((j:WaitForChild( "Shared" , 5 )):WaitForChild( "Remotes" , 5 ))
        end
        )
        if not B then
            pcall(function(...) B=require(j.Shared.Remotes )
            end
            )
        end
        local function J(e,r,...)
            local y=(j:FindFirstChild( "Packages" )and j.Packages :FindFirstChild( "Networking" ))or j:FindFirstChild( "Network" )or j
            local u=y:FindFirstChild(e)or j:FindFirstChild(e)
            if u then
                return u
            end
            local w=y:FindFirstChild(e, true )or j:FindFirstChild(e, true )
            if w then
                return w
            end
            if r then
                local e=y:FindFirstChild(r)or j:FindFirstChild(r)
                if e then
                    return e
                end
                local u=y:FindFirstChild(r, true )or j:FindFirstChild(r, true )
                if u then
                    return u
                end
            end
            local k=string.match (e, "[^/]+$" )
            if k then
                local e=y:FindFirstChild(k, true )or j:FindFirstChild(k, true )
                if e then
                    return e
                end
            end
            return nil
        end

        local K=J( "RF/EggWorld/AskPlaceEgg" , "AskPlaceEgg" ) 
        local c=J( "RF/EggWorld/AskLiveSnapshot" , "AskLiveSnapshot" ) 
        local v=J( "RF/Homestead/AskState" , "RF/Plots/AskState" )or J( "AskState" )
        local i=J( "RF/EggWorld/AskFieldEggCarry" , "AskFieldEggCarry" ) 
        local R=J( "RF/EggWorld/AskFieldEggSnapshot" , "AskFieldEggSnapshot" )or J( "Eggs: RequestAreaEggSnapshot" , "RequestAreaEggSnapshot" )
        local g=J( "RF/EggWorld/AskHatch" , "AskHatch" )or J( "Eggs: RequestHatchEgg" )
        local Q=J( "RF/EggWorld/AskFinishHatch" , "AskFinishHatch" )or J( "Eggs: RequestCompleteHatchEgg" )
        local P=J( "RE/GuardPatrol/ForestStrike" , "ForestStrike" )or(B and(B.GuardPatrol and B.GuardPatrol.ForestStrike ))
        local N=J( "SpeedTollOffer" , "RE/GuardPatrol/SpeedTollOffer" )or(B and(B.GuardPatrol and B.GuardPatrol.SpeedTollOffer ))
        local U=J( "RF/Treadmill/AskDoff" , "AskDoff" )
        local l=J( "RF/Treadmill/AskDon" , "AskDon" )or J( "RF/Treadmill/AskMount" , "AskMount" )
        local D=J( "RF/Treadmill/AskTierRaise" , "Treadmills: RequestUpgrade" , "AskTierRaise" )
        local C=J( "RF/Trailwear/AskPurchase" , "Trailwear: RequestPurchase" , "AskPurchase" )
        local q=J( "RF/Trailwear/AskChoose" , "Trailwear: RequestEquip" , "AskChoose" )
        local n=J( "RF/Trailwear/AskDoff" , "Trailwear: RequestUnequip" , "AskDoff" )H(string.format ( "[RemoteCheck] Carry: %s | Snapshot: %s | Place: %s | Hatch: %s | FinishHatch: %s | Strike: %s | Toll: %s | Doff: %s" ,tostring(i~=nil),tostring(R~=nil),tostring(K~=nil),tostring(g~=nil),tostring(Q~=nil),tostring(P~=nil),tostring(N~=nil),tostring(U~=nil)))

        local f={[ "Light Dark" ]= 1300 ,[ "LightDark" ]= 1300 ;
        [ "Titan Temple" ]= 1100 ,[ "Cherry Blossom" ]= 1000 ,[ "Cosmic" ]= 900 ;
        [ "Prehistoric" ]= 800 ;
        [ "Abyss Ocean" ]= 700 ,[ "Volcano" ]= 600 ;
        [ "Snow" ]= 500 ,[ "Jungle" ]= 400 ;
        [ "Desert" ]= 300 ,[ "Lake" ]= 200 ;
        [ "Forest" ]= 100 }
        local M={ "Angels and Demons" ;
        "Titan Temple" ;
        "Cherry Blossom" , "Cosmic" ;
        "Prehistoric" , "Abyss Ocean" ;
        "Volcano" ;
        "Snow" , "Jungle" , "Desert" , "Lake" }
        local I={[ "Light Dark" ]= 420 ,[ "LightDark" ]= 420 ;
        [ "Titan Temple" ]= 380 ,[ "Cherry Blossom" ]= 330 ,[ "Cosmic" ]= 280 ;
        [ "Prehistoric" ]= 240 ,[ "Abyss Ocean" ]= 200 ;
        [ "Volcano" ]= 180 ;
        [ "Snow" ]= 160 ,[ "Jungle" ]= 140 ;
        [ "Desert" ]= 130 ,[ "Lake" ]= 125 ,[ "Forest" ]= 125 }
        local L= -360
        local E= 525
        local b= 620
        local A= 130
        local S=CFrame.new ( 4773.7587890625 , 70.392112731934 , -315.73501586914 )

        local Z= "RH_HUB_FlightSpeed.txt"
        local z= "RH_HUB_FarmConfig.json"
        local d={[ "Angels and Demons" ]=Color3.fromRGB ( 244 , 63 , 94 );
        [ "Titan Temple" ]=Color3.fromRGB ( 245 , 158 , 11 );
        [ "Cherry Blossom" ]=Color3.fromRGB ( 236 , 72 , 153 );
        [ "Cosmic" ]=Color3.fromRGB ( 6 , 182 , 212 ),[ "Prehistoric" ]=Color3.fromRGB ( 16 , 185 , 129 ),[ "Abyss Ocean" ]=Color3.fromRGB ( 59 , 130 , 246 );
        [ "Volcano" ]=Color3.fromRGB ( 239 , 68 , 68 ),[ "Snow" ]=Color3.fromRGB ( 147 , 197 , 253 ),[ "Jungle" ]=Color3.fromRGB ( 34 , 197 , 94 ),[ "Desert" ]=Color3.fromRGB ( 234 , 179 , 8 ),[ "Lake" ]=Color3.fromRGB ( 20 , 184 , 166 )}

        local X={ "Divine" , "Eternal" , "Secret" ;
        "Cosmic" , "Mythic" , "Legendary" ;
        "Epic" ;
        "Rare" ;
        "Uncommon" ;
        "Common" }
        local G={[ "Divine" ]=Color3.fromRGB ( 244 , 63 , 94 );
        [ "Eternal" ]=Color3.fromRGB ( 217 , 70 , 239 ),[ "Secret" ]=Color3.fromRGB ( 249 , 115 , 22 ),[ "Cosmic" ]=Color3.fromRGB ( 6 , 182 , 212 ),[ "Mythic" ]=Color3.fromRGB ( 139 , 92 , 246 ),[ "Legendary" ]=Color3.fromRGB ( 251 , 191 , 36 );
        [ "Epic" ]=Color3.fromRGB ( 168 , 85 , 247 );
        [ "Rare" ]=Color3.fromRGB ( 59 , 130 , 246 );
        [ "Uncommon" ]=Color3.fromRGB ( 34 , 197 , 94 ),[ "Common" ]=Color3.fromRGB ( 148 , 163 , 184 )}
        local F={[ "Divine" ]= 6 ;
        [ "Eternal" ]= 5 ;
        [ "Secret" ]= 4 ,[ "Cosmic" ]= 3 ;
        [ "Mythic" ]= 2 ;
        [ "Legendary" ]= 1 ,[ "Epic" ]= 0.5 ,[ "Rare" ]= 0.3 ,[ "Uncommon" ]= 0.1 ;
        [ "Common" ]= 0 }
        local h
        local function O(...)
            local e= 600 pcall(function(...)
                local r= false
                if isfile then
                    r=isfile(Z)
                elseif readfile then
                    local e,y=pcall(readfile,Z)r=e and(y~=nil)
                end
                if r and readfile then
                    local r=readfile(Z)
                    local u=tonumber(r)
                    if u and(u>= 100 and u<= 1000 )then
                        e=math.floor (u)
                    end
                end
            end
            )
            return e
        end
        local function Y(e,...) pcall(function(...)
                if writefile then
                    local y=math.clamp (math.floor (tonumber(e)or 600 ), 100 , 1000 )writefile(Z,tostring(y))
                end
            end
            )
        end
        local function T(...)
            local e=nil pcall(function(...)
                local r= false
                if isfile then
                    r=isfile(z)
                elseif readfile then
                    local e,y=pcall(readfile,z)r=e and(y~=nil)
                end
                if r and(readfile and a)then
                    local r=readfile(z)
                    if r and r~= "" then
                        local u=a:JSONDecode(r)
                        if type(u)== "table" then
                            e=u
                        end
                    end
                end
            end
            )
            local r={[ "Angels and Demons" ]= false ,[ "Titan Temple" ]= false ,[ "Cherry Blossom" ]= false ;
            [ "Cosmic" ]= false ,[ "Prehistoric" ]= false ,[ "Abyss Ocean" ]= false ;
            [ "Volcano" ]= false ,[ "Snow" ]= false ,[ "Jungle" ]= false ,[ "Desert" ]= false ;
            [ "Lake" ]= false }
            local y={[ "Divine" ]= true ,[ "Eternal" ]= true ,[ "Secret" ]= true ,[ "Cosmic" ]= true ,[ "Mythic" ]= true ;
            [ "Legendary" ]= true ,[ "Epic" ]= true ,[ "Rare" ]= true ;
            [ "Uncommon" ]= true ;
            [ "Common" ]= true }
            if type(e)~= "table" then
                e={[ "selectedZones" ]=r;
                [ "selectedRarities" ]=y,[ "alwaysCollectSecretPlus" ]= true ,[ "minRarityTier" ]= 2 ;
                [ "autoTreadmill" ]= true ;
                [ "autoUpgradeTreadmill" ]= true ,[ "autoBuyTrails" ]= true ;
                [ "hideNotEnoughMoney" ]= true ;
                [ "performanceMode" ]= false ,[ "disable3D" ]= false ,[ "antiAFK" ]= true ,[ "language" ]= "EN" }
            else
                if type(e.selectedZones )~= "table" then
                    e.selectedZones =r
                else
                    local cleaned = {}
                    for _, zn in ipairs(M) do
                        cleaned[zn] = e.selectedZones[zn] == true
                    end
                    e.selectedZones = cleaned
                end
                if type(e.selectedRarities )~= "table" then
                    e.selectedRarities =y
                else
                    for r,w in ipairs(X)do
                        if e.selectedRarities [w]==nil then
                            e.selectedRarities [w]=(y[w]== true )
                        end
                    end
                end
                if e.alwaysCollectSecretPlus ==nil then
                    e.alwaysCollectSecretPlus = true
                end
                if e.minRarityTier ==nil then
                    e.minRarityTier = 2
                end
                if e.autoTreadmill ==nil then
                    e.autoTreadmill = true
                end
                if e.autoUpgradeTreadmill ==nil then
                    e.autoUpgradeTreadmill = true
                end
                if e.autoBuyTrails ==nil then
                    e.autoBuyTrails = true
                end
                if e.hideNotEnoughMoney ==nil then
                    e.hideNotEnoughMoney = true
                end
                if e.performanceMode ==nil then
                    e.performanceMode = false
                end
                if e.disable3D ==nil then
                    e.disable3D = false
                end
                if e.antiAFK ==nil then
                    e.antiAFK = true
                end
                if e.language and((e.language == "EN" or e.language == "TH" ))then
                    currentLang=e.language
                end
            end
            return e
        end
        local function x(...) pcall(function(...)
                if writefile and(a and h)then
                    local r={[ "selectedZones" ]=h.selectedZones or{};
                    [ "selectedRarities" ]=h.selectedRarities or{};
                    [ "alwaysCollectSecretPlus" ]=(h.alwaysCollectSecretPlus ~= false ),[ "minRarityTier" ]=h.minRarityTier or 2 ,[ "autoTreadmill" ]=(h.autoTreadmill == true );
                    [ "autoUpgradeTreadmill" ]=(h.autoUpgradeTreadmill == true ),[ "autoBuyTrails" ]=(h.autoBuyTrails == true );
                    [ "hideNotEnoughMoney" ]=(h.hideNotEnoughMoney == true );
                    [ "performanceMode" ]=(h.performanceMode == true );
                    [ "disable3D" ]=(h.disable3D == true );
                    [ "antiAFK" ]=(h.antiAFK == true );
                    [ "language" ]=currentLang or "EN" }
                    local y=a:JSONEncode(r)writefile(z,y)
                end
            end
            )
        end
        local W=T()h={[ "godmode" ]= true ,[ "autoGlide" ]= true ,[ "autoHatch" ]= false ;
        [ "autoPlaceEvery5" ]= false ;
        [ "batchStealCount" ]= 0 ,[ "isBatchPlacing" ]= false ,[ "isHatching" ]= false ;
        [ "autoFarmLoop" ]= false ,[ "pureTweenFarm" ]= false ;
        [ "glidingToTarget" ]= false ;
        [ "securingEgg" ]= false ,[ "glideSpeed" ]=O();
        [ "selectedZones" ]=W.selectedZones ;
        [ "selectedRarities" ]=W.selectedRarities ;
        [ "alwaysCollectSecretPlus" ]=W.alwaysCollectSecretPlus ,[ "minRarityTier" ]=W.minRarityTier ,[ "autoTreadmill" ]=(W.autoTreadmill ~= false) ;
        [ "autoUpgradeTreadmill" ]= false ,[ "autoBuyTrails" ]= false ,[ "hideNotEnoughMoney" ]= false ;
        [ "performanceMode" ]=(W.performanceMode == true ),[ "disable3D" ]=(W.disable3D == true ),[ "antiAFK" ]=(W.antiAFK ~= false ),[ "onTreadmill" ]= false ,[ "lastTreadmillMount" ]= 0 ,[ "laneZ" ]= -360 ,[ "swapped" ]= false ;
        [ "teleporting" ]= false ,[ "isReturning" ]= false ;
        [ "delivering" ]= false ,[ "holdingEggForGuard" ]= false ,[ "currentTargetModel" ]=nil,[ "targetPosition" ]=nil;
        [ "stateTime" ]=os.clock (),[ "statusText" ]= "Ready" ,[ "bestEggInfo" ]= "Scanning..." ;
        [ "gui" ]=nil;
        [ "alive" ]= true ,[ "plot" ]=nil;
        [ "pen" ]=nil,[ "origin" ]=nil;
        [ "tread" ]=nil}
        local m
        local e4
        local r4
        local y4
        local u4
        local w4
        local j4
        local k4
        local a4
        local o4
        local V4
        local H4
        local t4
        local s4
        local p4
        local B4
        local J4
        local K4
        local c4
        local v4
        local i4
        local R4
        local g4
        local Q4
        local P4
        local N4
        local U4
        local l4
        local D4
        local C4
        local q4
        local n4
        local f4
        local M4
        local I4
        local L4
        local E4
        local b4
        local A4
        local S4
        local Z4
        local z4
        local d4
        local X4={}
        local G4= 0
        local F4=nil
        local h4
        local O4= 0
        local Y4= "NONE"
        local T4
        local x4=nil
        local W4=nil pcall(function(...)
            local e=game:GetService( "Lighting" );
            (e:GetPropertyChangedSignal( "ClockTime" )):Connect(function(...) X4={}G4= 0
            end
            )
        end
        )pcall(function(...)
            local function e(e,...)
                if e:IsA( "RemoteEvent" )then
                    local y=string.lower (e.Name )
                    if string.find (y, "reset" )or string.find (y, "night" )or string.find (y, "spawn" )or string.find (y, "countdown" )then
                        pcall(function(...) e.OnClientEvent :Connect(function(...) X4={}G4= 0
                            end
                            )
                        end
                        )
                    end
                end
            end
            for y,u in ipairs(j:GetDescendants())do
                e(u)
            end
            j.DescendantAdded :Connect(e)
        end
        )m=function(e,...)
            if not e or not e:IsA( "Tool" )then
                return false
            end
            local r=string.lower (e.Name )
            if string.find (r, "sword" )or string.find (r, "radar" )or string.find (r, "basket" )or string.find (r, "punch" )then
                return false
            end
            if e:GetAttribute( "EggUid" )or e:GetAttribute( "UID" )or string.find (r, "egg" )or e:GetAttribute( "Category" )or e:GetAttribute( "ItemType" )== "Egg" then
                return true
            end
            return false
        end
        e4=function(...)
            local e=o.Character
            if e then
                for e,y in ipairs(e:GetChildren())do
                    if m(y)then
                        local e=y:GetAttribute( "UID" )or y:GetAttribute( "EggUid" )
                        return y,e or y.Name
                    end
                end
            end
            return nil,nil
        end
        r4=function(...)
            local e=o:FindFirstChild( "Backpack" )
            if e then
                for e,y in ipairs(e:GetChildren())do
                    if m(y)then
                        local e=y:GetAttribute( "UID" )or y:GetAttribute( "EggUid" )
                        return y,e or y.Name
                    end
                end
            end
            return nil,nil
        end
        y4=function(...)
            local e= 0
            local r=o:FindFirstChild( "Backpack" )
            if r then
                for r,y in ipairs(r:GetChildren())do
                    if m(y)then
                        e=e+ 1
                    end
                end
            end
            local y=o.Character
            if y then
                for r,y in ipairs(y:GetChildren())do
                    if m(y)then
                        e=e+ 1
                    end
                end
            end
            return e
        end
        u4=function(e,...)
            if not e and not((h.pureTweenFarm or h.autoFarmLoop or h.teleporting ))then
                return
            end
            local r=o.Character
            local y=r and r:FindFirstChildOfClass( "Humanoid" )
            local u=o:FindFirstChild( "Backpack" )
            if y then
                pcall(function(...) y:UnequipTools()
                end
                )
            end
            if r and u then
                for e,r in ipairs(r:GetChildren())do
                    if r:IsA( "Tool" )then
                        pcall(function(...) r.Parent =u
                        end
                        )
                    end
                end
            end
        end
        w4=function(e,...)
            if((h.pureTweenFarm or h.autoFarmLoop ))and not h.holdingEggForGuard then
                local e=e4()
                if e then
                    pcall(u4)
                end
                return false
            end
            local r,y=e4()
            if r then
                if e then
                    if y==e or not y then
                        return true
                    end
                else
                    return true
                end
            end
            local u=o.Character
            local w=u and u:FindFirstChild( "HumanoidRootPart" )
            if w and w.Position.X <=(E+ 15 )then
                return false
            end
            if s and s.ReadFieldEggs then
                local r,y=pcall(s.ReadFieldEggs )
                if r and(y and y.Records )then
                    for r,y in ipairs(y.Records )do
                        if((y.State == "Carried" or y.State == 2 ))and((y.CarrierUserId ==o.UserId or y.Carrier ==o.UserId ))then
                            if e then
                                if y.Uid ==e then
                                    return true
                                end
                            else
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
        j4=function(e,...)
            local r,y=e4()
            if r then
                if not e or y==e or not y then
                    return true
                end
            end
            local u=o:FindFirstChild( "Backpack" )
            if u then
                for r,y in ipairs(u:GetChildren())do
                    if m(y)then
                        local r=y:GetAttribute( "UID" )or y:GetAttribute( "EggUid" )
                        if not e or r==e or y.Name ==tostring(e)then
                            return true
                        end
                    end
                end
            end
            if e and(s and s.ReadFieldEggs )then
                local r,y=pcall(s.ReadFieldEggs )
                if r and(y and y.Records )then
                    for r,y in ipairs(y.Records )do
                        if y.Uid ==e then
                            if(y.State == "Carried" or y.State == 2 )then
                                local e=y.CarrierUserId or y.Carrier
                                if e==o.UserId then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            return false
        end
        local m4= false
        local function ek(...)
            if m4 then
                return
            end
            local e=R or j:FindFirstChild( "RF/EggWorld/AskFieldEggSnapshot" , true )or j:FindFirstChild( "AskFieldEggSnapshot" , true )or j:FindFirstChild( "Eggs: RequestAreaEggSnapshot" , true )
            if not e or not e:IsA( "RemoteFunction" )then
                return
            end
            m4= true task.spawn (function(...)
                local r,y=pcall(function(...)
                    return e:InvokeServer()
                end
                )
                if r and type(y)== "table" then
                    local e={}
                    local r=y.Records or y
                    if type(r)== "table" then
                        for r,y in pairs(r)do
                            if type(y)== "table" then
                                if not y.Uid and type(r)== "string" then
                                    y.Uid =r
                                end
                                table.insert (e,y)
                            end
                        end
                    end
                    if#e> 0 then
                        F4=e G4=os.clock ()
                    end
                end
                m4= false
            end
            )
        end
        task.spawn (function(...)
            while true do
                task.wait ( 1.5 )pcall(ek)
            end
        end
        )function h4(e,...)
            local y=os.clock ()
            if e or(y-G4>= 1.5 )or not F4 then
                ek()
            end
            local u=((F4 and#F4> 0 ))and F4 or nil
            local w=nil
            if s and s.ReadFieldEggs then
                local e,r=pcall(s.ReadFieldEggs )
                if e and type(r)== "table" then
                    local e={}
                    local y=r.Records or r
                    if type(y)== "table" then
                        for r,y in pairs(y)do
                            if type(y)== "table" then
                                if not y.Uid and type(r)== "string" then
                                    y.Uid =r
                                end
                                table.insert (e,y)
                            end
                        end
                    end
                    if#e> 0 then
                        w=e
                    end
                end
            end
            local j={}
            local k={}
            if u then
                for e,r in ipairs(u)do
                    if r.Uid then
                        k[r.Uid ]= true table.insert (j,r)
                    end
                end
            end
            if w then
                for e,r in ipairs(w)do
                    if r.Uid and not k[r.Uid ]then
                        k[r.Uid ]= true table.insert (j,r)
                    end
                end
            end
            local a=r:FindFirstChild( "AreaEggSlotsClient" )
            if a then
                for e,r in ipairs(a:GetChildren())do
                    local y=r.Name
                    if y and y~= "" then
                        local e=r:GetPivot()
                        local u=e.Position
                        if not string.find (tostring(y), "FirstArea" )then
                            if not k[y]then
                                k[y]= true
                                local u=r:GetAttribute( "Category" )or r:GetAttribute( "AssetCategory" )or r.Name
                                local w=r:GetAttribute( "AreaId" )or r:GetAttribute( "Area" )
                                local a=r:GetAttribute( "Rarity" )or r:GetAttribute( "RarityTier" )
                                local V=r:GetAttribute( "RarityRank" )or r:GetAttribute( "Rank" )
                                local H=r:GetAttribute( "Income" )or r:GetAttribute( "EarningRate" )
                                local t=r:GetAttribute( "Scale" )or r:GetAttribute( "AssetScale" )or 1
                                local s=r:GetAttribute( "Mutations" )or r:GetAttribute( "Mutation" )table.insert (j,{[ "Uid" ]=y,[ "AssetCategory" ]=u,[ "AreaId" ]=w;
                                [ "Rarity" ]=a,[ "Rank" ]=V,[ "Income" ]=H,[ "BoundsCFrame" ]=e;
                                [ "BottomCFrame" ]=e,[ "CFrame" ]=e;
                                [ "State" ]= "Slot" ;
                                [ "AssetScale" ]=t,[ "Mutations" ]=s,[ "PhysicalModel" ]=r})
                            else
                                for u,w in ipairs(j)do
                                    if w.Uid ==y then
                                        w.PhysicalModel =r
                                        if not w.BoundsCFrame then
                                            w.BoundsCFrame =e
                                        end
                                        if not w.AreaId or w.AreaId == "" or w.AreaId == "Unknown" then
                                            w.AreaId =r:GetAttribute( "AreaId" )or r:GetAttribute( "Area" )
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return j
        end
        k4=function(e,...)
            if not e then
                return false , "NoUid"
            end
            local y=h4( false )
            if y and#y> 0 then
                for r,y in ipairs(y)do
                    if y.Uid ==e then
                        if(y.State == "Carried" or y.State == 2 )then
                            local e=y.CarrierUserId or y.Carrier
                            if e and e==o.UserId then
                                return true , "CarriedBySelf"
                            else
                                return false , "CarriedByOther"
                            end
                        end
                        if(y.State == "Slot" or y.State == "Dropped" or y.State == "GuardCarried" or y.State == 1 )then
                            return true , "Available"
                        end
                        local e=y.CarrierUserId or y.Carrier
                        if e then
                            if e==o.UserId then
                                return true , "CarriedBySelf"
                            else
                                return false , "CarriedByOther"
                            end
                        end
                        return true , "Available"
                    end
                end
            end
            local u=r:FindFirstChild( "AreaEggSlotsClient" )
            if u then
                for r,y in ipairs(u:GetChildren())do
                    if y.Name ==tostring(e)or y:GetAttribute( "UID" )==e or y:GetAttribute( "Uid" )==e then
                        return true , "Available"
                    end
                end
            end
            return true , "Unchecked"
        end
        a4=function(...)
            local e,r=e4()
            if not r then
                local e,y=r4()r=y
            end
            if not r then
                return false
            end
            if s and s.ReadFieldEggs then
                local e,u=pcall(s.ReadFieldEggs )
                if e and(u and u.Records )then
                    for e,u in ipairs(u.Records )do
                        if u.Uid ==r then
                            local e=tostring(u.AreaId or "" )
                            if e== "Lake" or string.find (string.lower (e), "lake" )~=nil then
                                return true
                            end
                        end
                    end
                end
            end
            if string.find (string.lower (tostring(r)), "lake" )~=nil then
                return true
            end
            return false
        end
        o4=function(...)
            local e,r=e4()
            if not r then
                local e,y=r4()r=y
            end
            if not r then
                return h.glideSpeed or 350
            end
            if s and s.ReadFieldEggs then
                local e,u=pcall(s.ReadFieldEggs )
                if e and(u and u.Records )then
                    for e,u in ipairs(u.Records )do
                        if u.Uid ==r and u.AreaId then
                            return I[u.AreaId ]or h.glideSpeed or 350
                        end
                    end
                end
            end
            return h.glideSpeed or 350
        end
        V4=function(e,y,...) y=y or 8
            local u=Instance.new ( "Part" )u.Name = "SafetyFloorPad_AntiVoid" u.Size =Vector3.new ( 28 , 1.5 , 28 )u.Position =e-Vector3.new ( 0 , 3.2 , 0 )u.Anchored = true u.Transparency = 1 u.CanCollide = true u.Parent =r task.delay (y,function(...) pcall(function(...) u:Destroy()
                end
                )
            end
            )
            return u
        end
        H4=function(e,...)
            if P and e then
                pcall(function(...)
                    local r=o.Character
                    local y=r and r:FindFirstChild( "HumanoidRootPart" )
                    local u=y and(y.CFrame *CFrame.new ( 0 , 0 , -3 ))or CFrame.new ()
                    if P:IsA( "RemoteFunction" )then
                        P:InvokeServer({[ "EggUid" ]=e,[ "GuardCFrame" ]=u})
                    else
                        P:FireServer({[ "EggUid" ]=e;
                        [ "GuardCFrame" ]=u})
                    end
                end
                )
            end
        end
        if typeof(hookmetamethod)== "function" and not _G._DesyncAntiRagdollHooked then
            _G._DesyncAntiRagdollHooked = true
            _G._DesyncAntiRagdollActive = true
            local e e=hookmetamethod(game, "__newindex" ,safeNewCClosure(function(r,y,u,...)
                if _G._DesyncAntiRagdollActive and not executorCheckCaller()and typeof(r)== "Instance" then
                    if r:IsA( "Motor6D" )and(y== "Enabled" and u== false )then
                        return nil
                    end
                    if r:IsA( "Humanoid" )then
                        if y== "PlatformStand" and u== true then
                            return nil
                        end
                        if y== "Sit" and(u== true and((h.pureTweenFarm or h.autoFarmLoop or h.isReturning or h.glidingToTarget )))then
                            return nil
                        end
                    end
                end
                return e(r,y,u)
            end
            ))
        end
        S4=function(e,...) e=e or o.Character
            if not e then
                return
            end
            local r=e:FindFirstChild( "HumanoidRootPart" )
            local y=e:FindFirstChild( "Torso" )or e:FindFirstChild( "UpperTorso" )or r
            if not y then
                return
            end
            for e,r in ipairs(e:GetDescendants())do
                if r:IsA( "BallSocketConstraint" )or r:IsA( "HingeConstraint" )or r:IsA( "NoCollisionConstraint" )then
                    pcall(function(...) r:Destroy()
                    end
                    )
                end
            end
            for e,r in ipairs(e:GetDescendants())do
                if r:IsA( "Motor6D" )and(r.Part0 and r.Part1 )then
                    r.Enabled = true
                    local e= "RigidJointWeld_" ..r.Name
                    local y=r.Part1 :FindFirstChild(e)
                    if not y then
                        local y=Instance.new ( "WeldConstraint" )y.Name =e y.Part0 =r.Part0 y.Part1 =r.Part1 y.Parent =r.Part1
                    end
                end
            end
        end
        Z4=function(e,...)
            if h and h.onTreadmill then
                return
            end
            e=e or o.Character
            if not e then
                return
            end
            local r=e:FindFirstChildOfClass( "Humanoid" )
            if r then
                r:SetStateEnabled(Enum.HumanoidStateType.Ragdoll , false )r:SetStateEnabled(Enum.HumanoidStateType.FallingDown , false )r:SetStateEnabled(Enum.HumanoidStateType.Physics , false )r:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding , false )r:SetStateEnabled(Enum.HumanoidStateType.Seated , false )
                if r.PlatformStand then
                    r.PlatformStand = false
                end
                if r.Sit then
                    r.Sit = false
                end
            end
            for e,r in ipairs(e:GetDescendants())do
                if r:IsA( "LocalScript" )and((string.find (string.lower (r.Name ), "ragdoll" )or string.find (string.lower (r.Name ), "fall" )))then
                    r.Disabled = true
                end
            end
            S4(e)
        end
        z4=function(e,...)
            if not e then
                return
            end
            Z4(e)
            for e,y in ipairs(e:GetDescendants())do
                if y:IsA( "Motor6D" )then
                    (y:GetPropertyChangedSignal( "Enabled" )):Connect(function(...)
                        if not y.Enabled then
                            y.Enabled = true
                        end
                    end
                    )
                end
            end
            e.DescendantAdded :Connect(function(y,...)
                if y:IsA( "BallSocketConstraint" )or y:IsA( "HingeConstraint" )or y:IsA( "NoCollisionConstraint" )then
                    task.defer (function(...) pcall(function(...) y:Destroy()
                        end
                        )Z4(e)
                    end
                    )
                elseif y:IsA( "LocalScript" )and((string.find (string.lower (y.Name ), "ragdoll" )or string.find (string.lower (y.Name ), "fall" )))then
                    y.Disabled = true
                end
            end
            )e.ChildAdded :Connect(function(e,...)
                if e:IsA( "Tool" )and(((h.pureTweenFarm or h.autoFarmLoop ))and not h.holdingEggForGuard )then
                    task.defer (function(...) u4()
                    end
                    )
                end
            end
            )
        end
        C4=function(...)
            if h then
                h.onTreadmill = false
            end
            local e=o.Character
            local r=e and e:FindFirstChildOfClass( "Humanoid" )
            local y=e and e:FindFirstChild( "HumanoidRootPart" )
            if U then
                task.spawn (function(...) pcall(function(...) U:InvokeServer()
                    end
                    )
                end
                )
            end
            if r then
                pcall(function(...)
                    for r,y in ipairs(r:GetPlayingAnimationTracks())do
                        local u=y.Animation
                        local w=u and u.AnimationId or ""
                        if string.find (w, "10921259953" )or string.find (string.lower (y.Name ), "treadmill" )or string.find (string.lower (y.Name ), "run" )then
                            y:Stop( 0 )
                        end
                    end
                    r.PlatformStand = false r.Sit = false r:SetStateEnabled(Enum.HumanoidStateType.Running , true )r:SetStateEnabled(Enum.HumanoidStateType.Jumping , true )r:ChangeState(Enum.HumanoidStateType.Running )
                end
                )
            end
            local u=o:FindFirstChild( "PlayerGui" )
            if u then
                local e=u:FindFirstChild( "SpeedGainAnimation" )
                if e then
                    pcall(function(...) e:Destroy()
                    end
                    )
                end
            end
            if y then
                y.AssemblyLinearVelocity =Vector3.zero y.AssemblyAngularVelocity =Vector3.zero
            end
            Z4(e)
        end
        local rk= 0
        local yk= false

        -- ===== ФИКС A: сохранение исходных WalkSpeed/Jump =====
        local savedWalkSpeed = 16
        local savedJumpPower = 50
        local savedJumpHeight = 7.2
        local statsCaptureLock = false

        local function isFarming()
            return h.pureTweenFarm or h.autoFarmLoop or h.teleporting
                or h.glidingToTarget or h.securingEgg or h.isReturning
                or h.delivering or h.onTreadmill
        end

        local function captureOriginalStats(force)
            if statsCaptureLock and not force then return end
            if isFarming() and not force then return end

            local ch = o.Character
            if not ch then return end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not hum then return end

            local ws = hum.WalkSpeed
            if ws and ws > 0 and ws <= 500 then
                savedWalkSpeed = ws
            end
            if hum.UseJumpPower then
                if hum.JumpPower and hum.JumpPower > 0 then
                    savedJumpPower = hum.JumpPower
                end
            else
                if hum.JumpHeight and hum.JumpHeight > 0 then
                    savedJumpHeight = hum.JumpHeight
                end
            end

            addDiagnosticLog("INFO", string.format("[Stats] Saved: WalkSpeed=%.1f, JumpPower=%.1f, JumpHeight=%.1f, UseJumpPower=%s",
                savedWalkSpeed, savedJumpPower, savedJumpHeight, tostring(hum.UseJumpPower)))
        end

        task.spawn(function()
            task.wait(0.5)
            captureOriginalStats(true)
        end)

        o.CharacterAdded:Connect(function()
            task.wait(1.5)
            captureOriginalStats(true)
        end)

        task.spawn(function()
            while h.alive do
                if not isFarming() then
                    captureOriginalStats(false)
                end
                task.wait(2)
            end
        end)

        E4=function(...)
            local e=o:FindFirstChild( "PlayerGui" )
            if not e then
                return false
            end
            local r= false pcall(function(...)
                for e,u in ipairs(e:GetChildren())do
                    if u:IsA( "ScreenGui" )and u.Enabled then
                        for e,u in ipairs(u:GetDescendants())do
                            if((u:IsA( "TextButton" )or u:IsA( "ImageButton" )))and u.Visible then
                                local e=(u:IsA( "TextButton" )and u.Text )or u.Name
                                local w=string.lower (e or "" )
                                if string.find (w, "get out" )or string.find (w, "treadmill" )or string.find (w, "doff" )or string.find (w, "leave" )or string.find (w, "exit" )then
                                    if typeof(firesignal)== "function" and u.Activated then
                                        pcall(firesignal,u.Activated )
                                    elseif typeof(firesignal)== "function" and u.MouseButton1Click then
                                        pcall(firesignal,u.MouseButton1Click )
                                    elseif typeof(getconnections)== "function" then
                                        local e=getconnections(u.MouseButton1Click )or getconnections(u.Activated )or{}
                                        for e,r in ipairs(e)do
                                            pcall(function(...) r:Fire()
                                            end
                                            )
                                            break
                                        end
                                    end
                                    r= true
                                    break
                                end
                            end
                        end
                        if r then
                            break
                        end
                    end
                end
            end
            )
            return r
        end
        L4=function(...)
            local e=o.Character
            local r=e and e:FindFirstChild( "HumanoidRootPart" )
            if not r then
                return false
            end
            local y=(typeof(I4)== "function" )and I4()or nil
            if y then
                local e=y.Position +Vector3.new ( 0 , 1.8 , 0 )
                local u=((r.Position -e)).Magnitude
                if u> 6 then
                    if h then
                        h.onTreadmill = false
                    end
                    return false
                end
            else
                if r.Position.X > 535 then
                    if h then
                        h.onTreadmill = false
                    end
                    return false
                end
            end
            if h and h.onTreadmill then
                return true
            end
            local u=e and e:FindFirstChildOfClass( "Humanoid" )
            if u then
                for e,r in ipairs(u:GetPlayingAnimationTracks())do
                    local y=r.Animation
                    local u=y and y.AnimationId or ""
                    local w=string.lower (r.Name or "" )
                    if string.find (u, "10921259953" )or string.find (w, "treadmill" )or string.find (w, "run" )then
                        return true
                    end
                end
            end
            local w=o:FindFirstChild( "PlayerGui" )
            if w and w:FindFirstChild( "SpeedGainAnimation" )then
                return true
            end
            return false
        end
        M4=function(...)
            if yk then
                return
            end
            if os.clock ()-rk< 0.8 then
                if h then
                    h.onTreadmill = false
                end
                return
            end
            yk= true rk=os.clock ()
            if h then
                h.onTreadmill = false
            end
            E4()
            if U then
                pcall(function(...) U:InvokeServer()
                end
                )
            end
            local e=o.Character
            local r=e and e:FindFirstChildOfClass( "Humanoid" )
            local y=e and e:FindFirstChild( "HumanoidRootPart" )
            if r then
                pcall(function(...)
                    for r,y in ipairs(r:GetPlayingAnimationTracks())do
                        local u=y.Animation
                        local w=u and u.AnimationId or ""
                        local j=string.lower (y.Name or "" )
                        if string.find (w, "10921259953" )or string.find (j, "treadmill" )or string.find (j, "run" )then
                            y:Stop( 0 )
                        end
                    end
                    r.PlatformStand = false r.Sit = false r:SetStateEnabled(Enum.HumanoidStateType.Running , true )r:SetStateEnabled(Enum.HumanoidStateType.Jumping , true )r:ChangeState(Enum.HumanoidStateType.Running )
                end
                )
            end
            local u=o:FindFirstChild( "PlayerGui" )
            if u then
                local e=u:FindFirstChild( "SpeedGainAnimation" )
                if e then
                    pcall(function(...) e:Destroy()
                    end
                    )
                end
            end
            if y then
                y.AssemblyLinearVelocity =Vector3.zero y.AssemblyAngularVelocity =Vector3.zero
            end
            Z4(e)task.wait ( 0.15 )yk= false
        end
        q4=M4 n4=function(...) pcall(function(...)
                local e=r:FindFirstChild( "Plots" )
                if e then
                    local r=h and h.plot
                    if not r and t4 then
                        r=select( 1 ,t4())
                    end
                    for e,u in ipairs(e:GetChildren())do
                        local w=(r~=nil and u==r)
                        local j=u:FindFirstChild( "TreadmillBottom" )
                        if j and j:IsA( "BasePart" )then
                            if w and(h and h.autoTreadmill )then
                                j.CanTouch = true j.CanCollide = true
                            else
                                j.CanTouch = false j.CanCollide = false
                            end
                        end
                        local k=u:FindFirstChild( "TreadmillUpgrade" )
                        if k then
                            for e,r in ipairs(k:GetDescendants())do
                                if r:IsA( "BasePart" )then
                                    if w and(h and h.autoTreadmill )then
                                        r.CanTouch = true
                                    else
                                        r.CanTouch = false r.CanCollide = false
                                    end
                                end
                            end
                        end
                    end
                end
            end
            )
        end
        n4()r.DescendantAdded :Connect(function(e,...) pcall(function(...)
                local r=(e.Name == "TreadmillBottom" and e:IsA( "BasePart" ))
                local y=(e.Name == "TreadmillUpgrade" and e:IsA( "Model" ))
                if r or y then
                    local y=h and h.plot
                    if not y and t4 then
                        y=select( 1 ,t4())
                    end
                    local w=y and e:IsDescendantOf(y)
                    if w and(h and h.autoTreadmill )then
                        if r then
                            e.CanTouch = true e.CanCollide = true
                        else
                            for e,r in ipairs(e:GetDescendants())do
                                if r:IsA( "BasePart" )then
                                    r.CanTouch = true
                                end
                            end
                        end
                    else
                        if r then
                            e.CanTouch = false e.CanCollide = false
                        else
                            for e,r in ipairs(e:GetDescendants())do
                                if r:IsA( "BasePart" )then
                                    r.CanTouch = false r.CanCollide = false
                                end
                            end
                        end
                    end
                end
            end
            )
        end
        )D4=function(...) h.onTreadmill = false h.teleporting = false h.glidingToTarget = false h.securingEgg = false h.isReturning = false h.delivering = false h.holdingEggForGuard = false h.currentTargetModel =nil h.targetPosition =nil h.stateTime =os.clock ()
            local e=o.Character
            local r=e and e:FindFirstChild( "HumanoidRootPart" )
            if r then
                pcall(function(...) r.Anchored = false r.AssemblyLinearVelocity =Vector3.zero r.AssemblyAngularVelocity =Vector3.zero
                end
                )
            end
            pcall(function(...)
                if C4 then
                    C4()
                end
            end
            )pcall(function(...)
                if Z4 and e then
                    Z4(e)
                end
            end
            )pcall(function(...)
                if u4 and((h.pureTweenFarm or h.autoFarmLoop ))then
                    u4()
                end
            end
            )
        end
        d4=function(e,y,...)
            if e then
                for e,r in ipairs(e:GetDescendants())do
                    if r:IsA( "ProximityPrompt" )then
                        pcall(function(...) r.RequiresLineOfSight = false r.HoldDuration = 0 r.MaxActivationDistance = 50
                            if typeof(fireproximityprompt)== "function" then
                                fireproximityprompt(r, 0 )fireproximityprompt(r)
                            end
                        end
                        )
                    end
                end
            end
            local u=r:FindFirstChild( "AreaEggSlotsClient" )
            if u and y then
                for e,r in ipairs(u:GetChildren())do
                    local u=r:FindFirstChildWhichIsA( "BasePart" )or r.PrimaryPart
                    if u and((u.Position -y)).Magnitude <= 18 then
                        for e,r in ipairs(r:GetDescendants())do
                            if r:IsA( "ProximityPrompt" )then
                                pcall(function(...) r.RequiresLineOfSight = false r.HoldDuration = 0 r.MaxActivationDistance = 50
                                    if typeof(fireproximityprompt)== "function" then
                                        fireproximityprompt(r, 0 )fireproximityprompt(r)
                                    end
                                end
                                )
                            end
                        end
                    end
                end
            end
        end
        b4=function(e,...) h.godmode =e
            local r=o.Character
            if not r then
                return
            end
            local y=r:FindFirstChildOfClass( "Humanoid" )
            if y then
                y:SetStateEnabled(Enum.HumanoidStateType.Dead ,not e)
                if e and y.Health < 100 then
                    y.Health = 100
                end
            end
            for r,y in ipairs(r:GetDescendants())do
                if y:IsA( "BasePart" )then
                    if e then
                        y.CanTouch = false y.CanCollide = false
                    end
                end
            end
            Z4(r)
        end
        local function enableDesyncGodmode()
            b4(true)
        end
        local function disableDesyncGodmode()
            b4(false)
        end

        A4=function(...)
            local e=o.Character
            local y=e and e:FindFirstChildOfClass( "Humanoid" )
            if not e or not y then
                return false
            end
            pcall(function(...) y.BreakJointsOnDeath = false
                local w=y:Clone()w.Parent =e y:Destroy()
                local j=w:FindFirstChildOfClass( "Animator" )
                if not j then
                    j=Instance.new ( "Animator" )j.Parent =w
                end
                r.CurrentCamera.CameraSubject =w
                local k=e:FindFirstChild( "Animate" )
                if k and k:IsA( "LocalScript" )then
                    k.Disabled = true task.defer (function(...) task.wait ( 0.05 )k.Disabled = false
                    end
                    )
                end
                w:SetStateEnabled(Enum.HumanoidStateType.Jumping , true )w:SetStateEnabled(Enum.HumanoidStateType.Freefall , true )w:SetStateEnabled(Enum.HumanoidStateType.Running , true )w:SetStateEnabled(Enum.HumanoidStateType.Climbing , true )w.JumpPower =math.max ( 50 ,w.JumpPower )w.JumpHeight =math.max ( 7.2 ,w.JumpHeight )w:ChangeState(Enum.HumanoidStateType.Running )
            end
            )h.swapped = true
            if h.godmode then
                b4( true )
            end
            z4(e)
            return true
        end
        t4=function(...)
            if h.plot and(h.plot.Parent and(h.pen and(h.origin and h.plotVerified )))then
                return h.plot ,h.pen ,h.origin
            end
            local e=r:FindFirstChild( "Plots" )
            if not e then
                return nil,nil,nil
            end
            local y=o.UserId
            local u=o.Name
            local w=o.DisplayName
            local j=nil
            local k= false
            if v then
                local r,w=pcall(function(...)
                    return v:InvokeServer()
                end
                )
                if r and(type(w)== "table" and type(w.OwnersBySlot )== "table" )then
                    for r,w in pairs(w.OwnersBySlot )do
                        if w==y or tostring(w)==tostring(y)or w==u then
                            j=e:FindFirstChild(tostring(r))
                            if j then
                                k= true
                                break
                            end
                        end
                    end
                end
            end
            if not j and c then
                local r,u=pcall(function(...)
                    return c:InvokeServer()
                end
                )
                if r and type(u)== "table" then
                    for r,u in pairs(u)do
                        if type(u)== "table" and((u.OwnerUserId ==y or tostring(u.OwnerUserId )==tostring(y)))then
                            local y=u.Slot or r j=e:FindFirstChild(tostring(y))or e:FindFirstChild(tostring(r))
                            if j then
                                k= true
                                break
                            end
                        end
                    end
                end
            end
            if not j then
                for e,r in ipairs(e:GetChildren())do
                    local a=r:GetAttribute( "Owner" )or r:GetAttribute( "OwnerUserId" )or r:GetAttribute( "UserId" )or r:GetAttribute( "OwnerId" )or r:GetAttribute( "Player" )
                    if a and((a==y or tostring(a)==tostring(y)or a==u or tostring(a)==u or a==w))then
                        j=r k= true
                        break
                    end
                    for e,a in ipairs({ "Owner" , "OwnerUserId" , "OwnerId" ;
                        "UserId" ;
                        "Player" ;
                        "PlayerName" })do
                        local o=r:FindFirstChild(a)
                        if o and((o.Value ==y or tostring(o.Value )==tostring(y)or o.Value ==u or o.Value ==w))then
                            j=r k= true
                            break
                        end
                    end
                    if j then
                        break
                    end
                end
            end
            if not j then
                for e,r in ipairs(e:GetChildren())do
                    for e,y in ipairs(r:GetDescendants())do
                        if y:IsA( "TextLabel" )and y.Text ~= "" then
                            local e=string.lower (y.Text )
                            if string.find (e,string.lower (u), 1 , true )or(w and string.find (e,string.lower (w), 1 , true ))then
                                j=r k= true
                                break
                            end
                        end
                    end
                    if j then
                        break
                    end
                end
            end
            if not j then
                local r=o.Character
                local y=r and r:FindFirstChild( "HumanoidRootPart" )
                if y and y.Position.X <=(E+ 30 )then
                    local r=nil
                    local u= 999999
                    for e,w in ipairs(e:GetChildren())do
                        local j=w:FindFirstChild( "CenterPoint" )or w.PrimaryPart or w:FindFirstChildWhichIsA( "BasePart" )
                        if j then
                            local e=((y.Position -j.Position )).Magnitude
                            if e<u then
                                u=e r=w
                            end
                        end
                    end
                    if r and u< 160 then
                        j=r
                    end
                end
            end
            if not j then
                j=e:FindFirstChild( "2" )or e:FindFirstChild( "1" )or(e:GetChildren())[ 1 ]
            end
            if not j then
                return nil,nil,nil
            end
            h.plot =j h.plotVerified =k h.origin =j:FindFirstChild( "CenterPoint" )
            local a=j:FindFirstChild( "ToUpdate" )h.pen =(a and a:FindFirstChild( "PetArea" ))or j:FindFirstChild( "PetArea" )h.tread =j:FindFirstChild( "TreadmillBottom" )
            if not h.pen and a then
                for e,r in ipairs(a:GetChildren())do
                    if r:IsA( "BasePart" )and string.find (string.lower (r.Name ), "pet" )then
                        h.pen =r
                        break
                    end
                end
            end
            if not h.origin then
                h.origin =j:FindFirstChild( "CenterPoint" )or h.pen or j.PrimaryPart
            end
            if not h.pen then
                h.pen =h.origin
            end
            return h.plot ,h.pen ,h.origin
        end
        s4=function(...)
            local e,r,y=t4()
            if r then
                return r.Position +Vector3.new ( 0 , 3.5 , 0 )
            end
            if y then
                return y.Position +Vector3.new ( 0 , 3.5 , 0 )
            end
            return Vector3.new ( 464.7 , 71.7 , -304 )
        end
        p4=function(e,...)
            local r,y,u=t4()
            if not y then
                return nil
            end
            local w=y.Size
            local j=math.max ( 4 ,w.X / 2 - 5 )
            local k=math.max ( 4 ,w.Z / 2 - 5 )
            for r= 1 , 60 , 1 do
                local u=math.random (-math.floor (j),math.floor (j))
                local o=math.random (-math.floor (k),math.floor (k))
                local V=y.CFrame *CFrame.new (u,w.Y / 2 + 1 ,o)
                local H= true
                for e,r in ipairs(e)do
                    if((r-V.Position )).Magnitude < 5.5 then
                        H= false
                        break
                    end
                end
                if H then
                    return V
                end
            end
            return y.CFrame *CFrame.new (math.random ( -8 , 8 ),w.Y / 2 + 1 ,math.random ( -8 , 8 ))
        end
        B4=function(...)
            local e,r,y=t4()
            if not y or not K then
                return 0
            end
            local u= 0
            local w={}
            if c then
                local e,r=pcall(function(...)
                    return c:InvokeServer()
                end
                )
                if e and type(r)== "table" then
                    local e={}
                    for r,y in pairs(r)do
                        if type(y)== "table" and y.OwnerUserId ==o.UserId then
                            for r,y in pairs(y.Records or{})do
                                e[r]=y
                            end
                        end
                    end
                    for e,r in pairs(e)do
                        if r.Placement and r.Placement.LocalCFrame then
                            w[#w+ 1 ]=((y.CFrame *r.Placement.LocalCFrame )).Position
                        else
                            local r=p4(w)
                            if r then
                                local j=y.CFrame :ToObjectSpace(r)
                                local k,a=pcall(function(...)
                                    return K:InvokeServer({[ "Uid" ]=e;
                                    [ "LocalCFrame" ]=j})
                                end
                                )
                                if k and a then
                                    u=u+ 1 w[#w+ 1 ]=r.Position
                                end
                            end
                        end
                    end
                end
            end
            local j={}
            local k=o.Character
            if k then
                for e,r in ipairs(k:GetChildren())do
                    if m(r)then
                        table.insert (j,r)
                    end
                end
            end
            local a=o:FindFirstChild( "Backpack" )
            if a then
                for e,r in ipairs(a:GetChildren())do
                    if m(r)then
                        table.insert (j,r)
                    end
                end
            end
            for e,r in ipairs(j)do
                if not h.alive then
                    break
                end
                local j=r:GetAttribute( "UID" )or r:GetAttribute( "EggUid" )or r.Name
                local k=p4(w)
                if k then
                    local e=y.CFrame :ToObjectSpace(k)
                    local r,a=pcall(function(...)
                        return K:InvokeServer({[ "Uid" ]=j,[ "LocalCFrame" ]=e})
                    end
                    )
                    if r and a~= false then
                        u=u+ 1 w[#w+ 1 ]=k.Position H(string.format ( "[PlaceEgg] Placed egg %s from inventory" ,tostring(j)))
                    end
                    task.wait ( 0.04 )
                end
            end
            return u
        end
        J4=function(e,...)
            if(not e and not h.autoHatch )or not g or not Q or not c then
                return 0
            end
            if h.isHatching then
                return 0
            end
            h.isHatching = true
            local y,u=pcall(function(...)
                return c:InvokeServer()
            end
            )
            if not y or type(u)~= "table" then
                return 0
            end
            local w={}
            for e,r in pairs(u)do
                if type(r)== "table" and r.OwnerUserId ==o.UserId then
                    for e,r in pairs(r.Records or{})do
                        w[e]=r
                    end
                end
            end
            local j={}
            local k=r:GetServerTimeNow()
            for e,r in pairs(w)do
                if not h.alive then
                    break
                end
                if r.Placement then
                    local y=nil
                    if s then
                        local r=s.IsReadyToHatch or s.IsLocalEggReady
                        if r then
                            local u,w=pcall(r,e)
                            if u and type(w)== "boolean" then
                                y=w
                            end
                        end
                    end
                    if y==nil then
                        local e=r.Placement.PlacedAt or r.Placement.Time or 0
                        local u= 30
                        if p and(p.Assets and p.Assets [r.AssetCategory ])then
                            local e=p.Assets [r.AssetCategory ]u=(e and(e.Egg and e.Egg.GrowthTime ))or 30
                        end
                        local w=u/math.max ( 0.01 ,r.GrowthSpeedMultiplier or 1 )y=(k-e)>=w
                    end
                    if y then
                        table.insert (j,{[ "uid" ]=e;
                        [ "category" ]=r.AssetCategory or "Egg" })
                    end
                end
            end
            if#j== 0 then
                h.isHatching = false
                return 0
            end
            H(string.format ( "[AutoHatch] Found %d eggs ready to hatch! Starting hatch sequence..." ,#j))h.statusText =string.format ( "[Hatch] Hatching %d ready eggs..." ,#j)
            local a= 0
            for e,r in ipairs(j)do
                task.spawn (function(...)
                    local e,y=pcall(function(...)
                        if g:IsA( "RemoteFunction" )then
                            return g:InvokeServer(r.uid )
                        else
                            g:FireServer(r.uid )
                            return true
                        end
                    end
                    )
                    if e and y~= false then
                        task.wait ( 0.9 )
                        local e,y=pcall(function(...)
                            if Q:IsA( "RemoteFunction" )then
                                return Q:InvokeServer(r.uid )
                            else
                                Q:FireServer(r.uid )
                                return true
                            end
                        end
                        )
                        if e and y~= false then
                            a=a+ 1 h.hatched =((h.hatched or 0 ))+ 1 H(string.format ( "[+] [AutoHatch] Hatched %s (UID: %s) -> Total Hatched: %d" ,r.category ,tostring(r.uid ),h.hatched ))
                        end
                    end
                end
                )task.wait ( 0.04 )
            end
            task.wait ( 0.95 )h.isHatching = false H(string.format ( "[AutoHatch] Finished! Hatched %d eggs." ,a))
            return a
        end
        i4=function(...)
            local e={}
            local y=r:FindFirstChild( "__DEBRIS" )
            if y then
                for r,y in ipairs(y:GetChildren())do
                    local u=y:FindFirstChild( "Hitbox" )
                    if u and u:IsA( "BasePart" )then
                        table.insert (e,u)
                    elseif y:IsA( "BasePart" )and string.find (y.Name :lower(), "hitbox" )then
                        table.insert (e,y)
                    end
                end
            end
            local u=r:FindFirstChild( "BossArenaTeleport" )
            if u then
                local r=u:FindFirstChild( "Hitbox" )or u:FindFirstChildWhichIsA( "BasePart" )or(u:IsA( "BasePart" )and u)
                if r and r:IsA( "BasePart" )then
                    table.insert (e,r)
                end
            end
            return e
        end
        g4=function(e,r,u,...)
            local w=o.Character
            local j=w and w:FindFirstChild( "HumanoidRootPart" )
            local k=w and w:FindFirstChildOfClass( "Humanoid" )
            if not j then
                return false
            end
            if k then
                k.AutoRotate = false
            end
            local a=s4()e=math.max ( 100 ,e or h.glideSpeed or 600 )
            local V=h.laneZ or L h.isReturning = true h.stateTime =os.clock ()V4(a, 20 )j.AssemblyLinearVelocity =Vector3.zero j.AssemblyAngularVelocity =Vector3.zero
            local H=o4()
            local t=math.max (e,H)
            local s=os.clock ()+ 25
            while h.alive and(h.isReturning and os.clock ()<s)do
                if r and O4~=r then
                    if k then
                        k.AutoRotate = true
                    end
                    h.isReturning = false
                    return false
                end
                if not u and(not h.pureTweenFarm and not h.autoFarmLoop )then
                    if k then
                        k.AutoRotate = true
                    end
                    h.isReturning = false
                    return false
                end
                local e=j.Position
                local w=((a-e)).Magnitude
                if(e.X <=(a.X + 3 )and math.abs (e.Z -a.Z )<= 8 )or w<= 6 then
                    break
                end
                local o=y.Heartbeat :Wait()e=j.Position
                local H=t
                if e.X <=b and e.X >E then
                    local r=math.clamp (((e.X -E))/((b-E)), 0 , 1 )H=A+(((t-A))*r)
                elseif e.X <=E then
                    H=A
                end
                local s=a.Z
                if e.X > 540 then
                    s=V
                end
                local B=math.sign (a.X -e.X )
                local J=B*math.min (math.abs (a.X -e.X ),H*o)
                local K=e.X +J
                local c=math.sign (a.Y -e.Y )
                local v=c*math.min (math.abs (a.Y -e.Y ),(H*o)* 0.5 )
                local i=e.Y +v
                local R=s-e.Z
                local g=math.sign (R)*math.min (math.abs (R),H*o)
                local Q=e.Z +g
                local P=i4()
                local N= false
                if e.X >E then
                    for e,r in ipairs(P)do
                        local y=r.Position
                        local u=((Vector3.new (K,i,Q)-y)).Magnitude
                        local w=math.abs (K-y.X )
                        local j=math.abs (Q-y.Z )
                        if u< 22 or(w< 18 and j< 14 )then
                            N= true
                            local e=y.Y + 16
                            if i<e then
                                i=math.min (i+((H*o)* 1.5 ),e)
                            end
                            break
                        end
                    end
                end
                local U=Vector3.new (K,i,Q)
                local l=((U-e)).Magnitude > 0.05 and((U-e)).Unit or j.CFrame.LookVector j.CFrame =CFrame.lookAt (U,U+l)j.AssemblyLinearVelocity =Vector3.zero j.AssemblyAngularVelocity =Vector3.zero
                if N then
                    h.statusText =string.format ( "Tweening Home (Z: %.0f) [DODGING TRAP!]" ,Q)
                else
                    h.statusText =string.format ( "Tweening Home (%.0f studs | Z: %.0f | Spd: %.0f)" ,w,Q,H)
                end
            end
            j.CFrame =CFrame.new (a)j.AssemblyLinearVelocity =Vector3.zero j.AssemblyAngularVelocity =Vector3.zero
            if k then
                k.AutoRotate = true
            end
            u4()h.isReturning = false h.delivering = false h.statusText = "Arrived at Base PetArea!"
            return true
        end
        v4=function(e,r,y,...)
            local u=o.Character
            local w=u and u:FindFirstChild( "HumanoidRootPart" )
            local j=u and u:FindFirstChildOfClass( "Humanoid" )
            if not w or not j then
                return
            end
            local k=s4()
            local a=((w.Position -k)).Magnitude
            if a> 8 then
                h.statusText = "[Place] Tweening back to base plot..." g4(e or h.glideSpeed or 600 ,r, true )
            end
            V4(k, 15 )w.CFrame =CFrame.new (k)w.AssemblyLinearVelocity =Vector3.zero h.statusText = "[Place] Placing All Eggs to Stand..."
            local V=os.clock ()+ 3
            while y4()> 0 and(os.clock ()<V and h.alive )do
                B4()task.wait ( 0.06 )
            end
            h.statusText = "[Place] Hatching ready eggs..." J4( true )u4()h.isReturning = false h.delivering = false h.currentTargetModel =nil h.targetPosition =nil
            local H=y4()h.statusText =string.format ( "Placed & Hatched (Left: %d)! Hands Free." ,H)
        end
        local uk= 5 K4=function(e,...)
            if h.isBatchPlacing then
                return
            end
            h.isBatchPlacing = true H(string.format ( "[AutoPlace] %d steals done! Batch placing (%s mode)..." ,uk,tostring(e)))
            local r=O4 h.pureTweenFarm =(e== "TWEEN" )h.autoFarmLoop =(e== "WARP" )
            local y=o.Character
            local u=y and y:FindFirstChild( "HumanoidRootPart" )
            local w=y and y:FindFirstChildOfClass( "Humanoid" )
            local j=s4()
            local k=u and((u.Position -j)).Magnitude or 999
            if k> 8 then
                h.statusText = "[AutoPlace] Tweening home to base plot..." g4(h.glideSpeed or 600 ,r, true )
            end
            if u then
                V4(j, 20 )u.CFrame =CFrame.new (j)u.AssemblyLinearVelocity =Vector3.zero u.AssemblyAngularVelocity =Vector3.zero
                if w then
                    w.AutoRotate = true
                end
            end
            task.spawn (function(...) pcall(B4)pcall(J4, true )
            end
            )u4()h.isReturning = false h.delivering = false h.glidingToTarget = false h.securingEgg = false h.teleporting = false h.currentTargetModel =nil h.targetPosition =nil
            for e= 5 , 1 , -1 do
                if not h.alive then
                    break
                end
                h.statusText =string.format ( "[AutoPlace] At Base: Resuming in %ds..." ,e)task.wait ( 1 )
            end
            h.isBatchPlacing = false
            if h.alive and O4==r then
                H(string.format ( "[AutoPlace] Done! Continuing %s farm." ,e))h.statusText =string.format ( "[AutoPlace] Resuming %s farm..." ,e)
                if e== "TWEEN" then
                    h.pureTweenFarm = true h.autoFarmLoop = false
                elseif e== "WARP" then
                    h.autoFarmLoop = true h.pureTweenFarm = false
                end
                Y4=e
            end
        end
        c4=function(e,...)
            if not h.autoPlaceEvery5 then
                return false
            end
            h.batchStealCount =((h.batchStealCount or 0 ))+ 1 H(string.format ( "[AutoPlace] Steal trip %d / %d completed successfully." ,h.batchStealCount ,uk))
            if h.batchStealCount >=uk then
                h.batchStealCount = 0 task.spawn (function(...) K4(e)
                end
                )
                return true
            end
            return false
        end
        local function wk(e,r,u,w,...)
            local j=o.Character
            local k=j and j:FindFirstChild( "HumanoidRootPart" )
            local a=j and j:FindFirstChildOfClass( "Humanoid" )
            if not k then
                return false
            end
            if a then
                a.AutoRotate = false
            end
            r=math.max ( 60 ,r or h.glideSpeed or 350 )
            local V=e.Position V4(V, 14 )pcall(function(...) o:RequestStreamAroundAsync(V)
            end
            )k.AssemblyLinearVelocity =Vector3.zero k.AssemblyAngularVelocity =Vector3.zero
            local H=h.laneZ or L h.glidingToTarget = true h.stateTime =os.clock ()
            local t= 0
            local s=os.clock ()+ 15
            while h.alive and(h.glidingToTarget and os.clock ()<s)do
                if w and O4~=w then
                    if a then
                        a.AutoRotate = true
                    end
                    h.glidingToTarget = false
                    return false
                end
                if not h.pureTweenFarm and(not h.autoFarmLoop and not h.teleporting )then
                    if a then
                        a.AutoRotate = true
                    end
                    h.glidingToTarget = false
                    return false
                end
                local e=k.Position
                local j=((V-e)).Magnitude
                local o=((Vector2.new (e.X ,e.Z )-Vector2.new (V.X ,V.Z ))).Magnitude
                local s=math.abs (e.Y -V.Y )
                if j<= 6 or(o<= 3.5 and s<= 6 )then
                    break
                end
                local B=y.Heartbeat :Wait()e=k.Position j=((V-e)).Magnitude o=((Vector2.new (e.X ,e.Z )-Vector2.new (V.X ,V.Z ))).Magnitude
                local J=math.abs (e.X -V.X )
                if u and(os.clock ()-t> 0.5 )then
                    t=os.clock ()
                    local e,r=k4(u)
                    if not e and r== "CarriedByOther" then
                        if a then
                            a.AutoRotate = true
                        end
                        h.glidingToTarget = false
                        return false
                    end
                end
                local K=V.Z
                if J> 40 then
                    K=H
                end
                local c=math.sign (V.X -e.X )
                local v=c*math.min (math.abs (V.X -e.X ),r*B)
                local i=e.X +v
                local R=(o<= 25 )and 1.2 or 0.5
                local g=math.sign (V.Y -e.Y )
                local Q=g*math.min (math.abs (V.Y -e.Y ),(r*B)*R)
                local P=e.Y +Q
                local N=K-e.Z
                local U=math.sign (N)*math.min (math.abs (N),r*B)
                local l=e.Z +U
                local D= false
                if o> 25 then
                    local e=i4()
                    for e,y in ipairs(e)do
                        local u=y.Position
                        local w=((Vector3.new (i,P,l)-u)).Magnitude
                        local j=math.abs (i-u.X )
                        local k=math.abs (l-u.Z )
                        if w< 22 or(j< 18 and k< 14 )then
                            D= true
                            local e=u.Y + 16
                            if P<e then
                                P=math.min (P+((r*B)* 1.5 ),e)
                            end
                            break
                        end
                    end
                end
                local C=Vector3.new (i,P,l)
                local q=((C-e)).Magnitude > 0.05 and((C-e)).Unit or k.CFrame.LookVector k.CFrame =CFrame.lookAt (C,C+q)k.AssemblyLinearVelocity =Vector3.zero k.AssemblyAngularVelocity =Vector3.zero
                if D then
                    h.statusText =string.format ( "Gliding Out (Z: %.0f) [DODGING TRAP!]" ,l)
                else
                    h.statusText =string.format ( "Gliding -> Egg (%.0f studs | H: %.0f)" ,j,o)
                end
            end
            k.CFrame =e*CFrame.new ( 0 , 0.4 , 0 )k.AssemblyLinearVelocity =Vector3.zero k.AssemblyAngularVelocity =Vector3.zero
            if a then
                a.AutoRotate = true
            end
            h.glidingToTarget = false
            return true
        end
        R4=function(e,r,y,u,...)
            local w=o.Character
            local j=w and w:FindFirstChild( "HumanoidRootPart" )
            if j then
                local w=j.Position.X
                local a=e.Position.X
                if w<= 535 and a> 510 then
                    local e=CFrame.new ( 500 , 70 , -364 )
                    local a=((j.Position -e.Position )).Magnitude
                    if a> 5 then
                        h.statusText = "[AutoSteal] Exiting Base -> Waypoint (500, 70, -364)..." H(string.format ( "[AutoSteal] Leaving base (X=%.1f): Gliding to waypoint (500, 70, -364) first (dist=%.1f studs)..." ,w,a))
                        local j=wk(e,r,y,u)
                        if not j then
                            return false
                        end
                        task.wait ( 0.04 )
                    end
                end
            end
            return wk(e,r,y,u)
        end
        Q4=function(e,r,...)
            local u=o.Character
            local w=u and u:FindFirstChild( "HumanoidRootPart" )
            local j=u and u:FindFirstChildOfClass( "Humanoid" )
            if not w then
                return false
            end
            if j then
                j.AutoRotate = false
            end
            local k=h.laneZ or L
            local a=Vector3.new (E- 10 , 70 ,k)e=math.max ( 100 ,e or h.glideSpeed or 350 )h.isReturning = true h.stateTime =os.clock ()V4(Vector3.new (E, 70 ,k), 20 )pcall(u4)w.AssemblyLinearVelocity =Vector3.zero w.AssemblyAngularVelocity =Vector3.zero
            local V=o4()
            local H=math.max (e,V)
            local s=os.clock ()+ 15
            while h.alive and(h.isReturning and os.clock ()<s)do
                if r and O4~=r then
                    t( "[Return] Aborted by session switch!" )
                    if j then
                        j.AutoRotate = true
                    end
                    h.isReturning = false
                    return false
                end
                if not h.pureTweenFarm and not h.autoFarmLoop then
                    t( "[Return] Aborted (all farms disabled)" )
                    if j then
                        j.AutoRotate = true
                    end
                    h.isReturning = false
                    return false
                end
                local e=w.Position
                local o=((a-e)).Magnitude
                if e.X <=(E+ 10 )or o<= 6 then
                    u4()
                    break
                end
                if u then
                    for e,r in ipairs(u:GetChildren())do
                        if r:IsA( "Tool" )then
                            pcall(u4)
                            break
                        end
                    end
                end
                local V=y.Heartbeat :Wait()e=w.Position
                local s=H
                if e.X <=b and e.X >E then
                    local r=math.clamp (((e.X -E))/((b-E)), 0 , 1 )s=A+(((H-A))*r)
                elseif e.X <=E then
                    s=A
                end
                local B=math.sign (a.X -e.X )
                local J=B*math.min (math.abs (a.X -e.X ),s*V)
                local K=e.X +J
                local c=math.sign (a.Y -e.Y )
                local v=c*math.min (math.abs (a.Y -e.Y ),(s*V)* 0.5 )
                local i=e.Y +v
                local R=k-e.Z
                local g=math.sign (R)*math.min (math.abs (R),s*V)
                local Q=e.Z +g
                local P=i4()
                local N= false
                for e,r in ipairs(P)do
                    local y=r.Position
                    local u=((Vector3.new (K,i,Q)-y)).Magnitude
                    local w=math.abs (K-y.X )
                    local j=math.abs (Q-y.Z )
                    if u< 22 or(w< 18 and j< 14 )then
                        N= true
                        local e=y.Y + 16
                        if i<e then
                            i=math.min (i+((s*V)* 1.5 ),e)
                        end
                        break
                    end
                end
                local U=Vector3.new (K,i,Q)
                local l=((U-e)).Magnitude > 0.05 and((U-e)).Unit or w.CFrame.LookVector w.CFrame =CFrame.lookAt (U,U+l)w.AssemblyLinearVelocity =Vector3.zero w.AssemblyAngularVelocity =Vector3.zero
                if N then
                    h.statusText =string.format ( "Tweening Safe Line (Z: %.0f) [DODGING!]" ,Q)
                else
                    h.statusText =string.format ( "Tweening to Safe Line (%.0f studs | X: %.0f)" ,o,e.X )
                end
            end
            w.CFrame =CFrame.new (E,math.max ( 68 ,w.Position.Y ),k)w.AssemblyLinearVelocity =Vector3.zero w.AssemblyAngularVelocity =Vector3.zero
            if j then
                j.AutoRotate = true
            end
            u4()h.isReturning = false h.delivering = false
            if h then
                h.onTreadmill = false
            end
            h.statusText = "Arrived at Safe Line (X=525)! Hands Free."
            return true
        end
        local function jk(e,...)
            if not e then
                return nil
            end
            local r=e:FindFirstChild( "TreadmillBottom" )
            if r and r:IsA( "BasePart" )then
                return r
            end
            r=e:FindFirstChild( "TreadmillBottom" , true )
            if r and r:IsA( "BasePart" )then
                return r
            end
            local y=e:FindFirstChild( "TreadmillUpgrade" , true )
            if y then
                for e,r in ipairs({ "TreadmillBottom" , "Belt" , "RunArea" ;
                    "Run" ;
                    "Platform" ;
                    "Pad" , "Floor" ;
                    "Base" })do
                    local w=y:FindFirstChild(r, true )
                    if w and w:IsA( "BasePart" )then
                        return w
                    end
                end
                local e=nil
                local r= 999999
                for y,w in ipairs(y:GetDescendants())do
                    if w:IsA( "BasePart" )and(w.Size.X >= 1.2 and w.Size.Z >= 1.2 )then
                        if w.Position.Y <r then
                            r=w.Position.Y e=w
                        end
                    end
                end
                if e then
                    return e
                end
                if y.PrimaryPart then
                    return y.PrimaryPart
                end
                local w=y:FindFirstChildWhichIsA( "BasePart" , true )
                if w then
                    return w
                end
            end
            for e,r in ipairs(e:GetDescendants())do
                if r:IsA( "BasePart" )and string.find (string.lower (r.Name ), "treadmill" )then
                    return r
                end
            end
            return nil
        end
        I4=function(...)
            local e=t4()
            if h.tread and h.tread.Parent then
                return h.tread
            end
            local y=nil
            if e then
                y=jk(e)
            end
            if not y then
                local w=r:FindFirstChild( "Plots" )
                if w then
                    local r=string.lower (o.Name )
                    local j=o.DisplayName and string.lower (o.DisplayName )
                    for e,w in ipairs(w:GetChildren())do
                        local k=jk(w)
                        if k then
                            local e= false
                            for y,w in ipairs(w:GetDescendants())do
                                if w:IsA( "TextLabel" )and w.Text ~= "" then
                                    local y=string.lower (w.Text )
                                    if string.find (y,r, 1 , true )or(j and string.find (y,j, 1 , true ))then
                                        e= true
                                        break
                                    end
                                end
                            end
                            if e then
                                h.plot =w h.plotVerified = true y=k
                                break
                            end
                        end
                    end
                    if not y and e then
                        y=jk(e)
                    end
                end
            end
            h.tread =y
            return y
        end
        f4=function(e,...)
            local r=o.Character
            local u=r and r:FindFirstChild( "HumanoidRootPart" )
            local w=r and r:FindFirstChildOfClass( "Humanoid" )
            if not u or not w then
                return false
            end
            if w.PlatformStand then
                w.PlatformStand = false
            end
            if w.Sit then
                w.Sit = false
            end
            w:ChangeState(Enum.HumanoidStateType.Running )
            local j=t4()
            local k=I4()
            if not k then
                t( "[AutoTreadmill] Treadmill part not found! Retrying next loop..." )
                return false
            end
            pcall(function(...)
                for r,y in ipairs(r:GetChildren())do
                    if y:IsA( "BasePart" )and y.Name ~= "HumanoidRootPart" then
                        y.CanCollide = false
                    end
                end
            end
            )pcall(function(...) k.CanTouch = true k.CanCollide = true
                local e=j and j:FindFirstChild( "TreadmillUpgrade" , true )
                if e then
                    for e,y in ipairs(e:GetDescendants())do
                        if y:IsA( "BasePart" )then
                            y.CanTouch = true y.CanCollide = true
                        end
                    end
                end
                if k.Parent and k.Parent :IsA( "Model" )then
                    for e,y in ipairs(k.Parent :GetDescendants())do
                        if y:IsA( "BasePart" )then
                            y.CanTouch = true y.CanCollide = true
                        end
                    end
                end
            end
            )
            local a=k.Position +Vector3.new ( 0 , 1.8 , 0 )
            if u.Position.X > 535 then
                h.statusText = "[AutoTreadmill] Returning along highway to base..." Q4(h.glideSpeed ,e)
                if e and O4~=e then
                    return false
                end
                if u.Position.X > 535 then
                    if u.Position.X <= 560 then
                        u.CFrame =CFrame.new (E, 70 ,h.laneZ or L)
                    else
                        return false
                    end
                end
            end
            if e and O4~=e then
                return false
            end
            local V=((Vector2.new (u.Position.X ,u.Position.Z )-Vector2.new (a.X ,a.Z ))).Magnitude
            if V> 4 then
                h.statusText = "[AutoTreadmill] Elevated flyover to base plot..."
                local r=math.max ( 250 ,h.glideSpeed or 400 )
                local j=os.clock ()
                while h.alive and(((Vector2.new (u.Position.X ,u.Position.Z )-Vector2.new (a.X ,a.Z ))).Magnitude > 4 and(os.clock ()-j< 4 ))do
                    if e and O4~=e then
                        return false
                    end
                    local j=y.Heartbeat :Wait()
                    local k=u.Position
                    local o=Vector3.new (a.X , 70 ,a.Z )
                    local V=(o-k)
                    local H=V.Unit *math.min (V.Magnitude ,r*j)
                    local t=k+H u.CFrame =CFrame.lookAt (t,t+((V.Magnitude > 0.05 and V.Unit or u.CFrame.LookVector )))u.AssemblyLinearVelocity =Vector3.zero u.AssemblyAngularVelocity =Vector3.zero
                    if w then
                        if w.PlatformStand then
                            w.PlatformStand = false
                        end
                        if w.Sit then
                            w.Sit = false
                        end
                        w:ChangeState(Enum.HumanoidStateType.Running )
                    end
                end
            end
            if e and O4~=e then
                return false
            end
            local H=os.clock ()
            while h.alive and(math.abs (u.Position.Y -a.Y )> 2 and(os.clock ()-H< 1.5 ))do
                if e and O4~=e then
                    return false
                end
                local r=y.Heartbeat :Wait()
                local w=u.Position
                local j=a
                local k=(j-w)
                local o=k.Unit *math.min (k.Magnitude , 150 *r)
                local V=w+o u.CFrame =CFrame.new (V)u.AssemblyLinearVelocity =Vector3.zero u.AssemblyAngularVelocity =Vector3.zero
            end
            u.CFrame =CFrame.new (a)u.AssemblyLinearVelocity =Vector3.zero u.AssemblyAngularVelocity =Vector3.zero
            local s=((u.Position -a)).Magnitude
            if s<= 6 then
                pcall(function(...)
                    if typeof(firetouchinterest)== "function" then
                        firetouchinterest(u,k, 0 )task.wait ( 0.02 )firetouchinterest(u,k, 1 )
                    end
                end
                )pcall(function(...)
                    for r,y in ipairs(k:GetDescendants())do
                        if y:IsA( "ProximityPrompt" )and y.Enabled then
                            if typeof(fireproximityprompt)== "function" then
                                fireproximityprompt(y)
                            end
                        end
                    end
                    if k.Parent then
                        for r,y in ipairs(k.Parent :GetDescendants())do
                            if y:IsA( "ProximityPrompt" )and y.Enabled then
                                if typeof(fireproximityprompt)== "function" then
                                    fireproximityprompt(y)
                                end
                            end
                        end
                    end
                end
                )
                if l then
                    pcall(function(...) l:InvokeServer()
                    end
                    )
                end
                h.onTreadmill = true h.lastTreadmillMount =os.clock ()h.statusText = "[AutoTreadmill] Running on treadmill (Waiting for eggs...)"
                return true
            else
                h.onTreadmill = false t(string.format ( "[AutoTreadmill] Not yet at treadmill pad (dist=%.1f studs). Will retry!" ,s))
                return false
            end
        end
        local function kk(...)
            if not h or not h.hideNotEnoughMoney then
                return
            end
            local e=o:FindFirstChild( "PlayerGui" )
            if not e then
                return
            end
            pcall(function(...)
                for e,y in ipairs(e:GetDescendants())do
                    if y:IsA( "TextLabel" )and y.Visible then
                        local e=(tostring(y.Text or "" )):lower()
                        if e:find( "not enough money" )or e:find( "not enough cash" )or(e:find( "not enough" )and((e:find( "money" )or e:find( "cash" )or e:find( "coin" )or e:find( "fund" ))))then
                            y.Visible = false y.TextTransparency = 1 y.TextStrokeTransparency = 1
                            local e=y.Parent
                            if e and(((e:IsA( "Frame" )or e:IsA( "CanvasGroup" )))and#e:GetChildren()<= 3 )then
                                e.Visible = false
                            end
                        end
                    end
                end
            end
            )
        end
        local function ak(...)
            local e=o:FindFirstChild( "PlayerGui" )
            if not e then
                return
            end
            local function r(e,...)
                if e:IsA( "TextLabel" )then
                    local function y(...)
                        if not h or not h.hideNotEnoughMoney then
                            return
                        end
                        local y=(tostring(e.Text or "" )):lower()
                        if y:find( "not enough money" )or y:find( "not enough cash" )or(y:find( "not enough" )and((y:find( "money" )or y:find( "cash" )or y:find( "coin" )or y:find( "fund" ))))then
                            e.Visible = false e.TextTransparency = 1 e.TextStrokeTransparency = 1
                            local r=e.Parent
                            if r and(((r:IsA( "Frame" )or r:IsA( "CanvasGroup" )))and#r:GetChildren()<= 3 )then
                                r.Visible = false
                            end
                        end
                    end
                    y();
                    (e:GetPropertyChangedSignal( "Text" )):Connect(y);
                    (e:GetPropertyChangedSignal( "Visible" )):Connect(function(...)
                        if e.Visible then
                            y()
                        end
                    end
                    )
                end
            end
            pcall(function(...)
                for e,y in ipairs(e:GetDescendants())do
                    task.spawn (r,y)
                end
                e.DescendantAdded :Connect(r)
            end
            )task.spawn (function(...)
                while h and h.alive do
                    if h.hideNotEnoughMoney then
                        kk()
                    end
                    task.wait ( 0.25 )
                end
            end
            )
        end
        task.spawn (ak)
        local function ok(e,...)
            if not e then
                return 0
            end
            local r=(((tostring(e)):gsub( "[$,]" , "" )):gsub( "%s+" , "" )):lower()
            local y=r:match( "[%d%.]+" )
            if not y then
                return 0
            end
            local u=tonumber(y)
            if not u then
                return 0
            end
            if r:find( "sp" )then
                return u* 999999999999999983222784
            elseif r:find( "sx" )then
                return u* 1000000000000000000000
            elseif r:find( "qi" )then
                return u* 1000000000000000000
            elseif r:find( "qa" )or r:find( "q" )then
                return u* 1000000000000000
            elseif r:find( "t" )then
                return u* 1000000000000
            elseif r:find( "b" )then
                return u* 1000000000
            elseif r:find( "m" )then
                return u* 1000000
            elseif r:find( "k" )then
                return u* 1000
            end
            return u
        end
        local function Vk(...)
            local e=o:FindFirstChild( "leaderstats" )
            if e then
                for r,u in ipairs({ "Money" , "Cash" , "Coins" ;
                    "Currency" })do
                    local w=e:FindFirstChild(u)
                    if w then
                        local e=tonumber(w.Value )or ok(w.Value )
                        if e and e> 0 then
                            return e
                        end
                    end
                end
            end
            local r=o:FindFirstChild( "PlayerGui" )
            if r then
                local e=r:FindFirstChild( "HUD" )or r:FindFirstChild( "GameHUD" )or r:FindFirstChild( "MainHUD" )or r:FindFirstChild( "Main" )
                if e then
                    for e,r in ipairs(e:GetDescendants())do
                        if r:IsA( "TextLabel" )and r.Visible then
                            local e=r.Name :lower()
                            if e== "money" or e== "cash" or e== "coins" or e== "currency" or e== "value" then
                                local e=ok(r.Text )
                                if e and e> 0 then
                                    return e
                                end
                            end
                        end
                    end
                end
            end
            return 0
        end
        local function Hk(...)
            local e=h.plot or(t4 and t4())
            if not e then
                return nil
            end
            local r=e:FindFirstChild( "TreadmillUpgrade" , true )
            if not r then
                return nil
            end
            local y=nil
            for e,r in ipairs(r:GetDescendants())do
                if r:IsA( "TextLabel" )or r:IsA( "TextButton" )then
                    local e=tostring(r.Text or "" )
                    local w=e:match( "%$([%d%.,]+%s*[kKmMbBtTqQ]?[aA]?)" )
                    if w then
                        local e=ok(w)
                        if e and e> 0 then
                            if not y or e>y then
                                y=e
                            end
                        end
                    end
                end
            end
            return y
        end
        local tk= 0
        local sk= 10
        local function pk(...)
            if not h.autoUpgradeTreadmill then
                return
            end
            if os.clock ()-tk<sk then
                return
            end
            local e=h.plot or(t4 and t4())
            if not e then
                return
            end
            local r=e:FindFirstChild( "TreadmillUpgrade" , true )
            if not r then
                return
            end
            local y=Vk()
            local u=Hk()
            if u and(u> 0 and y<u)then
                return
            end
            tk=os.clock ()
            if D then
                pcall(function(...) D:InvokeServer()
                end
                )
            end
            local w=o.Character
            local j=w and w:FindFirstChild( "HumanoidRootPart" )pcall(function(...)
                for r,y in ipairs(r:GetDescendants())do
                    if y:IsA( "ProximityPrompt" )and y.Enabled then
                        if typeof(fireproximityprompt)== "function" then
                            fireproximityprompt(y, 0 )fireproximityprompt(y)
                        end
                    end
                    if y:IsA( "GuiButton" )and y.Visible then
                        local r=(y:IsA( "TextButton" )and y.Text )or y.Name
                        local u=string.lower (r)
                        if not string.find (u, "robux" )and(not string.find (u, "r%$" )and((string.find (u, "%$" )or string.find (u, "upgrade" )or string.find (u, "cash" )or(y.BackgroundColor3 and y.BackgroundColor3.G >y.BackgroundColor3.R ))))then
                            if typeof(firesignal)== "function" and y.Activated then
                                firesignal(y.Activated )
                            elseif typeof(firesignal)== "function" and y.MouseButton1Click then
                                firesignal(y.MouseButton1Click )
                            end
                        end
                    end
                    if y:IsA( "BasePart" )and(y.Name :find( "Pad" )and j)then
                        if((j.Position -y.Position )).Magnitude < 10 then
                            if typeof(firetouchinterest)== "function" then
                                firetouchinterest(j,y, 0 )task.wait ( 0.02 )firetouchinterest(j,y, 1 )
                            end
                        end
                    end
                end
            end
            )
        end
        local Bk={{[ "id" ]= "GreyTrail" ,[ "base" ]= "Grey" ,[ "name" ]= "Grey Trail" ;
        [ "price" ]= 100 ;
        [ "mult" ]= 1.5 },{[ "id" ]= "GreenTrail" ;
        [ "base" ]= "Green" ,[ "name" ]= "Green Trail" ;
        [ "price" ]= 5000 ;
        [ "mult" ]= 2 },{[ "id" ]= "BlueTrail" ,[ "base" ]= "Blue" ;
        [ "name" ]= "Blue Trail" ;
        [ "price" ]= 75000 ;
        [ "mult" ]= 2.5 };
        {[ "id" ]= "PurpleTrail" ,[ "base" ]= "Purple" ;
        [ "name" ]= "Purple Trail" ;
        [ "price" ]= 1500000 ;
        [ "mult" ]= 3 },{[ "id" ]= "GoldenTrail" ,[ "base" ]= "Golden" ;
        [ "name" ]= "Golden Trail" ;
        [ "price" ]= 1500000 ;
        [ "mult" ]= 3.5 };
        {[ "id" ]= "RedTrail" ;
        [ "base" ]= "Red" ,[ "name" ]= "Red Trail" ;
        [ "price" ]= 750000000 ,[ "mult" ]= 4 },{[ "id" ]= "GalaxyTrail" ,[ "base" ]= "Galaxy" ,[ "name" ]= "Galaxy Trail" ;
        [ "price" ]= 20000000000 ,[ "mult" ]= 5 },{[ "id" ]= "SecretTrail" ;
        [ "base" ]= "Secret" ;
        [ "name" ]= "Secret Trail" ,[ "price" ]= 500000000000 ,[ "mult" ]= 6 };
        {[ "id" ]= "EternalTrail" ;
        [ "base" ]= "Eternal" ,[ "name" ]= "Eternal Trail" ,[ "price" ]= 12500000000000 ;
        [ "mult" ]= 10 };
        {[ "id" ]= "DivineTrail" ,[ "base" ]= "Divine" ;
        [ "name" ]= "Divine Trail" ,[ "price" ]= 300000000000000 ;
        [ "mult" ]= 14 };
        {[ "id" ]= "MoonbloomTrail" ,[ "base" ]= "Moonbloom" ;
        [ "name" ]= "Moonbloom Trail" ,[ "price" ]= 5000000000000000 ,[ "mult" ]= 20 }}
        local function Jk(...)
            return Bk
        end
        local function Kk(...)
            local e={}
            local r=o:FindFirstChild( "PlayerGui" )
            local y=r and((r:FindFirstChild( "TrailShop" )or r:FindFirstChild( "TrailShop" , true )))
            local u=y and y:FindFirstChild( "ScrollingFrame" , true )
            if u then
                pcall(function(...)
                    for y,u in ipairs(u:GetChildren())do
                        if u:IsA( "GuiObject" )and(not u:IsA( "UIListLayout" )and not u:IsA( "UIPadding" ))then
                            local y=u.Name
                            for u,w in ipairs(u:GetDescendants())do
                                if w:IsA( "GuiButton" )or w:IsA( "TextButton" )then
                                    local u=(w:IsA( "TextButton" )and w.Text :lower())or w.Name :lower()
                                    if u:find( "unequip" )or(u:find( "equip" )and not u:find( "unequip" ))then
                                        e[y]= true e[y:lower()]= true
                                        local u=y:gsub( "Trail" , "" )e[u]= true e[u:lower()]= true
                                    end
                                end
                            end
                        end
                    end
                end
                )
            end
            return e
        end
        local function ck(e,...)
            if not e then
                return false
            end
            pcall(function(...)
                if typeof(firebutton1click)== "function" then
                    firebutton1click(e)
                elseif typeof(firesignal)== "function" and e.Activated then
                    firesignal(e.Activated )
                elseif typeof(firesignal)== "function" and e.MouseButton1Click then
                    firesignal(e.MouseButton1Click )
                end
            end
            )
            return true
        end
        local function vk(...)
            local e=Jk()
            local r=Kk()
            local y=o:FindFirstChild( "PlayerGui" )
            local u=y and((y:FindFirstChild( "TrailShop" )or y:FindFirstChild( "TrailShop" , true )))
            local w=u and u:FindFirstChild( "ScrollingFrame" , true )
            if w then
                for r=#e, 1 , -1 do
                    local y=e[r]
                    local u=w:FindFirstChild(y.id )or w:FindFirstChild(y.base )or w:FindFirstChild(y.name )
                    if not u then
                        for e,r in ipairs(w:GetChildren())do
                            if r:IsA( "GuiObject" )and((r.Name :lower()==y.id :lower()or r.Name :lower()==y.base :lower()or r.Name :lower()==y.name :lower()))then
                                u=r
                                break
                            end
                        end
                    end
                    if u then
                        local e= false
                        local r=nil
                        for y,u in ipairs(u:GetDescendants())do
                            if u:IsA( "GuiButton" )or u:IsA( "TextButton" )then
                                local y=(u:IsA( "TextButton" )and u.Text :lower())or u.Name :lower()
                                if y:find( "unequip" )then
                                    e= true
                                    break
                                elseif y:find( "equip" )and not y:find( "unequip" )then
                                    r=u
                                end
                            end
                        end
                        if e then
                            return true
                        end
                        if r then
                            ck(r)
                            if q then
                                pcall(function(...) q:InvokeServer(y.id )
                                end
                                )
                            end
                            task.wait ( 0.2 )
                            return true
                        end
                    end
                end
            end
            if q then
                for y=#e, 1 , -1 do
                    local u=e[y]
                    local w=r[u.id ]or r[u.id :lower()]or r[u.base ]or r[u.base :lower()]or r[u.name ]or r[u.name :lower()]
                    if w then
                        pcall(function(...) q:InvokeServer(u.id )
                        end
                        )
                        return true
                    end
                end
            end
            return false
        end
        local ik= 0
        local Rk= 8
        local function gk(...)
            if not h.autoBuyTrails then
                return
            end
            vk()
            if os.clock ()-ik<Rk then
                return
            end
            local e=Vk()
            if e<= 0 then
                return
            end
            local r=Jk()
            local y=Kk()
            local u=o:FindFirstChild( "PlayerGui" )
            local w=u and((u:FindFirstChild( "TrailShop" )or u:FindFirstChild( "TrailShop" , true )))
            local j=w and w:FindFirstChild( "ScrollingFrame" , true )
            for u=#r, 1 , -1 do
                local w=r[u]
                local a=y[w.id ]or y[w.id :lower()]or y[w.base ]or y[w.base :lower()]or y[w.name ]or y[w.name :lower()]
                if not a and(w.price > 0 and e>=w.price )then
                    ik=os.clock ()
                    local e= false
                    if j then
                        local r=j:FindFirstChild(w.id )or j:FindFirstChild(w.base )or j:FindFirstChild(w.name )
                        if not r then
                            for e,y in ipairs(j:GetChildren())do
                                if y:IsA( "GuiObject" )and((y.Name :lower()==w.id :lower()or y.Name :lower()==w.base :lower()or y.Name :lower()==w.name :lower()))then
                                    r=y
                                    break
                                end
                            end
                        end
                        if r then
                            for r,y in ipairs(r:GetDescendants())do
                                if y:IsA( "GuiButton" )or y:IsA( "TextButton" )then
                                    local r=(y:IsA( "TextButton" )and y.Text :lower())or y.Name :lower()
                                    if not r:find( "robux" )and(not r:find( "r%$" )and(not r:find( "unequip" )and not r:find( "equip" )))then
                                        if r:find( "%$" )or r:find( "buy" )then
                                            ck(y)e= true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if C then
                        pcall(function(...) C:InvokeServer(w.id )
                        end
                        )e= true
                    end
                    if e then
                        task.wait ( 0.3 )vk()
                        break
                    end
                end
            end
        end
        P4=function(...)
            local e=o.Character
            local y=e and e:FindFirstChild( "HumanoidRootPart" )
            if not y then
                return nil
            end
            local u={}
            local w=r:FindFirstChild( "AreaEggSlotsClient" )
            local j=h4( false )
            if j and#j> 0 then
                for e,r in ipairs(j)do
                    local w=(r.State == "Slot" or r.State == "Dropped" or r.State == 1 )
                    local j=(r.AreaId == "Lake" )or(string.find (string.lower (tostring(r.AreaId )), "lake" )~=nil)or(string.find (string.lower (tostring(r.Uid )), "lake" )~=nil)
                    local k=X4[r.Uid ]and(os.clock ()<X4[r.Uid ])
                    if w and(j and(r.BoundsCFrame and not k))then
                        local e=r.BoundsCFrame.Position
                        local w=((y.Position -e)).Magnitude table.insert (u,{[ "Uid" ]=r.Uid ;
                        [ "Model" ]=nil;
                        [ "Hitbox" ]=nil;
                        [ "CFrame" ]=r.BoundsCFrame ,[ "Position" ]=e,[ "Distance" ]=w;
                        [ "Area" ]= "Lake" })
                    end
                end
            end
            if#u== 0 and(j and#j> 0 )then
                for e,r in ipairs(j)do
                    local w=(r.State == "Slot" or r.State == "Dropped" or r.State == 1 )
                    local j=r.BoundsCFrame and r.BoundsCFrame.Position
                    local k=j and((j.X >= 545 and j.X < 850 ))
                    local o=X4[r.Uid ]and(os.clock ()<X4[r.Uid ])
                    if w and(k and not o)then
                        table.insert (u,{[ "Uid" ]=r.Uid ,[ "Model" ]=nil;
                        [ "Hitbox" ]=nil;
                        [ "CFrame" ]=r.BoundsCFrame ;
                        [ "Position" ]=j;
                        [ "Distance" ]=((y.Position -j)).Magnitude ;
                        [ "Area" ]=r.AreaId or "Field" })
                    end
                end
            end
            if#u== 0 then
                return nil
            end
            table.sort (u,function(e,r,...)
                return e.Distance <r.Distance
            end
            )
            local k=u[ 1 ]
            if k and w then
                for e,r in ipairs(w:GetChildren())do
                    local y=r:FindFirstChildWhichIsA( "BasePart" )or r.PrimaryPart
                    if y and((y.Position -k.Position )).Magnitude <= 8 then
                        k.Model =r
                        break
                    end
                end
            end
            return k
        end
        local Qk=nil
        local Pk=nil
        local Nk= 350
        local function Uk(...)
            local e=r:FindFirstChild( "__OBJECTS" )or r:FindFirstChild( "Objects" )
            local y=e and((e:FindFirstChild( "Areas" )or e:FindFirstChild( "Area" )))
            local u=y and((y:FindFirstChild( "GuardAreas" )or y:FindFirstChild( "Guards" )))
            if u then
                local e=u:FindFirstChild( "Light Dark" )or u:FindFirstChild( "LightDark" )or u:FindFirstChild( "Light_Dark" )or u:FindFirstChild( "Light-Dark" )
                if e then
                    return e
                end
                for e,r in ipairs(u:GetChildren())do
                    local y=string.lower (r.Name )
                    if string.find (y, "light" )and string.find (y, "dark" )then
                        return r
                    end
                end
            end
            if y then
                local e=y:FindFirstChild( "Light Dark" )or y:FindFirstChild( "LightDark" )or y:FindFirstChild( "Light_Dark" )
                if e then
                    return e
                end
                for e,r in ipairs(y:GetChildren())do
                    local y=string.lower (r.Name )
                    if string.find (y, "light" )and string.find (y, "dark" )then
                        return r
                    end
                end
            end
            for e,r in ipairs(r:GetChildren())do
                local y=r.Name
                if y== "__OBJECTS" or y== "Objects" or y== "Areas" or y== "Map" then
                    for e,r in ipairs(r:GetDescendants())do
                        local y=string.lower (r.Name )
                        if(y== "light dark" or y== "lightdark" or(string.find (y, "light" )and string.find (y, "dark" )))then
                            if r:IsA( "BasePart" )or r:IsA( "Model" )or r:IsA( "Folder" )then
                                return r
                            end
                        end
                    end
                end
            end
            return nil
        end
        local function lk(e,...)
            if not e then
                return false
            end
            if Qk then
                local r=((Vector3.new (e.X , 0 ,e.Z )-Vector3.new (Qk.X , 0 ,Qk.Z ))).Magnitude
                if r<=Nk then
                    return true
                end
            end
            local r=Uk()
            if not r then
                if e.X >= 5200 then
                    return true
                end
                return false
            end
            local y= false pcall(function(...)
                local u,w=nil,nil
                if r:IsA( "BasePart" )then
                    u=r.CFrame w=r.Size
                elseif r:IsA( "Model" )then
                    u,w=r:GetBoundingBox()
                else
                    local e,y=nil,nil
                    for r,u in ipairs(r:GetChildren())do
                        if u:IsA( "BasePart" )then
                            local r=u.CFrame
                            local w=u.Size / 2
                            local k=r.Position -w
                            local a=r.Position +w
                            if not e then
                                e=k y=a
                            else
                                e=Vector3.new (math.min (e.X ,k.X ),math.min (e.Y ,k.Y ),math.min (e.Z ,k.Z ))y=Vector3.new (math.max (y.X ,a.X ),math.max (y.Y ,a.Y ),math.max (y.Z ,a.Z ))
                            end
                        end
                    end
                    if e and y then
                        u=CFrame.new (((e+y))/ 2 )w=y-e
                    end
                end
                if u and w then
                    Qk=u.Position Pk=u Nk=math.max ( 350 ,math.max (w.X ,w.Z )/ 2 + 150 )
                    local r=((Vector3.new (e.X , 0 ,e.Z )-Vector3.new (u.Position.X , 0 ,u.Position.Z ))).Magnitude
                    if r<=Nk then
                        y= true
                        return
                    end
                    local k=u:PointToObjectSpace(e)
                    local a=w/ 2
                    if math.abs (k.X )<=(a.X + 200 )and math.abs (k.Z )<=(a.Z + 200 )then
                        y= true
                        return
                    end
                end
                for r,u in ipairs(r:GetDescendants())do
                    if u:IsA( "BasePart" )then
                        if((e-u.Position )).Magnitude <= 250 then
                            y= true
                            if not Qk then
                                Qk=u.Position
                            end
                            return
                        end
                    end
                end
            end
            )
            return y
        end
        local function Dk(e,r,y,...)
            local function nz(s)
                return (string.lower(tostring(s or "")):gsub("[%s_%-]", ""))
            end
            local byNorm={}
            for _,zn in ipairs(M)do
                byNorm[nz(zn)]=zn
            end
            local an=nz(e)
            if an~="" and an~="unknown" and byNorm[an] then
                return byNorm[an]
            end
            local x = r and tonumber(r.X) or nil
            if x then
                if x >= 5200 then return "Angels and Demons"
                elseif x >= 4750 then return "Titan Temple"
                elseif x >= 4000 then return "Cherry Blossom"
                elseif x >= 3350 then return "Cosmic"
                elseif x >= 2780 then return "Prehistoric"
                elseif x >= 2250 then return "Abyss Ocean"
                elseif x >= 1850 then return "Volcano"
                elseif x >= 1450 then return "Snow"
                elseif x >= 1150 then return "Jungle"
                elseif x >= 920 then return "Desert"
                elseif x >= 720 then return "Lake"
                end
            end
            if an~="" and an~="unknown" then
                for key,zn in pairs(byNorm)do
                    if #key >= 4 and string.find(an,key,1,true) then
                        return zn
                    end
                end
            end
            return nil
        end
        N4=function(...)
            local e=h4( false )
            if not e or#e== 0 then
                e=h4( true )
            end
            if not e or#e== 0 then
                return nil
            end
            local y=o.Character
            local u=y and y:FindFirstChild( "HumanoidRootPart" )
            local w=u and u.Position or Vector3.new ( 525 , 70 , -360 )
            local function j(e,...) e=tonumber(e)or 0
                if e>= 1000000000000 then
                    return string.format ( "%.1fT" ,e/ 1000000000000 )
                end
                if e>= 1000000000 then
                    return string.format ( "%.1fB" ,e/ 1000000000 )
                end
                if e>= 1000000 then
                    return string.format ( "%.1fM" ,e/ 1000000 )
                end
                if e>= 1000 then
                    return string.format ( "%.1fK" ,e/ 1000 )
                end
                return string.format ( "%.0f" ,e)
            end
            local function k(e,r,y,u,...)
                if e and e.PhysicalModel then
                    local u=e.PhysicalModel
                    local w=u:GetAttribute( "Rarity" )or u:GetAttribute( "RarityTier" )or u:GetAttribute( "Tier" )
                    if w and(tostring(w)~= "" and tostring(w)~= "Unknown" )then
                        y=tostring(w)
                    end
                    if not r or r== "Egg" or r== "" then
                        r=u:GetAttribute( "Category" )or u:GetAttribute( "AssetCategory" )or u.Name
                    end
                end
                local w=string.lower (tostring(e.Rarity or "" ))
                local j=string.lower (tostring(y or "" ))
                for e,r in ipairs({w,j})do
                    if r~= "" and(r~= "unknown" and r~= "nil" )then
                        if string.find (r, "divine" )then
                            return 6 , "Divine"
                        end
                        if string.find (r, "eternal" )then
                            return 5 , "Eternal"
                        end
                        if string.find (r, "secret" )then
                            return 4 , "Secret"
                        end
                        if string.find (r, "cosmic" )then
                            return 3 , "Cosmic"
                        end
                        if string.find (r, "mythic" )then
                            return 2 , "Mythic"
                        end
                        if string.find (r, "legendary" )then
                            return 1 , "Legendary"
                        end
                        if string.find (r, "epic" )then
                            return 0.5 , "Epic"
                        end
                        if string.find (r, "rare" )then
                            return 0.3 , "Rare"
                        end
                        if string.find (r, "uncommon" )then
                            return 0.1 , "Uncommon"
                        end
                        if string.find (r, "common" )then
                            return 0 , "Common"
                        end
                    end
                end
                if u and u>= 10 then
                    return 6 , "Divine"
                elseif u and u>= 9 then
                    return 5 , "Eternal"
                elseif u and u>= 8 then
                    return 4 , "Secret"
                elseif u and u>= 7 then
                    return 3 , "Cosmic"
                elseif u and u>= 6 then
                    return 2 , "Mythic"
                elseif u and u>= 5 then
                    return 1 , "Legendary"
                elseif u and u>= 4 then
                    return 0.5 , "Epic"
                elseif u and u>= 3 then
                    return 0.3 , "Rare"
                elseif u and u>= 2 then
                    return 0.1 , "Uncommon"
                elseif u and u>= 1 then
                    return 0 , "Common"
                end
                local k=string.lower (string.format ( "%s %s %s %s %s" ,tostring(r or "" ),tostring(e.Uid or "" ),tostring(e.Name or "" ),tostring(e.DisplayName or "" ),tostring(e.EggName or "" )))
                if string.find (k, "nightflame" )or string.find (k, "unicornegg" )or string.find (k, "unicorn egg" )or string.find (k, "shatteredcolossus" )or string.find (k, "kitsune" )or string.find (k, "elmaja" )or string.find (k, "el maja" )then
                    return 6 , "Divine"
                end
                if string.find (k, "gorillaking" )or string.find (k, "gorilla king" )or string.find (k, "lunardragon" )or string.find (k, "lunar dragon" )or string.find (k, "onitiger" )or string.find (k, "oni tiger" )or string.find (k, "mosasaurus" )then
                    return 5 , "Eternal"
                end
                if string.find (k, "mutantshark" )or string.find (k, "mutant shark" )or string.find (k, "skeletonboss" )or string.find (k, "skeleton boss" )or string.find (k, "stagegg" )or string.find (k, "stag egg" )or string.find (k, "cosmicdragon" )or string.find (k, "cosmic dragon" )or string.find (k, "trex" )or string.find (k, "t-rex" )or string.find (k, "tralaledon" )or string.find (k, "kraken" )then
                    return 4 , "Secret"
                end
                if string.find (k, "saturnita" )or string.find (k, "saturno" )or string.find (k, "mantaris" )or string.find (k, "rhinotaur" )or string.find (k, "snowyowl" )or string.find (k, "snowy owl" )or string.find (k, "koiegg" )or string.find (k, "koi egg" )or string.find (k, "triceratops" )or string.find (k, "bronto" )or string.find (k, "whaleshark" )or string.find (k, "whale shark" )or string.find (k, "belugawhale" )or string.find (k, "beluga whale" )then
                    return 3 , "Cosmic"
                end
                if string.find (k, "bladehide" )or string.find (k, "redpanda" )or string.find (k, "red panda" )or string.find (k, "cosmicgorilla" )or string.find (k, "cosmic gorilla" )or string.find (k, "ankylosaurus" )or string.find (k, "orca" )then
                    return 2 , "Mythic"
                end
                if string.find (k, "spideron" )or string.find (k, "crustacia" )or string.find (k, "salamander" )or string.find (k, "cosmicgecko" )or string.find (k, "cosmic gecko" )or string.find (k, "pterodactyl" )or string.find (k, "sharkegg" )or string.find (k, "shark egg" )then
                    return 1 , "Legendary"
                end
                if string.find (k, "crane" )or string.find (k, "centapede" )or string.find (k, "swordfish" )then
                    return 0.5 , "Epic"
                end
                if string.find (k, "dodo" )or string.find (k, "parrotfish" )then
                    return 0.3 , "Rare"
                end
                local a=tonumber(e.EarningRate or e.Income or 0 )
                if a and a>= 150000000 then
                    return 4 , "Secret"
                end
                local o=(y and(y~= "Unknown" and y))or "Common"
                local V=F[o]or 0
                return V,o
            end
            local function a(r,y,...)
                local u={}
                local anyZone= false
                for _,on in pairs(h.selectedZones or{})do
                    if on== true then
                        anyZone= true
                        break
                    end
                end
                if not anyZone then
                    h.statusText = "[Filter] No zones selected"
                    return nil
                end
                local anyRarity = false
                for _, rarityName in ipairs(X) do
                    if h.selectedRarities and h.selectedRarities[rarityName] == true then
                        anyRarity = true
                        break
                    end
                end
                for e,r in ipairs(e)do
                    local j=(r.State == "Slot" or r.State == "Dropped" or r.State == "GuardCarried" or r.State == 1 )
                    local a=string.find (tostring(r.Uid ), "FirstArea" )
                    local o=X4[r.Uid ]and(os.clock ()<X4[r.Uid ])
                    if j and(not a and(((y or not o))and r.BoundsCFrame ))then
                        local e=r.AssetCategory or "Egg"
                        local y= 0
                        local j= 0
                        local a= 0
                        local o= "Unknown"
                        if p then
                            pcall(function(...)
                                if p.RarityRankForCategory then
                                    y=p.RarityRankForCategory (e)or 0
                                end
                                if p.ProfileIncomePerSecond then
                                    j=p.ProfileIncomePerSecond (e)or 0
                                end
                                if p.SalePrice then
                                    a=p.SalePrice (e)or 0
                                end
                                if p.Assets and p.Assets [e]then
                                    local y=p.Assets [e]o=y.Rarity or(y.Egg and y.Egg.Rarity )or "Unknown"
                                    if not j or j== 0 then
                                        j=y.EarningRate or(y.Egg and y.Egg.EarningRate )or 0
                                    end
                                end
                            end
                            )
                        end
                        local V=r.BoundsCFrame.Position .X
                        local H=r.BoundsCFrame.Position
                        local t=r.AreaId
                        if((not t or t== "" or t== "Unknown" ))and r.PhysicalModel then
                            t=r.PhysicalModel :GetAttribute( "AreaId" )or r.PhysicalModel :GetAttribute( "Area" )
                        end
                        local B=string.format ( "%s %s %s %s" ,tostring(e or "" ),tostring(r.Uid or "" ),tostring(r.Name or "" ),(r.PhysicalModel and r.PhysicalModel.Name )or "" )
                        local J=Dk(t,H,B)
                        local K,c=k(r,e,o,y)
                        local i=(J~=nil and h.selectedZones and h.selectedZones [J]== true )
                        local R=(not anyRarity) or (h.selectedRarities and h.selectedRarities [c]== true )
                        local g=(i and R)
                        if g then
                            local k=tonumber(r.AssetScale or r.Scale )or 1
                            local a= 1
                            if r.Mutations and type(r.Mutations )== "table" then
                                for e,r in pairs(r.Mutations )do
                                    local y=(type(r)== "table" and tonumber(r.Multiplier or r.Value ))or tonumber(r)or 1.5 a=a*y
                                end
                            elseif r.Mutation then
                                a= 1.5
                            end
                            local o=(j*k)*a
                            local V=f[J]or 50
                            if o<= 0 then
                                o=(((V^ 2 )*k)*a)* 10
                            end
                            local H=((w-r.BoundsCFrame.Position )).Magnitude table.insert (u,{[ "Uid" ]=r.Uid ,[ "Category" ]=tostring(e),[ "Area" ]=tostring(J),[ "ZoneWeight" ]=V,[ "Rarity" ]=tostring(c);
                            [ "RarityTier" ]=K;
                            [ "Rank" ]=y;
                            [ "Income" ]=j,[ "RealIncome" ]=o;
                            [ "Scale" ]=k,[ "MutMultiplier" ]=a,[ "CFrame" ]=r.BoundsCFrame ;
                            [ "Position" ]=r.BoundsCFrame.Position ,[ "Distance" ]=H,[ "Model" ]=r.PhysicalModel })
                        end
                    end
                end
                if#u== 0 then
                    return nil
                end
                table.sort (u,function(e,r,...)
                    if not anyRarity then
                        local er = tonumber(e.RarityTier) or 0
                        local rr = tonumber(r.RarityTier) or 0
                        if er ~= rr then
                            return er > rr
                        end
                        local es = tonumber(e.Scale) or 1
                        local rs = tonumber(r.Scale) or 1
                        if es ~= rs then
                            return es > rs
                        end
                    end
                    return e.Distance < r.Distance
                end
                )
                return u[ 1 ]
            end
            local V=a(false, false)
            if not V then
                e=h4(true)
                V=a(false, false)
            end
            if V and r:FindFirstChild( "AreaEggSlotsClient" )then
                for e,r in ipairs(r.AreaEggSlotsClient :GetChildren())do
                    local y=r:FindFirstChildWhichIsA( "BasePart" )or r.PrimaryPart
                    if y and((y.Position -V.Position )).Magnitude <= 12 then
                        V.Model =r
                        break
                    end
                end
            end
            return V
        end
        U4=function(e,u,w,j,...)
            local k=o.Character
            local a=k and k:FindFirstChild( "HumanoidRootPart" )
            local V=k and k:FindFirstChildOfClass( "Humanoid" )
            if not a or not V then
                return false
            end
            h.securingEgg = true h.isReturning = false h.stateTime =os.clock ()h.holdingEggForGuard = true
            local s=u.Position V4(s, 14 )h.currentTargetModel =w h.targetPosition =s a.AssemblyLinearVelocity =Vector3.zero a.AssemblyAngularVelocity =Vector3.zero Z4(k)pcall(function(...) o:RequestStreamAroundAsync(s)
            end
            )
            if not w and r:FindFirstChild( "AreaEggSlotsClient" )then
                for e,r in ipairs(r.AreaEggSlotsClient :GetChildren())do
                    local y=r:FindFirstChildWhichIsA( "BasePart" )or r.PrimaryPart
                    if y and((y.Position -s)).Magnitude <= 16 then
                        w=r h.currentTargetModel =r
                        break
                    end
                end
            end
            if w then
                pcall(function(...)
                    for r,y in ipairs(w:GetDescendants())do
                        if y:IsA( "BasePart" )and(y.Transparency > 0.8 and(y.Name ~= "Hitbox" and(y.Name ~= "Root" and not y.Name :find( "Pad" ))))then
                            y.Transparency = 0
                        end
                    end
                end
                )
            end
            h.statusText = "[1/4] Lifting Egg to Trigger Guard..." H(string.format ( "[GuardStrike] Step 1: Lifting target egg (%s)..." ,tostring(e)))
            local p=os.clock ()+ 3.5
            local B=0
            local lastRemoteRequest=0
            while not w4(e)and(os.clock ()<p and(h.alive and h.securingEgg ))do
                if j and O4~=j then
                    t( "[GuardStrike] Cancelled by session switch in Step 1" )
                    break
                end
                if not h.pureTweenFarm and(not h.autoFarmLoop and not h.teleporting )then
                    break
                end
                if e and(os.clock ()-B> 0.4 )then
                    B=os.clock ()
                    local r,y=k4(e)
                    if not r and y== "CarriedByOther" then
                        t(string.format ( "[GuardStrike] Target egg %s was snatched by another player! Aborting pickup..." ,tostring(e)))
                        break
                    end
                end
                k:PivotTo(u*CFrame.new ( 0 , 0.4 , 0 ))d4(w,s)
                if e and i and (os.clock()-lastRemoteRequest)>=0.4 then
                    lastRemoteRequest=os.clock()
                    task.spawn(function()
                        local ok,err=pcall(function()
                            if i:IsA("RemoteFunction") then
                                i:InvokeServer({["Uid"]=e})
                                i:InvokeServer(e)
                            else
                                i:FireServer({["Uid"]=e})
                                i:FireServer(e)
                            end
                        end)
                        if not ok then
                            t("[PickupDiag] Remote request error: "..tostring(err))
                        end
                    end)
                end
                y.Heartbeat :Wait()
            end
            if not w4(e)then
                local _,pickupState=k4(e)
                H(string.format("[PickupDiag] Timeout uid=%s | targetState=%s | carriedEggCount=%d | remoteFound=%s",
                    tostring(e), tostring(pickupState), tonumber(y4()) or 0, tostring(i~=nil)))
                t("[GuardStrike] Initial egg pickup timed out or egg was stolen")
                if e then
                    X4[e]=os.clock()+8
                end
                h.currentTargetModel =nil h.targetPosition =nil h.securingEgg = false h.holdingEggForGuard = false
                return false
            end
            pcall(u4)
            h.currentTargetModel = nil
            h.targetPosition = nil
            h.securingEgg = false
            h.holdingEggForGuard = false
            h.statusText = "Egg secured! Returning to base..."
            H("[AutoSteal] Egg secured; skipping guard strike and returning to base immediately.")
            return true

        end
        l4=function(e,u,...)
            if h.teleporting or h.glidingToTarget or h.delivering or h.securingEgg then
                return false
            end
            h.teleporting = true h.isReturning = false h.stateTime =os.clock ()
            local w=o.Character
            local j=w and w:FindFirstChild( "HumanoidRootPart" )
            local k=w and w:FindFirstChildOfClass( "Humanoid" )
            if not j or not k then
                D4()
                return false
            end
            if k then
                k:UnequipTools()
            end
            h.statusText = "[1/7] Pre-Flight Desync..."
            if not h.swapped then
                A4()
            end
            if not h.godmode then
                b4( true )
            end
            Z4(w)
            if not e then
                e=N4()
            end
            local a=e and e.CFrame or S
            local V=e and e.Uid
            local H=a.Position
            if V then
                local e,r=k4(V)
                if not e and r~= "CarriedBySelf" then
                    t(string.format ( "[Snipe] Target egg %s is already taken (%s)! Selecting next target..." ,tostring(V),tostring(r)))h.statusText = "Target taken by another player!" X4[V]=os.clock ()+ 5 D4()
                    return false
                end
            end
            local s=select( 2 ,e4())
            if not s then
                local e=P4()
                if not e then
                    t( "[-] Lake egg not found" )h.statusText = "[-] No Lake egg found" D4()
                    return false
                end
                h.currentTargetModel =e.Model h.targetPosition =e.Position
                local r=((j.Position -e.Position )).Magnitude
                local w=e.CFrame *CFrame.new ( 0 , 0.4 , 0 )pcall(function(...) o:RequestStreamAroundAsync(e.Position )
                end
                )V4(e.Position , 8 )
                if r> 60 then
                    h.statusText =string.format ( "[2/7] Gliding to Lake Egg (%.0f studs)..." ,r)h.glidingToTarget = true
                    local y=R4(w,h.glideSpeed ,e.Uid ,u)h.glidingToTarget = false
                    if not y then
                        t( "[-] Lake starter egg was taken during flight" )X4[e.Uid ]=os.clock ()+ 5 D4()
                        return false
                    end
                else
                    h.statusText = "[2/7] Aligning with Lake Egg..." j.CFrame =w j.AssemblyLinearVelocity =Vector3.zero task.wait ( 0.04 )
                end
                j.Anchored = true task.wait ( 0.06 )j.Anchored = false h.holdingEggForGuard = true
                local k=os.clock ()+ 3
                while not w4()and(os.clock ()<k and(h.alive and h.teleporting ))do
                    if u and O4~=u then
                        t( "[Snipe] Cancelled by session switch during Lake egg pickup" )D4()
                        return false
                    end
                    if not h.autoFarmLoop and not h.teleporting then
                        D4()
                        return false
                    end
                    d4(e.Model ,e.Position )
                    if e.Uid and i then
                        task.spawn (function(...) pcall(function(...)
                                if i:IsA( "RemoteFunction" )then
                                    i:InvokeServer({[ "Uid" ]=e.Uid })
                                else
                                    i:FireServer({[ "Uid" ]=e.Uid })
                                end
                            end
                            )
                        end
                        )
                    end
                    y.Heartbeat :Wait()
                end
                s=select( 2 ,e4())
                if not w4()then
                    t( "[-] Lake egg pickup failed" )h.statusText = "[-] Lake pickup failed" D4()
                    return false
                end
            end
            h.statusText = "[3/7] Pre-streaming Target..." pcall(function(...) o:RequestStreamAroundAsync(H)
            end
            )V4(H, 12 )h.statusText = "[4/7] Waiting for physical bounce..." j.Anchored = false k:ChangeState(Enum.HumanoidStateType.Running )
            local p=(k.WalkSpeed > 0 )and k.WalkSpeed or 16 k.WalkSpeed = 0 k:Move(Vector3.zero , false )j.AssemblyLinearVelocity =Vector3.zero j.AssemblyAngularVelocity =Vector3.zero task.wait ( 0.04 )
            local B=j.Position
            local J=B.Y
            local K=select( 2 ,e4())or s
            local c= false
            local v=nil
            if N and N:IsA( "RemoteEvent" )then
                v=N.OnClientEvent :Connect(function(...) c= true
                    if v then
                        v:Disconnect()
                    end
                end
                )
            end
            h.holdingEggForGuard = true H4(K)
            local R=os.clock ()
            local g= false
            local Q=os.clock ()+ 2.5
            local P= false
            while os.clock ()<Q and(h.alive and h.teleporting )do
                if u and O4~=u then
                    t( "[Snipe] Cancelled by session switch during strike bounce" )
                    if v then
                        v:Disconnect()
                    end
                    k.WalkSpeed =p D4()
                    return false
                end
                local e=os.clock ()-R
                local r=j.AssemblyLinearVelocity
                local w=j.Position
                local a=w.Y -J
                local o=((w-B)).Magnitude
                if e>= 0.08 then
                    local e=c or(r.Y >= 10 )or(a>= 1.5 and r.Magnitude >= 16 )or(o>= 2 )or(r.Magnitude >= 20 )
                    if e then
                        g= true
                        break
                    end
                end
                if e>= 0.5 and not P then
                    P= true H4(K)
                end
                y.Heartbeat :Wait()
            end
            if v then
                v:Disconnect()
            end
            k.WalkSpeed =p h.holdingEggForGuard = false
            if not g then
                t( "[-] No bounce detected, aborting" )h.statusText = "[-] Aborted (No bounce detected)" D4()pcall(u4)
                return false
            end
            task.wait ( 0.05 )
            if V then
                local e,r=k4(V)
                if not e and r== "CarriedByOther" then
                    t(string.format ( "[Snipe] Target egg %s was snatched while bouncing (%s)! Aborting warp..." ,tostring(V),tostring(r)))h.statusText = "Target taken! Aborting warp..." X4[V]=os.clock ()+ 5 D4()
                    return false
                end
            end
            h.currentTargetModel =e and e.Model h.targetPosition =H h.statusText = "[5/7] Warping to Target Egg..." V4(H, 8 )w:PivotTo(a*CFrame.new ( 0 , 0.4 , 0 ))j.Anchored = true
            for e,r in ipairs(w:GetDescendants())do
                if r:IsA( "BasePart" )then
                    r.AssemblyLinearVelocity =Vector3.zero r.AssemblyAngularVelocity =Vector3.zero
                end
            end
            h.statusText = "[6/7] Picking up Target Egg..."
            local U=o:FindFirstChild( "Backpack" )
            for e,y in ipairs(w:GetChildren())do
                if y:IsA( "Tool" )then
                    pcall(function(...)
                        if U then
                            y.Parent =U
                        else
                            y.Parent =r
                        end
                    end
                    )
                end
            end
            task.wait ( 0.06 )j.Anchored = false k:ChangeState(Enum.HumanoidStateType.Running )
            local l=U4(V,a,e and e.Model ,u)j.Anchored = false k:ChangeState(Enum.HumanoidStateType.Running )
            for e,r in ipairs(w:GetDescendants())do
                if r:IsA( "BasePart" )then
                    r.AssemblyLinearVelocity =Vector3.zero r.AssemblyAngularVelocity =Vector3.zero
                end
            end
            if not l then
                t( "[-] Guard Strike criteria not met" )h.statusText = "[-] Guard Strike criteria failed" D4()
                return false
            else
                h.statusText = "[7/7] Target Secured! Stashing into Backpack..." h.teleporting = false pcall(u4)
                return true
            end
        end
        local function FULL_RESTORE()
            h.onTreadmill = false
            h.teleporting = false
            h.glidingToTarget = false
            h.securingEgg = false
            h.isReturning = false
            h.delivering = false
            h.holdingEggForGuard = false
            h.isHatching = false
            h.isBatchPlacing = false
            h.currentTargetModel = nil
            h.targetPosition = nil

            _G._DesyncAntiRagdollActive = false

            local char = o.Character
            if not char then return end

            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if hrp then
                pcall(function()
                    hrp.Anchored = false
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end

            if hum then
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)

                    hum.PlatformStand = false
                    hum.Sit = false
                    hum.AutoRotate = true

                    hum.WalkSpeed = savedWalkSpeed or 16
                    if hum.UseJumpPower then
                        hum.JumpPower = savedJumpPower or 50
                    else
                        hum.JumpHeight = savedJumpHeight or 7.2
                    end

                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end

            pcall(function()
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("WeldConstraint") and d.Name:match("^RigidJointWeld_") then
                        d:Destroy()
                    end
                end
            end)

            pcall(function()
                local animate = char:FindFirstChild("Animate")
                if animate and animate:IsA("LocalScript") then
                    animate.Disabled = false
                end
            end)

            H("[FarmController] FULL_RESTORE: игрок восстановлен (анимации, состояния, физика).")
        end
        T4=function(e,...)
            if Y4==e then
                return
            end
            O4=O4+ 1
            local r=O4 Y4= "SWITCHING" h.pureTweenFarm = false h.autoFarmLoop = false pcall(D4)pcall(u4)
            if e== "TWEEN" then
                if W4 then
                    W4( false , true )
                end
                if x4 then
                    x4( true , true )
                end
            elseif e== "WARP" then
                if x4 then
                    x4( false , true )
                end
                if W4 then
                    W4( true , true )
                end
            else
                if x4 then
                    x4( false , true )
                end
                if W4 then
                    W4( false , true )
                end
            end
            task.delay ( 0.06 ,function(...)
                if O4==r then
                    Y4=e
                    if e== "TWEEN" then
                        statsCaptureLock = true
                        _G._DesyncAntiRagdollActive = true
                        h.pureTweenFarm = true h.autoFarmLoop = false pcall(u4)H( "[FarmController] Pure Auto Steal (Tween) ACTIVATED exclusively." )
                    elseif e== "WARP" then
                        statsCaptureLock = true
                        _G._DesyncAntiRagdollActive = true
                        h.autoFarmLoop = true h.pureTweenFarm = false pcall(u4)H( "[FarmController] Snipe Auto Loop (Warp) ACTIVATED exclusively." )
                    else
                        h.pureTweenFarm = false h.autoFarmLoop = false
                        if not h.isBatchPlacing then
                            h.batchStealCount = 0
                        end
                        statsCaptureLock = false
                        pcall(C4)
                        pcall(M4)
                        pcall(u4)
                        pcall(FULL_RESTORE)
                        H( "[FarmController] All farms DEACTIVATED. Bot idle." )
                    end
                end
            end
            )
        end
        local Ck=os.clock ()task.spawn (function(...)
            while h.alive do
                local r,y=pcall(function(...)
                    if h.pureTweenFarm and(not h.autoFarmLoop and(Y4== "TWEEN" and(not h.isBatchPlacing and(not h.teleporting and(not h.glidingToTarget and(not h.securingEgg and(not h.delivering and not h.isReturning )))))))then
                        local r=o.Character
                        local y=r and r:FindFirstChild( "HumanoidRootPart" )
                        local u=r and r:FindFirstChildOfClass( "Humanoid" )
                        if y and u then
                            pcall(u4)
                            local u=w4()
                            if not u then
                                local u=O4
                                local w=N4()
                                if w and(h.pureTweenFarm and(Y4== "TWEEN" and O4==u))then
                                    h.idleResetDone = false
                                    if h.onTreadmill or L4()then
                                        h.statusText = "[AutoSteal] Target found! Getting off treadmill..." M4()task.wait ( 0.08 )
                                    end
                                    local j,k=k4(w.Uid )
                                    if not j and k~= "CarriedBySelf" then
                                        H(string.format ( "[AutoSteal] Egg %s already taken (%s). Switching to next target..." ,tostring(w.Uid ),tostring(k)))X4[w.Uid ]=os.clock ()+ 5 task.wait ( 0.12 )
                                        return
                                    end
                                    h.currentTargetModel =w.Model h.targetPosition =w.Position h.glidingToTarget = true h.stateTime =os.clock ()
                                    local a=((w.Scale and w.Scale > 1.05 ))and string.format ( " | %.1fx" ,w.Scale )or "" h.statusText =string.format ( "[AutoSteal] Flying to %s (%s%s)..." ,tostring(w.Category or "Egg" ),tostring(w.Area or "Field" ),a)H(string.format ( "[AutoSteal] Flying to %s | Zone: %s%s | Rank: %d (Corridor Z=-360)" ,tostring(w.Category or "Egg" ),tostring(w.Area or "Field" ),a,tonumber(w.Rank )or 1 ))
                                    if not h.swapped then
                                        A4()
                                    end
                                    if not h.godmode then
                                        b4( true )
                                    end
                                    Z4(r)pcall(function(...) o:RequestStreamAroundAsync(w.Position )
                                    end
                                    )
                                    local V=w.CFrame *CFrame.new ( 0 , 0.4 , 0 )
                                    local s=R4(V,h.glideSpeed ,w.Uid ,u)h.glidingToTarget = false
                                    if O4~=u or not h.pureTweenFarm or Y4~= "TWEEN" then
                                        return
                                    end
                                    if not s then
                                        t( "[AutoSteal] Egg was taken during flight. Switching to next target..." )X4[w.Uid ]=os.clock ()+ 5 D4()
                                        return
                                    end
                                    if h.pureTweenFarm and(Y4== "TWEEN" and((y.Position -w.Position )).Magnitude <= 22 )then
                                        local r=U4(w.Uid ,V,w.Model ,u)
                                        if not r and w4(w.Uid)then
                                            r= true
                                        end
                                        if not r and O4==u and h.pureTweenFarm and Y4== "TWEEN" then
                                            for pickupRetry=1,2 do
                                                task.wait(0.35)
                                                if O4~=u or not h.pureTweenFarm or Y4~= "TWEEN" then
                                                    break
                                                end
                                                r=U4(w.Uid,V,w.Model,u)
                                                if not r and w4(w.Uid) then
                                                    r=true
                                                end
                                                if r then
                                                    H(string.format("[AutoSteal] Pickup retry %d succeeded for egg %s",pickupRetry,tostring(w.Uid)))
                                                    break
                                                end
                                            end
                                        end
                                        if O4~=u or not h.pureTweenFarm or Y4~= "TWEEN" then
                                            return
                                        end
                                        if r then
                                            X4[w.Uid]=os.clock()+30
                                            H(string.format("[PickupDiag] Confirmed uid=%s | carriedEggCount=%d | cooling down UID for 30s",
                                                tostring(w.Uid), tonumber(y4()) or 0))
                                            pcall(u4)
                                            h.statusText = "[AutoSteal] Egg picked up! Returning to Safe Line immediately..."
                                            H("[AutoSteal] Egg pickup confirmed; skipping guard-strike wait and returning immediately.")
                                            Q4(h.glideSpeed, u)
                                            pcall(u4)
                                            local bagCount = y4()
                                            h.statusText = string.format("Returned to Safe Line. Backpack eggs: %d", bagCount)
                                            H(string.format("[AutoSteal] Returned to Safe Line; backpack/character egg count: %d", bagCount))
                                            h.isReturning = false
                                            h.delivering = false
                                            h.glidingToTarget = false
                                            h.securingEgg = false
                                            h.currentTargetModel = nil
                                            h.targetPosition = nil
                                            if c4("TWEEN") then
                                                return
                                            end
                                        else
                                            if O4==u and(h.pureTweenFarm and Y4== "TWEEN" )then
                                                t( "[AutoSteal] Guard Strike or Re-grab failed. Retrying with next egg..." )X4[w.Uid ]=os.clock ()+ 5 D4()
                                            end
                                        end
                                    else
                                        h.currentTargetModel =nil h.targetPosition =nil h.glidingToTarget = false
                                    end
                                else
                                    if os.clock ()-Ck> 5 then
                                        X4={}Ck=os.clock ()
                                    end
                                    if not h.idleResetDone then
                                        h.idleResetDone = true
                                        pcall(C4)
                                        pcall(function(...)
                                            local ch=o.Character
                                            local hu=ch and ch:FindFirstChildOfClass("Humanoid")
                                            if hu then
                                                hu.AutoRotate = true
                                                hu.PlatformStand = false
                                                hu.Sit = false
                                                hu:ChangeState(Enum.HumanoidStateType.Running)
                                                for _,track in ipairs(hu:GetPlayingAnimationTracks()) do
                                                    local anim=track.Animation
                                                    local aid=anim and anim.AnimationId or ""
                                                    local nm=string.lower(track.Name or "")
                                                    if string.find(aid,"10921259953") or string.find(nm,"treadmill") then
                                                        track:Stop(0)
                                                    end
                                                end
                                            end
                                            local animate=ch and ch:FindFirstChild("Animate")
                                            if animate and animate:IsA("LocalScript") then animate.Disabled=false end
                                        end)
                                    end
                                    if h.autoTreadmill and(not h.isBatchPlacing and not h.isHatching )then
                                        if not h.onTreadmill and not L4()then
                                            h.statusText = "[AutoTreadmill] No targets. Mounting treadmill..." f4(u)
                                        else
                                            h.statusText = "[AutoTreadmill] Running on treadmill (Waiting for eggs...)"
                                        end
                                    else
                                        h.statusText = "[AutoSteal] Scanning for targets..."
                                    end
                                end
                            end
                        end
                    end
                end
                )
                if not r then
                    t( "[AutoSteal Loop Recovered]:" ,tostring(y))pcall(D4)
                end
                task.wait ( 0.08 )
            end
        end
        )
        local qk=os.clock ()task.spawn (function(...)
            while h.alive do
                local r,y=pcall(function(...)
                    if h.autoFarmLoop and(not h.pureTweenFarm and(Y4== "WARP" and(not h.isBatchPlacing and(not h.teleporting and(not h.glidingToTarget and(not h.securingEgg and(not h.delivering and not h.isReturning )))))))then
                        local r=o.Character
                        local y=r and r:FindFirstChild( "HumanoidRootPart" )
                        local u=r and r:FindFirstChildOfClass( "Humanoid" )
                        if y and u then
                            pcall(u4)
                            local r=w4()
                            if not r then
                                local r=O4
                                local y=N4()
                                if y and(h.autoFarmLoop and(Y4== "WARP" and O4==r))then
                                    h.idleResetDone = false
                                    if h.onTreadmill or L4()then
                                        h.statusText = "[SnipeLoop] Target found! Getting off treadmill..." M4()task.wait ( 0.08 )
                                    end
                                    local u=((y.Scale and y.Scale > 1.05 ))and string.format ( " | %.1fx" ,y.Scale )or "" H(string.format ( "[SnipeLoop] Starting Warp Snipe: %s | Zone: %s%s (Rank %d)" ,tostring(y.Category or "Egg" ),tostring(y.Area or "Field" ),u,tonumber(y.Rank )or 1 ))h.statusText =string.format ( "[SnipeLoop] Warping for %s%s..." ,tostring(y.Category or "Egg" ),u)
                                    local w=l4(y,r)
                                    if O4~=r or not h.autoFarmLoop or Y4~= "WARP" then
                                        return
                                    end
                                    if w then
                                        pcall(u4)
                                        if h.autoGlide then
                                            h.statusText = "[SnipeLoop] Target secured! Tweening to Safe Line X=525..." Q4(h.glideSpeed ,r)pcall(u4)
                                            local y=y4()h.statusText =string.format ( "Stashed in Bag (%d Eggs). Next snipe..." ,y)H(string.format ( "[SnipeLoop] Egg stashed in bag (%d total eggs). Hands-Free ready for next snipe..." ,y))
                                        else
                                            h.statusText = "[SnipeLoop] Target secured! (Auto Return is OFF)" H( "[SnipeLoop] Snipe successful! Staying at target (Auto Return is OFF)." )
                                        end
                                        pcall(u4)h.isReturning = false h.delivering = false
                                        if c4( "WARP" )then
                                            return
                                        end
                                    else
                                        if O4==r and(h.autoFarmLoop and Y4== "WARP" )then
                                            t( "[SnipeLoop] Snipe cycle failed. Resetting for next target..." )
                                            if y and y.Uid then
                                                X4[y.Uid ]=os.clock ()+ 5
                                            end
                                            pcall(D4)
                                        end
                                    end
                                else
                                    if os.clock ()-qk> 5 then
                                        X4={}qk=os.clock ()
                                    end
                                    if not h.idleResetDone then
                                        h.idleResetDone = true
                                        pcall(C4)
                                        pcall(function(...)
                                            local ch=o.Character
                                            local hu=ch and ch:FindFirstChildOfClass("Humanoid")
                                            if hu then
                                                hu.AutoRotate = true
                                                hu.PlatformStand = false
                                                hu.Sit = false
                                                hu:ChangeState(Enum.HumanoidStateType.Running)
                                                for _,track in ipairs(hu:GetPlayingAnimationTracks()) do
                                                    local anim=track.Animation
                                                    local aid=anim and anim.AnimationId or ""
                                                    local nm=string.lower(track.Name or "")
                                                    if string.find(aid,"10921259953") or string.find(nm,"treadmill") then
                                                        track:Stop(0)
                                                    end
                                                end
                                            end
                                            local animate=ch and ch:FindFirstChild("Animate")
                                            if animate and animate:IsA("LocalScript") then animate.Disabled=false end
                                        end)
                                    end
                                    if h.autoTreadmill and(not h.isBatchPlacing and not h.isHatching )then
                                        if not h.onTreadmill and not L4()then
                                            h.statusText = "[AutoTreadmill] No targets. Mounting treadmill..." f4(r)
                                        else
                                            h.statusText = "[AutoTreadmill] Running on treadmill (Waiting for eggs...)"
                                        end
                                    else
                                        h.statusText = "[SnipeLoop] Searching for targets..."
                                    end
                                end
                            end
                        end
                    end
                end
                )
                if not r then
                    t( "[SnipeLoop Loop Recovered]:" ,tostring(y))pcall(D4)
                end
                task.wait ( 0.08 )
            end
        end
        )task.spawn (function(...)
            while h.alive do
                local r,y=pcall(function(...)
                    if h.autoTreadmill and(not h.pureTweenFarm and(not h.autoFarmLoop and(not h.isBatchPlacing and(not h.isHatching and(not h.teleporting and(not h.glidingToTarget and(not h.securingEgg and(not h.delivering and not h.isReturning ))))))))then
                        local e=o.Character
                        local y=e and e:FindFirstChild( "HumanoidRootPart" )
                        if y and not w4()then
                            if not h.onTreadmill and not L4()then
                                h.statusText = "[AutoTreadmill] Idle without farm. Mounting treadmill..." f4()task.wait( 3 )
                            end
                        end
                    end
                end
                )task.wait ( 0.5 )
            end
        end
        )task.spawn (function(...)
            while h.alive do
                pcall(function(...)
                    if h.autoUpgradeTreadmill then
                        pk()
                    end
                end
                )task.wait ( 5 )pcall(function(...)
                    if h.autoBuyTrails then
                        gk()
                    end
                end
                )task.wait ( 5 )
            end
        end
        )task.spawn (function(...)
            while h.alive do
                if h.autoHatch and(not h.securingEgg and(not h.teleporting and not h.isHatching ))then
                    pcall(function(...) J4( false )
                    end
                    )
                end
                task.wait ( 4 )
            end
        end
        )
        local nk=nil
        local function fk(e,...) pcall(function(...)
                if e:IsA( "BasePart" )then
                    e.Material =Enum.Material.SmoothPlastic e.Reflectance = 0 e.CastShadow = false
                    if e:IsA( "MeshPart" )then
                        e.TextureID = "" pcall(function(...) e.RenderFidelity =Enum.RenderFidelity.Performance
                        end
                        )pcall(function(...) e.CollisionFidelity =Enum.CollisionFidelity.Box
                        end
                        )
                    end
                elseif e:IsA( "SpecialMesh" )then
                    e.TextureId = ""
                elseif e:IsA( "Decal" )or e:IsA( "Texture" )or e:IsA( "SurfaceAppearance" )then
                    e.Transparency = 1
                elseif e:IsA( "ParticleEmitter" )or e:IsA( "Trail" )or e:IsA( "Smoke" )or e:IsA( "Fire" )or e:IsA( "Sparkles" )then
                    e.Enabled = false
                elseif e:IsA( "Beam" )then
                    e.Enabled = false
                elseif e:IsA( "Explosion" )then
                    e.Visible = false
                elseif e:IsA( "Light" )or e:IsA( "PointLight" )or e:IsA( "SpotLight" )or e:IsA( "SurfaceLight" )then
                    e.Enabled = false
                elseif e:IsA( "Highlight" )and e.Name ~= "EggESP_Highlight" then
                    e.Enabled = false
                end
            end
            )
        end
        local function Mk(...) h.performanceMode = true pcall(function(...)
                local e=r:FindFirstChild( "DiceHub_EggESP" )
                if e then
                    e:Destroy()
                end
                local y=game:GetService( "Lighting" )y.GlobalShadows = false y.FogEnd = 9000000000 y.Brightness = 1 y.ClockTime = 14 y.OutdoorAmbient =Color3.fromRGB ( 128 , 128 , 128 )
                for e,r in ipairs(y:GetChildren())do
                    if r:IsA( "PostEffect" )or r:IsA( "BloomEffect" )or r:IsA( "BlurEffect" )or r:IsA( "ColorCorrectionEffect" )or r:IsA( "SunRaysEffect" )or r:IsA( "DepthOfFieldEffect" )or r:IsA( "Atmosphere" )then
                        pcall(function(...) r.Enabled = false
                        end
                        )
                    elseif r:IsA( "Sky" )then
                        pcall(function(...) r.Parent =nil
                        end
                        )
                    end
                end
                local u=workspace:FindFirstChildOfClass( "Terrain" )
                if u then
                    pcall(function(...) u.Decoration = false u.WaterWaveSize = 0 u.WaterWaveSpeed = 0 u.WaterReflectance = 0 u.WaterTransparency = 0
                    end
                    )
                end
                for e,r in ipairs(workspace:GetDescendants())do
                    fk(r)
                end
                if not nk then
                    nk=workspace.DescendantAdded :Connect(function(e,...)
                        if h.performanceMode then
                            fk(e)
                        end
                    end
                    )
                end
                pcall(function(...)
                    if settings and(settings()).Rendering then
                        (settings()).Rendering.QualityLevel = 1
                    end
                end
                )
            end
            )
        end
        local function Ik(...) h.performanceMode = false
            if nk then
                pcall(function(...) nk:Disconnect()
                end
                )nk=nil
            end
            pcall(function(...)
                local e=game:GetService( "Lighting" )e.GlobalShadows = true
                for e,r in ipairs(e:GetChildren())do
                    if r:IsA( "PostEffect" )or r:IsA( "BloomEffect" )or r:IsA( "BlurEffect" )or r:IsA( "ColorCorrectionEffect" )or r:IsA( "SunRaysEffect" )or r:IsA( "DepthOfFieldEffect" )or r:IsA( "Atmosphere" )then
                        pcall(function(...) r.Enabled = true
                        end
                        )
                    end
                end
                local r=workspace:FindFirstChildOfClass( "Terrain" )
                if r then
                    pcall(function(...) r.Decoration = true
                    end
                    )
                end
            end
            )
        end
        local Lk= false
        local antiAfkConn = nil
        local function Ek(...)
            pcall(function(...)
                local vu = game:GetService("VirtualUser")
                if vu then
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new(0, 0))
                    vu:Button2Down(Vector2.new(0, 0), r.CurrentCamera.CFrame)
                    task.wait(0.05)
                    vu:Button2Up(Vector2.new(0, 0), r.CurrentCamera.CFrame)
                end
            end)
            pcall(function(...)
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
                    task.wait(0.05)
                    vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
                end
            end)
        end

        local function bk(...)
            if Lk then
                return
            end
            Lk = true
    
            pcall(function(...)
                if antiAfkConn then
                    antiAfkConn:Disconnect()
                    antiAfkConn = nil
                end
                antiAfkConn = o.Idled:Connect(function()
                    Ek()
                    pcall(function()
                        local vu = game:GetService("VirtualUser")
                        if vu then
                            vu:Button2Down(Vector2.new(0, 0), r.CurrentCamera.CFrame)
                            task.wait(1)
                            vu:Button2Up(Vector2.new(0, 0), r.CurrentCamera.CFrame)
                        end
                    end)
                end)
            end)

            task.spawn(function(...)
                while h and (h.alive and h.antiAFK and Lk) do
                    Ek()
                    for _ = 1, 60 do
                        if not h.antiAFK or not Lk then
                            break
                        end
                        task.wait(1)
                    end
                end
                Lk = false
            end)
        end

        local function Ak(...)
            Lk = false
            if antiAfkConn then
                pcall(function() antiAfkConn:Disconnect() end)
                antiAfkConn = nil
            end
        end
        y.Heartbeat :Connect(function(...)
            local e=o.Character
            local r=e and e:FindFirstChild( "HumanoidRootPart" )
            local y=e and e:FindFirstChildOfClass( "Humanoid" )
            if not r then
                return
            end
            if y and not((h and h.onTreadmill ))then
                if y.PlatformStand then
                    y.PlatformStand = false y:ChangeState(Enum.HumanoidStateType.Running )
                end
                if y.Sit and((h.pureTweenFarm or h.autoFarmLoop or h.isReturning or h.glidingToTarget ))then
                    y.Sit = false y:ChangeState(Enum.HumanoidStateType.Running )
                end
            end
            local u=r.Position
            local w=w4()
            if u.Y < 45 and((h.pureTweenFarm or h.autoFarmLoop ))then
                r.CFrame =CFrame.new (u.X , 72 ,u.Z )r.AssemblyLinearVelocity =Vector3.zero
                return
            end
            if((h.pureTweenFarm or h.autoFarmLoop ))and not h.holdingEggForGuard then
                local r= false
                for e,y in ipairs(e:GetChildren())do
                    if y:IsA( "Tool" )then
                        r= true
                        break
                    end
                end
                if r then
                    u4()
                end
            end
            if h.pureTweenFarm or h.autoFarmLoop or h.teleporting or h.glidingToTarget or h.delivering or h.securingEgg or h.isReturning then
                return
            end
            if h.alive and((h.pureTweenFarm or h.autoFarmLoop )and(h.autoGlide and(w and(not a4()and u.X >E))))then
                task.spawn (function(...) Q4(h.glideSpeed )u4()h.isReturning = false h.delivering = false
                end
                )
            end
        end
        )

        local function Shutdown(...)
            h.alive = false
            pcall(T4, "NONE" )
            pcall(D4)
            pcall(Ak)
            pcall(function(...)
                if h.performanceMode then
                    Ik()
                end
            end
            )
            pcall(function(...) y:Set3dRenderingEnabled( true )
            end
            )
        end
        return {
            State = h,
            SetFarmMode = T4,
            SetDesyncGodmode = b4,
            ResetFarmStates = D4,
            DoffTreadmillState = C4,
            MountTreadmillOff = M4,
            ExecuteManualPlaceSequence = v4,
            EnableUltraPotatoMode = Mk,
            DisableUltraPotatoMode = Ik,
            EnableAntiAFK = bk,
            DisableAntiAFK = Ak,
            GetTotalEggCount = y4,
            GetDiagnosticLogs = function() return table.clone(diagnosticLogs) end,
            ClearDiagnosticLogs = function() table.clear(diagnosticLogs) end,
            AddDiagnosticLog = function(level, ...) addDiagnosticLog(level or "INFO", ...) end,
            SaveEggSelectConfig = x,
            SaveSpeed = Y,
            ZoneList = M,
            RarityList = X,
            ZoneColors = d,
            RarityColors = G,
            FullRestore = FULL_RESTORE,
            ZoneSpeedReq = ZONE_SPEED_REQ,
            Shutdown = Shutdown
        }
    end)()
    FarmApi = Farm
    local h = Farm.State
    local toast = makeToast(main)

    -- Кнопка "← Назад" в gamesFarmContainer (возврат в меню игр)
    local backBtn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = C.surface2,
        BorderSizePixel = 0,
        Text = "←  НАЗАД К ИГРАМ",
        TextColor3 = C.text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
    }, gamesFarmContainer)
    corner(backBtn, 8)
    backBtn.MouseButton1Click:Connect(function()
        if _G.RH_HUB_SHOW_GAMES_MENU then _G.RH_HUB_SHOW_GAMES_MENU() end
    end)

    local function row(parent, height)
        local f = create("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = C.surface,
            BorderSizePixel = 0,
        }, parent)
        corner(f, 10)
        return f
    end

    local function toggleRow(parent, title, hint, default, cb)
        local on = default == true
        local hasHint = hint ~= nil and hint ~= ""
        local f = row(parent, hasHint and 50 or 44)

        create("TextLabel", {
            Position = UDim2.new(0, 12, 0, hasHint and 8 or 0),
            Size = UDim2.new(1, -80, 0, hasHint and 16 or 44),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, f)
        if hasHint then
            create("TextLabel", {
                Position = UDim2.new(0, 12, 0, 26),
                Size = UDim2.new(1, -80, 0, 14),
                BackgroundTransparency = 1,
                Text = hint,
                TextColor3 = C.muted,
                TextSize = 8,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, f)
        end

        local track = create("Frame", {
            Position = UDim2.new(1, -62, 0.5, -12),
            Size = UDim2.new(0, 46, 0, 24),
            BackgroundColor3 = on and C.accent or C.button,
            BorderSizePixel = 0,
        }, f)
        corner(track, 12)
        local knob = create("Frame", {
            Position = on and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundColor3 = C.text,
            BorderSizePixel = 0,
        }, track)
        corner(knob, 10)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
        }, f)

        local api = {}
        function api.get() return on end
        function api.set(state, silent)
            on = state == true
            TweenService:Create(track, TweenInfo.new(0.2), { BackgroundColor3 = on and C.accent or C.button }):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = on and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
            }):Play()
            if not silent and cb then
                local ok, err = pcall(cb, on)
                if not ok then warn("[RH-HUB] " .. tostring(title) .. ": " .. tostring(err)) end
            end
        end
        btn.MouseButton1Click:Connect(function() api.set(not on) end)
        return api
    end

    local function sliderRow(parent, title, min, max, step, default, onChange, onCommit)
        local value = math.clamp(default or min, min, max)
        local f = row(parent, 56)
        local lbl = create("TextLabel", {
            Position = UDim2.new(0, 12, 0, 6),
            Size = UDim2.new(1, -24, 0, 16),
            BackgroundTransparency = 1,
            Text = title .. ": " .. value,
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, f)
        local track = create("Frame", {
            Position = UDim2.new(0, 12, 0, 32),
            Size = UDim2.new(1, -24, 0, 8),
            BackgroundColor3 = C.button,
            BorderSizePixel = 0,
        }, f)
        corner(track, 4)
        local a0 = (value - min) / (max - min)
        local fill = create("Frame", {
            Size = UDim2.new(a0, 0, 1, 0),
            BackgroundColor3 = C.accent,
            BorderSizePixel = 0,
        }, track)
        corner(fill, 4)
        local knob = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(a0, 0, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = C.text,
            BorderSizePixel = 0,
        }, track)
        corner(knob, 9)

        local dragging = false
        local function setFromX(x)
            local left = track.AbsolutePosition.X
            local width = math.max(1, track.AbsoluteSize.X)
            local alpha = math.clamp((x - left) / width, 0, 1)
            local v = math.floor((min + alpha * (max - min)) / step + 0.5) * step
            value = math.clamp(v, min, max)
            local na = (value - min) / (max - min)
            lbl.Text = title .. ": " .. value
            fill.Size = UDim2.new(na, 0, 1, 0)
            knob.Position = UDim2.new(na, 0, 0.5, 0)
            if onChange then pcall(onChange, value) end
        end
        local function begin(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setFromX(input.Position.X)
            end
        end
        track.InputBegan:Connect(begin)
        knob.InputBegan:Connect(begin)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
                dragging = false
                if onCommit then pcall(onCommit, value) end
            end
        end)
    end

    local function buttonRow(parent, text, cb)
        local b = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = C.button,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = C.text,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = true,
        }, parent)
        corner(b, 10)
        b.MouseButton1Click:Connect(function()
            local ok, err = pcall(cb)
            if not ok then warn("[RH-HUB] " .. tostring(text) .. ": " .. tostring(err)) end
        end)
        return b
    end

    -- Сетка зон с подписями требуемой Speed
    local function zoneGridWithSpeed(parent, list, map, colors, speedReqs, onChange)
        for _, name in ipairs(list) do
            if map[name] == nil then map[name] = false end
        end

        local grid = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, parent)
        create("UIGridLayout", {
            CellSize = UDim2.new(1 / 2, -4, 0, 52),
            CellPadding = UDim2.fromOffset(6, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, grid)

        local buttons = {}
        local function paint(name)
            local wrap = buttons[name]
            if not wrap then return end
            local btn = wrap.btn
            local on = map[name] == true
            local col = colors[name] or C.accent

            local req = speedReqs[name]
            local have = getPlayerSpeed()
            local accessible = (req == nil) or (have >= req)

            if on then
                btn.BackgroundColor3 = col
                local lum = 0.299 * col.R + 0.587 * col.G + 0.114 * col.B
                btn.TextColor3 = lum > 0.62 and Color3.fromRGB(15, 15, 20) or Color3.new(1, 1, 1)
            else
                btn.BackgroundColor3 = C.button
                btn.TextColor3 = C.muted
            end

            -- Красная обводка если скорость не хватает
            if not accessible then
                wrap.stroke.Color = C.red
                wrap.stroke.Transparency = 0.1
                btn.Text = (on and "✓ " or "🔒 ") .. name
            else
                wrap.stroke.Color = on and col or C.border
                wrap.stroke.Transparency = on and 0.2 or 0.6
                btn.Text = (on and "✓ " or "") .. name
            end
        end

        for i, name in ipairs(list) do
            local wrap = create("Frame", {
                BackgroundColor3 = C.button,
                BorderSizePixel = 0,
                LayoutOrder = i,
            }, grid)
            corner(wrap, 8)

            local strk = create("UIStroke", {
                Color = C.border,
                Thickness = 1,
                Transparency = 0.6,
            }, wrap)

            local btn = create("TextButton", {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, -16),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = C.muted,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
            }, wrap)
            corner(btn, 8)

            local speedLbl = create("TextLabel", {
                Position = UDim2.new(0, 0, 1, -16),
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = speedReqs[name] and ("⚡ " .. formatSpeed(speedReqs[name])) or "⚡ —",
                TextColor3 = C.yellow,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            }, wrap)

            buttons[name] = { btn = btn, stroke = strk, label = speedLbl }

            btn.MouseButton1Click:Connect(function()
                map[name] = not (map[name] == true)
                paint(name)
                if onChange then pcall(onChange) end
            end)
        end

        return {
            setAll = function(state)
                for _, name in ipairs(list) do
                    map[name] = state
                    paint(name)
                end
                if onChange then pcall(onChange) end
            end,
            repaint = function()
                for _, name in ipairs(list) do
                    paint(name)
                end
            end,
        }
    end

    local function chipGrid(parent, list, map, colors, onChange)
        for _, name in ipairs(list) do
            if map[name] == nil then map[name] = false end
        end

        local grid = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, parent)
        create("UIGridLayout", {
            CellSize = UDim2.new(1 / 3, -5, 0, 30),
            CellPadding = UDim2.fromOffset(6, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, grid)

        local buttons = {}
        local function paint(name)
            local btn = buttons[name]
            if not btn then return end
            local on = map[name] == true
            local col = colors[name] or C.accent
            btn.Text = (on and "✓ " or "") .. name
            if on then
                btn.BackgroundColor3 = col
                local lum = 0.299 * col.R + 0.587 * col.G + 0.114 * col.B
                btn.TextColor3 = lum > 0.62 and Color3.fromRGB(15, 15, 20) or Color3.new(1, 1, 1)
            else
                btn.BackgroundColor3 = C.button
                btn.TextColor3 = C.muted
            end
        end

        for i, name in ipairs(list) do
            local b = create("TextButton", {
                BackgroundColor3 = C.button,
                BorderSizePixel = 0,
                Text = name,
                TextColor3 = C.muted,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = false,
                LayoutOrder = i,
            }, grid)
            corner(b, 8)
            buttons[name] = b
            paint(name)
            b.MouseButton1Click:Connect(function()
                map[name] = not (map[name] == true)
                paint(name)
                if onChange then pcall(onChange) end
            end)
        end

        return {
            setAll = function(state)
                for _, name in ipairs(list) do
                    map[name] = state
                    paint(name)
                end
                if onChange then pcall(onChange) end
            end,
        }
    end

    local function countOn(map, list)
        local n = 0
        for _, name in ipairs(list) do
            if map[name] == true then n = n + 1 end
        end
        return n
    end

    local function allNoneRow(parent, onAll, onNone)
        local f = create("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
        }, parent)
        local function mk(text, xs, cb)
            local b = create("TextButton", {
                Position = UDim2.new(xs, xs == 0 and 0 or 3, 0, 0),
                Size = UDim2.new(0.5, -3, 1, 0),
                BackgroundColor3 = C.surface2,
                BorderSizePixel = 0,
                Text = text,
                TextColor3 = C.text,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                AutoButtonColor = true,
            }, f)
            corner(b, 8)
            b.MouseButton1Click:Connect(function() pcall(cb) end)
        end
        mk("ВЫБРАТЬ ВСЕ", 0, onAll)
        mk("СБРОСИТЬ", 0.5, onNone)
    end

    section(gamesFarmContainer, "СТАТУС")
    local statusCard = row(gamesFarmContainer, 52)
    stroke(statusCard, C.accent, 1, 0.5)
    local statusLbl = create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 6),
        Size = UDim2.new(1, -24, 1, -12),
        BackgroundTransparency = 1,
        Text = "Ready",
        TextColor3 = C.text,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, statusCard)

    task.spawn(function()
        while mainGui.Parent and h.alive do
            local okc, carried = pcall(Farm.GetTotalEggCount)
            local s = tostring(h.statusText or "Ready")
            if s:sub(1, 1) ~= "[" then s = "[" .. s .. "]" end
            local spd = getPlayerSpeed()
            statusLbl.Text = string.format("%s • Bag: %d • Speed: %s", s, okc and carried or 0, formatSpeed(spd))
            task.wait(0.25)
        end
    end)

    -- ============ КОНСОЛЬ ============
    local consoleToggle = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = C.surface2,
        BorderSizePixel = 0,
        Text = "ОТКРЫТЬ ИСТОРИЮ / КОНСОЛЬ",
        TextColor3 = C.text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
    }, gamesFarmContainer)
    corner(consoleToggle, 8)

    local consolePanel = create("Frame", {
        Size = UDim2.new(1, 0, 0, 238),
        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
    }, gamesFarmContainer)
    corner(consolePanel, 10)
    stroke(consolePanel, C.accent, 1, 0.55)

    local consoleScroll = create("ScrollingFrame", {
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 1, -54),
        BackgroundColor3 = C.surface2,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = C.accent,
        ScrollBarImageTransparency = 0.2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        Active = true,
    }, consolePanel)
    corner(consoleScroll, 7)

    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, consoleScroll)

    local consoleLogLabel = create("TextLabel", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "История пока пуста.",
        TextColor3 = C.text,
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = false,
    }, consoleScroll)

    local consoleClear = create("TextButton", {
        Position = UDim2.new(0, 8, 1, -38),
        Size = UDim2.new(0.5, -12, 0, 30),
        BackgroundColor3 = C.button,
        BorderSizePixel = 0,
        Text = "ОЧИСТИТЬ",
        TextColor3 = C.text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
    }, consolePanel)
    corner(consoleClear, 7)

    local consoleCopy = create("TextButton", {
        Position = UDim2.new(0.5, 4, 1, -38),
        Size = UDim2.new(0.5, -12, 0, 30),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
        Text = "КОПИРОВАТЬ",
        TextColor3 = C.text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
    }, consolePanel)
    corner(consoleCopy, 7)

    local consoleOpen = false
    local lastRenderedLogs = ""

    local function renderDiagnosticLogs(force)
        local logs = Farm.GetDiagnosticLogs and Farm.GetDiagnosticLogs() or {}
        local joined = #logs > 0
            and table.concat(logs, "\n")
            or "История пуста. Включи авто-кражу, чтобы записать события."

        if force or joined ~= lastRenderedLogs then
            consoleLogLabel.Text = joined
            lastRenderedLogs = joined

            task.defer(function()
                task.wait()
                pcall(function()
                    local target = math.max(0, consoleScroll.AbsoluteCanvasSize.Y - consoleScroll.AbsoluteSize.Y)
                    consoleScroll.CanvasPosition = Vector2.new(0, target)
                end)
            end)
        end
    end

    consoleToggle.MouseButton1Click:Connect(function()
        consoleOpen = not consoleOpen
        consolePanel.Visible = consoleOpen
        consoleToggle.Text = consoleOpen and "ЗАКРЫТЬ ИСТОРИЮ / КОНСОЛЬ" or "ОТКРЫТЬ ИСТОРИЮ / КОНСОЛЬ"
        if consoleOpen then
            renderDiagnosticLogs(true)
            Farm.AddDiagnosticLog("INFO", "Diagnostic console opened.")
            renderDiagnosticLogs(true)
        end
    end)

    consoleClear.MouseButton1Click:Connect(function()
        if Farm.ClearDiagnosticLogs then Farm.ClearDiagnosticLogs() end
        lastRenderedLogs = ""
        Farm.AddDiagnosticLog("INFO", "History cleared by user.")
        renderDiagnosticLogs(true)
    end)

    consoleCopy.MouseButton1Click:Connect(function()
        renderDiagnosticLogs(true)
        local copied = false
        if type(setclipboard) == "function" then
            copied = pcall(setclipboard, consoleLogLabel.Text)
        elseif type(toclipboard) == "function" then
            copied = pcall(toclipboard, consoleLogLabel.Text)
        elseif type(set_clipboard) == "function" then
            copied = pcall(set_clipboard, consoleLogLabel.Text)
        end
        if copied then
            toast("История скопирована", "ok")
        else
            toast("Нет доступа к буферу", "warn")
        end
        renderDiagnosticLogs(true)
    end)

    task.spawn(function()
        while mainGui.Parent and h.alive do
            if consoleOpen then renderDiagnosticLogs(false) end
            task.wait(0.5)
        end
    end)

    -- ============ РЕЖИМ ФАРМА ============
    section(gamesFarmContainer, "РЕЖИМ ФАРМА")
    local farmMode = "NONE"
    local tweenRow, warpRow

    local function zonesPicked()
        return countOn(h.selectedZones, Farm.ZoneList)
    end

    tweenRow = toggleRow(gamesFarmContainer, "Авто-кража (Tween)", "Плавный полёт к яйцу по коридору", false, function(on)
        if on then
            farmMode = "TWEEN"
            warpRow.set(false, true)
            Farm.SetFarmMode("TWEEN")
            if zonesPicked() == 0 then toast("Выбери хотя бы одну зону ↓", "warn") else toast("Tween-фарм запущен", "ok") end
        elseif farmMode == "TWEEN" then
            farmMode = "NONE"
            Farm.SetFarmMode("NONE")
            toast("Фарм остановлен", "warn")
        end
    end)

    warpRow = toggleRow(gamesFarmContainer, "Авто-кража (Teleport)", "Мгновенный варп к яйцу", false, function(on)
        if on then
            farmMode = "WARP"
            tweenRow.set(false, true)
            Farm.SetFarmMode("WARP")
            if zonesPicked() == 0 then toast("Выбери хотя бы одну зону ↓", "warn") else toast("Teleport-фарм запущен", "ok") end
        elseif farmMode == "WARP" then
            farmMode = "NONE"
            Farm.SetFarmMode("NONE")
            toast("Фарм остановлен", "warn")
        end
    end)

    toggleRow(gamesFarmContainer, "Авто-возврат", "После кражи лететь на безопасную линию", h.autoGlide ~= false, function(on)
        h.autoGlide = on
    end)

    -- ============ ЗОНЫ С ПОДПИСЯМИ СКОРОСТИ ============
    local zonesSection = section(gamesFarmContainer, "ЗОНЫ")
    local function refreshZoneLabel()
        local n = zonesPicked()
        zonesSection.Text = "ЗОНЫ  •  ВЫБРАНО " .. n .. " / " .. #Farm.ZoneList .. "  (берутся только они)"
    end
    local zoneGrid = zoneGridWithSpeed(gamesFarmContainer, Farm.ZoneList, h.selectedZones, Farm.ZoneColors, Farm.ZoneSpeedReq, function()
        Farm.SaveEggSelectConfig(h)
        refreshZoneLabel()
    end)
    allNoneRow(gamesFarmContainer, function() zoneGrid.setAll(true) end, function() zoneGrid.setAll(false) end)
    refreshZoneLabel()

    -- Автоперекраска зон каждые 3 сек (обновляет блокировку 🔒 при изменении Speed)
    task.spawn(function()
        while mainGui.Parent and h.alive do
            pcall(function() zoneGrid.repaint() end)
            task.wait(3)
        end
    end)

    -- ============ РЕДКОСТЬ ============
    local rarSection = section(gamesFarmContainer, "РЕДКОСТЬ")
    local function refreshRarLabel()
        rarSection.Text = "РЕДКОСТЬ  •  ВЫБРАНО " .. countOn(h.selectedRarities, Farm.RarityList) .. " / " .. #Farm.RarityList
    end
    local rarGrid = chipGrid(gamesFarmContainer, Farm.RarityList, h.selectedRarities, Farm.RarityColors, function()
        Farm.SaveEggSelectConfig(h)
        refreshRarLabel()
    end)
    allNoneRow(gamesFarmContainer, function() rarGrid.setAll(true) end, function() rarGrid.setAll(false) end)
    refreshRarLabel()

    -- ============ ЯЙЦА И БАЗА ============
    section(gamesFarmContainer, "ЯЙЦА И БАЗА")
    toggleRow(gamesFarmContainer, "Авто-размещение (каждые 5)", "Каждые 5 краж лететь домой и ставить яйца", h.autoPlaceEvery5 == true, function(on)
        h.autoPlaceEvery5 = on
        if not on then h.batchStealCount = 0 end
    end)
    toggleRow(gamesFarmContainer, "Авто-вылупление", "Вылупляет готовые яйца откуда угодно", h.autoHatch ~= false, function(on)
        h.autoHatch = on
    end)
    buttonRow(gamesFarmContainer, "ПОСТАВИТЬ ЯЙЦА СЕЙЧАС", function()
        toast("Ставлю яйца...", "ok")
        task.spawn(function()
            Farm.ExecuteManualPlaceSequence(h.glideSpeed, nil, true)
        end)
    end)
    toggleRow(gamesFarmContainer, "Авто-беговая дорожка", "Бежать на дорожке, пока нет целей", h.autoTreadmill ~= false, function(on)
        h.autoTreadmill = on
        Farm.SaveEggSelectConfig(h)
        if not on then
            pcall(Farm.ResetFarmStates)
            pcall(Farm.DoffTreadmillState)
            pcall(Farm.MountTreadmillOff)
            if Farm.FullRestore then pcall(Farm.FullRestore) end
            toast("Слез с дорожки, физика восстановлена", "ok")
        end
    end)
    toggleRow(gamesFarmContainer, "Авто-апгрейд дорожки", "Улучшать уровень, когда хватает денег", h.autoUpgradeTreadmill ~= false, function(on)
        h.autoUpgradeTreadmill = on
        Farm.SaveEggSelectConfig(h)
    end)
    toggleRow(gamesFarmContainer, "Авто-трейлы", "Покупать и надевать лучший трейл", h.autoBuyTrails ~= false, function(on)
        h.autoBuyTrails = on
        Farm.SaveEggSelectConfig(h)
    end)
    toggleRow(gamesFarmContainer, "Скрывать «Not enough money»", "Прячет красное уведомление игры", h.hideNotEnoughMoney ~= false, function(on)
        h.hideNotEnoughMoney = on
        Farm.SaveEggSelectConfig(h)
    end)

    -- ============ ПОЛЁТ / БЕЗОПАСНОСТЬ ============
    section(gamesFarmContainer, "ПОЛЁТ И БЕЗОПАСНОСТЬ")
    sliderRow(gamesFarmContainer, "Скорость полёта", 100, 1000, 25, h.glideSpeed or 600,
        function(v) h.glideSpeed = v end,
        function(v) Farm.SaveSpeed(v) end)
    toggleRow(gamesFarmContainer, "Desync Godmode", "Неуязвимость к ловушкам карты", h.godmode == true, function(on)
        Farm.SetDesyncGodmode(on)
    end)
    buttonRow(gamesFarmContainer, "ОСВОБОДИТЬСЯ / СЛЕЗТЬ С ДОРОЖКИ", function()
        Farm.ResetFarmStates()
        Farm.DoffTreadmillState()
        Farm.MountTreadmillOff()
        if Farm.FullRestore then pcall(Farm.FullRestore) end
        toast("Unstuck выполнен, физика восстановлена", "ok")
    end)
end

-- ============ TIMER HELPERS ============
local function formatRemaining(sec)
    if sec == nil then return "∞" end
    sec = tonumber(sec)
    if not sec then return "--" end
    if sec <= 0 then return "истек" end

    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)

    if d > 0 then return string.format("%dд %dч", d, h) end
    if h > 0 then return string.format("%dч %dм", h, m) end
    if m > 0 then return string.format("%dм %dс", m, s) end
    return string.format("%dс", s)
end

local function updateTimerLabel(remaining)
    if not timerLabel then return end

    timerLabel.Text = "⏱ " .. formatRemaining(remaining)

    if remaining == nil then
        timerLabel.TextColor3 = C.muted
    elseif remaining <= 60 then
        timerLabel.TextColor3 = C.red
    elseif remaining <= 300 then
        timerLabel.TextColor3 = C.yellow
    else
        timerLabel.TextColor3 = C.green
    end
end

-- ============ AUTH CALLBACK ============
onAuthSuccess = function(token)
    STATE.authed = true
    STATE.token = token

    if token then saveToken(token) end

    setStatus("Успешная авторизация!", "ok")
    authToast("Добро пожаловать!", "ok")

    task.spawn(function()
        task.wait(0.7)

        if authMain and authMain.Parent then
            local tw = TweenService:Create(authMain, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(authMain.Size.X.Offset * 0.88, authMain.Size.Y.Offset * 0.88),
            })
            tw:Play()
            tw.Completed:Wait()
        end

        if authGui and authGui.Parent then
            pcall(function() authGui:Destroy() end)
        end

        mainGui.Enabled = true
        STATE.mode = "window"

        task.spawn(function()
            local okFarm, errFarm = xpcall(initFarm, debug.traceback)
            if not okFarm then
                warn("[RH-HUB] Farm init failed: " .. tostring(errFarm))
            end
        end)

        task.spawn(function()
            local result = api("/verify", { token = token })
            if result and result.valid == true and result.remaining_seconds then
                updateTimerLabel(tonumber(result.remaining_seconds))
            else
                updateTimerLabel(nil)
            end
        end)

        print("[RH-HUB] Меню открыто.")
    end)
end

-- ============ HEARTBEAT ============
task.spawn(function()
    task.wait(2)

    local localRemaining = nil
    local heartbeatActive = true

    task.spawn(function()
        while heartbeatActive do
            if STATE.authed and localRemaining and localRemaining > 0 then
                localRemaining = localRemaining - 1
                updateTimerLabel(localRemaining)

                if localRemaining <= 0 then
                    clearToken()
                    STATE.authed = false
                    STATE.token = nil

                    if FarmApi then pcall(FarmApi.Shutdown) end
                    if mainGui and mainGui.Parent then pcall(function() mainGui:Destroy() end) end
                    if overlayGui and overlayGui.Parent then pcall(function() overlayGui:Destroy() end) end
                    if circleGui and circleGui.Parent then pcall(function() circleGui:Destroy() end) end
                    if rushGui and rushGui.Parent then pcall(function() rushGui:Destroy() end) end

                    pcall(function()
                        loadstring(game:HttpGet(
                            "https://raw.githubusercontent.com/RAHER458/TEST-0.0.1/main/esp.lua?t=" .. os.time()
                        ))()
                    end)
                    heartbeatActive = false
                    return
                end
            end
            task.wait(1)
        end
    end)

    while heartbeatActive do
        if STATE.authed and STATE.token then
            local result, err = api("/verify", { token = STATE.token })

            if result and result.valid == true then
                localRemaining = tonumber(result.remaining_seconds)
                updateTimerLabel(localRemaining)
            else
                local errText = tostring(err or ""):lower()
                local shouldKick = false

                if not result then
                    if errText:find("expired") or errText:find("invalid") or errText:find("403") then
                        shouldKick = true
                    end
                else
                    if result.valid ~= true then
                        shouldKick = true
                    end
                end

                if shouldKick then
                    clearToken()
                    STATE.authed = false
                    STATE.token = nil

                    if FarmApi then pcall(FarmApi.Shutdown) end
                    if mainGui and mainGui.Parent then pcall(function() mainGui:Destroy() end) end
                    if overlayGui and overlayGui.Parent then pcall(function() overlayGui:Destroy() end) end
                    if circleGui and circleGui.Parent then pcall(function() circleGui:Destroy() end) end
                    if rushGui and rushGui.Parent then pcall(function() rushGui:Destroy() end) end

                    pcall(function()
                        loadstring(game:HttpGet(
                            "https://raw.githubusercontent.com/RAHER458/TEST-0.0.1/main/esp.lua?t=" .. os.time()
                        ))()
                    end)
                    heartbeatActive = false
                    return
                end
            end
        end

        task.wait(5)
    end
end)

-- ============ INIT ============
selectTab("HOME")

_G.RH_HUB_AUTH = {
    authed = STATE.authed,
    token = STATE.token,
    device = STATE.deviceId,
    userId = LocalPlayer.UserId,
}

print("----------------------------------------")
print("RH-HUB INITIALIZED")
print("Version: " .. CONFIG.VERSION)
print("UserId: " .. tostring(LocalPlayer.UserId))
print("API: " .. CONFIG.API_BASE)
print("----------------------------------------")