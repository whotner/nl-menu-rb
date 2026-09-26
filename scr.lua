local LoadAcrylic = function()
	local GuiSystem = {};
	local acrylicId = 0

	local Twen = game:GetService('TweenService');
	local RunService = game:GetService('RunService');

	function GuiSystem:Hash()
		acrylicId = acrylicId + 1
		return "NeverloseAcrylic_" .. tostring(acrylicId)
	end

	local function Hiter(planePos, planeNormal, rayOrigin, rayDirection)
		local n = planeNormal
		local d = rayDirection
		local v = rayOrigin - planePos

		local num = (n.x*v.x) + (n.y*v.y) + (n.z*v.z)
		local den = (n.x*d.x) + (n.y*d.y) + (n.z*d.z)
		if math.abs(den) < 0.000001 then
			return nil
		end
		local a = -num / den
		if a ~= a or math.abs(a) > 1e6 then
			return nil
		end

		return rayOrigin + (a * rayDirection), a
	end;

	local sharedDepthOfField = nil
	local function GetSharedDepthOfField()
		if sharedDepthOfField and sharedDepthOfField.Parent then return sharedDepthOfField end
		local ok, effect = pcall(function()
			return Instance.new('DepthOfFieldEffect', game:GetService('Lighting'))
		end)
		if ok and effect then
			effect.Enabled = true
			effect.FarIntensity = 1
			effect.FocusDistance = 0
			effect.InFocusRadius = 500
			effect.NearIntensity = 1
			effect.Name = "NeverloseDepthOfField"
			sharedDepthOfField = effect
		end
		return sharedDepthOfField
	end

	function GuiSystem.new(frame,NoAutoBackground)
		local Part = Instance.new('Part',workspace);
		local DepthOfField = GetSharedDepthOfField()
		local SurfaceGui = Instance.new('SurfaceGui',Part);
		local BlockMesh = Instance.new("BlockMesh");

		BlockMesh.Parent = Part;

		Part.Material = Enum.Material.Glass;
		Part.Transparency = 1;
		Part.Reflectance = 0.1
		Part.CastShadow = false
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		pcall(function()
			local PhysicsService = game:GetService('PhysicsService')
			if PhysicsService:IsCollisionGroupRegistered('NeverloseGui') then
				Part.CollisionGroup = 'NeverloseGui'
			else
				PhysicsService:RegisterCollisionGroup('NeverloseGui')
				Part.CollisionGroup = 'NeverloseGui'
			end
		end)
		Part.Size = Vector3.new(1, 1, 1) * 0.01;
		Part.Color = Color3.fromRGB(0,0,0);

		if DepthOfField then
			DepthOfField.Enabled = true
			DepthOfField.FarIntensity = 1
			DepthOfField.FocusDistance = 0
			DepthOfField.InFocusRadius = 500
			DepthOfField.NearIntensity = 1
		end

		SurfaceGui.AlwaysOnTop = true;
		SurfaceGui.Adornee = Part;
		SurfaceGui.Active = true;
		SurfaceGui.Face = Enum.NormalId.Front;
		SurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;

		if DepthOfField and not sharedDepthOfField then DepthOfField.Name = GuiSystem:Hash() end
		Part.Name = GuiSystem:Hash();
		SurfaceGui.Name = GuiSystem:Hash();

		local C4 = {
			Update = nil,
			Collection = SurfaceGui,
			Enabled = true,
			Instances = {
				BlockMesh = BlockMesh,
				Part = Part,
				DepthOfField = DepthOfField,
				SurfaceGui = SurfaceGui,
			},
			Signal = nil
		};

		local lastQuality = nil
		local lastTransparency = nil

		local function resolveQualityTransparency()
			local qualityLevel, target = nil, nil
			pcall(function()
				local userSettings = UserSettings():GetService("UserGameSettings")
				qualityLevel = userSettings.SavedQualityLevel.Value
				target = qualityLevel < 8 and 1 or 0.8
			end)
			if type(qualityLevel) ~= "number" or type(target) ~= "number" then return nil end
			return qualityLevel, target
		end

		local initialQuality, initialTarget = resolveQualityTransparency()
		lastQuality = initialQuality
		lastTransparency = initialTarget
		Part.Transparency = initialTarget or 0.8
		Part:SetAttribute("TargetTransparency", Part.Transparency)

		local function syncQualityTransparency()
			local qualityLevel, target = resolveQualityTransparency()
			if not qualityLevel then return end
			if lastQuality == qualityLevel and lastTransparency and math.abs(lastTransparency - target) < 0.001 then return end
			lastQuality = qualityLevel
			lastTransparency = target
			pcall(function() Part:SetAttribute("TargetTransparency", target) end)
			local ok, tween = pcall(function()
				return Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Transparency = target})
			end)
			if ok and tween then pcall(function() tween:Play() end) end
		end

		local Update = function()
			local camera = workspace.CurrentCamera
			if not frame.Parent or not camera or not camera.Parent or frame.AbsoluteSize.X <= 0 or frame.AbsoluteSize.Y <= 0 then return end
			syncQualityTransparency()

			local ok, result0, result1 = pcall(function()
				local corner0 = frame.AbsolutePosition
				local corner1 = corner0 + frame.AbsoluteSize
				local ray0 = camera:ScreenPointToRay(corner0.X, corner0.Y, 1)
				local ray1 = camera:ScreenPointToRay(corner1.X, corner1.Y, 1)
				local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
				local planeNormal = camera.CFrame.LookVector
				local pos0 = Hiter(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
				local pos1 = Hiter(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)
				if not pos0 or not pos1 then return nil end
				local a = camera.CFrame:PointToObjectSpace(pos0)
				local b = camera.CFrame:PointToObjectSpace(pos1)
				if a.X ~= a.X or a.Y ~= a.Y or a.Z ~= a.Z then return nil end
				if b.X ~= b.X or b.Y ~= b.Y or b.Z ~= b.Z then return nil end
				return a, b
			end)
			if not ok or not result0 or not result1 then return end
			local size = result1 - result0
			local center = (result0 + result1) / 2
			local scaleX = math.clamp(math.abs(size.X) / 0.0101, 0.01, 4000)
			local scaleY = math.clamp(math.abs(size.Y) / 0.0101, 0.01, 4000)
			local scaleZ = math.clamp(math.abs(size.Z) / 0.0101, 0.01, 4000)
			BlockMesh.Offset = center
			BlockMesh.Scale = Vector3.new(scaleX, scaleY, scaleZ)
			Part.CFrame = camera.CFrame
		end

		C4.Update = Update;

		pcall(function()
			C4.Signal2 = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				local camera = workspace.CurrentCamera
				if camera and camera.Parent then Part.CFrame = camera.CFrame end
			end)
		end)

		C4.Destroy = function()
			if C4.Signal then C4.Signal:Disconnect() end
			if C4.Signal2 then C4.Signal2:Disconnect() end
			C4.Signal = nil
			C4.Signal2 = nil
			C4.Update = function() end

			pcall(function()
				Twen:Create(Part,TweenInfo.new(1),{
					Transparency = 1
				}):Play()
			end)

			Part:Destroy()
		end;

		return C4;
	end;

	return GuiSystem;
end;

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPlayers()[1] or {Name = "Player", DisplayName = "Player", UserId = 0}
local RunService = game:GetService('RunService')

local _windowConfigCounter = 0

local function IsPrimaryInput(input)
	return input and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
end

local function GetPointerPosition()
	local ok, position = pcall(function() return UserInputService:GetMouseLocation() end)
	if ok and position then return position end
	return Vector2.new(0, 0)
end

local function GetInputPosition(input)
	if input and input.Position then return input.Position end
	return GetPointerPosition()
end

local function InvokeCallback(callback, ...)
	if type(callback) == "function" then pcall(callback, ...) end
end

local function IsAncestorVisible(object)
	local current = object and object.Parent
	while current do
		local ok, visible = pcall(function() return current.Visible end)
		if ok and visible == false then return false end
		current = current.Parent
	end
	return true
end

local function IsPointInside(object, point)
	if not object or not point then return false end
	local ok, isGui = pcall(function() return object:IsA("GuiObject") end)
	if not ok or not isGui or not object.Visible then return false end
	if not IsAncestorVisible(object) then return false end
	local size = object.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return false end
	local position = object.AbsolutePosition
	return point.X >= position.X and point.X <= position.X + size.X
		and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function IsPointInsideTree(object, point)
	if IsPointInside(object, point) then return true end
	if not object or not object.Parent then return false end
	local ok, descendants = pcall(function() return object:GetDescendants() end)
	if not ok then return false end
	for _, descendant in ipairs(descendants) do
		if IsPointInside(descendant, point) then return true end
	end
	return false
end

local function ClampRatio(value, maximum)
	if maximum == nil or maximum <= 0 then return 0 end
	return math.clamp(value / maximum, 0, 1)
end

local function NormalizeOptions(options)
	local result = {}
	if type(options) == "table" then
		for _, value in ipairs(options) do
			if value ~= nil then table.insert(result, tostring(value)) end
		end
	end
	if #result == 0 then table.insert(result, "Auto") end
	return result
end

local function NormalizeColor(value)
	if typeof(value) == "Color3" then
		return Color3.new(math.clamp(value.R, 0, 1), math.clamp(value.G, 0, 1), math.clamp(value.B, 0, 1))
	end
	return Color3.fromRGB(255, 255, 255)
end

local function ColorToHex(value)
	local c = NormalizeColor(value)
	return string.format("#%02X%02X%02X", math.clamp(math.round(c.R * 255), 0, 255), math.clamp(math.round(c.G * 255), 0, 255), math.clamp(math.round(c.B * 255), 0, 255))
end

local function NormalizeRange(min, max, default)
	min = type(min) == "number" and min or 0
	max = type(max) == "number" and max or 100
	if min ~= min then min = 0 end
	if max ~= max then max = 100 end
	if max <= min then max = min + 1 end
	local value = type(default) == "number" and default or min
	if value ~= value then value = min end
	return min, max, math.clamp(value, min, max)
end

local function GetValidOption(options, value)
	for _, option in ipairs(options) do
		if option == value then return value end
	end
	return options[1]
end

local function AddTextConstraint(object, minimum, maximum, force)
	if not object or not object:IsA("GuiObject") then return end
	if not (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) then return end
	if not object.TextScaled then return end
	local constraint = object:FindFirstChild("ReadableTextConstraint")
	if constraint and not force then return end
	if not constraint then
		constraint = Instance.new("UITextSizeConstraint")
		constraint.Name = "ReadableTextConstraint"
		constraint.Parent = object
	end
	constraint.MinTextSize = minimum or 9
	constraint.MaxTextSize = maximum or 16
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		object.TextWrapped = false
		object.TextTruncate = Enum.TextTruncate.AtEnd
	end
end

local function MakeReadableText(root, minimum, maximum)
	if not root then return end
	AddTextConstraint(root, minimum, maximum)
	for _, object in ipairs(root:GetDescendants()) do
		AddTextConstraint(object, minimum, maximum)
	end
end

local function SerializeValue(v)
	local t = type(v)
	if t == "boolean" or t == "number" or t == "string" then
		return v
	elseif typeof(v) == "Color3" then
		return { __type = "Color3", r = v.R, g = v.G, b = v.B }
	end
	return nil
end

local function DeserializeValue(v)
	if type(v) == "table" and v.__type == "Color3" then
		local ok, color = pcall(Color3.new, tonumber(v.r) or 1, tonumber(v.g) or 1, tonumber(v.b) or 1)
		if ok then return color end
	end
	return v
end

local function GetImageData(name, image)
	if not image then return end
	name = type(name) == "string" and name:lower() or "ads"
	local NigImage = "rbxassetid://3926305904"
	if name == "ads" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(205,565); image.ImageRectSize = Vector2.new(35,35)
	elseif name == "list" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(485,205); image.ImageRectSize = Vector2.new(35,35)
	elseif name == "folder" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(805,45); image.ImageRectSize = Vector2.new(35,35)
	elseif name == "earth" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(604,324); image.ImageRectSize = Vector2.new(35,35)
	elseif name == "locked" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(524,644); image.ImageRectSize = Vector2.new(35,35)
	elseif name == "home" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(964,205); image.ImageRectSize = Vector2.new(35,35)
	elseif name == "mouse" then image.Image = "rbxassetid://94866180901611"
	elseif name == "user" then image.Image = "rbxassetid://10494577250"
	elseif name == "cosmetics" then image.Image = "rbxassetid://111448140849101"
	elseif name == "sun" then image.Image = "rbxassetid://119948798441279"
	elseif name == "shop" then image.Image = "rbxassetid://97513888174732"
	elseif name == "farm" then image.Image = "rbxassetid://88262334591015"
	elseif name == "code" then image.Image = "rbxassetid://137998322875646"
	elseif name == "crosshair" then image.Image = "rbxassetid://107944169329467"
   elseif name == "image" then image.Image = "rbxassetid://111273759419615"
elseif name == "layers" then image.Image = "rbxassetid://99581501168713"
	elseif name == "side" then image.Image = "rbxassetid://109111534633587"
	elseif name == "grenade" then image.Image = "rbxassetid://106253651509472"
	elseif name == "bio" then image.Image = "rbxassetid://78652086695674"
	elseif name == "camera" then image.Image = "rbxassetid://103880096339912"
	elseif name == "car" then image.Image = "rbxassetid://116283987324457"
	elseif name == "run" then image.Image = "rbxassetid://117007794770586"
	elseif name == "box" then image.Image = "rbxassetid://140255234172865"
	elseif name == "carcolor" then image.Image = "rbxassetid://135983067514338"
	elseif name == "avacolor" then image.Image = "rbxassetid://88738565686900"
	elseif name == "locker" then image.Image = "rbxassetid://87534652127926"
	elseif name == "retry" then image.Image = "rbxassetid://85334730366974"
	elseif name == "gun" then image.Image = "rbxassetid://93001822915827"
	elseif name == "sword" then image.Image = "rbxassetid://82635240213192"
	elseif name == "knife" then image.Image = "rbxassetid://94102397172403"
	elseif name == "egg" then image.Image = "rbxassetid://110250017854460"
	elseif name == "sprinkler" then image.Image = "rbxassetid://139620040051222"
	elseif name == "gear" then image.Image = "rbxassetid://134488580093972"
	end
end

local Library = {}
Library.__index = Library

local function Tween(obj, props, t, style, dir)
	if not obj or not obj.Parent then return end
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out
	local ok, tween = pcall(function() return TweenService:Create(obj, TweenInfo.new(t or 0.2, style, dir), props) end)
	if ok and tween then tween:Play() end
end

local CenterElement

local function New(class, props, parent)
	local obj = Instance.new(class)
	if obj:IsA("GuiObject") and obj.BorderSizePixel == 1 then obj.BorderSizePixel = 0 end
	for k, v in pairs(props or {}) do
		pcall(function() obj[k] = v end)
	end
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		obj.TextYAlignment = Enum.TextYAlignment.Center
	end
	if parent then obj.Parent = parent end
	AddTextConstraint(obj, 9, 16)
	return obj
end

local function CleanBorders(root)
	if not root then return end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") and d.BorderSizePixel ~= 0 then
			d.BorderSizePixel = 0
		end
	end
end

CenterElement = function(el)
	if not el or not el:IsA("GuiObject") then return end
	local function place(child, center, h)
		if not child or not child:IsA("GuiObject") then return end
		local top = center - h * (0.5 - child.AnchorPoint.Y)
		child.Position = UDim2.new(child.Position.X.Scale, child.Position.X.Offset, top, 0)
		child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, h, 0)
	end
	local function placeText(child, center, h)
		if not child or not (child:IsA("TextLabel") or child:IsA("TextButton")) then return end
		child.TextYAlignment = Enum.TextYAlignment.Center
		child.TextXAlignment = Enum.TextXAlignment.Left
		place(child, center, h)
	end
	for _, name in ipairs({ "TextToggle", "TextDefault", "TextAccordion", "TextDropdown", "TextAccordionLabel" }) do
		placeText(el:FindFirstChild(name), 0.5, 0.5)
	end
	local toggleLabel = el:FindFirstChild("TextToggle")
	if toggleLabel and toggleLabel:IsA("GuiObject") then
		toggleLabel.Size = UDim2.new(0.58, toggleLabel.Size.X.Offset, toggleLabel.Size.Y.Scale, toggleLabel.Size.Y.Offset)
	end
	local effect = el:FindFirstChild("Effect")
	if effect and effect:IsA("GuiObject") then
		if effect:FindFirstChild("Icon") then
			effect.Position = UDim2.new(0.8, 0, effect.Position.Y.Scale, 0)
			effect.Size = UDim2.new(0.15, 0, effect.Size.Y.Scale, effect.Size.Y.Offset)
			place(effect, 0.5, 0.6)
		else
			place(effect, 0.5, 0.7)
		end
	end
	place(el:FindFirstChild("Line"), 0.5, 0.24)
	place(el:FindFirstChild("SliderValue"), 0.5, 0.8)
	place(el:FindFirstChild("DropdownArrow") or el:FindFirstChild("TextboxArrow"), 0.5, 0.5)
end

local ELLIPSIS = "..."
local TextService = game:GetService("TextService")
local MEASURE_SIZE = Vector2.new(10000, 10000)

local function MeasureText(text, fontSize, font)
	local ok, size = pcall(TextService.GetTextSize, TextService, text, fontSize or 14, font or Enum.Font.Gotham, MEASURE_SIZE)
	if ok and size then return size.X end
	return 0
end

local function EllipsizeTo(label, maxWidth)
	if not label or not label:IsA("TextLabel") and not label:IsA("TextButton") then return end
	if type(maxWidth) ~= "number" or maxWidth <= 0 then return end
	local full = label:GetAttribute("FullText")
	if type(full) ~= "string" or full == "" then
		full = label.Text
		label:SetAttribute("FullText", full)
	end
	if full == "" then return end
	local fontSize = label.TextSize or 14
	local font = label.Font or Enum.Font.Gotham
	local unscaled = MeasureText(full, fontSize, font)
	if unscaled <= 0 then return end
	local scale = 1
	if label.TextScaled and label.TextBounds.X > 0 then
		scale = label.TextBounds.X / unscaled
		if scale <= 0 or scale ~= scale then scale = 1 end
	end
	local function rendered(text)
		return MeasureText(text, fontSize, font) * scale
	end
	if rendered(full) <= maxWidth then
		if label.Text ~= full then label.Text = full end
		return
	end
	local low, high, best = 1, #full, ""
	while low <= high do
		local mid = math.floor((low + high) / 2)
		local candidate = full:sub(1, mid) .. ELLIPSIS
		if rendered(candidate) <= maxWidth then
			best = candidate
			low = mid + 1
		else
			high = mid - 1
		end
	end
	label.Text = best ~= "" and best or ELLIPSIS
end

local function FitTextBeforeArrow(label, arrow)
	if not label or not arrow then return end
	-- Do NOT re-measure and rewrite the text: with TextScaled on, replacing the
	-- string makes Roblox re-fit it and the glyph size drifts. Narrow the label so
	-- it cannot reach the arrow, then let TextTruncate handle the overflow.
	if label:IsA("TextLabel") or label:IsA("TextButton") then
		label.TextWrapped = false
		label.TextTruncate = Enum.TextTruncate.AtEnd
	end
	task.defer(function()
		if not label.Parent or not arrow.Parent then return end
		local parent = label.Parent
		if not parent or not parent:IsA("GuiObject") then return end
		local parentX = parent.AbsolutePosition.X
		local parentW = parent.AbsoluteSize.X
		if parentW <= 0 then return end
		local room = (arrow.AbsolutePosition.X - label.AbsolutePosition.X) - 6
		if room <= 4 then return end
		local scaleX = (label.AbsolutePosition.X - parentX) / parentW
		local scaleW = (label.AbsolutePosition.X - parentX + room) / parentW
		if scaleX < 0 then scaleX = 0 end
		if scaleW > 1 then scaleW = 1 end
		label.Size = UDim2.new(scaleW, 0, label.Size.Y.Scale, label.Size.Y.Offset)
	end)
end

local function SetTrimmedText(label, value)
	if not label then return end
	label:SetAttribute("FullText", tostring(value or ""))
	label.Text = tostring(value or "")
end

	local function RefreshColorPickerPopup(popup)
		if not popup or not popup:IsA("GuiObject") then return end
		local parent = popup.Parent
		if not parent then return end
		local w = parent.AbsoluteSize.X
		if w <= 0 then return end
		local h = (w * popup.Size.X.Scale) / 1.1
		if h > 0 then popup.Size = UDim2.new(popup.Size.X.Scale, popup.Size.X.Offset, 0, h) end
	end

	local function FitColorPickerPopup(popup)
		if not popup or not popup:IsA("GuiObject") then return end
		local parent = popup.Parent
		if not parent then
			task.defer(function() FitColorPickerPopup(popup) end)
			return
		end
		RefreshColorPickerPopup(popup)
		task.defer(function() RefreshColorPickerPopup(popup) end)
		if popup:GetAttribute("_nlPickerFitted") then return end
		popup:SetAttribute("_nlPickerFitted", true)
		pcall(function()
			parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				RefreshColorPickerPopup(popup)
			end)
		end)
	end


local function ApplyZIndexLadder(root, base)
	if not root or not root:IsA("GuiObject") then return end
	local queue = { { instance = root, depth = 0 } }
	local index = 0
	while index < #queue do
		local entry = queue[index + 1]
		index = index + 1
		local instance = entry.instance
		local depth = entry.depth
		if instance:IsA("GuiObject") then
			instance.ZIndex = base + depth
		end
		for _, child in ipairs(instance:GetChildren()) do
			table.insert(queue, { instance = child, depth = depth + 1 })
		end
	end
end

local function GetDragShield(frame)
	if not frame then return nil end
	local shield = frame:FindFirstChild("DragShield")
	if not shield then
		shield = New("TextButton", {
			Name = "DragShield",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Active = true,
			Visible = false,
			ZIndex = 4990,
		}, frame)
	end
	return shield
end

local function MeasureRowsHeight(container)
	local count = 0
	local total = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			local okSize, sizeValue = pcall(function() return child.AbsoluteSize end)
			if okSize and sizeValue and sizeValue.Y > 0 then total = total + sizeValue.Y end
			count = count + 1
		end
	end
	if count == 0 then return 0, 0 end
	local padding = 0
	local okLayout, layout = pcall(function() return container:FindFirstChildOfClass("UIListLayout") end)
	if okLayout and layout then padding = layout.Padding.Offset or 0 end
	return total + padding * (count - 1), count
end

local function EstimateRowsHeight(container, count, aspect)
	if count <= 0 then return 0 end
	local okSize, sizeValue = pcall(function() return container.AbsoluteSize end)
	if not okSize or not sizeValue or sizeValue.X <= 0 then return 0 end
	local padding = 0
	local okLayout, layout = pcall(function() return container:FindFirstChildOfClass("UIListLayout") end)
	if okLayout and layout then padding = layout.Padding.Offset or 0 end
	return count * (sizeValue.X / (aspect or 7.5)) + padding * (count - 1)
end

local function RefreshRowDividers(listFrame)
	if not listFrame or not listFrame.Parent then return end
	local rows = {}
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			local divider = child:FindFirstChild("Lines")
			if divider and divider:IsA("GuiObject") then
				divider.Visible = true
				divider.BackgroundTransparency = 0.9
				table.insert(rows, divider)
			end
		end
	end
	if #rows > 0 then
		rows[#rows].Visible = false
	end
end

local _watchedDividers = {}

local function WatchRowDividers(listFrame)
	if not listFrame or _watchedDividers[listFrame] then return end
	_watchedDividers[listFrame] = true
	RefreshRowDividers(listFrame)
	listFrame.ChildAdded:Connect(function() task.defer(RefreshRowDividers, listFrame) end)
	listFrame.ChildRemoved:Connect(function() task.defer(RefreshRowDividers, listFrame) end)
	table.insert(_watchedDividers, listFrame)
end

task.spawn(function()
	while true do
		task.wait(0.4)
		for i = #_watchedDividers, 1, -1 do
			local frame = _watchedDividers[i]
			if frame and frame.Parent then
				RefreshRowDividers(frame)
			else
				table.remove(_watchedDividers, i)
			end
		end
	end
end)

local function GetSliderStep(min, max)
	local span = max - min
	if span <= 0 then return 1 end
	if span >= 20 then return 1 end
	return 0.1
end

local function Quantize(value, min, max, step)
	local clamped = math.clamp(value, min, max)
	local snapped = min + math.round((clamped - min) / step) * step
	if math.abs(snapped - max) < step * 0.001 then snapped = max end
	if math.abs(snapped - math.round(snapped)) < 0.0001 then snapped = math.round(snapped) end
	return snapped
end

local function FormatSliderValue(value, suffix)
	local text
	if math.abs(value - math.round(value)) < 0.0001 then
		text = tostring(math.round(value))
	else
		text = string.format("%.1f", value)
	end
	return text .. (suffix or "")
end

local function MakeDraggable(frame, handle)
	handle = handle or frame
	frame.Draggable = false
	local dragging = false
	local dragInput, pointerPos, framePos

	local function update(input)
		if not input or not input.Position then return end
		local delta = input.Position - pointerPos
		local position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize.X > frame.AbsoluteSize.X and camera.ViewportSize.Y > frame.AbsoluteSize.Y then
			local anchor = frame.AnchorPoint
			local x = position.X.Scale * camera.ViewportSize.X + position.X.Offset
			local y = position.Y.Scale * camera.ViewportSize.Y + position.Y.Offset
			x = math.clamp(x, frame.AbsoluteSize.X * anchor.X, camera.ViewportSize.X - frame.AbsoluteSize.X * (1 - anchor.X))
			y = math.clamp(y, frame.AbsoluteSize.Y * anchor.Y, camera.ViewportSize.Y - frame.AbsoluteSize.Y * (1 - anchor.Y))
			position = UDim2.fromOffset(x, y)
		end
		frame.Position = position
	end

	handle.InputBegan:Connect(function(input)
		if IsPrimaryInput(input) then
			dragging = true
			dragInput = input
			pointerPos = input.Position
			framePos = frame.Position
			local shield = GetDragShield(frame)
			if shield then shield.Visible = true end
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then update(input) end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if IsPrimaryInput(input) then
			dragging = false
			dragInput = nil
			local shield = frame:FindFirstChild("DragShield")
			if shield then shield.Visible = false end
		end
	end)
end


	local _openPopups = {}
	local _popupClipRestore = {}
	local _popupClipCounts = {}
	local UnregisterPopup
	local RestorePopupClipping

	local function IsPopupAncestor(ancestor, descendant)
		if not ancestor or not descendant or ancestor == descendant then return false end
		local ok, result = pcall(function() return descendant:IsDescendantOf(ancestor) end)
		return ok and result
	end

	local function RegisterPopup(frame, closeFn, trigger)
		if not frame or type(closeFn) ~= "function" then return end
		for i = #_openPopups, 1, -1 do
			local entry = _openPopups[i]
			if not entry.frame or not entry.frame.Parent then
				if entry.connection then pcall(function() entry.connection:Disconnect() end) end
				RestorePopupClipping(entry.frame)
				table.remove(_openPopups, i)
			elseif entry.frame == frame then
				entry.closeFn = closeFn
				entry.trigger = trigger
				return
			end
		end
		local connection
		if frame.Destroying and frame.Destroying.Connect then
			local ok, result = pcall(function()
				return frame.Destroying:Connect(function()
					UnregisterPopup(frame)
					if connection then pcall(function() connection:Disconnect() end) end
				end)
			end)
			if ok then connection = result end
		end
		table.insert(_openPopups, {frame = frame, closeFn = closeFn, trigger = trigger, connection = connection})
	end

	UnregisterPopup = function(frame)
		RestorePopupClipping(frame)
		for i = #_openPopups, 1, -1 do
			if _openPopups[i].frame == frame then
				if _openPopups[i].connection then pcall(function() _openPopups[i].connection:Disconnect() end) end
				table.remove(_openPopups, i)
			end
		end
	end

	local function CloseAllPopupsExcept(exceptFrame)
		local copy = {}
		for i, entry in ipairs(_openPopups) do copy[i] = entry end
		for _, entry in ipairs(copy) do
			if entry.frame and entry.frame.Parent and entry.frame ~= exceptFrame
				and not IsPopupAncestor(entry.frame, exceptFrame) and type(entry.closeFn) == "function" then
				pcall(entry.closeFn)
			end
		end
	end

	local function HideAllPopupsNow(instant)
		local copy = {}
		for i, entry in ipairs(_openPopups) do copy[i] = entry end
		for _, entry in ipairs(copy) do
			local frame = entry.frame
			if frame and frame.Parent then
				if entry.connection then pcall(function() entry.connection:Disconnect() end) end
				RestorePopupClipping(frame)
				if instant then
					frame.Visible = false
				else
					Tween(frame, { BackgroundTransparency = 1 }, 0.18)
				end
			end
		end
		table.clear(_openPopups)
	end

	local function ClosePopupsUnder(root)
		if not root then return end
		local copy = {}
		for i, entry in ipairs(_openPopups) do copy[i] = entry end
		for _, entry in ipairs(copy) do
			if entry.frame and entry.frame ~= root and IsPopupAncestor(root, entry.frame) and type(entry.closeFn) == "function" then
				pcall(entry.closeFn)
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input)
		if not IsPrimaryInput(input) then return end
		local point = GetInputPosition(input)
		local toClose = {}
		for _, entry in ipairs(_openPopups) do
			local frame = entry.frame
			if frame and frame.Parent and frame.Visible then
				local inside = IsPointInsideTree(frame, point)
				if entry.trigger and entry.trigger.Parent then
					inside = inside or IsPointInsideTree(entry.trigger, point)
				end
				if not inside and type(entry.closeFn) == "function" then table.insert(toClose, entry.closeFn) end
			end
		end
		for _, fn in ipairs(toClose) do pcall(fn) end
	end)

local function CancelPopupTween(frame)
	if not frame or not frame.Parent then return end
	local running = frame:GetAttribute("PopupTween")
	if running then
		pcall(function() running:Cancel() end)
	end
	frame:SetAttribute("PopupTween", nil)
end

local function PlayPopupTween(frame, info, props)
	local ok, tween = pcall(function() return TweenService:Create(frame, info, props) end)
	if not ok or not tween then return end
	frame:SetAttribute("PopupTween", tween)
	pcall(function() tween:Play() end)
	pcall(function()
		tween.Completed:Connect(function()
			if frame:GetAttribute("PopupTween") == tween then
				frame:SetAttribute("PopupTween", nil)
			end
		end)
	end)
end

local function SmoothOpen(frame, targetAlpha, dur, style, dir)
	if not frame or not frame.Parent then return end
	local token = (frame:GetAttribute("PopupToken") or 0) + 1
	frame:SetAttribute("PopupToken", token)
	CancelPopupTween(frame)
	frame.BackgroundTransparency = 1
	frame.Visible = true
	PlayPopupTween(frame, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), {BackgroundTransparency = targetAlpha})
end

local function SmoothClose(frame, dur, cb)
	if not frame or not frame.Parent then return end
	local token = (frame:GetAttribute("PopupToken") or 0) + 1
	frame:SetAttribute("PopupToken", token)
	CancelPopupTween(frame)
	PlayPopupTween(frame, TweenInfo.new(math.min(dur or 0.18, 0.09), Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
	task.delay((dur or 0.18) + 0.01, function()
		if frame.Parent and frame:GetAttribute("PopupToken") == token then
			frame.Visible = false
			if cb then cb() end
		end
	end)
end

function Library:AddWindow(hubTitle, hubImage, gameTitle)
	hubTitle = tostring(hubTitle or "Neverlose")
	hubImage = tostring(hubImage or "")
	gameTitle = tostring(gameTitle or "Counter Strike 2")
	local username = LocalPlayer.DisplayName or LocalPlayer.Name or "Player"
	local daysLeft = "Lifetime"
	local userId = LocalPlayer.UserId or 0
	local userImage = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"

	_windowConfigCounter = _windowConfigCounter + 1
	local windowConfigId = tostring(_windowConfigCounter)
	local _registeredElements = {}
	local configKeyCounts = {}
	local function RegisterConfigElement(prefix, label, object)
		local base = tostring(prefix) .. tostring(label or "item")
		local count = (configKeyCounts[base] or 0) + 1
		configKeyCounts[base] = count
		table.insert(_registeredElements, {key = base .. "#" .. count, obj = object})
	end

	local mainColor = Color3.fromRGB(26, 123, 255)
	local tabs = {}
	local activeTabIndex = nil
	local tabOrder = 0
	local WindowObj = {}
	local _coloredElements = {}
	local logoVisible = true
	local customization = {}

	local screenGuiParent
	pcall(function() screenGuiParent = game.CoreGui end)
	if not screenGuiParent then
		local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
		if ok then screenGuiParent = coreGui end
	end
	if not screenGuiParent and LocalPlayer and LocalPlayer.FindFirstChildOfClass then
		local ok, playerGui = pcall(function() return LocalPlayer:FindFirstChildOfClass("PlayerGui") end)
		if ok then screenGuiParent = playerGui end
	end
	if not screenGuiParent then
		pcall(function() screenGuiParent = game:GetService("CoreGui") end)
	end

	local NeverloseCS2 = New("ScreenGui", {
		Name = "NeverloseCS2",
		ResetOnSpawn = false,
		ClipToDeviceSafeArea = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
	}, screenGuiParent)






	local MainFrame = New("Frame", {
		Name = "MainFrame",
		Active = true,
		Draggable = false,
		AnchorPoint = Vector2.new(0.5, 0.43),
		Size = UDim2.new(0.78, 0, 0.78, 0),
		Position = UDim2.new(0.5, 0, 0.43, 0),
	BackgroundColor3 = Color3.fromRGB(13,15,22),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	}, NeverloseCS2)
	local MainFrameUIScale
	local _windowContextTargets = {}
	GetDragShield(MainFrame)
    local Watermark = New("TextLabel", {
	Name = "Watermark",
	Visible = false,
    Position = UDim2.new(0.982, 0, 0.984, 0),
    Size = UDim2.new(0.150, 0, 0.026, 0),
    AnchorPoint = Vector2.new(1, 1),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.94,
		Text = "NEVERLOSE  •  UI",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.35,
		TextScaled = false,
		TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 6000,
    }, MainFrame)
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = Watermark end
	local watermarkConstraint = Watermark:FindFirstChild("ReadableTextConstraint")
	if watermarkConstraint then
		watermarkConstraint.MinTextSize = 9
		watermarkConstraint.MaxTextSize = 11
	end
	customization.watermark = Watermark
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 20); c.Parent = MainFrame end
	local DragHandle = New("Frame", {
		Name = "DragHandle",
		Size = UDim2.new(0.3, 0, 0.08, 0),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 100,
	}, MainFrame)
	New("UISizeConstraint", {
		MinSize = Vector2.new(220, 180),
		MaxSize = Vector2.new(820, 560),
	}, MainFrame)

	local AcrylicLib = LoadAcrylic()
	local AcrylicBlur = AcrylicLib.new(MainFrame)

	local function GetMainFrameScale()
		local scale = MainFrameUIScale and MainFrameUIScale.Scale or 1
		if type(scale) ~= "number" or scale ~= scale or scale <= 0 then return 1 end
		return scale
	end

	local function GetVisualScale(object)
		local scale = 1
		local current = object
		while current do
			local ok, uiScale = pcall(function()
				return current:FindFirstChildOfClass("UIScale")
			end)
			if (not ok or not uiScale) and current == MainFrame then uiScale = MainFrameUIScale end
			if (ok or current == MainFrame) and uiScale and type(uiScale.Scale) == "number" and uiScale.Scale > 0 then
				scale = scale * uiScale.Scale
			end
			if current == MainFrame then break end
			current = current.Parent
		end
		if type(scale) ~= "number" or scale ~= scale or scale <= 0 then return 1, 1 end
		scale = math.clamp(scale, 0.01, 100)
		return scale, scale
	end

	local function GetPopupParentOrigin(popup)
		local parent = popup and popup.Parent
		if parent and parent:IsA("GuiObject") then
			return parent.AbsolutePosition.X, parent.AbsolutePosition.Y,
				parent.AbsoluteSize.X, parent.AbsoluteSize.Y
		end
		return 0, 0, 0, 0
	end

	local function AbsoluteFromPosition(popup)
		local baseX, baseY, sizeX, sizeY = GetPopupParentOrigin(popup)
		local scaleX, scaleY = GetVisualScale(popup)
		local position = popup.Position
		return baseX + (position.X.Scale * sizeX + position.X.Offset) * scaleX,
			baseY + (position.Y.Scale * sizeY + position.Y.Offset) * scaleY
	end

	local function MovePopupToAbsolute(popup, x, y)
		if not popup or not popup.Parent then return end
		local baseX, baseY, sizeX, sizeY = GetPopupParentOrigin(popup)
		local scaleX, scaleY = GetVisualScale(popup)
		local position = popup.Position
		local targetX = (x - baseX) / scaleX - position.X.Scale * sizeX
		local targetY = (y - baseY) / scaleY - position.Y.Scale * sizeY
		if math.abs(position.X.Offset - targetX) < 0.5 and math.abs(position.Y.Offset - targetY) < 0.5 then return end
		popup.Position = UDim2.new(position.X.Scale, targetX, position.Y.Scale, targetY)
	end

	local function ConstrainPopupToMainFrame(popup, margin)
		margin = type(margin) == "number" and math.max(0, margin) or 6
		if not popup or not popup.Parent or not popup:IsA("GuiObject") then return end
		if MainFrame.AbsoluteSize.X <= 0 or MainFrame.AbsoluteSize.Y <= 0 then return end
		local size = popup.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		local mainPosition = MainFrame.AbsolutePosition
		local mainSize = MainFrame.AbsoluteSize
		local minX = mainPosition.X + margin
		local minY = mainPosition.Y + margin
		local maxX = mainPosition.X + mainSize.X - size.X - margin
		local maxY = mainPosition.Y + mainSize.Y - size.Y - margin
		local currentX, currentY = AbsoluteFromPosition(popup)
		local x = maxX < minX and minX or math.clamp(currentX, minX, maxX)
		local y = maxY < minY and minY or math.clamp(currentY, minY, maxY)
		MovePopupToAbsolute(popup, x, y)
	end
		local function FindClippingAncestors(popup)
			local ancestors = {}
			local current = popup and popup.Parent
			while current and current ~= MainFrame do
				local ok, clips = pcall(function() return current.ClipsDescendants end)
				if ok and clips == true then table.insert(ancestors, current) end
				current = current.Parent
			end
			return ancestors
		end

		local function RememberPopupClipping(popup)
			if not popup or not popup.Parent or _popupClipRestore[popup] then return end
			local ancestors = FindClippingAncestors(popup)
			if #ancestors == 0 then return end
			local restored = {}
			for _, ancestor in ipairs(ancestors) do
				local okClip, wasClipping = pcall(function() return ancestor.ClipsDescendants end)
				table.insert(restored, { frame = ancestor, clipping = okClip and wasClipping == true })
				_popupClipCounts[ancestor] = (_popupClipCounts[ancestor] or 0) + 1
				ancestor.ClipsDescendants = false
			end
			_popupClipRestore[popup] = restored
		end

		RestorePopupClipping = function(popup)
			local ancestors = popup and _popupClipRestore[popup]
			if not ancestors then return end
			_popupClipRestore[popup] = nil
			for _, entry in ipairs(ancestors) do
				local ancestor = entry.frame
				local count = (_popupClipCounts[ancestor] or 1) - 1
				if count > 0 then
					_popupClipCounts[ancestor] = count
				else
					_popupClipCounts[ancestor] = nil
					if ancestor.Parent then ancestor.ClipsDescendants = entry.clipping == true end
				end
			end
		end


	local function positionPopupNow(popup, preferBelow, margin, anchorOverride, knownSize)
		if not popup or not popup.Parent then return end
		local parent = popup.Parent
		local anchor = anchorOverride or (parent and (parent:FindFirstChild("TopBar") or parent:FindFirstChild("OpenBtn") or parent:FindFirstChild("ScaleOpenBtn") or parent:FindFirstChild("LangOpenBtn")))
		local parentPosition = (anchor or parent).AbsolutePosition
		local parentSize = (anchor or parent).AbsoluteSize
		local mainPosition = MainFrame.AbsolutePosition
		local mainSize = MainFrame.AbsoluteSize
		if mainSize.X <= 0 or mainSize.Y <= 0 or parentSize.X <= 0 or parentSize.Y <= 0 then return end
		local popupSize = knownSize or popup.AbsoluteSize
		if popupSize.X <= 0 or popupSize.Y <= 0 then return end
		local edge = type(margin) == "number" and math.max(0, margin) or 6
		local minX = mainPosition.X + edge
		local minY = mainPosition.Y + edge
		local maxX = mainPosition.X + mainSize.X - popupSize.X - edge
		local maxY = mainPosition.Y + mainSize.Y - popupSize.Y - edge
		local y = preferBelow and parentPosition.Y + parentSize.Y + edge or parentPosition.Y - popupSize.Y - edge
		if preferBelow and y > maxY then
			local flipped = parentPosition.Y - popupSize.Y - edge
			if flipped >= minY then y = flipped end
		elseif not preferBelow and y < minY then
			local flipped = parentPosition.Y + parentSize.Y + edge
			if flipped <= maxY then y = flipped end
		end
		local currentX = select(1, AbsoluteFromPosition(popup))
		local x = maxX < minX and minX or math.clamp(anchor and anchor.AbsolutePosition.X or currentX, minX, maxX)
		if maxY < minY then y = minY end
		MovePopupToAbsolute(popup, x, math.clamp(y, minY, math.max(minY, maxY)))
	end

	local function PositionPopupWithinMain(popup, preferBelow, margin, anchorOverride, knownSize)
		if not popup or not popup.Parent then return end
		RememberPopupClipping(popup)
		if knownSize then
			positionPopupNow(popup, preferBelow, margin, anchorOverride, knownSize)
			if popup.Visible then ConstrainPopupToMainFrame(popup, margin) end
			return
		end
		if popup.Visible then ConstrainPopupToMainFrame(popup, margin) end
		task.defer(function()
			if not popup.Parent or not popup.Visible then return end
			positionPopupNow(popup, preferBelow, margin, anchorOverride, nil)
			local edge = type(margin) == "number" and math.max(0, margin) or 6
			ConstrainPopupToMainFrame(popup, edge)
		end)
	end

	local function AnimateColorPickerOpen(popup, trigger, open, onClose)
		if not popup or not popup.Parent then return end
		if open then
			CloseAllPopupsExcept(popup)
			popup.Visible = true
			FitColorPickerPopup(popup)
			RefreshColorPickerPopup(popup)
			popup.BackgroundTransparency = 1
			popup.ZIndex = 8000
			ApplyZIndexLadder(popup, 8000)
			Tween(popup, { BackgroundTransparency = 0.02 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			PositionPopupWithinMain(popup, true)
			task.defer(function() if popup.Visible then PositionPopupWithinMain(popup, true) end end)
			RegisterPopup(popup, function()
				UnregisterPopup(popup)
				popup.Visible = false
				if type(onClose) == "function" then onClose(false) end
			end, trigger)
		else
			UnregisterPopup(popup)
			Tween(popup, { BackgroundTransparency = 1 }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.15, function() if not popup.Visible then popup.BackgroundTransparency = 1 end end)
			popup.Visible = false
		end
	end


local Stats = game:GetService('Stats')

local GameInfo = Instance.new('Frame')
GameInfo.Name = "GameInfo"
GameInfo.AnchorPoint = Vector2.new(1, 0)
GameInfo.Position = UDim2.new(0.98, 0, 0.02, 0)
GameInfo.Size = UDim2.fromOffset(660, 48)
GameInfo.BackgroundColor3 = Color3.fromRGB(17,20,30)
GameInfo.BackgroundTransparency = 0
GameInfo.BorderSizePixel = 0
GameInfo.Active = true
GameInfo.Draggable = false
GameInfo.ClipsDescendants = true
GameInfo.AutomaticSize = Enum.AutomaticSize.None
GameInfo.Parent = NeverloseCS2


local UICorner = Instance.new('UICorner')
UICorner.CornerRadius = UDim.new(0, 16)
UICorner.Parent = GameInfo

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.AspectRatio = 13
UIAspectRatioConstraint.Parent = GameInfo

local UIScale = Instance.new('UIScale')
UIScale.Scale = 0.7
UIScale.Parent = GameInfo

local FpsIcon = Instance.new('ImageLabel')
FpsIcon.Name = "FpsIcon"
FpsIcon.Position = UDim2.new(0.022, 0, 0.32, 0)
FpsIcon.Size = UDim2.new(0.1, 0, 0.4, 0)
FpsIcon.BackgroundTransparency = 1
FpsIcon.Image = "rbxthumb://type=Asset&id=137471315687443&w=420&h=420"
FpsIcon.ImageColor3 = Color3.fromRGB(0, 168, 255)
FpsIcon.Parent = GameInfo

local UIAspectRatio_FpsIcon = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_FpsIcon.Parent = FpsIcon

local FPSText = Instance.new('TextLabel')
FPSText.Name = "FPSText"
FPSText.Position = UDim2.new(0.115, 0, 0.28, 0)
FPSText.Size = UDim2.new(0.17, 0, 0.44, 0)
FPSText.BackgroundTransparency = 1
FPSText.Text = "0 FPS"
FPSText.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSText.TextScaled = true
FPSText.Font = Enum.Font.SourceSansSemibold
FPSText.TextTransparency = 0.5
FPSText.TextXAlignment = Enum.TextXAlignment.Left
FPSText.Parent = GameInfo

local UIAspectRatio_FPSText = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_FPSText.AspectRatio = 8
UIAspectRatio_FPSText.Parent = FPSText

local SignalImage = Instance.new('ImageLabel')
SignalImage.Name = "SignalImage"
SignalImage.Position = UDim2.new(0.338, 0, 0.34, 0)
SignalImage.Size = UDim2.new(0.085, 0, 0.36, 0)
SignalImage.BackgroundTransparency = 1
SignalImage.Image = "rbxthumb://type=Asset&id=113541980541438&w=420&h=420"
SignalImage.ImageColor3 = Color3.fromRGB(0, 168, 255)
SignalImage.Parent = GameInfo

local UIAspectRatio_SignalImage = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_SignalImage.Parent = SignalImage

local MSText = Instance.new('TextLabel')
MSText.Name = "MSText"
MSText.Position = UDim2.new(0.435, 0, 0.28, 0)
MSText.Size = UDim2.new(0.15, 0, 0.44, 0)
MSText.BackgroundTransparency = 1
MSText.Text = "0 MS"
MSText.TextColor3 = Color3.fromRGB(255, 255, 255)
MSText.TextScaled = true
MSText.Font = Enum.Font.SourceSansSemibold
MSText.TextTransparency = 0.5
MSText.TextXAlignment = Enum.TextXAlignment.Left
MSText.Parent = GameInfo

local UIAspectRatio_MSText = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_MSText.AspectRatio = 8
UIAspectRatio_MSText.Parent = MSText

local UserIcon = Instance.new('ImageLabel')
UserIcon.Name = "UserIcon"
UserIcon.Position = UDim2.new(0.618, 0, 0.27, 0)
UserIcon.Size = UDim2.new(0.09, 0, 0.5, 0)
UserIcon.BackgroundTransparency = 1
UserIcon.Image = "rbxthumb://type=Asset&id=123112467890707&w=420&h=420"
UserIcon.ImageColor3 = Color3.fromRGB(0, 168, 255)
UserIcon.Parent = GameInfo

local UIAspectRatio_UserIcon = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_UserIcon.Parent = UserIcon

local Username = Instance.new('TextLabel')
Username.Name = "Username"
Username.Position = UDim2.new(0.690, 0, 0.30, 0)
Username.Size = UDim2.new(0.140, 0, 0.40, 0)
Username.TextTruncate = Enum.TextTruncate.AtEnd
Username.BackgroundTransparency = 1
Username.Text = LocalPlayer.DisplayName
Username.TextColor3 = Color3.fromRGB(255, 255, 255)
Username.TextScaled = true
Username.Font = Enum.Font.SourceSansSemibold
Username.TextTransparency = 0.5
Username.TextXAlignment = Enum.TextXAlignment.Left
Username.Parent = GameInfo

local NeverIcon = Instance.new('ImageLabel')
NeverIcon.Name = "NeverIcon"
NeverIcon.Position = UDim2.new(0.845, 0, 0.18, 0)
NeverIcon.Size = UDim2.new(0.044, 0, 0.64, 0)
NeverIcon.BackgroundTransparency = 1
NeverIcon.Image = "rbxthumb://type=Asset&id=118608145176297&w=420&h=420"
NeverIcon.Parent = GameInfo

local UIAspectRatio_NeverIcon = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_NeverIcon.Parent = NeverIcon

local UICorner_NeverIcon = Instance.new('UICorner')
UICorner_NeverIcon.CornerRadius = UDim.new(1, 0)
UICorner_NeverIcon.Parent = NeverIcon

local Profile = Instance.new('ImageLabel')
Profile.Name = "Profile"
Profile.Position = UDim2.new(0.912, 0, 0.18, 0)
Profile.Size = UDim2.new(0.044, 0, 0.64, 0)
Profile.BackgroundColor3 = Color3.fromRGB(127, 127, 127)
Profile.Image = ("rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420")
Profile.Parent = GameInfo

do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = Profile end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(70, 78, 110); s.Transparency = 0.35; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = Profile end
local UIAspectRatio_Profile = Instance.new('UIAspectRatioConstraint')
UIAspectRatio_Profile.Parent = Profile

local UICorner_Profile = Instance.new('UICorner')
UICorner_Profile.CornerRadius = UDim.new(1, 0)
UICorner_Profile.Parent = Profile

-- live FPS + ping updates
local fpsBuffer = {}
RunService.RenderStepped:Connect(function(dt)
    if type(dt) ~= "number" or dt <= 0 then return end
    table.insert(fpsBuffer, dt)
    if #fpsBuffer > 20 then table.remove(fpsBuffer, 1) end
    local avg = 0
    for _, v in ipairs(fpsBuffer) do avg = avg + v end
    if avg > 0 then FPSText.Text = tostring(math.round(#fpsBuffer / avg)) .. " FPS" end
    local ping = Stats and Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
    if ping then
        local ok, value = pcall(function() return ping:GetValue() end)
        if ok and type(value) == "number" then MSText.Text = tostring(math.round(value)) .. " MS" end
    end
end)


-- rounded window: no square drop-shadow image (its corners broke the rounding)

local Aspect = Instance.new("UIAspectRatioConstraint")
Aspect.Parent = MainFrame
Aspect.AspectRatio = 1.4

	local HubIcon = New("ImageLabel", {
		Name = "HubIcon",
		Position = UDim2.new(0.014000000432133675, 0, 0.006000000052154064, 0),
		Size = UDim2.new(0.042000000178813934, 0, 0.07500000339746475, 0),
		BackgroundColor3 = Color3.fromRGB(19,22,33),
		BorderSizePixel = 0,
		Image = hubImage ~= "" and hubImage or "rbxthumb://type=Asset&id=118608145176297&w=420&h=420",
		ScaleType = Enum.ScaleType.Fit,
	}, MainFrame)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, HubIcon)

	New("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0.06800000369548798, 0, 0.008700000122189522, 0),
		Size = UDim2.new(0.20000000298023224, 0, 0.05000000074505806, 0),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		Text = hubTitle,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Font = Enum.Font.SourceSansSemibold,
      TextXAlignment = Enum.TextXAlignment.Left,
	}, MainFrame)

	New("TextLabel", {
		Name = "GameTitle",
		Position = UDim2.new(0.06800000369548798, 0, 0.04699999839067459, 0),
		Size = UDim2.new(0.20000000298023224, 0, 0.024000000208616257, 0),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		Text = gameTitle,
		TextColor3 = Color3.fromRGB(255,255,255),
		TextScaled = true,
      TextTransparency = 0.6,
		Font = Enum.Font.SourceSansSemibold,
      TextXAlignment = Enum.TextXAlignment.Left,
	}, MainFrame)


	local Info = Instance.new('Frame')
	Info.Name = "Info"
	Info.Position = UDim2.new(0.017, 0, 0.916, 0)
	Info.Size = UDim2.new(0.196, 0, 0.070, 0)
	Info.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Info.BackgroundTransparency = 1
	Info.BorderSizePixel = 0
	Info.Active = true
	Info.Parent = MainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = Info end
	local InfoStroke = New("UIStroke", {
		Color = Color3.fromRGB(70, 78, 110),
		Transparency = 1,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Info)

	local UserImageEl = Instance.new('ImageLabel')
	UserImageEl.Name = "UserImage"
	UserImageEl.Size = UDim2.new(0.235,0,1,0)
	UserImageEl.BackgroundColor3 = Color3.fromRGB(21,24,36)
	UserImageEl.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
	UserImageEl.Parent = Info
	New("UICorner", { CornerRadius = UDim.new(1,0) }, UserImageEl)
	New("UIAspectRatioConstraint", { AspectType = Enum.AspectType.ScaleWithParentSize }, UserImageEl)
	local UserImageStroke = New("UIStroke", {
		Color = Color3.fromRGB(90, 100, 140),
		Transparency = 0.35,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, UserImageEl)

	local User = Instance.new('TextLabel')
	User.Name = "Username"
	User.Position = UDim2.new(0.315, 0, 0.10, 0)
	User.Size = UDim2.new(0.50, 0, 0.46, 0)
	User.TextTruncate = Enum.TextTruncate.AtEnd
	User.BackgroundColor3 = Color3.fromRGB(162,162,162)
	User.BackgroundTransparency = 1
	User.Text = LocalPlayer.Name
	User.TextColor3 = Color3.fromRGB(255,255,255)
	User.TextScaled = true
	User.Font = Enum.Font.GothamBold
	User.TextTransparency = 0
	User.TextXAlignment = Enum.TextXAlignment.Left
	User.TextYAlignment = Enum.TextYAlignment.Center
	User.Parent = Info

	local DaysLeft = Instance.new('TextLabel')
	DaysLeft.Name = "Daysleft"
	DaysLeft.Position = UDim2.new(0.315, 0, 0.56, 0)
	DaysLeft.Size = UDim2.new(0.50, 0, 0.32, 0)
	DaysLeft.TextTruncate = Enum.TextTruncate.AtEnd
	DaysLeft.BackgroundColor3 = Color3.fromRGB(162,162,162)
	DaysLeft.BackgroundTransparency = 1
	DaysLeft.Text = daysLeft
	DaysLeft.TextColor3 = Color3.fromRGB(255,255,255)
	DaysLeft.TextScaled = true
	DaysLeft.Font = Enum.Font.SourceSansSemibold
	DaysLeft.TextTransparency = 0.45
	DaysLeft.Font = Enum.Font.Gotham
	DaysLeft.TextXAlignment = Enum.TextXAlignment.Left
	DaysLeft.TextYAlignment = Enum.TextYAlignment.Center
	DaysLeft.Parent = Info

	local WindowSettings = Instance.new('TextButton')
	WindowSettings.Name = "WindowSettings"
	WindowSettings.Position = UDim2.new(0.5, 0, 0.25, 0)
	WindowSettings.Size = UDim2.new(0.5, 0, 0.5, 0)
	WindowSettings.BackgroundColor3 = Color3.fromRGB(255,255,255)
	WindowSettings.BackgroundTransparency = 1
	WindowSettings.Text = ""
	WindowSettings.TextColor3 = Color3.fromRGB(255,255,255)
	WindowSettings.TextScaled = true
	WindowSettings.TextXAlignment = Enum.TextXAlignment.Right
	WindowSettings.Parent = Info

local ImageLabel = Instance.new('ImageLabel')
ImageLabel.Name = "UserSettingsArrow"
ImageLabel.Position = UDim2.new(0.99, 0, 0.5, 0)
ImageLabel.Size = UDim2.new(0.40, 0, 0.40, 0)
ImageLabel.AnchorPoint = Vector2.new(1, 0.5)
ImageLabel.BackgroundTransparency = 1
ImageLabel.Image = "rbxassetid://10709790948"
ImageLabel.ImageTransparency = 0.2
ImageLabel.ScaleType = Enum.ScaleType.Fit
ImageLabel.Rotation = 270
ImageLabel.ZIndex = 102
local SettingsArrow = ImageLabel

	Info.MouseEnter:Connect(function()
		Tween(Info, {BackgroundTransparency = 0.93}, 0.15)
		Tween(InfoStroke, {Transparency = 0.55}, 0.15)
		Tween(UserImageStroke, {Transparency = 0.15}, 0.15)
		Tween(SettingsArrow, {ImageTransparency = 0}, 0.15)
	end)
	Info.MouseLeave:Connect(function()
		Tween(Info, {BackgroundTransparency = 1}, 0.15)
		Tween(InfoStroke, {Transparency = 1}, 0.15)
		Tween(UserImageStroke, {Transparency = 0.35}, 0.15)
		Tween(SettingsArrow, {ImageTransparency = 0.2}, 0.15)
	end)
	ImageLabel.Parent = WindowSettings

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 1
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = ImageLabel

	local WindowSettingsFrame = Instance.new('Frame')
	WindowSettingsFrame.Name = "WindowSettingsFrame"
	WindowSettingsFrame.Position = UDim2.new(0.006, 0, 0.44, 0)
	WindowSettingsFrame.Size = UDim2.new(0.218, 0, 0, 0)
	WindowSettingsFrame.AutomaticSize = Enum.AutomaticSize.Y
	WindowSettingsFrame.ClipsDescendants = false
	WindowSettingsFrame.BackgroundColor3 = Color3.fromRGB(21,24,36)
	WindowSettingsFrame.BackgroundTransparency = 0
	WindowSettingsFrame.ZIndex = 101
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = WindowSettingsFrame end
	WindowSettingsFrame.Visible = false
	WindowSettingsFrame.Parent = MainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = WindowSettingsFrame end


	local WSScale = New("UIScale", { Scale = 1 }, WindowSettingsFrame)


	local UIScale = Instance.new("UIScale")
	MainFrameUIScale = UIScale
	UIScale.Scale = 0.9
	UIScale.Parent = MainFrame
	local manualScale = 0.9
	local automaticScale = true
	local syncScaleSelection
	local applyMainColorProxy
	local applyLogoProxy
	local scaleViewportConnection
	local function GetAutomaticScale()
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		if viewport.X <= 0 or viewport.Y <= 0 then viewport = Vector2.new(1280, 720) end
		return math.clamp(math.min(viewport.X / 1280, viewport.Y / 760), 0.78, 1)
	end
	local function ApplyScale(value)
		if type(value) ~= "number" or value ~= value then return end
		UIScale.Scale = math.clamp(value, 0.5, 1.1)
	end
	local function UpdateScale()
		ApplyScale(automaticScale and GetAutomaticScale() or manualScale)
	end
	local function ConnectScaleCamera()
		if scaleViewportConnection then pcall(function() scaleViewportConnection:Disconnect() end) end
		scaleViewportConnection = nil
		local camera = workspace.CurrentCamera
		if camera and camera.GetPropertyChangedSignal then
			local ok, connection = pcall(function() return camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale) end)
			if ok then scaleViewportConnection = connection end
		end
	end
	local function OnCurrentCameraChanged()
		ConnectScaleCamera()
		UpdateScale()
	end
	UpdateScale()
	ConnectScaleCamera()
	pcall(function() workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(OnCurrentCameraChanged) end)

	-- Settings Container (Main Color + dropdowns)
	local SettingsContainer = Instance.new("Frame")
	SettingsContainer.Name = "SettingsContainer"
	SettingsContainer.Position = UDim2.new(0,0,0.03,0)
	SettingsContainer.Size = UDim2.new(1,0,0,50)
	SettingsContainer.BackgroundColor3 = Color3.fromRGB(162,162,162)
	SettingsContainer.BackgroundTransparency = 1
	SettingsContainer.ZIndex = 13
	SettingsContainer.AutomaticSize = Enum.AutomaticSize.Y
	SettingsContainer.Parent = WindowSettingsFrame
	do local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0,4); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = SettingsContainer end

	local menuBind = Enum.KeyCode.RightShift
	local menuBindProxy

	do
		local Row = Instance.new("Frame")
		Row.Name = "MenuBind"
		Row.Size = UDim2.new(1, 0, 0, 28)
		Row.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
		Row.BackgroundTransparency = 1
		Row.BorderSizePixel = 0
		Row.ZIndex = 120
		Row.LayoutOrder = 90
		Row.Parent = SettingsContainer
		do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 7.5; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = Row end

		local BLabel = Instance.new("TextLabel")
		BLabel.Name = "Text"
		BLabel.Position = UDim2.new(0.04, 0, 0.5, 0)
		BLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		BLabel.AnchorPoint = Vector2.new(0, 0.5)
		BLabel.BackgroundTransparency = 1
		BLabel.Text = "Menu Bind"
		BLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		BLabel.TextScaled = true
		BLabel.Font = Enum.Font.SourceSansSemibold
		BLabel.TextTransparency = 0.1
		BLabel.ZIndex = 130
		BLabel.TextXAlignment = Enum.TextXAlignment.Left
		BLabel.Parent = Row

		local BValue = Instance.new("TextLabel")
		BValue.Name = "BindValue"
		BValue.Position = UDim2.new(0.56, 0, 0.17, 0)
		BValue.Size = UDim2.new(0.38, 0, 0.66, 0)
		BValue.BackgroundColor3 = Color3.fromRGB(32, 35, 50)
		BValue.BackgroundTransparency = 0
		BValue.BorderSizePixel = 0
		BValue.Text = ""
		BValue.TextColor3 = Color3.fromRGB(255, 255, 255)
		BValue.TextScaled = true
		BValue.Font = Enum.Font.SourceSansSemibold
		BValue.TextTransparency = 0.1
		BValue.ZIndex = 130
		BValue.TextXAlignment = Enum.TextXAlignment.Center
		BValue.Parent = Row
		New("UICorner", { CornerRadius = UDim.new(0, 5) }, BValue)

		local capturing = false
		local captureConn = nil

		local function refreshBind()
			if capturing then
				BValue.Text = "..."
				BValue.TextColor3 = mainColor
			elseif menuBind == Enum.KeyCode.Unknown then
				BValue.Text = "None"
				BValue.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				BValue.Text = string.gsub(menuBind.Name, "_", " ")
				BValue.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end

		local function stopCapture()
			capturing = false
			if captureConn then captureConn:Disconnect(); captureConn = nil end
			refreshBind()
		end

		menuBindProxy = function(key)
			if key == nil then return menuBind end
			menuBind = key
			refreshBind()
			return menuBind
		end
		refreshBind()

		local BHit = Instance.new("TextButton")
		BHit.Name = "Bind"
		BHit.Position = UDim2.new(0.54, 0, 0, 0)
		BHit.Size = UDim2.new(0.44, 0, 1, 0)
		BHit.BackgroundTransparency = 1
		BHit.Text = ""
		BHit.ZIndex = 131
		BHit.Parent = Row

		BHit.MouseButton1Click:Connect(function()
			if capturing then
				Tween(Row, {BackgroundTransparency = 1}, 0.12)
				stopCapture()
				return
			end
			capturing = true
			Tween(Row, {BackgroundTransparency = 0.93}, 0.12)
			refreshBind()
			captureConn = UserInputService.InputBegan:Connect(function(input, processed)
				if processed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
				if input.KeyCode == Enum.KeyCode.Escape then
					Tween(Row, {BackgroundTransparency = 1}, 0.12)
					stopCapture()
					return
				end
				menuBind = input.KeyCode
				Tween(Row, {BackgroundTransparency = 1}, 0.12)
				stopCapture()
			end)
		end)
	end

	-- Colorpicker row
	local WSColorpicker = Instance.new("Frame")
	WSColorpicker.Name = "Colorpicker"
	WSColorpicker.Size = UDim2.new(1,0,0.20000000298023224,0)
	WSColorpicker.BackgroundTransparency = 1
	WSColorpicker.BorderSizePixel = 0
	WSColorpicker.ZIndex = 130
	WSColorpicker.LayoutOrder = 1
	WSColorpicker.Parent = SettingsContainer
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 7.5; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = WSColorpicker end
	do
		local ln = Instance.new("Frame"); ln.Name = "Lines"
		ln.Position = UDim2.new(0.05000000074505806,0,1,0)
		ln.Size = UDim2.new(0.8899999856948853,0,0,1)
		ln.BackgroundColor3 = Color3.fromRGB(162,162,162)
		ln.BackgroundTransparency = 0.9
		ln.BorderSizePixel = 0; ln.ZIndex = 130; ln.Parent = WSColorpicker
	end
	do
		local lbl = Instance.new("TextLabel")
		lbl.Name = "colorpickerLabel"
		lbl.Position = UDim2.new(0.03999999910593033,0,0.5,0)
		lbl.Size = UDim2.new(0.6499999761581421,0,0.5,0)
		lbl.AnchorPoint = Vector2.new(0,0.5)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Main Color"
		lbl.TextColor3 = Color3.fromRGB(255,255,255)
		lbl.TextScaled = true
		lbl.Font = Enum.Font.SourceSansSemibold
		lbl.TextTransparency = 0.5
		lbl.ZIndex = 130
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = WSColorpicker
	end

	local wsColorBtn = Instance.new("ImageButton")
	wsColorBtn.Name = "colorpickerButton"
	wsColorBtn.Position = UDim2.new(0.875,0,0.5699999928474426,0)
	wsColorBtn.Size = UDim2.new(0.07999999821186066,0,0.5,0)
	wsColorBtn.AnchorPoint = Vector2.new(0.5,0.5)
	wsColorBtn.BackgroundColor3 = mainColor
	wsColorBtn.BorderSizePixel = 0
	wsColorBtn.Image = ""
	wsColorBtn.ZIndex = 130
	wsColorBtn.Parent = WSColorpicker
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = wsColorBtn end

	local wsColorFrame = Instance.new("Frame")
	wsColorFrame.Name = "colorpickerFrame"
	wsColorFrame.Position = UDim2.new(0.02,0,1,2)
	wsColorFrame.Size = UDim2.new(0.96,0,7,0)
	wsColorFrame.BackgroundColor3 = Color3.fromRGB(15,17,26)
	wsColorFrame.BorderSizePixel = 0
	wsColorFrame.Visible = false
	wsColorFrame.ZIndex = 150
	wsColorFrame.ClipsDescendants = false
	wsColorFrame.Parent = WSColorpicker
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = wsColorFrame end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.9200000166893005; s.Parent = wsColorFrame end
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 1.100000023841858; a.Parent = wsColorFrame end

	local wsRGB = Instance.new("ImageButton")
	wsRGB.Name = "RGB"
	wsRGB.Position = UDim2.new(0.06700000166893005,0,0.06800000369548798,0)
	wsRGB.Size = UDim2.new(0.7400000095367432,0,0.7400000095367432,0)
	wsRGB.BackgroundTransparency = 1
	wsRGB.BorderSizePixel = 0
	wsRGB.Image = "rbxassetid://6523286724"
	wsRGB.AutoButtonColor = false
	wsRGB.ZIndex = 160
	wsRGB.Parent = wsColorFrame

	local wsRGBCircle = Instance.new("ImageLabel")
	wsRGBCircle.Name = "RGBCircle"
	wsRGBCircle.Size = UDim2.new(0,14,0,14)
	wsRGBCircle.BackgroundTransparency = 1
	wsRGBCircle.BorderSizePixel = 0
	wsRGBCircle.Image = "rbxassetid://3926309567"
	wsRGBCircle.ImageRectOffset = Vector2.new(628,420)
	wsRGBCircle.ImageRectSize = Vector2.new(48,48)
	wsRGBCircle.ZIndex = 161
	wsRGBCircle.Parent = wsRGB

	local wsDark = Instance.new("ImageButton")
	wsDark.Name = "Darkness"
	wsDark.Position = UDim2.new(0.8319402933120728,0,0.06800000369548798,0)
	wsDark.Size = UDim2.new(0.14000000059604645,0,0.7400000095367432,0)
	wsDark.BackgroundColor3 = mainColor
	wsDark.BorderSizePixel = 0
	wsDark.Image = "rbxassetid://156579757"
	wsDark.AutoButtonColor = false
	wsDark.ZIndex = 160
	wsDark.Parent = wsColorFrame

	local wsDarkCircle = Instance.new("Frame")
	wsDarkCircle.Name = "DarknessCircle"
	wsDarkCircle.Position = UDim2.new(0.5,0,0,0)
	wsDarkCircle.Size = UDim2.new(1.399999976158142,0,0,5)
	wsDarkCircle.AnchorPoint = Vector2.new(0.5,0.5)
	wsDarkCircle.BackgroundColor3 = mainColor
	wsDarkCircle.BorderSizePixel = 0
	wsDarkCircle.ZIndex = 161
	wsDarkCircle.Parent = wsDark
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = wsDarkCircle end

	local wsHex = Instance.new("TextLabel")
	wsHex.Name = "colorHex"
	wsHex.Position = UDim2.new(0.0717131495475769,0,0.8550000190734863,0)
	wsHex.Size = UDim2.new(0.4399999976158142,0,0.09000000357627869,0)
	wsHex.BackgroundColor3 = Color3.fromRGB(15,17,26)
	wsHex.TextColor3 = Color3.fromRGB(210,215,225)
	wsHex.TextScaled = true
	wsHex.Font = Enum.Font.ArialBold
	wsHex.ZIndex = 160
	wsHex.Parent = wsColorFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = wsHex end

	local wsCopy = Instance.new("TextButton")
	wsCopy.Name = "Copy"
	wsCopy.Position = UDim2.new(0.5400000214576721,0,0.8550000190734863,0)
	wsCopy.Size = UDim2.new(0.38999998569488525,0,0.09000000357627869,0)
	wsCopy.BackgroundColor3 = Color3.fromRGB(15,17,26)
	wsCopy.Text = "Copy"
	wsCopy.TextColor3 = Color3.fromRGB(210,215,225)
	wsCopy.TextScaled = true
	wsCopy.Font = Enum.Font.ArialBold
	wsCopy.ZIndex = 160
	wsCopy.Parent = wsColorFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = wsCopy end

	-- Menu Scale selection row (new accordion-style)
	local WSScaleRow = Instance.new("Frame")
	WSScaleRow.Name = "Selection"
	WSScaleRow.Size = UDim2.new(1,0,0,28)
	WSScaleRow.BackgroundColor3 = Color3.fromRGB(162,162,162)
	WSScaleRow.BackgroundTransparency = 1
	WSScaleRow.ZIndex = 120
	WSScaleRow.LayoutOrder = 3
	WSScaleRow.Parent = SettingsContainer
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 7.5; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = WSScaleRow end
	do
		local ln = Instance.new("Frame"); ln.Name = "Lines"
		ln.Position = UDim2.new(0.05000000074505806,0,1,0)
		ln.Size = UDim2.new(0.8999999761581421,0,0,1)
		ln.BackgroundColor3 = Color3.fromRGB(162,162,162)
		ln.BackgroundTransparency = 0.9
		ln.BorderSizePixel = 0; ln.ZIndex = 150; ln.Parent = WSScaleRow
	end
	do
		local lbl = Instance.new("TextLabel"); lbl.Name = "Text"
		lbl.Position = UDim2.new(0.03999999910593033,0,0.5,0)
		lbl.Size = UDim2.new(0.6499999761581421,0,0.5,0)
		lbl.AnchorPoint = Vector2.new(0,0.5)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Menu Scale"; lbl.TextColor3 = Color3.fromRGB(255,255,255)
		lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansSemibold
		lbl.TextTransparency = 0.5; lbl.ZIndex = 130
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = WSScaleRow
	end

	local ScaleArrow = Instance.new("ImageLabel")
	ScaleArrow.Name = "TextArrow"
	ScaleArrow.Position = UDim2.new(0.8700000047683716,0,0.10000000149011612,0)
	ScaleArrow.Size = UDim2.new(0.10000000149011612,0,0.800000011920929,0)
	ScaleArrow.BackgroundTransparency = 1
	ScaleArrow.Image = "rbxassetid://10709790948"
	ScaleArrow.ImageTransparency = 0.4000000059604645
	ScaleArrow.ImageColor3 = Color3.fromRGB(255,255,255)
	ScaleArrow.ScaleType = Enum.ScaleType.Fit
	ScaleArrow.Rotation = 270
	ScaleArrow.ZIndex = 1000
	ScaleArrow.Parent = WSScaleRow

	local ScaleDefault = Instance.new("TextLabel")
	ScaleDefault.Name = "TextDefault"
	ScaleDefault.Position = UDim2.new(0.6539999842643738,0,0.17000000178813934,0)
	ScaleDefault.Size = UDim2.new(0.23000000417232513,0,0.6000000238418579,0)
	ScaleDefault.BackgroundTransparency = 1
	ScaleDefault.Text = "Auto"
	ScaleDefault.TextColor3 = Color3.fromRGB(255,255,255)
	ScaleDefault.TextScaled = true
	ScaleDefault.Font = Enum.Font.SourceSansSemibold
	ScaleDefault.TextTransparency = 0.699999988079071
	ScaleDefault.ZIndex = 150
	ScaleDefault.TextXAlignment = Enum.TextXAlignment.Right
	ScaleDefault.Parent = WSScaleRow

	local ScaleDownBar = Instance.new("Frame")
	ScaleDownBar.Name = "Dropdown"
	ScaleDownBar.Position = UDim2.new(0.02,0,1,2)
	ScaleDownBar.Size = UDim2.new(0.5899999737739563,0,0,0)
	ScaleDownBar.AutomaticSize = Enum.AutomaticSize.Y
	ScaleDownBar.BackgroundColor3 = Color3.fromRGB(16,19,28)
	ScaleDownBar.BackgroundTransparency = 0
	ScaleDownBar.BorderSizePixel = 0
	ScaleDownBar.Visible = false
	ScaleDownBar.ZIndex = 1000
	ScaleDownBar.Parent = WSScaleRow
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = ScaleDownBar end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = ScaleDownBar end
	do
		local ds = Instance.new("ImageLabel"); ds.Name = "DropShadow"
		ds.Position = UDim2.new(0.5,0,0.5,0); ds.Size = UDim2.new(1,47,1,47)
		ds.AnchorPoint = Vector2.new(0.5,0.5); ds.BackgroundTransparency = 1; ds.BorderSizePixel = 0
		ds.Image = "rbxassetid://6014261993"; ds.ImageColor3 = Color3.fromRGB(12,14,22); ds.ZIndex = 999
		ds.Parent = ScaleDownBar
	end
	local ScaleContainer = Instance.new("ScrollingFrame")
	ScaleContainer.Name = "Container"
	ScaleContainer.Position = UDim2.new(0.05,0,0.05,0)
	ScaleContainer.Size = UDim2.new(0.9,0,0,96)
	ScaleContainer.BackgroundTransparency = 1
	ScaleContainer.ZIndex = 1000
	ScaleContainer.Active = true
	ScaleContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScaleContainer.CanvasSize = UDim2.new()
	ScaleContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	ScaleContainer.ScrollBarThickness = 2
	ScaleContainer.ScrollBarImageTransparency = 0.5
	ScaleContainer.Parent = ScaleDownBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = ScaleContainer end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(28,32,48); s.Transparency = 0.800000011920929; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = ScaleContainer end
	do local ll = Instance.new("UIListLayout"); ll.FillDirection = Enum.FillDirection.Vertical; ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,2); ll.Parent = ScaleContainer end

	local ScaleOpenBtn = Instance.new("TextButton"); ScaleOpenBtn.Name = "OpenBtn"
	ScaleOpenBtn.Size = UDim2.new(1,0,1,0); ScaleOpenBtn.BackgroundTransparency = 1
	ScaleOpenBtn.Text = ""; ScaleOpenBtn.ZIndex = 500; ScaleOpenBtn.Parent = WSScaleRow

	local WSLogoRow = New("Frame", {
		Name = "LogoToggle",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(162,162,162),
		BackgroundTransparency = 1,
		ZIndex = 120,
		LayoutOrder = 2,
	}, SettingsContainer)
	local logoLine = New("Frame", {
		Name = "Lines",
		Position = UDim2.new(0.06, 0, 1, -1),
		Size = UDim2.new(0.88, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(162,162,162),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 150,
	}, WSLogoRow)
	local logoLabel = New("TextLabel", {
		Name = "Text",
		Position = UDim2.new(0.04, 0, 0.5, 0),
		Size = UDim2.new(0.6, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text = "Logo",
		TextColor3 = Color3.fromRGB(255,255,255),
		TextScaled = true,
		Font = Enum.Font.SourceSansSemibold,
		TextTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 130,
	}, WSLogoRow)
	local LogoButton
	local function SetLogoState(visible)
		logoVisible = visible == true
		HubIcon.Visible = logoVisible
		if LogoButton then LogoButton.Text = logoVisible and "Visible" or "Hidden" end
	end
	applyLogoProxy = SetLogoState
	LogoButton = New("TextButton", {
		Name = "LogoButton",
		Position = UDim2.new(0.68, 0, 0.2, 0),
		Size = UDim2.new(0.25, 0, 0.6, 0),
		BackgroundColor3 = mainColor,
		BackgroundTransparency = 0.65,
		Text = "Visible",
		TextColor3 = Color3.fromRGB(255,255,255),
		TextScaled = true,
		Font = Enum.Font.SourceSansSemibold,
		ZIndex = 160,
	}, WSLogoRow)
	New("UICorner", {CornerRadius = UDim.new(0, 5)}, LogoButton)
	LogoButton.MouseButton1Click:Connect(function() SetLogoState(not logoVisible) end)

	local WSLangRow = Instance.new("Frame")
	WSLangRow.Name = "Selection"
	WSLangRow.Size = UDim2.new(1,0,0,28)
	WSLangRow.BackgroundColor3 = Color3.fromRGB(162,162,162)
	WSLangRow.BackgroundTransparency = 1
	WSLangRow.ZIndex = 120
	WSLangRow.LayoutOrder = 4
	WSLangRow.Parent = SettingsContainer
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 7.5; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = WSLangRow end
	do
		local ln = Instance.new("Frame"); ln.Name = "Lines"
		ln.Position = UDim2.new(0.05000000074505806,0,1,0)
		ln.Size = UDim2.new(0.8999999761581421,0,0,1)
		ln.BackgroundColor3 = Color3.fromRGB(162,162,162)
		ln.BackgroundTransparency = 0.9
		ln.BorderSizePixel = 0; ln.ZIndex = 150; ln.Parent = WSLangRow
	end
	do
		local lbl = Instance.new("TextLabel"); lbl.Name = "Text"
		lbl.Position = UDim2.new(0.03999999910593033,0,0.5,0)
		lbl.Size = UDim2.new(0.6499999761581421,0,0.5,0)
		lbl.AnchorPoint = Vector2.new(0,0.5)
		lbl.BackgroundTransparency = 1
		lbl.Text = "Language"; lbl.TextColor3 = Color3.fromRGB(255,255,255)
		lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansSemibold
		lbl.TextTransparency = 0.5; lbl.ZIndex = 130
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = WSLangRow
	end

	local LangArrow = Instance.new("ImageLabel")
	LangArrow.Name = "TextArrow"
	LangArrow.Position = UDim2.new(0.8700000047683716,0,0.10000000149011612,0)
	LangArrow.Size = UDim2.new(0.10000000149011612,0,0.800000011920929,0)
	LangArrow.BackgroundTransparency = 1
	LangArrow.Image = "rbxassetid://10709790948"
	LangArrow.ImageTransparency = 0.4000000059604645
	LangArrow.ImageColor3 = Color3.fromRGB(255,255,255)
	LangArrow.ScaleType = Enum.ScaleType.Fit
	LangArrow.Rotation = 270
	LangArrow.ZIndex = 1000
	LangArrow.Parent = WSLangRow

	local LangDefault = Instance.new("TextLabel")
	LangDefault.Name = "TextDefault"
	LangDefault.Position = UDim2.new(0.6539999842643738,0,0.17000000178813934,0)
	LangDefault.Size = UDim2.new(0.23000000417232513,0,0.6000000238418579,0)
	LangDefault.BackgroundTransparency = 1
	LangDefault.Text = "English"
	LangDefault.TextColor3 = Color3.fromRGB(255,255,255)
	LangDefault.TextScaled = true
	LangDefault.Font = Enum.Font.SourceSansSemibold
	LangDefault.TextTransparency = 0.699999988079071
	LangDefault.ZIndex = 150
	LangDefault.TextXAlignment = Enum.TextXAlignment.Right
	LangDefault.Parent = WSLangRow

	local LangDownBar = Instance.new("Frame")
	LangDownBar.Name = "Dropdown"
	LangDownBar.Position = UDim2.new(0.02,0,1,2)
	LangDownBar.Size = UDim2.new(0.5899999737739563,0,0,0)
	LangDownBar.AutomaticSize = Enum.AutomaticSize.Y
	LangDownBar.BackgroundColor3 = Color3.fromRGB(16,19,28)
	LangDownBar.BackgroundTransparency = 0
	LangDownBar.BorderSizePixel = 0
	LangDownBar.Visible = false
	LangDownBar.ZIndex = 1000
	LangDownBar.Parent = WSLangRow
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = LangDownBar end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = LangDownBar end
	do
		local ds = Instance.new("ImageLabel"); ds.Name = "DropShadow"
		ds.Position = UDim2.new(0.5,0,0.5,0); ds.Size = UDim2.new(1,47,1,47)
		ds.AnchorPoint = Vector2.new(0.5,0.5); ds.BackgroundTransparency = 1; ds.BorderSizePixel = 0
		ds.Image = "rbxassetid://6014261993"; ds.ImageColor3 = Color3.fromRGB(12,14,22); ds.ZIndex = 999
		ds.Parent = LangDownBar
	end
	local LangContainer = Instance.new("ScrollingFrame")
	LangContainer.Name = "Container"
	LangContainer.Position = UDim2.new(0.05,0,0.05,0)
	LangContainer.Size = UDim2.new(0.9,0,0,96)
	LangContainer.BackgroundTransparency = 1
	LangContainer.ZIndex = 1000
	LangContainer.Active = true
	LangContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	LangContainer.CanvasSize = UDim2.new()
	LangContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	LangContainer.ScrollBarThickness = 2
	LangContainer.ScrollBarImageTransparency = 0.5
	LangContainer.Parent = LangDownBar
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = LangContainer end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(28,32,48); s.Transparency = 0.800000011920929; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = LangContainer end
	do local ll = Instance.new("UIListLayout"); ll.FillDirection = Enum.FillDirection.Vertical; ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,2); ll.Parent = LangContainer end

	local LangOpenBtn = Instance.new("TextButton"); LangOpenBtn.Name = "OpenBtn"
	LangOpenBtn.Size = UDim2.new(1,0,1,0); LangOpenBtn.BackgroundTransparency = 1
	LangOpenBtn.Text = ""; LangOpenBtn.ZIndex = 500; LangOpenBtn.Parent = WSLangRow

	do
		-- Colorpicker logic
		local wsColorHSV = { Color3.toHSV(mainColor) }
		local wsWheelDown, wsSlideDown = false, false
		local wsPickerOpen = false

		local function wsToHex(c)
			return ColorToHex(c)
		end

		local function isOffGrey(col)
			return math.round(col.R*255) == 0 and math.round(col.G*255) == 0 and math.round(col.B*255) == 0
		end

		local function wsSyncIndicators()
			if not wsRGBCircle.Parent or not wsDarkCircle.Parent then return end
			local h, s, v = wsColorHSV[1], wsColorHSV[2], wsColorHSV[3]
			pcall(function()
				local cx = wsRGBCircle.AbsoluteSize.X / 2
				local cy = wsRGBCircle.AbsoluteSize.Y / 2
				if cx <= 0 then cx = 7 end
				if cy <= 0 then cy = 7 end
				wsRGBCircle.Position = UDim2.new(math.clamp(1 - h, 0, 1), -cx, math.clamp(1 - s, 0, 1), -cy)
			end)
			pcall(function()
				local dcy = wsDarkCircle.AbsoluteSize.Y / 2
				if dcy <= 0 then dcy = 2.5 end
				wsDarkCircle.Position = UDim2.new(0.5, 0, math.clamp(1 - v, 0, 1), -dcy)
			end)
		end

		local function wsApplyColor(c, keepIndicators)
			c = NormalizeColor(c)
			if not keepIndicators then
				local hsv = Color3.toHSV(c)
				wsColorHSV = { hsv.X, hsv.Y, hsv.Z }
			end
			for i, t in ipairs(tabs) do
				pcall(function()
					if i == activeTabIndex then
						t.icon.ImageColor3 = c
						t.icon.ImageTransparency = 0
					else
						t.icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
						t.icon.ImageTransparency = 0.6
					end
				end)
			end
			for _, obj in ipairs(NeverloseCS2:GetDescendants()) do
				pcall(function()
					if obj.Name == "Effect" and obj:IsA("Frame") and not isOffGrey(obj.BackgroundColor3) then
						obj.BackgroundColor3 = c
					end
					if obj.Name == "InLine" and obj:IsA("Frame") then
						obj.BackgroundColor3 = c
					end
				end)
			end
			pcall(function() wsColorBtn.BackgroundColor3 = c end)
			pcall(function() wsDark.BackgroundColor3 = c end)
			pcall(function() wsDarkCircle.BackgroundColor3 = c end)
			pcall(function() wsHex.Text = wsToHex(c) end)
			mainColor = c
			if not keepIndicators then
				task.defer(wsSyncIndicators)
			end
		end
		applyMainColorProxy = wsApplyColor

		local function wsUpdate()
			wsApplyColor(Color3.fromHSV(wsColorHSV[1], wsColorHSV[2], wsColorHSV[3]), true)
		end

		local function wsUpdateSlide(input)
			local ml = GetInputPosition(input)
			local y = ml.Y - wsDark.AbsolutePosition.Y
			local maxY = wsDark.AbsoluteSize.Y
			if maxY <= 0 then return end
			if y < 0 then y = 0 end; if y > maxY then y = maxY end
			y = ClampRatio(y, maxY)
			local cy = wsDarkCircle.AbsoluteSize.Y / 2
			wsColorHSV = {wsColorHSV[1], wsColorHSV[2], 1 - y}
			local rc = Color3.fromHSV(wsColorHSV[1], wsColorHSV[2], wsColorHSV[3])
			wsDarkCircle.BackgroundColor3 = rc
			wsDarkCircle.Position = UDim2.new(0.5, 0, y, -cy)
			wsUpdate()
		end

		local function wsUpdateRing(input)
			local ml = GetInputPosition(input)
			local x = ml.X - wsRGB.AbsolutePosition.X
			local y = ml.Y - wsRGB.AbsolutePosition.Y
			local maxX, maxY = wsRGB.AbsoluteSize.X, wsRGB.AbsoluteSize.Y
			if maxX <= 0 or maxY <= 0 then return end
			if x < 0 then x = 0 end; if x > maxX then x = maxX end
			if y < 0 then y = 0 end; if y > maxY then y = maxY end
			x = ClampRatio(x, maxX); y = ClampRatio(y, maxY)
			local cx = wsRGBCircle.AbsoluteSize.X / 2
			local cy = wsRGBCircle.AbsoluteSize.Y / 2
			wsRGBCircle.Position = UDim2.new(x, -cx, y, -cy)
			wsColorHSV = {1-x, 1-y, wsColorHSV[3]}
			local rc = Color3.fromHSV(wsColorHSV[1], wsColorHSV[2], wsColorHSV[3])
			wsDark.BackgroundColor3 = rc
			wsDarkCircle.BackgroundColor3 = rc
			wsUpdate()
		end

		wsColorBtn.MouseButton1Click:Connect(function()
			wsPickerOpen = not wsPickerOpen
			if wsPickerOpen then
				CloseAllPopupsExcept(wsColorFrame)
				wsColorFrame.Visible = true
				PositionPopupWithinMain(wsColorFrame, true)
				task.defer(wsSyncIndicators)
				RegisterPopup(wsColorFrame, function()
					wsPickerOpen = false
					UnregisterPopup(wsColorFrame)
					wsColorFrame.Visible = false
				end, wsColorBtn)
			else
				UnregisterPopup(wsColorFrame)
				wsColorFrame.Visible = false
			end
		end)
		wsRGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then wsWheelDown = true; wsUpdateRing(input) end end)
		wsDark.InputBegan:Connect(function(input) if IsPrimaryInput(input) then wsSlideDown = true; wsUpdateSlide(input) end end)
		UserInputService.InputEnded:Connect(function(input)
			if IsPrimaryInput(input) then
				wsWheelDown = false; wsSlideDown = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if wsWheelDown then wsUpdateRing(input) end
				if wsSlideDown then wsUpdateSlide(input) end
			end
		end)
		wsCopy.MouseButton1Click:Connect(function()
			if setclipboard then setclipboard(wsHex.Text) end
		end)
		wsHex.Text = wsToHex(mainColor)

		-- Scale dropdown (new accordion style)
		local scales = {"Auto", "100%", "90%", "80%", "70%", "60%", "50%"}
		local scaleVals = {nil, 1, 0.9, 0.8, 0.7, 0.6, 0.5}
		local scaleOpen = false
		local scaleSelectedBtns = {}
		syncScaleSelection = function(selectedLabel)
			ScaleDefault.Text = tostring(selectedLabel or "Auto")
			for label, button in pairs(scaleSelectedBtns) do
				button.Text = label == selectedLabel and "✓" or ""
				if label == selectedLabel then button.TextColor3 = mainColor end
			end
		end

		local function closeScaleDropdown()
			scaleOpen = false
			Tween(ScaleArrow, {ImageTransparency = 0.4, Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			UnregisterPopup(ScaleDownBar)
			SmoothClose(ScaleDownBar, 0.18)
		end

		for i, scaleLabel in ipairs(scales) do
			local sv = scaleVals[i]
			local BtnRow = Instance.new("Frame")
			BtnRow.Name = "Buttons"
			BtnRow.Size = UDim2.new(1,0,0,16)
			BtnRow.BackgroundTransparency = 1
			BtnRow.ZIndex = 1001
			BtnRow.LayoutOrder = i
			BtnRow.Parent = ScaleContainer

			local lbl = Instance.new("TextLabel")
			lbl.Position = UDim2.new(0,0,0.20000000298023224,0)
			lbl.Size = UDim2.new(1,0,0.6990000009536743,0)
			lbl.BackgroundTransparency = 1
			lbl.Text = scaleLabel
			lbl.TextColor3 = Color3.fromRGB(255,255,255)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.SourceSansSemibold
			lbl.TextTransparency = 0.1
			lbl.ZIndex = 1002
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = BtnRow

			local SelBtn = Instance.new("TextButton")
			SelBtn.Name = "Selected"
			SelBtn.Position = UDim2.new(0.800000011920929,0,0,0)
			SelBtn.Size = UDim2.new(0.20000000298023224,0,0.800000011920929,0)
			SelBtn.BackgroundTransparency = 1
			SelBtn.BorderSizePixel = 0
			SelBtn.Text = ""
			SelBtn.TextColor3 = Color3.fromRGB(26,123,255)
			SelBtn.TextScaled = true
			SelBtn.ZIndex = 1004
			SelBtn.Parent = BtnRow
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = SelBtn end
			scaleSelectedBtns[scaleLabel] = SelBtn

			local RowBtn = Instance.new("TextButton")
			RowBtn.Size = UDim2.new(1,0,1,0)
			RowBtn.BackgroundTransparency = 1
			RowBtn.Text = ""
			RowBtn.ZIndex = 1005
			RowBtn.Parent = BtnRow

			local function selectScale()
				syncScaleSelection(scaleLabel)
				if scaleLabel == "Auto" then
					automaticScale = true
					UpdateScale()
				else
					automaticScale = false
					manualScale = sv
					ApplyScale(sv)
				end
				closeScaleDropdown()
			end
			RowBtn.MouseButton1Click:Connect(selectScale)
			SelBtn.MouseButton1Click:Connect(selectScale)
		end

		syncScaleSelection("Auto")
		ScaleOpenBtn.MouseButton1Click:Connect(function()
			if scaleOpen then closeScaleDropdown()
			else
				CloseAllPopupsExcept(ScaleDownBar)
				scaleOpen = true
				SmoothOpen(ScaleDownBar, 0.5, 0.2)
				PositionPopupWithinMain(ScaleDownBar, true)
				Tween(ScaleArrow, {ImageTransparency = 0, Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				RegisterPopup(ScaleDownBar, closeScaleDropdown, ScaleOpenBtn)
			end
		end)

		-- Language dropdown (new accordion style)
		local langs = {"English", "Filipino", "Chinese", "Russian", "Italian"}
		local langOpen = false
		local langSelectedBtns = {}

		local function closeLangDropdown()
			langOpen = false
			Tween(LangArrow, {ImageTransparency = 0.4, Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			UnregisterPopup(LangDownBar)
			SmoothClose(LangDownBar, 0.18)
		end

		for _, lang in ipairs(langs) do
			local BtnRow = Instance.new("Frame")
			BtnRow.Name = "Buttons"
			BtnRow.Size = UDim2.new(1,0,0,16)
			BtnRow.BackgroundTransparency = 1
			BtnRow.ZIndex = 1001
			BtnRow.Parent = LangContainer

			local lbl = Instance.new("TextLabel")
			lbl.Position = UDim2.new(0.04,0,0,0)
			lbl.Size = UDim2.new(0.75,0,1,0)
			lbl.BackgroundTransparency = 1
			lbl.Text = lang
			lbl.TextColor3 = Color3.fromRGB(255,255,255)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.SourceSansSemibold
			lbl.TextTransparency = 0.1
			lbl.ZIndex = 1002
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = BtnRow

			local SelBtn = Instance.new("TextButton")
			SelBtn.Name = "Selected"
			SelBtn.Position = UDim2.new(0.8,0,0.1,0)
			SelBtn.Size = UDim2.new(0.18,0,0.8,0)
			SelBtn.BackgroundTransparency = 1
			SelBtn.BorderSizePixel = 0
			SelBtn.Text = ""
			SelBtn.TextColor3 = Color3.fromRGB(26,123,255)
			SelBtn.TextScaled = true
			SelBtn.ZIndex = 1004
			SelBtn.Parent = BtnRow
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = SelBtn end
			langSelectedBtns[lang] = SelBtn

			local RowBtn = Instance.new("TextButton")
			RowBtn.Size = UDim2.new(1,0,1,0)
			RowBtn.BackgroundTransparency = 1
			RowBtn.Text = ""
			RowBtn.ZIndex = 1005
			RowBtn.Parent = BtnRow

			local function selectLang()
				for k, sb in pairs(langSelectedBtns) do sb.Text = "" end
				SelBtn.Text = "✓"
				SelBtn.TextColor3 = mainColor
				LangDefault.Text = lang
				closeLangDropdown()
			end
			RowBtn.MouseButton1Click:Connect(selectLang)
			SelBtn.MouseButton1Click:Connect(selectLang)
		end

		LangOpenBtn.MouseButton1Click:Connect(function()
			if langOpen then closeLangDropdown()
			else
				CloseAllPopupsExcept(LangDownBar)
				langOpen = true
				SmoothOpen(LangDownBar, 0.5, 0.2)
			Tween(LangArrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				PositionPopupWithinMain(LangDownBar, true)
				Tween(LangArrow, {ImageTransparency = 0}, 0.2)
				RegisterPopup(LangDownBar, closeLangDropdown, LangOpenBtn)
			end
		end)

		-- Open/close panel
		local wsOpen = false
		local function closeWS()
			wsOpen = false
			ClosePopupsUnder(WindowSettingsFrame)
			UnregisterPopup(WindowSettingsFrame)
			SmoothClose(WindowSettingsFrame, 0.18)
			Tween(ImageLabel, {Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
		WindowSettings.MouseButton1Click:Connect(function()
			wsOpen = not wsOpen
			if wsOpen then
				CloseAllPopupsExcept(WindowSettingsFrame)
				WindowSettingsFrame.Position = UDim2.new(0.006, 0, 0.44, 0)
		WSScale.Scale = 0.92
		Tween(WSScale, { Scale = 1 }, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		SmoothOpen(WindowSettingsFrame, 0.01, 0.2)
				PositionPopupWithinMain(WindowSettingsFrame, false, 30, Info)
				RegisterPopup(WindowSettingsFrame, closeWS, WindowSettings)
				Tween(ImageLabel, {Rotation = 180}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			else
				closeWS()
			end
		end)
	end

	RegisterConfigElement("window_", "logo", {
		Get = function() return logoVisible end,
		Set = function(_, value) if applyLogoProxy then applyLogoProxy(value == true) end end,
	})
	RegisterConfigElement("window_", "scale", {
		Get = function() return automaticScale and "Auto" or UIScale.Scale end,
		Set = function(_, value)
			if value == "Auto" then
				automaticScale = true
				UpdateScale()
				if syncScaleSelection then syncScaleSelection("Auto") end
			elseif type(value) == "number" and value == value then
				automaticScale = false
				manualScale = math.clamp(value, 0.5, 1.1)
				ApplyScale(manualScale)
				if syncScaleSelection then syncScaleSelection(tostring(math.round(manualScale * 100)) .. "%") end
			end
		end,
	})
	RegisterConfigElement("window_", "mainColor", {
		Get = function() return mainColor end,
		Set = function(_, value)
			if applyMainColorProxy then applyMainColorProxy(NormalizeColor(value)) end
		end,
	})

	-- UsageContainer: dynamic rows added via WindowObj:GetUsage()
	local UsageContainer = Instance.new("Frame")
	UsageContainer.Name = "UsageContainer"
	UsageContainer.Position = UDim2.new(0,0,0.45,0)
	UsageContainer.Size = UDim2.new(1,0,0,50)
	UsageContainer.BackgroundColor3 = Color3.fromRGB(162,162,162)
	UsageContainer.BackgroundTransparency = 1
	UsageContainer.ZIndex = 13
	UsageContainer.AutomaticSize = Enum.AutomaticSize.Y
	UsageContainer.Parent = WindowSettingsFrame
	do local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0,1); ll.Parent = UsageContainer end

	local UsageObj = {}
	local usageElemCount = 0

	function UsageObj:AddSelection(text, options, default, callback)
		if type(default) == "function" then callback = default; default = nil end
		options = NormalizeOptions(options)
		usageElemCount = usageElemCount + 1
		local selected = GetValidOption(options, default)
		local dropOpen = false
		local selectedBtns = {}

		local Row = Instance.new("Frame")
		Row.Name = "Selection"
		Row.Size = UDim2.new(1,0,0,28)
		Row.BackgroundColor3 = Color3.fromRGB(162,162,162)
		Row.BackgroundTransparency = 1
		Row.ZIndex = 120
		Row.LayoutOrder = usageElemCount
		Row.Parent = UsageContainer
		do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 7.5; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = Row end
		do
			local ln = Instance.new("Frame"); ln.Name = "Lines"
			ln.Position = UDim2.new(0.06,0,1,-1)
			ln.Size = UDim2.new(0.9,0,0,1)
			ln.BackgroundColor3 = Color3.fromRGB(162,162,162)
			ln.BackgroundTransparency = 0.9
			ln.BorderSizePixel = 0; ln.ZIndex = 150; ln.Parent = Row
		end
		do
			local lbl = Instance.new("TextLabel"); lbl.Name = "Text"
			lbl.Position = UDim2.new(0.04,0,0.5,0)
			lbl.Size = UDim2.new(0.65,0,0.5,0)
			lbl.AnchorPoint = Vector2.new(0,0.5)
			lbl.BackgroundTransparency = 1
			lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
			lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansSemibold
			lbl.TextTransparency = 0.5; lbl.ZIndex = 130
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = Row
		end

		local Arrow = Instance.new("ImageLabel")
		Arrow.Name = "TextArrow"
		Arrow.Position = UDim2.new(0.87,0,0.1,0)
		Arrow.Size = UDim2.new(0.1,0,0.8,0)
		Arrow.BackgroundTransparency = 1
		Arrow.Image = "rbxassetid://10709790948"
		Arrow.ImageTransparency = 0.4
		Arrow.ImageColor3 = Color3.fromRGB(255,255,255)
		Arrow.ScaleType = Enum.ScaleType.Fit
		Arrow.Rotation = 270
		Arrow.ZIndex = 1000
		Arrow.Parent = Row

		local TextDefault = Instance.new("TextLabel")
		TextDefault.Name = "TextDefault"
		TextDefault.Position = UDim2.new(0.654,0,0.17,0)
		TextDefault.Size = UDim2.new(0.23,0,0.6,0)
		TextDefault.BackgroundTransparency = 1
		TextDefault.Text = selected
		TextDefault.TextColor3 = Color3.fromRGB(255,255,255)
		TextDefault.TextScaled = true
		TextDefault.Font = Enum.Font.SourceSansSemibold
		TextDefault.TextTransparency = 0.7
		TextDefault.ZIndex = 150
		TextDefault.TextXAlignment = Enum.TextXAlignment.Right
		TextDefault.Parent = Row

		local DropPopup = Instance.new("Frame")
		DropPopup.Name = "Dropdown"
		DropPopup.Position = UDim2.new(0.02,0,1,2)
		DropPopup.Size = UDim2.new(0.96,0,0,100)
		DropPopup.BackgroundColor3 = Color3.fromRGB(21,24,36)
		DropPopup.BackgroundTransparency = 0
		DropPopup.BorderSizePixel = 0
		DropPopup.Visible = false
		DropPopup.ZIndex = 1000
		DropPopup.Parent = Row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = DropPopup end
		do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = DropPopup end
		do
			local ds = Instance.new("ImageLabel"); ds.Name = "DropShadow"
			ds.Position = UDim2.new(0.5,0,0.5,0); ds.Size = UDim2.new(1,47,1,47)
			ds.AnchorPoint = Vector2.new(0.5,0.5); ds.BackgroundTransparency = 1; ds.BorderSizePixel = 0
			ds.Image = "rbxassetid://6014261993"; ds.ImageColor3 = Color3.fromRGB(12,14,22); ds.ZIndex = -1
			ds.Parent = DropPopup
		end

		local DropContainer = Instance.new("ScrollingFrame")
		DropContainer.Name = "Container"
		DropContainer.Position = UDim2.new(0.05,0,0.1,0)
		DropContainer.Size = UDim2.new(0.898,0,0,96)
		DropContainer.BackgroundTransparency = 1
		DropContainer.ZIndex = 1000
		DropContainer.Active = true
		DropContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		DropContainer.CanvasSize = UDim2.new()
		DropContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		DropContainer.ScrollBarThickness = 2
		DropContainer.ScrollBarImageTransparency = 0.5
		DropContainer.Parent = DropPopup
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = DropContainer end
		do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(28,32,48); s.Transparency = 0.8; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = DropContainer end
		do local ll = Instance.new("UIListLayout"); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = DropContainer end

		local function closeDropdown()
			dropOpen = false
			Tween(Arrow, {ImageTransparency = 0.4, Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			UnregisterPopup(DropPopup)
			SmoothClose(DropPopup, 0.18)
		end

		local function updateCheckmarks()
			for opt, sb in pairs(selectedBtns) do
				sb.Text = opt == selected and "✓" or ""
				if opt == selected then sb.TextColor3 = mainColor end
			end
		end

		for i, opt in ipairs(options) do
			local BtnRow = Instance.new("Frame")
			BtnRow.Name = "Buttons"
			BtnRow.Size = UDim2.new(1,0,0.2,0)
			BtnRow.BackgroundTransparency = 1
			BtnRow.ZIndex = 1001
			BtnRow.LayoutOrder = i
			BtnRow.Parent = DropContainer
			do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 6; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = BtnRow end

			local lbl = Instance.new("TextLabel")
			lbl.Position = UDim2.new(0,0,0.2,0)
			lbl.Size = UDim2.new(1,0,0.699,0)
			lbl.BackgroundTransparency = 1
			lbl.Text = opt
			lbl.TextColor3 = Color3.fromRGB(255,255,255)
			lbl.TextScaled = true
			lbl.Font = Enum.Font.SourceSansSemibold
			lbl.TextTransparency = 0.1
			lbl.ZIndex = 1002
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = BtnRow

			local SelBtn = Instance.new("TextButton")
			SelBtn.Name = "Selected"
			SelBtn.Position = UDim2.new(0.8,0,0,0)
			SelBtn.Size = UDim2.new(0.2,0,0.8,0)
			SelBtn.BackgroundTransparency = 1
			SelBtn.BorderSizePixel = 0
			SelBtn.Text = ""
			SelBtn.TextColor3 = Color3.fromRGB(26,123,255)
			SelBtn.TextScaled = true
			SelBtn.ZIndex = 1004
			SelBtn.Parent = BtnRow
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = SelBtn end
			selectedBtns[opt] = SelBtn

			local RowBtn = Instance.new("TextButton")
			RowBtn.Size = UDim2.new(1,0,1,0)
			RowBtn.BackgroundTransparency = 1
			RowBtn.Text = ""
			RowBtn.ZIndex = 1005
			RowBtn.Parent = BtnRow

			local function selectOpt()
				selected = opt
				TextDefault.Text = opt
				updateCheckmarks()
				closeDropdown()
				InvokeCallback(callback, opt)
			end
			RowBtn.MouseButton1Click:Connect(selectOpt)
			SelBtn.MouseButton1Click:Connect(selectOpt)
		end

		local OpenBtn = Instance.new("TextButton")
		OpenBtn.Name = "OpenBtn"
		OpenBtn.Size = UDim2.new(1,0,1,0)
		OpenBtn.BackgroundTransparency = 1
		OpenBtn.Text = ""
		OpenBtn.ZIndex = 500
		OpenBtn.Parent = Row

		OpenBtn.MouseButton1Click:Connect(function()
			if dropOpen then closeDropdown()
			else
				CloseAllPopupsExcept(DropPopup)
				dropOpen = true
				SmoothOpen(DropPopup, 0.5, 0.2)
		Tween(Arrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				Tween(Arrow, {ImageTransparency = 0}, 0.2)
				PositionPopupWithinMain(DropPopup, true); RegisterPopup(DropPopup, closeDropdown, OpenBtn)
			end
		end)

		updateCheckmarks()

		local obj = {}
		function obj:Set(val, silent) val = GetValidOption(options, val); selected = val; TextDefault.Text = val; updateCheckmarks(); if not silent then InvokeCallback(callback, val) end end
		function obj:Get() return selected end
		MakeReadableText(Row, 12, 18)
		return obj
	end

	function UsageObj:AddColorpicker(text, defaultColor, callback)
		usageElemCount = usageElemCount + 1
		local hue, sat, val = Color3.toHSV(NormalizeColor(defaultColor))
		local color = {hue, sat, val}
		local pickerOpen = false
		local WheelDown, SlideDown = false, false

		local Row = Instance.new("Frame")
		Row.Name = "Colorpicker"
		Row.Size = UDim2.new(1,0,0,28)
		Row.BackgroundTransparency = 1
		Row.BorderSizePixel = 0
		Row.ZIndex = 130
		Row.LayoutOrder = usageElemCount
		Row.ClipsDescendants = false
		Row.Parent = UsageContainer
		do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 7.5; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = Row end
		do
			local ln = Instance.new("Frame"); ln.Name = "Lines"
			ln.Position = UDim2.new(0.06,0,1,-1)
			ln.Size = UDim2.new(0.89,0,0,1)
			ln.BackgroundColor3 = Color3.fromRGB(162,162,162)
			ln.BackgroundTransparency = 0.9
			ln.BorderSizePixel = 0; ln.ZIndex = 130; ln.Parent = Row
		end
		do
			local lbl = Instance.new("TextLabel")
			lbl.Name = "TextToggle"
			lbl.Position = UDim2.new(0.04,0,0.5,0)
			lbl.Size = UDim2.new(0.65,0,0.5,0)
			lbl.AnchorPoint = Vector2.new(0,0.5)
			lbl.BackgroundTransparency = 1
			lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
			lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansSemibold
			lbl.TextTransparency = 0.5; lbl.ZIndex = 130
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = Row
		end

		local cpBtn = Instance.new("ImageButton")
		cpBtn.Name = "colorpickerButton"
		cpBtn.Position = UDim2.new(0.875,0,0.57,0)
		cpBtn.Size = UDim2.new(0.08,0,0.5,0)
		cpBtn.AnchorPoint = Vector2.new(0.5,0.5)
		cpBtn.BackgroundColor3 = NormalizeColor(defaultColor)
		cpBtn.BorderSizePixel = 0
		cpBtn.Image = ""
		cpBtn.ZIndex = 130
		cpBtn.Parent = Row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = cpBtn end

		local cpFrame = Instance.new("Frame")
		cpFrame.Name = "colorpickerFrame"
		cpFrame.Position = UDim2.new(0.02,0,1,2)
		cpFrame.Size = UDim2.new(0.96,0,7,0)
		cpFrame.BackgroundColor3 = Color3.fromRGB(15,17,26)
		cpFrame.BorderSizePixel = 0
		cpFrame.Visible = false
		cpFrame.ZIndex = 350
		cpFrame.ClipsDescendants = false
		cpFrame.Parent = Row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = cpFrame end
		do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.92; s.Parent = cpFrame end
		do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 1.1; a.Parent = cpFrame end

		local RGB = Instance.new("ImageButton")
		RGB.BackgroundTransparency = 1; RGB.BorderSizePixel = 0
		RGB.Position = UDim2.new(0.067,0,0.068,0); RGB.Size = UDim2.new(0.74,0,0.74,0)
		RGB.AutoButtonColor = false; RGB.Image = "rbxassetid://6523286724"; RGB.ZIndex = 360; RGB.Parent = cpFrame

		local RGBCircle = Instance.new("ImageLabel")
		RGBCircle.BackgroundTransparency = 1; RGBCircle.BorderSizePixel = 0
		RGBCircle.Size = UDim2.new(0,14,0,14)
		RGBCircle.Image = "rbxassetid://3926309567"
		RGBCircle.ImageRectOffset = Vector2.new(628,420); RGBCircle.ImageRectSize = Vector2.new(48,48)
		RGBCircle.ZIndex = 361; RGBCircle.Parent = RGB

		local Darkness = Instance.new("ImageButton")
		Darkness.BackgroundColor3 = NormalizeColor(defaultColor); Darkness.BorderSizePixel = 0
		Darkness.Position = UDim2.new(0.83194,0,0.068,0); Darkness.Size = UDim2.new(0.14,0,0.74,0)
		Darkness.AutoButtonColor = false; Darkness.Image = "rbxassetid://156579757"; Darkness.ZIndex = 360; Darkness.Parent = cpFrame

		local DarknessCircle = Instance.new("Frame")
		DarknessCircle.AnchorPoint = Vector2.new(0.5,0.5); DarknessCircle.BackgroundColor3 = NormalizeColor(defaultColor)
		DarknessCircle.BorderSizePixel = 0; DarknessCircle.Position = UDim2.new(0.5,0,0,0)
		DarknessCircle.Size = UDim2.new(1.4,0,0,5); DarknessCircle.ZIndex = 361; DarknessCircle.Parent = Darkness
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = DarknessCircle end

		local colorHex = Instance.new("TextLabel")
		colorHex.BackgroundColor3 = Color3.fromRGB(15,17,26)
		colorHex.Position = UDim2.new(0.0717,0,0.855,0); colorHex.Size = UDim2.new(0.44,0,0.09,0)
		colorHex.Font = Enum.Font.ArialBold; colorHex.Text = "#FFFFFF"
		colorHex.TextColor3 = Color3.fromRGB(210,215,225); colorHex.TextScaled = true; colorHex.ZIndex = 360; colorHex.Parent = cpFrame
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = colorHex end

		local Copy = Instance.new("TextButton")
		Copy.BackgroundColor3 = Color3.fromRGB(15,17,26)
		Copy.Position = UDim2.new(0.54,0,0.855,0); Copy.Size = UDim2.new(0.39,0,0.09,0)
		Copy.AutoButtonColor = false; Copy.Font = Enum.Font.ArialBold; Copy.Text = "Copy"
		Copy.TextColor3 = Color3.fromRGB(210,215,225); Copy.TextScaled = true; Copy.ZIndex = 360; Copy.Parent = cpFrame
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = Copy end

		local function to_hex(c) return ColorToHex(c) end

		local function update()
			local c = Color3.fromHSV(color[1],color[2],color[3])
			colorHex.Text = to_hex(c); cpBtn.BackgroundColor3 = c
			Darkness.BackgroundColor3 = c; DarknessCircle.BackgroundColor3 = c
			InvokeCallback(callback, c)
		end

		local function UpdateSlide(input)
			local m = GetInputPosition(input)
			local maxY = Darkness.AbsoluteSize.Y
			if maxY <= 0 then return end
			local y = ClampRatio(m.Y - Darkness.AbsolutePosition.Y, maxY)
			local cy = DarknessCircle.AbsoluteSize.Y / 2
			color = {color[1],color[2],1-y}
			local rc = Color3.fromHSV(color[1],color[2],color[3])
			DarknessCircle.BackgroundColor3 = rc; DarknessCircle.Position = UDim2.new(0.5,0,y,-cy)
			update()
		end

		local function UpdateRing(input)
			local m = GetInputPosition(input)
			local x = ClampRatio(m.X - RGB.AbsolutePosition.X, RGB.AbsoluteSize.X)
			local y = ClampRatio(m.Y - RGB.AbsolutePosition.Y, RGB.AbsoluteSize.Y)
			local cx = RGBCircle.AbsoluteSize.X/2; local cy = RGBCircle.AbsoluteSize.Y/2
			RGBCircle.Position = UDim2.new(x,-cx,y,-cy)
			color = {1-x,1-y,color[3]}
			local rc = Color3.fromHSV(color[1],color[2],color[3])
			Darkness.BackgroundColor3 = rc; DarknessCircle.BackgroundColor3 = rc; update()
		end

		cpBtn.MouseButton1Click:Connect(function()
			pickerOpen = not pickerOpen
			AnimateColorPickerOpen(cpFrame, cpBtn, pickerOpen, function(v) pickerOpen = v end)
		end)
		RGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then WheelDown = true; UpdateRing(input) end end)
		Darkness.InputBegan:Connect(function(input) if IsPrimaryInput(input) then SlideDown = true; UpdateSlide(input) end end)
		UserInputService.InputEnded:Connect(function(input)
			if IsPrimaryInput(input) then WheelDown = false; SlideDown = false end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if WheelDown then UpdateRing(input) end
				if SlideDown then UpdateSlide(input) end
			end
		end)
		Copy.MouseButton1Click:Connect(function() if setclipboard then setclipboard(colorHex.Text) end end)

		local function setcolor(tbl)
			local rc = Color3.fromHSV(tbl[1],tbl[2],tbl[3])
			colorHex.Text = to_hex(rc); cpBtn.BackgroundColor3 = rc
			Darkness.BackgroundColor3 = rc; DarknessCircle.BackgroundColor3 = rc
			color = {tbl[1],tbl[2],tbl[3]}
		end
		setcolor({hue, sat, val})
		task.defer(function()
			local cx = RGBCircle.AbsoluteSize.X / 2
			local cy = RGBCircle.AbsoluteSize.Y / 2
			RGBCircle.Position = UDim2.new(math.clamp(1 - hue, 0, 1), -cx, math.clamp(1 - sat, 0, 1), -cy)
			local dcy = DarknessCircle.AbsoluteSize.Y / 2
			DarknessCircle.Position = UDim2.new(0.5, 0, math.clamp(1 - val, 0, 1), -dcy)
		end)

		local obj = {}
		function obj:Set(c)
			local normalized = NormalizeColor(c)
			local h,s,v = Color3.toHSV(normalized)
			setcolor({h,s,v})
			InvokeCallback(callback, normalized)
		end
		function obj:Get() return Color3.fromHSV(color[1],color[2],color[3]) end
		MakeReadableText(Row, 12, 18)
		return obj
	end

	function WindowObj:GetUsage() return UsageObj end


	local Tab = New("ScrollingFrame", {
		Name = "Tab",
		Position = UDim2.new(0.00800000037997961, 0, 0.085, 0),
		Size = UDim2.new(0.20000000298023224, 0, 0.815, 0),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.35,
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, MainFrame)
	New("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Tab)

	

	local Frame2 = New("Frame", {
		Name = "Frame2",
		Position = UDim2.new(0.23000000417232513, 0, 0, 0),
		Size = UDim2.new(0.7699999809265137, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(16,19,28),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, MainFrame)

	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = Frame2 end

	local Header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0.09, 0),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, Frame2)

	local SearchBtn = New("ImageButton", {
		Name = "Search",
		Position = UDim2.new(0.938, 0, 0.20, 0),
		Size = UDim2.new(0.034, 0, 0.45, 0),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031154871",
      ImageTransparency = 0.2,
	}, Header)

local asss = Instance.new("UIAspectRatioConstraint")
asss.Parent = SearchBtn

	local _configs = {}

	local function SanitizeConfigName(name)
		name = tostring(name or "Default"):gsub("[^%w%-%_ ]", "_")
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if #name == 0 then name = "Default" end
		return name:sub(1, 64)
	end

	local function GetConfigPath(name)
		return "NeverloseConfig_" .. windowConfigId .. "_" .. SanitizeConfigName(name) .. ".json"
	end

	local function SaveNamedConfig(name)
		if type(writefile) ~= "function" then return false end
		local data = {}
		for _, entry in ipairs(_registeredElements) do
			if entry.obj and type(entry.obj.Get) == "function" then
				local ok, value = pcall(function() return entry.obj:Get() end)
				if ok then
					local serialized = SerializeValue(value)
					if serialized ~= nil then data[entry.key] = serialized end
				end
			end
		end
		local http = game:GetService("HttpService")
		local ok, encoded = pcall(http.JSONEncode, http, data)
		if not ok or type(encoded) ~= "string" then return false end
		local writeOk, writeResult = pcall(writefile, GetConfigPath(name), encoded)
		return writeOk and writeResult ~= false
	end

	local function LoadNamedConfig(name)
		if type(readfile) ~= "function" or type(isfile) ~= "function" then return false end
		local path = GetConfigPath(name)
		local existsOk, exists = pcall(isfile, path)
		if not existsOk or not exists then return false end
		local ok, content = pcall(readfile, path)
		if not ok or type(content) ~= "string" or #content > 2097152 then return false end
		local http = game:GetService("HttpService")
		local decodedOk, data = pcall(http.JSONDecode, http, content)
		if not decodedOk or type(data) ~= "table" then return false end
		local success = true
		for _, entry in ipairs(_registeredElements) do
			local saved = data[entry.key]
			if saved ~= nil then
				if not entry.obj or type(entry.obj.Set) ~= "function" then
					success = false
				else
					local setOk = pcall(function() entry.obj:Set(DeserializeValue(saved)) end)
					if not setOk then success = false end
				end
			end
		end
		return success
	end

	local function ListConfigs()
		if type(listfiles) ~= "function" then return {} end
		local result = {}
		local ok, files = pcall(listfiles, "")
		if not ok or type(files) ~= "table" then return result end
		local prefix = "NeverloseConfig_" .. windowConfigId .. "_"
		for _, fileName in ipairs(files) do
			if type(fileName) == "string" and string.sub(fileName, 1, #prefix) == prefix then
				local name = fileName:match("^" .. prefix .. "(.+)%.json$")
				if name then table.insert(result, name) end
			end
		end
		return result
	end

	

	local Save = Instance.new("Frame")
	Save.Name = "Save"
	Save.Position = UDim2.new(0.009999999776482582, 0, 0.2, 0)
	Save.Size = UDim2.new(0.21, 0, 0.55, 0)
	Save.BackgroundColor3 = Color3.fromRGB(21,24,36)
	Save.BackgroundTransparency = 0
	Save.BorderSizePixel = 0
	Save.Parent = Header
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = Save end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(40,44,65); s.Transparency = 0.85; s.Parent = Save end

	local SaveIcon = Instance.new('ImageLabel')
SaveIcon.Name = "SaveIcon"
SaveIcon.Position = UDim2.new(0.019999995827674866,0,0.20003588497638702,0)
SaveIcon.Size = UDim2.new(0.2700001299381256,0,0.6990000009536743,0)
SaveIcon.BackgroundTransparency = 1
SaveIcon.Image = "rbxassetid://6035067857"
SaveIcon.ImageTransparency = 0.20000000298023224
SaveIcon.Parent = Save

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.Parent = SaveIcon

	local SaveText = Instance.new('TextLabel')
	SaveText.Name = "SaveText"
	SaveText.Position = UDim2.new(0.23000600934028625,0,0.1899999976158142,0)
	SaveText.Size = UDim2.new(0.5500003099441528,0,0.699999988079071,0)
	SaveText.BackgroundTransparency = 1
	SaveText.Text = "Save"
SaveText.TextColor3 = Color3.fromRGB(255,255,255)
SaveText.TextScaled = true
SaveText.Font = Enum.Font.SourceSansSemibold
SaveText.TextTransparency = 0.20000000298023224
SaveText.TextXAlignment = Enum.TextXAlignment.Left
SaveText.Parent = Save

local Lines = Instance.new('Frame')
Lines.Name = "Lines"
Lines.Position = UDim2.new(0,-5,-0.19000010192394257,0)
Lines.Size = UDim2.new(-0.0010000000474974513,1,1.2000000476837158,3)
Lines.BackgroundColor3 = Color3.fromRGB(40,44,65)
Lines.BackgroundTransparency = 0.9
Lines.BorderSizePixel = 0
Lines.Parent = SaveText

local Lines_2 = Instance.new('Frame')
Lines_2.Name = "Lines"
Lines_2.Position = UDim2.new(1,0,-0.19000010192394257,0)
Lines_2.Size = UDim2.new(-0.0010000000474974513,1,1.2000000476837158,3)
Lines_2.BackgroundColor3 = Color3.fromRGB(40,44,65)
Lines_2.BackgroundTransparency = 0.9
Lines_2.BorderSizePixel = 0
Lines_2.Parent = SaveText

local SaveArrow = Instance.new('ImageLabel')
SaveArrow.Name = "Arrow"
SaveArrow.Position = UDim2.new(0.845,0,0.32,0)
SaveArrow.Size = UDim2.new(0.12,0,0.36,0)
SaveArrow.BackgroundTransparency = 1
SaveArrow.Image = "rbxassetid://10709790948"
SaveArrow.ImageColor3 = Color3.fromRGB(255,255,255)
SaveArrow.ScaleType = Enum.ScaleType.Fit
SaveArrow.Rotation = 270
SaveArrow.ZIndex = 15
SaveArrow.Parent = Save

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 2
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = SaveArrow


	local TriggerSaveConfig = Instance.new("TextButton")
	TriggerSaveConfig.Name = "TriggerSaveConfig"
	TriggerSaveConfig.Size = UDim2.new(1, 0, 1, 0)
	TriggerSaveConfig.BackgroundTransparency = 1
	TriggerSaveConfig.Text = ""
	TriggerSaveConfig.ZIndex = 15
	TriggerSaveConfig.Parent = Save

	-- ── ConfigMainFrame (new design panel) ──────────────────────
	local ConfigMainFrame = Instance.new("Frame")
	ConfigMainFrame.Name = "ConfigMainFrame"
	ConfigMainFrame.Position = UDim2.new(0.012, 0, 0.075, 0)
	ConfigMainFrame.Size = UDim2.new(0.4, 0, 0.42, 0)
	ConfigMainFrame.BackgroundColor3 = Color3.fromRGB(21,24,36)
	ConfigMainFrame.BackgroundTransparency = 0
	ConfigMainFrame.BorderSizePixel = 0
	ConfigMainFrame.ZIndex = 110
	ConfigMainFrame.AutomaticSize = Enum.AutomaticSize.None
	ConfigMainFrame.ClipsDescendants = false
	ConfigMainFrame.Active = true
	ConfigMainFrame.Visible = false
	ConfigMainFrame.Parent = Frame2
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = ConfigMainFrame end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = ConfigMainFrame end

	local CMHeader = Instance.new("Frame")
	CMHeader.Name = "Header"
	CMHeader.Size = UDim2.new(1, 0, 0.22, 0)
	CMHeader.BackgroundColor3 = Color3.fromRGB(26,30,45)
	CMHeader.BackgroundTransparency = 0
	CMHeader.BorderSizePixel = 0
	CMHeader.ClipsDescendants = true
	CMHeader.ZIndex = 100
	CMHeader.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = CMHeader end

	-- Cloud icon
	local CloudIcon = Instance.new("ImageLabel")
	CloudIcon.Name = "CloudIcon"
	CloudIcon.Position = UDim2.new(0.037, 0, 0.27, 0)
	CloudIcon.Size = UDim2.new(0.09, 0, 0.5, 0)
	CloudIcon.BackgroundTransparency = 1
	CloudIcon.Image = "rbxassetid://114688799023067"
	CloudIcon.ImageColor3 = mainColor
	CloudIcon.ZIndex = 1000
	CloudIcon.Parent = CMHeader
	do local a = Instance.new("UIAspectRatioConstraint"); a.Parent = CloudIcon end

	-- Title
	local CMTitle = Instance.new("TextLabel")
	CMTitle.Name = "TitleLabel"
	CMTitle.Position = UDim2.new(0.15, 0, 0, 0)
	CMTitle.Size = UDim2.new(0.45, 0, 1, 0)
	CMTitle.BackgroundTransparency = 1
	CMTitle.Text = "Presets"
	CMTitle.TextColor3 = mainColor
	CMTitle.TextSize = 15
	CMTitle.Font = Enum.Font.GothamBold
	CMTitle.TextTransparency = 0.1
	CMTitle.ZIndex = 1000
	CMTitle.TextXAlignment = Enum.TextXAlignment.Left
	CMTitle.Parent = CMHeader

	-- Header right buttons
	local CMHeaderRight = Instance.new("Frame")
	CMHeaderRight.Name = "HeaderRight"
	CMHeaderRight.Position = UDim2.new(0.65, 0, 0, 0)
	CMHeaderRight.Size = UDim2.new(0.3, 0, 1, 0)
	CMHeaderRight.BackgroundTransparency = 1
	CMHeaderRight.ZIndex = 1000
	CMHeaderRight.Parent = CMHeader
	do
		local ll = Instance.new("UIListLayout")
		ll.FillDirection = Enum.FillDirection.Horizontal
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ll.VerticalAlignment = Enum.VerticalAlignment.Center
		ll.Padding = UDim.new(0, 8)
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Parent = CMHeaderRight
	end

	-- AutoSave button (toggle)
	local autoSaveEnabled = false
	local AutoSaveBtn = Instance.new("ImageButton")
	AutoSaveBtn.Name = "AutomaticSave"
	AutoSaveBtn.Size = UDim2.new(0.459, 0, 0.459, 0)
	AutoSaveBtn.BackgroundTransparency = 1
	AutoSaveBtn.Image = "rbxassetid://88602887448810"
	AutoSaveBtn.ImageColor3 = Color3.fromRGB(200, 200, 220) -- off color
	AutoSaveBtn.ZIndex = 1000
	AutoSaveBtn.Parent = CMHeaderRight
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 1.2; a.Parent = AutoSaveBtn end

	-- RecentlyDeleted button
	local RecentlyDeletedBtn = Instance.new("ImageButton")
	RecentlyDeletedBtn.Name = "RecentlyDeleted"
	RecentlyDeletedBtn.Size = UDim2.new(0.459, 0, 0.459, 0)
	RecentlyDeletedBtn.BackgroundTransparency = 1
	RecentlyDeletedBtn.Image = "rbxassetid://124719621927271"
	RecentlyDeletedBtn.ImageColor3 = Color3.fromRGB(200, 200, 220)
	RecentlyDeletedBtn.ZIndex = 1000
	RecentlyDeletedBtn.LayoutOrder = 2
	RecentlyDeletedBtn.Parent = CMHeaderRight
	do local a = Instance.new("UIAspectRatioConstraint"); a.Parent = RecentlyDeletedBtn end

	-- InsertConfig (add new) button
	local InsertConfigBtn = Instance.new("ImageButton")
	InsertConfigBtn.Name = "InsertConfig"
	InsertConfigBtn.Size = UDim2.new(0.459, 0, 0.459, 0)
	InsertConfigBtn.BackgroundTransparency = 1
	InsertConfigBtn.Image = "rbxassetid://79421118238646"
	InsertConfigBtn.ImageColor3 = Color3.fromRGB(200, 200, 220)
	InsertConfigBtn.ZIndex = 1000
	InsertConfigBtn.LayoutOrder = 3
	InsertConfigBtn.Parent = CMHeaderRight
	do local a = Instance.new("UIAspectRatioConstraint"); a.Parent = InsertConfigBtn end

	-- Divider line
	local CMLine = Instance.new("Frame")
	CMLine.Name = "Line"
	CMLine.Active = true
	CMLine.Position = UDim2.new(0.05, 0, 0.898, 0)
	CMLine.Size = UDim2.new(0.9, 0, 0, 1)
	CMLine.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
	CMLine.BackgroundTransparency = 0.9
	CMLine.BorderSizePixel = 0
	CMLine.ZIndex = 1000
	CMLine.Parent = CMHeader

	-- ── Search Container ─────────────────────────────────────────
	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Position = UDim2.new(0.037, 0, 0.27, 0)
	SearchContainer.Size = UDim2.new(0.928, 0, 0.143, 0)
	SearchContainer.BackgroundColor3 = Color3.fromRGB(28,32,48)
	SearchContainer.BorderSizePixel = 0
	SearchContainer.ZIndex = 1000
	SearchContainer.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = SearchContainer end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = SearchContainer end
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 10; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = SearchContainer end

	local SearchIconImg = Instance.new("ImageLabel")
	SearchIconImg.Name = "SearchIcon"
	SearchIconImg.Position = UDim2.new(0.025, 0, 0.25, 0)
	SearchIconImg.Size = UDim2.new(0, 20, 0, 20)
	SearchIconImg.BackgroundTransparency = 1
	SearchIconImg.Image = "rbxassetid://6031154871"
	SearchIconImg.ImageColor3 = Color3.fromRGB(140, 140, 160)
	SearchIconImg.ZIndex = 1000
	SearchIconImg.Parent = SearchContainer
	do local a = Instance.new("UIAspectRatioConstraint"); a.Parent = SearchIconImg end

	local ConfigSearchBox = Instance.new("TextBox")
	ConfigSearchBox.Name = "SearchBox"
	ConfigSearchBox.Position = UDim2.new(0.12, 0, 0, 0)
	ConfigSearchBox.Size = UDim2.new(0.85, 0, 1, 0)
	ConfigSearchBox.BackgroundTransparency = 1
	ConfigSearchBox.Text = ""
	ConfigSearchBox.PlaceholderText = "Search"
	ConfigSearchBox.PlaceholderColor3 = Color3.fromRGB(200, 200, 210)
	ConfigSearchBox.TextColor3 = Color3.fromRGB(210, 215, 225)
	ConfigSearchBox.TextSize = 16
	ConfigSearchBox.Font = Enum.Font.Gotham
	ConfigSearchBox.ZIndex = 1000
	ConfigSearchBox.TextXAlignment = Enum.TextXAlignment.Left
	ConfigSearchBox.ClearTextOnFocus = false
	ConfigSearchBox.Parent = SearchContainer

	-- ── Config Name Input (shown when InsertConfig clicked) ──────
	local NameInputContainer = Instance.new("Frame")
	NameInputContainer.Name = "NameInputContainer"
	NameInputContainer.Position = UDim2.new(0.037, 0, 0.27, 0)
	NameInputContainer.Size = UDim2.new(0.928, 0, 0.143, 0)
	NameInputContainer.BackgroundColor3 = Color3.fromRGB(19,22,33)
	NameInputContainer.BorderSizePixel = 0
	NameInputContainer.ZIndex = 1001
	NameInputContainer.Visible = false
	NameInputContainer.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = NameInputContainer end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = NameInputContainer end
	do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 10; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = NameInputContainer end

	local NameOfConfig = Instance.new("TextBox")
	NameOfConfig.Name = "NameOfConfig"
	NameOfConfig.Position = UDim2.new(0.03, 0, 0, 0)
	NameOfConfig.Size = UDim2.new(0.75, 0, 1, 0)
	NameOfConfig.BackgroundTransparency = 1
	NameOfConfig.Text = ""
	NameOfConfig.PlaceholderText = "Config name..."
	NameOfConfig.PlaceholderColor3 = Color3.fromRGB(200, 200, 210)
	NameOfConfig.TextColor3 = Color3.fromRGB(210, 215, 225)
	NameOfConfig.TextSize = 16
	NameOfConfig.Font = Enum.Font.Gotham
	NameOfConfig.ZIndex = 1001
	NameOfConfig.TextXAlignment = Enum.TextXAlignment.Left
	NameOfConfig.ClearTextOnFocus = false
	NameOfConfig.Parent = NameInputContainer

	local ConfirmAddBtn = Instance.new("TextButton")
	ConfirmAddBtn.Name = "ConfirmAdd"
	ConfirmAddBtn.Position = UDim2.new(0.78, 0, 0.1, 0)
	ConfirmAddBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
	ConfirmAddBtn.BackgroundColor3 = mainColor
	ConfirmAddBtn.BackgroundTransparency = 0.15
	ConfirmAddBtn.Text = "Create"
	ConfirmAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ConfirmAddBtn.TextSize = 13
	ConfirmAddBtn.Font = Enum.Font.GothamBold
	ConfirmAddBtn.ZIndex = 1002
	ConfirmAddBtn.Parent = NameInputContainer
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = ConfirmAddBtn end

	-- ── List Container ────────────────────────────────────────────
	local ListContainer = Instance.new("ScrollingFrame")
	ListContainer.Name = "ListContainer"
	ListContainer.Position = UDim2.new(0.037, 0, 0.435, 0)
	ListContainer.Size = UDim2.new(0.93, 0, 0.55, 0)
	ListContainer.BackgroundTransparency = 1
	ListContainer.BorderSizePixel = 0
	ListContainer.ZIndex = 100
	ListContainer.Active = true
	ListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ListContainer.CanvasSize = UDim2.new()
	ListContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	ListContainer.ScrollBarThickness = 3
	ListContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 128, 160)
	ListContainer.ScrollBarImageTransparency = 0.3
	ListContainer.Parent = ConfigMainFrame
	ListContainer.ClipsDescendants = true
	do
		local ll = Instance.new("UIListLayout")
		ll.Name = "UIListLayout"
		ll.Padding = UDim.new(0, 6)
		ll.Parent = ListContainer
	end

	-- Spacing frame
	local Space = Instance.new("Frame")
	Space.Name = "Space"
	Space.Size = UDim2.new(1, 0, 0, 3)
	Space.BackgroundTransparency = 1
	Space.ZIndex = 100
	Space.Parent = ListContainer

	-- ── Icons ────────────────────────────────────────────────────
	local SAVE_ICON = "rbxassetid://6035067857"  -- floppy/save
	local LOAD_ICON = "rbxassetid://102258343905919"                  -- download/load

	-- ── Deleted configs store (in-memory + file persistence) ─────
	local DELETED_FILE = "NeverloseDeleted_" .. windowConfigId .. ".json"
	local _deletedConfigs = {} -- { name=string, data=table }

	local function LoadDeletedList()
		if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
		local existsOk, exists = pcall(isfile, DELETED_FILE)
		if not existsOk or not exists then return end
		local ok, content = pcall(readfile, DELETED_FILE)
		if not ok or not content then return end
		local dok, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
		if dok and type(data) == "table" then
			local safe = {}
			for _, entry in ipairs(data) do
				if type(entry) == "table" and type(entry.name) == "string" and type(entry.data) == "table" then
					table.insert(safe, {name = SanitizeConfigName(entry.name), data = entry.data})
				end
			end
			while #safe > 20 do table.remove(safe) end
			_deletedConfigs = safe
		end
	end

	local function SaveDeletedList()
		if type(writefile) ~= "function" then return end
		local ok, encoded = pcall(game:GetService("HttpService").JSONEncode, game:GetService("HttpService"), _deletedConfigs)
		if ok then pcall(writefile, DELETED_FILE, encoded) end
	end

	LoadDeletedList()

	-- ── Recently Deleted Panel ────────────────────────────────────
	local RecentlyDeletedPanel = Instance.new("Frame")
	RecentlyDeletedPanel.Name = "RecentlyDeletedPanel"
	RecentlyDeletedPanel.Position = UDim2.new(0.012, 0, 0.075, 0)
	RecentlyDeletedPanel.Size = UDim2.new(0.4, 0, 0.42, 0)
	RecentlyDeletedPanel.BackgroundColor3 = Color3.fromRGB(17,20,30)
	RecentlyDeletedPanel.BackgroundTransparency = 0
	RecentlyDeletedPanel.BorderSizePixel = 0
	RecentlyDeletedPanel.ZIndex = 120
	RecentlyDeletedPanel.AutomaticSize = Enum.AutomaticSize.None
	RecentlyDeletedPanel.ClipsDescendants = false
	RecentlyDeletedPanel.Active = true
	RecentlyDeletedPanel.Visible = false
	RecentlyDeletedPanel.Parent = Frame2
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 18); c.Parent = RecentlyDeletedPanel end
	do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(46,52,74); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = RecentlyDeletedPanel end

	-- RD Header
	local RDHeader = Instance.new("Frame")
	RDHeader.Name = "RDHeader"
	RDHeader.Size = UDim2.new(1, 0, 0.22, 0)
	RDHeader.BackgroundColor3 = Color3.fromRGB(17,20,30)
	RDHeader.BorderSizePixel = 0
	RDHeader.ZIndex = 121
	RDHeader.Parent = RecentlyDeletedPanel
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = RDHeader end

	local RDTitle = Instance.new("TextLabel")
	RDTitle.Name = "RDTitle"
	RDTitle.Position = UDim2.new(0.05, 0, 0, 0)
	RDTitle.Size = UDim2.new(0.6, 0, 1, 0)
	RDTitle.BackgroundTransparency = 1
	RDTitle.Text = "Recently Deleted"
	RDTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	RDTitle.TextSize = 18
	RDTitle.Font = Enum.Font.GothamBold
	RDTitle.ZIndex = 122
	RDTitle.TextXAlignment = Enum.TextXAlignment.Left
	RDTitle.Parent = RDHeader

	local RDBackBtn = Instance.new("TextButton")
	RDBackBtn.Name = "RDBackBtn"
	RDBackBtn.Position = UDim2.new(0.82, 0, 0.2, 0)
	RDBackBtn.Size = UDim2.new(0.14, 0, 0.6, 0)
	RDBackBtn.BackgroundColor3 = Color3.fromRGB(23,26,39)
	RDBackBtn.BackgroundTransparency = 0.15
	RDBackBtn.Text = "← Back"
	RDBackBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
	RDBackBtn.TextSize = 12
	RDBackBtn.Font = Enum.Font.GothamBold
	RDBackBtn.ZIndex = 122
	RDBackBtn.Parent = RDHeader
	do local c = Instance.new("UICorner"); c.Parent = RDBackBtn end

	-- RD list
	local RDList = Instance.new("ScrollingFrame")
	RDList.Name = "RDList"
	RDList.Position = UDim2.new(0.037, 0, 0.28, 0)
	RDList.Size = UDim2.new(0.926, 0, 0.7, 0)
	RDList.BackgroundTransparency = 1
	RDList.BorderSizePixel = 0
	RDList.ZIndex = 121
	RDList.Active = true
	RDList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	RDList.CanvasSize = UDim2.new()
	RDList.ScrollingDirection = Enum.ScrollingDirection.Y
	RDList.ScrollBarThickness = 3
	RDList.ScrollBarImageTransparency = 0.35
	RDList.Parent = RecentlyDeletedPanel
	do local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 6); ll.Parent = RDList end

	local function RefreshDeletedList()
		for _, c in ipairs(RDList:GetChildren()) do
			if c:IsA("Frame") then c:Destroy() end
		end
		for i = #_deletedConfigs, 1, -1 do -- newest first
			local entry = _deletedConfigs[i]
			local drow = Instance.new("Frame")
			drow.Name = "DeletedRow"
			drow.Size = UDim2.new(1, 0, 0, 0)
			drow.BackgroundColor3 = Color3.fromRGB(35,18,18)
			drow.BackgroundTransparency = 0.25
			drow.BorderSizePixel = 0
			drow.ZIndex = 122
			drow.Parent = RDList
			do local c = Instance.new("UICorner"); c.Parent = drow end
			do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(180,60,60); s.Transparency = 0.7; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = drow end
			do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 10; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = drow end

			local dlbl = Instance.new("TextLabel")
			dlbl.Position = UDim2.new(0.04, 0, 0, 0)
			dlbl.Size = UDim2.new(0.6, 0, 1, 0)
			dlbl.BackgroundTransparency = 1
			dlbl.Text = entry.name
			dlbl.TextColor3 = Color3.fromRGB(220, 180, 180)
			dlbl.TextSize = 15
			dlbl.Font = Enum.Font.GothamBold
			dlbl.ZIndex = 123
			dlbl.TextXAlignment = Enum.TextXAlignment.Left
			dlbl.Parent = drow

			local restoreBtn = Instance.new("TextButton")
			restoreBtn.Name = "Restore"
			restoreBtn.Position = UDim2.new(0.72, 0, 0.15, 0)
			restoreBtn.Size = UDim2.new(0.24, 0, 0.7, 0)
			restoreBtn.BackgroundColor3 = mainColor
			restoreBtn.BackgroundTransparency = 0.15
			restoreBtn.Text = "Restore"
			restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			restoreBtn.TextSize = 12
			restoreBtn.Font = Enum.Font.GothamBold
			restoreBtn.ZIndex = 123
			restoreBtn.Parent = drow
			do local c = Instance.new("UICorner"); c.Parent = restoreBtn end

			local idx = i
			restoreBtn.MouseButton1Click:Connect(function()
				local restored = false
				local encodedOk, encoded = pcall(game:GetService("HttpService").JSONEncode, game:GetService("HttpService"), entry.data)
				if encodedOk and type(encoded) == "string" and type(writefile) == "function" then
					local writeOk, writeResult = pcall(writefile, GetConfigPath(entry.name), encoded)
					restored = writeOk and writeResult ~= false
				end
				if restored then
					table.remove(_deletedConfigs, idx)
					SaveDeletedList()
					RefreshDeletedList()
				end
			end)
		end

	end

	-- Back button
	local closeConfigPanel
	local configOpen = false
	RDBackBtn.MouseButton1Click:Connect(function()
		UnregisterPopup(RecentlyDeletedPanel)
		Tween(RecentlyDeletedPanel, {BackgroundTransparency = 1}, 0.2)
		task.delay(0.22, function()
			if not configOpen then return end
			RecentlyDeletedPanel.Visible = false
			ConfigMainFrame.Visible = true
			ConstrainPopupToMainFrame(ConfigMainFrame); task.defer(function() ConstrainPopupToMainFrame(ConfigMainFrame) end); RegisterPopup(ConfigMainFrame, closeConfigPanel, TriggerSaveConfig)
			ConfigMainFrame.BackgroundTransparency = 1
			Tween(ConfigMainFrame, {BackgroundTransparency = 0.01}, 0.2)
		end)
	end)

	-- ── Active row tracking ───────────────────────────────────────
	local activeRow = nil     -- the currently "loaded" row frame
	local activeLoadBtn = nil -- its LoadConfig ImageButton
	local activeConfigName = nil

	local function SetActiveConfigName(name)
		if type(name) == "string" and name ~= "" and name ~= "Save" then
			activeConfigName = name
		else
			activeConfigName = nil
		end
		SaveText.Text = activeConfigName or "Save"
	end

	local function ClearActiveConfig()
		activeRow = nil
		activeLoadBtn = nil
		SetActiveConfigName(nil)
	end

	local function DeactivateRow(rowFrame, loadBtn)
		-- Reset stroke color/transparency
		local s = rowFrame:FindFirstChildWhichIsA("UIStroke")
		if s then Tween(s, {Transparency = 0.5, Color = Color3.fromRGB(52,52,52)}, 0.15) end
		Tween(rowFrame, {BackgroundTransparency = 0}, 0.15)
		-- Reset icon back to LOAD
		loadBtn.Image = LOAD_ICON
		Tween(loadBtn, {ImageColor3 = Color3.fromRGB(180, 180, 200)}, 0.15)
	end

	-- ── Helper: create a config row ───────────────────────────────
	local function MakeConfigButton(name)
		local row = Instance.new("Frame")
		row.Name = "ConfigRow_" .. name
		row.Size = UDim2.new(1, 0, 0, 0)
		row.BackgroundColor3 = Color3.fromRGB(21,24,36)
		row.BackgroundTransparency = 0
		row.BorderSizePixel = 0
		row.ZIndex = 1000
		row.Parent = ListContainer
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row end
		do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = row end
		do local a = Instance.new("UIAspectRatioConstraint"); a.AspectRatio = 10; a.AspectType = Enum.AspectType.ScaleWithParentSize; a.Parent = row end

		local rowStroke = row:FindFirstChildWhichIsA("UIStroke")
		row.MouseEnter:Connect(function() Tween(row, {BackgroundTransparency = 0.85}, 0.12) end)
		row.MouseLeave:Connect(function() Tween(row, {BackgroundTransparency = 0}, 0.12) end)

		-- Name label
		local Rename = Instance.new("TextBox")
		Rename.Name = "Rename"
		Rename.Position = UDim2.new(0.037, 0, 0, 0)
		Rename.Size = UDim2.new(0.6, 0, 1, 0)
		Rename.BackgroundTransparency = 1
		Rename.Text = name
		Rename.PlaceholderText = "No Name"
		Rename.PlaceholderColor3 = Color3.fromRGB(210, 215, 225)
		Rename.TextColor3 = Color3.fromRGB(210, 215, 225)
		Rename.TextSize = 16
		Rename.Font = Enum.Font.GothamBold
		Rename.ZIndex = 1000
		Rename.TextXAlignment = Enum.TextXAlignment.Left
		Rename.ClearTextOnFocus = false
		pcall(function() Rename.ReadOnly = true end)
		Rename.Parent = row

		-- "..." button
		local SettingsBtn = Instance.new("TextButton")
		SettingsBtn.Name = "Settings"
		SettingsBtn.Position = UDim2.new(0.75, 0, 0, 0)
		SettingsBtn.Size = UDim2.new(0.1, 0, 1, 0)
		SettingsBtn.BackgroundTransparency = 1
		SettingsBtn.Text = "..."
		SettingsBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
		SettingsBtn.TextSize = 20
		SettingsBtn.Font = Enum.Font.GothamBold
		SettingsBtn.ZIndex = 3000
		SettingsBtn.Parent = row

		-- Load/Save icon button
		local LoadConfigBtn = Instance.new("ImageButton")
		LoadConfigBtn.Name = "LoadConfig"
		LoadConfigBtn.Position = UDim2.new(0.879, 0, 0.1, 0)
		LoadConfigBtn.Size = UDim2.new(0.095, 0, 0.8, 0)
		LoadConfigBtn.BackgroundTransparency = 1
		LoadConfigBtn.Image = LOAD_ICON
		LoadConfigBtn.ImageColor3 = Color3.fromRGB(180, 180, 200)
		LoadConfigBtn.ZIndex = 3000
		LoadConfigBtn.Parent = row
		do local a = Instance.new("UIAspectRatioConstraint"); a.Parent = LoadConfigBtn end

		-- ── Settings Frame (shown on "..." click) ─────────────────
		local SettingsFrame = Instance.new("Frame")
		SettingsFrame.Name = "SettingsFrame"
		SettingsFrame.Position = UDim2.new(0.54, 0, 1, 2)
		SettingsFrame.Size = UDim2.new(0.44, 0, 0, 0)
		SettingsFrame.BackgroundColor3 = Color3.fromRGB(21,24,36)
		SettingsFrame.BackgroundTransparency = 0
		SettingsFrame.BorderSizePixel = 0
		SettingsFrame.ZIndex = 6000
		SettingsFrame.AutomaticSize = Enum.AutomaticSize.None
		SettingsFrame.Visible = false
		SettingsFrame.ClipsDescendants = false
		SettingsFrame.Active = true
		SettingsFrame.Parent = row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = SettingsFrame end
		do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = SettingsFrame end
		do
			local ll = Instance.new("UIListLayout")
			ll.Padding = UDim.new(0, 2)
			ll.Parent = SettingsFrame
		end

		local sfOpen = false
		local closeSfRow
		local SF_ROW_HEIGHT = 58
		local function MakeSettingBtn(text, textColor, callback)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 27)
			btn.BackgroundTransparency = 1
			btn.Text = text
			btn.TextColor3 = textColor
			btn.TextSize = 13
			btn.Font = Enum.Font.GothamBold
			btn.ZIndex = 6001
			btn.Parent = SettingsFrame

			-- hover highlight
			btn.MouseEnter:Connect(function()
				Tween(btn, {BackgroundTransparency = 0.7}, 0.1)
				btn.BackgroundColor3 = Color3.fromRGB(25,28,42)
			end)
			btn.MouseLeave:Connect(function()
				Tween(btn, {BackgroundTransparency = 1}, 0.1)
			end)
			btn.MouseButton1Click:Connect(function()
				if closeSfRow then closeSfRow() else SettingsFrame.Visible = false end
				InvokeCallback(callback)
			end)
			return btn
		end

		-- Delete button
		MakeSettingBtn("Delete", Color3.fromRGB(255, 80, 80), function()
			-- Save deleted config data before removing file
			local configData = {}
			for _, entry in ipairs(_registeredElements) do
				local ok, val = pcall(function() return entry.obj:Get() end)
				if ok then
					local s = SerializeValue(val)
					if s ~= nil then configData[entry.key] = s end
				end
			end
			-- Try to read from file if it exists
			local path = GetConfigPath(name)
			if type(readfile) == "function" and type(isfile) == "function" then
				local existsOk, exists = pcall(isfile, path)
				if existsOk and exists then
					local ok2, content = pcall(readfile, path)
					if ok2 and type(content) == "string" and #content <= 2097152 then
						local dok, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), content)
						if dok and type(data) == "table" then configData = data end
					end
					if type(delfile) == "function" then pcall(delfile, path) end
				end
			end
			-- Add to deleted list (max 20 entries)
			table.insert(_deletedConfigs, { name = name, data = configData })
			if #_deletedConfigs > 20 then table.remove(_deletedConfigs, 1) end
			SaveDeletedList()
			-- Deactivate if this was the active row
			if activeRow == row then
				ClearActiveConfig()
			end
			Tween(row, {BackgroundTransparency = 1}, 0.2)
			task.delay(0.22, function() row:Destroy() end)
		end)

		-- Duplicate button
		MakeSettingBtn("Duplicate", Color3.fromRGB(180, 200, 255), function()
			local dupName = name .. " (Copy)"
			local saved = false
			local path = GetConfigPath(name)
			if type(readfile) == "function" and type(isfile) == "function" and type(writefile) == "function" then
				local existsOk, exists = pcall(isfile, path)
				if existsOk then
					if exists then
						local readOk, content = pcall(readfile, path)
						if readOk and type(content) == "string" then
							local writeOk, writeResult = pcall(writefile, GetConfigPath(dupName), content)
							saved = writeOk and writeResult ~= false
						end
					else
						saved = SaveNamedConfig(dupName)
					end
				end
			else
				saved = SaveNamedConfig(dupName)
			end
			if saved then MakeConfigButton(dupName) end
		end)

		-- "..." toggles settings frame
		closeSfRow = function()
			sfOpen = false
			UnregisterPopup(SettingsFrame)
			Tween(SettingsFrame, {Size = UDim2.new(0.44, 0, 0, 0), BackgroundTransparency = 1}, 0.18)
			task.delay(0.19, function() if not sfOpen then SettingsFrame.Visible = false end end)
		end
		SettingsBtn.MouseButton1Click:Connect(function()
			sfOpen = not sfOpen
			if sfOpen then
				CloseAllPopupsExcept(SettingsFrame)
				SettingsFrame.BackgroundTransparency = 1
				SettingsFrame.Visible = true
				SettingsFrame.Size = UDim2.new(0.44, 0, 0, SF_ROW_HEIGHT)
				PositionPopupWithinMain(SettingsFrame, true); RegisterPopup(SettingsFrame, closeSfRow, SettingsBtn)
				Tween(SettingsFrame, {Size = UDim2.new(0.44, 0, 0, SF_ROW_HEIGHT), BackgroundTransparency = 0}, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			else
				closeSfRow()
			end
		end)

		-- Close settings frame when clicking elsewhere on the row
		local RowOverlay = Instance.new("TextButton")
		RowOverlay.Name = "RowOverlay"
		RowOverlay.Size = UDim2.new(0.75, 0, 1, 0) -- covers everything except "..." and load btn
		RowOverlay.BackgroundTransparency = 1
		RowOverlay.Text = ""
		RowOverlay.ZIndex = 2500
		RowOverlay.Parent = row
		RowOverlay.MouseButton1Click:Connect(function()
			if sfOpen then closeSfRow() end
		end)

		-- ── Load / Save button logic ──────────────────────────────
		LoadConfigBtn.MouseButton1Click:Connect(function()
			if activeRow == row then
				-- Already loaded → SAVE
				SaveNamedConfig(name)
				Tween(LoadConfigBtn, {ImageColor3 = Color3.fromRGB(80, 255, 140)}, 0.1)
				task.delay(0.6, function()
					Tween(LoadConfigBtn, {ImageColor3 = mainColor}, 0.3)
				end)
			else
				local loaded = LoadNamedConfig(name)
				if not loaded then
					Tween(LoadConfigBtn, {ImageColor3 = Color3.fromRGB(255, 80, 80)}, 0.2)
					return
				end
				if activeRow and activeLoadBtn then
					DeactivateRow(activeRow, activeLoadBtn)
				end
				activeRow = row
				activeLoadBtn = LoadConfigBtn
				SetActiveConfigName(name)
				Tween(rowStroke, {Transparency = 0, Color = mainColor}, 0.2)
				Tween(row, {BackgroundTransparency = 0.5}, 0.2)
				LoadConfigBtn.Image = SAVE_ICON
				Tween(LoadConfigBtn, {ImageColor3 = mainColor}, 0.2)
			end
		end)

		local query = string.lower(tostring(ConfigSearchBox.Text or "")):gsub("^%s+", ""):gsub("%s+$", "")
		row.Visible = query == "" or string.lower(Rename.Text or ""):find(query, 1, true) ~= nil
		return row
	end

	-- ── Refresh main list ─────────────────────────────────────────
	local function RefreshConfigList()
		ClearActiveConfig()
		for _, c in ipairs(ListContainer:GetChildren()) do
			if c:IsA("Frame") and c.Name ~= "Space" then c:Destroy() end
		end
		local list = ListConfigs()
		for _, n in ipairs(list) do
			MakeConfigButton(n)
		end

	end

	-- ── InsertConfig button ───────────────────────────────────────
	local insertMode = false
	InsertConfigBtn.MouseButton1Click:Connect(function()
		insertMode = not insertMode
		SearchContainer.Visible = not insertMode
		NameInputContainer.Visible = insertMode
		if insertMode then
			Tween(InsertConfigBtn, {ImageColor3 = mainColor}, 0.2)
			task.spawn(function() NameOfConfig:CaptureFocus() end)
		else
			Tween(InsertConfigBtn, {ImageColor3 = Color3.fromRGB(200, 200, 220)}, 0.2)
		end
	end)

	ConfirmAddBtn.MouseButton1Click:Connect(function()
		local n = NameOfConfig.Text
		if n == "" then n = "Config " .. tostring(#ListContainer:GetChildren()) end
		if not SaveNamedConfig(n) then return end
		NameOfConfig.Text = ""
		MakeConfigButton(n)
		insertMode = false
		SearchContainer.Visible = true
		NameInputContainer.Visible = false
		Tween(InsertConfigBtn, {ImageColor3 = Color3.fromRGB(200, 200, 220)}, 0.2)
	end)

	-- ── Search filter ─────────────────────────────────────────────
	ConfigSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = ConfigSearchBox.Text:lower()
		for _, c in ipairs(ListContainer:GetChildren()) do
			if c:IsA("Frame") and c.Name ~= "Space" then
				local rename = c:FindFirstChild("Rename")
				if rename then
					c.Visible = rename.Text:lower():find(query, 1, true) ~= nil
				end
			end
		end
	end)

	-- ── AutoSave toggle ───────────────────────────────────────────
	-- AutoSave: saves the currently loaded config to file on a 30s loop
	-- so settings persist across rejoin. Also saves immediately on enable.
	local function SaveActiveConfig()
		if not autoSaveEnabled then return end
		if not activeRow or not activeLoadBtn then return end
		local n = activeConfigName
		if type(n) ~= "string" or n == "" or n == "Save" then return end
		SaveNamedConfig(n)
	end

	AutoSaveBtn.MouseButton1Click:Connect(function()
		autoSaveEnabled = not autoSaveEnabled
		if autoSaveEnabled then
			Tween(AutoSaveBtn, {ImageColor3 = mainColor}, 0.2)
			-- Immediate save when toggled on
			SaveActiveConfig()
		else
			Tween(AutoSaveBtn, {ImageColor3 = Color3.fromRGB(200, 200, 220)}, 0.2)
		end
	end)

	-- Auto-save loop: periodically saves the active config so it
	-- persists between sessions (load it next time with the Load button)
	if type(writefile) == "function" then
		task.spawn(function()
			while true do
				task.wait(30)
				SaveActiveConfig()
			end
		end)
	end

	-- Also save on character removing (best-effort "on close")
	if LocalPlayer and LocalPlayer.CharacterRemoving then
		LocalPlayer.CharacterRemoving:Connect(function()
			SaveActiveConfig()
		end)
	end

	-- ── Recently Deleted button ───────────────────────────────────
	RecentlyDeletedBtn.MouseButton1Click:Connect(function()
		UnregisterPopup(ConfigMainFrame)
		Tween(ConfigMainFrame, {BackgroundTransparency = 1}, 0.2)
		task.delay(0.22, function()
			if not configOpen then return end
			ConfigMainFrame.Visible = false
			RefreshDeletedList()
			RecentlyDeletedPanel.Visible = true
			RecentlyDeletedPanel.BackgroundTransparency = 1
			ConstrainPopupToMainFrame(RecentlyDeletedPanel); task.defer(function() ConstrainPopupToMainFrame(RecentlyDeletedPanel) end); RegisterPopup(RecentlyDeletedPanel, closeConfigPanel, RecentlyDeletedBtn)
			Tween(RecentlyDeletedPanel, {BackgroundTransparency = 0.01}, 0.2)
		end)
	end)

	closeConfigPanel = function()
		configOpen = false
		ClearActiveConfig()
		ClosePopupsUnder(ConfigMainFrame)
		ClosePopupsUnder(RecentlyDeletedPanel)
		UnregisterPopup(ConfigMainFrame)
		UnregisterPopup(RecentlyDeletedPanel)
		Tween(ConfigMainFrame, {BackgroundTransparency = 1}, 0.2)
		Tween(RecentlyDeletedPanel, {BackgroundTransparency = 1}, 0.2)
		Tween(SaveArrow, {Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.22, function()
			if configOpen then return end
			ConfigMainFrame.Visible = false
			RecentlyDeletedPanel.Visible = false
			ClearActiveConfig()
		end)
	end
	TriggerSaveConfig.MouseButton1Click:Connect(function()
		configOpen = not configOpen
		if configOpen then
			CloseAllPopupsExcept(ConfigMainFrame)
			RecentlyDeletedPanel.Visible = false
			RecentlyDeletedPanel.BackgroundTransparency = 1
			RefreshConfigList()
			ConfigMainFrame.BackgroundTransparency = 1
			ConfigMainFrame.Visible = true
			ConfigMainFrame.ZIndex = 7000
			ApplyZIndexLadder(ConfigMainFrame, 7000)
			ConstrainPopupToMainFrame(ConfigMainFrame); task.defer(function() ConstrainPopupToMainFrame(ConfigMainFrame) end); RegisterPopup(ConfigMainFrame, closeConfigPanel, TriggerSaveConfig)
			Tween(ConfigMainFrame, {BackgroundTransparency = 0.01}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		Tween(SaveArrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		else
			closeConfigPanel()
		end
	end)

	local SearchBox = New("TextBox", {
		Name = "SearchBox",
		Position = UDim2.new(0.44999998807907104, 0, 0.10000000149011612, 0),
		Size = UDim2.new(0, 0, 0.6000000238418579, 0),
		BackgroundColor3 = Color3.fromRGB(16,19,28),
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = Color3.fromRGB(178, 178, 178),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Font = Enum.Font.SourceSansSemibold,
		TextTransparency = 0.10000000149011612,
		Visible = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	}, Header)
	New("UICorner", { CornerRadius = UDim.new(0, 5) }, SearchBox)
	New("UIStroke", {
		Color = Color3.fromRGB(55,65,105),
		Transparency = 0.800000011920929,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, SearchBox)

	-- ApplySearch forward-declared; fully defined after TabHose is created below.
	local ApplySearch

	local searchOpen = false
	SearchBtn.MouseButton1Click:Connect(function()
		searchOpen = not searchOpen
		if searchOpen then
			SearchBox.Visible = true
			SearchBox.BackgroundTransparency = 1
			SearchBox.Size = UDim2.new(0, 0, 0.6000000238418579, 0)
			Tween(SearchBox, { BackgroundTransparency = 0 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Tween(SearchBox, { Size = UDim2.new(0.4000000059604645, 0, 0.6000000238418579, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			task.wait(0.3)
			SearchBox:CaptureFocus()
		else
			Tween(SearchBox, { Size = UDim2.new(0, 0, 0.6000000238418579, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.wait(0.21)
			SearchBox.Visible = false
			SearchBox.Text = ""
			if ApplySearch then ApplySearch("") end
		end
	end)

	local TabHose = New("Frame", {
		Name = "TabHose",
		Position = UDim2.new(0.009999999776482582, 0, 0.092, 0),
		Size = UDim2.new(0.9900000095367432, 0, 0.8960000033378601, 0),
		BackgroundColor3 = Color3.fromRGB(162, 162, 161),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, Frame2)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 13),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, TabHose)

	local function GetSearchText(object)
		local pieces = {}
		if not object then return "" end
		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			table.insert(pieces, object.Text or "")
		end
		local ok, descendants = pcall(function() return object:GetDescendants() end)
		if ok then
			for _, child in ipairs(descendants) do
				if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
					local childName = string.lower(child.Name)
					if childName == "text" or childName == "texttoggle" or childName == "textdefault" or childName == "label" or childName == "textdropdown" then
						table.insert(pieces, child.Text or "")
					end
				end
			end
		end
		return string.lower(table.concat(pieces, " "))
	end

	local function IsSearchColumnActive(column)
		local tabIndex = column:GetAttribute("TabIndex")
		if tabIndex ~= activeTabIndex then return false end
		local tab = tabs[tabIndex]
		if not tab then return false end
		local subTabIndex = column:GetAttribute("SubTabIndex")
		if tab.activeSubTabIndex ~= nil then return subTabIndex == tab.activeSubTabIndex end
		return subTabIndex == nil
	end

	local function _applySearchImpl(query)
		query = string.lower(tostring(query or "")):gsub("^%s+", ""):gsub("%s+$", "")
		local columnHasMatch = false
		for _, column in ipairs(TabHose:GetChildren()) do
			if column:IsA("ScrollingFrame") and (column.Name == "Left" or column.Name == "Right" or string.sub(column.Name, 1, 6) == "STLeft" or string.sub(column.Name, 1, 7) == "STRight") then
				local activeColumn = IsSearchColumnActive(column)
				if not activeColumn then
					column.Visible = false
				else
					local columnMatch = query == ""
					for _, section in ipairs(column:GetChildren()) do
						if section:IsA("Frame") and section.Name == "Section" then
							local elementsFrame = section:FindFirstChild("Elements")
							local sectionLabel = section:FindFirstChild("SectionLabel", true) or section:FindFirstChild("SectionTitle", true)
							local sectionText = sectionLabel and GetSearchText(sectionLabel) or ""
							local sectionMatch = query == "" or sectionText:find(query, 1, true) ~= nil
							local anyVisible = false
							if elementsFrame then
								for _, element in ipairs(elementsFrame:GetChildren()) do
									if element:IsA("GuiObject") then
										local elementText = GetSearchText(element)
										local matches = query == "" or sectionMatch or elementText:find(query, 1, true) ~= nil
										element.Visible = matches
										if matches then anyVisible = true end
									end
								end
								elementsFrame.Visible = anyVisible
							end
							if sectionLabel then sectionLabel.Visible = anyVisible end
							section.Visible = anyVisible
							if anyVisible then columnMatch = true end
						end
					end
					column.Visible = columnMatch
					if columnMatch and query ~= "" then columnHasMatch = true end
				end
			end
		end
		for _, row in ipairs(Tab:GetChildren()) do
			if row.Name == "TabButton" then
				local label = row:FindFirstChild("TabText")
				local matches = query == ""
				if label and label:IsA("TextLabel") then
					matches = query == "" or string.lower(label.Text or ""):find(query, 1, true) ~= nil
				end
				row.Visible = matches
			elseif row.Name == "SubTabContainer" then
				if row:GetAttribute("TabIndex") ~= activeTabIndex then
					row.Visible = false
				else
					local anyVisible = false
					for _, child in ipairs(row:GetChildren()) do
						if child:IsA("Frame") and string.sub(child.Name, 1, 6) == "STRow" then
							local label = child:FindFirstChild("STLabel")
							local matches = query == ""
							if label and label:IsA("TextLabel") then
								matches = query == "" or string.lower(label.Text or ""):find(query, 1, true) ~= nil
							end
							child.Visible = matches
							if matches then anyVisible = true end
						end
					end
					row.Visible = query == "" or anyVisible
				end
			end
		end
		return columnHasMatch
	end

	ApplySearch = _applySearchImpl
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		ApplySearch(SearchBox.Text)
	end)

local Line9 = Instance.new('Frame')
Line9.Name = "Line9"
Line9.Position = UDim2.new(0.010000000707268715,0,0.08799999952316284,0)
Line9.Size = UDim2.new(0.9789999723434448,0,0,1)
Line9.BackgroundColor3 = Color3.fromRGB(162,162,162)
Line9.BackgroundTransparency = 0.93
Line9.BorderSizePixel = 0
Line9.Parent = MainFrame

	local Line4 = Instance.new('Frame')
	Line4.Name = "Line4"
	Line4.Position = UDim2.new(0.00800000037997961,0,0.8999999761581421,0)
	Line4.Size = UDim2.new(0.20900000631809235,0,0,1)
	Line4.BackgroundColor3 = Color3.fromRGB(162,162,162)
	Line4.BackgroundTransparency = 0.93
	Line4.BorderSizePixel = 0
	Line4.Parent = MainFrame

	
	MakeDraggable(MainFrame, DragHandle)

	
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "ToggleBtn"
	ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
   ToggleBtn.BackgroundTransparency = 1
   ToggleBtn.Active = true
   ToggleBtn.Draggable = false
	ToggleBtn.Size = UDim2.new(0, 100, 0, 28)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(16,19,28)
	ToggleBtn.BorderSizePixel = 1
	ToggleBtn.Text = "Close  [RShift]"
	ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleBtn.TextScaled = true
	ToggleBtn.Font = Enum.Font.SourceSansSemibold
	ToggleBtn.ZIndex = 999
	ToggleBtn.Parent = NeverloseCS2
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = ToggleBtn end
	
-- rounded open button: no square drop-shadow image



	local function HideWindowInstantly()
		HideAllPopupsNow(true)
		if ConfigMainFrame then ConfigMainFrame.Visible = false end
		if WindowSettingsFrame then WindowSettingsFrame.Visible = false end
		if Save then Save.Visible = false end
		if RecentlyDeletedPanel then RecentlyDeletedPanel.Visible = false end
		if AcrylicBlur and AcrylicBlur.Instances and AcrylicBlur.Instances.Part then
			AcrylicBlur.Instances.Part.Transparency = 1
		end
		if AcrylicBlur and AcrylicBlur.Instances and AcrylicBlur.Instances.DepthOfField then
			AcrylicBlur.Instances.DepthOfField.Enabled = false
		end
		MainFrame.BackgroundTransparency = 1
		MainFrame.Visible = false
	end

	local guiOpen = true
	local function toggleGui()
    guiOpen = not guiOpen
    if not guiOpen then
		HideWindowInstantly()
	end
    ToggleBtn.Text = guiOpen and "Close [RShift]" or "Open  [RShift]"
    Tween(ToggleBtn, {
        BackgroundColor3 = guiOpen and Color3.fromRGB(16,19,28) or Color3.fromRGB(33,37,53)
    }, 0.1)
    	if guiOpen then
        if Save then Save.Visible = true end
        MainFrame.BackgroundTransparency = 1
        MainFrame.Visible = true
        AcrylicBlur.Instances.Part.Transparency = 1
        if AcrylicBlur.Instances.DepthOfField then AcrylicBlur.Instances.DepthOfField.Enabled = true end
        if AcrylicBlur.Signal then pcall(function() AcrylicBlur.Signal:Disconnect() end); AcrylicBlur.Signal = nil end
        AcrylicBlur.Signal = game:GetService("RunService").RenderStepped:Connect(AcrylicBlur.Update)
        Tween(MainFrame, { BackgroundTransparency = 0.1 }, 0.18)
        Tween(AcrylicBlur.Instances.Part, { Transparency = AcrylicBlur.Instances.Part:GetAttribute("TargetTransparency") or 0.8 }, 0.18)
    else
        if AcrylicBlur.Signal then
            AcrylicBlur.Signal:Disconnect()
            AcrylicBlur.Signal = nil
        end
        -- everything (text, logo, cards, popups, acrylic) disappears in one frame
        HideWindowInstantly()
    end
end

	ToggleBtn.MouseButton1Click:Connect(toggleGui)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if menuBind and input.KeyCode == menuBind then
			toggleGui()
		end
	end)

	MainFrame.BackgroundTransparency = 1
	Tween(MainFrame, { BackgroundTransparency = 0.1 }, 0.18)



	function WindowObj:AddTabLabel(text)
		text = tostring(text or "")
		tabOrder = tabOrder + 1
		local lbl = New("TextLabel", {
			Name = "TabLabel",
			Size = UDim2.new(0.800000011920929, 0, 0, 22),
			BackgroundColor3 = Color3.fromRGB(162, 162, 162),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = Color3.fromRGB(112, 118, 145),
			TextScaled = false,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
         TextTransparency = 0.35,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = tabOrder,
		}, Tab)
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 14),
			PaddingBottom = UDim.new(0, 6),
		}, lbl)
		return lbl
	end

	function WindowObj:AddTab(name, icon)
		name = tostring(name or "Tab")
		if icon ~= nil and type(icon) ~= "string" then icon = "" end
		tabOrder = tabOrder + 1
		local tabIndex = #tabs + 1
		local isFirst = tabIndex == 1

		local TabButtonFrame = New("Frame", {
			Name = "TabButton",
			Size = UDim2.new(1, 0, 0.028999999165534973, 0),
			BackgroundColor3 = isFirst and Color3.fromRGB(255,255,255) or Color3.fromRGB(25,28,42),
			BackgroundTransparency = isFirst and 0.9 or 1,
			LayoutOrder = tabOrder,
		}, Tab)
		New("UICorner", { CornerRadius = UDim.new(0, 5) }, TabButtonFrame)
		New("UIAspectRatioConstraint", {
			AspectRatio = 5,
			AspectType = Enum.AspectType.ScaleWithParentSize,
		}, TabButtonFrame)
		local TabScale = New("UIScale", { Scale = 1 }, TabButtonFrame)

		local TabIcon = New("ImageLabel", {
			Name = "TabIcon",
			Position = UDim2.new(0.1,0,0.5,0),
         AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.20000000298023224, 0, 0.6500000011920929, 0),
			BackgroundColor3 = Color3.fromRGB(255, 191, 255),
			BackgroundTransparency = 1,
			Image = "",
			ImageColor3 = isFirst and mainColor or Color3.fromRGB(255, 255, 255),
			ImageTransparency = isFirst and 0 or 0.6,
		}, TabButtonFrame)
		if icon and icon ~= "" then
			GetImageData(icon, TabIcon)
		end
		table.insert(_coloredElements, { type = "tabicon", ref = TabIcon })
New("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}, TabIcon)

		local TabText = New("TextLabel", {
			Name = "TabText",
			Position = UDim2.new(0.23000000417232513, 0, 0.235, 0),
			Size = UDim2.new(0.7070000171661377, 0, 0.510000011920929, 0),
			BackgroundColor3 = Color3.fromRGB(191, 255, 255),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.SourceSansSemibold,
			TextTransparency = isFirst and 0 or 0.6000000238418579,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, TabButtonFrame)

		local ClickArea = New("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 5,
		}, TabButtonFrame)

		local Left = New("ScrollingFrame", {
			Name = "Left",
			Size = UDim2.new(0.47999998927116394, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(162, 162, 162),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
		}, TabHose)
		
		local Right = New("ScrollingFrame", {
			Name = "Right",
			Size = UDim2.new(0.47999998927116394, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(162, 162, 162),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ClipsDescendants = true,
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
		}, TabHose)
		Left:SetAttribute("SearchName", name)
		Right:SetAttribute("SearchName", name)
		Left:SetAttribute("TabIndex", tabIndex)
		Right:SetAttribute("TabIndex", tabIndex)
		New("UIListLayout", { Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder }, Left)
New("UIListLayout", { Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder }, Right)

		if not isFirst then
			Left.Visible = false
			Right.Visible = false
		end

		local function HideContent()
			for _, column in ipairs({Left, Right}) do
				local list = column:FindFirstChildOfClass("UIListLayout")
				local items = column:GetChildren()
				for _, item in ipairs(items) do
					if item:IsA("GuiObject") then
						local texts = {}
						for _, d in ipairs(item:GetDescendants()) do
							if d:IsA("TextLabel") or d:IsA("TextButton") then table.insert(texts, d) end
						end
						for _, t in ipairs(texts) do Tween(t, {TextTransparency = 1}, 0.12) end
					end
				end
			end
			Left.Visible = false
			Right.Visible = false
		end

		local function ShowContent()
			Left.Position = UDim2.new(0, 0, 0, 0)
			Right.Position = UDim2.new(0, 0, 0, 0)
			Left.Visible = true
			Right.Visible = true
			for _, column in ipairs({Left, Right}) do
				for _, section in ipairs(column:GetChildren()) do
					if section:IsA("GuiObject") then
						section.BackgroundTransparency = 1
						Tween(section, {BackgroundTransparency = section.Name == "Section" and 1 or 0}, 0.28, Enum.EasingStyle.Quad)
						local list = section:FindFirstChild("Elements") or section:FindFirstChild("Container")
						if list and list:IsA("GuiObject") then
							list.BackgroundTransparency = 1
							Tween(list, {BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Quad)
							local order = 0
							for _, item in ipairs(list:GetChildren()) do
								if item:IsA("GuiObject") then
									order = order + 1
									local texts = {}
									for _, d in ipairs(item:GetDescendants()) do
										if d:IsA("TextLabel") or d:IsA("TextButton") then table.insert(texts, d) end
									end
									for _, t in ipairs(texts) do t.TextTransparency = 1 end
									local delay = math.min((order - 1) * 0.03, 0.25)
									task.delay(delay, function()
										for _, t in ipairs(texts) do
											if t.Parent then Tween(t, {TextTransparency = t.Name == "TextDefault" and 0.5 or 0}, 0.2) end
										end
									end)
								end
							end
						end
					end
				end
			end

		end

		local function ActivateTab()
			CloseAllPopupsExcept(nil)
			for _, t in ipairs(tabs) do
				t.btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				t.btn.BackgroundTransparency = 1
				t.icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				t.icon.ImageTransparency = 0.6
				t.txt.TextTransparency = 0.6
				t.hide()
			end
			TabButtonFrame.BackgroundColor3 = Color3.fromRGB(255,255,255)
			TabButtonFrame.BackgroundTransparency = 0.9
			TabIcon.ImageColor3 = mainColor
			TabIcon.ImageTransparency = 0
			TabText.TextTransparency = 0
			TabScale.Scale = 0.86
			Tween(TabScale, { Scale = 1 }, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			ShowContent()
			activeTabIndex = tabIndex
			if ApplySearch then task.defer(function() ApplySearch(SearchBox.Text) end) end
		end

		ClickArea.MouseButton1Click:Connect(ActivateTab)

		table.insert(tabs, {
			btn = TabButtonFrame,
			icon = TabIcon,
			txt = TabText,
			hide = HideContent,
			show = ShowContent,
			tabIndex = tabIndex,
			name = name,
			activeSubTabIndex = nil,
		})

		if isFirst then activeTabIndex = 1 end

		local TabObj = {}
		local sectionOrder = { left = 0, right = 0 }

		function TabObj:AddSection(title, side)
			title = tostring(title or "Section")
			side = side == "right" and "right" or "left"
			sectionOrder[side] = sectionOrder[side] + 1
			local col = side == "right" and Right or Left

			local Section = New("Frame", {
				Name = "Section",
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(162, 162, 162),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = sectionOrder[side],
			}, col)
			New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Section)

local SectionTitle = Instance.new('Frame')
SectionTitle.Name = "SectionTitle"
SectionTitle.Size = UDim2.new(1,0,0.030,0)
SectionTitle.BackgroundTransparency = 1
SectionTitle.ClipsDescendants = false
SectionTitle.Visible = true
SectionTitle.Parent = Section

local SectionLabel = Instance.new('TextLabel')
SectionLabel.Name = "SectionLabel"
SectionLabel.Position = UDim2.new(0,0,0,0)
SectionLabel.Size = UDim2.new(1,0,1,0)
SectionLabel.Visible = true
SectionLabel.ClipsDescendants = false
SectionLabel.BackgroundColor3 = Color3.fromRGB(162,162,162)
SectionLabel.BackgroundTransparency = 1
SectionLabel.BorderSizePixel = 0
SectionLabel.Text = title
SectionLabel.TextColor3 = customization.sectionTitleColor or Color3.fromRGB(112, 118, 145)
SectionLabel.TextScaled = customization.sectionTitleTextSize == nil
SectionLabel.TextSize = customization.sectionTitleTextSize or 12
SectionLabel.Font = customization.font or Enum.Font.GothamBold
SectionLabel.TextTransparency = customization.sectionTitleTransparency or 0.35
SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
SectionLabel.Parent = SectionTitle
AddTextConstraint(SectionLabel, 9, 12, true)


			local Elements = New("Frame", {
				Name = "Elements",
				-- inset by 1px: the column clips, a flush border loses half its width
				Size = UDim2.new(1, -2, 0, 30),
				Position = UDim2.new(0, 1, 0, 0),
				BackgroundColor3 = Color3.fromRGB(21,24,36),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
			}, Section)
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Elements end
			do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(44,50,72); s.Transparency = 0.45; s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = Elements end
			New("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, Elements)
			WatchRowDividers(Elements)


			local SectionObj = {}
			local elemCount = 0
			local _openDropdown = nil
			local _openAccordion = nil
			local _openAccordionDropdown = nil
			local settingsCache = {}
			local BindElementContext

			local function MakeSettings(parentFrame, elementType, label)
				if settingsCache[parentFrame] then return settingsCache[parentFrame] end
				label = tostring(label or "")
				local settingsOpen = false
				local settingsLayoutConnection = nil

				local SettingsBtn = New("Frame", {
					Name = "SettingsGear",
					Position = UDim2.new(0.72, 0, 0.18, 0),
					Size = UDim2.new(0.07, 0, 0.64, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					ZIndex = 2000,
				}, parentFrame)

				for i = 0, 2 do
					New("Frame", {
						Name = "Dot" .. tostring(i + 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, (i - 1) * 5, 0.5, 0),
						Size = UDim2.new(0, 3, 0, 3),
						BackgroundColor3 = Color3.fromRGB(205, 212, 226),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 2001,
					}, SettingsBtn)
				end

				local SettingsHit = New("TextButton", {
					Name = "SettingsHit",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 2002,
				}, SettingsBtn)
				for _, dot in ipairs(SettingsBtn:GetChildren()) do
					if dot:IsA("GuiObject") and string.sub(dot.Name, 1, 3) == "Dot" then
						dot.BackgroundTransparency = 1
					end
				end
				local function SetDotsTransparency(value)
					for _, dot in ipairs(SettingsBtn:GetChildren()) do
						if dot:IsA("GuiObject") and string.sub(dot.Name, 1, 3) == "Dot" then
							Tween(dot, { BackgroundTransparency = value }, 0.15)
						end
					end
				end
				SettingsHit.MouseEnter:Connect(function() SetDotsTransparency(0) end)
				SettingsHit.MouseLeave:Connect(function() SetDotsTransparency(0.45) end)
				SetDotsTransparency(0.45)

				local SettingsFrame = Instance.new('Frame')
				SettingsFrame.Name = "SettingsFrame"
				SettingsFrame.Position = UDim2.new(0.02, 0, 1, 2)
				SettingsFrame.Size = UDim2.new(0.96, 0, 0, 0)
				SettingsFrame.BackgroundColor3 = Color3.fromRGB(21, 24, 36)
				SettingsFrame.BackgroundTransparency = 0
				SettingsFrame.BorderSizePixel = 0
				SettingsFrame.Visible = false
				SettingsFrame.ZIndex = 5000
				SettingsFrame.AutomaticSize = Enum.AutomaticSize.None
				SettingsFrame.ClipsDescendants = false
				local SFScale = New("UIScale", { Scale = 1 }, SettingsFrame)

				SettingsFrame.Parent = parentFrame

				local UICorner = Instance.new('UICorner')
				UICorner.Name = "UICorner"
				UICorner.CornerRadius = UDim.new(0, 14)
				UICorner.Parent = SettingsFrame

				local UIStroke = Instance.new('UIStroke')
				UIStroke.Name = "UIStroke"
				UIStroke.Color = Color3.fromRGB(44, 50, 72)
				UIStroke.Transparency = 0.25
				UIStroke.Thickness = 1
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = SettingsFrame

				local SFContainer = Instance.new('ScrollingFrame')
				SFContainer.Name = "Container"
				SFContainer.AnchorPoint = Vector2.new(0, 0)
				SFContainer.Position = UDim2.new(0.04, 0, 0, 3 / GetMainFrameScale())
				SFContainer.Size = UDim2.new(0.92, 0, 1, -6 / GetMainFrameScale())
				SFContainer.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
				SFContainer.BackgroundTransparency = 1
				SFContainer.LayoutOrder = 1
				SFContainer.ZIndex = 5001
				SFContainer.Active = true
				SFContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
				SFContainer.CanvasSize = UDim2.new()
				SFContainer.ScrollingEnabled = false
				SFContainer.ScrollingDirection = Enum.ScrollingDirection.Y
				SFContainer.ScrollBarThickness = 0
				SFContainer.ScrollBarImageTransparency = 1
				SFContainer.ClipsDescendants = false
				SFContainer.Parent = SettingsFrame

				local SFLayout = Instance.new('UIListLayout')
				SFLayout.Name = "UIListLayout"
				SFLayout.Padding = UDim.new(0, 3)
				SFLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SFLayout.Parent = SFContainer
				WatchRowDividers(SFContainer)

				do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = SFContainer end

				local function UpdateSettingsLayout()
					local scale = GetMainFrameScale()
					SFContainer.Position = UDim2.new(0.04, 0, 0, 3 / scale)
					SFContainer.Size = UDim2.new(0.92, 0, 1, -6 / scale)
				end

				local function GetSettingsContentHeight()
					local measured = MeasureRowsHeight(SFContainer)
					if measured > 0 then return measured end
					local rowCount = 0
					for _, child in ipairs(SFContainer:GetChildren()) do
						if child:IsA("GuiObject") then rowCount = rowCount + 1 end
					end
					if rowCount <= 0 then return 0 end
					local estimated = EstimateRowsHeight(SFContainer, rowCount, 7.5)
					if estimated > 0 then return estimated end
					return rowCount * 28 * GetMainFrameScale()
				end

				local function getSettingsHeight()
					UpdateSettingsLayout()
					local scale = GetMainFrameScale()
					local contentVisual = GetSettingsContentHeight()
					-- the panel grows to fit every row, even past the window edge
					local desiredVisual = math.max(34 * scale, contentVisual + 14 * scale)
					return desiredVisual / scale
				end

				local function placeSettings(height)
					local scale = GetMainFrameScale()
					UpdateSettingsLayout()
					local mainSize = MainFrame.AbsoluteSize
					local mainPosition = MainFrame.AbsolutePosition
					local minHeight = 30
					local width = 0.96
					local edge = 5 * scale
					height = math.max(minHeight, type(height) == "number" and height == height and height or minHeight)
					local parentPosition = parentFrame.AbsolutePosition
					local parentSize = parentFrame.AbsoluteSize
					if mainSize.X <= 0 or mainSize.Y <= 0 or parentSize.X <= 0 or parentSize.Y <= 0 then return end
					local visualHeight = height * scale

					local mainLeft = mainPosition.X
					local mainRight = mainPosition.X + mainSize.X
					local mainTop = mainPosition.Y
					local mainBottom = mainPosition.Y + mainSize.Y

					local panelWidth = parentSize.X * width
					local leftX = parentPosition.X + (1 - width) * parentSize.X
					leftX = math.clamp(leftX, mainLeft + edge, math.max(mainLeft + edge, mainRight - panelWidth - edge))

					local belowY = parentPosition.Y + parentSize.Y + edge
					local aboveY = parentPosition.Y - visualHeight - edge
					local y
					if belowY + visualHeight <= mainBottom - edge then
						y = belowY
					elseif aboveY >= mainTop + edge then
						y = aboveY
					else
						-- neither side fits: keep the requested height and align to the top
						y = mainTop + edge
					end

					SettingsFrame.Position = UDim2.new((leftX - parentPosition.X) / parentSize.X, 0, 0, (y - parentPosition.Y) / scale)
					SettingsFrame.Size = UDim2.new(width, 0, 0, height)
					task.defer(function()
						if SettingsFrame.Parent and SettingsFrame.Visible and visualHeight <= mainSize.Y then
							ConstrainPopupToMainFrame(SettingsFrame)
						end
					end)
				end

				local function closeSF()
					settingsOpen = false
					ClosePopupsUnder(SettingsFrame)
					UnregisterPopup(SettingsFrame)
					Tween(SettingsFrame, {Size = UDim2.new(0.96, 0, 0, 0), BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					task.delay(0.21, function() if not settingsOpen then SettingsFrame.Visible = false end end)
				end
				local SettingsObj = {}
				SettingsHit.MouseButton1Click:Connect(function()
					if settingsOpen then closeSF() else SettingsObj:Open() end
				end)

				local settingsElemCount = 0
				local SettingsFrame_Container = SFContainer

				function SettingsObj:Open()
					if settingsOpen then return self end
					settingsOpen = true
					CloseAllPopupsExcept(SettingsFrame)
					SettingsFrame.Visible = true
					SettingsFrame.BackgroundTransparency = 1
					SFScale.Scale = 0.94
					ApplyZIndexLadder(SettingsFrame, 5000)
					placeSettings(getSettingsHeight())
					RegisterPopup(SettingsFrame, closeSF, SettingsBtn)
					local function settle()
						if not settingsOpen or not SettingsFrame.Parent then return end
						placeSettings(getSettingsHeight())
						Tween(SettingsFrame, {BackgroundTransparency = 0}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						Tween(SFScale, {Scale = 1}, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					end
					task.defer(settle)
					task.delay(0.05, settle)
					if not settingsLayoutConnection then
						local okLayout, layout = pcall(function() return SFContainer:FindFirstChildOfClass("UIListLayout") end)
						if okLayout and layout then
							pcall(function()
								settingsLayoutConnection = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
									if settingsOpen then task.defer(function() if settingsOpen then placeSettings(getSettingsHeight()) end end) end
								end)
							end)
						end
					end
					return self
				end

				function SettingsObj:Close()
					if settingsOpen then closeSF() end
					return self
				end

				function SettingsObj:AddToggle(text, default, callback)
					settingsElemCount = settingsElemCount + 1
					local enabled = default == true

					local Toggle = New("Frame", {
						Name = "Toggle",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
					}, SettingsFrame_Container)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 7.5
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = Toggle

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.88, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						ZIndex = 1000,
						BorderSizePixel = 0,
					}, Toggle)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Toggle)

					local Effect = New("Frame", {
						Name = "Effect",
						Position = UDim2.new(0.8400000143051147, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.11035999655723572, 0, 0.5600000023841858, 0),
						BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0),
						ZIndex = 1001,
					}, Toggle)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
					New("UIStroke", { Transparency = 0.800000011920929, Thickness = 0.800000011920929 }, Effect)

					local Icon = New("Frame", {
						Name = "Icon",
						Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0),
						Size = UDim2.new(1, 0, 0.8999999761581421, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = enabled and 0 or 0.5,
						ZIndex = 1002,
					}, Effect)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Icon)
					New("UIAspectRatioConstraint", {}, Icon)

					local Btn = New("TextButton", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 1010,
					}, Toggle)

					local function Set(val)
						enabled = val == true
						Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0) }, 0.25, Enum.EasingStyle.Quad)
						Tween(Icon, { Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0), BackgroundTransparency = enabled and 0 or 0.5 }, 0.25, Enum.EasingStyle.Back)
						InvokeCallback(callback, enabled)
					end

					Btn.MouseButton1Click:Connect(function() Set(not enabled) end)

					local obj = {}
					function obj:Set(v) Set(v) end
					function obj:Get() return enabled end
					RegisterConfigElement("settings_toggle_", text, obj)
					return obj
				end

				function SettingsObj:AddCheckbox(text, default, callback)
					settingsElemCount = settingsElemCount + 1
					local enabled = default == true

					local CheckBoxToggle = New("Frame", {
						Name = "CheckBoxToggle",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
					}, SettingsFrame_Container)
					New("UIAspectRatioConstraint", {
						AspectRatio = 7.5,
						AspectType = Enum.AspectType.ScaleWithParentSize,
					}, CheckBoxToggle)

					

					local CheckBox = New("Frame", {
						Name = "CheckBox",
						Position = UDim2.new(0.04, 0, 0.3, 0),
						Size = UDim2.new(0.075, 0, 0.7, 0),
						BackgroundTransparency = 1,
						ZIndex = 1001,
					}, CheckBoxToggle)
					New("UICorner", {}, CheckBox)
					New("UIAspectRatioConstraint", {}, CheckBox)

					local Check = New("ImageLabel", {
						Name = "Check",
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Image = "rbxassetid://138494545053627",
						ImageTransparency = enabled and 0.1 or 1,
						ZIndex = 1001,
					}, CheckBox)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.15, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, CheckBoxToggle)

					local Btn = New("TextButton", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 1010,
					}, CheckBoxToggle)

					local function Set(val)
						enabled = val == true
						Tween(Check, { ImageTransparency = enabled and 0.1 or 1 }, 0.2)
						InvokeCallback(callback, enabled)
					end

					Btn.MouseButton1Click:Connect(function() Set(not enabled) end)

					local obj = {}
					function obj:Set(v) Set(v) end
					function obj:Get() return enabled end
					RegisterConfigElement("settings_checkbox_", text, obj)
					return obj
				end

				function SettingsObj:AddSlider(text, min, max, default, callback, suffix)
					settingsElemCount = settingsElemCount + 1
					if type(suffix) ~= "string" then suffix = "" end
					local value
					min, max, value = NormalizeRange(min, max, default)
					value = Quantize(value, min, max, GetSliderStep(min, max))
					local initRatio = (value - min) / (max - min)
					local dragging = false

					local Slider = New("Frame", {
						Name = "Slider",
						Size = UDim2.new(1, 0, 0, 0),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
						ZIndex = 1000,
					}, SettingsFrame_Container)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 7.5
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = Slider

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.88, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						ZIndex = 1002,
						BorderSizePixel = 0,
					}, Slider)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Slider)

					local Effect = New("Frame", {
						Name = "Effect",
						Position = UDim2.new(0.4980000042915344, 0, 0.25, 0),
						Size = UDim2.new(0.5, 0, 0.6990000009536743, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						ZIndex = 1001,
					}, Slider)

					local SliderValue = New("TextLabel", {
						Name = "SliderValue",
						Position = UDim2.new(0.6990000009536743, 0, 0.10000000149011612, 0),
						Size = UDim2.new(0.25, 0, 0.8080000281333923, 0),
						BackgroundColor3 = Color3.fromRGB(33,37,53),
						Text = FormatSliderValue(value, suffix),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.20000000298023224,
						ZIndex = 1002,
					}, Effect)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, SliderValue)

					local Line = New("Frame", {
						Name = "Line",
						Active = true,
						Position = UDim2.new(0.03999999910593033, 0, 0.3190000057220459, 0),
						Size = UDim2.new(0.6000000238418579, 0, 0.24, 0),
						BackgroundColor3 = Color3.fromRGB(33,37,53),
						ZIndex = 1001,
					}, Effect)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Line)

					local InLine = New("Frame", {
						Name = "InLine",
						Size = UDim2.new(0, 0, 1, 0),
						BackgroundColor3 = mainColor,
						ZIndex = 1002,
					}, Line)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, InLine)

					local Trigger = New("TextButton", {
						Name = "Trigger",
						Position = UDim2.new(0.10000000149011612, 0, -1.8000000715255737, 0),
						Size = UDim2.new(1.1999999284744263, 0, 4.200000286102295, 0),
						AnchorPoint = Vector2.new(0.800000011920929, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						Active = false,
						Text = "",
						ZIndex = 1003,
					}, Line)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Trigger)
					New("UIAspectRatioConstraint", {}, Trigger)

					local initialValue = value
					task.defer(function()
						if value ~= initialValue then return end
						InLine.Size = UDim2.fromScale(initRatio, 1)
						Trigger.Position = UDim2.new(initRatio, 0, -1.8000000715255737, 0)
					end)

					local function update(input)
						local pointer = GetInputPosition(input)
						local lineSize = Line.AbsoluteSize.X
						if lineSize <= 0 then return end
						local sizeScale = ClampRatio(pointer.X - Line.AbsolutePosition.X, lineSize)
						value = Quantize(((max - min) * sizeScale) + min, min, max, GetSliderStep(min, max))
						Tween(InLine, { Size = UDim2.fromScale(sizeScale, 1) }, 0.1)
						Trigger.Position = UDim2.new(sizeScale, 0, -1.8000000715255737, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						InvokeCallback(callback, value)
					end

					Line.InputBegan:Connect(function(input)
						if IsPrimaryInput(input) then
							dragging = true; update(input)
						end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if IsPrimaryInput(input) then
							dragging = false
						end
					end)
					UserInputService.InputChanged:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							update(input)
						end
					end)

					local obj = {}
					function obj:Set(val)
						local numeric = type(val) == "number" and val == val and val or min
						value = math.clamp(numeric, min, max)
						value = Quantize(value, min, max, GetSliderStep(min, max))
					local ratio = (value - min) / (max - min)
						InLine.Size = UDim2.fromScale(ratio, 1)
						Trigger.Position = UDim2.new(ratio, 0, -1.8000000715255737, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						InvokeCallback(callback, value)
					end
					function obj:Get() return value end
					RegisterConfigElement("settings_slider_", text, obj)
					return obj
				end

				function SettingsObj:AddDropdown(text, options, default, callback)
					if type(default) == "function" then callback = default; default = nil end
					options = NormalizeOptions(options)
					settingsElemCount = settingsElemCount + 1
					local selected = GetValidOption(options, default)
					local dropOpen = false
					local selectedBtns = {}

					local Selection = New("Frame", {
						Name = "Selection",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
						ClipsDescendants = false,
						ZIndex = 1000,
					}, SettingsFrame_Container)
					New("UIAspectRatioConstraint", {
						AspectRatio = 7.5,
						AspectType = Enum.AspectType.ScaleWithParentSize,
					}, Selection)

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.05000000074505806, 0, 1, 0),
						Size = UDim2.new(0.8999999761581421, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						ZIndex = 1000,
					}, Selection)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000041723251, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.6000000238418579, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Selection)

					local SelArrow = New("ImageLabel", {
						Name = "TextArrow",
						Position = UDim2.new(0.8700000047683716, 0, 0.15000000596046448, 0),
						Size = UDim2.new(0.10000000149011612, 0, 0.800000011920929, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Image = "rbxassetid://10709790948",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						ImageTransparency = 0.10000000149011612,
						ScaleType = Enum.ScaleType.Fit,
						Rotation = 270,
						ZIndex = 1000,
					}, Selection)

					local TextDefault = New("TextLabel", {
						Name = "TextDefault",
						Position = UDim2.new(0.6400001645088196, 0, 0.2499999850988388, 0),
						Size = UDim2.new(0.23000000417232513, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = options[1] or "Auto",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.5,
						ZIndex = 1001,
						TextXAlignment = Enum.TextXAlignment.Right,
					}, Selection)

					local DropPopup = New("Frame", {
						Name = "Dropdown",
						Position = UDim2.new(0.02,0,1,2),
						Size = UDim2.new(0.6899999737739563, 0, 0, 100),
						BackgroundColor3 = Color3.fromRGB(16,19,28),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 5000,
					}, Selection)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, DropPopup)
					New("UIStroke", {
						Color = Color3.fromRGB(28,32,48),
						Transparency = 0.800000011920929,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}, DropPopup)

					local DropContainer = New("ScrollingFrame", {
						Name = "Container",
						Position = UDim2.new(0.05000000074505806, 0, 0.10000000149011612, 0),
						Size = UDim2.new(0.8980000019073486, 0, 0, 96),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						ZIndex = 5000,
						Active = true,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(),
						ScrollingDirection = Enum.ScrollingDirection.Y,
						ScrollBarThickness = 2,
						ScrollBarImageTransparency = 0.5,
					}, DropPopup)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, DropContainer)
					New("UIStroke", {
						Color = Color3.fromRGB(28,32,48),
						Transparency = 0.800000011920929,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}, DropContainer)
					New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, DropContainer)

					local function closeDropdown()
						dropOpen = false
						Tween(SelArrow, {Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						UnregisterPopup(DropPopup)
						SmoothClose(DropPopup, 0.18)
					end

					local function updateCheckmarks()
						for opt, selBtn in pairs(selectedBtns) do
							if opt == selected then
								selBtn.Text = "✓"
								Tween(selBtn, { TextColor3 = mainColor }, 0.15)
							else
								selBtn.Text = ""
							end
						end
					end

					for i, opt in ipairs(options) do
						local BtnRow = New("Frame", {
							Name = "Buttons",
							Size = UDim2.new(1, 0, 0, 0),
							BackgroundColor3 = Color3.fromRGB(162, 162, 162),
							BackgroundTransparency = 1,
							ZIndex = 5001,
							LayoutOrder = i,
						}, DropContainer)
						New("UIAspectRatioConstraint", {
							AspectRatio = 6,
							AspectType = Enum.AspectType.ScaleWithParentSize,
						}, BtnRow)

						New("TextLabel", {
							Name = "Label",
							Position = UDim2.new(0, 0, 0.20000000298023224, 0),
							Size = UDim2.new(1, 0, 0.6990000009536743, 0),
							BackgroundColor3 = Color3.fromRGB(162, 162, 162),
							BackgroundTransparency = 1,
							Text = opt,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextScaled = true,
							Font = Enum.Font.SourceSansSemibold,
							TextTransparency = 0.10000000149011612,
							ZIndex = 5002,
							TextXAlignment = Enum.TextXAlignment.Left,
						}, BtnRow)

						local SelBtn = New("TextButton", {
							Name = "Selected",
							Position = UDim2.new(0.800000011920929, 0, 0, 0),
							Size = UDim2.new(0.20000000298023224, 0, 0.800000011920929, 0),
							BackgroundColor3 = Color3.fromRGB(16,19,28),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = "",
							TextColor3 = Color3.fromRGB(26, 123, 255),
							TextScaled = true,
							ZIndex = 5004,
						}, BtnRow)
						New("UICorner", { CornerRadius = UDim.new(0, 5) }, SelBtn)
						selectedBtns[opt] = SelBtn

						local RowBtn = New("TextButton", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Text = "",
							ZIndex = 5005,
						}, BtnRow)
						RowBtn.MouseButton1Click:Connect(function()
							selected = opt; SetTrimmedText(TextDefault, opt); FitTextBeforeArrow(TextDefault, SelArrow); updateCheckmarks(); closeDropdown()
							InvokeCallback(callback, opt)
						end)
						SelBtn.MouseButton1Click:Connect(function()
							selected = opt; SetTrimmedText(TextDefault, opt); FitTextBeforeArrow(TextDefault, SelArrow); updateCheckmarks(); closeDropdown()
							InvokeCallback(callback, opt)
						end)
					end

					local OpenBtn = New("TextButton", {
						Name = "OpenBtn",
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 1500,
					}, Selection)
					OpenBtn.MouseButton1Click:Connect(function()
						if dropOpen then closeDropdown()
						else
							CloseAllPopupsExcept(DropPopup)
							dropOpen = true
							local knownH = math.max(24, math.min(100, math.max(MainFrame.AbsoluteSize.Y, 1)))
							local knownW = math.max(Selection.AbsoluteSize.X * 0.96, 1)
							DropPopup.Size = UDim2.new(0.96, 0, 0, knownH)
							PositionPopupWithinMain(DropPopup, true, nil, nil, Vector2.new(knownW, knownH))
							SmoothOpen(DropPopup, 0, 0.2)
							Tween(SelArrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
							RegisterPopup(DropPopup, closeDropdown, OpenBtn)
						end
					end)

					SetTrimmedText(TextDefault, selected); FitTextBeforeArrow(TextDefault, SelArrow)
					updateCheckmarks()

					local obj = {}
					function obj:Set(val, silent) val = GetValidOption(options, val); selected = val; SetTrimmedText(TextDefault, val); FitTextBeforeArrow(TextDefault, SelArrow); updateCheckmarks(); if not silent then InvokeCallback(callback, val) end end
					function obj:Get() return selected end
					RegisterConfigElement("settings_dropdown_", text, obj)
					return obj
				end

				function SettingsObj:AddColorpicker(text, defaultColor, callback)
					settingsElemCount = settingsElemCount + 1
					local hue, sat, val = Color3.toHSV(NormalizeColor(defaultColor))
					local color = { hue, sat, val }
					local pickerOpen = false
					local WheelDown = false
					local SlideDown = false

					local Colorpicker = New("Frame", {
						Name = "Colorpicker",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						LayoutOrder = settingsElemCount,
						ClipsDescendants = false,
						ZIndex = 1000,
					}, SettingsFrame_Container)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 7.5
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = Colorpicker

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.89, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						ZIndex = 1001,
					}, Colorpicker)

					local colorpickerLabel = New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.048, 0, 0.3, 0),
						Size = UDim2.new(0.66, 0, 0.6, 0),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansBold,
						TextTransparency = 0.1,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Colorpicker)

					local colorpickerButton = New("ImageButton", {
						Name = "colorpickerButton",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.875, 0, 0.57, 0),
						Size = UDim2.new(0.08, 0, 0.5, 0),
						BackgroundColor3 = NormalizeColor(defaultColor),
						BorderSizePixel = 0,
						Image = "",
						ZIndex = 1010,
					}, Colorpicker)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, colorpickerButton)

					local colorpickerFrame = New("Frame", {
						Name = "colorpickerFrame",
						Position = UDim2.new(0.02,0,1,2),
						Size = UDim2.new(0.96, 0, 7, 0),
						BackgroundColor3 = Color3.fromRGB(15,17,26),
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 1350,
						ClipsDescendants = false,
					}, Colorpicker)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, colorpickerFrame)
					New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1 }, colorpickerFrame)
					New("UIAspectRatioConstraint", { AspectRatio = 1.1 }, colorpickerFrame)
					FitColorPickerPopup(colorpickerFrame)

					local RGB = New("ImageButton", {
						Name = "RGB",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.new(0.067, 0, 0.068, 0),
						Size = UDim2.new(0.74, 0, 0.74, 0),
						AutoButtonColor = false,
						Image = "rbxassetid://6523286724",
						ZIndex = 1360,
					}, colorpickerFrame)

					local RGBCircle = New("ImageLabel", {
						Name = "RGBCircle",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(0, 14, 0, 14),
						Image = "rbxassetid://3926309567",
						ImageRectOffset = Vector2.new(628, 420),
						ImageRectSize = Vector2.new(48, 48),
						ZIndex = 1361,
					}, RGB)

					local Darkness = New("ImageButton", {
						Name = "Darkness",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Position = UDim2.new(0.831940293, 0, 0.068, 0),
						Size = UDim2.new(0.14, 0, 0.74, 0),
						AutoButtonColor = false,
						Image = "rbxassetid://156579757",
						ZIndex = 1360,
					}, colorpickerFrame)

					local DarknessCircle = New("Frame", {
						Name = "DarknessCircle",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Position = UDim2.new(0.5, 0, 0, 0),
						Size = UDim2.new(1.4, 0, 0, 5),
						ZIndex = 1361,
					}, Darkness)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, DarknessCircle)

					local colorHex = New("TextLabel", {
						BackgroundColor3 = Color3.fromRGB(15,17,26),
						Position = UDim2.new(0.0717131495, 0, 0.855, 0),
						Size = UDim2.new(0.44, 0, 0.09, 0),
						Font = Enum.Font.ArialBold,
						Text = "#FFFFFF",
						TextColor3 = Color3.fromRGB(210, 215, 225),
						TextScaled = true,
						ZIndex = 1360,
					}, colorpickerFrame)
					New("UICorner", { CornerRadius = UDim.new(0, 4) }, colorHex)

					local Copy = New("TextButton", {
						BackgroundColor3 = Color3.fromRGB(15,17,26),
						Position = UDim2.new(0.54, 0, 0.855, 0),
						Size = UDim2.new(0.39, 0, 0.09, 0),
						AutoButtonColor = false,
						Font = Enum.Font.ArialBold,
						Text = "Copy",
						TextColor3 = Color3.fromRGB(210, 215, 225),
						TextScaled = true,
						ZIndex = 1360,
					}, colorpickerFrame)
					New("UICorner", { CornerRadius = UDim.new(0, 4) }, Copy)

					local function to_hex(c)
						return ColorToHex(c)
					end

					local function update()
						local c = Color3.fromHSV(color[1], color[2], color[3])
						colorHex.Text = to_hex(c)
						colorpickerButton.BackgroundColor3 = c
						Darkness.BackgroundColor3 = c
						DarknessCircle.BackgroundColor3 = c
						InvokeCallback(callback, c)
					end

						local function UpdateSlide(input)
						local ml = GetInputPosition(input)
						local y = ml.Y - Darkness.AbsolutePosition.Y
						local maxY = Darkness.AbsoluteSize.Y
if maxY <= 0 then return end
						if y < 0 then y = 0 end
						if y > maxY then y = maxY end
						y = ClampRatio(y, maxY)
						local cy = DarknessCircle.AbsoluteSize.Y / 2
						color = {color[1], color[2], 1 - y}
						local realcolor = Color3.fromHSV(color[1], color[2], color[3])
						DarknessCircle.BackgroundColor3 = realcolor
						DarknessCircle.Position = UDim2.new(0.5, 0, y, -cy)
						update()
					end

					local function UpdateRing(input)
						local ml = GetInputPosition(input)
						local x = ml.X - RGB.AbsolutePosition.X
						local y = ml.Y - RGB.AbsolutePosition.Y
						local maxX = RGB.AbsoluteSize.X
if maxX <= 0 then return end
						local maxY = RGB.AbsoluteSize.Y
if maxY <= 0 then return end
						if x < 0 then x = 0 end
						if x > maxX then x = maxX end
						if y < 0 then y = 0 end
						if y > maxY then y = maxY end
						x = ClampRatio(x, maxX)
						y = ClampRatio(y, maxY)
						local cx = RGBCircle.AbsoluteSize.X / 2
						local cy = RGBCircle.AbsoluteSize.Y / 2
						RGBCircle.Position = UDim2.new(x, -cx, y, -cy)
						color = {1 - x, 1 - y, color[3]}
						local realcolor = Color3.fromHSV(color[1], color[2], color[3])
						Darkness.BackgroundColor3 = realcolor
						DarknessCircle.BackgroundColor3 = realcolor
						update()
					end

					colorpickerButton.MouseButton1Click:Connect(function()
						pickerOpen = not pickerOpen
						AnimateColorPickerOpen(colorpickerFrame, colorpickerButton, pickerOpen, function(v) pickerOpen = v end)
						Tween(colorpickerLabel, { TextColor3 = pickerOpen and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182) }, 0.06)
					end)

					RGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then WheelDown = true; UpdateRing(input) end end)
					Darkness.InputBegan:Connect(function(input) if IsPrimaryInput(input) then SlideDown = true; UpdateSlide(input) end end)
						
					UserInputService.InputEnded:Connect(function(input)
						if IsPrimaryInput(input) then
							WheelDown = false
							SlideDown = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							if WheelDown then UpdateRing(input) end
							if SlideDown then UpdateSlide(input) end
						end
					end)

					Copy.MouseButton1Click:Connect(function()
						if setclipboard then setclipboard(colorHex.Text) end
					end)

					local function setcolor(tbl)
						local realcolor = Color3.fromHSV(tbl[1], tbl[2], tbl[3])
						colorHex.Text = ColorToHex(realcolor)
						colorpickerButton.BackgroundColor3 = realcolor
						Darkness.BackgroundColor3 = realcolor
						DarknessCircle.BackgroundColor3 = realcolor
						color = {tbl[1], tbl[2], tbl[3]}
						task.defer(function()
							local cx = RGBCircle.AbsoluteSize.X / 2
							local cy2 = RGBCircle.AbsoluteSize.Y / 2
							RGBCircle.Position = UDim2.new(math.clamp(1 - tbl[1], 0, 1), -cx, math.clamp(1 - tbl[2], 0, 1), -cy2)
							local darknessY = 1 - tbl[3]
							local dcy = DarknessCircle.AbsoluteSize.Y / 2
							DarknessCircle.Position = UDim2.new(0.5, 0, darknessY, -dcy)
						end)
					end

					setcolor({hue, sat, val})

					local obj = {}
					function obj:Set(c)
						local normalized = NormalizeColor(c)
						local h2, s2, v2 = Color3.toHSV(normalized)
						setcolor({h2, s2, v2})
						InvokeCallback(callback, normalized)
					end
					function obj:Get()
						return Color3.fromHSV(color[1], color[2], color[3])
					end
					RegisterConfigElement("settings_colorpicker_", text, obj)
					return obj
				end

				MakeReadableText(SettingsFrame, 12, 18)
				settingsCache[parentFrame] = SettingsObj
				return SettingsObj
			end

			local _contextTargets = _windowContextTargets
			local _contextMenu
			local _contextOpen = false
			local _contextTarget
			local _bindTarget
			local _bindMenu
			local _keybinds = {}
			local _bindListener

			local function GetTargetBindLabel(target)
				if not target or not target.key then return "Not bound" end
				return target.key.Name
			end

			local function SetTargetBind(target, key)
				if not target or not target.obj then return end
				if target.key and _keybinds[target.key] == target then _keybinds[target.key] = nil end
				if key then
					local previous = _keybinds[key]
					if previous and previous ~= target then
						previous.key = nil
						if previous.dots then
							local previousIndicator = previous.dots:FindFirstChild("BindLabel")
							if previousIndicator then previousIndicator.Text = "" end
						end
					end
				end
				target.key = key
				if key then _keybinds[key] = target end
				if target.dots then
					target.dots.Visible = true
					local indicator = target.dots:FindFirstChild("BindLabel")
					if indicator then indicator.Text = key and key.Name or "" end
				end
			end

			local function CloseBindMenu()
				UnregisterPopup(_bindMenu)
				if not _bindMenu then return end
				_bindMenu.Visible = false
				_bindTarget = nil
			end

			local function BuildBindMenu()
				if _bindMenu then return _bindMenu end
				_bindMenu = New("Frame", {
					Name = "BindPrompt",
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0.34, 0, 0, 42),
					BackgroundColor3 = Color3.fromRGB(17, 20, 30),
					BackgroundTransparency = 0.05,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 9000,
					ClipsDescendants = true,
				}, MainFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 12) }, _bindMenu)
				local label = New("TextLabel", {
					Name = "BindLabel",
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = "Press a key to bind",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.GothamBold,
					ZIndex = 9001,
				}, _bindMenu)
				AddTextConstraint(label, 10, 14, true)
				return _bindMenu
			end

			local function OpenBindMenu(target)
				CloseAllPopupsExcept(nil)
				_bindTarget = target
				BuildBindMenu()
				local label = _bindMenu:FindFirstChild("BindLabel")
				if label then label.Text = "Press a key to bind: " .. tostring(target.label or "Function") end
				_bindMenu.Visible = true
				_bindMenu.BackgroundTransparency = 1
				Tween(_bindMenu, { BackgroundTransparency = 0.05 }, 0.15)
				ConstrainPopupToMainFrame(_bindMenu, 8)
				RegisterPopup(_bindMenu, CloseBindMenu, nil)
			end

			local function CloseContextMenu()
				if not _contextMenu then return end
				_contextOpen = false
				_contextTarget = nil
				UnregisterPopup(_contextMenu)
				SmoothClose(_contextMenu, 0.15)
			end

			local function BuildContextMenu()
				if _contextMenu then return _contextMenu end
				_contextMenu = New("Frame", {
					Name = "ElementContextMenu",
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0.28, 0, 0, 112),
					BackgroundColor3 = Color3.fromRGB(17, 20, 30),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 8000,
					ClipsDescendants = false,
				}, MainFrame)
					New("UICorner", { CornerRadius = UDim.new(0, 12) }, _contextMenu)
				New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, _contextMenu)
				return _contextMenu
			end

			local function AddContextItem(labelText, callback)
				local item = New("TextButton", {
					Name = "MenuItem",
					Size = UDim2.new(1, -12, 0, 26),
					Position = UDim2.new(0, 6, 0, 0),
					BackgroundTransparency = 1,
					Text = labelText,
					TextColor3 = Color3.fromRGB(235, 238, 248),
					TextScaled = true,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 8001,
				}, _contextMenu)
				AddTextConstraint(item, 12, 15, true)
				item.MouseButton1Click:Connect(function()
					local target = _contextTarget
					CloseContextMenu()
					if target and callback then callback(target) end
				end)
				return item
			end

			local function OpenContextMenu(target, point)
				BuildContextMenu()
				CloseAllPopupsExcept(_contextMenu)
				_contextTarget = target
				for _, child in ipairs(_contextMenu:GetChildren()) do
					if child:IsA("GuiObject") then child:Destroy() end
				end
				local layout = _contextMenu:FindFirstChildOfClass("UIListLayout")
				if not layout then New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, _contextMenu) end
				AddContextItem("Settings", function(current)
					if current.obj and current.obj.AddSettings then
						local settings = current.obj:AddSettings()
						if settings and settings.Open then settings:Open() end
					end
				end)
				AddContextItem("Reset", function(current)
					if current.obj and current.obj.Set and current.defaultValue ~= nil then
						current.obj:Set(current.defaultValue)
					end
				end)
				AddContextItem("Unbind", function(current)
					SetTargetBind(current, nil)
				end)
				_contextMenu.Size = UDim2.new(0.28, 0, 0, 112)
				SmoothOpen(_contextMenu, 0.03, 0.15)
				MovePopupToAbsolute(_contextMenu, point.X, point.Y)
				ConstrainPopupToMainFrame(_contextMenu, 8)
				_contextOpen = true
				RegisterPopup(_contextMenu, CloseContextMenu, target.dots)
			end

			local function IsEditableTarget()
				local ok, focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
				return not (ok and focused)
			end

			local function RunBoundFunction(target)
				if not target or not target.obj then return end
				local value = target.obj.Get and target.obj:Get()
				if type(value) == "boolean" then
					target.obj:Set(not value)
				elseif type(value) == "number" and target.min and target.max then
					local step = (target.max - target.min) / 10
					target.obj:Set(math.clamp(value + step, target.min, target.max))
				elseif type(value) == "string" and target.options then
					for index, option in ipairs(target.options) do
						if option == value then
							target.obj:Set(target.options[index % #target.options + 1] or target.options[1])
							break
						end
					end
				end
			end

			BindElementContext = function(row, kind, label, obj, defaultValue, options, min, max)
				if not row or not obj then return end
				CleanBorders(row)
				local target = {
					row = row,
					kind = kind,
					label = tostring(label or "Function"),
					obj = obj,
					defaultValue = defaultValue,
					options = options,
					min = min,
					max = max,
				}
				_contextTargets[row] = target
				local dots = row:FindFirstChild("ContextDots")
				target.dots = dots
				SetTargetBind(target, nil)
				if obj.Bind then return end
				function obj:Bind(key)
					local normalized = type(key) == "string" and Enum.KeyCode[key] or key
					if normalized and normalized ~= Enum.KeyCode.Unknown then SetTargetBind(target, normalized) end
					return self:GetBind()
				end
				function obj:Unbind() SetTargetBind(target, nil) return self:GetBind() end
				function obj:GetBind() return target.key end
			end

			UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if _bindTarget then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						local key = input.KeyCode
						if key ~= Enum.KeyCode.Escape then SetTargetBind(_bindTarget, key) end
						CloseBindMenu()
						return
					end
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						local bindPoint = GetInputPosition(input)
						local retargeted = false
						for bindRow, bindTargetRow in pairs(_contextTargets) do
							if bindRow.Parent and bindRow.Visible and IsPointInsideTree(bindRow, bindPoint) then
								OpenBindMenu(bindTargetRow)
								retargeted = true
								break
							end
						end
						if not retargeted then CloseBindMenu() end
						return
					end
					return
				end
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					local point = GetInputPosition(input)
					for _, entry in ipairs(_openPopups) do
						if entry.frame and entry.frame.Visible and IsPointInsideTree(entry.frame, point) then return end
					end
					for row, target in pairs(_contextTargets) do
						if row.Parent and row.Visible and IsPointInsideTree(row, point) then
							OpenBindMenu(target)
							return
						end
					end
				elseif input.UserInputType == Enum.UserInputType.Keyboard and IsEditableTarget() then
					local target = _keybinds[input.KeyCode]
					if target then RunBoundFunction(target) end
				end
			end)

			function SectionObj:AddToggle(text, default, callback)
				elemCount = elemCount + 1
				local enabled = default == true

				local Toggle = New("Frame", {
					Name = "Toggle",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
				New("UIAspectRatioConstraint", {
					AspectRatio = 9,
					AspectType = Enum.AspectType.ScaleWithParentSize,
				}, Toggle)

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					ZIndex = 100,
					BorderSizePixel = 0,
				}, Toggle)

				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.new(0.04800000086426735, 0, 0.3, 0),
					Size = UDim2.new(0.6600000262260437, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Toggle)

				local Effect = New("Frame", {
					Name = "Effect",
					Position = UDim2.new(0.8400000143051147, 0, 0.30000001192092896, 0),
					Size = UDim2.new(0.11035999655723572, 0, 0.5600000023841858, 0),
					BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0),
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
				New("UIStroke", { Transparency = 0.800000011920929, Thickness = 0.800000011920929 }, Effect)

				local Icon = New("Frame", {
					Name = "Icon",
					Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0),
					Size = UDim2.new(1, 0, 0.8999999761581421, 0),
					BackgroundColor3 = Color3.fromRGB(255,255,255),
					BackgroundTransparency = enabled and 0 or 0.5,
				}, Effect)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Icon)
				New("UIAspectRatioConstraint", {}, Icon)

				local Btn = New("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 5,
				}, Toggle)

				local function Set(val)
					enabled = val == true
					Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0) }, 0.25, Enum.EasingStyle.Quad)
					Tween(Icon, { Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0), BackgroundTransparency = enabled and 0 or 0.5 }, 0.25, Enum.EasingStyle.Back)
					InvokeCallback(callback, enabled)
				end

				Btn.MouseButton1Click:Connect(function() Set(not enabled) end)

				local obj = {}
				function obj:Set(v) Set(v) end
				function obj:Get() return enabled end
				function obj:AddSettings() return MakeSettings(Toggle, nil, text) end
				RegisterConfigElement("toggle_", text, obj)
				CenterElement(Toggle)
				BindElementContext(Toggle, "toggle", text, obj, default)
				return obj
			end

			function SectionObj:AddCheckbox(text, default, callback)
				elemCount = elemCount + 1
				local enabled = default == true
				local CheckBoxToggle = New("Frame", {
					Name = "CheckBoxToggle",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
				New("UIAspectRatioConstraint", {AspectRatio = 9, AspectType = Enum.AspectType.ScaleWithParentSize}, CheckBoxToggle)
				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					ZIndex = 100,
				}, CheckBoxToggle)
				local CheckBox = New("Frame", {
					Name = "CheckBox",
					Position = UDim2.new(0.04, 0, 0.3, 0),
					Size = UDim2.new(0.075, 0, 0.7, 0),
					BackgroundTransparency = 1,
					ZIndex = 1001,
				}, CheckBoxToggle)
				New("UICorner", {}, CheckBox)
				New("UIAspectRatioConstraint", {}, CheckBox)
				local Check = New("ImageLabel", {
					Name = "Check",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://138494545053627",
					ImageTransparency = enabled and 0.1 or 1,
					ZIndex = 1001,
				}, CheckBox)
				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.new(0.15, 0, 0.3, 0),
					Size = UDim2.new(0.66, 0, 0.5, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.1,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 1001,
				}, CheckBoxToggle)
				local Btn = New("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 1010,
				}, CheckBoxToggle)
				local function Set(val)
					enabled = val == true
					Tween(Check, {ImageTransparency = enabled and 0.1 or 1}, 0.2)
					InvokeCallback(callback, enabled)
				end
				Btn.MouseButton1Click:Connect(function() Set(not enabled) end)
				local obj = {}
				function obj:Set(v) Set(v) end
				function obj:Get() return enabled end
				function obj:AddSettings() return MakeSettings(CheckBoxToggle, nil, text) end
				RegisterConfigElement("checkbox_", text, obj)
				CenterElement(CheckBoxToggle)
				BindElementContext(CheckBoxToggle, "checkbox", text, obj, default)
				return obj
			end

			function SectionObj:AddColorToggle(text, defaultColor, defaultEnabled, callback)
				if type(defaultEnabled) == "function" then
					callback = defaultEnabled
					defaultEnabled = false
				end
				if type(callback) ~= "function" then callback = nil end
				local state = {
					enabled = defaultEnabled == true,
					color = NormalizeColor(defaultColor),
				}
				return SectionObj:AddToggleColorpicker(text, state.enabled, state.color,
					function(enabled)
						state.enabled = enabled
						if callback then callback(state.color, enabled) end
					end,
					function(newColor)
						state.color = newColor
						if callback then callback(newColor, state.enabled) end
					end)
			end

			function SectionObj:AddToggleColorpicker(text, defaultEnabled, defaultColor, callback, colorCallback)
				if type(callback) ~= "function" then callback = nil end
				if type(colorCallback) ~= "function" then colorCallback = nil end
				elemCount = elemCount + 1
				local enabled = defaultEnabled == true
				local color = { Color3.toHSV(NormalizeColor(defaultColor)) }
				local pickerOpen = false
				local WheelDown = false
				local SlideDown = false

				local Toggle = New("Frame", {
					Name = "Toggle",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
				New("UIAspectRatioConstraint", {
					AspectRatio = 9,
					AspectType = Enum.AspectType.ScaleWithParentSize,
				}, Toggle)

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					ZIndex = 100,
					BorderSizePixel = 0,
				}, Toggle)

				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.6000000238418579, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
				   TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Toggle)

				-- Toggle switch (shifted slightly left to make room for colorpicker button)
				local Effect = New("Frame", {
					Name = "Effect",
					Position = UDim2.new(0.840000143051147, 0, 0.30000001192092896, 0),
					Size = UDim2.new(0.11035999655723572, 0, 0.5600000023841858, 0),
					BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0),
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
				New("UIStroke", { Transparency = 0.800000011920929, Thickness = 0.800000011920929 }, Effect)

				local Icon = New("Frame", {
					Name = "Icon",
					Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0),
					Size = UDim2.new(1, 0, 0.8999999761581421, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = enabled and 0 or 0.5,
				}, Effect)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Icon)
				New("UIAspectRatioConstraint", {}, Icon)

				-- Colorpicker open button (small colored square)
				local cpBtn = New("ImageButton", {
					Name = "ColorpickerOpenButton",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.752, 0, 0.5, 0),
               Size = UDim2.new(0.06800000369548798,0,0.5600000023841858,0),
					BackgroundColor3 = Color3.fromHSV(color[1], color[2], color[3]),
					BorderSizePixel = 0,
					Image = "",
					ZIndex = 55,
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, cpBtn)

				-- Colorpicker panel
				local cpFrame = New("Frame", {
					Name = "Frame",
					Position = UDim2.new(0.02,0,1,2),
					Size = UDim2.new(0.96, 0, 7, 0),
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 350,
					ClipsDescendants = false,
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, cpFrame)
				New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9200000166893005 }, cpFrame)
				New("UIAspectRatioConstraint", { AspectRatio = 1.100000023841858 }, cpFrame)
				FitColorPickerPopup(cpFrame)

				local RGB = New("ImageButton", {
					Name = "ImageButton",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0.06700000166893005, 0, 0.06800000369548798, 0),
					Size = UDim2.new(0.7400000095367432, 0, 0.7400000095367432, 0),
					AutoButtonColor = false,
					Image = "rbxassetid://6523286724",
					ZIndex = 360,
				}, cpFrame)

				local RGBCircle = New("ImageLabel", {
					Name = "ImageLabel",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Image = "rbxassetid://3926309567",
					ZIndex = 361,
				}, RGB)

				local Darkness = New("ImageButton", {
					Name = "ImageButton",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0.8319402933120728, 0, 0.06800000369548798, 0),
					Size = UDim2.new(0.14000000059604645, 0, 0.7400000095367432, 0),
					AutoButtonColor = false,
					Image = "rbxassetid://156579757",
					ZIndex = 360,
				}, cpFrame)

				local DarknessCircle = New("Frame", {
					Name = "Frame",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(1.399999976158142, 0, 0, 5),
					ZIndex = 361,
				}, Darkness)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, DarknessCircle)

				local colorHex = New("TextLabel", {
					Name = "Hex",
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					Position = UDim2.new(0.0717131495475769, 0, 0.8550000190734863, 0),
					Size = UDim2.new(0.4399999976158142, 0, 0.09000000357627869, 0),
					Font = Enum.Font.ArialBold,
					Text = "#FFFFFF",
					TextColor3 = Color3.fromRGB(210, 215, 225),
					TextScaled = true,
					ZIndex = 360,
				}, cpFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, colorHex)

				local Copy = New("TextButton", {
					Name = "Copy",
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					Position = UDim2.new(0.5400000214576721, 0, 0.8550000190734863, 0),
					Size = UDim2.new(0.38999998569488525, 0, 0.09000000357627869, 0),
					AutoButtonColor = false,
					Font = Enum.Font.ArialBold,
					Text = "Copy",
					TextColor3 = Color3.fromRGB(210, 215, 225),
					TextScaled = true,
					ZIndex = 360,
				}, cpFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, Copy)

				-- Toggle button (transparent overlay for toggle clicks, excluding colorpicker area)
				local Btn = New("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 5,
				}, Toggle)

				-- Helper functions
				local function to_hex(c)
					return ColorToHex(c)
				end

				local function CurrentColor()
					return Color3.fromHSV(color[1], color[2], color[3])
				end

				local function NotifyColor(c)
					if colorCallback then
						InvokeCallback(colorCallback, c)
					elseif callback then
						InvokeCallback(callback, c, enabled)
					end
				end

				local function NotifyEnabled()
					if colorCallback then
						if callback then InvokeCallback(callback, enabled) end
					elseif callback then
						InvokeCallback(callback, CurrentColor(), enabled)
					end
				end

				local function updateColor()
					local c = CurrentColor()
					colorHex.Text = to_hex(c)
					cpBtn.BackgroundColor3 = c
					Darkness.BackgroundColor3 = c
					DarknessCircle.BackgroundColor3 = c
					NotifyColor(c)
				end

				local function UpdateSlide(input)
					local ml = GetInputPosition(input)
					local y = ml.Y - Darkness.AbsolutePosition.Y
					local maxY = Darkness.AbsoluteSize.Y
if maxY <= 0 then return end
					if y < 0 then y = 0 end
					if y > maxY then y = maxY end
					y = ClampRatio(y, maxY)
					local cy = DarknessCircle.AbsoluteSize.Y / 2
					color = {color[1], color[2], 1 - y}
					local rc = Color3.fromHSV(color[1], color[2], color[3])
					DarknessCircle.BackgroundColor3 = rc
					DarknessCircle.Position = UDim2.new(0.5, 0, y, -cy)
					updateColor()
				end

				local function UpdateRing(input)
					local ml = GetInputPosition(input)
					local x = ml.X - RGB.AbsolutePosition.X
					local y = ml.Y - RGB.AbsolutePosition.Y
					local maxX = RGB.AbsoluteSize.X
if maxX <= 0 then return end
					local maxY = RGB.AbsoluteSize.Y
if maxY <= 0 then return end
					if x < 0 then x = 0 end
					if x > maxX then x = maxX end
					if y < 0 then y = 0 end
					if y > maxY then y = maxY end
					x = ClampRatio(x, maxX)
					y = ClampRatio(y, maxY)
					local cx = RGBCircle.AbsoluteSize.X / 2
					local cy = RGBCircle.AbsoluteSize.Y / 2
					RGBCircle.Position = UDim2.new(x, -cx, y, -cy)
					color = {1 - x, 1 - y, color[3]}
					local rc = Color3.fromHSV(color[1], color[2], color[3])
					Darkness.BackgroundColor3 = rc
					DarknessCircle.BackgroundColor3 = rc
					updateColor()
				end

				-- Toggle logic
				local function SetEnabled(val)
					enabled = val == true
					Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0) }, 0.25, Enum.EasingStyle.Quad)
					Tween(Icon, { Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0), BackgroundTransparency = enabled and 0 or 0.5 }, 0.25, Enum.EasingStyle.Back)
					NotifyEnabled()
				end

				Btn.MouseButton1Click:Connect(function()
					-- Only toggle if not clicking on colorpicker button area
					SetEnabled(not enabled)
				end)

				cpBtn.MouseButton1Click:Connect(function()
					pickerOpen = not pickerOpen
					AnimateColorPickerOpen(cpFrame, cpBtn, pickerOpen, function(v) pickerOpen = v end)
				end)

				RGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then WheelDown = true; UpdateRing(input) end end)
				Darkness.InputBegan:Connect(function(input) if IsPrimaryInput(input) then SlideDown = true; UpdateSlide(input) end end)
				
				UserInputService.InputEnded:Connect(function(input)
					if IsPrimaryInput(input) then
						WheelDown = false
						SlideDown = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if WheelDown then UpdateRing(input) end
						if SlideDown then UpdateSlide(input) end
					end
				end)

				Copy.MouseButton1Click:Connect(function()
					if setclipboard then setclipboard(colorHex.Text) end
				end)

				-- Initialize color display
				local function setcolor(tbl, fireCallback, exactColor)
					local rc = exactColor or Color3.fromHSV(tbl[1], tbl[2], tbl[3])
					colorHex.Text = to_hex(rc)
					cpBtn.BackgroundColor3 = rc
					Darkness.BackgroundColor3 = rc
					DarknessCircle.BackgroundColor3 = rc
					color = {tbl[1], tbl[2], tbl[3]}
					task.defer(function()
						local cx = RGBCircle.AbsoluteSize.X / 2
						local cy = RGBCircle.AbsoluteSize.Y / 2
						RGBCircle.Position = UDim2.new(math.clamp(1 - tbl[1], 0, 1), -cx, math.clamp(1 - tbl[2], 0, 1), -cy)
						local darknessY = 1 - tbl[3]
						local dcy = DarknessCircle.AbsoluteSize.Y / 2
						DarknessCircle.Position = UDim2.new(0.5, 0, math.clamp(darknessY, 0, 1), -dcy)
					end)
					if fireCallback then
						NotifyColor(exactColor or rc)
					end
				end
				setcolor(color)

				local obj = {}
				function obj:Set(v) SetEnabled(v) end
				function obj:Get() return enabled end
				function obj:SetColor(c)
					local normalized = NormalizeColor(c)
					local h, s, v2 = Color3.toHSV(normalized)
					setcolor({h, s, v2}, true, normalized)
				end
				function obj:GetColor() return Color3.fromHSV(color[1], color[2], color[3]) end
				function obj:AddSettings() return MakeSettings(Toggle, nil, text) end
				RegisterConfigElement("togglecolorpicker_", text, obj)
				RegisterConfigElement("togglecolorpicker_color_", text, {Get = function() return obj:GetColor() end, Set = function(_, c) obj:SetColor(c) end})
				CenterElement(Toggle)
				BindElementContext(Toggle, "togglecolorpicker", text, obj, defaultEnabled)
				return obj
			end

			function SectionObj:AddSlider(text, min, max, default, callback, suffix)
				elemCount = elemCount + 1
				if type(suffix) ~= "string" then suffix = "" end
				local value
				min, max, value = NormalizeRange(min, max, default)
				value = Quantize(value, min, max, GetSliderStep(min, max))
				local initRatio = (value - min) / (max - min)
				local dragging = false

				local Slider = New("Frame", {
					Name = "Slider",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
				New("UIAspectRatioConstraint", {
					AspectRatio = 9,
					AspectType = Enum.AspectType.ScaleWithParentSize,
				}, Slider)

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					ZIndex = 100,
					BorderSizePixel = 0,
				}, Slider)

				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
					Size = UDim2.new(0.6600000262260437, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Slider)

				local Effect = New("Frame", {
					Name = "Effect",
					Position = UDim2.new(0.4980000042915344, 0, 0.25, 0),
					Size = UDim2.new(0.5, 0, 0.6990000009536743, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
				}, Slider)

				local SliderValue = New("TextLabel", {
					Name = "SliderValue",
					Position = UDim2.new(0.6990000009536743, 0, 0.10000000149011612, 0),
					Size = UDim2.new(0.25, 0, 0.8080000281333923, 0),
					BackgroundColor3 = Color3.fromRGB(32, 35, 50),
					Text = FormatSliderValue(value, suffix),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.20000000298023224,
				}, Effect)
				New("UICorner", { CornerRadius = UDim.new(0, 5) }, SliderValue)

				local Line = New("Frame", {
					Name = "Line",
					Active = true,
					Position = UDim2.new(0.03999999910593033, 0, 0.3190000057220459, 0),
					Size = UDim2.new(0.6000000238418579, 0, 0.15000000596046448, 0),
					BackgroundColor3 = Color3.fromRGB(33,37,53),
				}, Effect)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Line)

				local InLine = New("Frame", {
					Name = "InLine",
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundColor3 = mainColor,
					ZIndex = 2,
				}, Line)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, InLine)

				local Trigger = New("TextButton", {
					Name = "Trigger",
					Position = UDim2.new(0.10000000149011612, 0, -1.8000000715255737, 0),
					Size = UDim2.new(1.1999999284744263, 0, 4.200000286102295, 0),
					AnchorPoint = Vector2.new(0.800000011920929, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					Active = false,
					Text = "",
					ZIndex = 3,
				}, Line)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Trigger)
				New("UIAspectRatioConstraint", {}, Trigger)

				local initialValue = value
				task.defer(function()
					if value ~= initialValue then return end
					InLine.Size = UDim2.fromScale(initRatio, 1)
					Trigger.Position = UDim2.new(initRatio, 0, -1.8000000715255737, 0)
				end)

					local function update(input)
						local pointer = GetInputPosition(input)
						local lineSize = Line.AbsoluteSize.X
						if lineSize <= 0 then return end
						local sizeScale = ClampRatio(pointer.X - Line.AbsolutePosition.X, lineSize)
						value = Quantize(((max - min) * sizeScale) + min, min, max, GetSliderStep(min, max))
						Tween(InLine, { Size = UDim2.fromScale(sizeScale, 1) }, 0.1)
						Trigger.Position = UDim2.new(sizeScale, 0, -1.8000000715255737, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						InvokeCallback(callback, value)
					end

				Line.InputBegan:Connect(function(input)
					if IsPrimaryInput(input) then
						dragging = true
						update(input)
					end
				end)

				-- Bug 3 fix: use global InputEnded so releasing mouse outside the Line still stops dragging
				UserInputService.InputEnded:Connect(function(input)
					if IsPrimaryInput(input) then
						dragging = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging then
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							update(input)
						end
					end
				end)

				local obj = {}
				function obj:Set(val)
					local numeric = type(val) == "number" and val == val and val or min
						value = math.clamp(numeric, min, max)
					value = Quantize(value, min, max, GetSliderStep(min, max))
					local ratio = (value - min) / (max - min)
					InLine.Size = UDim2.fromScale(ratio, 1)
					Trigger.Position = UDim2.new(ratio, 0, -1.8000000715255737, 0)
					SliderValue.Text = FormatSliderValue(value, suffix)
					InvokeCallback(callback, value)
				end
				function obj:Get() return value end
				function obj:AddSettings() return MakeSettings(Slider, "slider", text) end
				RegisterConfigElement("slider_", text, obj)
				CenterElement(Slider)
				BindElementContext(Slider, "slider", text, obj, value, nil, min, max)
				return obj
			end

			function SectionObj:AddDropdown(text, options, default, callback)
				if type(default) == "function" then
					callback = default
					default = nil
				end
				options = NormalizeOptions(options)
				elemCount = elemCount + 1
				local selected = GetValidOption(options, default)
				local dropOpen = false

				local Dropdown = New("Frame", {
					Name = "Dropdown",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
					ClipsDescendants = false,
				}, Elements)
				New("UIAspectRatioConstraint", {
					AspectRatio = 9,
					AspectType = Enum.AspectType.ScaleWithParentSize,
				}, Dropdown)

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					ZIndex = 100,
					BorderSizePixel = 0,
				}, Dropdown)

				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
					Size = UDim2.new(0.6000000238418579, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Dropdown)

				local TopBar = New("TextButton", {
					Name = "TopBar",
					Position = UDim2.new(0.498, 0, 0.25, 0),
			      Size = UDim2.new(0.46, 0, 0.600000024, 0),
				   BackgroundColor3 = Color3.fromRGB(32, 35, 50),
               BackgroundTransparency = 0,
					Text = selected or "Select",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.20000000298023224,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 5) }, TopBar)

				local Arrow = New("ImageLabel", {
					Name = "Arrow",
					Position = UDim2.new(0.845, 0, 0.29, 0),
					Size = UDim2.new(0.12, 0, 0.42, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					Image = "rbxassetid://10709790948",
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					ScaleType = Enum.ScaleType.Fit,
					Rotation = 270,
					ZIndex = 7,
				}, TopBar)

				local DownBar = New("Frame", {
					Name = "DownBar",
					Position = UDim2.new(0.02, 0, 1, 2),
					Size = UDim2.new(0.72, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(21,24,36),
					BackgroundTransparency = 0,
					Visible = false,
					ZIndex = 5000,
					ClipsDescendants = true,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 10) }, DownBar)
				New("UIStroke", {
					Color = Color3.fromRGB(44, 50, 72),
					Transparency = 0.45,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}, DownBar)

				local Scrolls = New("ScrollingFrame", {
					Name = "Scrolls",
					Position = UDim2.new(0.02, 0, 0, 2),
					Size = UDim2.new(0.96, 0, 1, -4),
					ScrollingEnabled = false,
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Color3.fromRGB(120, 128, 160),
					ScrollBarImageTransparency = 0.3,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ClipsDescendants = false,
					ZIndex = 5001,
				}, DownBar)
				New("UIListLayout", {
					Padding = UDim.new(0, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, Scrolls)

				local function closeDropdown()
					dropOpen = false
					Tween(Arrow, {Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					Tween(DownBar, { Size = UDim2.new(0.72, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					task.delay(0.21, function() if not dropOpen then DownBar.Visible = false end end)
					UnregisterPopup(DownBar)
					if _openDropdown == closeDropdown then _openDropdown = nil end
				end

				for _, opt in ipairs(options) do
					local Buttons = New("TextButton", {
						Name = "Buttons",
						Size = UDim2.new(1, -4, 0, 23),
						Position = UDim2.new(0, 2, 0, 0),
						ClipsDescendants = false,
						BackgroundColor3 = Color3.fromRGB(33, 38, 56),
						BackgroundTransparency = 1,
						Text = opt,
						TextColor3 = Color3.fromRGB(226, 232, 244),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						AutoButtonColor = false,
						ZIndex = 5002,
					}, Scrolls)
					New("UICorner", { CornerRadius = UDim.new(0, 7) }, Buttons)

					Buttons.MouseEnter:Connect(function()
						Tween(Buttons, { BackgroundTransparency = 0.15 }, 0.1)
					end)
					Buttons.MouseLeave:Connect(function()
						Tween(Buttons, { BackgroundTransparency = selected == opt and 0.35 or 1 }, 0.1)
					end)
					Buttons.MouseButton1Click:Connect(function()
						selected = opt
						SetTrimmedText(TopBar, opt); FitTextBeforeArrow(TopBar, Arrow)
						InvokeCallback(callback, opt)
						closeDropdown()
					end)
				end

				TopBar.MouseButton1Click:Connect(function()
					if dropOpen then
						closeDropdown()
					else
						CloseAllPopupsExcept(DownBar)
						if _openDropdown then _openDropdown() end
						dropOpen = true
						_openDropdown = closeDropdown
						DownBar.Visible = true
						local h = math.clamp(#options * 25 + 10, 34, 400)
						local finalSize = UDim2.new(0.72, 0, 0, h)
						local knownSize = Vector2.new(math.max(Dropdown.AbsoluteSize.X * 0.72, 1), math.min(h, math.max(MainFrame.AbsoluteSize.Y, 1)))
						DownBar.Size = finalSize
						PositionPopupWithinMain(DownBar, true, nil, nil, knownSize)
						DownBar.Size = UDim2.new(0.72, 0, 0, 0)
						Tween(DownBar, { Size = finalSize }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
						Tween(Arrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						task.delay(0.32, function() if DownBar.Visible then PositionPopupWithinMain(DownBar, true) end end)
						RegisterPopup(DownBar, closeDropdown, TopBar)
					end
				end)

				local obj = {}
				function obj:Set(val, silent) val = GetValidOption(options, val); selected = val; SetTrimmedText(TopBar, val); FitTextBeforeArrow(TopBar, Arrow); if not silent then InvokeCallback(callback, val) end end
				function obj:Get() return selected end
				function obj:AddSettings() return MakeSettings(Dropdown, "dropdown", text) end
				
				RegisterConfigElement("dropdown_", text, obj)
				if default ~= nil then obj:Set(GetValidOption(options, default), true) end
				CenterElement(Dropdown)
				BindElementContext(Dropdown, "dropdown", text, obj, selected, options)
				return obj

			end


			function SectionObj:AddDropdownColorpicker(text, options, defaultColor, callback, colorCallback)
				options = NormalizeOptions(options)
				if type(callback) ~= "function" then callback = nil end
				if type(colorCallback) ~= "function" then colorCallback = nil end
				elemCount = elemCount + 1
				local selected = GetValidOption(options, options[1])
				local dropOpen = false
				local pickerOpen = false
				local WheelDown = false
				local SlideDown = false
				local hue, sat, val = Color3.toHSV(NormalizeColor(defaultColor))
				local color = { hue, sat, val }

				-- Root row frame (matches design exactly)
				local Dropdown = New("Frame", {
					Name = "Dropdown",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
					ClipsDescendants = false,
				}, Elements)
				New("UIAspectRatioConstraint", {
					AspectRatio = 9,
					AspectType = Enum.AspectType.ScaleWithParentSize,
				}, Dropdown)

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.05000000074505806, 0, 1, 0),
					Size = UDim2.new(0.8999999761581421, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					ZIndex = 100,
				}, Dropdown)

				New("TextLabel", {
					Name = "TextDropdown",
					Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
					Size = UDim2.new(0.6000000238418579, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Dropdown)

				-- Colorpicker open button (small colored square, always visible)
				local cpBtn = New("ImageButton", {
					Name = "ColorpickerOpenButton",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.446, 0, 0.5, 0),
               Size = UDim2.new(0.06800000369548798,0,0.5600000023841858,0),
					BackgroundColor3 = Color3.fromHSV(hue, sat, val),
					BorderSizePixel = 0,
					Image = "",
					ZIndex = 55,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, cpBtn)

				-- Dropdown TopBar (shifted right to leave room for cpBtn)
				local TopBar = New("TextButton", {
					Name = "TopBar",
					Position = UDim2.new(0.498, 0, 0.25, 0),
					Size = UDim2.new(0.46, 0, 0.6000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(32, 35, 50),
					BackgroundTransparency = 0,
					Text = selected or "Select",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.SourceSansSemibold,
					TextTransparency = 0.20000000298023224,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 6,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 5) }, TopBar)

				local Arrow = New("ImageLabel", {
					Name = "Arrow",
					Position = UDim2.new(0.845, 0, 0.29, 0),
					Size = UDim2.new(0.12, 0, 0.42, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					Image = "rbxassetid://10709790948",
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					ScaleType = Enum.ScaleType.Fit,
					Rotation = 270,
					ZIndex = 7,
				}, TopBar)

				-- Dropdown list frame
				local DownBar = New("Frame", {
					Name = "DownBar",
					Position = UDim2.new(0.02, 0, 1, 2),
					Size = UDim2.new(0.72, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(21,24,36),
					BackgroundTransparency = 0,
					ClipsDescendants = true,
					Visible = false,
					ZIndex = 5000,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 10) }, DownBar)
				New("UIStroke", {
					Color = Color3.fromRGB(44, 50, 72),
					Transparency = 0.45,
					Thickness = 1,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}, DownBar)

				local Scrolls = New("ScrollingFrame", {
					Name = "Scrolls",
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					ScrollBarThickness = 1,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ZIndex = 5001,
				}, DownBar)
				New("UIListLayout", {
					Padding = UDim.new(0, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, Scrolls)

				local function closeDropdown()
					dropOpen = false
					Tween(Arrow, {Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					Tween(DownBar, { Size = UDim2.new(0.72, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					task.delay(0.21, function() if not dropOpen then DownBar.Visible = false end end)
					UnregisterPopup(DownBar)
					if _openDropdown == closeDropdown then _openDropdown = nil end
				end

				local function CurrentColor()
					return Color3.fromHSV(color[1], color[2], color[3])
				end

				local function NotifySelection(value)
					if colorCallback then
						if callback then InvokeCallback(callback, value) end
					elseif callback then
						InvokeCallback(callback, value, CurrentColor())
					end
				end

				local function NotifyColor(c)
					if colorCallback then
						InvokeCallback(colorCallback, c)
					elseif callback then
						InvokeCallback(callback, selected, c)
					end
				end

				for _, opt in ipairs(options) do
					local Btn = New("TextButton", {
						Name = "Buttons",
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundColor3 = Color3.fromRGB(32, 35, 50),
						BackgroundTransparency = 1,
						Text = opt,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.20000000298023224,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 5002,
					}, Scrolls)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, Btn)

					Btn.MouseEnter:Connect(function()
						Tween(Btn, { BackgroundTransparency = 0.6 }, 0.1)
					end)
					Btn.MouseLeave:Connect(function()
						Tween(Btn, { BackgroundTransparency = selected == opt and 0.5 or 1 }, 0.1)
					end)
					Btn.MouseButton1Click:Connect(function()
						selected = opt
						SetTrimmedText(TopBar, opt); FitTextBeforeArrow(TopBar, Arrow)
						closeDropdown()
						NotifySelection(opt)
					end)
				end

				TopBar.MouseButton1Click:Connect(function()
					if dropOpen then
						closeDropdown()
					else
						CloseAllPopupsExcept(DownBar)
						if _openDropdown then _openDropdown() end
						dropOpen = true
						_openDropdown = closeDropdown
						DownBar.Visible = true
						local h = math.clamp(#options * 25 + 10, 34, 400)
						local finalSize = UDim2.new(0.72, 0, 0, h)
						local knownSize = Vector2.new(math.max(Dropdown.AbsoluteSize.X * 0.72, 1), math.min(h, math.max(MainFrame.AbsoluteSize.Y, 1)))
						DownBar.Size = finalSize
						PositionPopupWithinMain(DownBar, true, nil, nil, knownSize)
						DownBar.Size = UDim2.new(0.72, 0, 0, 0)
						Tween(DownBar, { Size = finalSize }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
						Tween(Arrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						task.delay(0.32, function() if DownBar.Visible then PositionPopupWithinMain(DownBar, true) end end)
						RegisterPopup(DownBar, closeDropdown, TopBar)
					end
				end)

				-- Colorpicker panel
				local cpFrame = New("Frame", {
					Name = "colorpickerFrame",
					Position = UDim2.new(0.02,0,1,2),
					Size = UDim2.new(0.96, 0, 7, 0),
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 350,
					ClipsDescendants = false,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, cpFrame)
				New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1 }, cpFrame)
				New("UIAspectRatioConstraint", { AspectRatio = 1.1 }, cpFrame)
				FitColorPickerPopup(cpFrame)

				local RGB = New("ImageButton", {
					Name = "RGB",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0.067, 0, 0.068, 0),
					Size = UDim2.new(0.74, 0, 0.74, 0),
					AutoButtonColor = false,
					Image = "rbxassetid://6523286724",
					ZIndex = 360,
				}, cpFrame)

				local RGBCircle = New("ImageLabel", {
					Name = "RGBCircle",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Image = "rbxassetid://3926309567",
					ImageRectOffset = Vector2.new(628, 420),
					ImageRectSize = Vector2.new(48, 48),
					ZIndex = 361,
				}, RGB)

				local Darkness = New("ImageButton", {
					Name = "Darkness",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0.831940293, 0, 0.068, 0),
					Size = UDim2.new(0.14, 0, 0.74, 0),
					AutoButtonColor = false,
					Image = "rbxassetid://156579757",
					ZIndex = 360,
				}, cpFrame)

				local DarknessCircle = New("Frame", {
					Name = "DarknessCircle",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(1.4, 0, 0, 5),
					ZIndex = 361,
				}, Darkness)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, DarknessCircle)

				local colorHex = New("TextLabel", {
					Name = "colorHex",
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					Position = UDim2.new(0.0717131495, 0, 0.855, 0),
					Size = UDim2.new(0.44, 0, 0.09, 0),
					Font = Enum.Font.ArialBold,
					Text = "#FFFFFF",
					TextColor3 = Color3.fromRGB(210, 215, 225),
					TextScaled = true,
					ZIndex = 360,
				}, cpFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, colorHex)

				local Copy = New("TextButton", {
					Name = "Copy",
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					Position = UDim2.new(0.54, 0, 0.855, 0),
					Size = UDim2.new(0.39, 0, 0.09, 0),
					AutoButtonColor = false,
					Font = Enum.Font.ArialBold,
					Text = "Copy",
					TextColor3 = Color3.fromRGB(210, 215, 225),
					TextScaled = true,
					ZIndex = 360,
				}, cpFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, Copy)

				local function to_hex(c)
					return ColorToHex(c)
				end

				local function updateColor(fireCallback, exactColor)
					local c = exactColor or CurrentColor()
					colorHex.Text = to_hex(c)
					cpBtn.BackgroundColor3 = c
					Darkness.BackgroundColor3 = c
					DarknessCircle.BackgroundColor3 = c
					if fireCallback then NotifyColor(c) end
				end

				local function UpdateSlide(input)
					local ml = GetInputPosition(input)
					local y = ml.Y - Darkness.AbsolutePosition.Y
					local maxY = Darkness.AbsoluteSize.Y
if maxY <= 0 then return end
					if y < 0 then y = 0 end
					if y > maxY then y = maxY end
					y = ClampRatio(y, maxY)
					local cy = DarknessCircle.AbsoluteSize.Y / 2
					color = {color[1], color[2], 1 - y}
					local realcolor = Color3.fromHSV(color[1], color[2], color[3])
					DarknessCircle.BackgroundColor3 = realcolor
					DarknessCircle.Position = UDim2.new(0.5, 0, y, -cy)
					updateColor(true)
				end

				local function UpdateRing(input)
					local ml = GetInputPosition(input)
					local x = ml.X - RGB.AbsolutePosition.X
					local y = ml.Y - RGB.AbsolutePosition.Y
					local maxX = RGB.AbsoluteSize.X
if maxX <= 0 then return end
					local maxY = RGB.AbsoluteSize.Y
if maxY <= 0 then return end
					if x < 0 then x = 0 end
					if x > maxX then x = maxX end
					if y < 0 then y = 0 end
					if y > maxY then y = maxY end
					x = ClampRatio(x, maxX)
					y = ClampRatio(y, maxY)
					local cx = RGBCircle.AbsoluteSize.X / 2
					local cy = RGBCircle.AbsoluteSize.Y / 2
					RGBCircle.Position = UDim2.new(x, -cx, y, -cy)
					color = {1 - x, 1 - y, color[3]}
					local realcolor = Color3.fromHSV(color[1], color[2], color[3])
					Darkness.BackgroundColor3 = realcolor
					DarknessCircle.BackgroundColor3 = realcolor
					updateColor(true)
				end

				cpBtn.MouseButton1Click:Connect(function()
					pickerOpen = not pickerOpen
					AnimateColorPickerOpen(cpFrame, cpBtn, pickerOpen, function(v) pickerOpen = v end)
				end)

				RGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then WheelDown = true; UpdateRing(input) end end)
				Darkness.InputBegan:Connect(function(input) if IsPrimaryInput(input) then SlideDown = true; UpdateSlide(input) end end)

				UserInputService.InputEnded:Connect(function(input)
					if IsPrimaryInput(input) then
						WheelDown = false
						SlideDown = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if WheelDown then UpdateRing(input) end
						if SlideDown then UpdateSlide(input) end
					end
				end)

				Copy.MouseButton1Click:Connect(function()
					if setclipboard then setclipboard(colorHex.Text) end
				end)

				updateColor()
				task.defer(function()
					local cx = RGBCircle.AbsoluteSize.X / 2
					local cy = RGBCircle.AbsoluteSize.Y / 2
					RGBCircle.Position = UDim2.new(math.clamp(1 - color[1], 0, 1), -cx, math.clamp(1 - color[2], 0, 1), -cy)
					local dcy = DarknessCircle.AbsoluteSize.Y / 2
					DarknessCircle.Position = UDim2.new(0.5, 0, math.clamp(1 - color[3], 0, 1), -dcy)
				end)

				local obj = {}
				function obj:Set(val)
					val = GetValidOption(options, val)
					selected = val
					SetTrimmedText(TopBar, val); FitTextBeforeArrow(TopBar, Arrow)
					NotifySelection(val)
				end
				function obj:Get() return selected end
				function obj:SetColor(c)
					local normalized = NormalizeColor(c)
					local h2, s2, v2 = Color3.toHSV(normalized)
					color = {h2, s2, v2}
					updateColor(true, normalized)
					task.defer(function()
						local cx = RGBCircle.AbsoluteSize.X / 2
						local cy = RGBCircle.AbsoluteSize.Y / 2
						RGBCircle.Position = UDim2.new(math.clamp(1 - h2, 0, 1), -cx, math.clamp(1 - s2, 0, 1), -cy)
						local dcy = DarknessCircle.AbsoluteSize.Y / 2
						DarknessCircle.Position = UDim2.new(0.5, 0, math.clamp(1 - v2, 0, 1), -dcy)
					end)
				end
				function obj:GetColor() return Color3.fromHSV(color[1], color[2], color[3]) end
				function obj:AddSettings() return MakeSettings(Dropdown, "dropdown", text) end
				RegisterConfigElement("dropdowncolorpicker_", text, obj)
				RegisterConfigElement("dropdowncolorpicker_color_", text, {Get = function() return obj:GetColor() end, Set = function(_, c) obj:SetColor(c) end})
				CenterElement(Dropdown)
				BindElementContext(Dropdown, "dropdowncolorpicker", text, obj, selected, options)
				return obj
			end


			function SectionObj:AddColorpicker(text, defaultColor, callback)
				elemCount = elemCount + 1
				local options = {
					text = text,
					color = NormalizeColor(defaultColor),
					callback = callback,
				}

				local hue, sat, val = Color3.toHSV(options.color)
				local color = { hue, sat, val }
				local pickerOpen = false
				local WheelDown = false
				local SlideDown = false

				local Colorpicker = New("Frame", {
					Name = "Colorpicker",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = elemCount,
					ClipsDescendants = false,
					ZIndex = 2,
				}, Elements)
				New("UIAspectRatioConstraint", { AspectRatio = 9, AspectType = Enum.AspectType.ScaleWithParentSize }, Colorpicker)

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.89, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, Colorpicker)




				local colorpickerLabel = New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.6000000238418579, 0, 0.5000000238418579, 0),
						BackgroundTransparency = 1,
						Text = options.text,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 10,
				}, Colorpicker)

				local colorpickerButton = New("ImageButton", {
					Name = "colorpickerButton",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.875, 0, 0.57, 0),
					Size = UDim2.new(0.068, 0, 0.56, 0),
					BackgroundColor3 = options.color,
					BorderSizePixel = 0,
					Image = "",
					ZIndex = 30,
				}, Colorpicker)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, colorpickerButton)

				local colorpickerFrame = New("Frame", {
					Name = "colorpickerFrame",
					Position = UDim2.new(0.02,0,1,2),
					Size = UDim2.new(0.96, 0, 7, 0),
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 350,
					ClipsDescendants = false,
				}, Colorpicker)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, colorpickerFrame)
				New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1 }, colorpickerFrame)
				New("UIAspectRatioConstraint", { AspectRatio = 1.1 }, colorpickerFrame)
				FitColorPickerPopup(colorpickerFrame)

				local RGB = New("ImageButton", {
					Name = "RGB",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0.067, 0, 0.068, 0),
					Size = UDim2.new(0.74, 0, 0.74, 0),
					AutoButtonColor = false,
					Image = "rbxassetid://6523286724",
					ZIndex = 360,
				}, colorpickerFrame)

				local RGBCircle = New("ImageLabel", {
					Name = "RGBCircle",
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Image = "rbxassetid://3926309567",
					ImageRectOffset = Vector2.new(628, 420),
					ImageRectSize = Vector2.new(48, 48),
					ZIndex = 361,
				}, RGB)

				local Darkness = New("ImageButton", {
					Name = "Darkness",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0.831940293, 0, 0.068, 0),
					Size = UDim2.new(0.14, 0, 0.74, 0),
					AutoButtonColor = false,
					Image = "rbxassetid://156579757",
					ZIndex = 360,
				}, colorpickerFrame)

				local DarknessCircle = New("Frame", {
					Name = "DarknessCircle",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(1.4, 0, 0, 5),
					ZIndex = 361,
				}, Darkness)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, DarknessCircle)

				local colorHex = New("TextLabel", {
					Name = "colorHex",
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					Position = UDim2.new(0.0717131495, 0, 0.855, 0),
					Size = UDim2.new(0.44, 0, 0.09, 0),
					Font = Enum.Font.ArialBold,
					Text = "#FFFFFF",
					TextColor3 = Color3.fromRGB(210, 215, 225),
					TextScaled = true,
					ZIndex = 360,
				}, colorpickerFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, colorHex)

				local Copy = New("TextButton", {
					Name = "Copy",
					BackgroundColor3 = Color3.fromRGB(15,17,26),
					Position = UDim2.new(0.54, 0, 0.855, 0),
					Size = UDim2.new(0.39, 0, 0.09, 0),
					AutoButtonColor = false,
					Font = Enum.Font.ArialBold,
					Text = "Copy",
					TextColor3 = Color3.fromRGB(210, 215, 225),
					TextScaled = true,
					ZIndex = 360,
				}, colorpickerFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, Copy)

				-- ORIGINAL LOGIC (unchanged) --

				local function to_hex(c)
					return ColorToHex(c)
				end

				local function update()
					local c = Color3.fromHSV(color[1], color[2], color[3])
					colorHex.Text = to_hex(c)
					colorpickerButton.BackgroundColor3 = c
					Darkness.BackgroundColor3 = c
					DarknessCircle.BackgroundColor3 = c
					InvokeCallback(options.callback, c)
				end

				local function UpdateSlide(input)
					local ml = GetInputPosition(input)
					local y = ml.Y - Darkness.AbsolutePosition.Y
					local maxY = Darkness.AbsoluteSize.Y
if maxY <= 0 then return end
					if y < 0 then y = 0 end
					if y > maxY then y = maxY end
					y = ClampRatio(y, maxY)
					local cy = DarknessCircle.AbsoluteSize.Y / 2
					color = {color[1], color[2], 1 - y}
					local realcolor = Color3.fromHSV(color[1], color[2], color[3])
					DarknessCircle.BackgroundColor3 = realcolor
					DarknessCircle.Position = UDim2.new(0.5, 0, y, -cy)
					update()
				end

				local function UpdateRing(input)
					local ml = GetInputPosition(input)
					local x = ml.X - RGB.AbsolutePosition.X
					local y = ml.Y - RGB.AbsolutePosition.Y
					local maxX = RGB.AbsoluteSize.X
if maxX <= 0 then return end
					local maxY = RGB.AbsoluteSize.Y
if maxY <= 0 then return end
					if x < 0 then x = 0 end
					if x > maxX then x = maxX end
					if y < 0 then y = 0 end
					if y > maxY then y = maxY end
					x = ClampRatio(x, maxX)
					y = ClampRatio(y, maxY)
					local cx = RGBCircle.AbsoluteSize.X / 2
					local cy = RGBCircle.AbsoluteSize.Y / 2
					RGBCircle.Position = UDim2.new(x, -cx, y, -cy)
					color = {1 - x, 1 - y, color[3]}
					local realcolor = Color3.fromHSV(color[1], color[2], color[3])
					Darkness.BackgroundColor3 = realcolor
					DarknessCircle.BackgroundColor3 = realcolor
					update()
				end

				colorpickerButton.MouseButton1Click:Connect(function()
					pickerOpen = not pickerOpen
					AnimateColorPickerOpen(colorpickerFrame, colorpickerButton, pickerOpen, function(v) pickerOpen = v end)
					Tween(colorpickerLabel, { TextColor3 = pickerOpen and Color3.fromRGB(255,255,255) or Color3.fromRGB(255,255,255) }, 0.06)
				end)

				RGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then WheelDown = true; UpdateRing(input) end end)
				Darkness.InputBegan:Connect(function(input) if IsPrimaryInput(input) then SlideDown = true; UpdateSlide(input) end end)

				UserInputService.InputEnded:Connect(function(input)
					if IsPrimaryInput(input) then
						WheelDown = false
						SlideDown = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						if WheelDown then UpdateRing(input) end
						if SlideDown then UpdateSlide(input) end
					end
				end)

				Copy.MouseButton1Click:Connect(function()
					if setclipboard then
						setclipboard(colorHex.Text)
					end
				end)

				local function setcolor(tbl)
					local realcolor = Color3.fromHSV(tbl[1], tbl[2], tbl[3])
					colorHex.Text = ColorToHex(realcolor)
					colorpickerButton.BackgroundColor3 = realcolor
					Darkness.BackgroundColor3 = realcolor
					DarknessCircle.BackgroundColor3 = realcolor
					color = {tbl[1], tbl[2], tbl[3]}
					-- FIX: reposition circle handles to match the loaded color
					task.defer(function()
						local cx = RGBCircle.AbsoluteSize.X / 2
						local cy2 = RGBCircle.AbsoluteSize.Y / 2
						RGBCircle.Position = UDim2.new(math.clamp(1 - tbl[1], 0, 1), -cx, math.clamp(1 - tbl[2], 0, 1), -cy2)
						local darknessY = 1 - tbl[3]
						local dcy = DarknessCircle.AbsoluteSize.Y / 2
						DarknessCircle.Position = UDim2.new(0.5, 0, darknessY, -dcy)
					end)
				end

				setcolor({hue, sat, val})

				local obj = {}
				function obj:Set(c)
					local h2, s2, v2 = Color3.toHSV(NormalizeColor(c))
					setcolor({h2, s2, v2})
					InvokeCallback(callback, c)
				end
				function obj:Get()
					return Color3.fromHSV(color[1], color[2], color[3])
				end
				function obj:AddSettings() return MakeSettings(Colorpicker, nil, text) end
				RegisterConfigElement("colorpicker_", text, obj)
				CenterElement(Colorpicker)
				BindElementContext(Colorpicker, "colorpicker", text, obj, options.color)
				return obj
				end

			function SectionObj:AddAccordion(text)
				text = tostring(text or "Accordion")
				elemCount = elemCount + 1

				local DropdownSection = Instance.new('Frame')
				DropdownSection.Name = "Accordion"
				DropdownSection.Size = UDim2.new(1, 0, 0, 0)
				DropdownSection.BackgroundColor3 = Color3.fromRGB(21,24,36)
				DropdownSection.BackgroundTransparency = 1
				DropdownSection.LayoutOrder = elemCount
				DropdownSection.Parent = Elements

				local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
				UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
				UIAspectRatioConstraint.AspectRatio = 9
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
				UIAspectRatioConstraint.Parent = DropdownSection

				local TextArrow = Instance.new('ImageLabel')
				TextArrow.Name = "TextArrow"
				TextArrow.Position = UDim2.new(0.8699999737739563, 0, 0.1, 0)
				TextArrow.AnchorPoint = Vector2.new(0, 0)
				TextArrow.Size = UDim2.new(0.06, 0, 0.8, 0)
				TextArrow.BackgroundTransparency = 1
				TextArrow.Image = "rbxassetid://10709790948"
				TextArrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
				TextArrow.ImageTransparency = 0.10000000149011612
				TextArrow.ScaleType = Enum.ScaleType.Fit
				TextArrow.Rotation = 270
				TextArrow.Parent = DropdownSection

				local Text = Instance.new('TextLabel')
				Text.Name = "Text"
				Text.Position = UDim2.new(0.04800000041723251, 0, 0.30000001192092896, 0)
				Text.Size = UDim2.new(0.6600000262260437, 0, 0.5000000238418579, 0)
				Text.BackgroundColor3 = Color3.fromRGB(28,32,48)
				Text.BackgroundTransparency = 1
				Text.Text = text
				Text.TextColor3 = Color3.fromRGB(255, 255, 255)
				Text.TextScaled = true
				Text.Font = Enum.Font.SourceSansSemibold
				Text.TextTransparency = 0.10000000149011612
				Text.TextXAlignment = Enum.TextXAlignment.Left
				Text.Parent = DropdownSection

				local Open = Instance.new('TextButton')
				Open.Name = "Open"
				Open.Size = UDim2.new(1, 0, 1, 0)
				Open.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Open.BackgroundTransparency = 1
				Open.Text = ""
				Open.ZIndex = 10
				Open.Parent = DropdownSection

				local Section2Frame = Instance.new('Frame')
				Section2Frame.Name = "AccordionFrame"
				Section2Frame.Position = UDim2.new(0.02, 0, 1, 2 / GetMainFrameScale())
				Section2Frame.Size = UDim2.new(0.96, 0, 0, 0)
				Section2Frame.BackgroundColor3 = Color3.fromRGB(21, 24, 36)
				Section2Frame.BackgroundTransparency = 1
				Section2Frame.BorderSizePixel = 0
				Section2Frame.Visible = false
				Section2Frame.ZIndex = 5000
				Section2Frame.ClipsDescendants = false
				Section2Frame.AutomaticSize = Enum.AutomaticSize.None
				local S2Scale = New("UIScale", { Scale = 1 }, Section2Frame)
				Section2Frame.Parent = DropdownSection

				local UICorner = Instance.new('UICorner')
				UICorner.Name = "UICorner"
				UICorner.CornerRadius = UDim.new(0, 14)
				UICorner.Parent = Section2Frame

				local UIStroke = Instance.new('UIStroke')
				UIStroke.Name = "UIStroke"
				UIStroke.Color = Color3.fromRGB(44, 50, 72)
				UIStroke.Transparency = 0.45
				UIStroke.Thickness = 1
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = Section2Frame

				local Container = Instance.new('ScrollingFrame')
				Container.Name = "Container"
				Container.Position = UDim2.new(0.04, 0, 0, 3 / GetMainFrameScale())
				Container.Size = UDim2.new(0.92, 0, 1, -6 / GetMainFrameScale())
				Container.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
				Container.BackgroundTransparency = 1
				Container.AnchorPoint = Vector2.new(0, 0)
				Container.LayoutOrder = 1
				Container.ZIndex = 5001
				Container.Active = true
				Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
				Container.CanvasSize = UDim2.new()
				Container.ScrollingEnabled = false
				Container.ScrollingDirection = Enum.ScrollingDirection.Y
				Container.ScrollBarThickness = 0
				Container.ScrollBarImageTransparency = 0.5
				Container.ClipsDescendants = true
				Container.Parent = Section2Frame

				local UIListLayout = Instance.new('UIListLayout')
				UIListLayout.Name = "UIListLayout"
				UIListLayout.Padding = UDim.new(0, 3)
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				UIListLayout.Parent = Container
				WatchRowDividers(Container)

				-- single panel: the inner container is layout-only, no second card

				local function GetAccordionContentHeight()
					local measured = MeasureRowsHeight(Container)
					if measured > 0 then return measured end
					local rowCount = 0
					for _, child in ipairs(Container:GetChildren()) do
						if child:IsA("GuiObject") then rowCount = rowCount + 1 end
					end
					if rowCount <= 0 then return 0 end
					local estimated = EstimateRowsHeight(Container, rowCount, 7.5)
					if estimated > 0 then return estimated end
					return rowCount * 28 * GetMainFrameScale()
				end

				local function UpdateAccordionLayout()
					local scale = GetMainFrameScale()
					Section2Frame.Position = UDim2.new(0.02, 0, 1, 2 / scale)
					Container.Position = UDim2.new(0.04, 0, 0, 3 / scale)
					Container.Size = UDim2.new(0.92, 0, 1, -6 / scale)
				end

				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					ZIndex = 100,
					BorderSizePixel = 0,
				}, DropdownSection)

				local accordionOpen = false
				local accordionLayoutConnection = nil
				local accordionRefitConnection = nil
				local function getAccordionHeight()
					UpdateAccordionLayout()
					local scale = GetMainFrameScale()
					local contentVisual = GetAccordionContentHeight()
					local desiredVisual = math.max(34 * scale, contentVisual + 16 * scale)
					local maxVisual = math.max(34 * scale, MainFrame.AbsoluteSize.Y * 0.92)
					return math.min(desiredVisual, maxVisual) / scale
				end

				local function fitAccordionHeight()
					if not accordionOpen or not Section2Frame.Parent then return end
					Section2Frame.Size = UDim2.new(0.96, 0, 0, getAccordionHeight())
				end

				local function closeAccordion()
					accordionOpen = false
					if _openAccordionDropdown then _openAccordionDropdown() end
					ClosePopupsUnder(Section2Frame)
					UnregisterPopup(Section2Frame)
					Tween(Section2Frame, {Size = UDim2.new(0.96, 0, 0, 0), BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					Tween(TextArrow, {Rotation = 270}, 0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					task.delay(0.21, function() if not accordionOpen then Section2Frame.Visible = false end end)
					if _openAccordion == closeAccordion then _openAccordion = nil end
				end

				Open.MouseButton1Click:Connect(function()
					if accordionOpen then
						closeAccordion()
					else
						if _openAccordion then _openAccordion() end
						CloseAllPopupsExcept(Section2Frame)
						accordionOpen = true
						_openAccordion = closeAccordion
						Section2Frame.Visible = true
						Section2Frame.BackgroundTransparency = 1
						S2Scale.Scale = 0.94
						ApplyZIndexLadder(Section2Frame, 5000)
						local accordionHeight = getAccordionHeight()
						local accordionKnown = Vector2.new(
							math.max(DropdownSection.AbsoluteSize.X * 0.96, 1),
							math.min(accordionHeight * GetMainFrameScale(), math.max(MainFrame.AbsoluteSize.Y, 1)))
						Section2Frame.Size = UDim2.new(0.96, 0, 0, accordionHeight)
						PositionPopupWithinMain(Section2Frame, true, nil, nil, accordionKnown)
						Tween(TextArrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						RegisterPopup(Section2Frame, closeAccordion, Open)
						local function settle()
							if not accordionOpen or not Section2Frame.Parent then return end
							fitAccordionHeight()
						end
						task.defer(function()
							if not accordionOpen or not Section2Frame.Parent then return end
							fitAccordionHeight()
							Tween(Section2Frame, {BackgroundTransparency = 0}, 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
							Tween(S2Scale, {Scale = 1}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
						end)
						task.delay(0.05, settle)
						if not accordionRefitConnection then
							local frames = 0
							accordionRefitConnection = RunService.RenderStepped:Connect(function()
								frames = frames + 1
								if not accordionOpen then
									accordionRefitConnection:Disconnect()
									accordionRefitConnection = nil
									return
								end
								fitAccordionHeight()
								if frames >= 4 then
									accordionRefitConnection:Disconnect()
									accordionRefitConnection = nil
								end
							end)
						end
						if not accordionLayoutConnection then
							local okLayout, layout = pcall(function() return Container:FindFirstChildOfClass("UIListLayout") end)
							if okLayout and layout then
								pcall(function()
									accordionLayoutConnection = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
										task.defer(settle)
									end)
								end)
							end
						end
					end
				end)

				local AccordionObj = {}
				local accordionElemCount = 0

				function AccordionObj:AddToggle(text2, default, callback)
					accordionElemCount = accordionElemCount + 1
					local enabled = default == true

					local Toggle = New("Frame", {
						Name = "Toggle",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
					}, Container)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 7.5
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = Toggle

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.88, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						ZIndex = 100,
						BorderSizePixel = 0,
					}, Toggle)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Toggle)

					local Effect = New("Frame", {
						Name = "Effect",
						Position = UDim2.new(0.8400000143051147, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.11035999655723572, 0, 0.5600000023841858, 0),
						BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0),
						ZIndex = 101,
					}, Toggle)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
					New("UIStroke", { Transparency = 0.800000011920929, Thickness = 0.800000011920929 }, Effect)

					local Icon = New("Frame", {
						Name = "Icon",
						Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0),
						Size = UDim2.new(1, 0, 0.8999999761581421, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = enabled and 0 or 0.5,
						ZIndex = 102,
					}, Effect)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Icon)
					New("UIAspectRatioConstraint", {}, Icon)

					local Btn = New("TextButton", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 110,
					}, Toggle)

					local function Set(val)
						enabled = val == true
						Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(0, 0, 0) }, 0.25, Enum.EasingStyle.Quad)
						Tween(Icon, { Position = enabled and UDim2.new(0.55, 0, 0.04500000551342964, 0) or UDim2.new(0.05, 0, 0.04500000551342964, 0), BackgroundTransparency = enabled and 0 or 0.5 }, 0.25, Enum.EasingStyle.Back)
						InvokeCallback(callback, enabled)
					end

					Btn.MouseButton1Click:Connect(function() Set(not enabled) end)

					local obj = {}
					function obj:Set(v) Set(v) end
				function obj:Get() return enabled end
				function obj:AddSettings() return MakeSettings(Toggle, nil, text2) end
				RegisterConfigElement("accordion_toggle_", text2, obj)
				CenterElement(Toggle)
				BindElementContext(Toggle, "accordion_toggle", text2, obj, default)
					return obj
				end

				function AccordionObj:AddCheckbox(text2, default, callback)
					accordionElemCount = accordionElemCount + 1
					local enabled = default == true

					local CheckBoxToggle = New("Frame", {
						Name = "CheckBoxToggle",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
					}, Container)
					New("UIAspectRatioConstraint", {
						AspectRatio = 7.5,
						AspectType = Enum.AspectType.ScaleWithParentSize,
					}, CheckBoxToggle)

				

					local CheckBox = New("Frame", {
						Name = "CheckBox",
						Position = UDim2.new(0.04, 0, 0.3, 0),
						Size = UDim2.new(0.075, 0, 0.7, 0),
						BackgroundTransparency = 1,
						ZIndex = 101,
					}, CheckBoxToggle)
					New("UICorner", {}, CheckBox)
					New("UIAspectRatioConstraint", {}, CheckBox)

					local Check = New("ImageLabel", {
						Name = "Check",
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Image = "rbxassetid://138494545053627",
						ImageTransparency = enabled and 0.1 or 1,
						ZIndex = 101,
					}, CheckBox)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.15, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, CheckBoxToggle)

					local Btn = New("TextButton", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 110,
					}, CheckBoxToggle)

					local function Set(val)
						enabled = val == true
						Tween(Check, { ImageTransparency = enabled and 0.1 or 1 }, 0.2)
						InvokeCallback(callback, enabled)
					end

					Btn.MouseButton1Click:Connect(function() Set(not enabled) end)

					local obj = {}
					function obj:Set(v) Set(v) end
				function obj:Get() return enabled end
				function obj:AddSettings() return MakeSettings(CheckBoxToggle, nil, text2) end
				RegisterConfigElement("accordion_checkbox_", text2, obj)
				CenterElement(CheckBoxToggle)
				BindElementContext(CheckBoxToggle, "accordion_checkbox", text2, obj, default)
					return obj
				end

				-- New Selection style (popup with checkmark buttons) for accordion dropdowns
				function AccordionObj:AddDropdown(text2, options, default, callback)
					if type(default) == "function" then
						callback = default
						default = nil
					end
					options = NormalizeOptions(options)
					accordionElemCount = accordionElemCount + 1
					local selected = GetValidOption(options, default)
					local dropOpen = false
					local selectedBtns = {} -- track Selected checkmark buttons per option

					-- Selection row frame (matches new design: AspectRatio=10)
					local Selection = New("Frame", {
						Name = "Selection",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
						ClipsDescendants = false,
						ZIndex = 100,
					}, Container)
					New("UIAspectRatioConstraint", {
						AspectRatio = 7.5,
						AspectType = Enum.AspectType.ScaleWithParentSize,
					}, Selection)

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.05000000074505806, 0, 1, 0),
						Size = UDim2.new(0.8999999761581421, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						ZIndex = 100,
					}, Selection)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000041723251, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.6000000238418579, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Selection)

					-- Arrow indicator
					local SelArrow = New("ImageLabel", {
						Name = "TextArrow",
						Position = UDim2.new(0.8700000047683716,0,0.15000000596046448,0),
						Size = UDim2.new(0.10000000149011612, 0, 0.800000011920929, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Image = "rbxassetid://10709790948",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						ImageTransparency = 0.10000000149011612,
						ScaleType = Enum.ScaleType.Fit,
						Rotation = 270,
						ZIndex = 1000,
					}, Selection)

					-- TextDefault shows the currently selected value
					local TextDefault = New("TextLabel", {
						Name = "TextDefault",
						Position = UDim2.new(0.6400001645088196,0,0.2499999850988388,0),
						Size = UDim2.new(0.23000000417232513, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = options[1] or "Auto",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.5,
						ZIndex = 101,
						TextXAlignment = Enum.TextXAlignment.Right,
					}, Selection)

					-- Popup dropdown frame (new style: slides from right, position=(1,0,0,0))
					local DropPopup = New("Frame", {
						Name = "Dropdown",
						Position = UDim2.new(0.02,0,1,2),
						Size = UDim2.new(0.6899999737739563, 0, 0, 100),
						BackgroundColor3 = Color3.fromRGB(16,19,28),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 5000,
					}, Selection)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, DropPopup)
					New("UIStroke", {
						Color = Color3.fromRGB(28,32,48),
						Transparency = 0.800000011920929,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}, DropPopup)

					-- Inner container for buttons
					local DropContainer = New("ScrollingFrame", {
						Name = "Container",
						Position = UDim2.new(0.05000000074505806, 0, 0.10000000149011612, 0),
						Size = UDim2.new(0.8980000019073486, 0, 0, 96),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						ZIndex = 5000,
						Active = true,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(),
						ScrollingDirection = Enum.ScrollingDirection.Y,
						ScrollBarThickness = 2,
						ScrollBarImageTransparency = 0.5,
					}, DropPopup)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, DropContainer)
					New("UIStroke", {
						Color = Color3.fromRGB(28,32,48),
						Transparency = 0.800000011920929,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}, DropContainer)
					New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, DropContainer)

					local function closeDropdown2()
						dropOpen = false
						Tween(SelArrow, {Rotation = 270}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
						UnregisterPopup(DropPopup)
						SmoothClose(DropPopup, 0.18)
						if _openAccordionDropdown == closeDropdown2 then _openAccordionDropdown = nil end
					end

					local function updateCheckmarks()
						for opt, selBtn in pairs(selectedBtns) do
							if opt == selected then
								selBtn.Text = "✓"
								Tween(selBtn, { TextColor3 = mainColor }, 0.15)
							else
								selBtn.Text = ""
							end
						end
					end

					for i, opt in ipairs(options) do
						local BtnRow = New("Frame", {
							Name = "Buttons",
							Size = UDim2.new(1, 0, 0, 0),
							BackgroundColor3 = Color3.fromRGB(162, 162, 162),
							BackgroundTransparency = 1,
							ZIndex = 1001,
							LayoutOrder = i,
						}, DropContainer)
						New("UIAspectRatioConstraint", {
							AspectRatio = 6,
							AspectType = Enum.AspectType.ScaleWithParentSize,
						}, BtnRow)

						local Label = New("TextLabel", {
							Name = "Label",
							Position = UDim2.new(0, 0, 0.20000000298023224, 0),
							Size = UDim2.new(1, 0, 0.6990000009536743, 0),
							BackgroundColor3 = Color3.fromRGB(162, 162, 162),
							BackgroundTransparency = 1,
							Text = opt,
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextScaled = true,
							Font = Enum.Font.SourceSansSemibold,
							TextTransparency = 0.10000000149011612,
							ZIndex = 1002,
							TextXAlignment = Enum.TextXAlignment.Left,
						}, BtnRow)

						local SelBtn = New("TextButton", {
							Name = "Selected",
							Position = UDim2.new(0.800000011920929, 0, 0, 0),
							Size = UDim2.new(0.20000000298023224, 0, 0.800000011920929, 0),
							BackgroundColor3 = Color3.fromRGB(16,19,28),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = "",
							TextColor3 = Color3.fromRGB(26, 123, 255),
							TextScaled = true,
							ZIndex = 1004,
						}, BtnRow)
						New("UICorner", { CornerRadius = UDim.new(0, 5) }, SelBtn)

						selectedBtns[opt] = SelBtn

						-- Full-row click
						local RowBtn = New("TextButton", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Text = "",
							ZIndex = 1005,
						}, BtnRow)
						RowBtn.MouseButton1Click:Connect(function()
							selected = opt
							SetTrimmedText(TextDefault, opt); FitTextBeforeArrow(TextDefault, SelArrow)
							updateCheckmarks()
							closeDropdown2()
							InvokeCallback(callback, opt)
						end)
						SelBtn.MouseButton1Click:Connect(function()
							selected = opt
							SetTrimmedText(TextDefault, opt); FitTextBeforeArrow(TextDefault, SelArrow)
							updateCheckmarks()
							closeDropdown2()
							InvokeCallback(callback, opt)
						end)
					end

					-- Open button (invisible overlay on the row)
					local OpenBtn = New("TextButton", {
						Name = "OpenBtn",
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "",
						ZIndex = 500,
					}, Selection)

					OpenBtn.MouseButton1Click:Connect(function()
						if dropOpen then
							closeDropdown2()
						else
							CloseAllPopupsExcept(DropPopup)
							if _openAccordionDropdown then _openAccordionDropdown() end
							dropOpen = true
							_openAccordionDropdown = closeDropdown2
							local knownH = math.max(24, math.min(100, math.max(MainFrame.AbsoluteSize.Y, 1)))
							local knownW = math.max(Selection.AbsoluteSize.X * 0.96, 1)
							DropPopup.Size = UDim2.new(0.96, 0, 0, knownH)
							PositionPopupWithinMain(DropPopup, true, nil, nil, Vector2.new(knownW, knownH))
							SmoothOpen(DropPopup, 0, 0.2)
							Tween(SelArrow, {Rotation = 360}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
							RegisterPopup(DropPopup, closeDropdown2, OpenBtn)
						end
					end)

					local obj = {}
					function obj:Set(val, silent)
						val = GetValidOption(options, val)
						selected = val
						SetTrimmedText(TextDefault, val); FitTextBeforeArrow(TextDefault, SelArrow)
						updateCheckmarks()
						if not silent then InvokeCallback(callback, val) end
					end
					function obj:Get() return selected end
					function obj:AddSettings() return MakeSettings(Selection, "dropdown", text2) end
				if default ~= nil then obj:Set(GetValidOption(options, default), true) end
					RegisterConfigElement("accordion_dropdown_", text2, obj)
					CenterElement(Selection)
				BindElementContext(Selection, "accordion_dropdown", text2, obj, selected, options)
					return obj
				end

				function AccordionObj:AddSlider(text2, min, max, default, callback, suffix)
					accordionElemCount = accordionElemCount + 1
					if type(suffix) ~= "string" then suffix = "" end
					local value
					min, max, value = NormalizeRange(min, max, default)
					value = Quantize(value, min, max, GetSliderStep(min, max))
					local initRatio = (value - min) / (max - min)
					local dragging = false

					local Slider = New("Frame", {
						Name = "Slider",
						Size = UDim2.new(1, 0, 0, 0),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
						ZIndex = 100,
					}, Container)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 7.5
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = Slider

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.88, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						ZIndex = 1002,
						BorderSizePixel = 0,
					}, Slider)

					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.04800000086426735, 0, 0.30000001192092896, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Slider)

					local Effect = New("Frame", {
						Name = "Effect",
						Position = UDim2.new(0.4980000042915344, 0, 0.25, 0),
						Size = UDim2.new(0.5, 0, 0.6990000009536743, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						ZIndex = 101,
					}, Slider)

					local SliderValue = New("TextLabel", {
						Name = "SliderValue",
						Position = UDim2.new(0.6990000009536743, 0, 0.10000000149011612, 0),
						Size = UDim2.new(0.25, 0, 0.8080000281333923, 0),
						BackgroundColor3 = Color3.fromRGB(33,37,53),
						Text = FormatSliderValue(value, suffix),
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansSemibold,
						TextTransparency = 0.20000000298023224,
						ZIndex = 102,
					}, Effect)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, SliderValue)

					local Line = New("Frame", {
						Name = "Line",
						Active = true,
						Position = UDim2.new(0.03999999910593033, 0, 0.3190000057220459, 0),
						Size = UDim2.new(0.6000000238418579, 0, 0.24, 0),
						BackgroundColor3 = Color3.fromRGB(33,37,53),
						ZIndex = 101,
					}, Effect)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Line)

					local InLine = New("Frame", {
						Name = "InLine",
						Size = UDim2.new(0, 0, 1, 0),
						BackgroundColor3 = mainColor,
						ZIndex = 102,
					}, Line)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, InLine)

					local Trigger = New("TextButton", {
						Name = "Trigger",
						Position = UDim2.new(0.10000000149011612, 0, -1.8000000715255737, 0),
						Size = UDim2.new(1.1999999284744263, 0, 4.200000286102295, 0),
						AnchorPoint = Vector2.new(0.800000011920929, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                     BackgroundTransparency = 1,
						Active = false,
						Text = "",
						ZIndex = 103,
					}, Line)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Trigger)
					New("UIAspectRatioConstraint", {}, Trigger)

					local initialValue = value
					task.defer(function()
						if value ~= initialValue then return end
						InLine.Size = UDim2.fromScale(initRatio, 1)
						Trigger.Position = UDim2.new(initRatio, 0, -1.8000000715255737, 0)
					end)

					local function update(input)
						local pointer = GetInputPosition(input)
						local lineSize = Line.AbsoluteSize.X
						if lineSize <= 0 then return end
						local sizeScale = ClampRatio(pointer.X - Line.AbsolutePosition.X, lineSize)
						value = Quantize(((max - min) * sizeScale) + min, min, max, GetSliderStep(min, max))
						Tween(InLine, { Size = UDim2.fromScale(sizeScale, 1) }, 0.1)
						Trigger.Position = UDim2.new(sizeScale, 0, -1.8000000715255737, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						InvokeCallback(callback, value)
					end

					Line.InputBegan:Connect(function(input)
						if IsPrimaryInput(input) then
							dragging = true; update(input)
						end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if IsPrimaryInput(input) then
							dragging = false
						end
					end)
					UserInputService.InputChanged:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							update(input)
						end
					end)

					local obj = {}
					function obj:Set(val)
						local numeric = type(val) == "number" and val == val and val or min
						value = math.clamp(numeric, min, max)
						value = Quantize(value, min, max, GetSliderStep(min, max))
					local ratio = (value - min) / (max - min)
						InLine.Size = UDim2.fromScale(ratio, 1)
						Trigger.Position = UDim2.new(ratio, 0, -1.8000000715255737, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						InvokeCallback(callback, value)
					end
				function obj:Get() return value end
				function obj:AddSettings() return MakeSettings(Slider, "slider", text2) end
				RegisterConfigElement("accordion_slider_", text2, obj)
				CenterElement(Slider)
				BindElementContext(Slider, "accordion_slider", text2, obj, value, nil, min, max)
					return obj
				end

				function AccordionObj:AddColorpicker(text2, defaultColor, callback)
					accordionElemCount = accordionElemCount + 1
					local hue, sat, val = Color3.toHSV(NormalizeColor(defaultColor))
					local color = { hue, sat, val }
					local pickerOpen = false
					local WheelDown = false
					local SlideDown = false

					local Colorpicker = New("Frame", {
						Name = "Colorpicker",
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						LayoutOrder = accordionElemCount,
						ClipsDescendants = false,
						ZIndex = 100,
					}, Container)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 7.5
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = Colorpicker

					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.89, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						ZIndex = 101,
					}, Colorpicker)

					local colorpickerLabel = New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.new(0.048, 0, 0.3, 0),
						Size = UDim2.new(0.66, 0, 0.6, 0),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.SourceSansBold,
						TextTransparency = 0.1,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Colorpicker)

					local colorpickerButton = New("ImageButton", {
						Name = "colorpickerButton",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.875, 0, 0.57, 0),
						Size = UDim2.new(0.08, 0, 0.5, 0),
						BackgroundColor3 = NormalizeColor(defaultColor),
						BorderSizePixel = 0,
						Image = "",
						ZIndex = 110,
					}, Colorpicker)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, colorpickerButton)

					local colorpickerFrame = New("Frame", {
						Name = "colorpickerFrame",
						Position = UDim2.new(0.02,0,1,2),
						Size = UDim2.new(0.96, 0, 7, 0),
						BackgroundColor3 = Color3.fromRGB(15,17,26),
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 350,
						ClipsDescendants = false,
					}, Colorpicker)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, colorpickerFrame)
					New("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1 }, colorpickerFrame)
					New("UIAspectRatioConstraint", { AspectRatio = 1.1 }, colorpickerFrame)
					FitColorPickerPopup(colorpickerFrame)

					local RGB = New("ImageButton", {
						Name = "RGB",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.new(0.067, 0, 0.068, 0),
						Size = UDim2.new(0.74, 0, 0.74, 0),
						AutoButtonColor = false,
						Image = "rbxassetid://6523286724",
						ZIndex = 360,
					}, colorpickerFrame)

					local RGBCircle = New("ImageLabel", {
						Name = "RGBCircle",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Size = UDim2.new(0, 14, 0, 14),
						Image = "rbxassetid://3926309567",
						ImageRectOffset = Vector2.new(628, 420),
						ImageRectSize = Vector2.new(48, 48),
						ZIndex = 361,
					}, RGB)

					local Darkness = New("ImageButton", {
						Name = "Darkness",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Position = UDim2.new(0.831940293, 0, 0.068, 0),
						Size = UDim2.new(0.14, 0, 0.74, 0),
						AutoButtonColor = false,
						Image = "rbxassetid://156579757",
						ZIndex = 360,
					}, colorpickerFrame)

					local DarknessCircle = New("Frame", {
						Name = "DarknessCircle",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						Position = UDim2.new(0.5, 0, 0, 0),
						Size = UDim2.new(1.4, 0, 0, 5),
						ZIndex = 361,
					}, Darkness)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, DarknessCircle)

					local colorHex = New("TextLabel", {
						BackgroundColor3 = Color3.fromRGB(15,17,26),
						Position = UDim2.new(0.0717131495, 0, 0.855, 0),
						Size = UDim2.new(0.44, 0, 0.09, 0),
						Font = Enum.Font.ArialBold,
						Text = "#FFFFFF",
						TextColor3 = Color3.fromRGB(210, 215, 225),
						TextScaled = true,
						ZIndex = 360,
					}, colorpickerFrame)
					New("UICorner", { CornerRadius = UDim.new(0, 4) }, colorHex)

					local Copy = New("TextButton", {
						BackgroundColor3 = Color3.fromRGB(15,17,26),
						Position = UDim2.new(0.54, 0, 0.855, 0),
						Size = UDim2.new(0.39, 0, 0.09, 0),
						AutoButtonColor = false,
						Font = Enum.Font.ArialBold,
						Text = "Copy",
						TextColor3 = Color3.fromRGB(210, 215, 225),
						TextScaled = true,
						ZIndex = 360,
					}, colorpickerFrame)
					New("UICorner", { CornerRadius = UDim.new(0, 4) }, Copy)

					local function to_hex(c)
						return ColorToHex(c)
					end

					local function update()
						local c = Color3.fromHSV(color[1], color[2], color[3])
						colorHex.Text = to_hex(c)
						colorpickerButton.BackgroundColor3 = c
						Darkness.BackgroundColor3 = c
						DarknessCircle.BackgroundColor3 = c
						InvokeCallback(callback, c)
					end

						local function UpdateSlide(input)
						local ml = GetInputPosition(input)
						local y = ml.Y - Darkness.AbsolutePosition.Y
						local maxY = Darkness.AbsoluteSize.Y
if maxY <= 0 then return end
						if y < 0 then y = 0 end
						if y > maxY then y = maxY end
						y = ClampRatio(y, maxY)
						local cy = DarknessCircle.AbsoluteSize.Y / 2
						color = {color[1], color[2], 1 - y}
						local realcolor = Color3.fromHSV(color[1], color[2], color[3])
						DarknessCircle.BackgroundColor3 = realcolor
						DarknessCircle.Position = UDim2.new(0.5, 0, y, -cy)
						update()
					end

					local function UpdateRing(input)
						local ml = GetInputPosition(input)
						local x = ml.X - RGB.AbsolutePosition.X
						local y = ml.Y - RGB.AbsolutePosition.Y
						local maxX = RGB.AbsoluteSize.X
if maxX <= 0 then return end
						local maxY = RGB.AbsoluteSize.Y
if maxY <= 0 then return end
						if x < 0 then x = 0 end
						if x > maxX then x = maxX end
						if y < 0 then y = 0 end
						if y > maxY then y = maxY end
						x = ClampRatio(x, maxX)
						y = ClampRatio(y, maxY)
						local cx = RGBCircle.AbsoluteSize.X / 2
						local cy = RGBCircle.AbsoluteSize.Y / 2
						RGBCircle.Position = UDim2.new(x, -cx, y, -cy)
						color = {1 - x, 1 - y, color[3]}
						local realcolor = Color3.fromHSV(color[1], color[2], color[3])
						Darkness.BackgroundColor3 = realcolor
						DarknessCircle.BackgroundColor3 = realcolor
						update()
					end

					colorpickerButton.MouseButton1Click:Connect(function()
						pickerOpen = not pickerOpen
						AnimateColorPickerOpen(colorpickerFrame, colorpickerButton, pickerOpen, function(v) pickerOpen = v end)
						Tween(colorpickerLabel, { TextColor3 = pickerOpen and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182) }, 0.06)
					end)

					RGB.InputBegan:Connect(function(input) if IsPrimaryInput(input) then WheelDown = true; UpdateRing(input) end end)
					Darkness.InputBegan:Connect(function(input) if IsPrimaryInput(input) then SlideDown = true; UpdateSlide(input) end end)
						
					UserInputService.InputEnded:Connect(function(input)
						if IsPrimaryInput(input) then
							WheelDown = false
							SlideDown = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							if WheelDown then UpdateRing(input) end
							if SlideDown then UpdateSlide(input) end
						end
					end)

					Copy.MouseButton1Click:Connect(function()
						if setclipboard then setclipboard(colorHex.Text) end
					end)

					local function setcolor(tbl)
						local realcolor = Color3.fromHSV(tbl[1], tbl[2], tbl[3])
						colorHex.Text = ColorToHex(realcolor)
						colorpickerButton.BackgroundColor3 = realcolor
						Darkness.BackgroundColor3 = realcolor
						DarknessCircle.BackgroundColor3 = realcolor
						color = {tbl[1], tbl[2], tbl[3]}
						-- FIX: reposition circle handles to match the loaded color
						task.defer(function()
							local cx = RGBCircle.AbsoluteSize.X / 2
							local cy2 = RGBCircle.AbsoluteSize.Y / 2
							RGBCircle.Position = UDim2.new(math.clamp(1 - tbl[1], 0, 1), -cx, math.clamp(1 - tbl[2], 0, 1), -cy2)
							local darknessY = 1 - tbl[3]
							local dcy = DarknessCircle.AbsoluteSize.Y / 2
							DarknessCircle.Position = UDim2.new(0.5, 0, darknessY, -dcy)
						end)
					end

					setcolor({hue, sat, val})

					local obj = {}
					function obj:Set(c)
						local normalized = NormalizeColor(c)
						local h2, s2, v2 = Color3.toHSV(normalized)
						setcolor({h2, s2, v2})
						InvokeCallback(callback, normalized)
					end
				function obj:Get()
					return Color3.fromHSV(color[1], color[2], color[3])
				end
				function obj:AddSettings() return MakeSettings(Colorpicker, nil, text2) end
				-- FIX: register so LoadSavedConfig can find and restore this colorpicker
					RegisterConfigElement("accordion_colorpicker_", text2, obj)
					CenterElement(Colorpicker)
				BindElementContext(Colorpicker, "accordion_colorpicker", text2, obj, NormalizeColor(defaultColor))
					return obj
				end

				MakeReadableText(Section2Frame, 12, 18)
				return AccordionObj
			end

			MakeReadableText(Section, 12, 18)
			return SectionObj
		end

		-- SubTab system: indented entries in the left sidebar under the parent tab
		local subTabs = {}
		local activeSubTabIndex = nil
		local subTabContainer = nil

		local function EnsureSubTabContainer()
			if subTabContainer then return end

			tabOrder = tabOrder + 0.5
			subTabContainer = New("Frame", {
				Name = "SubTabContainer",
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false,
				LayoutOrder = TabButtonFrame.LayoutOrder + 1,
			}, Tab)
			subTabContainer:SetAttribute("TabIndex", tabIndex)
			New("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
			}, subTabContainer)

			local origHide = HideContent
			local origShow = ShowContent

			HideContent = function()
				origHide()
				subTabContainer.Visible = false
				for _, st in ipairs(subTabs) do
					st.left.Visible = false
					st.right.Visible = false
				end
			end

			ShowContent = function()
				-- Parent tab's own Left/Right stay hidden; sub-tabs own the content
				Left.Visible = false
				Right.Visible = false
				subTabContainer.Visible = true
				-- only one row may look selected: the active sub-tab
				TabButtonFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TabButtonFrame.BackgroundTransparency = 1
				TabIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				TabIcon.ImageTransparency = 0.6
				TabText.TextTransparency = 0.6
				for i, st in ipairs(subTabs) do
					if st.scale then
						local delay = math.min((i - 1) * 0.04, 0.3)
						task.delay(delay, function()
							if not subTabContainer.Visible then return end
							st.scale.Scale = 0.88
							Tween(st.scale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
						end)
					end
				end
				if activeSubTabIndex then
					local st = subTabs[activeSubTabIndex]
					if st then
					st.left.Position  = UDim2.new(0, 0, 0, 0)
					st.right.Position = UDim2.new(0, 0, 0, 0)
					st.left.Visible  = true
					st.right.Visible = true
					-- the content was faded out on hide: bring the labels back
					for _, column in ipairs({st.left, st.right}) do
						for _, section in ipairs(column:GetChildren()) do
							if section:IsA("GuiObject") then
								local list = section:FindFirstChild("Elements") or section:FindFirstChild("Container")
								if list and list:IsA("GuiObject") then
									for _, item in ipairs(list:GetChildren()) do
										if item:IsA("GuiObject") then
											for _, d in ipairs(item:GetDescendants()) do
												if d:IsA("TextLabel") or d:IsA("TextButton") then
													Tween(d, {TextTransparency = d.Name == "TextDefault" and 0.5 or 0}, 0.18)
												end
											end
										end
									end
								end
							end
						end
					end
					end
				elseif #subTabs > 0 then
					subTabs[1].activate()
				end
			end

			tabs[tabIndex].hide = HideContent
			tabs[tabIndex].show = ShowContent

		end

		function TabObj:AddSubTab(name, icon)
			name = tostring(name or "Subtab")
			if icon ~= nil and type(icon) ~= "string" then icon = "" end
			EnsureSubTabContainer()

			local stIndex = #subTabs + 1
			local isFirstST = stIndex == 1

			-- Content columns in TabHose
			local stLeft = New("ScrollingFrame", {
				Name = "STLeft_" .. name,
				Size = UDim2.new(0.47999998927116394, 0, 1, 0),
				BackgroundTransparency = 1,
				Visible = false,
				ClipsDescendants = true,
				Active = true,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 3,
			}, TabHose)
			New("UIListLayout", { Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder }, stLeft)

			local stRight = New("ScrollingFrame", {
				Name = "STRight_" .. name,
				Size = UDim2.new(0.47999998927116394, 0, 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Visible = false,
				ClipsDescendants = true,
				Active = true,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 3,
			}, TabHose)
			stLeft:SetAttribute("SearchName", name)
			stRight:SetAttribute("SearchName", name)
			stLeft:SetAttribute("TabIndex", tabIndex)
			stRight:SetAttribute("TabIndex", tabIndex)
			stLeft:SetAttribute("SubTabIndex", stIndex)
			stRight:SetAttribute("SubTabIndex", stIndex)
			New("UIListLayout", { Padding = UDim.new(0, 15), SortOrder = Enum.SortOrder.LayoutOrder }, stRight)

			-- Sidebar row — same size/shape as a normal tab button, just indented via padding
			local STRow = New("Frame", {
				Name = "STRow_" .. name,
				Size = UDim2.new(0.92, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = isFirstST and 0.9 or 1,
				LayoutOrder = stIndex,
			}, subTabContainer)
			New("UICorner", { CornerRadius = UDim.new(0, 5) }, STRow)
			New("UIAspectRatioConstraint", {
				AspectRatio = 4.6,
				AspectType = Enum.AspectType.ScaleWithParentSize,
			}, STRow)
			local STScale = New("UIScale", { Scale = 1 }, STRow)



			-- Optional icon
			local iconRef = nil
			if icon and icon ~= "" then
				iconRef = New("ImageLabel", {
					Name = "STIcon",
					Position = UDim2.new(0.1, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0.20000000298023224, 0, 0.6500000011920929, 0),
					BackgroundTransparency = 1,
					ImageColor3 = isFirstST and mainColor or Color3.fromRGB(200, 200, 210),
					ImageTransparency = isFirstST and 0 or 0.6,
				}, STRow)
				New("UIAspectRatioConstraint", { AspectRatio = 1 }, iconRef)
				GetImageData(icon, iconRef)
			end

			local STLabel = New("TextLabel", {
				Name = "STLabel",
				Position = UDim2.new(0.23000000417232513, 0, 0.235, 0),
				Size = UDim2.new(0.7070000171661377, 0, 0.510000011920929, 0),
				BackgroundTransparency = 1,
				Text = name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Font = Enum.Font.SourceSansSemibold,
				TextTransparency = isFirstST and 0 or 0.55,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, STRow)

			local STClick = New("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				ZIndex = 5,
			}, STRow)

			local function ActivateSubTab()
				CloseAllPopupsExcept(nil)
				for _, st in ipairs(subTabs) do
					st.row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					st.row.BackgroundTransparency = 1
					st.lbl.TextTransparency = 0.55
					if st.icon then
						st.icon.ImageColor3 = Color3.fromRGB(200, 200, 210)
						st.icon.ImageTransparency = 0.6
					end
					st.left.Visible  = false
					st.right.Visible = false
				end
				STRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				STRow.BackgroundTransparency = 0.9
				STLabel.TextTransparency = 0
				if iconRef then
					iconRef.ImageColor3 = mainColor
					iconRef.ImageTransparency = 0
				end
				STScale.Scale = 0.86
				Tween(STScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

				stLeft.Position  = UDim2.new(0, 0, 0, 0)
				stRight.Position = UDim2.new(0, 0, 0, 0)
				stLeft.Visible  = true
				stRight.Visible = true
				for _, column in ipairs({stLeft, stRight}) do
					for _, section in ipairs(column:GetChildren()) do
						if section:IsA("GuiObject") then
							section.BackgroundTransparency = 1
							Tween(section, {BackgroundTransparency = section.Name == "Section" and 1 or 0}, 0.28, Enum.EasingStyle.Quad)
							local list = section:FindFirstChild("Elements") or section:FindFirstChild("Container")
							if list and list:IsA("GuiObject") then
								local order = 0
								for _, item in ipairs(list:GetChildren()) do
									if item:IsA("GuiObject") then
										order = order + 1
										local texts = {}
										for _, d in ipairs(item:GetDescendants()) do
											if d:IsA("TextLabel") or d:IsA("TextButton") then table.insert(texts, d) end
										end
										for _, t in ipairs(texts) do t.TextTransparency = 1 end
										local delay = math.min((order - 1) * 0.03, 0.25)
										task.delay(delay, function()
											for _, t in ipairs(texts) do
												if t.Parent then Tween(t, {TextTransparency = t.Name == "TextDefault" and 0.5 or 0}, 0.2) end
											end
										end)
									end
								end
							end
						end
					end
				end

				activeSubTabIndex = stIndex
				if tabs[tabIndex] then tabs[tabIndex].activeSubTabIndex = stIndex end
				if ApplySearch then task.defer(function() ApplySearch(SearchBox.Text) end) end
			end

			table.insert(subTabs, {
				row  = STRow,
				lbl  = STLabel,
				icon = iconRef,
				scale = STScale,
				left = stLeft,
				right = stRight,
				activate = ActivateSubTab,
			})

			STClick.MouseButton1Click:Connect(ActivateSubTab)

			if isFirstST and activeTabIndex == tabIndex then
				Left.Visible = false
				Right.Visible = false
				subTabContainer.Visible = true
				ActivateSubTab()
			elseif not isFirstST then
				STRow.BackgroundTransparency = 1
				STLabel.TextTransparency = 1
				STScale.Scale = 0.7
				if iconRef then iconRef.ImageTransparency = 1 end
				task.defer(function()
					if not STRow.Parent then return end
					Tween(STRow, { BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					Tween(STLabel, { TextTransparency = 0.55 }, 0.3)
					Tween(STScale, { Scale = 1 }, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					if iconRef then Tween(iconRef, { ImageTransparency = 0.6 }, 0.3) end
				end)
			end

			-- SubTabObj: AddSection pipes into this sub-tab's stLeft/stRight
			local SubTabObj = {}
			local stSectionOrder = { left = 0, right = 0 }

			function SubTabObj:AddSection(title, side)
				side = side == "right" and "right" or "left"
				local savedLeft  = Left
				local savedRight = Right
				local savedOrder = { left = sectionOrder.left, right = sectionOrder.right }

				Left  = stLeft
				Right = stRight
				sectionOrder.left  = stSectionOrder.left
				sectionOrder.right = stSectionOrder.right

				local sec = TabObj:AddSection(title, side)

				stSectionOrder.left  = sectionOrder.left
				stSectionOrder.right = sectionOrder.right
				Left  = savedLeft
				Right = savedRight
				sectionOrder.left  = savedOrder.left
				sectionOrder.right = savedOrder.right
				return sec
			end

			return SubTabObj
		end

		return TabObj
	end

	function WindowObj:SetScale(value)
		if value == "Auto" then
			automaticScale = true
			UpdateScale()
			if syncScaleSelection then syncScaleSelection("Auto") end
			return UIScale.Scale
		end
		if type(value) ~= "number" or value ~= value then return UIScale.Scale end
		automaticScale = false
		manualScale = math.clamp(value, 0.5, 1.1)
		ApplyScale(manualScale)
		if syncScaleSelection then syncScaleSelection(tostring(math.round(manualScale * 100)) .. "%") end
		return UIScale.Scale
	end

	function WindowObj:GetScale()
		return UIScale.Scale
	end

	function WindowObj:SetLogoVisible(visible)
		if applyLogoProxy then applyLogoProxy(visible == true) end
		return logoVisible
	end

	function WindowObj:GetLogoVisible()
		return logoVisible
	end

	function WindowObj:GetMainFrame()
		return MainFrame
	end

	function WindowObj:GetMenuBind()
		if menuBindProxy then return menuBindProxy() end
		return nil
	end

	function WindowObj:SetMenuBind(key)
		if menuBindProxy then menuBindProxy(key) end
		return self
	end

	local defaultCustomization = {
		accentColor = mainColor,
		font = Enum.Font.SourceSansSemibold,
		textColor = Color3.fromRGB(255, 255, 255),
		sectionTitleSize = 13,
		elementTextSize = 12,
		watermarkText = "NEVERLOSE  •  UI",
		watermarkVisible = false,
		cornerRadius = 14,
		showContextDots = false,
	}

	local function eachText(root, fn)
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then fn(d) end
		end
	end

	local function applyCustomization()
		eachText(MainFrame, function(t)
			t.Font = customization.font
			t.TextColor3 = customization.textColor
		end)
		for _, d in ipairs(MainFrame:GetDescendants()) do
			if d:IsA("TextLabel") and d.Name == "SectionLabel" then
				d.TextSize = customization.sectionTitleSize
			end
		end
		if Watermark then
			Watermark.Text = customization.watermarkText
			Watermark.Visible = customization.watermarkVisible == true
		end
		for _, d in ipairs(MainFrame:GetDescendants()) do
			if d:IsA("UICorner") and d.Parent and d.Parent:IsA("GuiObject") then
				local name = d.Parent.Name
				if name == "Frame2" or name == "MainFrame" or name == "WindowSettingsFrame"
					or name == "ConfigMainFrame" or name == "RecentlyDeletedPanel" then
					d.CornerRadius = UDim.new(0, customization.cornerRadius)
				end
			end
		end
		for _, row in pairs(_windowContextTargets) do
			if row.dots then row.dots.Visible = customization.showContextDots == true end
		end
	end

	function WindowObj:SetCustomization(options)
		if type(options) ~= "table" then return customization end
		if options.accentColor and typeof(options.accentColor) == "Color3" then
			customization.accentColor = options.accentColor
			if applyMainColorProxy then applyMainColorProxy(options.accentColor) end
		end
		if options.font and typeof(options.font) == "EnumItem" then customization.font = options.font end
		if options.textColor and typeof(options.textColor) == "Color3" then customization.textColor = options.textColor end
		if type(options.sectionTitleSize) == "number" then
			customization.sectionTitleSize = math.clamp(options.sectionTitleSize, 8, 40)
		end
		if type(options.elementTextSize) == "number" then
			customization.elementTextSize = math.clamp(options.elementTextSize, 8, 40)
		end
		if type(options.watermarkText) == "string" then customization.watermarkText = options.watermarkText end
		if options.watermarkVisible ~= nil then customization.watermarkVisible = options.watermarkVisible == true end
		if type(options.cornerRadius) == "number" then
			customization.cornerRadius = math.clamp(options.cornerRadius, 0, 30)
		end
		if options.showContextDots ~= nil then customization.showContextDots = options.showContextDots == true end
		applyCustomization()
		return customization
	end

	function WindowObj:GetCustomization()
		return customization
	end

	local customMenus = {}

	function WindowObj:AddCustomMenu(name, builder, options)
		options = type(options) == "table" and options or {}
		name = tostring(name or "Custom")
		local panel = New("Frame", {
			Name = "CustomMenu_" .. name,
			Position = options.position or UDim2.new(0, 0, 0, 0),
			Size = options.size or UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = options.backgroundColor or Color3.fromRGB(15, 17, 26),
			BackgroundTransparency = options.backgroundTransparency or 0.8,
			BorderSizePixel = 0,
			Visible = false,
			Active = true,
			ClipsDescendants = options.clipsDescendants == true,
		}, options.parent or Frame2)
		New("UICorner", { CornerRadius = UDim.new(0, options.cornerRadius or customization.cornerRadius) }, panel)

		local api = {
			name = name,
			frame = panel,
			visible = false,
		}

		function api:Show()
			self.frame.Visible = true
			self.visible = true
			self.frame.BackgroundTransparency = 1
			Tween(self.frame, { BackgroundTransparency = (type(options.backgroundTransparency) == "number" and options.backgroundTransparency or 0.8) }, 0.2)
			return self
		end

		function api:Hide()
			self.visible = false
			Tween(self.frame, { BackgroundTransparency = 1 }, 0.18)
			task.delay(0.19, function()
				if not self.visible then self.frame.Visible = false end
			end)
			return self
		end

		function api:SetVisible(state)
			if state then return self:Show() end
			return self:Hide()
		end

		function api:IsVisible() return self.visible end

		function api:Destroy()
			if self.frame.Parent then self.frame:Destroy() end
			for i = #customMenus, 1, -1 do
				if customMenus[i] == self then table.remove(customMenus, i) end
			end
		end

		if type(builder) == "function" then
			local ok, err = pcall(builder, panel, api)
			if not ok then warn("[scr] AddCustomMenu(" .. name .. ") builder error: " .. tostring(err)) end
		end
		table.insert(customMenus, api)
		return api
	end

	WindowObj.AddCustomPanel = WindowObj.AddCustomMenu

	function WindowObj:GetCustomMenus()
		return customMenus
	end

	MakeReadableText(NeverloseCS2, 12, 18)
	CleanBorders(MainFrame)

	return WindowObj
end

return Library
