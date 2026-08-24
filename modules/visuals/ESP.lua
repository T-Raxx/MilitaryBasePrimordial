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
