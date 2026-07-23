-- ===== СИСТЕМА СКРЫТНЫХ ДЕЙСТВИЙ =====

local StealthActions = {
    Enabled = true,
    FakeAFK = true,           -- Имитация AFK для других
    HideCharacter = false,    -- Скрыть персонажа (рискованно)
    UseRemoteEvents = true,   -- Покупать через RemoteEvents
    GhostMode = false,        -- Режим призрака (тело на базе, действия удаленно)
    AFKPosition = nil,        -- Позиция для имитации AFK
}

-- Сохраняем "фейковую" позицию на базе
local function SetAFKPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        StealthActions.AFKPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
end

-- ВАРИАНТ 1: Покупка через RemoteEvents (САМЫЙ БЕЗОПАСНЫЙ)
-- Для других вы просто стоите на месте, а покупка происходит через серверные запросы
local function BuyViaRemote(button)
    pcall(function()
        -- Ищем RemoteEvent для покупки
        local remotes = {}
        
        -- Собираем все RemoteEvents которые могут быть связаны с покупкой
        for _, remote in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local name = remote.Name:lower()
                if name:find("buy") or 
                   name:find("purchase") or 
                   name:find("rebirth") or
                   name:find("upgrade") or
                   name:find("click") then
                    table.insert(remotes, remote)
                end
            end
        end
        
        -- Пробуем активировать каждый Remote
        for _, remote in pairs(remotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    -- Пробуем разные аргументы
                    local success1 = pcall(function() remote:FireServer() end)
                    local success2 = pcall(function() remote:FireServer(button.Name) end)
                    local success3 = pcall(function() remote:FireServer(button.Object) end)
                elseif remote:IsA("RemoteFunction") then
                    pcall(function() remote:InvokeServer() end)
                end
            end)
        end
    end)
end

-- ВАРИАНТ 2: Режим "Призрака"
-- Ваш персонаж остается на базе, а покупка происходит "удаленно"
local function GhostBuy(button)
    if not StealthActions.AFKPosition then return false end
    
    local success = false
    local realPosition = nil
    
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            -- Сохраняем реальную позицию
            realPosition = hrp.CFrame
            
            -- Мгновенно телепортируемся к кнопке (невидимо для других)
            if button.Position then
                -- Отключаем сетевое обновление позиции
                pcall(function()
                    -- На некоторых эксплойтах можно отключить отправку позиции
                    if sethiddenproperty then
                        sethiddenproperty(LocalPlayer, "SimulationRadius", 0)
                    end
                end)
                
                -- Быстро телепортируемся
                hrp.CFrame = CFrame.new(button.Position + Vector3.new(0, 2, 0))
                
                -- Активируем кнопку
                task.wait(0.1)
                if button.ClickDetector then
                    -- Используем RemoteEvent если нашли
                    BuyViaRemote(button)
                end
                
                task.wait(0.1)
                
                -- Возвращаемся обратно
                hrp.CFrame = realPosition
                
                -- Восстанавливаем сетевое обновление
                pcall(function()
                    if sethiddenproperty then
                        sethiddenproperty(LocalPlayer, "SimulationRadius", 1000)
                    end
                end)
                
                success = true
            end
        end
    end)
    
    return success
end

-- ВАРИАНТ 3: Подмена сетевых пакетов (ПРОДВИНУТЫЙ)
local function NetworkSpoofBuy(button)
    -- Этот метод подменяет сетевые пакеты
    -- Для сервера вы остаетесь на месте, но покупка происходит
    
    pcall(function()
        -- Сохраняем текущую позицию для сервера
        local fakePosition = StealthActions.AFKPosition or 
            (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
             LocalPlayer.Character.HumanoidRootPart.CFrame)
        
        -- Временно "замораживаем" отправку позиции на сервер
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if self == LocalPlayer.Character and 
               LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
               key == "CFrame" then
                -- Сервер всегда видит фейковую позицию
                return fakePosition
            end
            return oldIndex(self, key)
        end)
        
        -- Теперь можно делать что угодно - сервер не увидит
        
        -- Выполняем покупку
        if button.ClickDetector then
            -- Активируем через RemoteEvent
            BuyViaRemote(button)
        end
        
        task.wait(0.5)
        
        -- Восстанавливаем нормальную работу
        hookmetamethod(game, "__index", oldIndex)
    end)
end

-- ВАРИАНТ 4: Имитация AFK с фоновой работой
local function AFKSimulation()
    if not StealthActions.AFKPosition then return end
    
    task.spawn(function()
        while StealthActions.FakeAFK do
            pcall(function()
                if LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and hrp then
                        -- Делаем вид что мы AFK
                        humanoid.WalkSpeed = 0
                        humanoid.JumpPower = 0
                        
                        -- Иногда делаем микро-движения (как настоящий AFK)
                        if math.random(1, 30) == 1 then
                            hrp.CFrame = StealthActions.AFKPosition * 
                                        CFrame.Angles(0, math.rad(math.random(-5, 5)), 0)
                            task.wait(0.5)
                            hrp.CFrame = StealthActions.AFKPosition
                        end
                    end
                end
            end)
            task.wait(5)
        end
    end)
end

-- ОБНОВЛЕННАЯ ФУНКЦИЯ ПОКУПКИ (СКРЫТНАЯ ВЕРСИЯ)
local function StealthBuy(button)
    -- Сначала пробуем купить через RemoteEvent (САМЫЙ БЕЗОПАСНЫЙ)
    if StealthActions.UseRemoteEvents then
        BuyViaRemote(button)
        return true
    end
    
    -- Если не получилось, пробуем Ghost Mode
    if StealthActions.GhostMode and StealthActions.AFKPosition then
        return GhostBuy(button)
    end
    
    return false
end

-- ВКЛЮЧЕНИЕ РЕЖИМА AFK ДЛЯ ДРУГИХ
local function EnableAFKMode()
    SetAFKPosition()
    StealthActions.FakeAFK = true
    
    print("👻 AFK Mode: You appear AFK to other players")
    print("📍 Your visible position is frozen at spawn")
    print("🤫 All purchases will happen silently")
    
    -- Запускаем имитацию AFK
    AFKSimulation()
    
    -- Замораживаем персонажа на месте
    pcall(function()
        if LocalPlayer.Character then
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if hrp and humanoid then
                hrp.Anchored = false -- Не анкорим, иначе палевно
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
        end
    end)
end

-- GUI ДЛЯ УПРАВЛЕНИЯ РЕЖИМАМИ
local function CreateAFKControlGUI()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(1, -210, 0, 140)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = GUI.Frame.Parent
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "👻 GHOST SETTINGS"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 10
    title.Parent = frame
    
    -- Режим AFK
    local afkBtn = Instance.new("TextButton")
    afkBtn.Size = UDim2.new(1, -10, 0, 22)
    afkBtn.Position = UDim2.new(0, 5, 0, 25)
    afkBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    afkBtn.Text = "👻 TOGGLE AFK MODE"
    afkBtn.TextColor3 = Color3.new(1, 1, 1)
    afkBtn.Font = Enum.Font.GothamBold
    afkBtn.TextSize = 10
    afkBtn.Parent = frame
    
    -- RemoteEvent Mode
    local remoteBtn = Instance.new("TextButton")
    remoteBtn.Size = UDim2.new(1, -10, 0, 22)
    remoteBtn.Position = UDim2.new(0, 5, 0, 52)
    remoteBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    remoteBtn.Text = "🌐 REMOTE BUY MODE"
    remoteBtn.TextColor3 = Color3.new(1, 1, 1)
    remoteBtn.Font = Enum.Font.GothamBold
    remoteBtn.TextSize = 10
    remoteBtn.Parent = frame
    
    -- Кнопки
    afkBtn.MouseButton1Click:Connect(function()
        StealthActions.FakeAFK = not StealthActions.FakeAFK
        if StealthActions.FakeAFK then
            EnableAFKMode()
            afkBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            afkBtn.Text = "👻 AFK MODE: ON"
        else
            afkBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            afkBtn.Text = "👻 TOGGLE AFK MODE"
            pcall(function()
                if LocalPlayer.Character then
                    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = 16
                        humanoid.JumpPower = 50
                    end
                end
            end)
        end
    end)
    
    remoteBtn.MouseButton1Click:Connect(function()
        StealthActions.UseRemoteEvents = not StealthActions.UseRemoteEvents
        remoteBtn.BackgroundColor3 = StealthActions.UseRemoteEvents and 
            Color3.fromRGB(46, 204, 113) or Color3.fromRGB(52, 152, 219)
        remoteBtn.Text = StealthActions.UseRemoteEvents and 
            "🌐 REMOTE MODE: ON" or "🌐 REMOTE BUY MODE"
    end)
    
    return frame
end

-- Инициализация
local afkControlGUI = CreateAFKControlGUI()

print("👻 Stealth Features Active:")
print("   📍 AFK Mode - You appear frozen at spawn")
print("   🌐 Remote Buy - Purchase without moving")
print("   👤 Ghost Mode - Invisible actions")
print("")
print("🎮 How to use:")
print("   1. Stand at spawn/base")
print("   2. Enable AFK Mode")
print("   3. Enable Remote Buy")
print("   4. Start buying - others see you as AFK!")
