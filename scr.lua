local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local function New(className, props, parent)
	local obj = Instance.new(className)
	for key, value in pairs(props or {}) do
		obj[key] = value
	end
	if parent then
		obj.Parent = parent
	end
	return obj
end

local function MakeCorner(parent, radius)
	local corner = New("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
	return corner
end

local function Tween(obj, props, duration, style, direction)
	local tweenInfo = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local tween = TweenService:Create(obj, tweenInfo, props)
	tween:Play()
	return tween
end

local function Clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(value, maxValue))
end

local function MakeDraggable(target, handle)
	handle = handle or target
	local dragging = false
	local startPos
	local startMouse

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = target.Position
			startMouse = input.Position
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startMouse
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function GetIcon(name)
	local icons = {
		home = "rbxassetid://151595117",
		user = "rbxassetid://183943567",
		gear = "rbxassetid://132245831",
		settings = "rbxassetid://132245831",
		code = "rbxassetid://137998322875646",
		box = "rbxassetid://3926305904",
		camera = "rbxassetid://103880096339912",
		list = "rbxassetid://3926305904",
		star = "rbxassetid://166795897",
		run = "rbxassetid://117007794770586",
		cart = "rbxassetid://97513888174732",
		shield = "rbxassetid://1240635167",
		chart = "rbxassetid://145814630",
		hammer = "rbxassetid://102273996",
	}
	return icons[name] or icons.home
end

local function BuildSettingsPopup(parent, title)
	local panel = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 21, 30),
		BorderSizePixel = 0,
		Visible = false,
		Size = UDim2.new(1, 0, 0, 72),
		Position = UDim2.new(0, 0, 1, 6),
		ClipsDescendants = true,
		Parent = parent,
	})
	MakeCorner(panel, 10)
	local label = New("TextLabel", {
		Text = title,
		TextColor3 = Color3.fromRGB(220, 225, 235),
		TextSize = 11,
		Font = Enum.Font.SourceSansSemibold,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.new(0, 8, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})
	local settingsList = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 26),
		Size = UDim2.new(1, -16, 1, -26),
		Parent = panel,
	})
	local listLayout = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, settingsList)

	local openState = false
	local settings = {}
	local function SetOpen(value)
		openState = value
		panel.Visible = value
		if value then
			panel.Size = UDim2.new(1, 0, 0, 72)
		end
	end

	function settings:Toggle()
		SetOpen(not openState)
	end

	function settings:AddToggle(text, default, callback)
		local row = New("Frame", {
			BackgroundColor3 = Color3.fromRGB(25, 30, 40),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 22),
			Parent = settingsList,
		})
		MakeCorner(row, 8)
		local t = New("TextLabel", {
			Text = text,
			TextColor3 = Color3.fromRGB(220, 225, 235),
			TextSize = 10,
			Font = Enum.Font.SourceSansSemibold,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -36, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local knob = New("TextButton", {
			Text = "",
			BackgroundColor3 = Color3.fromRGB(36, 41, 52),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 26, 0, 14),
			Position = UDim2.new(1, -30, 0.5, -7),
			Parent = row,
		})
		MakeCorner(knob, 7)
		local dot = New("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 8, 0, 8),
			Position = UDim2.new(default and 0.58 or 0.18, 0, 0.5, -4),
			Parent = knob,
		})
		MakeCorner(dot, 5)
		local enabled = default == true
		local function Sync()
			enabled = enabled == true
			Tween(knob, { BackgroundColor3 = enabled and Color3.fromRGB(78, 141, 255) or Color3.fromRGB(36, 41, 52) }, 0.12)
			Tween(dot, { Position = UDim2.new(enabled and 0.58 or 0.18, 0, 0.5, -4) }, 0.12)
		end
		knob.MouseButton1Click:Connect(function()
			enabled = not enabled
			Sync()
			if callback then callback(enabled) end
		end)
		Sync()
		return { Set = function(v) enabled = v == true; Sync(); if callback then callback(enabled) end end, Get = function() return enabled end }
	end

	return settings
end

function Library:AddWindow(title, logo, gameTitle, options)
	options = options or {}
	title = title or "NL Menu"
	logo = logo or ""
	gameTitle = gameTitle or "UI"

	local width = Clamp(options.width or 280, options.minWidth or 220, options.maxWidth or 420)
	local height = options.height or 430
	local navWidth = options.navWidth or 78
	local compactNavWidth = options.compactNavWidth or 62
	local mainColor = options.mainColor or Color3.fromRGB(77, 122, 255)
	local backgroundColor = Color3.fromRGB(12, 15, 24)
	local panelColor = Color3.fromRGB(18, 21, 30)
	local sidebarColor = Color3.fromRGB(14, 17, 24)
	local cardColor = Color3.fromRGB(16, 20, 29)
	local isCompact = false
	local tabs = {}
	local activeTab = nil
	local tabButtons = {}

	local gui = New("ScreenGui", {
		Name = "NLMenuRB",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		Parent = game.CoreGui,
	})

	local root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, width, 0, height),
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
		Parent = gui,
	})
	MakeCorner(root, 18)

	local shadow = New("ImageLabel", {
		Image = "rbxassetid://131604521",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 42, 1, 42),
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.45,
		ZIndex = -1,
		Parent = root,
	})

	local topBar = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(13, 17, 26),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = root,
	})
	MakeCorner(topBar, 18)

	local logoLabel = New("ImageLabel", {
		Image = logo ~= "" and logo or "",
		ImageTransparency = logo ~= "" and 0 or 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 12, 0.5, -10),
		Parent = topBar,
	})
	MakeCorner(logoLabel, 6)

	local titleLabel = New("TextLabel", {
		Text = title,
		TextColor3 = Color3.fromRGB(245, 247, 250),
		TextSize = 15,
		Font = Enum.Font.SourceSansSemibold,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, logo ~= "" and 40 or 12, 0, 9),
		Size = UDim2.new(1, -90, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})

	local subtitleLabel = New("TextLabel", {
		Text = gameTitle,
		TextColor3 = Color3.fromRGB(170, 180, 195),
		TextSize = 10,
		Font = Enum.Font.SourceSans,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, logo ~= "" and 40 or 12, 0, 28),
		Size = UDim2.new(1, -90, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})

	local userBadge = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 22, 34),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 118, 0, 30),
		Parent = topBar,
	})
	MakeCorner(userBadge, 12)
	local avatar = New("ImageLabel", {
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=100&h=100",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 18, 0, 18),
		Position = UDim2.new(0, 8, 0.5, -9),
		Parent = userBadge,
	})
	MakeCorner(avatar, 9)
	local userLabel = New("TextLabel", {
		Text = LocalPlayer.DisplayName or LocalPlayer.Name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 11,
		Font = Enum.Font.SourceSansSemibold,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -34, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = userBadge,
	})

	local sidebar = New("Frame", {
		Position = UDim2.new(0, 0, 0, 52),
		Size = UDim2.new(0, navWidth, 1, -52),
		BackgroundColor3 = sidebarColor,
		BorderSizePixel = 0,
		Parent = root,
	})

	local sidebarList = New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, sidebar)

	local content = New("Frame", {
		Position = UDim2.new(0, navWidth + 8, 0, 52),
		Size = UDim2.new(1, -(navWidth + 8), 1, -52),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = root,
	})

	local sectionsHolder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = content,
	})
	local sectionsLayout = New("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sectionsHolder)

	local gearButton = New("TextButton", {
		Text = "⚙",
		TextColor3 = Color3.fromRGB(240, 243, 248),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		BackgroundColor3 = Color3.fromRGB(17, 20, 31),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = UDim2.new(0, 28, 0, 28),
		Position = UDim2.new(1, -38, 0, 12),
		Parent = topBar,
	})
	MakeCorner(gearButton, 9)

	local function setCompactMode(value)
		isCompact = value
		local widthNow = isCompact and compactNavWidth or navWidth
		Tween(sidebar, { Size = UDim2.new(0, widthNow, 1, -52) }, 0.18)
		Tween(content, { Position = UDim2.new(0, widthNow + 8, 0, 52), Size = UDim2.new(1, -(widthNow + 8), 1, -52) }, 0.18)
		for _, btn in ipairs(tabButtons) do
			btn.label.Visible = not isCompact
			btn.icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		end
		titleLabel.Visible = not isCompact
		subtitleLabel.Visible = not isCompact
		userBadge.Visible = not isCompact
		if logo == "" then
			logoLabel.Visible = false
		else
			logoLabel.Visible = not isCompact
		end
	end

	local function setTab(tab)
		activeTab = tab
		for _, btn in ipairs(tabButtons) do
			Tween(btn.bg, { BackgroundColor3 = (btn.tab == tab) and mainColor or Color3.fromRGB(21, 24, 35) }, 0.16)
			Tween(btn.icon, { ImageColor3 = (btn.tab == tab) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 188, 200) }, 0.16)
		end
		for _, child in ipairs(sectionsHolder:GetChildren()) do
			if child:IsA("Frame") then
				child.Visible = false
			end
		end
		for _, section in ipairs(tab.sections) do
			section.Visible = true
		end
	end

	gearButton.MouseButton1Click:Connect(function()
		setCompactMode(not isCompact)
	end)

	function window:SetSize(newSize)
		if type(newSize) == "number" then
			width = Clamp(newSize, options.minWidth or 220, options.maxWidth or 420)
		elseif typeof(newSize) == "Vector2" then
			width = Clamp(newSize.X, options.minWidth or 220, options.maxWidth or 420)
			height = newSize.Y
		elseif typeof(newSize) == "UDim2" then
			width = Clamp(newSize.X.Offset, options.minWidth or 220, options.maxWidth or 420)
			height = newSize.Y.Offset
		end
		Tween(root, { Size = UDim2.new(0, width, 0, height) }, 0.2)
	end

	function window:GetSize()
		return Vector2.new(width, height)
	end

	function window:SetLogo(image, visible)
		if image then
			logoLabel.Image = image
		end
		logoLabel.Visible = visible ~= false and logo ~= ""
	end

	function window:Toggle(value)
		if value == nil then
			value = not root.Visible
		end
		root.Visible = value
	end

	function window:Destroy()
		gui:Destroy()
	end

	function window:AddTab(tabName, icon)
		local tab = { Name = tabName, sections = {} }
		local btn = New("TextButton", {
			Text = "",
			BackgroundColor3 = Color3.fromRGB(21, 24, 35),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -12, 0, 42),
			AutoButtonColor = false,
			Parent = sidebar,
		})
		MakeCorner(btn, 12)

		local iconLabel = New("ImageLabel", {
			Image = GetIcon(icon or "home"),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(180, 188, 200),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Parent = btn,
		})
		local label = New("TextLabel", {
			Text = tabName,
			TextColor3 = Color3.fromRGB(240, 244, 250),
			TextSize = 11,
			Font = Enum.Font.SourceSansSemibold,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 42, 0, 0),
			Size = UDim2.new(1, -42, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Visible = not isCompact,
			Parent = btn,
		})
		btn.MouseButton1Click:Connect(function()
			setTab(tab)
		end)
		table.insert(tabButtons, { bg = btn, icon = iconLabel, label = label, tab = tab })
		table.insert(tabs, tab)

		local function AddSection(title)
			local section = New("Frame", {
				BackgroundColor3 = cardColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false,
				Parent = sectionsHolder,
			})
			MakeCorner(section, 12)
			local header = New("TextLabel", {
				Text = title,
				TextColor3 = Color3.fromRGB(180, 188, 203),
				TextSize = 11,
				Font = Enum.Font.SourceSansSemibold,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 8),
				Size = UDim2.new(1, -20, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = section,
			})
			local body = New("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 28),
				Size = UDim2.new(1, -16, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				ClipsDescendants = true,
				Parent = section,
			})
			New("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, body)
			local sectionAPI = {}

			local function AddToggle(text, default, callback)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 30),
					Parent = body,
				})
				local label = New("TextLabel", {
					Text = text,
					TextColor3 = Color3.fromRGB(240, 244, 250),
					TextSize = 12,
					Font = Enum.Font.SourceSansSemibold,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -74, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				local toggle = New("TextButton", {
					Text = "",
					BackgroundColor3 = Color3.fromRGB(35, 40, 52),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 30, 0, 16),
					Position = UDim2.new(1, -32, 0.5, -8),
					Parent = row,
				})
				MakeCorner(toggle, 8)
				local knob = New("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new(0.28, 0, 0.5, -6),
					Parent = toggle,
				})
				MakeCorner(knob, 12)
				local settings = BuildSettingsPopup(row, text)
				local gear = New("TextButton", {
					Text = "⚙",
					TextColor3 = Color3.fromRGB(200, 206, 220),
					TextSize = 10,
					Font = Enum.Font.GothamBold,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(1, -62, 0.5, -9),
					Parent = row,
				})
				gear.MouseButton1Click:Connect(function()
					settings:Toggle()
				end)
				local enabled = default == true
				local function Sync()
					Tween(toggle, { BackgroundColor3 = enabled and Color3.fromRGB(77, 122, 255) or Color3.fromRGB(35, 40, 52) }, 0.12)
					Tween(knob, { Position = UDim2.new(enabled and 0.68 or 0.28, 0, 0.5, -6) }, 0.12)
				end
				toggle.MouseButton1Click:Connect(function()
					enabled = not enabled
					Sync()
					if callback then callback(enabled) end
				end)
				Sync()
				local obj = {}
				function obj:Set(v)
					enabled = v == true
					Sync()
					if callback then callback(enabled) end
				end
				function obj:Get()
					return enabled
				end
				function obj:AddSettings()
					settings:AddToggle("Extra", true)
					return settings
				end
				return obj
			end

			local function AddCheckbox(text, default, callback)
				return AddToggle(text, default, callback)
			end

			local function AddSlider(text, minValue, maxValue, default, callback, suffix)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 46),
					Parent = body,
				})
				local label = New("TextLabel", {
					Text = text,
					TextColor3 = Color3.fromRGB(240, 244, 250),
					TextSize = 12,
					Font = Enum.Font.SourceSansSemibold,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -98, 0, 16),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				local valueText = New("TextLabel", {
					Text = tostring(default or minValue) .. (suffix or ""),
					TextColor3 = Color3.fromRGB(170, 180, 195),
					TextSize = 11,
					Font = Enum.Font.SourceSans,
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 50, 0, 16),
					Position = UDim2.new(1, -50, 0, 0),
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = row,
				})
				local track = New("Frame", {
					BackgroundColor3 = Color3.fromRGB(35, 40, 52),
					BorderSizePixel = 0,
					Size = UDim2.new(1, -8, 0, 6),
					Position = UDim2.new(0, 4, 0, 22),
					Parent = row,
				})
				MakeCorner(track, 6)
				local fill = New("Frame", {
					BackgroundColor3 = mainColor,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 0, 1, 0),
					Parent = track,
				})
				MakeCorner(fill, 6)
				local value = Clamp(default or minValue, minValue, maxValue)
				local function updateValue(v)
					value = Clamp(v, minValue, maxValue)
					local ratio = (value - minValue) / math.max(0.001, maxValue - minValue)
					fill.Size = UDim2.new(ratio, 0, 1, 0)
					valueText.Text = tostring(math.round(value)) .. (suffix or "")
					if callback then callback(value) end
				end
				local drag = New("TextButton", {
					Text = "",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = row,
				})
				drag.MouseButton1Down:Connect(function()
					local mouse = UserInputService:GetMouseLocation()
					local startX = row.AbsolutePosition.X
					local endX = row.AbsolutePosition.X + row.AbsoluteSize.X
					local range = math.max(1, endX - startX)
					local ratio = Clamp((mouse.X - startX) / range, 0, 1)
					updateValue(minValue + ratio * (maxValue - minValue))
				end)
				updateValue(value)
				local obj = {}
				function obj:Set(v) updateValue(v) end
				function obj:Get() return value end
				return obj
			end

			local function AddDropdown(text, options, default, callback)
				local row = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 34),
					Parent = body,
				})
				local label = New("TextLabel", {
					Text = text,
					TextColor3 = Color3.fromRGB(240, 244, 250),
					TextSize = 12,
					Font = Enum.Font.SourceSansSemibold,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -100, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})
				local selected = default or options[1] or ""
				local box = New("TextButton", {
					Text = tostring(selected),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 11,
					Font = Enum.Font.SourceSansSemibold,
					BackgroundColor3 = Color3.fromRGB(25, 30, 40),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -90, 0.5, -12),
					Size = UDim2.new(0, 86, 0, 24),
					Parent = row,
				})
				MakeCorner(box, 8)
				local popup = New("Frame", {
					BackgroundColor3 = Color3.fromRGB(18, 21, 30),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Visible = false,
					Position = UDim2.new(0, 0, 1, 2),
					Size = UDim2.new(1, 0, 0, 0),
					Parent = row,
				})
				MakeCorner(popup, 8)
				local popupList = New("UIListLayout", {
					Padding = UDim.new(0, 3),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, popup)
				local open = false
				local function setOpen(v)
					open = v
					popup.Visible = v
					popup.Size = UDim2.new(1, 0, 0, v and math.min(#options * 22 + 8, 110) or 0)
				end
				box.MouseButton1Click:Connect(function()
					setOpen(not open)
				end)
				for _, value in ipairs(options or {}) do
					local opt = New("TextButton", {
						Text = tostring(value),
						TextColor3 = Color3.fromRGB(220, 225, 235),
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 20),
						Parent = popup,
					})
					opt.MouseButton1Click:Connect(function()
						selected = value
						box.Text = tostring(value)
						setOpen(false)
						if callback then callback(value) end
					end)
				end
				local obj = {}
				function obj:Set(v)
					selected = v
					box.Text = tostring(v)
					if callback then callback(v) end
				end
				function obj:Get()
					return selected
				end
				return obj
			end

			sectionAPI.AddToggle = AddToggle
			sectionAPI.AddCheckbox = AddCheckbox
			sectionAPI.AddSlider = AddSlider
			sectionAPI.AddDropdown = AddDropdown
			sectionAPI.wrapper = section
			sectionAPI.body = body
			table.insert(tab.sections, section)
			return sectionAPI
		end

		tab.AddSection = AddSection
		return tab
	end

	MakeDraggable(root, topBar)
	setCompactMode(false)
	if #tabs > 0 then
		setTab(tabs[1])
	end
	return window
end

return Library
