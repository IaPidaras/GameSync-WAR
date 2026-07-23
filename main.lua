-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

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

-- ===== ПЕРЕМЕННЫЕ =====
local isBuying = false
local isCollecting = false
local totalClicks = 0
local totalCollected = 0
local AFKPosition = nil

-- ===== АВТО-СБОР (Free версия доната) =====
local AutoCollectRange = 50

local function FindCollectibles()
    local items = {}
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 1 then
                local name = obj.Name:lower()
                
                -- Предметы для сбора (монеты, гемы, ящики)
                if name:find("coin") or name:find("money") or name:find("cash") or
                   name:find("gem") or name:find("diamond") or
                   name:find("crate") or name:find("chest") or name:find("box") or
                   name:find("collect") then
                    
                    -- ПРОВЕРКА: НЕ трогаем донатные кнопки!
                    if not name:find("donate") and not name:find("premium") and 
                       not name:find("vip") and not name:find("gamepass") then
                        
                        local hasTouch = obj:FindFirstChildOfClass("TouchTransmitter") ~= nil
                        local hasClick = obj:FindFirstChildOfClass("ClickDetector") ~= nil
                        local hasPrompt = obj:FindFirstChildOfClass("ProximityPrompt") ~= nil
                        
                        if hasTouch or hasClick or hasPrompt then
                            table.insert(items, {
                                Object = obj,
                                Position = obj.Position,
                                Name = obj.Name,
                                HasTouch = hasTouch,
                                HasClick = hasClick,
                                HasPrompt = hasPrompt
                            })
                        end
                    end
                end
            end
        end
    end)
    return items
end

local function CollectItem(item)
    if not LocalPlayer.Character then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local distance = (item.Position - hrp.Position).Magnitude
    if distance > AutoCollectRange then return false end
    
    pcall(function()
        -- Подходим к предмету
        if distance > 5 then
            local tween = TweenService:Create(hrp, 
                TweenInfo.new(0.5), 
                {CFrame = CFrame.new(item.Position + Vector3.new(0, 3, 0))})
            tween:Play()
            task.wait(0.3)
        end
        
        -- Собираем через Touch
        if item.HasTouch then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.2)
                humanoid:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end
        
        -- Или через Click
        if item.HasClick then
            local screenPos = Camera:WorldToScreenPoint(item.Position)
            VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, nil, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, nil, 0)
        end
        
        -- Или через Prompt
        if item.HasPrompt then
            local prompt = item.Object:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                prompt:InputHoldBegin()
                task.wait(0.2)
                prompt:InputHoldEnd()
            end
        end
    end)
    
    return true
end

-- ===== ПОИСК КНОПОК ДЛЯ ПОКУПКИ =====
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

-- ===== AFK РЕЖИМ =====
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
end

-- ===== GUI =====
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "StealthGUI"
    gui.Parent = CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 260)
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
    title.Text = "🛡️ STEALTH FARM"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.Parent = mainFrame
    
    -- Деньги
    local moneyLabel = Instance.new("TextLabel")
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
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 60)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: READY"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- ===== КНОПКА АВТО-СБОРА (БЕСПЛАТНЫЙ ДОНАТ) =====
    local collectFrame = Instance.new("Frame")
    collectFrame.Size = UDim2.new(1, -20, 0, 50)
    collectFrame.Position = UDim2.new(0, 10, 0, 85)
    collectFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    collectFrame.BorderSizePixel = 0
    collectFrame.Parent = mainFrame
    
    local collectCorner = Instance.new("UICorner")
    collectCorner.CornerRadius = UDim.new(0, 5)
    collectCorner.Parent = collectFrame
    
    local collectTitle = Instance.new("TextLabel")
    collectTitle.Size = UDim2.new(1, 0, 0, 18)
    collectTitle.BackgroundTransparency = 1
    collectTitle.Text = "🎁 AUTO COLLECT (Free)"
    collectTitle.TextColor3 = Color3.fromRGB(255, 200, 0)
    collectTitle.Font = Enum.Font.GothamBold
    collectTitle.TextSize = 10
    collectTitle.Parent = collectFrame
    
    local collectBtn = Instance.new("TextButton")
    collectBtn.Size = UDim2.new(1, -10, 0, 25)
    collectBtn.Position = UDim2.new(0, 5, 0, 20)
    collectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    collectBtn.Text = "🎁 START COLLECT (C)"
    collectBtn.TextColor3 = Color3.new(1, 1, 1)
    collectBtn.Font = Enum.Font.GothamBold
    collectBtn.TextSize = 11
    collectBtn.Parent = collectFrame
    
    local collectBtnCorner = Instance.new("UICorner")
    collectBtnCorner.CornerRadius = UDim.new(0, 3)
    collectBtnCorner.Parent = collectBtn
    
    -- ===== КНОПКА ПОКУПКИ =====
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(1, -20, 0, 30)
    buyBtn.Position = UDim2.new(0, 10, 0, 140)
    buyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    buyBtn.Text = "🛒 START BUY (B)"
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 11
    buyBtn.Parent = mainFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 5)
    buyCorner.Parent = buyBtn
    
    -- ===== КНОПКА AFK =====
    local afkBtn = Instance.new("TextButton")
    afkBtn.Size = UDim2.new(1, -20, 0, 30)
    afkBtn.Position = UDim2.new(0, 10, 0, 175)
    afkBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    afkBtn.Text = "👻 AFK MODE: OFF (G)"
    afkBtn.TextColor3 = Color3.new(1, 1, 1)
    afkBtn.Font = Enum.Font.GothamBold
    afkBtn.TextSize = 11
    afkBtn.Parent = mainFrame
    
    local afkCorner = Instance.new("UICorner")
    afkCorner.CornerRadius = UDim.new(0, 5)
    afkCorner.Parent = afkBtn
    
    -- ===== КНОПКА ПАНИКИ =====
    local panicBtn = Instance.new("TextButton")
    panicBtn.Size = UDim2.new(1, -20, 0, 30)
    panicBtn.Position = UDim2.new(0, 10, 0, 210)
    panicBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    panicBtn.Text = "🛑 PANIC STOP (DEL)"
    panicBtn.TextColor3 = Color3.new(1, 1, 1)
    panicBtn.Font = Enum.Font.GothamBold
    panicBtn.TextSize = 11
    panicBtn.Parent = mainFrame
    
    local panicCorner = Instance.new("UICorner")
    panicCorner.CornerRadius = UDim.new(0, 5)
    panicCorner.Parent = panicBtn
    
    -- ===== ОБРАБОТЧИКИ =====
    
    -- Кнопка авто-сбора
    collectBtn.MouseButton1Click:Connect(function()
        isCollecting = not isCollecting
        if isCollecting then
            collectBtn.Text = "🎁 STOP COLLECT (C)"
            collectBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            statusLabel.Text = "Status: COLLECTING..."
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            collectBtn.Text = "🎁 START COLLECT (C)"
            collectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            statusLabel.Text = "Status: READY"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end)
    
    -- Кнопка покупки
    buyBtn.MouseButton1Click:Connect(function()
        isBuying = not isBuying
        if isBuying then
            buyBtn.Text = "🛒 STOP BUY (B)"
            buyBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            statusLabel.Text = "Status: BUYING..."
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
        else
            buyBtn.Text = "🛒 START BUY (B)"
            buyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
            statusLabel.Text = "Status: READY"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end)
    
    -- Кнопка AFK
    afkBtn.MouseButton1Click:Connect(function()
        if AFKPosition then
            DisableAFK()
            afkBtn.Text = "👻 AFK MODE: OFF (G)"
            afkBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        else
            EnableAFK()
            afkBtn.Text = "👻 AFK MODE: ON (G)"
            afkBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        end
    end)
    
    -- Кнопка паники
    panicBtn.MouseButton1Click:Connect(function()
        isBuying = false
        isCollecting = false
        DisableAFK()
        mainFrame.Visible = false
        print("🛑 PANIC! All stopped")
    end)
    
    return {
        Gui = gui,
        Frame = mainFrame,
        MoneyLabel = moneyLabel,
        StatusLabel = statusLabel,
        CollectBtn = collectBtn,
        BuyBtn = buyBtn,
        AFKBtn = afkBtn
    }
end

-- Создаем GUI
local GUI = CreateGUI()
print("✅ GUI created with Auto-Collect button!")

-- ===== ГОРЯЧИЕ КЛАВИШИ =====
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.C then
        -- Авто-сбор
        isCollecting = not isCollecting
        if isCollecting then
            GUI.CollectBtn.Text = "🎁 STOP COLLECT (C)"
            GUI.CollectBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            GUI.StatusLabel.Text = "Status: COLLECTING..."
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            GUI.CollectBtn.Text = "🎁 START COLLECT (C)"
            GUI.CollectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            GUI.StatusLabel.Text = "Status: READY"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
        
    elseif input.KeyCode == Enum.KeyCode.B then
        -- Покупка
        isBuying = not isBuying
        if isBuying then
            GUI.BuyBtn.Text = "🛒 STOP BUY (B)"
            GUI.BuyBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        else
            GUI.BuyBtn.Text = "🛒 START BUY (B)"
            GUI.BuyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        end
        
    elseif input.KeyCode == Enum.KeyCode.G then
        -- AFK
        if AFKPosition then
            DisableAFK()
            GUI.AFKBtn.Text = "👻 AFK MODE: OFF (G)"
            GUI.AFKBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        else
            EnableAFK()
            GUI.AFKBtn.Text = "👻 AFK MODE: ON (G)"
            GUI.AFKBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        end
        
    elseif input.KeyCode == Enum.KeyCode.Delete then
        -- Паника
        isBuying = false
        isCollecting = false
        DisableAFK()
        GUI.Frame.Visible = false
        print("🛑 PANIC DELETE!")
        
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        -- Скрыть GUI
        GUI.Frame.Visible = not GUI.Frame.Visible
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ =====
task.spawn(function()
    while true do
        pcall(function()
            -- Обновляем деньги
            GUI.MoneyLabel.Text = "💵 Money: " .. GetMoney()
            
            -- Авто-сбор
            if isCollecting then
                local items = FindCollectibles()
                if #items > 0 then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = LocalPlayer.Character.HumanoidRootPart
                        table.sort(items, function(a, b)
                            return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                        end)
                    end
                    
                    for i = 1, math.min(3, #items) do
                        if not isCollecting then break end
                        if CollectItem(items[i]) then
                            totalCollected = totalCollected + 1
                        end
                        task.wait(math.random(3, 8) / 10)
                    end
                end
            end
            
            -- Авто-покупка
            if isBuying then
                local buttons = FindButtons()
                if #buttons > 0 then
                    for _, btn in pairs(buttons) do
                        if not isBuying then break end
                        if btn.Type == "Remote" then
                            pcall(function() btn.Object:FireServer() end)
                            totalClicks = totalClicks + 1
                        end
                    end
                end
            end
        end)
        
        task.wait(math.random(15, 35) / 10) -- 1.5-3.5 сек задержка
    end
end)

print("=" .. string.rep("=", 50))
print("✅ SCRIPT LOADED!")
print("📋 Controls:")
print("   C - Auto Collect (Free Donate!)")
print("   B - Auto Buy Rebirth")
print("   G - AFK Mode")
print("   Delete - Panic Stop")
print("   RightCtrl - Hide GUI")
print("=" .. string.rep("=", 50))
