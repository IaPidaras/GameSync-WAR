-- ===== БЕЗОПАСНЫЙ АВТО-СБОР (НЕ ВЗЛАМЫВАЕТ ДОНАТ) =====

local AutoCollect = {
    Enabled = false,
    Range = 50,              -- Радиус сбора
    Speed = 1,               -- Скорость (1 = медленно, 5 = быстро)
    CollectCoins = true,     -- Собирать монеты
    CollectGems = true,      -- Собирать гемы
    CollectCrates = true,    -- Собирать ящики
    UseTouchMethod = true,   -- Метод касания (безопаснее)
    AvoidDonateButton = true,-- НЕ трогать донатную кнопку!
}

-- Поиск предметов для сбора (как донат, но без взлома)
local function FindCollectibles()
    local items = {}
    
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 1 then
                local name = obj.Name:lower()
                local canCollect = false
                local itemType = "Unknown"
                
                -- Определяем тип предмета
                if AutoCollect.CollectCoins and (name:find("coin") or name:find("money")) then
                    canCollect = true
                    itemType = "Coin"
                elseif AutoCollect.CollectGems and (name:find("gem") or name:find("diamond")) then
                    canCollect = true
                    itemType = "Gem"
                elseif AutoCollect.CollectCrates and (name:find("crate") or name:find("chest") or name:find("box")) then
                    canCollect = true
                    itemType = "Crate"
                end
                
                -- ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: не трогаем донатные объекты!
                if AutoCollect.AvoidDonateButton then
                    if name:find("donate") or name:find("premium") or name:find("vip") or name:find("gamepass") then
                        canCollect = false
                    end
                end
                
                -- Проверяем что предмет можно собрать
                if canCollect then
                    local hasTouch = obj:FindFirstChildOfClass("TouchTransmitter") ~= nil
                    local hasClick = obj:FindFirstChildOfClass("ClickDetector") ~= nil
                    local hasProximity = obj:FindFirstChildOfClass("ProximityPrompt") ~= nil
                    
                    if hasTouch or hasClick or hasProximity then
                        table.insert(items, {
                            Object = obj,
                            Position = obj.Position,
                            Type = itemType,
                            HasTouch = hasTouch,
                            HasClick = hasClick,
                            HasProximity = hasProximity
                        })
                    end
                end
            end
        end
    end)
    
    return items
end

-- Безопасный сбор предмета (НЕ через взлом доната)
local function SafeCollect(item)
    local success = false
    
    pcall(function()
        if not LocalPlayer.Character then return end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local distance = (item.Position - hrp.Position).Magnitude
        
        if distance <= AutoCollect.Range then
            -- Метод 1: Через касание (самый безопасный)
            if item.HasTouch and AutoCollect.UseTouchMethod then
                -- Плавно подходим
                local tween = TweenService:Create(hrp, 
                    TweenInfo.new(distance / (50 * AutoCollect.Speed)), 
                    {CFrame = CFrame.new(item.Position + Vector3.new(0, 3, 0))})
                tween:Play()
                task.wait(0.5)
                
                -- Прыжок для активации касания
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.3)
                    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                end
                
                success = true
            end
            
            -- Метод 2: Через ClickDetector (если есть)
            if item.HasClick and not success then
                local screenPos = Camera:WorldToScreenPoint(item.Position)
                VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, true, nil, 0)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(screenPos.X, screenPos.Y, 0, false, nil, 0)
                success = true
            end
            
            -- Метод 3: Через ProximityPrompt (если есть)
            if item.HasProximity and not success then
                local prompt = item.Object:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    -- Активируем через InputHold
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(0.3)
                        prompt:InputHoldEnd()
                    end)
                    success = true
                end
            end
        end
    end)
    
    return success
end

-- ===== GUI ДЛЯ АВТО-СБОРА =====
local function AddAutoCollectGUI(existingGUI)
    -- Добавляем новую секцию в существующий GUI
    local collectFrame = Instance.new("Frame")
    collectFrame.Size = UDim2.new(1, -20, 0, 80)
    collectFrame.Position = UDim2.new(0, 10, 0, 170)
    collectFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    collectFrame.Parent = existingGUI.Frame
    
    local collectCorner = Instance.new("UICorner")
    collectCorner.CornerRadius = UDim.new(0, 4)
    collectCorner.Parent = collectFrame
    
    local collectTitle = Instance.new("TextLabel")
    collectTitle.Size = UDim2.new(1, 0, 0, 20)
    collectTitle.BackgroundTransparency = 1
    collectTitle.Text = "🎁 AUTO COLLECT (Free)"
    collectTitle.TextColor3 = Color3.new(1, 1, 1)
    collectTitle.Font = Enum.Font.GothamBold
    collectTitle.TextSize = 10
    collectTitle.Parent = collectFrame
    
    local collectBtn = Instance.new("TextButton")
    collectBtn.Size = UDim2.new(1, -10, 0, 22)
    collectBtn.Position = UDim2.new(0, 5, 0, 22)
    collectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    collectBtn.Text = "🎁 AUTO COLLECT: OFF"
    collectBtn.TextColor3 = Color3.new(1, 1, 1)
    collectBtn.Font = Enum.Font.GothamBold
    collectBtn.TextSize = 10
    collectBtn.Parent = collectFrame
    
    local collectCorner2 = Instance.new("UICorner")
    collectCorner2.CornerRadius = UDim.new(0, 3)
    collectCorner2.Parent = collectBtn
    
    -- Статус сбора
    local collectStatus = Instance.new("TextLabel")
    collectStatus.Size = UDim2.new(1, -10, 0, 15)
    collectStatus.Position = UDim2.new(0, 5, 0, 48)
    collectStatus.BackgroundTransparency = 1
    collectStatus.Text = "Items: 0 | Range: " .. AutoCollect.Range
    collectStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    collectStatus.Font = Enum.Font.Gotham
    collectStatus.TextSize = 9
    collectStatus.TextXAlignment = Enum.TextXAlignment.Left
    collectStatus.Parent = collectFrame
    
    -- Слайдер радиуса
    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Size = UDim2.new(0, 40, 0, 15)
    rangeLabel.Position = UDim2.new(0, 5, 0, 63)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Text = "Range:"
    rangeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextSize = 9
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    rangeLabel.Parent = collectFrame
    
    local rangeSlider = Instance.new("TextBox")
    rangeSlider.Size = UDim2.new(1, -50, 0, 15)
    rangeSlider.Position = UDim2.new(0, 45, 0, 63)
    rangeSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    rangeSlider.Text = tostring(AutoCollect.Range)
    rangeSlider.TextColor3 = Color3.new(1, 1, 1)
    rangeSlider.Font = Enum.Font.Gotham
    rangeSlider.TextSize = 9
    rangeSlider.Parent = collectFrame
    
    -- Обработчики
    local isCollecting = false
    
    collectBtn.MouseButton1Click:Connect(function()
        isCollecting = not isCollecting
        if isCollecting then
            collectBtn.Text = "🎁 AUTO COLLECT: ON"
            collectBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        else
            collectBtn.Text = "🎁 AUTO COLLECT: OFF"
            collectBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        end
    end)
    
    rangeSlider.FocusLost:Connect(function()
        local newRange = tonumber(rangeSlider.Text)
        if newRange and newRange > 0 and newRange <= 200 then
            AutoCollect.Range = newRange
            collectStatus.Text = "Items: ? | Range: " .. AutoCollect.Range
        end
    end)
    
    -- Цикл авто-сбора
    task.spawn(function()
        while true do
            if isCollecting then
                pcall(function()
                    local items = FindCollectibles()
                    
                    if #items > 0 then
                        -- Сортируем по расстоянию
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = LocalPlayer.Character.HumanoidRootPart
                            table.sort(items, function(a, b)
                                return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
                            end)
                        end
                        
                        -- Собираем ближайшие 3 предмета
                        local collected = 0
                        for i = 1, math.min(3, #items) do
                            if SafeCollect(items[i]) then
                                collected = collected + 1
                            end
                            task.wait(math.random(5, 15) / 10) -- Задержка 0.5-1.5с
                        end
                        
                        collectStatus.Text = "Items: " .. #items .. " | Range: " .. AutoCollect.Range
                    else
                        collectStatus.Text = "Searching... | Range: " .. AutoCollect.Range
                    end
                end)
            end
            
            -- Частота проверки зависит от скорости
            task.wait(2 / AutoCollect.Speed)
        end
    end)
    
    return collectFrame
end

-- Добавляем в основной GUI
AddAutoCollectGUI(GUI)

-- Увеличиваем размер главного фрейма
GUI.Frame.Size = UDim2.new(0, 250, 0, 260)

-- Горячая клавиша для авто-сбора
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C then
        -- Переключаем авто-сбор
        local collectBtn = GUI.Frame:FindFirstChild("CollectBtn", true)
        if collectBtn then
            collectBtn.Text = collectBtn.Text:find("OFF") and "🎁 AUTO COLLECT: ON" or "🎁 AUTO COLLECT: OFF"
        end
    end
end)

print("🎁 Auto Collect Mode Added (Free & Safe)!")
print("   C - Toggle Auto Collect")
print("   Range: " .. AutoCollect.Range .. " studs")
print("   ⚠️ NEVER touches donate buttons!")
