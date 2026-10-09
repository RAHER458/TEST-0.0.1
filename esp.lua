--[[
    RH-AUTH  |  v0.3 "Neon Compact"
    Standalone License Admin Panel
    Delta Executor / Roblox
]]

repeat task.wait() until game:IsLoaded()

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    SERVER_URL = "https://raherauth.raher458.workers.dev",
    VERSION    = "0.3",
    NAME       = "RH-AUTH",
}

local C = {
    Bg       = Color3.fromRGB(8, 9, 16),
    Surf     = Color3.fromRGB(16, 18, 30),
    Surf2    = Color3.fromRGB(24, 27, 44),
    Surf3    = Color3.fromRGB(32, 36, 58),
    Bord     = Color3.fromRGB(44, 49, 74),
    Accent   = Color3.fromRGB(120, 90, 255),
    Accent2  = Color3.fromRGB(90, 200, 255),
    Text     = Color3.fromRGB(240, 242, 255),
    Dim      = Color3.fromRGB(160, 168, 195),
    Muted    = Color3.fromRGB(110, 118, 145),
    Green    = Color3.fromRGB(60, 220, 140),
    Yellow   = Color3.fromRGB(255, 200, 70),
    Red      = Color3.fromRGB(255, 90, 110),
    Gray     = Color3.fromRGB(100, 108, 135),
}

local STATE = {
    adminSecret = "",
    authed      = false,
    screens     = {},
    current     = nil,
    licenses    = {},
    filter      = "all",
}

-- HTTP =========================================================

local function GetReq()
    if typeof(request) == "function" then return request end
    if typeof(http_request) == "function" then return http_request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    if fluxus and typeof(fluxus.request) == "function" then return fluxus.request end
    if typeof(http) == "table" and typeof(http.request) == "function" then return http.request end
    return nil
end

local function API(path, body, useAdmin)
    local req = GetReq()
    if not req then return false, "HTTP недоступен" end

    local headers = { ["Content-Type"] = "application/json" }
    if useAdmin then
        if STATE.adminSecret == "" then return false, "Введите Admin Secret" end
        headers["X-Admin-Secret"] = STATE.adminSecret
    end

    local opts = { Url = CONFIG.SERVER_URL .. path, Method = body and "POST" or "GET", Headers = headers }
    if body then opts.Body = HttpService:JSONEncode(body) end

    local ok, res = pcall(req, opts)
    if not ok then return false, "Ошибка соединения: " .. tostring(res) end
    if not res then return false, "Пустой ответ" end

    local code = tonumber(res.StatusCode or res.status or 0) or 0
    local rbody = res.Body or res.body or ""
    local dok, decoded = pcall(function() return HttpService:JSONDecode(rbody) end)
    if not dok then return false, "Некорректный JSON" end

    if code < 200 or code >= 300 then
        return false, decoded.error or ("HTTP " .. tostring(code)), code
    end
    return true, decoded, code
end

-- Helpers ======================================================

local function trim(s) return (string.gsub(s or "", "^%s*(.-)%s*$", "%1")) end

local function fmtDur(sec)
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

local function copyClip(text)
    if typeof(setclipboard) == "function" then return pcall(setclipboard, text) end
    return false
end

local function pasteClip()
    if typeof(getclipboard) == "function" then
        local ok, v = pcall(getclipboard)
        if ok and v and v ~= "" then return v end
    end
    return nil
end

-- Root GUI =====================================================

local old = game:GetService("CoreGui"):FindFirstChild("RHAuth")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "RHAuth"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true

local okP = pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not okP then SG.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- Main window ==================================================

local WIN_W, WIN_H = 340, 520
local MINI_H = 66

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = C.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, SG)
New("UICorner", { CornerRadius = UDim.new(0, 18) }, Main)
New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.3 }, Main)

Main.BackgroundTransparency = 1
Main.Size = UDim2.new(0, WIN_W * 0.9, 0, WIN_H * 0.9)
TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
}):Play()

-- Header =======================================================

local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.Surf,
    BorderSizePixel = 0,
}, Main)
New("UICorner", { CornerRadius = UDim.new(0, 18) }, Header)
New("Frame", {
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.new(0, 0, 1, -22),
    BackgroundColor3 = C.Surf,
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

New("TextLabel", {
    Position = UDim2.new(0, 60, 0, 14),
    Size = UDim2.new(1, -160, 0, 24),
    BackgroundTransparency = 1,
    Text = CONFIG.NAME,
    TextColor3 = C.Text,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

New("TextLabel", {
    Position = UDim2.new(0, 61, 0, 38),
    Size = UDim2.new(1, -160, 0, 16),
    BackgroundTransparency = 1,
    Text = "v" .. CONFIG.VERSION .. "  •  LICENSE PANEL",
    TextColor3 = C.Muted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Buttons (minimize + close)
local function HeaderBtn(xOffset, glyph)
    local b = New("TextButton", {
        Position = UDim2.new(1, xOffset, 0, 16),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = C.Surf2,
        Text = glyph,
        TextColor3 = C.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
    }, Header)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
    return b
end

local MinBtn = HeaderBtn(-76, "—")
local CloseBtn = HeaderBtn(-42, "×")

MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.Surf3 }):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.Surf2 }):Play()
end)
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.Red }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), { BackgroundColor3 = C.Surf2 }):Play()
end)

-- Floating bubble ==============================================

local Bubble = New("Frame", {
    Name = "Bubble",
    Size = UDim2.new(0, 54, 0, 54),
    Position = UDim2.new(1, -74, 0, 100),
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 100,
}, SG)
New("UICorner", { CornerRadius = UDim.new(1, 0) }, Bubble)
New("UIStroke", { Color = C.Accent2, Thickness = 2, Transparency = 0.3 }, Bubble)

local BubbleLabel = New("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "RH",
    TextColor3 = C.Text,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
}, Bubble)

-- Bubble dragging (tap to open, drag to move)
local bubbleDragging = false
local bubbleMoved = false
local bubbleStart, bubbleStartPos

Bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        bubbleDragging = true
        bubbleMoved = false
        bubbleStart = input.Position
        bubbleStartPos = Bubble.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if bubbleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - bubbleStart
        if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then
            bubbleMoved = true
        end
        Bubble.Position = UDim2.new(
            bubbleStartPos.X.Scale, bubbleStartPos.X.Offset + d.X,
            bubbleStartPos.Y.Scale, bubbleStartPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if bubbleDragging and (input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch) then
        bubbleDragging = false
        if not bubbleMoved then
            -- tap → open window
            Bubble.Visible = false
            Main.Visible = true
            Main.Size = UDim2.new(0, WIN_W * 0.9, 0, WIN_H * 0.9)
            Main.BackgroundTransparency = 1
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, WIN_W, 0, WIN_H),
                BackgroundTransparency = 0,
            }):Play()
        end
    end
end)

-- Window dragging ==============================================

local wDrag, wStart, wStartPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        wDrag = true
        wStart = input.Position
        wStartPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then wDrag = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if wDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - wStart
        Main.Position = UDim2.new(
            wStartPos.X.Scale, wStartPos.X.Offset + d.X,
            wStartPos.Y.Scale, wStartPos.Y.Offset + d.Y
        )
    end
end)

-- Minimize / Close =============================================

local isMinimized = false

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetH = isMinimized and MINI_H or WIN_H
    if ScreenContainer then ScreenContainer.Visible = not isMinimized end
    if ToastC then ToastC.Visible = not isMinimized end
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, WIN_W, 0, targetH),
    }):Play()
    MinBtn.Text = isMinimized and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, WIN_W * 0.85, 0, WIN_H * 0.85),
        BackgroundTransparency = 1,
    }):Play()
    task.wait(0.2)
    Main.Visible = false
    Bubble.Visible = true
    -- pulse bubble
    task.spawn(function()
        while Bubble.Visible do
            TweenService:Create(Bubble, TweenInfo.new(0.8), { Size = UDim2.new(0, 60, 0, 60) }):Play()
            task.wait(0.8)
            if not Bubble.Visible then break end
            TweenService:Create(Bubble, TweenInfo.new(0.8), { Size = UDim2.new(0, 54, 0, 54) }):Play()
            task.wait(0.8)
        end
    end)
end)

-- [КОНЕЦ ЧАСТИ 1]
-- Toast =======================================================

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

local toastN = 0

local function Toast(text, kind)
    toastN = toastN + 1
    local color = kind == "success" and C.Green
              or kind == "error"   and C.Red
              or kind == "warn"    and C.Yellow
              or C.Accent

    local t = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.Surf3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = toastN,
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

-- Components ===================================================

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

local function Btn(text, parent, color, onClick, h)
    color = color or C.Accent
    h = h or 44

    local b = New("TextButton", {
        Size = UDim2.new(1, 0, 0, h),
        BackgroundColor3 = color,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ClipsDescendants = true,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, b)

    local lbl = New("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
    }, b)

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), { Size = UDim2.new(1, 4, 0, h) }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, h) }):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), { Size = UDim2.new(1, -8, 0, h) }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { Size = UDim2.new(1, 0, 0, h) }):Play()
    end)
    b.MouseButton1Click:Connect(function()
        if onClick then task.spawn(function() onClick(b, lbl) end) end
    end)
    return b, lbl
end

local function Input(placeholder, default, parent, opts)
    opts = opts or {}
    local wrap = New("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.Surf2,
        BorderSizePixel = 0,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, wrap)
    local stroke = New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.3 }, wrap)

    local box = New("TextBox", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24 - (opts.paste and 40 or 0), 1, 0),
        BackgroundTransparency = 1,
        Text = default or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = C.Muted,
        TextColor3 = C.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, wrap)

    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = C.Accent, Transparency = 0 }):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = C.Bord, Transparency = 0.3 }):Play()
    end)

    if opts.paste then
        local pb = New("TextButton", {
            Position = UDim2.new(1, -40, 0, 6),
            Size = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = C.Surf3,
            Text = "📋",
            TextColor3 = C.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        }, wrap)
        New("UICorner", { CornerRadius = UDim.new(0, 8) }, pb)
        pb.MouseButton1Click:Connect(function()
            local v = pasteClip()
            if v and v ~= "" then box.Text = v; Toast("Вставлено", "info")
            else Toast("Буфер пуст", "warn") end
        end)
    end
    return box, wrap
end

local function Toggle(parent, defaultOn, labelText)
    local st = defaultOn and true or false
    local wrap = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.Surf2,
        BorderSizePixel = 0,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 10) }, wrap)
    New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.3 }, wrap)

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
        BackgroundColor3 = st and C.Accent or C.Surf3,
        BorderSizePixel = 0,
    }, wrap)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

    local knob = New("Frame", {
        Position = st and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
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
        st = not st
        TweenService:Create(track, TweenInfo.new(0.2), {
            BackgroundColor3 = st and C.Accent or C.Surf3,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = st and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        }):Play()
    end)
    return { Get = function() return st end }, wrap
end

local function Label(text, h, color, parent, order)
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, h or 20),
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

local function Section(text, parent, order)
    local l = Label(text, 20, C.Accent2, parent, order or 0)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    return l
end

-- Router ======================================================

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
    TweenService:Create(sc.Root, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
    STATE.current = name
end

-- Screen: AUTH =================================================

SCREENS.auth = {
    Build = function(root)
        local card = New("Frame", {
            Position = UDim2.new(0, 16, 0.5, -170),
            Size = UDim2.new(1, -32, 0, 320),
            BackgroundColor3 = C.Surf,
            BorderSizePixel = 0,
        }, root)
        New("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
        New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.5 }, card)

        local t1 = Label("🔐  Авторизация", 26, C.Text, card)
        t1.Position = UDim2.new(0, 20, 0, 22)
        t1.Font = Enum.Font.GothamBold
        t1.TextSize = 18

        local t2 = Label("Введите Admin Secret для доступа.", 36, C.Dim, card)
        t2.Position = UDim2.new(0, 20, 0, 56)

        local t3 = Label("ADMIN SECRET", 16, C.Muted, card)
        t3.Position = UDim2.new(0, 20, 0, 100)
        t3.Font = Enum.Font.GothamBold
        t3.TextSize = 9

        local secretBox, wrap = Input("Вставьте секрет", "", card, { paste = true })
        wrap.Position = UDim2.new(0, 20, 0, 120)
        wrap.Size = UDim2.new(1, -40, 0, 44)

        local status = Label("", 30, C.Muted, card)
        status.Position = UDim2.new(0, 20, 0, 178)

        local loginBtn, loginLbl = Btn("ВОЙТИ", card, C.Accent, function()
            local v = trim(secretBox.Text)
            if v == "" then Toast("Введите секрет", "error") return end

            loginLbl.Text = "⏳  ПРОВЕРКА..."
            status.Text = "Соединение..."
            STATE.adminSecret = v

            task.spawn(function()
                local ok, result = API("/admin/list", {}, true)
                if ok then
                    STATE.authed = true
                    STATE.licenses = result.keys or {}
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

        local srvBtn = Btn("ПРОВЕРИТЬ СЕРВЕР", card, C.Surf3, function()
            local ok, _, code = API("", nil, false)
            if ok then Toast("Сервер онлайн (" .. tostring(code) .. ")", "success")
            else Toast("Сервер недоступен", "error") end
        end)
        srvBtn.Position = UDim2.new(0, 20, 0, 272)
    end,
}

-- Screen: MAIN =================================================

SCREENS.main = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = Label("📊  Обзор", 24, C.Text, scroll)
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
            local c = New("Frame", { BackgroundColor3 = C.Surf, BorderSizePixel = 0 }, statsFrame)
            New("UICorner", { CornerRadius = UDim.new(0, 12) }, c)
            New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.5 }, c)
            New("Frame", {
                Size = UDim2.new(0, 3, 0, 24),
                Position = UDim2.new(0, 0, 0, 14),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
            }, c)
            local vl = New("TextLabel", {
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
                TextColor3 = C.Muted,
                TextSize = 9,
                Font = Enum.Font.GothamMedium,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, c)
            return vl
        end

        local sTotal    = StatCard("ВСЕГО", "—", C.Accent)
        local sActive   = StatCard("АКТИВНЫХ", "—", C.Green)
        local sExpired  = StatCard("ИСТЁКШИХ", "—", C.Yellow)
        local sRevoked  = StatCard("ОТОЗВАНО", "—", C.Red)
        local sBound    = StatCard("ПРИВЯЗАНО", "—", C.Accent2)
        local sLifetime = StatCard("БЕССРОЧНЫХ", "—", C.Accent2)

        local function loadStats()
            local ok, result = API("/admin/stats", {}, true)
            if ok and result.stats then
                local s = result.stats
                sTotal.Text    = tostring(s.total or 0)
                sActive.Text   = tostring(s.active or 0)
                sExpired.Text  = tostring(s.expired or 0)
                sRevoked.Text  = tostring(s.revoked or 0)
                sBound.Text    = tostring(s.bound or 0)
                sLifetime.Text = tostring(s.lifetime or 0)
            end
        end

        local rBtn, rLbl = Btn("🔄  ОБНОВИТЬ СТАТИСТИКУ", scroll, C.Surf2, function()
            rLbl.Text = "⏳  ЗАГРУЗКА..."
            task.spawn(function()
                loadStats()
                Toast("Обновлено", "success")
                rLbl.Text = "🔄  ОБНОВИТЬ СТАТИСТИКУ"
            end)
        end)
        rBtn.LayoutOrder = 2

        local cBtn = Btn("➕  СОЗДАТЬ КЛЮЧ", scroll, C.Accent, function() ShowScreen("create") end)
        cBtn.LayoutOrder = 3

        local lBtn = Btn("📋  СПИСОК КЛЮЧЕЙ", scroll, C.Surf2, function() ShowScreen("list") end)
        lBtn.LayoutOrder = 4

        local setBtn = Btn("⚙️  НАСТРОЙКИ", scroll, C.Surf2, function() ShowScreen("settings") end)
        setBtn.LayoutOrder = 5

        task.spawn(loadStats)
    end,
}

-- [КОНЕЦ ЧАСТИ 2]
-- Screen: CREATE ===============================================

SCREENS.create = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = Label("➕  Создать лицензии", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        Section("СРОК ДЕЙСТВИЯ", scroll)

        local lifetime, lw = Toggle(scroll, false, "Бессрочная лицензия")
        lw.LayoutOrder = 2

        local daysBox,  dw = Input("Дни",    "1", scroll)
        local hoursBox, hw = Input("Часы",   "0", scroll)
        local minsBox,  mw = Input("Минуты", "0", scroll)
        dw.LayoutOrder = 3
        hw.LayoutOrder = 4
        mw.LayoutOrder = 5

        Section("ПАРАМЕТРЫ", scroll)

        local countBox, cw = Input("Количество ключей", "1", scroll)
        cw.LayoutOrder = 7

        local robloxBox, rw = Input("Roblox User ID (необязательно)", "", scroll, { paste = true })
        rw.LayoutOrder = 8

        local status = Label("", 30, C.Muted, scroll)
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
                days     = math.floor(days),
                hours    = math.floor(hours),
                minutes  = math.floor(minutes),
                count    = math.floor(count),
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
            status.TextColor3 = C.Dim

            task.spawn(function()
                local ok, result = API("/admin/create", body, true)

                if not ok then
                    status.Text = tostring(result)
                    status.TextColor3 = C.Red
                    Toast(tostring(result), "error")
                    createLbl.Text = "✨  СОЗДАТЬ"
                    return
                end

                local keys = result.keys or {}
                local failed = result.failed or {}

                status.Text = "Создано: " .. #keys .. (#failed > 0 and ("  •  ошибок: " .. #failed) or "")
                status.TextColor3 = #keys > 0 and C.Green or C.Red
                createLbl.Text = "✨  СОЗДАТЬ"

                if #keys > 0 then
                    Toast("Создано ключей: " .. #keys, "success")

                    local rw2 = New("Frame", {
                        Size = UDim2.new(1, 0, 0, 140),
                        BackgroundColor3 = C.Surf2,
                        BorderSizePixel = 0,
                        LayoutOrder = 11,
                    }, scroll)
                    New("UICorner", { CornerRadius = UDim.new(0, 10) }, rw2)
                    New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.3 }, rw2)

                    New("TextBox", {
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
                    }, rw2)

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
                    }, rw2)
                    New("UICorner", { CornerRadius = UDim.new(0, 8) }, copyBtn)
                    copyBtn.MouseButton1Click:Connect(function()
                        local ok2 = copyClip(table.concat(keys, "\n"))
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

        local backBtn = Btn("←  НАЗАД", scroll, C.Surf2, function() ShowScreen("main") end)
        backBtn.LayoutOrder = 12
    end,
}

-- Screen: LIST =================================================

SCREENS.list = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = Label("📋  Список ключей", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        local searchBox, searchWrap = Input("Поиск по ключу или Roblox ID", "", scroll, { paste = true })
        searchWrap.LayoutOrder = 1

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
            {id = "all",     label = "ВСЕ",      color = C.Surf3},
            {id = "active",  label = "АКТИВ",    color = C.Green},
            {id = "expired", label = "ИСТЕКЛИ",  color = C.Yellow},
            {id = "revoked", label = "ОТОЗВАНЫ", color = C.Red},
        }

        local filterBtns = {}

        for i, f in ipairs(filters) do
            local fb = New("TextButton", {
                Size = UDim2.new(0, 76, 1, 0),
                BackgroundColor3 = f.color,
                BackgroundTransparency = (f.id == "all") and 0 or 0.55,
                Text = f.label,
                TextColor3 = C.Text,
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = i,
            }, filterRow)
            New("UICorner", { CornerRadius = UDim.new(0, 8) }, fb)
            filterBtns[f.id] = fb
        end

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

        local countLabel = Label("", 22, C.Muted, scroll, 4)

        local function getStatus(item)
            if item.is_active == 0 then return "revoked", "ОТОЗВАН", C.Red end
            if item.expired then return "expired", "ИСТЁК", C.Yellow end
            if not item.activated_at and item.duration_seconds ~= nil then
                return "pending", "НЕ АКТИВЕН", C.Gray
            end
            return "active", "АКТИВЕН", C.Green
        end

        local renderList

        local function buildCard(item)
            local _, statusText, statusColor = getStatus(item)

            local card = New("Frame", {
                Size = UDim2.new(1, 0, 0, 130),
                BackgroundColor3 = C.Surf,
                BorderSizePixel = 0,
            }, cardsWrap)
            New("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
            New("UIStroke", { Color = C.Bord, Thickness = 1, Transparency = 0.5 }, card)

            New("Frame", {
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = statusColor,
                BorderSizePixel = 0,
            }, card)

            New("TextLabel", {
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

            local meta = {}
            if item.roblox_user_id then table.insert(meta, "👤 " .. tostring(item.roblox_user_id)) end
            table.insert(meta, item.install_hash and "💻 привязан" or "💻 свободен")
            if item.duration_seconds == nil then
                table.insert(meta, "∞ бессрочно")
            elseif item.expires_at then
                table.insert(meta, "⏱ " .. fmtDur(item.remaining_seconds))
            else
                table.insert(meta, "⏱ " .. fmtDur(item.duration_seconds))
            end

            New("TextLabel", {
                Position = UDim2.new(0, 14, 0, 34),
                Size = UDim2.new(1, -20, 0, 32),
                BackgroundTransparency = 1,
                Text = table.concat(meta, "   •   "),
                TextColor3 = C.Dim,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
            }, card)

            local actions = New("Frame", {
                Position = UDim2.new(0, 10, 1, -42),
                Size = UDim2.new(1, -20, 0, 34),
                BackgroundTransparency = 1,
            }, card)
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, actions)

            local function act(text, cb)
                local b = New("TextButton", {
                    Size = UDim2.new(0.25, -4, 1, 0),
                    BackgroundColor3 = C.Surf3,
                    Text = text,
                    TextColor3 = C.Text,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                }, actions)
                New("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
                b.MouseButton1Click:Connect(function() task.spawn(cb) end)
            end

            act("📋", function()
                local ok = copyClip(item.key or "")
                Toast(ok and "Копия" or "Буфер недоступен", ok and "success" or "warn")
            end)

            act("🚫", function()
                local ok, res = API("/admin/revoke", { key = item.key }, true)
                if ok and res.success then Toast("Отозван", "success"); renderList()
                else Toast(tostring(res), "error") end
            end)

            act("🔄", function()
                local ok, res = API("/admin/reset-device", { key = item.key }, true)
                if ok and res.success then Toast("HWID сброшен", "success"); renderList()
                else Toast(tostring(res), "error") end
            end)

            act("🗑", function()
                local ok, res = API("/admin/delete", { key = item.key }, true)
                if ok and res.success then Toast("Удалён", "success"); renderList()
                else Toast(tostring(res), "error") end
            end)
        end

        local loading = false

        renderList = function()
            if loading then return end
            loading = true

            for _, ch in ipairs(cardsWrap:GetChildren()) do
                if ch:IsA("GuiObject") then ch:Destroy() end
            end

            local search = string.lower(trim(searchBox.Text))
            local filter = STATE.filter

            local all = STATE.licenses or {}
            local shown = 0

            for _, item in ipairs(all) do
                local status = getStatus(item)
                local okF = (filter == "all") or (status == filter)
                local okS = true

                if search ~= "" then
                    local k = string.lower(item.key or "")
                    local u = string.lower(tostring(item.roblox_user_id or ""))
                    okS = (string.find(k, search, 1, true) ~= nil)
                       or (string.find(u, search, 1, true) ~= nil)
                end

                if okF and okS then
                    buildCard(item)
                    shown = shown + 1
                end
            end

            countLabel.Text = "Показано: " .. shown .. " из " .. #all
            loading = false
        end

        for id, btn in pairs(filterBtns) do
            btn.MouseButton1Click:Connect(function()
                STATE.filter = id
                for fid, fb in pairs(filterBtns) do
                    fb.BackgroundTransparency = (fid == id) and 0 or 0.55
                end
                renderList()
            end)
        end

        local rBtn, rLbl = Btn("🔄  ОБНОВИТЬ СПИСОК", scroll, C.Accent, function()
            rLbl.Text = "⏳  ЗАГРУЗКА..."
            task.spawn(function()
                local ok, result = API("/admin/list", {}, true)
                if ok then
                    STATE.licenses = result.keys or {}
                    renderList()
                    Toast("Загружено: " .. #STATE.licenses, "success")
                else
                    Toast(tostring(result), "error")
                end
                rLbl.Text = "🔄  ОБНОВИТЬ СПИСОК"
            end)
        end)
        rBtn.LayoutOrder = 5

        searchBox:GetPropertyChangedSignal("Text"):Connect(renderList)

        local backBtn = Btn("←  НАЗАД", scroll, C.Surf2, function() ShowScreen("main") end)
        backBtn.LayoutOrder = 6

        task.spawn(renderList)
    end,
}

-- Screen: SETTINGS =============================================

SCREENS.settings = {
    Build = function(root)
        local scroll = Scroll(root)

        local title = Label("⚙️  Настройки", 24, C.Text, scroll)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16

        Section("СЕРВЕР", scroll)

        local urlLabel = Label(CONFIG.SERVER_URL, 36, C.Dim, scroll, 3)
        urlLabel.Font = Enum.Font.Code
        urlLabel.TextSize = 10

        local pBtn, pLbl = Btn("🌐  ПРОВЕРИТЬ СВЯЗЬ", scroll, C.Surf2, function()
            pLbl.Text = "⏳  ПРОВЕРКА..."
            task.spawn(function()
                local t = os.clock()
                local ok = API("", nil, false)
                local ms = math.floor((os.clock() - t) * 1000)
                if ok then Toast("Онлайн • " .. ms .. " мс", "success")
                else Toast("Ошибка соединения", "error") end
                pLbl.Text = "🌐  ПРОВЕРИТЬ СВЯЗЬ"
            end)
        end)
        pBtn.LayoutOrder = 4

        Section("СЕССИЯ", scroll)

        Label(
            "Admin Secret хранится только в памяти текущей сессии.",
            40, C.Dim, scroll, 6
        )

        local outBtn = Btn("🔓  ВЫЙТИ ИЗ АККАУНТА", scroll, C.Red, function()
            STATE.adminSecret = ""
            STATE.authed = false
            STATE.licenses = {}
            Toast("Сессия завершена", "success")
            task.wait(0.3)
            ShowScreen("auth")
        end)
        outBtn.LayoutOrder = 7

        Section("О ПАНЕЛИ", scroll)

        local about1 = Label(CONFIG.NAME .. "  •  v" .. CONFIG.VERSION, 20, C.Text, scroll, 9)
        about1.Font = Enum.Font.GothamBold

        Label("Standalone License Admin Panel", 20, C.Muted, scroll, 10).TextSize = 10
        Label("Cloudflare Workers + D1", 20, C.Muted, scroll, 11).TextSize = 10

        local backBtn = Btn("←  НАЗАД", scroll, C.Surf2, function() ShowScreen("main") end)
        backBtn.LayoutOrder = 12
    end,
}

-- INIT ========================================================

ShowScreen("auth")

print("[RH-AUTH] v" .. CONFIG.VERSION .. " initialized")
print("[RH-AUTH] Server: " .. CONFIG.SERVER_URL)

-- [КОНЕЦ ЧАСТИ 3]
-- [[ КОНЕЦ ФАЙЛА ]]