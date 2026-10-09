--[[
    RH-AUTH
    Standalone Authentication & License Admin Panel
    Version: 1.2.3 "Cards Fix v3"
    Platform: Roblox / Delta Executor / iOS
    Language: Russian

    CHANGELOG 1.2.3:
      - Toggle "Бессрочная" — через OnChange, без двойного обработчика
      - Бейджи статусов — читаемый контрастный текст
      - Ширина окна: 340 -> 380 (шире, не выше)
      - Scale-формула: /370 -> /410
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local VERSION = "1.2.3 Cards Fix v3"
local API_BASE = "https://raherauth.raher458.workers.dev"
local DEVICE_FILE = "RH_AUTH_DEVICE.dat"

local COLORS = {
    Background = Color3.fromRGB(13, 15, 23),
    Window = Color3.fromRGB(20, 23, 34),
    Panel = Color3.fromRGB(28, 32, 46),
    Panel2 = Color3.fromRGB(35, 40, 56),
    Panel3 = Color3.fromRGB(42, 48, 68),
    Accent = Color3.fromRGB(100, 90, 255),
    Accent2 = Color3.fromRGB(70, 130, 255),
    Green = Color3.fromRGB(70, 220, 145),
    Red = Color3.fromRGB(255, 85, 105),
    Yellow = Color3.fromRGB(255, 195, 75),
    Gray = Color3.fromRGB(110, 118, 145),
    Text = Color3.fromRGB(240, 242, 255),
    Muted = Color3.fromRGB(145, 153, 177),
    Border = Color3.fromRGB(52, 59, 80),
}

pcall(function()
    local old = PlayerGui:FindFirstChild("RH_AUTH_GUI")
    if old then old:Destroy() end
end)
pcall(function()
    local old = CoreGui:FindFirstChild("RH_AUTH_GUI")
    if old then old:Destroy() end
end)

local STATE = {
    adminSecret = "",
    authed = false,
    licenses = {},
    filters = "all",
    isCreating = false,
    isMinimized = false,
    isBubbleVisible = false,
}

-- ==== HTTP ====
local function getRequestFunction()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    return nil
end

local function apiRequest(path, body, adminSecret)
    local req = getRequestFunction()
    if not req then
        return nil, "Executor не предоставляет HTTP request API."
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
        return nil, "Ошибка подготовки JSON: " .. tostring(encodeError)
    end

    local ok, response = pcall(function()
        return req({
            Url = API_BASE .. path,
            Method = "POST",
            Headers = headers,
            Body = payload,
        })
    end)

    if not ok then
        return nil, "Ошибка запроса: " .. tostring(response)
    end

    if type(response) ~= "table" then
        return nil, "Некорректный ответ Executor."
    end

    local status = tonumber(
        response.StatusCode or response.Status or response.statusCode or response.status or 0
    ) or 0

    local raw = response.Body or response.body or ""

    local decodedOK, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if status < 200 or status >= 300 then
        local message
        if decodedOK and type(decoded) == "table" then
            message = decoded.error or decoded.message
        end
        if not message and raw ~= "" then
            message = tostring(raw):sub(1, 120)
        end
        return nil, tostring(message or ("HTTP " .. status))
    end

    if not decodedOK or type(decoded) ~= "table" then
        return nil, "Сервер вернул некорректный JSON."
    end

    return decoded
end

-- ==== DEVICE ====
local function generateDeviceId()
    return "RH-" .. HttpService:GenerateGUID(false)
end

local function getDeviceId()
    if type(readfile) == "function" and type(writefile) == "function" then
        local ok, result = pcall(function()
            if type(isfile) == "function" and isfile(DEVICE_FILE) then
                local value = readfile(DEVICE_FILE)
                if type(value) == "string" and #value >= 16 then
                    return value
                end
            end
            local value = generateDeviceId()
            writefile(DEVICE_FILE, value)
            return value
        end)
        if ok and type(result) == "string" then return result end
    end
    return nil
end

local deviceId = getDeviceId()

-- ==== HELPERS ====
local function formatSeconds(sec)
    sec = tonumber(sec)
    if not sec then return "—" end
    if sec <= 0 then return "истёк" end
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    if d > 0 then return string.format("%dд %dч", d, h) end
    if h > 0 then return string.format("%dч %dм", h, m) end
    if m > 0 then return string.format("%dм", m) end
    return string.format("%dс", sec)
end

local function formatDate(iso)
    if not iso or iso == "" then return "—" end
    local y, mo, d, h, mi = string.match(tostring(iso), "(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if not y then return tostring(iso) end
    return string.format("%s.%s.%s %s:%s", d, mo, y, h, mi)
end

local function isRevoked(item)
    local v = item and item.is_active
    if v == 0 or v == false or v == "0" then return true end
    return false
end

local function getLicenseStatus(item)
    if not item then return "expired", "ОШИБКА", COLORS.Gray end
    if isRevoked(item) then return "revoked", "ОТОЗВАН", COLORS.Red end
    if item.expired == true then return "expired", "ИСТЁК", COLORS.Gray end
    if not item.activated_at and item.duration_seconds ~= nil then
        return "pending", "НЕ АКТИВИРОВАН", COLORS.Yellow
    end
    return "active", "АКТИВЕН", COLORS.Green
end

-- Контрастный цвет текста по яркости фона
local function getContrastText(bgColor)
    local lum = (bgColor.R * 0.299) + (bgColor.G * 0.587) + (bgColor.B * 0.114)
    if lum > 0.5 then
        return Color3.fromRGB(20, 20, 30)
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

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

local function bindButton(button, callback)
    button.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then
            warn("[RH-AUTH] Button error:", err)
        end
    end)
end

-- ==== MAIN GUI ====
local screenGui = create("ScreenGui", {
    Name = "RH_AUTH_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000,
    IgnoreGuiInset = false,
}, PlayerGui)

local FULL_HEIGHT = 460
local MINI_HEIGHT = 48
local WINDOW_WIDTH = 380

local main = create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, WINDOW_WIDTH, 0, FULL_HEIGHT),
    BackgroundColor3 = COLORS.Window,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, screenGui)

addCorner(main, 12)
addStroke(main, COLORS.Border, 1)

local scale = create("UIScale", { Scale = 1 }, main)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local scaleX = viewport.X / 410
    local scaleY = viewport.Y / 500
    scale.Scale = math.clamp(math.min(scaleX, scaleY), 0.72, 1)
end

updateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- ==== HEADER ====
local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
}, main)

create("TextLabel", {
    Position = UDim2.new(0, 13, 0, 4),
    Size = UDim2.new(1, -90, 0, 23),
    BackgroundTransparency = 1,
    Text = "RH-AUTH",
    TextColor3 = COLORS.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

create("TextLabel", {
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

-- ==== STATUS BAR ====
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

-- ==== NAV ====
local nav = create("Frame", {
    Position = UDim2.new(0, 10, 0, 96),
    Size = UDim2.new(1, -20, 0, 36),
    BackgroundTransparency = 1,
}, main)

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
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

local renderKeys
local refreshList

local ADM_TABS = { KEYS = true, CREATE = true }

local function makeAuthWall(page)
    local wall = create("Frame", {
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Name = "AuthWall",
        ZIndex = 50,
    }, page)
    addCorner(wall, 8)

    create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 16),
        Size = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1,
        Text = "🔒 Требуется авторизация",
        TextColor3 = COLORS.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 51,
    }, wall)

    create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 42),
        Size = UDim2.new(1, -28, 0, 46),
        BackgroundTransparency = 1,
        Text = "Перейди во вкладку ADMIN и введи ADMIN_SECRET.",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 51,
    }, wall)

    return wall
end

local function selectPage(name)
    if not pages[name] then return end

    activePage = name

    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end

    for buttonName, button in pairs(navButtons) do
        local selected = buttonName == name
        button.BackgroundColor3 = selected and COLORS.Accent or COLORS.Panel
        button.TextColor3 = selected and COLORS.Text or COLORS.Muted
    end

    if ADM_TABS[name] and not STATE.authed then
        return
    end

    if name == "KEYS" and STATE.authed and refreshList then
        task.spawn(function()
            local ok, err = pcall(refreshList)
            if not ok then warn("[RH-AUTH] refreshList:", err) end
        end)
    end
end

local function createNavButton(name, text, order)
    local button = create("TextButton", {
        Name = name,
        Size = UDim2.new(0.2, -4, 1, 0),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        LayoutOrder = order,
    }, nav)

    addCorner(button, 7)
    navButtons[name] = button

    bindButton(button, function()
        selectPage(name)
    end)

    return button
end

createNavButton("HOME", "ГЛАВНАЯ", 1)
createNavButton("KEYS", "КЛЮЧИ", 2)
createNavButton("CREATE", "СОЗДАТЬ", 3)
createNavButton("ADMIN", "ADMIN", 4)
createNavButton("ABOUT", "О ПАНЕЛИ", 5)

local homePage = createPage("HOME")
local keysPage = createPage("KEYS")
local createPg = createPage("CREATE")
local adminPage = createPage("ADMIN")
local aboutPage = createPage("ABOUT")

local keysAuthWall = makeAuthWall(keysPage)
local createAuthWall = makeAuthWall(createPg)

-- ==== COMPONENTS ====
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

local function createInput(parent, placeholder, defaultText, numeric)
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

    if numeric then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local cleaned = box.Text:gsub("%D", "")
            if cleaned ~= box.Text then
                box.Text = cleaned
            end
        end)
    end

    return box
end

local function createNumericInput(parent, placeholder, defaultText)
    return createInput(parent, placeholder, defaultText, true)
end

local function createButton(parent, text, callback, color, height)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, height or 36),
        BackgroundColor3 = color or COLORS.Panel2,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = COLORS.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = true,
    }, parent)

    addCorner(button, 7)
    bindButton(button, callback)

    return button
end

-- FIX 1: Toggle с OnChange callback — без гонки обработчиков
local function createToggle(parent, labelText, defaultOn)
    local state = defaultOn and true or false
    local changeCallbacks = {}

    local wrap = create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, parent)
    addCorner(wrap, 7)

    create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText or "",
        TextColor3 = COLORS.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, wrap)

    local track = create("Frame", {
        Position = UDim2.new(1, -58, 0.5, -12),
        Size = UDim2.new(0, 46, 0, 24),
        BackgroundColor3 = state and COLORS.Accent or COLORS.Panel2,
        BorderSizePixel = 0,
    }, wrap)
    addCorner(track, 12)

    local knob = create("Frame", {
        Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
    }, track)
    addCorner(knob, 10)

    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, wrap)

    bindButton(btn, function()
        state = not state

        TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = state and COLORS.Accent or COLORS.Panel2,
        }):Play()

        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        }):Play()

        for _, cb in ipairs(changeCallbacks) do
            pcall(cb, state)
        end
    end)

    local api = {
        Get = function() return state end,
        Set = function(v)
            state = v and true or false
            track.BackgroundColor3 = state and COLORS.Accent or COLORS.Panel2
            knob.Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
            for _, cb in ipairs(changeCallbacks) do
                pcall(cb, state)
            end
        end,
        OnChange = function(cb)
            table.insert(changeCallbacks, cb)
        end,
    }

    return api, wrap, btn
end

-- ==== MODAL ====
local modalOverlay = create("Frame", {
    Name = "ModalOverlay",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 500,
    Active = false,
}, screenGui)

local modalBox = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 280, 0, 150),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    ZIndex = 501,
    Active = true,
}, modalOverlay)

addCorner(modalBox, 12)
addStroke(modalBox, COLORS.Border, 1)

local modalTitle = create("TextLabel", {
    Position = UDim2.new(0, 16, 0, 14),
    Size = UDim2.new(1, -32, 0, 22),
    BackgroundTransparency = 1,
    Text = "Подтверждение",
    TextColor3 = COLORS.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 502,
}, modalBox)

local modalText = create("TextLabel", {
    Position = UDim2.new(0, 16, 0, 42),
    Size = UDim2.new(1, -32, 0, 44),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = COLORS.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 502,
}, modalBox)

local modalConfirm = create("TextButton", {
    Position = UDim2.new(0, 16, 1, -50),
    Size = UDim2.new(0.5, -20, 0, 36),
    BackgroundColor3 = COLORS.Red,
    BorderSizePixel = 0,
    Text = "ДА",
    TextColor3 = COLORS.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 502,
}, modalBox)
addCorner(modalConfirm, 7)

local modalCancel = create("TextButton", {
    Position = UDim2.new(0.5, 4, 1, -50),
    Size = UDim2.new(0.5, -20, 0, 36),
    BackgroundColor3 = COLORS.Panel2,
    BorderSizePixel = 0,
    Text = "ОТМЕНА",
    TextColor3 = COLORS.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 502,
}, modalBox)
addCorner(modalCancel, 7)

local modalCallback = nil

local function openModal(titleText, messageText, onConfirm, confirmColor)
    modalTitle.Text = titleText
    modalText.Text = messageText
    modalCallback = onConfirm
    modalConfirm.BackgroundColor3 = confirmColor or COLORS.Red
    modalOverlay.Visible = true
end

local function closeModal()
    modalOverlay.Visible = false
    modalCallback = nil
end

bindButton(modalCancel, function()
    closeModal()
end)

bindButton(modalConfirm, function()
    local cb = modalCallback
    closeModal()
    if cb then
        task.spawn(function()
            local ok, err = pcall(cb)
            if not ok then
                setStatus("Ошибка операции: " .. tostring(err), false)
            end
        end)
    end
end)

-- Клик по фону (не по кнопкам) — отмена
modalOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = input.Target
        if target == modalOverlay then
            closeModal()
        end
    end
end)

-- ==== HOME ====
section(homePage, "СТАТИСТИКА")

local statsFrame = create("Frame", {
    Size = UDim2.new(1, 0, 0, 320),
    BackgroundTransparency = 1,
}, homePage)

create("UIGridLayout", {
    CellSize = UDim2.new(0.5, -5, 0, 68),
    CellPadding = UDim2.new(0, 8, 0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, statsFrame)

local statValues = {}

local function statCard(label, color, key)
    local c = create("Frame", {
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, statsFrame)
    addCorner(c, 10)

    create("Frame", {
        Size = UDim2.new(0, 3, 0, 22),
        Position = UDim2.new(0, 0, 0, 14),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, c)

    local val = create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -20, 0, 26),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = COLORS.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, c)

    create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 40),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, c)

    statValues[key] = val
end

statCard("ВСЕГО", COLORS.Accent, "total")
statCard("АКТИВНЫХ", COLORS.Green, "active")
statCard("ИСТЁКШИХ", COLORS.Yellow, "expired")
statCard("ОТОЗВАНО", COLORS.Red, "revoked")
statCard("АКТИВИРОВАНО", COLORS.Accent2, "activated")
statCard("БЕССРОЧНЫХ", COLORS.Accent2, "lifetime")
statCard("ПРИВЯЗАНО", COLORS.Accent2, "bound")

create("Frame", { BackgroundTransparency = 1 }, statsFrame)

section(homePage, "БЫСТРЫЕ ДЕЙСТВИЯ")

createButton(homePage, "ОБНОВИТЬ СТАТИСТИКУ", function()
    if not STATE.authed then
        setStatus("Сначала авторизуйся — вкладка ADMIN.", false)
        return
    end

    setStatus("Загружаем статистику...", nil)

    local result, err = apiRequest("/admin/stats", {}, STATE.adminSecret)
    if not result or not result.stats then
        setStatus("Ошибка: " .. tostring(err or "нет статистики"), false)
        return
    end

    local s = result.stats
    for k, lbl in pairs(statValues) do
        lbl.Text = tostring(s[k] or 0)
    end

    setStatus("Статистика обновлена.", true)
end, COLORS.Accent)

createButton(homePage, "ПЕРЕЙТИ К КЛЮЧАМ", function()
    selectPage("KEYS")
end, COLORS.Panel2)

createButton(homePage, "СОЗДАТЬ НОВЫЙ КЛЮЧ", function()
    selectPage("CREATE")
end, COLORS.Panel2)

section(homePage, "СЕРВЕР")
infoCard(homePage, "CLOUDFLARE WORKER", API_BASE)

createButton(homePage, "ПРОВЕРИТЬ СВЯЗЬ", function()
    setStatus("Проверяем связь...", nil)

    local result, err = apiRequest("/admin/stats", {}, STATE.adminSecret)

    if result and result.stats then
        setStatus("Сервер онлайн. Ответ получен.", true)
    elseif err and tostring(err):find("Unauthorized") then
        setStatus("Сервер онлайн, но нужно ввести ADMIN_SECRET.", false)
    else
        setStatus("Ответ сервера: " .. tostring(err), false)
    end
end, COLORS.Panel2)

-- ==== CREATE ====
section(createPg, "НОВЫЙ КЛЮЧ")

infoCard(createPg, "СОЗДАНИЕ ЛИЦЕНЗИИ",
    "Укажи срок (Дни / Часы / Минуты) или включи Бессрочную лицензию. "
    .. "Ключ создастся свободным — привяжется при первой активации."
)

section(createPg, "СРОК ДЕЙСТВИЯ")

local durationRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
}, createPg)

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, durationRow)

local function labeledNumInput(parent, placeholder, default, order)
    local col = create("Frame", {
        Size = UDim2.new(0.333, -4, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = order,
    }, parent)

    local box = createNumericInput(col, placeholder, default)
    box.Size = UDim2.new(1, 0, 0, 36)
    box.Position = UDim2.new(0, 0, 0, 0)
    box.TextXAlignment = Enum.TextXAlignment.Center

    create("TextLabel", {
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundTransparency = 1,
        Text = placeholder,
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, col)

    return box
end

local daysBox = labeledNumInput(durationRow, "ДНИ", "0", 1)
local hoursBox = labeledNumInput(durationRow, "ЧАСЫ", "0", 2)
local minutesBox = labeledNumInput(durationRow, "МИН", "5", 3)

local lifetimeToggle, lifetimeWrap, lifetimeBtn = createToggle(
    createPg, "БЕССРОЧНАЯ ЛИЦЕНЗИЯ", false
)

-- FIX 1: используем OnChange, а НЕ второй MouseButton1Click
local function applyLifetimeBlock()
    local life = lifetimeToggle.Get()
    for _, box in ipairs({daysBox, hoursBox, minutesBox}) do
        box.TextEditable = not life
        box.TextColor3 = life and COLORS.Gray or COLORS.Text
    end
end

lifetimeToggle.OnChange(function()
    applyLifetimeBlock()
end)

-- применить сразу при создании
applyLifetimeBlock()

section(createPg, "ПАРАМЕТРЫ")

local countBox = createNumericInput(createPg, "Количество ключей (1-100)", "1")
local robloxIdBox = createInput(createPg, "Roblox User ID (опционально)", "")

local createStatusLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = COLORS.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, createPg)

createButton(createPg, "СОЗДАТЬ КЛЮЧ", function()
    if STATE.isCreating then
        setStatus("Запрос уже выполняется...", nil)
        return
    end

    if not STATE.authed then
        setStatus("Сначала авторизуйся — вкладка ADMIN.", false)
        return
    end

    local life = lifetimeToggle.Get()
    local days = tonumber(daysBox.Text) or 0
    local hours = tonumber(hoursBox.Text) or 0
    local minutes = tonumber(minutesBox.Text) or 0
    local count = tonumber(countBox.Text) or 1

    if not life and days + hours + minutes <= 0 then
        setStatus("Укажи срок или включи Бессрочную лицензию.", false)
        return
    end

    if count < 1 or count > 100 then
        setStatus("Количество должно быть от 1 до 100.", false)
        return
    end

    local body = {
        count = math.floor(count),
        lifetime = life,
    }

    if not life then
        body.days = math.floor(days)
        body.hours = math.floor(hours)
        body.minutes = math.floor(minutes)
    end

    local uid = tostring(robloxIdBox.Text or ""):gsub("%s+", "")
    if uid ~= "" then
        local n = tonumber(uid)
        if not n or n < 1 then
            setStatus("Некорректный Roblox User ID.", false)
            return
        end
        body.roblox_user_id = n
    end

    STATE.isCreating = true
    createStatusLabel.Text = "Создание..."
    createStatusLabel.TextColor3 = COLORS.Muted

    task.spawn(function()
        local result, err = apiRequest("/admin/create", body, STATE.adminSecret)
        STATE.isCreating = false

        if not result then
            createStatusLabel.Text = "Ошибка: " .. tostring(err)
            createStatusLabel.TextColor3 = COLORS.Red
            setStatus("Не удалось создать ключ: " .. tostring(err), false)
            return
        end

        local keys = result.keys or {}
        local failed = result.failed or {}

        createStatusLabel.Text = "Создано: " .. #keys .. (#failed > 0 and (" • ошибок: " .. #failed) or "")
        createStatusLabel.TextColor3 = #keys > 0 and COLORS.Green or COLORS.Red

        if #keys > 0 then
            local keyList = table.concat(keys, "\n")

            if type(setclipboard) == "function" then
                pcall(setclipboard, keyList)
                setStatus("Создано ключей: " .. #keys .. ". Скопированы в буфер.", true)
            else
                setStatus("Создано ключей: " .. #keys, true)
            end

            if refreshList then
                task.spawn(function()
                    local ok, e = pcall(refreshList)
                    if not ok then warn("[RH-AUTH] refreshList:", e) end
                end)
            end
        end

        if #failed > 0 then
            local reason = tostring(failed[1] and failed[1].reason or "?")
            setStatus("Некоторые ключи не созданы: " .. reason, false)
        end
    end)
end, COLORS.Accent, 40)

-- [КОНЕЦ ЧАСТИ 2]

-- ==== KEYS ====
section(keysPage, "ФИЛЬТРЫ")

local filterRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundTransparency = 1,
}, keysPage)

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, filterRow)

local filterDefs = {
    {id = "all",       label = "ВСЕ",      color = COLORS.Accent},
    {id = "active",    label = "АКТИВ",    color = COLORS.Green},
    {id = "pending",   label = "СВОБОД",   color = COLORS.Yellow},
    {id = "expired",   label = "ИСТЕКЛИ",  color = COLORS.Gray},
    {id = "revoked",   label = "ОТОЗВАН",  color = COLORS.Red},
}

local filterBtns = {}

for i, f in ipairs(filterDefs) do
    local fb = create("TextButton", {
        Size = UDim2.new(0.2, -4, 1, 0),
        BackgroundColor3 = f.color,
        BackgroundTransparency = (f.id == "all") and 0 or 0.6,
        Text = f.label,
        TextColor3 = COLORS.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = i,
        ZIndex = 2,
    }, filterRow)
    addCorner(fb, 7)
    filterBtns[f.id] = fb

    bindButton(fb, function()
        STATE.filters = f.id
        for id, b in pairs(filterBtns) do
            b.BackgroundTransparency = (id == f.id) and 0 or 0.6
        end
        if renderKeys then
            task.spawn(function()
                local ok, e = pcall(renderKeys)
                if not ok then warn("[RH-AUTH] renderKeys:", e) end
            end)
        end
    end)
end

createButton(keysPage, "ОБНОВИТЬ СПИСОК", function()
    if not STATE.authed then
        setStatus("Сначала авторизуйся — вкладка ADMIN.", false)
        return
    end
    if refreshList then
        task.spawn(function()
            local ok, e = pcall(refreshList)
            if not ok then warn("[RH-AUTH] refreshList:", e) end
        end)
    end
end, COLORS.Panel2, 32)

local countLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    BackgroundTransparency = 1,
    Text = "Ключей: 0",
    TextColor3 = COLORS.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, keysPage)

local cardsWrap = create("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y,
}, keysPage)

create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, cardsWrap)

local function buildKeyCard(item)
    local _, statusText, statusColor = getLicenseStatus(item)

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1,
    }, cardsWrap)
    addCorner(card, 10)
    addStroke(card, COLORS.Border, 1)

    create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = statusColor,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, card)

    create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -100, 0, 18),
        BackgroundTransparency = 1,
        Text = item.key or "?",
        TextColor3 = COLORS.Text,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    }, card)

    -- FIX 2: бейдж статуса с контрастным текстом
    local pill = create("TextLabel", {
        Position = UDim2.new(1, -92, 0, 7),
        Size = UDim2.new(0, 80, 0, 20),
        BackgroundColor3 = statusColor,
        BackgroundTransparency = 0.15,
        Text = statusText,
        TextColor3 = getContrastText(statusColor),
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, card)
    addCorner(pill, 10)

    local metaLabel = create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 30),
        Size = UDim2.new(1, -30, 0, 16),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    }, card)

    do
        local parts = {}
        local t
        if item.duration_seconds == nil then
            t = "∞ бессрочно"
        elseif item.expires_at then
            t = formatSeconds(item.remaining_seconds)
        else
            t = formatSeconds(item.duration_seconds)
        end
        table.insert(parts, "⏱ " .. t)
        if item.roblox_user_id then
            table.insert(parts, "👤 " .. tostring(item.roblox_user_id))
        end
        table.insert(parts, item.install_hash and "💻 привязан" or "💻 свободен")
        metaLabel.Text = table.concat(parts, "  •  ")
    end

    local hint = create("TextLabel", {
        Position = UDim2.new(1, -22, 0, 40),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "▾",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 2,
    }, card)

    local tapBtn = create("TextButton", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
    }, card)

    local expanded = false
    local actionsRow = nil

    local function collapse()
        expanded = false
        hint.Text = "▾"
        if actionsRow then
            actionsRow:Destroy()
            actionsRow = nil
        end
        TweenService:Create(card, TweenInfo.new(0.2), {
            Size = UDim2.new(1, 0, 0, 62),
        }):Play()
    end

    local function expand()
        expanded = true
        hint.Text = "▴"

        actionsRow = create("Frame", {
            Position = UDim2.new(0, 10, 0, 60),
            Size = UDim2.new(1, -20, 0, 36),
            BackgroundTransparency = 1,
            ZIndex = 10,
        }, card)

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, actionsRow)

        local function actBtn(text, color, order, cb)
            local b = create("TextButton", {
                Size = UDim2.new(0.25, -3, 1, 0),
                BackgroundColor3 = color or COLORS.Panel2,
                BorderSizePixel = 0,
                Text = text,
                TextColor3 = COLORS.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                AutoButtonColor = true,
                LayoutOrder = order,
                ZIndex = 11,
            }, actionsRow)
            addCorner(b, 7)
            bindButton(b, cb)
            return b
        end

        actBtn("📋", COLORS.Panel2, 1, function()
            if type(setclipboard) == "function" then
                local ok = pcall(setclipboard, item.key or "")
                if ok then
                    setStatus("Ключ скопирован.", true)
                else
                    setStatus("Не удалось скопировать.", false)
                end
            else
                setStatus("Буфер обмена недоступен.", false)
            end
        end)

        actBtn("🚫", COLORS.Panel2, 2, function()
            setStatus("Отзываем...", nil)
            local result, err = apiRequest("/admin/revoke", { key = item.key }, STATE.adminSecret)
            if result and result.success then
                setStatus("Ключ отозван.", true)
                if refreshList then
                    task.spawn(function()
                        local ok, e = pcall(refreshList)
                        if not ok then warn("[RH-AUTH] refreshList:", e) end
                    end)
                end
            else
                setStatus("Ошибка: " .. tostring(err or "нет ответа"), false)
            end
        end)

        actBtn("🔄", COLORS.Panel2, 3, function()
            openModal(
                "Сбросить HWID?",
                "Ключ " .. tostring(item.key) .. " отвяжется от текущего устройства.",
                function()
                    local result, err = apiRequest("/admin/reset-device", { key = item.key }, STATE.adminSecret)
                    if result and result.success then
                        setStatus("HWID сброшен.", true)
                        if refreshList then
                            task.spawn(function()
                                local ok, e = pcall(refreshList)
                                if not ok then warn("[RH-AUTH] refreshList:", e) end
                            end)
                        end
                    else
                        setStatus("Ошибка: " .. tostring(err or "нет ответа"), false)
                    end
                end,
                COLORS.Yellow
            )
        end)

        actBtn("🗑", COLORS.Panel2, 4, function()
            openModal(
                "Удалить ключ?",
                "Ключ " .. tostring(item.key) .. " будет удалён НАВСЕГДА вместе со всеми сессиями.",
                function()
                    local result, err = apiRequest("/admin/delete", { key = item.key }, STATE.adminSecret)
                    if result and result.success then
                        setStatus("Ключ удалён.", true)
                        if refreshList then
                            task.spawn(function()
                                local ok, e = pcall(refreshList)
                                if not ok then warn("[RH-AUTH] refreshList:", e) end
                            end)
                        end
                    else
                        setStatus("Ошибка: " .. tostring(err or "нет ответа"), false)
                    end
                end,
                COLORS.Red
            )
        end)

        TweenService:Create(card, TweenInfo.new(0.25), {
            Size = UDim2.new(1, 0, 0, 104),
        }):Play()
    end

    bindButton(tapBtn, function()
        if expanded then collapse() else expand() end
    end)

    return card
end

renderKeys = function()
    if keysAuthWall then
        keysAuthWall.Visible = not STATE.authed
    end

    for _, ch in ipairs(cardsWrap:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end

    if not STATE.authed then
        countLabel.Text = "Ключей: 0"
        return
    end

    local all = STATE.licenses or {}
    local filter = STATE.filters or "all"
    local shown = 0

    for _, item in ipairs(all) do
        local status = getLicenseStatus(item)
        if filter == "all" or status == filter then
            buildKeyCard(item)
            shown = shown + 1
        end
    end

    countLabel.Text = "Ключей: " .. shown .. " из " .. #all

    if shown == 0 then
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 1,
            Text = "Нет ключей в этой категории.",
            TextColor3 = COLORS.Muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
        }, cardsWrap)
    end
end

refreshList = function()
    if not STATE.authed then
        setStatus("Сначала авторизуйся в ADMIN.", false)
        return
    end

    setStatus("Загружаем ключи...", nil)

    local result, err = apiRequest("/admin/list", {}, STATE.adminSecret)

    if not result then
        setStatus("Ошибка загрузки ключей: " .. tostring(err), false)
        return
    end

    STATE.licenses = result.keys or {}
    renderKeys()
    setStatus("Загружено ключей: " .. #STATE.licenses, true)
end

-- ==== ADMIN ====
section(adminPage, "АВТОРИЗАЦИЯ")

infoCard(adminPage, "ЗАЩИЩЁННЫЙ ДОСТУП",
    "Введи ADMIN_SECRET. Секрет хранится только в памяти текущей сессии."
)

local adminSecretBox = createInput(adminPage, "ADMIN_SECRET")

createButton(adminPage, "ВОЙТИ", function()
    local secret = tostring(adminSecretBox.Text or ""):gsub("%s+", "")

    if secret == "" then
        setStatus("Введи ADMIN_SECRET.", false)
        return
    end

    setStatus("Проверяем секрет...", nil)

    local result, err = apiRequest("/admin/stats", {}, secret)

    if not result or not result.stats then
        setStatus("Доступ не подтверждён: " .. tostring(err or "неверный ответ сервера"), false)
        return
    end

    STATE.adminSecret = secret
    STATE.authed = true
    setStatus("Успешный вход. Загружаем данные...", true)

    local listResult, listErr = apiRequest("/admin/list", {}, STATE.adminSecret)
    local statsResult, statsErr = apiRequest("/admin/stats", {}, STATE.adminSecret)

    local okList = listResult and listResult.keys ~= nil
    local okStats = statsResult and statsResult.stats ~= nil

    if okList then
        STATE.licenses = listResult.keys or {}
    end
    renderKeys()

    if okStats then
        local s = statsResult.stats
        for k, lbl in pairs(statValues) do
            lbl.Text = tostring(s[k] or 0)
        end
    end

    if okList and okStats then
        setStatus("Данные загружены. Ключей: " .. #STATE.licenses, true)
    elseif okList and not okStats then
        setStatus("Ключи загружены, но статистика недоступна: " .. tostring(statsErr), false)
    elseif not okList and okStats then
        setStatus("Статистика загружена, но ключи не загрузились: " .. tostring(listErr), false)
    else
        setStatus("Секрет принят, но данные не загружены. Проверь связь.", false)
    end
end, COLORS.Accent, 40)

createButton(adminPage, "ВЫЙТИ ИЗ АККАУНТА", function()
    STATE.adminSecret = ""
    STATE.authed = false
    STATE.licenses = {}
    adminSecretBox.Text = ""

    for _, lbl in pairs(statValues) do
        lbl.Text = "—"
    end

    renderKeys()
    setStatus("Сессия завершена.", true)
end, COLORS.Panel2)

section(adminPage, "СТАТУС СЕССИИ")

local authStatusLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Text = "Не авторизован",
    TextColor3 = COLORS.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, adminPage)
addCorner(authStatusLabel, 7)
addPadding(authStatusLabel, 9)

task.spawn(function()
    while screenGui.Parent do
        if STATE.authed then
            authStatusLabel.Text = "✓ Авторизован"
            authStatusLabel.TextColor3 = COLORS.Green
        else
            authStatusLabel.Text = "Не авторизован"
            authStatusLabel.TextColor3 = COLORS.Muted
        end
        task.wait(1)
    end
end)

-- ==== ABOUT ====
section(aboutPage, "О ПАНЕЛИ")
infoCard(aboutPage, "ВЕРСИЯ", VERSION)
infoCard(aboutPage, "НАЗНАЧЕНИЕ", "Панель управления лицензиями RH-AUTH.")
infoCard(aboutPage, "СЕРВЕР", API_BASE)
infoCard(aboutPage, "ПОЛЬЗОВАТЕЛЬ", "Roblox UserId: " .. tostring(LocalPlayer.UserId))
infoCard(aboutPage, "УСТРОЙСТВО",
    deviceId and ("Идентификатор: " .. deviceId:sub(1, 16) .. "...")
    or "Постоянное хранилище недоступно."
)
infoCard(aboutPage, "ТЕХНОЛОГИИ", "Cloudflare Workers + D1 • Lua • Delta Executor")

-- ==== DRAG ====
local dragging = false
local dragStart = nil
local startPosition = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or not dragStart or not startPosition then return end
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local delta = input.Position - dragStart
    main.Position = UDim2.new(
        startPosition.X.Scale, startPosition.X.Offset + delta.X,
        startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        dragStart = nil
        startPosition = nil
    end
end)

-- ==== BUBBLE ====
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

create("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "RH",
    TextColor3 = COLORS.Text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    ZIndex = 201,
}, bubble)

local pulseRunning = false

local function startPulse()
    if pulseRunning then return end
    pulseRunning = true
    task.spawn(function()
        while bubble.Visible do
            TweenService:Create(bubble, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Size = UDim2.new(0, 60, 0, 60) }):Play()
            task.wait(0.8)
            if not bubble.Visible then break end
            TweenService:Create(bubble, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Size = UDim2.new(0, 54, 0, 54) }):Play()
            task.wait(0.8)
        end
        pulseRunning = false
    end)
end

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
    if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    local d = input.Position - bStart
    if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then
        bMoved = true
    end
    bubble.Position = UDim2.new(
        bStartPos.X.Scale, bStartPos.X.Offset + d.X,
        bStartPos.Y.Scale, bStartPos.Y.Offset + d.Y
    )
end)

UserInputService.InputEnded:Connect(function(input)
    if not bDragging then return end
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        bDragging = false
        if not bMoved then
            bubble.Visible = false
            STATE.isBubbleVisible = false
            main.Visible = true
            main.Size = UDim2.new(0, WINDOW_WIDTH, 0, MINI_HEIGHT)
            TweenService:Create(main, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { Size = UDim2.new(0, WINDOW_WIDTH, 0, FULL_HEIGHT) }):Play()
            updateScale()
        end
    end
end)

-- ==== MIN/CLOSE ====
bindButton(minimizeButton, function()
    STATE.isMinimized = not STATE.isMinimized

    if STATE.isMinimized then
        content.Visible = false
        statusBar.Visible = false
        nav.Visible = false
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, WINDOW_WIDTH, 0, MINI_HEIGHT) }):Play()
        minimizeButton.Text = "+"
    else
        content.Visible = true
        statusBar.Visible = true
        nav.Visible = true
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, WINDOW_WIDTH, 0, FULL_HEIGHT) }):Play()
        minimizeButton.Text = "—"
    end
end)

bindButton(closeButton, function()
    TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.new(0, WINDOW_WIDTH - 40, 0, 400) }):Play()
    task.wait(0.2)
    main.Visible = false
    main.Size = UDim2.new(0, WINDOW_WIDTH, 0, FULL_HEIGHT)
    bubble.Visible = true
    STATE.isBubbleVisible = true
    STATE.isMinimized = false
    content.Visible = true
    statusBar.Visible = true
    nav.Visible = true
    startPulse()
end)

-- ==== INIT ====
selectPage("HOME")

setStatus("RH-Auth v" .. VERSION .. " загружен. Войди через ADMIN.", true)

renderKeys()

print("----------------------------------------")
print("RH-AUTH INITIALIZED")
print("Version: " .. VERSION)
print("UserId: " .. tostring(LocalPlayer.UserId))
print("API: " .. API_BASE)
print("----------------------------------------")

-- [КОНЕЦ ЧАСТИ 3]
-- [[ КОНЕЦ ФАЙЛА ]]