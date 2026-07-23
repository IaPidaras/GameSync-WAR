--[[
    GameSync WAR - Stealth Auto Buy/Farm v3.0
    Полностью скрытая версия для публичных серверов
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
    VirtualInputManager = game:GetService("VirtualInputManager"),
    TeleportService = game:GetService("TeleportService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

-- ===== КОНФИГУРАЦИЯ СТЕЛС РЕЖИМА =====
local StealthConfig = {
    -- Задержки (в секундах)
    MinDelay = 2.5,
    MaxDelay = 6.0,
    MinActionDelay = 1.5,
    MaxActionDelay = 4.0,
    
    -- Лимиты действий
    MaxActionsPerMinute = 12,  -- Не больше 12 действий в минуту
    MaxSessionTime = 480,       -- Максимум 8 минут фарма
    CooldownAfterSession = 300, -- 5 минут перерыв
    
    -- Маскировка
    SimulateAfk = true,         -- Имитировать AFK между действиями
    RandomMouseMovements = true,-- Случайные движения мыши
    FakeCameraMovements = true, -- Фейковые движения камеры
    AvoidOtherPlayers = true,   -- Избегать других игроков
    MinDistanceFromPlayers = 50,-- Минимальная дистанция до других игроков
    
    -- Анти-детект
    HumanizeMovements = true,   -- Человеческие движения
    AddMistakes = true,         -- Иногда "промахиваться"
    RandomPauses = true,        -- Случайные паузы
    NightModeOnly = false,      -- Только ночью (по времени сервера)
    
    -- Скрытие GUI
    HideGUIWhenPlayersNear = true,
    GUIOpacity = 0.7,           -- Полупрозрачный GUI
    MinimalGUI = false,          -- Минимальный GUI режим
    GUIHotkey = Enum.KeyCode.RightControl -- Показать/скрыть GUI
}

-- ===== СИСТЕМА БЕЗОПАСНОСТИ =====
local SecuritySystem = {
    ActionsThisMinute = 0,
    LastActionReset = tick(),
    SessionStartTime = 0,
    IsOnCooldown = false,
    NearbyPlayers = {},
    IsGUIHidden = false,
    FakeAfkTimer = 0,
    LastMouseMove = tick(),
    MistakesCount = 0,
    TotalActions = 0
}

-- Проверка на других игроков поблизости
local function CheckNearbyPlayers()
    if not StealthConfig.AvoidOtherPlayers then return true end
    
    local nearbyCount = 0
    local minDistance = math.huge
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        
        for _, player in pairs(Services.Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (hrp.Position - myPos).Magnitude
                    if distance < StealthConfig.MinDistanceFromPlayers then
                        nearbyCount = nearbyCount + 1
                        if distance < minDistance then
                            minDistance = distance
                        end
                    end
                end
            end
        end
    end
    
    SecuritySystem.NearbyPlayers = {
        Count = nearbyCount,
        ClosestDistance = minDistance
    }
    
    return nearbyCount == 0
end

-- Проверка лимита действий
local function CheckActionLimit()
    -- Сброс счетчика каждую минуту
    if tick() - SecuritySystem.LastActionReset > 60 then
        SecuritySystem.ActionsThisMinute = 0
        SecuritySystem.LastActionReset = tick()
    end
    
    if SecuritySystem.ActionsThisMinute >= StealthConfig.MaxActionsPerMinute then
        return false
    end
    
    -- Проверка времени сессии
    if SecuritySystem.SessionStartTime > 0 then
        local sessionTime = tick() - SecuritySystem.SessionStartTime
        if sessionTime > StealthConfig.MaxSessionTime then
            SecuritySystem.IsOnCooldown = true
            return false
        end
    end
    
    -- Проверка кулдауна
    if SecuritySystem.IsOnCooldown then
        if tick() - SecuritySystem.SessionStartTime - StealthConfig.MaxSessionTime < StealthConfig.CooldownAfterSession then
            return false
        else
            SecuritySystem.IsOnCooldown = false
            SecuritySystem.SessionStartTime = 0
        end
    end
    
    return true
end

-- Человеческие задержки с вариациями
local function HumanDelay()
    local baseDelay = math.random(
        StealthConfig.MinDelay * 100,
        StealthConfig.MaxDelay * 100
    ) / 100
    
    -- Добавляем случайные паузы
    if StealthConfig.RandomPauses and math.random(1, 5) == 1 then
        baseDelay = baseDelay + math.random(2, 8)
    end
    
    -- Иногда делаем очень длинную паузу (как будто задумался)
    if math.random(1, 10) == 1 then
        baseDelay = baseDelay + math.random(10, 30)
        if StealthConfig.SimulateAfk then
            -- Имитируем AFK
            SecuritySystem.FakeAfkTimer = tick()
        end
    end
    
    task.wait(baseDelay)
    SecuritySystem.ActionsThisMinute = SecuritySystem.ActionsThisMinute + 1
    SecuritySystem.TotalActions = SecuritySystem.TotalActions + 1
end

-- Безопасная задержка между действиями
local function ActionDelay()
    local delay = math.random(
        StealthConfig.MinActionDelay * 100,
        StealthConfig.MaxActionDelay * 100
    ) / 100
    task.wait(delay)
end

-- Имитация случайных движений мыши
local function SimulateMouseMovement()
    if not StealthConfig.RandomMouseMovements then return end
    
    if tick() - SecuritySystem.LastMouseMove > 5 then
        pcall(function()
            local screenSize = Camera.ViewportSize
            local randomX = math.random(100, screenSize.X - 100)
            local randomY = math.random(100, screenSize.Y - 100)
            
            -- Плавное движение мыши
            local steps = math.random(3, 8)
            local currentX = Services.UIS:GetMouseLocation().X
            local currentY = Services.UIS:GetMouseLocation().Y
            
            for i = 1, steps do
                local newX = currentX + (randomX - currentX) * (i / steps)
                local newY = currentY + (randomY - currentY) * (i / steps)
                Services.VirtualInputManager:SendMouseMoveEvent(newX, newY, nil)
                task.wait(0.05)
            end
            
            SecuritySystem.LastMouseMove = tick()
        end)
    end
end

-- Фейковые движения камеры
local function FakeCameraMovement()
    if not StealthConfig.FakeCameraMovements then return end
    
    if math.random(1, 8) == 1 then
        pcall(function()
            local randomRotation = CFrame.Angles(
                math.rad(math.random(-10, 10)),
                math.rad(math.random(-30, 30)),
                0
            )
            
            -- Плавный поворот камеры
            local tweenInfo = TweenInfo.new(
                math.random(1, 3),
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            )
            
            local targetCFrame = Camera.CFrame * randomRotation
            local tween = Services.TweenService:Create(Camera, tweenInfo, {
                CFrame = targetCFrame
            })
            tween:Play()
            task.wait(math.random(1, 2))
        end)
    end
end

-- Случайные "ошибки" (промахи)
local function MaybeMakeMistake()
    if not StealthConfig.AddMistakes then return false end
    
    -- 15% шанс ошибки
    if math.random(1, 100) <= 15 then
        SecuritySystem.MistakesCount = SecuritySystem.MistakesCount + 1
        
        pcall(function()
            -- Кликаем мимо кнопки
            local screenSize = Camera.ViewportSize
            local randomX = math.random(0, screenSize.X)
            local randomY = math.random(0, screenSize.Y)
            
            Services.VirtualInputManager:SendMouseButtonEvent(
                randomX, randomY,
                0, true, nil, 0
            )
            task.wait(0.1)
            Services.VirtualInputManager:SendMouseButtonEvent(
                randomX, randomY,
                0, false, nil, 0
            )
        end)
        
        return true
    end
    
    return false
end

-- Проверка времени суток (если включен NightMode)
local function IsNightTime()
    if not StealthConfig.NightModeOnly then return true end
    
    local success, result = pcall(function()
        return Services.Workspace:FindFirstChild("Lighting")
    end)
    
    if success and result then
        local lighting = result
        -- Проверяем через ClockTime или другие индикаторы
        local time = lighting.ClockTime or 12
        return time >= 20 or time <= 6 -- Ночь с 20:00 до 6:00
    end
    
    return true
end

-- Безопасное получение денег
local function GetMoney()
    local money = 0
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                local text = gui.Text
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

-- Поиск кнопок
local function FindClickableButtons()
    local buttons = {}
    
    pcall(function()
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            pcall(function()
                local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
                if clickDetector then
                    local parent = obj
                    local name = parent.Name:lower()
                    
                    if name:find("rebirth") or 
                       name:find("reborn") or 
                       name:find("button") or
                       name:find("buy") or
                       name:find("prestige") then
                        
                        table.insert(buttons, {
                            Object = parent,
                            ClickDetector = clickDetector,
                            Position = parent:IsA("BasePart") and parent.Position or nil,
                            Name = parent.Name
                        })
                    end
                end
            end)
            
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
        
        for _, remote in pairs(Services.ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local rName = remote.Name:lower()
                if rName:find("rebirth") or 
                   rName:find("reborn") or 
                   rName:find("buybutton") then
                    
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

-- Поиск предметов для фарма
local function FindFarmItems()
    local items = {}
    
    pcall(function()
        for _, obj in pairs(Services.Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                
                if name:find("coin") or 
                   name:find("money") or 
                   name:find("cash") or
                   name:find("gem") or
                   name:find("collect") then
                    
                    local canCollect = false
                    
                    if obj:FindFirstChildOfClass("TouchTransmitter") then
                        canCollect = true
                    end
                    
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

-- Скрытая активация кнопки
local function StealthClickButton(button)
    local success = false
    
    -- Сначала проверяем безопасность
    if not CheckActionLimit() then return false end
    if not CheckNearbyPlayers() then 
        -- Ждем пока игроки уйдут
        HumanDelay()
        return false 
    end
    if not IsNightTime() then return false end
    
    -- Иногда специально промахиваемся
    if MaybeMakeMistake() then
        HumanDelay()
    end
    
    pcall(function()
        if button.ClickDetector then
            -- Плавное и скрытное перемещение
            if button.Position and LocalPlayer.Character then
                local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    -- Случайное смещение для маскировки
                    local offset = Vector3.new(
                        math.random(-2, 2),
                        0,
                        math.random(-2, 2)
                    )
                    
                    local tweenInfo = TweenInfo.new(
                        math.random(15, 30) / 10,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.InOut
                    )
                    
                    local targetPos = CFrame.new(button.Position + offset + Vector3.new(0, 2, 0))
                    
                    -- Промежуточные точки для естественности
                    local midPoint1 = humanoidRootPart.CFrame:Lerp(targetPos, 0.5) * 
                                     CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
                    
                    -- Двигаемся через промежуточную точку
                    local tween1 = Services.TweenService:Create(humanoidRootPart, 
                        TweenInfo.new(0.5, Enum.EasingStyle.Linear), 
                        {CFrame = midPoint1})
                    tween1:Play()
                    task.wait(0.5)
                    
                    local tween2 = Services.TweenService:Create(humanoidRootPart, 
                        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                        {CFrame = targetPos})
                    tween2:Play()
                    task.wait(1)
                end
            end
            
            -- Эмулируем клик мышью
            pcall(function()
                if button.Object:IsA("BasePart") then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(button.Object.Position)
                    if onScreen then
                        -- Случайное смещение клика (±5 пикселей)
                        local clickX = screenPos.X + math.random(-5, 5)
                        local clickY = screenPos.Y + math.random(-5, 5)
                        
                        Services.VirtualInputManager:SendMouseButtonEvent(
                            clickX, clickY,
                            0, true, nil, 0
                        )
                        ActionDelay()
                        Services.VirtualInputManager:SendMouseButtonEvent(
                            clickX, clickY,
                            0, false, nil, 0
                        )
                        success = true
                    end
                end
            end)
        end
        
        if button.Type == "Remote" then
            pcall(function()
                if button.Object:IsA("RemoteEvent") then
                    button.Object:FireServer()
                elseif button.Object:IsA("RemoteFunction") then
                    button.Object:InvokeServer()
                end
                success = true
            end)
        end
        
        if button.Type == "GUI" then
            pcall(function()
                if button.Object.MouseButton1Click then
                    local connections = getconnections(button.Object.MouseButton1Click)
                    for _, conn in pairs(connections) do
                        pcall(function() conn:Fire() end)
                    end
                end
                success = true
            end)
        end
    end)
    
    -- Имитируем движения после действия
    SimulateMouseMovement()
    FakeCameraMovement()
    
    return success
end

-- Скрытый сбор предметов
local function StealthCollectItem(item)
    local success = false
    
    if not CheckActionLimit() then return false end
    if not CheckNearbyPlayers() then 
        HumanDelay()
        return false 
    end
    
    pcall(function()
        if not LocalPlayer.Character then return end
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        local distance = (item.Position - humanoidRootPart.Position).Magnitude
        
        if distance < 50 then
            -- Естественный подход (не по прямой)
            local randomOffset = Vector3.new(
                math.random(-3, 3),
                0,
                math.random(-3, 3)
            )
            
            local tweenInfo = TweenInfo.new(
                math.random(5, 15) / 10,
                Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut
            )
            
            local targetPos = CFrame.new(item.Position + randomOffset + Vector3.new(0, 3, 0))
            
            local tween = Services.TweenService:Create(humanoidRootPart, tweenInfo, {
                CFrame = targetPos
            })
            tween:Play()
            task.wait(0.8)
            
            -- Имитация естественного сбора (прыжок)
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and math.random(1, 3) == 1 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.5)
                humanoid:ChangeState(Enum.HumanoidStateType.Landed)
            end
            
            success = true
        end
    end)
    
    SimulateMouseMovement()
    
    return success
end

-- Скрытый GUI
local function CreateStealthGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "GameSync_Stealth_"
    gui.Parent = Services.CoreGui
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    
    -- Главная панель (компактная)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 120)
    mainFrame.Position = UDim2.new(1, -210, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false -- Скрыто по умолчанию
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = mainFrame
    
    -- Статус бар
    local statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(1, 0, 0, 3)
    statusBar.Position = UDim2.new(0, 0, 0, 0)
    statusBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    statusBar.Parent = mainFrame
    
    -- Иконка статуса
    local statusIcon = Instance.new("TextLabel")
    statusIcon.Size = UDim2.new(1, 0, 0, 20)
    statusIcon.Position = UDim2.new(0, 0, 0, 5)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Text = "🟢 READY"
    statusIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusIcon.Font = Enum.Font.GothamBold
    statusIcon.TextSize = 11
    statusIcon.Parent = mainFrame
    
    -- Информация
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -10, 0, 40)
    infoLabel.Position = UDim2.new(0, 5, 0, 28)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = ""
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 10
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = true
    infoLabel.Parent = mainFrame
    
    -- Кнопки управления
    local farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(0, 55, 0, 22)
    farmBtn.Position = UDim2.new(0, 5, 0, 72)
    farmBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    farmBtn.BackgroundTransparency = 0.3
    farmBtn.Text = "FARM"
    farmBtn.TextColor3 = Color3.new(1, 1, 1)
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = 10
    farmBtn.Parent = mainFrame
    
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0, 55, 0, 22)
    buyBtn.Position = UDim2.new(0, 65, 0, 72)
    buyBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    buyBtn.BackgroundTransparency = 0.3
    buyBtn.Text = "BUY"
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 10
    buyBtn.Parent = mainFrame
    
    local bothBtn = Instance.new("TextButton")
    bothBtn.Size = UDim2.new(0, 55, 0, 22)
    bothBtn.Position = UDim2.new(0, 125, 0, 72)
    bothBtn.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
    bothBtn.BackgroundTransparency = 0.3
    bothBtn.Text = "BOTH"
    bothBtn.TextColor3 = Color3.new(1, 1, 1)
    bothBtn.Font = Enum.Font.GothamBold
    bothBtn.TextSize = 10
    bothBtn.Parent = mainFrame
    
    -- Кнопка экстренного выключения
    local panicBtn = Instance.new("TextButton")
    panicBtn.Size = UDim2.new(1, -10, 0, 20)
    panicBtn.Position = UDim2.new(0, 5, 0, 97)
    panicBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    panicBtn.BackgroundTransparency = 0.3
    panicBtn.Text = "🛑 PANIC STOP"
    panicBtn.TextColor3 = Color3.new(1, 1, 1)
    panicBtn.Font = Enum.Font.GothamBold
    panicBtn.TextSize = 10
    panicBtn.Parent = mainFrame
    
    return {
        Frame = mainFrame,
        StatusBar = statusBar,
        StatusIcon = statusIcon,
        InfoLabel = infoLabel,
        FarmBtn = farmBtn,
        BuyBtn = buyBtn,
        BothBtn = bothBtn,
        PanicBtn = panicBtn
    }
end

-- Инициализация GUI
local GUI = CreateStealthGUI()
local isFarming = false
local isBuying = false
local totalClicks = 0
local totalCollected = 0

-- Функция обновления GUI
local function UpdateGUI()
    local nearbyInfo = SecuritySystem.NearbyPlayers
    local status = "IDLE"
    local color = Color3.fromRGB(100, 255, 100)
    
    if isFarming and isBuying then
        status = "FARM+BUY"
        color = Color3.fromRGB(255, 200, 0)
    elseif isFarming then
        status = "FARMING"
        color = Color3.fromRGB(100, 255, 100)
    elseif isBuying then
        status = "BUYING"
        color = Color3.fromRGB(100, 200, 255)
    end
    
    if SecuritySystem.IsOnCooldown then
        status = "COOLDOWN"
        color = Color3.fromRGB(255, 150, 0)
    end
    
    if nearbyInfo.Count > 0 then
        status = "PLAYERS NEAR"
        color = Color3.fromRGB(255, 80, 80)
    end
    
    GUI.StatusIcon.Text = "🟢 " .. status
    GUI.StatusIcon.TextColor3 = color
    
    GUI.InfoLabel.Text = string.format(
        "💰 %d | 🖱️ %d | ❌ %d\n👥 %d (%.0fm) | ⏱️ %d",
        GetMoney(),
        totalClicks,
        SecuritySystem.MistakesCount,
        nearbyInfo.Count,
        nearbyInfo.ClosestDistance == math.huge and 999 or nearbyInfo.ClosestDistance,
        SecuritySystem.ActionsThisMinute
    )
    
    -- Цвет статус бара
    GUI.StatusBar.BackgroundColor3 = color
end

-- Цикл фарма
local function FarmLoop()
    SecuritySystem.SessionStartTime = tick()
    
    while isFarming do
        pcall(function()
            if not CheckActionLimit() then
                GUI.StatusIcon.Text = "⏸️ LIMIT"
                HumanDelay()
                return
            end
            
            local items = FindFarmItems()
            
            if #items > 0 and CheckNearbyPlayers() then
                -- Сортируем по расстоянию
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    table.sort(items, function(a, b)
                        return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                    end)
                end
                
                -- Собираем только 1-2 предмета
                local collectCount = math.random(1, 2)
                for i = 1, collectCount do
                    if not isFarming then break end
                    if StealthCollectItem(items[i]) then
                        totalCollected = totalCollected + 1
                    end
                    HumanDelay()
                end
            end
            
            UpdateGUI()
        end)
        
        HumanDelay()
    end
end

-- Цикл покупки
local function BuyLoop()
    SecuritySystem.SessionStartTime = tick()
    
    while isBuying do
        pcall(function()
            if not CheckActionLimit() then
                GUI.StatusIcon.Text = "⏸️ LIMIT"
                HumanDelay()
                return
            end
            
            local buttons = FindClickableButtons()
            
            if #buttons > 0 and CheckNearbyPlayers() then
                -- Активируем только 1 кнопку за раз
                if StealthClickButton(buttons[1]) then
                    totalClicks = totalClicks + 1
                end
            end
            
            UpdateGUI()
        end)
        
        HumanDelay()
    end
end

-- Кнопка паники
GUI.PanicBtn.MouseButton1Click:Connect(function()
    isFarming = false
    isBuying = false
    GUI.Frame.Visible = false
    GUI.StatusIcon.Text = "🛑 STOPPED"
    
    -- Телепортируемся в безопасное место
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = 
                CFrame.new(0, 50, 0) -- Высоко в небе
        end
    end)
end)

-- Управление
Services.UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Скрыть/показать GUI
    if input.KeyCode == StealthConfig.GUIHotkey then
        GUI.Frame.Visible = not GUI.Frame.Visible
        return
    end
    
    if not GUI.Frame.Visible then return end
    
    if input.KeyCode == Enum.KeyCode.G then
        isFarming = not isFarming
        if isFarming then
            isBuying = false
            task.spawn(FarmLoop)
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        isBuying = not isBuying
        if isBuying then
            isFarming = false
            task.spawn(BuyLoop)
        end
    elseif input.KeyCode == Enum.KeyCode.H then
        if isFarming or isBuying then
            isFarming = false
            isBuying = false
        else
            isFarming = true
            isBuying = true
            task.spawn(FarmLoop)
            task.spawn(BuyLoop)
        end
    end
end)

-- Обновление GUI
task.spawn(function()
    while true do
        UpdateGUI()
        
        -- Авто-скрытие GUI при игроках рядом
        if StealthConfig.HideGUIWhenPlayersNear and not CheckNearbyPlayers() then
            GUI.Frame.Visible = false
        end
        
        task.wait(2)
    end
end)

print("🛡️ GameSync WAR - Stealth Mode Activated")
print("📋 Controls:")
print("   G - Farm | B - Buy | H - Both")
print("   RightCtrl - Show/Hide GUI")
print("   Panic Button - Emergency Stop")
print("🔒 Anti-Detection Features:")
print("   • Human-like delays")
print("   • Player avoidance")
print("   • Action limits")
print("   • Random mistakes")
print("   • Fake mouse movements")
