--[[
    RH-HUB
    Standalone Roblox Multi-Tool Hub
    Version: 1.0
    Platform: Roblox / Delta Executor / iOS

    Отдельный проект. Работает через Cloudflare Worker.
    Создание ключей — в панели RH-AUTH.
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

-- [КОНЕЦ ЧАСТИ 1]