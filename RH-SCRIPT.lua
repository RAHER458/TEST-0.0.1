--[[
    RH-SCRIPT
    Universal Roblox UI framework
    Version: 0.1.1 (Mobile Fit)

    This file is independent from LAUNCHER.lua.
    Gameplay modules are intentionally not implemented yet.
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    Name = "RH-SCRIPT",
    Version = "0.1.1",
    Background = Color3.fromRGB(10, 11, 16),
    Panel = Color3.fromRGB(17, 20, 31),
    PanelLight = Color3.fromRGB(23, 27, 42),
    PanelHover = Color3.fromRGB(30, 35, 54),
    Accent = Color3.fromRGB(105, 91, 255),
    AccentBlue = Color3.fromRGB(67, 139, 255),
    Text = Color3.fromRGB(239, 241, 255),
    Muted = Color3.fromRGB(137, 145, 168),
    Border = Color3.fromRGB(43, 49, 70),
    Green = Color3.fromRGB(88, 214, 160),
}

local oldGui
pcall(function()
    oldGui = (gethui and gethui():FindFirstChild("RH_SCRIPT_UI")) or nil
end)
if not oldGui then
    pcall(function()
        oldGui = CoreGui:FindFirstChild("RH_SCRIPT_UI")
    end)
end
if not oldGui and LocalPlayer then
    pcall(function()
        oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("RH_SCRIPT_UI")
    end)
end
if oldGui then
    oldGui:Destroy()
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function stroke(parent, color, transparency)
    make("UIStroke", {
        Color = color or CONFIG.Border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function label(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or CONFIG.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.None,
    }, parent)
end

local ScreenGui = make("ScreenGui", {
    Name = "RH_SCRIPT_UI",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
}, nil)

local guiParent
local parentOk = pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)
if not parentOk or not guiParent then
    local coreOk = pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not coreOk then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
else
    ScreenGui.Parent = guiParent
end

local Window = make("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(480, 460),
    BackgroundColor3 = CONFIG.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
round(Window, 15)
stroke(Window, CONFIG.Border, 0.12)

local WindowScale = make("UIScale", {Scale = 1}, Window)

local function updateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize

    -- Match RH-LAUNCHER window dimensions and viewport fitting exactly.
    WindowScale.Scale = 1
    Window.Size = UDim2.fromOffset(
        math.min(480, viewport.X - 20),
        math.min(460, viewport.Y - 60)
    )
end
updateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local Header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, Window)

local HeaderLine = make("Frame", {
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = CONFIG.Border,
    BorderSizePixel = 0,
}, Header)

local Logo = make("Frame", {
    Position = UDim2.fromOffset(17, 11),
    Size = UDim2.fromOffset(36, 36),
    BackgroundColor3 = CONFIG.Accent,
    BorderSizePixel = 0,
}, Header)
round(Logo, 10)
make("UIGradient", {
    Color = ColorSequence.new(CONFIG.Accent, CONFIG.AccentBlue),
    Rotation = 35,
}, Logo)
local LogoText = label(Logo, "RH", 15, Color3.new(1, 1, 1), Enum.Font.GothamBold)
LogoText.Size = UDim2.fromScale(1, 1)
LogoText.TextXAlignment = Enum.TextXAlignment.Center

local Brand = label(Header, "RH-SCRIPT", 15, CONFIG.Text, Enum.Font.GothamBold)
Brand.Position = UDim2.fromOffset(64, 10)
Brand.Size = UDim2.fromOffset(180, 20)

local SubBrand = label(Header, "UNIVERSAL TOOLKIT  •  BETA", 9, CONFIG.Muted, Enum.Font.GothamMedium)
SubBrand.Position = UDim2.fromOffset(65, 30)
SubBrand.Size = UDim2.fromOffset(220, 15)

local Version = label(Header, "v" .. CONFIG.Version, 10, CONFIG.Muted)
Version.AnchorPoint = Vector2.new(1, 0.5)
Version.Position = UDim2.new(1, -88, 0.5, 0)
Version.Size = UDim2.fromOffset(65, 20)
Version.TextXAlignment = Enum.TextXAlignment.Right

local function headerButton(text, xOffset, color)
    local button = make("TextButton", {
        Position = UDim2.new(1, xOffset, 0, 16),
        Size = UDim2.fromOffset(27, 26),
        BackgroundColor3 = CONFIG.PanelLight,
        Text = text,
        TextColor3 = color or CONFIG.Muted,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, Header)
    round(button, 8)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.PanelHover}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.PanelLight}):Play()
    end)
    return button
end

local MinButton = headerButton("—", -67)
local CloseButton = headerButton("×", -34, Color3.fromRGB(255, 112, 130))

local Body = make("Frame", {
    Name = "Body",
    Position = UDim2.fromOffset(0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
}, Window)

local Sidebar = make("Frame", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(0, 174, 1, 0),
    BackgroundColor3 = CONFIG.Panel,
    BorderSizePixel = 0,
}, Body)

local SideDivider = make("Frame", {
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = CONFIG.Border,
    BorderSizePixel = 0,
}, Sidebar)

local NavCaption = label(Sidebar, "NAVIGATION", 9, CONFIG.Muted, Enum.Font.GothamBold)
NavCaption.Position = UDim2.fromOffset(17, 17)
NavCaption.Size = UDim2.new(1, -30, 0, 18)

local NavHolder = make("Frame", {
    Position = UDim2.fromOffset(10, 43),
    Size = UDim2.new(1, -20, 0, 300),
    BackgroundTransparency = 1,
}, Sidebar)
make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, NavHolder)

local SideFooter = make("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 10, 1, -12),
    Size = UDim2.new(1, -20, 0, 48),
    BackgroundColor3 = CONFIG.PanelLight,
    BorderSizePixel = 0,
}, Sidebar)
round(SideFooter, 9)
local FooterDot = make("Frame", {
    Position = UDim2.fromOffset(11, 18),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = CONFIG.Green,
    BorderSizePixel = 0,
}, SideFooter)
round(FooterDot, 8)
local FooterText = label(SideFooter, "Interface loaded", 10, CONFIG.Muted)
FooterText.Position = UDim2.fromOffset(25, 0)
FooterText.Size = UDim2.new(1, -30, 1, 0)

local Content = make("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(174, 0),
    Size = UDim2.new(1, -174, 1, 0),
    BackgroundTransparency = 1,
}, Body)

local PageTitle = label(Content, "MAIN", 21, CONFIG.Text, Enum.Font.GothamBold)
PageTitle.Position = UDim2.fromOffset(25, 19)
PageTitle.Size = UDim2.new(1, -50, 0, 29)

local PageDescription = label(Content, "Your universal Roblox workspace", 11, CONFIG.Muted)
PageDescription.Position = UDim2.fromOffset(26, 49)
PageDescription.Size = UDim2.new(1, -50, 0, 20)

local PageContainer = make("Frame", {
    Position = UDim2.fromOffset(25, 82),
    Size = UDim2.new(1, -50, 1, -105),
    BackgroundTransparency = 1,
}, Content)

local pages = {
    MAIN = "Welcome to RH-SCRIPT. Your workspace is ready.",
    AIM = "Aim tools will be configured here in a future update.",
    WH = "WH module placeholder. No gameplay functions are active.",
    ESP = "ESP module placeholder. No gameplay functions are active.",
    MISC = "Extra tools and utilities will appear in this section.",
    SETTINGS = "Interface preferences and script options.",
}

local function createInfoCard(parent, title, description, height)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 94),
        BackgroundColor3 = CONFIG.Panel,
        BorderSizePixel = 0,
    }, parent)
    round(card, 11)
    stroke(card, CONFIG.Border, 0.25)

    local accent = make("Frame", {
        Position = UDim2.fromOffset(0, 13),
        Size = UDim2.new(0, 3, 0, 34),
        BackgroundColor3 = CONFIG.Accent,
        BorderSizePixel = 0,
    }, card)
    round(accent, 3)

    local titleLabel = label(card, title, 13, CONFIG.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.fromOffset(16, 13)
    titleLabel.Size = UDim2.new(1, -32, 0, 21)

    local descLabel = label(card, description, 10, CONFIG.Muted)
    descLabel.Position = UDim2.fromOffset(16, 39)
    descLabel.Size = UDim2.new(1, -32, 0, 36)
    descLabel.TextWrapped = true
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    return card
end

local function clearPage()
    for _, child in ipairs(PageContainer:GetChildren()) do
        child:Destroy()
    end
end

local currentPage = "MAIN"
local navButtons = {}

local function renderPage(pageName)
    currentPage = pageName
    PageTitle.Text = pageName
    PageDescription.Text = pageName == "MAIN" and "Your universal Roblox workspace" or "RH-SCRIPT  /  " .. pageName
    clearPage()

    if pageName == "MAIN" then
        local welcome = createInfoCard(
            PageContainer,
            "Welcome back",
            "RH-SCRIPT interface preview is running. Choose a section on the left to explore the layout.",
            105
        )
        local status = createInfoCard(
            PageContainer,
            "SYSTEM STATUS",
            "UI: ONLINE     •     GAME MODULES: NOT ADDED",
            82
        )
        status.Position = UDim2.fromOffset(0, 118)
        local note = createInfoCard(
            PageContainer,
            "DEVELOPMENT BUILD",
            "This is the visual foundation. Individual modules and their settings will be added separately.",
            82
        )
        note.Position = UDim2.fromOffset(0, 212)
    else
        createInfoCard(PageContainer, pageName .. " MODULE", pages[pageName], 105)
        local note = createInfoCard(
            PageContainer,
            "COMING LATER",
            "This section is reserved for future features. The interface is ready for expansion.",
            82
        )
        note.Position = UDim2.fromOffset(0, 118)
    end

    for name, button in pairs(navButtons) do
        local selected = name == pageName
        local target = selected and CONFIG.PanelHover or CONFIG.Panel
        TweenService:Create(button, TweenInfo.new(0.16), {
            BackgroundColor3 = target,
            TextColor3 = selected and CONFIG.Text or CONFIG.Muted,
        }):Play()
        local indicator = button:FindFirstChild("ActiveIndicator")
        if indicator then
            indicator.BackgroundTransparency = selected and 0 or 1
        end
    end
end

local navItems = {
    {name = "MAIN", icon = "⌂"},
    {name = "AIM", icon = "◎"},
    {name = "WH", icon = "◈"},
    {name = "ESP", icon = "◇"},
    {name = "MISC", icon = "✳"},
    {name = "SETTINGS", icon = "⚙"},
}

for index, item in ipairs(navItems) do
    local button = make("TextButton", {
        Name = item.name .. "Button",
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = CONFIG.Panel,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = index,
    }, NavHolder)
    round(button, 8)

    local indicator = make("Frame", {
        Name = "ActiveIndicator",
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(0, 3, 0, 23),
        BackgroundColor3 = CONFIG.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, button)
    round(indicator, 3)

    local iconLabel = label(button, item.icon, 16, CONFIG.Muted, Enum.Font.GothamBold)
    iconLabel.Position = UDim2.fromOffset(12, 0)
    iconLabel.Size = UDim2.fromOffset(22, 39)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local textLabel = label(button, item.name, 11, CONFIG.Muted, Enum.Font.GothamBold)
    textLabel.Position = UDim2.fromOffset(43, 0)
    textLabel.Size = UDim2.new(1, -50, 1, 0)

    navButtons[item.name] = button
    button.MouseButton1Click:Connect(function()
        renderPage(item.name)
    end)
    button.MouseEnter:Connect(function()
        if currentPage ~= item.name then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = CONFIG.PanelLight}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if currentPage ~= item.name then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = CONFIG.Panel}):Play()
        end
    end)
end

renderPage("MAIN")

local minimized = false
local expandedSize = UDim2.fromOffset(480, 460)
MinButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    Body.Visible = not minimized
    local targetSize = minimized and UDim2.fromOffset(480, 58) or expandedSize
    TweenService:Create(Window, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = targetSize,
    }):Play()
    MinButton.Text = minimized and "+" or "—"
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dragging support for mouse and touch.
local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

print("[RH-SCRIPT] Interface " .. CONFIG.Version .. " loaded.")
