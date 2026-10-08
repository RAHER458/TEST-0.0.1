--[[
    RAHERHUB V0.1 💗
    Modern Mobile Interface
    No activation password
]]

if getgenv and getgenv().RAHERHUB_LOADED then
    warn("RAHERHUB is already running!")
    return
end

if getgenv then
    getgenv().RAHERHUB_LOADED = true
end

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local VERSION = "V0.1"

local COLORS = {
    Background = Color3.fromRGB(12, 13, 20),
    Panel = Color3.fromRGB(20, 22, 33),
    PanelLight = Color3.fromRGB(29, 32, 46),
    Border = Color3.fromRGB(48, 52, 70),
    Text = Color3.fromRGB(240, 242, 255),
    Muted = Color3.fromRGB(140, 146, 168),
    Accent = Color3.fromRGB(157, 91, 255),
    Accent2 = Color3.fromRGB(64, 190, 255),
    Green = Color3.fromRGB(74, 224, 151),
    Red = Color3.fromRGB(255, 89, 115),
}

local ACCENT_GRADIENT = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COLORS.Accent),
    ColorSequenceKeypoint.new(1, COLORS.Accent2)
})

--==================================================
-- STATE
--==================================================

local State = {
    ESP = false,
    Noclip = false,
    Speed = false,
    SpeedValue = 32,

    Fly = false,
    FlyHolding = false,
    FlyMoveMode = false,

    Points = {},
    NextPointId = 0,

    CurrentTab = "MAIN",
    WindowOpen = true,
    Destroyed = false,
}

local ESPObjects = {}
local SavedCollision = {}

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- GUI HELPERS
--==================================================

local function create(className, properties, parent)
    local obj = Instance.new(className)

    for property, value in pairs(properties or {}) do
        obj[property] = value
    end

    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 10)
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function padding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function tween(object, properties, duration)
    local info = TweenInfo.new(
        duration or 0.2,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )

    local animation = TweenService:Create(object, info, properties)
    animation:Play()

    return animation
end

local function makeLabel(parent, text, size, position, textSize, color)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        Size = size,
        Position = position,
        Font = Enum.Font.Gotham,
        TextSize = textSize or 13,
        TextColor3 = color or COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local function makeButton(parent, text, size, position)
    local button = create("TextButton", {
        AutoButtonColor = false,
        Text = text,
        Size = size,
        Position = position,
        BackgroundColor3 = COLORS.PanelLight,
        TextColor3 = COLORS.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
    }, parent)

    corner(button, 9)
    stroke(button, COLORS.Border, 1)

    button.MouseEnter:Connect(function()
        tween(button, {
            BackgroundColor3 = Color3.fromRGB(39, 42, 59)
        }, 0.12)
    end)

    button.MouseLeave:Connect(function()
        tween(button, {
            BackgroundColor3 = COLORS.PanelLight
        }, 0.12)
    end)

    return button
end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = create("ScreenGui", {
    Name = "RAHERHUB_V01",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, nil)

local guiParent

pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)

if not guiParent then
    guiParent = CoreGui
end

local parentSuccess = pcall(function()
    ScreenGui.Parent = guiParent
end)

if not parentSuccess then
    ScreenGui.Parent = PlayerGui
end

--==================================================
-- RGB LOGO
--==================================================

local function makeRGBLogo(parent, position, size, textSize)
    local holder = create("Frame", {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
    }, parent)

    local layout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    }, holder)

    local letters = {}
    local title = "RAHERHUB"

    for i = 1, #title do
        local character = title:sub(i, i)

        local label = create("TextLabel", {
            BackgroundTransparency = 1,
            Text = character,
            Font = Enum.Font.GothamBlack,
            TextSize = textSize or 24,
            TextColor3 = Color3.new(1, 1, 1),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            LayoutOrder = i,
        }, holder)

        table.insert(letters, {
            Label = label,
            Offset = i / #title,
        })
    end

    task.spawn(function()
        while holder.Parent and not State.Destroyed do
            local timeNow = os.clock()

            for _, item in ipairs(letters) do
                local hue = (timeNow * 0.18 + item.Offset) % 1

                item.Label.TextColor3 = Color3.fromHSV(
                    hue,
                    0.75,
                    1
                )
            end

            RunService.RenderStepped:Wait()
        end
    end)

    return holder
end

--==================================================
-- LOADING SCREEN
--==================================================

local Loading = create("Frame", {
    Name = "LoadingScreen",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    ZIndex = 100,
}, ScreenGui)

local backgroundGradient = create("UIGradient", {
    Rotation = 35,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 11, 21)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 17, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 20, 32)),
    }),
}, Loading)

local orb1 = create("Frame", {
    Size = UDim2.fromOffset(250, 250),
    Position = UDim2.new(0.5, -125, 0.5, -180),
    BackgroundColor3 = COLORS.Accent,
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
    ZIndex = 101,
}, Loading)
corner(orb1, 125)

local orb2 = create("Frame", {
    Size = UDim2.fromOffset(200, 200),
    Position = UDim2.new(0.5, -100, 0.5, 25),
    BackgroundColor3 = COLORS.Accent2,
    BackgroundTransparency = 0.91,
    BorderSizePixel = 0,
    ZIndex = 101,
}, Loading)
corner(orb2, 100)

local loadingCard = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.88, 0, 0, 270),
    BackgroundColor3 = Color3.fromRGB(16, 18, 29),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ZIndex = 102,
}, Loading)

create("UISizeConstraint", {
    MinSize = Vector2.new(260, 270),
    MaxSize = Vector2.new(390, 270),
}, loadingCard)

corner(loadingCard, 20)
stroke(loadingCard, Color3.fromRGB(93, 76, 145), 1, 0.2)

makeRGBLogo(
    loadingCard,
    UDim2.new(0, 0, 0, 25),
    UDim2.new(1, 0, 0, 45),
    28
)

local loadingVersion = makeLabel(
    loadingCard,
    VERSION .. "  |  ALPHA",
    UDim2.new(1, 0, 0, 20),
    UDim2.new(0, 0, 0, 73),
    11,
    COLORS.Muted
)
loadingVersion.TextXAlignment = Enum.TextXAlignment.Center

local loadingStatus = makeLabel(
    loadingCard,
    "Initializing interface...",
    UDim2.new(1, -36, 0, 32),
    UDim2.new(0, 18, 0, 119),
    13,
    COLORS.Text
)
loadingStatus.TextXAlignment = Enum.TextXAlignment.Center

local percentLabel = makeLabel(
    loadingCard,
    "0%",
    UDim2.new(1, -36, 0, 22),
    UDim2.new(0, 18, 0, 157),
    12,
    COLORS.Accent2
)
percentLabel.TextXAlignment = Enum.TextXAlignment.Right

local barBack = create("Frame", {
    Position = UDim2.new(0, 18, 0, 187),
    Size = UDim2.new(1, -36, 0, 8),
    BackgroundColor3 = Color3.fromRGB(37, 39, 54),
    BorderSizePixel = 0,
}, loadingCard)
corner(barBack, 5)

local barFill = create("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,
}, barBack)
corner(barFill, 5)

create("UIGradient", {
    Color = ACCENT_GRADIENT,
}, barFill)

local loadingFooter = makeLabel(
    loadingCard,
    "RAHERHUB  •  MOBILE INTERFACE",
    UDim2.new(1, -30, 0, 22),
    UDim2.new(0, 15, 1, -32),
    9,
    COLORS.Muted
)
loadingFooter.TextXAlignment = Enum.TextXAlignment.Center

local loadingStages = {
    {0.15, "Initializing interface..."},
    {0.32, "Preparing visual modules..."},
    {0.50, "Loading movement controls..."},
    {0.68, "Preparing teleport panel..."},
    {0.85, "Finishing setup..."},
    {1.00, "Ready!"},
}

task.spawn(function()
    local duration = 5
    local startTime = os.clock()
    local stageIndex = 1

    while true do
        local elapsed = os.clock() - startTime
        local progress = math.clamp(elapsed / duration, 0, 1)

        tween(barFill, {
            Size = UDim2.new(progress, 0, 1, 0)
        }, 0.08)

        percentLabel.Text = tostring(math.floor(progress * 100)) .. "%"

        if stageIndex < #loadingStages then
            if progress >= loadingStages[stageIndex][1] then
                stageIndex += 1
            end
        end

        loadingStatus.Text = loadingStages[stageIndex][2]

        if progress >= 1 then
            break
        end

        RunService.RenderStepped:Wait()
    end

    task.wait(0.25)

    tween(loadingCard, {
        BackgroundTransparency = 1,
    }, 0.3)

    tween(Loading, {
        BackgroundTransparency = 1,
    }, 0.4)

    tween(orb1, {
        BackgroundTransparency = 1,
    }, 0.3)

    tween(orb2, {
        BackgroundTransparency = 1,
    }, 0.3)

    task.wait(0.45)

    if Loading then
        Loading:Destroy()
    end
end)

--==================================================
-- MAIN WINDOW
--==================================================

local Window = create("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.92, 0, 0.78, 0),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    Visible = false,
    ClipsDescendants = true,
}, ScreenGui)

create("UISizeConstraint", {
    MinSize = Vector2.new(290, 360),
    MaxSize = Vector2.new(470, 650),
}, Window)

corner(Window, 16)
stroke(Window, COLORS.Border, 1)

local windowScale = create("UIScale", {
    Scale = 1,
}, Window)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    if viewport.X < 500 then
        windowScale.Scale = 0.95
    else
        windowScale.Scale = 1
    end
end

updateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

--==================================================
-- TITLE BAR
--==================================================

local TitleBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, Window)

local titleAccent = create("Frame", {
    Position = UDim2.new(0, 0, 1, -2),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,
}, TitleBar)

create("UIGradient", {
    Color = ACCENT_GRADIENT,
}, titleAccent)

makeRGBLogo(
    TitleBar,
    UDim2.new(0, 12, 0, 5),
    UDim2.new(0, 185, 0, 30),
    21
)

local versionBadge = create("TextLabel", {
    Position = UDim2.new(0, 14, 0, 35),
    Size = UDim2.new(0, 65, 0, 16),
    BackgroundColor3 = COLORS.PanelLight,
    Text = VERSION,
    TextColor3 = COLORS.Accent2,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
}, TitleBar)
corner(versionBadge, 5)

local closeButton = makeButton(
    TitleBar,
    "×",
    UDim2.new(0, 34, 0, 34),
    UDim2.new(1, -44, 0, 13)
)
closeButton.TextSize = 24
closeButton.BackgroundColor3 = Color3.fromRGB(45, 28, 43)
closeButton.TextColor3 = COLORS.Red

--==================================================
-- WINDOW DRAGGING
--==================================================

local dragging = false
local dragStart
local startPosition
local dragInput

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Window.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input == dragInput
        or input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        Window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- NAVIGATION
--==================================================

local Body = create("Frame", {
    Position = UDim2.new(0, 0, 0, 60),
    Size = UDim2.new(1, 0, 1, -60),
    BackgroundTransparency = 1,
}, Window)

local Sidebar = create("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(0, 112, 1, 0),
    BackgroundColor3 = Color3.fromRGB(16, 18, 27),
    BorderSizePixel = 0,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = COLORS.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Body)

padding(Sidebar, 7, 7, 10, 10)

local sidebarLayout = create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)

local Content = create("Frame", {
    Position = UDim2.new(0, 112, 0, 0),
    Size = UDim2.new(1, -112, 1, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, Body)

local PageHeader = makeLabel(
    Content,
    "MAIN",
    UDim2.new(1, -20, 0, 32),
    UDim2.new(0, 12, 0, 8),
    17,
    COLORS.Text
)
PageHeader.Font = Enum.Font.GothamBold

local PageSubtitle = makeLabel(
    Content,
    "Welcome to RAHERHUB",
    UDim2.new(1, -20, 0, 22),
    UDim2.new(0, 12, 0, 36),
    10,
    COLORS.Muted
)

local PageContainer = create("ScrollingFrame", {
    Position = UDim2.new(0, 8, 0, 65),
    Size = UDim2.new(1, -16, 1, -73),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Content)

padding(PageContainer, 1, 5, 0, 10)

local pageLayout = create("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, PageContainer)

local pages = {}
local tabButtons = {}

local tabInfo = {
    {
        Name = "MAIN",
        Icon = "⌂",
        Subtitle = "Welcome to RAHERHUB",
    },
    {
        Name = "VISUALS",
        Icon = "◉",
        Subtitle = "Visual options",
    },
    {
        Name = "MOVEMENT",
        Icon = "➤",
        Subtitle = "Movement controls",
    },
    {
        Name = "FLY",
        Icon = "↑",
        Subtitle = "Flight controls",
    },
    {
        Name = "TELEPORT",
        Icon = "⌖",
        Subtitle = "Saved locations",
    },
    {
        Name = "EXPLOITS",
        Icon = "⚡",
        Subtitle = "Experimental modules",
    },
    {
        Name = "SETTINGS",
        Icon = "⚙",
        Subtitle = "Interface settings",
    },
    {
        Name = "UPDATES",
        Icon = "♡",
        Subtitle = "What's new",
    },
}

for _, tab in ipairs(tabInfo) do
    local page = create("Frame", {
        Name = tab.Name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, PageContainer)

    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)

    pages[tab.Name] = page

    local button = create("TextButton", {
        Name = tab.Name .. "Button",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = COLORS.Panel,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #tabButtons + 1,
    }, Sidebar)

    corner(button, 9)

    local icon = makeLabel(
        button,
        tab.Icon,
        UDim2.new(0, 25, 1, 0),
        UDim2.new(0, 5, 0, 0),
        16,
        COLORS.Muted
    )
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local name = makeLabel(
        button,
        tab.Name,
        UDim2.new(1, -32, 1, 0),
        UDim2.new(0, 32, 0, 0),
        9,
        COLORS.Muted
    )
    name.Font = Enum.Font.GothamBold

    tabButtons[tab.Name] = {
        Button = button,
        Icon = icon,
        Label = name,
    }

    button.MouseButton1Click:Connect(function()
        State.CurrentTab = tab.Name

        PageHeader.Text = tab.Name
        PageSubtitle.Text = tab.Subtitle

        for pageName, pageObject in pairs(pages) do
            pageObject.Visible = pageName == tab.Name
        end

        for buttonName, item in pairs(tabButtons) do
            local selected = buttonName == tab.Name

            tween(item.Button, {
                BackgroundColor3 = selected
                    and Color3.fromRGB(46, 36, 72)
                    or COLORS.Panel
            }, 0.15)

            item.Icon.TextColor3 = selected and COLORS.Accent2 or COLORS.Muted
            item.Label.TextColor3 = selected and COLORS.Text or COLORS.Muted
        end

        PageContainer.CanvasPosition = Vector2.zero
    end)
end

local function openTab(name)
    local item = tabButtons[name]
    if item then
        item.Button:Activate()
        -- Explicitly select the page for environments where Activate
        -- does not fire MouseButton1Click.
        State.CurrentTab = name
        PageHeader.Text = name

        for pageName, page in pairs(pages) do
            page.Visible = pageName == name
        end

        for buttonName, tab in pairs(tabButtons) do
            local selected = buttonName == name

            tab.Button.BackgroundColor3 = selected
                and Color3.fromRGB(46, 36, 72)
                or COLORS.Panel

            tab.Icon.TextColor3 = selected and COLORS.Accent2 or COLORS.Muted
            tab.Label.TextColor3 = selected and COLORS.Text or COLORS.Muted
        end

        for _, tab in ipairs(tabInfo) do
            if tab.Name == name then
                PageSubtitle.Text = tab.Subtitle
                break
            end
        end
    end
end

--==================================================
-- CARD / ROW HELPERS
--==================================================

local function makeCard(parent, height, title, subtitle)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, parent)

    corner(card, 11)
    stroke(card, COLORS.Border, 1)

    local titleLabel = makeLabel(
        card,
        title,
        UDim2.new(1, -22, 0, 24),
        UDim2.new(0, 11, 0, 8),
        13,
        COLORS.Text
    )
    titleLabel.Font = Enum.Font.GothamBold

    if subtitle then
        makeLabel(
            card,
            subtitle,
            UDim2.new(1, -22, 0, 30),
            UDim2.new(0, 11, 0, 31),
            10,
            COLORS.Muted
        )
    end

    return card
end

local function makeToggle(parent, title, description, defaultValue, callback)
    local card = makeCard(parent, 66, title, description)

    local toggle = create("TextButton", {
        Size = UDim2.new(0, 42, 0, 24),
        Position = UDim2.new(1, -53, 0.5, -12),
        BackgroundColor3 = defaultValue and COLORS.Accent or COLORS.PanelLight,
        Text = "",
        AutoButtonColor = false,
    }, card)
    corner(toggle, 12)

    local knob = create("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = defaultValue
            and UDim2.new(1, -21, 0.5, -9)
            or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, toggle)
    corner(knob, 9)

    local enabled = defaultValue

    local function setEnabled(value)
        enabled = value

        tween(toggle, {
            BackgroundColor3 = enabled and COLORS.Accent or COLORS.PanelLight
        }, 0.15)

        tween(knob, {
            Position = enabled
                and UDim2.new(1, -21, 0.5, -9)
                or UDim2.new(0, 3, 0.5, -9)
        }, 0.15)

        callback(enabled)
    end

    toggle.MouseButton1Click:Connect(function()
        setEnabled(not enabled)
    end)

    return {
        Set = setEnabled,
        Get = function()
            return enabled
        end,
        Button = toggle,
    }
end

local function makeAction(parent, title, description, buttonText, callback)
    local card = makeCard(parent, 75, title, description)

    local button = makeButton(
        card,
        buttonText,
        UDim2.new(0, 82, 0, 32),
        UDim2.new(1, -94, 0.5, -16)
    )

    button.MouseButton1Click:Connect(callback)

    return card, button
end

--==================================================
-- ESP
--==================================================

local function removeESP(player)
    local highlight = ESPObjects[player]

    if highlight then
        highlight:Destroy()
        ESPObjects[player] = nil
    end
end

local function addESP(player)
    if player == LocalPlayer or not State.ESP then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    removeESP(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "RAHERHUB_ESP"
    highlight.Adornee = character
    highlight.FillColor = COLORS.Accent
    highlight.OutlineColor = COLORS.Accent2
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    ESPObjects[player] = highlight
end

local function setESP(enabled)
    State.ESP = enabled

    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            addESP(player)
        end
    else
        for player in pairs(ESPObjects) do
            removeESP(player)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if State.ESP then
            addESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if State.ESP then
                addESP(player)
            end
        end)
    end
end

--==================================================
-- SPEED
--==================================================

local function applySpeed()
    local humanoid = getHumanoid()

    if not humanoid then
        return
    end

    if State.Speed then
        humanoid.WalkSpeed = State.SpeedValue
    else
        humanoid.WalkSpeed = 16
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

--==================================================
-- NOCLIP
--==================================================

local function setNoclip(enabled)
    State.Noclip = enabled

    if not enabled then
        for part, originalValue in pairs(SavedCollision) do
            if part and part.Parent then
                part.CanCollide = originalValue
            end
        end

        table.clear(SavedCollision)
    end
end

RunService.Stepped:Connect(function()
    if not State.Noclip then
        return
    end

    local character = getCharacter()
    if not character then
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if SavedCollision[part] == nil then
                SavedCollision[part] = part.CanCollide
            end

            part.CanCollide = false
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    table.clear(SavedCollision)
end)

--==================================================
-- FLY JUMP CONTROL
--==================================================

local FlyButton = create("TextButton", {
    Name = "RAHERHUB_FlyButton",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.83, 0, 0.72, 0),
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = COLORS.Accent,
    Text = "↑",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBlack,
    TextSize = 27,
    Visible = false,
    AutoButtonColor = false,
    ZIndex = 20,
}, ScreenGui)

corner(FlyButton, 29)
stroke(FlyButton, COLORS.Accent2, 2)

create("UIGradient", {
    Color = ACCENT_GRADIENT,
    Rotation = 45,
}, FlyButton)

local flyDrag = false
local flyDragStart
local flyStartPosition
local flyMoved = false

FlyButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        flyDrag = true
        flyMoved = false
        flyDragStart = input.Position
        flyStartPosition = FlyButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                flyDrag = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if flyDrag and State.FlyMoveMode then
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then

            local delta = input.Position - flyDragStart

            if delta.Magnitude > 5 then
                flyMoved = true
            end

            FlyButton.Position = UDim2.new(
                flyStartPosition.X.Scale,
                flyStartPosition.X.Offset + delta.X,
                flyStartPosition.Y.Scale,
                flyStartPosition.Y.Offset + delta.Y
            )
        end
    end
end)

FlyButton.Activated:Connect(function()
    if flyMoved then
        return
    end

    if not State.Fly then
        return
    end

    State.FlyHolding = true

    task.delay(0.18, function()
        if State.FlyHolding then
            local humanoid = getHumanoid()

            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.FlyHolding = false
    end
end)

RunService.Heartbeat:Connect(function()
    if not State.Fly or not State.FlyHolding then
        return
    end

    local root = getRoot()
    if not root then
        return
    end

    local velocity = root.AssemblyLinearVelocity

    root.AssemblyLinearVelocity = Vector3.new(
        velocity.X,
        45,
        velocity.Z
    )
end)

local function setFly(enabled)
    State.Fly = enabled
    State.FlyHolding = false
    FlyButton.Visible = enabled

    tween(FlyButton, {
        BackgroundTransparency = enabled and 0 or 1
    }, 0.15)
end

--==================================================
-- TELEPORT POINTS
--==================================================

local function teleportToPoint(point)
    local root = getRoot()

    if not root or not point or not point.CFrame then
        return
    end

    root.CFrame = point.CFrame + Vector3.new(0, 3, 0)
end

local function makePointCard(parent, point)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, parent)

    corner(card, 10)
    stroke(card, COLORS.Border, 1)

    local nameLabel = makeLabel(
        card,
        point.Name,
        UDim2.new(1, -110, 0, 24),
        UDim2.new(0, 10, 0, 7),
        12,
        COLORS.Text
    )
    nameLabel.Font = Enum.Font.GothamBold

    makeLabel(
        card,
        string.format(
            "X: %.1f   Y: %.1f   Z: %.1f",
            point.CFrame.Position.X,
            point.CFrame.Position.Y,
            point.CFrame.Position.Z
        ),
        UDim2.new(1, -110, 0, 20),
        UDim2.new(0, 10, 0, 33),
        9,
        COLORS.Muted
    )

    local goButton = makeButton(
        card,
        "GO",
        UDim2.new(0, 43, 0, 29),
        UDim2.new(1, -98, 0, 9)
    )

    goButton.BackgroundColor3 = Color3.fromRGB(42, 34, 68)

    local deleteButton = makeButton(
        card,
        "×",
        UDim2.new(0, 35, 0, 29),
        UDim2.new(1, -46, 0, 9)
    )
    deleteButton.TextColor3 = COLORS.Red
    deleteButton.TextSize = 20

    goButton.MouseButton1Click:Connect(function()
        teleportToPoint(point)
    end)

    deleteButton.MouseButton1Click:Connect(function()
        for index, existing in ipairs(State.Points) do
            if existing.Id == point.Id then
                table.remove(State.Points, index)
                break
            end
        end

        card:Destroy()
    end)

    return card
end

local function refreshPointList(list)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    for _, point in ipairs(State.Points) do
        makePointCard(list, point)
    end
end

--==================================================
-- MAIN PAGE
--==================================================

do
    local page = pages.MAIN

    local hero = makeCard(
        page,
        105,
        "Welcome back!",
        "Your personal hub is ready."
    )

    local heroVersion = makeLabel(
        hero,
        "RAHERHUB " .. VERSION .. "  💗",
        UDim2.new(1, -22, 0, 25),
        UDim2.new(0, 11, 1, -34),
        12,
        COLORS.Accent2
    )
    heroVersion.Font = Enum.Font.GothamBold

    local statusCard = makeCard(
        page,
        82,
        "SYSTEM STATUS",
        "Interface initialized successfully."
    )

    local status = makeLabel(
        statusCard,
        "● ONLINE",
        UDim2.new(1, -22, 0, 20),
        UDim2.new(0, 11, 1, -28),
        11,
        COLORS.Green
    )
    status.Font = Enum.Font.GothamBold

    makeAction(
        page,
        "VISUALS",
        "Configure visual modules.",
        "OPEN",
        function()
            openTab("VISUALS")
        end
    )

    makeAction(
        page,
        "MOVEMENT",
        "Speed and noclip controls.",
        "OPEN",
        function()
            openTab("MOVEMENT")
        end
    )

    makeAction(
        page,
        "TELEPORT",
        "Manage your saved locations.",
        "OPEN",
        function()
            openTab("TELEPORT")
        end
    )
end

--==================================================
-- VISUALS PAGE
--==================================================

do
    local page = pages.VISUALS

    makeToggle(
        page,
        "PLAYER ESP",
        "Highlight other players.",
        false,
        function(enabled)
            setESP(enabled)
        end
    )

    makeCard(
        page,
        82,
        "ESP INFORMATION",
        "Uses Roblox Highlight objects. Visibility and behavior may depend on the game."
    )
end

--==================================================
-- MOVEMENT PAGE
--==================================================

do
    local page = pages.MOVEMENT

    makeToggle(
        page,
        "SPEED",
        "Change your local WalkSpeed.",
        false,
        function(enabled)
            State.Speed = enabled
            applySpeed()
        end
    )

    local speedCard = makeCard(
        page,
        106,
        "SPEED VALUE",
        "Choose a value from 16 to 1000."
    )

    local speedValueLabel = makeLabel(
        speedCard,
        tostring(State.SpeedValue),
        UDim2.new(0, 70, 0, 22),
        UDim2.new(1, -82, 0, 8),
        14,
        COLORS.Accent2
    )
    speedValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    speedValueLabel.Font = Enum.Font.GothamBold

    local sliderBack = create("Frame", {
        Position = UDim2.new(0, 12, 0, 61),
        Size = UDim2.new(1, -24, 0, 8),
        BackgroundColor3 = COLORS.PanelLight,
        BorderSizePixel = 0,
    }, speedCard)
    corner(sliderBack, 5)

    local sliderFill = create("Frame", {
        Size = UDim2.new(
            (State.SpeedValue - 16) / (1000 - 16),
            0,
            1,
            0
        ),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, sliderBack)
    corner(sliderFill, 5)

    create("UIGradient", {
        Color = ACCENT_GRADIENT,
    }, sliderFill)

    local sliderKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(
            (State.SpeedValue - 16) / (1000 - 16),
            0,
            0.5,
            0
        ),
        Size = UDim2.fromOffset(17, 17),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, sliderBack)
    corner(sliderKnob, 9)
    stroke(sliderKnob, COLORS.Accent, 2)

    local sliderButton = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, -12),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, sliderBack)

    local sliderDragging = false

    local function updateSpeedSlider(input)
        local width = sliderBack.AbsoluteSize.X
        if width <= 0 then
            return
        end

        local x = input.Position.X - sliderBack.AbsolutePosition.X
        local alpha = math.clamp(x / width, 0, 1)

        State.SpeedValue = math.floor(16 + alpha * (1000 - 16))
        speedValueLabel.Text = tostring(State.SpeedValue)

        sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
        sliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)

        if State.Speed then
            applySpeed()
        end
    end

    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            sliderDragging = true
            updateSpeedSlider(input)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if sliderDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            updateSpeedSlider(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = false
        end
    end)

    makeToggle(
        page,
        "NOCLIP",
        "Disable character part collisions locally.",
        false,
        function(enabled)
            setNoclip(enabled)
        end
    )
end

--==================================================
-- FLY PAGE
--==================================================

do
    local page = pages.FLY

    makeToggle(
        page,
        "FLY JUMP",
        "Hold the floating arrow to move upward.",
        false,
        function(enabled)
            setFly(enabled)
        end
    )

    makeToggle(
        page,
        "MOVE BUTTON MODE",
        "Drag the floating button to reposition it.",
        false,
        function(enabled)
            State.FlyMoveMode = enabled
        end
    )

    makeAction(
        page,
        "BUTTON SIZE",
        "Increase the floating button size.",
        "+",
        function()
            FlyButton.Size = UDim2.fromOffset(
                math.clamp(FlyButton.AbsoluteSize.X + 5, 40, 100),
                math.clamp(FlyButton.AbsoluteSize.Y + 5, 40, 100)
            )
        end
    )

    makeAction(
        page,
        "BUTTON SIZE",
        "Decrease the floating button size.",
        "−",
        function()
            FlyButton.Size = UDim2.fromOffset(
                math.clamp(FlyButton.AbsoluteSize.X - 5, 40, 100),
                math.clamp(FlyButton.AbsoluteSize.Y - 5, 40, 100)
            )
        end
    )

    makeAction(
        page,
        "BUTTON POSITION",
        "Return the arrow to its default location.",
        "RESET",
        function()
            FlyButton.Position = UDim2.new(0.83, 0, 0.72, 0)
        end
    )

    makeCard(
        page,
        80,
        "HOW TO USE",
        "Enable FLY JUMP, then hold the floating arrow. This is an upward-jump control, not a full directional flight system."
    )
end

--==================================================
-- TELEPORT PAGE
--==================================================

do
    local page = pages.TELEPORT

    local createCard = makeCard(
        page,
        120,
        "CREATE LOCATION",
        "Save your current position for this session."
    )

    local pointNameBox = create("TextBox", {
        Position = UDim2.new(0, 10, 0, 65),
        Size = UDim2.new(0.57, -8, 0, 34),
        BackgroundColor3 = COLORS.PanelLight,
        Text = "",
        PlaceholderText = "Location name",
        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        ClearTextOnFocus = false,
    }, createCard)
    corner(pointNameBox, 8)
    stroke(pointNameBox, COLORS.Border, 1)

    local savePointButton = makeButton(
        createCard,
        "SAVE POINT",
        UDim2.new(0.43, -8, 0, 34),
        UDim2.new(0.57, 0, 0, 65)
    )
    savePointButton.BackgroundColor3 = Color3.fromRGB(43, 34, 70)

    local pointList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, page)

    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, pointList)

    savePointButton.MouseButton1Click:Connect(function()
        local root = getRoot()

        if not root then
            pointNameBox.PlaceholderText = "Character not ready"
            return
        end

        State.NextPointId += 1

        local name = pointNameBox.Text
        if name == "" then
            name = "Location " .. tostring(State.NextPointId)
        end

        local point = {
            Id = State.NextPointId,
            Name = name,
            CFrame = root.CFrame,
        }

        table.insert(State.Points, point)

        pointNameBox.Text = ""
        refreshPointList(pointList)
    end)

    local emptyState = makeCard(
        page,
        70,
        "SAVED LOCATIONS",
        "Create a point to see it here."
    )

    local function updateEmptyState()
        emptyState.Visible = #State.Points == 0
    end

    savePointButton.MouseButton1Click:Connect(function()
        task.defer(updateEmptyState)
    end)

    local originalRefresh = refreshPointList

    refreshPointList = function(list)
        originalRefresh(list)
        updateEmptyState()
    end
end

--==================================================
-- EXPLOITS PAGE
--==================================================

do
    local page = pages.EXPLOITS

    local card = makeCard(
        page,
        110,
        "EXPERIMENTAL MODULES",
        "New experimental options will appear here in future versions."
    )

    local badge = makeLabel(
        card,
        "COMING SOON  ♡",
        UDim2.new(1, -22, 0, 24),
        UDim2.new(0, 11, 1, -32),
        12,
        COLORS.Accent2
    )
    badge.Font = Enum.Font.GothamBold
end

--==================================================
-- SETTINGS PAGE
--==================================================

do
    local page = pages.SETTINGS

    makeAction(
        page,
        "RESET WINDOW",
        "Return the menu to the screen center.",
        "RESET",
        function()
            Window.Position = UDim2.fromScale(0.5, 0.5)
        end
    )

    makeAction(
        page,
        "RESET FLY BUTTON",
        "Return the floating arrow to its original position.",
        "RESET",
        function()
            FlyButton.Position = UDim2.new(0.83, 0, 0.72, 0)
            FlyButton.Size = UDim2.fromOffset(58, 58)
        end
    )

    makeCard(
        page,
        100,
        "ABOUT",
        "RAHERHUB " .. VERSION .. " 💗\nMobile interface • RGB theme"
    )
end

--==================================================
-- UPDATES PAGE
--==================================================

do
    local page = pages.UPDATES

    local current = makeCard(
        page,
        110,
        "RAHERHUB V0.1",
        "Initial interface release."
    )

    local list = makeLabel(
        current,
        "• New animated loading screen\n• RGB logo\n• Mobile-friendly layout\n• Organized function tabs\n• Teleport point list",
        UDim2.new(1, -22, 0, 65),
        UDim2.new(0, 11, 1, -72),
        10,
        COLORS.Muted
    )

    local future = makeCard(
        page,
        90,
        "NEXT",
        "Additional modules and interface improvements."
    )

    local futureBadge = makeLabel(
        future,
        "PLANNED  ♡",
        UDim2.new(1, -22, 0, 20),
        UDim2.new(0, 11, 1, -28),
        11,
        COLORS.Accent2
    )
end

--==================================================
-- FLOATING OPEN BUTTON
--==================================================

local OpenButton = create("TextButton", {
    Name = "RAHERHUB_Open",
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.new(0, 15, 0.5, -25),
    Size = UDim2.fromOffset(52, 52),
    BackgroundColor3 = COLORS.Panel,
    Text = "R",
    TextColor3 = COLORS.Accent2,
    Font = Enum.Font.GothamBlack,
    TextSize = 25,
    Visible = false,
    AutoButtonColor = false,
    ZIndex = 30,
}, ScreenGui)

corner(OpenButton, 18)
stroke(OpenButton, COLORS.Accent, 2)

create("UIGradient", {
    Color = ACCENT_GRADIENT,
    Rotation = 45,
}, OpenButton)

local openButtonDragging = false
local openButtonStart
local openButtonPosition
local openButtonMoved = false

OpenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

        openButtonDragging = true
        openButtonMoved = false
        openButtonStart = input.Position
        openButtonPosition = OpenButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                openButtonDragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if openButtonDragging and (
        input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - openButtonStart

        if delta.Magnitude > 5 then
            openButtonMoved = true
        end

        OpenButton.Position = UDim2.new(
            openButtonPosition.X.Scale,
            openButtonPosition.X.Offset + delta.X,
            openButtonPosition.Y.Scale,
            openButtonPosition.Y.Offset + delta.Y
        )
    end
end)

OpenButton.Activated:Connect(function()
    if openButtonMoved then
        return
    end

    Window.Visible = true
    OpenButton.Visible = false
    State.WindowOpen = true
end)

closeButton.MouseButton1Click:Connect(function()
    Window.Visible = false
    OpenButton.Visible = true
    State.WindowOpen = false
end)

--==================================================
-- STARTUP
--==================================================

openTab("MAIN")

task.delay(5.15, function()
    if State.Destroyed then
        return
    end

    Window.Visible = true
    Window.BackgroundTransparency = 1

    tween(Window, {
        BackgroundTransparency = 0,
    }, 0.35)

    local originalSize = Window.Size

    Window.Size = UDim2.new(
        originalSize.X.Scale,
        originalSize.X.Offset,
        originalSize.Y.Scale,
        originalSize.Y.Offset - 14
    )

    tween(Window, {
        Size = originalSize,
    }, 0.35)
end)

print("RAHERHUB " .. VERSION .. " loaded 💗")