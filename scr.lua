-- Neverlose Roblox UI v30: compact function rows and corrected right-column bounds
-- Preserves register-limit/search fixes and restores full-size control rows.
local FONT = Enum.Font.SourceSansSemibold
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
	-- Semantic aliases keep common navigation names mapped to the same icon family.
	elseif name == "aimbot" or name == "rage" or name == "combat" then image.Image = "rbxassetid://107944169329467"
	elseif name == "legit" then image.Image = ""
	elseif name == "visuals" then image.Image = "rbxassetid://111273759419615"
	elseif name == "inventory" or name == "other" then image.Image = "rbxassetid://99581501168713"
	elseif name == "miscellaneous" or name == "settings" then image.Image = "rbxassetid://134488580093972"
	elseif name == "profile" or name == "account" then image.Image = "rbxassetid://10494577250"
	elseif name == "configs" or name == "config" then
		image.Image = NigImage; image.ImageRectOffset = Vector2.new(805,45); image.ImageRectSize = Vector2.new(35,35)
	end
end

local Library = {}
Library.__index = Library

-- Track running tweens by object/property so repeated hover and popup inputs do
-- not fight each other. Tweens for unrelated properties can still run in parallel.
local _liveTweensByObject = setmetatable({}, { __mode = "k" })
local function Tween(obj, props, t, style, dir, delay)
	if not obj or not obj.Parent or type(props) ~= "table" then return nil end
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out
	local bucket = _liveTweensByObject[obj]
	if not bucket then bucket = {}; _liveTweensByObject[obj] = bucket end
	local cancel = {}
	for property in pairs(props) do
		local running = bucket[property]
		if running then cancel[running] = true end
	end
	for running in pairs(cancel) do pcall(function() running:Cancel() end) end
	-- Cancelling a tween fires Completed(Cancelled), whose callback may remove the bucket.
	bucket = _liveTweensByObject[obj]
	if not bucket then bucket = {}; _liveTweensByObject[obj] = bucket end
	local ok, tween = pcall(function()
		return TweenService:Create(obj, TweenInfo.new(t or 0.2, style, dir, 0, false, delay or 0), props)
	end)
	if not ok or not tween then return nil end
	for property in pairs(props) do bucket[property] = tween end
	tween.Completed:Connect(function()
		local current = _liveTweensByObject[obj]
		if not current then return end
		for property in pairs(props) do
			if current[property] == tween then current[property] = nil end
		end
		if next(current) == nil then _liveTweensByObject[obj] = nil end
	end)
	tween:Play()
	return tween
end

local CenterElement
local SizeSliderChip

local STROKE = { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1 }
local strokeAuthored = setmetatable({}, { __mode = "k" })
local strokeScale = 1
local function ApplyStrokeScale(stroke, scale)
	if not stroke or not stroke:IsA("UIStroke") then return end
	local base = strokeAuthored[stroke]
	if not base then base = stroke.Thickness; strokeAuthored[stroke] = base end
	stroke.Thickness = 1
end
local function Stroke(parent, name)
	local stroke = Instance.new("UIStroke")
	stroke.Name = name or "Stroke"
	stroke.Color = STROKE.Color
	stroke.Transparency = STROKE.Transparency
	stroke.Thickness = STROKE.Thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	if parent then stroke.Parent = parent end
	ApplyStrokeScale(stroke, strokeScale)
	return stroke
end
local function RescaleStrokes(root, scale)
	strokeScale = scale
	if not root then return end
	ApplyStrokeScale(root, scale)
	for _, d in ipairs(root:GetDescendants()) do ApplyStrokeScale(d, scale) end
end

local function New(class, props, parent)
	local obj = Instance.new(class)
	if obj:IsA("GuiObject") and obj.BorderSizePixel == 1 then obj.BorderSizePixel = 0 end
	for k, v in pairs(props or {}) do
		pcall(function() obj[k] = v end)
	end
	if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
		obj.TextYAlignment = Enum.TextYAlignment.Center
		obj.TextScaled = false
		local roleSizes = { Title = 17, GameTitle = 11, TabLabel = 11, TabText = 15, SectionLabel = 11,
			TextToggle = 16, TextDropdown = 16, TextDefault = 15, TopBar = 15, SliderValue = 14,
			Username = 14, Daysleft = 12, SaveText = 15, HeaderLabel = 11, SearchBox = 13 }
		obj.TextSize = roleSizes[obj.Name] or ((props and props.TextSize) or 13)
		obj.Font = FONT
		if obj.Name == "GameTitle" or obj.Name == "TabLabel" or obj.Name == "SectionLabel"
			or obj.Name == "Daysleft" or obj.Name == "HeaderLabel" or obj.Name == "SearchEmptyState" then
			obj.TextColor3 = Color3.fromRGB(112, 116, 138)
		elseif obj.Name == "TextToggle" or obj.Name == "TextDropdown" or obj.Name == "TextDefault" or obj.Name == "TopBar" or obj.Name == "SaveText" then
			obj.TextColor3 = Color3.fromRGB(226, 228, 236)
		end
		if obj.Name == "TextToggle" or obj.Name == "TextDropdown" or obj.Name == "TextDefault" or obj.Name == "TopBar" or obj.Name == "TabText" or obj.Name == "SaveText" then
			obj.TextTruncate = Enum.TextTruncate.AtEnd
		end
	end
	if parent then obj.Parent = parent end
	if obj:IsA("UIStroke") then
		obj.Color = STROKE.Color
		obj.Transparency = STROKE.Transparency
		obj.Thickness = STROKE.Thickness
		obj.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ApplyStrokeScale(obj, strokeScale)
	end
	AddTextConstraint(obj, 7, 16)
	return obj
end

-- Rounded hover styling for function rows.
local function AttachRowHover(row)
	if not row or not row:IsA("GuiObject") or row:GetAttribute("NLRowHoverAttached") then return end
	local ok, baseTransparency = pcall(function() return row.BackgroundTransparency end)
	if not ok or type(baseTransparency) ~= "number" or baseTransparency < 0.98 then return end
	local baseColor = row.BackgroundColor3
	row:SetAttribute("NLRowHoverAttached", true)
	if not row:FindFirstChildOfClass("UICorner") then
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
	end
	local hoverStroke = row:FindFirstChild("NLRowHoverStroke")
	if not hoverStroke then
		hoverStroke = Stroke(row, "NLRowHoverStroke")
		hoverStroke.Transparency = 1
	end
	row.MouseEnter:Connect(function()
		if not row.Parent then return end
		Tween(row, { BackgroundColor3 = Color3.fromRGB(245, 247, 255), BackgroundTransparency = 0.955 }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		Tween(hoverStroke, { Transparency = 0.82 }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end)
	row.MouseLeave:Connect(function()
		if not row.Parent then return end
		Tween(row, { BackgroundColor3 = baseColor, BackgroundTransparency = baseTransparency }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		Tween(hoverStroke, { Transparency = 1 }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	end)
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
	local sliderEffect = effect and effect:IsA("GuiObject") and effect:FindFirstChild("Line") and effect:FindFirstChild("SliderValue")
	if effect and effect:IsA("GuiObject") then
		if effect:FindFirstChild("Icon") then
			effect.AnchorPoint = Vector2.new(1, 0.5)
			effect.Position = UDim2.new(1, -14, 0.5, 0)
			effect.Size = UDim2.fromOffset(33, 20)
		elseif sliderEffect then
			if SizeSliderChip then SizeSliderChip(effect, effect:FindFirstChild("Line"), effect:FindFirstChild("SliderValue")) end
		else
			place(effect, 0.5, 0.7)
		end
	end
	if not sliderEffect then
		place(el:FindFirstChild("Line"), 0.5, 0.24)
		place(el:FindFirstChild("SliderValue"), 0.5, 0.8)
	end
	local cp = el:FindFirstChild("colorpickerButton")
	if cp and cp:IsA("GuiObject") then
		cp.AnchorPoint = Vector2.new(1, 0.5)
		cp.Position = UDim2.new(1, -14, 0.5, 0)
		cp.Size = UDim2.fromOffset(18, 18)
	end
	local rowLabel = el:FindFirstChild("TextToggle") or el:FindFirstChild("TextDropdown")
	if rowLabel and rowLabel:IsA("GuiObject") then
		local width = 0.55
		if el.Name == "Dropdown" or sliderEffect then width = 0.42 end
		if el:FindFirstChild("ColorpickerOpenButton") then width = 0.36 end
		if effect and effect:FindFirstChild("Icon") and cp then width = 0.36 end
		rowLabel.Size = UDim2.new(width, 0, 0.5, 0)
		rowLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end
	place(el:FindFirstChild("DropdownArrow") or el:FindFirstChild("TextboxArrow"), 0.5, 0.5)
end

local ELLIPSIS = "..."
local TextService = game:GetService("TextService")
local MEASURE_SIZE = Vector2.new(10000, 10000)

local function MeasureText(text, fontSize, font)
	local ok, size = pcall(TextService.GetTextSize, TextService, text, fontSize or 14, font or FONT, MEASURE_SIZE)
	if ok and size then return size.X end
	return 0
end

SizeSliderChip = function(effect, line, value)
	if not effect or not line or not value or not effect.Parent then return end
	local textWidth = MeasureText(tostring(value.Text or ""), 14, FONT)
	local chipWidth = math.max(30, math.ceil(textWidth) + 10)
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.new(1, 0, 0.5, 0)
	value.Size = UDim2.fromOffset(chipWidth, 22)
	value.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	value.TextScaled = false
	value.TextSize = 14
	value.Font = FONT
	value.TextColor3 = Color3.fromRGB(255, 255, 255)
	value.TextTransparency = 0
	value.TextXAlignment = Enum.TextXAlignment.Center
	effect.AnchorPoint = Vector2.new(0, 0.5)
	effect.Position = UDim2.new(0, 150, 0.5, 0)
	effect.Size = UDim2.new(1, -164, 0, 22)
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.Size = UDim2.new(1, -(chipWidth + 10), 0, 3)
	line.BackgroundColor3 = Color3.fromRGB(45, 48, 64)
	line.BorderSizePixel = 0
	if not value:GetAttribute("NLSliderChipWatch") then
		value:SetAttribute("NLSliderChipWatch", true)
		value:GetPropertyChangedSignal("Text"):Connect(function()
			if value.Parent and effect.Parent then task.defer(function()
				if value.Parent and effect.Parent then SizeSliderChip(effect, line, value) end
			end) end
		end)
	end
end

local function BindKeyName(key)
	if not key then return "—" end
	local n
	if type(key) == "string" then
		n = key
	else
		local ok, keyName = pcall(function() return key.Name end)
		if ok then n = keyName end
	end
	if type(n) ~= "string" then return tostring(key) end
	if n == "MouseButton3" then return "Mouse 3" end
	if n == "MouseButton4" then return "Mouse 4" end
	if n == "MouseButton5" then return "Mouse 5" end
	if n == "MouseWheelUp" then return "Wheel Up" end
	if n == "MouseWheelDown" then return "Wheel Down" end
	return n
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
	local font = label.Font or FONT
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



local Z_BASE = 10000

-- ============================================================================
-- PATCH 1: THEME tokens (from [G].txt §1)
-- ============================================================================
local THEME = {
	plate = Color3.fromRGB(20, 23, 34),
	row = Color3.fromRGB(28, 31, 45),
	stroke = Color3.fromRGB(255, 255, 255),
	strokeAlpha = 0.92,
	text = Color3.fromRGB(226, 228, 236),
	dim = Color3.fromRGB(112, 116, 138),
	danger = Color3.fromRGB(233, 90, 110),
	radius = 12,
}

local _popupZStep = 0

local function TweenShadowLayers(frame, show, dur, dir)
	for _, node in ipairs(frame:GetDescendants()) do
		if node:GetAttribute("IsShadowLayer") then
			local alpha = node:GetAttribute("ShadowAlpha") or 0.8
			Tween(node, { BackgroundTransparency = show and alpha or 1 }, dur or 0.2, Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
		end
	end
end

local Z_RUNG = 100
local function NextPopupZ()
	_popupZStep = _popupZStep + 1
	if _popupZStep > 40 then _popupZStep = 1 end
	return Z_BASE + _popupZStep * Z_RUNG
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
			if instance:GetAttribute("IsShadowLayer") then
				instance.ZIndex = base + depth - 2
			end
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
			if listFrame:GetAttribute("NLGroupOutlineInset") and not child:GetAttribute("NLGroupInsetApplied") then
				-- UIPadding already insets the row. An extra -4 offset squeezed
				-- controls and left uneven spacing along the card outline.
				child:SetAttribute("NLGroupInsetApplied", true)
			end
			local divider = child:FindFirstChild("Lines")
			if divider and divider:IsA("GuiObject") then
				divider.Visible = true
				divider.Position = UDim2.new(0, 14, 1, -1)
				divider.Size = UDim2.new(1, -28, 0, 1)
				divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				divider.BackgroundTransparency = 0.93
				divider.BorderSizePixel = 0
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
		task.wait(2)
		for i = #_watchedDividers, 1, -1 do
			local frame = _watchedDividers[i]
			if not frame or not frame.Parent then table.remove(_watchedDividers, i) end
		end
	end
end)

-- Preserve each widget's authored alpha and reveal real content rows with a
-- short, staggered fade. State is cached per instance so tab switches do not
-- overwrite intentionally muted labels, selected states, or control styling.
local _contentAlphaState = setmetatable({}, { __mode = "k" })
local _contentRevealTokens = setmetatable({}, { __mode = "k" })

local function ContentAlphaTargets(object)
    local state = _contentAlphaState[object]
    if state then return state end
    state = {}
    -- Only text and strokes are animated on rows. Background/image alpha can
    -- encode live states (checkboxes, toggles, previews), so they stay untouched.
    if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and object.Text ~= "" then
        state.TextTransparency = object.TextTransparency
    end
    if object:IsA("UIStroke") and object.Name ~= "GroupOutline" then
        state.Transparency = object.Transparency
    end
    _contentAlphaState[object] = state
    return state
end

local function HasVisiblePath(object, root)
    local current = object
    while current and current ~= root do
        if current:IsA("GuiObject") and not current.Visible then return false end
        current = current.Parent
    end
    return current == root
end

local function RevealContentRows(elements)
    if not elements or not elements.Parent or not elements:IsA("GuiObject") or not elements.Visible then return end
    local token = (_contentRevealTokens[elements] or 0) + 1
    _contentRevealTokens[elements] = token
    local rows = {}
    for _, child in ipairs(elements:GetChildren()) do
        if child:IsA("GuiObject") then table.insert(rows, child) end
    end
    table.sort(rows, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    for index, row in ipairs(rows) do
        if row.Visible then
            local delaySeconds = math.min((index - 1) * 0.012, 0.10)
            task.delay(delaySeconds, function()
                if not elements.Parent or not row.Parent or _contentRevealTokens[elements] ~= token then return end
                local objects = { row }
                for _, descendant in ipairs(row:GetDescendants()) do
                    table.insert(objects, descendant)
                end
                for _, object in ipairs(objects) do
                    if object.Parent and HasVisiblePath(object, elements) then
                        local targets = ContentAlphaTargets(object)
                        local props = {}
                        for property, target in pairs(targets) do
                            if type(target) == "number" and target < 0.995 then
                                props[property] = target
                                pcall(function() object[property] = 1 end)
                            end
                        end
                        if next(props) then
                            Tween(object, props, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                        end
                    end
                end
            end)
        end
    end
end

local function AnimateSectionColumn(column)
    if not column or not column.Parent or not column.Visible then return end
    local token = (column:GetAttribute("NLSectionMotionToken") or 0) + 1
    column:SetAttribute("NLSectionMotionToken", token)
    local sections = {}
    for _, section in ipairs(column:GetChildren()) do
        if section:IsA("GuiObject") and section.Visible then
            table.insert(sections, section)
        end
    end
    table.sort(sections, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    for index, section in ipairs(sections) do
        local delaySeconds = math.min((index - 1) * 0.018, 0.054)
        task.delay(delaySeconds, function()
            if not column.Parent or not column.Visible or column:GetAttribute("NLSectionMotionToken") ~= token then return end
            if not section.Parent or not section.Visible then return end
            -- Keep text at its authored opacity. The former fade-to-transparent pass
            -- was responsible for one-frame label flashes on tab changes.
            -- Keep typography at native scale: fractional UIScale transitions can soften glyphs.
            local motionScale = section:FindFirstChild("SectionMotionScale")
            if motionScale and motionScale:IsA("UIScale") then motionScale.Scale = 1 end

            local list = section:FindFirstChild("Elements") or section:FindFirstChild("Container")
            if list and list:IsA("GuiObject") then
                local outline = list:FindFirstChild("GroupOutline")
                if outline and outline:IsA("UIStroke") then
                    local target = outline:GetAttribute("NLBaseTransparency")
                    if type(target) ~= "number" then
                        target = outline.Transparency
                        outline:SetAttribute("NLBaseTransparency", target)
                    end
                    outline.Transparency = math.min(0.84, target + 0.16)
                    Tween(outline, { Transparency = target }, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                end
            end
            local heading = section:FindFirstChild("SectionLabel", true)
            if heading and heading:IsA("TextLabel") then
                local baseColor = heading:GetAttribute("NLBaseTextColor")
                if typeof(baseColor) ~= "Color3" then
                    baseColor = heading.TextColor3
                    heading:SetAttribute("NLBaseTextColor", baseColor)
                end
                heading.TextColor3 = Color3.fromRGB(190, 199, 224)
                Tween(heading, { TextColor3 = baseColor }, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            end
        end)
    end
end

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
	suffix = tostring(suffix or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local text
	if string.find(suffix, "°", 1, true) then
		text = string.format("%.1f", value)
	elseif math.abs(value - math.round(value)) < 0.0001 then
		text = tostring(math.round(value))
	else
		text = string.format("%.1f", value)
	end
	return text .. (suffix or "")
end

local RepositionOpenPopups
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
		if RepositionOpenPopups then RepositionOpenPopups() end
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
					local token = (frame:GetAttribute("PopupToken") or 0) + 1
					frame:SetAttribute("PopupToken", token)
					Tween(frame, { BackgroundTransparency = 1 }, 0.18)
					TweenShadowLayers(frame, false, 0.18, Enum.EasingDirection.In)
					task.delay(0.19, function()
						if not frame.Parent or frame:GetAttribute("PopupToken") ~= token then return end
						frame.Visible = false
						local home = frame.Parent
						if home and home:IsA("GuiObject") then ApplyZIndexLadder(frame, home.ZIndex) end
					end)
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

-- Tween instances cannot be stored as Roblox attributes; keep live popup tweens
-- in a weak-key table so destroyed frames do not remain referenced.
local _activePopupTweens = setmetatable({}, { __mode = "k" })

local function CancelPopupTween(frame)
	if not frame then return end
	local running = _activePopupTweens[frame]
	_activePopupTweens[frame] = nil
	if running then
		pcall(function() running:Cancel() end)
	end
end

local function PlayPopupTween(frame, info, props)
	if not frame or not frame.Parent then return end
	local ok, tween = pcall(function() return TweenService:Create(frame, info, props) end)
	if not ok or not tween then return end
	_activePopupTweens[frame] = tween
	tween.Completed:Connect(function()
		if _activePopupTweens[frame] == tween then
			_activePopupTweens[frame] = nil
		end
	end)
	tween:Play()
end

local function GetPopupScale(frame)
	if not frame or not frame.Parent then return nil end
	-- Reuse the animation scale on every opening. Checking for any UIScale first
	-- made _PopScale work once, then silently disabled future open/close motion.
	local pop = frame:FindFirstChild("_PopScale")
	if pop and pop:IsA("UIScale") then return pop end
	local existing = frame:FindFirstChildOfClass("UIScale")
	if existing then return nil end
	return New("UIScale", { Name = "_PopScale", Scale = 1 }, frame)
end

local function SmoothOpen(frame, targetAlpha, dur, style, dir)
	if not frame or not frame.Parent then return end
	local token = (frame:GetAttribute("PopupToken") or 0) + 1
	frame:SetAttribute("PopupToken", token)
	CancelPopupTween(frame)
	frame.BackgroundTransparency = 1
	frame.Visible = true
	TweenShadowLayers(frame, true, dur or 0.2)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		if frame:GetAttribute("StrokeTarget") == nil then
			frame:SetAttribute("StrokeTarget", stroke.Transparency)
		end
		stroke.Transparency = 1
		Tween(stroke, { Transparency = frame:GetAttribute("StrokeTarget") }, dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
	local scale = GetPopupScale(frame)
	if scale then
		scale.Scale = 0.965
		Tween(scale, { Scale = 1 }, dur or 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end
	PlayPopupTween(frame, TweenInfo.new(dur or 0.17, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), {BackgroundTransparency = targetAlpha})
end

local function SmoothClose(frame, dur, cb)
	if not frame or not frame.Parent then return end
	local token = (frame:GetAttribute("PopupToken") or 0) + 1
	frame:SetAttribute("PopupToken", token)
	CancelPopupTween(frame)
	TweenShadowLayers(frame, false, dur or 0.18, Enum.EasingDirection.In)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		Tween(stroke, { Transparency = 1 }, dur or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	local scale = GetPopupScale(frame)
	if scale then
		Tween(scale, { Scale = 0.985 }, dur or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	PlayPopupTween(frame, TweenInfo.new(dur or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
	task.delay((dur or 0.14) + 0.01, function()
		if frame.Parent and frame:GetAttribute("PopupToken") == token then
			frame.Visible = false
			if scale then scale.Scale = 1 end
			local home = frame.Parent
			if home and home:IsA("GuiObject") then ApplyZIndexLadder(frame, home.ZIndex) end
			if cb then cb() end
		end
	end)
end

function Library:AddWindow(hubTitle, hubImage, gameTitle)
	hubTitle = tostring(hubTitle or "Neverlose")
	hubImage = tostring(hubImage or "")
	gameTitle = tostring(gameTitle or "Counter Strike 2")
	if string.lower(hubTitle) == "neverlose" and string.lower(gameTitle) == "blockstrike" then
		hubTitle, gameTitle = gameTitle, hubTitle
	end
	local daysLeft = "Lifetime"

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

	local mainColor = Color3.fromRGB(78, 131, 255)
	local tabs = {}
	local activeTabIndex = nil
	local tabOrder = 0
	local WindowObj = {}
	local _coloredElements = {}
	local logoVisible = true
	local customization = {
		font = FONT,
		textColor = Color3.fromRGB(226, 228, 236),
		sectionTitleSize = 11,
		sectionTitleColor = Color3.fromRGB(112, 116, 138),
		sectionTitleTransparency = 0,
		watermarkText = "NEVERLOSE  •  UI",
		watermarkVisible = false,
		cornerRadius = 12,
		showContextDots = false,
	}

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
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
	}, screenGuiParent)





	local MainFrame = New("Frame", {
		Name = "MainFrame",
		Active = true,
		Draggable = false,
		AnchorPoint = Vector2.new(0.5, 0.43),
		Size = UDim2.new(0.78, 0, 0.78, 0),
		Position = UDim2.new(0.5, 0, 0.43, 0),
	BackgroundColor3 = Color3.fromRGB(13, 15, 22),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	}, NeverloseCS2)
	local MainFrameUIScale
	local windowTargetSize = MainFrame.Size
	local windowAnimSize = UDim2.new(
		windowTargetSize.X.Scale * 0.97, windowTargetSize.X.Offset * 0.97,
		windowTargetSize.Y.Scale * 0.97, windowTargetSize.Y.Offset * 0.97
	)
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
    Font = FONT,
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
	do local windowStroke = Stroke(MainFrame, "WindowOutline"); windowStroke.Transparency = 0.95 end
	local DragHandle = New("Frame", {
		Name = "DragHandle",
		Position = UDim2.new(0.2, 0, 0, 0),
		Size = UDim2.new(0.6, 0, 0, 54),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 1,
	}, MainFrame)
	New("UISizeConstraint", {
		MinSize = Vector2.new(220, 180),
		MaxSize = Vector2.new(798, 610),
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
		if popup.AbsoluteSize.X <= 0 or popup.AbsoluteSize.Y <= 0 then return end
		local scaleX, scaleY = GetVisualScale(popup)
		local position = popup.Position
		local dx = (x - popup.AbsolutePosition.X) / scaleX
		local dy = (y - popup.AbsolutePosition.Y) / scaleY
		if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then return end
		popup.Position = UDim2.new(position.X.Scale, position.X.Offset + dx, position.Y.Scale, position.Y.Offset + dy)
	end

	local function PopupSafeArea()
		local gui = MainFrame and MainFrame.Parent
		if gui and gui:IsA("ScreenGui") and gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0 then
			return gui.AbsolutePosition, gui.AbsoluteSize
		end
		if MainFrame and MainFrame.AbsoluteSize.X > 0 and MainFrame.AbsoluteSize.Y > 0 then
			return MainFrame.AbsolutePosition, MainFrame.AbsoluteSize
		end
		return Vector2.new(0, 0), Vector2.new(0, 0)
	end

	local function ConstrainPopupToMainFrame(popup, margin, knownSize)
		margin = type(margin) == "number" and math.max(0, margin) or 6
		if not popup or not popup.Parent or not popup:IsA("GuiObject") then return end
		local size = knownSize or popup.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end
		local mainPosition, mainSize = PopupSafeArea()
		if mainSize.X <= 0 or mainSize.Y <= 0 then return end
		local minX = mainPosition.X + margin
		local minY = mainPosition.Y + margin
		local maxX = mainPosition.X + mainSize.X - size.X - margin
		local maxY = mainPosition.Y + mainSize.Y - size.Y - margin
		if maxX < minX then minX, maxX = mainPosition.X, mainPosition.X end
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

		local function ForceLiftClipping(popup)
			local current = popup and popup.Parent
			while current and current ~= MainFrame do
				pcall(function() current.ClipsDescendants = false end)
				current = current.Parent
			end
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
		local mainPosition, mainSize = PopupSafeArea()
		if mainSize.X <= 0 or mainSize.Y <= 0 or parentSize.X <= 0 or parentSize.Y <= 0 then return end
		local popupSize = knownSize or popup.AbsoluteSize
		if popupSize.X <= 0 or popupSize.Y <= 0 then return end
		local edge = type(margin) == "number" and math.max(0, margin) or 6
		local minX = mainPosition.X + edge
		local minY = mainPosition.Y + edge
		local maxX = mainPosition.X + mainSize.X - popupSize.X - edge
		local maxY = mainPosition.Y + mainSize.Y - popupSize.Y - edge
		if maxX < minX then minX, maxX = mainPosition.X, mainPosition.X end
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

	RepositionOpenPopups = function()
		local copy = {}
		for i, entry in ipairs(_openPopups) do copy[i] = entry end
		for _, entry in ipairs(copy) do
			local frame = entry.frame
			if frame and frame.Parent and frame.Visible then
				ConstrainPopupToMainFrame(frame, 6)
			end
		end
	end

	local function PositionPopupWithinMain(popup, preferBelow, margin, anchorOverride, knownSize)
		if not popup or not popup.Parent then return end
		RememberPopupClipping(popup)
		local wasVisible = popup.Visible
		local savedTransparency = popup.BackgroundTransparency
		if not wasVisible then
			popup.Visible = true
			popup.BackgroundTransparency = 1
		end
		positionPopupNow(popup, preferBelow, margin, anchorOverride, knownSize)
		ConstrainPopupToMainFrame(popup, margin, knownSize)
		if not wasVisible then
			popup.BackgroundTransparency = savedTransparency
			popup.Visible = false
			task.defer(function()
				if popup.Parent and popup.Visible then
					PositionPopupWithinMain(popup, preferBelow, margin, anchorOverride)
				end
			end)
		end
	end

	AcrylicBlur.CreateColorPicker = function(anchorButton, initialColor, onChange)
		local currentColor = NormalizeColor(initialColor)
		local hue, saturation, value = Color3.toHSV(currentColor)
		local dragPart = nil
		local isOpen = false

		local frame = New("Frame", {
			Name = "ColorPickerFrame",
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(212, 214),
			BackgroundColor3 = Color3.fromRGB(17, 19, 28),
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			Visible = false,
			ClipsDescendants = false,
			ZIndex = Z_BASE + 800,
		}, MainFrame)
		New("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
		Stroke(frame, "ColorPickerOutline")
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
		}, frame)
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, frame)

		local svSquare = New("ImageButton", {
			Name = "SVSquare",
			Size = UDim2.fromOffset(192, 136),
			BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = "",
			ClipsDescendants = true,
			LayoutOrder = 1,
			ZIndex = Z_BASE + 801,
		}, frame)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, svSquare)
		local svWhite = New("Frame", {
			Name = "SVWhite",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 802,
		}, svSquare)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, svWhite)
		New("UIGradient", {
			Rotation = 0,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, svWhite)
		local svBlack = New("Frame", {
			Name = "SVBlack",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 803,
		}, svSquare)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, svBlack)
		New("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}, svBlack)

		local svShadow = New("Frame", {
			Name = "SVCursorShadow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(saturation, 0, 1 - value, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 804,
		}, svSquare)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, svShadow)
		local svShadowStroke = Stroke(svShadow, "SVCursorShadowStroke")
		svShadowStroke.Color = Color3.fromRGB(10, 12, 18)
		svShadowStroke.Transparency = 0
		svShadowStroke.Thickness = 1
		local svCursor = New("Frame", {
			Name = "SVCursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(saturation, 0, 1 - value, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 805,
		}, svSquare)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, svCursor)
		local svCursorStroke = Stroke(svCursor, "SVCursorStroke")
		svCursorStroke.Color = Color3.fromRGB(255, 255, 255)
		svCursorStroke.Transparency = 0
		svCursorStroke.Thickness = 2

		local hueBar = New("ImageButton", {
			Name = "HueBar",
			Size = UDim2.fromOffset(192, 10),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = "",
			ClipsDescendants = false,
			Active = true,
			LayoutOrder = 2,
			ZIndex = Z_BASE + 801,
		}, frame)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, hueBar)
		New("UIGradient", {
			Name = "HueSpectrum",
			Rotation = 0,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
		}, hueBar)
		local hueThumb = New("Frame", {
			Name = "HueThumb",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(hue, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 805,
		}, hueBar)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, hueThumb)
		local hueThumbStroke = Stroke(hueThumb, "HueThumbStroke")
		hueThumbStroke.Color = Color3.fromRGB(17, 19, 28)
		hueThumbStroke.Transparency = 0.05
		hueThumbStroke.Thickness = 1

		local hexRow = New("Frame", {
			Name = "HexRow",
			Size = UDim2.fromOffset(192, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			ZIndex = Z_BASE + 801,
		}, frame)
		local hexField = New("Frame", {
			Name = "HexField",
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(156, 28),
			BackgroundColor3 = Color3.fromRGB(28, 31, 45),
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 802,
		}, hexRow)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, hexField)
		local hexPreview = New("Frame", {
			Name = "HexPreview",
			Position = UDim2.fromOffset(8, 7),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = currentColor,
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 803,
		}, hexField)
		New("UICorner", { CornerRadius = UDim.new(0, 4) }, hexPreview)
		local hexLabel = New("TextLabel", {
			Name = "HexValue",
			Position = UDim2.fromOffset(30, 0),
			Size = UDim2.fromOffset(118, 28),
			BackgroundTransparency = 1,
			Text = ColorToHex(currentColor),
			TextColor3 = Color3.fromRGB(226, 228, 236),
			TextScaled = false,
			TextSize = 14,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = Z_BASE + 803,
		}, hexField)
		local copyButton = New("ImageButton", {
			Name = "CopyHex",
			Position = UDim2.fromOffset(164, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Color3.fromRGB(28, 31, 45),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Image = "",
			ZIndex = Z_BASE + 802,
		}, hexRow)
		New("UICorner", { CornerRadius = UDim.new(0, 6) }, copyButton)
		local copyBack = New("Frame", {
			Name = "CopyIconBack",
			Position = UDim2.fromOffset(7, 6),
			Size = UDim2.fromOffset(9, 11),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 803,
		}, copyButton)
		New("UICorner", { CornerRadius = UDim.new(0, 2) }, copyBack)
		local copyBackStroke = Stroke(copyBack, "CopyIconBackStroke")
		copyBackStroke.Color = Color3.fromRGB(226, 228, 236)
		copyBackStroke.Transparency = 0.12
		local copyFront = New("Frame", {
			Name = "CopyIconFront",
			Position = UDim2.fromOffset(11, 10),
			Size = UDim2.fromOffset(9, 11),
			BackgroundColor3 = Color3.fromRGB(28, 31, 45),
			BorderSizePixel = 0,
			ZIndex = Z_BASE + 804,
		}, copyButton)
		New("UICorner", { CornerRadius = UDim.new(0, 2) }, copyFront)
		local copyFrontStroke = Stroke(copyFront, "CopyIconFrontStroke")
		copyFrontStroke.Color = Color3.fromRGB(226, 228, 236)
		copyFrontStroke.Transparency = 0.12

		local function refreshDisplay(notify)
			currentColor = Color3.fromHSV(hue, saturation, value)
			svSquare.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			svShadow.Position = UDim2.new(saturation, 0, 1 - value, 0)
			svCursor.Position = UDim2.new(saturation, 0, 1 - value, 0)
			hueThumb.Position = UDim2.new(hue, 0, 0.5, 0)
			hexPreview.BackgroundColor3 = currentColor
			hexLabel.Text = ColorToHex(currentColor)
			if anchorButton and anchorButton.Parent then anchorButton.BackgroundColor3 = currentColor end
			if notify then InvokeCallback(onChange, currentColor) end
		end

		local function setColor(color)
			currentColor = NormalizeColor(color)
			hue, saturation, value = Color3.toHSV(currentColor)
			refreshDisplay(false)
		end

		local function updateSV(input)
			local point = GetInputPosition(input)
			local pos = svSquare.AbsolutePosition
			local size = svSquare.AbsoluteSize
			if size.X <= 0 or size.Y <= 0 then return end
			saturation = math.clamp((point.X - pos.X) / size.X, 0, 1)
			value = 1 - math.clamp((point.Y - pos.Y) / size.Y, 0, 1)
			refreshDisplay(true)
		end

		local function updateHue(input)
			local point = GetInputPosition(input)
			local pos = hueBar.AbsolutePosition
			local size = hueBar.AbsoluteSize
			if size.X <= 0 then return end
			hue = math.clamp((point.X - pos.X) / size.X, 0, 1)
			refreshDisplay(true)
		end

		local function positionFrame()
			if not frame.Parent or not anchorButton or not anchorButton.Parent then return end
			local safePos, safeSize = PopupSafeArea()
			if safeSize.X <= 0 or safeSize.Y <= 0 then return end
			local anchorPos, anchorSize = anchorButton.AbsolutePosition, anchorButton.AbsoluteSize
			local popupW = frame.AbsoluteSize.X > 0 and frame.AbsoluteSize.X or 212
			local popupH = frame.AbsoluteSize.Y > 0 and frame.AbsoluteSize.Y or 214
			local x = anchorPos.X + anchorSize.X - popupW
			local y = anchorPos.Y + anchorSize.Y + 6
			if y + popupH > safePos.Y + safeSize.Y - 6 then y = anchorPos.Y - popupH - 6 end
			x = math.clamp(x, safePos.X + 6, math.max(safePos.X + 6, safePos.X + safeSize.X - popupW - 6))
			y = math.clamp(y, safePos.Y + 6, math.max(safePos.Y + 6, safePos.Y + safeSize.Y - popupH - 6))
			MovePopupToAbsolute(frame, x, y)
		end

		local function closePicker()
			if not isOpen and not frame.Visible then return end
			isOpen = false
			UnregisterPopup(frame)
			SmoothClose(frame, 0.12)
		end

		local function openPicker()
			if isOpen then return end
			CloseAllPopupsExcept(frame)
			isOpen = true
			frame.Visible = true
			ApplyZIndexLadder(frame, NextPopupZ())
			positionFrame()
			SmoothOpen(frame, 0.02, 0.16)
			task.defer(function()
				if frame.Visible and isOpen then positionFrame() end
			end)
			RegisterPopup(frame, closePicker, anchorButton)
		end

		local picker = { frame = frame }
		function picker.Set(color) setColor(color) end
		function picker.Get() return currentColor end
		function picker.Close() closePicker() end
		function picker.Toggle()
			if isOpen then closePicker() else openPicker() end
		end

		anchorButton.MouseButton1Click:Connect(function() picker.Toggle() end)
		svSquare.InputBegan:Connect(function(input)
			if IsPrimaryInput(input) then dragPart = "sv"; updateSV(input) end
		end)
		hueBar.InputBegan:Connect(function(input)
			if IsPrimaryInput(input) then dragPart = "hue"; updateHue(input) end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragPart then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if dragPart == "sv" then updateSV(input) else updateHue(input) end
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if dragPart and IsPrimaryInput(input) then dragPart = nil end
		end)
		copyButton.MouseButton1Click:Connect(function()
			if setclipboard then setclipboard(hexLabel.Text) end
		end)
		setColor(currentColor)
		return picker
	end



local Stats = game:GetService('Stats')

local FPSText, MSText, TimeText, RamText, SignalImage
local ACCENT = mainColor or Color3.fromRGB(78, 131, 255)
local GOOD = Color3.fromRGB(120, 220, 140)
local WARN = Color3.fromRGB(240, 180, 80)
local BAD = Color3.fromRGB(233, 90, 130)

do
local GameInfo = Instance.new('Frame')
GameInfo.Name = "GameInfo"
GameInfo.AnchorPoint = Vector2.new(1, 0)
GameInfo.Position = UDim2.new(1, -6, 0, 2)
GameInfo.Size = UDim2.fromOffset(0, 36)
GameInfo.AutomaticSize = Enum.AutomaticSize.X
GameInfo.BackgroundColor3 = Color3.fromRGB(15, 17, 25)
GameInfo.BackgroundTransparency = 0.06
GameInfo.BorderSizePixel = 0
GameInfo.Active = true
GameInfo.Draggable = false
GameInfo.ClipsDescendants = false
GameInfo.Parent = NeverloseCS2
GameInfo.ZIndex = Z_BASE + 900
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = GameInfo end
do Stroke(GameInfo, "Border") end
do local pd = Instance.new("UIPadding"); pd.PaddingLeft = UDim.new(0, 12); pd.PaddingRight = UDim.new(0, 14); pd.PaddingTop = UDim.new(0, 7); pd.PaddingBottom = UDim.new(0, 7); pd.Parent = GameInfo end
do local ly = Instance.new("UIListLayout"); ly.FillDirection = Enum.FillDirection.Horizontal; ly.HorizontalAlignment = Enum.HorizontalAlignment.Left; ly.VerticalAlignment = Enum.VerticalAlignment.Center; ly.Padding = UDim.new(0, 0); ly.SortOrder = Enum.SortOrder.LayoutOrder; ly.Parent = GameInfo end

local ICON_LAYERS   = "rbxassetid://114499998778667"
local ICON_WIFI     = "rbxassetid://104941258142372"
local ICON_RAM      = "rbxassetid://82464660673318"
local ICON_CLOCK    = "rbxassetid://136533241128438"
local ICON_EYE      = "rbxassetid://127234874352422"
local ICON_KEYBOARD = "rbxassetid://121978468376124"

local function WMCell(name, order, iconAsset, text, iconSize, iconCorner)
	local cell = Instance.new("Frame")
	cell.Name = name .. "Cell"
	cell.LayoutOrder = order
	cell.Size = UDim2.fromOffset(0, 22)
	cell.AutomaticSize = Enum.AutomaticSize.X
	cell.BackgroundTransparency = 1
	cell.BorderSizePixel = 0
	cell.ZIndex = Z_BASE + 901
	cell.Parent = GameInfo
	do local ly = Instance.new("UIListLayout"); ly.FillDirection = Enum.FillDirection.Horizontal; ly.VerticalAlignment = Enum.VerticalAlignment.Center; ly.Padding = UDim.new(0, 6); ly.SortOrder = Enum.SortOrder.LayoutOrder; ly.Parent = cell end
	do local pd = Instance.new("UIPadding"); pd.PaddingLeft = UDim.new(0, 12); pd.PaddingRight = UDim.new(0, 12); pd.Parent = cell end
	local icon
	if iconAsset then
		icon = Instance.new("ImageLabel")
		icon.Name = name .. "Icon"
		icon.LayoutOrder = 1
		icon.Size = UDim2.fromOffset(iconSize or 14, iconSize or 14)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.Image = iconAsset
		icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		icon.ImageTransparency = 0.05
		icon.ScaleType = Enum.ScaleType.Fit
		icon.ZIndex = Z_BASE + 901
		icon.Parent = cell
		if iconCorner then do local c = Instance.new("UICorner"); c.CornerRadius = iconCorner; c.Parent = icon end end
	end
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = 2
	label.Size = UDim2.fromOffset(0, 22)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextTransparency = 0.04
	label.TextScaled = false
	label.TextSize = 13
	label.Font = FONT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = Z_BASE + 901
	label.Parent = cell
	return cell, icon, label
end

local function WMDivider()
	local d = Instance.new("Frame")
	d.Name = "Divider"
	d.Size = UDim2.fromOffset(1, 14)
	d.BackgroundColor3 = Color3.fromRGB(120, 126, 150)
	d.BackgroundTransparency = 0.58
	d.BorderSizePixel = 0
	d.Visible = false
	d.ZIndex = Z_BASE + 901
	d.Parent = GameInfo
	return d
end

local BrandCell = Instance.new("Frame")
BrandCell.Name = "BrandCell"
BrandCell.LayoutOrder = 2
BrandCell.Size = UDim2.fromOffset(0, 22)
BrandCell.AutomaticSize = Enum.AutomaticSize.X
BrandCell.BackgroundTransparency = 1
BrandCell.BorderSizePixel = 0
BrandCell.ZIndex = Z_BASE + 901
BrandCell.Parent = GameInfo
do local ly = Instance.new("UIListLayout"); ly.FillDirection = Enum.FillDirection.Horizontal; ly.VerticalAlignment = Enum.VerticalAlignment.Center; ly.Padding = UDim.new(0, 8); ly.SortOrder = Enum.SortOrder.LayoutOrder; ly.Parent = BrandCell end
do local pd = Instance.new("UIPadding"); pd.PaddingRight = UDim.new(0, 12); pd.Parent = BrandCell end

local NeverIcon = Instance.new("ImageLabel")
NeverIcon.Name = "NeverIcon"
NeverIcon.LayoutOrder = 1
NeverIcon.Size = UDim2.fromOffset(18, 18)
NeverIcon.BackgroundTransparency = 1
NeverIcon.BorderSizePixel = 0
NeverIcon.Image = hubImage ~= "" and hubImage or "rbxthumb://type=Asset&id=118608145176297&w=420&h=420"
NeverIcon.ImageColor3 = Color3.new(1, 1, 1)
NeverIcon.ScaleType = Enum.ScaleType.Fit
NeverIcon.ZIndex = Z_BASE + 901
NeverIcon.Parent = BrandCell
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = NeverIcon end

local UserCell = WMCell("Username", 4, nil, LocalPlayer.DisplayName or "Player")
local UserIcon = Instance.new("ImageLabel")
UserIcon.Name = "UserIcon"
UserIcon.LayoutOrder = 1
UserIcon.Size = UDim2.fromOffset(16, 16)
UserIcon.BackgroundTransparency = 1
UserIcon.BorderSizePixel = 0
UserIcon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId or 0) .. "&w=150&h=150"
UserIcon.ZIndex = Z_BASE + 901
UserIcon.Parent = UserCell
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = UserIcon end
local Username = UserCell:FindFirstChild("Username")

local FpsCell, FpsCellIcon
FpsCell, FpsCellIcon, FPSText = WMCell("FPS", 6, ICON_LAYERS, "0")
local PingCell
PingCell, SignalImage, MSText = WMCell("Ping", 8, ICON_WIFI, "0ms")
local RamCell, RamCellIcon
RamCell, RamCellIcon, RamText = WMCell("RAM", 10, ICON_RAM, "0mb")
local TimeCell, TimeCellIcon
TimeCell, TimeCellIcon, TimeText = WMCell("Time", 12, ICON_CLOCK, os.date("%H:%M"))

local WMCells = { brand = BrandCell, user = UserCell, fps = FpsCell, ping = PingCell, ram = RamCell, time = TimeCell }
local WMDefaultOrder = { "brand", "fps", "ping", "user", "time", "ram" }
local WMShowMap = { logo = true, user = true, fps = false, ping = false, ram = false, time = false }
local WMDividers = {}
for key in pairs(WMCells) do WMDividers[key] = WMDivider() end

-- ============================================================================
-- PATCH 6: forward-declare WMShadowSync BEFORE ApplyWatermarkLayout
-- ============================================================================
local WMShadowSync

local function ApplyWatermarkLayout(orderList, showMap)
	if type(showMap) == "table" then
		for key in pairs(WMShowMap) do
			if showMap[key] ~= nil then WMShowMap[key] = showMap[key] == true end
		end
	end
	local function normalize(k) return k == "logo" and "brand" or k end
	local order, seen = {}, {}
	local source = (type(orderList) == "table" and #orderList > 0) and orderList or WMDefaultOrder
	for _, raw in ipairs(source) do
		local key = normalize(raw)
		if WMCells[key] and not seen[key] then
			seen[key] = true
			table.insert(order, key)
		end
	end
	for _, key in ipairs(WMDefaultOrder) do
		if not seen[key] then table.insert(order, key) end
	end
	local shown = {}
	for i, key in ipairs(order) do
		local cell = WMCells[key]
		local hidden = WMShowMap[key] == false or (key == "brand" and WMShowMap.logo == false)
		cell.Visible = not hidden
		cell.LayoutOrder = i * 2
		if not hidden then table.insert(shown, { key = key, index = i }) end
	end
	for _, divider in pairs(WMDividers) do divider.Visible = false end
	for n = 2, #shown do
		local divider = WMDividers[shown[n].key]
		if divider then
			divider.Visible = true
			divider.LayoutOrder = shown[n].index * 2 - 1
		end
	end
	GameInfo.Visible = #shown > 0
	if WMShadowSync then WMShadowSync() end
end
ApplyWatermarkLayout(nil, nil)

-- (WMShadowSync local declaration removed here — moved above ApplyWatermarkLayout)
do
	local WMShadowHost = Instance.new("Frame")
	WMShadowHost.Name = "WMShadow"
	WMShadowHost.AnchorPoint = Vector2.new(1, 0)
	WMShadowHost.Position = UDim2.new(1, -6, 0, 2)
	WMShadowHost.Size = UDim2.fromOffset(10, 36)
	WMShadowHost.BackgroundTransparency = 1
	WMShadowHost.BorderSizePixel = 0
	WMShadowHost.ZIndex = Z_BASE + 899
	WMShadowHost.Parent = NeverloseCS2

	-- Watermark shadow: more overlapping, low-contrast layers read as a soft
	-- ambient shadow instead of four separate dark outlines.
	local layers = {}
	local shadowLayerCount = 2
	for i = 1, shadowLayerCount do
		local layer = Instance.new("Frame")
		layer.Name = "Layer" .. i
		layer.BackgroundColor3 = Color3.new(0, 0, 0)
		-- Strongest near the watermark, gradually fading outward.
		layer.BackgroundTransparency = 0.82 + (i - 1) * 0.08
		layer.BorderSizePixel = 0
		layer.ZIndex = Z_BASE + 899
		layer.Parent = WMShadowHost
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = layer end
		layers[i] = layer
	end

	WMShadowSync = function()
		local w, h = GameInfo.AbsoluteSize.X, GameInfo.AbsoluteSize.Y
		-- Keep the sibling shadow attached to the watermark for every position preset.
		WMShadowHost.AnchorPoint = GameInfo.AnchorPoint
		WMShadowHost.Position = GameInfo.Position
		WMShadowHost.Visible = GameInfo.Visible and w > 0 and h > 0
		if not WMShadowHost.Visible then return end
		WMShadowHost.Size = UDim2.fromOffset(w, h)
		for i, layer in ipairs(layers) do
			local s = i * 0.65
			-- Minimal near-field shade; keep the watermark crisp without a detached halo.
			layer.Position = UDim2.new(0, -s, 0, 1 - s)
			layer.Size = UDim2.new(1, s * 2, 1, s * 2 + 2)
		end
	end
	GameInfo:GetPropertyChangedSignal("AbsoluteSize"):Connect(WMShadowSync)
	GameInfo:GetPropertyChangedSignal("Visible"):Connect(WMShadowSync)
	GameInfo:GetPropertyChangedSignal("Position"):Connect(WMShadowSync)
	GameInfo:GetPropertyChangedSignal("AnchorPoint"):Connect(WMShadowSync)
	task.defer(WMShadowSync)
end

WindowObj.Watermark = {
	frame = GameInfo,
	logo = NeverIcon,
	user = Username,
	avatar = UserIcon,
	fps = FPSText,
	time = TimeText,
	ping = MSText,
	ram = RamText,
	icons = { NeverIcon, UserIcon, FpsCellIcon, SignalImage, RamCellIcon, TimeCellIcon },
	cells = WMCells,
	applyLayout = ApplyWatermarkLayout,
	isShown = function(key)
		key = key == "logo" and "logo" or key
		return WMShowMap[key] == true
	end,
	toggle = function(key, on)
		WMShowMap[key] = on == true
		ApplyWatermarkLayout(nil, nil)
	end,
}
end

function WindowObj:SetWatermark(options)
	local wm = WindowObj.Watermark
	if type(options) ~= "table" then return wm end
	if options.position then
		-- Preserve the current anchor when callers only change Position.
		-- Resetting it to (0, 0) here made top/right presets jump unexpectedly.
		if options.anchorPoint then
			wm.frame.AnchorPoint = options.anchorPoint
		end
		wm.frame.Position = options.position
	end
	if options.background then wm.frame.BackgroundColor3 = options.background end
	if type(options.backgroundTransparency) == "number" then
		wm.frame.BackgroundTransparency = options.backgroundTransparency
	end
	if type(options.cornerRadius) == "number" then
		local corner = wm.frame:FindFirstChildOfClass("UICorner")
		if corner then corner.CornerRadius = UDim.new(0, options.cornerRadius) end
	end
	if type(options.title) == "string" and wm.title then
		wm.title.Text = options.title
	end
	local keys = { "user", "fps", "ping", "ram", "time" }
	if type(options.textSize) == "number" then
		for _, key in ipairs(keys) do
			if wm[key] then wm[key].TextSize = options.textSize end
		end
	end
	if options.accent and typeof(options.accent) == "Color3" then
		for _, icon in ipairs(wm.icons) do
			if icon and icon:IsA("ImageLabel") and icon ~= wm.logo and icon ~= wm.avatar then
				icon.ImageColor3 = options.accent
				icon.ImageTransparency = 0.15
			end
		end
	end
	if type(options.show) == "table" or type(options.order) == "table" then
		wm.applyLayout(options.order, options.show)
	end
	return wm
end

local _smoothTextBaseTransparency = setmetatable({}, { __mode = "k" })

local function setTextSmooth(label, newText)
    if not label or not label.Parent then return end
    newText = tostring(newText or "")
    if label:GetAttribute("shownText") == newText then return end

    -- Keep each label's authored opacity. A hard-coded 0.15 made watermark
    -- values gradually settle to a different opacity than their initial style.
    if _smoothTextBaseTransparency[label] == nil then
        _smoothTextBaseTransparency[label] = label.TextTransparency
    end
    local targetTransparency = _smoothTextBaseTransparency[label]

    label:SetAttribute("shownText", newText)
    local token = (label:GetAttribute("SmoothTextToken") or 0) + 1
    label:SetAttribute("SmoothTextToken", token)

    -- The shared tween manager cancels overlapping fades on the same property.
    local fadeOut = Tween(label, {
        TextTransparency = math.max(targetTransparency, 0.82),
    }, 0.085, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    if not fadeOut then
        label.Text = newText
        label.TextTransparency = targetTransparency
        return
    end

    fadeOut.Completed:Connect(function(playbackState)
        if playbackState ~= Enum.PlaybackState.Completed then return end
        if not label.Parent or label:GetAttribute("SmoothTextToken") ~= token then return end
        label.Text = newText
        Tween(label, {
            TextTransparency = targetTransparency,
        }, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    end)
end

-- (duplicate setTextSmooth removed)

local fpsBuffer = {}
local clockAcc = 0
local statAcc = 0
local lastFps
local lastMs
RunService.RenderStepped:Connect(function(dt)
if type(dt) ~= "number" or dt <= 0 then return end
table.insert(fpsBuffer, dt)
if #fpsBuffer > 20 then table.remove(fpsBuffer, 1) end
clockAcc = clockAcc + dt
if clockAcc >= 1 then
clockAcc = 0
setTextSmooth(TimeText, os.date("%H:%M"))
end
statAcc = statAcc + dt
if statAcc < 1 then return end
statAcc = 0
local avg = 0
for _, v in ipairs(fpsBuffer) do avg = avg + v end
if avg > 0 then
local fps = math.round(#fpsBuffer / avg)
if fps ~= lastFps then
lastFps = fps
setTextSmooth(FPSText, tostring(fps))
end
end
local ping = Stats and Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
if ping then
local ok, value = pcall(function() return ping:GetValue() end)
if ok and type(value) == "number" then
local ms = math.round(value)
if ms ~= lastMs then
lastMs = ms
setTextSmooth(MSText, tostring(ms) .. "ms")
local tint = ms >= 150 and BAD or ms >= 80 and WARN or GOOD
MSText.TextColor3 = tint
SignalImage.ImageColor3 = tint
end
end
end
local okMem, memMb = pcall(function() return game:GetTotalMemoryUsageMb() end)
if okMem and type(memMb) == "number" then
setTextSmooth(RamText, tostring(math.floor(memMb)) .. "mb")
end
end)

-- ============================================================================
-- PATCH 2: AttachShadow guards against layout parents
-- ============================================================================
local function AttachShadow(frame, opts)
	if not frame or not frame.Parent then return end
	if frame:FindFirstChildWhichIsA("UIListLayout") or frame:FindFirstChildWhichIsA("UIGridLayout") then
		warn("[ui] AttachShadow: " .. frame.Name .. " has a layout, shadow skipped")
		return
	end
	opts = opts or {}
	local layers = math.clamp(opts.layers or 6, 1, 8)
	local step = opts.step or 2.0
	local bias = opts.bias or 2
	local radius = opts.radius or 16
	for i = 1, layers do
		local spread = math.floor(i * step + 0.5)
		-- Keep the inner edge subtle; outer layers fade instead of forming a black halo.
		local alpha = math.clamp(0.76 + (i - 1) * (0.22 / math.max(1, layers - 1)), 0.76, 0.98)
		local shadow = New("Frame", {
			Name = "ShadowLayer" .. i,
			Position = UDim2.new(0, -spread, 0, bias - spread),
			Size = UDim2.new(1, spread * 2, 1, spread * 2),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = alpha,
			BorderSizePixel = 0,
			ZIndex = frame.ZIndex - 1,
		}, frame)
		shadow:SetAttribute("IsShadowLayer", true)
		shadow:SetAttribute("ShadowAlpha", alpha)
		New("UICorner", { CornerRadius = UDim.new(0, radius + spread) }, shadow)
	end
end
AttachShadow(MainFrame, { radius = 20, layers = 6, step = 2.0, bias = 2 })

local RefreshKeybindOverlay
do
local ICON_EYE = "rbxassetid://127234874352422"
local ICON_KEYBOARD = "rbxassetid://121978468376124"
local OverlayStack = New("Frame", {
	Name = "OverlayStack",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -6, 0, 46),
	Size = UDim2.fromOffset(220, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = Z_BASE + 880,
}, NeverloseCS2)
New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, OverlayStack)

-- ============================================================================
-- PATCH 3: MakeOverlayPanel rewritten — shadow lives in a panel WITHOUT layout,
-- content goes into a Body child that owns the layout
-- ============================================================================
local function MakeOverlayPanel(name, iconAsset, title)
	local panel = New("Frame", {
		Name = name,
		Size = UDim2.fromOffset(156, 46),
		BackgroundColor3 = Color3.fromRGB(13, 15, 22),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Visible = false,
		ZIndex = Z_BASE + 890,
	}, OverlayStack)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
	Stroke(panel)
	AttachShadow(panel, { radius = 10, layers = 3, step = 1.3, bias = 2 }) -- panel has NO layout now

	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = Z_BASE + 891,
	}, panel)
	New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, body)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, body)

	local header = New("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 1, ZIndex = Z_BASE + 891 }, body)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, header)
	New("ImageLabel", {
		Name = "HeaderIcon", Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1,
		Image = iconAsset, ImageColor3 = mainColor, ScaleType = Enum.ScaleType.Fit, LayoutOrder = 1, ZIndex = Z_BASE + 891,
	}, header)
	New("TextLabel", {
		Name = "HeaderTitle", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1, Text = title, TextColor3 = Color3.fromRGB(255, 255, 255), TextTransparency = 0.08,
		TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, ZIndex = Z_BASE + 891,
	}, header)

	New("Frame", {
		Name = "HeaderRule", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, LayoutOrder = 2, ZIndex = Z_BASE + 891,
	}, body)

	local rows = New("Frame", {
		Name = "Rows", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = 3, ZIndex = Z_BASE + 891,
	}, body)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, rows)
	return panel, rows
end

	-- header(8+16) + rule(1) + top gap(6) + n*18 + (n-1)*2 + bottom pad(8)
	local function OverlayPanelHeight(rowCount)
		return 8 + 16 + 6 + 1 + 6 + (rowCount * 18 + math.max(0, rowCount - 1) * 2) + 8
	end

	local function FadeOverlayContents(panel, show)
	for _, node in ipairs(panel:GetDescendants()) do
		if node:IsA("TextLabel") then
			node.TextTransparency = 1
			Tween(node, { TextTransparency = show and 0.08 or 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		elseif node:IsA("ImageLabel") then
			node.ImageTransparency = 1
			Tween(node, { ImageTransparency = show and 0 or 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		elseif node:IsA("Frame") and node.Name == "HeaderRule" then
			node.BackgroundTransparency = 1
			Tween(node, { BackgroundTransparency = show and 0.9 or 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		elseif node:GetAttribute("IsShadowLayer") then
			local alpha = node:GetAttribute("ShadowAlpha") or 0.8
			Tween(node, { BackgroundTransparency = show and alpha or 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end
end

local function SetOverlayPanelShown(panel, shown)
	local token = (panel:GetAttribute("FadeToken") or 0) + 1
	panel:SetAttribute("FadeToken", token)
	if shown then
		if panel.Visible and panel.BackgroundTransparency <= 0.15 then return end
		panel.BackgroundTransparency = 1
		panel.Visible = true
		FadeOverlayContents(panel, true)
		Tween(panel, { BackgroundTransparency = 0.1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local stroke = panel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 1
			Tween(stroke, { Transparency = 0.6 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	else
		if not panel.Visible then return end
		Tween(panel, { BackgroundTransparency = 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		FadeOverlayContents(panel, false)
		local stroke = panel:FindFirstChildOfClass("UIStroke")
		if stroke then Tween(stroke, { Transparency = 1 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		task.delay(0.19, function()
			if panel.Parent and panel:GetAttribute("FadeToken") == token then
				panel.Visible = false
			end
		end)
	end
end

local KBPanel, KBRows = MakeOverlayPanel("Keybinds", ICON_KEYBOARD, "Hotkeys")
KBPanel.LayoutOrder = 1
local kbEnabled = true
local kbRowCache = {}
local lastKbSig = nil

local function BuildBindRow(entry, order)
	local row = New("Frame", {
		Name = "BindRow",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = Z_BASE + 892,
	}, KBRows)
	local miniSwitch = New("Frame", {
		Name = "MiniSwitch", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(22, 12),
		BackgroundColor3 = mainColor, BorderSizePixel = 0, ZIndex = Z_BASE + 892,
	}, row)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, miniSwitch)
	local miniKnob = New("Frame", {
		Name = "MiniKnob", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -1, 0.5, 0), Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = Z_BASE + 893,
	}, miniSwitch)
	New("UICorner", { CornerRadius = UDim.new(1, 0) }, miniKnob)
	local nameLabel = New("TextLabel", {
		Name = "BindName",
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -82, 1, 0),
		BackgroundTransparency = 1,
		Text = entry.label,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 1,
		TextSize = 12,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = Z_BASE + 892,
	}, row)
	local keyLabel = New("TextLabel", {
		Name = "BindKey",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 48, 1, 0),
		BackgroundTransparency = 1,
		Text = entry.key,
		TextColor3 = Color3.fromRGB(150, 155, 172),
		TextTransparency = 1,
		TextSize = 12,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = Z_BASE + 892,
	}, row)
	Tween(nameLabel, { TextTransparency = 0.08 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	Tween(keyLabel, { TextTransparency = 0.08 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return row
end

RefreshKeybindOverlay = function()
	if not KBPanel.Parent then return end
	local snapshot = {}
	if WindowObj._bindSnapshot then
		local ok, result = pcall(WindowObj._bindSnapshot)
		if ok and type(result) == "table" then snapshot = result end
	end
	local target = kbEnabled and MainFrame.Visible
	local sigParts = {}
	for i, entry in ipairs(snapshot) do sigParts[i] = entry.label .. "=" .. entry.key end
	local sig = table.concat(sigParts, "|")
	if sig == lastKbSig and KBPanel.Visible == target then return end
	lastKbSig = sig
	for _, row in ipairs(kbRowCache) do
		if row.Parent then row:Destroy() end
	end
	table.clear(kbRowCache)
	local maxW = 0
	for i, entry in ipairs(snapshot) do
		kbRowCache[#kbRowCache + 1] = BuildBindRow(entry, 10 + i)
		maxW = math.max(maxW,
			MeasureText(entry.label, 12, FONT)
			+ MeasureText(entry.key, 12, FONT) + 58)
	end
	KBPanel.Size = UDim2.fromOffset(24 + math.max(132, math.ceil(maxW + 0.5)), OverlayPanelHeight(#snapshot))
	SetOverlayPanelShown(KBPanel, target)
end

WindowObj.KeybindList = {
	frame = KBPanel,
	setEnabled = function(enabled)
		kbEnabled = enabled == true
		RefreshKeybindOverlay()
	end,
	refresh = function() RefreshKeybindOverlay() end,
}

local SpecPanel, SpecRows = MakeOverlayPanel("Spectators", ICON_EYE, "Spectators")
SpecPanel.LayoutOrder = 2
local specEnabled = true
local specAuto = true
local specList = {}
local specRowCache = {}
local lastSpecSig = nil

local function BuildSpecRow(person, order)
	local row = New("Frame", {
		Name = "SpecRow",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = Z_BASE + 892,
	}, SpecRows)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	if person.id and person.id > 0 then
		local avatar = New("ImageLabel", {
			Name = "SpecAvatar",
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(person.id) .. "&w=150&h=150",
			ImageTransparency = 1,
			LayoutOrder = 1,
			ZIndex = Z_BASE + 892,
		}, row)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, avatar)
		Tween(avatar, { ImageTransparency = 0 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	else
		New("Frame", {
			Name = "SpecAvatarSpacer",
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ZIndex = Z_BASE + 892,
		}, row)
	end
	local nameLabel = New("TextLabel", {
		Name = "SpecName",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = person.name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 1,
		TextSize = 12,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		ZIndex = Z_BASE + 892,
	}, row)
	Tween(nameLabel, { TextTransparency = 0.08 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	return row
end

local function RefreshSpectatorOverlay()
	if not SpecPanel.Parent then return end
	local target = specEnabled and MainFrame.Visible
	local sigParts = {}
	for i, person in ipairs(specList) do sigParts[i] = person.id .. ":" .. person.name end
	local sig = table.concat(sigParts, "|")
	if sig == lastSpecSig and SpecPanel.Visible == target then return end
	lastSpecSig = sig
	for _, row in ipairs(specRowCache) do
		if row.Parent then row:Destroy() end
	end
	table.clear(specRowCache)
	local maxW = 0
	for i, person in ipairs(specList) do
		specRowCache[#specRowCache + 1] = BuildSpecRow(person, 10 + i)
		maxW = math.max(maxW, MeasureText(person.name, 12, FONT) + 64)
	end
	SpecPanel.Size = UDim2.fromOffset(24 + math.max(132, math.ceil(maxW + 0.5)), OverlayPanelHeight(#specList))
	SetOverlayPanelShown(SpecPanel, target)
end

local function NormalizeSpectatorList(list)
	local out = {}
	if type(list) ~= "table" then return out end
	for _, item in ipairs(list) do
		if typeof(item) == "Instance" and item:IsA("Player") then
			table.insert(out, { id = item.UserId, name = item.DisplayName })
		elseif type(item) == "table" and item.name then
			table.insert(out, { id = tonumber(item.id) or 0, name = tostring(item.name) })
		elseif type(item) == "string" then
			table.insert(out, { id = 0, name = item })
		end
	end
	return out
end

local function UpdateAutoSpectators()
	if not specAuto then return end
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char = p.Character
			local dead = false
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				dead = humanoid == nil or humanoid.Health <= 0
			end
			if not char or dead then
				table.insert(list, { id = p.UserId, name = p.DisplayName })
			end
		end
	end
	specList = list
end

WindowObj.SpectatorList = {
	frame = SpecPanel,
	setEnabled = function(enabled)
		specEnabled = enabled == true
		RefreshSpectatorOverlay()
	end,
	refresh = function()
		UpdateAutoSpectators()
		RefreshSpectatorOverlay()
	end,
}
function WindowObj:SetSpectators(list)
	specAuto = false
	specList = NormalizeSpectatorList(list)
	RefreshSpectatorOverlay()
	return SpecPanel
end
function WindowObj:SetSpectatorsAuto(enabled)
	specAuto = enabled == true
	if specAuto then UpdateAutoSpectators() end
	RefreshSpectatorOverlay()
	return specAuto
end

MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	OverlayStack.Visible = MainFrame.Visible
	if RefreshKeybindOverlay then RefreshKeybindOverlay() end
	RefreshSpectatorOverlay()
end)

task.spawn(function()
	while OverlayStack.Parent do
		task.wait(1)
		if not OverlayStack.Parent then break end
		pcall(function()
			if specAuto then UpdateAutoSpectators() end
		end)
		pcall(RefreshSpectatorOverlay)
	end
end)

task.defer(function()
	if RefreshKeybindOverlay then RefreshKeybindOverlay() end
	RefreshSpectatorOverlay()
end)
end

local Aspect = Instance.new("UIAspectRatioConstraint")
Aspect.Parent = MainFrame
Aspect.AspectRatio = 798 / 610

	local HubIcon = New("Frame", {
		Name = "HubIcon",
		Position = UDim2.fromOffset(16, 11),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, MainFrame)
	New("ImageLabel", {
		Name = "HubGlyph",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = hubImage ~= "" and hubImage or "rbxthumb://type=Asset&id=118608145176297&w=420&h=420",
		ScaleType = Enum.ScaleType.Fit,
	}, HubIcon)

	New("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(59, 10),
		Size = UDim2.fromOffset(110, 20),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		Text = hubTitle,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		Font = FONT,
      TextXAlignment = Enum.TextXAlignment.Left,
	}, MainFrame)

	New("TextLabel", {
		Name = "GameTitle",
		Position = UDim2.fromOffset(59, 30),
		Size = UDim2.fromOffset(110, 12),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		Text = gameTitle,
		TextColor3 = Color3.fromRGB(112, 116, 138),
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextScaled = false,
		TextSize = 11,
      TextTransparency = 0,
		Font = FONT,
      TextXAlignment = Enum.TextXAlignment.Left,
	}, MainFrame)
	local Info = Instance.new('Frame')
	Info.Name = "Info"
	Info.Position = UDim2.new(0, 15, 1, -13)
	Info.Size = UDim2.new(0, 150, 0, 30)
	Info.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Info.BackgroundTransparency = 1
	Info.BorderSizePixel = 0
	Info.Active = true
	Info.Parent = MainFrame

	local UserImageEl = Instance.new('ImageLabel')
	UserImageEl.Name = "UserImage"
	UserImageEl.Position = UDim2.fromOffset(0, 0)
	UserImageEl.Size = UDim2.fromOffset(30, 30)
	UserImageEl.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	UserImageEl.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
	UserImageEl.Parent = Info
	New("UICorner", { CornerRadius = UDim.new(1,0) }, UserImageEl)
	New("UIAspectRatioConstraint", { AspectType = Enum.AspectType.ScaleWithParentSize }, UserImageEl)
	local UserImageStroke = Stroke(UserImageEl)

	local User = Instance.new('TextLabel')
	User.Name = "Username"
	User.Position = UDim2.fromOffset(44, 1)
	User.Size = UDim2.fromOffset(86, 16)
	User.TextTruncate = Enum.TextTruncate.AtEnd
	User.BackgroundColor3 = Color3.fromRGB(162,162,162)
	User.BackgroundTransparency = 1
	User.Text = LocalPlayer.Name
	User.TextColor3 = Color3.fromRGB(255,255,255)
	User.TextScaled = false
	User.TextSize = 14
	User.Font = FONT
	User.TextTransparency = 0
	User.TextXAlignment = Enum.TextXAlignment.Left
	User.TextYAlignment = Enum.TextYAlignment.Center
	User.Parent = Info

	local DaysLeft = Instance.new('TextLabel')
	DaysLeft.Name = "Daysleft"
	DaysLeft.Position = UDim2.fromOffset(44, 21)
	DaysLeft.Size = UDim2.fromOffset(86, 12)
	DaysLeft.TextTruncate = Enum.TextTruncate.AtEnd
	DaysLeft.BackgroundColor3 = Color3.fromRGB(162,162,162)
	DaysLeft.BackgroundTransparency = 1
	DaysLeft.Text = daysLeft
	DaysLeft.TextColor3 = Color3.fromRGB(255,255,255)
	DaysLeft.TextScaled = false
	DaysLeft.TextSize = 12
	DaysLeft.Font = FONT
	DaysLeft.TextTransparency = 0
	DaysLeft.TextColor3 = Color3.fromRGB(112, 116, 138)
	DaysLeft.TextXAlignment = Enum.TextXAlignment.Left
	DaysLeft.TextYAlignment = Enum.TextYAlignment.Center
	DaysLeft.Parent = Info

	local WindowSettings = Instance.new('TextButton')
	WindowSettings.Name = "WindowSettings"
	WindowSettings.Position = UDim2.new(0, 0, 0, 0)
	WindowSettings.Size = UDim2.new(1, 0, 1, 0)
	WindowSettings.BackgroundColor3 = Color3.fromRGB(255,255,255)
	WindowSettings.BackgroundTransparency = 1
	WindowSettings.Text = ""
	WindowSettings.TextColor3 = Color3.fromRGB(255,255,255)
	WindowSettings.TextScaled = false
	WindowSettings.TextXAlignment = Enum.TextXAlignment.Right
	WindowSettings.Parent = Info

local SettingsArrow = New("ImageLabel", {
	Name = "UserSettingsArrow",
	Position = UDim2.new(1, -9, 0.5, 0),
	Size = UDim2.fromOffset(12, 12),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundTransparency = 1,
	Image = "rbxassetid://10709790990",
	ImageTransparency = 0.3,
	ScaleType = Enum.ScaleType.Fit,
	Rotation = 0,
	ZIndex = 102,
}, WindowSettings)

	Info.MouseEnter:Connect(function()
		Tween(Info, {BackgroundTransparency = 0.95}, 0.15)
		Tween(SettingsArrow, {ImageTransparency = 0}, 0.15)
	end)
	Info.MouseLeave:Connect(function()
		Tween(Info, {BackgroundTransparency = 1}, 0.15)
		Tween(SettingsArrow, {ImageTransparency = 0.3}, 0.15)
	end)

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 1
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = SettingsArrow

	local WindowSettingsFrame = Instance.new('Frame')
	WindowSettingsFrame.Name = "WindowSettingsFrame"
	WindowSettingsFrame.Position = UDim2.new(0.006, 0, 0.44, 0)
	WindowSettingsFrame.Size = UDim2.fromOffset(215, 0)
	WindowSettingsFrame.AutomaticSize = Enum.AutomaticSize.Y
	WindowSettingsFrame.ClipsDescendants = false
	WindowSettingsFrame.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	WindowSettingsFrame.BackgroundTransparency = 0.045
	WindowSettingsFrame.ZIndex = 101
	do Stroke(WindowSettingsFrame) end
	WindowSettingsFrame.Visible = false
	WindowSettingsFrame.Parent = MainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = WindowSettingsFrame end
	AttachShadow(WindowSettingsFrame, { radius = 13, layers = 3, step = 1.2, bias = 2 })


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
		RescaleStrokes(MainFrame, UIScale.Scale)
		if RepositionOpenPopups then RepositionOpenPopups() end
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

	local SettingsContainer = Instance.new("Frame")
	SettingsContainer.Name = "SettingsContainer"
	SettingsContainer.Position = UDim2.new(0,10,0,0)
	SettingsContainer.Size = UDim2.new(1,-20,0,50)
	SettingsContainer.BackgroundColor3 = Color3.fromRGB(162,162,162)
	SettingsContainer.BackgroundTransparency = 1
	SettingsContainer.ZIndex = 13
	SettingsContainer.AutomaticSize = Enum.AutomaticSize.Y
	SettingsContainer.Parent = WindowSettingsFrame
	do
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 3)
        ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = SettingsContainer
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent = SettingsContainer
    end

	-- Compact account block matching the Neverlose profile popover reference.
		do
			local header = Instance.new("Frame")
			header.Name = "ProfileHeader"
			header.Size = UDim2.new(1, 0, 0, 68)
			header.BackgroundTransparency = 1
			header.BorderSizePixel = 0
			header.LayoutOrder = 0
			header.ZIndex = 120
			header.Parent = SettingsContainer

			local avatar = Instance.new("ImageLabel")
			avatar.Name = "ProfileAvatar"
			avatar.Position = UDim2.new(0, 2, 0, 11)
			avatar.Size = UDim2.fromOffset(38, 38)
			avatar.BackgroundColor3 = Color3.fromRGB(28, 31, 44)
			avatar.BackgroundTransparency = 0
			avatar.BorderSizePixel = 0
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId or 0) .. "&w=150&h=150"
			avatar.ScaleType = Enum.ScaleType.Crop
			avatar.ZIndex = 121
			avatar.Parent = header
			local avatarCorner = Instance.new("UICorner")
			avatarCorner.CornerRadius = UDim.new(1, 0)
			avatarCorner.Parent = avatar
			local avatarStroke = Stroke(avatar, "ProfileAvatarStroke")

			local name = Instance.new("TextLabel")
			name.Name = "ProfileName"
			name.Position = UDim2.new(0, 50, 0, 8)
			name.Size = UDim2.new(1, -56, 0, 17)
			name.BackgroundTransparency = 1
			name.BorderSizePixel = 0
			name.Text = tostring(LocalPlayer.Name or "Player")
			name.TextColor3 = Color3.fromRGB(232, 234, 242)
			name.TextSize = 14
			name.Font = FONT
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextYAlignment = Enum.TextYAlignment.Center
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.ZIndex = 121
			name.Parent = header

			local plan = Instance.new("TextLabel")
			plan.Name = "ProfilePlan"
			plan.Position = UDim2.new(0, 50, 0, 26)
			plan.Size = UDim2.new(1, -56, 0, 14)
			plan.BackgroundTransparency = 1
			plan.BorderSizePixel = 0
			plan.Text = daysLeft == "Lifetime" and "Lifetime access" or ("Till: " .. tostring(daysLeft))
			plan.TextColor3 = Color3.fromRGB(151, 157, 175)
			plan.TextSize = 12
			plan.Font = FONT
			plan.TextXAlignment = Enum.TextXAlignment.Left
			plan.TextYAlignment = Enum.TextYAlignment.Center
			plan.TextTruncate = Enum.TextTruncate.AtEnd
			plan.ZIndex = 121
			plan.Parent = header

			local renew = Instance.new("TextLabel")
			renew.Name = "RenewLabel"
			renew.Position = UDim2.new(0, 50, 0, 42)
			renew.Size = UDim2.new(1, -56, 0, 14)
			renew.BackgroundTransparency = 1
			renew.BorderSizePixel = 0
			renew.Text = "Renew"
			renew.TextColor3 = mainColor
			renew.TextSize = 12
			renew.Font = FONT
			renew.TextXAlignment = Enum.TextXAlignment.Left
			renew.TextYAlignment = Enum.TextYAlignment.Center
			renew.ZIndex = 121
			renew.Parent = header

			local separator = Instance.new("Frame")
			separator.Name = "ProfileDivider"
			separator.Position = UDim2.new(0, 0, 1, -1)
			separator.Size = UDim2.new(1, 0, 0, 1)
			separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			separator.BackgroundTransparency = 0.91
			separator.BorderSizePixel = 0
			separator.ZIndex = 121
			separator.Parent = header
		end

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
		Row.LayoutOrder = 60
		Row.Parent = SettingsContainer
		

		local BLabel = Instance.new("TextLabel")
		BLabel.Name = "Text"
		BLabel.Position = UDim2.new(0.04, 0, 0.5, 0)
		BLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
		BLabel.AnchorPoint = Vector2.new(0, 0.5)
		BLabel.BackgroundTransparency = 1
		BLabel.Text = "Menu Bind"
		BLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		BLabel.TextScaled = false
		BLabel.Font = FONT
		BLabel.TextTransparency = 0.1
		BLabel.ZIndex = 130
		BLabel.TextXAlignment = Enum.TextXAlignment.Left
		BLabel.Parent = Row

		local BValue = Instance.new("TextLabel")
		BValue.Name = "BindValue"
		BValue.Position = UDim2.new(0.56, 0, 0.17, 0)
		BValue.Size = UDim2.new(0.38, 0, 0.66, 0)
		BValue.BackgroundColor3 = Color3.fromRGB(24, 27, 37)
		BValue.BackgroundTransparency = 0
		BValue.BorderSizePixel = 0
		BValue.Text = ""
		BValue.TextColor3 = Color3.fromRGB(255, 255, 255)
		BValue.TextScaled = false
		BValue.Font = FONT
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

	local WSColorpicker = Instance.new("Frame")
	WSColorpicker.Name = "Colorpicker"
	-- Fixed row height prevents a circular AutoSize dependency with the popup.
	WSColorpicker.Size = UDim2.new(1, 0, 0, 30)
	WSColorpicker.BackgroundTransparency = 1
	WSColorpicker.BorderSizePixel = 0
	WSColorpicker.ZIndex = 130
	WSColorpicker.LayoutOrder = 30
	WSColorpicker.Parent = SettingsContainer
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
		lbl.Text = "Style"
		lbl.TextColor3 = Color3.fromRGB(255,255,255)
		lbl.TextScaled = false
		lbl.Font = FONT
		lbl.TextTransparency = 0.5
		lbl.ZIndex = 130
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = WSColorpicker
	end

	local wsColorBtn = New("ImageButton", {
		Name = "colorpickerButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = mainColor,
		BorderSizePixel = 0,
		Image = "",
		ZIndex = 130,
	}, WSColorpicker)
	New("UICorner", { CornerRadius = UDim.new(0, 5) }, wsColorBtn)
	Stroke(wsColorBtn, "ColorpickerButtonStroke")
	local wsPicker = AcrylicBlur.CreateColorPicker(wsColorBtn, mainColor, function(c)
		if applyMainColorProxy then applyMainColorProxy(c) end
	end)

	local WSScaleRow = Instance.new("Frame")
	WSScaleRow.Name = "Selection"
	WSScaleRow.Size = UDim2.new(1,0,0,28)
	WSScaleRow.BackgroundColor3 = Color3.fromRGB(162,162,162)
	WSScaleRow.BackgroundTransparency = 1
	WSScaleRow.ZIndex = 120
	WSScaleRow.LayoutOrder = 20
	WSScaleRow.Parent = SettingsContainer
	
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
		lbl.TextScaled = false; lbl.Font = FONT
		lbl.TextTransparency = 0.5; lbl.ZIndex = 130
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = WSScaleRow
	end

	local ScaleArrow = Instance.new("ImageLabel")
	ScaleArrow.Name = "TextArrow"
	ScaleArrow.AnchorPoint = Vector2.new(1, 0.5)
	ScaleArrow.Position = UDim2.new(1, -12, 0.5, 0)
	ScaleArrow.Size = UDim2.fromOffset(10, 10)
	ScaleArrow.BackgroundTransparency = 1
	ScaleArrow.Image = "rbxassetid://10709790948"
	ScaleArrow.ImageTransparency = 0.4000000059604645
	ScaleArrow.ImageColor3 = Color3.fromRGB(255,255,255)
	ScaleArrow.ScaleType = Enum.ScaleType.Fit
	ScaleArrow.Rotation = 0
	ScaleArrow.ZIndex = 1000
	ScaleArrow.Parent = WSScaleRow

	local ScaleDefault = Instance.new("TextLabel")
	ScaleDefault.Name = "TextDefault"
	ScaleDefault.Position = UDim2.new(0.60, 0, 0.17, 0)
	ScaleDefault.Size = UDim2.new(0.25, 0, 0.6, 0)
	ScaleDefault.TextTruncate = Enum.TextTruncate.None
	ScaleDefault.BackgroundTransparency = 1
	ScaleDefault.Text = "Auto"
	ScaleDefault:SetAttribute("FullText", ScaleDefault.Text)
	
	ScaleDefault.TextColor3 = Color3.fromRGB(255,255,255)
	ScaleDefault.TextScaled = false
	ScaleDefault.Font = FONT
	ScaleDefault.TextTransparency = 0.699999988079071
	ScaleDefault.ZIndex = 150
	ScaleDefault.TextXAlignment = Enum.TextXAlignment.Right
	ScaleDefault.Parent = WSScaleRow

	local ScaleDownBar = Instance.new("Frame")
	ScaleDownBar.Name = "Dropdown"
	ScaleDownBar.Position = UDim2.new(0.02,0,1,2)
	ScaleDownBar.Size = UDim2.new(0.5899999737739563,0,0,0)
	ScaleDownBar.AutomaticSize = Enum.AutomaticSize.Y
	ScaleDownBar.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	ScaleDownBar.BackgroundTransparency = 0
	ScaleDownBar.BorderSizePixel = 0
	ScaleDownBar.Visible = false
	ScaleDownBar.ZIndex = 1000
	ScaleDownBar.Parent = WSScaleRow
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = ScaleDownBar end
	do Stroke(ScaleDownBar) end
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
	do Stroke(ScaleContainer) end
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
		LayoutOrder = 40,
	}, SettingsContainer)
	New("Frame", {
		Name = "Lines",
		Position = UDim2.new(0.06, 0, 1, -1),
		Size = UDim2.new(0.88, 0, 0, 1),
		BackgroundColor3 = Color3.fromRGB(162,162,162),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 150,
	}, WSLogoRow)
	New("TextLabel", {
		Name = "Text",
		Position = UDim2.new(0.04, 0, 0.5, 0),
		Size = UDim2.new(0.6, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text = "Logo",
		TextColor3 = Color3.fromRGB(255,255,255),
		TextScaled = false,
		Font = FONT,
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
		TextScaled = false,
		Font = FONT,
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
	WSLangRow.LayoutOrder = 10
	WSLangRow.Parent = SettingsContainer
	
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
		lbl.TextScaled = false; lbl.Font = FONT
		lbl.TextTransparency = 0.5; lbl.ZIndex = 130
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = WSLangRow
	end

	local LangArrow = Instance.new("ImageLabel")
	LangArrow.Name = "TextArrow"
	LangArrow.AnchorPoint = Vector2.new(1, 0.5)
	LangArrow.Position = UDim2.new(1, -12, 0.5, 0)
	LangArrow.Size = UDim2.fromOffset(10, 10)
	LangArrow.BackgroundTransparency = 1
	LangArrow.Image = "rbxassetid://10709790948"
	LangArrow.ImageTransparency = 0.4000000059604645
	LangArrow.ImageColor3 = Color3.fromRGB(255,255,255)
	LangArrow.ScaleType = Enum.ScaleType.Fit
	LangArrow.Rotation = 0
	LangArrow.ZIndex = 1000
	LangArrow.Parent = WSLangRow

	local LangDefault = Instance.new("TextLabel")
	LangDefault.Name = "TextDefault"
	LangDefault.Position = UDim2.new(0.60, 0, 0.17, 0)
	LangDefault.Size = UDim2.new(0.25, 0, 0.6, 0)
	LangDefault.TextTruncate = Enum.TextTruncate.None
	LangDefault.BackgroundTransparency = 1
	LangDefault.Text = "English"
	LangDefault:SetAttribute("FullText", LangDefault.Text)
	
	LangDefault.TextColor3 = Color3.fromRGB(255,255,255)
	LangDefault.TextScaled = false
	LangDefault.Font = FONT
	LangDefault.TextTransparency = 0.699999988079071
	LangDefault.ZIndex = 150
	LangDefault.TextXAlignment = Enum.TextXAlignment.Right
	LangDefault.Parent = WSLangRow

	local LangDownBar = Instance.new("Frame")
	LangDownBar.Name = "Dropdown"
	LangDownBar.Position = UDim2.new(0.02,0,1,2)
	LangDownBar.Size = UDim2.new(0.5899999737739563,0,0,0)
	LangDownBar.AutomaticSize = Enum.AutomaticSize.Y
	LangDownBar.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	LangDownBar.BackgroundTransparency = 0
	LangDownBar.BorderSizePixel = 0
	LangDownBar.Visible = false
	LangDownBar.ZIndex = 1000
	LangDownBar.Parent = WSLangRow
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,5); c.Parent = LangDownBar end
	do Stroke(LangDownBar) end
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
	do Stroke(LangContainer) end
	do local ll = Instance.new("UIListLayout"); ll.FillDirection = Enum.FillDirection.Vertical; ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,2); ll.Parent = LangContainer end

	local LangOpenBtn = Instance.new("TextButton"); LangOpenBtn.Name = "OpenBtn"
	LangOpenBtn.Size = UDim2.new(1,0,1,0); LangOpenBtn.BackgroundTransparency = 1
	LangOpenBtn.Text = ""; LangOpenBtn.ZIndex = 500; LangOpenBtn.Parent = WSLangRow

	do
		local function wsApplyColor(c)
			c = NormalizeColor(c)
			for i, tabEntry in ipairs(tabs) do
				pcall(function()
					if i == activeTabIndex then
						tabEntry.icon.ImageColor3 = c
						tabEntry.icon.ImageTransparency = 0
					else
						tabEntry.icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
						tabEntry.icon.ImageTransparency = 0.6
					end
				end)
			end
			for _, object in ipairs(NeverloseCS2:GetDescendants()) do
				pcall(function()
					if object.Name == "Effect" and object:IsA("Frame") then
						local color = object.BackgroundColor3
						local isOff = math.round(color.R * 255) == 0 and math.round(color.G * 255) == 0 and math.round(color.B * 255) == 0
						if not isOff then object.BackgroundColor3 = c end
					end
					if object.Name == "InLine" and object:IsA("Frame") then object.BackgroundColor3 = c end
				end)
			end
			mainColor = c
			if wsPicker then wsPicker.Set(c) end
		end
		applyMainColorProxy = wsApplyColor
		wsPicker.Set(mainColor)
	end

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
			Tween(ScaleArrow, {ImageTransparency = 0.4, Rotation = 0}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
			lbl.TextScaled = false
			lbl.Font = FONT
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
			SelBtn.TextColor3 = Color3.fromRGB(78, 131, 255)
			SelBtn.TextScaled = false
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
				ApplyZIndexLadder(ScaleDownBar, NextPopupZ())
PositionPopupWithinMain(ScaleDownBar, true)
				Tween(ScaleArrow, {ImageTransparency = 0, Rotation = 180}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				RegisterPopup(ScaleDownBar, closeScaleDropdown, ScaleOpenBtn)
			end
		end)

		local langs = {"English", "Filipino", "Chinese", "Russian", "Italian"}
		local langOpen = false
		local langSelectedBtns = {}

		local function closeLangDropdown()
			langOpen = false
			Tween(LangArrow, {ImageTransparency = 0.4, Rotation = 0}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
			lbl.TextScaled = false
			lbl.Font = FONT
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
			SelBtn.TextColor3 = Color3.fromRGB(78, 131, 255)
			SelBtn.TextScaled = false
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
			Tween(LangArrow, {Rotation = 180}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				ApplyZIndexLadder(LangDownBar, NextPopupZ())
PositionPopupWithinMain(LangDownBar, true)
				Tween(LangArrow, {ImageTransparency = 0}, 0.2)
				RegisterPopup(LangDownBar, closeLangDropdown, LangOpenBtn)
			end
		end)

		local wsOpen = false
		local function closeWS()
			wsOpen = false
			ClosePopupsUnder(WindowSettingsFrame)
			UnregisterPopup(WindowSettingsFrame)
			local anchorCenterX = Info.AbsolutePosition.X + Info.AbsoluteSize.X * 0.5
			local popupCenterX = WindowSettingsFrame.AbsolutePosition.X + WindowSettingsFrame.AbsoluteSize.X * 0.5
			local closeOffsetX = popupCenterX >= anchorCenterX and -6 or 6
			local closingPosition = WindowSettingsFrame.Position
			Tween(WindowSettingsFrame, {
				Position = UDim2.new(closingPosition.X.Scale, closingPosition.X.Offset + closeOffsetX, closingPosition.Y.Scale, closingPosition.Y.Offset + 2),
			}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Tween(WSScale, { Scale = 0.975 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			SmoothClose(WindowSettingsFrame, 0.14)
			Tween(SettingsArrow, { Rotation = 0 }, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		end
		WindowSettings.MouseButton1Click:Connect(function()
			wsOpen = not wsOpen
			if wsOpen then
				CloseAllPopupsExcept(WindowSettingsFrame)
				WindowSettingsFrame.BackgroundTransparency = 1
				WindowSettingsFrame.Visible = false
				WSScale.Scale = 1
				ApplyZIndexLadder(WindowSettingsFrame, NextPopupZ())

				-- Let AutomaticSize/UIListLayout finish before measuring. A hidden
				-- first-open popup otherwise reports a short height and jumps on open.
				task.spawn(function()
					task.wait()
					if not wsOpen or not WindowSettingsFrame.Parent then return end
					local popupSize = WindowSettingsFrame.AbsoluteSize
					if popupSize.X <= 0 or popupSize.Y <= 0 then
						-- The first layout pass may not have completed yet. Yield once more,
						-- still hidden, rather than flashing the panel at its default origin.
						task.wait()
						if not wsOpen or not WindowSettingsFrame.Parent then return end
						popupSize = WindowSettingsFrame.AbsoluteSize
					end
					if popupSize.X <= 0 or popupSize.Y <= 0 then
						-- Fallback for unusual GUI scale/layout timing.
						WindowSettingsFrame.Visible = true
						PositionPopupWithinMain(WindowSettingsFrame, false, 8, WindowSettings)
						popupSize = WindowSettingsFrame.AbsoluteSize
						WindowSettingsFrame.Visible = false
					end
					if not wsOpen or popupSize.X <= 0 or popupSize.Y <= 0 then return end

					local anchorPos = Info.AbsolutePosition
					local anchorSize = Info.AbsoluteSize
					local popupAppearsOnRight = true
					local gui = NeverloseCS2
					if gui and gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0 then
						local edge = 8
						local safeLeft = gui.AbsolutePosition.X + edge
						local safeTop = gui.AbsolutePosition.Y + edge
						local safeRight = gui.AbsolutePosition.X + gui.AbsoluteSize.X - edge
						local safeBottom = gui.AbsolutePosition.Y + gui.AbsoluteSize.Y - edge
						local x = anchorPos.X + anchorSize.X + edge
						if x + popupSize.X > safeRight then x = anchorPos.X - popupSize.X - edge end
						local maxX = math.max(safeLeft, safeRight - popupSize.X)
						local maxY = math.max(safeTop, safeBottom - popupSize.Y)
						x = math.clamp(x, safeLeft, maxX)
						popupAppearsOnRight = x >= (anchorPos.X + anchorSize.X * 0.5)
						local y = math.clamp(anchorPos.Y + anchorSize.Y - popupSize.Y, safeTop, maxY)
						MovePopupToAbsolute(WindowSettingsFrame, x, y)
					else
						WindowSettingsFrame.Position = UDim2.new(0.006, 0, 0.44, 0)
					end

					local settled = WindowSettingsFrame.Position
					local entranceOffsetX = popupAppearsOnRight and -7 or 7
					WindowSettingsFrame.Position = UDim2.new(settled.X.Scale, settled.X.Offset + entranceOffsetX, settled.Y.Scale, settled.Y.Offset + 3)
					WSScale.Scale = 0.955
					WindowSettingsFrame.Visible = true
					ApplyZIndexLadder(WindowSettingsFrame, NextPopupZ())
					SmoothOpen(WindowSettingsFrame, 0.01, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					Tween(WSScale, { Scale = 1 }, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					Tween(WindowSettingsFrame, { Position = settled }, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					RegisterPopup(WindowSettingsFrame, closeWS, WindowSettings)
					Tween(SettingsArrow, { Rotation = 180 }, 0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end)
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

	do
		local WMRow = Instance.new("Frame")
		WMRow.Name = "WatermarkRow"
		WMRow.Size = UDim2.new(1, 0, 0, 60)
		WMRow.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
		WMRow.BackgroundTransparency = 1
		WMRow.ZIndex = 120
		WMRow.LayoutOrder = 50
		WMRow.Parent = SettingsContainer

		local wmLabel = Instance.new("TextLabel")
		wmLabel.Name = "Text"
		wmLabel.Position = UDim2.new(0.05, 0, 0, 2)
		wmLabel.Size = UDim2.new(0.9, 0, 0, 14)
		wmLabel.BackgroundTransparency = 1
		wmLabel.Text = "Watermark"
		wmLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		wmLabel.TextTransparency = 0.1
		wmLabel.TextSize = 13
		wmLabel.Font = FONT
		wmLabel.TextXAlignment = Enum.TextXAlignment.Left
		wmLabel.ZIndex = 150
		wmLabel.Parent = WMRow

		local chipsHost = Instance.new("Frame")
		chipsHost.Name = "Chips"
		chipsHost.Position = UDim2.new(0, 12, 0, 20)
		chipsHost.Size = UDim2.new(1, -24, 0, 38)
		chipsHost.ClipsDescendants = true
		chipsHost.BackgroundTransparency = 1
		chipsHost.ZIndex = 150
		chipsHost.Parent = WMRow
		local chipsLayout = Instance.new("UIGridLayout")
		chipsLayout.FillDirection = Enum.FillDirection.Horizontal
		chipsLayout.FillDirectionMaxCells = 3
		chipsLayout.CellSize = UDim2.new(0.31, 0, 0, 17)
		chipsLayout.CellPadding = UDim2.fromOffset(4, 3)
		chipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		chipsLayout.Parent = chipsHost

		local chipDefs = { { "logo", "Logo" }, { "user", "User" }, { "fps", "FPS" }, { "ping", "Ping" }, { "ram", "RAM" }, { "time", "Time" } }
		for index, def in ipairs(chipDefs) do
			local key, caption = def[1], def[2]
			local chip = Instance.new("TextButton")
			chip.Name = "Chip_" .. caption
			chip.Size = UDim2.new(1, 0, 1, 0)
			chip.BackgroundColor3 = Color3.fromRGB(28, 31, 44)
			chip.BackgroundTransparency = 0.2
			chip.BorderSizePixel = 0
			chip.AutoButtonColor = false
			chip.Text = caption
			chip.TextColor3 = Color3.fromRGB(150, 154, 172)
			chip.TextSize = 11
			chip.Font = FONT
			chip.ZIndex = 151
			chip.LayoutOrder = index
			chip.Parent = chipsHost
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = chip end
			do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 5); p.PaddingRight = UDim.new(0, 5); p.Parent = chip end

			local hovered = false
			local function paintChip()
				local on = WindowObj.Watermark.isShown and WindowObj.Watermark.isShown(key)
				chip.BackgroundColor3 = on and mainColor or (hovered and Color3.fromRGB(40, 45, 62) or Color3.fromRGB(28, 31, 44))
				chip.BackgroundTransparency = on and 0.12 or (hovered and 0.08 or 0.2)
				chip.TextColor3 = on and Color3.fromRGB(255, 255, 255) or (hovered and Color3.fromRGB(224, 228, 239) or Color3.fromRGB(150, 154, 172))
			end
			chip.MouseEnter:Connect(function() hovered = true; Tween(chip, {BackgroundTransparency = 0.08}, 0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out); paintChip() end)
			chip.MouseLeave:Connect(function() hovered = false; paintChip() end)
			paintChip()
			chip.MouseButton1Click:Connect(function()
				local on = WindowObj.Watermark.isShown and WindowObj.Watermark.isShown(key)
				if WindowObj.Watermark.toggle then
					WindowObj.Watermark.toggle(key, not on)
				end
				paintChip()
			end)
		end
	end

	local UsageContainer = Instance.new("Frame")
	UsageContainer.Name = "UsageContainer"
	UsageContainer.Position = UDim2.new(0,0,0,0)
	UsageContainer.Size = UDim2.new(1,0,0,0)
	UsageContainer.BackgroundColor3 = Color3.fromRGB(162,162,162)
	UsageContainer.BackgroundTransparency = 1
	UsageContainer.BorderSizePixel = 0
	UsageContainer.ZIndex = 120
	UsageContainer.LayoutOrder = 70
	UsageContainer.AutomaticSize = Enum.AutomaticSize.Y
	UsageContainer.Parent = SettingsContainer
	do
		local ll = Instance.new("UIListLayout")
		ll.Padding = UDim.new(0, 3)
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Parent = UsageContainer
	end

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
			lbl.TextScaled = false; lbl.Font = FONT
			lbl.TextTransparency = 0.5; lbl.ZIndex = 130
			lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = Row
		end

		local Arrow = Instance.new("ImageLabel")
		Arrow.Name = "TextArrow"
		Arrow.AnchorPoint = Vector2.new(1, 0.5)
		Arrow.Position = UDim2.new(1, -12, 0.5, 0)
		Arrow.Size = UDim2.fromOffset(10, 10)
		Arrow.BackgroundTransparency = 1
		Arrow.Image = "rbxassetid://10709790948"
		Arrow.ImageTransparency = 0.4
		Arrow.ImageColor3 = Color3.fromRGB(255,255,255)
		Arrow.ScaleType = Enum.ScaleType.Fit
		Arrow.Rotation = 0
		Arrow.ZIndex = 1000
		Arrow.Parent = Row

		local TextDefault = Instance.new("TextLabel")
		TextDefault.Name = "TextDefault"
		TextDefault.Position = UDim2.new(0.60, 0, 0.17, 0)
		TextDefault.Size = UDim2.new(0.25, 0, 0.6, 0)
		TextDefault.TextTruncate = Enum.TextTruncate.None
		TextDefault.BackgroundTransparency = 1
		TextDefault.Text = selected
		
		TextDefault.TextColor3 = Color3.fromRGB(255,255,255)
		TextDefault.TextScaled = false
		TextDefault.Font = FONT
		TextDefault.TextTransparency = 0.7
		TextDefault.ZIndex = 150
		TextDefault.TextXAlignment = Enum.TextXAlignment.Right
		TextDefault.Parent = Row

		-- ============================================================================
		-- PATCH 4: Settings dropdown — THEME.plate, radius, stroke; no divider watcher
		-- ============================================================================
		local DropPopup = Instance.new("Frame")
		DropPopup.Name = "Dropdown"
		DropPopup.Position = UDim2.new(0.02,0,1,2)
		DropPopup.Size = UDim2.new(0.96,0,0,100)
		DropPopup.BackgroundColor3 = THEME.plate
		DropPopup.BackgroundTransparency = 0
		DropPopup.BorderSizePixel = 0
		DropPopup.Visible = false
		DropPopup.ZIndex = 1000
		DropPopup.Parent = Row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = DropPopup end
		do Stroke(DropPopup) end

		local DropHeader = Instance.new("TextLabel")
		DropHeader.Name = "HeaderLabel"
		DropHeader.Position = UDim2.new(0, 10, 0, 5)
		DropHeader.Size = UDim2.new(1, -20, 0, 14)
		DropHeader.BackgroundTransparency = 1
		DropHeader.Text = tostring(text or "")
		DropHeader.TextColor3 = Color3.fromRGB(122, 124, 136)
			DropHeader.TextSize = 11
		DropHeader.Font = FONT
		DropHeader.TextXAlignment = Enum.TextXAlignment.Left
		DropHeader.TextTruncate = Enum.TextTruncate.AtEnd
		DropHeader.ZIndex = 1000
		DropHeader.Parent = DropPopup

		local DropContainer = Instance.new("ScrollingFrame")
		DropContainer.Name = "Container"
		DropContainer.Position = UDim2.new(0, 4, 0, 22)
		DropContainer.Size = UDim2.new(1, -8, 1, -26)
		DropContainer.BackgroundTransparency = 1
		DropContainer.ZIndex = 1000
		DropContainer.Active = true
		DropContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
		DropContainer.CanvasSize = UDim2.new()
		DropContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		DropContainer.ScrollBarThickness = 2
		DropContainer.ScrollBarImageTransparency = 0.5
		DropContainer.Parent = DropPopup
		do local ll = Instance.new("UIListLayout"); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0, 1); ll.Parent = DropContainer end

		local function closeDropdown()
			dropOpen = false
			Tween(Arrow, {ImageTransparency = 0.4, Rotation = 0}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
			BtnRow.Size = UDim2.new(1, 0, 0, 26)
			BtnRow.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
			BtnRow.BackgroundTransparency = 1
			BtnRow.ZIndex = 1001
			BtnRow.LayoutOrder = i
			BtnRow.Parent = DropContainer
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = BtnRow end

			local lbl = Instance.new("TextLabel")
			lbl.Position = UDim2.new(0, 8, 0, 0)
			lbl.Size = UDim2.new(1, -32, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = opt
			lbl.TextColor3 = Color3.fromRGB(215, 217, 225)
			lbl.TextScaled = false
			lbl.TextSize = 13
			lbl.Font = FONT
			lbl.TextTruncate = Enum.TextTruncate.AtEnd
			lbl.TextTransparency = 0.05
			lbl.ZIndex = 1002
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = BtnRow

			local SelBtn = Instance.new("TextButton")
			SelBtn.Name = "Selected"
			SelBtn.AnchorPoint = Vector2.new(1, 0)
			SelBtn.Position = UDim2.new(1, -6, 0, 0)
			SelBtn.Size = UDim2.new(0, 18, 1, 0)
			SelBtn.BackgroundTransparency = 1
			SelBtn.BorderSizePixel = 0
			SelBtn.Text = ""
			SelBtn.TextColor3 = Color3.fromRGB(78, 131, 255)
			SelBtn.TextScaled = false
			SelBtn.TextSize = 15
			SelBtn.Font = FONT
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
			RowBtn.MouseEnter:Connect(function()
				Tween(BtnRow, { BackgroundTransparency = 0.35 }, 0.08)
			end)
			RowBtn.MouseLeave:Connect(function()
				Tween(BtnRow, { BackgroundTransparency = 1 }, 0.12)
			end)

			local function selectOpt()
				selected = opt
				TextDefault.Text = opt; 
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
				DropPopup.Size = UDim2.new(0.96, 0, 0, math.clamp(26 * #options + 28, 46, 460))
				DropPopup.BackgroundTransparency = 0
						DropPopup.Visible = true
		Tween(Arrow, {Rotation = 180}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				Tween(Arrow, {ImageTransparency = 0}, 0.2)
				PositionPopupWithinMain(DropPopup, true); RegisterPopup(DropPopup, closeDropdown, OpenBtn)
			end
		end)

		updateCheckmarks()

		local obj = {}
		function obj:Set(val, silent) val = GetValidOption(options, val); selected = val; TextDefault.Text = val; ; updateCheckmarks(); if not silent then InvokeCallback(callback, val) end end
		function obj:Get() return selected end
		MakeReadableText(Row, 10, 18)
		return obj
	end

	function UsageObj:AddColorpicker(text, defaultColor, callback)
		usageElemCount = usageElemCount + 1
		local initialColor = NormalizeColor(defaultColor)
		local Row = New("Frame", {
			Name = "Colorpicker",
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = usageElemCount,
			ZIndex = 130,
		}, UsageContainer)
		New("TextLabel", {
			Name = "TextToggle",
			Position = UDim2.new(0.04, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0.65, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = Color3.fromRGB(226, 228, 236),
			TextScaled = false,
			TextSize = 15,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 130,
		}, Row)
		local cpBtn = New("ImageButton", {
			Name = "colorpickerButton",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = initialColor,
			BorderSizePixel = 0,
			Image = "",
			ZIndex = 131,
		}, Row)
		New("UICorner", { CornerRadius = UDim.new(0, 5) }, cpBtn)
		Stroke(cpBtn, "ColorpickerButtonStroke")
		local picker = AcrylicBlur.CreateColorPicker(cpBtn, initialColor, function(c)
			InvokeCallback(callback, c)
		end)
		local obj = {}
		function obj:Set(c)
			local normalized = NormalizeColor(c)
			picker.Set(normalized)
			InvokeCallback(callback, normalized)
		end
		function obj:Get() return picker.Get() end
		MakeReadableText(Row, 10, 18)
		return obj
	end

	function WindowObj:GetUsage() return UsageObj end


	local Tab = New("ScrollingFrame", {
		Name = "Tab",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(0, 170, 1, -115),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollBarImageTransparency = 0.35,
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, MainFrame)
	New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 11) }, Tab)
	New("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Tab)

	

	local Frame2 = New("Frame", {
		Name = "Frame2",
		Position = UDim2.fromOffset(170, 0),
		Size = UDim2.new(1, -170, 1, 0),
		BackgroundColor3 = Color3.fromRGB(15, 17, 24),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, MainFrame)

	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 20); c.Parent = Frame2 end
	New("Frame", { Name = "HeaderDivider", Position = UDim2.new(0, 11, 0, 53), Size = UDim2.new(1, -22, 0, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.93, BorderSizePixel = 0 }, Frame2)

	local Header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, Frame2)

	local SearchBtn = New("ImageButton", {
		Name = "Search",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.fromRGB(162, 162, 162),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031154871",
		ImageColor3 = Color3.fromRGB(200, 204, 218),
		ImageTransparency = 0.2,
	}, Header)

local asss = Instance.new("UIAspectRatioConstraint")
asss.Parent = SearchBtn


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

	

	local GlobalPreset
	local Save = Instance.new("Frame")
	Save.Name = "Save"
	Save.Position = UDim2.fromOffset(11, 13)
	Save.Size = UDim2.fromOffset(150, 28)
	Save.BackgroundColor3 = Color3.fromRGB(20, 23, 34)
	Save.BackgroundTransparency = 0
	Save.BorderSizePixel = 0
	Save.Parent = Header
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = Save end
	do Stroke(Save) end

	local SaveIcon = Instance.new('ImageLabel')
SaveIcon.Name = "SaveIcon"
SaveIcon.Position = UDim2.fromOffset(10, 8)
SaveIcon.Size = UDim2.fromOffset(13, 13)
SaveIcon.BackgroundTransparency = 1
SaveIcon.Image = "rbxassetid://6035067857"
SaveIcon.ImageTransparency = 0.20000000298023224
SaveIcon.Parent = Save

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.Parent = SaveIcon

	local SaveText = Instance.new('TextLabel')
	SaveText.Name = "SaveText"
	SaveText.Position = UDim2.fromOffset(42, 0)
	SaveText.Size = UDim2.new(1, -82, 1, 0)
	SaveText.BackgroundTransparency = 1
	SaveText.Text = "Default"
SaveText.TextColor3 = Color3.fromRGB(226, 228, 236)
SaveText.TextScaled = false
SaveText.TextSize = 15
SaveText.Font = FONT
SaveText.TextTransparency = 0.20000000298023224
SaveText.TextXAlignment = Enum.TextXAlignment.Left
SaveText.TextTruncate = Enum.TextTruncate.AtEnd
SaveText.Parent = Save

	local function UpdateSavePillWidth(textValue)
		local textWidth = MeasureText(tostring(textValue or SaveText.Text or "Default"), 15, FONT)
		local width = math.clamp(math.ceil(textWidth) + 42 + 40, 150, 265)
		Save.Size = UDim2.fromOffset(width, 28)
		Save.Position = UDim2.fromOffset(11, 13)
		SaveText.Size = UDim2.new(1, -82, 1, 0)
		if GlobalPreset then GlobalPreset.Position = UDim2.fromOffset(11 + width + 17, 13) end
	end
	UpdateSavePillWidth(SaveText.Text)

	local function FlashSaved()
		if not Save then return end
		Tween(Save, { BackgroundColor3 = mainColor }, 0.09)
		task.delay(0.1, function()
			if Save then Tween(Save, { BackgroundColor3 = Color3.fromRGB(17, 19, 27) }, 0.22) end
		end)
	end
	local function ShowSavedName()
		if not SaveText then return end
		SaveText.Text = activeConfigName or "Default"
		UpdateSavePillWidth(SaveText.Text)
	end

local Lines = Instance.new('Frame')
Lines.Name = "Lines"
Lines.Position = UDim2.new(0, -10, 0.15, 0)
Lines.Size = UDim2.new(0, 1, 0.70, 0)
Lines.BackgroundColor3 = Color3.fromRGB(255,255,255)
Lines.BackgroundTransparency = 0.92
Lines.BorderSizePixel = 0
Lines.Parent = SaveText
Lines.Visible = false

local Lines_2 = Instance.new('Frame')
Lines_2.Name = "Lines"
Lines_2.Position = UDim2.new(1,0,-0.19000010192394257,0)
Lines_2.Size = UDim2.new(-0.0010000000474974513,1,1.2000000476837158,3)
Lines_2.Visible = false
Lines_2.BackgroundColor3 = Color3.fromRGB(255,255,255)
Lines_2.BackgroundTransparency = 1
Lines_2.BorderSizePixel = 0
Lines_2.Parent = SaveText

local SaveArrow = Instance.new('ImageLabel')
SaveArrow.Name = "Arrow"
SaveArrow.AnchorPoint = Vector2.new(1, 0.5)
SaveArrow.Position = UDim2.new(1, -17, 0.5, 0)
SaveArrow.Size = UDim2.fromOffset(10, 10)
SaveArrow.BackgroundTransparency = 1
SaveArrow.Image = "rbxassetid://10709790948"
SaveArrow.ImageColor3 = Color3.fromRGB(255,255,255)
SaveArrow.ScaleType = Enum.ScaleType.Fit
SaveArrow.Rotation = 0
SaveArrow.ZIndex = 15
SaveArrow.Parent = Save

GlobalPreset = New("Frame", {
	Name = "GlobalPreset",
	Position = UDim2.fromOffset(178, 13),
	Size = UDim2.fromOffset(83, 28),
	BackgroundColor3 = Color3.fromRGB(20, 23, 34),
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
}, Header)
New("UICorner", { CornerRadius = UDim.new(0, 8) }, GlobalPreset)
Stroke(GlobalPreset)
New("TextLabel", {
	Name = "GlobalPresetLabel",
	Position = UDim2.fromOffset(11, 0),
	Size = UDim2.new(1, -34, 1, 0),
	BackgroundTransparency = 1,
	Text = "Global",
	TextColor3 = Color3.fromRGB(226, 228, 236),
	TextSize = 15,
	Font = FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, GlobalPreset)
New("ImageLabel", {
	Name = "GlobalPresetArrow",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(10, 10),
	BackgroundTransparency = 1,
	Image = "rbxassetid://10709790948",
	ImageColor3 = Color3.fromRGB(150, 155, 172),
	ScaleType = Enum.ScaleType.Fit,
	Rotation = 0,
}, GlobalPreset)
GlobalPreset.Visible = false
UpdateSavePillWidth(SaveText.Text)
local function ShouldShowGlobalPreset(tabName)
	local normalized = string.lower(tostring(tabName or ""))
	return string.find(normalized, "legit", 1, true) ~= nil
		or string.find(normalized, "rage", 1, true) ~= nil
end

local UIAspectRatioConstraint = Instance.new('UIAspectRatioConstraint')
UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
UIAspectRatioConstraint.AspectRatio = 1
UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
UIAspectRatioConstraint.Parent = SaveArrow


	local TriggerSaveConfig = Instance.new("TextButton")
	TriggerSaveConfig.Name = "TriggerSaveConfig"
	TriggerSaveConfig.Size = UDim2.new(1, 0, 1, 0)
	TriggerSaveConfig.BackgroundTransparency = 1
	TriggerSaveConfig.Text = ""
	TriggerSaveConfig.ZIndex = 15
	TriggerSaveConfig.Parent = Save

	local ConfigMainFrame = Instance.new("Frame")
	ConfigMainFrame.Name = "ConfigMainFrame"
	ConfigMainFrame.Position = UDim2.fromOffset(11, 47)
	ConfigMainFrame.Size = UDim2.fromOffset(250, 104)
	ConfigMainFrame.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	ConfigMainFrame.BackgroundTransparency = 0.045
	ConfigMainFrame.BorderSizePixel = 0
	ConfigMainFrame.ZIndex = 110
	ConfigMainFrame.AutomaticSize = Enum.AutomaticSize.None
	ConfigMainFrame.ClipsDescendants = false
	ConfigMainFrame.Active = true
	ConfigMainFrame.Visible = false
	ConfigMainFrame.Parent = Frame2
	local ConfigScale = Instance.new("UIScale")
	ConfigScale.Scale = 1
	ConfigScale.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = ConfigMainFrame end
	do Stroke(ConfigMainFrame) end
	AttachShadow(ConfigMainFrame, { radius = 10, layers = 4, step = 1.25, bias = 2 })

	local CMHeader = Instance.new("Frame")
	CMHeader.Name = "Header"
	CMHeader.Size = UDim2.new(1, 0, 0, 46)
	CMHeader.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	CMHeader.BackgroundTransparency = 0
	CMHeader.BorderSizePixel = 0
	CMHeader.ClipsDescendants = true
	CMHeader.ZIndex = 100
	CMHeader.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = CMHeader end

	do
		local CMHeaderRule = Instance.new("Frame")
		CMHeaderRule.Name = "HeaderRule"
		CMHeaderRule.Position = UDim2.new(0, 14, 1, -1)
		CMHeaderRule.Size = UDim2.new(1, -28, 0, 1)
		CMHeaderRule.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		CMHeaderRule.BackgroundTransparency = 0.92
		CMHeaderRule.BorderSizePixel = 0
		CMHeaderRule.ZIndex = 1000
		CMHeaderRule.Parent = CMHeader
	end

	local CloudIcon = Instance.new("ImageLabel")
	CloudIcon.Name = "CloudIcon"
	CloudIcon.AnchorPoint = Vector2.new(0, 0.5)
	CloudIcon.Position = UDim2.new(0, 16, 0.5, 0)
	CloudIcon.Size = UDim2.fromOffset(18, 18)
	CloudIcon.BackgroundTransparency = 1
	CloudIcon.Image = "rbxassetid://97828544806816"
	CloudIcon.ImageColor3 = mainColor
	CloudIcon.ScaleType = Enum.ScaleType.Fit
	CloudIcon.ZIndex = 1000
	CloudIcon.Parent = CMHeader

	local CMTitle = Instance.new("TextLabel")
	CMTitle.Name = "TitleLabel"
	CMTitle.Position = UDim2.new(0, 44, 0, 0)
	CMTitle.Size = UDim2.new(1, -154, 1, 0)
	CMTitle.BackgroundTransparency = 1
	CMTitle.Text = "Presets"
	CMTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	CMTitle.TextSize = 15
	CMTitle.Font = FONT
	CMTitle.TextTransparency = 0.05
	CMTitle.ZIndex = 1000
	CMTitle.TextXAlignment = Enum.TextXAlignment.Left
	CMTitle.Parent = CMHeader

	local CMHeaderRight = Instance.new("Frame")
	CMHeaderRight.Name = "HeaderRight"
	CMHeaderRight.AnchorPoint = Vector2.new(1, 0)
	CMHeaderRight.Position = UDim2.new(1, -14, 0, 0)
	CMHeaderRight.Size = UDim2.fromOffset(96, 46)
	CMHeaderRight.BackgroundTransparency = 1
	CMHeaderRight.ZIndex = 1000
	CMHeaderRight.Parent = CMHeader
	do
		local ll = Instance.new("UIListLayout")
		ll.FillDirection = Enum.FillDirection.Horizontal
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ll.VerticalAlignment = Enum.VerticalAlignment.Center
		ll.Padding = UDim.new(0, 10)
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Parent = CMHeaderRight
	end

	local IDLE_ICON_TINT = Color3.fromRGB(176, 180, 198)
	local autoSaveEnabled = false
	local AutoSaveBtn, RecentlyDeletedBtn, InsertConfigBtn
	do
		local function HeaderIconButton(name, asset, order)
			local btn = Instance.new("ImageButton")
			btn.Name = name
			btn.Size = UDim2.fromOffset(18, 18)
			btn.BackgroundTransparency = 1
			btn.Image = asset
			btn.ImageColor3 = IDLE_ICON_TINT
			btn.ScaleType = Enum.ScaleType.Fit
			btn.ZIndex = 1000
			btn.LayoutOrder = order
			btn.Parent = CMHeaderRight
			btn.MouseEnter:Connect(function()
				Tween(btn, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.1)
			end)
			btn.MouseLeave:Connect(function()
				if btn:GetAttribute("Pinned") ~= true then
					Tween(btn, { ImageColor3 = IDLE_ICON_TINT }, 0.15)
				end
			end)
			return btn
		end

		AutoSaveBtn = HeaderIconButton("AutomaticSave", "rbxassetid://122894934359450", 1)
		RecentlyDeletedBtn = HeaderIconButton("RecentlyDeleted", "rbxassetid://3926305904", 2)
		RecentlyDeletedBtn.ImageRectOffset = Vector2.new(805, 45)
		RecentlyDeletedBtn.ImageRectSize = Vector2.new(35, 35)
		InsertConfigBtn = HeaderIconButton("InsertConfig", "rbxassetid://101123124881873", 3)
	end

	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Position = UDim2.new(0, 14, 0, 54)
	SearchContainer.Size = UDim2.new(1, -28, 0, 34)
	SearchContainer.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
	SearchContainer.BorderSizePixel = 0
	SearchContainer.ZIndex = 1000
	SearchContainer.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = SearchContainer end
	do Stroke(SearchContainer) end

	local SearchIconImg = Instance.new("ImageLabel")
	SearchIconImg.Name = "SearchIcon"
	SearchIconImg.AnchorPoint = Vector2.new(0, 0.5)
	SearchIconImg.Position = UDim2.new(0, 10, 0.5, 0)
	SearchIconImg.Size = UDim2.fromOffset(16, 16)
	SearchIconImg.BackgroundTransparency = 1
	SearchIconImg.Image = "rbxassetid://6031154871"
	SearchIconImg.ImageColor3 = Color3.fromRGB(130, 134, 152)
	SearchIconImg.ScaleType = Enum.ScaleType.Fit
	SearchIconImg.ZIndex = 1000
	SearchIconImg.Parent = SearchContainer

	local ConfigSearchBox = Instance.new("TextBox")
	ConfigSearchBox.Name = "SearchBox"
	ConfigSearchBox.Position = UDim2.new(0, 34, 0, 0)
	ConfigSearchBox.Size = UDim2.new(1, -44, 1, 0)
	ConfigSearchBox.BackgroundTransparency = 1
	ConfigSearchBox.Text = ""
	ConfigSearchBox.PlaceholderText = "Search"
	ConfigSearchBox.PlaceholderColor3 = Color3.fromRGB(130, 134, 152)
	ConfigSearchBox.TextColor3 = Color3.fromRGB(228, 230, 238)
	ConfigSearchBox.TextSize = 14
	ConfigSearchBox.Font = FONT
	ConfigSearchBox.ZIndex = 1000
	ConfigSearchBox.TextXAlignment = Enum.TextXAlignment.Left
	ConfigSearchBox.ClearTextOnFocus = false
	ConfigSearchBox.Parent = SearchContainer

	local NameInputContainer = Instance.new("Frame")
	NameInputContainer.Name = "NameInputContainer"
	NameInputContainer.Position = UDim2.new(0, 14, 0, 56)
	NameInputContainer.Size = UDim2.new(1, -28, 0, 34)
	NameInputContainer.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
	NameInputContainer.BorderSizePixel = 0
	NameInputContainer.ZIndex = 1001
	NameInputContainer.Visible = false
	NameInputContainer.Parent = ConfigMainFrame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = NameInputContainer end
	do Stroke(NameInputContainer) end

	local NameOfConfig = Instance.new("TextBox")
	NameOfConfig.Name = "NameOfConfig"
	NameOfConfig.Position = UDim2.new(0, 12, 0, 0)
	NameOfConfig.Size = UDim2.new(1, -96, 1, 0)
	NameOfConfig.BackgroundTransparency = 1
	NameOfConfig.Text = ""
	NameOfConfig.PlaceholderText = "Config name..."
	NameOfConfig.PlaceholderColor3 = Color3.fromRGB(130, 134, 152)
	NameOfConfig.TextColor3 = Color3.fromRGB(228, 230, 238)
	NameOfConfig.TextSize = 14
	NameOfConfig.Font = FONT
	NameOfConfig.ZIndex = 1001
	NameOfConfig.TextXAlignment = Enum.TextXAlignment.Left
	NameOfConfig.ClearTextOnFocus = false
	NameOfConfig.Parent = NameInputContainer

	local ConfirmAddBtn = Instance.new("TextButton")
	ConfirmAddBtn.Name = "ConfirmAdd"
	ConfirmAddBtn.AnchorPoint = Vector2.new(1, 0.5)
	ConfirmAddBtn.Position = UDim2.new(1, -14, 0.5, 0)
	ConfirmAddBtn.Size = UDim2.new(0, 72, 0, 24)
	ConfirmAddBtn.BackgroundColor3 = mainColor
	ConfirmAddBtn.BackgroundTransparency = 0.1
	ConfirmAddBtn.Text = "Create"
	ConfirmAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ConfirmAddBtn.TextSize = 12
	ConfirmAddBtn.Font = FONT
	ConfirmAddBtn.ZIndex = 1002
	ConfirmAddBtn.Parent = NameInputContainer
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = ConfirmAddBtn end

	local ListContainer = Instance.new("ScrollingFrame")
	ListContainer.Name = "ListContainer"
	ListContainer.Position = UDim2.new(0, 14, 0, 96)
	ListContainer.Size = UDim2.new(1, -28, 1, -104)
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
		ll.Padding = UDim.new(0, 2)
		ll.Parent = ListContainer
	end

	local Space = Instance.new("Frame")
	Space.Name = "Space"
	Space.Size = UDim2.new(1, 0, 0, 0)
	Space.BackgroundTransparency = 1
	Space.ZIndex = 100
	Space.Parent = ListContainer

	local SAVE_ICON = "rbxassetid://122894934359450"
	local LOAD_ICON = "rbxassetid://109698732019071"

	local DELETED_FILE = "NeverloseDeleted_" .. windowConfigId .. ".json"
	local _deletedConfigs = {}

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

	local RecentlyDeletedPanel = Instance.new("Frame")
	RecentlyDeletedPanel.Name = "RecentlyDeletedPanel"
	RecentlyDeletedPanel.Position = UDim2.new(0.012, 0, 0.075, 0)
	RecentlyDeletedPanel.Size = UDim2.new(0.34, 0, 0.42, 0)
	RecentlyDeletedPanel.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	RecentlyDeletedPanel.BackgroundTransparency = 0.045
	RecentlyDeletedPanel.BorderSizePixel = 0
	RecentlyDeletedPanel.ZIndex = 120
	RecentlyDeletedPanel.AutomaticSize = Enum.AutomaticSize.None
	RecentlyDeletedPanel.ClipsDescendants = false
	RecentlyDeletedPanel.Active = true
	RecentlyDeletedPanel.Visible = false
	RecentlyDeletedPanel.Parent = Frame2
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = RecentlyDeletedPanel end
	do Stroke(RecentlyDeletedPanel) end
	AttachShadow(RecentlyDeletedPanel, { radius = 10, layers = 4, step = 1.25, bias = 2 })

	local RDHeader = Instance.new("Frame")
	RDHeader.Name = "RDHeader"
	RDHeader.Size = UDim2.new(1, 0, 0, 46)
	RDHeader.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	RDHeader.BorderSizePixel = 0
	RDHeader.ClipsDescendants = true
	RDHeader.ZIndex = 121
	RDHeader.Parent = RecentlyDeletedPanel
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = RDHeader end
	do
		local rule = Instance.new("Frame")
		rule.Name = "HeaderRule"
		rule.Position = UDim2.new(0, 14, 1, -1)
		rule.Size = UDim2.new(1, -28, 0, 1)
		rule.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		rule.BackgroundTransparency = 0.92
		rule.BorderSizePixel = 0
		rule.ZIndex = 122
		rule.Parent = RDHeader
	end

	local RDTitle = Instance.new("TextLabel")
	RDTitle.Name = "RDTitle"
	RDTitle.Position = UDim2.new(0, 16, 0, 0)
	RDTitle.Size = UDim2.new(1, -130, 1, 0)
	RDTitle.BackgroundTransparency = 1
	RDTitle.Text = "Recently Deleted"
	RDTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	RDTitle.TextSize = 15
	RDTitle.Font = FONT
	RDTitle.TextXAlignment = Enum.TextXAlignment.Left
	RDTitle.ZIndex = 122
	RDTitle.Parent = RDHeader

	local RDBackBtn = Instance.new("TextButton")
	RDBackBtn.Name = "RDBackBtn"
	RDBackBtn.AnchorPoint = Vector2.new(1, 0.5)
	RDBackBtn.Position = UDim2.new(1, -14, 0.5, 0)
	RDBackBtn.Size = UDim2.fromOffset(84, 26)
	RDBackBtn.BackgroundColor3 = Color3.fromRGB(28, 31, 44)
	RDBackBtn.BackgroundTransparency = 0.1
	RDBackBtn.Text = "← Back"
	RDBackBtn.TextColor3 = Color3.fromRGB(210, 212, 222)
	RDBackBtn.TextSize = 12
	RDBackBtn.Font = FONT
	RDBackBtn.ZIndex = 122
	RDBackBtn.Parent = RDHeader
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = RDBackBtn end

	local RDList = Instance.new("ScrollingFrame")
	RDList.Name = "RDList"
	RDList.Position = UDim2.new(0, 14, 0, 60)
	RDList.Size = UDim2.new(1, -28, 1, -74)
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
		for i = #_deletedConfigs, 1, -1 do
			local entry = _deletedConfigs[i]
			local drow = Instance.new("Frame")
			drow.Name = "DeletedRow"
			drow.Size = UDim2.new(1, 0, 0, 36)
			drow.BackgroundColor3 = Color3.fromRGB(35,18,18)
			drow.BackgroundTransparency = 0.25
			drow.BorderSizePixel = 0
			drow.ZIndex = 122
			drow.Parent = RDList
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = drow end
			do Stroke(drow) end

			local dlbl = Instance.new("TextLabel")
			dlbl.Position = UDim2.new(0.04, 0, 0, 0)
			dlbl.Size = UDim2.new(0.6, 0, 1, 0)
			dlbl.BackgroundTransparency = 1
			dlbl.Text = entry.name
			dlbl.TextColor3 = Color3.fromRGB(220, 180, 180)
			dlbl.TextSize = 15
			dlbl.Font = FONT
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
			restoreBtn.Font = FONT
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

	local closeConfigPanel
	local configOpen = false
	RDBackBtn.MouseButton1Click:Connect(function()
		UnregisterPopup(RecentlyDeletedPanel)
		Tween(RecentlyDeletedPanel, {BackgroundTransparency = 1}, 0.2)
		task.delay(0.22, function()
			if not configOpen then return end
			RecentlyDeletedPanel.Visible = false
			ConfigMainFrame.BackgroundTransparency = 1
			ConfigMainFrame.Visible = true
			ConstrainPopupToMainFrame(ConfigMainFrame); task.defer(function() ConstrainPopupToMainFrame(ConfigMainFrame) end); RegisterPopup(ConfigMainFrame, closeConfigPanel, TriggerSaveConfig)
			ConfigScale.Scale = 0.94
			Tween(ConfigScale, { Scale = 1 }, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			Tween(ConfigMainFrame, { BackgroundTransparency = 0.045 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
	end)

	local activeRow = nil
	local activeLoadBtn = nil
	local activeConfigName = nil

	local function SetActiveConfigName(name)
		if type(name) == "string" and name ~= "" and name ~= "Save" then
			activeConfigName = name
		else
			activeConfigName = nil
		end
		SaveText.Text = activeConfigName or "Default"
		UpdateSavePillWidth(SaveText.Text)
	end

	local function ClearActiveConfig()
		activeRow = nil
		activeLoadBtn = nil
		SetActiveConfigName(nil)
	end

	local function DeactivateRow(rowFrame, loadBtn)
		local s = rowFrame:FindFirstChildWhichIsA("UIStroke")
		if s then Tween(s, {Transparency = 1}, 0.15) end
		Tween(rowFrame, {BackgroundTransparency = 0.25}, 0.15)
		loadBtn.Image = LOAD_ICON
		Tween(loadBtn, {ImageColor3 = Color3.fromRGB(180, 180, 200)}, 0.15)
	end

	local function MakeConfigButton(name)
		local row = Instance.new("Frame")
		row.Name = "ConfigRow_" .. name
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = Color3.fromRGB(16, 18, 27)
		row.BackgroundTransparency = 0.25
		row.BorderSizePixel = 0
		row.ZIndex = 1000
		row.Parent = ListContainer
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = row end

		local rowStroke = Stroke(row, "ConfigRowStroke")
		rowStroke.Transparency = 1
		row.MouseEnter:Connect(function()
			Tween(row, { BackgroundTransparency = 0.12 }, 0.1, Enum.EasingStyle.Sine)
			Tween(rowStroke, { Transparency = activeRow == row and 0.3 or 0.78 }, 0.1, Enum.EasingStyle.Sine)
		end)
		row.MouseLeave:Connect(function()
			Tween(row, { BackgroundTransparency = activeRow == row and 0.5 or 0.25 }, 0.13, Enum.EasingStyle.Sine)
			Tween(rowStroke, { Transparency = activeRow == row and 0.3 or 1 }, 0.13, Enum.EasingStyle.Sine)
		end)

		local Rename = Instance.new("TextBox")
		Rename.Name = "Rename"
		Rename.Position = UDim2.new(0, 12, 0, 0)
		Rename.Size = UDim2.new(1, -80, 1, 0)
		Rename.BackgroundTransparency = 1
		Rename.Text = name
		Rename.PlaceholderText = "No Name"
		Rename.PlaceholderColor3 = Color3.fromRGB(130, 134, 152)
		Rename.TextColor3 = Color3.fromRGB(228, 230, 238)
		Rename.TextSize = 14
		Rename.Font = FONT
		Rename.ZIndex = 1000
		Rename.TextXAlignment = Enum.TextXAlignment.Left
		Rename.TextTruncate = Enum.TextTruncate.AtEnd
		Rename.ClearTextOnFocus = false
		pcall(function() Rename.ReadOnly = true end)
		Rename.Parent = row

		local SettingsBtn = Instance.new("TextButton")
		SettingsBtn.Name = "Settings"
		SettingsBtn.AnchorPoint = Vector2.new(1, 0)
		SettingsBtn.Position = UDim2.new(1, -34, 0, 0)
		SettingsBtn.Size = UDim2.fromOffset(28, 36)
		SettingsBtn.BackgroundTransparency = 1
		SettingsBtn.Text = ""
		SettingsBtn.ZIndex = 3000
		SettingsBtn.Parent = row
		do
			local dotsIcon = Instance.new("ImageLabel")
			dotsIcon.Name = "DotsIcon"
			dotsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			dotsIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
			dotsIcon.Size = UDim2.fromOffset(16, 16)
			dotsIcon.BackgroundTransparency = 1
			dotsIcon.Image = "rbxassetid://95127553964880"
			dotsIcon.ImageColor3 = Color3.fromRGB(176, 180, 198)
			dotsIcon.ScaleType = Enum.ScaleType.Fit
			dotsIcon.ZIndex = 3001
			dotsIcon.Parent = SettingsBtn
		end

		local LoadConfigBtn = Instance.new("ImageButton")
		LoadConfigBtn.Name = "LoadConfig"
		LoadConfigBtn.AnchorPoint = Vector2.new(1, 0.5)
		LoadConfigBtn.Position = UDim2.new(1, -14, 0.5, 0)
		LoadConfigBtn.Size = UDim2.fromOffset(18, 18)
		LoadConfigBtn.BackgroundTransparency = 1
		LoadConfigBtn.Image = LOAD_ICON
		LoadConfigBtn.ImageColor3 = Color3.fromRGB(176, 180, 198)
		LoadConfigBtn.ScaleType = Enum.ScaleType.Fit
		LoadConfigBtn.ZIndex = 3000
		LoadConfigBtn.Parent = row

		local SettingsFrame = Instance.new("Frame")
		SettingsFrame.Name = "SettingsFrame"
		SettingsFrame.Position = UDim2.new(0.02, 0, 1, 2)
		SettingsFrame.Size = UDim2.new(0.96, 0, 0, 0)
		SettingsFrame.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
		SettingsFrame.BackgroundTransparency = 0.045
		SettingsFrame.BorderSizePixel = 0
		SettingsFrame.ZIndex = 6000
		SettingsFrame.AutomaticSize = Enum.AutomaticSize.None
		SettingsFrame.Visible = false
		SettingsFrame.ClipsDescendants = false
		SettingsFrame.Active = true
		SettingsFrame.Parent = row
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = SettingsFrame end
		local SettingsFrameStroke = Stroke(SettingsFrame, "SettingsFrameStroke")
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
			btn.Font = FONT
			btn.ZIndex = 6001
			btn.Parent = SettingsFrame

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

		MakeSettingBtn("Delete", Color3.fromRGB(255, 80, 80), function()
			local configData = {}
			for _, entry in ipairs(_registeredElements) do
				local ok, val = pcall(function() return entry.obj:Get() end)
				if ok then
					local s = SerializeValue(val)
					if s ~= nil then configData[entry.key] = s end
				end
			end
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
			table.insert(_deletedConfigs, { name = name, data = configData })
			if #_deletedConfigs > 20 then table.remove(_deletedConfigs, 1) end
			SaveDeletedList()
			if activeRow == row then
				ClearActiveConfig()
			end
			Tween(row, {BackgroundTransparency = 1}, 0.2)
			task.delay(0.22, function() row:Destroy() end)
		end)

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

		closeSfRow = function()
			sfOpen = false
			UnregisterPopup(SettingsFrame)
			Tween(SettingsFrame, { Size = UDim2.new(0.44, 0, 0, 0), BackgroundTransparency = 1 }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Tween(SettingsFrameStroke, { Transparency = 1 }, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			task.delay(0.19, function() if not sfOpen then SettingsFrame.Visible = false end end)
		end
		SettingsBtn.MouseButton1Click:Connect(function()
			sfOpen = not sfOpen
			if sfOpen then
				CloseAllPopupsExcept(SettingsFrame)
				SettingsFrame.BackgroundTransparency = 1
				SettingsFrame.Visible = true
				local targetSize = UDim2.new(0.44, 0, 0, SF_ROW_HEIGHT)
				SettingsFrame.Size = targetSize
				PositionPopupWithinMain(SettingsFrame, true)
				local targetPosition = SettingsFrame.Position
				SettingsFrame.Size = UDim2.new(0.44, 0, 0, 0)
				SettingsFrame.Position = targetPosition
				RegisterPopup(SettingsFrame, closeSfRow, SettingsBtn)
				SettingsFrameStroke.Transparency = 1
				Tween(SettingsFrame, { Size = targetSize, BackgroundTransparency = 0.045 }, 0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				Tween(SettingsFrameStroke, { Transparency = 0.5 }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			else
				closeSfRow()
			end
		end)

		local RowOverlay = Instance.new("TextButton")
		RowOverlay.Name = "RowOverlay"
		RowOverlay.Size = UDim2.new(1, -72, 1, 0)
		RowOverlay.BackgroundTransparency = 1
		RowOverlay.Text = ""
		RowOverlay.ZIndex = 2500
		RowOverlay.Parent = row
		RowOverlay.MouseButton1Click:Connect(function()
			if sfOpen then closeSfRow() end
		end)

		LoadConfigBtn.MouseButton1Click:Connect(function()
			if activeRow == row then
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
				Tween(rowStroke, {Transparency = 0.3, Color = mainColor}, 0.2)
				Tween(row, {BackgroundTransparency = 0.5}, 0.2)
				LoadConfigBtn.Image = SAVE_ICON
				Tween(LoadConfigBtn, {ImageColor3 = mainColor}, 0.2)
			end
		end)

		local query = string.lower(tostring(ConfigSearchBox.Text or "")):gsub("^%s+", ""):gsub("%s+$", "")
		row.Visible = query == "" or string.lower(Rename.Text or ""):find(query, 1, true) ~= nil
		return row
	end

	local function UpdateConfigPanelHeight()
		local frame2H = Frame2.AbsoluteSize.Y
		local maxH = math.min(370, math.max(104, (frame2H > 0 and frame2H or 480) - 53))
		local function countRows(container)
			local count = 0
			for _, c in ipairs(container:GetChildren()) do
				if c:IsA("Frame") and c.Name ~= "Space" and c.Visible then count = count + 1 end
			end
			return count
		end
		local cfgH = 104 + math.min(countRows(ListContainer), 7) * 38
		local rdH = 88 + countRows(RDList) * 34
		ConfigMainFrame.Size = UDim2.fromOffset(250, math.clamp(cfgH, 104, maxH))
		RecentlyDeletedPanel.Size = UDim2.new(0.34, 0, 0, math.clamp(rdH, 180, maxH))
	end
	ListContainer.ChildAdded:Connect(function() task.defer(UpdateConfigPanelHeight) end)
	ListContainer.ChildRemoved:Connect(function() task.defer(UpdateConfigPanelHeight) end)
	RDList.ChildAdded:Connect(function() task.defer(UpdateConfigPanelHeight) end)
	RDList.ChildRemoved:Connect(function() task.defer(UpdateConfigPanelHeight) end)

	local function RefreshConfigList()
		ClearActiveConfig()
		for _, c in ipairs(ListContainer:GetChildren()) do
			if c:IsA("Frame") and c.Name ~= "Space" then c:Destroy() end
		end
		local list = ListConfigs()
		for _, n in ipairs(list) do
			MakeConfigButton(n)
		end
		UpdateConfigPanelHeight()
	end

	local insertMode = false
	InsertConfigBtn.MouseButton1Click:Connect(function()
		insertMode = not insertMode
		SearchContainer.Visible = not insertMode
		NameInputContainer.Visible = insertMode
		if insertMode then
			InsertConfigBtn:SetAttribute("Pinned", true)
			Tween(InsertConfigBtn, {ImageColor3 = mainColor}, 0.2)
			task.spawn(function() NameOfConfig:CaptureFocus() end)
		else
			InsertConfigBtn:SetAttribute("Pinned", false)
			Tween(InsertConfigBtn, {ImageColor3 = IDLE_ICON_TINT}, 0.2)
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

	ConfigSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		-- Use the same whitespace normalization as row creation so a row does
		-- not flicker out when the query contains leading/trailing spaces.
		local query = string.lower(tostring(ConfigSearchBox.Text or "")):gsub("^%s+", ""):gsub("%s+$", "")
		for _, c in ipairs(ListContainer:GetChildren()) do
			if c:IsA("Frame") and c.Name ~= "Space" then
				local rename = c:FindFirstChild("Rename")
				if rename then
					local name = string.lower(tostring(rename.Text or ""))
					c.Visible = query == "" or name:find(query, 1, true) ~= nil
				end
			end
		end
		task.defer(UpdateConfigPanelHeight)
	end)

	local function SaveActiveConfig()
		if not autoSaveEnabled then return end
		if not activeRow or not activeLoadBtn then return end
		local n = activeConfigName
		if type(n) ~= "string" or n == "" or n == "Save" then return end
		SaveNamedConfig(n)
		ShowSavedName()
		FlashSaved()
	end

	AutoSaveBtn.MouseButton1Click:Connect(function()
		autoSaveEnabled = not autoSaveEnabled
		if autoSaveEnabled then
			AutoSaveBtn:SetAttribute("Pinned", true)
			Tween(AutoSaveBtn, {ImageColor3 = mainColor}, 0.2)
			SaveActiveConfig()
		else
			AutoSaveBtn:SetAttribute("Pinned", false)
			Tween(AutoSaveBtn, {ImageColor3 = IDLE_ICON_TINT}, 0.2)
		end
	end)

	if type(writefile) == "function" then
		task.spawn(function()
			while true do
				task.wait(30)
				SaveActiveConfig()
			end
		end)
	end

	if LocalPlayer and LocalPlayer.CharacterRemoving then
		LocalPlayer.CharacterRemoving:Connect(function()
			SaveActiveConfig()
		end)
	end

	RecentlyDeletedBtn.MouseButton1Click:Connect(function()
		UnregisterPopup(ConfigMainFrame)
		Tween(ConfigMainFrame, {BackgroundTransparency = 1}, 0.2)
		task.delay(0.22, function()
			if not configOpen then return end
			ConfigMainFrame.Visible = false
			RefreshDeletedList()
			RecentlyDeletedPanel.BackgroundTransparency = 1
			RecentlyDeletedPanel.Visible = false
			ApplyZIndexLadder(RecentlyDeletedPanel, NextPopupZ())
			RecentlyDeletedPanel.Visible = true
			ConstrainPopupToMainFrame(RecentlyDeletedPanel); task.defer(function() ConstrainPopupToMainFrame(RecentlyDeletedPanel) end); RegisterPopup(RecentlyDeletedPanel, closeConfigPanel, RecentlyDeletedBtn)
			Tween(RecentlyDeletedPanel, { BackgroundTransparency = 0.045 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local rdScale = GetPopupScale(RecentlyDeletedPanel)
			if rdScale then
				rdScale.Scale = 0.975
				Tween(rdScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			end
		end)
	end)

	closeConfigPanel = function()
		configOpen = false
		ClearActiveConfig()
		ClosePopupsUnder(ConfigMainFrame)
		ClosePopupsUnder(RecentlyDeletedPanel)
		UnregisterPopup(ConfigMainFrame)
		UnregisterPopup(RecentlyDeletedPanel)
		Tween(ConfigMainFrame, { BackgroundTransparency = 1 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Tween(ConfigScale, { Scale = 0.94 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Tween(RecentlyDeletedPanel, { BackgroundTransparency = 1 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local rdScale = RecentlyDeletedPanel:FindFirstChild("_PopScale")
		if rdScale and rdScale:IsA("UIScale") then Tween(rdScale, { Scale = 0.94 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		Tween(SaveArrow, { Rotation = 0 }, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
			RefreshConfigList()
			ConfigMainFrame.BackgroundTransparency = 1
			ConfigMainFrame.Visible = false
			ConfigMainFrame.ZIndex = 7000
			ApplyZIndexLadder(ConfigMainFrame, NextPopupZ())
			ConstrainPopupToMainFrame(ConfigMainFrame); task.defer(function() ConstrainPopupToMainFrame(ConfigMainFrame) end); RegisterPopup(ConfigMainFrame, closeConfigPanel, TriggerSaveConfig)
			task.delay(0.26, function()
				if not ConfigMainFrame.Visible then return end
				local safe = PopupSafeArea()
				local w = ConfigMainFrame.AbsoluteSize.X
				if w > 0 and safe.X > 0 and w > safe.X - 12 then
					ConfigScale.Scale = math.max(0.5, (safe.X - 12) / w)
				end
			end)
			ConfigMainFrame.Visible = true
			ConfigScale.Scale = 0.94
			Tween(ConfigScale, { Scale = 1 }, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			Tween(ConfigMainFrame, { BackgroundTransparency = 0.045 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local cfgSettled = ConfigMainFrame.Position
			ConfigMainFrame.Position = UDim2.new(cfgSettled.X.Scale, cfgSettled.X.Offset, cfgSettled.Y.Scale, cfgSettled.Y.Offset - 5)
			Tween(ConfigMainFrame, { Position = cfgSettled }, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		Tween(SaveArrow, { Rotation = 180 }, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		else
			closeConfigPanel()
		end
	end)

	local SearchBox = New("TextBox", {
		Name = "SearchBox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -46, 0.5, 0),
		Size = UDim2.fromOffset(0, 28),
		BackgroundColor3 = Color3.fromRGB(15, 17, 26),
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = Color3.fromRGB(130, 134, 152),
		TextColor3 = Color3.fromRGB(228, 230, 238),
		TextScaled = false,
		TextSize = 13,
		Font = FONT,
		TextTransparency = 0.05,
		Visible = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		ZIndex = 4,
	}, Header)
	New("UICorner", { CornerRadius = UDim.new(0, 8) }, SearchBox)
	Stroke(SearchBox)
	New("ImageLabel", {
		Name = "SearchGlyph",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031154871",
		ImageColor3 = Color3.fromRGB(130, 134, 152),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
	}, SearchBox)
	New("UIPadding", { PaddingLeft = UDim.new(0, 40) }, SearchBox)

	local ApplySearch

	local searchOpen = false
	local searchTransitionToken = 0
	SearchBtn.MouseButton1Click:Connect(function()
		searchOpen = not searchOpen
		searchTransitionToken = searchTransitionToken + 1
		local token = searchTransitionToken
		if searchOpen then
			SearchBox.Visible = true
			SearchBox.BackgroundTransparency = 1
			SearchBox.Size = UDim2.fromOffset(0, 28)
			Tween(SearchBox, { BackgroundTransparency = 0 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			Tween(SearchBox, { Size = UDim2.fromOffset(190, 28) }, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			task.delay(0.16, function()
				if searchOpen and searchTransitionToken == token and SearchBox.Visible then pcall(function() SearchBox:CaptureFocus() end) end
			end)
		else
			pcall(function() SearchBox:ReleaseFocus() end)
			Tween(SearchBox, { Size = UDim2.fromOffset(0, 28), BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.13, function()
				if searchOpen or searchTransitionToken ~= token then return end
				SearchBox.Visible = false
				SearchBox.Text = ""
				if ApplySearch then ApplySearch("") end
			end)
		end
	end)

	local TabHose = New("Frame", {
		Name = "TabHose",
		Position = UDim2.new(0, 11, 0, 61),
		Size = UDim2.new(1, -22, 1, -71),
		BackgroundColor3 = Color3.fromRGB(162, 162, 161),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, Frame2)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		-- Responsive gutter: more breathing room on wide menus without overflowing
		-- the columns when the menu is scaled down.
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, TabHose)

	local SubTabHose = New("Frame", {
		Name = "SubTabHose",
		Position = UDim2.new(0, 11, 0, 61),
		Size = UDim2.new(1, -22, 1, -71),
		BackgroundColor3 = Color3.fromRGB(162, 162, 161),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, Frame2)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, SubTabHose)

	New("TextLabel", {
		Name = "SearchEmptyState",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.54, 0),
		Size = UDim2.new(0.72, 0, 0, 44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "NO MATCHING SETTINGS",
		TextColor3 = Color3.fromRGB(126, 133, 154),
		TextSize = 12,
		Font = FONT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Visible = false,
		Active = false,
		ZIndex = 5,
	}, Frame2)

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

	local function SearchMatches(haystack, query)
		haystack = string.lower(tostring(haystack or ""))
		query = string.lower(tostring(query or "")):gsub("^%s+", ""):gsub("%s+$", "")
		if query == "" then return true end
		for word in query:gmatch("%S+") do
			if not haystack:find(word, 1, true) then return false end
		end
		return true
	end

	local function ColumnHasSearchMatch(column, query)
		if not column or query == "" then return query == "" end
		for _, section in ipairs(column:GetChildren()) do
			if section:IsA("Frame") and section.Name == "Section" then
				local elementsFrame = section:FindFirstChild("Elements")
				local sectionLabel = section:FindFirstChild("SectionLabel", true) or section:FindFirstChild("SectionTitle", true)
				if sectionLabel and SearchMatches(GetSearchText(sectionLabel), query) then return true end
				if elementsFrame then
					for _, element in ipairs(elementsFrame:GetChildren()) do
						if element:IsA("GuiObject") then
							local baseVisible = element:GetAttribute("NLSearchBaseVisible")
							if baseVisible == nil then baseVisible = element.Visible end
							if baseVisible and SearchMatches(GetSearchText(element), query) then return true end
						end
					end
				end
			end
		end
		return false
	end

	local function FindSearchTarget(query)
		if query == "" then return nil, nil, false end
		-- Prefer content in the actually active tab/subtab. Base-tab columns can
		-- remain in the tree while a subtab is selected; considering them first
		-- produced incorrect search hints for hidden content.
		for _, holder in ipairs({ TabHose, SubTabHose }) do
			for _, column in ipairs(holder:GetChildren()) do
				if column:IsA("ScrollingFrame")
					and column:GetAttribute("TabIndex") == activeTabIndex
					and IsSearchColumnActive(column)
					and ColumnHasSearchMatch(column, query) then
					return activeTabIndex, holder == SubTabHose and column:GetAttribute("SubTabIndex") or nil, false
				end
			end
		end
		-- Then search settings in other tabs and subtabs.
		for _, holder in ipairs({ TabHose, SubTabHose }) do
			for _, column in ipairs(holder:GetChildren()) do
				if column:IsA("ScrollingFrame") and ColumnHasSearchMatch(column, query) then
					return column:GetAttribute("TabIndex"), holder == SubTabHose and column:GetAttribute("SubTabIndex") or nil, false
				end
			end
		end
		-- Finally allow navigation labels (tab/subtab names) to be searched as well.
		for _, tab in ipairs(tabs) do
			if SearchMatches(tab.name, query) then return tab.tabIndex, nil, true end
			for _, subtab in ipairs(tab.subTabs or {}) do
				if SearchMatches(subtab.name, query) then return tab.tabIndex, subtab.index, true end
			end
		end
		return nil, nil, false
	end

	local function _applySearchImpl(query)
		query = string.lower(tostring(query or "")):gsub("^%s+", ""):gsub("%s+$", "")
		local targetTab, targetSubTab, navOnly
		if query ~= "" then
			targetTab, targetSubTab, navOnly = FindSearchTarget(query)
			-- Don't switch pages while the user is still typing. Matching pages and
			-- subtabs are exposed in navigation; the user chooses when to jump.
			if navOnly and targetTab == activeTabIndex then query = "" end
		end
		local columnHasMatch = false
		for _, holder in ipairs({ TabHose, SubTabHose }) do
		for _, column in ipairs(holder:GetChildren()) do
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
							local sectionBaseVisible = section:GetAttribute("NLSearchBaseVisible")
							if sectionBaseVisible == nil then
								sectionBaseVisible = section.Visible
								section:SetAttribute("NLSearchBaseVisible", sectionBaseVisible)
							end
							local sectionMatch = query == "" or SearchMatches(sectionText, query)
							local anyVisible = false
							if elementsFrame then
								local elementsBaseVisible = elementsFrame:GetAttribute("NLSearchBaseVisible")
								if elementsBaseVisible == nil then
									elementsBaseVisible = elementsFrame.Visible
									elementsFrame:SetAttribute("NLSearchBaseVisible", elementsBaseVisible)
								end
								for _, element in ipairs(elementsFrame:GetChildren()) do
									if element:IsA("GuiObject") then
										local baseVisible = element:GetAttribute("NLSearchBaseVisible")
										if baseVisible == nil then
											baseVisible = element.Visible
											element:SetAttribute("NLSearchBaseVisible", baseVisible)
										end
										local elementText = GetSearchText(element)
										local matches = baseVisible and (query == "" or sectionMatch or SearchMatches(elementText, query))
										element.Visible = matches
										if matches then anyVisible = true end
									end
								end
								elementsFrame.Visible = elementsBaseVisible and anyVisible
							end
							if sectionLabel then
								local labelBaseVisible = sectionLabel:GetAttribute("NLSearchBaseVisible")
								if labelBaseVisible == nil then
									labelBaseVisible = sectionLabel.Visible
									sectionLabel:SetAttribute("NLSearchBaseVisible", labelBaseVisible)
								end
								sectionLabel.Visible = labelBaseVisible and anyVisible
							end
							section.Visible = sectionBaseVisible and anyVisible
							if anyVisible then columnMatch = true end
						end
					end
					column.Visible = columnMatch
					if columnMatch and query ~= "" then columnHasMatch = true end
				end
			end
		end
		end
		for _, row in ipairs(Tab:GetChildren()) do
			if row.Name == "TabButton" then
				local label = row:FindFirstChild("TabText")
				local matches = query == "" or (label and SearchMatches(label.Text, query)) or false
				if not matches and query ~= "" then
					local rowTabIndex = row:GetAttribute("TabIndex")
					for _, holder in ipairs({ TabHose, SubTabHose }) do
						for _, column in ipairs(holder:GetChildren()) do
							if column:IsA("ScrollingFrame") and column:GetAttribute("TabIndex") == rowTabIndex and ColumnHasSearchMatch(column, query) then
								matches = true; break
							end
						end
						if matches then break end
					end
				end
				row.Visible = matches
				local searchIndicator = row:FindFirstChild("SelectedIndicator")
				if searchIndicator and row:GetAttribute("TabIndex") ~= activeTabIndex then
					local matchedRail = query ~= "" and matches
					Tween(searchIndicator, { BackgroundTransparency = matchedRail and 0.42 or 1 }, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end
			elseif row.Name == "SubTabContainer" then
				if row:GetAttribute("TabIndex") ~= activeTabIndex then
					row.Visible = false
				else
					local anyVisible = false
					for _, child in ipairs(row:GetChildren()) do
						if child:IsA("Frame") and string.sub(child.Name, 1, 6) == "STRow" then
							local label = child:FindFirstChild("STLabel")
							local matches = query == "" or (label and SearchMatches(label.Text, query)) or false
							if not matches and query ~= "" then
								local rowTabIndex = child:GetAttribute("TabIndex")
								local rowSubTabIndex = child:GetAttribute("SubTabIndex")
								for _, column in ipairs(SubTabHose:GetChildren()) do
									if column:IsA("ScrollingFrame") and column:GetAttribute("TabIndex") == rowTabIndex and column:GetAttribute("SubTabIndex") == rowSubTabIndex and ColumnHasSearchMatch(column, query) then
										matches = true; break
									end
								end
							end
							child.Visible = matches
							local subtabIndex = child:GetAttribute("SubTabIndex")
							local selectedSubtab = row:GetAttribute("TabIndex") == activeTabIndex and tabs[activeTabIndex] and tabs[activeTabIndex].activeSubTabIndex == subtabIndex
							local searchIndicator = child:FindFirstChild("SelectedIndicator")
							if searchIndicator and not selectedSubtab then
								local matchedRail = query ~= "" and matches
								Tween(searchIndicator, { BackgroundTransparency = matchedRail and 0.42 or 1 }, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
							end
							if matches then anyVisible = true end
						end
					end
					row.Visible = query == "" or anyVisible
				end
			end
		end

		local emptyState = Frame2:FindFirstChild("SearchEmptyState")
		if emptyState and emptyState:IsA("TextLabel") then
			if query == "" or columnHasMatch then
				emptyState.Visible = false
			else
				if targetTab and tabs[targetTab] then
					if targetSubTab and tabs[targetTab].subTabs and tabs[targetTab].subTabs[targetSubTab] then
						emptyState.Text = "MATCH IN " .. string.upper(tostring(tabs[targetTab].name)) .. " / " .. string.upper(tostring(tabs[targetTab].subTabs[targetSubTab].name)) .. "\nSELECT THE HIGHLIGHTED TAB"
					else
						emptyState.Text = "MATCH IN " .. string.upper(tostring(tabs[targetTab].name)) .. "\nSELECT THE HIGHLIGHTED TAB"
					end
				else
					emptyState.Text = "NO MATCHING SETTINGS"
				end
				emptyState.Visible = true
			end
		end

		return columnHasMatch
	end

	ApplySearch = _applySearchImpl
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		-- Re-filter after a short pause so a whole word is searched, not every key.
		SearchBox:SetAttribute("SearchApplyToken", (SearchBox:GetAttribute("SearchApplyToken") or 0) + 1)
		local token = SearchBox:GetAttribute("SearchApplyToken")
		task.delay(0.075, function()
			if SearchBox.Parent and SearchBox:GetAttribute("SearchApplyToken") == token and ApplySearch then
				ApplySearch(SearchBox.Text)
			end
		end)
	end)

local Line9 = Instance.new('Frame')
Line9.Name = "Line9"
Line9.Position = UDim2.new(0.008, 0, 0, 53)
Line9.Size = UDim2.new(0.222, 0, 0, 1)
Line9.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Line9.BackgroundTransparency = 0.93
Line9.BorderSizePixel = 0
Line9.Parent = MainFrame
	Line9.Visible = false

	MakeDraggable(MainFrame, DragHandle)

	
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "ToggleBtn"
	ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
   ToggleBtn.BackgroundTransparency = 1
   ToggleBtn.Active = true
   ToggleBtn.Draggable = false
	ToggleBtn.Size = UDim2.new(0, 100, 0, 28)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
	ToggleBtn.BorderSizePixel = 1
	ToggleBtn.Text = "Close  [RShift]"
	ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleBtn.TextScaled = false
	ToggleBtn.Font = FONT
	ToggleBtn.ZIndex = 999
	ToggleBtn.Parent = NeverloseCS2
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = ToggleBtn end
	



	local guiOpen = true

	local function AnimateWindow(open)
		local dur = open and 0.2 or 0.16
		local part = AcrylicBlur and AcrylicBlur.Instances and AcrylicBlur.Instances.Part
		local dof = AcrylicBlur and AcrylicBlur.Instances and AcrylicBlur.Instances.DepthOfField
		if open then
			MainFrame.Visible = true
			MainFrame.BackgroundTransparency = 1
			MainFrame.Size = windowAnimSize
			Tween(MainFrame, { BackgroundTransparency = 0.1 }, dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			Tween(MainFrame, { Size = windowTargetSize }, dur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		else
			HideAllPopupsNow(true)
			if ConfigMainFrame then ConfigMainFrame.Visible = false end
			if WindowSettingsFrame then WindowSettingsFrame.Visible = false end
			if Save then Save.Visible = false end
			if RecentlyDeletedPanel then RecentlyDeletedPanel.Visible = false end
			Tween(MainFrame, { BackgroundTransparency = 1 }, dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
			Tween(MainFrame, { Size = windowAnimSize }, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(dur + 0.02, function()
				if guiOpen then return end
				MainFrame.Visible = false
				MainFrame.Size = windowTargetSize
				if part then part.Transparency = 1 end
				if dof then dof.Enabled = false end
			end)
		end
		if part then
			local target = open and (part:GetAttribute("TargetTransparency") or 0.8) or 1
			Tween(part, { Transparency = target }, dur)
		end
		if dof then dof.Enabled = open end
	end

	AcrylicBlur.toggleGui = function()
    guiOpen = not guiOpen
    ToggleBtn.Text = guiOpen and "Close [RShift]" or "Open  [RShift]"
    Tween(ToggleBtn, {
        BackgroundColor3 = guiOpen and Color3.fromRGB(17, 19, 27) or Color3.fromRGB(33,37,53)
    }, 0.1)
    	if guiOpen then
        if Save then Save.Visible = true end
        if AcrylicBlur.Signal then
            pcall(function() AcrylicBlur.Signal:Disconnect() end)
            AcrylicBlur.Signal = nil
        end
        AcrylicBlur.Signal = game:GetService("RunService").RenderStepped:Connect(AcrylicBlur.Update)
    else
        if AcrylicBlur.Signal then
            AcrylicBlur.Signal:Disconnect()
            AcrylicBlur.Signal = nil
        end
    end
    AnimateWindow(guiOpen)
end

	ToggleBtn.MouseButton1Click:Connect(AcrylicBlur.toggleGui)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if menuBind and input.KeyCode == menuBind then
			AcrylicBlur.toggleGui()
		end
	end)

	MainFrame.BackgroundTransparency = 1
	Tween(MainFrame, { BackgroundTransparency = 0.1 }, 0.18)



	function WindowObj:AddTabLabel(text)
		text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		local hasPreviousCategory = false
		for _, child in ipairs(Tab:GetChildren()) do
			if child:IsA("TextLabel") and child.Name == "TabLabel" then
				hasPreviousCategory = true
				break
			end
		end

		-- Use a real spacer instead of vertical UIPadding inside a 22px label.
		-- The old padding consumed almost the whole label height, making
		-- "Aimbot" and "Common" headers appear cramped and visually merge.
		if hasPreviousCategory then
			tabOrder = tabOrder + 1
			New("Frame", {
				Name = "TabCategorySpacer",
				Size = UDim2.new(1, 0, 0, 7),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = tabOrder,
			}, Tab)
		end

		tabOrder = tabOrder + 1
		local lbl = New("TextLabel", {
			Name = "TabLabel",
			Size = UDim2.new(1, 0, 0, 17),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = text:upper(),
			TextColor3 = Color3.fromRGB(112, 116, 138),
			TextScaled = false,
			TextSize = 11,
			Font = FONT,
			TextTransparency = 0.1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = tabOrder,
		}, Tab)
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 11),
		}, lbl)

		return lbl
	end

	function WindowObj:AddTab(name, icon)
		local function TintTabIcon(iconObject, color, transparency, duration, style, direction)
			Tween(iconObject, { ImageColor3 = color, ImageTransparency = transparency }, duration, style, direction)
			local outline = iconObject and iconObject:FindFirstChild("MouseOutline")
			if not outline then return end
			local stroke = outline:FindFirstChild("MouseOutlineStroke")
			if stroke then Tween(stroke, { Color = color, Transparency = transparency }, duration, style, direction) end
			for _, partName in ipairs({ "MouseSplit", "MouseWheel" }) do
				local part = outline:FindFirstChild(partName)
				if part then Tween(part, { BackgroundColor3 = color, BackgroundTransparency = transparency }, duration, style, direction) end
			end
		end
		name = tostring(name or "Tab")
		if icon ~= nil and type(icon) ~= "string" then icon = "" end
		tabOrder = tabOrder + 1
		local tabIndex = #tabs + 1
		local isFirst = tabIndex == 1

		local TabButtonFrame = New("Frame", {
			Name = "TabButton",
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = isFirst and 0.92 or 1,
			LayoutOrder = tabOrder,
		}, Tab)
		TabButtonFrame:SetAttribute("TabIndex", tabIndex)
		New("UICorner", { CornerRadius = UDim.new(0, 8) }, TabButtonFrame)
		local TabScale = New("UIScale", { Scale = 1 }, TabButtonFrame)
		local TabIndicator = New("Frame", {
			Name = "SelectedIndicator",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = mainColor,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, TabButtonFrame)
		New("UICorner", { CornerRadius = UDim.new(1, 0) }, TabIndicator)

		local TabIcon = New("ImageLabel", {
			Name = "TabIcon",
			Position = UDim2.new(0, 17, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Color3.fromRGB(255, 191, 255),
			BackgroundTransparency = 1,
			Image = "",
			ImageColor3 = isFirst and mainColor or Color3.fromRGB(150, 155, 172),
			ImageTransparency = 0,
		}, TabButtonFrame)
		if icon and icon ~= "" then
			GetImageData(icon, TabIcon)
		end
		if type(icon) == "string" and string.lower(icon) == "legit" then
			local MouseOutline = New("Frame", {
				Name = "MouseOutline",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(9, 13),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, TabIcon)
			New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, MouseOutline)
			Stroke(MouseOutline, "MouseOutlineStroke")
			New("Frame", {
				Name = "MouseSplit",
				Position = UDim2.new(0, 0, 0, 4),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = isFirst and mainColor or Color3.fromRGB(150, 155, 172),
				BorderSizePixel = 0,
			}, MouseOutline)
			New("Frame", {
				Name = "MouseWheel",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(0, 1, 0, 4),
				BackgroundColor3 = isFirst and mainColor or Color3.fromRGB(150, 155, 172),
				BorderSizePixel = 0,
			}, MouseOutline)
		end
		table.insert(_coloredElements, { type = "tabicon", ref = TabIcon })
New("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}, TabIcon)

		local TabText = New("TextLabel", {
			Name = "TabText",
			Position = UDim2.new(0, 35, 0, 0),
			Size = UDim2.new(1, -43, 1, 0),
			BackgroundColor3 = Color3.fromRGB(191, 255, 255),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = isFirst and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 172),
			TextScaled = false,
			TextSize = 15,
			Font = FONT,
			TextTransparency = 0,
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
			Size = UDim2.new(0.49, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(162, 162, 162),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
		}, TabHose)
		
		local Right = New("ScrollingFrame", {
			Name = "Right",
			Size = UDim2.new(0.49, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(162, 162, 162),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			ClipsDescendants = true,
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 0,
		}, TabHose)
		Left:SetAttribute("SearchName", name)
		Right:SetAttribute("SearchName", name)
		Left:SetAttribute("TabIndex", tabIndex)
		Right:SetAttribute("TabIndex", tabIndex)
		New("UIPadding", { PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 12) }, Left)
		New("UIPadding", { PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 12) }, Right)
		New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, Left)
		New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, Right)

		if not isFirst then
			Left.Visible = false
			Right.Visible = false
		end

		local			function HideContent()
			Left.Visible = false
			Right.Visible = false
		end

		local function ShowContent()
			Left.Position = UDim2.new(0, 0, 0, 0)
			Right.Position = UDim2.new(0, 0, 0, 0)
			Left.Visible = true
			Right.Visible = true
			AnimateSectionColumn(Left)
			AnimateSectionColumn(Right)
		end

		local function ActivateTab()
			CloseAllPopupsExcept(nil)
			for _, t in ipairs(tabs) do
				Tween(t.btn, {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
				}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				if t.indicator then Tween(t.indicator, { BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
				t.hide()
				if t.btn ~= TabButtonFrame then
					TintTabIcon(t.icon, Color3.fromRGB(150, 155, 172), 0, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					t.txt.TextColor3 = Color3.fromRGB(150, 155, 172)
					Tween(t.txt, { TextTransparency = 0 }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end
			end
			Tween(TabButtonFrame, {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.92,
			}, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			Tween(TabIndicator, { BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TintTabIcon(TabIcon, mainColor, 0, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TabText.TextColor3 = Color3.fromRGB(255, 255, 255)
			Tween(TabText, { TextTransparency = 0 }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TabScale.Scale = 0.985
			Tween(TabScale, { Scale = 1 }, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			activeTabIndex = tabIndex
			ShowContent()
			local tabState = tabs[tabIndex]
			GlobalPreset.Visible = ShouldShowGlobalPreset(name)
			if ApplySearch then task.defer(function() ApplySearch(SearchBox.Text) end) end
		end

		ClickArea.MouseButton1Click:Connect(ActivateTab)

		-- Hover feedback is limited to real navigation items. Transparent hit targets elsewhere stay inert.
		TabButtonFrame.MouseEnter:Connect(function()
			if activeTabIndex == tabIndex then return end
			Tween(TabButtonFrame, { BackgroundTransparency = 0.94 }, 0.11, Enum.EasingStyle.Sine)
			TintTabIcon(TabIcon, mainColor, 0.24, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			Tween(TabText, { TextTransparency = 0.22 }, 0.11, Enum.EasingStyle.Sine)
		end)
		TabButtonFrame.MouseLeave:Connect(function()
			if activeTabIndex == tabIndex then return end
			Tween(TabButtonFrame, { BackgroundTransparency = 1 }, 0.14, Enum.EasingStyle.Sine)
			TintTabIcon(TabIcon, Color3.fromRGB(150, 155, 172), 0, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			Tween(TabText, { TextTransparency = 0 }, 0.14, Enum.EasingStyle.Sine)
		end)

		table.insert(tabs, {
			btn = TabButtonFrame,
			icon = TabIcon,
			indicator = TabIndicator,
			txt = TabText,
			hide = HideContent,
			show = ShowContent,
			tabIndex = tabIndex,
			name = name,
			activeSubTabIndex = nil,
			activate = ActivateTab,
		})

		if isFirst then
			activeTabIndex = 1
			GlobalPreset.Visible = ShouldShowGlobalPreset(name)
		end

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
			New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, Section)

local SectionTitle = Instance.new('Frame')
SectionTitle.Name = "SectionTitle"
SectionTitle.Size = UDim2.new(1, 0, 0, 22)
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
SectionLabel.Text = tostring(title or "Section"):upper()
SectionLabel.TextColor3 = customization.sectionTitleColor or Color3.fromRGB(112, 116, 138)
SectionLabel.TextScaled = false
SectionLabel.TextSize = customization.sectionTitleSize or 11
SectionLabel.Font = FONT
SectionLabel.TextTransparency = customization.sectionTitleTransparency or 0.15
SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
SectionLabel.TextYAlignment = Enum.TextYAlignment.Center
SectionLabel.Parent = SectionTitle
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 13)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = SectionLabel
end
AddTextConstraint(SectionLabel, 10, 14, true)
do
	local limit = SectionLabel:FindFirstChild("ReadableTextConstraint")
	if not limit then
		limit = Instance.new("UITextSizeConstraint")
		limit.Name = "ReadableTextConstraint"
		limit.Parent = SectionLabel
	end
	limit.MinTextSize = 10
	limit.MaxTextSize = 14
end


			local Elements = New("Frame", {
				Name = "Elements",
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(19, 22, 32),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				ClipsDescendants = false,
			}, Section)
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = Elements end
			Elements:SetAttribute("NLGroupOutlineInset", true)
			do local groupStroke = Stroke(Elements, "GroupOutline"); groupStroke:SetAttribute("NLBaseTransparency", 0.92) end
			-- Inset rows slightly from the card edges. This keeps each side of the
			-- rounded outline visible even when a row uses an opaque background.
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 1),
				PaddingRight = UDim.new(0, 1),
				PaddingTop = UDim.new(0, 0),
				PaddingBottom = UDim.new(0, 0),
			}, Elements)
			New("UIListLayout", {
				Padding = UDim.new(0, 0),
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

				local hasLeftControl = elementType == "slider" or elementType == "dropdown" or parentFrame.Name == "Selection"
				local SettingsBtn = New("Frame", {
					Name = "SettingsGear",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = hasLeftControl and UDim2.new(0, 132, 0.5, 0) or UDim2.new(1, -65, 0.5, 0),
					Size = UDim2.fromOffset(20, 20),
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
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
				SettingsHit.MouseLeave:Connect(function() SetDotsTransparency(0.1) end)
				SetDotsTransparency(0.1)

				local SettingsFrame = Instance.new('Frame')
				SettingsFrame.Name = "SettingsFrame"
				SettingsFrame.Position = UDim2.new(0.02, 0, 1, 4)
				SettingsFrame.Size = UDim2.new(0.96, 0, 0, 0)
				SettingsFrame.BackgroundColor3 = THEME.plate
				SettingsFrame.BackgroundTransparency = 0.045
				SettingsFrame.BorderSizePixel = 0
				SettingsFrame.Visible = false
				SettingsFrame.ZIndex = 5000
				SettingsFrame.AutomaticSize = Enum.AutomaticSize.None
				SettingsFrame.ClipsDescendants = false
				local SFScale = New("UIScale", { Scale = 1 }, SettingsFrame)

				SettingsFrame.Parent = parentFrame

				local UICorner = Instance.new('UICorner')
				UICorner.Name = "UICorner"
				UICorner.CornerRadius = UDim.new(0, THEME.radius)
				UICorner.Parent = SettingsFrame

				local UIStroke = Stroke(SettingsFrame, "UIStroke")

				-- PATCH 4: settings plate header + no divider watcher
				local PLATE_HEADER = 30
				New("TextLabel", {
					Name = "PlateTitle",
					Position = UDim2.new(0, 14, 0, 14),
					Size = UDim2.new(1, -28, 0, 16),
					BackgroundTransparency = 1,
					Text = label,
					TextColor3 = THEME.text,
					TextSize = 13,
					Font = FONT,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 5001,
				}, SettingsFrame)

				local SFContainer = Instance.new('ScrollingFrame')
				SFContainer.Name = "Container"
				SFContainer.AnchorPoint = Vector2.new(0, 0)
				SFContainer.Position = UDim2.new(0.04, 0, 0, PLATE_HEADER + 3 / GetMainFrameScale())
				SFContainer.Size = UDim2.new(0.92, 0, 1, -(PLATE_HEADER + 6 / GetMainFrameScale()))
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
				SFLayout.Padding = UDim.new(0, 0)
				SFLayout.SortOrder = Enum.SortOrder.LayoutOrder
				SFLayout.Parent = SFContainer

				SFContainer.DescendantAdded:Connect(function(d)
					if d.Name == "Lines" and d:IsA("GuiObject") then d.Visible = false end
				end)
				for _, d in ipairs(SFContainer:GetDescendants()) do
					if d.Name == "Lines" and d:IsA("GuiObject") then d.Visible = false end
				end

				do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = SFContainer end

				local function UpdateSettingsLayout()
					local scale = GetMainFrameScale()
					SFContainer.Position = UDim2.new(0.04, 0, 0, PLATE_HEADER + 3 / scale)
					SFContainer.Size = UDim2.new(0.92, 0, 1, -(PLATE_HEADER + 6 / scale))
				end

				local function GetSettingsContentHeight()
					local measured = MeasureRowsHeight(SFContainer)
					if measured > 0 then return measured end
					local rowCount = 0
					for _, child in ipairs(SFContainer:GetChildren()) do
						if child:IsA("GuiObject") then rowCount = rowCount + 1 end
					end
					if rowCount <= 0 then return 0 end
					local estimated = EstimateRowsHeight(SFContainer, rowCount, 8.5)
					if estimated > 0 then return estimated end
					return rowCount * 34 * GetMainFrameScale()
				end

				local function getSettingsHeight()
					UpdateSettingsLayout()
					local scale = GetMainFrameScale()
					local contentVisual = GetSettingsContentHeight()
					local desiredVisual = math.max(34 * scale, contentVisual + (14 + PLATE_HEADER) * scale)
					return desiredVisual / scale
				end

				local function placeSettings(height)
					local scale = GetMainFrameScale()
					UpdateSettingsLayout()
					local mainSize = MainFrame.AbsoluteSize
					local mainPosition = MainFrame.AbsolutePosition
					local minHeight = 30
					local width = 240
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

					local panelWidth = width * scale
					local leftX = SettingsBtn.AbsolutePosition.X + SettingsBtn.AbsoluteSize.X + 8 * scale
					leftX = math.clamp(leftX, mainLeft + edge, math.max(mainLeft + edge, mainRight - panelWidth - edge))

					local belowY = parentPosition.Y + parentSize.Y + edge
					local aboveY = parentPosition.Y - visualHeight - edge
					local y
					if belowY + visualHeight <= mainBottom - edge then
						y = belowY
					elseif aboveY >= mainTop + edge then
						y = aboveY
					else
						y = mainTop + edge
					end

					SettingsFrame.Position = UDim2.new(0, (leftX - parentPosition.X) / scale, 0, (y - parentPosition.Y) / scale)
					SettingsFrame.Size = UDim2.fromOffset(width, height)
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
					Tween(SettingsFrame, {Size = UDim2.new(0.96, 0, 0, 0), BackgroundTransparency = 1}, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
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
					RememberPopupClipping(SettingsFrame)
					ForceLiftClipping(SettingsFrame)
					SettingsFrame.BackgroundTransparency = 0.045
					SettingsFrame.Visible = false
					SFScale.Scale = 0.94
					ApplyZIndexLadder(SettingsFrame, NextPopupZ())
					placeSettings(getSettingsHeight())
					SettingsFrame.Visible = true
					RegisterPopup(SettingsFrame, closeSF, SettingsBtn)
					local function settle()
						if not settingsOpen or not SettingsFrame.Parent then return end
						placeSettings(getSettingsHeight())
						Tween(SFScale, {Scale = 1}, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
					}, SettingsFrame_Container)

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
						TextScaled = false,
						Font = FONT,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Toggle)

					local Effect = New("Frame", {
						Name = "Effect",
						Position = UDim2.new(1, -14, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5),
						Size = UDim2.fromOffset(33, 20),
						BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44),
						ZIndex = 1001,
					}, Toggle)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
					Stroke(Effect)

					local Icon = New("Frame", {
						Name = "Icon",
						Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3),
						Size = UDim2.fromOffset(14, 14),
						BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142),
						BackgroundTransparency = 0,
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

					AttachRowHover(Btn.Parent)

					local function Set(val)
						enabled = val == true
						Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44) }, 0.16, Enum.EasingStyle.Sine)
						Tween(Icon, { Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142), BackgroundTransparency = 0 }, 0.16, Enum.EasingStyle.Quad)
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
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
					}, SettingsFrame_Container)
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
						TextScaled = false,
						Font = FONT,
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

					AttachRowHover(Btn.Parent)

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
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
						ZIndex = 1000,
					}, SettingsFrame_Container)
					AttachRowHover(Slider)

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
						TextScaled = false,
						Font = FONT,
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
						TextScaled = false,
						Font = FONT,
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
					SizeSliderChip(Effect, Line, SliderValue)
					Effect.AnchorPoint = Vector2.new(0, 0.5)
					Effect.Position = UDim2.new(0.45, 0, 0.5, 0)
					Effect.Size = UDim2.new(0.55, -14, 0, 22)
					Line.Size = UDim2.new(1, -(SliderValue.Size.X.Offset + 10), 0, 3)
					Line.Position = UDim2.new(0, 0, 0.5, 0)

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
					local Thumb = New("Frame", {
						Name = "Thumb",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(initRatio, 0, 0.5, 0),
						Size = UDim2.fromOffset(14, 14),
						BackgroundColor3 = Color3.fromRGB(248, 250, 255),
						BorderSizePixel = 0,
						ZIndex = Line.ZIndex + 3,
					}, Line)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Thumb)
					Stroke(Thumb)
					Line.MouseEnter:Connect(function()
						Tween(Thumb, { Size = UDim2.fromOffset(16, 16) }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end)
					Line.MouseLeave:Connect(function()
						Tween(Thumb, { Size = UDim2.fromOffset(14, 14) }, 0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end)
					local initialValue = value
					task.defer(function()
						if value ~= initialValue then return end
						InLine.Size = UDim2.fromScale(initRatio, 1)
						Thumb.Position = UDim2.new(initRatio, 0, 0.5, 0)
						Trigger.Position = UDim2.new(initRatio, 0, -1.8000000715255737, 0)
					end)

					local function update(input)
						local pointer = GetInputPosition(input)
						local lineSize = Line.AbsoluteSize.X
						if lineSize <= 0 then return end
						local sizeScale = ClampRatio(pointer.X - Line.AbsolutePosition.X, lineSize)
						local nextValue = Quantize(((max - min) * sizeScale) + min, min, max, GetSliderStep(min, max))
						local changed = nextValue ~= value
						value = nextValue
						local span = max - min
						local snappedRatio = span ~= 0 and math.clamp((value - min) / span, 0, 1) or 0
						InLine.Size = UDim2.fromScale(snappedRatio, 1)
						Trigger.Position = UDim2.new(snappedRatio, 0, -1.8000000715255737, 0)
						Thumb.Position = UDim2.new(snappedRatio, 0, 0.5, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						if changed then InvokeCallback(callback, value) end
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
					local span = max - min
					local ratio = span ~= 0 and math.clamp((value - min) / span, 0, 1) or 0
						Tween(InLine, { Size = UDim2.fromScale(ratio, 1) }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
						Trigger.Position = UDim2.new(ratio, 0, -1.8000000715255737, 0)
						Tween(Thumb, { Position = UDim2.new(ratio, 0, 0.5, 0) }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = settingsElemCount,
						ClipsDescendants = false,
						ZIndex = 1000,
					}, SettingsFrame_Container)
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
						TextScaled = false,
						Font = FONT,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Selection)

					local SelArrow = New("ImageLabel", {
						Name = "TextArrow",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -12, 0.5, 0),
						Size = UDim2.fromOffset(10, 10),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Image = "rbxassetid://10709790948",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						ImageTransparency = 0.10000000149011612,
						ScaleType = Enum.ScaleType.Fit,
						Rotation = 0,
						ZIndex = 1000,
					}, Selection)

					local TextDefault = New("TextLabel", {
						Name = "TextDefault",
						Position = UDim2.new(0.60, 0, 0.25, 0),
						Size = UDim2.new(0.29, 0, 0.6, 0),
						TextTruncate = Enum.TextTruncate.AtEnd,
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = options[1] or "Auto",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = false,
						Font = FONT,
						TextTransparency = 0.5,
						ZIndex = 1001,
						TextXAlignment = Enum.TextXAlignment.Right,
					}, Selection)

					-- ============================================================================
					-- PATCH 4: settings-level dropdown uses THEME.plate
					-- ============================================================================
					local DropPopup = New("Frame", {
						Name = "Dropdown",
						Position = UDim2.new(0.02,0,1,2),
						Size = UDim2.new(0.6899999737739563, 0, 0, 100),
						BackgroundColor3 = THEME.plate,
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 5000,
					}, Selection)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, DropPopup)
						do Stroke(DropPopup) end

					New("TextLabel", {
						Name = "HeaderLabel",
						Position = UDim2.new(0, 10, 0, 5),
						Size = UDim2.new(1, -20, 0, 14),
						BackgroundTransparency = 1,
						Text = tostring(text or ""),
						TextColor3 = Color3.fromRGB(122, 124, 136),
						TextSize = 11,
						Font = FONT,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 5000,
					}, DropPopup)

					local DropContainer = New("ScrollingFrame", {
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						Name = "Container",
						Position = UDim2.new(0, 4, 0, 22),
						Size = UDim2.new(1, -8, 1, -26),
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
					New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, DropContainer)

					local function closeDropdown()
						dropOpen = false
						Tween(SelArrow, {Rotation = 0}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
							Size = UDim2.new(1, 0, 0, 26),
							BackgroundColor3 = Color3.fromRGB(38, 38, 45),
							BackgroundTransparency = 1,
							ZIndex = 5001,
							LayoutOrder = i,
						}, DropContainer)
						New("UICorner", { CornerRadius = UDim.new(0, 4) }, BtnRow)

						New("TextLabel", {
							Name = "Label",
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, -32, 1, 0),
							BackgroundColor3 = Color3.fromRGB(162, 162, 162),
							BackgroundTransparency = 1,
							Text = opt,
							TextColor3 = Color3.fromRGB(215, 217, 225),
							TextScaled = false,
							TextSize = 13,
							Font = FONT,
							TextTruncate = Enum.TextTruncate.AtEnd,
							TextTransparency = 0.05,
							ZIndex = 5002,
							TextXAlignment = Enum.TextXAlignment.Left,
						}, BtnRow)

						local SelBtn = New("TextButton", {
							Name = "Selected",
							AnchorPoint = Vector2.new(1, 0),
							Position = UDim2.new(1, -6, 0, 0),
							Size = UDim2.new(0, 18, 1, 0),
							BackgroundColor3 = Color3.fromRGB(17, 19, 27),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Text = "",
							TextColor3 = Color3.fromRGB(78, 131, 255),
							TextScaled = false,
							TextSize = 15,
							Font = FONT,
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
						RowBtn.MouseEnter:Connect(function()
							Tween(BtnRow, { BackgroundTransparency = 0.35 }, 0.08)
						end)
						RowBtn.MouseLeave:Connect(function()
							Tween(BtnRow, { BackgroundTransparency = 1 }, 0.12)
						end)
						RowBtn.MouseButton1Click:Connect(function()
							selected = opt; TextDefault.Text = opt; ; updateCheckmarks(); closeDropdown()
							InvokeCallback(callback, opt)
						end)
						SelBtn.MouseButton1Click:Connect(function()
							selected = opt; TextDefault.Text = opt; ; updateCheckmarks(); closeDropdown()
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
							local popupW = math.max(Selection.AbsoluteSize.X * 0.96, 1)
							local popupH = math.clamp(26 * #options + 28, 46, 460)
							DropPopup.Size = UDim2.new(0.96, 0, 0, popupH)
							DropPopup.BackgroundTransparency = 0
							DropPopup.Visible = false
							ApplyZIndexLadder(DropPopup, NextPopupZ())
							PositionPopupWithinMain(DropPopup, true, nil, Selection, Vector2.new(popupW, popupH))
							ForceLiftClipping(DropPopup)
							DropPopup.Visible = true
							Tween(SelArrow, {Rotation = 180}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
							RegisterPopup(DropPopup, closeDropdown, OpenBtn)
						end
					end)

					TextDefault.Text = selected; 
					updateCheckmarks()

					local obj = {}
					function obj:Set(val, silent) val = GetValidOption(options, val); selected = val; TextDefault.Text = val; ; updateCheckmarks(); if not silent then InvokeCallback(callback, val) end end
					function obj:Get() return selected end
					RegisterConfigElement("settings_dropdown_", text, obj)
					return obj
				end

				function SettingsObj:AddColorpicker(text, defaultColor, callback)
					settingsElemCount = settingsElemCount + 1
					local initialColor = NormalizeColor(defaultColor)
					local Colorpicker = New("Frame", {
						Name = "Colorpicker",
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						LayoutOrder = settingsElemCount,
						ClipsDescendants = false,
						ZIndex = 1000,
					}, SettingsFrame_Container)
					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.fromOffset(15, 0),
						Size = UDim2.new(0.68, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = text,
						TextColor3 = Color3.fromRGB(226, 228, 236),
						TextScaled = false,
						TextSize = 15,
						Font = FONT,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 1001,
					}, Colorpicker)
					local colorpickerButton = New("ImageButton", {
						Name = "colorpickerButton",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -14, 0.5, 0),
						Size = UDim2.fromOffset(20, 20),
						BackgroundColor3 = initialColor,
						BorderSizePixel = 0,
						Image = "",
						ZIndex = 1010,
					}, Colorpicker)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, colorpickerButton)
					Stroke(colorpickerButton, "ColorpickerButtonStroke")
					local picker = AcrylicBlur.CreateColorPicker(colorpickerButton, initialColor, function(c)
						InvokeCallback(callback, c)
					end)
					local obj = {}
					function obj:Set(c)
						local normalized = NormalizeColor(c)
						picker.Set(normalized)
						InvokeCallback(callback, normalized)
					end
					function obj:Get() return picker.Get() end
					RegisterConfigElement("settings_colorpicker_", text, obj)
					return obj
				end

				MakeReadableText(SettingsFrame, 10, 18)
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
				return BindKeyName(target.key)
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
					if indicator then indicator.Text = key and BindKeyName(key) or "" end
				end
				if RefreshKeybindOverlay then
					task.defer(RefreshKeybindOverlay)
				end
			end

			-- ============================================================================
			-- PATCH 5: hide hidden binds from the snapshot
			-- ============================================================================
			WindowObj._bindSnapshot = function()
				local out = {}
				for key, target in pairs(_keybinds) do
					if target and target.label and key and not target.hideInList then
						table.insert(out, { label = target.label, key = BindKeyName(key) })
					end
				end
				table.sort(out, function(a, b) return a.label:lower() < b.label:lower() end)
				return out
			end

			local function CloseBindMenu()
				UnregisterPopup(_bindMenu)
				if not _bindMenu then return end
				if _bindMenu.Visible then
					Tween(_bindMenu, { BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					TweenShadowLayers(_bindMenu, false, 0.12, Enum.EasingDirection.In)
					task.delay(0.13, function()
						if _bindMenu and _bindMenu.Parent and not _bindTarget then
							_bindMenu.Visible = false
						end
					end)
				end
				_bindTarget = nil
			end

			local BIND_MODES = { "hold", "toggle", "always" }
			local function CurrentBindMode(target)
				return target and target.bindMode or "toggle"
			end

			-- ============================================================================
			-- PATCH 5: BuildBindMenu rewritten (themed, Body container, rows Key/Mode/Visible/Delete)
			-- ============================================================================
			local bindRefs = {}

			local function PaintBindMenu(target)
				bindRefs.key.Text = target.key and BindKeyName(target.key) or "press key"
				local mode = CurrentBindMode(target)
				bindRefs.mode.Text = mode:sub(1, 1):upper() .. mode:sub(2) .. "  ▾"
				local on = not target.hideInList
				Tween(bindRefs.sw, { BackgroundColor3 = on and mainColor or Color3.new(0, 0, 0) }, 0.15)
				Tween(bindRefs.knob, { Position = on and UDim2.fromOffset(16, 2) or UDim2.fromOffset(3, 3) }, 0.15)
			end

			local function BuildBindMenu()
				if _bindMenu then return _bindMenu end
				_bindMenu = New("Frame", {
					Name = "BindPrompt",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.fromOffset(212, 134),
					BackgroundColor3 = THEME.plate,
					BackgroundTransparency = 0.02,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = Z_BASE + 950,
					ClipsDescendants = false,
				}, MainFrame)
				New("UICorner", { CornerRadius = UDim.new(0, THEME.radius) }, _bindMenu)
				Stroke(_bindMenu)
				AttachShadow(_bindMenu, { radius = THEME.radius, layers = 4, step = 1.5, bias = 3 })

				local body = New("Frame", { Name = "Body", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = Z_BASE + 951 }, _bindMenu)
				New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, body)
				New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, body)

				local function makeRow(order, icon, text, color)
					local row = New("TextButton", {
						Name = "Row" .. order, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 30),
						BackgroundColor3 = THEME.row, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = Z_BASE + 952,
					}, body)
					New("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
					New("ImageLabel", {
						Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(15, 15),
						BackgroundTransparency = 1, Image = icon, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit, ZIndex = Z_BASE + 953,
					}, row)
					New("TextLabel", {
						Name = "Label", Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(0.5, -32, 1, 0), BackgroundTransparency = 1,
						Text = text, TextColor3 = color, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = Z_BASE + 953,
					}, row)
					row.MouseEnter:Connect(function() Tween(row, { BackgroundTransparency = 0.35 }, 0.08) end)
					row.MouseLeave:Connect(function() Tween(row, { BackgroundTransparency = 1 }, 0.12) end)
					return row
				end

				local function makeChip(row, width, text, accent)
					local chip = New("TextLabel", {
						Name = "Value", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(width, 20),
						BackgroundColor3 = accent and mainColor or THEME.row, BackgroundTransparency = accent and 0 or 0.1, Text = text, TextColor3 = Color3.fromRGB(255,255,255),
						TextSize = 12, Font = FONT, ZIndex = Z_BASE + 953,
					}, row)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, chip)
					return chip
				end

				local keyRow = makeRow(1, "rbxassetid://121978468376124", "Key", THEME.text)
				bindRefs.key = makeChip(keyRow, 84, "press key")

				local modeRow = makeRow(2, "rbxassetid://109485777305919", "Mode", THEME.text)
				bindRefs.mode = makeChip(modeRow, 84, "Toggle  ▾", true)
				modeRow.MouseButton1Click:Connect(function()
					if not _bindTarget then return end
					local current, index = CurrentBindMode(_bindTarget), 1
					for i, m in ipairs(BIND_MODES) do if m == current then index = i break end end
					_bindTarget.bindMode = BIND_MODES[(index % #BIND_MODES) + 1]
					PaintBindMenu(_bindTarget)
				end)

				local visRow = makeRow(3, "rbxassetid://127234874352422", "Visible", THEME.text)
				bindRefs.sw = New("Frame", {
					Name = "Switch", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(30, 16),
					BackgroundColor3 = mainColor, ZIndex = Z_BASE + 953,
				}, visRow)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, bindRefs.sw)
				bindRefs.knob = New("Frame", {
					Name = "Knob", Position = UDim2.fromOffset(16, 2), Size = UDim2.fromOffset(12, 12),
					BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = Z_BASE + 954,
				}, bindRefs.sw)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, bindRefs.knob)
				visRow.MouseButton1Click:Connect(function()
					if not _bindTarget then return end
					_bindTarget.hideInList = not _bindTarget.hideInList
					PaintBindMenu(_bindTarget)
					if RefreshKeybindOverlay then task.defer(RefreshKeybindOverlay) end
				end)

				local delRow = makeRow(4, "rbxassetid://116396312853810", "Delete", THEME.danger)
				delRow.MouseButton1Click:Connect(function()
					local t = _bindTarget
					if t then SetTargetBind(t, nil) end
					CloseBindMenu()
				end)
				return _bindMenu
			end

			local function OpenBindMenu(target)
				CloseAllPopupsExcept(nil)
				_bindTarget = target
				BuildBindMenu()
				PaintBindMenu(target)
				_bindMenu.Visible = true
				_bindMenu.BackgroundTransparency = 1
				Tween(_bindMenu, { BackgroundTransparency = 0.02 }, 0.15)
				TweenShadowLayers(_bindMenu, true, 0.15)
				local pop = GetPopupScale(_bindMenu)
				if pop then
					pop.Scale = 0.96
					Tween(pop, { Scale = 1 }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				end
				local row = target.row
				MovePopupToAbsolute(_bindMenu,
					row.AbsolutePosition.X + row.AbsoluteSize.X - _bindMenu.AbsoluteSize.X,
					row.AbsolutePosition.Y + row.AbsoluteSize.Y + 4)
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
					Size = UDim2.fromOffset(150, 89),
					BackgroundColor3 = Color3.fromRGB(30, 30, 36),
					BackgroundTransparency = 0.02,
					BorderSizePixel = 0,
					Visible = false,
					ZIndex = 8000,
					ClipsDescendants = false,
				}, MainFrame)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, _contextMenu)
				Stroke(_contextMenu)
				New("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, _contextMenu)
				New("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, _contextMenu)
				AttachShadow(_contextMenu, { radius = 6, layers = 3, step = 1.4, bias = 2 })
				return _contextMenu
			end

			local function AddContextItem(labelText, iconAsset, callback)
				local item = New("TextButton", {
					Name = "MenuItem",
					Size = UDim2.new(1, -8, 0, 26),
					Position = UDim2.new(0, 4, 0, 0),
					BackgroundColor3 = Color3.fromRGB(42, 42, 49),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "  " .. labelText,
					TextColor3 = Color3.fromRGB(232, 234, 240),
					TextScaled = false,
					TextSize = 13,
					Font = FONT,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 8001,
				}, _contextMenu)
				New("UICorner", { CornerRadius = UDim.new(0, 4) }, item)
				New("UIPadding", { PaddingLeft = UDim.new(0, 30) }, item)
				New("ImageLabel", {
					Name = "MenuIcon",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 9, 0.5, 0),
					Size = UDim2.fromOffset(15, 15),
					BackgroundTransparency = 1,
					Image = iconAsset,
					ImageColor3 = Color3.fromRGB(210, 212, 222),
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 8002,
				}, item)
				item.MouseEnter:Connect(function()
					Tween(item, { BackgroundTransparency = 0 }, 0.08)
				end)
				item.MouseLeave:Connect(function()
					Tween(item, { BackgroundTransparency = 1 }, 0.12)
				end)
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
				AddContextItem("Settings", "rbxassetid://109485777305919", function(current)
					if current.obj and current.obj.AddSettings then
						local settings = current.obj:AddSettings()
						if settings and settings.Open then settings:Open() end
					end
				end)
				AddContextItem("Reset", "rbxassetid://106497040962250", function(current)
					if current.obj and current.obj.Set and current.defaultValue ~= nil then
						current.obj:Set(current.defaultValue)
					end
				end)
				AddContextItem("Unbind", "rbxassetid://116396312853810", function(current)
					SetTargetBind(current, nil)
				end)
				_contextMenu.Size = UDim2.fromOffset(150, 89)
				ApplyZIndexLadder(_contextMenu, NextPopupZ())
				SmoothOpen(_contextMenu, 0.02, 0.15)
				local anchorX, anchorY = point.X, point.Y
				if target.dots and target.dots.Parent and target.dots.AbsoluteSize.X > 0 then
					anchorX = target.dots.AbsolutePosition.X + target.dots.AbsoluteSize.X - 150
					anchorY = target.dots.AbsolutePosition.Y + target.dots.AbsoluteSize.Y + 4
				end
				MovePopupToAbsolute(_contextMenu, anchorX, anchorY)
				ConstrainPopupToMainFrame(_contextMenu, 8)
				local settled = _contextMenu.Position
				_contextMenu.Position = UDim2.new(settled.X.Scale, settled.X.Offset, settled.Y.Scale, settled.Y.Offset - 8)
				Tween(_contextMenu, { Position = settled }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local entryIndex = 0
				for _, child in ipairs(_contextMenu:GetChildren()) do
					if child:IsA("TextButton") then
						entryIndex = entryIndex + 1
						child.TextTransparency = 1
						Tween(child, { TextTransparency = 0 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, entryIndex * 0.035)
					end
				end
				_contextOpen = true
				RegisterPopup(_contextMenu, CloseContextMenu, target.dots)
			end

			local function IsEditableTarget()
				local ok, focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
				return not (ok and focused)
			end

			local function RunBoundFunction(target, phase)
				if not target or not target.obj then return end
				local value = target.obj.Get and target.obj:Get()
				if phase == "up" then
					if target.bindMode == "hold" and type(value) == "boolean" then
						target.obj:Set(false)
					end
					return
				end
				if target.bindMode == "hold" and type(value) == "boolean" then
					target.obj:Set(true)
					return
				end
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

			local function IsExtraMouseType(t)
				-- Roblox's standard enum only exposes MouseButton1/2/3.
				-- Read optional executor-provided side-button types by name instead
				-- of indexing unsupported Enum.UserInputType members.
				local name
				local ok = pcall(function() name = t and t.Name end)
				if not ok or type(name) ~= "string" then
					name = tostring(t):match("([^%.]+)$")
				end
				return name == "MouseButton4" or name == "MouseButton5"
			end

			UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if _bindTarget then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						local key = input.KeyCode
						if key ~= Enum.KeyCode.Unknown then SetTargetBind(_bindTarget, key) end
						CloseBindMenu()
						return
					end
					if IsExtraMouseType(input.UserInputType) then
						SetTargetBind(_bindTarget, input.UserInputType)
						CloseBindMenu()
						return
					end
					if input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3 then
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
				if input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3 then
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
				end
			end)

			UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if _bindTarget then return end
				local key = input.KeyCode
				if key == nil or key == Enum.KeyCode.Unknown then
					local t = input.UserInputType
					if not IsExtraMouseType(t) then return end
					key = t
				end
				if not IsEditableTarget() then return end
				local target = _keybinds[key]
				if target and target.bindMode ~= "hold" then
					RunBoundFunction(target, "down")
				end
			end)

			UserInputService.InputChanged:Connect(function(input, gameProcessed)
				-- Roblox exposes the wheel as MouseWheel; direction is input.Position.Z.
				local wheelType = input.UserInputType
				if wheelType ~= Enum.UserInputType.MouseWheel then return end
				local wheelKey = input.Position.Z > 0 and "MouseWheelUp" or "MouseWheelDown"
				if input.Position.Z == 0 then return end
				if _bindTarget then
					-- Keep wheel direction as a string token; Roblox has no enum members for up/down.
					SetTargetBind(_bindTarget, wheelKey)
					CloseBindMenu()
					return
				end
				if gameProcessed or not IsEditableTarget() then return end
				local target = _keybinds[wheelKey]
				if target then RunBoundFunction(target, "down") end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if not IsEditableTarget() then return end
				local key = input.KeyCode
				if key == nil or key == Enum.KeyCode.Unknown then key = input.UserInputType end
				local target = key and _keybinds[key] or nil
				if target and target.bindMode == "hold" then
					RunBoundFunction(target, "up")
				end
			end)


			function SectionObj:AddToggle(text, default, callback)
				elemCount = elemCount + 1
				local enabled = default == true

				local Toggle = New("Frame", {
					Name = "Toggle",
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
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
					TextColor3 = Color3.fromRGB(217, 219, 226),
					TextScaled = false,
					Font = FONT,
					TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Toggle)

				local Effect = New("Frame", {
					Name = "Effect",
					Position = UDim2.new(1, -14, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Size = UDim2.fromOffset(33, 20),
					BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44),
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
				Stroke(Effect)

				local Icon = New("Frame", {
					Name = "Icon",
					Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3),
					Size = UDim2.fromOffset(14, 14),
					BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142),
					BackgroundTransparency = 0,
				}, Effect)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Icon)
				New("UIAspectRatioConstraint", {}, Icon)

				local Btn = New("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 5,
				}, Toggle)

				AttachRowHover(Btn.Parent)

				local function Set(val)
					enabled = val == true
					Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44) }, 0.16, Enum.EasingStyle.Sine)
					Tween(Icon, { Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142), BackgroundTransparency = 0 }, 0.16, Enum.EasingStyle.Quad)
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
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
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
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 15, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
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
					Position = UDim2.fromOffset(34, 0),
					Size = UDim2.new(0.55, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = false,
					Font = FONT,
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
				AttachRowHover(Btn.Parent)

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
				local color = NormalizeColor(defaultColor)
				local Toggle = New("Frame", {
					Name = "Toggle",
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.88, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, Toggle)
				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.fromOffset(15, 0),
					Size = UDim2.new(0.6, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(217, 219, 226),
					TextScaled = false,
					TextSize = 16,
					Font = FONT,
					TextTransparency = 0.1,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 5,
				}, Toggle)
				local Effect = New("Frame", {
					Name = "Effect",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(33, 20),
					BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44),
					ZIndex = 6,
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
				Stroke(Effect, "ToggleStroke")
				local Icon = New("Frame", {
					Name = "Icon",
					Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3),
					Size = UDim2.fromOffset(14, 14),
					BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142),
					BorderSizePixel = 0,
					ZIndex = 7,
				}, Effect)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Icon)
				local cpBtn = New("ImageButton", {
					Name = "colorpickerButton",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -64, 0.5, 0),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
					Image = "",
					ZIndex = 8,
				}, Toggle)
				New("UICorner", { CornerRadius = UDim.new(0, 5) }, cpBtn)
				Stroke(cpBtn, "ColorpickerButtonStroke")
				local Btn = New("TextButton", {
					Name = "ToggleHitArea",
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					ZIndex = 4,
				}, Toggle)

				local function NotifyColor(c)
					color = NormalizeColor(c)
					if colorCallback then
						InvokeCallback(colorCallback, color)
					elseif callback then
						InvokeCallback(callback, color, enabled)
					end
				end
				local function NotifyEnabled()
					if colorCallback then
						if callback then InvokeCallback(callback, enabled) end
					elseif callback then
						InvokeCallback(callback, color, enabled)
					end
				end
				local picker = AcrylicBlur.CreateColorPicker(cpBtn, color, NotifyColor)

				local function SetEnabled(val)
					enabled = val == true
					Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44) }, 0.16, Enum.EasingStyle.Sine)
					Tween(Icon, { Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142), BackgroundTransparency = 0 }, 0.16, Enum.EasingStyle.Quad)
					NotifyEnabled()
				end
				Btn.MouseButton1Click:Connect(function() SetEnabled(not enabled) end)
				AttachRowHover(Toggle)

				local obj = {}
				function obj:Set(val) SetEnabled(val) end
				function obj:Get() return enabled end
				function obj:SetColor(c)
					local normalized = NormalizeColor(c)
					picker.Set(normalized)
					NotifyColor(normalized)
				end
				function obj:GetColor() return color end
				function obj:AddSettings() return MakeSettings(Toggle, nil, text) end
				RegisterConfigElement("togglecolorpicker_", text, obj)
				RegisterConfigElement("togglecolorpicker_color_", text, {
					Get = function() return obj:GetColor() end,
					Set = function(_, c) obj:SetColor(c) end,
				})
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
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
				}, Elements)
				AttachRowHover(Slider)
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
					Position = UDim2.fromOffset(15, 0),
					Size = UDim2.new(0.6600000262260437, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(217, 219, 226),
					TextScaled = false,
					Font = FONT,
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
					BackgroundColor3 = Color3.fromRGB(24, 27, 37),
					Text = FormatSliderValue(value, suffix),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = false,
					Font = FONT,
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
				local Thumb = New("Frame", {
					Name = "Thumb",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(initRatio, 0, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					ZIndex = Line.ZIndex + 3,
				}, Line)
				New("UICorner", { CornerRadius = UDim.new(1, 0) }, Thumb)
				Stroke(Thumb)
				Line.MouseEnter:Connect(function()
					Tween(Thumb, { Size = UDim2.fromOffset(16, 16) }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end)
				Line.MouseLeave:Connect(function()
					Tween(Thumb, { Size = UDim2.fromOffset(14, 14) }, 0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end)
				local initialValue = value
				task.defer(function()
					if value ~= initialValue then return end
					InLine.Size = UDim2.fromScale(initRatio, 1)
					Thumb.Position = UDim2.new(initRatio, 0, 0.5, 0)
					Trigger.Position = UDim2.new(initRatio, 0, -1.8000000715255737, 0)
				end)

					local function update(input)
						local pointer = GetInputPosition(input)
						local lineSize = Line.AbsoluteSize.X
						if lineSize <= 0 then return end
						local sizeScale = ClampRatio(pointer.X - Line.AbsolutePosition.X, lineSize)
						local nextValue = Quantize(((max - min) * sizeScale) + min, min, max, GetSliderStep(min, max))
						local changed = nextValue ~= value
						value = nextValue
						local span = max - min
						local snappedRatio = span ~= 0 and math.clamp((value - min) / span, 0, 1) or 0
						InLine.Size = UDim2.fromScale(snappedRatio, 1)
						Trigger.Position = UDim2.new(snappedRatio, 0, -1.8000000715255737, 0)
						Thumb.Position = UDim2.new(snappedRatio, 0, 0.5, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						if changed then InvokeCallback(callback, value) end
					end

				local Hitbox = New("TextButton", {
					Name = "SliderHitbox",
					Position = UDim2.new(0.03999999910553033, 0, 0, -10),
					Size = UDim2.new(0.6000000238418579, 0, 1, 20),
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 4,
				}, Effect)
				Hitbox.InputBegan:Connect(function(input)
					if IsPrimaryInput(input) then
						dragging = true
						update(input)
					end
				end)

				Line.InputBegan:Connect(function(input)
					if IsPrimaryInput(input) then
						dragging = true
						update(input)
					end
				end)

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
					local span = max - min
					local ratio = span ~= 0 and math.clamp((value - min) / span, 0, 1) or 0
					Tween(InLine, { Size = UDim2.fromScale(ratio, 1) }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					Trigger.Position = UDim2.new(ratio, 0, -1.8000000715255737, 0)
					Tween(Thumb, { Position = UDim2.new(ratio, 0, 0.5, 0) }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
					ClipsDescendants = false,
				}, Elements)
				AttachRowHover(Dropdown)

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
					Position = UDim2.fromOffset(15, 0),
					Size = UDim2.new(0.6000000238418579, 0, 0.5000000238418579, 0),
					BackgroundColor3 = Color3.fromRGB(28,32,48),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(217, 219, 226),
					TextScaled = false,
					Font = FONT,
					TextTransparency = 0.10000000149011612,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Dropdown)

				local TopBar = New("TextButton", {
					Name = "TopBar",
					Position = UDim2.new(1, -14, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Size = UDim2.fromOffset(135, 26),
					BackgroundColor3 = Color3.fromRGB(30, 33, 47),
					BackgroundTransparency = 0,
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = false,
					Font = FONT,
					ZIndex = 6,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, TopBar)
				local TopBarText = New("TextLabel", {
					Name = "TopBarText",
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -36, 1, 0),
					BackgroundTransparency = 1,
					Text = selected or "Select",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = false,
					TextSize = 15,
					Font = FONT,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 7,
				}, TopBar)

				local Arrow = New("ImageLabel", {
					Name = "Arrow",
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(10, 10),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					Image = "rbxassetid://10709790948",
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					ScaleType = Enum.ScaleType.Fit,
					Rotation = 0,
					ZIndex = 7,
				}, TopBar)

				local DownBar = New("Frame", {
					Name = "DownBar",
					Position = UDim2.new(0.02, 0, 1, 4),
					Size = UDim2.new(0.72, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(17, 19, 27),
					BackgroundTransparency = 0,
					Visible = false,
					ZIndex = 5000,
					ClipsDescendants = true,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 10) }, DownBar)
				local PopupStroke = Stroke(DownBar)

				local Scrolls = New("ScrollingFrame", {
					Name = "Scrolls",
					Position = UDim2.fromOffset(6, 6),
					Size = UDim2.new(1, -12, 1, -12),
					ScrollingEnabled = true,
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ClipsDescendants = false,
					ZIndex = 5001,
				}, DownBar)
				New("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, Scrolls)

				local function closeDropdown()
					if not dropOpen and not DownBar.Visible then return end
					dropOpen = false
					Tween(Arrow, { Rotation = 0 }, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					Tween(PopupStroke, { Transparency = 1 }, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
					Tween(DownBar, { Size = UDim2.new(0.72, 0, 0, 0) }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					UnregisterPopup(DownBar)
					local closeToken = (DownBar:GetAttribute("CloseToken") or 0) + 1
					DownBar:SetAttribute("CloseToken", closeToken)
					task.delay(0.16, function()
						if DownBar.Parent and not dropOpen and DownBar:GetAttribute("CloseToken") == closeToken then DownBar.Visible = false end
					end)
					if _openDropdown == closeDropdown then _openDropdown = nil end
				end

				local optionRows = {}
				for _, opt in ipairs(options) do
					local Buttons = New("TextButton", {
						Name = "Buttons",
						Size = UDim2.new(1, -12, 0, 28),
						Position = UDim2.new(0, 6, 0, 0),
						ClipsDescendants = false,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = selected == opt and 0.94 or 1,
						Text = opt,
						TextColor3 = selected == opt and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 204, 218),
						TextScaled = false,
						TextSize = 15,
						Font = FONT,
						TextTransparency = 0,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						AutoButtonColor = false,
						ZIndex = 5002,
					}, Scrolls)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, Buttons)
					New("UIPadding", { PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 8) }, Buttons)
					New("ImageLabel", { Name = "SelectedCheck", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Image = "rbxassetid://138494545053627", ImageColor3 = Color3.fromRGB(255, 255, 255), Visible = selected == opt, ZIndex = 5003 }, Buttons)
					optionRows[opt] = Buttons

					Buttons.MouseEnter:Connect(function()
						Tween(Buttons, { BackgroundTransparency = 0.94 }, 0.09, Enum.EasingStyle.Sine)
					end)
					Buttons.MouseLeave:Connect(function()
						Tween(Buttons, { BackgroundTransparency = selected == opt and 0.94 or 1 }, 0.12, Enum.EasingStyle.Sine)
					end)
					Buttons.MouseButton1Click:Connect(function()
						selected = opt
						TopBarText.Text = opt; 
						for option, row in pairs(optionRows) do
							Tween(row, { BackgroundTransparency = option == selected and 0.94 or 1 }, 0.12, Enum.EasingStyle.Sine)
							local check = row:FindFirstChild("SelectedCheck")
							if check then check.Visible = option == selected end
							row.TextColor3 = option == selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 204, 218)
						end
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
						DownBar:SetAttribute("CloseToken", (DownBar:GetAttribute("CloseToken") or 0) + 1)
						DownBar.Visible = false
						ApplyZIndexLadder(DownBar, NextPopupZ())
						local h = math.min(#options, 8) * 30 + 12
						local popupWidth = math.max(TopBar.AbsoluteSize.X, 150)
						local finalSize = UDim2.fromOffset(popupWidth, h)
						local knownSize = Vector2.new(popupWidth, math.min(h, math.max(MainFrame.AbsoluteSize.Y, 1)))
						DownBar.Size = finalSize
						DownBar.Visible = true
						PositionPopupWithinMain(DownBar, true, 4, TopBar, knownSize)
						DownBar.Size = UDim2.new(0.72, 0, 0, 0)
						PopupStroke.Transparency = 1
						Tween(DownBar, { Size = finalSize }, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						Tween(PopupStroke, { Transparency = 0.5 }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
						Tween(Arrow, { Rotation = 180 }, 0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
						task.delay(0.24, function() if DownBar.Visible then PositionPopupWithinMain(DownBar, true, 4, TopBar) end end)
						RegisterPopup(DownBar, closeDropdown, TopBar)
					end
				end)

				local obj = {}
				function obj:Set(val, silent)
					val = GetValidOption(options, val)
					selected = val
					TopBarText.Text = val
					
					for option, row in pairs(optionRows) do
						Tween(row, { BackgroundTransparency = option == selected and 0.42 or 1 }, 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end
					if not silent then InvokeCallback(callback, val) end
				end
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
				local currentColor = NormalizeColor(defaultColor)
				local dropOpen = false

				local Dropdown = New("Frame", {
					Name = "Dropdown",
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundTransparency = 1,
					LayoutOrder = elemCount,
					ClipsDescendants = false,
				}, Elements)
				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.05, 0, 1, -1),
					Size = UDim2.new(0.9, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, Dropdown)
				New("TextLabel", {
					Name = "TextDropdown",
					Position = UDim2.fromOffset(15, 0),
					Size = UDim2.new(0.6, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(217, 219, 226),
					TextScaled = false,
					TextSize = 16,
					Font = FONT,
					TextTransparency = 0.1,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 5,
				}, Dropdown)

				local cpBtn = New("ImageButton", {
					Name = "colorpickerButton",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -155, 0.5, 0),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = currentColor,
					BorderSizePixel = 0,
					Image = "",
					ZIndex = 8,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 5) }, cpBtn)
				Stroke(cpBtn, "ColorpickerButtonStroke")

				local TopBar = New("TextButton", {
					Name = "TopBar",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(135, 26),
					BackgroundColor3 = Color3.fromRGB(30, 33, 47),
					BackgroundTransparency = 0,
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = false,
					Font = FONT,
					ZIndex = 6,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 6) }, TopBar)
				local TopBarText = New("TextLabel", {
					Name = "TopBarText",
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, -36, 1, 0),
					BackgroundTransparency = 1,
					Text = selected,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = false,
					TextSize = 15,
					Font = FONT,
					TextTransparency = 0,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 7,
				}, TopBar)
				local Arrow = New("ImageLabel", {
					Name = "Arrow",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(10, 10),
					BackgroundTransparency = 1,
					Image = "rbxassetid://10709790948",
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					ImageTransparency = 0,
					ScaleType = Enum.ScaleType.Fit,
					Rotation = 0,
					ZIndex = 8,
				}, TopBar)

				local DownBar = New("Frame", {
					Name = "DownBar",
					Position = UDim2.new(0, 0, 1, 4),
					Size = UDim2.fromOffset(150, 0),
					BackgroundColor3 = Color3.fromRGB(17, 19, 28),
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Visible = false,
					ZIndex = Z_BASE + 500,
				}, Dropdown)
				New("UICorner", { CornerRadius = UDim.new(0, 10) }, DownBar)
				Stroke(DownBar, "DropdownPopupStroke")
				local Scrolls = New("ScrollingFrame", {
					Name = "Scrolls",
					Position = UDim2.fromOffset(6, 6),
					Size = UDim2.new(1, -12, 1, -12),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					ScrollBarThickness = 2,
					Active = true,
					ScrollingEnabled = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ZIndex = Z_BASE + 501,
				}, DownBar)
				New("UIPadding", {
					PaddingLeft = UDim.new(0, 0),
					PaddingRight = UDim.new(0, 0),
					PaddingTop = UDim.new(0, 0),
					PaddingBottom = UDim.new(0, 0),
				}, Scrolls)
				New("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, Scrolls)

				local optionRows = {}
				local function updateSelected()
					TopBarText.Text = selected
					for option, row in pairs(optionRows) do
						local isSelected = option == selected
						row.BackgroundTransparency = isSelected and 0.94 or 1
						row.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 204, 218)
						local check = row:FindFirstChild("SelectedCheck")
						if check then check.Visible = isSelected end
					end
				end
				local function closeDropdown()
					dropOpen = false
					Tween(Arrow, { Rotation = 0 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					Tween(DownBar, { Size = UDim2.fromOffset(150, 0) }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					task.delay(0.15, function() if not dropOpen then DownBar.Visible = false end end)
					UnregisterPopup(DownBar)
					if _openDropdown == closeDropdown then _openDropdown = nil end
				end
				local function CurrentColor() return currentColor end
				local function NotifySelection(value)
					if colorCallback then
						if callback then InvokeCallback(callback, value) end
					elseif callback then
						InvokeCallback(callback, value, CurrentColor())
					end
				end
				local function NotifyColor(c)
					currentColor = NormalizeColor(c)
					if colorCallback then
						InvokeCallback(colorCallback, currentColor)
					elseif callback then
						InvokeCallback(callback, selected, currentColor)
					end
				end

				for _, opt in ipairs(options) do
					local row = New("TextButton", {
						Name = "Option",
						Size = UDim2.new(1, -12, 0, 28),
						Position = UDim2.new(0, 6, 0, 0),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = opt == selected and 0.94 or 1,
						Text = opt,
						TextColor3 = opt == selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 204, 218),
						TextScaled = false,
						TextSize = 15,
						Font = FONT,
						TextTransparency = 0,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = Z_BASE + 502,
					}, Scrolls)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
					New("UIPadding", { PaddingLeft = UDim.new(0, 28), PaddingRight = UDim.new(0, 8) }, row)
					New("ImageLabel", {
						Name = "SelectedCheck",
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(0, 4, 0.5, 0),
						Size = UDim2.fromOffset(14, 14),
						BackgroundTransparency = 1,
						Image = "rbxassetid://138494545053627",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Visible = opt == selected,
						ZIndex = Z_BASE + 503,
					}, row)
					optionRows[opt] = row
					row.MouseEnter:Connect(function() Tween(row, { BackgroundTransparency = 0.94 }, 0.09, Enum.EasingStyle.Sine) end)
					row.MouseLeave:Connect(function() Tween(row, { BackgroundTransparency = opt == selected and 0.94 or 1 }, 0.12, Enum.EasingStyle.Sine) end)
					row.MouseButton1Click:Connect(function()
						selected = opt
						updateSelected()
						NotifySelection(opt)
						closeDropdown()
					end)
				end
				local function openDropdown()
					if dropOpen then closeDropdown(); return end
					CloseAllPopupsExcept(DownBar)
					if _openDropdown then _openDropdown() end
					dropOpen = true
					_openDropdown = closeDropdown
					local popupWidth = math.max(TopBar.AbsoluteSize.X, 150)
					local h = math.min(#options, 8) * 30 + 12
					local finalSize = UDim2.fromOffset(popupWidth, h)
					local knownSize = Vector2.new(popupWidth, math.min(h, math.max(MainFrame.AbsoluteSize.Y, 1)))
					DownBar.Size = finalSize
					DownBar.Visible = true
					ApplyZIndexLadder(DownBar, NextPopupZ())
					PositionPopupWithinMain(DownBar, true, 4, TopBar, knownSize)
					DownBar.Size = UDim2.fromOffset(popupWidth, 0)
					Tween(DownBar, { Size = finalSize }, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					Tween(Arrow, { Rotation = 180 }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					task.delay(0.2, function() if DownBar.Visible then PositionPopupWithinMain(DownBar, true, 4, TopBar) end end)
					RegisterPopup(DownBar, closeDropdown, TopBar)
				end
				TopBar.MouseButton1Click:Connect(openDropdown)

				local picker = AcrylicBlur.CreateColorPicker(cpBtn, currentColor, NotifyColor)
				updateSelected()
				local obj = {}
				function obj:Set(val)
					selected = GetValidOption(options, val)
					updateSelected()
					NotifySelection(selected)
				end
				function obj:Get() return selected end
				function obj:SetColor(c)
					currentColor = NormalizeColor(c)
					picker.Set(currentColor)
					NotifyColor(currentColor)
				end
				function obj:GetColor() return currentColor end
				function obj:AddSettings() return MakeSettings(Dropdown, "dropdown", text) end
				RegisterConfigElement("dropdowncolorpicker_", text, obj)
				RegisterConfigElement("dropdowncolorpicker_color_", text, {
					Get = function() return obj:GetColor() end,
					Set = function(_, c) obj:SetColor(c) end,
				})
				CenterElement(Dropdown)
				BindElementContext(Dropdown, "dropdowncolorpicker", text, obj, selected, options)
				return obj
			end

			function SectionObj:AddColorpicker(text, defaultColor, callback)
				elemCount = elemCount + 1
				local initialColor = NormalizeColor(defaultColor)
				local Colorpicker = New("Frame", {
					Name = "Colorpicker",
					Size = UDim2.new(1, 0, 0, 39),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = elemCount,
					ClipsDescendants = false,
					ZIndex = 2,
				}, Elements)
				New("Frame", {
					Name = "Lines",
					Position = UDim2.new(0.06, 0, 1, -1),
					Size = UDim2.new(0.89, 0, 0, 1),
					BackgroundColor3 = Color3.fromRGB(162, 162, 162),
					BackgroundTransparency = 0.9,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, Colorpicker)
				New("TextLabel", {
					Name = "TextToggle",
					Position = UDim2.fromOffset(15, 0),
					Size = UDim2.new(0.6, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Color3.fromRGB(217, 219, 226),
					TextScaled = false,
					TextSize = 16,
					Font = FONT,
					TextTransparency = 0.1,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 5,
				}, Colorpicker)
				local colorpickerButton = New("ImageButton", {
					Name = "colorpickerButton",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = initialColor,
					BorderSizePixel = 0,
					Image = "",
					ZIndex = 30,
				}, Colorpicker)
				New("UICorner", { CornerRadius = UDim.new(0, 5) }, colorpickerButton)
				Stroke(colorpickerButton, "ColorpickerButtonStroke")
				local picker = AcrylicBlur.CreateColorPicker(colorpickerButton, initialColor, function(c)
					InvokeCallback(callback, c)
				end)
				local obj = {}
				function obj:Set(c)
					local normalized = NormalizeColor(c)
					picker.Set(normalized)
					InvokeCallback(callback, normalized)
				end
				function obj:Get() return picker.Get() end
				function obj:AddSettings() return MakeSettings(Colorpicker, nil, text) end
				RegisterConfigElement("colorpicker_", text, obj)
				CenterElement(Colorpicker)
				BindElementContext(Colorpicker, "colorpicker", text, obj, initialColor)
				return obj
			end

			function SectionObj:AddAccordion(text)
				text = tostring(text or "Accordion")
				elemCount = elemCount + 1

				local DropdownSection = Instance.new('Frame')
				DropdownSection.Name = "Accordion"
				DropdownSection.Size = UDim2.new(1, 0, 0, 0)
				DropdownSection.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
				DropdownSection.BackgroundTransparency = 1
				DropdownSection.LayoutOrder = elemCount
				DropdownSection.Parent = Elements

				local TextArrow = Instance.new('ImageLabel')
				TextArrow.Name = "TextArrow"
				TextArrow.Position = UDim2.new(1, -12, 0.5, 0)
				TextArrow.AnchorPoint = Vector2.new(1, 0.5)
				TextArrow.Size = UDim2.fromOffset(10, 10)
				TextArrow.BackgroundTransparency = 1
				TextArrow.Image = "rbxassetid://10709790948"
				TextArrow.ImageColor3 = Color3.fromRGB(255, 255, 255)
				TextArrow.ImageTransparency = 0.10000000149011612
				TextArrow.ScaleType = Enum.ScaleType.Fit
				TextArrow.Rotation = 0
				TextArrow.Parent = DropdownSection

				local Text = Instance.new('TextLabel')
				Text.Name = "Text"
				Text.Position = UDim2.new(0.04800000041723251, 0, 0.30000001192092896, 0)
				Text.Size = UDim2.new(0.6600000262260437, 0, 0.5000000238418579, 0)
				Text.BackgroundColor3 = Color3.fromRGB(28,32,48)
				Text.BackgroundTransparency = 1
				Text.Text = text
				Text.TextColor3 = Color3.fromRGB(255, 255, 255)
				Text.TextScaled = false
				Text.Font = FONT
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
				Section2Frame.BackgroundColor3 = Color3.fromRGB(17, 19, 27)
				Section2Frame.BackgroundTransparency = 0
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

				local UIStroke = Stroke(Section2Frame, "UIStroke")

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
					Tween(TextArrow, {Rotation = 0}, 0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
						Section2Frame.BackgroundTransparency = 0
						S2Scale.Scale = 0.94
						ApplyZIndexLadder(Section2Frame, NextPopupZ())
						local accordionHeight = getAccordionHeight()
						local accordionKnown = Vector2.new(
							math.max(DropdownSection.AbsoluteSize.X * 0.96, 1),
							math.min(accordionHeight * GetMainFrameScale(), math.max(MainFrame.AbsoluteSize.Y, 1)))
						Section2Frame.Size = UDim2.new(0.96, 0, 0, accordionHeight)
						PositionPopupWithinMain(Section2Frame, true, nil, nil, accordionKnown)
						Tween(TextArrow, {Rotation = 180}, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						RegisterPopup(Section2Frame, closeAccordion, Open)
						local function settle()
							if not accordionOpen or not Section2Frame.Parent then return end
							fitAccordionHeight()
						end
						task.defer(function()
							if not accordionOpen or not Section2Frame.Parent then return end
							fitAccordionHeight()
							Tween(S2Scale, {Scale = 1}, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
					}, Container)

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
						Position = UDim2.fromOffset(15, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(217, 219, 226),
						TextScaled = false,
						Font = FONT,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Toggle)

					local Effect = New("Frame", {
						Name = "Effect",
						Position = UDim2.new(1, -14, 0.5, 0),
						AnchorPoint = Vector2.new(1, 0.5),
						Size = UDim2.fromOffset(33, 20),
						BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44),
						ZIndex = 101,
					}, Toggle)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Effect)
					Stroke(Effect)

					local Icon = New("Frame", {
						Name = "Icon",
						Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3),
						Size = UDim2.fromOffset(14, 14),
						BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142),
						BackgroundTransparency = 0,
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

					AttachRowHover(Btn.Parent)

					local function Set(val)
						enabled = val == true
						Tween(Effect, { BackgroundColor3 = enabled and mainColor or Color3.fromRGB(30, 32, 44) }, 0.16, Enum.EasingStyle.Sine)
						Tween(Icon, { Position = enabled and UDim2.fromOffset(16, 3) or UDim2.fromOffset(3, 3), BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(125, 128, 142), BackgroundTransparency = 0 }, 0.16, Enum.EasingStyle.Quad)
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
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
					}, Container)
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
						TextScaled = false,
						Font = FONT,
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

					AttachRowHover(Btn.Parent)

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

				function AccordionObj:AddDropdown(text2, options, default, callback)
					if type(default) == "function" then
						callback = default
						default = nil
					end
					options = NormalizeOptions(options)
					accordionElemCount = accordionElemCount + 1
					local selected = GetValidOption(options, default)
					local dropOpen = false
					local selectedBtns = {}

					local Selection = New("Frame", {
						Name = "Selection",
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
						ClipsDescendants = false,
						ZIndex = 100,
					}, Container)
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
						TextColor3 = Color3.fromRGB(217, 219, 226),
						TextScaled = false,
						Font = FONT,
						TextTransparency = 0.10000000149011612,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Selection)

					local SelArrow = New("ImageLabel", {
						Name = "TextArrow",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -12, 0.5, 0),
						Size = UDim2.fromOffset(10, 10),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Image = "rbxassetid://10709790948",
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						ImageTransparency = 0.10000000149011612,
						ScaleType = Enum.ScaleType.Fit,
						Rotation = 0,
						ZIndex = 1000,
					}, Selection)

					local TextDefault = New("TextLabel", {
						Name = "TextDefault",
						Position = UDim2.new(0.60, 0, 0.25, 0),
						Size = UDim2.new(0.29, 0, 0.6, 0),
						TextTruncate = Enum.TextTruncate.AtEnd,
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = options[1] or "Auto",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = false,
						Font = FONT,
						TextTransparency = 0.5,
						ZIndex = 101,
						TextXAlignment = Enum.TextXAlignment.Right,
					}, Selection)

					local DropPopup = New("Frame", {
						Name = "Dropdown",
						Position = UDim2.new(0.02,0,1,2),
						Size = UDim2.new(0.6899999737739563, 0, 0, 100),
						BackgroundColor3 = THEME.plate,
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 5000,
					}, Selection)
					New("UICorner", { CornerRadius = UDim.new(0, 6) }, DropPopup)
					do Stroke(DropPopup) end

					New("TextLabel", {
						Name = "HeaderLabel",
						Position = UDim2.new(0, 10, 0, 5),
						Size = UDim2.new(1, -20, 0, 14),
						BackgroundTransparency = 1,
						Text = tostring(text2 or text or ""),
						TextColor3 = Color3.fromRGB(122, 124, 136),
						TextSize = 11,
						Font = FONT,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						ZIndex = 5000,
					}, DropPopup)

					local DropContainer = New("ScrollingFrame", {
						Name = "Container",
						Position = UDim2.new(0, 4, 0, 22),
						Size = UDim2.new(1, -8, 1, -26),
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
					New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, DropContainer)

					local function closeDropdown2()
						dropOpen = false
						Tween(SelArrow, { Rotation = 0 }, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
								Size = UDim2.new(1, 0, 0, 26),
								BackgroundColor3 = Color3.fromRGB(38, 38, 45),
								BackgroundTransparency = 1,
								ZIndex = 1001,
								LayoutOrder = i,
							}, DropContainer)
							New("UICorner", { CornerRadius = UDim.new(0, 4) }, BtnRow)

							local Label = New("TextLabel", {
								Name = "Label",
								Position = UDim2.new(0, 8, 0, 0),
								Size = UDim2.new(1, -32, 1, 0),
								BackgroundColor3 = Color3.fromRGB(162, 162, 162),
								BackgroundTransparency = 1,
								Text = opt,
								TextColor3 = Color3.fromRGB(215, 217, 225),
								TextScaled = false,
								TextSize = 13,
								Font = FONT,
								TextTruncate = Enum.TextTruncate.AtEnd,
								TextTransparency = 0.05,
								ZIndex = 1002,
								TextXAlignment = Enum.TextXAlignment.Left,
							}, BtnRow)

							local SelBtn = New("TextButton", {
								Name = "Selected",
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.new(1, -6, 0, 0),
								Size = UDim2.new(0, 18, 1, 0),
								BackgroundColor3 = Color3.fromRGB(17, 19, 27),
								BackgroundTransparency = 1,
								BorderSizePixel = 0,
								Text = "",
								TextColor3 = Color3.fromRGB(78, 131, 255),
								TextScaled = false,
								TextSize = 15,
								Font = FONT,
								ZIndex = 1004,
							}, BtnRow)
							New("UICorner", { CornerRadius = UDim.new(0, 5) }, SelBtn)

							selectedBtns[opt] = SelBtn

							local RowBtn = New("TextButton", {
								Size = UDim2.new(1, 0, 1, 0),
								BackgroundTransparency = 1,
								Text = "",
								ZIndex = 1005,
							}, BtnRow)
							RowBtn.MouseEnter:Connect(function()
								Tween(BtnRow, { BackgroundTransparency = 0.35 }, 0.08)
							end)
							RowBtn.MouseLeave:Connect(function()
								Tween(BtnRow, { BackgroundTransparency = 1 }, 0.12)
							end)
						RowBtn.MouseButton1Click:Connect(function()
							selected = opt
							TextDefault.Text = opt; 
							updateCheckmarks()
							closeDropdown2()
							InvokeCallback(callback, opt)
						end)
						SelBtn.MouseButton1Click:Connect(function()
							selected = opt
							TextDefault.Text = opt; 
							updateCheckmarks()
							closeDropdown2()
							InvokeCallback(callback, opt)
						end)
					end

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
							local knownH = math.clamp(26 * #options + 28, 46, 460)
							local knownW = math.max(Selection.AbsoluteSize.X * 0.96, 1)
							DropPopup.Size = UDim2.new(0.96, 0, 0, knownH)
							DropPopup.BackgroundTransparency = 0
							DropPopup.Visible = false
							ApplyZIndexLadder(DropPopup, NextPopupZ())
							PositionPopupWithinMain(DropPopup, true, nil, nil, Vector2.new(knownW, knownH))
							ForceLiftClipping(DropPopup)
							DropPopup.Visible = true
							Tween(SelArrow, { Rotation = 180 }, 0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
							RegisterPopup(DropPopup, closeDropdown2, OpenBtn)
						end
					end)

					local obj = {}
					function obj:Set(val, silent)
						val = GetValidOption(options, val)
						selected = val
						TextDefault.Text = val; 
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
						Size = UDim2.new(1, 0, 0, 39),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 1,
						LayoutOrder = accordionElemCount,
						ZIndex = 100,
					}, Container)
					AttachRowHover(Slider)

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
						Position = UDim2.fromOffset(15, 0),
						Size = UDim2.new(0.7600000262260437, 0, 0.6000000238418579, 0),
						BackgroundColor3 = Color3.fromRGB(28,32,48),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(217, 219, 226),
						TextScaled = false,
						Font = FONT,
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
						TextScaled = false,
						Font = FONT,
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
					SizeSliderChip(Effect, Line, SliderValue)

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
					local Thumb = New("Frame", {
						Name = "Thumb",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(initRatio, 0, 0.5, 0),
						Size = UDim2.fromOffset(14, 14),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						ZIndex = Line.ZIndex + 3,
					}, Line)
					New("UICorner", { CornerRadius = UDim.new(1, 0) }, Thumb)
					Stroke(Thumb)
					Line.MouseEnter:Connect(function()
						Tween(Thumb, { Size = UDim2.fromOffset(16, 16) }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end)
					Line.MouseLeave:Connect(function()
						Tween(Thumb, { Size = UDim2.fromOffset(14, 14) }, 0.13, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end)
					local initialValue = value
					task.defer(function()
						if value ~= initialValue then return end
						InLine.Size = UDim2.fromScale(initRatio, 1)
						Thumb.Position = UDim2.new(initRatio, 0, 0.5, 0)
						Trigger.Position = UDim2.new(initRatio, 0, -1.8000000715255737, 0)
					end)

					local function update(input)
						local pointer = GetInputPosition(input)
						local lineSize = Line.AbsoluteSize.X
						if lineSize <= 0 then return end
						local sizeScale = ClampRatio(pointer.X - Line.AbsolutePosition.X, lineSize)
						local nextValue = Quantize(((max - min) * sizeScale) + min, min, max, GetSliderStep(min, max))
						local changed = nextValue ~= value
						value = nextValue
						local span = max - min
						local snappedRatio = span ~= 0 and math.clamp((value - min) / span, 0, 1) or 0
						InLine.Size = UDim2.fromScale(snappedRatio, 1)
						Trigger.Position = UDim2.new(snappedRatio, 0, -1.8000000715255737, 0)
						Thumb.Position = UDim2.new(snappedRatio, 0, 0.5, 0)
						SliderValue.Text = FormatSliderValue(value, suffix)
						if changed then InvokeCallback(callback, value) end
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
					local span = max - min
					local ratio = span ~= 0 and math.clamp((value - min) / span, 0, 1) or 0
						Tween(InLine, { Size = UDim2.fromScale(ratio, 1) }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
						Trigger.Position = UDim2.new(ratio, 0, -1.8000000715255737, 0)
						Tween(Thumb, { Position = UDim2.new(ratio, 0, 0.5, 0) }, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
					local initialColor = NormalizeColor(defaultColor)
					local Colorpicker = New("Frame", {
						Name = "Colorpicker",
						Size = UDim2.new(1, 0, 0, 34),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						LayoutOrder = accordionElemCount,
						ClipsDescendants = false,
						ZIndex = 100,
					}, Container)
					New("Frame", {
						Name = "Lines",
						Position = UDim2.new(0.06, 0, 1, -1),
						Size = UDim2.new(0.89, 0, 0, 1),
						BackgroundColor3 = Color3.fromRGB(162, 162, 162),
						BackgroundTransparency = 0.9,
						BorderSizePixel = 0,
						ZIndex = 101,
					}, Colorpicker)
					New("TextLabel", {
						Name = "TextToggle",
						Position = UDim2.fromOffset(15, 0),
						Size = UDim2.new(0.66, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = text2,
						TextColor3 = Color3.fromRGB(217, 219, 226),
						TextScaled = false,
						TextSize = 15,
						Font = FONT,
						TextTransparency = 0.1,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 101,
					}, Colorpicker)
					local colorpickerButton = New("ImageButton", {
						Name = "colorpickerButton",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -14, 0.5, 0),
						Size = UDim2.fromOffset(20, 20),
						BackgroundColor3 = initialColor,
						BorderSizePixel = 0,
						Image = "",
						ZIndex = 110,
					}, Colorpicker)
					New("UICorner", { CornerRadius = UDim.new(0, 5) }, colorpickerButton)
					Stroke(colorpickerButton, "ColorpickerButtonStroke")
					local picker = AcrylicBlur.CreateColorPicker(colorpickerButton, initialColor, function(c)
						InvokeCallback(callback, c)
					end)
					local obj = {}
					function obj:Set(c)
						local normalized = NormalizeColor(c)
						picker.Set(normalized)
						InvokeCallback(callback, normalized)
					end
					function obj:Get() return picker.Get() end
					function obj:AddSettings() return MakeSettings(Colorpicker, nil, text2) end
					RegisterConfigElement("accordion_colorpicker_", text2, obj)
					CenterElement(Colorpicker)
					BindElementContext(Colorpicker, "accordion_colorpicker", text2, obj, initialColor)
					return obj
				end

				MakeReadableText(Section2Frame, 10, 18)
				return AccordionObj
			end

			MakeReadableText(Section, 10, 18)
			return SectionObj
		end

		local subTabs = {}
		local activeSubTabIndex = nil
		local subTabContainer = nil
		tabs[tabIndex].subTabs = subTabs

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
				Left.Visible = false
				Right.Visible = false
				subTabContainer.Visible = true
				-- Do not fade the parent tab back to its inactive state here.
				-- ActivateTab() has just selected it; running the opposite tweens
				-- in the same frame caused a visible flash on every tab switch.
				if activeTabIndex == tabIndex then
					Tween(TabButtonFrame, {
						BackgroundColor3 = Color3.fromRGB(39, 43, 54),
						BackgroundTransparency = 0.22,
					}, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					Tween(TabIcon, { ImageColor3 = mainColor, ImageTransparency = 0 }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					Tween(TabText, { TextTransparency = 0 }, 0.11, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end
				for i, st in ipairs(subTabs) do
					if st.scale then
						local delay = math.min((i - 1) * 0.04, 0.3)
						task.delay(delay, function()
							if not subTabContainer.Visible then return end
							st.scale.Scale = 0.985
							Tween(st.scale, { Scale = 1 }, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
					AnimateSectionColumn(st.left)
					AnimateSectionColumn(st.right)
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

			local stLeft = New("ScrollingFrame", {
				Name = "STLeft_" .. name,
				Size = UDim2.new(0.49, 0, 1, 0),
				BackgroundTransparency = 1,
				Visible = false,
				ClipsDescendants = true,
				Active = true,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 0,
			}, SubTabHose)
			New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, stLeft)

			local stRight = New("ScrollingFrame", {
				Name = "STRight_" .. name,
				Size = UDim2.new(0.49, 0, 1, 0),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Visible = false,
				ClipsDescendants = true,
				Active = true,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 0,
			}, SubTabHose)
			stLeft:SetAttribute("SearchName", name)
			stRight:SetAttribute("SearchName", name)
			stLeft:SetAttribute("TabIndex", tabIndex)
			stRight:SetAttribute("TabIndex", tabIndex)
			stLeft:SetAttribute("SubTabIndex", stIndex)
			stRight:SetAttribute("SubTabIndex", stIndex)
			New("UIPadding", { PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 12) }, stLeft)
			New("UIPadding", { PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 12) }, stRight)
			New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, stRight)

			local STRow = New("Frame", {
				Name = "STRow_" .. name,
				Size = UDim2.new(0.92, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = isFirstST and 0.9 or 1,
				LayoutOrder = stIndex,
			}, subTabContainer)
			STRow:SetAttribute("TabIndex", tabIndex)
			STRow:SetAttribute("SubTabIndex", stIndex)
			New("UICorner", { CornerRadius = UDim.new(0, 5) }, STRow)
			New("UIAspectRatioConstraint", {
				AspectRatio = 4.6,
				AspectType = Enum.AspectType.ScaleWithParentSize,
			}, STRow)
			local STScale = New("UIScale", { Scale = 1 }, STRow)
			local STIndicator = New("Frame", {
				Name = "SelectedIndicator",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(0, 2, 0.58, 0),
				BackgroundColor3 = mainColor,
				BackgroundTransparency = isFirstST and 0 or 1,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, STRow)
			New("UICorner", { CornerRadius = UDim.new(1, 0) }, STIndicator)

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
				TextScaled = false,
				Font = FONT,
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
					Tween(st.row, {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
					}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					if st.indicator then Tween(st.indicator, { BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
					if st.row ~= STRow then
						Tween(st.lbl, { TextTransparency = 0.55 }, 0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end
					if st.icon then
						Tween(st.icon, { ImageColor3 = Color3.fromRGB(200, 200, 210), ImageTransparency = 0.6 }, 0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
					end
					st.left.Visible  = false
					st.right.Visible = false
				end
				Tween(STRow, {
					BackgroundColor3 = Color3.fromRGB(39, 43, 54),
					BackgroundTransparency = 0.22,
				}, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				Tween(STIndicator, { BackgroundTransparency = 0 }, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				Tween(STLabel, { TextTransparency = 0 }, 0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				if iconRef then
					Tween(iconRef, { ImageColor3 = mainColor, ImageTransparency = 0 }, 0.10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				end
				STScale.Scale = 0.985
				Tween(STScale, { Scale = 1 }, 0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				for otherIndex, other in ipairs(subTabs) do
					local rank = otherIndex == stIndex and 0 or 100 + otherIndex
					other.left.LayoutOrder  = rank
					other.right.LayoutOrder = rank
				end
				stLeft.Visible  = true
				stRight.Visible = true
				AnimateSectionColumn(stLeft)
				AnimateSectionColumn(stRight)

				activeSubTabIndex = stIndex
				if tabs[tabIndex] then
					tabs[tabIndex].activeSubTabIndex = stIndex
					tabs[tabIndex].activeSubTabName = name
				end
				GlobalPreset.Visible = ShouldShowGlobalPreset(tabs[tabIndex] and tabs[tabIndex].name or "")
				if ApplySearch then task.defer(function() ApplySearch(SearchBox.Text) end) end
			end

			table.insert(subTabs, {
				row  = STRow,
				lbl  = STLabel,
				indicator = STIndicator,
				icon = iconRef,
				scale = STScale,
				left = stLeft,
				right = stRight,
				activate = ActivateSubTab,
				index = stIndex,
				name = name,
			})

			STClick.MouseButton1Click:Connect(ActivateSubTab)
			STRow.MouseEnter:Connect(function()
				if activeSubTabIndex == stIndex then return end
				Tween(STRow, { BackgroundTransparency = 0.94 }, 0.11, Enum.EasingStyle.Sine)
				Tween(STLabel, { TextTransparency = 0.22 }, 0.11, Enum.EasingStyle.Sine)
				if iconRef then Tween(iconRef, { ImageColor3 = mainColor, ImageTransparency = 0.24 }, 0.11, Enum.EasingStyle.Sine) end
			end)
			STRow.MouseLeave:Connect(function()
				if activeSubTabIndex == stIndex then return end
				Tween(STRow, { BackgroundTransparency = 1 }, 0.14, Enum.EasingStyle.Sine)
				Tween(STLabel, { TextTransparency = 0.55 }, 0.14, Enum.EasingStyle.Sine)
				if iconRef then Tween(iconRef, { ImageColor3 = Color3.fromRGB(200, 200, 210), ImageTransparency = 0.6 }, 0.14, Enum.EasingStyle.Sine) end
			end)

			if isFirstST and activeTabIndex == tabIndex then
				Left.Visible = false
				Right.Visible = false
				subTabContainer.Visible = true
				ActivateSubTab()
			elseif not isFirstST then
				STRow.BackgroundTransparency = 1
				STLabel.TextTransparency = 0.55
				STScale.Scale = 0.985
				if iconRef then iconRef.ImageTransparency = 0.6 end
				task.defer(function()
					if not STRow.Parent then return end
					Tween(STScale, { Scale = 1 }, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				end)
			end

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



	WindowObj._applyCustomization = function()
		-- A delayed customization call must not traverse a destroyed GUI tree.
		if not MainFrame or not MainFrame.Parent then return end
		local function eachText(root, fn)
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then fn(d) end
			end
		end
		eachText(MainFrame, function(t)
			t.Font = FONT
			t.TextScaled = false
			if t.Name ~= "GameTitle" and t.Name ~= "TabLabel" and t.Name ~= "SectionLabel"
				and t.Name ~= "Daysleft" and t.Name ~= "HeaderLabel" and t.Name ~= "SearchEmptyState"
				and t.Name ~= "TabText" and t.Name ~= "Watermark" then t.TextColor3 = customization.textColor end
		end)
		for _, d in ipairs(MainFrame:GetDescendants()) do
			if d:IsA("TextLabel") and d.Name == "SectionLabel" then
				d.TextScaled = false
				d.TextSize = customization.sectionTitleSize or 11
				d.TextColor3 = customization.sectionTitleColor or Color3.fromRGB(150, 158, 190)
				d.TextTransparency = customization.sectionTitleTransparency or 0
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
		WindowObj._applyCustomization()
		return customization
	end

	function WindowObj:GetCustomization()
		return customization
	end

	-- Keep this collection on WindowObj rather than allocating another AddWindow local.
	-- AddWindow is deliberately large and Luau enforces a 200-local-register limit.
	WindowObj._customMenus = {}

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
			for i = #WindowObj._customMenus, 1, -1 do
				if WindowObj._customMenus[i] == self then table.remove(WindowObj._customMenus, i) end
			end
		end

		if type(builder) == "function" then
			local ok, err = pcall(builder, panel, api)
			if not ok then warn("[scr] AddCustomMenu(" .. name .. ") builder error: " .. tostring(err)) end
		end
		table.insert(WindowObj._customMenus, api)
		return api
	end

	WindowObj.AddCustomPanel = WindowObj.AddCustomMenu

	function WindowObj:GetCustomMenus()
		return WindowObj._customMenus
	end

	MakeReadableText(NeverloseCS2, 9, 16)
	CleanBorders(MainFrame)

	task.defer(function()
		local preloadAssets = {
			"rbxassetid://97828544806816", "rbxassetid://122894934359450",
			"rbxassetid://126010725826757", "rbxassetid://101123124881873",
			"rbxassetid://109698732019071", "rbxassetid://95127553964880",
			"rbxassetid://109485777305919", "rbxassetid://106497040962250",
			"rbxassetid://116396312853810", "rbxassetid://121978468376124",
			"rbxassetid://127234874352422", "rbxassetid://104941258142372",
			"rbxassetid://82464660673318", "rbxassetid://136533241128438",
			"rbxassetid://114499998778667", "rbxassetid://6031154871",
			hubImage ~= "" and hubImage or "rbxthumb://type=Asset&id=118608145176297&w=420&h=420",
			"rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId or 0) .. "&w=150&h=150",
		}
		local preloader = New("Frame", {
			Name = "TexturePreloader",
			Position = UDim2.new(0, -50, 0, -50),
			Size = UDim2.fromOffset(1, 1),
			BackgroundTransparency = 1,
		}, NeverloseCS2)
		for i, asset in ipairs(preloadAssets) do
			New("ImageLabel", {
				Name = "P" .. tostring(i),
				Size = UDim2.fromOffset(1, 1),
				BackgroundTransparency = 1,
				Image = asset,
				ImageTransparency = 0.01,
				ScaleType = Enum.ScaleType.Fit,
			}, preloader)
		end
		task.delay(4, function()
			if preloader.Parent then preloader:Destroy() end
		end)
	end)

	return WindowObj
end

return Library
