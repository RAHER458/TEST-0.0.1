local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local espEnabled = false
local highlights = {}

local function addESP(player)
    if player == LocalPlayer then
        return
    end

    local function characterAdded(character)
        if highlights[player] then
            highlights[player]:Destroy()
        end

        if not espEnabled then
            return
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = "SimpleESP"
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.Adornee = character
        highlight.Parent = character

        highlights[player] = highlight
    end

    if player.Character then
        characterAdded(player.Character)
    end

    player.CharacterAdded:Connect(characterAdded)
end

local function setESP(state)
    espEnabled = state

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if state then
                addESP(player)
            elseif highlights[player] then
                highlights[player]:Destroy()
                highlights[player] = nil
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        addESP(player)
    end
end)

-- Меню
local gui = Instance.new("ScreenGui")
gui.Name = "SimpleESPMenu"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(120, 40)
button.Position = UDim2.new(0, 15, 0.5, 0)
button.Text = "ESP: OFF"
button.TextSize = 16
button.Parent = gui

button.Activated:Connect(function()
    setESP(not espEnabled)
    button.Text = espEnabled and "ESP: ON" or "ESP: OFF"
end)