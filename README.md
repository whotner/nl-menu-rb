# nl-menu-rb

Компактная и кастомизируемая библиотека для создания интерфейса меню в Roblox (подобие Neverlose / custom UI).

## Возможности

- компактный и современный дизайн
- настройка размера окна
- возможность скрывать или оставлять логотип
- поддержка вкладок и секций
- простые элементы: toggle, checkbox, dropdown, slider
- мягкие анимации
- кастомизация цвета акцента
- поддержка опционального объекта настроек окна

## Установка

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whotner/nl-menu-rb/main/scr.lua"))()
```

Или просто добавьте `scr.lua` в свой проект и подключите его как модуль:

```lua
local Library = require(script.Parent.scr)
```

## Быстрый пример

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whotner/nl-menu-rb/main/scr.lua"))()

local Window = Library:AddWindow({
    Title = "My Hub",
    GameTitle = "Roblox",
    Image = "rbxassetid://123456789", -- можно оставить пустым или nil
    ShowLogo = true,
    Size = Vector2.new(760, 540),
    Color = Color3.fromRGB(26, 123, 255),
})

local MainTab = Window:AddTab("Main", "gear")
local Combat = MainTab:AddSection("Combat")

local AimToggle = Combat:AddToggle("Aimbot", true, function(value)
    print("Aimbot:", value)
end)

local FovSlider = Combat:AddSlider("FOV", 0, 120, 80, function(value)
    print("FOV:", value)
end)

local Mode = Combat:AddDropdown("Mode", {"Normal", "Silent", "Legit"}, "Normal", function(value)
    print("Mode:", value)
end)

local Visuals = Window:AddTab("Visuals", "arrow")
local ESP = Visuals:AddSection("ESP")
ESP:AddToggle("Boxes", false)
ESP:AddToggle("Names", true)
```

## API

### Library:AddWindow(options)

Создаёт главное окно библиотеки.

Параметры:

```lua
{
    Title = "My Hub",
    GameTitle = "Game",
    Image = "rbxassetid://123456789",
    ShowLogo = true,
    Size = Vector2.new(760, 540),
    MinSize = Vector2.new(520, 360),
    MaxSize = Vector2.new(1300, 900),
    Color = Color3.fromRGB(26, 123, 255),
}
```

Также поддерживается старый вызов:

```lua
Library:AddWindow("My Hub", "rbxassetid://123456789", "Game", Vector2.new(760, 540))
```

### Window:SetSize(size)

Изменяет размер окна.

```lua
Window:SetSize(Vector2.new(820, 600))
```

### Window:SetLogo(image, visible)

Меняет логотип или скрывает его.

```lua
Window:SetLogo("rbxassetid://123456789", true)
```

### Window:Toggle(value)

Показывает/скрывает окно.

```lua
Window:Toggle(true)
Window:Toggle(false)
```

### Window:AddTab(name, icon)

Добавляет новую вкладку.

```lua
local Tab = Window:AddTab("Combat", "gear")
```

### Tab:AddSection(title)

Добавляет секцию внутри вкладки.

```lua
local Section = Tab:AddSection("Main Settings")
```

### Section:AddToggle(text, default, callback)

```lua
local Toggle = Section:AddToggle("Aimbot", true, function(enabled)
    print("Enabled:", enabled)
end)
```

### Section:AddCheckbox(text, default, callback)

```lua
local Checkbox = Section:AddCheckbox("Team Check", true)
```

### Section:AddDropdown(text, options, default, callback)

```lua
local Dropdown = Section:AddDropdown("Mode", {"Normal", "Silent", "Legit"}, "Normal", function(value)
    print(value)
end)
```

### Section:AddSlider(text, min, max, default, callback, suffix)

```lua
local Slider = Section:AddSlider("FOV", 0, 120, 80, function(value)
    print(value)
end, "")
```

## Методы элементов

У большинства элементов есть методы:

```lua
Toggle:Set(true)
Toggle:Get()

Slider:Set(90)
Slider:Get()

Dropdown:Set("Silent")
Dropdown:Get()
```

## Примечания

- Логотип можно полностью отключить через `ShowLogo = false`.
- Если окно слишком маленькое, можно задать `MinSize`.
- Яркость и цвет акцента регулируются через `Color`.
- Библиотека рассчитана на простой и быстрый UI для Roblox проектов.

## Автор

`whotner` / `nl-menu-rb`

## Лицензия

Для этого проекта можно использовать свободный подход без явного указания лицензии, если вы сами используете его в своём проекте.

Если хотите, я могу сразу сделать ещё и:

- более “премиальный” README с красивой структурой;
- README на английском;
- раздел с примерами кастомизации под ваш UI-стиль;
- короткую документацию по каждому элементу в виде таблицы.
