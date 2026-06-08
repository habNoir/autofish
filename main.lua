-- [[ AUTO FISHING INDO VOICE made by habNoir ]]
-- Custom Premium Hub V2.0 (Window-Shade Minimize, Keybind, & About Tab)
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- ===================== CONFIGURATION =====================
local MOOD_AXIS = "Y"

_G.IV_Fishing_Active  = false
_G.AutoPauseThreshold = 30
_G.AutoPauseEnabled   = true
_G.CastDelay          = 0.2
_G.CastHoldTime       = 0.0
_G.ClickSpeed         = 0.035
_G.HideKeybind        = Enum.KeyCode.RightControl -- Default Keybind Hide/Show

local isResting    = false
local pingHistory  = {}
local MAX_HISTORY  = 10
local isMinimized  = false

-- ===================== PREMIUM THEME COLORS =====================
local Theme = {
    Background = Color3.fromRGB(13, 8, 20),      -- Very Dark Violet
    Container  = Color3.fromRGB(22, 14, 33),     -- Component Background
    Hover      = Color3.fromRGB(30, 20, 45),     -- Component Hover
    TextMain   = Color3.fromRGB(245, 245, 250),
    TextMuted  = Color3.fromRGB(150, 140, 170),
    Stroke     = Color3.fromRGB(45, 30, 65),     -- Normal Border
    
    Success    = Color3.fromRGB(50, 220, 100),
    Warning    = Color3.fromRGB(255, 180, 50),
    Danger     = Color3.fromRGB(255, 70, 70),
    
    GradientColors = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 30, 60)),   -- Red
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 45, 105)),  -- Pink
        ColorSequenceKeypoint.new(0.70, Color3.fromRGB(210, 30, 180)),  -- Magenta
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(130, 40, 255))   -- Purple
    })
}

-- Cleanup Old UI
for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "HabNoirHub" then v:Destroy() end end
for _, v in pairs(playerGui:GetChildren()) do if v.Name == "HabNoirHub" then v:Destroy() end end

-- ===================== UI FRAMEWORK (CORE) =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HabNoirHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui:FindFirstChild("RobloxGui") and CoreGui or playerGui

-- Main Hub Window
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 340, 0, 420)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -210)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.ClipsDescendants = true -- Penting untuk efek Minimize (Shade roll-up)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Main Premium Gradient Stroke
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1.5
local MainGradient = Instance.new("UIGradient", MainStroke)
MainGradient.Color = Theme.GradientColors
MainGradient.Rotation = 45

-- Draggable Logic for MainFrame (Mobile + PC)
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Hanya drag jika di area Header (Y < 40)
        local relativeY = input.Position.Y - MainFrame.AbsolutePosition.Y
        if relativeY <= 40 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Global Hide/Show Keybind Logic
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == _G.HideKeybind then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Top Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "INDO VOICE  •  habNoir"
Title.TextColor3 = Theme.TextMain
Title.TextSize = 13
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Header Buttons (Minimize & Close)
local ControlContainer = Instance.new("Frame", Header)
ControlContainer.Size = UDim2.new(0, 60, 1, 0)
ControlContainer.Position = UDim2.new(1, -70, 0, 0)
ControlContainer.BackgroundTransparency = 1

local MinBtn = Instance.new("TextButton", ControlContainer)
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Position = UDim2.new(0, 0, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = Theme.TextMuted
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold

local CloseBtn = Instance.new("TextButton", ControlContainer)
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(0, 30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextMuted
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold

-- Window Control Logic
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        -- Naik ke atas memendek (Window Shade)
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 340, 0, 40)}):Play()
        MinBtn.Text = "☐"
        MinBtn.TextColor3 = Theme.TextMain
    else
        -- Memanjang kembali kebawah
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 340, 0, 420)}):Play()
        MinBtn.Text = "—"
        MinBtn.TextColor3 = Theme.TextMuted
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- Sembunyikan UI
    MainFrame.Visible = false
    -- Animasi feedback kecil
    CloseBtn.TextColor3 = Theme.Danger
    task.wait(0.2)
    CloseBtn.TextColor3 = Theme.TextMuted
end)

-- Hover effect Header Buttons
MinBtn.MouseEnter:Connect(function() MinBtn.TextColor3 = Theme.TextMain end)
MinBtn.MouseLeave:Connect(function() if not isMinimized then MinBtn.TextColor3 = Theme.TextMuted end end)
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Danger end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextMuted end)

-- Separator Line
local HeaderLine = Instance.new("Frame", MainFrame)
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 0, 40)
HeaderLine.BorderSizePixel = 0
Instance.new("UIGradient", HeaderLine).Color = Theme.GradientColors

-- Tab Buttons Container
local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(1, -30, 0, 32)
TabContainer.Position = UDim2.new(0, 15, 0, 48)
TabContainer.BackgroundTransparency = 1
local TabListLayout = Instance.new("UIListLayout", TabContainer)
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 6)

-- Pages Container
local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -30, 1, -95)
PageContainer.Position = UDim2.new(0, 15, 0, 85)
PageContainer.BackgroundTransparency = 1

local CurrentTabBtn = nil
local CurrentPage = nil

-- ===================== COMPONENT BUILDERS =====================
local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", TabContainer)
    TabBtn.Size = UDim2.new(0, 72, 1, 0)
    TabBtn.BackgroundColor3 = Theme.Container
    TabBtn.Text = name
    TabBtn.TextColor3 = Theme.TextMuted
    TabBtn.TextSize = 10
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.AutoButtonColor = false
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)
    
    local Stroke = Instance.new("UIStroke", TabBtn)
    Stroke.Color = Theme.Stroke
    Stroke.Thickness = 1
    
    local Page = Instance.new("ScrollingFrame", PageContainer)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.TextMuted
    Page.Visible = false
    Page.BorderSizePixel = 0
    
    local PageLayout = Instance.new("UIListLayout", Page)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 8)
    
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 5)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        if CurrentTabBtn then
            TweenService:Create(CurrentTabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Container}):Play()
            CurrentTabBtn.TextColor3 = Theme.TextMuted
            CurrentTabBtn.UIStroke.Color = Theme.Stroke
            CurrentPage.Visible = false
        end
        CurrentTabBtn = TabBtn
        CurrentPage = Page
        
        TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Hover}):Play()
        TabBtn.TextColor3 = Theme.TextMain
        TabBtn.UIStroke.Color = Color3.fromRGB(255, 45, 105) 
        Page.Visible = true
    end)

    if not CurrentTabBtn then
        TabBtn.BackgroundColor3 = Theme.Hover
        TabBtn.TextColor3 = Theme.TextMain
        Stroke.Color = Color3.fromRGB(255, 45, 105)
        Page.Visible = true
        CurrentTabBtn = TabBtn
        CurrentPage = Page
    end

    return Page
end

local function CreateSection(page, titleText)
    local Sec = Instance.new("TextLabel", page)
    Sec.Size = UDim2.new(1, 0, 0, 20)
    Sec.BackgroundTransparency = 1
    Sec.Text = titleText
    Sec.TextColor3 = Theme.TextMain
    Sec.TextSize = 12
    Sec.Font = Enum.Font.GothamBold
    Sec.TextXAlignment = Enum.TextXAlignment.Left
end

local function CreateLabel(page, defaultText)
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, 0, 0, 32)
    Frame.BackgroundColor3 = Theme.Container
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", Frame).Color = Theme.Stroke
    
    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(1, -20, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = defaultText
    Lbl.TextColor3 = Theme.TextMuted
    Lbl.TextSize = 11
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    return Lbl
end

local function CreateToggle(page, text, default, callback)
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Theme.Container
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", Frame).Color = Theme.Stroke
    
    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(0.7, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.TextMain
    Lbl.TextSize = 11
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local SwitchBg = Instance.new("TextButton", Frame)
    SwitchBg.Size = UDim2.new(0, 36, 0, 20)
    SwitchBg.Position = UDim2.new(1, -46, 0.5, -10)
    SwitchBg.BackgroundColor3 = default and Color3.fromRGB(255, 45, 105) or Theme.Background
    SwitchBg.Text = ""
    SwitchBg.AutoButtonColor = false
    Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", SwitchBg).Color = Theme.Stroke
    
    local SwitchKnob = Instance.new("Frame", SwitchBg)
    SwitchKnob.Size = UDim2.new(0, 14, 0, 14)
    SwitchKnob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    SwitchKnob.BackgroundColor3 = Theme.TextMain
    Instance.new("UICorner", SwitchKnob).CornerRadius = UDim.new(1, 0)
    
    local state = default
    SwitchBg.MouseButton1Click:Connect(function()
        state = not state
        local goalColor = state and Color3.fromRGB(255, 45, 105) or Theme.Background
        local goalPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        
        TweenService:Create(SwitchBg, TweenInfo.new(0.3), {BackgroundColor3 = goalColor}):Play()
        TweenService:Create(SwitchKnob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = goalPos}):Play()
        callback(state)
    end)
end

local function CreateSlider(page, text, min, max, default, decimals, callback)
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, 0, 0, 50)
    Frame.BackgroundColor3 = Theme.Container
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", Frame).Color = Theme.Stroke
    
    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(0.7, 0, 0, 20)
    Lbl.Position = UDim2.new(0, 10, 0, 6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.TextMain
    Lbl.TextSize = 11
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local ValLbl = Instance.new("TextLabel", Frame)
    ValLbl.Size = UDim2.new(0.3, 0, 0, 20)
    ValLbl.Position = UDim2.new(0.7, -10, 0, 6)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = tostring(default)
    ValLbl.TextColor3 = Color3.fromRGB(255, 45, 105)
    ValLbl.TextSize = 11
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local Track = Instance.new("Frame", Frame)
    Track.Size = UDim2.new(1, -20, 0, 6)
    Track.Position = UDim2.new(0, 10, 0, 34)
    Track.BackgroundColor3 = Theme.Background
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
    
    local Fill = Instance.new("Frame", Track)
    local pct = (default - min) / (max - min)
    Fill.Size = UDim2.new(pct, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    Instance.new("UIGradient", Fill).Color = Theme.GradientColors
    
    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * pos
        local fmt = "%." .. decimals .. "f"
        val = tonumber(string.format(fmt, val))
        
        TweenService:Create(Fill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        ValLbl.Text = val == 0 and "Random" or tostring(val)
        callback(val)
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function CreateButton(page, text, callback)
    local Btn = Instance.new("TextButton", page)
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Theme.Container
    Btn.Text = text
    Btn.TextColor3 = Theme.TextMain
    Btn.TextSize = 11
    Btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", Btn).Color = Theme.Stroke
    
    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Hover}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Container}):Play()
        callback()
    end)
end

local function CreateKeybind(page, text, defaultKey, callback)
    local Frame = Instance.new("Frame", page)
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Theme.Container
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", Frame).Color = Theme.Stroke
    
    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(0.6, 0, 1, 0)
    Lbl.Position = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.TextColor3 = Theme.TextMain
    Lbl.TextSize = 11
    Lbl.Font = Enum.Font.GothamSemibold
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local BindBtn = Instance.new("TextButton", Frame)
    BindBtn.Size = UDim2.new(0, 80, 0, 22)
    BindBtn.Position = UDim2.new(1, -90, 0.5, -11)
    BindBtn.BackgroundColor3 = Theme.Background
    BindBtn.Text = defaultKey.Name
    BindBtn.TextColor3 = Theme.TextMain
    BindBtn.TextSize = 10
    BindBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", BindBtn).Color = Theme.Stroke
    
    local listening = false
    BindBtn.MouseButton1Click:Connect(function()
        listening = true
        BindBtn.Text = "..."
        BindBtn.TextColor3 = Color3.fromRGB(255, 45, 105)
    end)
    
    UserInputService.InputBegan:Connect(function(input)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            local newKey = input.KeyCode
            BindBtn.Text = newKey.Name
            BindBtn.TextColor3 = Theme.TextMain
            callback(newKey)
        end
    end)
end


-- ===================== BUILDING UI CONTENT =====================
local Tab1 = CreateTab("Utama")
local Tab2 = CreateTab("Stats")
local Tab3 = CreateTab("Pengaturan")
local Tab4 = CreateTab("About")

-- Tab: Utama
CreateSection(Tab1, "Kontrol Utama")
local StatusLbl = CreateLabel(Tab1, "Status : MATI")

CreateToggle(Tab1, "Auto Fishing (Start/Stop)", false, function(val)
    _G.IV_Fishing_Active = val
    isResting = false
    if val then
        StatusLbl.Text = "Status : AKTIF"
        StatusLbl.TextColor3 = Theme.Success
    else
        StatusLbl.Text = "Status : MATI"
        StatusLbl.TextColor3 = Theme.TextMuted
    end
end)
CreateToggle(Tab1, "Auto-Pause (<" .. _G.AutoPauseThreshold .. "% Mood)", true, function(val)
    _G.AutoPauseEnabled = val
end)

-- Tab: Stats
CreateSection(Tab2, "Kondisi Karakter")
local MoodLbl = CreateLabel(Tab2, "Mood : Menghubungkan...")
local ProxLbl = CreateLabel(Tab2, "Teman Sekitar : --")

CreateSection(Tab2, "Jaringan Server")
local PingLbl = CreateLabel(Tab2, "RTT / Jitter : --")
local StabilLbl = CreateLabel(Tab2, "Koneksi Stabil : --")

-- Tab: Pengaturan
CreateSection(Tab3, "Tampilan & UI")
CreateKeybind(Tab3, "Hide/Show UI", _G.HideKeybind, function(newKey)
    _G.HideKeybind = newKey
end)

CreateSection(Tab3, "Parameter Memancing")
CreateSlider(Tab3, "Batas Pause / Rest", 5, 95, _G.AutoPauseThreshold, 0, function(val) _G.AutoPauseThreshold = val end)
CreateSlider(Tab3, "Delay Cast (Detik)", 0, 5, _G.CastDelay, 1, function(val) _G.CastDelay = val end)
CreateSlider(Tab3, "Cast Power", 0, 1, _G.CastHoldTime, 2, function(val) _G.CastHoldTime = val end)
CreateSlider(Tab3, "Click Speed", 0.005, 0.1, _G.ClickSpeed, 3, function(val) _G.ClickSpeed = val end)

-- Tab: About
CreateSection(Tab4, "Informasi Script")
CreateLabel(Tab4, "Developer : habNoir")
CreateLabel(Tab4, "Version : V2.0 Premium Custom")
CreateLabel(Tab4, "Library : Native Luau (No Externals)")

CreateSection(Tab4, "Sosial & Dukungan")
CreateLabel(Tab4, "GitHub : github.com/habNoir")
CreateButton(Tab4, "Salin Link GitHub", function()
    pcall(function()
        setclipboard("https://github.com/habNoir")
    end)
end)


-- ===================== CORE LOGIC & BYPASS =====================
local function getMoodBar()
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return nil end
    local canvas = tool:FindFirstChild("MoodCanvas", true)
    return canvas and canvas:FindFirstChild("Bar")
end

local function getProximityCount()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local rp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if rp and (hrp.Position - rp.Position).Magnitude <= 30 then count = count + 1 end
        end
    end
    return count
end

local function getScreenCenter()
    return camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
end

local function simulateHoldClick(x, y, duration)
    VirtualInputManager:SendMouseMoveEvent(x, y, game)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(duration)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
end

-- Ping & Jitter Thread
task.spawn(function()
    while true do
        local rtt = player:GetNetworkPing() * 1000
        if rtt <= 0 then rtt = 45.0 end
        table.insert(pingHistory, rtt)
        if #pingHistory > MAX_HISTORY then table.remove(pingHistory, 1) end

        local jitter = 0
        if #pingHistory > 1 then
            local sum = 0
            for i = 2, #pingHistory do sum = sum + math.abs(pingHistory[i] - pingHistory[i - 1]) end
            jitter = sum / (#pingHistory - 1)
        end

        PingLbl.Text = string.format("RTT: %.1f ms | Jitter: %.2f ms", rtt, jitter)
        if jitter < 50 then
            StabilLbl.Text = "Koneksi Stabil : ✓ Ya"
            StabilLbl.TextColor3 = Theme.Success
        else
            StabilLbl.Text = "Koneksi Stabil : ✗ Tidak"
            StabilLbl.TextColor3 = Theme.Danger
        end
        task.wait(0.5)
    end
end)

-- Stats Thread
task.spawn(function()
    while true do
        local count = getProximityCount()
        local eco = count == 0 and "x0.85" or count == 1 and "x0.95" or count <= 4 and "x1.00" or "x1.15"
        ProxLbl.Text = string.format("Teman Sekitar: %d (Eco %s)", count, eco)

        local bar = getMoodBar()
        if bar then
            local mood = math.round((MOOD_AXIS == "X" and bar.Size.X.Scale or bar.Size.Y.Scale) * 100)
            local resumeLimit = math.clamp(_G.AutoPauseThreshold + 15, 60, 98)

            if mood <= _G.AutoPauseThreshold and not isResting and _G.IV_Fishing_Active then
                isResting = true
            elseif mood >= resumeLimit and isResting then
                isResting = false
            end

            if mood < _G.AutoPauseThreshold then
                if isResting then
                    MoodLbl.Text = string.format("Mood : %d%% [ REGEN-RESTING ]", mood)
                    MoodLbl.TextColor3 = Theme.Warning
                else
                    MoodLbl.Text = string.format("Mood : %d%% [ LOW ]", mood)
                    MoodLbl.TextColor3 = Theme.Danger
                    if _G.AutoPauseEnabled and _G.IV_Fishing_Active then
                        _G.IV_Fishing_Active = false
                        StatusLbl.Text = "Status : TERHENTI (Mood < " .. _G.AutoPauseThreshold .. "!)"
                        StatusLbl.TextColor3 = Theme.Danger
                    end
                end
            else
                MoodLbl.Text = string.format("Mood : %d%%", mood)
                MoodLbl.TextColor3 = Theme.Success
            end
        else
            MoodLbl.Text = "Mood : ⚠ Pegang Joran Dulu!"
            MoodLbl.TextColor3 = Theme.TextMuted
        end
        task.wait(1)
    end
end)

-- Main Automation Thread
task.spawn(function()
    while true do
        if _G.IV_Fishing_Active then
            if isResting then
                StatusLbl.Text = "Status : Istirahat (Regen Mood...)"
                StatusLbl.TextColor3 = Theme.Warning
                task.wait(1)
            else
                local fishingUI = playerGui:FindFirstChild("FishingUI")
                
                if not fishingUI then
                    StatusLbl.Text = "Status : Menunggu Jeda..."
                    StatusLbl.TextColor3 = Theme.TextMain
                    local finalDelay = math.clamp(_G.CastDelay + math.random(-5, 15) / 100, 0.0, 10.0)
                    task.wait(finalDelay)

                    if _G.IV_Fishing_Active and not playerGui:FindFirstChild("FishingUI") and not isResting then
                        StatusLbl.Text = "Status : Melempar Pancing..."
                        local cx, cy = getScreenCenter()
                        local holdTime = _G.CastHoldTime > 0 and _G.CastHoldTime or math.random(20, 100) / 100
                        simulateHoldClick(cx, cy, holdTime)

                        local elapsed = 0
                        while _G.IV_Fishing_Active and not playerGui:FindFirstChild("FishingUI") and elapsed < 25 and not isResting do
                            task.wait(0.5)
                            elapsed = elapsed + 0.5
                        end
                    end
                else
                    local preFishing = fishingUI:FindFirstChild("PreFishingHolder")
                    local fishingHolder = fishingUI:FindFirstChild("FishingHolder")
                    local fishingFrame = fishingHolder and fishingHolder:FindFirstChild("FishingFrame")
                    local barContainer = fishingFrame and fishingFrame:FindFirstChild("BarContainer")
                    local bar = barContainer and barContainer:FindFirstChild("Bar")
                    local isMinigameActive = fishingHolder and fishingHolder.Visible

                    -- CLICK IKAN (Multi-Spot Bypass)
                    if preFishing and preFishing.Visible and not isMinigameActive then
                        StatusLbl.Text = "Status : Klik Ikan..."
                        StatusLbl.TextColor3 = Color3.fromRGB(255, 45, 105)
                        
                        for _, child in ipairs(preFishing:GetDescendants()) do
                            if child.Name == "TapImage" and child:IsA("ImageLabel") and child.Visible and child.AbsoluteSize.X > 0 then
                                pcall(function()
                                    if getconnections then
                                        for _, evName in ipairs({"InputBegan", "Activated", "MouseButton1Click", "MouseButton1Down"}) do
                                            pcall(function()
                                                if child[evName] then
                                                    for _, conn in pairs(getconnections(child[evName])) do
                                                        if evName == "InputBegan" then
                                                            conn:Fire({UserInputType = Enum.UserInputType.MouseButton1, UserInputState = Enum.UserInputState.Begin})
                                                        else conn:Fire() end
                                                    end
                                                end
                                            end)
                                        end
                                    end
                                end)
                                
                                local sg = child:FindFirstAncestorOfClass("ScreenGui")
                                local insetY = (sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset().Y or 0
                                local px, py = child.AbsolutePosition.X, child.AbsolutePosition.Y + insetY
                                local sx, sy = child.AbsoluteSize.X, child.AbsoluteSize.Y

                                local spots = {
                                    {px + sx/2, py + sy/2}, {px + sx - 15, py + sy - 15},
                                    {px + 15, py + sy - 15}, {px + sx - 15, py + 15}, {px + 15, py + 15}
                                }
                                for _, s in ipairs(spots) do
                                    VirtualInputManager:SendMouseButtonEvent(s[1], s[2], 0, true, game, 0)
                                    VirtualInputManager:SendMouseButtonEvent(s[1], s[2], 0, false, game, 0)
                                end
                                task.wait(0.01)
                            end
                        end
                    end

                    -- MINIGAME BAR (Klik Hijau)
                    if fishingFrame and fishingFrame.Visible and bar and isMinigameActive then
                        local c = bar.BackgroundColor3
                        if (c.G * 255 - c.R * 255) > 50 then
                            StatusLbl.Text = "Status : Klik Bar Hijau!"
                            StatusLbl.TextColor3 = Theme.Success
                            local mcx, mcy = getScreenCenter()
                            VirtualInputManager:SendMouseButtonEvent(mcx, mcy, 0, true, game, 0)
                            VirtualInputManager:SendMouseButtonEvent(mcx, mcy, 0, false, game, 0)
                            task.wait(_G.ClickSpeed)
                        else
                            StatusLbl.Text = "Status : Menahan Bar..."
                            StatusLbl.TextColor3 = Theme.Warning
                            task.wait(0.05)
                        end
                    end
                end
            end
        else
            task.wait(0.1)
        end
        task.wait(0.05)
    end
end)
