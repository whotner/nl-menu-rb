# nl-menu-rb

UI-библиотека для Roblox (Luau), максимально близко повторяющая меню **Neverlose (CS2)**: стеклянное окно с блюром, вкладки и подвкладки, карточки-секции, плашки «...» с доп. настройками, аккордеоны, система биндов, вотермарка, списки Hotkeys / Spectators, превью игроков и экран снаряжения как в CS2.

Вся библиотека — один файл `scr.lua`. Полный пример со всеми элементами и комментариями — `scr_test.lua`.

## Возможности

- **Окно**: стекло с акриловым блюром, тень, плавное открытие/закрытие (RShift), перетаскивание, масштаб (Auto / вручную).
- **Плашка загрузки** в стиле Neverlose (можно отключить).
- **Вкладки, подвкладки, группы вкладок** (AIMBOT / COMMON), иконки.
- **Элементы**: переключатель, чекбокс, слайдер, выпадающий список, выбор цвета, их комбинации, аккордеоны.
- **Плашка «...»** у функции с её доп. настройками; несколько карточек внутри.
- **Подсказки** при наведении (через ~1.5 с).
- **Бинды**: колесико или ПКМ по любой функции → All Hotkeys / New Hotkey / Reset. Несколько хоткеев на функцию, режимы Toggle / Hold / Always, для слайдеров — бинд на конкретное число.
- **Hotkeys / Spectators** — списки на экране, видны и при закрытом меню, если есть активный бинд или зрители.
- **Вотермарка**: 16 показателей (FPS, пинг, разброс пинга, скорость, время, ник, аватар, KD, CPU/GPU и др.), ПКМ — настройки, перетаскивание показателей, пресеты положения.
- **Пресеты (конфиги)**: сохранение, загрузка, дублирование, удаление с корзиной, share-коды `NL1:`. Сохраняются значения всех элементов, хоткеи, вотермарка и позиции окон. Последний пресет загружается при следующем запуске.
- **Профиль**: язык, масштаб, акцентный цвет, переключатели, About.
- **Players**: превью твоего персонажа, Enemies / Teammates, выбор ESP Items.
- **Inventory**: экран снаряжения CS2 (агент — твой персонаж, CT / T, слоты).
- Анимации везде, акцентный цвет меняется на лету.

## Установка

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whotner/nl-menu-rb/main/scr.lua"))()
```

Файл большой. Если экзекутор не может его скомпилировать или GitHub отдаёт старую версию (кэш до нескольких минут), используй загрузчик из `scr_test.lua`: он вырезает комментарии и качает файл по хэшу последнего коммита.

## Быстрый старт

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/whotner/nl-menu-rb/main/scr.lua"))()

Library.DaysLeft = 30            -- nil = "Lifetime"
-- Library.ShowLoader = false    -- без плашки загрузки

local Win = Library:AddWindow("Neverlose", "", "My Game")
Win:AddTabLabel("Aimbot")

local Rage = Win:AddTab("Rage", "crosshair")
local Main = Rage:AddSection("Main", "left")

local Enabled = Main:AddToggle("Enabled", false, function(on) print("enabled", on) end)
Enabled:SetTooltip("Turns the ragebot on")

local Extra = Enabled:AddSettings()          -- плашка «...»
Extra:AddSlider("Field of View", 0, 360, 180, function(v) end, "°")

Main:AddDropdown("Target", {"Closest", "Lowest Health"}, "Closest", function(v) end)
```

## API

### Библиотека

| | |
|---|---|
| `Library:AddWindow(title, image, subtitle)` | Создаёт окно. `image`: `""` = нарисованное «NL», иначе `"rbxassetid://..."`. |
| `Library.DaysLeft` | Дни подписки в профиле; `nil` = Lifetime. |
| `Library.ShowLoader` | `false` — без плашки загрузки. |

### Окно (`Win`)

| | |
|---|---|
| `Win:AddTab(name, icon)` | Вкладка. Иконки: `crosshair`, `mouse`, `image`, `layers`, `gear`, `user`, `earth` или `rbxassetid://...`. |
| `Win:AddTabLabel(text)` | Заголовок группы вкладок. |
| `Win:SetScale("Auto" \| number)` / `Win:GetScale()` | Масштаб меню. |
| `Win:SetMenuBind(KeyCode)` / `Win:GetMenuBind()` | Клавиша открытия (по умолчанию RightShift). |
| `Win:SetCustomization({...})` / `Win:GetCustomization()` | `accentColor`, `textColor`, `font`, `sectionTitleSize`, `elementTextSize`, `cornerRadius`, `showContextDots`. |
| `Win:SetWatermark({...})` | Вотермарка, см. ниже. |
| `Win:SetSpectators(list)` / `Win:SetSpectatorsAuto(bool)` | Свой список зрителей (игроки или строки) / авто. |
| `Win:SetWeaponPresets(names)` / `Win:OnWeaponPreset(fn)` / `Win:GetWeaponPreset()` | Пресеты оружия под кнопкой Global. |
| `Win:OnProfileSetting(fn(key, value))` / `Win:GetProfileSetting(key)` | Настройки профиля. |
| `Win:OnProfileAction(fn(key))` | Клик по About / Chat. |
| `Win:SetLogoVisible(bool)` | Показать / скрыть лого. |

### Вкладки и секции

| | |
|---|---|
| `Tab:AddSection(title, "left" \| "right")` | Карточка в колонке. |
| `Tab:AddSubTab(name, icon)` | Подвкладка; у неё те же `AddSection`, `AddESPPreview`. |
| `Tab:AddLoadout(options)` | Экран снаряжения CS2 на всю вкладку. |
| `Tab:AddESPPreview(options)` | Превью игроков в правой колонке. |

### Элементы секции

```lua
Section:AddToggle(text, default, callback(on))
Section:AddCheckbox(text, default, callback(on))
Section:AddSlider(text, min, max, default, callback(value), suffix)
Section:AddDropdown(text, options, default, callback(value))
Section:AddColorpicker(text, color, callback(color))
Section:AddToggleColorpicker(text, on, color, callback(on), callback(color))
Section:AddDropdownColorpicker(text, options, color, callback(option), callback(color))
Section:AddColorToggle(text, color, on, callback(color, on))
Section:AddAccordion(text)          -- раскрывающаяся строка; внутри те же Add*
```

Методы элементов:

```lua
el:Set(value)          el:Get()
el:SetTooltip("текст") -- подсказка при наведении
el:Bind("F")           el:Unbind()      el:GetBind()
toggle:AddSettings()   -- плашка «...»; внутри Add*, :AddGroup() — новая карточка
accordion:AddGroup()   -- новая карточка в аккордеоне
```

### Бинды

В игре: колесико (или ПКМ) по функции → **New Hotkey**. Справа откроется редактор:

- **Key** — клик и нажать клавишу. Backspace — стереть, Esc — отмена.
- **Mode** — Toggle / Hold / Always.
- **Value** — для слайдеров: число, которое ставит бинд. Toggle ставит его и возвращает прежнее при следующем нажатии, Hold держит, пока зажата клавиша.
- **Visible** — показывать ли в списке Hotkeys.

Функция может иметь несколько хоткеев. Список Hotkeys показывает включённые бинды.

### Вотермарка

```lua
Win:SetWatermark({
    positionPreset = "Top Right", -- Top Right/Center/Left, Bottom Right/Center/Left
    show  = { logo = true, name = true, ping = true, user = true, time = false },
    order = { "logo", "name", "ping", "user", "time" },
})
```

Пункты: `logo`, `name` (ник), `user` (аватар), `ping` (разброс пинга), `latency`, `speed`, `fps`, `ram`, `time`, `kd`, `gpu`, `cpu`, `cpufreq`, `loss`, `issues`, `server`, `preset`.

В игре: **ПКМ** по вотермарке — меню (Items, Additional Colors, Display Avatar, Position). **ЛКМ** — тянуть показатель (перестановка) или край полосы (перемещение).

### Players — `AddESPPreview`

```lua
local Preview = VisPlayer:AddESPPreview({
    team = "Enemies",
    sections = { Enemies = { EnemySection }, Teammates = { TeamSection } },
    onItem  = function(team, group, item, on) end,
    onTeam  = function(team) end,
    onScale = function(together) end,
})
Preview:SetTeam("Teammates")
Preview:IsItemOn("Enemies", "Main", "Name")
```

### Inventory — `AddLoadout`

```lua
local Loadout = InvTab:AddLoadout({
    team = "CT",
    icons = { CT = "rbxassetid://...", T = "rbxassetid://..." }, -- необязательно
    onSelect = function(team, category, index, name) end,
    onTeam = function(team) end,
})
Loadout:SetTeam("T")
```

## Пресеты (конфиги)

Файлы `NeverloseConfig_<id>_<имя>.json` в папке workspace экзекутора. Кнопка с дискетой сохраняет выбранный пресет (или `Default`). В пресет попадают:

- значения всех элементов;
- хоткеи;
- настройки вотермарки, Players-превью;
- позиции вотермарки, списков и окна.

Последний сохранённый или загруженный пресет автоматически загружается при следующем запуске. Share-код (`NL1:...`) копируется из меню пресета и вставляется в поле «+».

## Заметки

- Блюр работает при качестве графики 8+ или Auto.
- Картинки аватаров и превью Roblox иногда не грузятся; тогда показываются заглушки (буква ника, нарисованное «NL»).
- Требуется экзекутор с `writefile` / `readfile` / `isfile` для пресетов и `setclipboard` для share-кодов.
