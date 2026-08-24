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
