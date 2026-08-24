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
    Pan:AddDropdown("StrafeResolver", { Text = "Resolver", Values = { "Off", "Cluster", "Density" }, Default = "Off",
        Tooltip = "Resuelve la pos real si el target anti-aimea (Cluster=juju void-spam, Density=sakura/Unnamed)" })
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
        local plr = Players:GetPlayerFromCharacter(char)
        local rawPos = tHRP.Position
        local center = (plr and U.Services.Resolver and U.Services.Resolver.resolvePos(plr, rawPos, F.StrafeResolver)) or rawPos
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
