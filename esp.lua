--[[
    RH-HUB
    Standalone Roblox Multi-Tool Hub
    Version: 1.0
    Platform: Roblox / Delta Executor / iOS
]]

-- ============ WAIT GAME ============
repeat task.wait() until game:IsLoaded()

-- ============ SERVICES ============
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local CONFIG = {
    VERSION     = "1.0",
    NAME        = "RH-HUB",
    API_BASE    = "https://raherauth.raher458.workers.dev",
    TOKEN_FILE  = "RH_HUB_TOKEN.dat",
    DEVICE_FILE = "RH_HUB_DEVICE.dat",
    TG_LINK     = "https://t.me/generalvaneska2024",
    TG_ICON     = "rbxassetid://104099125092946",
    TIMEOUT     = 10,
}

-- ============ COLORS ============
local C = {
    bg      = Color3.fromRGB(11, 12, 18),
    surface = Color3.fromRGB(20, 23, 32),
    surface2= Color3.fromRGB(28, 32, 45),
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

-- ============ CLEANUP ============
pcall(function()
    local core = game:GetService("CoreGui")
    local old = core:FindFirstChild("RH_HUB_GUI")
    if old then old:Destroy() end
    local oldAuth = core:FindFirstChild("RH_HUB_AUTH_GUI")
    if oldAuth then oldAuth:Destroy() end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local oldP = playerGui:FindFirstChild("RH_HUB_GUI")
        if oldP then oldP:Destroy() end
        local oldAP = playerGui:FindFirstChild("RH_HUB_AUTH_GUI")
        if oldAP then oldAP:Destroy() end
    end
end)

-- ============ STATE ============
local STATE = {
    authed   = false,
    token    = nil,
    deviceId = nil,
    busy     = false,
}

-- ============ HELPERS ============
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

-- ============ FILE API ============
local function hasFileAPI()
    return type(readfile) == "function"
       and type(writefile) == "function"
       and type(isfile) == "function"
end

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
        if ok and type(result) == "string" then
            return result
        end
    end
    return generateDeviceId()
end

STATE.deviceId = loadDeviceId()

-- ============ TOKEN ============
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

-- ============ HTTP ============
local function getRequestFn()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    return nil
end

local function api(path, body)
    local req = getRequestFn()
    if not req then
        return nil, "Executor не поддерживает HTTP-запросы"
    end

    local payload
    local encOK, encErr = pcall(function()
        payload = HttpService:JSONEncode(body or {})
    end)
    if not encOK then
        return nil, "Ошибка подготовки данных: " .. tostring(encErr)
    end

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
        return nil, "Не удалось выполнить запрос к серверу"
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
        return nil, "Сервер вернул некорректный ответ"
    end

    return decoded
end

-- ============ TOAST FACTORY ============
local function makeToast(guiObj, parentFrame)
    local container = create("Frame", {
        Position = UDim2.new(0, 0, 1, -220),
        Size = UDim2.new(1, 0, 0, 200),
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
        PaddingBottom = UDim.new(0, 16),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),
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
            Size = UDim2.new(1, 0, 0, 40),
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

-- ============ AUTH GUI ============
local authGui = create("ScreenGui", {
    Name = "RH_HUB_AUTH_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 99999,
})
safeParent(authGui)

local authBg = create("Frame", {
    Name = "Bg",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    BackgroundTransparency = 0.15,
}, authGui)

-- Главное окно авторизации (высота уменьшена до 420)
local authMain = create("Frame", {
    Name = "AuthWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(340, 420),
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
    local w = math.min(340, vp.X - 24)
    local h = math.min(420, vp.Y - 60)
    authMain.Size = UDim2.fromOffset(w, h)
end
authFit()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(authFit)
end

-- Header (высота 76)
local authHeader = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, authMain)
corner(authHeader, 18)
create("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.new(0, 0, 1X, -22),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, authHeader)

local authTitle = create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 12),
    Size = UDim2.new(1, -40, 0, 38),
    BackgroundTransparency = 1,
    Text = "RH-HUB",
    TextColor3 = C.pink,
    TextSize = 30,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextAlignment.Center,
}, authHeader)

create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 52),
    Size = UDim2.new(1, -40, 0, 16),
    BackgroundTransparency = 1,
    Text = "АВТОРИЗАЦИЯ • ВВЕДИТЕ КЛЮЧ",
    TextColor3 = C.muted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authHeader)

-- Радужная анимация
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

-- Замок (высота 24, сдвинут к 84)
create("TextLabel", {
    Position = UDim2.new(0.5, -14, 0, 84),
    Size = UDim2.fromOffset(28, 28),
    BackgroundTransparency = 1,
    Text = "🔒",
    TextColor3 = C.text,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authMain)

-- Описание (компактное)
create("TextLabel", {
    Position = UDim2.new(0, 22, 0, 116),
    Size = UDim2.new(1, -44, 0, 36),
    BackgroundTransparency = 1,
    Text = "Получите ключ у администратора и введите его ниже.\nОдин ключ работает на одном устройстве.",
    TextColor3 = C.muted,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Top,
}, authMain)

-- Заголовок поля
create("TextLabel", {
    Position = UDim2.new(0, 22, 0, 158),
    Size = UDim2.new(1, -44, 0, 14),
    BackgroundTransparency = 1,
    Text = "КЛЮЧ ДОСТУПА",
    TextColor3 = C.muted,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authMain)

-- Поле ввода (компактное, 44px)
local authInputWrap = create("Frame", {
    Position = UDim2.new(0, 22, 0, 176),
    Size = UDim2.new(1, -44, 0, 44),
    BackgroundColor3 = C.input,
    BorderSizePixel = 0,
}, authMain)
corner(authInputWrap, 11)
local authInputStroke = stroke(authInputWrap, C.border, 1.5, 0.1)

local authKeyBox = create("TextBox", {
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -56, 1, 0),
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
    Position = UDim2.new(1, -42, 0, 6),
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

-- Кнопка АКТИВИРОВАТЬ (высота 44)
local authActBtn = create("TextButton", {
    Position = UDim2.new(0, 22, 0, 232),
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

-- Кнопка ПОЛУЧИТЬ КЛЮЧ (высота 40)
local authTgBtn = create("TextButton", {
    Position = UDim2.new(0, 22, 0, 284),
    Size = UDim2.new(1, -44, 0, 40),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, authMain)
corner(authTgBtn, 11)
stroke(authTgBtn, C.pink, 1, 0.3)

create("ImageLabel", {
    Position = UDim2.new(0, 10, 0.5, -12),
    Size = UDim2.fromOffset(24, 24),
    BackgroundTransparency = 1,
    Image = CONFIG.TG_ICON,
    ScaleType = Enum.ScaleType.Fit,
}, authTgBtn)

local authTgLabel = create("TextLabel", {
    Position = UDim2.new(0, 42, 0, 0),
    Size = UDim2.new(1, -50, 1, 0),
    BackgroundTransparency = 1,
    Text = "ПОЛУЧИТЬ КЛЮЧ",
    TextColor3 = C.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authTgBtn)

-- Статус-строка (высота 30, привязана к низу)
local authStatus = create("TextLabel", {
    Position = UDim2.new(0, 22, 1, -40),
    Size = UDim2.new(1, -44, 0, 30),
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

-- ============ PASTE BUTTON ============
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
        setStatus("Ключ вставлен. Нажмите АКТИВИРОВАТЬ.", "ok")
        authToast("Ключ вставлен", "ok")
    else
        authToast("Буфер обмена пуст", "warn")
        setStatus("Не удалось прочитать буфер", "warn")
    end
end)

-- ============ TELEGRAM BUTTON ============
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

    authTgLabel.Text = copied and "ССЫЛКА СКОПИРОВАНА!" or "КОПИРУЙТЕ ВРУЧНУЮ"
    authTgLabel.TextColor3 = copied and C.green or C.yellow

    if copied then
        authToast("Вставьте ссылку в браузер", "ok")
        setStatus("Telegram: " .. CONFIG.TG_LINK, "ok")
    else
        authToast("Скопируйте ссылку вручную", "warn")
        setStatus("Ссылка: " .. CONFIG.TG_LINK, "warn")
    end

    task.delay(2.5, function()
        if authTgLabel.Parent then
            authTgLabel.Text = "ПОЛУЧИТЬ КЛЮЧ"
            authTgLabel.TextColor3 = C.text
        end
        tgCooldown = false
    end)
end)

-- ============ SUCCESS ============
local function onAuthSuccess(token)
    STATE.authed = true
    STATE.token = token

    if token then saveToken(token) end

    setStatus("Успешная авторизация!", "ok")
    authToast("Добро пожаловать в RH-HUB!", "ok")

    task.spawn(function()
        task.wait(0.8)

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

        if _G.RH_HUB_ON_AUTH_SUCCESS then
            pcall(_G.RH_HUB_ON_AUTH_SUCCESS, token)
        end
    end)
end

-- ============ ACTIVATE ============
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

-- ============ VERIFY ============
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

-- ============ AUTO CHECK ============
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

_G.RH_HUB_AUTH = {
    authed = false,
    token = nil,
    device = STATE.deviceId,
    userId = LocalPlayer.UserId,
}

-- ============ MAIN GUI (заглушка) ============
local mainGui = create("ScreenGui", {
    Name = "RH_HUB_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    Enabled = false,
})
safeParent(mainGui)

local mainStub = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(320, 180),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
}, mainGui)
corner(mainStub, 18)
stroke(mainStub, C.accent, 1.5, 0.2)

create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 20),
    Size = UDim2.new(1, -40, 0, 36),
    BackgroundTransparency = 1,
    Text = "RH-HUB",
    TextColor3 = C.pink,
    TextSize = 26,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Center,
}, mainStub)

create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 62),
    Size = UDim2.new(1, -40, 0, 22),
    BackgroundTransparency = 1,
    Text = "✓ Авторизация пройдена",
    TextColor3 = C.green,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
}, mainStub)

create("TextLabel", {
    Position = UDim2.new(0, 20, 0, 90),
    Size = UDim2.new(1, -40, 0, 40),
    BackgroundTransparency = 1,
    Text = "Здесь будет основное меню (следующий шаг).",
    TextColor3 = C.muted,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Top,
}, mainStub)

local logoutBtn = create("TextButton", {
    Position = UDim2.new(0, 20, 1, -58),
    Size = UDim2.new(1, -40, 0, 40),
    BackgroundColor3 = C.button,
    BorderSizePixel = 0,
    Text = "🔓 ВЫЙТИ",
    TextColor3 = C.text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, mainStub)
corner(logoutBtn, 11)
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
            "https://raw.githubusercontent.com/RAHER458/TEST-0.0.1/main/rh-hub.lua?t=" .. os.time()
        ))()
    end)
    if not ok then
        warn("[RH-HUB] Перезапуск не удался: " .. tostring(err))
    end
end)

-- ============ CALLBACK ============
_G.RH_HUB_ON_AUTH_SUCCESS = function(token)
    if _G.RH_HUB_AUTH then
        _G.RH_HUB_AUTH.authed = true
        _G.RH_HUB_AUTH.token = token
    end
    if mainGui then
        mainGui.Enabled = true
    end
    print("[RH-HUB] Меню открыто.")
end

if STATE.authed then
    mainGui.Enabled = true
    if _G.RH_HUB_AUTH then
        _G.RH_HUB_AUTH.authed = true
        _G.RH_HUB_AUTH.token = STATE.token
    end
end

-- ============ INIT ============
print("----------------------------------------")
print("RH-HUB INITIALIZED")
print("Version: " .. CONFIG.VERSION)
print("UserId: " .. tostring(LocalPlayer.UserId))
print("API: " .. CONFIG.API_BASE)
print("----------------------------------------")