--[[
    RH-LAUNCHER — Standalone Roblox Launcher
    Version: 0.8.5-beta (Layout Fix + Syntax Fix)
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
    VERSION        = "0.8.5-beta",
    NAME           = "RH-LAUNCHER",
    API_BASE       = "https://raherauth.rh-launcher.workers.dev",
    TOKEN_FILE     = "RH_LAUNCHER_TOKEN.dat",
    DEVICE_FILE    = "RH_LAUNCHER_DEVICE.dat",
    TG_LINK        = "https://t.me/generalvaneska2024",
    WINDOW_W       = 400,
    WINDOW_H       = 460,
    RETRY_MAX      = 3,
    RETRY_DELAY    = 1.5,
    HEARTBEAT_S    = 300,
    GUI_WATCH_S    = 5,
    GUI_WATCH_STEP = 0.5,
}

local C = {
    bg       = Color3.fromRGB(10, 11, 16),
    surface  = Color3.fromRGB(18, 22, 35),
    surface2 = Color3.fromRGB(25, 30, 48),
    surface3 = Color3.fromRGB(35, 42, 65),
    button   = Color3.fromRGB(25, 30, 48),
    input    = Color3.fromRGB(15, 18, 28),
    border   = Color3.fromRGB(45, 55, 85),
    text     = Color3.fromRGB(255, 255, 255),
    muted    = Color3.fromRGB(140, 150, 180),
    accent   = Color3.fromRGB(80, 100, 255),
    pink     = Color3.fromRGB(160, 80, 255),
    green    = Color3.fromRGB(50, 220, 150),
    red      = Color3.fromRGB(240, 70, 90),
    yellow   = Color3.fromRGB(255, 190, 70),
}

local GameIcons = {
    ["Blox Fruits"] = "🍎",
    ["Steal an Egg"] = "🥚",
    ["Steal a Brainrot"] = "🧠",
    ["Murder Mystery 2"] = "🔪",
    ["RIVALS"] = "🔫",
    ["Grow a Garden 2"] = "🌱",
    ["Blade Ball"] = "⚔️",
    ["Pet Simulator 99"] = "🐾",
    ["Meme Sea"] = "😂",
    ["San Diego Border RP"] = "👮",
    ["+1 Speed Keyboard"] = "⌨️",
    ["Drive A Kukirin!"] = "🏎️",
    ["BloxStrike"] = "🔫",
    default = "🎮"
}

local GUI_NAMES = { "RH_LAUNCHER_GUI", "RH_LAUNCHER_AUTH_GUI", "RH_LAUNCHER_TOAST" }

pcall(function()
    local core = game:GetService("CoreGui")
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    for _, name in ipairs(GUI_NAMES) do
        local o = core:FindFirstChild(name)
        if o then o:Destroy() end
        if pg then
            local p = pg:FindFirstChild(name)
            if p then p:Destroy() end
        end
    end
end)

local STATE = { authed = false, token = nil, deviceId = nil, busy = false, games = {}, localRemaining = nil }

-- ============================================================
-- HELPERS
-- ============================================================
local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", { Color = color or C.border, Thickness = thickness or 1, Transparency = transparency or 0.2 }, parent)
end

local function safeParent(guiObj)
    local ok = pcall(function() guiObj.Parent = game:GetService("CoreGui") end)
    if not ok or not guiObj.Parent then guiObj.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function makeDraggable(frame, dragArea)
    local dragging, dragInput, dragStart, startPos, moved
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragInput = input; dragStart = input.Position; startPos = frame.Position; moved = false
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then moved = true end
            if moved then
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

local function hasFileAPI()
    return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
end

local function generateDeviceId() return "RH-" .. HttpService:GenerateGUID(false) end

local function loadDeviceId()
    if hasFileAPI() then
        local ok, result = pcall(function()
            if isfile(CONFIG.DEVICE_FILE) then
                local val = readfile(CONFIG.DEVICE_FILE)
                if type(val) == "string" and #val >= 16 then return (tostring(val):gsub("%s+", "")) end
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

local function saveToken(token) if hasFileAPI() then pcall(writefile, CONFIG.TOKEN_FILE, tostring(token)) end end

local function loadToken()
    if not hasFileAPI() then return nil end
    local ok, result = pcall(function()
        if isfile(CONFIG.TOKEN_FILE) then
            local val = readfile(CONFIG.TOKEN_FILE)
            if type(val) == "string" and #val >= 16 then return (tostring(val):gsub("%s+", "")) end
        end
        return nil
    end)
    if ok then return result end
end

local function clearToken()
    if hasFileAPI() and type(delfile) == "function" then
        pcall(function() if isfile(CONFIG.TOKEN_FILE) then delfile(CONFIG.TOKEN_FILE) end end)
    end
end

local function getRequestFn()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    return nil
end

local function api(path, body, method)
    local req = getRequestFn()
    if not req then return nil, "Executor не поддерживает HTTP" end
    method = method or "POST"
    local payload = ""
    if method ~= "GET" then
        local okEnc, encErr = pcall(function() payload = HttpService:JSONEncode(body or {}) end)
        if not okEnc then return nil, "JSON error: " .. tostring(encErr) end
    end
    local response, done = nil, false

    task.spawn(function()
        local ok, res = pcall(function()
            local options = { Url = CONFIG.API_BASE .. path, Method = method, Headers = { ["Content-Type"] = "application/json", ["Accept"] = "application/json" } }
            if method ~= "GET" then options.Body = payload end
            return req(options)
        end)
        response = ok and res or { __error = tostring(res) }
        done = true
    end)

    local t0 = os.clock()
    while not done and os.clock() - t0 < 15 do task.wait(0.1) end
    if not done then return nil, "Таймаут" end
    if type(response) ~= "table" then return nil, "Нет ответа" end
    if response.__error then return nil, response.__error end

    local status = tonumber(response.StatusCode or response.Status or 0) or 0
    local raw = response.Body or response.body or ""
    local okDec, decoded = pcall(function() return HttpService:JSONDecode(raw) end)

    if status < 200 or status >= 300 then
        local msg
        if okDec and type(decoded) == "table" then msg = decoded.error or decoded.message end
        if not msg and raw ~= "" then msg = tostring(raw):sub(1, 120) end
        return nil, tostring(msg or ("HTTP " .. status))
    end
    if not okDec or type(decoded) ~= "table" then return nil, "Bad response" end
    return decoded
end

local function apiWithRetry(path, body)
    local lastErr
    for attempt = 1, CONFIG.RETRY_MAX do
        local result, err = api(path, body)
        if result then return result, nil, attempt end
        lastErr = err
        local low = tostring(err or ""):lower()
        if low:find("таймаут") or low:find("timeout") then
            if attempt < CONFIG.RETRY_MAX then task.wait(CONFIG.RETRY_DELAY) end
        else return nil, err, attempt end
    end
    return nil, lastErr, CONFIG.RETRY_MAX
end

-- ============================================================
-- TOAST
-- ============================================================
local toastGui = create("ScreenGui", { Name = "RH_LAUNCHER_TOAST", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 99999, Enabled = true })
safeParent(toastGui)
local toastContainer = create("Frame", { Position = UDim2.new(0, 0, 1, -180), Size = UDim2.new(1, 0, 0, 170), BackgroundTransparency = 1, ZIndex = 200 }, toastGui)
create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }, toastContainer)
create("UIPadding", { PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, toastContainer)
local toastN = 0
local function showToast(text, kind)
    toastN = toastN + 1
    local col = kind == "ok" and C.green or kind == "err" and C.red or kind == "warn" and C.yellow or C.accent
    local t = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.surface2, BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = toastN }, toastContainer)
    corner(t, 10)
    create("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = col, BorderSizePixel = 0 }, t)
    create("TextLabel", { Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = tostring(text), TextColor3 = C.text, TextSize = 11, Font = Enum.Font.GothamMedium, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, t)
    TweenService:Create(t, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 38) }):Play()
    task.delay(3.2, function()
        if t.Parent then
            TweenService:Create(t, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
            task.wait(0.2) t:Destroy()
        end
    end)
end

-- ============================================================
-- AUTH GUI
-- ============================================================
local authGui = create("ScreenGui", { Name = "RH_LAUNCHER_AUTH_GUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 99999, Enabled = true })
safeParent(authGui)
local authMain = create("Frame", { Name = "AuthWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 380), BackgroundColor3 = C.surface, BorderSizePixel = 0, ClipsDescendants = true }, authGui)
corner(authMain, 16)
stroke(authMain, C.border, 1, 0.15)

local function authFit()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    authMain.Size = UDim2.fromOffset(math.min(300, vp.X - 24), math.min(380, vp.Y - 60))
end
authFit()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(authFit) end

local authHeader = create("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, authMain)
corner(authHeader, 16)
create("Frame", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -20), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, authHeader)

local authTitle = create("TextLabel", { Position = UDim2.new(0, 20, 0, 6), Size = UDim2.new(1, -40, 0, 32), BackgroundTransparency = 1, Text = "RH-LAUNCHER", TextColor3 = C.pink, TextSize = 24, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center }, authHeader)
create("TextLabel", { Position = UDim2.new(0, 20, 0, 38), Size = UDim2.new(1, -40, 0, 14), BackgroundTransparency = 1, Text = "СИСТЕМА АВТОРИЗАЦИИ", TextColor3 = C.muted, TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Center }, authHeader)

makeDraggable(authMain, authHeader)

task.spawn(function()
    local hue = 0
    while authGui.Parent do
        hue = (hue + 0.008) % 1
        if authTitle.Parent then authTitle.TextColor3 = Color3.fromHSV(hue, 0.7, 1) end
        task.wait(0.05)
    end
end)

create("TextLabel", { Position = UDim2.new(0.5, -12, 0, 70), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "🔒", TextColor3 = C.text, TextSize = 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center }, authMain)
create("TextLabel", { Position = UDim2.new(0, 22, 0, 98), Size = UDim2.new(1, -44, 0, 34), BackgroundTransparency = 1, Text = "Получите ключ у администратора.\nОдин ключ = одно устройство.", TextColor3 = C.muted, TextSize = 10, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top }, authMain)
create("TextLabel", { Position = UDim2.new(0, 22, 0, 136), Size = UDim2.new(1, -44, 0, 14), BackgroundTransparency = 1, Text = "КЛЮЧ ДОСТУПА", TextColor3 = C.muted, TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, authMain)

local authInputWrap = create("Frame", { Position = UDim2.new(0, 22, 0, 154), Size = UDim2.new(1, -44, 0, 42), BackgroundColor3 = C.input, BorderSizePixel = 0 }, authMain)
corner(authInputWrap, 10)
local authInputStroke = stroke(authInputWrap, C.border, 1.5, 0.1)
local authKeyBox = create("TextBox", { Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "RAH-XXXXXXXXXXXXXXXX", PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 12, Font = Enum.Font.Code, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, authInputWrap)

authKeyBox.Focused:Connect(function() TweenService:Create(authInputStroke, TweenInfo.new(0.15), { Color = C.accent, Transparency = 0 }):Play() end)
authKeyBox.FocusLost:Connect(function() TweenService:Create(authInputStroke, TweenInfo.new(0.15), { Color = C.border, Transparency = 0.1 }):Play() end)

local authActBtn = create("TextButton", { Position = UDim2.new(0, 22, 0, 206), Size = UDim2.new(1, -44, 0, 44), BackgroundColor3 = C.accent, BorderSizePixel = 0, Text = "✨  АКТИВИРОВАТЬ", TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.GothamBold, AutoButtonColor = false }, authMain)
corner(authActBtn, 12)

local authTgBtn = create("TextButton", { Position = UDim2.new(0, 22, 0, 258), Size = UDim2.new(1, -44, 0, 40), BackgroundColor3 = C.button, BorderSizePixel = 0, Text = "📱  ПОЛУЧИТЬ КЛЮЧ", TextColor3 = C.text, TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = true }, authMain)
corner(authTgBtn, 11)
stroke(authTgBtn, C.pink, 1, 0.3)

local authStatus = create("TextLabel", { Position = UDim2.new(0, 22, 1, -36), Size = UDim2.new(1, -44, 0, 28), BackgroundTransparency = 1, Text = "Ожидание ввода...", TextColor3 = C.muted, TextSize = 10, Font = Enum.Font.GothamMedium, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, authMain)

local function setStatus(text, kind)
    authStatus.Text = tostring(text)
    if kind == "ok" then authStatus.TextColor3 = C.green
    elseif kind == "err" then authStatus.TextColor3 = C.red
    elseif kind == "warn" then authStatus.TextColor3 = C.yellow
    else authStatus.TextColor3 = C.muted end
end

local function setBusy(busy)
    STATE.busy = busy
    if busy then authActBtn.Text = "⏳  ПРОВЕРКА..."; authActBtn.BackgroundColor3 = C.surface2
    else authActBtn.Text = "✨  АКТИВИРОВАТЬ"; authActBtn.BackgroundColor3 = C.accent end
end

local tgCooldown = false
authTgBtn.MouseButton1Click:Connect(function()
    if tgCooldown then return end
    tgCooldown = true
    local copied = false
    if type(setclipboard) == "function" then copied = pcall(setclipboard, CONFIG.TG_LINK)
    elseif type(toclipboard) == "function" then copied = pcall(toclipboard, CONFIG.TG_LINK) end
    if copied then showToast("Ссылка скопирована!", "ok"); setStatus("Ссылка в буфере", "ok")
    else showToast("Скопируйте вручную", "warn"); setStatus("Ссылка: " .. CONFIG.TG_LINK, "warn") end
    task.delay(2.5, function() tgCooldown = false end)
end)

-- ============================================================
-- AUTH LOGIC
-- ============================================================
local function verifySavedToken(token)
    if type(token) ~= "string" or token == "" then return false, "no_token" end
    local result, err = api("/verify", { token = token })
    if not result then
        local low = tostring(err or ""):lower()
        if low:find("expired") then clearToken(); return false, "expired" end
        return false, "request_failed"
    end
    if result.valid ~= true then return false, "invalid" end
    return true, "ok"
end

local onAuthSuccess

local function activateKey(rawKey)
    local key = tostring(rawKey or ""):gsub("%s+", "")
    if key == "" then setStatus("Введите ключ доступа", "warn"); showToast("Ключ пустой", "warn"); return end
    if STATE.busy then return end
    setBusy(true); setStatus("Активация ключа...", nil)

    task.spawn(function()
        if type(STATE.deviceId) ~= "string" or STATE.deviceId == "" then STATE.deviceId = generateDeviceId() end
        local body = { 
            key = key, 
            install_hash = STATE.deviceId,
            roblox_name = LocalPlayer.Name
        }
        local result, err, attempts = apiWithRetry("/activate", body)
        if attempts > 1 and result then setStatus("Попытка " .. attempts .. " успешна", "ok") end
        if not result then
            setBusy(false)
            local msg = tostring(err or "неизвестная ошибка")
            local low = msg:lower()
            if low:find("invalid license") then setStatus("❌ Неверный ключ", "err"); showToast("Неверный ключ", "err")
            elseif low:find("bound to another") then setStatus("❌ Ключ привязан к другому устройству", "err"); showToast("Ключ занят другим устройством", "err")
            elseif low:find("expired") then setStatus("❌ Ключ истёк", "err"); showToast("Ключ истёк", "err")
            elseif low:find("таймаут") or low:find("timeout") then setStatus("❌ Сервер не отвечает", "err"); showToast("Сервер не отвечает", "err")
            else setStatus("❌ " .. msg, "err"); showToast(msg, "err") end
            return
        end
        if type(result.token) ~= "string" or result.token == "" then setBusy(false); setStatus("❌ Сервер не выдал токен", "err"); showToast("Пустой ответ", "err"); return end
        
        if result.remaining_seconds then
            STATE.localRemaining = tonumber(result.remaining_seconds)
        end
        
        setBusy(false)
        onAuthSuccess(result.token)
    end)
end

authActBtn.MouseButton1Click:Connect(function()
    if STATE.busy then return end
    activateKey(authKeyBox.Text)
end)

authKeyBox.FocusLost:Connect(function(enterPressed) if enterPressed and not STATE.busy then activateKey(authKeyBox.Text) end end)

-- ============================================================
-- MAIN GUI
-- ============================================================
local mainGui = create("ScreenGui", { Name = "RH_LAUNCHER_GUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 99998, Enabled = false })
safeParent(mainGui)

local WIN_W, WIN_H = CONFIG.WINDOW_W, CONFIG.WINDOW_H
local main = create("Frame", { Name = "MainWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true }, mainGui)
corner(main, 16); stroke(main, C.border, 1, 0.15)

local function fitMain()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    main.Size = UDim2.fromOffset(math.min(WIN_W, vp.X - 20), math.min(WIN_H, vp.Y - 60))
end
fitMain()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMain) end

-- ============================================================
-- HEADER
-- ============================================================
local header = create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 2 }, main)
corner(header, 16)
create("Frame", { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -18), BackgroundColor3 = C.surface, BorderSizePixel = 0 }, header)

local logoLabel = create("TextLabel", { Position = UDim2.new(0, 12, 0, 8), Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Text = "RH", TextColor3 = C.pink, Font = Enum.Font.GothamBlack, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, header)
local titleLabel = create("TextLabel", { Position = UDim2.new(0, 50, 0, 8), Size = UDim2.new(1, -150, 0, 20), BackgroundTransparency = 1, Text = "RH-LAUNCHER", TextColor3 = C.text, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, header)
create("TextLabel", { Position = UDim2.new(0, 50, 0, 28), Size = UDim2.new(1, -150, 0, 14), BackgroundTransparency = 1, Text = "v" .. CONFIG.VERSION, TextColor3 = C.muted, TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left }, header)

local timerLabel = create("TextLabel", { Position = UDim2.new(1, -110, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(90, 28), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "⏱ ∞", TextColor3 = C.green, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, header)
corner(timerLabel, 14)
stroke(timerLabel, C.border, 1, 0.5)

makeDraggable(main, header)

-- ============================================================
-- BANNER
-- ============================================================
local banner = create("Frame", { Position = UDim2.new(0, 8, 0, 64), Size = UDim2.new(1, -16, 0, 50), BackgroundColor3 = C.surface2, BorderSizePixel = 0, ClipsDescendants = true }, main)
corner(banner, 10)
stroke(banner, C.accent, 1, 0.3)

local gradientFrame = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.accent, BackgroundTransparency = 0.7, BorderSizePixel = 0 }, banner)
corner(gradientFrame, 10)
local grad = create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.surface2), ColorSequenceKeypoint.new(1, C.accent)}, Rotation = 45 }, gradientFrame)

create("TextLabel", { Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 20), BackgroundTransparency = 1, Text = "RH-LAUNCHER", TextColor3 = C.text, Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left }, banner)
create("TextLabel", { Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -24, 0, 14), BackgroundTransparency = 1, Text = "Быстрый • Удобный", TextColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, banner)

-- ============================================================
-- SEARCH BAR
-- ============================================================
local searchFrame = create("Frame", { Position = UDim2.new(0, 8, 0, 120), Size = UDim2.new(1, -16, 0, 36), BackgroundColor3 = C.input, BorderSizePixel = 0 }, main)
corner(searchFrame, 8)
stroke(searchFrame, C.border, 1, 0.5)

create("TextLabel", { Position = UDim2.new(0, 10, 0, 0), Size = UDim2.fromOffset(20, 36), BackgroundTransparency = 1, Text = "🔍", TextColor3 = C.muted, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, searchFrame)

local searchBox = create("TextBox", { Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Поиск игр...", PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, searchFrame)

-- ============================================================
-- CONTENT
-- ============================================================
local content = create("Frame", { Position = UDim2.new(0, 8, 0, 160), Size = UDim2.new(1, -16, 1, -168), BackgroundTransparency = 1, ClipsDescendants = true }, main)

local function makePage(parent, name)
    local page = create("ScrollingFrame", { Name = name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, parent)
    create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 4) }, page)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, page)
    return page
end

local gamesPage = makePage(content, "GamesPage")
local cheatsPage = makePage(content, "CheatsPage")

local cheatsBackBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "←  НАЗАД К ИГРАМ", TextColor3 = C.text, TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = true, LayoutOrder = -2 }, cheatsPage)
corner(cheatsBackBtn, 8)

local cheatsTitleLbl = create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", TextColor3 = C.accent, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -1 }, cheatsPage)

local cheatsListFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 0 }, cheatsPage)
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, cheatsListFrame)

local function showPage(name)
    gamesPage.Visible = (name == "games")
    cheatsPage.Visible = (name == "cheats")
    searchFrame.Visible = (name == "games")
    banner.Visible = (name == "games")
    
    if name == "games" then
        TweenService:Create(content, TweenInfo.new(0.2), { Position = UDim2.new(0, 8, 0, 160) }):Play()
    else
        TweenService:Create(content, TweenInfo.new(0.2), { Position = UDim2.new(0, 8, 0, 64) }):Play()
    end
end

-- ============================================================
-- CHEAT TRACKER
-- ============================================================
local CheatTracker = { active = false, killFlag = false, guis = {}, connSnap = nil, currentName = nil }
local PROTECTED_GUI_NAMES = { RH_LAUNCHER_AUTH_GUI = true, RH_LAUNCHER_GUI = true, RH_LAUNCHER_TOAST = true }
local function isProtectedGui(obj) return PROTECTED_GUI_NAMES[obj.Name] == true end

local function snapshotGuis()
    local set = {}
    local function scan(parent) for _, obj in ipairs(parent:GetDescendants()) do if (obj:IsA("ScreenGui") or obj:IsA("BillboardGui") or obj:IsA("Highlight")) and not isProtectedGui(obj) then set[obj] = true end end end
    pcall(function() scan(game:GetService("CoreGui")) end)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then pcall(function() scan(pg) end) end
    return set
end

local function collectNewGuis(snapshot)
    local list = {}
    local function scan(parent) for _, obj in ipairs(parent:GetDescendants()) do if (obj:IsA("ScreenGui") or obj:IsA("BillboardGui") or obj:IsA("Highlight")) and not snapshot[obj] and not isProtectedGui(obj) and obj.Parent then table.insert(list, obj) end end end
    pcall(function() scan(game:GetService("CoreGui")) end)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then pcall(function() scan(pg) end) end
    return list
end

local function getWatchedSignals() return { RunService.Heartbeat, RunService.RenderStepped, RunService.Stepped, RunService.PreRender, RunService.PreSimulation, UserInputService.InputBegan, UserInputService.InputChanged, UserInputService.InputEnded, UserInputService.JumpRequest, UserInputService.TouchStarted, UserInputService.TouchEnded } end

local function snapshotConnections()
    if type(getconnections) ~= "function" then return nil end
    local set = {}
    for _, sig in ipairs(getWatchedSignals()) do
        local ok, conns = pcall(getconnections, sig)
        if ok and type(conns) == "table" then for _, conn in ipairs(conns) do local fn; pcall(function() fn = conn.Function end); if fn then set[fn] = true end end end
    end
    return set
end

local function killNewConnections(snapshot)
    if not snapshot or type(getconnections) ~= "function" then return end
    for _, sig in ipairs(getWatchedSignals()) do
        local ok, conns = pcall(getconnections, sig)
        if ok and type(conns) == "table" then
            for _, conn in ipairs(conns) do
                local fn; pcall(function() fn = conn.Function end)
                if fn and not snapshot[fn] then pcall(function() if conn.Disable then conn:Disable() end end); pcall(function() if conn.Disconnect then conn:Disconnect() end end) end
            end
        end
    end
end

local function killCheat(reason)
    if not CheatTracker.active then return end
    CheatTracker.killFlag = true
    for _, gui in ipairs(CheatTracker.guis) do pcall(function() if gui and gui.Parent then gui:Destroy() end end) end
    CheatTracker.guis = {}
    killNewConnections(CheatTracker.connSnap)
    CheatTracker.connSnap = nil
    CheatTracker.active = false; CheatTracker.killFlag = false; CheatTracker.currentName = nil
end

local function launchCheat(cheat)
    if STATE.busy then return end
    if not STATE.authed then showToast("Нужен ключ доступа", "warn"); return end
    if not cheat or not cheat.id or cheat.id == "" then showToast("Ошибка ID чита", "warn"); return end

    STATE.busy = true
    local guiSnap = snapshotGuis()
    local connSnap = snapshotConnections()

    CheatTracker.active = true; CheatTracker.killFlag = false; CheatTracker.guis = {}; CheatTracker.connSnap = connSnap; CheatTracker.currentName = cheat.name
    showToast("Загрузка: " .. cheat.name, "ok")

    task.spawn(function()
        local secureUrl = CONFIG.API_BASE .. "/secure_load?cheat_id=" .. cheat.id .. "&token=" .. tostring(STATE.token)
        
        local okFetch, source = pcall(function() return game:HttpGet(secureUrl) end)
        
        if not okFetch or type(source) ~= "string" or #source < 10 then 
            CheatTracker.active = false; CheatTracker.connSnap = nil; STATE.busy = false; 
            showToast("Чит на обновлении", "warn") 
            return 
        end

        local compiled
        if type(loadstring) == "function" then local okLs, fn = pcall(loadstring, source); if okLs then compiled = fn end end
        if not compiled then CheatTracker.active = false; CheatTracker.connSnap = nil; STATE.busy = false; showToast("Ошибка компиляции", "err"); return end

        mainGui.Enabled = false
        authGui.Enabled = false

        task.spawn(function()
            local okRun, err = pcall(compiled)
            if not okRun then showToast("Ошибка в " .. cheat.name .. ": " .. tostring(err):sub(1, 90), "err"); print("[RH-LAUNCHER] Cheat error: " .. tostring(err)); CheatTracker.active = false; mainGui.Enabled = true end
        end)

        task.spawn(function()
            local seen = {}
            local steps = math.floor(CONFIG.GUI_WATCH_S / CONFIG.GUI_WATCH_STEP)
            for _ = 1, steps do
                task.wait(CONFIG.GUI_WATCH_STEP)
                if CheatTracker.killFlag or not CheatTracker.active then return end
                local new = collectNewGuis(guiSnap)
                for _, gui in ipairs(new) do if not seen[gui] and gui.Parent then seen[gui] = true; table.insert(CheatTracker.guis, gui) end end
            end
        end)
        STATE.busy = false
    end)
end

-- ============================================================
-- TIMER
-- ============================================================
local function formatRemaining(sec)
    if sec == nil then return "∞" end
    sec = tonumber(sec)
    if not sec then return "--" end
    if sec <= 0 then return "истёк" end
    local d = math.floor(sec / 86400); local h = math.floor((sec % 86400) / 3600); local m = math.floor((sec % 3600) / 60); local s = math.floor(sec % 60)
    if d > 0 then return string.format("%dд %dч", d, h) end
    if h > 0 then return string.format("%dч %dм", h, m) end
    if m > 0 then return string.format("%dм %dс", m, s) end
    return string.format("%dс", s)
end

local function updateTimerLabel(remaining)
    if not timerLabel then return end
    timerLabel.Text = "⏱ " .. formatRemaining(remaining)
    if remaining == nil then timerLabel.TextColor3 = C.muted
    elseif remaining <= 60 then timerLabel.TextColor3 = C.red
    elseif remaining <= 300 then timerLabel.TextColor3 = C.yellow
    else timerLabel.TextColor3 = C.green end
end

-- ============================================================
-- RATINGS & LINK CHECK
-- ============================================================
local Ratings = { data = {}, loading = false, lastFetch = 0, cacheDuration = 30 }
local LinkStatus = {} 

local function checkLink(cheat)
    if LinkStatus[cheat.id] then return end
    LinkStatus[cheat.id] = "checking"
    
    task.spawn(function()
        local req = getRequestFn()
        if not req then LinkStatus[cheat.id] = "unknown"; return end
        
        local ok, res = pcall(function()
            return req({ Url = cheat.url, Method = "GET" })
        end)
        
        if ok and res then
            local status = tonumber(res.StatusCode or res.Status or 0) or 0
            if status >= 200 and status < 300 and type(res.Body) == "string" and #res.Body > 10 then
                LinkStatus[cheat.id] = "ok"
            else
                LinkStatus[cheat.id] = "dead"
            end
        else
            LinkStatus[cheat.id] = "dead"
        end
    end)
end

local function getRating(cheatId)
    local rating = Ratings.data[cheatId]
    if type(rating) ~= "table" then return { likes = 0, dislikes = 0, verified = false } end
    return { likes = tonumber(rating.likes) or 0, dislikes = tonumber(rating.dislikes) or 0, verified = rating.verified == true }
end

local function fetchRatings(force)
    if Ratings.loading then return false end
    if not STATE.authed or not STATE.token then return false end
    if not force and os.clock() - Ratings.lastFetch < Ratings.cacheDuration then return true end

    Ratings.loading = true
    local result, err = api("/get_ratings", nil, "GET")

    if result and result.success == true and type(result.ratings) == "table" then
        Ratings.data = result.ratings
        Ratings.lastFetch = os.clock()
        Ratings.loading = false
        return true
    end
    Ratings.loading = false
    warn("[RH-LAUNCHER] Ratings fetch failed: " .. tostring(err or "invalid response"))
    return false
end

local function submitVote(cheatId, voteType)
    if not STATE.authed or not STATE.token then showToast("Сначала авторизуйтесь", "warn"); return false end
    if type(cheatId) ~= "string" or cheatId == "" then showToast("Не указан ID чита", "err"); return false end
    if voteType ~= 1 and voteType ~= -1 then return false end

    local result, err = apiWithRetry("/vote", { token = STATE.token, cheat_id = cheatId, vote_type = voteType })
    if not result or result.success ~= true then showToast("Не удалось отправить голос: " .. tostring(err or "ошибка сервера"), "err"); return false end

    Ratings.data[cheatId] = { likes = tonumber(result.likes) or 0, dislikes = tonumber(result.dislikes) or 0, verified = result.verified == true }
    Ratings.lastFetch = os.clock()
    showToast(voteType == 1 and "Лайк засчитан!" or "Дизлайк засчитан!", "ok")
    return true
end

-- ============================================================
-- CARDS
-- ============================================================
local function makeCard(parent, title, subtitle, icon, onClick)
    local card = create("TextButton", { Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = C.surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true }, parent)
    corner(card, 12)
    stroke(card, C.accent, 1, 0.6)

    local iconFrame = create("Frame", { Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = C.surface2, BorderSizePixel = 0 }, card)
    corner(iconFrame, 10)
    stroke(iconFrame, C.border, 1, 0.5)
    
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = icon, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)

    create("TextLabel", { Position = UDim2.new(0, 74, 0, 14), Size = UDim2.new(1, -140, 0, 18), BackgroundTransparency = 1, Text = title, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)

    if subtitle and subtitle ~= "" then 
        create("TextLabel", { Position = UDim2.new(0, 74, 0, 34), Size = UDim2.new(1, -140, 0, 16), BackgroundTransparency = 1, Text = subtitle, TextColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, card) 
    end

    local arrowBtn = create("TextButton", { Position = UDim2.new(1, -44, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "›", TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 22, AutoButtonColor = false, Active = false }, card)
    corner(arrowBtn, 15)
    stroke(arrowBtn, C.accent, 1.5, 0.3)

    card.MouseButton1Down:Connect(function() TweenService:Create(card, TweenInfo.new(0.1), { Size = UDim2.new(0.97, 0, 0, 70), Position = UDim2.new(0.015, 0, 0, 2) }):Play() end)
    card.MouseButton1Up:Connect(function() TweenService:Create(card, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, 72), Position = UDim2.new(0, 0, 0, 0) }):Play() end)
    card.MouseLeave:Connect(function() TweenService:Create(card, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, 72), Position = UDim2.new(0, 0, 0, 0) }):Play() end)

    card.MouseButton1Click:Connect(function() 
        local ok, err = pcall(onClick); 
        if not ok then warn("[RH-LAUNCHER] Card click: " .. tostring(err)) end 
    end)
    
    return card
end

local function createCheatCard(parent, cheat, index)
    local rating = getRating(cheat.id)
    local status = LinkStatus[cheat.id] or "unknown"
    local isDead = (status == "dead")
    
    local card = create("Frame", { Name = "RatingCard_" .. cheat.id, Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = C.surface, BorderSizePixel = 0, LayoutOrder = index }, parent)
    corner(card, 10)
    stroke(card, isDead and C.border or ((rating.likes >= 4) and C.green or C.accent), 1, isDead and 0.8 or 0.5)

    local iconFrame = create("Frame", { Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = C.surface2, BorderSizePixel = 0 }, card)
    corner(iconFrame, 8)
    stroke(iconFrame, C.border, 1, 0.5)
    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = isDead and "🔄" or "⚡", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)

    local title = create("TextLabel", { Position = UDim2.new(0, 56, 0, 8), Size = UDim2.new(1, -150, 0, 16), BackgroundTransparency = 1, Text = cheat.name, TextColor3 = isDead and C.muted or C.text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
    
    local badgeText = "✓ ПРОВЕРЕН"
    if isDead then badgeText = "🔄 НА ОБНОВЛЕНИИ"
    elseif status == "checking" then badgeText = "⏳ ПРОВЕРКА..."
    else badgeText = "👍 " .. rating.likes .. "   👎 " .. rating.dislikes end

    local badge = create("TextLabel", { Name = "VerifiedBadge", Position = UDim2.new(0, 56, 0, 26), Size = UDim2.new(1, -150, 0, 14), BackgroundTransparency = 1, Text = badgeText, TextColor3 = isDead and C.muted or (status == "checking" and C.yellow or (rating.likes >= 4 and C.green or C.muted)), Font = Enum.Font.GothamBold, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Left }, card)
    
    local launchBtn = create("TextButton", { Position = UDim2.new(1, -85, 0, 8), Size = UDim2.fromOffset(75, 24), BackgroundColor3 = isDead and C.surface2 or C.accent, BorderSizePixel = 0, Text = isDead and "ОБНОВ." or "ЗАПУСТИТЬ", TextColor3 = isDead and C.muted or Color3.new(1, 1, 1), TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false }, card)
    corner(launchBtn, 6)
    
    if not isDead then
        stroke(launchBtn, C.accent, 1, 0.3)
    end

    launchBtn.MouseButton1Click:Connect(function() 
        if isDead then showToast("Чит скоро вернется после обновления", "warn")
        else launchCheat(cheat) end
    end)

    local likeBtn, dislikeBtn
    if not isDead then
        likeBtn = create("TextButton", { Position = UDim2.new(1, -85, 0, 36), Size = UDim2.fromOffset(33, 20), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "👍", TextColor3 = C.green, TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = true }, card)
        corner(likeBtn, 6)
        
        dislikeBtn = create("TextButton", { Position = UDim2.new(1, -48, 0, 36), Size = UDim2.fromOffset(33, 20), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "👎", TextColor3 = C.red, TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = true }, card)
        corner(dislikeBtn, 6)
    end

    local voting = false
    local function vote(voteType)
        if voting or isDead then return end
        voting = true
        if likeBtn then likeBtn.Active = false end
        if dislikeBtn then dislikeBtn.Active = false end
        
        task.spawn(function()
            local success = submitVote(cheat.id, voteType)
            if success and card.Parent then
                local updated = getRating(cheat.id)
                badge.Text = (updated.likes >= 4) and "✓ ПРОВЕРЕН" or ("👍 " .. updated.likes .. "   👎 " .. updated.dislikes)
                badge.TextColor3 = (updated.likes >= 4) and C.green or C.muted
                stroke(card, (updated.likes >= 4) and C.green or C.accent, 1, 0.5)
            end
            if likeBtn and likeBtn.Parent then likeBtn.Active = true end
            if dislikeBtn and dislikeBtn.Parent then dislikeBtn.Active = true end
            voting = false
        end)
    end
    
    if likeBtn then likeBtn.MouseButton1Click:Connect(function() vote(1) end) end
    if dislikeBtn then dislikeBtn.MouseButton1Click:Connect(function() vote(-1) end) end

    return card
end

-- ============================================================
-- SEARCH LOGIC & GAME LOADING
-- ============================================================
local showCheatsForGame -- Forward declaration

local function filterGames()
    local query = string.lower(searchBox.Text)
    for _, child in ipairs(gamesPage:GetChildren()) do
        if child:IsA("GuiObject") and child.Name == "GameCard" then
            local gameName = string.lower(child:GetAttribute("GameName") or "")
            if query == "" or string.find(gameName, query, 1, true) then
                child.Visible = true
            else
                child.Visible = false
            end
        end
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(filterGames)

local function loadGamesList()
    for _, child in ipairs(gamesPage:GetChildren()) do 
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") then 
            child:Destroy() 
        end 
    end

    local result, err = api("/get_scripts", nil, "GET")
    
    if not result or result.success ~= true or type(result.games) ~= "table" then
        local lbl = create("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = "Ошибка загрузки списка игр.\nПроверьте интернет.", TextColor3 = C.red, TextSize = 11, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, gamesPage)
        lbl.LayoutOrder = 1
        return
    end

    STATE.games = {}
    local index = 1

    for gameName, cheatsList in pairs(result.games) do
        local gameObj = {
            name = gameName,
            cheats = {}
        }
        for _, c in ipairs(cheatsList) do
            table.insert(gameObj.cheats, { id = c.id, name = c.name, url = c.url })
        end
        table.insert(STATE.games, gameObj)

        local count = #gameObj.cheats
        local subtitle = count .. " " .. (count == 1 and "чит" or "читов")
        
        local icon = GameIcons[gameName] or GameIcons.default
        local card = makeCard(gamesPage, gameName, subtitle, icon, function()
            showCheatsForGame(gameObj)
        end)
        card.Name = "GameCard"
        card:SetAttribute("GameName", gameName)
        card.LayoutOrder = index
        index = index + 1
    end

    if index == 1 then
        local lbl = create("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = "Пока нет доступных игр.\nДобавьте их через Telegram-бота.", TextColor3 = C.muted, TextSize = 11, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, gamesPage)
        lbl.LayoutOrder = 1
    end
end

showCheatsForGame = function(selectedGame)
    for _, child in ipairs(cheatsListFrame:GetChildren()) do if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end end
    cheatsTitleLbl.Text = "ЧИТЫ ДЛЯ " .. tostring(selectedGame.name):upper()

    if not selectedGame.cheats or #selectedGame.cheats == 0 then
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Читы пока не добавлены", TextColor3 = C.muted, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, cheatsListFrame)
        showPage("cheats")
        return
    end

    for i, cheat in ipairs(selectedGame.cheats) do 
        checkLink(cheat)
        createCheatCard(cheatsListFrame, cheat, i) 
    end
    showPage("cheats")

    task.spawn(function()
        task.wait(2)
        if not cheatsPage.Visible then return end
        for _, child in ipairs(cheatsListFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name:sub(1, 11) == "RatingCard_" then
                local cheatId = child.Name:sub(12)
                local status = LinkStatus[cheatId] or "unknown"
                local badge = child:FindFirstChild("VerifiedBadge")
                local launchBtn = nil
                for _, c in ipairs(child:GetChildren()) do if c:IsA("TextButton") and (c.Text == "ЗАПУСТИТЬ" or c.Text == "ОБНОВ.") then launchBtn = c break end end

                if status == "dead" and badge then
                    badge.Text = "🔄 НА ОБНОВЛЕНИИ"
                    badge.TextColor3 = C.muted
                    badge.Visible = true
                    if launchBtn then launchBtn.Text = "ОБНОВ."; launchBtn.BackgroundColor3 = C.surface2; launchBtn.TextColor3 = C.muted; launchBtn.Active = false end
                    stroke(child, C.border, 1, 0.8)
                elseif status == "ok" and badge then
                    local rating = getRating(cheatId)
                    badge.Text = (rating.likes >= 4) and "✓ ПРОВЕРЕН" or ("👍 " .. rating.likes .. "   👎 " .. rating.dislikes)
                    badge.TextColor3 = (rating.likes >= 4) and C.green or C.muted
                end
            end
        end
    end)
end

cheatsBackBtn.MouseButton1Click:Connect(function() showPage("games") end)

-- ============================================================
-- ON AUTH SUCCESS / KICK
-- ============================================================
onAuthSuccess = function(token)
    if CheatTracker.active then killCheat("re-auth") end
    STATE.authed = true; STATE.token = token
    if token then saveToken(token) end
    setStatus("Успешная авторизация!", "ok"); showToast("Добро пожаловать!", "ok")
    
    authGui.Enabled = false
    
    task.spawn(function()
        task.wait(0.6)
        if authMain and authMain.Parent then
            local tw = TweenService:Create(authMain, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
            tw:Play(); tw.Completed:Wait()
        end
        authMain.BackgroundTransparency = 0
        mainGui.Enabled = true
        showPage("games")

        loadGamesList()
        
        if STATE.localRemaining then
             updateTimerLabel(STATE.localRemaining)
        end

        task.spawn(function()
            local result = api("/verify", { token = token })
            if result and result.valid == true and result.remaining_seconds then STATE.localRemaining = tonumber(result.remaining_seconds); updateTimerLabel(STATE.localRemaining)
            else updateTimerLabel(nil) end
        end)
        task.spawn(function() fetchRatings(true) end)
    end)
end

local function kickToAuth(reason)
    killCheat(reason or "key expired")
    STATE.authed = false; STATE.token = nil; STATE.busy = false; STATE.localRemaining = nil
    clearToken(); updateTimerLabel(nil)
    if mainGui then mainGui.Enabled = false end
    authGui.Enabled = true
    if authFit then authFit() end
    authMain.BackgroundTransparency = 0; authKeyBox.Text = ""
    setBusy(false); setStatus(reason or "Сессия завершена — введите ключ", "warn")
    showToast(reason or "Нужен ключ доступа", "warn")
end

-- ============================================================
-- HEARTBEAT
-- ============================================================
task.spawn(function()
    task.wait(2)
    task.spawn(function()
        while true do
            if STATE.authed and STATE.localRemaining and STATE.localRemaining > 0 then
                STATE.localRemaining = STATE.localRemaining - 1; updateTimerLabel(STATE.localRemaining)
                if STATE.localRemaining <= 0 then kickToAuth("Ключ истёк") end
            end
            task.wait(1)
        end
    end)
    while true do
        if STATE.authed and STATE.token then
            local result, err = api("/verify", { token = STATE.token })
            if result and result.valid == true then STATE.localRemaining = tonumber(result.remaining_seconds); updateTimerLabel(STATE.localRemaining)
            elseif result and result.valid ~= true then kickToAuth("Ключ отозван")
            elseif not result then
                local low = tostring(err or ""):lower()
                if low:find("expired") or low:find("invalid") or low:find("403") then kickToAuth("Ключ недействителен") end
            end
        end
        task.wait(CONFIG.HEARTBEAT_S)
    end
end)

-- ============================================================
-- INITIAL TOKEN CHECK
-- ============================================================
task.spawn(function()
    task.wait(0.3)
    local saved = loadToken()
    if not saved then setStatus("Введите ключ доступа", nil); return end
    
    setStatus("Проверка сессии...", nil); setBusy(true)
    local valid, reason = verifySavedToken(saved)
    setBusy(false)
    if valid then 
        onAuthSuccess(saved)
    elseif reason == "expired" then 
        setStatus("Ключ истёк — введите новый", "warn")
    elseif reason == "invalid" then 
        clearToken()
        setStatus("Сессия недействительна", "warn")
    else 
        setStatus("Введите ключ доступа", nil) 
    end
end)

showPage("games")

print("----------------------------------------")
print("RH-LAUNCHER " .. CONFIG.VERSION)
print("UserId: " .. tostring(LocalPlayer.UserId))
print("----------------------------------------")