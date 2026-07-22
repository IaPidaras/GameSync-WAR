-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local function GetCIELUVColor(percentage)
    local green = Color3.fromRGB(46, 204, 113); local red = Color3.fromRGB(231, 76, 60)
    return red:Lerp(green, percentage)
end

-- Настройки
local Config = {
    Menu_Logo = "rbxassetid://0",
    UIColor1 = Color3.fromRGB(199, 149, 237), UIColor2 = Color3.fromRGB(85, 0, 255),
    Rainbow_Enabled = false, Rainbow_Speed = 0.5, Watermark_Enabled = true, Keybinds_Enabled = true,
    Aim_Enabled = false, Aim_Silent = false, Aim_Silent_Method = "SpoofCamera", Aim_Bind = Enum.UserInputType.MouseButton2,
    Aim_Mode = "Camera", Aim_Target = "Head", Aim_Smooth = 20, Aim_Predict = 0, Aim_TeamCheck = false, Aim_FOV_Show = true, Aim_FOV_Radius = 150,
    TP_Enabled = false, TP_Bind = Enum.KeyCode.E, Noclip_Enabled = false, Noclip_Bind = Enum.KeyCode.N,
    Fly_Enabled = false, Fly_Bind = Enum.KeyCode.F, Fly_Speed = 50, Fly_AntiFall = true,
    FreeCam_Enabled = false, FreeCam_Bind = Enum.KeyCode.C, FreeCam_Speed = 100,
    ESP_Enabled = false, ESP_TeamCheck = false, ESP_ShowSelf = false, ESP_Box = true, ESP_Skeleton = false, ESP_Tracers = false,
    ESP_Name = true, ESP_Name_Pos = "Top", ESP_HPText = true, ESP_HPText_Pos = "Right",
    ESP_Dist = true, ESP_Dist_Pos = "Bottom", ESP_Faction = true, ESP_Faction_Pos = "Top", ESP_HPBar = true, ESP_HPBar_Pos = "Left",
    Fling_Enabled = false, Fling_Bind = Enum.KeyCode.V, Fling_Mode = "Spin", Fling_SpinSpeed = 500, Fling_MaxDist = 10000, 
    VehNoclip_Enabled = false, VehNoclip_Bind = Enum.KeyCode.M,
    Anti_Void = false, Bypass_Chat = false, Anti_Kick = true, Anti_Idle = true, 
    Square_Enabled = false, Square_Bind = Enum.KeyCode.P, Square_Mode = "Toggle", Square_Visual = "3D Wireframe",
    Menu_Bind = Enum.KeyCode.RightShift, Unbind_Key = Enum.KeyCode.End,
    Menu_PosX = 0.5, Menu_PosY = 0.5, Menu_OffX = -280, Menu_OffY = -220,
    -- Авто-покупка кнопок
    AutoBuy_Enabled = false, AutoBuy_Bind = Enum.KeyCode.B, AutoBuy_Speed = 1,
    AutoBuy_Teleport = true, AutoBuy_Distance = 200,
    AutoFarm_Enabled = false, AutoFarm_Bind = Enum.KeyCode.G,
    AutoBuy_Gamepasses = {}, AutoBuy_Products = {}
}

local UI_NAME = "GameSync_WAR"
local FOLDER_NAME = "GameSyncWAR_Configs"
local connections, bindButtons, espCache, UIUpdaters = {}, {}, {}, {}
local bindingTarget, CachedTarget, FlingTarget = nil, nil, nil
local isFlingToggled, squareToggled, isAutoBuying, isAutoFarming = false, false, false, false
local dynamicGradientObjects = {}
local RefreshConfigs
local autoBuyQueue = {}
local lastPurchaseTime = 0
local foundButtons = {}
local foundMoneyItems = {}

-- ФУНКЦИЯ ПОЛУЧЕНИЯ ДЕНЕГ
local function GetMoney()
    local money = 0
    local moneyStat = nil
    
    -- Ищем деньги в leaderstats
    pcall(function()
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 5)
        if leaderstats then
            for _, stat in pairs(leaderstats:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                    local name = stat.Name:lower()
                    if name:find("cash") or name:find("money") or name:find("coin") or 
                       name:find("gold") or name:find("credit") or name:find("gem") or
                       name:find("dollar") or name:find("buck") then
                        money = stat.Value
                        moneyStat = stat
                        break
                    end
                end
            end
        end
    end)
    
    -- Ищем деньги в других местах
    if money == 0 then
        pcall(function()
            for _, child in pairs(LocalPlayer:GetChildren()) do
                if child:IsA("IntValue") or child:IsA("NumberValue") then
                    local name = child.Name:lower()
                    if name:find("cash") or name:find("money") or name:find("coin") then
                        money = child.Value
                        moneyStat = child
                        break
                    end
                end
            end
        end)
    end
    
    return money, moneyStat
end

-- ФУНКЦИИ ПОИСКА И СБОРА ДЕНЕГ
local function FindMoneyItems()
    local items = {}
    
    -- Ищем предметы для сбора денег
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local name = obj.Name:lower()
            local parentName = obj.Parent and obj.Parent.Name:lower() or ""
            
            -- Различные типы предметов с деньгами
            if obj:IsA("Part") or obj:IsA("MeshPart") then
                -- Монеты/деньги на карте
                if name:find("coin") or name:find("money") or name:find("cash") or
                   name:find("dollar") or name:find("gem") or name:find("bill") or
                   parentName:find("coin") or parentName:find("money") or
                   obj:FindFirstChild("Coin") or obj:FindFirstChild("Money") then
                    table.insert(items, {
                        Object = obj,
                        Position = obj.Position,
                        Type = "MoneyItem",
                        Name = obj.Name
                    })
                end
            end
            
            -- ProximityPrompt с деньгами
            if obj:IsA("ProximityPrompt") then
                local objName = obj.Name:lower()
                local objText = obj.ObjectText:lower()
                if objName:find("coin") or objName:find("money") or objName:find("collect") or
                   objText:find("coin") or objText:find("money") or objText:find("collect") then
                    table.insert(items, {
                        Object = obj,
                        Position = obj.Parent and obj.Parent.Position,
                        Type = "MoneyPrompt",
                        Name = obj.ObjectText
                    })
                end
            end
            
            -- ClickDetector с деньгами
            if obj:IsA("ClickDetector") then
                local parent = obj.Parent
                if parent and (parent.Name:lower():find("coin") or parent.Name:lower():find("money")) then
                    table.insert(items, {
                        Object = obj,
                        Position = parent.Position,
                        Type = "MoneyClick",
                        Name = parent.Name
                    })
                end
            end
        end)
    end
    
    return items
end

-- ФУНКЦИЯ ПОИСКА КНОПОК ДЛЯ ПОКУПКИ (РЕБИРТХ)
local function FindRebirthButtons()
    local buttons = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            local name = obj.Name:lower()
            local parentName = obj.Parent and obj.Parent.Name:lower() or ""
            
            -- Поиск частей с кнопками ребитха
            if obj:IsA("Part") or obj:IsA("MeshPart") then
                if name:find("rebirth") or name:find("reborn") or 
                   parentName:find("rebirth") or parentName:find("reborn") or
                   name:find("reset") or name:find("prestige") then
                    
                    -- Ищем ProximityPrompt или ClickDetector внутри
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                    local click = obj:FindFirstChildOfClass("ClickDetector")
                    
                    if prompt or click then
                        table.insert(buttons, {
                            Object = obj,
                            Prompt = prompt,
                            Click = click,
                            Position = obj.Position,
                            Type = "RebirthButton",
                            Name = obj.Name
                        })
                    end
                end
            end
            
            -- GUI кнопки ребитха
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if name:find("rebirth") or name:find("reborn") or
                   name:find("reset") or name:find("prestige") then
                    table.insert(buttons, {
                        Object = obj,
                        Position = nil,
                        Type = "GUIRebirth",
                        Name = obj.Name
                    })
                end
            end
        end)
    end
    
    -- Ищем RemoteEvents для ребитха
    pcall(function()
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local rName = remote.Name:lower()
                if rName:find("rebirth") or rName:find("reborn") or rName:find("reset") then
                    table.insert(buttons, {
                        Object = remote,
                        Position = nil,
                        Type = "RemoteRebirth",
                        Name = remote.Name
                    })
                end
            end
        end
    end)
    
    return buttons
end

-- АКТИВАЦИЯ ПРЕДМЕТОВ ДЛЯ СБОРА ДЕНЕГ
local function CollectMoneyItem(item)
    local success, err = pcall(function()
        if item.Type == "MoneyItem" then
            -- Телепортируемся к предмету
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(item.Position + Vector3.new(0, 2, 0))
                task.wait(0.1)
            end
            
            -- Пробуем активировать касанием
            if firetouchinterest and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    firetouchinterest(item.Object, hrp, 0)
                    task.wait(0.05)
                    firetouchinterest(item.Object, hrp, 1)
                end
            end
            
        elseif item.Type == "MoneyPrompt" then
            -- Активируем ProximityPrompt
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(item.Position + Vector3.new(0, 2, 0))
                task.wait(0.2)
            end
            fireproximityprompt(item.Object)
            
        elseif item.Type == "MoneyClick" then
            -- Активируем ClickDetector
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(item.Position + Vector3.new(0, 2, 0))
                task.wait(0.2)
            end
            fireclickdetector(item.Object)
        end
    end)
    
    return success
end

-- АКТИВАЦИЯ КНОПКИ РЕБИРТХА
local function ActivateRebirthButton(button)
    local success, err = pcall(function()
        -- Телепортируемся к кнопке если нужно
        if button.Position and Config.AutoBuy_Teleport then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(button.Position + Vector3.new(0, 3, 0))
                task.wait(0.2)
            end
        end
        
        -- Активируем в зависимости от типа
        if button.Prompt then
            fireproximityprompt(button.Prompt)
        elseif button.Click then
            fireclickdetector(button.Click)
        elseif button.Type == "GUIRebirth" then
            -- Нажимаем GUI кнопку
            if button.Object.MouseButton1Click then
                firesignal(button.Object.MouseButton1Click)
            end
            if button.Object.Activated then
                firesignal(button.Object.Activated)
            end
        elseif button.Type == "RemoteRebirth" then
            -- Отправляем RemoteEvent
            if button.Object:IsA("RemoteEvent") then
                button.Object:FireServer()
            elseif button.Object:IsA("RemoteFunction") then
                button.Object:InvokeServer()
            end
        end
    end)
    
    return success
end

-- ОСНОВНОЙ ЦИКЛ АВТО-ФАРМА ДЕНЕГ
local function ProcessAutoFarm()
    if not isAutoFarming then return end
    
    -- Ищем предметы с деньгами
    foundMoneyItems = FindMoneyItems()
    
    if #foundMoneyItems > 0 then
        -- Сортируем по расстоянию
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            table.sort(foundMoneyItems, function(a, b)
                if not a.Position or not b.Position then return false end
                return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
            end)
        end
        
        -- Собираем предметы
        for _, item in pairs(foundMoneyItems) do
            if not isAutoFarming then break end
            
            if item.Position and Config.AutoBuy_Teleport then
                local distance = (item.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance <= Config.AutoBuy_Distance then
                    CollectMoneyItem(item)
                    task.wait(0.1)
                end
            else
                CollectMoneyItem(item)
                task.wait(0.1)
            end
        end
    end
    
    task.wait(0.2)
end

-- ОСНОВНОЙ ЦИКЛ АВТО-ПОКУПКИ (ТРАТА ДЕНЕГ)
local function ProcessAutoBuy()
    if not isAutoBuying then return end
    
    local currentMoney, _ = GetMoney()
    
    -- Ищем кнопки ребитха
    foundButtons = FindRebirthButtons()
    
    if #foundButtons > 0 then
        -- Сортируем по расстоянию
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            table.sort(foundButtons, function(a, b)
                if not a.Position or not b.Position then return false end
                if not hrp then return false end
                return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
            end)
        end
        
        -- Активируем кнопки
        for _, button in pairs(foundButtons) do
            if not isAutoBuying then break end
            
            local success = ActivateRebirthButton(button)
            if success then
                task.wait(0.3)
            end
        end
    else
        -- Если не нашли кнопок, пробуем купить gamepass'ы
        if #Config.AutoBuy_Gamepasses > 0 then
            for _, id in pairs(Config.AutoBuy_Gamepasses) do
                if not isAutoBuying then break end
                pcall(function()
                    MarketplaceService:PromptGamePassPurchase(LocalPlayer, id)
                end)
                task.wait(0.5)
            end
        end
    end
    
    task.wait(1 / Config.AutoBuy_Speed)
end

-- СОЗДАНИЕ GUI ПАНЕЛИ
local function CreateControlGUI()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "MoneyControlGUI"
    
    local mainFrame = Instance.new("Frame", gui)
    mainFrame.Size = UDim2.new(0, 280, 0, 200)
    mainFrame.Position = UDim2.new(1, -290, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(199, 149, 237)
    
    -- Заголовок
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.Text = "💰 MONEY FARM & BUY CONTROL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)
    
    -- Отображение денег
    local moneyFrame = Instance.new("Frame", mainFrame)
    moneyFrame.Size = UDim2.new(1, -20, 0, 30)
    moneyFrame.Position = UDim2.new(0, 10, 0, 38)
    moneyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Instance.new("UICorner", moneyFrame).CornerRadius = UDim.new(0, 5)
    
    local moneyLabel = Instance.new("TextLabel", moneyFrame)
    moneyLabel.Size = UDim2.new(1, 0, 1, 0)
    moneyLabel.BackgroundTransparency = 1
    moneyLabel.Text = "💵 Money: 0"
    moneyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    moneyLabel.Font = Enum.Font.GothamBold
    moneyLabel.TextSize = 16
    
    -- Статус фарма
    local farmStatus = Instance.new("TextLabel", mainFrame)
    farmStatus.Size = UDim2.new(1, -20, 0, 20)
    farmStatus.Position = UDim2.new(0, 10, 0, 75)
    farmStatus.BackgroundTransparency = 1
    farmStatus.Text = "Farm: ❌ OFF (Press G)"
    farmStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    farmStatus.Font = Enum.Font.Gotham
    farmStatus.TextSize = 11
    farmStatus.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Статус покупки
    local buyStatus = Instance.new("TextLabel", mainFrame)
    buyStatus.Size = UDim2.new(1, -20, 0, 20)
    buyStatus.Position = UDim2.new(0, 10, 0, 95)
    buyStatus.BackgroundTransparency = 1
    buyStatus.Text = "Buy: ❌ OFF (Press B)"
    buyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    buyStatus.Font = Enum.Font.Gotham
    buyStatus.TextSize = 11
    buyStatus.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Информация о найденных предметах
    local itemsInfo = Instance.new("TextLabel", mainFrame)
    itemsInfo.Size = UDim2.new(1, -20, 0, 20)
    itemsInfo.Position = UDim2.new(0, 10, 0, 115)
    itemsInfo.BackgroundTransparency = 1
    itemsInfo.Text = "Money items: 0 | Buttons: 0"
    itemsInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemsInfo.Font = Enum.Font.Gotham
    itemsInfo.TextSize = 11
    itemsInfo.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Кнопка Farm
    local farmBtn = Instance.new("TextButton", mainFrame)
    farmBtn.Size = UDim2.new(0.44, 0, 0, 30)
    farmBtn.Position = UDim2.new(0, 10, 0, 140)
    farmBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    farmBtn.Text = "💰 FARM (G)"
    farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = 11
    Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 5)
    
    -- Кнопка Buy
    local buyBtn = Instance.new("TextButton", mainFrame)
    buyBtn.Size = UDim2.new(0.44, 0, 0, 30)
    buyBtn.Position = UDim2.new(0.5, 0, 0, 140)
    buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    buyBtn.Text = "🛒 BUY (B)"
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 11
    Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 5)
    
    -- Кнопка Both
    local bothBtn = Instance.new("TextButton", mainFrame)
    bothBtn.Size = UDim2.new(1, -20, 0, 30)
    bothBtn.Position = UDim2.new(0, 10, 0, 175)
    bothBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    bothBtn.Text = "🔄 BOTH (Press H)"
    bothBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bothBtn.Font = Enum.Font.GothamBold
    bothBtn.TextSize = 11
    Instance.new("UICorner", bothBtn).CornerRadius = UDim.new(0, 5)
    
    -- Обработчики кнопок
    farmBtn.MouseButton1Click:Connect(function()
        isAutoFarming = not isAutoFarming
    end)
    
    buyBtn.MouseButton1Click:Connect(function()
        isAutoBuying = not isAutoBuying
    end)
    
    bothBtn.MouseButton1Click:Connect(function()
        isAutoFarming = not isAutoFarming
        isAutoBuying = not isAutoBuying
    end)
    
    -- Обновление GUI
    RunService.RenderStepped:Connect(function()
        local money, _ = GetMoney()
        moneyLabel.Text = "💵 Money: " .. tostring(money)
        
        -- Статус фарма
        if isAutoFarming then
            farmStatus.Text = "Farm: ✅ ON (Press G)"
            farmStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
            farmBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            farmBtn.Text = "💰 STOP (G)"
        else
            farmStatus.Text = "Farm: ❌ OFF (Press G)"
            farmStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            farmBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            farmBtn.Text = "💰 FARM (G)"
        end
        
        -- Статус покупки
        if isAutoBuying then
            buyStatus.Text = "Buy: ✅ ON (Press B)"
            buyStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
            buyBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            buyBtn.Text = "🛒 STOP (B)"
        else
            buyStatus.Text = "Buy: ❌ OFF (Press B)"
            buyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
            buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            buyBtn.Text = "🛒 BUY (B)"
        end
        
        -- Информация о предметах
        itemsInfo.Text = "Money items: " .. #foundMoneyItems .. " | Buttons: " .. #foundButtons
    end)
    
    return {
        Frame = mainFrame,
        MoneyLabel = moneyLabel,
        FarmStatus = farmStatus,
        BuyStatus = buyStatus,
        ItemsInfo = itemsInfo
    }
end

-- Создаем GUI
local controlGUI = CreateControlGUI()

-- Обработчики клавиш
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.AutoFarm_Bind then
        isAutoFarming = not isAutoFarming
    elseif input.KeyCode == Config.AutoBuy_Bind then
        isAutoBuying = not isAutoBuying
    elseif input.KeyCode == Enum.KeyCode.H then
        -- Включаем оба режима
        isAutoFarming = not isAutoFarming
        isAutoBuying = not isAutoBuying
    end
    
    -- Управление скоростью
    if isAutoBuying or isAutoFarming then
        if input.KeyCode == Enum.KeyCode.Up then
            Config.AutoBuy_Speed = math.min(Config.AutoBuy_Speed + 0.5, 10)
        elseif input.KeyCode == Enum.KeyCode.Down then
            Config.AutoBuy_Speed = math.max(Config.AutoBuy_Speed - 0.5, 0.5)
        elseif input.KeyCode == Enum.KeyCode.Right then
            Config.AutoBuy_Distance = math.min(Config.AutoBuy_Distance + 25, 500)
        elseif input.KeyCode == Enum.KeyCode.Left then
            Config.AutoBuy_Distance = math.max(Config.AutoBuy_Distance - 25, 25)
        end
    end
end)

-- Запускаем циклы фарма и покупки
task.spawn(function()
    while true do
        if isAutoFarming then
            ProcessAutoFarm()
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if isAutoBuying then
            ProcessAutoBuy()
        end
        task.wait(0.1)
    end
end)

print("✅ GameSync WAR - Money Farm & AutoBuy loaded!")
print("📋 Controls:")
print("   G - Toggle Auto Farm (collect money)")
print("   B - Toggle Auto Buy (spend money)")
print("   H - Toggle Both")
print("   ↑↓ - Adjust speed")
print("   ←→ - Adjust range")
