--[[
    RH-AUTH  |  v0.2 "Neon"
    Standalone License Administration Panel
    Platform: Delta Executor / Roblox
    Backend: Cloudflare Workers + D1
]]

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    SERVER_URL = "https://raherauth.raher458.workers.dev",
    VERSION    = "0.2",
    NAME       = "RH-AUTH",
    TAGLINE    = "LICENSE CONTROL PANEL",
}

local C = {
    Background  = Color3.fromRGB(8, 9, 16),
    Surface     = Color3.fromRGB(16, 18, 30),
    Surface2    = Color3.fromRGB(24, 27, 44),
    Surface3    = Color3.fromRGB(32, 36, 58),
    Border      = Color3.fromRGB(44, 49, 74),
    BorderFocus = Color3.fromRGB(120, 100, 255),
    Accent      = Color3.fromRGB(120, 90, 255),
    Accent2     = Color3.fromRGB(90, 200, 255),
    Accent3     = Color3.fromRGB(255, 100, 220),
    Text        = Color3.fromRGB(240, 242, 255),
    TextDim     = Color3.fromRGB(160, 168, 195),
    TextMuted   = Color3.fromRGB(110, 118, 145),
    Green       = Color3.fromRGB(60, 220, 140),
    Yellow      = Color3.fromRGB(255, 200, 70),
    Red         = Color3.fromRGB(255, 90, 110),
    Gray        = Color3.fromRGB(100, 108, 135),
}

local STATE = {
    adminSecret = "",
    authed = false,
    screens = {},
    currentScreen = nil,
    cache = { licenses = {}, stats = nil },
    filter = "all",
    search = "",
}

-- HTTP =========================================================

local function GetRequestFunction()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    if fluxus and typeof(fluxus.request) == "function" then return fluxus.request end
    if typeof(http) == "table" and typeof(http.request) == "function" then return http.request end
    return nil
end

local function APIRequest(path, body, useAdmin)
    local req = GetRequestFunction()
    if not req then return false, "HTTP недоступен" end

    local headers = { ["Content-Type"] = "application/json" }
    if useAdmin then
        if STATE.adminSecret == "" then return false, "Введите Admin Secret" end
        headers["X-Admin-Secret"] = STATE.adminSecret
    end

    local options = {
        Url = CONFIG.SERVER_URL .. path,
        Method = body and "POST" or "GET",
        Headers = headers,
    }
    if body then options.Body = HttpService:JSONEncode(body) end

    local ok, response = pcall(req, options)
    if not ok then return false, "Ошибка соединения: " .. tostring(response) end
    if not response then return false, "Пустой ответ" end

    local statusCode = tonumber(response.StatusCode or response.status or 0) or 0
    local responseBody = response.Body or response.body or ""

    local decodedOK, decoded = pcall(function() return HttpService:JSONDecode(responseBody) end)
    if not decodedOK then return false, "Некорректный JSON: " .. tostring(responseBody) end

    if statusCode < 200 or statusCode >= 300 then
        return false, decoded.error or ("HTTP " .. tostring(statusCode)), statusCode
    end
    return true, decoded, statusCode
end

-- HELPERS ======================================================

local function trim(s) return (string.gsub(s or "", "^%s*(.-)%s*$", "%1")) end

local function fmtDuration(sec)
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

local function fmtDate(iso)
    if not iso or iso == "" then return "—" end
    local y, mo, d, h, mi = string.match(iso, "(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if not y then return iso end
    return string.format("%s.%s.%s %s:%s", d, mo, y, h, mi)
end

local function copyToClipboard(text)
    if typeof(setclipboard) == "function" then
        return pcall(setclipboard, text)
    end
    return false
end

local function pasteFromClipboard()
    if typeof(getclipboard) == "function" then
        local ok, v = pcall(getclipboard)
        if ok and v and v ~= "" then return v end
    end
    return nil
end

-- ROOT UI ======================================================

local old = game:GetService("CoreGui"):FindFirstChild("RHAuth")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RHAuth"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

local okParent = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not okParent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local W, H = 340, 540

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, W*0.9, 0, H*0.9),
    Position = UDim2.new(0.5, -W*0.45, 0.5, -H*0.45),
    BackgroundColor3 = C.Background,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)

New("UICorner", { CornerRadius = UDim.new(0, 20) }, Main)
New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.3 }, Main)

TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
    Size = UDim2.new(0, W, 0, H),
    Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
}):Play()

-- HEADER =======================================================

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,
}, Main)
New("UICorner", { CornerRadius = UDim.new(0, 20) }, Header)
New("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = C.Surface,
    BorderSizePixel = 0,
}, Header)

local LogoDot = New("Frame", {
    Size = UDim2.new(0, 34, 0, 34),
    Position = UDim2.new(0, 16, 0, 16),
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
}, Header)
New("UICorner", { CornerRadius = UDim.new(0, 10) }, LogoDot)
New("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "RH",
    TextColor3 = C.Text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
}, LogoDot)
New("UIStroke", { Color = C.Accent3, Thickness = 1, Transparency = 0.5 }, LogoDot)

task.spawn(function()
    while LogoDot.Parent do
        local pulse = New("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            ZIndex = -1,
        }, LogoDot)
        New("UICorner", { CornerRadius = UDim.new(0, 10) }, pulse)
        TweenService:Create(pulse, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 20, 1, 20),
            Position = UDim2.new(0, -10, 0, -10),
            BackgroundTransparency = 1,
        }):Play()
        task.wait(1.5)
        pulse:Destroy()
    end
end)

New("TextLabel", {
    Position = UDim2.new(0, 60, 0, 14),
    Size = UDim2.new(1, -110, 0, 24),
    BackgroundTransparency = 1,
    Text = CONFIG.NAME,
    TextColor3 = C.Text,
    TextSize = 21,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

New("TextLabel", {
    Position = UDim2.new(0, 61, 0, 38),
    Size = UDim2.new(1, -110, 0, 16),
    BackgroundTransparency = 1,
    Text = CONFIG.TAGLINE .. "  •  v" .. CONFIG.VERSION,
    TextColor3 = C.TextMuted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

local CloseBtn = New("TextButton", {
    Position = UDim2.new(1, -42, 0, 16),
    Size = UDim2.new(0, 30, 0, 30),
    BackgroundColor3 = C.Surface2,
    Text = "×",
    TextColor3 = C.Text,
    TextSize = 22,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    AutoButtonColor = false,
}, Header)
New("UICorner", { CornerRadius = UDim.new(0, 8) }, CloseBtn)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.Red }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.Surface2 }):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- DRAGGING =====================================================

local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- [КОНЕЦ ЧАСТИ 1]

-- TOAST ========================================================

local ToastC = New("Frame", {
    Position = UDim2.new(0, 0, 1, -190),
    Size = UDim2.new(1, 0, 0, 180),
    BackgroundTransparency = 1,
    ZIndex = 50,
}, Main)

New("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, ToastC)
New("UIPadding", {
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 14),
    PaddingRight = UDim.new(0, 14),
}, ToastC)

local toastOrder = 0

local function Toast(text, kind)
    toastOrder = toastOrder + 1
    local color = kind == "success" and C.Green
              or kind == "error"   and C.Red
              or kind == "warn"    and C.Yellow
              or C.Accent

    local t = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Surface3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = toastOrder,
    }, ToastC)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, t)
    New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, t)
    New("TextLabel", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, t)

    TweenService:Create(t, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 36),
    }):Play()

    task.delay(3, function()
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

-- COMPONENTS ===================================================

local ScreenContainer = New("Frame", {
    Position = UDim2.new(0, 0, 0, 66),
    Size = UDim2.new(1, 0, 1, -66),
    BackgroundTransparency = 1,
}, Main)

local function Scroll(parent)
    local s = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, parent)
    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, s)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    }, s)
    return s
end

local function Btn(text, parent, color, onClick, height)
    color = color or C.Accent
    height = height or 44

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = color,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, btn)

    local lbl = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
    }, btn)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { Size = UDim2.new(1, 4, 0, height) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, height) }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), { Size = UDim2.new(1, -8, 0, height) }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { Size = UDim2.new(1, 0, 0, height) }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if onClick then task.spawn(function() onClick(btn, lbl) end) end
    end)

    return btn, lbl
end

local function Input(placeholder, default, parent, opts)
    opts = opts or {}
    local wrap = New("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.Surface2,
        BorderSizePixel = 0,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, wrap)
    local stroke = New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.3 }, wrap)

    local box = New("TextBox", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24 - (opts.paste and 40 or 0), 1, 0),
        BackgroundTransparency = 1,
        Text = default or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = C.TextMuted,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, wrap)

    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = C.BorderFocus, Transparency = 0 }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = C.Border, Transparency = 0.3 }):Play()
    end)

    if opts.paste then
        local pb = New("TextButton", {
            Position = UDim2.new(1, -40, 0, 6),
            Size = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = C.Surface3,
            Text = "📋",
            TextColor3 = C.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, wrap)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, pb)
        pb.MouseButton1Click:Connect(function()
            local v = pasteFromClipboard()
            if v and v ~= "" then
                box.Text = v
                Toast("Вставлено", "info")
            else
                Toast("Буфер пуст", "warn")
            end
        end)
    end

    return box, wrap
end

local function Toggle(parent, defaultOn, labelText)
    local state = defaultOn and true or false
    local wrap = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.Surface2,
        BorderSizePixel = 0,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, wrap)
    New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.3 }, wrap)

    New("TextLabel", {
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText or "",
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, wrap)

    local track = New("Frame", {
        Position = UDim2.new(1, -62, 0.5, -12),
        Size = UDim2.new(0, 46, 0, 24),
        BackgroundColor3 = state and C.Accent or C.Surface3,
        BorderSizePixel = 0,
    }, wrap)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

    local knob = New("Frame", {
        Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = C.Text,
        BorderSizePixel = 0,
    }, track)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, wrap)

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = state and C.Accent or C.Surface3,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        }):Play()
    end)

    return { Get = function() return state end }, wrap
end

local function TextLabel(text, size, color, parent, order)
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, size or 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or C.Text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = order or 0,
    }, parent)
end

local function SectionHeader(text, parent, order)
    local l = TextLabel(text, 20, C.Accent2, parent, order or 0)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    return l
end

-- SCREEN ROUTER ================================================

local SCREENS = STATE.screens

local function ShowScreen(name)
    for _, s in pairs(SCREENS) do
        if s.Root then s.Root.Visible = false end
    end
    local sc = SCREENS[name]
    if not sc then return end
    if not sc.Root then
        local root = New("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
        }, ScreenContainer)
        sc.Root = root
        sc.Build(root)
    end
    sc.Root.Visible = true
    sc.Root.Position = UDim2.new(0, 30, 0, 0)
    TweenService:Create(sc.Root, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
    STATE.currentScreen = name
end

-- [КОНЕЦ ЧАСТИ 2]

-- SCREEN: AUTH =================================================

SCREENS.auth = {
    Build = function(root)
        local card = New("Frame", {
            Position = UDim2.new(0, 16, 0.5, -170),
            Size = UDim2.new(1, -32, 0, 320),
            BackgroundColor3 = C.Surface,
            BorderSizePixel = 0,
        }, root)
        New("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
        New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.5 }, card)

        local t1 = TextLabel("🔐  Авторизация", 26, C.Text, card)
        t1.Position = UDim2.new(0, 20, 0, 22)
        t1.Font = Enum.Font.GothamBold
        t1.TextSize = 18

        local t2 = TextLabel("Введите Admin Secret для доступа к панели.", 36, C.TextDim, card)
        t2.Position = UDim2.new(0, 20, 0, 56)

        local t3 = TextLabel("ADMIN SECRET", 16, C.TextMuted, card)
        t3.Position = UDim2.new(0, 20, 0, 100)
        t3.Font = Enum.Font.GothamBold
        t3.TextSize = 9

        local secretBox, wrap = Input("Вставьте секрет", "", card, { paste = true })
        wrap.Position = UDim2.new(0, 20, 0, 120)
        wrap.Size = UDim2.new(1, -40, 0, 44)

        local status = TextLabel("", 30, C.TextMuted, card)
        status.Position = UDim2.new(0, 20, 0, 178)

        local loginBtn, loginLbl = Btn("ВОЙТИ", card, C.Accent, function()
            local v = trim(secretBox.Text)
            if v == "" then Toast("Введите секрет", "error") return end

            loginLbl.Text = "⏳  ПРОВЕРКА..."
            status.Text = "Соединение..."
            STATE.adminSecret = v

            task.spawn(function()
                local ok, result = APIRequest("/admin/list", {}, true)
                if ok then
                    STATE.authed = true
                    STATE.cache.licenses = result.keys or {}
                    status.Text = "Успешный вход"
                    status.TextColor3 = C.Green
                    Toast("Добро пожаловать!", "success")
                    task.wait(0.3)
                    ShowScreen("main")
                else
                    STATE.adminSecret = ""
                    loginLbl.Text = "ВОЙТИ"
                    status.Text = tostring(result)
                    status.TextColor3 = C.Red
                    Toast(tostring(result), "error")
                end
            end)
        end)
        loginBtn.Position = UDim2.new(0, 20, 0, 218)
        loginBtn.Size = UDim2.new(1, -40, 0, 46)

        local srvBtn = Btn("ПРОВЕРИТЬ СЕРВЕР", card, C.Surface3, function()
            local ok, _, code = APIRequest("", nil, false)
            if ok then Toast("Сервер онлайн (" .. tostring(code) .. ")", "success")
            else Toast("Сервер недоступен", "error") end
        end)
        srvBtn.Position = UDim2.new(0, 20, 0, 272)
    end,
}

-- SCREEN: MAIN =================================================

SCREENS.main = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = TextLabel("📊  Обзор", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        local statsFrame = New("Frame", {
            Size = UDim2.new(1, 0, 0, 230),
            BackgroundTransparency = 1,
            LayoutOrder = 1,
        }, scroll)
        New("UIGridLayout", {
            CellSize = UDim2.new(0.5, -5, 0, 70),
            CellPadding = UDim2.new(0, 10, 0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, statsFrame)

        local function StatCard(label, value, color)
            local c = New("Frame", {
                BackgroundColor3 = C.Surface,
                BorderSizePixel = 0,
            }, statsFrame)
            New("UICorner", { CornerRadius = UDim.new(0, 12) }, c)
            New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.5 }, c)

            New("Frame", {
                Size = UDim2.new(0, 3, 0, 24),
                Position = UDim2.new(0, 0, 0, 14),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
            }, c)

            local valLabel = New("TextLabel", {
                Position = UDim2.new(0, 14, 0, 12),
                Size = UDim2.new(1, -20, 0, 26),
                BackgroundTransparency = 1,
                Text = value,
                TextColor3 = C.Text,
                TextSize = 20,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, c)

            New("TextLabel", {
                Position = UDim2.new(0, 14, 0, 42),
                Size = UDim2.new(1, -20, 0, 16),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = C.TextMuted,
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, c)

            return valLabel
        end

        local statTotal    = StatCard("ВСЕГО", "—", C.Accent)
        local statActive   = StatCard("АКТИВНЫХ", "—", C.Green)
        local statExpired  = StatCard("ИСТЁКШИХ", "—", C.Yellow)
        local statRevoked  = StatCard("ОТОЗВАНО", "—", C.Red)
        local statBound    = StatCard("ПРИВЯЗАНО", "—", C.Accent2)
        local statLifetime = StatCard("БЕССРОЧНЫХ", "—", C.Accent3)

        local function loadStats()
            local ok, result = APIRequest("/admin/stats", {}, true)
            if ok and result.stats then
                local s = result.stats
                statTotal.Text    = tostring(s.total or 0)
                statActive.Text   = tostring(s.active or 0)
                statExpired.Text  = tostring(s.expired or 0)
                statRevoked.Text  = tostring(s.revoked or 0)
                statBound.Text    = tostring(s.bound or 0)
                statLifetime.Text = tostring(s.lifetime or 0)
            end
        end

        local refreshBtn, refreshLbl = Btn("🔄  ОБНОВИТЬ СТАТИСТИКУ", scroll, C.Surface2, function()
            refreshLbl.Text = "⏳  ЗАГРУЗКА..."
            task.spawn(function()
                loadStats()
                Toast("Статистика обновлена", "success")
                refreshLbl.Text = "🔄  ОБНОВИТЬ СТАТИСТИКУ"
            end)
        end)
        refreshBtn.LayoutOrder = 2

        local createBtn = Btn("➕  СОЗДАТЬ КЛЮЧ", scroll, C.Accent, function()
            ShowScreen("create")
        end)
        createBtn.LayoutOrder = 3

        local listBtn = Btn("📋  СПИСОК КЛЮЧЕЙ", scroll, C.Surface2, function()
            ShowScreen("list")
        end)
        listBtn.LayoutOrder = 4

        local settingsBtn = Btn("⚙️  НАСТРОЙКИ", scroll, C.Surface2, function()
            ShowScreen("settings")
        end)
        settingsBtn.LayoutOrder = 5

        task.spawn(loadStats)
    end,
}

-- SCREEN: CREATE ===============================================

SCREENS.create = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = TextLabel("➕  Создать лицензии", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        SectionHeader("СРОК ДЕЙСТВИЯ", scroll)

        local lifetime, lw = Toggle(scroll, false, "Бессрочная лицензия")
        lw.LayoutOrder = 2

        local daysBox,  dw = Input("Дни",    "1", scroll)
        local hoursBox, hw = Input("Часы",   "0", scroll)
        local minsBox,  mw = Input("Минуты", "0", scroll)
        dw.LayoutOrder = 3
        hw.LayoutOrder = 4
        mw.LayoutOrder = 5

        SectionHeader("ПАРАМЕТРЫ", scroll)

        local countBox, cw = Input("Количество ключей", "1", scroll)
        cw.LayoutOrder = 7

        local robloxBox, rw = Input("Roblox User ID (необязательно)", "", scroll, { paste = true })
        rw.LayoutOrder = 8

        local status = TextLabel("", 30, C.TextMuted, scroll)
        status.LayoutOrder = 9

        local createBtn, createLbl = Btn("✨  СОЗДАТЬ", scroll, C.Accent, function()
            local days    = tonumber(daysBox.Text)  or 0
            local hours   = tonumber(hoursBox.Text) or 0
            local minutes = tonumber(minsBox.Text)  or 0
            local count   = tonumber(countBox.Text) or 1
            local isLife  = lifetime.Get()

            if not isLife and (days + hours + minutes) <= 0 then
                Toast("Укажите срок или включите бессрочность", "error")
                return
            end
            if count < 1 or count > 100 then
                Toast("Количество: 1–100", "error")
                return
            end

            local body = {
                days    = math.floor(days),
                hours   = math.floor(hours),
                minutes = math.floor(minutes),
                count   = math.floor(count),
                lifetime = isLife,
            }

            local uid = trim(robloxBox.Text)
            if uid ~= "" then
                local n = tonumber(uid)
                if not n or n < 1 then
                    Toast("Некорректный Roblox ID", "error")
                    return
                end
                body.roblox_user_id = n
            end

            createLbl.Text = "⏳  СОЗДАНИЕ..."
            status.Text = "Отправка на сервер..."
            status.TextColor3 = C.TextDim

            task.spawn(function()
                local ok, result = APIRequest("/admin/create", body, true)

                if not ok then
                    status.Text = tostring(result)
                    status.TextColor3 = C.Red
                    Toast(tostring(result), "error")
                    createLbl.Text = "✨  СОЗДАТЬ"
                    return
                end

                local keys = result.keys or {}
                local failed = result.failed or {}

                status.Text = "Создано: " .. #keys .. (#failed > 0 and (", ошибок: " .. #failed) or "")
                status.TextColor3 = #keys > 0 and C.Green or C.Red
                createLbl.Text = "✨  СОЗДАТЬ"

                if #keys > 0 then
                    Toast("Создано ключей: " .. #keys, "success")

                    -- Result box
                    local resultWrap = New("Frame", {
                        Size = UDim2.new(1, 0, 0, 140),
                        BackgroundColor3 = C.Surface2,
                        BorderSizePixel = 0,
                        LayoutOrder = 11,
                    }, scroll)
                    New("UICorner", { CornerRadius = UDim.new(0, 10) }, resultWrap)
                    New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.3 }, resultWrap)

                    local resultBox = New("TextBox", {
                        Position = UDim2.new(0, 10, 0, 10),
                        Size = UDim2.new(1, -20, 1, -60),
                        BackgroundTransparency = 1,
                        Text = table.concat(keys, "\n"),
                        TextColor3 = C.Text,
                        TextSize = 11,
                        Font = Enum.Font.Code,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        MultiLine = true,
                        TextEditable = false,
                        TextWrapped = true,
                    }, resultWrap)

                    local copyBtn = New("TextButton", {
                        Position = UDim2.new(0, 10, 1, -46),
                        Size = UDim2.new(1, -20, 0, 36),
                        BackgroundColor3 = C.Accent,
                        Text = "📋  КОПИРОВАТЬ ВСЕ",
                        TextColor3 = C.Text,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                    }, resultWrap)
                    New("UICorner", { CornerRadius = UDim.new(0, 8) }, copyBtn)
                    copyBtn.MouseButton1Click:Connect(function()
                        local ok2 = copyToClipboard(table.concat(keys, "\n"))
                        if ok2 then Toast("Скопировано", "success")
                        else Toast("Буфер недоступен", "warn") end
                    end)
                end

                if #failed > 0 then
                    for _, f in ipairs(failed) do
                        Toast("Ошибка: " .. tostring(f.reason), "error")
                    end
                end
            end)
        end)
        createBtn.LayoutOrder = 10

        local backBtn = Btn("←  НАЗАД", scroll, C.Surface2, function()
            ShowScreen("main")
        end)
        backBtn.LayoutOrder = 12
    end,
}

-- [КОНЕЦ ЧАСТИ 3]

-- SCREEN: LIST =================================================

SCREENS.list = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = TextLabel("📋  Список ключей", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        -- Search
        local searchBox, searchWrap = Input("Поиск по ключу или Roblox ID", "", scroll, { paste = true })
        searchWrap.LayoutOrder = 1

        -- Filter row
        local filterRow = New("Frame", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, scroll)
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, filterRow)

        local filters = {
            {id = "all",     label = "ВСЕ",       color = C.Surface3},
            {id = "active",  label = "АКТИВ",     color = C.Green},
            {id = "expired", label = "ИСТЕКЛИ",   color = C.Yellow},
            {id = "revoked", label = "ОТОЗВАНЫ",  color = C.Red},
        }

        local filterButtons = {}

        for i, f in ipairs(filters) do
            local fb = New("TextButton", {
                Size = UDim2.new(0, 76, 1, 0),
                BackgroundColor3 = f.color,
                Text = f.label,
                TextColor3 = C.Text,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = i,
            }, filterRow)
            New("UICorner", { CornerRadius = UDim.new(0, 8) }, fb)
            filterButtons[f.id] = fb

            fb.MouseButton1Click:Connect(function()
                STATE.filter = f.id
                for id, btn in pairs(filterButtons) do
                    btn.BackgroundTransparency = (id == f.id) and 0 or 0.55
                end
                renderList()
            end)
        end
        filterButtons.all.BackgroundTransparency = 0
        filterButtons.active.BackgroundTransparency = 0.55
        filterButtons.expired.BackgroundTransparency = 0.55
        filterButtons.revoked.BackgroundTransparency = 0.55

        -- Container for cards
        local cardsWrap = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            AutomaticSize = Enum.AutomaticSize.Y,
        }, scroll)
        New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, cardsWrap)

        local countLabel = TextLabel("", 22, C.TextMuted, scroll, 4)

        local function getStatus(item)
            if item.is_active == 0 then return "revoked", "ОТОЗВАН", C.Red end
            if item.expired then return "expired", "ИСТЁК", C.Yellow end
            if not item.activated_at and item.duration_seconds ~= nil then
                return "pending", "НЕ АКТИВИРОВАН", C.Gray
            end
            return "active", "АКТИВЕН", C.Green
        end

        local function buildCard(item)
            local status, statusText, statusColor = getStatus(item)

            local card = New("Frame", {
                Size = UDim2.new(1, 0, 0, 130),
                BackgroundColor3 = C.Surface,
                BorderSizePixel = 0,
            }, cardsWrap)
            New("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
            New("UIStroke", { Color = C.Border, Thickness = 1, Transparency = 0.5 }, card)

            -- Status stripe
            New("Frame", {
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = statusColor,
                BorderSizePixel = 0,
            }, card)

            -- Key (monospace)
            local keyBox = New("TextLabel", {
                Position = UDim2.new(0, 14, 0, 10),
                Size = UDim2.new(1, -100, 0, 20),
                BackgroundTransparency = 1,
                Text = item.key or "?",
                TextColor3 = C.Text,
                TextSize = 12,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, card)

            -- Status pill
            local pill = New("TextLabel", {
                Position = UDim2.new(1, -86, 0, 8),
                Size = UDim2.new(0, 74, 0, 22),
                BackgroundColor3 = statusColor,
                BackgroundTransparency = 0.75,
                Text = statusText,
                TextColor3 = statusColor,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
            }, card)
            New("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)
            New("UIStroke", { Color = statusColor, Thickness = 1, Transparency = 0.5 }, pill)

            -- Meta info
            local meta = {}
            if item.roblox_user_id then table.insert(meta, "👤 " .. tostring(item.roblox_user_id)) end
            if item.install_hash then table.insert(meta, "💻 привязан") else table.insert(meta, "💻 свободен") end
            if item.duration_seconds == nil then
                table.insert(meta, "∞ бессрочно")
            elseif item.expires_at then
                table.insert(meta, "⏱ " .. fmtDuration(item.remaining_seconds))
            else
                table.insert(meta, "⏱ " .. fmtDuration(item.duration_seconds))
            end

            New("TextLabel", {
                Position = UDim2.new(0, 14, 0, 34),
                Size = UDim2.new(1, -20, 0, 32),
                BackgroundTransparency = 1,
                Text = table.concat(meta, "   •   "),
                TextColor3 = C.TextDim,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
            }, card)

            -- Actions row (4 small buttons)
            local actionsWrap = New("Frame", {
                Position = UDim2.new(0, 10, 1, -42),
                Size = UDim2.new(1, -20, 0, 34),
                BackgroundTransparency = 1,
            }, card)
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, actionsWrap)

            local function smallAction(text, color, onClick)
                local b = New("TextButton", {
                    Size = UDim2.new(0.25, -4, 1, 0),
                    BackgroundColor3 = color,
                    Text = text,
                    TextColor3 = C.Text,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, actionsWrap)
                New("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
                b.MouseButton1Click:Connect(function()
                    task.spawn(function() onClick() end)
                end)
                return b
            end

            smallAction("📋", C.Surface3, function()
                local ok = copyToClipboard(item.key or "")
                if ok then Toast("Ключ скопирован", "success")
                else Toast("Буфер недоступен", "warn") end
            end)

            smallAction("🚫", C.Surface3, function()
                local ok, res = APIRequest("/admin/revoke", { key = item.key }, true)
                if ok and res.success then
                    Toast("Отозван", "success")
                    renderList()
                else
                    Toast(tostring(res), "error")
                end
            end)

            smallAction("🔄", C.Surface3, function()
                local ok, res = APIRequest("/admin/reset-device", { key = item.key }, true)
                if ok and res.success then
                    Toast("HWID сброшен", "success")
                    renderList()
                else
                    Toast(tostring(res), "error")
                end
            end)

            smallAction("🗑", C.Surface3, function()
                local ok, res = APIRequest("/admin/delete", { key = item.key }, true)
                if ok and res.success then
                    Toast("Удалён", "success")
                    renderList()
                else
                    Toast(tostring(res), "error")
                end
            end)
        end

        local loading = false

        function renderList()
            if loading then return end
            loading = true

            for _, ch in ipairs(cardsWrap:GetChildren()) do
                if ch:IsA("GuiObject") then ch:Destroy() end
            end

            local searchText = string.lower(trim(searchBox.Text))
            local filter = STATE.filter

            local all = STATE.cache.licenses or {}
            local shown = 0

            for _, item in ipairs(all) do
                local status = getStatus(item)
                local matchesFilter = (filter == "all") or (status == filter)
                local matchesSearch = true

                if searchText ~= "" then
                    local k = string.lower(item.key or "")
                    local u = string.lower(tostring(item.roblox_user_id or ""))
                    matchesSearch = (string.find(k, searchText, 1, true) ~= nil)
                                 or (string.find(u, searchText, 1, true) ~= nil)
                end

                if matchesFilter and matchesSearch then
                    buildCard(item)
                    shown = shown + 1
                end
            end

            countLabel.Text = "Показано: " .. shown .. " из " .. #all
            loading = false
        end

        local refreshBtn, refreshLbl = Btn("🔄  ОБНОВИТЬ СПИСОК", scroll, C.Accent, function()
            refreshLbl.Text = "⏳  ЗАГРУЗКА..."
            task.spawn(function()
                local ok, result = APIRequest("/admin/list", {}, true)
                if ok then
                    STATE.cache.licenses = result.keys or {}
                    renderList()
                    Toast("Загружено: " .. #STATE.cache.licenses, "success")
                else
                    Toast(tostring(result), "error")
                end
                refreshLbl.Text = "🔄  ОБНОВИТЬ СПИСОК"
            end)
        end)
        refreshBtn.LayoutOrder = 5

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            renderList()
        end)

        local backBtn = Btn("←  НАЗАД", scroll, C.Surface2, function()
            ShowScreen("main")
        end)
        backBtn.LayoutOrder = 6

        -- auto render cached
        task.spawn(renderList)
    end,
}

-- SCREEN: SETTINGS =============================================

SCREENS.settings = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = TextLabel("⚙️  Настройки", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        SectionHeader("СЕРВЕР", scroll)

        local urlLabel = TextLabel(CONFIG.SERVER_URL, 36, C.TextDim, scroll, 3)
        urlLabel.Font = Enum.Font.Code
        urlLabel.TextSize = 10

        local pingBtn, pingLbl = Btn("🌐  ПРОВЕРИТЬ СВЯЗЬ", scroll, C.Surface2, function()
            pingLbl.Text = "⏳  ПРОВЕРКА..."
            task.spawn(function()
                local t = os.clock()
                local ok, _, code = APIRequest("", nil, false)
                local ms = math.floor((os.clock() - t) * 1000)
                if ok then Toast("Онлайн • " .. ms .. " мс", "success")
                else Toast("Ошибка соединения", "error") end
                pingLbl.Text = "🌐  ПРОВЕРИТЬ СВЯЗЬ"
            end)
        end)
        pingBtn.LayoutOrder = 4

        SectionHeader("СЕССИЯ", scroll)

        local infoLabel = TextLabel(
            "Admin Secret хранится только в памяти текущей сессии и не сохраняется на диск.",
            40, C.TextDim, scroll, 6
        )

        local logoutBtn, logoutLbl = Btn("🔓  ВЫЙТИ ИЗ АККАУНТА", scroll, C.Red, function()
            STATE.adminSecret = ""
            STATE.authed = false
            STATE.cache.licenses = {}
            STATE.cache.stats = nil
            Toast("Сессия завершена", "success")
            task.wait(0.3)
            ShowScreen("auth")
        end)
        logoutBtn.LayoutOrder = 7

        SectionHeader("О ПАНЕЛИ", scroll)

        TextLabel(CONFIG.NAME .. "  •  v" .. CONFIG.VERSION, 20, C.Text, scroll, 9).Font = Enum.Font.GothamBold
        TextLabel("Standalone License Administration Panel", 20, C.TextMuted, scroll, 10).TextSize = 10
        TextLabel("Cloudflare Workers + D1 backend", 20, C.TextMuted, scroll, 11).TextSize = 10

        local backBtn = Btn("←  НАЗАД", scroll, C.Surface2, function()
            ShowScreen("main")
        end)
        backBtn.LayoutOrder = 12
    end,
}

-- =========================================================
-- INITIALIZATION
-- =========================================================

ShowScreen("auth")

print("[RH-AUTH] Panel initialized")
print("[RH-AUTH] Standalone version " .. CONFIG.VERSION)
print("[RH-AUTH] Server: " .. CONFIG.SERVER_URL)

-- [КОНЕЦ ЧАСТИ 4]
-- [[ КОНЕЦ ФАЙЛА ]]