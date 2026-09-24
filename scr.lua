-- nl-menu-rb: compact, configurable Neverlose-style UI library.
-- AddWindow accepts legacy arguments or an options table.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local function New(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do object[property] = value end
    if parent then object.Parent = parent end
    return object
end

local function Tween(object, properties, duration, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(duration or .18, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function Corner(parent, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function MakeDraggable(target, handle)
    handle = handle or target
    local active, startInput, startPosition
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        active, startInput, startPosition = true, input, target.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then active = false end
        end)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not active or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
        local delta = input.Position - startInput.Position
        target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)
end

local function GetImage(name)
    local icons = {gear = "rbxassetid://134488580093972", arrow = "rbxassetid://10709790948", check = "rbxassetid://138494545053627"}
    return icons[(name or ""):lower()] or name or ""
end

function Library:AddWindow(a, b, c, d)
    local options = type(a) == "table" and a or {Title = a, Image = b, GameTitle = c, Size = d}
    local title, gameTitle = options.Title or options.HubTitle or "Neverlose", options.GameTitle or "Counter Strike 2"
    local showLogo, accent = options.ShowLogo ~= false, options.Color or Color3.fromRGB(26, 123, 255)
    local requestedSize = options.Size or Vector2.new(760, 540)
    local minSize, maxSize = options.MinSize or Vector2.new(520, 360), options.MaxSize or Vector2.new(1300, 900)

    local gui = New("ScreenGui", {Name = "NLMenu", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global}, game.CoreGui)
    local main = New("Frame", {Name = "MainFrame", Active = true, AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5), Size = UDim2.fromOffset(requestedSize.X, requestedSize.Y), BackgroundColor3 = Color3.fromRGB(10,13,22), BackgroundTransparency = .08, BorderSizePixel = 0, ClipsDescendants = true}, gui)
    Corner(main, 10); New("UIStroke", {Color = Color3.fromRGB(62,73,105), Transparency = .65}, main)
    local header = New("Frame", {Name = "Header", Size = UDim2.new(1,0,0,58), BackgroundTransparency = 1}, main); MakeDraggable(main, header)
    local logo = New("ImageLabel", {Name = "Logo", Visible = showLogo and (options.Image or "") ~= "", Position = UDim2.fromOffset(14,11), Size = UDim2.fromOffset(36,36), BackgroundTransparency = 1, Image = options.Image or "", ScaleType = Enum.ScaleType.Fit}, header); Corner(logo,7)
    local titleLabel = New("TextLabel", {Position = UDim2.fromOffset(showLogo and 60 or 16,8), Size = UDim2.new(.5,0,0,25), BackgroundTransparency = 1, Text = title, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left}, header)
    local gameLabel = New("TextLabel", {Position = UDim2.fromOffset(showLogo and 60 or 16,31), Size = UDim2.new(.5,0,0,17), BackgroundTransparency = 1, Text = gameTitle, TextColor3 = Color3.fromRGB(155,163,183), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, header)
    New("Frame", {Position = UDim2.new(0,0,1,-1), Size = UDim2.new(1,0,0,1), BackgroundColor3 = Color3.fromRGB(55,65,90), BackgroundTransparency = .55, BorderSizePixel = 0}, header)
    local sidebar = New("ScrollingFrame", {Name="Tabs", Position=UDim2.fromOffset(10,68), Size=UDim2.new(0,150,1,-78), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=0, AutomaticCanvasSize=Enum.AutomaticSize.Y}, main); New("UIListLayout", {Padding=UDim.new(0,5)}, sidebar)
    local content = New("Frame", {Name="Content", Position=UDim2.fromOffset(170,68), Size=UDim2.new(1,-180,1,-78), BackgroundTransparency=1, ClipsDescendants=true}, main)
    local tabs = {}
    local function Activate(tab) for _, item in ipairs(tabs) do item.page.Visible=item==tab; Tween(item.button,{BackgroundTransparency=item==tab and .78 or 1},.2); Tween(item.label,{TextColor3=item==tab and Color3.new(1,1,1) or Color3.fromRGB(165,173,193)},.2) end end
    local window = {}
    function window:SetSize(size) size=Vector2.new(math.clamp(size.X,minSize.X,maxSize.X),math.clamp(size.Y,minSize.Y,maxSize.Y)); Tween(main,{Size=UDim2.fromOffset(size.X,size.Y)},.25,Enum.EasingStyle.Quint) end
    function window:GetSize() return main.AbsoluteSize end
    function window:SetLogo(image, visible) if image~=nil then logo.Image=image end; if visible~=nil then logo.Visible=visible end; titleLabel.Position=UDim2.fromOffset(logo.Visible and 60 or 16,8); gameLabel.Position=UDim2.fromOffset(logo.Visible and 60 or 16,31) end
    function window:Toggle(value) gui.Enabled=value==nil and not gui.Enabled or value end
    function window:Destroy() gui:Destroy() end
    local resize=New("TextButton",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-4,1,-4),Size=UDim2.fromOffset(22,22),BackgroundTransparency=1,Text="↘",TextColor3=Color3.fromRGB(145,155,180),TextSize=16,ZIndex=20},main); local resizing,resizeStart,sizeStart
    resize.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then resizing,resizeStart,sizeStart=true,input.Position,main.AbsoluteSize; input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then resizing=false end end) end end)
    UserInputService.InputChanged:Connect(function(input) if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local delta=input.Position-resizeStart; window:SetSize(Vector2.new(sizeStart.X+delta.X,sizeStart.Y+delta.Y)) end end)
    function window:AddTab(name, icon)
        local tab={}; local button=New("TextButton",{Size=UDim2.new(1,-4,0,34),BackgroundColor3=Color3.fromRGB(36,43,64),BackgroundTransparency=1,Text="",AutoButtonColor=false},sidebar); Corner(button,6)
        if icon and icon~="" then New("ImageLabel",{Position=UDim2.fromOffset(10,8),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,Image=GetImage(icon),ImageColor3=accent},button) end
        local label=New("TextLabel",{Position=UDim2.fromOffset(icon and 36 or 12,0),Size=UDim2.new(1,-42,1,0),BackgroundTransparency=1,Text=name,TextColor3=Color3.fromRGB(165,173,193),Font=Enum.Font.GothamSemibold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},button)
        local page=New("Frame",{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,ClipsDescendants=true},content); New("UIListLayout",{Padding=UDim.new(0,12)},page); table.insert(tabs,{button=button,label=label,page=page}); local index=#tabs; button.MouseButton1Click:Connect(function() Activate(tabs[index]) end)
        function tab:AddSection(sectionName)
            local section=New("Frame",{Name="Section",Size=UDim2.new(1,-4,0,40),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(21,26,39),BackgroundTransparency=.18,BorderSizePixel=0,ClipsDescendants=true},page); Corner(section,7); New("UIStroke",{Color=Color3.fromRGB(55,65,90),Transparency=.7},section); New("TextLabel",{Name="SectionLabel",Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,20),BackgroundTransparency=1,Text=sectionName,TextColor3=Color3.fromRGB(145,155,180),Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},section)
            local body=New("Frame",{Name="Elements",Position=UDim2.fromOffset(8,34),Size=UDim2.new(1,-16,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ClipsDescendants=true},section); New("UIListLayout",{Padding=UDim.new(0,5)},body); local sec={}
            function sec:AddToggle(text,default,callback)
                local value=default==true; local row=New("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Text="",AutoButtonColor=false},body); New("TextLabel",{Position=UDim2.fromOffset(4,0),Size=UDim2.new(1,-62,1,0),BackgroundTransparency=1,Text=text,TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},row); local switch=New("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-5,.5,0),Size=UDim2.fromOffset(42,20),BackgroundColor3=value and accent or Color3.fromRGB(45,52,72)},row); Corner(switch,10); local knob=New("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(value and 1 or 0,value and -18 or 4,.5,0),Size=UDim2.fromOffset(14,14),BackgroundColor3=Color3.new(1,1,1)},switch); Corner(knob,7)
                local function set(v,silent) value=v==true; Tween(switch,{BackgroundColor3=value and accent or Color3.fromRGB(45,52,72)},.18); Tween(knob,{Position=UDim2.new(value and 1 or 0,value and -18 or 4,.5,0)},.2,Enum.EasingStyle.Back); if callback and not silent then callback(value) end end; row.MouseButton1Click:Connect(function() set(not value) end); local obj={}; function obj:Set(v) set(v) end; function obj:Get() return value end; return obj
            end
            function sec:AddCheckbox(text,default,callback) return self:AddToggle(text,default,callback) end
            function sec:AddDropdown(text,options,default,callback) local value=default or options[1]; local obj={}; function obj:Set(v,silent) value=v; if callback and not silent then callback(v) end end; function obj:Get() return value end; return obj end
            return sec
        end
        if #tabs==1 then Activate(tabs[1]) end; return tab
    end
    return window
end
return Library
