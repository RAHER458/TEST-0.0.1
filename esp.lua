--[[
    RH-HUB
    Standalone Roblox Multi-Tool Hub
    Version: 1.2 "Heartbeat"
    Platform: Roblox / Delta Executor / iOS

    CHANGELOG 1.2:
      - Таймер оставшегося времени в хедере
      - Heartbeat: проверка каждые 5 секунд
      - Авто-выкид на авторизацию при истечении ключа
      - Исправлена логика кнопок «—» и «⌄»
]]

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    VERSION     = "1.2",
    NAME        = "RH-HUB",
    API_BASE    = "https://raherauth.raher458.workers.dev",
    TOKEN_FILE  = "RH_HUB_TOKEN.dat",
    DEVICE_FILE = "RH_HUB_DEVICE.dat",
    TG_LINK     = "https://t.me/generalvaneska2024",
    WINDOW_W    = 340,
    WINDOW_H    = 440,
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

-- CLEANUP
pcall(function()
    local core = game:GetService("CoreGui")
    for _, name in ipairs({"RH_HUB_GUI", "RH_HUB_AUTH_GUI", "RH_HUB_OVERLAY", "RH_HUB_CIRCLE"}) do
        local old = core:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, name in ipairs({"RH_HUB_GUI", "RH_HUB_AUTH_GUI", "RH_HUB_OVERLAY", "RH_HUB_CIRCLE"}) do
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
    mode     = "window",  -- "window" / "circle" / "overlay"
}

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

    local callOK, response = pcall(function()
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

    if not callOK or type(response) ~= "table" then
        return nil, "Не удалось выполнить запрос"
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

local function makeToast(guiObj, parentFrame)
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

-- AUTH GUI
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

local authToast = makeToast(authGui, authGui)

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

        local body = {
            key = key,
            install_hash = STATE.deviceId,
        }

        local result, err = api("/activate", body)

        if not result then
            setBusy(false)
            local msg = tostring(err or "неизвестная ошибка")
            local low = msg:lower()

            if low:find("invalid license") then
                setStatus("❌ Неверный ключ", "err")
                authToast("Неверный ключ", "err")
            elseif low:find("bound to another") then
                setStatus("❌ Ключ привязан к другому устройству", "err")
                authToast("Ключ занят", "err")
            elseif low:find("expired") then
                setStatus("❌ Ключ истёк", "err")
                authToast("Ключ истёк", "err")
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

-- [КОНЕЦ ЧАСТИ 1]

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

-- Таймер оставшегося времени (в хедере)
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
        Size = UDim2.new(1/6, -3, 1, 0),
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

-- ============ HOME ============
section(homePage, "ГЛАВНАЯ")
infoCard(homePage, "RH-HUB  •  МУЛЬТИ-ИНСТРУМЕНТ", "Добро пожаловать. Используй вкладки для перехода к функциям.")
infoCard(homePage, "АВТОРИЗАЦИЯ ПРОЙДЕНА", "Твой токен сохранён. При следующем запуске вход автоматический.")
infoCard(homePage, "ТАЙМЕР КЛЮЧА", "Справа вверху видно оставшееся время действия ключа. Когда заканчивается — перезапуск на авторизацию.")
infoCard(homePage, "РЕЖИМ ОВЕРЛЕЯ", "«—» — оверлей RH | FPS | PING. «⌄» — свёрнуть в кружок HUB.")

-- ============ MOVE ============
section(movePage, "ДВИЖЕНИЕ")
soonCard(movePage)

-- ============ VISUAL ============
section(visualPage, "ВИЗУАЛИЗАЦИЯ")
soonCard(visualPage)

-- ============ TELEPORT ============
section(tpPage, "ТЕЛЕПОРТ")
soonCard(tpPage)

-- ============ SETTINGS ============
section(settingsPage, "НАСТРОЙКИ")
infoCard(settingsPage, "КНОПКА ВЫХОДА", "Выход из аккаунта — сброс сохранённого токена. При следующем запуске — экран авторизации.")

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

-- [КОНЕЦ ЧАСТИ 2]


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

-- ============ OVERLAY (RH | FPS | PING) ============
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

-- Драг оверлея
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

-- ============ CIRCLE (Кружок HUB) ============
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
            -- Тап по кружку → вернуть окно
            circleGui.Enabled = false
            mainGui.Enabled = true
            STATE.mode = "window"
        end
    end
end)

-- ============ MINIMIZE / CIRCLE / OVERLAY LOGIC ============

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

-- «—» → оверлей (туда-обратно)
minimizeBtn.MouseButton1Click:Connect(function()
    if STATE.mode == "window" then
        setMode("overlay")
    elseif STATE.mode == "overlay" then
        setMode("window")
    end
end)

-- «⌄» → кружок HUB
circleBtn.MouseButton1Click:Connect(function()
    if STATE.mode == "window" then
        setMode("circle")
    end
end)

-- Двойной тап по оверлею → вернуть окно
local lastOverlayTap = 0
overlayFrame.MouseButton1Click:Connect(function()
    local now = os.clock()
    if now - lastOverlayTap < 0.6 then
        setMode("window")
    end
    lastOverlayTap = now
end)

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
        timerLabel.TextColor3 = C.muted       -- ∞
    elseif remaining <= 60 then
        timerLabel.TextColor3 = C.red         -- срочно
    elseif remaining <= 300 then
        timerLabel.TextColor3 = C.yellow      -- 5 мин
    else
        timerLabel.TextColor3 = C.green       -- долго
    end
end

-- ============ AUTH CALLBACK ============
local onAuthSuccess = function(token)
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

        -- Открываем меню + запускаем таймер
        mainGui.Enabled = true
        STATE.mode = "window"

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

-- ============ HEARTBEAT (5 сек) + ТАЙМЕР ============
task.spawn(function()
    task.wait(2)

    local localRemaining = nil
    local heartbeatActive = true

    -- Локальный счётчик — раз в секунду
    task.spawn(function()
        while heartbeatActive do
            if STATE.authed and localRemaining and localRemaining > 0 then
                localRemaining = localRemaining - 1
                updateTimerLabel(localRemaining)

                if localRemaining <= 0 then
                    clearToken()
                    STATE.authed = false
                    STATE.token = nil

                    if mainGui and mainGui.Parent then pcall(function() mainGui:Destroy() end) end
                    if overlayGui and overlayGui.Parent then pcall(function() overlayGui:Destroy() end) end
                    if circleGui and circleGui.Parent then pcall(function() circleGui:Destroy() end) end

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

    -- Опрос сервера раз в 5 секунд
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

                    if mainGui and mainGui.Parent then pcall(function() mainGui:Destroy() end) end
                    if overlayGui and overlayGui.Parent then pcall(function() overlayGui:Destroy() end) end
                    if circleGui and circleGui.Parent then pcall(function() circleGui:Destroy() end) end

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

-- [КОНЕЦ ЧАСТИ 3]
-- [[ КОНЕЦ ФАЙЛА ]]