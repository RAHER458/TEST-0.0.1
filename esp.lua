-- =====================================================================
-- RAHERHUB AUTH SYSTEM  |  v1.0
-- Встроено после loading screen, до создания основного меню.
-- Пока не пройдена авторизация — основное меню НЕ создаётся.
-- =====================================================================

local AUTH_API_BASE = "https://raherauth.raher458.workers.dev"
local AUTH_TOKEN_FILE = "RAHERHUB_TOKEN.dat"
local AUTH_DEVICE_FILE = "RAHERHUB_DEVICE.dat"
local AUTH_TELEGRAM_LINK = "https://t.me/generalvaneska2024"
local AUTH_TELEGRAM_ICON = "rbxassetid://138727397408628"

local AUTH_COLORS = {
    bg        = Color3.fromRGB(13, 15, 22),
    panel     = Color3.fromRGB(21, 24, 34),
    panel2    = Color3.fromRGB(29, 33, 46),
    button    = Color3.fromRGB(37, 42, 57),
    input     = Color3.fromRGB(24, 27, 38),
    text      = Color3.fromRGB(244, 246, 255),
    muted     = Color3.fromRGB(155, 163, 184),
    accent    = Color3.fromRGB(105, 115, 255),
    pink      = Color3.fromRGB(255, 80, 190),
    green     = Color3.fromRGB(48, 210, 130),
    red       = Color3.fromRGB(220, 75, 88),
    yellow    = Color3.fromRGB(255, 190, 70),
    border    = Color3.fromRGB(70, 75, 110),
}

local AUTH_STATE = {
    authed = false,
    token = nil,
    deviceId = nil,
    busy = false,
}

-- Утилиты создания UI (не конфликтуют с существующим кодом)
local function authMake(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function authCorner(parent, radius)
    return authMake("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

local function authStroke(parent, color, thickness, transparency)
    return authMake("UIStroke", {
        Color = color or AUTH_COLORS.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.2,
    }, parent)
end

-- HTTP request (совместимость с Delta и другими)
local function authGetRequest()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    return nil
end

local function authApiRequest(path, body, useAdmin)
    local req = authGetRequest()
    if not req then return nil, "Executor не поддерживает HTTP." end

    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
    }
    if useAdmin and AUTH_STATE.adminSecret then
        headers["X-Admin-Secret"] = AUTH_STATE.adminSecret
    end

    local payload
    local encoded, encErr = pcall(function()
        payload = HttpService:JSONEncode(body or {})
    end)
    if not encoded then return nil, "Ошибка подготовки JSON." end

    local ok, response = pcall(function()
        return req({
            Url = AUTH_API_BASE .. path,
            Method = "POST",
            Headers = headers,
            Body = payload,
        })
    end)
    if not ok or type(response) ~= "table" then
        return nil, "Не удалось выполнить HTTPS-запрос."
    end

    local status = tonumber(response.StatusCode or response.Status or 0) or 0
    local raw = response.Body or response.body or ""

    local decodedOK, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if status < 200 or status >= 300 then
        local message
        if decodedOK and type(decoded) == "table" then
            message = decoded.error or decoded.message
        end
        return nil, tostring(message or ("HTTP " .. status))
    end

    if not decodedOK or type(decoded) ~= "table" then
        return nil, "Некорректный ответ сервера."
    end

    return decoded
end

-- Device ID (генерируется 1 раз, сохраняется в файл)
local function authGenerateDeviceId()
    return "RH-" .. HttpService:GenerateGUID(false)
end

local function authLoadDeviceId()
    if type(readfile) ~= "function" or type(writefile) ~= "function" then
        return authGenerateDeviceId()
    end

    local ok, result = pcall(function()
        if type(isfile) == "function" and isfile(AUTH_DEVICE_FILE) then
            local val = readfile(AUTH_DEVICE_FILE)
            if type(val) == "string" and #val >= 16 then
                return val
            end
        end
        local val = authGenerateDeviceId()
        writefile(AUTH_DEVICE_FILE, val)
        return val
    end)

    if ok and type(result) == "string" then return result end
    return authGenerateDeviceId()
end

AUTH_STATE.deviceId = authLoadDeviceId()

-- Token (сохраняется после успешной активации)
local function authSaveToken(token)
    if type(writefile) ~= "function" then return false end
    return pcall(writefile, AUTH_TOKEN_FILE, tostring(token))
end

local function authLoadToken()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return nil end
    local ok, result = pcall(function()
        if isfile(AUTH_TOKEN_FILE) then
            local val = readfile(AUTH_TOKEN_FILE)
            if type(val) == "string" and #val >= 16 then return val end
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local function authClearToken()
    if type(delfile) == "function" and type(isfile) == "function" then
        pcall(function()
            if isfile(AUTH_TOKEN_FILE) then delfile(AUTH_TOKEN_FILE) end
        end)
    end
end

-- Clipboard helpers
local function authCopyToClipboard(text)
    if type(setclipboard) == "function" then
        return pcall(setclipboard, text)
    end
    if type(toclipboard) == "function" then
        return pcall(toclipboard, text)
    end
    return false
end

-- [КОНЕЦ ЧАСТИ 1]

-- =====================================================================
-- UI: экран регистрации
-- =====================================================================

-- Скрываем основной ScreenGui, пока авторизация не пройдена
-- (если он уже создан и пуст — просто отключим)
if gui then
    pcall(function() gui.Enabled = false end)
end

-- Свой изолированный ScreenGui для регистрации
local authGui = authMake("ScreenGui", {
    Name = "RAHERHUB_AUTH_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 99999,
})
pcall(function() authGui.Parent = game:GetService("CoreGui") end)
if not authGui.Parent then
    authGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Анимированное появление основного контейнера
local authMain = authMake("Frame", {
    Name = "AuthWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(340, 430),
    BackgroundColor3 = AUTH_COLORS.bg,
    BorderSizePixel = 0,
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, authGui)
authCorner(authMain, 18)
authStroke(authMain, AUTH_COLORS.border, 1, 0.15)

-- Адаптация под экран
local function authFitPanel()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local vp = camera.ViewportSize
    local w = math.min(360, vp.X - 24)
    local h = math.min(450, vp.Y - 60)
    authMain.Size = UDim2.fromOffset(w, h)
end
authFitPanel()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(authFitPanel)
end

-- Появление с анимацией
task.spawn(function()
    authMain.Size = UDim2.fromOffset(authMain.Size.X.Offset * 0.88, authMain.Size.Y.Offset * 0.88)
    TweenService:Create(authMain, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(math.min(360, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 360) - 24), math.min(450, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 450) - 60)),
        BackgroundTransparency = 0,
    }):Play()
end)

-- Верхний градиентный «header» для красоты
local authHeader = authMake("Frame", {
    Name = "AuthHeader",
    Size = UDim2.new(1, 0, 0, 92),
    BackgroundColor3 = AUTH_COLORS.panel,
    BorderSizePixel = 0,
}, authMain)
authCorner(authHeader, 18)
authMake("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.new(0, 0, 1, -22),
    BackgroundColor3 = AUTH_COLORS.panel,
    BorderSizePixel = 0,
}, authHeader)

-- Радужный логотип (как в основном меню)
local authTitle = authMake("TextLabel", {
    Position = UDim2.new(0, 20, 0, 18),
    Size = UDim2.new(1, -40, 0, 40),
    BackgroundTransparency = 1,
    Text = "RAHERHUB",
    TextColor3 = Color3.fromRGB(255, 80, 190),
    TextSize = 30,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authHeader)

authMake("TextLabel", {
    Position = UDim2.new(0, 20, 0, 58),
    Size = UDim2.new(1, -40, 0, 18),
    BackgroundTransparency = 1,
    Text = "АВТОРИЗАЦИЯ • ВВЕДИТЕ КЛЮЧ",
    TextColor3 = AUTH_COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authHeader)

-- Радужная анимация логотипа
task.spawn(function()
    local hue = 0
    while authGui.Parent do
        hue = (hue + 0.01) % 1
        if authTitle.Parent then
            authTitle.TextColor3 = Color3.fromHSV(hue, 0.7, 1)
        end
        task.wait(0.05)
    end
end)

-- Иконка «замок» под логотипом
authMake("TextLabel", {
    Position = UDim2.new(0.5, -16, 0, 96),
    Size = UDim2.fromOffset(32, 32),
    BackgroundTransparency = 1,
    Text = "🔒",
    TextColor3 = AUTH_COLORS.text,
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
}, authMain)

authMake("TextLabel", {
    Position = UDim2.new(0, 24, 0, 130),
    Size = UDim2.new(1, -48, 0, 36),
    BackgroundTransparency = 1,
    Text = "Получите ключ у администратора и введите его ниже. Один ключ работает на одном устройстве.",
    TextColor3 = AUTH_COLORS.muted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Top,
}, authMain)

-- Заголовок поля
authMake("TextLabel", {
    Position = UDim2.new(0, 24, 0, 178),
    Size = UDim2.new(1, -48, 0, 16),
    BackgroundTransparency = 1,
    Text = "КЛЮЧ ДОСТУПА",
    TextColor3 = AUTH_COLORS.muted,
    TextSize = 9,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authMain)

-- [КОНЕЦ ЧАСТИ 2]

-- =====================================================================
-- UI: поле ввода ключа + кнопки
-- =====================================================================

-- Поле ввода ключа
local authInputWrap = authMake("Frame", {
    Position = UDim2.new(0, 24, 0, 198),
    Size = UDim2.new(1, -48, 0, 48),
    BackgroundColor3 = AUTH_COLORS.input,
    BorderSizePixel = 0,
}, authMain)
authCorner(authInputWrap, 12)
local authInputStroke = authStroke(authInputWrap, AUTH_COLORS.border, 1.5, 0.1)

local authKeyBox = authMake("TextBox", {
    Position = UDim2.new(0, 14, 0, 0),
    Size = UDim2.new(1, -56, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "RAH-XXXXXXXXXXXXXXXX",
    PlaceholderColor3 = AUTH_COLORS.muted,
    TextColor3 = AUTH_COLORS.text,
    TextSize = 13,
    Font = Enum.Font.Code,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authInputWrap)

-- Кнопка «вставить из буфера»
local authPasteBtn = authMake("TextButton", {
    Position = UDim2.new(1, -46, 0, 8),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = AUTH_COLORS.button,
    BorderSizePixel = 0,
    Text = "📋",
    TextColor3 = AUTH_COLORS.text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, authInputWrap)
authCorner(authPasteBtn, 10)

-- Фокус — подсветка рамки
authKeyBox.Focused:Connect(function()
    TweenService:Create(authInputStroke, TweenInfo.new(0.15), {
        Color = AUTH_COLORS.accent,
        Transparency = 0,
    }):Play()
end)
authKeyBox.FocusLost:Connect(function()
    TweenService:Create(authInputStroke, TweenInfo.new(0.15), {
        Color = AUTH_COLORS.border,
        Transparency = 0.1,
    }):Play()
end)

-- Кнопка «АКТИВИРОВАТЬ»
local authActivateBtn = authMake("TextButton", {
    Position = UDim2.new(0, 24, 0, 260),
    Size = UDim2.new(1, -48, 0, 50),
    BackgroundColor3 = AUTH_COLORS.accent,
    BorderSizePixel = 0,
    Text = "✨  АКТИВИРОВАТЬ",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false,
}, authMain)
authCorner(authActivateBtn, 13)

-- Кнопка «ПОЛУЧИТЬ КЛЮЧ» (Telegram)
local authTelegramBtn = authMake("TextButton", {
    Position = UDim2.new(0, 24, 0, 322),
    Size = UDim2.new(1, -48, 0, 46),
    BackgroundColor3 = AUTH_COLORS.button,
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = AUTH_COLORS.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true,
}, authMain)
authCorner(authTelegramBtn, 12)
authStroke(authTelegramBtn, AUTH_COLORS.pink, 1, 0.3)

-- Иконка Telegram (слева)
local authTgIcon = authMake("ImageLabel", {
    Position = UDim2.new(0, 12, 0.5, -14),
    Size = UDim2.fromOffset(28, 28),
    BackgroundTransparency = 1,
    Image = AUTH_TELEGRAM_ICON,
    ScaleType = Enum.ScaleType.Fit,
}, authTelegramBtn)

-- Текст кнопки Telegram
local authTgLabel = authMake("TextLabel", {
    Position = UDim2.new(0, 48, 0, 0),
    Size = UDim2.new(1, -56, 1, 0),
    BackgroundTransparency = 1,
    Text = "ПОЛУЧИТЬ КЛЮЧ",
    TextColor3 = AUTH_COLORS.text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, authTelegramBtn)

-- Статус-строка
local authStatus = authMake("TextLabel", {
    Position = UDim2.new(0, 24, 1, -58),
    Size = UDim2.new(1, -48, 0, 40),
    BackgroundTransparency = 1,
    Text = "Ожидание ввода...",
    TextColor3 = AUTH_COLORS.muted,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
}, authMain)

-- Менеджер статуса
local function authSetStatus(text, kind)
    authStatus.Text = tostring(text)
    if kind == "ok" then
        authStatus.TextColor3 = AUTH_COLORS.green
    elseif kind == "err" then
        authStatus.TextColor3 = AUTH_COLORS.red
    elseif kind == "warn" then
        authStatus.TextColor3 = AUTH_COLORS.yellow
    else
        authStatus.TextColor3 = AUTH_COLORS.muted
    end
end

-- Кнопка «АКТИВИРОВАТЬ» — визуальная реакция
authActivateBtn.MouseEnter:Connect(function()
    TweenService:Create(authActivateBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(125, 135, 255),
    }):Play()
end)
authActivateBtn.MouseLeave:Connect(function()
    TweenService:Create(authActivateBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = AUTH_COLORS.accent,
    }):Play()
end)
authActivateBtn.MouseButton1Down:Connect(function()
    TweenService:Create(authActivateBtn, TweenInfo.new(0.06), {
        Size = UDim2.new(1, -52, 0, 50),
    }):Play()
end)
authActivateBtn.MouseButton1Up:Connect(function()
    TweenService:Create(authActivateBtn, TweenInfo.new(0.1), {
        Size = UDim2.new(1, -48, 0, 50),
    }):Play()
end)

-- Кнопка Telegram — визуальная реакция
authTelegramBtn.MouseEnter:Connect(function()
    TweenService:Create(authTelegramBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = AUTH_COLORS.panel2,
    }):Play()
end)
authTelegramBtn.MouseLeave:Connect(function()
    TweenService:Create(authTelegramBtn, TweenInfo.new(0.12), {
        BackgroundColor3 = AUTH_COLORS.button,
    }):Play()
end)

-- [КОНЕЦ ЧАСТИ 3]

-- =====================================================================
-- UI: Toast-уведомления (отдельные от основного меню)
-- =====================================================================

local authToastContainer = authMake("Frame", {
    Position = UDim2.new(0, 0, 1, -220),
    Size = UDim2.new(1, 0, 0, 200),
    BackgroundTransparency = 1,
    ZIndex = 200,
}, authGui)

authMake("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, authToastContainer)

authMake("UIPadding", {
    PaddingBottom = UDim.new(0, 16),
    PaddingLeft = UDim.new(0, 20),
    PaddingRight = UDim.new(0, 20),
}, authToastContainer)

local authToastCounter = 0

local function authToast(text, kind)
    authToastCounter = authToastCounter + 1

    local color = kind == "ok" and AUTH_COLORS.green
              or kind == "err" and AUTH_COLORS.red
              or kind == "warn" and AUTH_COLORS.yellow
              or AUTH_COLORS.accent

    local toast = authMake("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = AUTH_COLORS.panel2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = authToastCounter,
    }, authToastContainer)
    authCorner(toast, 10)

    authMake("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, toast)

    authMake("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = AUTH_COLORS.text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, toast)

    TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 40),
    }):Play()

    task.delay(3.2, function()
        if toast.Parent then
            TweenService:Create(toast, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.2)
            toast:Destroy()
        end
    end)
end

-- =====================================================================
-- Логика кнопки «ВСТАВИТЬ ИЗ БУФЕРА»
-- =====================================================================

authPasteBtn.MouseButton1Click:Connect(function()
    if AUTH_STATE.busy then return end

    local value = nil

    if type(getclipboard) == "function" then
        local ok, v = pcall(getclipboard)
        if ok and type(v) == "string" and v ~= "" then
            value = v
        end
    end

    if not value and type(getClipboard) == "function" then
        local ok, v = pcall(getClipboard)
        if ok and type(v) == "string" and v ~= "" then
            value = v
        end
    end

    if value and value ~= "" then
        -- Очищаем от пробелов и переносов
        value = value:gsub("%s+", "")
        authKeyBox.Text = value
        authSetStatus("Ключ вставлен из буфера. Нажмите АКТИВИРОВАТЬ.", "ok")
        authToast("Ключ вставлен", "ok")
    else
        authToast("Буфер обмена пуст или недоступен", "warn")
        authSetStatus("Не удалось прочитать буфер обмена", "warn")
    end
end)

-- =====================================================================
-- Логика кнопки «ПОЛУЧИТЬ КЛЮЧ» (Telegram)
-- =====================================================================

-- Визуальный «статус» для кнопки Telegram
local authTgCooldown = false

authTelegramBtn.MouseButton1Click:Connect(function()
    if authTgCooldown then return end
    authTgCooldown = true

    -- Копируем ссылку
    local copied = authCopyToClipboard(AUTH_TELEGRAM_LINK)

    -- Меняем текст кнопки на время
    authTgLabel.Text = copied and "ССЫЛКА СКОПИРОВАНА!" or "КОПИРУЙТЕ ВРУЧНУЮ"
    authTgLabel.TextColor3 = copied and AUTH_COLORS.green or AUTH_COLORS.yellow

    -- Toast с подсказкой
    if copied then
        authToast("Ссылка скопирована! Вставьте её в браузер", "ok")
        authSetStatus("Telegram: " .. AUTH_TELEGRAM_LINK, "ok")
    else
        authToast("Не удалось скопировать автоматически", "warn")
        authSetStatus("Ссылка: " .. AUTH_TELEGRAM_LINK, "warn")
    end

    task.delay(2.5, function()
        if authTgLabel.Parent then
            authTgLabel.Text = "ПОЛУЧИТЬ КЛЮЧ"
            authTgLabel.TextColor3 = AUTH_COLORS.text
        end
        authTgCooldown = false
    end)
end)

-- [КОНЕЦ ЧАСТИ 4]

-- =====================================================================
-- Логика авторизации: /activate и /verify
-- =====================================================================

-- Универсальный «запуск задачи» для кнопки активации
local function authSetBusy(busy)
    AUTH_STATE.busy = busy
    if busy then
        authActivateBtn.Text = "⏳  ПРОВЕРКА..."
        authActivateBtn.BackgroundColor3 = AUTH_COLORS.panel2
        authActivateBtn.AutoButtonColor = false
    else
        authActivateBtn.Text = "✨  АКТИВИРОВАТЬ"
        authActivateBtn.BackgroundColor3 = AUTH_COLORS.accent
        authActivateBtn.AutoButtonColor = false
    end
end

-- Успешная авторизация
local function authSuccess(token)
    AUTH_STATE.authed = true
    AUTH_STATE.token = token
    authSaveToken(token)

    authSetStatus("Успешная авторизация! Запуск RAHERHUB...", "ok")
    authToast("Добро пожаловать в RAHERHUB!", "ok")

    -- Анимация исчезновения
    task.spawn(function()
        task.wait(0.8)
        TweenService:Create(authMain, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(authMain.Size.X.Offset * 0.85, authMain.Size.Y.Offset * 0.85),
        }):Play()
        task.wait(0.45)
        if authGui then authGui:Destroy() end
    end)
end

-- Активация ключа
local function authActivate(key)
    key = tostring(key or ""):gsub("%s+", "")
    if key == "" then
        authSetStatus("Введите ключ доступа", "warn")
        authToast("Ключ пустой", "warn")
        return
    end

    if AUTH_STATE.busy then return end
    authSetBusy(true)
    authSetStatus("Активация ключа...", "info")

    task.spawn(function()
        local body = {
            key = key,
            install_hash = AUTH_STATE.deviceId,
            roblox_user_id = tostring(LocalPlayer.UserId),
        }

        local result, err = authApiRequest("/activate", body, false)

        if not result then
            authSetBusy(false)
            local msg = tostring(err or "неизвестная ошибка")

            if msg:find("Invalid license") then
                authSetStatus("❌ Неверный ключ или ключ не существует", "err")
                authToast("Неверный ключ", "err")
            elseif msg:find("bound to another") then
                authSetStatus("❌ Ключ уже привязан к другому устройству", "err")
                authToast("Ключ занят другим устройством", "err")
            elseif msg:find("expired") then
                authSetStatus("❌ Ключ истёк. Обратитесь к администратору", "err")
                authToast("Ключ истёк", "err")
            elseif msg:find("HTTP 401") or msg:find("Unauthorized") then
                authSetStatus("❌ Ошибка авторизации на сервере", "err")
                authToast("Ошибка сервера", "err")
            else
                authSetStatus("❌ Ошибка: " .. msg, "err")
                authToast(msg, "err")
            end
            return
        end

        if type(result.token) ~= "string" or result.token == "" then
            authSetBusy(false)
            authSetStatus("❌ Сервер вернул пустой токен", "err")
            authToast("Сервер не выдал токен", "err")
            return
        end

        authSetBusy(false)
        authSuccess(result.token)
    end)
end

-- Проверка сохранённого токена при запуске
local function authVerifySavedToken(token)
    if type(token) ~= "string" or token == "" then return false end

    local result, err = authApiRequest("/verify", { token = token }, false)

    if not result then return false end
    if result.valid ~= true then return false end
    if result.error == "License expired" then
        authClearToken()
        return false, "expired"
    end

    return true
end

-- [КОНЕЦ ЧАСТИ 5]

-- =====================================================================
-- Привязка кнопок и запуск проверки
-- =====================================================================

-- Клик по АКТИВИРОВАТЬ
authActivateBtn.MouseButton1Click:Connect(function()
    if AUTH_STATE.busy then return end
    authActivate(authKeyBox.Text)
end)

-- Enter в поле ключа = активация
authKeyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and not AUTH_STATE.busy then
        authActivate(authKeyBox.Text)
    end
end)

-- Автоматическая проверка сохранённого токена при старте
task.spawn(function()
    task.wait(0.3)

    local savedToken = authLoadToken()
    if not savedToken then
        authSetStatus("Введите ключ доступа для начала работы.", "info")
        return
    end

    authSetStatus("Проверка сохранённой сессии...", "info")
    authSetBusy(true)

    local valid, reason = authVerifySavedToken(savedToken)

    if valid then
        authSetBusy(false)
        authSuccess(savedToken)
    else
        authSetBusy(false)
        authClearToken()

        if reason == "expired" then
            authSetStatus("⏱ Ключ истёк. Введите новый ключ у администратора.", "warn")
            authToast("Ключ истёк — нужен новый", "warn")
        else
            authSetStatus("Сессия недействительна. Введите ключ заново.", "warn")
        end
    end
end)

-- =====================================================================
-- БЛОКИРУЮЩЕЕ ОЖИДАНИЕ АВТОРИЗАЦИИ
-- После вызова этой функции код ниже НЕ выполняется, пока не будет
-- успешной авторизации. Возвращает управление только после успеха.
-- =====================================================================

local function requireAuthOrExit()
    if AUTH_STATE.authed then return end
    while not AUTH_STATE.authed do
        task.wait(0.15)
    end
end

-- Ждём авторизацию
requireAuthOrExit()

-- После успешной авторизации:
-- 1. Удаляем экран авторизации (если ещё существует)
-- 2. Включаем основной ScreenGui
-- 3. Скрипт продолжается — создаётся основное меню

if authGui and authGui.Parent then
    pcall(function() authGui:Destroy() end)
end

if gui then
    pcall(function() gui.Enabled = true end)
end

-- Глобальная метка, чтобы основной скрипт мог при желании проверить статус
_G.RAHERHUB_AUTH = {
    authed = true,
    token = AUTH_STATE.token,
    device = AUTH_STATE.deviceId,
    userId = LocalPlayer.UserId,
}

print("[RAHERHUB] Авторизация успешна. Запуск основного меню...")

-- [КОНЕЦ ЧАСТИ 6]
-- =====================================================================
-- ДАЛЬШЕ ИДЁТ ТВОЙ ОРИГИНАЛЬНЫЙ КОД:
-- local COLORS = { ... }
-- local main = make("Frame", ...)
-- и т.д.
-- =====================================================================