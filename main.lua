-- GameSync SAFE - No Ban Version
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Тишина
local function noop() end
print = noop
warn = noop

-- Состояния
local isFarming = false
local isRebirthing = false

-- Получение денег
local function GetMoney()
    local money = 0
    pcall(function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            for _, v in pairs(ls:GetChildren()) do
                if v:IsA("IntValue") then
                    money = v.Value
                    break
                end
            end
        end
    end)
    return money
end

-- Поиск ближайшего объекта (без телепортации!)
local function FindNearest(maxDist)
    local nearest = nil
    local minDist = maxDist or 15
    
    pcall(function()
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            pcall(function()
                if not obj:IsA("BasePart") then return end
                
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < minDist then
                    local hasPrompt = obj:FindFirstChildOfClass("ProximityPrompt")
                    local hasClick = obj:FindFirstChildOfClass("ClickDetector")
                    
                    if hasPrompt or hasClick then
                        nearest = obj
                        minDist = dist
                    end
                end
            end)
        end
    end)
    
    return nearest
end

-- БЕЗОПАСНАЯ активация (без fire-функций!)
local function SafeActivate(obj)
    pcall(function()
        local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
        local click = obj:FindFirstChildOfClass("ClickDetector")
        
        if prompt then
            prompt:InputHoldBegin()
            task.wait(0.5)
            prompt:InputHoldEnd()
        elseif click then
            local pos = Camera:WorldToScreenPoint(obj.Position)
            if pos.Z > 0 then
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, nil, 0)
                task.wait(0.15)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, nil, 0)
            end
        end
    end)
end

-- GUI (4 кнопки)
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "_"
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 130)
    frame.Position = UDim2.new(1, -190, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    
    -- Деньги
    local moneyText = Instance.new("TextLabel")
    moneyText.Size = UDim2.new(1, -15, 0, 18)
    moneyText.Position = UDim2.new(0, 8, 0, 5)
    moneyText.BackgroundTransparency = 1
    moneyText.Text = "$" .. GetMoney()
    moneyText.TextColor3 = Color3.fromRGB(255, 200, 0)
    moneyText.Font = Enum.Font.GothamBold
    moneyText.TextSize = 11
    moneyText.TextXAlignment = Enum.TextXAlignment.Left
    moneyText.Parent = frame
    
    -- Кнопка 1
    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(1, -16, 0, 22)
    btn1.Position = UDim2.new(0, 8, 0, 26)
    btn1.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn1.Text = "FARM (F)"
    btn1.TextColor3 = Color3.new(1, 1, 1)
    btn1.Font = Enum.Font.GothamBold
    btn1.TextSize = 10
    btn1.AutoButtonColor = false
    btn1.Parent = frame
    
    -- Кнопка 2
    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(1, -16, 0, 22)
    btn2.Position = UDim2.new(0, 8, 0, 50)
    btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn2.Text = "REBIRTH (R)"
    btn2.TextColor3 = Color3.new(1, 1, 1)
    btn2.Font = Enum.Font.GothamBold
    btn2.TextSize = 10
    btn2.AutoButtonColor = false
    btn2.Parent = frame
    
    -- Кнопка 3
    local btn3 = Instance.new("TextButton")
    btn3.Size = UDim2.new(1, -16, 0, 22)
    btn3.Position = UDim2.new(0, 8, 0, 74)
    btn3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn3.Text = "HIDE (H)"
    btn3.TextColor3 = Color3.new(1, 1, 1)
    btn3.Font = Enum.Font.GothamBold
    btn3.TextSize = 10
    btn3.AutoButtonColor = false
    btn3.Parent = frame
    
    -- Кнопка 4
    local btn4 = Instance.new("TextButton")
    btn4.Size = UDim2.new(1, -16, 0, 22)
    btn4.Position = UDim2.new(0, 8, 0, 98)
    btn4.BackgroundColor3 = Color3.fromRGB(50, 15, 15)
    btn4.Text = "EXIT (DEL)"
    btn4.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn4.Font = Enum.Font.GothamBold
    btn4.TextSize = 10
    btn4.AutoButtonColor = false
    btn4.Parent = frame
    
    -- Обработчики
    btn1.MouseButton1Click:Connect(function()
        isFarming = not isFarming
        isRebirthing = false
        btn1.BackgroundColor3 = isFarming and Color3.fromRGB(60, 30, 30) or Color3.fromRGB(40, 40, 40)
        btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    
    btn2.MouseButton1Click:Connect(function()
        isRebirthing = not isRebirthing
        isFarming = false
        btn2.BackgroundColor3 = isRebirthing and Color3.fromRGB(60, 30, 30) or Color3.fromRGB(40, 40, 40)
        btn1.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    
    btn3.MouseButton1Click:Connect(function()
        frame.Visible = not frame.Visible
    end)
    
    btn4.MouseButton1Click:Connect(function()
        isFarming = false
        isRebirthing = false
        gui:Destroy()
    end)
    
    return {Frame = frame, MoneyText = moneyText, Btn1 = btn1, Btn2 = btn2}
end

local GUI = CreateGUI()

-- Главный цикл
task.spawn(function()
    while true do
        pcall(function()
            GUI.MoneyText.Text = "$" .. GetMoney()
            
            if isFarming or isRebirthing then
                local obj = FindNearest(20)
                
                if obj then
                    local name = obj.Name:lower()
                    
                    if isRebirthing then
                        if name:find("rebirth") or name:find("reborn") then
                            SafeActivate(obj)
                        end
                    end
                    
                    if isFarming then
                        SafeActivate(obj)
                    end
                end
            end
        end)
        
        task.wait(math.random(30, 60) / 10) -- 3-6 секунд
    end
end)

-- Горячие клавиши
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        isFarming = not isFarming
        isRebirthing = false
        GUI.Btn1.BackgroundColor3 = isFarming and Color3.fromRGB(60, 30, 30) or Color3.fromRGB(40, 40, 40)
        GUI.Btn2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    elseif input.KeyCode == Enum.KeyCode.R then
        isRebirthing = not isRebirthing
        isFarming = false
        GUI.Btn2.BackgroundColor3 = isRebirthing and Color3.fromRGB(60, 30, 30) or Color3.fromRGB(40, 40, 40)
        GUI.Btn1.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    elseif input.KeyCode == Enum.KeyCode.H then
        GUI.Frame.Visible = not GUI.Frame.Visible
    elseif input.KeyCode == Enum.KeyCode.Delete then
        isFarming = false
        isRebirthing = false
        GUI.Frame:Destroy()
    end
end)
