local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}
Library.__index = Library

local function New(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function Tween(obj, props, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration or 0.18, easingStyle or Enum.EasingStyle.Quint, easingDirection or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

local function Corner(parent, radius)
    local c = New("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
    return c
end

local function Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function MakeDraggable(target, handle)
    handle = handle or target
    local dragging = false
    local startPos = nil
    local startMouse = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        startPos = target.Position
        startMouse = input.Position
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMouse
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function GetIcon(name)
    local icons = {
        gear = "rbxassetid://134488580093972",
        arrow = "rbxassetid://10709790948",
        check = "rbxassetid://138494545053627",
        search = "rbxassetid://6031154871",
    }
    return icons[(name or ""):lower()] or name or ""
end

local function MakeSettingToggle(parent, text, default, callback)
    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(21, 24, 35),
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    Corner(frame, 6)

    local label = New("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -52, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 225, 235),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)

    local enabled = default == true
    local toggle = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(36, 18),
        BackgroundColor3 = enabled and Color3.fromRGB(28, 134, 255) or Color3.fromRGB(63, 69, 86),
        BorderSizePixel = 0,
    }, frame)
    Corner(toggle, 9)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, toggle)
    Corner(knob, 7)

    local button = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, frame)

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Tween(toggle, {
            BackgroundColor3 = enabled and Color3.fromRGB(28, 134, 255) or Color3.fromRGB(63, 69, 86)
        }, 0.18)
        Tween(knob, {
            Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0)
        }, 0.18)
        if callback then callback(enabled) end
    end)

    return {
        Set = function(v)
            enabled = v == true
            Tween(toggle, {
                BackgroundColor3 = enabled and Color3.fromRGB(28, 134, 255) or Color3.fromRGB(63, 69, 86)
            }, 0.18)
            Tween(knob, {
                Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0)
            }, 0.18)
        end,
        Get = function()
            return enabled
        end,
    }
end

function Library:AddWindow(a, b, c, d)
    local options = type(a) == "table" and a or {
        Title = a,
        Image = b,
        GameTitle = c,
        Size = d,
    }

    local title = options.Title or options.HubTitle or "nl-menu-rb"
    local gameTitle = options.GameTitle or "Game"
    local accent = options.Color or Color3.fromRGB(25, 120, 255)
    local showLogo = options.ShowLogo ~= false
    local size = options.Size or Vector2.new(760, 540)

    local gui = New("ScreenGui", {
        Name = "NLMenu",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
    }, game.CoreGui)

    local main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundColor3 = Color3.fromRGB(10, 13, 20),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)
    Corner(main, 12)
    New("UIStroke", {
        Color = Color3.fromRGB(90, 99, 120),
        Transparency = 0.6,
        Thickness = 1,
    }, main)

    local header = New("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
    }, main)
    MakeDraggable(main, header)

    local logo = New("ImageLabel", {
        Position = UDim2.fromOffset(14, 11),
        Size = UDim2.fromOffset(36, 36),
        BackgroundTransparency = 1,
        Visible = showLogo and (options.Image ~= nil and options.Image ~= ""),
        Image = options.Image or "",
        ScaleType = Enum.ScaleType.Fit,
    }, header)
    Corner(logo, 8)

    local titleLabel = New("TextLabel", {
        Position = UDim2.fromOffset(showLogo and 60 or 18, 9),
        Size = UDim2.new(1, -(showLogo and 80 or 40), 0, 24),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    local subtitle = New("TextLabel", {
        Position = UDim2.fromOffset(showLogo and 60 or 18, 31),
        Size = UDim2.new(1, -(showLogo and 90 or 40), 0, 18),
        BackgroundTransparency = 1,
        Text = gameTitle,
        TextColor3 = Color3.fromRGB(168, 176, 192),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    local divider = New("Frame", {
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(63, 71, 87),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, header)

    local sidebar = New("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 66),
        Size = UDim2.new(0, 150, 1, -76),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    }, main)
    local sidebarLayout = New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)

    local content = New("Frame", {
        Position = UDim2.fromOffset(168, 66),
        Size = UDim2.new(1, -178, 1, -76),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, main)

    local tabs = {}
    local activeTab = nil

    local function ActivateTab(tab)
        for _, item in ipairs(tabs) do
            item.page.Visible = item == tab
            local bg = item == tab and Color3.fromRGB(36, 44, 62) or Color3.fromRGB(32, 39, 53)
            Tween(item.button, {
                BackgroundColor3 = bg,
                BackgroundTransparency = 0.15,
            }, 0.16)
            Tween(item.label, {
                TextColor3 = item == tab and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 180, 196),
            }, 0.16)
        end
        activeTab = tab
    end

    local window = {}

    function window:SetSize(newSize)
        local x = Clamp(newSize.X, 520, 1200)
        local y = Clamp(newSize.Y, 360, 900)
        Tween(main, {
            Size = UDim2.fromOffset(x, y),
        }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end

    function window:GetSize()
        return main.AbsoluteSize
    end

    function window:SetLogo(image, visible)
        if image ~= nil then
            logo.Image = image
            logo.Visible = visible ~= false
        elseif visible ~= nil then
            logo.Visible = visible
        end

        titleLabel.Position = UDim2.fromOffset(logo.Visible and 60 or 18, 9)
        subtitle.Position = UDim2.fromOffset(logo.Visible and 60 or 18, 31)
    end

    function window:Toggle(value)
        if value == nil then
            gui.Enabled = not gui.Enabled
            return
        end
        gui.Enabled = value
    end

    function window:Destroy()
        gui:Destroy()
    end

    local resizeHandle = New("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -4, 1, -4),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Text = "↘",
        TextColor3 = Color3.fromRGB(155, 163, 180),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
    }, main)

    local resizing = false
    local startPos = nil
    local startSize = nil

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startPos = input.Position
            startSize = main.AbsoluteSize
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startPos
            local newSize = Vector2.new(startSize.X + delta.X, startSize.Y + delta.Y)
            window:SetSize(newSize)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)

    function window:AddTab(name, icon)
        local tab = {}

        local button = New("TextButton", {
            Size = UDim2.new(1, -10, 0, 32),
            BackgroundColor3 = Color3.fromRGB(32, 39, 53),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, sidebar)
        Corner(button, 8)

        if icon and icon ~= "" then
            local iconImg = New("ImageLabel", {
                Position = UDim2.fromOffset(10, 7),
                Size = UDim2.fromOffset(18, 18),
                BackgroundTransparency = 1,
                Image = GetIcon(icon),
                ImageColor3 = accent,
            }, button)
        end

        local label = New("TextLabel", {
            Position = UDim2.fromOffset(icon and 36 or 12, 0),
            Size = UDim2.new(1, -(icon and 42 or 18), 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Color3.fromRGB(173, 182, 198),
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, button)

        local page = New("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ClipsDescendants = true,
        }, content)
        local pageLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)

        table.insert(tabs, { button = button, label = label, page = page })

        button.MouseButton1Click:Connect(function()
            ActivateTab(tabs[#tabs])
        end)

        function tab:AddSection(title)
            local section = New("Frame", {
                Size = UDim2.new(1, -8, 0, 34),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(20, 24, 35),
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, page)
            Corner(section, 10)

            local header = New("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
            }, section)

            local sectionLabel = New("TextLabel", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -40, 1, 0),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = Color3.fromRGB(183, 189, 202),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, header)

            local chevron = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(10, 10),
                BackgroundTransparency = 1,
                Image = GetIcon("arrow"),
                ImageColor3 = Color3.fromRGB(158, 166, 183),
                Rotation = 0,
            }, header)

            local body = New("Frame", {
                Position = UDim2.fromOffset(8, 34),
                Size = UDim2.new(1, -16, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ClipsDescendants = true,
            }, section)
            local bodyLayout = New("UIListLayout", {
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, body)

            local expanded = true

            local function setExpanded(v)
                expanded = v
                Tween(chevron, { Rotation = expanded and 0 or -90 }, 0.18)
                body.Visible = expanded
                if expanded then
                    section.Size = UDim2.new(1, -8, 0, 34)
                    section.AutomaticSize = Enum.AutomaticSize.Y
                else
                    section.Size = UDim2.new(1, -8, 0, 34)
                end
            end

            local collapsible = New("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            }, header)
            collapsible.MouseButton1Click:Connect(function()
                setExpanded(not expanded)
            end)

            local sectionObj = {}

            local function addBasicRow()
                return New("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Color3.fromRGB(16, 19, 28),
                    BorderSizePixel = 0,
                }, body)
            end

            function sectionObj:AddToggle(text, default, callback)
                local row = addBasicRow()
                Corner(row, 8)

                local label = New("TextLabel", {
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -62, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Color3.fromRGB(234, 238, 244),
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, row)

                local enabled = default == true
                local toggleBg = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(36, 18),
                    BackgroundColor3 = enabled and accent or Color3.fromRGB(63, 69, 86),
                    BorderSizePixel = 0,
                }, row)
                Corner(toggleBg, 9)

                local knob = New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                }, toggleBg)
                Corner(knob, 7)

                local settings = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -54, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    BackgroundTransparency = 1,
                    Text = "⚙",
                    TextColor3 = Color3.fromRGB(170, 179, 194),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    AutoButtonColor = false,
                }, row)

                local settingsPanel = New("Frame", {
                    Position = UDim2.new(0, 0, 1, 4),
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(15, 18, 25),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ClipsDescendants = true,
                    Visible = false,
                }, row)
                Corner(settingsPanel, 8)
                local settingsLayout = New("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, settingsPanel)

                local settingsOpen = false
                settings.MouseButton1Click:Connect(function()
                    settingsOpen = not settingsOpen
                    settingsPanel.Visible = settingsOpen
                    Tween(settings, { TextColor3 = settingsOpen and accent or Color3.fromRGB(170, 179, 194) }, 0.15)
                end)

                local function SetValue(v)
                    enabled = v == true
                    Tween(toggleBg, {
                        BackgroundColor3 = enabled and accent or Color3.fromRGB(63, 69, 86),
                    }, 0.15)
                    Tween(knob, {
                        Position = UDim2.new(enabled and 1 or 0, enabled and -18 or 2, 0.5, 0),
                    }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    if callback then callback(enabled) end
                end

                row.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        SetValue(not enabled)
                    end
                end)

                local obj = {}
                function obj:Set(v)
                    SetValue(v)
                end
                function obj:Get()
                    return enabled
                end
                function obj:AddSettings()
                    local item = MakeSettingToggle(settingsPanel, "Option", true)
                    return item
                end
                return obj
            end

            function sectionObj:AddCheckbox(text, default, callback)
                return sectionObj:AddToggle(text, default, callback)
            end

            function sectionObj:AddSlider(text, min, max, default, callback, suffix)
                local row = addBasicRow()
                Corner(row, 8)

                min = min or 0
                max = max or 100
                default = default or min
                local value = Clamp(default, min, max)

                local label = New("TextLabel", {
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Color3.fromRGB(240, 244, 249),
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, row)

                local valueLabel = New("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -10, 0, 4),
                    Size = UDim2.fromOffset(60, 16),
                    BackgroundTransparency = 1,
                    Text = tostring(value) .. (suffix or ""),
                    TextColor3 = Color3.fromRGB(185, 191, 204),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, row)

                local track = New("Frame", {
                    Position = UDim2.fromOffset(10, 24),
                    Size = UDim2.new(1, -20, 0, 6),
                    BackgroundColor3 = Color3.fromRGB(52, 58, 74),
                    BorderSizePixel = 0,
                }, row)
                Corner(track, 5)

                local fill = New("Frame", {
                    Size = UDim2.fromScale((value - min) / (max - min), 1),
                    BackgroundColor3 = accent,
                    BorderSizePixel = 0,
                }, track)
                Corner(fill, 5)

                local drag = false
                local function updateValue(v)
                    value = Clamp(v, min, max)
                    local ratio = (value - min) / (max - min)
                    fill.Size = UDim2.fromScale(ratio, 1)
                    valueLabel.Text = tostring(math.floor(value)) .. (suffix or "")
                    if callback then callback(value) end
                end

                track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        drag = true
                        local x = Clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        updateValue(min + (max - min) * x)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local x = Clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        updateValue(min + (max - min) * x)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        drag = false
                    end
                end)

                local obj = {}
                function obj:Set(v)
                    updateValue(v)
                end
                function obj:Get()
                    return value
                end
                return obj
            end

            function sectionObj:AddDropdown(text, options, default, callback)
                local row = addBasicRow()
                Corner(row, 8)

                options = options or {}
                default = default or (options[1] or "Select")
                local selected = default

                local label = New("TextLabel", {
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Color3.fromRGB(240, 244, 249),
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, row)

                local valueBtn = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(110, 18),
                    BackgroundColor3 = Color3.fromRGB(30, 35, 46),
                    BorderSizePixel = 0,
                    Text = tostring(selected),
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    AutoButtonColor = false,
                }, row)
                Corner(valueBtn, 6)

                local list = New("Frame", {
                    Position = UDim2.new(0, 0, 1, 4),
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(18, 22, 31),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ClipsDescendants = true,
                }, row)
                Corner(list, 8)
                local listLayout = New("UIListLayout", {
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, list)

                for _, opt in ipairs(options) do
                    local optionBtn = New("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = Color3.fromRGB(25, 30, 39),
                        BorderSizePixel = 0,
                        Text = tostring(opt),
                        TextColor3 = Color3.fromRGB(240, 245, 255),
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        AutoButtonColor = false,
                    }, list)
                    Corner(optionBtn, 6)
                    optionBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        valueBtn.Text = tostring(opt)
                        list.Visible = false
                        if callback then callback(opt) end
                    end)
                end

                local open = false
                valueBtn.MouseButton1Click:Connect(function()
                    open = not open
                    list.Visible = open
                end)

                local obj = {}
                function obj:Set(v)
                    selected = v
                    valueBtn.Text = tostring(v)
                    if callback then callback(v) end
                end
                function obj:Get()
                    return selected
                end
                return obj
            end

            return sectionObj
        end

        if #tabs == 1 then
            ActivateTab(tabs[1])
        end

        return tab
    end

    return window
end

return Library
