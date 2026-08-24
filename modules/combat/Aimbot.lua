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
