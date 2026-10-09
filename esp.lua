--[[
    RH-AUTH
    Standalone Authentication & License Admin Panel
    Version: 1.2 "Cards"
    Platform: Roblox / Delta Executor / iOS
    Language: Russian

    Project: RH-Auth
    Separate from RAHERHUB.

    Cloudflare Worker:
    https://raherauth.raher458.workers.dev/

    CHANGELOG 1.2:
      - Вкладка «КЛЮЧИ» с карточками и фильтрами
      - Вкладка «СОЗДАТЬ» с точным вводом Дни/Часы/Минуты
      - Toggle «Бессрочная лицензия»
      - Статистика 7 карточек на главной
      - Тап по карточке → разворот с действиями
      - Подтверждение для «Сброс HWID» и «Удалить»
      - Кнопки «—»/«×» + кружок RH (как в v1.1)
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

local VERSION = "1.2 Cards"

local API_BASE =
    "https://raherauth.raher458.workers.dev"

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
-- 4. STATE
--==================================================

local STATE = {
    adminSecret = "",
    authed = false,
    licenses = {},
    filters = "all",
}

--==================================================
-- 5. HTTP REQUEST SUPPORT
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
-- 6. DEVICE IDENTIFIER
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
-- 7. HELPERS
--==================================================

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
    local y, mo, d, h, mi = string.match(iso, "(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if not y then return iso end
    return string.format("%s.%s.%s %s:%s", d, mo, y, h, mi)
end

local function getLicenseStatus(item)
    if item.is_active == 0 then
        return "revoked", "ОТОЗВАН", COLORS.Red
    end
    if item.expired then
        return "expired", "ИСТЁК", COLORS.Gray
    end
    if not item.activated_at and item.duration_seconds ~= nil then
        return "pending", "НЕ АКТИВИРОВАН", COLORS.Yellow
    end
    return "active", "АКТИВЕН", COLORS.Green
end

--==================================================
-- 8. GUI HELPERS
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
-- 9. MAIN GUI
--==================================================

local screenGui = create("ScreenGui", {
    Name = "RH_AUTH_GUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000,
    IgnoreGuiInset = false,
}, PlayerGui)

local FULL_HEIGHT = 460
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
    local scaleY = viewport.Y / 500

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
-- 10. HEADER
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
-- 11. STATUS BAR
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
-- 12. NAVIGATION (5 вкладок)
--==================================================

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

    -- Автоподгрузка при переходе на вкладку КЛЮЧИ
    if name == "KEYS" and STATE.authed then
        task.spawn(function()
            if _G._RHAuthRefreshList then
                _G._RHAuthRefreshList()
            end
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

    button.MouseButtonClick(function()
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
local createPage = createPage("CREATE")
local adminPage = createPage("ADMIN")
local aboutPage = createPage("ABOUT")

--==================================================
-- 13. UI COMPONENTS
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
        -- Только цифры (для iOS — цифровая клавиатура)
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

    button.MouseButtonClick(function()
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

local function createToggle(parent, labelText, defaultOn)
    local state = defaultOn and true or false

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

    btn.MouseButtonClick(function()
        state = not state

        TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = state and COLORS.Accent or COLORS.Panel2,
        }):Play()

        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        }):Play()
    end)

    return {
        Get = function() return state end,
        Set = function(v)
            state = v and true or false
            track.BackgroundColor3 = state and COLORS.Accent or COLORS.Panel2
            knob.Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
        end,
    }, wrap
end

local function formatJSON(value)
    local ok, result = pcall(function()
        return HttpService:JSONEncode(value)
    end)
    if ok then return result end
    return tostring(value)
end

--==================================================
-- 14. MODAL (подтверждение)
--==================================================

local modalOverlay = create("Frame", {
    Name = "ModalOverlay",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 500,
}, screenGui)

local modalBox = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 280, 0, 150),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    ZIndex = 501,
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

modalCancel.MouseButtonClick(closeModal)
modalOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        closeModal()
    end
end)

modalConfirm.MouseButtonClick(function()
    local cb = modalCallback
    closeModal()
    if cb then
        task.spawn(cb)
    end
end)

--==================================================
-- 15. HOME PAGE
--==================================================

section(homePage, "СТАТИСТИКА")

local statsFrame = create("Frame", {
    Size = UDim2.new(1, 0, 0, 280),
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
    addCorner(c:FindFirstChildOfClass("Frame"), 2)

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

-- Пустая карточка для выравнивания сетки (8-я ячейка)
create("Frame", {
    BackgroundTransparency = 1,
}, statsFrame)

section(homePage, "БЫСТРЫЕ ДЕЙСТВИЯ")

createButton(homePage, "ОБНОВИТЬ СТАТИСТИКУ", function()
    setStatus("Загружаем статистику...", nil)
    task.spawn(function()
        local result, err = apiRequest("/admin/stats", {}, STATE.adminSecret)

        if not result then
            setStatus("Ошибка: " .. tostring(err), false)
            return
        end

        local s = result.stats or {}

        for k, lbl in pairs(statValues) do
            lbl.Text = tostring(s[k] or 0)
        end

        setStatus("Статистика обновлена.", true)
    end)
end, COLORS.Accent)

createButton(homePage, "ПЕРЕЙТИ К КЛЮЧАМ", function()
    selectPage("KEYS")
end, COLORS.Panel2)

createButton(homePage, "СОЗДАТЬ НОВЫЙ КЛЮЧ", function()
    selectPage("CREATE")
end, COLORS.Panel2)

section(homePage, "СЕРВЕР")

infoCard(
    homePage,
    "CLOUDFLARE WORKER",
    API_BASE
)

createButton(homePage, "ПРОВЕРИТЬ СВЯЗЬ", function()
    setStatus("Проверяем связь...", nil)

    -- Проверяем через /admin/stats с секретом (если он есть)
    local result, err = apiRequest("/admin/stats", {}, STATE.adminSecret)

    if result and result.stats then
        setStatus("Сервер онлайн. Ответ получен.", true)
    elseif err and tostring(err):find("Unauthorized") then
        setStatus("Сервер онлайн, но нужно ввести ADMIN_SECRET.", false)
    else
        setStatus("Ответ сервера: " .. tostring(err), false)
    end
end, COLORS.Panel2)

-- [КОНЕЦ ЧАСТИ 2]
--==================================================
-- 16. CREATE PAGE (СОЗДАТЬ)
--==================================================

section(createPage, "НОВЫЙ КЛЮЧ")

infoCard(
    createPage,
    "СОЗДАНИЕ ЛИЦЕНЗИИ",
    "Укажи срок (Дни / Часы / Минуты) или включи Бессрочную лицензию. "
    .. "Ключ создастся свободным — привяжется при первой активации."
)

section(createPage, "СРОК ДЕЙСТВИЯ")

local durationRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
}, createPage)

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

local lifetimeToggle, lifetimeWrap = createToggle(
    createPage,
    "БЕССРОЧНАЯ ЛИЦЕНЗИЯ",
    false
)

local function applyLifetimeBlock()
    local life = lifetimeToggle.Get()
    for _, box in ipairs({daysBox, hoursBox, minutesBox}) do
        box.TextEditable = not life
        box.TextTransparency = life and 0.5 or 0
    end
end

lifetimeToggleWrap = lifetimeWrap
-- Навесим обработку на toggle — перехватываем через активацию кнопки
lifetimeWrap:FindFirstChildOfClass("TextButton").MouseButtonClick(function()
    applyLifetimeBlock()
end)

section(createPage, "ПАРАМЕТРЫ")

local countBox = createNumericInput(
    createPage,
    "Количество ключей (1-100)",
    "1"
)

local robloxIdBox = createInput(
    createPage,
    "Roblox User ID (опционально)",
    ""
)

-- TODO: [BIND_TO_SELF] тут будет кнопка «Мой UserId»,
--       которая вставит tostring(LocalPlayer.UserId) в robloxIdBox

local createStatusLabel = create("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = COLORS.Muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, createPage)

createButton(createPage, "СОЗДАТЬ КЛЮЧ", function()
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

    createStatusLabel.Text = "Создание..."
    createStatusLabel.TextColor3 = COLORS.Muted

    task.spawn(function()
        local result, err = apiRequest("/admin/create", body, STATE.adminSecret)

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

            -- обновим список ключей
            task.spawn(function()
                if _G._RHAuthRefreshList then
                    _G._RHAuthRefreshList()
                end
            end)
        end

        if #failed > 0 then
            setStatus("Некоторые ключи не созданы: " .. tostring(failed[1] and failed[1].reason or "?"), false)
        end
    end)
end, COLORS.Accent, 40)

--==================================================
-- 17. KEYS PAGE (КЛЮЧИ)
--==================================================

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
    }, filterRow)
    addCorner(fb, 7)
    filterBtns[f.id] = fb

    fb.MouseBittonClick(function()
        STATE.filters = f.id
        for id, b in pairs(filterBtns) do
            b.BackgroundTransparency = (id == f.id) and 0 or 0.6
        end
        _G._RHAuthRenderKeys()
    end)
end

local refreshBtn = createButton(keysPage, "ОБНОВИТЬ СПИСОК", function()
    if not STATE.authed then
        setStatus("Сначала авторизуйся — вкладка ADMIN.", false)
        return
    end
    _G._RHAuthRefreshList()
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

-- Карточка ключа
local function buildKeyCard(item)
    local _, statusText, statusColor = getLicenseStatus(item)

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, cardsWrap)
    addCorner(card, 10)
    addStroke(card, COLORS.Border, 1)

    -- Цветная полоска статуса
    create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = statusColor,
        BorderSizePixel = 0,
    }, card)

    -- Ключ
    local keyLabel = create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -100, 0, 18),
        BackgroundTransparency = 1,
        Text = item.key or "?",
        TextColor3 = COLORS.Text,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    -- Бейдж статуса
    local pill = create("TextLabel", {
        Position = UDim2.new(1, -84, 0, 7),
        Size = UDim2.new(0, 72, 0, 20),
        BackgroundColor3 = statusColor,
        BackgroundTransparency = 0.75,
        Text = statusText,
        TextColor3 = statusColor,
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        BorderSizePixel = 0,
    }, card)
    addCorner(pill, 10)
    addStroke(pill, statusColor, 1)

    -- Срок + инфо
    local metaLabel = create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 30),
        Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, card)

    do
        local parts = {}
        table.insert(parts, "⏱ " .. (item.duration_seconds == nil and "∞ бессрочно"
            or (item.expires_at and formatSeconds(item.remaining_seconds))
            or formatSeconds(item.duration_seconds)))
        if item.roblox_user_id then
            table.insert(parts, "👤 " .. tostring(item.roblox_user_id))
        end
        table.insert(parts, item.install_hash and "💻 привязан" or "💻 свободен")
        metaLabel.Text = table.concat(parts, "  •  ")
    end

    -- Хинт «развернуть»
    local hint = create("TextLabel", {
        Position = UDim2.new(1, -22, 0, 40),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "▾",
        TextColor3 = COLORS.Muted,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    }, card)

    -- Тап-зона (на весь верх карточки)
    local tapBtn = create("TextButton", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
        Text = "",
    }, card)

    -- Раскрытая панель с кнопками
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
            }, actionsRow)
            addCorner(b, 7)
            b.MouseButtonClick(function()
                task.spawn(cb)
            end)
        end

        actBtn("📋", COLORS.Panel2, 1, function()
            if type(setclipboard) == "function" then
                pcall(setclipboard, item.key or "")
                setStatus("Ключ скопирован.", true)
            end
        end)

        actBtn("🚫", COLORS.Panel2, 2, function()
            local result, err = apiRequest("/admin/revoke", { key = item.key }, STATE.adminSecret)
            if result and result.success then
                setStatus("Ключ отозван.", true)
                _G._RHAuthRefreshList()
            else
                setStatus("Ошибка: " .. tostring(err or "нет ответа"), false)
            end
        end)

        actBtn("🔄", COLORS.Panel2, 3, function()
            openModal(
                "Сбросить HWID?",
                "Ключ " .. tostring(item.key) .. " отвяжется от текущего устройства. "
                .. "Пользователь сможет активировать его заново.",
                function()
                    local result, err = apiRequest("/admin/reset-device", { key = item.key }, STATE.adminSecret)
                    if result and result.success then
                        setStatus("HWID сброшен.", true)
                        _G._RHAuthRefreshList()
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
                "Ключ " .. tostring(item.key) .. " будет удалён НАВСЕГДА вместе со всеми сессиями. "
                .. "Это действие нельзя отменить.",
                function()
                    local result, err = apiRequest("/admin/delete", { key = item.key }, STATE.adminSecret)
                    if result and result.success then
                        setStatus("Ключ удалён.", true)
                        _G._RHAuthRefreshList()
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

    tapBtn.MouseButtonClick(function()
        if expanded then
            collapse()
        else
            expand()
        end
    end)

    return card
end

-- Render функция
_G._RHAuthRenderKeys = function()
    for _, ch in ipairs(cardsWrap:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
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

-- Refresh функция
_G._RHAuthRefreshList = function()
    if not STATE.authed then
        setStatus("Сначала авторизуйся в ADMIN.", false)
        return
    end

    setStatus("Загружаем ключи...", nil)

    task.spawn(function()
        local result, err = apiRequest("/admin/list", {}, STATE.adminSecret)

        if not result then
            setStatus("Ошибка загрузки ключей: " .. tostring(err), false)
            return
        end

        STATE.licenses = result.keys or {}
        _G._RHAuthRenderKeys()
        setStatus("Загружено ключей: " .. #STATE.licenses, true)
    end)
end

--==================================================
-- 18. ADMIN PAGE
--==================================================

section(adminPage, "АВТОРИЗАЦИЯ")

infoCard(
    adminPage,
    "ЗАЩИЩЁННЫЙ ДОСТУП",
    "Введи ADMIN_SECRET. Секрет хранится только в памяти текущей сессии."
)

local adminSecretBox = createInput(
    adminPage,
    "ADMIN_SECRET"
)

createButton(adminPage, "ВОЙТИ", function()
    local secret = tostring(adminSecretBox.Text or ""):gsub("%s+", "")

    if secret == "" then
        setStatus("Введи ADMIN_SECRET.", false)
        return
    end

    setStatus("Проверяем секрет...", nil)

    task.spawn(function()
        -- Проверяем через /admin/stats
        local result, err = apiRequest("/admin/stats", {}, secret)

        if not result then
            setStatus("Доступ не подтверждён: " .. tostring(err), false)
            return
        end

        STATE.adminSecret = secret
        STATE.authed = true

        setStatus("Успешный вход. Загружаем данные...", true)

        -- Автозагрузка ключей и статистики
        task.spawn(function()
            local listResult = apiRequest("/admin/list", {}, STATE.adminSecret)
            if listResult then
                STATE.licenses = listResult.keys or {}
                _G._RHAuthRenderKeys()
            end

            local statsResult = apiRequest("/admin/stats", {}, STATE.adminSecret)
            if statsResult and statsResult.stats then
                local s = statsResult.stats
                for k, lbl in pairs(statValues) do
                    lbl.Text = tostring(s[k] or 0)
                end
            end

            setStatus("Данные загружены. Ключей: " .. #STATE.licenses, true)
        end)
    end)
end, COLORS.Accent, 40)

createButton(adminPage, "ВЫЙТИ ИЗ АККАУНТА", function()
    STATE.adminSecret = ""
    STATE.authed = false
    STATE.licenses = {}
    adminSecretBox.Text = ""

    for _, lbl in pairs(statValues) do
        lbl.Text = "—"
    end

    _G._RHAuthRenderKeys()

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

--==================================================
-- 19. ABOUT PAGE
--==================================================

section(aboutPage, "О ПАНЕЛИ")

infoCard(aboutPage, "ВЕРСИЯ", VERSION)

infoCard(
    aboutPage,
    "НАЗНАЧЕНИЕ",
    "Панель управления лицензиями RH-AUTH. Отдельный проект от RAHERHUB."
)

infoCard(
    aboutPage,
    "СЕРВЕР",
    API_BASE
)

infoCard(
    aboutPage,
    "ПОЛЬЗОВАТЕЛЬ",
    "Roblox UserId: " .. tostring(LocalPlayer.UserId)
)

infoCard(
    aboutPage,
    "УСТРОЙСТВО",
    deviceId
        and "Идентификатор: " .. deviceId:sub(1, 16) .. "..."
        or "Постоянное хранилище недоступно."
)

infoCard(
    aboutPage,
    "ТЕХНОЛОГИИ",
    "Cloudflare Workers + D1 • Lua (Roblox) • Delta Executor"
)

--==================================================
-- 20. WINDOW DRAG
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
-- 21. MINIMIZE / CLOSE / FLOATING BUBBLE
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

create("TextLabel", {
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

-- Кнопка «—»
minimizeButton.MouseButtonClick(function()
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

-- Кнопка «×»
closeButton.MouseButtonClick(function()
    TweenService:Create(
        main,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 300, 0, 400) }
    ):Play()

    task.wait(0.2)

    main.Visible = false
    main.Size = UDim2.new(0, 340, 0, FULL_HEIGHT)

    bubble.Visible = true
    startPulse()
end)

--==================================================
-- 22. INITIALIZATION
--==================================================

selectPage("HOME")

setStatus(
    "RH-Auth v" .. VERSION .. " загружен. Войди через ADMIN.",
    true
)

_G._RHAuthRenderKeys()

print("----------------------------------------")
print("RH-AUTH INITIALIZED")
print("Version: " .. VERSION)
print("UserId: " .. tostring(LocalPlayer.UserId))
print("API: " .. API_BASE)
print("----------------------------------------")

-- [КОНЕЦ ЧАСТИ 3]
-- [[ КОНЕЦ ФАЙЛА ]]