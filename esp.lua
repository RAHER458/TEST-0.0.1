--[[
    RH-AUTH
    Standalone License Administration Panel
    Version: 0.1
    Platform: Delta Executor / Roblox
    UI: Mobile-friendly
    Backend: Cloudflare Workers + D1

    Independent project.
    Does not load RAHERHUB.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local SERVER_URL = "https://raherauth.raher458.workers.dev/"

local ADMIN_SECRET = ""

-- =========================================================
-- HTTP COMPATIBILITY
-- =========================================================

local function GetRequestFunction()
    if typeof(request) == "function" then
        return request
    end

    if typeof(http_request) == "function" then
        return http_request
    end

    if syn and typeof(syn.request) == "function" then
        return syn.request
    end

    if fluxus and typeof(fluxus.request) == "function" then
        return fluxus.request
    end

    return nil
end

local function APIRequest(path, body, admin)
    local req = GetRequestFunction()

    if not req then
        return false, "HTTP request недоступен в Executor"
    end

    local headers = {
        ["Content-Type"] = "application/json"
    }

    if admin then
        if ADMIN_SECRET == "" then
            return false, "Введите Admin Secret"
        end

        headers["X-Admin-Secret"] = ADMIN_SECRET
    end

    local options = {
        Url = SERVER_URL .. path,
        Method = body and "POST" or "GET",
        Headers = headers
    }

    if body then
        options.Body = HttpService:JSONEncode(body)
    end

    local ok, response = pcall(function()
        return req(options)
    end)

    if not ok then
        return false, "Ошибка соединения: " .. tostring(response)
    end

    if not response then
        return false, "Пустой ответ сервера"
    end

    local statusCode = tonumber(
        response.StatusCode or response.StatusCode
    ) or 0

    local responseBody = response.Body or ""

    local decodedOK, decoded = pcall(function()
        return HttpService:JSONDecode(responseBody)
    end)

    if not decodedOK then
        return false, "Некорректный JSON: " .. responseBody
    end

    if statusCode < 200 or statusCode >= 300 then
        return false, decoded.error
            or ("HTTP " .. tostring(statusCode))
    end

    return true, decoded
end

-- =========================================================
-- UI
-- =========================================================

local oldGui = game:GetService("CoreGui"):FindFirstChild("RHAuth")

if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RHAuth"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parentOK = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

if not parentOK then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function New(className, properties, parent)
    local object = Instance.new(className)

    for key, value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent

    return object
end

local COLORS = {
    Background = Color3.fromRGB(13, 15, 23),
    Panel = Color3.fromRGB(21, 24, 35),
    Panel2 = Color3.fromRGB(29, 33, 47),
    Accent = Color3.fromRGB(110, 85, 255),
    Accent2 = Color3.fromRGB(66, 180, 255),
    Text = Color3.fromRGB(240, 242, 255),
    Muted = Color3.fromRGB(145, 151, 175),
    Green = Color3.fromRGB(60, 210, 135),
    Red = Color3.fromRGB(255, 83, 103),
    Border = Color3.fromRGB(49, 54, 73)
}

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 340, 0, 410),
    Position = UDim2.new(0.5, -170, 0.5, -205),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, ScreenGui)

New("UICorner", {
    CornerRadius = UDim.new(0, 14)
}, Main)

New("UIStroke", {
    Color = COLORS.Border,
    Thickness = 1
}, Main)

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0
}, Main)

New("TextLabel", {
    Position = UDim2.new(0, 16, 0, 9),
    Size = UDim2.new(1, -65, 0, 26),
    BackgroundTransparency = 1,
    Text = "RH-AUTH",
    TextColor3 = COLORS.Text,
    TextSize = 23,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

New("TextLabel", {
    Position = UDim2.new(0, 17, 0, 36),
    Size = UDim2.new(1, -70, 0, 17),
    BackgroundTransparency = 1,
    Text = "LICENSE CONTROL PANEL  /  0.1",
    TextColor3 = COLORS.Muted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, Header)

local Close = New("TextButton", {
    Position = UDim2.new(1, -43, 0, 14),
    Size = UDim2.new(0, 30, 0, 30),
    BackgroundColor3 = COLORS.Panel2,
    Text = "×",
    TextColor3 = COLORS.Text,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0
}, Header)

New("UICorner", {
    CornerRadius = UDim.new(0, 8)
}, Close)

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- =========================================================
-- DRAGGING
-- =========================================================

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- =========================================================
-- NAVIGATION
-- =========================================================

local Navigation = New("Frame", {
    Position = UDim2.new(0, 10, 0, 73),
    Size = UDim2.new(1, -20, 0, 35),
    BackgroundTransparency = 1
}, Main)

local navLayout = New("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Navigation)

local Content = New("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 117),
    Size = UDim2.new(1, -20, 1, -127),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, Main)

New("UIPadding", {
    PaddingBottom = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 3)
}, Content)

local contentLayout = New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, Content)

local pages = {}
local navButtons = {}

local function ClearContent()
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("GuiObject") and child ~= contentLayout then
            child:Destroy()
        end
    end
end

local function ShowPage(name)
    ClearContent()

    for pageName, button in pairs(navButtons) do
        local selected = pageName == name

        button.BackgroundColor3 = selected
            and COLORS.Accent
            or COLORS.Panel2
    end

    if pages[name] then
        pages[name]()
    end
end

local function CreateNav(name, order)
    local button = New("TextButton", {
        Name = name,
        LayoutOrder = order,
        Size = UDim2.new(0, 101, 0, 33),
        BackgroundColor3 = COLORS.Panel2,
        Text = name,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = true
    }, Navigation)

    New("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, button)

    navButtons[name] = button

    button.MouseButton1Click:Connect(function()
        ShowPage(name)
    end)
end

CreateNav("MAIN", 1)
CreateNav("LICENSES", 2)
CreateNav("SERVER", 3)

-- =========================================================
-- UI COMPONENTS
-- =========================================================

local function Label(text, height, color, size)
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or COLORS.Text,
        TextSize = size or 12,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, Content)
end

local function Section(text)
    local label = Label(text, 23, COLORS.Accent2, 12)
    label.Font = Enum.Font.GothamBold
    return label
end

local function Input(placeholder, defaultText)
    local box = New("TextBox", {
        Size = UDim2.new(1, 0, 0, 37),
        BackgroundColor3 = COLORS.Panel2,
        Text = defaultText or "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0
    }, Content)

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, box)

    New("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, box)

    return box
end

local function Button(text, callback, color)
    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = color or COLORS.Accent,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = true
    }, Content)

    New("UICorner", {
        CornerRadius = UDim.new(0, 7)
    }, button)

    button.MouseButton1Click:Connect(function()
        task.spawn(callback)
    end)

    return button
end

local statusLabel

local function SetStatus(text, success)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = text

        statusLabel.TextColor3 = success == true
            and COLORS.Green
            or success == false
                and COLORS.Red
                or COLORS.Muted
    end
end

local function CreateStatus()
    statusLabel = Label("Статус: ожидание", 34, COLORS.Muted, 10)
    statusLabel.TextWrapped = true
end

-- =========================================================
-- MAIN PAGE
-- =========================================================

pages.MAIN = function()
    Section("OVERVIEW")

    Label("Независимая панель управления лицензиями.", 34)

    Label("Адрес сервера", 18, COLORS.Muted, 10)

    local urlBox = Input("Worker URL", SERVER_URL)
    urlBox.TextEditable = false

    Section("ADMIN AUTHENTICATION")

    local secretBox = Input("Вставьте Admin Secret")
    secretBox.Text = ""

    Button("СОХРАНИТЬ ADMIN SECRET", function()
        local value = secretBox.Text

        if value == "" then
            SetStatus("Введите Admin Secret", false)
            return
        end

        ADMIN_SECRET = value
        SetStatus("Admin Secret сохранён в памяти сессии", true)
    end)

    Button("ПРОВЕРИТЬ СЕРВЕР", function()
        SetStatus("Подключение...", nil)

        local ok, result = APIRequest("", nil, false)

        if ok then
            SetStatus(
                "Сервер доступен: " ..
                tostring(result.status or "online"),
                true
            )
        else
            SetStatus(tostring(result), false)
        end
    end, COLORS.Panel2)

    CreateStatus()

    Label(
        "Секрет администратора хранится только в памяти текущей сессии.",
        32,
        COLORS.Muted,
        9
    )
end

-- =========================================================
-- LICENSES PAGE
-- =========================================================

pages.LICENSES = function()
    Section("CREATE LICENSE")

    local daysBox = Input("Дни", "1")
    local hoursBox = Input("Часы", "0")
    local minutesBox = Input("Минуты", "0")
    local countBox = Input("Количество ключей", "1")
    local lifetimeBox = Input("Бессрочная лицензия: true / false", "false")
    local robloxIdBox = Input("Roblox User ID (необязательно)", "")

    Button("СОЗДАТЬ ЛИЦЕНЗИИ", function()
        local days = tonumber(daysBox.Text)
        local hours = tonumber(hoursBox.Text)
        local minutes = tonumber(minutesBox.Text)
        local count = tonumber(countBox.Text)

        if not days or not hours or not minutes or not count then
            SetStatus("Проверьте числовые поля", false)
            return
        end

        if days < 0 or hours < 0 or minutes < 0 then
            SetStatus("Продолжительность не может быть отрицательной", false)
            return
        end

        if count < 1 or count > 100 or count % 1 ~= 0 then
            SetStatus("Количество должно быть от 1 до 100", false)
            return
        end

        local lifetimeText = string.lower(
            string.gsub(lifetimeBox.Text, "%s+", "")
        )

        if lifetimeText ~= "true" and lifetimeText ~= "false" then
            SetStatus("Бессрочность: укажите true или false", false)
            return
        end

        local lifetime = lifetimeText == "true"

        if not lifetime
            and (days * 1440 + hours * 60 + minutes <= 0) then

            SetStatus(
                "Укажите положительный срок или включите бессрочность",
                false
            )
            return
        end

        local body = {
            days = days,
            hours = hours,
            minutes = minutes,
            lifetime = lifetime,
            count = count
        }

        local userId = robloxIdBox.Text

        if userId ~= "" then
            local parsedId = tonumber(userId)

            if not parsedId or parsedId < 1 then
                SetStatus("Некорректный Roblox User ID", false)
                return
            end

            body.roblox_user_id = parsedId
        end

        SetStatus("Создание лицензий...", nil)

        local ok, result = APIRequest(
            "admin/create",
            body,
            true
        )

        if not ok then
            SetStatus(tostring(result), false)
            return
        end

        local keys = result.keys or {}

        if #keys == 0 then
            SetStatus("Сервер не вернул созданные ключи", false)
            return
        end

        local output = {}

        for _, item in ipairs(keys) do
            if type(item) == "table" then
                table.insert(
                    output,
                    tostring(item.key or item.license_key or item.id or "?")
                )
            else
                table.insert(output, tostring(item))
            end
        end

        local keyText = table.concat(output, "\n")

        SetStatus(
            "Создано лицензий: " .. tostring(#keys),
            true
        )

        local resultBox = Input("Созданные ключи", keyText)
        resultBox.Size = UDim2.new(1, 0, 0, 95)
        resultBox.MultiLine = true
        resultBox.TextYAlignment = Enum.TextYAlignment.Top
        resultBox.TextEditable = false

        Button("КОПИРОВАТЬ КЛЮЧИ", function()
            if typeof(setclipboard) == "function" then
                local copied = pcall(setclipboard, keyText)

                if copied then
                    SetStatus("Ключи скопированы", true)
                else
                    SetStatus("Не удалось скопировать ключи", false)
                end
            else
                SetStatus(
                    "Буфер обмена не поддерживается этим Executor",
                    false
                )
            end
        end, COLORS.Panel2)
    end)

    Section("LICENSE MANAGEMENT")

    local searchBox = Input("Ключ для отзыва или сброса привязки")

    Button("ОТОЗВАТЬ ЛИЦЕНЗИЮ", function()
        local key = searchBox.Text

        if key == "" then
            SetStatus("Введите ключ", false)
            return
        end

        SetStatus("Отзыв лицензии...", nil)

        local ok, result = APIRequest(
            "admin/revoke",
            {key = key},
            true
        )

        if ok and result.success then
            SetStatus("Лицензия отозвана", true)
        else
            SetStatus(
                ok and "Сервер не подтвердил отзыв"
                    or tostring(result),
                false
            )
        end
    end, COLORS.Red)

    Button("СБРОСИТЬ ПРИВЯЗКУ УСТРОЙСТВА", function()
        local key = searchBox.Text

        if key == "" then
            SetStatus("Введите ключ", false)
            return
        end

        SetStatus("Сброс привязки...", nil)

        local ok, result = APIRequest(
            "admin/reset-device",
            {key = key},
            true
        )

        if ok and result.success then
            SetStatus("Привязка устройства сброшена", true)
        else
            SetStatus(
                ok and "Сервер не подтвердил сброс"
                    or tostring(result),
                false
            )
        end
    end, COLORS.Panel2)

    Button("ОБНОВИТЬ СПИСОК ЛИЦЕНЗИЙ", function()
        SetStatus("Загрузка списка...", nil)

        local ok, result = APIRequest(
            "admin/list",
            {},
            true
        )

        if not ok then
            SetStatus(tostring(result), false)
            return
        end

        local keys = result.keys or {}

        local lines = {}

        for _, item in ipairs(keys) do
            if type(item) == "table" then
                local key = tostring(
                    item.key or item.license_key or item.id or "?"
                )

                local expires = tostring(
                    item.expires_at or item.expiration or "не указан"
                )

                local status = tostring(
                    item.status or item.state or "unknown"
                )

                table.insert(
                    lines,
                    key .. " | " .. status .. " | " .. expires
                )
            else
                table.insert(lines, tostring(item))
            end
        end

        SetStatus(
            "Получено записей: " .. tostring(#keys),
            true
        )

        local listBox = Input("Список лицензий", table.concat(lines, "\n"))
        listBox.Size = UDim2.new(1, 0, 0, 150)
        listBox.MultiLine = true
        listBox.TextYAlignment = Enum.TextYAlignment.Top
        listBox.TextEditable = false
    end, COLORS.Panel2)
end

-- =========================================================
-- SERVER PAGE
-- =========================================================

pages.SERVER = function()
    Section("SERVER STATUS")

    Label(
        "Cloudflare Workers / D1",
        25,
        COLORS.Text,
        13
    )

    Label(SERVER_URL, 38, COLORS.Muted, 10)

    Button("ПРОВЕРИТЬ СОЕДИНЕНИЕ", function()
        SetStatus("Проверка...", nil)

        local started = os.clock()

        local ok, result = APIRequest("", nil, false)

        local elapsed = math.floor((os.clock() - started) * 1000)

        if ok then
            SetStatus(
                "Статус: " ..
                tostring(result.status or "online") ..
                "\nОтвет: " .. tostring(elapsed) .. " мс",
                true
            )
        else
            SetStatus(tostring(result), false)
        end
    end)

    Section("AVAILABLE API ROUTES")

    Label("GET /", 23)
    Label("POST /admin/create", 23)
    Label("POST /admin/list", 23)
    Label("POST /admin/revoke", 23)
    Label("POST /admin/reset-device", 23)
    Label("POST /activate", 23)
    Label("POST /verify", 23)

    Label(
        "Административные маршруты требуют X-Admin-Secret.",
        36,
        COLORS.Muted,
        10
    )

    Section("SESSION")

    Button("ОЧИСТИТЬ ADMIN SECRET", function()
        ADMIN_SECRET = ""
        SetStatus("Admin Secret очищен", true)
    end, COLORS.Panel2)
end

-- =========================================================
-- INITIALIZATION
-- =========================================================

ShowPage("MAIN")

print("[RH-AUTH] Panel initialized")
print("[RH-AUTH] Standalone version 0.1")
print("[RH-AUTH] Server: " .. SERVER_URL)