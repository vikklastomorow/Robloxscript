-- ==============================================================================
-- 🚀 RAKAHUB - PLAYER UTILITY SCRIPT (WalkSpeed, JumpPower, Fly, Noclip, Inf Jump)
-- Kompatibel: PC & Mobile (Delta, Fluxus, Arceus X, Codex, Solara, Wave, Studio)
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Parent GUI aman (Mendukung Exploit CoreGui maupun PlayerGui)
local function getSafeGuiParent()
    local success, coreGui = pcall(function()
        return (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if success and coreGui then
        return coreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = getSafeGuiParent()

-- Hapus GUI lama jika ada
if GuiParent:FindFirstChild("RakaPlayerHub") then
    GuiParent.RakaPlayerHub:Destroy()
end

-- ==============================================================================
-- ⚙️ KONFIGURASI STATE & NILAI DEFAULT
-- ==============================================================================
local State = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlySpeed = 50,
    SpeedEnabled = false,
    JumpEnabled = false,
    FlyEnabled = false,
    NoclipEnabled = false,
    InfJumpEnabled = false,
}

local DefaultStats = {
    WalkSpeed = 16,
    JumpPower = 50,
}

-- ==============================================================================
-- 🧠 FUNGSI SISTEM (LOGIC)
-- ==============================================================================

-- 1. Helper Karakter & Humanoid
local function getHumanoid()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function getRootPart()
    local char = LocalPlayer.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    end
    return nil
end

-- Terapkan WalkSpeed & JumpPower
local function updatePlayerStats()
    local hum = getHumanoid()
    if hum then
        hum.UseJumpPower = true
        if State.SpeedEnabled then
            hum.WalkSpeed = State.WalkSpeed
        else
            hum.WalkSpeed = DefaultStats.WalkSpeed
        end

        if State.JumpEnabled then
            hum.JumpPower = State.JumpPower
        else
            hum.JumpPower = DefaultStats.JumpPower
        end
    end
end

-- 2. Noclip Connection
local noclipConnection = nil
local function toggleNoclip(enable)
    State.NoclipEnabled = enable
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if enable then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char and State.NoclipEnabled then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- 3. Infinite Jump Connection
local infJumpConnection = nil
local function toggleInfiniteJump(enable)
    State.InfJumpEnabled = enable
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end

    if enable then
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            if State.InfJumpEnabled then
                local hum = getHumanoid()
                if hum and hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
end

-- 4. Fly System (Smooth BodyVelocity + BodyGyro)
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyStepConnection = nil

local moveKeys = {
    Forward = false,
    Backward = false,
    Left = false,
    Right = false,
    Up = false,
    Down = false,
}

local function stopFly()
    State.FlyEnabled = false
    if flyStepConnection then
        flyStepConnection:Disconnect()
        flyStepConnection = nil
    end
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
    local hum = getHumanoid()
    if hum then
        hum.PlatformStand = false
    end
end

local function startFly()
    stopFly()
    State.FlyEnabled = true

    local root = getRootPart()
    local hum = getHumanoid()
    if not root or not hum then return end

    hum.PlatformStand = true

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "RakaFlyVelocity"
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Parent = root

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "RakaFlyGyro"
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root

    flyStepConnection = RunService.RenderStepped:Connect(function()
        if not State.FlyEnabled or not root or not root.Parent or not hum or hum.Health <= 0 then
            stopFly()
            return
        end

        hum.PlatformStand = true
        flyBodyGyro.CFrame = Camera.CFrame

        local moveDir = Vector3.new(0, 0, 0)
        local camCFrame = Camera.CFrame

        if moveKeys.Forward then
            moveDir = moveDir + camCFrame.LookVector
        end
        if moveKeys.Backward then
            moveDir = moveDir - camCFrame.LookVector
        end
        if moveKeys.Left then
            moveDir = moveDir - camCFrame.RightVector
        end
        if moveKeys.Right then
            moveDir = moveDir + camCFrame.RightVector
        end
        if moveKeys.Up then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if moveKeys.Down then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end

        if moveDir.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDir.Unit * State.FlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- Key listener untuk Fly keyboard
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then
        moveKeys.Forward = true
    elseif input.KeyCode == Enum.KeyCode.S then
        moveKeys.Backward = true
    elseif input.KeyCode == Enum.KeyCode.A then
        moveKeys.Left = true
    elseif input.KeyCode == Enum.KeyCode.D then
        moveKeys.Right = true
    elseif input.KeyCode == Enum.KeyCode.Space then
        moveKeys.Up = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then
        moveKeys.Down = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        moveKeys.Forward = false
    elseif input.KeyCode == Enum.KeyCode.S then
        moveKeys.Backward = false
    elseif input.KeyCode == Enum.KeyCode.A then
        moveKeys.Left = false
    elseif input.KeyCode == Enum.KeyCode.D then
        moveKeys.Right = false
    elseif input.KeyCode == Enum.KeyCode.Space then
        moveKeys.Up = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then
        moveKeys.Down = false
    end
end)

-- Auto Re-apply ketika respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("Humanoid")
    task.wait(0.5)
    updatePlayerStats()
    if State.NoclipEnabled then toggleNoclip(true) end
    if State.FlyEnabled then startFly() end
end)

-- Loop proteksi stat
task.spawn(function()
    while true do
        task.wait(1)
        if State.SpeedEnabled or State.JumpEnabled then
            updatePlayerStats()
        end
    end
end)

-- ==============================================================================
-- 🎨 PEMBUATAN USER INTERFACE (MODERN DARK THEME)
-- ==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RakaPlayerHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = GuiParent

-- Floating Button untuk Buka / Tutup (Sangat cocok untuk Mobile)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "RakaOpenBtn"
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 20, 0.5, -25)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
OpenBtn.Text = "⚡"
OpenBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
OpenBtn.TextSize = 22
OpenBtn.Font = Enum.Font.SourceSansBold
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Parent = ScreenGui

local OpenBtnCorner = Instance.new("UICorner")
OpenBtnCorner.CornerRadius = UDim.new(1, 0)
OpenBtnCorner.Parent = OpenBtn

local OpenBtnStroke = Instance.new("UIStroke")
OpenBtnStroke.Color = Color3.fromRGB(0, 255, 150)
OpenBtnStroke.Thickness = 1.5
OpenBtnStroke.Parent = OpenBtn

-- Frame Utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 27)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -220)
MainFrame.Size = UDim2.new(0, 350, 0, 440)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(35, 40, 60)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Header Bar
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(12, 13, 20)
Header.Size = UDim2.new(1, 0, 0, 45)

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderPatch = Instance.new("Frame")
HeaderPatch.Size = UDim2.new(1, 0, 0, 10)
HeaderPatch.Position = UDim2.new(0, 0, 1, -10)
HeaderPatch.BackgroundColor3 = Color3.fromRGB(12, 13, 20)
HeaderPatch.BorderSizePixel = 0
HeaderPatch.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = Header
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ RAKAHUB • PLAYER"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Minimize & Close
local BtnMin = Instance.new("TextButton")
BtnMin.Parent = Header
BtnMin.Size = UDim2.new(0, 26, 0, 26)
BtnMin.Position = UDim2.new(1, -65, 0.5, -13)
BtnMin.BackgroundColor3 = Color3.fromRGB(26, 29, 43)
BtnMin.Text = "-"
BtnMin.TextColor3 = Color3.fromRGB(200, 200, 200)
BtnMin.TextSize = 16
BtnMin.Font = Enum.Font.GothamBold

local BtnMinCorner = Instance.new("UICorner")
BtnMinCorner.CornerRadius = UDim.new(0, 6)
BtnMinCorner.Parent = BtnMin

local BtnClose = Instance.new("TextButton")
BtnClose.Parent = Header
BtnClose.Size = UDim2.new(0, 26, 0, 26)
BtnClose.Position = UDim2.new(1, -34, 0.5, -13)
BtnClose.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
BtnClose.Text = "✕"
BtnClose.TextColor3 = Color3.fromRGB(255, 100, 100)
BtnClose.TextSize = 12
BtnClose.Font = Enum.Font.GothamBold

local BtnCloseCorner = Instance.new("UICorner")
BtnCloseCorner.CornerRadius = UDim.new(0, 6)
BtnCloseCorner.Parent = BtnClose

-- Minimize logic
local function toggleMinimize()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end

BtnMin.MouseButton1Click:Connect(toggleMinimize)
OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenBtn.Visible = false
end)

BtnClose.MouseButton1Click:Connect(function()
    stopFly()
    toggleNoclip(false)
    toggleInfiniteJump(false)
    State.SpeedEnabled = false
    State.JumpEnabled = false
    updatePlayerStats()
    ScreenGui:Destroy()
end)

-- Scroll Container
local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Parent = MainFrame
ScrollList.Position = UDim2.new(0, 12, 0, 52)
ScrollList.Size = UDim2.new(1, -24, 1, -60)
ScrollList.BackgroundTransparency = 1
ScrollList.ScrollBarThickness = 3
ScrollList.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 150)
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 520)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ScrollList
ListLayout.Padding = UDim.new(0, 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- ==============================================================================
-- 🛠️ UI COMPONENT BUILDERS (Toggles, Sliders, Reset)
-- ==============================================================================

-- 1. Helper Toggle Component
local function createToggle(title, defaultState, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
    ToggleFrame.Parent = ScrollList

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = ToggleFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(35, 38, 55)
    Stroke.Thickness = 1
    Stroke.Parent = ToggleFrame

    local Title = Instance.new("TextLabel")
    Title.Parent = ToggleFrame
    Title.Size = UDim2.new(1, -65, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = Color3.fromRGB(220, 225, 240)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamMedium
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 44, 0, 22)
    Switch.Position = UDim2.new(1, -54, 0.5, -11)
    Switch.BackgroundColor3 = defaultState and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(45, 48, 65)
    Switch.Text = ""
    Switch.AutoButtonColor = false
    Switch.Parent = ToggleFrame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 16, 0, 16)
    Circle.Position = defaultState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = Switch

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local isEnabled = defaultState

    local function setToggle(val)
        isEnabled = val
        local targetColor = isEnabled and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(45, 48, 65)
        local targetPos = isEnabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)

        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = targetPos}):Play()

        callback(isEnabled)
    end

    Switch.MouseButton1Click:Connect(function()
        setToggle(not isEnabled)
    end)

    return {
        Frame = ToggleFrame,
        Set = setToggle
    }
end

-- 2. Helper Slider Component
local function createSlider(title, minVal, maxVal, defaultVal, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 60)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
    SliderFrame.Parent = ScrollList

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = SliderFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(35, 38, 55)
    Stroke.Thickness = 1
    Stroke.Parent = SliderFrame

    local Title = Instance.new("TextLabel")
    Title.Parent = SliderFrame
    Title.Size = UDim2.new(1, -70, 0, 25)
    Title.Position = UDim2.new(0, 12, 0, 4)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = Color3.fromRGB(220, 225, 240)
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamMedium
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Parent = SliderFrame
    ValueLabel.Size = UDim2.new(0, 50, 0, 25)
    ValueLabel.Position = UDim2.new(1, -62, 0, 4)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(defaultVal)
    ValueLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    ValueLabel.TextSize = 13
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- Slider Track
    local Track = Instance.new("TextButton")
    Track.Name = "Track"
    Track.Size = UDim2.new(1, -24, 0, 8)
    Track.Position = UDim2.new(0, 12, 0, 38)
    Track.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
    Track.Text = ""
    Track.AutoButtonColor = false
    Track.Parent = SliderFrame

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    local initialRatio = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    Fill.Size = UDim2.new(initialRatio, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local isDragging = false

    local function updateValue(input)
        local trackAbsPos = Track.AbsolutePosition.X
        local trackAbsSize = Track.AbsoluteSize.X
        local mousePos = input.Position.X
        local ratio = math.clamp((mousePos - trackAbsPos) / trackAbsSize, 0, 1)
        local value = math.floor(minVal + (maxVal - minVal) * ratio)

        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        ValueLabel.Text = tostring(value)
        callback(value)
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)

    return {
        Frame = SliderFrame,
        SetValue = function(v)
            local ratio = math.clamp((v - minVal) / (maxVal - minVal), 0, 1)
            Fill.Size = UDim2.new(ratio, 0, 1, 0)
            ValueLabel.Text = tostring(v)
            callback(v)
        end
    }
end

-- ==============================================================================
-- 🚀 MEMBUAT SEMUA FITUR DI UI
-- ==============================================================================

-- 1. WALKSPEED (Toggle + Slider)
local speedToggle = createToggle("🏃 Enable Custom WalkSpeed", false, function(enabled)
    State.SpeedEnabled = enabled
    updatePlayerStats()
end)

local speedSlider = createSlider("⚡ WalkSpeed Value", 16, 300, 16, function(val)
    State.WalkSpeed = val
    if State.SpeedEnabled then
        updatePlayerStats()
    end
end)

-- 2. JUMPPOWER (Toggle + Slider)
local jumpToggle = createToggle("🦘 Enable Custom JumpPower", false, function(enabled)
    State.JumpEnabled = enabled
    updatePlayerStats()
end)

local jumpSlider = createSlider("💥 JumpPower Value", 50, 400, 50, function(val)
    State.JumpPower = val
    if State.JumpEnabled then
        updatePlayerStats()
    end
end)

-- 3. FLY (Toggle + FlySpeed Slider)
local flyToggle = createToggle("🕊️ Fly (Terbang) [PC: F / WASD]", false, function(enabled)
    if enabled then
        startFly()
    else
        stopFly()
    end
end)

local flySlider = createSlider("🚀 Fly Speed", 10, 200, 50, function(val)
    State.FlySpeed = val
end)

-- Shortcut tombol keyboard 'F' untuk toggle Fly di PC
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        local newState = not State.FlyEnabled
        flyToggle.Set(newState)
    end
end)

-- 4. NOCLIP (Toggle)
local noclipToggle = createToggle("👻 Noclip (Tembus Tembok)", false, function(enabled)
    toggleNoclip(enabled)
end)

-- 5. INFINITE JUMP (Toggle)
local infJumpToggle = createToggle("🤾 Infinite Jump (Lompat Udara)", false, function(enabled)
    toggleInfiniteJump(enabled)
end)

-- 6. TOMBOL RESET SEMUA STAT
local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, 0, 0, 38)
ResetBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
ResetBtn.Text = "🔄 Reset Stats to Default"
ResetBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
ResetBtn.TextSize = 13
ResetBtn.Font = Enum.Font.GothamBold
ResetBtn.Parent = ScrollList

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 8)
ResetCorner.Parent = ResetBtn

local ResetStroke = Instance.new("UIStroke")
ResetStroke.Color = Color3.fromRGB(70, 35, 45)
ResetStroke.Thickness = 1
ResetStroke.Parent = ResetBtn

ResetBtn.MouseButton1Click:Connect(function()
    speedToggle.Set(false)
    jumpToggle.Set(false)
    flyToggle.Set(false)
    noclipToggle.Set(false)
    infJumpToggle.Set(false)

    speedSlider.SetValue(16)
    jumpSlider.SetValue(50)
    flySlider.SetValue(50)

    State.WalkSpeed = 16
    State.JumpPower = 50
    State.FlySpeed = 50

    updatePlayerStats()

    ResetBtn.Text = "✅ Reset Berhasil!"
    task.wait(0.8)
    ResetBtn.Text = "🔄 Reset Stats to Default"
end)

print("[Rakahub] Player features loaded successfully!")
