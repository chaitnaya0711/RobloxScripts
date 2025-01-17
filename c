local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- GUI Settings
local teleportDistance = 1.2
local teleportInterval = 0.00001
local isWalking = false

-- Create GUI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportControls"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0.5, -150, 0.8, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Add corner radius
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Teleport Controls"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Create Slider Function
local function createSlider(name, min, max, default, yPos)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = name .. "Slider"
    SliderFrame.Size = UDim2.new(0.8, 0, 0, 40)
    SliderFrame.Position = UDim2.new(0.1, 0, 0, yPos)
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Parent = MainFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.Parent = SliderFrame

    local Value = Instance.new("TextLabel")
    Value.Size = UDim2.new(0.2, 0, 0, 20)
    Value.Position = UDim2.new(0.8, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.Text = tostring(default)
    Value.TextColor3 = Color3.fromRGB(255, 255, 255)
    Value.TextSize = 14
    Value.Font = Enum.Font.Gotham
    Value.Parent = SliderFrame

    -- Make the click area larger for better mobile interaction
    local SliderArea = Instance.new("TextButton")
    SliderArea.Size = UDim2.new(1, 0, 0, 30)
    SliderArea.Position = UDim2.new(0, 0, 0.6, 0)
    SliderArea.BackgroundTransparency = 1
    SliderArea.Text = ""
    SliderArea.Parent = SliderFrame

    local SliderBG = Instance.new("Frame")
    SliderBG.Size = UDim2.new(1, 0, 0, 4)
    SliderBG.Position = UDim2.new(0, 0, 0.5, -2)
    SliderBG.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    SliderBG.BorderSizePixel = 0
    SliderBG.Parent = SliderArea

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBG

    local SliderButton = Instance.new("TextButton")
    SliderButton.Size = UDim2.new(0, 20, 0, 20)  -- Made larger for easier touch
    SliderButton.Position = UDim2.new((default - min)/(max - min), -10, 0.5, -10)
    SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderButton.Text = ""
    SliderButton.Parent = SliderBG

    -- Add corner radius to slider elements
    local UICorner1 = Instance.new("UICorner")
    UICorner1.CornerRadius = UDim.new(0, 2)
    UICorner1.Parent = SliderBG

    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 2)
    UICorner2.Parent = SliderFill

    local UICorner3 = Instance.new("UICorner")
    UICorner3.CornerRadius = UDim.new(1, 0)
    UICorner3.Parent = SliderButton

    -- Updated Slider Functionality
    local dragging = false
    local function updateSlider(input)
        local mousePos = input.Position
        local sliderPos = SliderBG.AbsolutePosition
        local sliderSize = SliderBG.AbsoluteSize
        
        local relativeX = mousePos.X - sliderPos.X
        local pos = math.clamp(relativeX / sliderSize.X, 0, 1)
        local value = min + (max - min) * pos
        
        -- Animate the slider movement
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        TweenService:Create(SliderFill, tweenInfo, {Size = UDim2.new(pos, 0, 1, 0)}):Play()
        TweenService:Create(SliderButton, tweenInfo, {Position = UDim2.new(pos, -10, 0.5, -10)}):Play()
        
        Value.Text = string.format("%.4f", value)
        
        if name == "Distance" then
            teleportDistance = value
        else
            teleportInterval = value
        end
        
        return value
    end

    -- Handle both touch and mouse input
    local function beginDrag()
        dragging = true
    end

    local function endDrag()
        dragging = false
    end

    local function handleDrag(input)
        if dragging then
            updateSlider(input)
        end
    end

    -- Mouse and touch input for the slider button
    SliderButton.MouseButton1Down:Connect(beginDrag)
    SliderButton.TouchLongPress:Connect(beginDrag)
    
    -- Mouse and touch input for the slider area
    SliderArea.MouseButton1Down:Connect(function(x, y)
        dragging = true
        updateSlider({Position = Vector2.new(x, y)})
    end)
    
    SliderArea.TouchLongPress:Connect(function(touch, state)
        dragging = true
        updateSlider({Position = Vector2.new(touch.Position.X, touch.Position.Y)})
    end)

    -- Global input handling
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and 
           (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    return SliderFrame
end

-- Create Sliders
createSlider("Distance", 0.1, 5, teleportDistance, 50)
createSlider("Interval", 0.00001, 0.01, teleportInterval, 100)

-- Teleport Logic
local function teleportWalk()
    while isWalking do
        local moveDirection = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            rootPart.CFrame = rootPart.CFrame + (moveDirection * teleportDistance)
        end
        task.wait(teleportInterval)
    end
end

-- Detect when the player starts walking
humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    if humanoid.MoveDirection.Magnitude > 0 then
        if not isWalking then
            isWalking = true
            teleportWalk()
        end
    else
        isWalking = false
    end
end)