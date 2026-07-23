--[[
    GameSync WAR - Auto Button Buyer v2.0
    Безопасная версия с защитой от античита
]]--

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UIS = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    MarketplaceService = game:GetService("MarketplaceService"),
    Stats = game:GetService("Stats"),
    HttpService = game:GetService("HttpService"),
    VirtualInputManager = game:GetService("VirtualInputManager")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Безопасные задержки (как у реального игрока)
local function RandomDelay()
    local delay = math.random(15, 35) / 10 -- 1.5 - 3.5 секунды
    task.wait(delay)
end

local function ShortDelay()
    local delay = math.random(5, 15) / 10 -- 0.5 - 1.5 секунды
    task.wait(delay)
end

-- Безопасное получение денег (без прямого доступа к leaderstats)
local function GetMoney()
    local money = 0
    pcall(function()
        -- Ищем через GUI (безопаснее)
        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                local text = gui.Text
                -- Ищем паттерны денег
                local patterns = {"%$", "Money:", "Cash:", "Coins:", "Gold:", "Gems:"}
                for _, pattern in pairs(patterns) do
                    if text:find(pattern) then
                        local num = text:match(pattern .. "%s*(%d+[%,%d]*)")
                        if num then
                            money = tonumber(num:gsub(",", "")) or 0
                            break
                        end
                    end
                end
            end
            if money > 0 then break end
        end
    end)
    return money
end

-- Безопасный поиск кнопок (через обычные методы)
local function FindClickableButtons()
    local buttons = {}
    
    pcall(function()
        -- Ищем в Workspace через обычный перебор
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            -- Проверяем ClickDetectors
            pcall(function()
                local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
                if clickDetector then
                    local parent = obj
                    local name = parent.Name:lower()
                    
                    -- Ищем кнопки по ключевым словам
                    if name:find("rebirth") or 
                       name:find("reborn") or 
                       name:find("button") or
                       name:find("buy") or
                       name:find("prestige") or
                       name:find("reset") then
                        
                        table.insert(buttons, {
                            Object = parent,
                            ClickDetector = clickDetector,
                            Position = parent:IsA("BasePart") and parent.Position or nil,
                            Name = parent.Name
                        })
                    end
                end
            end)
            
            -- Ищем GUI кнопки в SurfaceGui/BillboardGui
            pcall(function()
                if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                    for _, button in pairs(obj:GetDescendants()) do
                        if button:IsA("TextButton") or button:IsA("ImageButton") then
                            local btnName = button.Name:lower()
                            local btnText = button:IsA("TextButton") and button.Text:lower() or ""
                            
                            if btnName:find("rebirth") or 
                               btnName:find("reborn") or
                               btnText:find("rebirth") or
                               btnText:find("reborn") then
                                
                                table.insert(buttons, {
                                    Object = button,
                                    Type = "GUI",
                                    Name = button.Name
                                })
                            end
                        end
                    end
                end
            end)
        end
        
        -- Ищем RemoteEvents
        for _, remote in pairs(Services.ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local rName = remote.Name:lower()
                if rName:find("rebirth") or 
                   rName:find("reborn") or 
                   rName:find("buybutton") or
                   rName:find("purchase") then
                    
                    table.insert(buttons, {
                        Object = remote,
                        Type = "Remote",
                        Name = remote.Name
                    })
                end
            end
        end
    end)
    
    return buttons
end

-- Безопасный поиск предметов для фарма
local function FindFarmItems()
    local items = {}
    
    pcall(function()
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                
                -- Предметы для сбора
                if name:find("coin") or 
                   name:find("money") or 
                   name:find("cash") or
                   name:find("gem") or
                   name:find("dollar") or
                   name:find("collect") then
                    
                    -- Проверяем что предмет можно собрать
                    local canCollect = false
                    
                    -- Проверяем TouchInterest
                    if obj:FindFirstChildOfClass("TouchTransmitter") then
                        canCollect = true
                    end
                    
                    -- Проверяем ClickDetector
                    if obj:FindFirstChildOfClass("ClickDetector") then
                        canCollect = true
                    end
                    
                    if canCollect then
                        table.insert(items, {
                            Object = obj,
                            Position = obj.Position,
                            Name = obj.Name
                        })
                    end
                end
            end
        end
    end)
    
    return items
end

-- Безопасная активация кнопки (через обычные методы)
local function SafeClickButton(button)
    local success = false
    
    pcall(function()
        -- Способ 1: Через ClickDetector (самый безопасный)
        if button.ClickDetector then
            -- Перемещаем персонажа к кнопке
            if button.Position and LocalPlayer.Character then
                local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    -- Плавное перемещение (как у игрока)
                    local tweenInfo = TweenInfo.new(
                        math.random(10, 25) / 10, -- 1-2.5 секунды
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out
                    )
                    
                    local targetPos = CFrame.new(
                        button.Position.X + math.random(-1, 1),
                        button.Position.Y + 2,
                        button.Position.Z + math.random(-1, 1)
                    )
                    
                    local tween = Services.TweenService:Create(humanoidRootPart, tweenInfo, {
                        CFrame = targetPos
                    })
                    tween:Play()
                    
                    -- Ждем пока персонаж "подойдет"
                    RandomDelay()
                end
            end
            
            -- Эмулируем клик через Mouse
            -- Это безопаснее чем fireclickdetector
            pcall(function()
                -- Перемещаем мышь на кнопку
                if button.Object:IsA("BasePart") then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(button.Object.Position)
                    if onScreen then
                        -- Нажимаем кнопку мыши
                        Services.VirtualInputManager:SendMouseButtonEvent(
                            screenPos.X,
                            screenPos.Y,
                            0, -- Left button
                            true,
                            nil,
                            0
                        )
                        ShortDelay()
                        Services.VirtualInputManager:SendMouseButtonEvent(
                            screenPos.X,
                            screenPos.Y,
                            0,
                            false,
                            nil,
                            0
                        )
                        success = true
                    end
                end
            end)
        end
        
        -- Способ 2: Через RemoteEvent
        if button.Type == "Remote" then
            pcall(function()
                if button.Object:IsA("RemoteEvent") then
                    button.Object:FireServer()
                elseif button.Object:IsA("RemoteFunction") then
                    button.Object:InvokeServer()
                end
                success = true
            end)
            RandomDelay()
        end
        
        -- Способ 3: Через GUI кнопку
        if button.Type == "GUI" then
            pcall(function()
                -- Эмулируем нажатие через сигналы
                if button.Object.MouseButton1Click then
                    local connections = getconnections(button.Object.MouseButton1Click)
                    for _, conn in pairs(connections) do
                        pcall(function()
                            conn:Fire()
                        end)
                    end
                end
                success = true
            end)
            RandomDelay()
        end
    end)
    
    return success
end

-- Безопасный сбор предмета
local function SafeCollectItem(item)
    local success = false
    
    pcall(function()
        if not LocalPlayer.Character then return end
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- Плавно двигаемся к предмету
        local distance = (item.Position - humanoidRootPart.Position).Magnitude
        
        if distance < 50 then -- Если близко
            local tweenInfo = TweenInfo.new(
                math.random(5, 15) / 10, -- 0.5-1.5 секунды
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.Out
            )
            
            local targetPos = CFrame.new(
                item.Position.X,
                item.Position.Y + 3,
                item.Position.Z
            )
            
            local tween = Services.TweenService:Create(humanoidRootPart, tweenInfo, {
                CFrame = targetPos
            })
            tween:Play()
            task.wait(0.8) -- Ждем касания
            
            -- Эмулируем касание через прыжок на месте
            pcall(function()
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.5)
                    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                end
            end)
            
            success = true
        end
    end)
    
    return success
end

-- GUI
local function CreateGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "GameSync_AutoBuy"
    gui.Parent = Services.CoreGui
    gui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 200)
    mainFrame.Position = UDim2.new(1, -290, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(199, 149, 237)
    stroke.Thickness = 1.5
    stroke.Parent = mainFrame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    title.Text = "💰 Auto Farm & Buy"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Информация о деньгах
    local moneyLabel = Instance.new("TextLabel")
    moneyLabel.Size = UDim2.new(1, -20, 0, 25)
    moneyLabel.Position = UDim2.new(0, 10, 0, 38)
    moneyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    moneyLabel.Text = "💵 Money: 0"
    moneyLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    moneyLabel.Font = Enum.Font.GothamBold
    moneyLabel.TextSize = 14
    moneyLabel.Parent = mainFrame
    
    local moneyCorner = Instance.new("UICorner")
    moneyCorner.CornerRadius = UDim.new(0, 5)
    moneyCorner.Parent = moneyLabel
    
    -- Статус
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 68)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: IDLE"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    -- Кнопка Farm
    local farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(0.45, 0, 0, 35)
    farmBtn.Position = UDim2.new(0, 10, 0, 95)
    farmBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    farmBtn.Text = "💰 FARM (G)"
    farmBtn.TextColor3 = Color3.new(1, 1, 1)
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = 12
    farmBtn.Parent = mainFrame
    
    local farmCorner = Instance.new("UICorner")
    farmCorner.CornerRadius = UDim.new(0, 5)
    farmCorner.Parent = farmBtn
    
    -- Кнопка Buy
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0.45, 0, 0, 35)
    buyBtn.Position = UDim2.new(0.5, 0, 0, 95)
    buyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    buyBtn.Text = "🛒 BUY (B)"
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 12
    buyBtn.Parent = mainFrame
    
    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 5)
    buyCorner.Parent = buyBtn
    
    -- Кнопка Both
    local bothBtn = Instance.new("TextButton")
    bothBtn.Size = UDim2.new(1, -20, 0, 35)
    bothBtn.Position = UDim2.new(0, 10, 0, 138)
    bothBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    bothBtn.Text = "🔄 AUTO BOTH (H)"
    bothBtn.TextColor3 = Color3.new(1, 1, 1)
    bothBtn.Font = Enum.Font.GothamBold
    bothBtn.TextSize = 12
    bothBtn.Parent = mainFrame
    
    local bothCorner = Instance.new("UICorner")
    bothCorner.CornerRadius = UDim.new(0, 5)
    bothCorner.Parent = bothBtn
    
    -- Счетчик действий
    local counterLabel = Instance.new("TextLabel")
    counterLabel.Size = UDim2.new(1, -20, 0, 20)
    counterLabel.Position = UDim2.new(0, 10, 0, 178)
    counterLabel.BackgroundTransparency = 1
    counterLabel.Text = "Buttons: 0 | Items: 0"
    counterLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    counterLabel.Font = Enum.Font.Gotham
    counterLabel.TextSize = 11
    counterLabel.TextXAlignment = Enum.TextXAlignment.Left
    counterLabel.Parent = mainFrame
    
    return {
        Frame = mainFrame,
        MoneyLabel = moneyLabel,
        StatusLabel = statusLabel,
        FarmBtn = farmBtn,
        BuyBtn = buyBtn,
        BothBtn = bothBtn,
        CounterLabel = counterLabel
    }
end

-- Основная логика
local GUI = CreateGUI()
local isFarming = false
local isBuying = false
local totalClicks = 0
local totalCollected = 0
local lastAction = tick()

-- Безопасный цикл фарма
local function FarmLoop()
    while isFarming do
        pcall(function()
            local items = FindFarmItems()
            
            if #items > 0 then
                GUI.StatusLabel.Text = "Status: FARMING..."
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                
                -- Сортируем по расстоянию
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    table.sort(items, function(a, b)
                        return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                    end)
                end
                
                -- Собираем ближайшие 3 предмета
                local collectCount = math.min(3, #items)
                for i = 1, collectCount do
                    if not isFarming then break end
                    
                    if SafeCollectItem(items[i]) then
                        totalCollected = totalCollected + 1
                    end
                    
                    -- Случайная пауза между сборами
                    RandomDelay()
                end
            else
                GUI.StatusLabel.Text = "Status: SEARCHING..."
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                RandomDelay()
            end
            
            -- Обновляем счетчики
            local money = GetMoney()
            GUI.MoneyLabel.Text = "💵 Money: " .. tostring(money)
            GUI.CounterLabel.Text = "Buttons: " .. totalClicks .. " | Items: " .. totalCollected
            
            -- Проверяем не пора ли остановиться
            if tick() - lastAction > 300 then -- 5 минут без действий
                isFarming = false
                isBuying = false
                GUI.StatusLabel.Text = "Status: PAUSED (5min limit)"
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        end)
        
        RandomDelay()
    end
end

-- Безопасный цикл покупки
local function BuyLoop()
    while isBuying do
        pcall(function()
            local buttons = FindClickableButtons()
            
            if #buttons > 0 then
                GUI.StatusLabel.Text = "Status: BUYING..."
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 255)
                
                -- Активируем только 1-2 кнопки за раз
                local clickCount = math.min(math.random(1, 2), #buttons)
                for i = 1, clickCount do
                    if not isBuying then break end
                    
                    if SafeClickButton(buttons[i]) then
                        totalClicks = totalClicks + 1
                        lastAction = tick()
                    end
                    
                    -- Большая пауза между покупками
                    RandomDelay()
                    RandomDelay()
                end
            else
                GUI.StatusLabel.Text = "Status: SEARCHING..."
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                RandomDelay()
            end
            
            -- Обновляем счетчики
            local money = GetMoney()
            GUI.MoneyLabel.Text = "💵 Money: " .. tostring(money)
            GUI.CounterLabel.Text = "Buttons: " .. totalClicks .. " | Items: " .. totalCollected
        end)
        
        RandomDelay()
    end
end

-- Управление
Services.UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.G then
        isFarming = not isFarming
        if isFarming then
            isBuying = false
            lastAction = tick()
            task.spawn(FarmLoop)
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        isBuying = not isBuying
        if isBuying then
            isFarming = false
            lastAction = tick()
            task.spawn(BuyLoop)
        end
    elseif input.KeyCode == Enum.KeyCode.H then
        if isFarming or isBuying then
            isFarming = false
            isBuying = false
        else
            isFarming = true
            isBuying = true
            lastAction = tick()
            task.spawn(FarmLoop)
            task.spawn(BuyLoop)
        end
    end
end)

-- Обновление GUI
task.spawn(function()
    while true do
        if isFarming or isBuying then
            local money = GetMoney()
            GUI.MoneyLabel.Text = "💵 Money: " .. tostring(money)
        else
            GUI.StatusLabel.Text = "Status: IDLE"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        
        -- Обновляем цвета кнопок
        GUI.FarmBtn.BackgroundColor3 = isFarming and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113)
        GUI.BuyBtn.BackgroundColor3 = isBuying and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(52, 152, 219)
        
        task.wait(3)
    end
end)

-- Первоначальная загрузка оригинального скрипта
pcall(function()
    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/IaPidaras/GameSync-WAR/main/main.lua")
    end)
    
    if success and result then
        local originalScript = loadstring(result)
        if originalScript then
            pcall(originalScript)
        end
    end
end)

print("✅ GameSync WAR - Safe Auto Buy/Farm Loaded!")
print("📋 Controls: G-Farm | B-Buy | H-Both")
print("🛡️ Protected with human-like delays")
print("⏱️ Auto-pause after 5 minutes of activity")
