-- RAHERHUB V0.1 💗
-- Mobile UI
-- 8 tabs: MAIN, VISUALS, MOVEMENT, FLY,
-- TELEPORT, EXPLOITS, SETTINGS, UPDATES

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("RAHERHUB: LocalPlayer unavailable")
    return
end

local CoreGui = game:GetService("CoreGui")
local old = CoreGui:FindFirstChild("RAHERHUB_V01")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RAHERHUB_V01"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok = pcall(function()
    gui.Parent = CoreGui
end)

if not ok then
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local BG = Color3.fromRGB(18, 16, 25)
local PANEL = Color3.fromRGB(29, 25, 39)
local PANEL2 = Color3.fromRGB(40, 34, 53)
local PINK = Color3.fromRGB(255, 80, 190)
local WHITE = Color3.fromRGB(245, 240, 250)
local GREEN = Color3.fromRGB(48, 72, 63)

local state = {
    speedEnabled = false,
    speed = 32,
    flyEnabled = false,
    flySpeed = 55,
    noclipEnabled = false,
    espEnabled = false,
    savedPoints = {},
    selectedPoint = nil,
    flyButtons = {},
}

local connections = {}

local function track(conn)
    table.insert(connections, conn)
    return conn
end

local function make(className, props, parent)
    local obj = Instance.new(className)

    for k, v in pairs(props or {}) do
        pcall(function()
            obj[k] = v
        end)
    end

    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 10)
    }, parent)
end

local function outline(parent, color, thickness)
    make("UIStroke", {
        Color = color or PINK,
        Thickness = thickness or 1.5,
        Transparency = 0.15
    }, parent)
end

-- MAIN WINDOW

local screen = make("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(0, 340, 0, 430),
    Position = UDim2.new(0.5, -170, 0.5, -215),
    BackgroundColor3 = BG,
    BorderSizePixel = 0
}, gui)

corner(screen, 14)
outline(screen, PINK, 2)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0
}, screen)

corner(top, 14)

make("Frame", {
    Position = UDim2.new(0, 0, 1, -14),
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0
}, top)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -100, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "RAHERHUB V0.1 💗",
    TextColor3 = PINK,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

local minimize = make("TextButton", {
    Position = UDim2.new(1, -72, 0, 8),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = PANEL2,
    Text = "—",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    BorderSizePixel = 0
}, top)

corner(minimize, 8)

local close = make("TextButton", {
    Position = UDim2.new(1, -38, 0, 8),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = Color3.fromRGB(105, 40, 65),
    Text = "×",
    TextColor3 = WHITE,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    BorderSizePixel = 0
}, top)

corner(close, 8)

-- WINDOW DRAGGING

do
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = screen.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    top.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    track(UIS.InputChanged:Connect(function(input)
        if dragging and (
            input == dragInput
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart

            screen.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- CONTENT AREA

local body = make("Frame", {
    Position = UDim2.new(0, 10, 0, 56),
    Size = UDim2.new(1, -20, 1, -66),
    BackgroundTransparency = 1
}, screen)

local tabBar = make("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.X
}, body)

local tabLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabBar)

tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    tabBar.CanvasSize = UDim2.new(
        0,
        tabLayout.AbsoluteContentSize.X + 4,
        0,
        0
    )
end)

local content = make("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 46),
    Size = UDim2.new(1, 0, 1, -46),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, body)

corner(content, 10)

make("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10)
}, content)

make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, content)

local function clearContent()
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("GuiObject")
        and not child:IsA("UIListLayout")
        and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function label(text, height)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WHITE,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, content)
end

local function button(text, callback, parent)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = PANEL2,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = WHITE,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextWrapped = true,
        AutoButtonColor = true
    }, parent or content)

    corner(b, 8)
    outline(b, Color3.fromRGB(80, 68, 100), 1)

    b.Activated:Connect(callback)

    return b
end

local function toggle(text, initial, callback)
    local enabled = initial
    local b

    local function refresh()
        b.Text = text .. (enabled and "  [ON]" or "  [OFF]")
        b.BackgroundColor3 = enabled and GREEN or PANEL2
    end

    b = button("", function()
        enabled = not enabled
        refresh()
        callback(enabled)
    end)

    refresh()

    return function(value)
        enabled = value
        refresh()
        callback(enabled)
    end
end

-- SLIDER

local function slider(text, minVal, maxVal, initial, callback)
    local holder = make("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1
    }, content)

    local caption = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text .. ": " .. tostring(initial),
        TextColor3 = WHITE,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, holder)

    local rail = make("Frame", {
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Color3.fromRGB(65, 56, 78),
        BorderSizePixel = 0
    }, holder)

    corner(rail, 6)

    local alpha = (initial - minVal) / (maxVal - minVal)

    local fill = make("Frame", {
        Size = UDim2.new(alpha, 0, 1, 0),
        BackgroundColor3 = PINK,
        BorderSizePixel = 0
    }, rail)

    corner(fill, 6)

    local knob = make("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        Size = UDim2.new(0, 22, 0, 22),
        BackgroundColor3 = WHITE,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, rail)

    corner(knob, 11)
    outline(knob, PINK, 2)

    local dragging = false

    local function setFromX(x)
        local width = math.max(rail.AbsoluteSize.X, 1)

        local a = math.clamp(
            (x - rail.AbsolutePosition.X) / width,
            0,
            1
        )

        local value = math.floor(
            minVal + a * (maxVal - minVal) + 0.5
        )

        local realAlpha = (value - minVal) / (maxVal - minVal)

        fill.Size = UDim2.new(realAlpha, 0, 1, 0)
        knob.Position = UDim2.new(realAlpha, 0, 0.5, 0)
        caption.Text = text .. ": " .. tostring(value)

        callback(value)
    end

    local function begin(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromX(input.Position.X)
        end
    end

    rail.InputBegan:Connect(begin)
    knob.InputBegan:Connect(begin)

    track(UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement
        ) then
            setFromX(input.Position.X)
        end
    end))

    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

-- CHARACTER HELPERS

local function getCharacter()
    local character = LocalPlayer.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    return character, humanoid, root
end

local function applySpeed()
    local _, humanoid = getCharacter()

    if humanoid then
        humanoid.WalkSpeed = state.speedEnabled and state.speed or 16
    end
end

local function applyNoclip()
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if state.noclipEnabled then
                part.CanCollide = false
            end
        end
    end
end

-- FLY

local flyAttachment
local flyVelocity
local flyOrientation

local function stopFly()
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end

    if flyOrientation then
        flyOrientation:Destroy()
        flyOrientation = nil
    end

    if flyAttachment then
        flyAttachment:Destroy()
        flyAttachment = nil
    end
end

local function startFly()
    local _, humanoid, root = getCharacter()

    if not root or not humanoid then
        return
    end

    stopFly()

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "RAHERHUB_FlyAttachment"
    flyAttachment.Parent = root

    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "RAHERHUB_FlyVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.VelocityConstraintMode =
        Enum.VelocityConstraintMode.Vector
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.MaxForce = 100000
    flyVelocity.Parent = root

    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode =
        Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.MaxTorque = 100000
    flyOrientation.Responsiveness = 15
    flyOrientation.Parent = root
end

local function teleportTo(cf)
    local _, _, root = getCharacter()

    if root and typeof(cf) == "CFrame" then
        root.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

-- ESP

local function applyESP(player)
    if player == LocalPlayer then return end

    local character = player.Character
    if not character then return end

    local existing = character:FindFirstChild("RAHERHUB_ESP")

    if state.espEnabled then
        if not existing then
            local highlight = Instance.new("Highlight")
            highlight.Name = "RAHERHUB_ESP"
            highlight.FillColor = PINK
            highlight.OutlineColor = WHITE
            highlight.FillTransparency = 0.55
            highlight.Parent = character
        end
    elseif existing then
        existing:Destroy()
    end
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        applyESP(player)
    end
end

-- FLOATING MENU BUTTON

local showButton = make("TextButton", {
    Name = "ShowRAHERHUB",
    Size = UDim2.new(0, 54, 0, 54),
    Position = UDim2.new(0, 18, 0.5, -27),
    BackgroundColor3 = BG,
    Text = "RH💗",
    TextColor3 = PINK,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0,
    Visible = false
}, gui)

corner(showButton, 27)
outline(showButton, PINK, 2)

showButton.Activated:Connect(function()
    screen.Visible = true
    showButton.Visible = false
end)

minimize.Activated:Connect(function()
    screen.Visible = false
    showButton.Visible = true
end)

close.Activated:Connect(function()
    state.flyEnabled = false
    stopFly()

    for _, conn in ipairs(connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    gui:Destroy()
end)

-- TAB CONTENT

local function setTab(name)
    clearContent()

    if name == "MAIN" then
        label("Welcome back 💗", 28)
        label("RAHERHUB V0.1 — mobile build", 28)

        button("Reapply movement settings", function()
            applySpeed()
            applyNoclip()

            if state.flyEnabled then
                startFly()
            end
        end)

        button("Reset movement", function()
            state.speedEnabled = false
            state.flyEnabled = false
            state.noclipEnabled = false

            stopFly()

            local _, humanoid = getCharacter()

            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid:ChangeState(
                    Enum.HumanoidStateType.GettingUp
                )
            end

            setTab("MOVEMENT")
        end)

    elseif name == "VISUALS" then
        label("Player ESP — client-side highlights.", 42)

        toggle("Player ESP", state.espEnabled, function(on)
            state.espEnabled = on
            refreshESP()
        end)

        button("Refresh ESP", function()
            refreshESP()
        end)

    elseif name == "MOVEMENT" then
        label("Client movement may be overridden by the server.", 42)

        toggle("Speed boost", state.speedEnabled, function(on)
            state.speedEnabled = on
            applySpeed()
        end)

        slider("WalkSpeed", 16, 1000, state.speed, function(value)
            state.speed = value

            if state.speedEnabled then
                applySpeed()
            end
        end)

        toggle("Noclip", state.noclipEnabled, function(on)
            state.noclipEnabled = on
            applyNoclip()
        end)

    elseif name == "FLY" then
        label("Fly controls for touch screens.", 30)

        toggle("Fly", state.flyEnabled, function(on)
            state.flyEnabled = on

            if on then
                startFly()
            else
                stopFly()

                local _, humanoid = getCharacter()

                if humanoid then
                    humanoid:ChangeState(
                        Enum.HumanoidStateType.GettingUp
                    )
                end
            end
        end)

        slider("Fly speed", 10, 250, state.flySpeed, function(value)
            state.flySpeed = value
        end)

        local directions = make("Frame", {
            Size = UDim2.new(1, 0, 0, 100),
            BackgroundTransparency = 1
        }, content)

        local function flyButton(text, position)
            local held = false

            local b = make("TextButton", {
                Position = position,
                Size = UDim2.new(0, 92, 0, 38),
                BackgroundColor3 = PANEL2,
                Text = text,
                TextColor3 = WHITE,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                BorderSizePixel = 0
            }, directions)

            corner(b, 8)

            b.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    held = true
                end
            end)

            b.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    held = false
                end
            end)

            return function()
                return held
            end
        end

        state.flyButtons = {
            up = flyButton("UP", UDim2.new(0.5, -46, 0, 0)),
            down = flyButton("DOWN", UDim2.new(0.5, -46, 0, 48)),
            left = flyButton("LEFT", UDim2.new(0, 0, 0, 24)),
            right = flyButton("RIGHT", UDim2.new(1, -92, 0, 24))
        }

    elseif name == "TELEPORT" then
        label("Save your current position, then select a point.", 42)

        local nameBox = make("TextBox", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = BG,
            TextColor3 = WHITE,
            PlaceholderText = "Point name",
            Text = "Point " .. tostring(#state.savedPoints + 1),
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            BorderSizePixel = 0
        }, content)

        corner(nameBox, 8)

        button("SAVE CURRENT POSITION", function()
            local _, _, root = getCharacter()

            if not root then
                label("Character not ready.", 25)
                return
            end

            local pointName = nameBox.Text

            if pointName == "" then
                pointName = "Point " .. tostring(#state.savedPoints + 1)
            end

            table.insert(state.savedPoints, {
                name = pointName,
                cf = root.CFrame
            })

            setTab("TELEPORT")
        end)

        if #state.savedPoints == 0 then
            label("No saved points yet.", 28)
        end

        for index, point in ipairs(state.savedPoints) do
            local row = make("Frame", {
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundTransparency = 1
            }, content)

            local selectBtn = make("TextButton", {
                Size = UDim2.new(1, -82, 1, 0),
                BackgroundColor3 =
                    state.selectedPoint == index
                    and Color3.fromRGB(76, 45, 83)
                    or PANEL2,
                Text = point.name,
                TextColor3 = WHITE,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                BorderSizePixel = 0
            }, row)

            corner(selectBtn, 8)

            selectBtn.Activated:Connect(function()
                state.selectedPoint = index
                setTab("TELEPORT")
            end)

            local del = make("TextButton", {
                Position = UDim2.new(1, -76, 0, 0),
                Size = UDim2.new(0, 76, 1, 0),
                BackgroundColor3 = Color3.fromRGB(100, 40, 60),
                Text = "DELETE",
                TextColor3 = WHITE,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                BorderSizePixel = 0
            }, row)

            corner(del, 8)

            del.Activated:Connect(function()
                table.remove(state.savedPoints, index)

                if state.selectedPoint == index then
                    state.selectedPoint = nil
                elseif state.selectedPoint and state.selectedPoint > index then
                    state.selectedPoint = state.selectedPoint - 1
                end

                setTab("TELEPORT")
            end)
        end

        button("GO TO SELECTED POINT", function()
            local point = state.savedPoints[state.selectedPoint or -1]

            if point then
                teleportTo(point.cf)
            else
                label("Select a saved point first.", 28)
            end
        end)

        button("CLEAR ALL POINTS", function()
            state.savedPoints = {}
            state.selectedPoint = nil
            setTab("TELEPORT")
        end)

    elseif name == "EXPLOITS" then
        label("Authorized testing tools for your own map.", 32)

        button("Show security checklist", function()
            label(
                "Validate movement, teleport requests, inventory, currency and permissions on the server. Never trust client values.",
                80
            )
        end)

        button("Print checklist to output", function()
            warn("RAHERHUB SECURITY CHECKLIST:")
            warn("1. Validate RemoteEvents on the server.")
            warn("2. Clamp movement and teleport requests.")
            warn("3. Verify inventory and currency server-side.")
            warn("4. Check player permissions and ownership.")
            warn("5. Rate-limit remote requests.")

            label("Checklist sent to output.", 30)
        end)

    elseif name == "SETTINGS" then
        button("Hide menu", function()
            screen.Visible = false
            showButton.Visible = true
        end)

        button("Reset movement", function()
            state.speedEnabled = false
            state.noclipEnabled = false
            state.flyEnabled = false

            stopFly()

            local _, humanoid = getCharacter()

            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid:ChangeState(
                    Enum.HumanoidStateType.GettingUp
                )
            end

            state.flyButtons = {}
            setTab("SETTINGS")
        end)

        label("Saved points last only for this session.", 38)

    elseif name == "UPDATES" then
        label("RAHERHUB V0.1 💗", 30)

        label(
            "Mobile interface\n" ..
            "• 8 tabs\n" ..
            "• WalkSpeed slider 16–1000\n" ..
            "• Fly controls\n" ..
            "• ESP toggle\n" ..
            "• Saved teleport points",
            110
        )

        label("Report any broken feature so we can fix it.", 42)
    end
end

-- CREATE TABS

local tabs = {
    "MAIN",
    "VISUALS",
    "MOVEMENT",
    "FLY",
    "TELEPORT",
    "EXPLOITS",
    "SETTINGS",
    "UPDATES"
}

for _, name in ipairs(tabs) do
    local b = make("TextButton", {
        Size = UDim2.new(0, 92, 0, 32),
        BackgroundColor3 = name == "MAIN" and PINK or PANEL2,
        Text = name,
        TextColor3 = WHITE,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        BorderSizePixel = 0
    }, tabBar)

    corner(b, 8)

    b.Activated:Connect(function()
        for _, child in ipairs(tabBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 =
                    child.Text == name and PINK or PANEL2
            end
        end

        setTab(name)
    end)
end

-- UPDATE ESP WHEN PLAYERS JOIN

track(Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)

        if state.espEnabled then
            applyESP(player)
        end
    end)
end))

track(Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        local highlight = player.Character:FindFirstChild("RAHERHUB_ESP")

        if highlight then
            highlight:Destroy()
        end
    end
end))

-- MOVEMENT / FLY LOOP

track(RunService.Heartbeat:Connect(function()
    if state.speedEnabled then
        applySpeed()
    end

    if state.noclipEnabled then
        applyNoclip()
    end

    if state.flyEnabled then
        local _, humanoid, root = getCharacter()

        if root and humanoid and flyVelocity then
            local camera = workspace.CurrentCamera
            local direction = humanoid.MoveDirection

            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                direction += Vector3.yAxis
            end

            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                direction -= Vector3.yAxis
            end

            local controls = state.flyButtons

            if camera and controls then
                if controls.up and controls.up() then
                    direction += Vector3.yAxis
                end

                if controls.down and controls.down() then
                    direction -= Vector3.yAxis
                end

                if controls.left and controls.left() then
                    direction -= camera.CFrame.RightVector
                end

                if controls.right and controls.right() then
                    direction += camera.CFrame.RightVector
                end
            end

            if direction.Magnitude > 0 then
                flyVelocity.VectorVelocity =
                    direction.Unit * state.flySpeed
            else
                flyVelocity.VectorVelocity = Vector3.zero
            end
        end
    end
end))

-- CHARACTER RESPAWN

track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)

    if state.speedEnabled then
        applySpeed()
    end

    if state.noclipEnabled then
        applyNoclip()
    end

    if state.flyEnabled then
        startFly()
    end

    if state.espEnabled then
        refreshESP()
    end
end))

-- START

setTab("MAIN")

print("RAHERHUB V0.1 💗 loaded")