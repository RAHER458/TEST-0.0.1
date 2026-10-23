--[[
    RH-LAUNCHER — Standalone Roblox Launcher
    Version: 1.0.6 (Bugs & Optimizations)
    Platform: Roblox / Delta Executor / iOS
]]

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local ContentProvider  = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    VERSION        = "1.0.6",
    NAME           = "RH-LAUNCHER",
    API_BASE       = "https://raherauth.rh-launcher.workers.dev",
    TOKEN_FILE     = "RH_LAUNCHER_TOKEN.dat",
    DEVICE_FILE    = "RH_LAUNCHER_DEVICE.dat",
    FAV_FILE       = "RH_LAUNCHER_FAVS.dat",
    TG_LINK        = "https://t.me/rh_launcher_scripts",
    WINDOW_W       = 480,
    WINDOW_H       = 460,
    RETRY_MAX      = 3,
    RETRY_DELAY    = 1.5,
    HEARTBEAT_S    = 300,
    GUI_WATCH_S    = 5,
    GUI_WATCH_STEP = 0.5,
    LOGO_IMAGE_ID  = "101226271656911",
    BACKGROUND_ID  = "120280268407455"
}

local C = {
    bg       = Color3.fromRGB(8, 12, 30),
    surface  = Color3.fromRGB(18, 22, 35),
    surface2 = Color3.fromRGB(25, 30, 48),
    surface3 = Color3.fromRGB(35, 42, 65),
    input    = Color3.fromRGB(12, 20, 50),
    border   = Color3.fromRGB(45, 55, 85),
    text     = Color3.fromRGB(255, 255, 255),
    muted    = Color3.fromRGB(160, 180, 220),
    accent   = Color3.fromRGB(0, 80, 255),
    cyan     = Color3.fromRGB(0, 220, 255),
    pink     = Color3.fromRGB(200, 50, 255),
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

local activeConnections = {}
local isRunning = false

local function addConnection(conn) table.insert(activeConnections, conn) end

local function disconnectAll()
    for _, conn in ipairs(activeConnections) do pcall(function() conn:Disconnect() end) end
    activeConnections = {}
end

local function clearAllGuis()
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
end

local STATE = { 
    authed = false, token = nil, deviceId = nil, busy = false, games = {}, localRemaining = nil, 
    favorites = {}, currentPage = "games", lastNonCheatPage = "games", gameImages = {},
    activatedAt = nil, gamesLoaded = false, gamesLoading = false
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(parent, radius) return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent) end
local function stroke(parent, color, thickness, transparency) return create("UIStroke", { Color = color or C.border, Thickness = thickness or 1, Transparency = transparency or 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent) end
local function gradient(parent, color1, color2, rotation) return create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2) }), Rotation = rotation or 0 }, parent) end

local function safeParent(guiObj)
    local ok = pcall(function() guiObj.Parent = game:GetService("CoreGui") end)
    if not ok or not guiObj.Parent then guiObj.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

local function makeDraggable(frame, dragArea)
    local dragging, dragInput, dragStart, startPos, moved
    local c1, c2
    c1 = dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragInput = input; dragStart = input.Position; startPos = frame.Position; moved = false
            addConnection(input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end))
        end
    end)
    c2 = dragArea.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then moved = true end
            if moved then
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    addConnection(c1)
    addConnection(c2)
end

local function hasFileAPI() return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function" end

local function loadFavorites()
    if hasFileAPI() and isfile(CONFIG.FAV_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG.FAV_FILE)) end)
        if ok and type(data) == "table" then STATE.favorites = data end
    end
end
loadFavorites()

local function saveFavorites() if hasFileAPI() then pcall(writefile, CONFIG.FAV_FILE, HttpService:JSONEncode(STATE.favorites)) end end

local function toggleFavorite(gameName)
    STATE.favorites[gameName] = not STATE.favorites[gameName]
    if STATE.favorites[gameName] == false then STATE.favorites[gameName] = nil end
    saveFavorites()
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
        local low = string.lower(tostring(err or ""))
        if string.find(low, "таймаут") or string.find(low, "timeout") then
            if attempt < CONFIG.RETRY_MAX then task.wait(CONFIG.RETRY_DELAY) end
        else return nil, err, attempt end
    end
    return nil, lastErr, CONFIG.RETRY_MAX
end

local function verifySavedToken(token)
    if type(token) ~= "string" or token == "" then return false, "no_token" end
    local result, err = api("/verify", { token = token })
    if not result then
        local low = string.lower(tostring(err or ""))
        if string.find(low, "expired") then clearToken(); return false, "expired" end
        return false, "request_failed"
    end
    if result.valid ~= true then return false, "invalid" end
    return true, "ok"
end

local startLauncher
local onAuthSuccess

startLauncher = function()
    if isRunning then return end
    isRunning = true
    clearAllGuis()
    STATE.busy = false
    
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

    local authScreen = create("ScreenGui", { Name = "RH_LAUNCHER_AUTH_GUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 99999, Enabled = true })
    safeParent(authScreen)

    local AuthPanel = create("Frame", { Name = "AuthPanel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.60), BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true }, authScreen)
    corner(AuthPanel, 14)

    local BackgroundArea = create("Frame", { Name = "BackgroundArea", Size = UDim2.fromScale(0.60, 1), Position = UDim2.fromScale(0, 0), BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true }, AuthPanel)
    local Background = create("ImageLabel", { Name = "BackgroundImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://" .. CONFIG.BACKGROUND_ID, ScaleType = Enum.ScaleType.Crop }, BackgroundArea)

    local Card = create("Frame", { Name = "LoginCard", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.98, 0.5), Size = UDim2.fromScale(0.38, 0.96), BackgroundColor3 = C.bg, BorderSizePixel = 0 }, AuthPanel)
    corner(Card, 19)

    local BorderFrame = create("Frame", { Name = "OuterBorder", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Card)
    corner(BorderFrame, 19)
    local BorderStroke = create("UIStroke", { Color = C.accent, Thickness = 2, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, BorderFrame)
    gradient(BorderStroke, C.cyan, C.pink, 0)

    local Content = create("Frame", { Name = "Content", Position = UDim2.fromScale(0.065, 0.05), Size = UDim2.fromScale(0.87, 0.90), BackgroundTransparency = 1 }, Card)

    local function makeText(parent, name, text, position, size, font, color, minSize, maxSize)
        local label = create("TextLabel", { Name = name, Position = position, Size = size, BackgroundTransparency = 1, Text = text, TextColor3 = color or C.text, Font = font or Enum.Font.Gotham, TextScaled = true, TextWrapped = true }, parent)
        create("UITextSizeConstraint", { MinTextSize = minSize or 8, MaxTextSize = maxSize or 20 }, label)
        return label
    end

    local Welcome = makeText(Content, "Welcome", "Добро пожаловать!", UDim2.fromScale(0, 0.13), UDim2.fromScale(1, 0.115), Enum.Font.GothamBold, C.text, 10, 22)
    Welcome.TextXAlignment = Enum.TextXAlignment.Left
    local Subtitle = makeText(Content, "Subtitle", "Войдите в свой аккаунт RH-LAUNCHER", UDim2.fromScale(0, 0.255), UDim2.fromScale(1, 0.075), Enum.Font.Gotham, C.muted, 8, 14)
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local InputFrame = create("Frame", { Name = "KeyInputFrame", Position = UDim2.fromScale(0, 0.375), Size = UDim2.fromScale(1, 0.135), BackgroundColor3 = C.input }, Content)
    corner(InputFrame, 10)
    local InputStroke = create("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, InputFrame)
    gradient(InputStroke, C.cyan, C.pink, 0)

    local keyIcon = create("TextLabel", { Position = UDim2.fromScale(0.03, 0), Size = UDim2.fromScale(0.08, 1), BackgroundTransparency = 1, Text = "🔑", TextColor3 = C.cyan, Font = Enum.Font.Gotham, TextScaled = true }, InputFrame)
    create("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 16 }, keyIcon)

    local KeyBox = create("TextBox", { Name = "KeyInput", Position = UDim2.fromScale(0.12, 0.08), Size = UDim2.fromScale(0.82, 0.84), BackgroundTransparency = 1, Text = "", PlaceholderText = "Введите ключ...", PlaceholderColor3 = C.muted, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Code, TextScaled = true, ClearTextOnFocus = false }, InputFrame)
    create("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 16 }, KeyBox)

    local Notice = makeText(Content, "Notice", "", UDim2.fromScale(0, 0.52), UDim2.fromScale(1, 0.055), Enum.Font.Gotham, C.cyan, 8, 12)

    local noticeCounter = 0
    local function notify(message, color)
        noticeCounter += 1
        local currentCounter = noticeCounter
        Notice.Text = message
        Notice.TextColor3 = color or C.cyan
        Notice.TextTransparency = 0
        task.delay(2.5, function() if Notice.Parent and noticeCounter == currentCounter then TweenService:Create(Notice, TweenInfo.new(0.2), {TextTransparency = 1}):Play() end end)
    end

    local function makeButton(parent, name, caption, position, size, outlined, callback)
        local button = create("TextButton", { Name = name, Position = position, Size = size, BackgroundColor3 = C.bg, BackgroundTransparency = 0.2, BorderSizePixel = 0, AutoButtonColor = false, Text = caption, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextScaled = true }, parent)
        corner(button, 10)
        if outlined then
            local outline = create("UIStroke", { Color = C.accent, Thickness = 1.5, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
            gradient(outline, C.cyan, C.pink, 0)
        else
            local outline = create("UIStroke", { Color = C.accent, Thickness = 2, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
            gradient(outline, C.cyan, C.pink, 45)
        end
        create("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 16 }, button)
        button.Activated:Connect(callback)
        return button
    end

    local isBusy = false
    local savedSessionToken = nil
    local LoginBtn
    LoginBtn = makeButton(Content, "LoginButton", "Войти", UDim2.fromScale(0, 0.58), UDim2.fromScale(1, 0.12), false, function()
        if isBusy then return end
        if savedSessionToken then
            isBusy = true
            LoginBtn.Text = "Проверка сессии..."
            LoginBtn.TextColor3 = C.muted
            notify("Проверяем сохранённую сессию...", C.accent)
            task.spawn(function()
                local valid = verifySavedToken(savedSessionToken)
                if valid then
                    local token = savedSessionToken
                    authScreen:Destroy()
                    onAuthSuccess(token)
                else
                    savedSessionToken = nil
                    isBusy = false
                    LoginBtn.Text = "Войти"
                    LoginBtn.TextColor3 = C.text
                    Notice.Text = "Сессия истекла. Введите ключ заново."
                    Notice.TextColor3 = C.red
                    KeyBox.Text = ""
                    notify("Сессия недействительна — введите ключ", C.red)
                end
            end)
            return
        end
        local key = KeyBox.Text:gsub("%s+", "")
        if key == "" then notify("Введите ключ доступа", C.red); return end
        isBusy = true
        LoginBtn.Text = "Проверка..."
        LoginBtn.TextColor3 = C.muted
        notify("Соединение с сервером...", C.accent)
        task.spawn(function()
            if type(STATE.deviceId) ~= "string" or STATE.deviceId == "" then STATE.deviceId = generateDeviceId() end
            local body = { key = key, install_hash = STATE.deviceId, roblox_name = LocalPlayer.Name }
            local result, err, attempts = apiWithRetry("/activate", body)
            if not result then
                isBusy = false
                LoginBtn.Text = "Войти"
                LoginBtn.TextColor3 = C.text
                local msg = tostring(err or "неизвестная ошибка")
                local low = string.lower(msg)
                if string.find(low, "invalid license") then notify("❌ Неверный ключ", C.red)
                elseif string.find(low, "bound to another") then notify("❌ Ключ привязан к другому устройству", C.red)
                elseif string.find(low, "expired") then notify("❌ Ключ истёк", C.red)
                elseif string.find(low, "таймаут") or string.find(low, "timeout") then notify("❌ Сервер не отвечает", C.red)
                else notify("❌ " .. msg, C.red) end
                return
            end
            if type(result.token) ~= "string" or result.token == "" then isBusy = false; LoginBtn.Text = "Войти"; LoginBtn.TextColor3 = C.text; notify("❌ Сервер не выдал токен", C.red); return end
            
            if result.remaining_seconds then STATE.localRemaining = tonumber(result.remaining_seconds) end
            if result.activated_at then 
                STATE.activatedAt = result.activated_at 
            else
                STATE.activatedAt = os.date("%d.%m.%Y %H:%M")
            end
            
            isBusy = false
            notify("Успешный вход!", C.green)
            LoginBtn.Text = "Успех"
            LoginBtn.TextColor3 = C.green
            task.wait(0.5)
            authScreen:Destroy()
            onAuthSuccess(result.token)
        end)
    end)

    local divFrame = create("Frame", { Position = UDim2.fromScale(0, 0.73), Size = UDim2.fromScale(1, 0.065), BackgroundTransparency = 1 }, Content)
    create("Frame", { Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(0.35, 0), BackgroundColor3 = C.muted, BackgroundTransparency = 0.6 }, divFrame)
    create("Frame", { Position = UDim2.fromScale(0.65, 0.5), Size = UDim2.fromScale(0.35, 0), BackgroundColor3 = C.muted, BackgroundTransparency = 0.6 }, divFrame)
    local divText = makeText(divFrame, "DivText", "Нет ключа?", UDim2.fromScale(0.35, 0), UDim2.fromScale(0.3, 1), Enum.Font.Gotham, C.muted, 8, 12)
    divText.TextXAlignment = Enum.TextXAlignment.Center

    makeButton(Content, "GetKeyButton", "Получить ключ", UDim2.fromScale(0, 0.825), UDim2.fromScale(1, 0.12), true, function()
        local link = CONFIG.TG_LINK
        local copied = false
        if type(setclipboard) == "function" then copied = pcall(setclipboard, link)
        elseif type(toclipboard) == "function" then copied = pcall(toclipboard, link) end
        if copied then notify("Ссылка скопирована!", C.green)
        else notify("t.me/rh_launcher_scripts", C.cyan) end
    end)

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
    if workspace.CurrentCamera then addConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitMain)) end

    local showPage
    local showCheatsForGame
    local loadFavoritesPage

    local sidebar = create("Frame", { Size = UDim2.new(0, 110, 1, 0), BackgroundColor3 = C.bg, BorderSizePixel = 0, ZIndex = 5, ClipsDescendants = true }, main)
    corner(sidebar, 16)

    local sideGradFrame = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.accent, BackgroundTransparency = 0.9, BorderSizePixel = 0 }, sidebar)
    corner(sideGradFrame, 16)
    create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.bg), ColorSequenceKeypoint.new(1, C.surface)}, Rotation = 90 }, sideGradFrame)

    local logoFrame = create("Frame", { Position = UDim2.new(0.5, 0, 0, 20), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = C.surface2, BorderSizePixel = 0, ClipsDescendants = true }, sidebar)
    corner(logoFrame, 25)
    stroke(logoFrame, C.accent, 1.5, 0.2)

    if CONFIG.LOGO_IMAGE_ID and CONFIG.LOGO_IMAGE_ID ~= "" then
        local logoImg = create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(CONFIG.LOGO_IMAGE_ID), ScaleType = Enum.ScaleType.Crop }, logoFrame)
        corner(logoImg, 25)
        local failed = false
        addConnection(logoImg.Changed:Connect(function(prop)
            if (prop == "IsLoaded" and not logoImg.IsLoaded) or prop == "Image" then
                if not failed and (not logoImg.IsLoaded or logoImg.Image == "") then
                    failed = true; logoImg:Destroy()
                    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "RH", TextColor3 = C.pink, Font = Enum.Font.GothamBlack, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, logoFrame)
                end
            end
        end))
    else
        create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "RH", TextColor3 = C.pink, Font = Enum.Font.GothamBlack, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, logoFrame)
    end

    local navButtons = {}
    local function createNavButton(icon, text, order, pageName)
        local btn = create("TextButton", { Size = UDim2.new(1, -10, 0, 40), Position = UDim2.new(0, 5, 0, 90 + (order * 45)), BackgroundColor3 = C.surface2, BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false }, sidebar)
        corner(btn, 8)
        local bgHighlight = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.accent, BackgroundTransparency = 1, BorderSizePixel = 0 }, btn)
        corner(bgHighlight, 8)
        local iconLabel = create("TextLabel", { Size = UDim2.fromOffset(24, 24), Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Text = icon, TextColor3 = C.muted, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, btn)
        local textLabel = create("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 38, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.muted, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, btn)
        navButtons[pageName] = { btn = btn, iconLabel = iconLabel, textLabel = textLabel, bg = bgHighlight }
        addConnection(btn.MouseButton1Click:Connect(function()
            for pName, data in pairs(navButtons) do
                data.iconLabel.TextColor3 = C.muted
                data.textLabel.TextColor3 = C.muted
                TweenService:Create(data.bg, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            end
            iconLabel.TextColor3 = C.accent
            textLabel.TextColor3 = C.accent
            TweenService:Create(bgHighlight, TweenInfo.new(0.2), { BackgroundTransparency = 0.8 }):Play()
            showPage(pageName)
        end))
        return btn
    end

    createNavButton("🏠", "Главная", 0, "games")
    createNavButton("⭐", "Избранное", 1, "favorites")
    createNavButton("⚙️", "Настройки", 2, "settings")
    createNavButton("👤", "Профиль", 3, "profile")

    local statusFrame = create("Frame", { Position = UDim2.new(0, 5, 1, -65), Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = C.surface2, BackgroundTransparency = 0.5, BorderSizePixel = 0 }, sidebar)
    corner(statusFrame, 8)
    local statusDot = create("Frame", { Position = UDim2.new(0, 8, 0, 10), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.yellow, BorderSizePixel = 0 }, statusFrame)
    corner(statusDot, 4)
    local statusLabel = create("TextLabel", { Position = UDim2.new(0, 20, 0, 6), Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, Text = "Статус", TextColor3 = C.muted, TextSize = 8, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left }, statusFrame)
    local statusText = create("TextLabel", { Position = UDim2.new(0, 20, 0, 18), Size = UDim2.new(1, -20, 0, 14), BackgroundTransparency = 1, Text = "Загрузка...", TextColor3 = C.yellow, TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left }, statusFrame)
    local versionLabel = create("TextLabel", { Position = UDim2.new(0, 8, 0, 34), Size = UDim2.new(1, -16, 0, 10), BackgroundTransparency = 1, Text = "v" .. CONFIG.VERSION, TextColor3 = C.muted, TextSize = 7, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left }, statusFrame)

    local function setLoaderStatus(text, color)
        statusText.Text = text
        statusText.TextColor3 = color
        statusDot.BackgroundColor3 = color
    end

    local divider = create("Frame", { Position = UDim2.new(0, 110, 0, 8), Size = UDim2.new(0, 2, 1, -16), BackgroundColor3 = C.accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 6 }, main)
    corner(divider, 1)

    local contentArea = create("Frame", { Position = UDim2.new(0, 110, 0, 0), Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1 }, main)
    local rightBg = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 1 }, contentArea)
    corner(rightBg, 16)
    stroke(rightBg, C.border, 1, 0.8)
    local rightGradFrame = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.accent, BackgroundTransparency = 0.8, BorderSizePixel = 0 }, rightBg)
    corner(rightGradFrame, 16)
    create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.surface2), ColorSequenceKeypoint.new(1, C.accent)}, Rotation = 90 }, rightGradFrame)

    local banner = create("Frame", { Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 0, 64), BackgroundColor3 = C.surface2, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3 }, contentArea)
    corner(banner, 10)
    stroke(banner, C.accent, 1, 0.3)
    
    local bannerGradFrame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.accent, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 1 }, banner)
    corner(bannerGradFrame, 10)
    create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.surface2), ColorSequenceKeypoint.new(1, C.accent)}, Rotation = 45 }, bannerGradFrame)

    create("TextLabel", { Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -64, 0, 24), BackgroundTransparency = 1, Text = "RH-LAUNCHER", TextColor3 = C.text, Font = Enum.Font.GothamBlack, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, banner)
    create("TextLabel", { Position = UDim2.new(0, 16, 0, 36), Size = UDim2.new(1, -64, 0, 14), BackgroundTransparency = 1, Text = "Быстрый • Удобный", TextColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, banner)

    local closeBtn = create("TextButton", { Position = UDim2.new(1, -34, 0, 16), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = C.surface3, BorderSizePixel = 0, Text = "✖", TextColor3 = C.red, TextSize = 14, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 3 }, banner)
    corner(closeBtn, 6)
    stroke(closeBtn, C.red, 1, 0.5)

    addConnection(closeBtn.MouseButton1Click:Connect(function()
        isRunning = false
        disconnectAll()
        clearAllGuis()
        showToast("Лаунчер закрыт. Перезапустите скрипт.", "warn")
        task.wait(3)
        if toastGui then toastGui:Destroy() end
    end))

    makeDraggable(main, banner)

    local searchFrame = create("Frame", { Position = UDim2.new(0, 8, 0, 80), Size = UDim2.new(1, -16, 0, 36), BackgroundColor3 = C.input, BorderSizePixel = 0, ZIndex = 3 }, contentArea)
    corner(searchFrame, 8)
    stroke(searchFrame, C.border, 1, 0.5)
    create("TextLabel", { Position = UDim2.new(0, 10, 0, 0), Size = UDim2.fromOffset(20, 36), BackgroundTransparency = 1, Text = "🔍", TextColor3 = C.muted, TextSize = 14, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, searchFrame)
    local searchBox = create("TextBox", { Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Поиск игр...", PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, searchFrame)

    local content = create("Frame", { Position = UDim2.new(0, 8, 0, 124), Size = UDim2.new(1, -16, 1, -132), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 }, contentArea)

    local function makePage(parent, name)
        local page = create("ScrollingFrame", { Name = name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, parent)
        create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 4) }, page)
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, page)
        return page
    end

    local gamesPage = makePage(content, "GamesPage")
    local cheatsPage = makePage(content, "CheatsPage")
    local favoritesPage = makePage(content, "FavoritesPage")
    local settingsPage = makePage(content, "SettingsPage")
    local profilePage = makePage(content, "ProfilePage")

    create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "⚙️", TextColor3 = C.muted, TextSize = 28, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, settingsPage)
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "Настройки в разработке", TextColor3 = C.muted, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, settingsPage)

    local cheatsBackBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "←  НАЗАД К ИГРАМ", TextColor3 = C.text, TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = true, LayoutOrder = -2 }, cheatsPage)
    corner(cheatsBackBtn, 8)
    local cheatsTitleLbl = create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "", TextColor3 = C.accent, TextSize = 10, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -1 }, cheatsPage)

    local profileFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 300), BackgroundColor3 = C.surface, BorderSizePixel = 0, ClipsDescendants = true }, profilePage)
    corner(profileFrame, 12)
    stroke(profileFrame, C.accent, 1, 0.4)
    profileFrame.LayoutOrder = 1
    
    local profileGradFrame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.accent, BackgroundTransparency = 0.85, BorderSizePixel = 0 }, profileFrame)
    corner(profileGradFrame, 12)
    create("UIGradient", { Color = ColorSequence.new{ColorSequenceKeypoint.new(0, C.surface2), ColorSequenceKeypoint.new(1, C.pink)}, Rotation = 90 }, profileGradFrame)

    local profileContent = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, profileFrame)
    
    local avatarFrame = create("Frame", { Position = UDim2.new(0.5, 0, 0, 20), AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(80, 80), BackgroundColor3 = C.surface2, BorderSizePixel = 0 }, profileContent)
    corner(avatarFrame, 40)
    stroke(avatarFrame, C.accent, 2, 0)

    local userId = LocalPlayer.UserId
    local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. tostring(userId) .. "&width=150&height=150&format=png"
    local avatarImg = create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = avatarUrl, ScaleType = Enum.ScaleType.Crop }, avatarFrame)
    corner(avatarImg, 40)
    local fallbackLetter = create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.sub(LocalPlayer.Name, 1, 1):upper(), TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 36, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Visible = false }, avatarFrame)

    addConnection(avatarImg.Changed:Connect(function(prop)
        if prop == "IsLoaded" or prop == "Image" then
            if avatarImg.IsLoaded == false or avatarImg.Image == "" then avatarImg.Visible = false; fallbackLetter.Visible = true
            else avatarImg.Visible = true; fallbackLetter.Visible = false end
        end
    end))

    local nameLbl = create("TextLabel", { Position = UDim2.new(0, 0, 0, 110), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = LocalPlayer.Name, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center }, profileContent)
    create("TextLabel", { Position = UDim2.new(0, 0, 0, 136), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "ID: " .. tostring(userId), TextColor3 = C.muted, Font = Enum.Font.GothamMedium, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center }, profileContent)

    local keyStatusFrame = create("Frame", { Position = UDim2.new(0, 16, 0, 170), Size = UDim2.new(1, -32, 0, 65), BackgroundColor3 = C.surface2, BorderSizePixel = 0, BackgroundTransparency = 0.3 }, profileContent)
    corner(keyStatusFrame, 8)
    stroke(keyStatusFrame, C.border, 1, 0.5)

    create("TextLabel", { Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 14), BackgroundTransparency = 1, Text = "ВАШ КЛЮЧ ДОСТУПА", TextColor3 = C.muted, Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left }, keyStatusFrame)
    local profileKeyLbl = create("TextLabel", { Position = UDim2.new(0, 12, 0, 22), Size = UDim2.new(1, -24, 0, 18), BackgroundTransparency = 1, Text = "Загрузка...", TextColor3 = C.green, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, keyStatusFrame)
    
    local activatedLbl = create("TextLabel", { Position = UDim2.new(0, 12, 0, 44), Size = UDim2.new(1, -24, 0, 14), BackgroundTransparency = 1, Text = "Активирован: --", TextColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left }, keyStatusFrame)

    local renewBtn = create("TextButton", { Position = UDim2.new(0, 16, 0, 245), Size = UDim2.new(1, -32, 0, 40), BackgroundColor3 = C.accent, BorderSizePixel = 0, Text = "💳 ПРОДЛИТЬ КЛЮЧ", TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = false }, profileContent)
    corner(renewBtn, 8)

    addConnection(renewBtn.MouseButton1Click:Connect(function()
        local copied = false
        if type(setclipboard) == "function" then copied = pcall(setclipboard, CONFIG.TG_LINK)
        elseif type(toclipboard) == "function" then copied = pcall(toclipboard, CONFIG.TG_LINK) end
        if copied then showToast("Ссылка на продление скопирована!", "ok")
        else showToast("Ссылка: " .. CONFIG.TG_LINK, "warn") end
    end))

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
            authScreen.Enabled = false

            task.spawn(function()
                local okRun, err = pcall(compiled)
                if not okRun then showToast("Ошибка в " .. cheat.name .. ": " .. tostring(err):sub(1, 90), "err"); CheatTracker.active = false; mainGui.Enabled = true end
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

    local function formatRemaining(sec)
        if sec == nil then return "∞ Бесконечный" end
        sec = tonumber(sec)
        if not sec then return "--" end
        if sec <= 0 then return "Истёк" end
        local d = math.floor(sec / 86400); local h = math.floor((sec % 86400) / 3600); local m = math.floor((sec % 3600) / 60); local s = math.floor(sec % 60)
        if d > 0 then return string.format("%dд %dч %dм", d, h, m) end
        if h > 0 then return string.format("%dч %dм", h, m) end
        if m > 0 then return string.format("%dм %dс", m, s) end
        return string.format("%dс", s)
    end

    local function updateTimerLabel(remaining)
        if profileKeyLbl then
            local timeStr = formatRemaining(remaining)
            profileKeyLbl.Text = remaining and ("Осталось: " .. timeStr) or "Навсегда (∞)"
            if remaining == nil then profileKeyLbl.TextColor3 = C.green
            elseif remaining <= 60 then profileKeyLbl.TextColor3 = C.red
            elseif remaining <= 300 then profileKeyLbl.TextColor3 = C.yellow
            else profileKeyLbl.TextColor3 = C.green end
        end
    end

    local Ratings = { data = {}, loading = false, lastFetch = 0, cacheDuration = 30 }
    local LinkStatus = {} 

    local function checkLink(cheat)
        if LinkStatus[cheat.id] then return end
        LinkStatus[cheat.id] = "checking"
        
        task.spawn(function()
            local req = getRequestFn()
            if not req then LinkStatus[cheat.id] = "unknown"; return end
            
            local ok, res = pcall(function() return req({ Url = cheat.url, Method = "GET" }) end)
            
            if ok and res then
                local status = tonumber(res.StatusCode or res.Status or 0) or 0
                if status >= 200 and status < 300 and type(res.Body) == "string" and #res.Body > 10 then LinkStatus[cheat.id] = "ok"
                else LinkStatus[cheat.id] = "dead" end
            else LinkStatus[cheat.id] = "dead" end
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

    local function updateStarVisuals(gameName)
        local isFav = STATE.favorites[gameName] == true
        local text = isFav and "⭐" or "☆"
        local color = isFav and C.yellow or C.muted
        
        for _, page in ipairs({gamesPage, favoritesPage}) do
            for _, child in ipairs(page:GetChildren()) do
                if child:IsA("TextButton") and child:GetAttribute("GameName") == gameName then
                    local starBtn = child:FindFirstChild("StarButton")
                    if starBtn then
                        local star = starBtn:FindFirstChild("StarIcon")
                        if star then star.Text = text; star.TextColor3 = color end
                    end
                end
            end
        end
    end

    local function makeCard(parent, title, subtitle, icon, imageId, onClick)
        local card = create("TextButton", { Size = UDim2.new(1, 0, 0, 78), BackgroundColor3 = C.surface, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ClipsDescendants = true }, parent)
        corner(card, 10)
        stroke(card, C.accent, 1, 0.6)

        local iconFrame = create("Frame", { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.surface2, BorderSizePixel = 0, ClipsDescendants = true }, card)
        corner(iconFrame, 10)
        
        if imageId and imageId ~= "" then
            local img = create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(imageId), ScaleType = Enum.ScaleType.Stretch }, iconFrame)
            
            local failed = false
            addConnection(img.Changed:Connect(function(prop)
                if (prop == "IsLoaded" and not img.IsLoaded) or prop == "Image" then
                    if not failed and (not img.IsLoaded or img.Image == "") then
                        failed = true
                        img:Destroy()
                        create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = icon, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)
                    end
                end
            end))
            task.delay(7, function()
                if not failed and img.Parent and img.IsLoaded == false then
                    failed = true
                    img:Destroy()
                    create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = icon, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)
                end
            end)
        else
            create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = icon, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)
        end

        create("TextLabel", { Position = UDim2.new(0, 112, 0, 18), Size = UDim2.new(1, -200, 0, 20), BackgroundTransparency = 1, Text = title, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)

        if subtitle and subtitle ~= "" then 
            create("TextLabel", { Position = UDim2.new(0, 112, 0, 40), Size = UDim2.new(1, -200, 0, 16), BackgroundTransparency = 1, Text = subtitle, TextColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, card) 
        end

        local starBtn = create("TextButton", { Name = "StarButton", Position = UDim2.new(1, -70, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 }, card)
        local isFav = STATE.favorites[title] == true
        local starLbl = create("TextLabel", { Name = "StarIcon", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = isFav and "⭐" or "☆", TextColor3 = isFav and C.yellow or C.muted, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, starBtn)
        
        addConnection(starBtn.MouseButton1Click:Connect(function()
            toggleFavorite(title)
            local nowFav = STATE.favorites[title] == true
            starLbl.Text = nowFav and "⭐" or "☆"
            starLbl.TextColor3 = nowFav and C.yellow or C.muted
            if nowFav then showToast("Добавлено в избранное", "ok") else showToast("Удалено из избранного", "warn") end
            updateStarVisuals(title)
            if favoritesPage.Visible then loadFavoritesPage() end
        end))

        local arrowBtn = create("TextButton", { Position = UDim2.new(1, -38, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "›", TextColor3 = C.accent, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false, Active = false }, card)
        corner(arrowBtn, 13)
        stroke(arrowBtn, C.accent, 1.5, 0.3)

        addConnection(card.MouseButton1Click:Connect(function() 
            local ok, err = pcall(onClick); 
            if not ok then warn("[RH-LAUNCHER] Card click: " .. tostring(err)) end 
        end))
        
        return card
    end

    local function createCheatCard(parent, cheat, index)
        local rating = getRating(cheat.id)
        local status = LinkStatus[cheat.id] or "unknown"
        local isDead = (status == "dead")
        
        local card = create("Frame", { Name = "RatingCard_" .. cheat.id, Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = C.surface, BorderSizePixel = 0, LayoutOrder = index, ClipsDescendants = true }, parent)
        corner(card, 10)
        stroke(card, isDead and C.border or ((rating.likes >= 4) and C.green or C.accent), 1, isDead and 0.8 or 0.5)

        local iconFrame = create("Frame", { Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 72, 1, 0), BackgroundColor3 = C.surface2, BorderSizePixel = 0, ClipsDescendants = true }, card)
        corner(iconFrame, 10)
        
        if cheat.image_id and cheat.image_id ~= "" then
            local img = create("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(cheat.image_id), ScaleType = Enum.ScaleType.Stretch }, iconFrame)
            local failed = false
            addConnection(img.Changed:Connect(function(prop)
                if (prop == "IsLoaded" and not img.IsLoaded) or prop == "Image" then
                    if not failed and (not img.IsLoaded or img.Image == "") then
                        failed = true; img:Destroy()
                        create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = isDead and "🔄" or "⚡", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)
                    end
                end
            end))
        else
            create("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = isDead and "🔄" or "⚡", TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, iconFrame)
        end

        local title = create("TextLabel", { Position = UDim2.new(0, 84, 0, 14), Size = UDim2.new(1, -180, 0, 18), BackgroundTransparency = 1, Text = cheat.name, TextColor3 = isDead and C.muted or C.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
        
        local badgeText = "✓ ПРОВЕРЕН"
        if isDead then badgeText = "🔄 НА ОБНОВЛЕНИИ"
        elseif status == "checking" then badgeText = "⏳ ПРОВЕРКА..."
        else badgeText = "👍 " .. rating.likes .. "   👎 " .. rating.dislikes end

        local badge = create("TextLabel", { Name = "VerifiedBadge", Position = UDim2.new(0, 84, 0, 36), Size = UDim2.new(1, -180, 0, 16), BackgroundTransparency = 1, Text = badgeText, TextColor3 = isDead and C.muted or (status == "checking" and C.yellow or (rating.likes >= 4 and C.green or C.muted)), Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left }, card)
        
        local launchBtn = create("TextButton", { Position = UDim2.new(1, -90, 0, 10), Size = UDim2.fromOffset(80, 26), BackgroundColor3 = isDead and C.surface2 or C.accent, BorderSizePixel = 0, Text = isDead and "ОБНОВ." or "ЗАПУСТИТЬ", TextColor3 = isDead and C.muted or Color3.new(1, 1, 1), TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false }, card)
        corner(launchBtn, 6)
        
        if not isDead then stroke(launchBtn, C.accent, 1, 0.3) end

        addConnection(launchBtn.MouseButton1Click:Connect(function() 
            if isDead then showToast("Чит скоро вернется после обновления", "warn")
            else launchCheat(cheat) end
        end))

        local likeBtn, dislikeBtn
        if not isDead then
            likeBtn = create("TextButton", { Position = UDim2.new(1, -90, 0, 40), Size = UDim2.fromOffset(37, 22), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "👍", TextColor3 = C.green, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = true }, card)
            corner(likeBtn, 6)
            dislikeBtn = create("TextButton", { Position = UDim2.new(1, -50, 0, 40), Size = UDim2.fromOffset(37, 22), BackgroundColor3 = C.surface2, BorderSizePixel = 0, Text = "👎", TextColor3 = C.red, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = true }, card)
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
        
        if likeBtn then addConnection(likeBtn.MouseButton1Click:Connect(function() vote(1) end)) end
        if dislikeBtn then addConnection(dislikeBtn.MouseButton1Click:Connect(function() vote(-1) end)) end

        return card
    end

    local function filterGames()
        local query = string.lower(searchBox.Text)
        for _, child in ipairs(gamesPage:GetChildren()) do
            if child:IsA("GuiObject") and child.Name == "GameCard" then
                local gameName = string.lower(child:GetAttribute("GameName") or "")
                if query == "" or string.find(gameName, query, 1, true) then child.Visible = true
                else child.Visible = false end
            end
        end
    end

    addConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(filterGames))

    local function loadGamesList()
        if STATE.gamesLoading then return end
        STATE.gamesLoading = true

        for _, child in ipairs(gamesPage:GetChildren()) do 
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end 
        end

        setLoaderStatus("Загрузка...", C.yellow)

        local result, err = api("/get_scripts", nil, "GET")
        
        if not result or result.success ~= true or type(result.games) ~= "table" then
            local lbl = create("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = "Ошибка загрузки списка игр.\nПроверьте интернет.", TextColor3 = C.red, TextSize = 11, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, gamesPage)
            lbl.LayoutOrder = 1
            setLoaderStatus("Нет связи", C.red)
            STATE.gamesLoading = false
            return
        end

        STATE.games = {}
        local index = 1
        STATE.gameImages = result.gameImages or {}

        for gameName, cheatsList in pairs(result.games) do
            local gameObj = { name = gameName, cheats = {} }
            for _, c in ipairs(cheatsList) do
                table.insert(gameObj.cheats, { id = c.id, name = c.name, url = c.url, image_id = c.image_id })
            end
            table.insert(STATE.games, gameObj)

            local count = #gameObj.cheats
            local subtitle = count .. " " .. (count == 1 and "чит" or "читов")
            
            local icon = GameIcons[gameName] or GameIcons.default
            local gameImageId = STATE.gameImages[gameName] or ""
            
            local card = makeCard(gamesPage, gameName, subtitle, icon, gameImageId, function()
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

        setLoaderStatus("Готов к работе", C.green)
        STATE.gamesLoaded = true
        STATE.gamesLoading = false
    end

    loadFavoritesPage = function()
        for _, child in ipairs(favoritesPage:GetChildren()) do 
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end 
        end
        
        local hasFavs = false
        for _, gameObj in ipairs(STATE.games) do
            if STATE.favorites[gameObj.name] then
                hasFavs = true
                local count = #gameObj.cheats
                local subtitle = count .. " " .. (count == 1 and "чит" or "читов")
                local icon = GameIcons[gameObj.name] or GameIcons.default
                
                local gameImageId = STATE.gameImages[gameObj.name] or ""
                if gameImageId == "" and gameObj.cheats[1] and gameObj.cheats[1].image_id then gameImageId = gameObj.cheats[1].image_id end
                
                local card = makeCard(favoritesPage, gameObj.name, subtitle, icon, gameImageId, function()
                    showCheatsForGame(gameObj)
                end)
                card:SetAttribute("GameName", gameObj.name)
            end
        end
        
        if not hasFavs then
            create("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = "Вы пока не добавили игры в избранное.\nНажмите ☆ на карточке игры.", TextColor3 = C.muted, TextSize = 11, Font = Enum.Font.Gotham, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, favoritesPage)
        end
    end

    showCheatsForGame = function(selectedGame)
        for _, child in ipairs(cheatsPage:GetChildren()) do 
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and child ~= cheatsBackBtn and child ~= cheatsTitleLbl then child:Destroy() end 
        end
        
        cheatsTitleLbl.Text = "ЧИТЫ ДЛЯ " .. tostring(selectedGame.name):upper()

        if not selectedGame.cheats or #selectedGame.cheats == 0 then
            create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "Читы пока не добавлены", TextColor3 = C.muted, TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center }, cheatsPage)
            showPage("cheats")
            return
        end

        setLoaderStatus("Проверка...", C.yellow)

        for i, cheat in ipairs(selectedGame.cheats) do 
            checkLink(cheat)
            createCheatCard(cheatsPage, cheat, i) 
        end
        showPage("cheats")

        task.spawn(function()
            local allChecked = false
            while not allChecked do
                task.wait(0.5)
                allChecked = true
                for _, cheat in ipairs(selectedGame.cheats) do
                    if LinkStatus[cheat.id] == "checking" or LinkStatus[cheat.id] == nil then allChecked = false; break end
                end
            end
            setLoaderStatus("Готов к работе", C.green)
            
            if not cheatsPage.Visible then return end
            for _, child in ipairs(cheatsPage:GetChildren()) do
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

    addConnection(cheatsBackBtn.MouseButton1Click:Connect(function() 
        showPage(STATE.lastNonCheatPage or "games") 
    end))

    showPage = function(name)
        if name == "cheats" then
            if STATE.currentPage ~= "cheats" then STATE.lastNonCheatPage = STATE.currentPage end
        else
            STATE.currentPage = name
        end

        gamesPage.Visible = (name == "games")
        cheatsPage.Visible = (name == "cheats")
        favoritesPage.Visible = (name == "favorites")
        settingsPage.Visible = (name == "settings")
        profilePage.Visible = (name == "profile")
        
        local showTop = (name == "games")
        banner.Visible = showTop
        searchFrame.Visible = showTop
        
        if showTop then
            TweenService:Create(content, TweenInfo.new(0.2), { Position = UDim2.new(0, 8, 0, 124), Size = UDim2.new(1, -16, 1, -132) }):Play()
        else
            TweenService:Create(content, TweenInfo.new(0.2), { Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 1, -16) }):Play()
        end
        
        if name == "favorites" then 
            loadFavoritesPage() 
        elseif name == "profile" then
            profileContent.Position = UDim2.fromScale(0, 0.2)
            TweenService:Create(profileContent, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0, 0) }):Play()
            
            if STATE.activatedAt then
                activatedLbl.Text = "Активирован: " .. STATE.activatedAt
            else
                activatedLbl.Text = "Активирован: --"
            end
        end
    end

    navButtons["games"].iconLabel.TextColor3 = C.accent
    navButtons["games"].textLabel.TextColor3 = C.accent
    navButtons["games"].bg.BackgroundTransparency = 0.8

    onAuthSuccess = function(token)
        if CheatTracker.active then killCheat("re-auth") end
        STATE.authed = true; STATE.token = token
        if token then saveToken(token) end
        showToast("Добро пожаловать!", "ok")
        
        mainGui.Enabled = true
        showPage("games")
        if not STATE.gamesLoaded then loadGamesList() end
        
        if STATE.localRemaining then updateTimerLabel(STATE.localRemaining)
        else updateTimerLabel(nil) end

        task.spawn(function()
            local result = api("/verify", { token = token })
            if result and result.valid == true and result.remaining_seconds then STATE.localRemaining = tonumber(result.remaining_seconds); updateTimerLabel(STATE.localRemaining)
            else updateTimerLabel(nil) end
        end)
        task.spawn(function() fetchRatings(true) end)
    end

    local function kickToAuth(reason)
        killCheat(reason or "key expired")
        STATE.authed = false; STATE.token = nil; STATE.busy = false; STATE.localRemaining = nil
        clearToken(); updateTimerLabel(nil)
        isRunning = false
        startLauncher()
        showToast(reason or "Нужен ключ доступа", "warn")
    end

    task.spawn(function()
        task.spawn(function()
            while isRunning do
                if STATE.authed and STATE.localRemaining and STATE.localRemaining > 0 then
                    STATE.localRemaining = STATE.localRemaining - 1; updateTimerLabel(STATE.localRemaining)
                    if STATE.localRemaining <= 0 then kickToAuth("Ключ истёк") end
                end
                task.wait(1)
            end
        end)
        while isRunning do
            if STATE.authed and STATE.token then
                local result, err = api("/verify", { token = STATE.token })
                if result and result.valid == true then STATE.localRemaining = tonumber(result.remaining_seconds); updateTimerLabel(STATE.localRemaining)
                elseif result and result.valid ~= true then kickToAuth("Ключ отозван")
                elseif not result then
                    local low = string.lower(tostring(err or ""))
                    if string.find(low, "expired") or string.find(low, "invalid") or string.find(low, "403") then kickToAuth("Ключ недействителен") end
                end
            end
            task.wait(CONFIG.HEARTBEAT_S)
        end
    end)

    local viewportConnection
    local function updateAuthLayout()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local viewport = camera.ViewportSize
        local width = viewport.X
        local height = viewport.Y
        local aspect = width / math.max(height, 1)

        if width < 700 then
            AuthPanel.Size = UDim2.fromScale(0.97, 0.42)
            BackgroundArea.Size = UDim2.fromScale(0.50, 1)
            Card.Size = UDim2.fromScale(0.46, 0.96)
        elseif aspect < 1.4 then
            AuthPanel.Size = UDim2.fromScale(0.91, 0.58)
            BackgroundArea.Size = UDim2.fromScale(0.60, 1)
            Card.Size = UDim2.fromScale(0.36, 0.96)
        elseif width < 1100 then
            AuthPanel.Size = UDim2.fromScale(0.90, 0.72)
            BackgroundArea.Size = UDim2.fromScale(0.60, 1)
            Card.Size = UDim2.fromScale(0.37, 0.96)
        else
            local panelWidth = math.min(1250, width * 0.88)
            local panelHeight = math.min(700, height * 0.82)
            AuthPanel.Size = UDim2.fromOffset(panelWidth, panelHeight)
            BackgroundArea.Size = UDim2.fromScale(0.60, 1)
            Card.Size = UDim2.fromScale(0.37, 0.96)
        end
    end

    local function connectCamera()
        if viewportConnection then
            viewportConnection:Disconnect()
            viewportConnection = nil
        end
        local camera = workspace.CurrentCamera
        if camera then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAuthLayout)
        end
        updateAuthLayout()
    end

    addConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera))
    connectCamera()

    task.spawn(function()
        local saved = loadToken()
        if not saved then 
            setLoaderStatus("Ожидание", C.red)
            return 
        end
        
        local valid, reason = verifySavedToken(saved)
        if valid then
            savedSessionToken = saved
            KeyBox.Text = ""
            KeyBox.PlaceholderText = "Сессия сохранена"
            Notice.Text = "Сессия сохранена. Нажмите «Войти»"
            Notice.TextColor3 = C.green
            LoginBtn.Text = "Войти"
            LoginBtn.TextColor3 = C.text
        else
            savedSessionToken = nil
        end
    end)

    showPage("games")

    -- Параллельная загрузка списка игр (до входа)
    task.spawn(function()
        loadGamesList()
    end)

    -- Предзагрузка фона и логотипа (без блокировки старта)
    task.spawn(function()
        pcall(function()
            local list = {}
            if Background and Background.Parent then table.insert(list, Background) end
            local logoImg = logoFrame:FindFirstChildOfClass("ImageLabel")
            if logoImg then table.insert(list, logoImg) end
            if #list > 0 then ContentProvider:PreloadAsync(list) end
        end)
    end)
end

startLauncher()

LocalPlayer.Chatted:Connect(function(msg)
    local cmd = string.lower(msg):gsub("^%s+", "")
    if cmd == "/rh" or cmd == ";rh" or cmd == "!rh" then
        if not isRunning then
            startLauncher()
        end
    end
end)