-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("✅ Script starting...")

-- ===== ФУНКЦИИ =====
local function GetMoney()
    local money = 0
    pcall(function()
        for _, child in pairs(LocalPlayer:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                if child.Name:lower():find("money") or child.Name:lower():find("cash") or child.Name:lower():find("coin") then
                    money = child.Value
                    break
                end
            end
        end
        if money == 0 then
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in pairs(leaderstats:GetChildren()) do
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        money = stat.Value
                        break
                    end
                end
            end
        end
    end)
    return money
end

local function FindButtons()
    local buttons = {}
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            pcall(function()
                local cd = obj:FindFirstChildOfClass("ClickDetector")
                if cd then
                    local name = obj.Name:lower()
                    if name:find("rebirth") or name:find("button") or name:find("buy") then
                        table.insert(buttons, {
                            Object = obj,
                            ClickDetector = cd,
                            Position = obj:IsA("BasePart") and obj.Position or nil,
                            Name = obj.Name
                        })
                    end
                end
            end)
        end
        
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local name = remote.Name:lower()
                if name:find("rebirth") or name:find("buy") then
                    table.insert(buttons, {
                        Object = remote,
                        Type = "Remote",
                        Name = remote.Name,
                        Position = nil
                    })
                end
            end
        end
    end)
    return buttons
end

-- ===== ПЕРЕМЕННЫЕ =====
local isFarming = false
local isBuying = false
local totalClicks = 0
local totalCollected = 0
local guiHidden = false
local lastAction = tick()

-- ===== СТЕЛС РЕЖИМ =====
local AFKPosition = nil

local function EnableAFK()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        AFKPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
        pcall(function()
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
        end)
        print("👻 AFK Mode ON - Position saved")
    end
end

local function DisableAFK()
    AFKPosition = nil
    pcall(function()
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
    end)
    print("👻 AFK Mode OFF")
end

local function BuyRemote(button)
    if button.Type == "Remote" then
        pcall(function()
            button.Object:FireServer()
            totalClicks = totalClicks + 1
            print("🌐 Remote buy: " .. button.Name)
        end)
        return true
    end
    
    if button.ClickDetector then
        -- Ищем RemoteEvent для этой кнопки
        pcall(function()
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") and remote.Name:lower():find("click") then
                    remote:FireServer(button.Object)
                    totalClicks = totalClicks + 1
                    print("🌐 Remote buy via click: " .. button.Name)
                    return true
                end
            end
        end)
    end
    
    return false
end

-- ===== GUI =====
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "StealthGUI_Main"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 250, 0, 180)
    mainFrame.Position = UDim2.new(1, -260, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "🛡️ STEALTH FARM v3"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.Parent = mainFrame
    
    -- Деньги
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Name = "MoneyLabel"
    moneyLabel.Size = UDim2.new(1, -20, 0, 25)
    moneyLabel.Position = UDim2.new(0, 10, 0, 30)
    moneyLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    moneyLabel.Text = "💵 Money: " .. GetMoney()
    moneyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    moneyLabel.Font = Enum.Font.GothamBold
    moneyLabel.TextSize = 14
    moneyLabel.Parent = mainFrame
    
    local moneyCorner = Instance.new("UICorner")
    moneyCorner.CornerRadius = UDim.new(0, 4)
    moneyCorner.Parent = moneyLabel
    
    -- Статус
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: READY"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- Кнопки
    local afkBtn = Instance.new("TextButton")
    afkBtn.Name = "AFKBtn"
    afkBtn.Size = UDim2.new(1, -20, 0, 25)
    afkBtn.Position = UDim2.new(0, 10, 0, 85)
    afkBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    afkBtn.Text = "👻 AFK MODE: OFF"
    afkBtn.TextColor3 = Color3.new(1, 1, 1)
    afkBtn.Font = Enum.Font.GothamBold
    afkBtn.TextSize = 11
    afkBtn.Parent = mainFrame
    
    local afkCorner = Instance.new("UICorner")
    afkCorner.CornerRadius = UDim.new(0, 4)
    afkCorner.Parent = afkBtn
    
    local buyBtn = Instance.new("TextButton")
    buyBtn.Name = "BuyBtn"
    buyBtn.Size = UDim2.new(1, -20, 0, 25)
    buyBtn.Position = UDim2.new(0, 10, 0, 113)
    buyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    buyBtn.Text = "🛒 START BUY (B)"
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 11
    buyBtn.Parent = mainFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 4)
    buyCorner.Parent = buyBtn
    
    local panicBtn = Instance.new("TextButton")
    panicBtn.Name = "PanicBtn"
    panicBtn.Size = UDim2.new(1, -20, 0, 25)
    panicBtn.Position = UDim2.new(0, 10, 0, 141)
    panicBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    panicBtn.Text = "🛑 PANIC STOP (DELETE)"
    panicBtn.TextColor3 = Color3.new(1, 1, 1)
    panicBtn.Font = Enum.Font.GothamBold
    panicBtn.TextSize = 11
    panicBtn.Parent = mainFrame
    
    local panicCorner = Instance.new("UICorner")
    panicCorner.CornerRadius = UDim.new(0, 4)
    panicCorner.Parent = panicBtn
    
    return {
        Gui = gui,
        Frame = mainFrame,
        MoneyLabel = moneyLabel,
        StatusLabel = statusLabel,
        AFKBtn = afkBtn,
        BuyBtn = buyBtn,
        PanicBtn = panicBtn
    }
end

-- Создаем GUI
local GUI = CreateGUI()
print("✅ GUI created")

-- ===== ОБРАБОТЧИКИ КНОПОК =====
GUI.AFKBtn.MouseButton1Click:Connect(function()
    if AFKPosition then
        DisableAFK()
        GUI.AFKBtn.Text = "👻 AFK MODE: OFF"
        GUI.AFKBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        EnableAFK()
        GUI.AFKBtn.Text = "👻 AFK MODE: ON"
        GUI.AFKBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

GUI.BuyBtn.MouseButton1Click:Connect(function()
    isBuying = not isBuying
    if isBuying then
        GUI.BuyBtn.Text = "🛒 STOP BUY (B)"
        GUI.BuyBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        GUI.StatusLabel.Text = "Status: BUYING..."
        GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
        print("🛒 Buying started")
    else
        GUI.BuyBtn.Text = "🛒 START BUY (B)"
        GUI.BuyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        GUI.StatusLabel.Text = "Status: STOPPED"
        GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        print("🛒 Buying stopped")
    end
end)

GUI.PanicBtn.MouseButton1Click:Connect(function()
    isBuying = false
    isFarming = false
    GUI.Frame.Visible = false
    DisableAFK()
    print("🛑 PANIC! All stopped")
end)

-- ===== ГОРЯЧИЕ КЛАВИШИ =====
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.B then
        -- Переключаем покупку
        isBuying = not isBuying
        if isBuying then
            GUI.BuyBtn.Text = "🛒 STOP BUY (B)"
            GUI.BuyBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            GUI.StatusLabel.Text = "Status: BUYING..."
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
        else
            GUI.BuyBtn.Text = "🛒 START BUY (B)"
            GUI.BuyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            GUI.StatusLabel.Text = "Status: STOPPED"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    elseif input.KeyCode == Enum.KeyCode.G then
        -- AFK переключение
        if AFKPosition then
            DisableAFK()
            GUI.AFKBtn.Text = "👻 AFK MODE: OFF"
            GUI.AFKBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        else
            EnableAFK()
            GUI.AFKBtn.Text = "👻 AFK MODE: ON"
            GUI.AFKBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        -- Паника
        isBuying = false
        isFarming = false
        GUI.Frame.Visible = false
        DisableAFK()
        print("🛑 PANIC DELETE! All stopped")
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        -- Скрыть/показать GUI
        GUI.Frame.Visible = not GUI.Frame.Visible
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ ПОКУПКИ =====
task.spawn(function()
    while true do
        if isBuying then
            pcall(function()
                local buttons = FindButtons()
                
                if #buttons > 0 then
                    -- Сортируем ближайшие
                    if AFKPosition == nil and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        table.sort(buttons, function(a, b)
                            if not a.Position or not b.Position then return false end
                            return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                        end)
                    end
                    
                    -- Покупаем через Remote
                    if #buttons > 0 then
                        BuyRemote(buttons[1])
                    end
                else
                    GUI.StatusLabel.Text = "Status: Searching..."
                end
                
                -- Обновляем GUI
                GUI.MoneyLabel.Text = "💵 Money: " .. GetMoney()
                
                -- Случайная задержка 2-4 секунды
                task.wait(math.random(20, 40) / 10)
            end)
        else
            task.wait(1)
        end
    end
end)

print("=" .. string.rep("=", 50))
print("✅ SCRIPT LOADED SUCCESSFULLY!")
print("📋 Controls:")
print("   B - Start/Stop Buying")
print("   G - Toggle AFK Mode")
print("   Delete - Panic Stop")
print("   RightCtrl - Hide GUI")
print("=" .. string.rep("=", 50))
