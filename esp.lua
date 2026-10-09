--[[
    RH-AUTH
    Standalone Authentication & License Admin Panel
    Version: 1.1 "Bubble"
    Platform: Roblox / Delta Executor / iOS
    Language: Russian

    Project: RH-Auth
    Separate from RAHERHUB.

    Cloudflare Worker:
    https://raherauth.raher458.workers.dev/

    CHANGELOG 1.1:
      - Кнопка «—» сворачивает окно в полоску хедера
      - Кнопка «×» скрывает окно и показывает плавающий кружок RH
      - Кружок RH перетаскивается пальцем по экрану
      - Тап по кружку открывает окно обратно
      - Плавные анимации появления/скрытия
]]

repeat task.wait() until game:IsLoaded()

--==================================================
-- 1. SERVICES
--==================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- 2. CONFIGURATION
--==================================================

local VERSION = "1.1 Bubble"

local API_BASE =
    "https://raherauth.raher458.workers.dev"

local DEVICE_FILE = "RH_AUTH_DEVICE.dat"

local COLORS = {
    Background = Color3.fromRGB(13, 15, 23),
    Window = Color3.fromRGB(20, 23, 34),
    Panel = Color3.fromRGB(28, 32, 46),
    Panel2 = Color3.fromRGB(35, 40, 56),

    Accent = Color3.fromRGB(100, 90, 255),
    Accent2 = Color3.fromRGB(70, 130, 255),

    Green = Color3.fromRGB(70, 220, 145),
    Red = Color3.fromRGB(255, 85, 105),
    Yellow = Color3.fromRGB(255, 195, 75),

    Text = Color3.fromRGB(240, 242, 255),
    Muted = Color3.fromRGB(145, 153, 177),
    Border = Color3.fromRGB(52, 59, 80),
}

--==================================================
-- 3. SAFE CLEANUP
--==================================================

pcall(function()
    local old = PlayerGui:FindFirstChild("RH_AUTH_GUI")
    if old then old:Destroy() end
end)

pcall(function()
    local old = CoreGui:FindFirstChild("RH_AUTH_GUI")
    if old then old:Destroy() end
end)

--==================================================
-- 4. HTTP REQUEST SUPPORT
--==================================================

local function getRequestFunction()
    if type(request) == "function" then
        return request
    end

    if type(http_request) == "function" then
        return http_request
    end

    if type(syn) == "table"
        and type(syn.request) == "function" then

        return syn.request
    end

    return nil
end

local function apiRequest(path, body, adminSecret)
    local req = getRequestFunction()

    if not req then
        return nil,
            "Executor не предоставляет HTTP request API."
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
    }

    if adminSecret and adminSecret ~= "" then
        headers["X-Admin-Secret"] = adminSecret
    end

    local payload

    local encoded, encodeError = pcall(function()
        payload = HttpService:JSONEncode(body or {})
    end)

    if not encoded then
        return nil,
            "Ошибка подготовки JSON: "
            .. tostring(encodeError)
    end

    local ok, response = pcall(function()
        return req({
            Url = API_BASE .. path,
            Method = "POST",
            Headers = headers,
            Body = payload,
        })
    end)

    if not ok or type(response) ~= "table" then
        return nil,
            "Не удалось выполнить HTTPS-запрос."
    end

    local status = tonumber(
        response.StatusCode
        or response.Status
        or 0
    ) or 0

    local raw = response.Body
        or response.body
        or ""

    local decodedOK, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if status < 200 or status >= 300 then
        local message

        if decodedOK and type(decoded) == "table" then
            message = decoded.error
                or decoded.message
        end

        return nil,
            tostring(message or ("HTTP " .. status))
    end

    if not decodedOK or type(decoded) ~= "table" then
        return nil,
            "Сервер вернул некорректный JSON."
    end

    return decoded
end

--==================================================
-- 5. DEVICE IDENTIFIER
--==================================================

local function generateDeviceId()
    local randomPart = HttpService:GenerateGUID(false)
    return "RH-" .. randomPart
end

local function getDeviceId()
    if type(readfile) == "function"
        and type(writefile) == "function" then

        local ok, result = pcall(function()
            if type(isfile) == "function"
                and isfile(DEVICE_FILE) then

                local value = readfile(DEVICE_FILE)

                if type(value) == "string"
                    and #value >= 16 then

                    return value
                end
            end

            local value = generateDeviceId()

            writefile(DEVICE_FILE, value)

            return value
        end)

        if ok and type(result) == "string" then
            return result
        end
    end

    return nil
end

local deviceId = getDeviceId()

--==================================================
-- 6. GUI HELPERS
--==================================================

local function create(className, properties, parent)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    object.Parent = parent

    return object
end

local function addCorner(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    }, object)
end

local function addStroke(object, color, thickness)
    return create("UIStroke", {
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        Transparency = 0,
    }, object)
end

local function addPadding(object, value)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, value),
        PaddingRight = UDim.new(0, value),
        PaddingTop = UDim.new(0, value),
        PaddingBottom = UDim.new(0, value),
    }, object)
end

--==================================================
-- 7. MAIN GUI
--==================================================

local screenGui = create("ScreenGui", {
    Name = "RH_AUTH_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000,
    IgnoreGuiInset = false,
}, PlayerGui)

local FULL_HEIGHT = 430
local MINI_HEIGHT = 48

local main = create("Frame", {
    Name = "MainWindow",

    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),

    Size = UDim2.new(0, 340, 0, FULL_HEIGHT),

    BackgroundColor3 = COLORS.Window,
    BorderSizePixel = 0,

    ClipsDescendants = true,
}, screenGui)

addCorner(main, 12)
addStroke(main, COLORS.Border, 1)

local scale = create("UIScale", {
    Scale = 1,
}, main)

local function updateScale()
    local camera = workspace.CurrentCamera

    if not camera then return end

    local viewport = camera.ViewportSize

    local scaleX = viewport.X / 370
    local scaleY = viewport.Y / 470

    scale.Scale = math.clamp(
        math.min(scaleX, scaleY),
        0.72,
        1
    )
end

updateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal(
        "ViewportSize"
    ):Connect(updateScale)
end

--==================================================
-- 8. HEADER
--==================================================

local header = create("Frame", {
    Name = "Header",

    Size = UDim2.new(1, 0, 0, 48),

    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
}, main)

local title = create("TextLabel", {
    Position = UDim2.new(0, 13, 0, 4),
    Size = UDim2.new(1, -90, 0, 23),

    BackgroundTransparency = 1,

    Text = "RH-AUTH",
    TextColor3 = COLORS.Text,

    Font = Enum.Font.GothamBold,
    TextSize = 17,

    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local subtitle = create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 27),
    Size = UDim2.new(1, -100, 0, 14),

    BackgroundTransparency = 1,

    Text = "LICENSE CONTROL PANEL",
    TextColor3 = COLORS.Muted,

    Font = Enum.Font.Gotham,
    TextSize = 9,

    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local minimizeButton = create("TextButton", {
    Position = UDim2.new(1, -78, 0, 9),
    Size = UDim2.new(0, 30, 0, 29),

    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,

    Text = "—",
    TextColor3 = COLORS.Text,

    Font = Enum.Font.GothamBold,
    TextSize = 16,

    AutoButtonColor = true,
}, header)

addCorner(minimizeButton, 7)

local closeButton = create("TextButton", {
    Position = UDim2.new(1, -40, 0, 9),
    Size = UDim2.new(0, 30, 0, 29),

    BackgroundColor3 = Color3.fromRGB(75, 35, 48),
    BorderSizePixel = 0,

    Text = "×",
    TextColor3 = COLORS.Red,

    Font = Enum.Font.GothamBold,
    TextSize = 20,

    AutoButtonColor = true,
}, header)

addCorner(closeButton, 7)

-- [КОНЕЦ ЧАСТИ 1]
--==================================================
-- 9. STATUS BAR
--==================================================

local statusBar = create("TextLabel", {
    Name = "Status",

    Position = UDim2.new(0, 10, 0, 54),
    Size = UDim2.new(1, -20, 0, 34),

    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,

    Text = "Готов к работе.",
    TextColor3 = COLORS.Muted,

    TextSize = 10,
    Font = Enum.Font.Gotham,

    TextWrapped = true,
}, main)

addCorner(statusBar, 7)

local function setStatus(message, success)
    statusBar.Text = tostring(message)

    if success == true then
        statusBar.TextColor3 = COLORS.Green

    elseif success == false then
        statusBar.TextColor3 = COLORS.Red

    else
        statusBar.TextColor3 = COLORS.Muted
    end
end

--==================================================
-- 10. NAVIGATION
--==================================================

local nav = create("Frame", {
    Position = UDim2.new(0, 10, 0, 96),
    Size = UDim2.new(1, -20, 0, 36),

    BackgroundTransparency = 1,
}, main)

local navLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,

    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
}, nav)

local content = create("Frame", {
    Name = "Content",

    Position = UDim2.new(0, 10, 0, 140),
    Size = UDim2.new(1, -20, 1, -150),

    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, main)

local pages = {}
local navButtons = {}
local activePage = nil

local function createPage(name)
    local page = create("ScrollingFrame", {
        Name = name,

        Size = UDim2.new(1, 0, 1, 0),

        BackgroundTransparency = 1,
        BorderSizePixel = 0,

        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Accent,

        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        Visible = false,
    }, content)

    addPadding(page, 2)

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 7),
    }, page)

    pages[name] = page

    return page
end

local function selectPage(name)
    if not pages[name] then return end

    activePage = name

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for buttonName, button in pairs(navButtons) do
        local selected = buttonName == name

        button.BackgroundColor3 = selected
            and COLORS.Accent
            or COLORS.Panel

        button.TextColor3 = selected
            and COLORS.Text
            or COLORS.Muted
    end
end

local function createNavButton(name, text, order)
    local button = create("TextButton", {
        Name = name,

        Size = UDim2.new(0.333, -4, 1, 0),

        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,

        Text = text,
        TextColor3 = COLORS.Muted,

        Font = Enum.Font.GothamBold,
        TextSize = 10,

        LayoutOrder = order,
    }, nav)

    addCorner(button, 7)

    navButtons[name] = button

    button.Activated:Connect(function()
        selectPage(name)
    end)

    return button
end

createNavButton("HOME", "ГЛАВНАЯ", 1)
createNavButton("LICENSE", "ЛИЦЕНЗИЯ", 2)
createNavButton("ADMIN", "ADMIN", 3)

local homePage = createPage("HOME")
local licensePage = createPage("LICENSE")
local adminPage = createPage("ADMIN")

--==================================================
-- 11. UI COMPONENTS
--==================================================

local function section(parent, text)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 23),

        BackgroundTransparency = 1,

        Text = text,
        TextColor3 = COLORS.Accent2,

        Font = Enum.Font.GothamBold,
        TextSize = 11,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function infoCard(parent, heading, description)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 65),

        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, parent)

    addCorner(frame, 8)

    create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 7),
        Size = UDim2.new(1, -20, 0, 18),

        BackgroundTransparency = 1,

        Text = heading,
        TextColor3 = COLORS.Text,

        Font = Enum.Font.GothamBold,
        TextSize = 11,

        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    create("TextLabel", {
        Position = UDim2.new(0, 10, 0, 27),
        Size = UDim2.new(1, -20, 0, 32),

        BackgroundTransparency = 1,

        Text = description,
        TextColor3 = COLORS.Muted,

        Font = Enum.Font.Gotham,
        TextSize = 10,

        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, frame)

    return frame
end

local function createInput(parent, placeholder, defaultText)
    local box = create("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),

        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,

        Text = defaultText or "",
        PlaceholderText = placeholder,

        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.Text,

        Font = Enum.Font.Gotham,
        TextSize = 11,

        ClearTextOnFocus = false,
    }, parent)

    addCorner(box, 7)
    addPadding(box, 9)

    return box
end

local function createButton(parent, text, callback, color)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),

        BackgroundColor3 = color or COLORS.Panel2,
        BorderSizePixel = 0,

        Text = text,
        TextColor3 = COLORS.Text,

        Font = Enum.Font.GothamBold,
        TextSize = 10,

        AutoButtonColor = true,
    }, parent)

    addCorner(button, 7)

    button.Activated:Connect(function()
        local ok, err = pcall(callback)

        if not ok then
            setStatus(
                "Ошибка интерфейса: " .. tostring(err),
                false
            )
        end
    end)

    return button
end

local function createOutput(parent, initialText, height)
    local output = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 100),

        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,

        Text = initialText or "",
        TextColor3 = COLORS.Text,

        Font = Enum.Font.Code,
        TextSize = 10,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, parent)

    addCorner(output, 7)
    addPadding(output, 8)

    return output
end

local function formatJSON(value)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(value)
    end)

    if ok then return result end

    return tostring(value)
end

--==================================================
-- 12. HOME PAGE
--==================================================

section(homePage, "ОБЗОР RH-AUTH")

infoCard(
    homePage,
    "СИСТЕМА АВТОРИЗАЦИИ",
    "Отдельная панель управления лицензиями через Cloudflare Worker."
)

infoCard(homePage, "ВЕРСИЯ", VERSION)

infoCard(
    homePage,
    "ПОЛЬЗОВАТЕЛЬ",
    "Roblox UserId: " .. tostring(LocalPlayer.UserId)
)

infoCard(
    homePage,
    "УСТРОЙСТВО",
    deviceId
        and "Локальный идентификатор создан."
        or "Постоянное хранилище недоступно."
)

createButton(homePage, "ПРОВЕРИТЬ СВЯЗЬ С СЕРВЕРОМ", function()
    setStatus("Проверяем сервер...", nil)

    local result, err = apiRequest("/verify", {
        token = "",
    })

    if result then
        setStatus("Сервер отвечает. Ответ получен.", true)
    else
        setStatus("Ответ сервера: " .. tostring(err), false)
    end
end)

createButton(homePage, "ОТКРЫТЬ ЛИЦЕНЗИИ", function()
    selectPage("LICENSE")
end, COLORS.Accent)

createButton(homePage, "ОТКРЫТЬ ADMIN", function()
    selectPage("ADMIN")
end, COLORS.Accent2)

--==================================================
-- 13. LICENSE PAGE
--==================================================

section(licensePage, "УПРАВЛЕНИЕ ЛИЦЕНЗИЕЙ")

infoCard(
    licensePage,
    "АКТИВАЦИЯ",
    "Введи лицензионный ключ, выданный администратором."
)

local licenseKeyBox = createInput(
    licensePage,
    "Вставь лицензионный ключ"
)

local licenseToken = nil

local licenseOutput = createOutput(
    licensePage,
    "Здесь появится информация о лицензии.",
    75
)

createButton(licensePage, "АКТИВИРОВАТЬ ЛИЦЕНЗИЮ", function()
    local key = tostring(licenseKeyBox.Text or "")
        :gsub("%s+", "")

    if key == "" then
        setStatus("Сначала введи лицензионный ключ.", false)
        return
    end

    if not deviceId then
        setStatus(
            "Нет постоянного идентификатора устройства. "
            .. "Проверь поддержку file APIs в executor.",
            false
        )
        return
    end

    setStatus("Отправляем запрос на активацию...", nil)

    local result, err = apiRequest("/activate", {
        key = key,
        install_hash = deviceId,
        roblox_user_id = tostring(LocalPlayer.UserId),
    })

    if not result then
        licenseOutput.Text = tostring(err)
        setStatus("Активация не удалась: " .. tostring(err), false)
        return
    end

    licenseToken = result.token
    licenseOutput.Text = formatJSON(result)
    setStatus("Сервер обработал активацию.", true)
end, COLORS.Accent)

createButton(licensePage, "ПРОВЕРИТЬ СЕССИЮ", function()
    if not licenseToken then
        setStatus("Сначала активируй лицензию в этой сессии.", false)
        return
    end

    setStatus("Проверяем сессию...", nil)

    local result, err = apiRequest("/verify", {
        token = licenseToken,
    })

    if not result then
        setStatus("Ошибка проверки: " .. tostring(err), false)
        licenseOutput.Text = tostring(err)
        return
    end

    licenseOutput.Text = formatJSON(result)

    if result.valid == true then
        setStatus("Сессия подтверждена сервером.", true)
    else
        setStatus("Сервер не подтвердил действительность сессии.", false)
    end
end)

createButton(licensePage, "ОЧИСТИТЬ ПОЛЕ КЛЮЧА", function()
    licenseKeyBox.Text = ""
    setStatus("Поле ключа очищено.", true)
end)

-- [КОНЕЦ ЧАСТИ 2]
--==================================================
-- 14. ADMIN PAGE
--==================================================

section(adminPage, "ADMIN PANEL")

infoCard(
    adminPage,
    "ЗАЩИЩЁННЫЙ ДОСТУП",
    "Секрет передаётся серверу в заголовке X-Admin-Secret. "
    .. "Не вшивай его в публичный Lua-код."
)

local adminSecretBox = createInput(
    adminPage,
    "ADMIN_SECRET — введи секрет владельца"
)

adminSecretBox.Text = ""

local adminAuthenticated = false

local adminOutput = createOutput(
    adminPage,
    "Сначала подтверди права администратора.",
    115
)

local function adminRequest(path, body)
    local secret = tostring(adminSecretBox.Text or "")

    if secret == "" then
        setStatus("Введи ADMIN_SECRET.", false)
        return nil
    end

    return apiRequest(path, body or {}, secret)
end

local function showAdminResult(result)
    adminOutput.Text = formatJSON(result)
end

createButton(adminPage, "ПРОВЕРИТЬ ADMIN_SECRET", function()
    adminAuthenticated = false
    setStatus("Проверяем права администратора...", nil)

    local result, err = adminRequest("/admin/list", {})

    if not result then
        adminOutput.Text = tostring(err)
        setStatus("Доступ не подтверждён: " .. tostring(err), false)
        return
    end

    adminAuthenticated = true
    showAdminResult(result)
    setStatus("Сервер подтвердил доступ ADMIN.", true)
end, COLORS.Accent)

section(adminPage, "СОЗДАНИЕ ЛИЦЕНЗИЙ")

local durationBox = createInput(
    adminPage,
    "Срок: 30m / 12h / 7d / lifetime",
    "1d"
)

local countBox = createInput(
    adminPage,
    "Количество ключей: от 1 до 100",
    "1"
)

local function parseDuration(value)
    value = tostring(value or "")
        :lower()
        :gsub("%s+", "")

    if value == "lifetime" or value == "life" then
        return { lifetime = true }
    end

    local number, unit = value:match("^(%d+)([mhd])$")
    number = tonumber(number)

    if not number or number < 1 then
        return nil
    end

    if unit == "m" then
        return { minutes = number }
    elseif unit == "h" then
        return { hours = number }
    elseif unit == "d" then
        return { days = number }
    end

    return nil
end

createButton(adminPage, "СОЗДАТЬ ЛИЦЕНЗИИ", function()
    local count = math.floor(tonumber(countBox.Text) or 1)

    if count < 1 or count > 100 then
        setStatus("Количество должно быть от 1 до 100.", false)
        return
    end

    local duration = parseDuration(durationBox.Text)

    if not duration then
        setStatus("Неверный формат срока. Примеры: 30m, 12h, 7d.", false)
        return
    end

    local body = { count = count }

    for key, value in pairs(duration) do
        body[key] = value
    end

    setStatus("Создаём лицензии...", nil)

    local result, err = adminRequest("/admin/create", body)

    if not result then
        adminOutput.Text = tostring(err)
        setStatus("Не удалось создать лицензии: " .. tostring(err), false)
        return
    end

    showAdminResult(result)
    setStatus("Сервер обработал запрос создания.", true)
end, COLORS.Accent)

createButton(adminPage, "ПОЛУЧИТЬ СПИСОК ЛИЦЕНЗИЙ", function()
    setStatus("Запрашиваем список лицензий...", nil)

    local result, err = adminRequest("/admin/list", {})

    if not result then
        adminOutput.Text = tostring(err)
        setStatus("Ошибка получения списка: " .. tostring(err), false)
        return
    end

    showAdminResult(result)
    setStatus("Список получен.", true)
end)

section(adminPage, "УПРАВЛЕНИЕ КЛЮЧАМИ")

local targetKeyBox = createInput(
    adminPage,
    "Введи лицензионный ключ"
)

createButton(adminPage, "ОТОЗВАТЬ ЛИЦЕНЗИЮ", function()
    local key = tostring(targetKeyBox.Text or ""):gsub("%s+", "")

    if key == "" then
        setStatus("Введи ключ для отзыва.", false)
        return
    end

    setStatus("Отзываем лицензию...", nil)

    local result, err = adminRequest("/admin/revoke", { key = key })

    if not result then
        adminOutput.Text = tostring(err)
        setStatus("Ошибка отзыва: " .. tostring(err), false)
        return
    end

    showAdminResult(result)
    setStatus("Запрос отзыва обработан сервером.", true)
end, COLORS.Red)

createButton(adminPage, "СБРОСИТЬ ПРИВЯЗКУ УСТРОЙСТВА", function()
    local key = tostring(targetKeyBox.Text or ""):gsub("%s+", "")

    if key == "" then
        setStatus("Введи ключ для сброса привязки.", false)
        return
    end

    setStatus("Отправляем запрос сброса привязки...", nil)

    local result, err = adminRequest("/admin/reset-device", { key = key })

    if not result then
        adminOutput.Text = tostring(err)
        setStatus("Ошибка сброса: " .. tostring(err), false)
        return
    end

    showAdminResult(result)
    setStatus("Запрос сброса обработан сервером.", true)
end, COLORS.Accent2)

createButton(adminPage, "ОЧИСТИТЬ РЕЗУЛЬТАТ", function()
    adminOutput.Text = "Результат очищен."
    setStatus("Поле результата очищено.", true)
end)

createButton(adminPage, "ЗАКРЫТЬ ADMIN", function()
    adminSecretBox.Text = ""
    adminAuthenticated = false
    selectPage("HOME")
    setStatus("Секрет очищен из поля ввода.", true)
end)

--==================================================
-- 15. WINDOW DRAG
--==================================================

local dragging = false
local dragStart = nil
local startPosition = nil
local dragInput = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        dragInput = input

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not startPosition then
        return
    end

    local matchingInput = input == dragInput

    local mouseMovement =
        input.UserInputType == Enum.UserInputType.MouseMovement

    local touchMovement =
        input.UserInputType == Enum.UserInputType.Touch

    if not matchingInput and not mouseMovement and not touchMovement then
        return
    end

    local delta = input.Position - dragStart

    main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,

        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

--==================================================
-- 16. MINIMIZE / CLOSE / FLOATING BUBBLE
--==================================================

local isMinimized = false

-- Плавающий кружок RH
local bubble = create("Frame", {
    Name = "RH_AUTH_BUBBLE",

    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(1, -50, 0.4, 0),

    Size = UDim2.new(0, 54, 0, 54),

    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,

    Visible = false,
    ZIndex = 200,

    Active = true,
}, screenGui)

addCorner(bubble, 27)
addStroke(bubble, COLORS.Accent2, 2)

local bubbleLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),

    BackgroundTransparency = 1,

    Text = "RH",
    TextColor3 = COLORS.Text,

    Font = Enum.Font.GothamBold,
    TextSize = 16,

    ZIndex = 201,
}, bubble)

-- Пульсация кружка
local pulseRunning = false

local function startPulse()
    if pulseRunning then return end
    pulseRunning = true

    task.spawn(function()
        while bubble.Visible do
            TweenService:Create(
                bubble,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Size = UDim2.new(0, 60, 0, 60) }
            ):Play()

            task.wait(0.8)

            if not bubble.Visible then break end

            TweenService:Create(
                bubble,
                TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Size = UDim2.new(0, 54, 0, 54) }
            ):Play()

            task.wait(0.8)
        end

        pulseRunning = false
    end)
end

-- Перетаскивание кружка + тап
local bDragging = false
local bMoved = false
local bStart = nil
local bStartPos = nil

bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        bDragging = true
        bMoved = false
        bStart = input.Position
        bStartPos = bubble.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not bDragging then return end

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseMovement then

        local d = input.Position - bStart

        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then
            bMoved = true
        end

        bubble.Position = UDim2.new(
            bStartPos.X.Scale,
            bStartPos.X.Offset + d.X,

            bStartPos.Y.Scale,
            bStartPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not bDragging then return end

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        bDragging = false

        if not bMoved then
            -- тап → открыть окно
            bubble.Visible = false
            main.Visible = true

            main.Size = UDim2.new(0, 340, 0, MINI_HEIGHT)

            TweenService:Create(
                main,
                TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, 340, 0, FULL_HEIGHT) }
            ):Play()

            updateScale()
        end
    end
end)

-- Кнопка «—»: свернуть в полоску / развернуть
minimizeButton.Activated:Connect(function()
    isMinimized = not isMinimized

    if isMinimized then
        content.Visible = false
        statusBar.Visible = false
        nav.Visible = false

        TweenService:Create(
            main,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 340, 0, MINI_HEIGHT) }
        ):Play()

        minimizeButton.Text = "+"
    else
        content.Visible = true
        statusBar.Visible = true
        nav.Visible = true

        TweenService:Create(
            main,
            TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 340, 0, FULL_HEIGHT) }
        ):Play()

        minimizeButton.Text = "—"
    end
end)

-- Кнопка «×»: скрыть окно + показать кружок
closeButton.Activated:Connect(function()
    TweenService:Create(
        main,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 300, 0, 380) }
    ):Play()

    task.wait(0.2)

    main.Visible = false
    main.Size = UDim2.new(0, 340, 0, FULL_HEIGHT)

    bubble.Visible = true
    startPulse()
end)

--==================================================
-- 17. INITIALIZATION
--==================================================

selectPage("HOME")

setStatus(
    "RH-Auth загружен. Версия " .. VERSION,
    true
)

print("----------------------------------------")
print("RH-AUTH INITIALIZED")
print("Version: " .. VERSION)
print("UserId: " .. tostring(LocalPlayer.UserId))
print("API: " .. API_BASE)
print("----------------------------------------")

-- [КОНЕЦ ЧАСТИ 3]
-- [[ КОНЕЦ ФАЙЛА ]]