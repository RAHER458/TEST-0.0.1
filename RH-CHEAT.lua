--[[
    RH-CHEAT
    Standalone RH menu UI
    Version: 1.0.1
    Visual layout based on the supplied RH reference.
    This file does not modify RH-SCRIPT.lua or LAUNCHER.lua.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local C = {
    bg = Color3.fromRGB(10, 13, 31),
    panel = Color3.fromRGB(19, 25, 52),
    card = Color3.fromRGB(29, 36, 76),
    card2 = Color3.fromRGB(36, 43, 88),
    purple = Color3.fromRGB(111, 45, 255),
    purple2 = Color3.fromRGB(153, 70, 255),
    blue = Color3.fromRGB(55, 183, 255),
    white = Color3.fromRGB(245, 245, 255),
    muted = Color3.fromRGB(169, 174, 220),
    border = Color3.fromRGB(64, 68, 139),
    off = Color3.fromRGB(53, 59, 94),
}

local old
pcall(function()
    old = (gethui and gethui():FindFirstChild("RH_CHEAT_UI")) or nil
end)
if not old then
    pcall(function() old = CoreGui:FindFirstChild("RH_CHEAT_UI") end)
end
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "RH_CHEAT_UI"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    if gethui then Gui.Parent = gethui() else Gui.Parent = CoreGui end
end)
if not Gui.Parent then Gui.Parent = PlayerGui end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, parent)
end

local function stroke(parent, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or C.border,
        Transparency = transparency or 0.35,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function gradient(parent, a, b, rotation)
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(1, b)
        }),
        Rotation = rotation or 0
    }, parent)
end

local function label(parent, text, size, pos, font, color)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or C.white,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = pos or UDim2.new(),
        Size = UDim2.new(1, 0, 0, 24)
    }, parent)
end

local function button(parent, text, size, pos, color)
    local b = make("TextButton", {
        AutoButtonColor = false,
        Text = text,
        TextColor3 = C.white,
        TextSize = 14,
        Font = Enum.Font.GothamSemibold,
        BackgroundColor3 = color or C.card,
        Size = size,
        Position = pos,
        BorderSizePixel = 0
    }, parent)
    corner(b, 12)
    stroke(b, C.border, 0.45, 1)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.card2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color or C.card}):Play()
    end)
    return b
end

local function notify(text)
    local toast = make("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -18),
        Size = UDim2.new(0, 260, 0, 38),
        BackgroundColor3 = C.card2,
        Text = text,
        TextColor3 = C.white,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        ZIndex = 20
    }, Gui)
    corner(toast, 10)
    stroke(toast, C.purple2, 0.2, 1)
    task.delay(2, function()
        if toast then
            TweenService:Create(toast, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            toast:Destroy()
        end
    end)
end

local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(900, 700)
local mobile = viewport.X < 650
local windowW = mobile and math.min(viewport.X - 12, 520) or 820
local windowH = mobile and math.min(viewport.Y - 54, 600) or 470

local Main = make("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(windowW, windowH),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, Gui)
corner(Main, 22)
stroke(Main, C.purple2, 0.08, 2)
gradient(Main, Color3.fromRGB(13, 17, 43), Color3.fromRGB(12, 15, 36), 25)

local SidebarW = mobile and 104 or 145
local Sidebar = make("Frame", {
    Size = UDim2.new(0, SidebarW, 1, 0),
    BackgroundColor3 = Color3.fromRGB(13, 18, 42),
    BorderSizePixel = 0
}, Main)
corner(Sidebar, 20)
make("Frame", {
    Position = UDim2.new(1, -1, 0, 12),
    Size = UDim2.new(0, 1, 1, -24),
    BackgroundColor3 = C.border,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0
}, Sidebar)

local Logo = make("Frame", {
    Position = UDim2.new(0.5, -39, 0, 15),
    Size = UDim2.fromOffset(78, 78),
    BackgroundColor3 = C.purple,
    BorderSizePixel = 0
}, Sidebar)
corner(Logo, 40)
gradient(Logo, C.purple2, C.blue, 35)
stroke(Logo, C.blue, 0.15, 2)
local crown = label(Logo, "♛", 21, UDim2.new(0.5, -11, 0, -15), Enum.Font.GothamBlack, Color3.fromRGB(255, 202, 92))
crown.Size = UDim2.fromOffset(24, 24)
crown.TextXAlignment = Enum.TextXAlignment.Center
local logoText = label(Logo, "RH", 31, UDim2.new(0, 0, 0, 0), Enum.Font.GothamBlack, C.white)
logoText.TextXAlignment = Enum.TextXAlignment.Center
logoText.Size = UDim2.fromScale(1, 1)

local navHolder = make("ScrollingFrame", {
    Position = UDim2.new(0, 9, 0, 108),
    Size = UDim2.new(1, -18, 1, -158),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = C.purple2,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Active = true
}, Sidebar)
make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, navHolder)

local footer = label(Sidebar, "♧ RH-SCRIPT\nv1.0.0", 12, UDim2.new(0, 16, 1, -45), Enum.Font.GothamBold, C.purple2)
footer.Size = UDim2.new(1, -22, 0, 38)
footer.TextYAlignment = Enum.TextYAlignment.Center

local Content = make("Frame", {
    Position = UDim2.new(0, SidebarW + 1, 0, 0),
    Size = UDim2.new(1, -SidebarW - 1, 1, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true
}, Main)

local Header = make("Frame", {
    Position = UDim2.new(0, 22, 0, 12),
    Size = UDim2.new(1, -44, 0, 58),
    BackgroundTransparency = 1
}, Content)
local headerIcon = label(Header, "⌂", 34, UDim2.new(0, 0, 0, 0), Enum.Font.GothamBold, C.purple2)
headerIcon.Size = UDim2.fromOffset(42, 42)
local headerTitle = label(Header, "Main", 26, UDim2.new(0, 48, 0, -1), Enum.Font.GothamBold)
headerTitle.Size = UDim2.new(1, -130, 0, 32)
local headerSub = label(Header, "Основные функции чита", 12, UDim2.new(0, 49, 0, 31), Enum.Font.Gotham, C.muted)
headerSub.Size = UDim2.new(1, -130, 0, 20)

local minimize = button(Content, "—", UDim2.fromOffset(38, 34), UDim2.new(1, -88, 0, 18), C.panel)
minimize.TextSize = 22
local close = button(Content, "×", UDim2.fromOffset(38, 34), UDim2.new(1, -43, 0, 18), C.panel)
close.TextSize = 24

local pageHolder = make("Frame", {
    Position = UDim2.new(0, 18, 0, 78),
    Size = UDim2.new(1, -36, 1, -92),
    BackgroundTransparency = 1,
    ClipsDescendants = true
}, Content)

local pages, navButtons = {}, {}
local activePage = "Main"
local function makePage(name)
    local p = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = C.purple2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Active = true
    }, pageHolder)
    make("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, p)
    pages[name] = p
    return p
end

local function addToggle(parent, title, desc, default, callback)
    local row = make("Frame", {
        Size = UDim2.new(1, -4, 0, 72),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0
    }, parent)
    corner(row, 14)
    stroke(row, C.border, 0.6, 1)
    local ico = make("Frame", {
        Position = UDim2.new(0, 10, 0.5, -24),
        Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = Color3.fromRGB(65, 34, 150),
        BorderSizePixel = 0
    }, row)
    corner(ico, 12)
    gradient(ico, Color3.fromRGB(91, 37, 208), Color3.fromRGB(51, 45, 145), 45)
    local glyphs = {ESP="⌖", ["ESP Boxes"]="◉", ["Player ESP"]="●", Tracers="◆", Aimbot="◎", ["Silent Aim"]="⊙", Hitbox="▣", ["Auto Shoot"]="ϟ", WalkSpeed="➤", ["Jump Power"]="↑", Fly="✈", Noclip="◇", Boxes="▣", Names="♙", Distance="↔", ["Anti AFK"]="◷", ["Full Bright"]="☼", ["Hide UI"]="◧", ["Show Notifications"]="♢", ["Compact Mode"]="▤", ["Remember Position"]="⌖"}
    local glyph = label(ico, glyphs[title] or "✦", 25, UDim2.new(0, 0, 0, 0), Enum.Font.GothamBold, C.white)
    glyph.Size = UDim2.fromScale(1, 1)
    glyph.TextXAlignment = Enum.TextXAlignment.Center
    local titleLabel = label(row, title, 14, UDim2.new(0, 70, 0, 13), Enum.Font.GothamSemibold)
    titleLabel.Size = UDim2.new(1, -145, 0, 22)
    local descLabel = label(row, desc, 11, UDim2.new(0, 70, 0, 36), Enum.Font.Gotham, C.muted)
    descLabel.Size = UDim2.new(1, -145, 0, 25)
    descLabel.TextWrapped = true
    local track = make("TextButton", {
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.new(1, -66, 0.5, -12),
        Size = UDim2.fromOffset(54, 25),
        BackgroundColor3 = default and C.purple or C.off,
        BorderSizePixel = 0
    }, row)
    corner(track, 20)
    local knob = make("Frame", {
        Position = default and UDim2.new(1, -22, 0, 3) or UDim2.new(0, 3, 0, 3),
        Size = UDim2.fromOffset(19, 19),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0
    }, track)
    corner(knob, 20)
    local state = default == true
    track.Activated:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.16), {BackgroundColor3 = state and C.purple or C.off}):Play()
        TweenService:Create(knob, TweenInfo.new(0.16), {Position = state and UDim2.new(1, -22, 0, 3) or UDim2.new(0, 3, 0, 3)}):Play()
        if callback then pcall(callback, state) end
    end)
    return row
end

local function addAction(parent, title, subtitle, icon, callback)
    local b = button(parent, icon .. "   " .. title .. "\n" .. subtitle,
        UDim2.new(1, -4, 0, 58), UDim2.new(), C.card)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextSize = 13
    b.TextWrapped = true
    b.Activated:Connect(callback)
    return b
end

local function section(parent, text)
    local t = label(parent, text, 16, UDim2.new(), Enum.Font.GothamBold)
    t.Size = UDim2.new(1, -4, 0, 26)
    return t
end

local function buildMain()
    local p = makePage("Main")
    local grid = make("Frame", {Size = UDim2.new(1, -4, 0, mobile and 318 or 154), BackgroundTransparency = 1}, p)
    local columns = 2
    local gridLayout = make("UIGridLayout", {
        CellSize = UDim2.new(0.5, -7, 0, mobile and 82 or 72),
        CellPadding = UDim2.fromOffset(10, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, grid)
    if mobile then grid.Size = UDim2.new(1, -4, 0, 174) end
    addToggle(grid, "ESP", "Показывает игроков и объекты", true)
    addToggle(grid, "ESP Boxes", "Рамки вокруг игроков", true)
    addToggle(grid, "Player ESP", "Информация о игроках", false)
    addToggle(grid, "Tracers", "Линии к игрокам", false)
    section(p, "🚀  Quick Actions")
    local actions = make("Frame", {Size = UDim2.new(1, -4, 0, mobile and 126 or 66), BackgroundTransparency = 1}, p)
    make("UIGridLayout", {
        CellSize = UDim2.new(mobile and 1/3 or 1/3, mobile and -7 or -8, 0, mobile and 58 or 62),
        CellPadding = UDim2.fromOffset(6, 7)
    }, actions)
    addAction(actions, "Reset Character", "Сброс персонажа", "ϟ", function()
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)
    addAction(actions, "Rejoin Server", "Перезаход на сервер", "⟲", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
    addAction(actions, "Server Hop", "Другой сервер", "⇧", function()
        notify("Server Hop: функция требует списка серверов")
    end)
    local banner = make("Frame", {
        Size = UDim2.new(1, -4, 0, 68),
        BackgroundColor3 = Color3.fromRGB(63, 27, 154),
        BorderSizePixel = 0
    }, p)
    corner(banner, 15)
    gradient(banner, Color3.fromRGB(86, 36, 195), Color3.fromRGB(27, 34, 89), 0)
    label(banner, "👑   RH-SCRIPT", 16, UDim2.new(0, 16, 0, 10), Enum.Font.GothamBold)
    label(banner, "Лучший чит для Roblox!", 11, UDim2.new(0, 18, 0, 37), Enum.Font.Gotham, C.muted)
    local made = button(banner, "♛  Made by RH", UDim2.new(0, 112, 0, 34), UDim2.new(1, -124, 0.5, -17), C.panel)
    made.TextSize = 11
end

local function buildSimple(name, subtitle, entries)
    local p = makePage(name)
    section(p, subtitle)
    for _, item in ipairs(entries) do
        if item[1] == "toggle" then
            addToggle(p, item[2], item[3], item[4] or false)
        else
            addAction(p, item[2], item[3], item[4] or "✦", function()
                notify(item[5] or "Раздел интерфейса готов")
            end)
        end
    end
end

buildMain()
buildSimple("Combat", "Combat  /  Боевые функции", {
    {"toggle", "Aimbot", "Настройки наведения", false},
    {"toggle", "Silent Aim", "Скрытое наведение", false},
    {"toggle", "Hitbox", "Настройка хитбоксов", false},
    {"toggle", "Auto Shoot", "Автоматическое действие", false},
})
buildSimple("Movement", "Movement  /  Передвижение", {
    {"toggle", "WalkSpeed", "Изменение скорости ходьбы", false},
    {"toggle", "Jump Power", "Изменение силы прыжка", false},
    {"toggle", "Fly", "Режим полёта", false},
    {"toggle", "Noclip", "Прохождение сквозь объекты", false},
})
buildSimple("Visuals", "Visuals  /  Визуальные настройки", {
    {"toggle", "ESP", "Отображение игроков", true},
    {"toggle", "Boxes", "Рамки вокруг персонажей", true},
    {"toggle", "Names", "Имена игроков", false},
    {"toggle", "Distance", "Дистанция до игроков", false},
    {"toggle", "Tracers", "Линии до игроков", false},
})
buildSimple("Misc", "Misc  /  Дополнительно", {
    {"toggle", "Anti AFK", "Защита от бездействия", false},
    {"toggle", "Full Bright", "Повышенная яркость", false},
    {"toggle", "Hide UI", "Скрывать интерфейс", false},
})
buildSimple("Settings", "Settings  /  Настройки", {
    {"toggle", "Show Notifications", "Уведомления интерфейса", true},
    {"toggle", "Compact Mode", "Компактный режим", false},
    {"toggle", "Remember Position", "Запоминать расположение", true},
})
buildSimple("About", "About  /  О проекте", {
    {"action", "RH-CHEAT", "Версия интерфейса 1.0.0", "👑", "RH-CHEAT • Made by RH"},
    {"action", "Telegram", "Новости и обновления проекта", "✈", "Откройте канал RH-LAUNCHER"},
})

local navItems = {
    {"Main", "⌂", "Main"},
    {"Combat", "ϟ", "Combat"},
    {"Movement", "◇", "Movement"},
    {"Visuals", "⚙", "Visuals"},
    {"Misc", "🔧", "Misc"},
    {"Settings", "★", "Settings"},
    {"About", "ⓘ", "About"},
}
local function showPage(name)
    activePage = name
    for n, page in pairs(pages) do page.Visible = n == name end
    for n, b in pairs(navButtons) do
        local selected = n == name
        b.BackgroundColor3 = selected and C.purple or Color3.fromRGB(13, 18, 42)
        b.TextColor3 = selected and C.white or C.muted
        if b:FindFirstChildOfClass("UIStroke") then
            b:FindFirstChildOfClass("UIStroke").Transparency = selected and 0.1 or 1
        end
    end
    local icons = {Main="⌂", Combat="ϟ", Movement="◇", Visuals="⚙", Misc="🔧", Settings="★", About="ⓘ"}
    local subs = {
        Main="Основные функции чита", Combat="Боевые функции",
        Movement="Настройки передвижения", Visuals="Визуальные настройки",
        Misc="Дополнительные функции", Settings="Настройки интерфейса",
        About="Информация о проекте"
    }
    headerIcon.Text = icons[name] or "✦"
    headerTitle.Text = name
    headerSub.Text = subs[name] or ""
end

for i, item in ipairs(navItems) do
    local b = make("TextButton", {
        Name = item[1],
        LayoutOrder = i,
        Size = UDim2.new(1, 0, 0, 43),
        BackgroundColor3 = item[1] == "Main" and C.purple or Color3.fromRGB(13, 18, 42),
        Text = item[2] .. "   " .. item[3],
        TextColor3 = item[1] == "Main" and C.white or C.muted,
        TextSize = mobile and 11 or 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        BorderSizePixel = 0
    }, navHolder)
    corner(b, 11)
    local s = stroke(b, C.purple2, item[1] == "Main" and 0.1 or 1, 1)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, b)
    b.Activated:Connect(function() showPage(item[1]) end)
    navButtons[item[1]] = b
end

showPage("Main")

-- Drag the window from its header.
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local minimized = false
local bubble = button(Gui, "RH", UDim2.fromOffset(52, 52), UDim2.new(1, -68, 0.72, 0), C.purple)
bubble.Visible = false
bubble.TextSize = 18
bubble.Font = Enum.Font.GothamBlack
gradient(bubble, C.purple2, C.blue, 45)
minimize.Activated:Connect(function()
    minimized = true
    Main.Visible = false
    bubble.Visible = true
end)
bubble.Activated:Connect(function()
    minimized = false
    Main.Visible = true
    bubble.Visible = false
end)
close.Activated:Connect(function()
    Gui:Destroy()
end)

notify("RH-CHEAT загружен")
