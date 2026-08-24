-- MilitaryBasePrimordial bundle (auto-generado) --
local Lib = (function()
-- PrimordialUI bundle (auto-generado por build.sh) --
local P = {}
-- ==== Core/Signal ====
do local __m = (function()
return function(P)
    local Signal = {}
    Signal.__index = Signal
    function Signal.new()
        return setmetatable({ _cbs = {} }, Signal)
    end
    function Signal:Connect(fn)
        local conn = { fn = fn, _sig = self }
        function conn:Disconnect()
            for i, c in ipairs(self._sig._cbs) do
                if c == self then table.remove(self._sig._cbs, i) break end
            end
        end
        table.insert(self._cbs, conn)
        return conn
    end
    function Signal:Fire(...)
        for _, c in ipairs({ table.unpack(self._cbs) }) do
            task.spawn(c.fn, ...)
        end
    end
    function Signal:DisconnectAll() self._cbs = {} end
    P.Signal = Signal
end

end)(); __m(P) end
-- ==== Core/Theme ====
do local __m = (function()
return function(P)
    P.Theme = {
        Accent    = Color3.fromRGB(202, 151, 161),  -- rosa mauve exacto (swatch primordial)
        AccentDim = Color3.fromRGB(138, 102, 110),
        Bg        = Color3.fromRGB(29, 29, 32),      -- fondo window (no negro)
        Surface   = Color3.fromRGB(34, 34, 37),      -- panels
        Bar       = Color3.fromRGB(40, 40, 44),      -- header + barra de categorias (mas claro que bg/panels)
        Sidebar   = Color3.fromRGB(32, 32, 35),      -- sidebar (un pelin mas oscuro)
        Surface2  = Color3.fromRGB(23, 23, 26),      -- controls (toggle/dropdown/textbox/slider) mas oscuro que Bg
        Surface3  = Color3.fromRGB(56, 56, 62),      -- hover / pill categoria activa
        Knob      = Color3.fromRGB(206, 206, 211),   -- perilla gris clara
        Outline   = Color3.fromRGB(48, 48, 53),
        Border    = Color3.fromRGB(8, 8, 10),        -- borde negro thin de panels
        Text      = Color3.fromRGB(228, 228, 233),
        SubText   = Color3.fromRGB(132, 132, 140),
        Positive  = Color3.fromRGB(120, 200, 120),
        Negative  = Color3.fromRGB(210, 70, 70),
        Radius    = 5,
        RadiusBig = 7,
        Pad       = 6,
        RowH      = 22,          -- compacto (match primordial real)
        Font      = Enum.Font.Gotham,
        FontBold  = Enum.Font.GothamBold,
        TextSize  = 12,
        Shadow    = "rbxassetid://6014261993",       -- drop shadow 9-slice
    }
end

end)(); __m(P) end
-- ==== Core/Util ====
do local __m = (function()
return function(P)
    local TweenService = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local Util = {}

    function Util.Create(class, props, children)
        local inst = Instance.new(class)
        for k, v in pairs(props or {}) do
            if k ~= "Parent" then inst[k] = v end
        end
        for _, c in ipairs(children or {}) do c.Parent = inst end
        if props and props.Parent then inst.Parent = props.Parent end
        return inst
    end

    function Util.Tween(inst, info, goal)
        local t = TweenService:Create(inst, info, goal); t:Play(); return t
    end

    function Util.Round(n, dec)
        local m = 10 ^ (dec or 0)
        return math.floor(n * m + 0.5) / m
    end

    function Util.GetGui()
        local parent
        local ok = pcall(function() parent = gethui() end)
        if not ok or not parent then
            parent = game:GetService("CoreGui")
        end
        return parent
    end

    -- Arrastre: handleGui recibe input, mueve targetFrame por delta.
    -- maid opcional: objeto con :Maid(conn) para limpiar la conexion global en Unload.
    function Util.Drag(handleGui, targetFrame, maid)
        local dragging, startPos, startInput
        local function reg(c) if maid then maid:Maid(c) end return c end
        reg(handleGui.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if maid and maid.CloseActivePopup then maid:CloseActivePopup() end
                dragging = true
                startPos = targetFrame.Position
                startInput = input.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end))
        reg(UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - startInput
                targetFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
    end

    -- Sombra suave y externa detras de un frame (elevacion sutil).
    -- Usar SOLO en frames que NO sean AutomaticSize (si no, la infla).
    function Util.Shadow(target, opts)
        opts = opts or {}
        local sp = opts.Spread or 22
        local sh = Instance.new("ImageLabel")
        sh.Name = "Shadow"
        sh.BackgroundTransparency = 1
        sh.Image = P.Theme.Shadow
        sh.ImageColor3 = opts.Color or Color3.new(0, 0, 0)
        sh.ImageTransparency = opts.Transparency or 0.78
        sh.ScaleType = Enum.ScaleType.Slice
        sh.SliceCenter = Rect.new(49, 49, 450, 450)
        sh.ZIndex = -1
        sh.AnchorPoint = Vector2.new(0.5, 0.5)
        sh.Position = UDim2.new(0.5, 0, 0.5, opts.YOffset or 4)
        sh.Size = UDim2.new(1, sp * 2, 1, sp * 2)
        sh.Parent = target
        return sh
    end

    -- Profundidad interna sutil para controles (Surface2). Oscurece hacia abajo
    -- (gradiente multiplicativo) + linea de highlight 1px arriba (borde superior con luz).
    -- opts.Bottom = cuanto oscurece abajo (0..1, default 0.14). opts.Highlight = agregar rim light.
    function Util.Depth(inst, opts)
        opts = opts or {}
        local b = 1 - (opts.Bottom or 0.14)
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(b, b, b)),
        })
        g.Parent = inst
        if opts.Highlight then
            local hl = Instance.new("Frame")
            hl.Name = "Rim"; hl.BorderSizePixel = 0
            hl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hl.BackgroundTransparency = opts.HighlightT or 0.9
            hl.Position = UDim2.fromOffset(2, 1)
            hl.Size = UDim2.new(1, -4, 0, 1)
            hl.ZIndex = (inst.ZIndex or 1) + 1
            hl.Parent = inst
        end
        return g
    end

    P.Util = Util
end

end)(); __m(P) end
-- ==== Core/Registry ====
do local __m = (function()
return function(P)
    local Registry = {}
    Registry.__index = Registry
    function Registry.new() return setmetatable({ _items = {} }, Registry) end
    function Registry:Add(inst, role, prop)
        table.insert(self._items, { inst = inst, role = role, prop = prop })
        if P.Theme[role] then inst[prop] = P.Theme[role] end
    end
    function Registry:Apply(theme)
        for _, it in ipairs(self._items) do
            if it.inst and it.inst.Parent ~= nil and theme[it.role] then
                it.inst[it.prop] = theme[it.role]
            end
        end
    end
    P.Registry = Registry
end

end)(); __m(P) end
-- ==== Core/Icons ====
do local __m = (function()
return function(P)
    local Icons = {}
    -- fuente Lucide para Roblox (spritesheet), cargada lazy + cacheada
    Icons.URL = "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"
    Icons._mod = nil  -- nil = sin intentar; false = fallo; table = cargado

    function Icons.load()
        if Icons._mod ~= nil then return Icons._mod or nil end
        local ok, mod = pcall(function()
            return loadstring(game:HttpGet(Icons.URL))()
        end)
        Icons._mod = (ok and type(mod) == "table" and mod) or false
        return Icons._mod or nil
    end

    -- resuelve un icono a props de ImageLabel.
    -- acepta: nombre Lucide ("crosshair"), "rbxassetid://123", "rbxasset://...", o numero.
    function Icons.resolve(icon)
        if not icon or icon == "" then return nil end
        icon = tostring(icon)
        if icon:match("^%d+$") then return { Image = "rbxassetid://" .. icon } end
        if icon:match("^rbxasset") then return { Image = icon } end
        local mod = Icons.load()
        if mod and mod.GetAsset then
            local ok, a = pcall(mod.GetAsset, icon)
            if ok and type(a) == "table" then
                return { Image = a.Url or a.Image, ImageRectOffset = a.ImageRectOffset, ImageRectSize = a.ImageRectSize }
            end
        end
        return nil
    end

    -- aplica el icono a un ImageLabel/ImageButton existente
    function Icons.apply(img, icon)
        local r = Icons.resolve(icon)
        if not r then img.Image = ""; return false end
        img.Image = r.Image
        img.ImageRectOffset = r.ImageRectOffset or Vector2.zero
        img.ImageRectSize = r.ImageRectSize or Vector2.zero
        return true
    end

    P.Icons = Icons
end

end)(); __m(P) end
-- ==== Core/Library ====
do local __m = (function()
return function(P)
    local UIS = game:GetService("UserInputService")
    local Library = {
        Flags = {}, Toggles = {}, Options = {}, Windows = {},
        Open = true, Unloaded = false,
        ToggleKey = Enum.KeyCode.RightShift,
        Connections = {}, _flagSignals = {},
    }
    Library.Registry = P.Registry.new()
    Library.FlagChanged = P.Signal.new()

    function Library:Maid(x) table.insert(self.Connections, x); return x end

    function Library:GetFlagSignal(flag)
        local s = self._flagSignals[flag]
        if not s then s = P.Signal.new(); self._flagSignals[flag] = s end
        return s
    end

    function Library:SetFlag(flag, value)
        self.Flags[flag] = value
        self.FlagChanged:Fire(flag, value)
        local s = self._flagSignals[flag]
        if s then s:Fire(value) end
    end

    -- solo un popup (dropdown/colorpicker/gear) abierto a la vez
    function Library:OpenPopup(closer)
        if self._activePopup and self._activePopup ~= closer then pcall(self._activePopup) end
        self._activePopup = closer
    end
    function Library:ClosePopup(closer)
        if self._activePopup == closer then self._activePopup = nil end
    end
    function Library:CloseActivePopup()
        if self._activePopup then local c = self._activePopup; self._activePopup = nil; pcall(c) end
    end

    function Library:SetTheme(patch)
        for k, v in pairs(patch or {}) do P.Theme[k] = v end
        self.Registry:Apply(P.Theme)
    end

    function Library:CreateWindow(opts)
        if not P.Window then warn("PrimordialUI: Window module ausente"); return nil end
        local w = P.Window.new(self, opts or {})
        table.insert(self.Windows, w)
        return w
    end

    function Library:Unload()
        self.Unloaded = true
        for _, c in ipairs(self.Connections) do
            pcall(function() if c.Disconnect then c:Disconnect() elseif c.Destroy then c:Destroy() end end)
        end
        self.Connections = {}
        for _, w in ipairs(self.Windows) do pcall(function() w:Destroy() end) end
        self.Windows = {}
        if getgenv then getgenv().__PUI = nil end
    end

    -- toggle show/hide global
    Library:Maid(UIS.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Library.ToggleKey then
            Library.Open = not Library.Open
            for _, w in ipairs(Library.Windows) do w:SetVisible(Library.Open) end
        end
    end))

    -- single-instance: descarga cualquier instancia previa al recargar la lib
    if getgenv then
        if getgenv().__PUI then pcall(function() getgenv().__PUI:Unload() end) end
        -- barrer guis huerfanas (windows PUI_ y overlays PUIo_) de instancias leakeadas
        pcall(function()
            local roots = {}
            local ok, hui = pcall(function() return gethui() end)
            if ok and hui then table.insert(roots, hui) end
            table.insert(roots, game:GetService("CoreGui"))
            for _, r in ipairs(roots) do
                for _, g in ipairs(r:GetChildren()) do
                    if g:IsA("ScreenGui") and (tostring(g.Name):match("^PUI_") or tostring(g.Name):match("^PUIo_")) then
                        g:Destroy()
                    end
                end
            end
        end)
        getgenv().__PUI = Library
    end
    P.Library = Library
end

end)(); __m(P) end
-- ==== Core/Overlays ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local UIS = game:GetService("UserInputService")
    local Lib = P.Library

    Lib.DPIScale = 1
    function Lib:SetDPIScale(pct)
        self.DPIScale = math.clamp(pct / 100, 0.5, 2)
        for _, w in ipairs(self.Windows) do
            if w.UIScale then w.UIScale.Scale = self.DPIScale end
        end
    end

    -- ScreenGui compartido para overlays (no escala con el DPI del menu)
    local function overlay()
        if Lib._overlayGui and Lib._overlayGui.Parent then return Lib._overlayGui end
        Lib._overlayGui = U.Create("ScreenGui", { Name = "PUIo_" .. tostring(math.random(1e5, 9e5)),
            ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9999, Parent = U.GetGui() })
        Lib:Maid(Lib._overlayGui)
        return Lib._overlayGui
    end

    -- hace un overlay arrastrable y persiste su posicion en self._overlayPos[key]
    function Lib:_trackOverlay(key, frame)
        self._overlayPos = self._overlayPos or {}
        local p = self._overlayPos[key]
        if p then frame.Position = UDim2.fromOffset(p[1], p[2]) end
        U.Drag(frame, frame, self)
        frame:GetPropertyChangedSignal("Position"):Connect(function()
            self._overlayPos[key] = { frame.Position.X.Offset, frame.Position.Y.Offset }
        end)
    end
    -- aplica posiciones guardadas (llamado por LoadConfig)
    function Lib:ApplyOverlayPositions(pos)
        self._overlayPos = pos or {}
        if self._wm and self._overlayPos.watermark then
            local p = self._overlayPos.watermark; self._wm.Position = UDim2.fromOffset(p[1], p[2])
        end
        if self._kbFrame and self._overlayPos.keybindlist then
            local p = self._overlayPos.keybindlist; self._kbFrame.Position = UDim2.fromOffset(p[1], p[2])
        end
    end

    ---------------------------------------------------------------- WATERMARK
    function Lib:SetWatermark(text)
        local g = overlay()
        if not self._wm then
            self._wm = U.Create("Frame", { Parent = g, BackgroundColor3 = T.Bar, BorderSizePixel = 0,
                Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(10, 24),
                AutomaticSize = Enum.AutomaticSize.X,
            }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
                U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
                U.Create("Frame", { Name = "Bar", BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                    Size = UDim2.new(0, 2, 1, 0) }),
                U.Create("TextLabel", { Name = "T", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
                    Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0, 0, 1, 0),
                    Font = T.FontBold, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left },
                    { U.Create("UIPadding", { PaddingRight = UDim.new(0, 10) }) }) })
            self.Registry:Add(self._wm.Bar, "Accent", "BackgroundColor3")
            self:_trackOverlay("watermark", self._wm)
        end
        self._wm.T.Text = text
    end
    function Lib:SetWatermarkVisibility(b)
        if not self._wm and b then self:SetWatermark("PrimordialUI") end
        if self._wm then self._wm.Visible = b end
    end

    ---------------------------------------------------------------- TOOLTIP
    local function tip()
        if Lib._tip and Lib._tip.Parent then return Lib._tip end
        Lib._tip = U.Create("TextLabel", { Parent = overlay(), Visible = false, ZIndex = 50,
            BackgroundColor3 = T.Surface2, AutomaticSize = Enum.AutomaticSize.XY,
            Font = T.Font, TextSize = 12, TextColor3 = T.Text, Text = "",
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }) })
        return Lib._tip
    end
    function Lib:ShowTooltip(text)
        local t = tip(); t.Text = text; t.Visible = true
        local m = UIS:GetMouseLocation()
        t.Position = UDim2.fromOffset(m.X + 14, m.Y + 6)
    end
    function Lib:MoveTooltip()
        if self._tip and self._tip.Visible then
            local m = UIS:GetMouseLocation()
            self._tip.Position = UDim2.fromOffset(m.X + 14, m.Y + 6)
        end
    end
    function Lib:HideTooltip() if self._tip then self._tip.Visible = false end end

    ---------------------------------------------------------------- NOTIFY
    function Lib:_notifyHolder()
        if self._nHolder and self._nHolder.Parent then return self._nHolder end
        self._nHolder = U.Create("Frame", { Parent = overlay(), BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
            Size = UDim2.fromOffset(250, 600),
        }, { U.Create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder }) })
        return self._nHolder
    end
    function Lib:Notify(a, b)
        local title, desc, time
        if type(a) == "table" then title, desc, time = a.Title, a.Description, a.Time
        else title, desc, time = a, nil, b end
        time = time or 4
        local card = U.Create("Frame", { Parent = self:_notifyHolder(), BackgroundColor3 = T.Bar,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("Frame", { Name = "Bar", BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                Size = UDim2.new(0, 2, 1, 0) }) })
        local content = U.Create("Frame", { Parent = card, BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -18, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, { U.Create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }) })
        U.Create("TextLabel", { Parent = content, BackgroundTransparency = 1, LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 16), Font = T.FontBold, TextSize = 13, TextColor3 = T.Text,
            Text = title or "", TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y })
        if desc then
            U.Create("TextLabel", { Parent = content, BackgroundTransparency = 1, LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 14), Font = T.Font, TextSize = 12, TextColor3 = T.SubText,
                Text = desc, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y })
        end
        task.delay(time, function()
            if card and card.Parent then card:Destroy() end
        end)
        return card
    end

    ---------------------------------------------------------------- THEME PRESETS
    Lib.ThemePresets = {
        Default  = { Accent = Color3.fromRGB(202, 151, 161) },
        Crimson  = { Accent = Color3.fromRGB(214, 84, 84) },
        Ocean    = { Accent = Color3.fromRGB(96, 156, 214) },
        Emerald  = { Accent = Color3.fromRGB(104, 196, 140) },
        Amethyst = { Accent = Color3.fromRGB(168, 130, 214) },
        Amber    = { Accent = Color3.fromRGB(214, 168, 92) },
    }
    function Lib:ListThemePresets()
        local list = {}
        for k in pairs(self.ThemePresets) do table.insert(list, k) end
        table.sort(list)
        return list
    end
    function Lib:ApplyThemePreset(name)
        local p = self.ThemePresets[name]
        if p then self:SetTheme(p) end
    end

    ---------------------------------------------------------------- KEYBIND LIST
    function Lib:_kbHolder()
        if self._kbFrame and self._kbFrame.Parent then return self._kbFrame end
        self._kbFrame = U.Create("Frame", { Parent = overlay(), Visible = false,
            BackgroundColor3 = T.Bar, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 46),
            Size = UDim2.new(0, 160, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("Frame", { Name = "Bar", BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 2) }) })
        self.Registry:Add(self._kbFrame.Bar, "Accent", "BackgroundColor3")
        local body = U.Create("Frame", { Parent = self._kbFrame, Name = "Body", BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { U.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
        U.Create("TextLabel", { Parent = body, BackgroundTransparency = 1, LayoutOrder = 0,
            Size = UDim2.new(1, 0, 0, 15), Font = T.FontBold, TextSize = 13, TextColor3 = T.Text,
            Text = "Keybinds", TextXAlignment = Enum.TextXAlignment.Left })
        self._kbBody = body
        self:_trackOverlay("keybindlist", self._kbFrame)
        return self._kbFrame
    end
    function Lib:RegisterKeybind(kb)
        local body = self:_kbHolder().Body or self._kbBody
        local row = U.Create("TextLabel", { Parent = body, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14), Font = T.Font, TextSize = 12, TextColor3 = T.SubText,
            Text = "", TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #self.KeybindEntries + 1 })
        local entry = { row = row, kb = kb }
        function entry:Update()
            local keyN = self.kb.Key and self.kb.Key.Name or "None"
            self.row.Text = ("%s  [%s]"):format(self.kb.Text or self.kb.Flag, keyN)
            self.row.TextColor3 = self.kb.Active and T.Accent or T.SubText
        end
        table.insert(self.KeybindEntries, entry)
        entry:Update()
        return entry
    end
    Lib.KeybindEntries = Lib.KeybindEntries or {}
    function Lib:SetKeybindListVisibility(b)
        self:_kbHolder().Visible = b
    end
end

end)(); __m(P) end
-- ==== Core/ConfigManager ====
do local __m = (function()
return function(P)
    local Lib = P.Library
    local HttpService = game:GetService("HttpService")

    Lib.ConfigFolder = "PrimordialUI/configs"

    local function ensure()
        if typeof(makefolder) == "function" then
            if not (typeof(isfolder) == "function" and isfolder(Lib.ConfigFolder)) then
                pcall(makefolder, Lib.ConfigFolder)
            end
        end
    end

    -- serializar tipos Roblox a JSON-safe
    local function ser(v)
        local t = typeof(v)
        if t == "boolean" or t == "number" or t == "string" then return v end
        if t == "Color3" then
            return { __ = "c3", r = math.floor(v.R * 255 + 0.5), g = math.floor(v.G * 255 + 0.5), b = math.floor(v.B * 255 + 0.5) }
        end
        if t == "EnumItem" then return { __ = "en", t = tostring(v.EnumType):gsub("^Enum%.", ""), n = v.Name } end
        if t == "table" then
            local o = {}
            for k, x in pairs(v) do o[k] = ser(x) end
            return o
        end
        return nil
    end
    local function deser(v)
        if type(v) ~= "table" then return v end
        if v.__ == "c3" then return Color3.fromRGB(v.r, v.g, v.b) end
        if v.__ == "en" then local ok, e = pcall(function() return Enum[v.t][v.n] end); return ok and e or nil end
        local o = {}
        for k, x in pairs(v) do if k ~= "__" then o[k] = deser(x) end end
        return o
    end

    Lib.ConfigIgnore = {}  -- flags a NO guardar (ej. los widgets del settings tab)
    function Lib:GetConfig()
        local out = {}
        for flag, t in pairs(self.Toggles) do
            if not self.ConfigIgnore[flag] then out[flag] = ser(t:GetValue()) end
        end
        for flag, o in pairs(self.Options) do
            if not self.ConfigIgnore[flag] and o.GetValue then
                local v = o:GetValue()
                if v ~= nil then out[flag] = ser(v) end
            end
        end
        if self._overlayPos then out.__overlays = self._overlayPos end
        return out
    end

    function Lib:LoadConfig(tbl)
        for flag, v in pairs(tbl or {}) do
            if flag ~= "__overlays" then
                local w = self.Toggles[flag] or self.Options[flag]
                if w and w.SetValue then pcall(function() w:SetValue(deser(v)) end) end
            end
        end
        if tbl and tbl.__overlays and self.ApplyOverlayPositions then
            self:ApplyOverlayPositions(tbl.__overlays)
        end
    end

    local function path(name) return Lib.ConfigFolder .. "/" .. name .. ".json" end

    function Lib:SaveConfig(name)
        if not name or name == "" then return false, "sin nombre" end
        ensure()
        local ok = pcall(function()
            writefile(path(name), HttpService:JSONEncode(self:GetConfig()))
        end)
        return ok
    end
    function Lib:LoadConfigFile(name)
        local p = path(name)
        if typeof(isfile) == "function" and not isfile(p) then return false end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
        if ok and data then self:LoadConfig(data); return true end
        return false
    end
    function Lib:DeleteConfig(name)
        if typeof(delfile) == "function" then pcall(delfile, path(name)) end
    end
    function Lib:ListConfigs()
        local list = {}
        if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(self.ConfigFolder) then
            for _, f in ipairs(listfiles(self.ConfigFolder)) do
                local n = tostring(f):match("([^/\\]+)%.json$")
                if n then table.insert(list, n) end
            end
        end
        return list
    end
    function Lib:SetAutoloadConfig(name)
        ensure()
        pcall(function() writefile(Lib.ConfigFolder .. "/autoload.txt", name or "") end)
    end
    function Lib:GetAutoloadConfig()
        local p = Lib.ConfigFolder .. "/autoload.txt"
        if typeof(isfile) == "function" and isfile(p) then
            local ok, n = pcall(readfile, p)
            if ok and n and n ~= "" then return n end
        end
        return nil
    end
    function Lib:LoadAutoloadConfig()
        local n = self:GetAutoloadConfig()
        if n then return self:LoadConfigFile(n) end
        return false
    end
end

end)(); __m(P) end
-- ==== Chrome/Window ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Window = {}
    Window.__index = Window

    function Window.new(Library, opts)
        local self = setmetatable({ Library = Library, Categories = {}, ActiveCategory = nil }, Window)
        local size = opts.Size or Vector2.new(834, 586)

        self.Gui = U.Create("ScreenGui", {
            Name = "PUI_"..tostring(math.random(1e5,9e5)),
            ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = U.GetGui(),
        })
        self.Root = U.Create("Frame", {
            Parent = self.Gui, Size = UDim2.fromOffset(size.X, size.Y),
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3 = T.Bg, BorderSizePixel = 0,
        }, {
            U.Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),   -- borde negro thin alrededor
        })
        self.UIScale = U.Create("UIScale", { Parent = self.Root, Scale = Library.DPIScale or 1 })
        Library.Registry:Add(self.Root, "Bg", "BackgroundColor3")

        -- Header (mismo alto que la barra inferior = 64); esquinas superiores redondeadas
        local HEADERH = 64
        self.Header = U.Create("Frame", {
            Parent = self.Root, Size = UDim2.new(1, 0, 0, HEADERH),
            BackgroundColor3 = T.Bar, BorderSizePixel = 0,
        }, {
            U.Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
            U.Create("Frame", { Name = "SquareBottom", BorderSizePixel = 0, BackgroundColor3 = T.Bar,
                Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10) }),
            U.Create("TextLabel", {
                Name = "Title", BackgroundTransparency = 1,
                Position = UDim2.fromOffset(48, 0), Size = UDim2.new(0.5, -60, 1, 0),
                Font = T.FontBold, TextSize = 22, TextColor3 = T.Accent,
                Text = opts.Title or "primordial",
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
        })
        Library.Registry:Add(self.Header, "Bar", "BackgroundColor3")
        Library.Registry:Add(self.Header.SquareBottom, "Bar", "BackgroundColor3")

        -- barra de busqueda en el header (top-right): contenedor + icono separado del texto
        self.SearchBar = U.Create("Frame", {
            Parent = self.Header, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(220, 28), BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("ImageLabel", { Name = "Icon", BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0),
                Size = UDim2.fromOffset(14, 14), Image = "rbxassetid://6031154871", ImageColor3 = T.SubText }) })
        self.Search = U.Create("TextBox", { Parent = self.SearchBar, BackgroundTransparency = 1,
            Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -36, 1, 0), ClearTextOnFocus = false,
            Font = T.Font, TextSize = 13, TextColor3 = T.Text, Text = "",
            PlaceholderText = "Search...", PlaceholderColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
        Library.Registry:Add(self.SearchBar, "Surface2", "BackgroundColor3")

        -- separador accent bajo header
        U.Create("Frame", { Parent = self.Root, Position = UDim2.fromOffset(0, HEADERH),
            Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundColor3 = T.Accent })

        -- Category holder (franja inferior); esquinas inferiores redondeadas, superiores cuadradas
        self.CategoryHolder = U.Create("Frame", {
            Parent = self.Root, AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = T.Bar, BorderSizePixel = 0,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
            U.Create("Frame", { Name = "SquareTop", BorderSizePixel = 0, BackgroundColor3 = T.Bar,
                Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 10) }) })
        Library.Registry:Add(self.CategoryHolder, "Bar", "BackgroundColor3")
        Library.Registry:Add(self.CategoryHolder.SquareTop, "Bar", "BackgroundColor3")
        -- fila interna que ordena las categorias (fuera del cover)
        self.CategoryButtons = U.Create("Frame", { Parent = self.CategoryHolder,
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        }, { U.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 18) }) })
        -- linea de theme (accent) que separa el content de la barra de categorias
        local catLine = U.Create("Frame", { Parent = self.Root, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -56), Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = T.Accent })
        Library.Registry:Add(catLine, "Accent", "BackgroundColor3")

        -- Body (entre header y category holder)
        self.Body = U.Create("Frame", {
            Parent = self.Root, Position = UDim2.fromOffset(0, 65),
            Size = UDim2.new(1, 0, 1, -(65 + 56)), BackgroundTransparency = 1,
        })

        U.Drag(self.Header, self.Root, Library)
        return self
    end

    -- callback de la barra de busqueda del header
    function Window:OnSearch(fn)
        self._searchConn = self.Search:GetPropertyChangedSignal("Text"):Connect(function()
            fn(self.Search.Text)
        end)
        return self
    end

    function Window:AddCategory(name, icon)
        if not P.CategoryBar then warn("PrimordialUI: CategoryBar ausente"); return nil end
        local cat = P.CategoryBar.new(self, name, icon)
        table.insert(self.Categories, cat)
        if not self.ActiveCategory then self:SetActiveCategory(cat) end
        return cat
    end

    function Window:SetActiveCategory(cat)
        if self.Library.CloseActivePopup then self.Library:CloseActivePopup() end
        for _, c in ipairs(self.Categories) do c:SetActive(c == cat) end
        self.ActiveCategory = cat
    end

    -- categoria estandar para configurar la UI (accent, DPI, keybind, watermark, themes, configs, unload)
    function Window:AddSettingsTab(name)
        local Lib = self.Library
        local cat = self:AddCategory(name or "Settings", "settings")
        local sec = cat:AddSection("Configuration", "Configure the UI")

        -- no guardar los widgets del settings tab en las configs del usuario
        for _, f in ipairs({ "UIAccent", "UIDPIScale", "UIMenuKey", "UIWatermark", "UIWatermarkText",
            "UITheme", "UIKeybindList", "UIConfigName", "UIConfigList", "UIAutoload" }) do
            if Lib.ConfigIgnore then Lib.ConfigIgnore[f] = true end
        end

        local menu = sec:AddPanel("Menu", { Column = 1 })
        menu:AddColorPicker("UIAccent", { Text = "Accent Color", Default = T.Accent,
            Callback = function(c) Lib:SetTheme({ Accent = c }) end })
        if Lib.ListThemePresets then
            menu:AddDropdown("UITheme", { Text = "Theme Preset", Values = Lib:ListThemePresets(), Default = "Default",
                Callback = function(v) Lib:ApplyThemePreset(v) end })
        end
        menu:AddSlider("UIDPIScale", { Text = "DPI Scale", Min = 50, Max = 200, Default = 100, Suffix = "%",
            Callback = function(v) Lib:SetDPIScale(v) end })
        menu:AddKeybind("UIMenuKey", { Text = "Menu Keybind", Default = Lib.ToggleKey, NoUI = true,
            BindCallback = function(k) Lib.ToggleKey = k end })
        if Lib.SetKeybindListVisibility then
            menu:AddToggle("UIKeybindList", { Text = "Show Keybind List", Default = false,
                Callback = function(v) Lib:SetKeybindListVisibility(v) end })
        end
        menu:AddDivider()
        menu:AddButton("Unload", function() Lib:Unload() end)

        local wm = sec:AddPanel("Watermark", { Column = 2 })
        wm:AddToggle("UIWatermark", { Text = "Show Watermark", Default = false,
            Callback = function(v) Lib:SetWatermarkVisibility(v) end })
        wm:AddTextBox("UIWatermarkText", { Text = "Watermark Text", Default = "primordial",
            Placeholder = "text", Callback = function(t) if Lib.Flags.UIWatermark then Lib:SetWatermark(t) end end })

        -- Config manager (save/load)
        if Lib.SaveConfig then
            local cfg = sec:AddPanel("Configs", { Column = 2 })
            cfg:AddTextBox("UIConfigName", { Text = "Config Name", Placeholder = "my config" })
            local list = cfg:AddDropdown("UIConfigList", { Text = "Saved", Values = Lib:ListConfigs(), AllowNull = true })
            local function refresh() list:SetValues(Lib:ListConfigs()) end
            cfg:AddButton("Save", function()
                local n = Lib.Flags.UIConfigName
                if n and n ~= "" and Lib:SaveConfig(n) then refresh(); Lib:Notify("Config saved: " .. n, 3)
                else Lib:Notify("Enter a config name", 3) end
            end)
            cfg:AddButton("Load", function()
                local n = Lib.Flags.UIConfigList
                if n and Lib:LoadConfigFile(n) then Lib:Notify("Config loaded: " .. n, 3) end
            end)
            cfg:AddButton("Delete", function()
                local n = Lib.Flags.UIConfigList
                if n then Lib:DeleteConfig(n); refresh(); Lib:Notify("Config deleted: " .. n, 3) end
            end)
            cfg:AddToggle("UIAutoload", { Text = "Autoload selected", Default = Lib:GetAutoloadConfig() ~= nil,
                Callback = function(v) Lib:SetAutoloadConfig(v and Lib.Flags.UIConfigList or "") end })
        end
        return cat
    end

    function Window:SetVisible(b) self.Root.Visible = b end
    function Window:Destroy() self.Gui:Destroy() end

    P.Window = Window
end

end)(); __m(P) end
-- ==== Chrome/CategoryBar ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Category = {}
    Category.__index = Category

    function Category.new(Window, name, icon)
        local self = setmetatable({ Window = Window, Name = name, Sections = {}, ActiveSection = nil }, Category)

        -- botón en la franja inferior (icono + label)
        self.Button = U.Create("TextButton", {
            Parent = Window.CategoryButtons, AutoButtonColor = false,
            BackgroundTransparency = 1, Size = UDim2.fromOffset(72, 52), Text = "",
        }, {
            U.Create("Frame", { Name = "Hi", BackgroundColor3 = T.Surface3,
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) },
                { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }) }),
            U.Create("ImageLabel", {
                Name = "Icon", BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4),
                Size = UDim2.fromOffset(24, 24), Image = "",
                ImageColor3 = T.SubText,
            }),
            U.Create("TextLabel", {
                Name = "Label", BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 16), Font = T.Font, TextSize = 12,
                Text = name, TextColor3 = T.SubText,
            }),
        })

        -- icono: nombre Lucide ("crosshair") o rbxassetid
        if P.Icons then P.Icons.apply(self.Button.Icon, icon)
        elseif icon then self.Button.Icon.Image = icon end

        -- página de contenido
        self.Page = U.Create("Frame", {
            Parent = Window.Body, Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, Visible = false,
        })
        self.Sidebar = U.Create("Frame", {
            Parent = self.Page, Size = UDim2.new(0, 172, 1, 0),
            BackgroundColor3 = T.Sidebar, BorderSizePixel = 0, ClipsDescendants = true,
        }, { U.Create("UIListLayout", { Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8) }) })
        Window.Library.Registry:Add(self.Sidebar, "Sidebar", "BackgroundColor3")
        self.Content = U.Create("Frame", {
            Parent = self.Page, Position = UDim2.fromOffset(180, 8),
            Size = UDim2.new(1, -188, 1, -16), BackgroundTransparency = 1,
        })
        -- separador vertical entre sidebar y content, con sombra suave
        U.Create("Frame", { Parent = self.Page, BorderSizePixel = 0,
            Position = UDim2.fromOffset(172, 0), Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = T.Border })
        U.Create("Frame", { Parent = self.Page, BorderSizePixel = 0,
            Position = UDim2.fromOffset(173, 0), Size = UDim2.new(0, 8, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0) },
            { U.Create("UIGradient", { Rotation = 0, Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6),
                NumberSequenceKeypoint.new(1, 1) }) }) })

        self.Button.MouseButton1Click:Connect(function()
            Window:SetActiveCategory(self)
        end)
        return self
    end

    function Category:AddSection(title, subtitle, opts)
        if not P.Section then warn("PrimordialUI: Section ausente"); return nil end
        local s = P.Section.new(self, title, subtitle, opts)
        table.insert(self.Sections, s)
        if not self.ActiveSection then self:SetActiveSection(s) end
        return s
    end

    function Category:SetActiveSection(s)
        local Lib = self.Window.Library
        if Lib.CloseActivePopup then Lib:CloseActivePopup() end
        for _, sec in ipairs(self.Sections) do sec:SetActive(sec == s) end
        self.ActiveSection = s
    end

    function Category:SetActive(b)
        self.Page.Visible = b
        self.Button.Hi.BackgroundTransparency = b and 0.55 or 1
        self.Button.Icon.ImageColor3 = b and T.Accent or T.SubText
        self.Button.Label.TextColor3 = b and T.Text or T.SubText
    end

    P.Category = Category
    P.CategoryBar = Category  -- alias esperado por Window
end

end)(); __m(P) end
-- ==== Chrome/Section ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Section = {}
    Section.__index = Section

    -- crea un set de N columnas (scrolling) dentro de parent, offset yOff arriba
    local function makeBoardSet(parent, yOff, nCols)
        nCols = nCols or 2
        local gap = 8
        local board = U.Create("Frame", { Parent = parent, BackgroundTransparency = 1, Visible = false,
            Position = UDim2.fromOffset(0, yOff), Size = UDim2.new(1, 0, 1, -yOff),
        }, { U.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }) })
        local cols = {}
        local off = -(gap * (nCols - 1) / nCols)
        for i = 1, nCols do
            cols[i] = U.Create("ScrollingFrame", { Parent = board, LayoutOrder = i,
                Size = UDim2.new(1 / nCols, off, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y,
            }, { U.Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
                U.Create("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 2), PaddingRight = UDim.new(0, 5) }) })
        end
        return board, cols
    end

    function Section.new(Category, title, subtitle, opts)
        opts = opts or {}
        local self = setmetatable({ Category = Category, Panels = {}, Columns = {}, HasTabs = false,
            NumCols = math.clamp(opts.Columns or 2, 1, 4) }, Section)

        self.Button = U.Create("TextButton", {
            Parent = Category.Sidebar, AutoButtonColor = false, Text = "",
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44),
        }, {
            U.Create("Frame", { Name = "Hi", BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(-8, 0),
            }, { U.Create("UIGradient", { Rotation = 0, Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.7),
                NumberSequenceKeypoint.new(0.65, 0.9),
                NumberSequenceKeypoint.new(1, 1) }) }) }),
            U.Create("Frame", { Name = "Bar", BackgroundColor3 = T.Accent, BorderSizePixel = 0,
                Position = UDim2.fromOffset(-8, 0), Size = UDim2.new(0, 2, 1, 0), Visible = false }),
            U.Create("TextLabel", { Name = "Title", BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 16),
                Font = T.FontBold, TextSize = 14, Text = title, TextColor3 = T.SubText,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }),
            U.Create("TextLabel", { Name = "Sub", BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 22), Size = UDim2.new(1, -16, 0, 14),
                Font = T.Font, TextSize = 12, Text = subtitle or "", TextColor3 = T.SubText,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }),
        })

        -- raiz de contenido (toggle por SetActive)
        self.Board = U.Create("Frame", { Parent = Category.Content, Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1, Visible = false })
        -- set de columnas por defecto (sin content-tabs)
        local b, c = makeBoardSet(self.Board, 0, self.NumCols)
        b.Visible = true
        self._defaultBoard = b
        self.Columns = c
        self._activeCols = c

        self.Button.MouseButton1Click:Connect(function()
            Category:SetActiveSection(self)
        end)
        return self
    end

    -- content-tabs de arma que abarcan AMBAS columnas (Rifles/Pistols/...)
    -- opts.PerRow = cuantos tabs por fila (default: todos en 1 fila). Envuelve en varias filas.
    function Section:AddTabs(list, opts)
        opts = opts or {}
        self.HasTabs = true
        self._defaultBoard.Visible = false
        self._tabBoards = {}
        self._tabOrder = list

        local n = #list
        local perRow = math.max(1, math.min(opts.PerRow or n, n))
        local rowH = 28
        local rows = math.ceil(n / perRow)
        local barH = rows * rowH

        self.TabBar = U.Create("Frame", { Parent = self.Board, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, barH),
        }, { U.Create("UIGridLayout", { CellSize = UDim2.new(1 / perRow, 0, 0, rowH),
            CellPadding = UDim2.fromOffset(0, 0), FillDirectionMaxCells = perRow,
            SortOrder = Enum.SortOrder.LayoutOrder }) })
        -- separador bajo la barra de tabs
        U.Create("Frame", { Parent = self.Board, Position = UDim2.fromOffset(0, barH),
            Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundColor3 = T.Border })

        for i, name in ipairs(list) do
            local btn = U.Create("TextButton", { Parent = self.TabBar, AutoButtonColor = false,
                BackgroundTransparency = 1, LayoutOrder = i,
                Font = T.FontBold, TextSize = 13, Text = name, TextColor3 = T.SubText,
            }, { U.Create("Frame", { Name = "UL", BorderSizePixel = 0, BackgroundColor3 = T.Accent,
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(0, 40, 0, 2), Visible = false }) })
            local board, cols = makeBoardSet(self.Board, barH + 4, self.NumCols)
            self._tabBoards[name] = { board = board, cols = cols, btn = btn }
            btn.MouseButton1Click:Connect(function() self:SetContentTab(name) end)
        end
        self:SetContentTab(list[1])
        return self
    end

    function Section:SetContentTab(name)
        local Lib = self.Category.Window.Library
        if Lib.CloseActivePopup then Lib:CloseActivePopup() end
        for n, t in pairs(self._tabBoards) do
            local on = n == name
            t.board.Visible = on
            t.btn.TextColor3 = on and T.Accent or T.SubText
            t.btn.UL.Visible = on
        end
        self._activeCols = self._tabBoards[name].cols
        self._activeTab = name
    end

    function Section:AddPanel(title, opts)
        opts = opts or {}
        local col = opts.Column
        if not col then col = (#self.Panels % self.NumCols) + 1 end
        col = math.clamp(col, 1, self.NumCols)
        local cols = self.Columns
        if self.HasTabs then
            local tab = opts.Tab or self._activeTab
            local tb = self._tabBoards[tab]
            cols = (tb and tb.cols) or self._activeCols
        end
        if not P.Panel then warn("PrimordialUI: Panel ausente"); return nil end
        local p = P.Panel.new(self, cols[col], title, opts)
        table.insert(self.Panels, p)
        return p
    end

    function Section:SetActive(b)
        self.Board.Visible = b
        self.Button.Bar.Visible = b
        self.Button.Hi.BackgroundTransparency = b and 0 or 1
        self.Button.Title.TextColor3 = b and T.Text or T.SubText
    end

    P.Section = Section
end

end)(); __m(P) end
-- ==== Chrome/Panel ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Panel = {}
    Panel.__index = Panel

    function Panel.new(Section, columnFrame, title, opts)
        local self = setmetatable({
            Section = Section,
            Library = Section.Category.Window.Library,
            _widgets = {}, Tabs = nil,
        }, Panel)

        local HH = 26 -- alto header (compacto)
        -- alto FIJO ligado al Body (no AutomaticSize) para que la sombra offset no lo infle
        self.Frame = U.Create("Frame", {
            Parent = columnFrame, Size = UDim2.new(1, 0, 0, HH + 1), ClipsDescendants = false,
            BackgroundColor3 = T.Surface, BorderSizePixel = 0, LayoutOrder = #Section.Panels + 1,
        }, {
            U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            -- gradiente sutil de profundidad (arriba mas claro -> abajo mas oscuro)
            U.Create("UIGradient", { Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(224, 224, 228)),
                }) }),
        })
        self.Library.Registry:Add(self.Frame, "Surface", "BackgroundColor3")

        -- sombra externa suave (Frame no es AutomaticSize => segura)
        U.Shadow(self.Frame, { Spread = 18, Transparency = 0.78, YOffset = 4 })

        self.Header = U.Create("TextLabel", {
            Parent = self.Frame, BackgroundTransparency = 1,
            Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 0, HH),
            Font = T.FontBold, TextSize = 13, Text = title, TextColor3 = T.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        -- separador bajo el titulo: color principal (accent)
        local sep = U.Create("Frame", { Parent = self.Frame, Position = UDim2.fromOffset(0, HH),
            Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundColor3 = T.Accent })
        self.Library.Registry:Add(sep, "Accent", "BackgroundColor3")

        self.Body = U.Create("Frame", {
            Parent = self.Frame, Position = UDim2.fromOffset(0, HH + 1),
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        }, {
            U.Create("UIListLayout", { Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
        })

        -- ligar alto del Frame al contenido del Body
        local function resize()
            self.Frame.Size = UDim2.new(1, 0, 0, (HH + 1) + self.Body.AbsoluteSize.Y)
        end
        self.Library:Maid(self.Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
        resize()
        return self
    end

    function Panel:_rowParent()
        if self.Tabs then return self.Tabs:ActiveContent() end
        return self.Body
    end

    local function widgetAdder(moduleKey)
        return function(self, flag, o)
            if not P[moduleKey] then warn("PrimordialUI: "..moduleKey.." ausente"); return nil end
            local W = P[moduleKey].new(self, flag, o or {})
            table.insert(self._widgets, W)
            return W
        end
    end
    Panel.AddToggle   = widgetAdder("Toggle")
    Panel.AddSlider   = widgetAdder("Slider")
    Panel.AddDropdown = widgetAdder("Dropdown")
    Panel.AddKeybind  = widgetAdder("Keybind")
    Panel.AddTextBox  = widgetAdder("TextBox")
    Panel.AddColorPicker = widgetAdder("ColorPicker")
    Panel.AddList        = widgetAdder("List")

    function Panel:AddButton(text, cb, opts)
        if not P.Button then return nil end
        opts = opts or {}
        local W = P.Button.new(self, nil, { Text = text, Callback = cb, DoubleClick = opts.DoubleClick })
        table.insert(self._widgets, W); return W
    end
    function Panel:AddLabel(text, opts)
        if not P.Label then return nil end
        local W = P.Label.new(self, nil, { Text = text, Header = opts and opts.Header })
        table.insert(self._widgets, W); return W
    end
    function Panel:AddDivider()
        if not P.Divider then return nil end
        local W = P.Divider.new(self, nil, {})
        table.insert(self._widgets, W); return W
    end
    function Panel:AddTabs(list)
        if not P.PanelTabs then return nil end
        self.Tabs = P.PanelTabs.new(self, list); return self.Tabs
    end
    function Panel:AddViewport(opts)
        if not P.Viewport then return nil end
        local W = P.Viewport.new(self, opts or {})
        table.insert(self._widgets, W); return W
    end
    function Panel:AddGrid(opts)
        if not P.Grid then return nil end
        local W = P.Grid.new(self, opts or {})
        table.insert(self._widgets, W); return W
    end

    P.Panel = Panel
end

end)(); __m(P) end
-- ==== Chrome/PanelTabs ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local PanelTabs = {}
    PanelTabs.__index = PanelTabs

    function PanelTabs.new(Panel, list)
        local self = setmetatable({ Panel = Panel, Tabs = {}, Contents = {}, Active = nil }, PanelTabs)

        self.Bar = U.Create("Frame", { Parent = Panel.Body, Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1, LayoutOrder = 0,
        }, { U.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

        for i, name in ipairs(list) do
            local btn = U.Create("TextButton", { Parent = self.Bar, AutoButtonColor = false,
                BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 1, 0), Font = T.FontBold, TextSize = 13,
                Text = name, TextColor3 = T.SubText, LayoutOrder = i,
            }, { U.Create("Frame", { Name = "UL", BorderSizePixel = 0, BackgroundColor3 = T.Accent,
                AnchorPoint = Vector2.new(0.5,1), Position = UDim2.new(0.5,0,1,0),
                Size = UDim2.new(1,0,0,2), Visible = false }) })
            local content = U.Create("Frame", { Parent = Panel.Body, LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, Visible = false,
            }, { U.Create("UIListLayout", { Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder }) })
            self.Tabs[name] = btn; self.Contents[name] = content
            btn.MouseButton1Click:Connect(function() self:SetActive(name) end)
            if i == 1 then self:SetActive(name) end
        end
        return self
    end

    function PanelTabs:SetActive(name)
        local Lib = self.Panel.Library
        if Lib and Lib.CloseActivePopup then Lib:CloseActivePopup() end
        for n, btn in pairs(self.Tabs) do
            local on = n == name
            btn.TextColor3 = on and T.Accent or T.SubText
            btn.UL.Visible = on
            self.Contents[n].Visible = on
        end
        self.Active = name
    end

    function PanelTabs:ActiveContent() return self.Contents[self.Active] end

    P.PanelTabs = PanelTabs
end

end)(); __m(P) end
-- ==== Widgets/_Base ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Base = {}
    Base.__index = Base

    function Base.new(Panel, opts)
        local self = setmetatable({
            Panel = Panel, Library = Panel.Library,
            Changed = P.Signal.new(), _deps = {},
        }, Base)
        local h = opts.Height or T.RowH
        self.Row = U.Create("Frame", {
            Parent = Panel:_rowParent(), Size = UDim2.new(1, 0, 0, h),
            BackgroundTransparency = 1, LayoutOrder = #Panel._widgets + 10,
        })
        if opts.LabelText ~= nil then
            self.Label = U.Create("TextLabel", { Parent = self.Row, BackgroundTransparency = 1,
                Size = UDim2.new(1, -120, 1, 0), Font = T.Font, TextSize = T.TextSize,
                Text = opts.LabelText, TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center })
            self.Library.Registry:Add(self.Label, "Text", "TextColor3")
        end
        self.Control = U.Create("Frame", { Parent = self.Row,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 110, 1, 0), BackgroundTransparency = 1 })
        if opts.Tooltip and self.Library.ShowTooltip then
            self.Row.MouseEnter:Connect(function() self.Library:ShowTooltip(opts.Tooltip) end)
            self.Row.MouseMoved:Connect(function() self.Library:MoveTooltip() end)
            self.Row.MouseLeave:Connect(function() self.Library:HideTooltip() end)
        end
        return self
    end

    function Base:SetVisible(b) self.Row.Visible = b end

    function Base:_evalDeps()
        local vis = true
        for _, d in ipairs(self._deps) do
            if self.Library.Flags[d.flag] ~= d.expected then vis = false break end
        end
        self:SetVisible(vis)
    end

    function Base:DependsOn(flag, expected)
        table.insert(self._deps, { flag = flag, expected = expected })
        self.Library:GetFlagSignal(flag):Connect(function() self:_evalDeps() end)
        self:_evalDeps()
        return self._widget or self
    end

    function Base:OnChanged(fn)
        self.Changed:Connect(fn)
        return self._widget or self
    end

    P.Base = Base
end

end)(); __m(P) end
-- ==== Widgets/Toggle ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Toggle = {}
    Toggle.__index = Toggle

    function Toggle.new(Panel, flag, opts)
        -- checkbox a la IZQUIERDA + label despues (estilo primordial)
        local base = P.Base.new(Panel, { LabelText = nil, Height = 22, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Panel = Panel, Library = Panel.Library,
            Flag = flag, Value = opts.Default and true or false, Callback = opts.Callback }, Toggle)
        base._widget = self

        self.Box = U.Create("TextButton", { Parent = base.Row, AutoButtonColor = false,
            Text = "", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0.5, 0),
            Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Surface2,
        }, {
            U.Create("UICorner", { CornerRadius = UDim.new(0, 3) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("UIGradient", { Name = "Depth", Rotation = 90, Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.new(0.82, 0.82, 0.82)) }) }),
            U.Create("ImageLabel", { Name = "Check", BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.82, 0.82), Image = "rbxassetid://6031094667",
                ImageColor3 = Color3.fromRGB(18, 18, 20), ImageTransparency = 1 }),
        })
        self.Label = U.Create("TextLabel", { Parent = base.Row, BackgroundTransparency = 1,
            Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -140, 1, 0),
            Font = T.Font, TextSize = T.TextSize, Text = opts.Text or flag, TextColor3 = T.Text,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center })

        self.Box.MouseButton1Click:Connect(function() self:SetValue(not self.Value) end)
        self.Library.Toggles[flag] = self
        self:_render()
        self.Library:SetFlag(flag, self.Value)
        return self
    end

    function Toggle:_render()
        self.Box.BackgroundColor3 = self.Value and T.Accent or T.Surface2
        self.Box.Check.ImageTransparency = self.Value and 0 or 1
        -- texto atenuado cuando esta apagado
        self.Label.TextColor3 = self.Value and T.Text or Color3.fromRGB(150, 150, 157)
    end

    function Toggle:SetValue(v)
        v = v and true or false
        if v == self.Value then return end
        self.Value = v; self:_render()
        self.Library:SetFlag(self.Flag, v)
        self._base.Changed:Fire(v)
        if self.Callback then task.spawn(self.Callback, v) end
    end
    function Toggle:GetValue() return self.Value end
    -- adjunta un swatch de color a la fila del toggle (patron Hitmarker); apilable
    function Toggle:AddColorPicker(flag, opts)
        if not P.ColorPicker then return self end
        self._cpCount = (self._cpCount or 0) + 1
        local xOffset = -(24 + (self._cpCount - 1) * 34)  -- deja lugar al checkbox + apila
        P.ColorPicker._attach(self.Library, self._base.Control, flag, opts or {}, xOffset)
        return self
    end
    -- adjunta un keybind COMPACTO inline a la fila del toggle: la tecla BINDEA el toggle (Toggle/Hold).
    -- La caja "[Key]" queda a la derecha (junto al toggle, no texto abajo). Chainable.
    function Toggle:AddKeybind(opts)
        opts = opts or {}
        local UIS = game:GetService("UserInputService")
        local Lib = self.Library
        local bindFlag = self.Flag .. "Bind"
        self._bindMode = opts.Mode or "Toggle"
        self._bindKey = opts.Default
        local function kn(kc) return kc and kc.Name or "None" end
        local btn = U.Create("TextButton", { Parent = self._base.Control, AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(70, 18), BackgroundColor3 = T.Surface2,
            Font = T.Font, TextSize = 11, TextColor3 = T.Text, Text = "[" .. kn(self._bindKey) .. "]",
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
             U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }) })
        self._bindBtn = btn
        local capturing = false
        btn.MouseButton1Click:Connect(function() capturing = true; btn.Text = "[...]" end)
        Lib:Maid(UIS.InputBegan:Connect(function(inp, gpe)
            if capturing and inp.KeyCode ~= Enum.KeyCode.Unknown then
                capturing = false; self._bindKey = inp.KeyCode
                btn.Text = "[" .. kn(inp.KeyCode) .. "]"; Lib.Flags[bindFlag] = inp.KeyCode
                return
            end
            if not gpe and self._bindKey and inp.KeyCode == self._bindKey then
                if self._bindMode == "Toggle" then self:SetValue(not self.Value)
                elseif self._bindMode == "Hold" then self:SetValue(true) end
            end
        end))
        Lib:Maid(UIS.InputEnded:Connect(function(inp)
            if self._bindMode == "Hold" and self._bindKey and inp.KeyCode == self._bindKey then self:SetValue(false) end
        end))
        -- right-click en la caja -> ventanita al lado: Always / Hold / Toggle
        local popup
        local function closePopup()
            if popup then popup:Destroy(); popup = nil end
            Lib:ClosePopup(self._modeCloser)
        end
        self._modeCloser = function() closePopup() end
        btn.MouseButton2Click:Connect(function()
            if popup then closePopup(); return end
            Lib:OpenPopup(self._modeCloser)
            local gui = btn:FindFirstAncestorWhichIsA("ScreenGui")
            local ap = btn.AbsolutePosition
            popup = U.Create("Frame", { Parent = gui, ZIndex = 60,
                Position = UDim2.fromOffset(ap.X, ap.Y + 22), Size = UDim2.fromOffset(80, 66),
                BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
            }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
                 U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }),
                 U.Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
                 U.Create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
                     PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3) }) })
            for _, m in ipairs({ "Always", "Hold", "Toggle" }) do
                local ob = U.Create("TextButton", { Parent = popup, ZIndex = 61, AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = (self._bindMode == m) and T.Accent or T.Bar,
                    Font = T.Font, TextSize = 12, TextColor3 = T.Text, Text = m,
                }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }) })
                ob.MouseButton1Click:Connect(function()
                    self._bindMode = m
                    Lib.Flags[self.Flag .. "BindMode"] = m
                    if m == "Always" then self:SetValue(true) end
                    closePopup()
                end)
            end
        end)
        Lib.Flags[bindFlag] = self._bindKey
        Lib.Flags[self.Flag .. "BindMode"] = self._bindMode
        return self
    end
    function Toggle:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Toggle:OnChanged(fn) self._base:OnChanged(fn); return self end
    function Toggle:SetVisible(b) self._base:SetVisible(b) end

    P.Toggle = Toggle
end

end)(); __m(P) end
-- ==== Widgets/Slider ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local UIS = game:GetService("UserInputService")
    local Slider = {}
    Slider.__index = Slider

    function Slider.new(Panel, flag, opts)
        local base = P.Base.new(Panel, { LabelText = nil, Height = 40, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Library = Panel.Library, Flag = flag,
            Min = opts.Min or 0, Max = opts.Max or 100, Decimals = opts.Decimals or 0,
            Suffix = opts.Suffix or "", Prefix = opts.Prefix or "", OffAtMin = opts.OffAtMin,
            Callback = opts.Callback }, Slider)
        base._widget = self
        base.Control.Visible = false

        -- linea superior: nombre + box de valor pegado al lado
        local topRow = U.Create("Frame", { Parent = base.Row, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
        }, { U.Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

        U.Create("TextLabel", { Parent = topRow, BackgroundTransparency = 1, LayoutOrder = 1,
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
            Font = T.FontBold, TextSize = T.TextSize, Text = opts.Text or flag,
            TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left })

        self.ValBox = U.Create("Frame", { Parent = topRow, LayoutOrder = 2,
            AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 15),
            BackgroundColor3 = T.Surface2,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            U.Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
            U.Create("TextLabel", { Name = "V", BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
                Font = T.Font, TextSize = 12, Text = "", TextColor3 = T.SubText,
                TextYAlignment = Enum.TextYAlignment.Center }) })
        self.ValLabel = self.ValBox.V

        -- track con fill (gradient de textura) + perilla
        self.Track = U.Create("TextButton", { Parent = base.Row, Text = "", AutoButtonColor = false,
            Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 8),
            BackgroundColor3 = T.Surface2,
        }, {
            U.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
            U.Create("Frame", { Name = "Fill", BorderSizePixel = 0, BackgroundColor3 = T.Accent,
                Size = UDim2.new(0, 0, 1, 0) }, {
                U.Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                U.Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.15),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(1, 0.2) }) }),
            }),
        })
        -- perilla deslizable GRIS con textura (gradient vertical claro->oscuro)
        self.Knob = U.Create("Frame", { Parent = self.Track, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(7, 13),
            BackgroundColor3 = T.Knob, ZIndex = 3,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
            U.Create("UIStroke", { Color = Color3.fromRGB(20,20,22), Transparency = 0.5, Thickness = 1 }),
            U.Create("UIGradient", { Rotation = 90, Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(235,235,238)),
                ColorSequenceKeypoint.new(0.5, T.Knob),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(150,150,156)) }) }) })
        U.Depth(self.Track, { Bottom = 0.18 })
        U.Depth(self.ValBox, { Bottom = 0.12 })
        base.Control.Visible = false

        local function setFromX(px)
            local abs = self.Track.AbsolutePosition.X
            local w = self.Track.AbsoluteSize.X
            local a = math.clamp((px - abs) / w, 0, 1)
            self:SetValue(self.Min + a * (self.Max - self.Min))
        end
        local dragging = false
        self.Track.MouseButton1Down:Connect(function() dragging = true
            setFromX(UIS:GetMouseLocation().X) end)
        self.Library:Maid(UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end))
        self.Library:Maid(UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                setFromX(UIS:GetMouseLocation().X) end end))

        self.Library.Options[flag] = self
        self:SetValue(opts.Default ~= nil and opts.Default or self.Min)
        return self
    end

    function Slider:_fmt(v)
        if self.OffAtMin and v <= self.Min then return "Off" end
        local num
        if self.Decimals > 0 then
            num = string.format("%." .. self.Decimals .. "f", v)
        else
            num = tostring(math.floor(v + 0.5))
        end
        return self.Prefix .. num .. self.Suffix
    end

    function Slider:SetValue(v)
        v = math.clamp(v, self.Min, self.Max)
        if self.Decimals == 0 then v = math.floor(v + 0.5) end
        self.Value = v
        local a = (v - self.Min) / (self.Max - self.Min)
        self.Track.Fill.Size = UDim2.new(a, 0, 1, 0)
        self.Knob.Position = UDim2.new(a, 0, 0.5, 0)
        self.ValLabel.Text = self:_fmt(v)
        self.Library:SetFlag(self.Flag, v)
        self._base.Changed:Fire(v)
        if self.Callback then task.spawn(self.Callback, v) end
    end
    function Slider:GetValue() return self.Value end
    function Slider:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Slider:OnChanged(fn) self._base:OnChanged(fn); return self end
    function Slider:SetVisible(b) self._base:SetVisible(b) end

    P.Slider = Slider
end

end)(); __m(P) end
-- ==== Widgets/Dropdown ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Dropdown = {}
    Dropdown.__index = Dropdown

    local function hamburger(parent)
        local f = U.Create("Frame", { Parent = parent, Name = "Ham", BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.fromOffset(14, 11) })
        for i = 0, 2 do
            U.Create("Frame", { Parent = f, BorderSizePixel = 0, BackgroundColor3 = T.SubText,
                Position = UDim2.new(0, 0, 0, i * 5), Size = UDim2.new(1, 0, 0, 1.5) })
        end
        return f
    end

    function Dropdown.new(Panel, flag, opts)
        local base = P.Base.new(Panel, { LabelText = nil, Height = 46, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Library = Panel.Library, Flag = flag,
            Values = opts.Values or {}, AllowNull = opts.AllowNull, Callback = opts.Callback,
            Multi = opts.Multi and true or false, Searchable = opts.Searchable and true or false,
            Open = false }, Dropdown)
        base._widget = self
        base.Control.Visible = false

        self.Title = U.Create("TextLabel", { Parent = base.Row, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16), Font = T.FontBold, TextSize = T.TextSize,
            Text = opts.Text or flag, TextColor3 = T.SubText,
            TextXAlignment = Enum.TextXAlignment.Left })

        self.DControl = U.Create("TextButton", { Parent = base.Row, Text = "", AutoButtonColor = false,
            Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = T.Surface2,
        }, {
            U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("TextLabel", { Name = "Val", BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -30, 1, 0),
                Font = T.Font, TextSize = T.TextSize, Text = "...", TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }),
        })
        U.Depth(self.DControl, { Highlight = true })
        if self.Multi then
            hamburger(self.DControl)
            self.Value = {}
        else
            U.Create("ImageLabel", { Parent = self.DControl, Name = "Chev", BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(14, 14), Image = "rbxassetid://6034818372",
                ImageColor3 = T.SubText })
        end
        self.DControl.MouseButton1Click:Connect(function() self:Toggle() end)

        self.Library.Options[flag] = self
        if self.Multi then
            local def = opts.Default
            if type(def) == "table" then for _, v in ipairs(def) do self.Value[v] = true end end
            self:_renderMulti()
            self.Library:SetFlag(flag, self:GetValue())
        else
            local def = opts.Default
            if def == nil and not self.AllowNull then def = self.Values[1] end
            self:SetValue(def)
        end
        return self
    end

    function Dropdown:_closePopup()
        if self.Popup then self.Popup:Destroy(); self.Popup = nil end
        self.Open = false
        self.Library:ClosePopup(self._closer)
    end

    function Dropdown:Toggle()
        if self.Open then self:_closePopup(); return end
        self._closer = self._closer or function() self:_closePopup() end
        self.Library:OpenPopup(self._closer)
        self.Open = true
        local gui = self.DControl:FindFirstAncestorWhichIsA("ScreenGui")
        local ap, sz = self.DControl.AbsolutePosition, self.DControl.AbsoluteSize
        local rows = math.min(#self.Values, 7)
        local searchH = self.Searchable and 26 or 0
        self.Popup = U.Create("Frame", { Parent = gui, ZIndex = 50,
            Position = UDim2.fromOffset(ap.X, ap.Y + sz.Y + 2),
            Size = UDim2.fromOffset(sz.X, rows * 24 + 4 + searchH), BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
            ClipsDescendants = true,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }) })
        local searchBox
        if self.Searchable then
            searchBox = U.Create("TextBox", { Parent = self.Popup, ZIndex = 52,
                Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 0, 20),
                BackgroundColor3 = T.Bg, ClearTextOnFocus = false, Font = T.Font, TextSize = 12,
                TextColor3 = T.Text, PlaceholderText = "Search...", PlaceholderColor3 = T.SubText,
                Text = "", TextXAlignment = Enum.TextXAlignment.Left,
            }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
                U.Create("UIPadding", { PaddingLeft = UDim.new(0, 6) }) })
        end
        local scroll = U.Create("ScrollingFrame", { Parent = self.Popup, ZIndex = 51,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, searchH), Size = UDim2.new(1, 0, 1, -searchH),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
        }, { U.Create("UIListLayout", {}), U.Create("UIPadding", {
            PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2) }) })

        local itemBtns = {}
        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchBox.Text:lower()
                for _, ib in ipairs(itemBtns) do
                    ib.btn.Visible = (q == "") or ib.name:lower():find(q, 1, true) ~= nil
                end
            end)
        end

        for _, v in ipairs(self.Values) do
            local sel = self.Multi and self.Value[v] or (v == self.Value)
            local it = U.Create("TextButton", { Parent = scroll, ZIndex = 52,
                BackgroundColor3 = T.Surface3, BackgroundTransparency = sel and 0.5 or 1,
                Size = UDim2.new(1, 0, 0, 24), AutoButtonColor = false,
                Font = T.Font, TextSize = T.TextSize, Text = "",
            }, { U.Create("TextLabel", { Name = "L", BackgroundTransparency = 1, ZIndex = 52,
                Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -12, 1, 0),
                Font = T.Font, TextSize = T.TextSize, Text = tostring(v),
                TextColor3 = sel and T.Accent or T.Text, TextXAlignment = Enum.TextXAlignment.Left }) })
            table.insert(itemBtns, { btn = it, name = tostring(v) })
            it.MouseButton1Click:Connect(function()
                if self.Multi then
                    self.Value[v] = (not self.Value[v]) or nil
                    it.BackgroundTransparency = self.Value[v] and 0.5 or 1
                    it.L.TextColor3 = self.Value[v] and T.Accent or T.Text
                    self:_renderMulti()
                    self.Library:SetFlag(self.Flag, self:GetValue())
                    self._base.Changed:Fire(self:GetValue())
                    if self.Callback then task.spawn(self.Callback, self:GetValue()) end
                else
                    self:SetValue(v); self:_closePopup()
                end
            end)
        end
    end

    function Dropdown:_renderMulti()
        local list = {}
        for _, v in ipairs(self.Values) do if self.Value[v] then table.insert(list, v) end end
        self.DControl.Val.Text = (#list == 0) and "None Selected" or table.concat(list, ", ")
        self.DControl.Val.TextColor3 = (#list == 0) and T.SubText or T.Text
    end

    function Dropdown:SetValue(v)
        if self.Multi then
            self.Value = {}
            if type(v) == "table" then for _, x in ipairs(v) do self.Value[x] = true end end
            self:_renderMulti()
            self.Library:SetFlag(self.Flag, self:GetValue())
        else
            self.Value = v
            self.DControl.Val.Text = v == nil and "None" or tostring(v)
            self.DControl.Val.TextColor3 = v == nil and T.SubText or T.Text
            self.Library:SetFlag(self.Flag, v)
        end
        self._base.Changed:Fire(self:GetValue())
        if self.Callback then task.spawn(self.Callback, self:GetValue()) end
    end

    function Dropdown:GetValue()
        if not self.Multi then return self.Value end
        local list = {}
        for _, v in ipairs(self.Values) do if self.Value[v] then table.insert(list, v) end end
        return list
    end
    function Dropdown:SetValues(list) self.Values = list end
    -- gear ⚙ a la derecha del titulo, abre un mini-panel de settings
    function Dropdown:AddGear()
        if not P.Gear then return nil end
        local g = P.Gear.new(self.Library)
        local icon = P.Gear.icon(self._base.Row)
        g:attachTo(icon)
        return g
    end
    function Dropdown:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Dropdown:OnChanged(fn) self._base:OnChanged(fn); return self end
    function Dropdown:SetVisible(b) self._base:SetVisible(b) end

    P.Dropdown = Dropdown
end

end)(); __m(P) end
-- ==== Widgets/Keybind ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local UIS = game:GetService("UserInputService")
    local Keybind = {}
    Keybind.__index = Keybind

    local function keyName(kc) return kc and kc.Name or "None" end

    function Keybind.new(Panel, flag, opts)
        local base = P.Base.new(Panel, { LabelText = opts.Text or flag, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Library = Panel.Library, Flag = flag,
            Mode = opts.Mode or "Toggle", Key = opts.Default, Capturing = false, Active = false,
            Callback = opts.Callback, BindCallback = opts.BindCallback }, Keybind)
        base._widget = self

        self.Btn = U.Create("TextButton", { Parent = base.Control, AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(96, 20), BackgroundColor3 = T.Surface2,
            Font = T.Font, TextSize = 12, TextColor3 = T.Text, Text = "Key: "..keyName(self.Key),
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }) })

        self.Btn.MouseButton1Click:Connect(function()
            self.Capturing = true; self.Btn.Text = "Key: ..."
        end)

        self.Library:Maid(UIS.InputBegan:Connect(function(inp, gpe)
            if self.Capturing and inp.KeyCode ~= Enum.KeyCode.Unknown then
                self.Capturing = false; self:SetKey(inp.KeyCode); return
            end
            if not gpe and self.Key and inp.KeyCode == self.Key then
                if self.Mode == "Toggle" then self:_setActive(not self.Active)
                elseif self.Mode == "Hold" then self:_setActive(true) end
            end
        end))
        self.Library:Maid(UIS.InputEnded:Connect(function(inp)
            if self.Mode == "Hold" and self.Key and inp.KeyCode == self.Key then
                self:_setActive(false)
            end
        end))

        self.Library.Options[flag] = self
        self.Library.Flags[flag] = self.Key
        if opts.NoUI ~= true and self.Library.RegisterKeybind then
            self._kbEntry = self.Library:RegisterKeybind(self)
        end
        if self.Mode == "Always" then self:_setActive(true) end
        return self
    end

    function Keybind:_setActive(v)
        self.Active = v
        self.Library.Flags[self.Flag.."Active"] = v
        if self._kbEntry then self._kbEntry:Update() end
        if self.Callback then task.spawn(self.Callback, v) end
        self._base.Changed:Fire(v)
    end
    function Keybind:SetKey(kc)
        self.Key = kc; self.Btn.Text = "Key: "..keyName(kc)
        self.Library.Flags[self.Flag] = kc
        if self._kbEntry then self._kbEntry:Update() end
        if self.BindCallback then task.spawn(self.BindCallback, kc) end
    end
    function Keybind:GetKey() return self.Key end
    function Keybind:SetValue(kc) self:SetKey(kc) end
    function Keybind:GetValue() return self.Key end
    function Keybind:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Keybind:OnChanged(fn) self._base:OnChanged(fn); return self end
    function Keybind:SetVisible(b) self._base:SetVisible(b) end

    P.Keybind = Keybind
end

end)(); __m(P) end
-- ==== Widgets/TextBox ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local TextBox = {}
    TextBox.__index = TextBox
    function TextBox.new(Panel, flag, opts)
        local base = P.Base.new(Panel, { LabelText = nil, Height = 46, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Library = Panel.Library, Flag = flag,
            Numeric = opts.Numeric, MaxLength = opts.MaxLength, Callback = opts.Callback }, TextBox)
        base._widget = self; base.Control.Visible = false
        U.Create("TextLabel", { Parent = base.Row, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16), Font = T.FontBold, TextSize = T.TextSize,
            Text = opts.Text or flag, TextColor3 = T.SubText,
            TextXAlignment = Enum.TextXAlignment.Left })
        self.Input = U.Create("TextBox", { Parent = base.Row, Position = UDim2.fromOffset(0, 20),
            Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Surface2, ClearTextOnFocus = false,
            Font = T.Font, TextSize = T.TextSize, TextColor3 = T.Text,
            PlaceholderText = opts.Placeholder or "Enter Text...", PlaceholderColor3 = T.SubText,
            Text = opts.Default or "", TextXAlignment = Enum.TextXAlignment.Left,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }),
            U.Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
        U.Depth(self.Input, { Highlight = true })
        self.Input:GetPropertyChangedSignal("Text"):Connect(function()
            local t = self.Input.Text
            if self.Numeric then t = t:gsub("[^%d%.%-]", "") end
            if self.MaxLength then t = t:sub(1, self.MaxLength) end
            if t ~= self.Input.Text then self.Input.Text = t end
            self:_set(t)
        end)
        self.Library.Options[flag] = self
        self:_set(opts.Default or "")
        return self
    end
    function TextBox:_set(t) self.Value = t; self.Library:SetFlag(self.Flag, t)
        self._base.Changed:Fire(t); if self.Callback then task.spawn(self.Callback, t) end end
    function TextBox:SetValue(t) self.Input.Text = t end
    function TextBox:GetValue() return self.Value end
    function TextBox:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function TextBox:OnChanged(fn) self._base:OnChanged(fn); return self end
    function TextBox:SetVisible(b) self._base:SetVisible(b) end
    P.TextBox = TextBox
end

end)(); __m(P) end
-- ==== Widgets/Button ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Button = {}
    Button.__index = Button
    function Button.new(Panel, _flag, opts)
        local base = P.Base.new(Panel, { LabelText = nil, Height = 30, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Callback = opts.Callback,
            Double = opts.DoubleClick, _last = 0 }, Button)
        base._widget = self; base.Control.Visible = false
        self.Btn = U.Create("TextButton", { Parent = base.Row, AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.Surface2,
            Font = T.FontBold, TextSize = T.TextSize, TextColor3 = T.Text, Text = opts.Text or "Button",
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }) })
        self.Btn.MouseEnter:Connect(function() self.Btn.BackgroundColor3 = T.AccentDim end)
        self.Btn.MouseLeave:Connect(function() self.Btn.BackgroundColor3 = T.Surface2 end)
        self.Btn.MouseButton1Click:Connect(function()
            if self.Double then
                local now = os.clock()
                if now - self._last > 0.4 then self._last = now; self.Btn.Text = "Are you sure?"; return end
                self.Btn.Text = opts.Text or "Button"
            end
            if self.Callback then task.spawn(self.Callback) end
        end)
        return self
    end
    function Button:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Button:SetVisible(b) self._base:SetVisible(b) end
    P.Button = Button
end

end)(); __m(P) end
-- ==== Widgets/Label ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Label = {}
    Label.__index = Label
    function Label.new(Panel, _flag, opts)
        local base = P.Base.new(Panel, { LabelText = nil, Height = opts.Header and 20 or 18 })
        local self = setmetatable({ _base = base }, Label)
        base._widget = self; base.Control.Visible = false
        self.Text = U.Create("TextLabel", { Parent = base.Row, BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1), Text = opts.Text or "",
            Font = opts.Header and T.FontBold or T.Font, TextSize = T.TextSize,
            TextColor3 = opts.Header and T.Text or T.SubText,
            TextXAlignment = Enum.TextXAlignment.Left })
        return self
    end
    function Label:SetText(t) self.Text.Text = t end
    function Label:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Label:SetVisible(b) self._base:SetVisible(b) end
    P.Label = Label
end

end)(); __m(P) end
-- ==== Widgets/Divider ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Divider = {}
    Divider.__index = Divider
    function Divider.new(Panel, _flag, _opts)
        local base = P.Base.new(Panel, { LabelText = nil, Height = 9 })
        local self = setmetatable({ _base = base }, Divider)
        base._widget = self; base.Control.Visible = false
        U.Create("Frame", { Parent = base.Row, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0, BackgroundColor3 = T.Outline })
        return self
    end
    function Divider:SetVisible(b) self._base:SetVisible(b) end
    P.Divider = Divider
end

end)(); __m(P) end
-- ==== Widgets/ColorPicker ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local UIS = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local function mouseXY()
        local m = UIS:GetMouseLocation()
        local ins = GuiService:GetGuiInset()
        return m.X - ins.X, m.Y - ins.Y
    end
    local CP = {}
    CP.__index = CP

    local RAINBOW = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.51, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.68, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
    })

    local function swatch(parent)
        return U.Create("TextButton", { Parent = parent, Text = "", AutoButtonColor = false,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(28, 14), BackgroundColor3 = Color3.new(1, 1, 1),
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }) })
    end

    -- Crea el swatch en un parent arbitrario (uso standalone o adjunto a toggle)
    function CP._attach(Library, parentControl, flag, opts, xOffset)
        local self = setmetatable({ Library = Library, Flag = flag, Callback = opts.Callback,
            Open = false }, CP)
        self.Swatch = swatch(parentControl)
        if xOffset then self.Swatch.Position = UDim2.new(1, xOffset, 0.5, 0) end
        local d = opts.Default or Color3.fromRGB(255, 0, 0)
        self.H, self.S, self.V = d:ToHSV()
        self.Swatch.MouseButton1Click:Connect(function() self:Toggle() end)
        Library.Options[flag] = self
        self:_apply()
        return self
    end

    function CP.new(Panel, flag, opts)
        local base = P.Base.new(Panel, { LabelText = opts.Text or flag })
        local self = CP._attach(Panel.Library, base.Control, flag, opts, nil)
        self._base = base
        base._widget = self
        return self
    end

    function CP:_color() return Color3.fromHSV(self.H, self.S, self.V) end

    function CP:_apply()
        local c = self:_color()
        self.Value = c                      -- expone .Value como Color3 (fresco) para leerlo directo
        self.Swatch.BackgroundColor3 = c
        self.Library:SetFlag(self.Flag, c)
        if self._base then self._base.Changed:Fire(c) end
        if self.Callback then task.spawn(self.Callback, c) end
    end

    function CP:SetColor(c) self.H, self.S, self.V = c:ToHSV(); self:_apply()
        if self.SVCursor then self:_syncCursors() end end
    function CP:GetColor() return self:_color() end
    function CP:SetValue(c) self:SetColor(c) end
    function CP:GetValue() return self:_color() end

    function CP:_syncCursors()
        self.SVCursor.Position = UDim2.new(self.S, 0, 1 - self.V, 0)
        self.SV.BackgroundColor3 = Color3.fromHSV(self.H, 1, 1)
        self.HueCursor.Position = UDim2.new(0.5, 0, self.H, 0)
    end

    function CP:_closePopup()
        if self._c1 then self._c1:Disconnect(); self._c1 = nil end
        if self._c2 then self._c2:Disconnect(); self._c2 = nil end
        if self.Popup then self.Popup:Destroy(); self.Popup = nil end
        self.Open = false
        self.Library:ClosePopup(self._closer)
    end

    function CP:Toggle()
        if self.Open then self:_closePopup(); return end
        self._closer = self._closer or function() self:_closePopup() end
        self.Library:OpenPopup(self._closer)
        self.Open = true
        local gui = self.Swatch:FindFirstAncestorWhichIsA("ScreenGui")
        local ap = self.Swatch.AbsolutePosition
        local PH = 150
        local py = ap.Y + 20
        if py + PH > gui.AbsoluteSize.Y - 8 then py = ap.Y - PH - 6 end  -- flip arriba si no cabe
        self.Popup = U.Create("Frame", { Parent = gui, ZIndex = 60,
            Position = UDim2.fromOffset(ap.X - 150, py),
            Size = UDim2.fromOffset(190, PH), BackgroundColor3 = T.Surface2, BorderSizePixel = 0,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Outline, Thickness = 1 }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8),
                PaddingBottom = UDim.new(0,8), PaddingRight = UDim.new(0,8) }) })

        -- cuadro SV (saturacion x, valor y)
        self.SV = U.Create("Frame", { Parent = self.Popup, ZIndex = 61,
            Size = UDim2.fromOffset(150, 134), BackgroundColor3 = Color3.fromHSV(self.H, 1, 1),
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            -- blanco horizontal (saturacion)
            U.Create("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.fromScale(1,1),
                ZIndex = 61 }, { U.Create("UICorner", { CornerRadius = UDim.new(0,4) }),
                U.Create("UIGradient", { Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }) }),
            -- negro vertical (valor)
            U.Create("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.fromScale(1,1),
                ZIndex = 62 }, { U.Create("UICorner", { CornerRadius = UDim.new(0,4) }),
                U.Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }) }),
        })
        self.SVBtn = U.Create("TextButton", { Parent = self.SV, Text = "", BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1), ZIndex = 64 })
        self.SVCursor = U.Create("Frame", { Parent = self.SV, ZIndex = 63,
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = Color3.new(1,1,1) },
            { U.Create("UICorner", { CornerRadius = UDim.new(1,0) }),
              U.Create("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }) })

        -- barra de hue vertical
        self.Hue = U.Create("TextButton", { Parent = self.Popup, Text = "", AutoButtonColor = false,
            ZIndex = 61, Position = UDim2.fromOffset(160, 0), Size = UDim2.fromOffset(14, 134),
            BackgroundColor3 = Color3.new(1,1,1),
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            U.Create("UIGradient", { Rotation = 90, Color = RAINBOW }) })
        self.HueCursor = U.Create("Frame", { Parent = self.Hue, ZIndex = 62,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, self.H, 0),
            Size = UDim2.new(1, 4, 0, 3), BackgroundColor3 = Color3.new(1,1,1) },
            { U.Create("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1 }) })

        self:_syncCursors()

        -- drag SV
        local function svFrom(px, py)
            local s = math.clamp((px - self.SV.AbsolutePosition.X) / self.SV.AbsoluteSize.X, 0, 1)
            local v = 1 - math.clamp((py - self.SV.AbsolutePosition.Y) / self.SV.AbsoluteSize.Y, 0, 1)
            self.S, self.V = s, v; self:_apply(); self:_syncCursors()
        end
        local function hueFrom(py)
            self.H = math.clamp((py - self.Hue.AbsolutePosition.Y) / self.Hue.AbsoluteSize.Y, 0, 1)
            self:_apply(); self:_syncCursors()
        end
        local svDrag, hueDrag = false, false
        self.SVBtn.MouseButton1Down:Connect(function() svDrag = true
            local mx, my = mouseXY(); svFrom(mx, my) end)
        self.Hue.MouseButton1Down:Connect(function() hueDrag = true
            local _, my = mouseXY(); hueFrom(my) end)
        self._c1 = UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag, hueDrag = false, false end end)
        self._c2 = UIS.InputChanged:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local mx, my = mouseXY()
            if svDrag then svFrom(mx, my) elseif hueDrag then hueFrom(my) end
        end)
    end

    function CP:DependsOn(f, e) if self._base then self._base:DependsOn(f, e) end; return self end
    function CP:OnChanged(fn) if self._base then self._base:OnChanged(fn) end; return self end
    function CP:SetVisible(b) if self._base then self._base:SetVisible(b) end end

    P.ColorPicker = CP
end

end)(); __m(P) end
-- ==== Widgets/Gear ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local UIS = game:GetService("UserInputService")
    local Gear = {}
    Gear.__index = Gear

    -- icono engranaje
    function Gear.icon(parent)
        return U.Create("ImageButton", { Parent = parent, Name = "Gear", BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(14, 14),
            Image = "rbxassetid://6031280882", ImageColor3 = T.SubText, ZIndex = 5 })
    end

    -- mini-panel flotante que imita la interfaz de Panel (para reusar los widgets)
    function Gear.new(Library)
        local self = setmetatable({ Library = Library, _widgets = {}, Open = false }, Gear)
        self.Popup = U.Create("Frame", { Visible = false, ZIndex = 70, BackgroundColor3 = T.Surface,
            BorderSizePixel = 0, Size = UDim2.new(0, 210, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }) })
        U.Shadow(self.Popup, { Spread = 18, Transparency = 0.72, YOffset = 5 })
        self.Body = U.Create("Frame", { Parent = self.Popup, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { U.Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
        return self
    end

    function Gear:_rowParent() return self.Body end

    local function adder(key)
        return function(self, flag, o)
            if not P[key] then return nil end
            local W = P[key].new(self, flag, o or {})
            table.insert(self._widgets, W); return W
        end
    end
    Gear.AddToggle   = adder("Toggle")
    Gear.AddSlider   = adder("Slider")
    Gear.AddDropdown = adder("Dropdown")
    Gear.AddKeybind  = adder("Keybind")
    Gear.AddTextBox  = adder("TextBox")
    function Gear:AddButton(t, cb) local W = P.Button.new(self, nil, { Text = t, Callback = cb })
        table.insert(self._widgets, W); return W end
    function Gear:AddLabel(t, o) local W = P.Label.new(self, nil, { Text = t, Header = o and o.Header })
        table.insert(self._widgets, W); return W end
    function Gear:AddColorPicker(f, o) local W = P.ColorPicker.new(self, f, o or {})
        table.insert(self._widgets, W); return W end

    function Gear:attachTo(iconBtn)
        self._icon = iconBtn
        iconBtn.MouseButton1Click:Connect(function() self:Toggle() end)
    end

    function Gear:_forceClose()
        self.Popup.Visible = false; self.Open = false
        if self._icon then self._icon.ImageColor3 = T.SubText end
        self.Library:ClosePopup(self._closer)
    end

    function Gear:Toggle()
        if self.Open then self:_forceClose(); return end
        self._closer = self._closer or function() self:_forceClose() end
        self.Library:OpenPopup(self._closer)
        local gui = self._icon:FindFirstAncestorWhichIsA("ScreenGui")
        self.Popup.Parent = gui
        local ap = self._icon.AbsolutePosition
        self.Popup.Position = UDim2.fromOffset(ap.X - 210 + 20, ap.Y + 20)
        self.Popup.Visible = true; self.Open = true
        self._icon.ImageColor3 = T.Accent
    end

    P.Gear = Gear
end

end)(); __m(P) end
-- ==== Widgets/Viewport ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local RunService = game:GetService("RunService")
    local Viewport = {}
    Viewport.__index = Viewport

    -- handler generico: mete cualquier modelo/instancia y lo muestra (auto-frame + auto-rotate)
    function Viewport.new(Panel, opts)
        opts = opts or {}
        local base = P.Base.new(Panel, { LabelText = nil, Height = opts.Height or 180 })
        local self = setmetatable({ _base = base, Library = Panel.Library,
            AutoRotate = opts.AutoRotate ~= false, Speed = opts.RotateSpeed or 40,
            Pitch = opts.Pitch or 0.35, _angle = 0 }, Viewport)
        base._widget = self
        base.Control.Visible = false

        self.VF = U.Create("ViewportFrame", { Parent = base.Row, Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = opts.Background or T.Surface2, BorderSizePixel = 0,
            Ambient = Color3.fromRGB(170, 170, 175), LightColor = Color3.fromRGB(255, 255, 255),
            LightDirection = Vector3.new(-0.4, -1, -0.5),
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }) })
        self.Cam = Instance.new("Camera"); self.Cam.Parent = self.VF; self.VF.CurrentCamera = self.Cam
        self.World = Instance.new("WorldModel"); self.World.Parent = self.VF
        self.Library:Maid(self.VF)
        return self
    end

    function Viewport:Clear()
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        for _, c in ipairs(self.World:GetChildren()) do c:Destroy() end
        self.Model = nil
    end

    -- inst: cualquier Model / BasePart / Folder de partes. opts.AutoRotate opcional override.
    function Viewport:SetModel(inst, opts)
        self:Clear()
        if not inst then return end
        opts = opts or {}
        local m
        pcall(function() m = inst:Clone() end)
        if not m then
            -- Archivable=false devuelve nil: forzarlo temporalmente
            local prev = inst.Archivable
            inst.Archivable = true
            pcall(function() m = inst:Clone() end)
            inst.Archivable = prev
        end
        if not m then return end
        if not m:IsA("Model") then
            local wrap = Instance.new("Model")
            m.Parent = wrap
            m = wrap
        end
        m.Parent = self.World
        self.Model = m

        local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
        if not ok or not cf then cf, size = CFrame.new(), Vector3.new(4, 4, 4) end
        self._center = cf.Position
        self._radius = math.max(size.Magnitude / 2, 1)
        self._dist = self._radius / math.tan(math.rad(30)) + self._radius
        self:_apply(0)

        local rotate = opts.AutoRotate
        if rotate == nil then rotate = self.AutoRotate end
        if rotate then
            self._conn = RunService.RenderStepped:Connect(function(dt) self:_spin(dt) end)
            self.Library:Maid(self._conn)
        end
        return self
    end

    function Viewport:_apply(angle)
        local c = self._center
        local pos = c + Vector3.new(math.sin(angle) * self._dist, self._radius * self.Pitch, math.cos(angle) * self._dist)
        self.Cam.CFrame = CFrame.lookAt(pos, c)
    end
    function Viewport:_spin(dt)
        self._angle = self._angle + math.rad(self.Speed) * dt
        self:_apply(self._angle)
    end

    function Viewport:SetAutoRotate(b)
        self.AutoRotate = b
        if not b and self._conn then self._conn:Disconnect(); self._conn = nil
        elseif b and self.Model and not self._conn then
            self._conn = RunService.RenderStepped:Connect(function(dt) self:_spin(dt) end)
            self.Library:Maid(self._conn)
        end
    end
    function Viewport:SetSpeed(s) self.Speed = s end
    function Viewport:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function Viewport:SetVisible(b) self._base:SetVisible(b) end

    P.Viewport = Viewport
end

end)(); __m(P) end
-- ==== Widgets/Grid ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local Grid = {}
    Grid.__index = Grid

    -- grid de thumbnails (estilo Skins de primordial). opts: Height, CellSize, Callback
    function Grid.new(Panel, opts)
        opts = opts or {}
        local base = P.Base.new(Panel, { LabelText = nil, Height = opts.Height or 200 })
        local self = setmetatable({ _base = base, Library = Panel.Library,
            Cell = opts.CellSize or 54, Callback = opts.Callback, Items = {}, Selected = nil }, Grid)
        base._widget = self
        base.Control.Visible = false

        self.Scroll = U.Create("ScrollingFrame", { Parent = base.Row, BackgroundColor3 = T.Surface2,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }),
            U.Create("UIGridLayout", { CellSize = UDim2.fromOffset(self.Cell, self.Cell),
                CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Left }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6) }) })
        return self
    end

    -- item: { Image = assetId, Name = string?, Callback = fn? }
    function Grid:AddItem(item)
        local i = #self.Items + 1
        local cell = U.Create("TextButton", { Parent = self.Scroll, AutoButtonColor = false, Text = "",
            BackgroundColor3 = T.Surface3, LayoutOrder = i,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
            U.Create("UIStroke", { Name = "Sel", Color = T.Accent, Thickness = 1, Transparency = 1 }),
            U.Create("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = item.Image or "",
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(0.78, 0.78), ScaleType = Enum.ScaleType.Fit }) })
        if item.Name then
            cell.Icon.Position = UDim2.fromScale(0.5, 0.42)
            cell.Icon.Size = UDim2.fromScale(0.66, 0.66)
            U.Create("TextLabel", { Parent = cell, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, -4, 0, 11),
                Font = T.Font, TextSize = 10, TextColor3 = T.SubText, Text = item.Name,
                TextTruncate = Enum.TextTruncate.AtEnd })
        end
        local rec = { cell = cell, item = item }
        table.insert(self.Items, rec)
        cell.MouseButton1Click:Connect(function() self:Select(i) end)
        return rec
    end

    function Grid:Select(i)
        for idx, rec in ipairs(self.Items) do
            rec.cell.Sel.Transparency = (idx == i) and 0 or 1
        end
        self.Selected = i
        local it = self.Items[i]
        if it then
            if it.item.Callback then task.spawn(it.item.Callback, it.item) end
            if self.Callback then task.spawn(self.Callback, it.item, i) end
        end
    end
    function Grid:GetSelected() local r = self.Items[self.Selected]; return r and r.item end
    function Grid:Clear()
        for _, r in ipairs(self.Items) do r.cell:Destroy() end
        self.Items = {}; self.Selected = nil
    end
    function Grid:SetVisible(b) self._base:SetVisible(b) end

    P.Grid = Grid
end

end)(); __m(P) end
-- ==== Widgets/List ====
do local __m = (function()
return function(P)
    local U, T = P.Util, P.Theme
    local List = {}
    List.__index = List

    -- list-box permanente (dropdown pre-abierto). opts: Text, Values, Multi, Default, Height, Callback
    function List.new(Panel, flag, opts)
        local titleH = opts.Text and 18 or 0
        local boxH = opts.Height or 120
        local base = P.Base.new(Panel, { LabelText = nil, Height = titleH + boxH, Tooltip = opts.Tooltip })
        local self = setmetatable({ _base = base, Library = Panel.Library, Flag = flag,
            Values = opts.Values or {}, Multi = opts.Multi and true or false, Callback = opts.Callback,
            Items = {} }, List)
        base._widget = self
        base.Control.Visible = false

        if opts.Text then
            self.Title = U.Create("TextLabel", { Parent = base.Row, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16), Font = T.FontBold, TextSize = T.TextSize,
                Text = opts.Text, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left })
        end

        self.Box = U.Create("Frame", { Parent = base.Row, Position = UDim2.fromOffset(0, titleH),
            Size = UDim2.new(1, 0, 0, boxH), BackgroundColor3 = T.Surface2, BorderSizePixel = 0, ClipsDescendants = true,
        }, { U.Create("UICorner", { CornerRadius = UDim.new(0, T.Radius) }),
            U.Create("UIStroke", { Color = T.Border, Thickness = 1 }) })
        self.Scroll = U.Create("ScrollingFrame", { Parent = self.Box, BackgroundTransparency = 1,
            BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0,
        }, { U.Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
            U.Create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }) })

        if self.Multi then self.Value = {} else self.Value = nil end
        self:_build()

        self.Library.Options[flag] = self
        local def = opts.Default
        if self.Multi then
            if type(def) == "table" then for _, v in ipairs(def) do self.Value[v] = true end end
        elseif def == nil and not opts.AllowNull then def = self.Values[1] end
        self:SetValue(self.Multi and self:GetValue() or def)
        return self
    end

    function List:_build()
        for _, it in ipairs(self.Items) do it.btn:Destroy() end
        self.Items = {}
        for i, v in ipairs(self.Values) do
            local btn = U.Create("TextButton", { Parent = self.Scroll, AutoButtonColor = false,
                BackgroundColor3 = T.Surface3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
                LayoutOrder = i, Text = "",
            }, { U.Create("TextLabel", { Name = "L", BackgroundTransparency = 1,
                Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -12, 1, 0), Font = T.Font,
                TextSize = T.TextSize, Text = tostring(v), TextColor3 = T.Text,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }) })
            table.insert(self.Items, { btn = btn, value = v })
            btn.MouseButton1Click:Connect(function() self:_click(v) end)
        end
        self:_render()
    end

    function List:_click(v)
        if self.Multi then
            self.Value[v] = (not self.Value[v]) or nil
        else
            self.Value = v
        end
        self:_render()
        self.Library:SetFlag(self.Flag, self:GetValue())
        self._base.Changed:Fire(self:GetValue())
        if self.Callback then task.spawn(self.Callback, self:GetValue()) end
    end

    function List:_isSel(v)
        if self.Multi then return self.Value[v] == true else return self.Value == v end
    end
    function List:_render()
        for _, it in ipairs(self.Items) do
            local sel = self:_isSel(it.value)
            it.btn.BackgroundTransparency = sel and 0.4 or 1
            it.btn.L.TextColor3 = sel and T.Accent or T.Text
        end
    end

    function List:GetValue()
        if not self.Multi then return self.Value end
        local out = {}
        for _, v in ipairs(self.Values) do if self.Value[v] then table.insert(out, v) end end
        return out
    end
    function List:SetValue(v)
        if self.Multi then
            self.Value = {}
            if type(v) == "table" then for _, x in ipairs(v) do self.Value[x] = true end end
        else
            self.Value = v
        end
        self:_render()
        self.Library:SetFlag(self.Flag, self:GetValue())
        self._base.Changed:Fire(self:GetValue())
        if self.Callback then task.spawn(self.Callback, self:GetValue()) end
    end
    function List:SetValues(list) self.Values = list; self:_build() end
    function List:DependsOn(f, e) self._base:DependsOn(f, e); return self end
    function List:OnChanged(fn) self._base:OnChanged(fn); return self end
    function List:SetVisible(b) self._base:SetVisible(b) end

    P.List = List
end

end)(); __m(P) end
return P.Library

end)()
local U = { Library = Lib, Services = {}, Tabs = {}, Registry = nil, Flags = Lib.Flags }
-- ==== bootstrap ====
do local __m = (function()
-- bootstrap: crea la ventana + gate de auth (frontera para key system futuro)
return function(U)
    local Lib = U.Library
    -- cleanup de instancia previa: evita fugas de conexiones/Drawing al recargar
    if getgenv().__MBT_CLEANUP then pcall(getgenv().__MBT_CLEANUP) end
    local function AuthCheck() return true end -- reemplazable por HWID+key contra CF Workers
    if not AuthCheck() then return end
    U.Window = Lib:CreateWindow({ Title = "military base", Size = Vector2.new(834, 586) })
    U.Window:AddSettingsTab() -- UI de configs (Save/Load/Autoload) que ya trae la lib
    getgenv().__MBT = U
end

end)(); __m(U) end
-- ==== tabs ====
do local __m = (function()
-- tabs main del suite (Base Militar Tycoon, place 23380021)
return function(U)
    local Win = U.Window
    U.Tabs.Combat  = Win:AddCategory("Combat",  "crosshair")
    U.Tabs.Visuals = Win:AddCategory("Visuals", "eye")
    U.Tabs.Tycoon  = Win:AddCategory("Tycoon",  "coins")
    U.Tabs.Misc    = Win:AddCategory("Misc",    "settings")
end

end)(); __m(U) end
-- ==== core/Registry ====
do local __m = (function()
-- registro de modulos: cada uno registra su Unload para el cleanup global
return function(U)
    local Reg = { _mods = {} }
    function Reg.Add(name, ctrl) Reg._mods[name] = ctrl end
    function Reg.Get(name) return Reg._mods[name] end
    function Reg.UnloadAll()
        for _, ctrl in pairs(Reg._mods) do
            if ctrl and ctrl.Unload then pcall(ctrl.Unload) end
        end
        Reg._mods = {}
    end
    U.Registry = Reg
end

end)(); __m(U) end
-- ==== services/EntityService ====
do local __m = (function()
-- EntityService: enumera targets (players) con aimPart/head/hrp. Copiado de UniversalPrimordial.
-- SetSource permite inyectar NPCs a futuro (soldiers de workspace.NPCs).
return function(U)
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Ent = { _source = nil, _cache = {} }
    local FALLBACK = { "UpperTorso", "Torso", "HumanoidRootPart" }

    function Ent.ResolveParts(char, partName)
        if not char then return nil end
        local aim
        if partName and partName ~= "Nearest" then aim = char:FindFirstChild(partName) end
        if not aim then
            for _, n in ipairs(FALLBACK) do
                if not aim then aim = char:FindFirstChild(n) end
            end
        end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        return aim or head or hrp, head, hrp
    end

    function Ent.SetSource(fn) Ent._source = fn end
    local function source()
        if Ent._source then return Ent._source() end
        return Players:GetPlayers()
    end

    function Ent.GetTargets(opts)
        opts = opts or {}
        local list = {}
        for _, plr in ipairs(source()) do
            if plr ~= LP then
                local okp, char = pcall(function() return plr.Character end)
                char = okp and char or nil
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local aim, head, hrp = Ent.ResolveParts(char, opts.partName)
                local ok = char ~= nil and aim ~= nil
                if ok and opts.aliveCheck ~= false then ok = hum ~= nil and hum.Health > 0 end
                if ok and opts.teamCheck and LP.Team then
                    ok = plr.Team ~= LP.Team
                end
                if ok then
                    list[#list+1] = {
                        key = plr.UserId or plr.Name, player = plr, character = char,
                        humanoid = hum, aimPart = aim, headPart = head, hrpPart = hrp,
                    }
                end
            end
        end
        Ent._cache = list
        return list
    end

    function Ent.Current() return Ent._cache end
    U.Services.Entity = Ent
end

end)(); __m(U) end
-- ==== services/VelocityService ====
do local __m = (function()
-- VelocityService: velocidad suavizada (median) + resolver de posicion. Copiado de UniversalPrimordial.
-- SilentAim usa Vel.Get(key) para lead = vel * (dist/BulletSpeed). Requiere Vel.Enabled=true.
return function(U)
    local RunService = game:GetService("RunService")
    local N = 6
    local Vel = { _e = {}, MaxSpeed = 0, YClamp = 0, Enabled = false } -- 0 = sin cap (la mediana atenua flings)

    local function median(h)
        local n = #h; if n == 0 then return 0 end
        local s = {}; for i=1,n do s[i] = h[i] end
        table.sort(s)
        if n % 2 == 1 then return s[(n+1)//2] else return (s[n//2] + s[n//2+1]) / 2 end
    end
    local function push(h, v) h[#h+1] = v; if #h > N then table.remove(h, 1) end end

    function Vel.Update(key, pos, now)
        local e = Vel._e[key]
        if not e then
            Vel._e[key] = { last = pos, t = now, hx = {}, hy = {}, hz = {}, res = Vector3.zero, ps = { pos }, pt = { now } }
            return
        end
        local dt = now - e.t
        if dt <= 0 then return end
        local v = (pos - e.last) / dt
        e.last = pos; e.t = now
        push(e.hx, v.X); push(e.hy, v.Y); push(e.hz, v.Z)
        local res = Vector3.new(median(e.hx), median(e.hy), median(e.hz))
        if Vel.MaxSpeed > 0 and res.Magnitude > Vel.MaxSpeed then res = res.Unit * Vel.MaxSpeed end
        if Vel.YClamp > 0 then res = Vector3.new(res.X, math.clamp(res.Y, -Vel.YClamp, Vel.YClamp), res.Z) end
        e.res = res
        local pn = #e.ps
        local pdt = now - e.pt[pn]
        if not (pdt > 0 and (pos - e.ps[pn]).Magnitude / pdt > 300) then
            e.ps[pn + 1] = pos; e.pt[pn + 1] = now
            if #e.ps > 48 then table.remove(e.ps, 1); table.remove(e.pt, 1) end
        end
    end

    function Vel.Get(key) local e = Vel._e[key]; return e and e.res or Vector3.zero end
    function Vel.Reset(key) Vel._e[key] = nil end

    Vel._conn = RunService.Heartbeat:Connect(function()
        if not Vel.Enabled then return end
        local Ent = U.Services.Entity
        if not Ent then return end
        local now = os.clock()
        local seen = {}
        local ok, ents = pcall(Ent.GetTargets, { teamCheck = false, aliveCheck = true })
        if ok and ents then
            for _, ent in ipairs(ents) do
                local part = ent.hrpPart or ent.aimPart
                if part then
                    seen[ent.key] = true
                    pcall(Vel.Update, ent.key, part.Position, now)
                end
            end
        end
        for k, e in pairs(Vel._e) do if not seen[k] and (now - e.t) > 2 then Vel._e[k] = nil end end
    end)

    function Vel.Unload() if Vel._conn then Vel._conn:Disconnect() end end

    function Vel.TargetVel(key)
        local e = Vel._e[key]; local n = e and #e.ps or 0
        if n < 2 then return Vector3.zero end
        local dt = math.max(e.pt[n] - e.pt[n - 1], 1 / 240)
        return (e.ps[n] - e.ps[n - 1]) / dt
    end

    U.Services.Velocity = Vel
end

end)(); __m(U) end
-- ==== services/AimService ====
do local __m = (function()
-- AimService: WorldToScreen/Center/Visible + AimCamera/AimMouse. Copiado de UniversalPrimordial.
-- Aimbot mueve la VISTA al target (aim real) -> el click del user manda una posicion que el server acepta.
return function(U)
    local atan2 = math.atan2 or function(y, x)
        if x > 0 then return math.atan(y / x)
        elseif x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi)
        else return (y >= 0 and math.pi/2 or -math.pi/2) end
    end
    local function cam() return workspace.CurrentCamera end
    local Aim = {}

    function Aim.WorldToScreen(pos)
        local c = cam(); if not c then return Vector2.zero, false, 0 end
        local v, on = c:WorldToViewportPoint(pos)
        return Vector2.new(v.X, v.Y), (on and v.Z > 0), v.Z
    end

    function Aim.Center()
        local c = cam()
        local vp = (c and c.ViewportSize) or Vector2.new(1920, 1080)
        return vp / 2
    end

    function Aim.Visible(origin, targetPos, ignore)
        local c = cam()
        origin = origin or (c and c.CFrame.Position)
        if not origin then return true end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignore or {}
        local res = workspace:Raycast(origin, targetPos - origin, params)
        return res == nil or (res.Position - targetPos).Magnitude < 2
    end

    local function yawPitch(look)
        return atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
    end

    function Aim.AimCamera(aimPoint, smoothX, smoothY)
        local c = cam(); if not c then return end
        local pos = c.CFrame.Position
        local ax = math.clamp(1 - (smoothX or 0), 0.01, 1)
        local ay = math.clamp(1 - (smoothY or 0), 0.01, 1)
        local cy, cp = yawPitch(c.CFrame.LookVector)
        local gy, gp = yawPitch((aimPoint - pos).Unit)
        local dy = (gy - cy + math.pi) % (2 * math.pi) - math.pi -- camino angular corto
        local ny = cy + dy * ax
        local np = cp + (gp - cp) * ay
        local nl = Vector3.new(-math.sin(ny) * math.cos(np), math.sin(np), -math.cos(ny) * math.cos(np))
        c.CFrame = CFrame.lookAt(pos, pos + nl)
    end

    function Aim.CanMouse() return typeof(mousemoverel) == "function" end

    function Aim.AimMouse(delta, smoothX, smoothY)
        if not Aim.CanMouse() then return false end
        local fx = math.clamp(1 - (smoothX or 0), 0.01, 1)
        local fy = math.clamp(1 - (smoothY or 0), 0.01, 1)
        mousemoverel(delta.X * fx, delta.Y * fy)
        return true
    end

    U.Services.Aim = Aim
end

end)(); __m(U) end
-- ==== services/SpoofService ====
do local __m = (function()
-- SpoofService: motor de desync server-pos por HOOK __index (port del Spoof.lua de LifeInPrisonPrimordial).
-- El server te ve en la fakeCF; tu cuerpo/camara reales NO se mueven (hook devuelve la CF real → AC-safe).
-- Reload-safe (getgenv guards). Consumido por TargetStrafe (ofensa) y ClientDesync (defensa).
return function(U)
    local Players    = game:GetService("Players")
    local Workspace  = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local hookmm = hookmetamethod
    local newcc  = newcclosure or function(f) return f end
    local sethidden = sethiddenproperty

    if not getgenv().__MBT_SP then
        getgenv().__MBT_SP = { spoofOn = false, cachedRoot = nil, spoofRealCF = nil, spoofRestore = nil, spoofFakePos = nil, spoofVel = nil, connRep = false }
    end
    local SP = getgenv().__MBT_SP
    local Spoof = { state = SP }

    local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    Spoof.myRoot = myRoot

    ------------------------------------------------------------------ __index hook (una vez)
    if not getgenv().__MBT_IDX and typeof(hookmm) == "function" then
        local orig
        local ok = pcall(function()
            orig = hookmm(game, "__index", newcc(function(self, key)
                local D = getgenv().__MBT_SP
                if D and D.spoofOn and self == D.cachedRoot and D.spoofRealCF then
                    if key == "CFrame" then return D.spoofRealCF end
                    if key == "Position" then return D.spoofRealCF.Position end
                end
                return orig(self, key)
            end))
        end)
        if ok then getgenv().__MBT_IDX = true; getgenv().__MBT_ORIG_INDEX = orig end
    end
    local function trueCF(root) local o = getgenv().__MBT_ORIG_INDEX; return (o and o(root, "CFrame")) or root.CFrame end
    Spoof.trueCF = trueCF
    function Spoof.captureReal(root)
        local tc = trueCF(root)
        if SP.spoofOn and SP.spoofRealCF then
            local last = SP.spoofRealCF
            if (tc.Position - last.Position).Magnitude > 400 then return last end
            if SP.spoofFakePos and (tc.Position - SP.spoofFakePos).Magnitude < 30 then return last end
        end
        return tc
    end

    ------------------------------------------------------------------ camara anclada a pos real (sin teleport visual)
    local function camAnchor()
        local a = getgenv().__MBT_CamAnchor
        if not a or not a.Parent then
            a = Instance.new("Part")
            a.Name = "MBT_CamAnchor"; a.Anchored = true; a.CanCollide = false; a.Transparency = 1; a.Size = Vector3.new(2, 2, 1)
            pcall(function() a.Parent = Workspace end)
            getgenv().__MBT_CamAnchor = a
        end
        return a
    end
    function Spoof.camToLocal(cam, realCF)
        local a = camAnchor()
        pcall(function()
            a.CFrame = realCF + Vector3.new(0, 2.5, 0)
            if cam.CameraSubject ~= a then cam.CameraSubject = a end
        end)
    end
    function Spoof.camToChar(cam)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() if cam.CameraSubject ~= hum then cam.CameraSubject = hum end end) end
    end

    ------------------------------------------------------------------ connection weld exploit (PhysicsRepRootPart, sin Weld)
    function Spoof.setPhysRep(targetHRP)
        local r = myRoot()
        if r and sethidden and targetHRP and targetHRP.Parent then
            pcall(function() sethidden(r, "PhysicsRepRootPart", targetHRP) end)
            SP.connRep = true
        end
    end
    function Spoof.unweld()
        SP.connRep = false
        if sethidden then
            task.spawn(function()
                for _ = 1, 10 do
                    local rr = myRoot()
                    if rr then pcall(function() sethidden(rr, "PhysicsRepRootPart", rr) end) end
                    task.wait()
                end
            end)
        end
    end

    ------------------------------------------------------------------ restore loop (una vez)
    if not getgenv().__MBT_RESTORE then
        getgenv().__MBT_RESTORE = true
        getgenv().__MBT_RESTORE_CONN = RunService.RenderStepped:Connect(function()
            local D = getgenv().__MBT_SP
            if not D then return end
            local root = D.cachedRoot
            if root and root.Parent and D.spoofRestore then
                pcall(function()
                    root.CFrame = D.spoofRestore
                    if D.spoofVel then root.AssemblyLinearVelocity = D.spoofVel end
                end)
                D.spoofRestore = nil
            end
        end)
    end

    ------------------------------------------------------------------ API alto nivel
    -- desyncTo: el server te ve en fakeCF; cuerpo/camara reales quedan. camLock=true ancla la camara a la pos real.
    function Spoof.desyncTo(fakeCF, camLock)
        local root = myRoot(); if not root then return end
        local cam = Workspace.CurrentCamera
        if SP.connRep then Spoof.unweld() end
        local realCF = Spoof.captureReal(root)
        SP.cachedRoot = root; SP.spoofRealCF = realCF; SP.spoofOn = true; SP.spoofFakePos = fakeCF.Position
        SP.spoofVel = root.AssemblyLinearVelocity; SP.spoofRestore = realCF
        if camLock and cam then Spoof.camToLocal(cam, realCF) end
        pcall(function() root.CFrame = fakeCF end)
    end
    -- weldTo: connection weld point-blank al target (PhysicsRepRootPart), SIN escribir CFrame ni desync.
    function Spoof.weldTo(targetHRP)
        Spoof.setPhysRep(targetHRP)
        SP.spoofFakePos = targetHRP and targetHRP.Position
        SP.spoofOn = false; SP.spoofRealCF = nil; SP.spoofRestore = nil
    end
    function Spoof.stop()
        local cam = Workspace.CurrentCamera
        if SP.spoofOn then
            local r = myRoot()
            if r and SP.spoofRealCF then pcall(function() r.CFrame = SP.spoofRealCF end) end
        end
        if SP.connRep then Spoof.unweld() end
        SP.spoofOn = false; SP.spoofRealCF = nil; SP.spoofRestore = nil; SP.spoofFakePos = nil; SP.spoofVel = nil
        if cam then Spoof.camToChar(cam) end
    end
    function Spoof.fakePos() return SP.spoofFakePos end
    function Spoof.isActive() return SP.spoofOn or SP.connRep end

    function Spoof.Unload()
        local rc = getgenv().__MBT_RESTORE_CONN
        if rc then rc:Disconnect() end
        getgenv().__MBT_RESTORE = nil
        Spoof.stop()
        local a = getgenv().__MBT_CamAnchor
        if a then pcall(function() a:Destroy() end); getgenv().__MBT_CamAnchor = nil end
    end

    U.Services.Spoof = Spoof
end

end)(); __m(U) end
-- ==== modules/combat/InstantReload ====
do local __m = (function()
-- InstantReload: setea Configuration.ReloadTime=0 en toda arma (client-only, no replica).
-- Server gatea por RATE no por silencio de reload -> borrar la pausa de 1.8s es AC-safe.
-- Confirmado live por el usuario ("100% viable"). NO tocar FireRate/MaxAmmo (esos buguean).
return function(U)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Combat = U.Tabs.Combat
    local F = U.Flags

    local Sec = Combat:AddSection("Weapon", "Reload & fire")
    local Pan = Sec:AddPanel("Reload", { Column = 1 })
    Pan:AddLabel("Instant Reload", { Header = true })

    -- guarda el valor original por cada NumberValue de ReloadTime (weak keys)
    local originals = setmetatable({}, { __mode = "k" })

    local function eachReloadValue(fn)
        local containers = { LP:FindFirstChildOfClass("Backpack"), LP.Character }
        for _, cont in ipairs(containers) do
            if cont then
                for _, t in ipairs(cont:GetChildren()) do
                    if t:IsA("Tool") then
                        local cfg = t:FindFirstChild("Configuration")
                        local rt = cfg and cfg:FindFirstChild("ReloadTime")
                        if rt then fn(rt) end
                    end
                end
            end
        end
    end

    local function restore()
        for rt, v in pairs(originals) do
            if typeof(rt) == "Instance" and rt.Parent then
                pcall(function() rt.Value = v end)
            end
        end
    end

    Pan:AddToggle("InstantReload", {
        Text = "Instant Reload", Default = false,
        Tooltip = "ReloadTime puesto a 0 en todas las armas",
        Callback = function(v)
            if not v then restore() end
        end,
    })

    -- scan throttled ~2.5Hz: cubre respawn + armas nuevas sin costo por-frame
    local acc = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not F.InstantReload then return end
        acc = acc + dt
        if acc < 0.4 then return end
        acc = 0
        eachReloadValue(function(rt)
            if originals[rt] == nil then originals[rt] = rt.Value end
            if rt.Value ~= 0 then rt.Value = 0 end
        end)
    end)

    if U.Registry then
        U.Registry.Add("InstantReload", { Unload = function()
            if conn then conn:Disconnect() end
            pcall(restore)
        end })
    end
end

end)(); __m(U) end
-- ==== modules/combat/Aimbot ====
do local __m = (function()
-- Aimbot: mueve tu VISTA (camara o mouse) al target mientras mantenes la tecla.
-- Tu click legitimo raycastea al enemigo -> el server acepta (aim real, sin redirigir posicion).
-- NO hookea MouseEvent (silent-aim = flag en este server). Port de UniversalPrimordial adaptado.
return function(U)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags

    local Sec = Combat:AddSection("Aimbot", "Snap de vista al target (aim real, AC-safe)")
    local Pan = Sec:AddPanel("Aimbot", { Column = 1 })

    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("AimEnable", { Text = "Enabled", Default = false, Tooltip = "Mante la tecla de aim para apuntar" })
    Pan:AddDropdown("AimTrigger", { Text = "Trigger", Values = { "Hold Mouse2", "Hold Key", "Always" }, Default = "Hold Mouse2" })
    Pan:AddKeybind("AimKey", { Text = "Aim Key", Mode = "Hold", Default = Enum.KeyCode.E })
    Pan:AddDropdown("AimMethod", { Text = "Aim Method", Values = { "Camera", "Mouse" }, Default = "Camera" })
    Pan:AddLabel("Target", { Header = true })
    Pan:AddDropdown("AimPart", { Text = "Target Part", Values = { "Head", "UpperTorso", "HumanoidRootPart" }, Default = "Head" })
    Pan:AddDropdown("AimSelect", { Text = "Selection", Values = { "FOV closest", "Distance", "Lowest HP" }, Default = "FOV closest" })
    Pan:AddToggle("AimSticky", { Text = "Sticky Target", Default = true })
    Pan:AddLabel("FOV", { Header = true })
    Pan:AddSlider("AimFOV", { Text = "FOV", Min = 10, Max = 600, Default = 120, Suffix = "px" })
    Pan:AddToggle("AimShowFOV", { Text = "Show Circle", Default = true })
        :AddColorPicker("AimFOVColor", { Default = Color3.fromRGB(202, 151, 161) })
    Pan:AddLabel("Aim feel", { Header = true })
    Pan:AddSlider("AimSmoothX", { Text = "Smoothing X", Min = 0, Max = 99, Default = 55, Suffix = "%" })
    Pan:AddSlider("AimSmoothY", { Text = "Smoothing Y", Min = 0, Max = 99, Default = 55, Suffix = "%" })
    Pan:AddSlider("AimDeadzone", { Text = "Deadzone", Min = 0, Max = 50, Default = 0, Suffix = "px" })
    Pan:AddLabel("Prediction", { Header = true })
    Pan:AddToggle("AimAutoPredict", { Text = "Auto Predict", Default = false,
        Tooltip = "Lead = distancia / BulletSpeed del arma actual * (Base + Amplitude)" })
    Pan:AddTextBox("AimPredBase", { Text = "Predict Base", Numeric = true, Default = "1.00000",
        Tooltip = "0.00000-1.00000 · escala del lead fisico (1 = exacto)" })
    Pan:AddTextBox("AimPredAmp", { Text = "Predict Amplitude", Numeric = true, Default = "0.00000",
        Tooltip = "0.00000-1.00000 · ajuste fino aditivo" })
    Pan:AddSlider("AimPrediction", { Text = "Lead % (manual)", Min = 0, Max = 200, Default = 0, Suffix = "%",
        Tooltip = "Usado solo si Auto Predict OFF" })
    Pan:AddLabel("Filters", { Header = true })
    Pan:AddToggle("AimTeamCheck", { Text = "Team Check", Default = true })
    Pan:AddToggle("AimVisible", { Text = "Visible Check", Default = true })
    Pan:AddToggle("AimAlive", { Text = "Alive Check", Default = true })

    local circle
    if Drawing then
        circle = Drawing.new("Circle")
        circle.Thickness = 1; circle.NumSides = 64; circle.Filled = false; circle.Visible = false
    end

    local function triggerHeld()
        local m = F.AimTrigger
        if m == "Always" then return true
        elseif m == "Hold Key" then return F.AimKeyActive == true
        else return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    end

    local function equippedWeapon()
        local char = Players.LocalPlayer.Character
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then return t end end end
    end

    local current = nil

    local function pick(cands, center)
        local Aim = U.Services.Aim
        local mode = F.AimSelect
        local fov = F.AimFOV or 120
        local best, bestScore
        for _, c in ipairs(cands) do
            local screen, on = Aim.WorldToScreen(c.aimPart.Position)
            if on then
                local d = (screen - center).Magnitude
                if d <= fov then
                    local score
                    if mode == "Distance" then
                        local cam = workspace.CurrentCamera
                        score = cam and (cam.CFrame.Position - c.aimPart.Position).Magnitude or d
                    elseif mode == "Lowest HP" then
                        score = (c.humanoid and c.humanoid.Health) or 1e9
                    else
                        score = d
                    end
                    if not bestScore or score < bestScore then best, bestScore = c, score end
                end
            end
        end
        return best
    end

    local function tick()
        local Ent, Vel, Aim = U.Services.Entity, U.Services.Velocity, U.Services.Aim
        if Vel then Vel.Enabled = F.AimEnable == true end
        if circle and Aim then
            circle.Visible = (F.AimEnable and F.AimShowFOV) == true
            if circle.Visible then
                circle.Radius = F.AimFOV or 120
                circle.Position = Aim.Center()
                circle.Color = F.AimFOVColor or Color3.new(1, 1, 1)
            end
        elseif circle then
            circle.Visible = false
        end
        if not F.AimEnable then current = nil; return end
        if not triggerHeld() then current = nil; return end
        if not Ent or not Aim then return end
        local ok, cands = pcall(Ent.GetTargets, { teamCheck = F.AimTeamCheck, aliveCheck = F.AimAlive, partName = F.AimPart })
        if not ok or not cands then return end
        local center = Aim.Center()
        local target
        if F.AimSticky and current then
            for _, c in ipairs(cands) do
                if c.key == current then
                    local s, on = Aim.WorldToScreen(c.aimPart.Position)
                    if on and (s - center).Magnitude <= (F.AimFOV or 120) then target = c end
                end
            end
        end
        if not target then target = pick(cands, center) end
        if not target then current = nil; return end
        current = target.key
        local vel = (Vel and Vel.Get(target.key)) or Vector3.zero
        local aimPoint
        if F.AimAutoPredict then
            -- lead = (distancia / BulletSpeed del arma) * (Base + Amplitude)
            local mult = (tonumber(F.AimPredBase) or 0) + (tonumber(F.AimPredAmp) or 0)
            local speed = 800
            local w = equippedWeapon()
            local cfg = w and w:FindFirstChild("Configuration")
            if cfg and cfg:FindFirstChild("BulletSpeed") and cfg.BulletSpeed.Value > 0 then speed = cfg.BulletSpeed.Value end
            local cam = workspace.CurrentCamera
            local dist = cam and (cam.CFrame.Position - target.aimPart.Position).Magnitude or 0
            local leadTime = (speed > 0 and dist / speed or 0) * mult
            aimPoint = target.aimPart.Position + vel * leadTime
        else
            local lead = (F.AimPrediction or 0) / 100
            aimPoint = target.aimPart.Position + (lead > 0 and vel or Vector3.zero) * lead
        end
        if F.AimVisible then
            local lc = Players.LocalPlayer and Players.LocalPlayer.Character
            if not Aim.Visible(nil, aimPoint, { lc, workspace.CurrentCamera }) then return end
        end
        local sx, sy = (F.AimSmoothX or 0) / 100, (F.AimSmoothY or 0) / 100
        if F.AimMethod == "Mouse" and Aim.CanMouse and Aim.CanMouse() then
            local screen = Aim.WorldToScreen(aimPoint)
            local delta = screen - center
            if delta.Magnitude > (F.AimDeadzone or 0) then pcall(Aim.AimMouse, delta, sx, sy) end
        else
            pcall(Aim.AimCamera, aimPoint, sx, sy)
        end
    end

    local conn = RunService.RenderStepped:Connect(tick)

    if U.Registry then
        U.Registry.Add("Aimbot", { Unload = function()
            if conn then conn:Disconnect() end
            if circle then circle:Remove() end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/combat/FireBlink ====
do local __m = (function()
-- FireBlink: packet blink hook-level. Mante la tecla -> encola los FireServer (weapon o todos)
-- SIN enviarlos (movimiento = engine, sigue replicando -> tu posicion real replica y valida OK).
-- Soltas o a los 3s (limite outbound) -> flush burst = todos los tiros juntos ANTES del rate-check
-- del server = daño acumulado / one-shot. Hook unico reload-safe (getgenv().__MBT_BLINK_HOOK).
return function(U)
    local RunService = game:GetService("RunService")
    local Combat = U.Tabs.Combat
    local F = U.Flags

    local Sec = Combat:AddSection("Fire Blink", "Encola disparos, libera en burst")
    local Pan = Sec:AddPanel("Fire Blink", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("BlinkEnable", { Text = "Enabled", Default = false })
    Pan:AddKeybind("BlinkKey", { Text = "Hold to Blink", Mode = "Hold", Default = Enum.KeyCode.V })
    Pan:AddDropdown("BlinkScope", { Text = "Scope", Values = { "Weapon Only", "All Remotes" }, Default = "Weapon Only",
        Tooltip = "Weapon = solo MouseEvent (seguro). All = todos los FireServer (blink real)" })
    Pan:AddSlider("BlinkMaxTime", { Text = "Max Hold", Min = 0.5, Max = 3, Default = 3, Decimals = 1, Suffix = "s",
        Tooltip = "Auto-flush (margen del outbound timeout ~3s)" })
    Pan:AddSlider("BlinkReleaseGap", { Text = "Release Gap", Min = 0, Max = 100, Default = 0, Suffix = "ms",
        Tooltip = "0 = todo el burst en 1 frame (max daño). >0 = espaciado" })
    Pan:AddToggle("BlinkShowHUD", { Text = "Show Indicator", Default = true })

    -- estado global compartido con el hook unico
    if not getgenv().__MBT_BLINK then getgenv().__MBT_BLINK = { active = false, scope = "Weapon Only", queue = {} } end

    -- hook unico (reload-safe): swallow FireServer cuando active y matchea scope
    if not getgenv().__MBT_BLINK_HOOK and typeof(hookmetamethod) == "function" then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local S = getgenv().__MBT_BLINK
            if S and S.active and typeof(self) == "Instance" then
                local isSelf = (typeof(checkcaller) == "function") and checkcaller() or false
                if not isSelf then
                    local ok, m = pcall(getnamecallmethod)
                    if ok and m == "FireServer" then
                        if S.scope == "All Remotes" or self.Name == "MouseEvent" then
                            S.queue[#S.queue + 1] = { remote = self, args = table.pack(...) }
                            return -- swallow: encolado, no se envia
                        end
                    end
                end
            end
            return old(self, ...)
        end)
        getgenv().__MBT_BLINK_HOOK = true
        getgenv().__MBT_BLINK_OLD = old
    end

    local function flush()
        local S = getgenv().__MBT_BLINK
        local old = getgenv().__MBT_BLINK_OLD
        S.active = false
        if not old then S.queue = {}; return end
        local q = S.queue
        S.queue = {}
        local gap = (F.BlinkReleaseGap or 0) / 1000
        for i = 1, #q do
            local it = q[i]
            if it.remote and it.remote.Parent then
                pcall(old, it.remote, table.unpack(it.args, 1, it.args.n))
            end
            if gap > 0 then task.wait(gap) end
        end
    end

    local hud
    if Drawing then hud = Drawing.new("Text"); hud.Size = 18; hud.Center = true; hud.Outline = true; hud.Visible = false end

    local blinkStart = 0
    local conn = RunService.RenderStepped:Connect(function()
        local S = getgenv().__MBT_BLINK
        if not S then return end
        S.scope = F.BlinkScope or "Weapon Only"
        local held = (F.BlinkEnable == true) and (F.BlinkKeyActive == true)
        if held and not S.active then
            S.active = true; blinkStart = os.clock()
        elseif S.active then
            local elapsed = os.clock() - blinkStart
            if (not held) or elapsed >= (F.BlinkMaxTime or 3) then
                task.spawn(flush)
            end
        end
        if hud then
            hud.Visible = (F.BlinkEnable and F.BlinkShowHUD and S.active) == true
            if hud.Visible then
                local vp = workspace.CurrentCamera.ViewportSize
                local remain = math.max(0, (F.BlinkMaxTime or 3) - (os.clock() - blinkStart))
                hud.Text = string.format("BLINK %.1fs  [%d]", remain, #S.queue)
                hud.Position = Vector2.new(vp.X / 2, vp.Y / 2 + 45)
                hud.Color = remain < 0.6 and Color3.fromRGB(235, 60, 60) or Color3.fromRGB(202, 151, 161)
            end
        end
    end)

    if U.Registry then
        U.Registry.Add("FireBlink", { Unload = function()
            local S = getgenv().__MBT_BLINK
            if S then S.active = false; S.queue = {} end -- desarma (hook queda inerte)
            if conn then conn:Disconnect() end
            if hud then hud:Remove() end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/combat/TargetStrafe ====
do local __m = (function()
-- TargetStrafe: orbita al TARGET via desync (el server te ve orbitando; cuerpo/camara reales quietos).
-- Port simple del Strafe.lua de LifeInPrisonPrimordial (sin el resolver HvH pesado). Solo-target (los
-- modos self viven en ClientDesync). Random = XYZ random cada frame en el rango (radius). Toggle bindeable.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace  = game:GetService("Workspace")
    local LP = Players.LocalPlayer
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local Spoof = U.Services.Spoof

    local Sec = Combat:AddSection("Target Strafe", "Orbita al target por desync (offense)")
    local Pan = Sec:AddPanel("Target Strafe", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("StrafeEnable", { Text = "Enabled", Default = false,
        Tooltip = "Orbita al target; el server te ve moviendote, tu cuerpo real queda" })
        :AddKeybind({ Default = Enum.KeyCode.C }) -- default Toggle; right-click la caja para Always/Hold/Toggle
    Pan:AddDropdown("StrafeMode", { Text = "Mode", Values = { "Normal", "Random", "Behind", "Spiral", "Inside" }, Default = "Random",
        Tooltip = "Random = XYZ random/frame en el rango. Inside = dentro del target (cero mismatch de rango)" })
    Pan:AddDropdown("StrafeTargetType", { Text = "Target", Values = { "Enemy Player", "Soldier NPC" }, Default = "Enemy Player" })
    Pan:AddSlider("StrafeRadius", { Text = "Radius", Min = 0, Max = 60, Default = 12, Suffix = "studs" })
    Pan:AddSlider("StrafeSpeed", { Text = "Speed", Min = 1, Max = 40, Default = 20 })
    Pan:AddSlider("StrafeHeight", { Text = "Height", Min = -20, Max = 20, Default = 0, Suffix = "studs" })
    Pan:AddSlider("StrafePredict", { Text = "Predict", Min = 0, Max = 0.5, Default = 0, Decimals = 3, Suffix = "s" })
    Pan:AddToggle("StrafeWeld", { Text = "Connection Weld (point-blank)", Default = false,
        Tooltip = "PhysicsRepRootPart=target: point-blank sin delay, en vez de orbitar" })
    Pan:AddToggle("StrafeSpectate", { Text = "Spectate Target (mouse-on-target)", Default = true,
        Tooltip = "Camara al target -> tu mouse/hitPos cae en el = tiro valido" })
    Pan:AddToggle("StrafeMarker", { Text = "Show Marker", Default = true })
        :AddColorPicker("StrafeMarkerColor", { Default = Color3.fromRGB(235, 60, 60) })
    Pan:AddButton("Set Target (crosshair)", function()
        local cam = Workspace.CurrentCamera
        local best, bd
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local sp, on = cam:WorldToViewportPoint(hrp.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - cam.ViewportSize / 2).Magnitude
                        if not bd or d < bd then bd, best = d, plr end
                    end
                end
            end
        end
        getgenv().__MBT_STRAFE_UID = best and best.UserId or nil
        if best and U.Library.Notify then U.Library:Notify({ Title = "Strafe Target", Description = "Locked: " .. best.Name, Time = 3 }) end
    end)
    Pan:AddButton("Clear Target", function() getgenv().__MBT_STRAFE_UID = nil end)

    -- LCG (Math.random bloqueado en executor) para el modo Random XYZ
    local brng = 987654321
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end

    -- velocidad del target (2 samples) para predict
    local vhist = {}
    local function targetVel(key, pos, now)
        local h = vhist[key]
        if not h then vhist[key] = { p = pos, t = now, v = Vector3.zero }; return Vector3.zero end
        local dt = now - h.t
        if dt > 1e-3 then h.v = (pos - h.p) / dt; h.p = pos; h.t = now end
        return h.v
    end

    -- target: manual (UserId, persiste) o auto mas cercano a la mira / mas cercano (NPC)
    local function pickTarget()
        if F.StrafeTargetType == "Soldier NPC" then
            local NPCs = Workspace:FindFirstChild("NPCs")
            local myhrp = Spoof.myRoot()
            if not (NPCs and myhrp) then return nil end
            local best, bd
            for _, m in ipairs(NPCs:GetChildren()) do
                local h = m:FindFirstChildOfClass("Humanoid")
                local r = m:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    local d = (r.Position - myhrp.Position).Magnitude
                    if not bd or d < bd then bd, best = d, m end
                end
            end
            return best
        end
        local uid = getgenv().__MBT_STRAFE_UID
        local cam = Workspace.CurrentCamera
        local best, bd
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    if uid then
                        if plr.UserId == uid then return c end
                    else
                        local sp, on = cam:WorldToViewportPoint(hrp.Position)
                        if on and sp.Z > 0 then
                            local d = (Vector2.new(sp.X, sp.Y) - cam.ViewportSize / 2).Magnitude
                            if not bd or d < bd then bd, best = d, c end
                        end
                    end
                end
            end
        end
        return best
    end

    -- orbitCF (port de LiP): Normal/Random/Behind/Spiral/Inside alrededor del centro, mirando al centro
    local seed = 0
    local function orbitCF(center, look)
        local R, spd, h = F.StrafeRadius or 12, F.StrafeSpeed or 20, F.StrafeHeight or 0
        local mode = F.StrafeMode or "Random"
        if mode == "Inside" then
            return CFrame.new(center + Vector3.new(0, h, 0))
        elseif mode == "Behind" then
            local lv = look or Vector3.new(0, 0, -1)
            return CFrame.lookAt(center - lv * R + Vector3.new(0, h, 0), center)
        elseif mode == "Random" then
            return CFrame.new(center + Vector3.new(rndS() * R, h + rndS() * R, rndS() * R)) -- XYZ random/frame
        elseif mode == "Spiral" then
            seed = seed + spd * 0.03
            local vAmp = (math.abs(h) > 0.1) and math.abs(h) or 6
            return CFrame.lookAt(center + Vector3.new(math.cos(seed) * R, math.sin(seed * 0.5) * vAmp, math.sin(seed) * R), center)
        else -- Normal
            seed = seed + spd * 0.05
            return CFrame.lookAt(center + Vector3.new(math.cos(seed) * R, h, math.sin(seed) * R), center)
        end
    end

    -- marker (donde te ve el server)
    local mC, mT, mL
    if Drawing then
        mC = Drawing.new("Circle"); mC.Thickness = 2; mC.NumSides = 32; mC.Filled = false; mC.Radius = 7; mC.Visible = false
        mT = Drawing.new("Text"); mT.Size = 14; mT.Center = true; mT.Outline = true; mT.Visible = false
        mL = Drawing.new("Line"); mL.Thickness = 1; mL.Visible = false
    end
    local UIS = game:GetService("UserInputService")
    local function hideMarker() if mC then mC.Visible = false; mT.Visible = false; mL.Visible = false end end
    local function drawMarker(pos)
        if not mC or not pos then return end
        local cam = Workspace.CurrentCamera
        local v = cam:WorldToViewportPoint(pos); local on = v.Z > 0
        mC.Visible = on; mT.Visible = on; mL.Visible = on
        if on then
            local col = F.StrafeMarkerColor or Color3.fromRGB(235, 60, 60)
            local p = Vector2.new(v.X, v.Y)
            mC.Position = p; mC.Color = col
            mT.Position = p + Vector2.new(0, 10); mT.Text = "STRAFE"; mT.Color = col
            mL.From = UIS:GetMouseLocation(); mL.To = p; mL.Color = col
        end
    end

    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        if not (F.StrafeEnable == true) then
            if wasActive then wasActive = false; Spoof.stop() end
            hideMarker()
            return
        end
        local char = pickTarget()
        local tHRP = char and char:FindFirstChild("HumanoidRootPart")
        if not tHRP then hideMarker(); return end
        local now = os.clock()
        local center = tHRP.Position
        local predict = F.StrafePredict or 0
        if predict > 0 then center = center + targetVel(tHRP, tHRP.Position, now) * predict end

        if F.StrafeWeld then
            Spoof.weldTo(tHRP) -- point-blank
        else
            Spoof.desyncTo(orbitCF(center, tHRP.CFrame.LookVector), F.StrafeSpectate ~= true)
        end
        -- spectator: camara al target -> mouse cae en el (hitPos valido)
        if F.StrafeSpectate then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() if cam.CameraSubject ~= hum then cam.CameraSubject = hum end end) end
        end
        if F.StrafeMarker and Drawing then drawMarker(Spoof.fakePos()) else hideMarker() end
        wasActive = true
    end)

    if U.Registry then
        U.Registry.Add("TargetStrafe", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
            hideMarker()
            for _, d in ipairs({ mC, mT, mL }) do if d then pcall(function() d:Remove() end) end end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/combat/Autofire ====
do local __m = (function()
-- Autofire: full-auto para cualquier arma. 2 metodos:
--  Activate  = tool:Activate() -> corre el flujo Client (ammo+reload+MouseEvent) = SIN lockout, dispara al mouse.
--  MouseEvent= Tool.MouseEvent:FireServer(pos) directo -> posicion controlable (silent-aim), pero bypassa el
--              ammo del client -> maneja su propio ciclo de mag (MaxAmmo tiros -> pausa reload -> repite) o el
--              server lockea. pos = crosshair (raycast camara, superficie valida) por default.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer

    local Sec = Combat:AddSection("Autofire", "Full-auto para cualquier arma")
    local Pan = Sec:AddPanel("Autofire", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("Autofire", { Text = "Enabled", Default = false, Tooltip = "Dispara solo al rate del arma" })
        :AddKeybind({ Default = Enum.KeyCode.F }) -- Toggle default; right-click la caja para Hold/Always
    Pan:AddDropdown("AutofireMethod", { Text = "Method", Values = { "Activate", "MouseEvent" }, Default = "Activate",
        Tooltip = "Activate=safe (ammo/reload del client). MouseEvent=pos controlable (silent), maneja mag propio" })
    Pan:AddLabel("Rate", { Header = true })
    Pan:AddToggle("AutofireUseWeaponRate", { Text = "Use Weapon FireRate", Default = true })
    Pan:AddSlider("AutofireInterval", { Text = "Interval", Min = 0.03, Max = 1, Default = 0.12, Decimals = 2, Suffix = "s",
        Tooltip = "Usado si Use Weapon FireRate OFF. Muy rapido = lockout del server" })
    Pan:AddLabel("MouseEvent method", { Header = true })
    Pan:AddSlider("AutofireReloadPause", { Text = "Reload Pause", Min = 0, Max = 3, Default = 1.8, Decimals = 2, Suffix = "s",
        Tooltip = "Pausa tras vaciar el mag (deja que el server auto-recargue). NO uses con InstantReload aca" })
    Pan:AddToggle("AutofireOnlyHeld", { Text = "Only While Firing Key Down", Default = false,
        Tooltip = "Requiere ademas mantener Mouse1" })

    local function equippedWeapon()
        local char = LP.Character
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t:FindFirstChild("MouseEvent") then return t end end end
    end
    local function cfgVal(tool, name, default)
        local c = tool:FindFirstChild("Configuration")
        local v = c and c:FindFirstChild(name)
        return (v and v.Value) or default
    end
    local UIS = game:GetService("UserInputService")

    -- pos de disparo = hit del raycast desde el centro de la camara (superficie valida, misma forma que el client)
    local function crosshairPos(tool)
        local cam = workspace.CurrentCamera
        local range = cfgVal(tool, "BulletRange", 800)
        local ray = cam:ViewportPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { LP.Character, cam }
        local res = workspace:Raycast(ray.Origin, ray.Direction * range, rp)
        return res and res.Position or (ray.Origin + ray.Direction * range)
    end

    local acc = 0
    local magCount = 0
    local reloadUntil = 0
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.Autofire == true) then acc = 0; return end
        if F.AutofireOnlyHeld and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
        local tool = equippedWeapon()
        if not tool then return end
        local interval = F.AutofireUseWeaponRate ~= false and cfgVal(tool, "FireRate", 0.2) or (F.AutofireInterval or 0.12)
        interval = math.max(interval, 0.03)
        acc = acc + dt
        if acc < interval then return end
        acc = 0

        if F.AutofireMethod == "MouseEvent" then
            local now = os.clock()
            if now < reloadUntil then return end
            local maxAmmo = cfgVal(tool, "MaxAmmo", 8)
            if magCount >= maxAmmo then
                reloadUntil = now + (F.AutofireReloadPause or 1.8) -- deja que el server auto-recargue
                magCount = 0
                return
            end
            local me = tool:FindFirstChild("MouseEvent")
            if me then pcall(function() me:FireServer(crosshairPos(tool)) end); magCount = magCount + 1 end
        else -- Activate (safe: el client maneja ammo/reload)
            pcall(function() tool:Activate() end)
        end
    end)

    if U.Registry then
        U.Registry.Add("Autofire", { Unload = function() if driver then driver:Disconnect() end end })
    end
end

end)(); __m(U) end
-- ==== modules/combat/TargetMelee ====
do local __m = (function()
-- TargetMelee: perfect melee kill a un PLAYER (cheater). El melee usa TU posicion (grip manip NO sirve,
-- hay que estar cerca del target). Solucion = mismo approach que Soldier Farm: TRAER el target a vos
-- (HRP a un punto enfrente + CanCollide off) + void spoof (unhittable) + KnifeFire. Target = nearest-to-mouse.
-- Menos elegante (el player se ve traido) pero registra. Single-target.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Combat:AddSection("Target Melee", "Perfect melee kill a cheaters")
    local Pan = Sec:AddPanel("Target Melee", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("TMelee", { Text = "Enabled", Default = false,
        Tooltip = "Trae el target nearest-to-mouse a vos + KnifeFire. Void = intocable" })
        :AddKeybind({ Default = Enum.KeyCode.B })
    Pan:AddDropdown("TMWeapon", { Text = "Weapon", Values = { "Knife", "Katana" }, Default = "Knife" })
    Pan:AddToggle("TMAutoEquip", { Text = "Auto-Equip", Default = true })
    Pan:AddToggle("TMVoidSpoof", { Text = "Void Spoof (unhittable)", Default = true })
    Pan:AddToggle("TMTeamCheck", { Text = "Team Check", Default = false, Tooltip = "Off = cualquier player (cheaters)" })
    Pan:AddToggle("TMForceField", { Text = "ForceField Check", Default = true, Tooltip = "Salta targets con spawn protection" })
    Pan:AddSlider("TMDist", { Text = "Distance To Tool", Min = 0, Max = 12, Default = 2, Decimals = 1, Suffix = "studs" })
    Pan:AddSlider("TMRate", { Text = "Swing Interval", Min = 0.1, Max = 1, Default = 0.5, Decimals = 2, Suffix = "s" })

    local brng = 246813579
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end
    local function voidCF()
        local B = 2147483647
        local y = math.abs(rndS() * B); if y < 30 then y = 30 + y end
        return CFrame.new(rndS() * B, y, rndS() * B)
    end

    local function meleeTool()
        local name = F.TMWeapon or "Knife"
        for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
            if src then local t = src:FindFirstChild(name); if t and t:IsA("Tool") then return t end end
        end
    end
    local function equipMelee()
        local char = LP.Character; local t = meleeTool()
        if char and t and t.Parent ~= char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then pcall(function() h:EquipTool(t) end) end
        end
        return char and char:FindFirstChild(F.TMWeapon or "Knife")
    end
    local function fireRemote(tool)
        for _, c in ipairs(tool:GetChildren()) do
            if c:IsA("RemoteEvent") and c.Name ~= "PlayerCheck" then return c end
        end
    end

    -- target = char del player nearest al MOUSE, SIN check offscreen
    local function nearestToMouse()
        local cam = workspace.CurrentCamera
        local mp = UIS:GetMouseLocation()
        local best, bd
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local ff = F.TMForceField ~= false and c:FindFirstChildOfClass("ForceField")
                if hrp and hum and hum.Health > 0 and not ff and not (F.TMTeamCheck and LP.Team and plr.Team == LP.Team) then
                    local sp = cam:WorldToViewportPoint(hrp.Position)
                    local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if not bd or d < bd then bd, best = d, c end
                end
            end
        end
        return best
    end

    -- trae el target a un punto enfrente tuyo (CanCollide off = sin fling). Como el Soldier Farm.
    local function bringTarget(char, dist)
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local thrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hrp and thrp) then return end
        local point = hrp.Position + hrp.CFrame.LookVector * dist
        pcall(function()
            for _, p in ipairs(char:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
            thrp.CFrame = CFrame.new(point)
        end)
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.TMelee == true) then
            if wasActive then wasActive = false; pcall(Spoof.stop) end
            return
        end
        local tool = (F.TMAutoEquip ~= false and equipMelee()) or meleeTool()
        if not tool then return end
        local target = nearestToMouse()
        if not target then return end
        if F.TMVoidSpoof ~= false then Spoof.desyncTo(voidCF(), false) end
        bringTarget(target, F.TMDist or 2)
        wasActive = true
        acc = acc + dt
        local interval = math.max(F.TMRate or 0.5, 0.1)
        if acc < interval then return end
        acc = 0
        local fr = fireRemote(tool)
        if fr then pcall(function() fr:FireServer() end) end
    end)

    if U.Registry then
        U.Registry.Add("TargetMelee", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
        end })
    end
end

end)(); __m(U) end
-- ==== modules/combat/SilentAim ====
do local __m = (function()
-- SilentAim: hookea MouseEvent:FireServer y reescribe la pos al TARGET (nearest-to-mouse, SIN FOV check) +
-- prediccion (lead = dist/BulletSpeed * (Base+Amp)). Riddea tu fire real (con Autofire = auto-aim-fire ragebot).
-- Hook unico reload-safe (getgenv().__MBT_SA_HOOK); el load actual publica su handler en getgenv().__MBT_SA.
-- El server valida la pos vs tu posicion -> el usuario testea si registra (redirect off-aim historicamente rechazado).
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer

    local Sec = Combat:AddSection("Silent Aim", "Redirige tu tiro al target (sin FOV) + prediccion")
    local Pan = Sec:AddPanel("Silent Aim", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("SilentAim", { Text = "Enabled", Default = false,
        Tooltip = "Reescribe la pos de tu MouseEvent al target. Sin FOV. Combinar con Autofire" })
        :AddKeybind({ Default = Enum.KeyCode.K })
    Pan:AddDropdown("SilentSelect", { Text = "Selection", Values = { "Nearest Mouse", "Nearest Distance", "Lowest HP" }, Default = "Nearest Mouse" })
    Pan:AddDropdown("SilentHitbox", { Text = "Hitbox", Values = { "Head", "HumanoidRootPart", "UpperTorso" }, Default = "Head" })
    Pan:AddLabel("Prediction", { Header = true })
    Pan:AddToggle("SilentPredict", { Text = "Prediction", Default = true, Tooltip = "Lead = dist/BulletSpeed * (Base+Amp)" })
    Pan:AddTextBox("SilentPredBase", { Text = "Predict Base", Numeric = true, Default = "1.00000" })
    Pan:AddTextBox("SilentPredAmp", { Text = "Predict Amplitude", Numeric = true, Default = "0.00000" })
    Pan:AddLabel("Filters", { Header = true })
    Pan:AddToggle("SilentTeamCheck", { Text = "Team Check", Default = false })
    Pan:AddToggle("SilentFFCheck", { Text = "ForceField Check", Default = true })
    Pan:AddToggle("SilentVisible", { Text = "Visible Check", Default = false })

    -- velocidad por player (2 samples)
    local vhist = {}
    local velConn = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if r then
                    local h = vhist[plr]
                    if not h then vhist[plr] = { p = r.Position, t = now, v = Vector3.zero }
                    else local dt = now - h.t; if dt > 1e-3 then h.v = (r.Position - h.p) / dt; h.p = r.Position; h.t = now end end
                end
            end
        end
    end)
    local function targetVel(plr) local h = vhist[plr]; return h and h.v or Vector3.zero end

    -- target = player por Selection (Nearest Mouse SIN check offscreen / Nearest Distance / Lowest HP)
    local function pickTarget()
        local cam = workspace.CurrentCamera
        local mp = UIS:GetMouseLocation()
        local mode = F.SilentSelect or "Nearest Mouse"
        local part = F.SilentHitbox or "Head"
        local best, bestScore, bestPlr
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local ff = F.SilentFFCheck ~= false and c and c:FindFirstChildOfClass("ForceField")
                if hrp and hum and hum.Health > 0 and not ff and not (F.SilentTeamCheck and LP.Team and plr.Team == LP.Team) then
                    local score
                    if mode == "Nearest Distance" then
                        score = cam and (cam.CFrame.Position - hrp.Position).Magnitude or 0
                    elseif mode == "Lowest HP" then
                        score = hum.Health
                    else -- Nearest Mouse (sin FOV/offscreen)
                        local sp = cam:WorldToViewportPoint(hrp.Position)
                        score = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    end
                    if not bestScore or score < bestScore then
                        bestScore = score; bestPlr = plr; best = c:FindFirstChild(part) or hrp
                    end
                end
            end
        end
        return best, bestPlr
    end

    local function predictedPos(remote)
        local target, plr = pickTarget()
        if not target then return nil end
        local base = target.Position
        if F.SilentVisible then
            local cam = workspace.CurrentCamera; local origin = cam and cam.CFrame.Position
            if origin then
                local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
                rp.FilterDescendantsInstances = { LP.Character, cam }
                local res = workspace:Raycast(origin, base - origin, rp)
                if res and res.Instance and plr and plr.Character and not res.Instance:IsDescendantOf(plr.Character) then return nil end
            end
        end
        if F.SilentPredict then
            local weapon = remote.Parent
            local speed = 800
            local cfg = weapon and weapon:FindFirstChild("Configuration")
            if cfg and cfg:FindFirstChild("BulletSpeed") and cfg.BulletSpeed.Value > 0 then speed = cfg.BulletSpeed.Value end
            local cam = workspace.CurrentCamera
            local dist = cam and (cam.CFrame.Position - base).Magnitude or 0
            local mult = (tonumber(F.SilentPredBase) or 0) + (tonumber(F.SilentPredAmp) or 0)
            base = base + targetVel(plr) * ((speed > 0 and dist / speed or 0) * mult)
        end
        return base
    end

    -- handler que consulta el hook global
    getgenv().__MBT_SA = function(remote)
        if not F.SilentAim then return nil end
        local parent = remote.Parent
        if not (parent and parent:IsA("Tool") and parent:FindFirstChild("Configuration")) then return nil end
        return predictedPos(remote)
    end

    -- hook unico (reload-safe)
    if not getgenv().__MBT_SA_HOOK and typeof(hookmetamethod) == "function" then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local h = getgenv().__MBT_SA
            if h and typeof(self) == "Instance" and self.Name == "MouseEvent" then
                local isSelf = (typeof(checkcaller) == "function") and checkcaller() or false
                if not isSelf then
                    local ok, m = pcall(getnamecallmethod)
                    if ok and m == "FireServer" then
                        local okh, np = pcall(h, self)
                        if okh and typeof(np) == "Vector3" then return old(self, np) end
                    end
                end
            end
            return old(self, ...)
        end)
        getgenv().__MBT_SA_HOOK = true
    end

    if U.Registry then
        U.Registry.Add("SilentAim", { Unload = function()
            getgenv().__MBT_SA = nil -- desarma (hook queda inerte)
            if velConn then velConn:Disconnect() end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/visuals/ESP ====
do local __m = (function()
-- ESP: Drawing API (0 instancias = AC-safe). Players (box/name/health/dist/tracer, team color),
-- NPCs soldiers, Capture Points, Crates. Pool de Drawings reusado por-frame (sin churn).
return function(U)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Visuals = U.Tabs.Visuals
    local F = U.Flags

    if not Drawing then
        Visuals:AddSection("ESP", "no disponible"):AddPanel("ESP", { Column = 1 })
            :AddLabel("Drawing API no soportada por tu executor", { Header = true })
        return
    end

    local Sec = Visuals:AddSection("ESP", "World ESP (Drawing)")
    local P1 = Sec:AddPanel("Players", { Column = 1 })
    P1:AddLabel("Master", { Header = true })
    P1:AddToggle("ESPEnable", { Text = "Enabled", Default = false })
    P1:AddToggle("ESPEnemyOnly", { Text = "Enemy Only", Default = true, Tooltip = "Oculta tu equipo (Team)" })
    P1:AddSlider("ESPMaxDist", { Text = "Max Distance", Min = 100, Max = 5000, Default = 2000, Suffix = "studs" })
    P1:AddLabel("Players", { Header = true })
    P1:AddToggle("ESPBox", { Text = "Box", Default = true })
    P1:AddToggle("ESPName", { Text = "Name", Default = true })
    P1:AddToggle("ESPHealth", { Text = "Health Bar", Default = true })
    P1:AddToggle("ESPDist", { Text = "Distance", Default = false })
    P1:AddToggle("ESPTracer", { Text = "Tracer", Default = false })
    P1:AddColorPicker("ESPEnemyColor", { Text = "Enemy", Default = Color3.fromRGB(235, 60, 60) })
    P1:AddColorPicker("ESPAllyColor", { Text = "Ally", Default = Color3.fromRGB(70, 200, 90) })

    local P2 = Sec:AddPanel("World", { Column = 2 })
    P2:AddLabel("NPCs", { Header = true })
    P2:AddToggle("ESPNpc", { Text = "Soldiers", Default = false })
        :AddColorPicker("ESPNpcColor", { Default = Color3.fromRGB(240, 160, 40) })
    P2:AddLabel("Objectives", { Header = true })
    P2:AddToggle("ESPFlags", { Text = "Capture Points", Default = false })
        :AddColorPicker("ESPFlagColor", { Default = Color3.fromRGB(120, 170, 255) })
    P2:AddToggle("ESPCrates", { Text = "Crates", Default = false })
        :AddColorPicker("ESPCrateColor", { Default = Color3.fromRGB(200, 200, 120) })

    ----------------------------------------------------------------- Drawing pool
    local function Pool(kind)
        local p = { items = {}, used = 0 }
        function p:get()
            self.used = self.used + 1
            local it = self.items[self.used]
            if not it then it = Drawing.new(kind); self.items[self.used] = it end
            it.Visible = true
            return it
        end
        function p:hideRest()
            for i = self.used + 1, #self.items do self.items[i].Visible = false end
            self.used = 0
        end
        function p:clear()
            for _, it in ipairs(self.items) do pcall(function() it:Remove() end) end
            self.items = {}; self.used = 0
        end
        return p
    end
    local boxes, texts, lines, bars = Pool("Square"), Pool("Text"), Pool("Line"), Pool("Square")

    local function W2S(pos)
        local c = workspace.CurrentCamera
        local v, on = c:WorldToViewportPoint(pos)
        return Vector2.new(v.X, v.Y), on and v.Z > 0, v.Z
    end
    local function camPos() local c = workspace.CurrentCamera; return c and c.CFrame.Position end

    local function text(str, pos, col, center)
        local t = texts:get()
        t.Text = str; t.Size = 13; t.Color = col; t.Center = center == true; t.Outline = true
        t.Position = pos
    end

    -- dibuja box + extras a partir de head/hrp de un character
    local function drawChar(char, hum, col, opts)
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
        if not head or not hrp then return end
        local topS, onT = W2S(head.Position + Vector3.new(0, 0.7, 0))
        local botS, onB = W2S(hrp.Position - Vector3.new(0, 3.2, 0))
        if not (onT and onB) then return end
        local h = math.abs(botS.Y - topS.Y)
        local w = h * 0.5
        local x, y = topS.X - w / 2, topS.Y
        if opts.box then
            local b = boxes:get()
            b.Position = Vector2.new(x, y); b.Size = Vector2.new(w, h)
            b.Color = col; b.Thickness = 1; b.Filled = false
        end
        if opts.name and opts.nameStr then
            text(opts.nameStr, Vector2.new(x + w / 2, y - 15), col, true)
        end
        if opts.health and hum then
            local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            local bg = bars:get()
            bg.Position = Vector2.new(x - 5, y); bg.Size = Vector2.new(2, h); bg.Color = Color3.new(0, 0, 0)
            bg.Filled = true; bg.Thickness = 1
            local hb = bars:get()
            hb.Size = Vector2.new(2, h * frac)
            hb.Position = Vector2.new(x - 5, y + h * (1 - frac))
            hb.Color = Color3.fromRGB(math.floor(255 * (1 - frac)), math.floor(255 * frac), 60)
            hb.Filled = true; hb.Thickness = 1
        end
        if opts.dist and opts.distVal then
            text(string.format("%dm", opts.distVal), Vector2.new(x + w / 2, y + h + 2), col, true)
        end
        if opts.tracer then
            local ln = lines:get()
            local vp = workspace.CurrentCamera.ViewportSize
            ln.From = Vector2.new(vp.X / 2, vp.Y); ln.To = Vector2.new(x + w / 2, y + h)
            ln.Color = col; ln.Thickness = 1
        end
    end

    local function render()
        boxes.used, texts.used, lines.used, bars.used = 0, 0, 0, 0
        if F.ESPEnable then
            local cp = camPos()
            local maxd = F.ESPMaxDist or 2000
            -- Players
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if char and hum and hrp and hum.Health > 0 then
                        local enemy = not (LP.Team and plr.Team == LP.Team)
                        if enemy or not F.ESPEnemyOnly then
                            local d = cp and (hrp.Position - cp).Magnitude or 0
                            if d <= maxd then
                                local col = enemy and (F.ESPEnemyColor or Color3.new(1, 0, 0)) or (F.ESPAllyColor or Color3.new(0, 1, 0))
                                drawChar(char, hum, col, {
                                    box = F.ESPBox, name = F.ESPName, nameStr = plr.Name,
                                    health = F.ESPHealth, dist = F.ESPDist, distVal = math.floor(d / 3.57),
                                    tracer = F.ESPTracer,
                                })
                            end
                        end
                    end
                end
            end
            -- NPCs (soldiers)
            if F.ESPNpc then
                local folder = workspace:FindFirstChild("NPCs")
                if folder then
                    for _, npc in ipairs(folder:GetChildren()) do
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 then
                            local d = cp and (hrp.Position - cp).Magnitude or 0
                            if d <= maxd then
                                drawChar(npc, hum, F.ESPNpcColor or Color3.fromRGB(240, 160, 40), {
                                    box = true, name = true, nameStr = npc.Name, health = true,
                                })
                            end
                        end
                    end
                end
            end
            -- Capture Points + Crates: label + distancia
            local function labelFolder(folderName, on, col)
                if not on then return end
                local folder = workspace:FindFirstChild(folderName)
                if not folder then return end
                for _, m in ipairs(folder:GetChildren()) do
                    local pos = m:IsA("BasePart") and m.Position or (m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")).Position)
                    if pos then
                        local s, on2 = W2S(pos)
                        local d = cp and (pos - cp).Magnitude or 0
                        if on2 and d <= maxd then
                            text(m.Name .. " [" .. math.floor(d / 3.57) .. "m]", s, col, true)
                        end
                    end
                end
            end
            labelFolder("CapturePoints", F.ESPFlags, F.ESPFlagColor or Color3.fromRGB(120, 170, 255))
            labelFolder("Crates", F.ESPCrates, F.ESPCrateColor or Color3.fromRGB(200, 200, 120))
        end
        boxes:hideRest(); texts:hideRest(); lines:hideRest(); bars:hideRest()
    end

    local conn = RunService.RenderStepped:Connect(render)

    if U.Registry then
        U.Registry.Add("ESP", { Unload = function()
            if conn then conn:Disconnect() end
            boxes:clear(); texts:clear(); lines:clear(); bars:clear()
        end })
    end
end

end)(); __m(U) end
-- ==== modules/tycoon/AutoBuy ====
do local __m = (function()
-- AutoBuy: teleporta el HRP sobre cada boton asequible (toque real = server valida posicion OK).
-- firetouchinterest/RequestPurch remotos NO compran (server valida posicion real). Este juego NO
-- tiene AC de desplazamiento -> teleport seguro. Compra confirmada cuando Head.Transparency->1.
return function(U)
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Tycoon = U.Tabs.Tycoon
    local F = U.Flags

    local Sec = Tycoon:AddSection("Auto Buy", "Teleporta a los botones y compra")
    local Pan = Sec:AddPanel("Auto Buy", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("AutoBuy", { Text = "Auto Buy", Default = false,
        Tooltip = "Teleporta a cada boton asequible. Usar en base/seguro (te mueve)" })
    Pan:AddSlider("AutoBuyRate", { Text = "Buys / sec", Min = 1, Max = 15, Default = 6 })
    Pan:AddSlider("AutoBuyMaxPrice", { Text = "Max Price", Min = 0, Max = 100000000, Default = 0, OffAtMin = true, Tooltip = "0 = sin limite" })
    Pan:AddSlider("AutoBuyTimeout", { Text = "Confirm Timeout", Min = 0.1, Max = 1, Default = 0.4, Decimals = 2, Suffix = "s",
        Tooltip = "Espera a que el server confirme la compra antes del siguiente" })
    Pan:AddToggle("AutoBuyReturn", { Text = "Return To Start", Default = true, Tooltip = "Vuelve a tu posicion al terminar/apagar" })
    Pan:AddToggle("AutoBuyCashOnly", { Text = "Cash Only (skip R$/Rebirth)", Default = true,
        Tooltip = "Salta botones robux (R$), rebirth/renacimiento y VIP/gamepass" })

    -- botones que NO son compra de cash normal (no comprar con AutoBuy)
    local SPECIAL = { "r%$", "robux", "rebirth", "renacimiento", "vip", "gamepass" }
    local function isSpecial(name)
        local n = name:lower()
        for _, pat in ipairs(SPECIAL) do if n:find(pat) then return true end end
        return false
    end

    -- mi plot = inner Model (BrickColor) con Owner==LP dentro de workspace.Tycoons.<Color>
    local function myPlot()
        local T = workspace:FindFirstChild("Tycoons")
        if not T then return nil end
        for _, plot in ipairs(T:GetChildren()) do
            local inner = plot:FindFirstChildWhichIsA("Model")
            local owner = inner and inner:FindFirstChild("Owner")
            if owner and owner.Value == LP and inner:FindFirstChild("Buttons") and inner:FindFirstChild("Cash") then
                return inner
            end
        end
        return nil
    end

    local function pickButton(plot, cash, maxp)
        local best, bestP
        for _, btn in ipairs(plot.Buttons:GetChildren()) do
            local head = btn:FindFirstChild("Head")
            local price = btn:FindFirstChild("Price")
            if head and price and price.Value > 0
                and head.Transparency < 1 and head.CanTouch ~= false
                and price.Value <= cash and (maxp == 0 or price.Value <= maxp)
                and not (F.AutoBuyCashOnly ~= false and isSpecial(btn.Name)) then
                if not bestP or price.Value < bestP then best, bestP = head, price.Value end
            end
        end
        return best
    end

    local state = { alive = true, running = false, startCF = nil }

    local function hrpOf()
        local char = LP.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function run()
        if state.running then return end
        state.running = true
        task.spawn(function()
            state.startCF = (hrpOf() and hrpOf().CFrame) or state.startCF
            while F.AutoBuy and state.alive do
                local hrp = hrpOf()
                local plot = myPlot()
                if hrp and plot then
                    local head = pickButton(plot, plot.Cash.Value, F.AutoBuyMaxPrice or 0)
                    if head then
                        hrp.CFrame = CFrame.new(head.Position)
                        -- espera confirmacion del server (Transparency->1) o timeout
                        local deadline = os.clock() + (F.AutoBuyTimeout or 0.4)
                        repeat
                            task.wait()
                        until head.Transparency >= 1 or head.CanTouch == false or os.clock() > deadline or not F.AutoBuy
                    else
                        task.wait(0.3) -- nada asequible: esperar que suba el cash
                    end
                else
                    task.wait(0.3)
                end
                local rate = math.clamp(F.AutoBuyRate or 6, 1, 15)
                task.wait(1 / rate)
            end
            -- volver a la posicion inicial
            if F.AutoBuyReturn and state.startCF then
                local hrp = hrpOf()
                if hrp then pcall(function() hrp.CFrame = state.startCF end) end
            end
            state.running = false
        end)
    end

    -- arranca el loop cuando el flag se enciende (watcher liviano)
    local RunService = game:GetService("RunService")
    local watch = RunService.Heartbeat:Connect(function()
        if F.AutoBuy and not state.running then run() end
    end)

    if U.Registry then
        U.Registry.Add("AutoBuy", { Unload = function()
            state.alive = false
            if watch then watch:Disconnect() end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/tycoon/CrateFarm ====
do local __m = (function()
-- CrateFarm: colecta las crates de workspace.Crates (Crate=Cash+XP, GunCrate=arma). Colección = TOUCH
-- (tienen TouchInterest, sin prompt/click). Metodo Touch = firetouchinterest(crate, HRP) dispara el .Touched
-- sin moverte. Si el server valida posicion (no colecta), usar Teleport To Crate (overlap real).
return function(U)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Tycoon = U.Tabs.Tycoon
    local F = U.Flags

    local Sec = Tycoon:AddSection("Crate Farm", "Colecta Crates/GunCrates (cash + armas)")
    local Pan = Sec:AddPanel("Crate Farm", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("CrateFarm", { Text = "Enabled", Default = false, Tooltip = "Colecta todas las crates en loop" })
        :AddKeybind({ Default = Enum.KeyCode.G })
    Pan:AddDropdown("CrateMethod", { Text = "Method", Values = { "Touch", "Teleport To Crate" }, Default = "Touch",
        Tooltip = "Touch=firetouchinterest sin moverte. Teleport=overlap real (si Touch no colecta)" })
    Pan:AddSlider("CrateRate", { Text = "Crates / sec", Min = 1, Max = 20, Default = 4 })
    Pan:AddToggle("CrateReturn", { Text = "Return To Start (teleport)", Default = true })

    if typeof(firetouchinterest) ~= "function" then
        Pan:AddLabel("firetouchinterest no soportado por tu executor", { Header = true })
    end

    local function hrpOf() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    local state = { alive = true, running = false, startCF = nil }
    -- dedupe: cada crate se colecta 1 SOLA vez (evita floodear loot = crash). Respawn = instancia nueva.
    local collected = setmetatable({}, { __mode = "k" })

    local function run()
        if state.running then return end
        state.running = true
        task.spawn(function()
            state.startCF = (hrpOf() and hrpOf().CFrame) or state.startCF
            while F.CrateFarm and state.alive do
                local Crates = workspace:FindFirstChild("Crates")
                local h = hrpOf()
                if Crates and h then
                    for _, c in ipairs(Crates:GetChildren()) do
                        if not (F.CrateFarm and state.alive) then break end
                        if c:IsA("BasePart") then
                            if F.CrateMethod == "Teleport To Crate" then
                                pcall(function() h.CFrame = CFrame.new(c.Position) end)
                                task.wait(1 / math.clamp(F.CrateRate or 4, 1, 20))
                            elseif not collected[c] then
                                collected[c] = true -- 1 sola vez por crate
                                pcall(function()
                                    firetouchinterest(c, h, 0)
                                    firetouchinterest(c, h, 1)
                                end)
                                task.wait(1 / math.clamp(F.CrateRate or 4, 1, 20))
                            end
                        end
                    end
                    if F.CrateMethod == "Teleport To Crate" and F.CrateReturn and state.startCF then
                        pcall(function() hrpOf().CFrame = state.startCF end)
                    end
                else
                    task.wait(0.3)
                end
                task.wait(0.1) -- SIEMPRE espera por scan: evita busy-spin cuando no quedan crates = lag/crash
            end
            state.running = false
        end)
    end

    local watch = RunService.Heartbeat:Connect(function()
        if F.CrateFarm and not state.running then run() end
    end)

    if U.Registry then
        U.Registry.Add("CrateFarm", { Unload = function()
            state.alive = false
            if watch then watch:Disconnect() end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/tycoon/SoldierFarm ====
do local __m = (function()
-- MeleeAura: melee farm hit-safe. Un toggle: (auto-)equip melee + void spoof (unhittable) + gather nearest
-- pocos a rango del tool (CanCollide=false = sin fling) + spam del fire remote. Fire = single-target (mata 1/swing).
-- Weapon select (Knife/Katana). Fire remote generico = el RemoteEvent del tool != PlayerCheck (KnifeFire/KatanaFire).
-- Soldados = clientside (daño en tu pos real). Avatar mini = hitbox chica -> traer soldados mas cerca (GatherDist).
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Tab = U.Tabs.Tycoon
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Tab:AddSection("Soldier Farm", "Knife/Katana farm unhittable (void + gather)")
    local Pan = Sec:AddPanel("Soldier Farm", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("MeleeAura", { Text = "Enabled", Default = false,
        Tooltip = "Todo-en-uno: equip + void spoof + gather + fire" })
        :AddKeybind({ Default = Enum.KeyCode.V })
    Pan:AddDropdown("MeleeWeapon", { Text = "Weapon", Values = { "Knife", "Katana" }, Default = "Knife" })
    Pan:AddToggle("MeleeAutoEquip", { Text = "Auto-Equip", Default = true, Tooltip = "Off = equipas el melee vos" })
    Pan:AddToggle("MeleeVoidSpoof", { Text = "Void Spoof (unhittable)", Default = true })
    Pan:AddLabel("Gather", { Header = true })
    Pan:AddToggle("MeleeGather", { Text = "Gather Soldiers", Default = true,
        Tooltip = "Trae nearest a rango del tool (CanCollide off = sin fling)" })
    Pan:AddSlider("MeleeGatherCount", { Text = "Gather Count", Min = 1, Max = 8, Default = 3, Suffix = "npc" })
    Pan:AddSlider("MeleeGatherDist", { Text = "Distance To Tool", Min = 0, Max = 12, Default = 2, Decimals = 1, Suffix = "studs",
        Tooltip = "Que tan cerca traer los soldados (avatar mini = mas cerca)" })
    Pan:AddSlider("MeleeRange", { Text = "Search Range", Min = 20, Max = 1000, Default = 300, Suffix = "studs" })
    Pan:AddSlider("MeleeRate", { Text = "Swing Interval", Min = 0.1, Max = 1, Default = 0.5, Decimals = 2, Suffix = "s" })

    local brng = 135797531
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end
    local function voidCF()
        local B = 2147483647
        local y = math.abs(rndS() * B); if y < 30 then y = 30 + y end
        return CFrame.new(rndS() * B, y, rndS() * B)
    end

    local function meleeTool()
        local name = F.MeleeWeapon or "Knife"
        for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
            if src then local t = src:FindFirstChild(name); if t and t:IsA("Tool") then return t end end
        end
    end
    local function equipMelee()
        local char = LP.Character; local t = meleeTool()
        if char and t and t.Parent ~= char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then pcall(function() h:EquipTool(t) end) end
        end
        return char and char:FindFirstChild(F.MeleeWeapon or "Knife")
    end
    -- fire remote generico: el RemoteEvent del tool que no es PlayerCheck (KnifeFire / KatanaFire / etc)
    local function fireRemote(tool)
        for _, c in ipairs(tool:GetChildren()) do
            if c:IsA("RemoteEvent") and c.Name ~= "PlayerCheck" then return c end
        end
    end

    local function nearestSoldiers(count, range)
        local NPCs = workspace:FindFirstChild("NPCs")
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not (NPCs and hrp) then return {} end
        local list = {}
        for _, m in ipairs(NPCs:GetChildren()) do
            local r = m:FindFirstChild("HumanoidRootPart")
            local h = m:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                if d <= range then list[#list + 1] = { m = m, r = r, d = d } end
            end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        while #list > count do table.remove(list) end
        return list
    end
    local function gather(count, range, dist)
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local point = hrp.Position + hrp.CFrame.LookVector * dist
        for _, e in ipairs(nearestSoldiers(count, range)) do
            pcall(function()
                for _, p in ipairs(e.m:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                e.r.CFrame = CFrame.new(point)
            end)
        end
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.MeleeAura == true) then
            if wasActive then wasActive = false; pcall(Spoof.stop) end
            return
        end
        local tool = (F.MeleeAutoEquip ~= false and equipMelee()) or meleeTool()
        if not tool then return end
        if F.MeleeVoidSpoof ~= false then Spoof.desyncTo(voidCF(), false) end
        if F.MeleeGather ~= false then gather(math.floor(F.MeleeGatherCount or 3), F.MeleeRange or 300, F.MeleeGatherDist or 2) end
        wasActive = true
        acc = acc + dt
        local interval = math.max(F.MeleeRate or 0.5, 0.1)
        if acc < interval then return end
        acc = 0
        local fr = fireRemote(tool)
        if fr then pcall(function() fr:FireServer() end) end
    end)

    if U.Registry then
        U.Registry.Add("SoldierFarm", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
        end })
    end
end

end)(); __m(U) end
-- ==== modules/misc/ClientDesync ====
do local __m = (function()
-- ClientDesync: desync de TU pos (defensa anti-ragebot). El server te ve orbitando/saltando alrededor
-- de tu pos real; tu cuerpo/camara reales quedan quietos (camLock). Separado del Target Strafe (ofensa).
return function(U)
    local RunService = game:GetService("RunService")
    local Workspace  = game:GetService("Workspace")
    local Misc = U.Tabs.Misc
    local F = U.Flags
    local Spoof = U.Services.Spoof

    local Sec = Misc:AddSection("Client Desync", "Desync propio (anti-ragebot)")
    local Pan = Sec:AddPanel("Client Desync", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("DesyncEnable", { Text = "Enabled", Default = false,
        Tooltip = "El server te ve desincronizado de tu pos real; te quedas quieto en pantalla" })
        :AddKeybind({ Mode = "Toggle", Default = Enum.KeyCode.X })
    Pan:AddDropdown("DesyncMode", { Text = "Mode", Values = { "Orbit", "Random", "Static Up" }, Default = "Random",
        Tooltip = "Random = XYZ random/frame en el rango (mas dificil de resolver)" })
    Pan:AddSlider("DesyncRadius", { Text = "Radius", Min = 2, Max = 100, Default = 20, Suffix = "studs" })
    Pan:AddSlider("DesyncSpeed", { Text = "Speed", Min = 1, Max = 40, Default = 16 })
    Pan:AddSlider("DesyncHeight", { Text = "Height", Min = -20, Max = 20, Default = 0, Suffix = "studs" })
    Pan:AddToggle("DesyncMarker", { Text = "Show Marker", Default = true })
        :AddColorPicker("DesyncMarkerColor", { Default = Color3.fromRGB(120, 170, 255) })

    local brng = 424242123
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end

    local seed = 0
    local function fakePosFrom(realPos)
        local R, spd, h = F.DesyncRadius or 20, F.DesyncSpeed or 16, F.DesyncHeight or 0
        local mode = F.DesyncMode or "Random"
        if mode == "Static Up" then
            return realPos + Vector3.new(0, R, 0)
        elseif mode == "Random" then
            return realPos + Vector3.new(rndS() * R, h + rndS() * R, rndS() * R)
        else -- Orbit
            seed = seed + spd * 0.05
            return realPos + Vector3.new(math.cos(seed) * R, h, math.sin(seed) * R)
        end
    end

    local mC, mT, mL
    if Drawing then
        mC = Drawing.new("Circle"); mC.Thickness = 2; mC.NumSides = 32; mC.Filled = false; mC.Radius = 7; mC.Visible = false
        mT = Drawing.new("Text"); mT.Size = 14; mT.Center = true; mT.Outline = true; mT.Visible = false
        mL = Drawing.new("Line"); mL.Thickness = 1; mL.Visible = false
    end
    local UIS = game:GetService("UserInputService")
    local function hideMarker() if mC then mC.Visible = false; mT.Visible = false; mL.Visible = false end end
    local function drawMarker(pos)
        if not mC or not pos then return end
        local cam = Workspace.CurrentCamera
        local v = cam:WorldToViewportPoint(pos); local on = v.Z > 0
        mC.Visible = on; mT.Visible = on; mL.Visible = on
        if on then
            local col = F.DesyncMarkerColor or Color3.fromRGB(120, 170, 255)
            local p = Vector2.new(v.X, v.Y)
            mC.Position = p; mC.Color = col
            mT.Position = p + Vector2.new(0, 10); mT.Text = "DESYNC"; mT.Color = col
            mL.From = UIS:GetMouseLocation(); mL.To = p; mL.Color = col
        end
    end

    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function()
        if not (F.DesyncEnable == true) then
            if wasActive then wasActive = false; Spoof.stop() end
            hideMarker()
            return
        end
        local root = Spoof.myRoot(); if not root then return end
        local realCF = Spoof.captureReal(root)
        local fakePos = fakePosFrom(realCF.Position)
        Spoof.desyncTo(CFrame.new(fakePos) * realCF.Rotation, true) -- camLock: te quedas quieto en pantalla
        if F.DesyncMarker and Drawing then drawMarker(Spoof.fakePos()) else hideMarker() end
        wasActive = true
    end)

    if U.Registry then
        U.Registry.Add("ClientDesync", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
            hideMarker()
            for _, d in ipairs({ mC, mT, mL }) do if d then pcall(function() d:Remove() end) end end
        end })
    end
end

end)(); __m(U) end
-- ==== modules/misc/About ====
do local __m = (function()
-- About: contenido visible para verificar el pipeline UI + módulos vivo
return function(U)
    local Misc = U.Tabs.Misc
    local Sec = Misc:AddSection("About", "Base Militar Tycoon suite")
    local Pan = Sec:AddPanel("Info", { Column = 1 })
    Pan:AddLabel("MilitaryBasePrimordial", { Header = true })
    Pan:AddLabel("place 23380021 · Base Militar Tycoon")
    Pan:AddLabel("v0 · scaffold")
    Pan:AddDivider()
    Pan:AddLabel("Toggle UI: RightShift", { Header = true })
end

end)(); __m(U) end
-- ==== finalize ====
do local __m = (function()
-- corre ultimo: envuelve Unload para limpiar modulos+servicios, watermark, notifica
return function(U)
    -- envuelve Lib:Unload para que el boton Unload/ToggleKey limpie modulos+servicios
    -- (Drawing/ESP + conexiones Heartbeat), que PrimordialUI no conoce
    local rawUnload = U.Library.Unload
    U.Library.Unload = function(self)
        if U.Registry then pcall(U.Registry.UnloadAll) end
        for _, s in pairs(U.Services) do
            if type(s) == "table" and s.Unload then pcall(s.Unload) end
        end
        return rawUnload(self)
    end
    -- cleanup global reutilizable: lo llama el proximo load (bootstrap) para no dejar fugas
    getgenv().__MBT_CLEANUP = function() pcall(function() U.Library:Unload() end) end
    -- defer: el Settings tab roba foco al crearse; forzamos Combat tras el frame
    task.defer(function() U.Window:SetActiveCategory(U.Tabs.Combat) end)
    U.Library:SetWatermark("military base | dev")
    U.Library:Notify({ Title = "MilitaryBasePrimordial", Description = "cargado", Time = 3 })
    print("[MBT] loaded")
end

end)(); __m(U) end
return U
