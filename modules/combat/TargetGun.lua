-- TargetGun: ragebot gun "inventado" pa' el juego. El silent redirect muere (server valida la pos del fire).
-- Truco: en vez de redirigir el tiro (rechazado), GATHER el target ENFRENTE de tu camara + fire MouseEvent al
-- crosshair-forward (raycast camara = pos VALIDA que pega al target ahi). No es redirect -> el server acepta.
-- Si el gun daña clientside como el melee -> registra. Experimental (el user testea). FF/team check.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer

    local Sec = Combat:AddSection("Target Gun", "Ragebot gun: gather target + fire (experimental)")
    local Pan = Sec:AddPanel("Target Gun", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("TGun", { Text = "Enabled", Default = false,
        Tooltip = "Trae el target enfrente + dispara al crosshair (pos valida). Rapidfire" })
        :AddKeybind({ Default = Enum.KeyCode.N })
    Pan:AddToggle("TGunTeamCheck", { Text = "Team Check", Default = false })
    Pan:AddToggle("TGunFFCheck", { Text = "ForceField Check", Default = true })
    Pan:AddSlider("TGunDist", { Text = "Front Distance", Min = 3, Max = 30, Default = 8, Suffix = "studs",
        Tooltip = "Que tan enfrente de tu camara traer el target" })
    Pan:AddSlider("TGunRate", { Text = "Fire Interval", Min = 0.05, Max = 1, Default = 0.1, Decimals = 2, Suffix = "s",
        Tooltip = "0 = usa FireRate del arma. Muy rapido puede lockear" })
    Pan:AddToggle("TGunUseWeaponRate", { Text = "Use Weapon FireRate", Default = true })

    -- gun equipado = Tool con MouseEvent + Configuration.BulletSpeed (los melee NO tienen BulletSpeed)
    local function equippedGun()
        local char = LP.Character
        if not char then return end
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("MouseEvent") then
                local cfg = t:FindFirstChild("Configuration")
                if cfg and cfg:FindFirstChild("BulletSpeed") then return t end
            end
        end
    end

    local function nearestToMouse()
        local cam = workspace.CurrentCamera
        local mp = UIS:GetMouseLocation()
        local best, bd
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local ff = F.TGunFFCheck ~= false and c and c:FindFirstChildOfClass("ForceField")
                if hrp and hum and hum.Health > 0 and not ff and not (F.TGunTeamCheck and LP.Team and plr.Team == LP.Team) then
                    local sp = cam:WorldToViewportPoint(hrp.Position)
                    local d = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    if not bd or d < bd then bd, best = d, c end
                end
            end
        end
        return best
    end

    -- trae el target enfrente de la camara (CanCollide off). El fire va al crosshair -> pega al target ahi.
    local function bringToFront(char, dist)
        local cam = workspace.CurrentCamera
        local thrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (cam and thrp) then return end
        local point = cam.CFrame.Position + cam.CFrame.LookVector * dist
        pcall(function()
            for _, p in ipairs(char:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
            thrp.CFrame = CFrame.new(point)
        end)
    end

    -- pos del fire = hit del raycast camara-centro (VALIDA, misma que el client legit). Pega al target enfrente.
    local function crosshairHit(gun)
        local cam = workspace.CurrentCamera
        local cfg = gun:FindFirstChild("Configuration")
        local range = (cfg and cfg:FindFirstChild("BulletRange") and cfg.BulletRange.Value) or 800
        local ray = cam:ViewportPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { LP.Character, cam }
        local res = workspace:Raycast(ray.Origin, ray.Direction * range, rp)
        return res and res.Position or (ray.Origin + ray.Direction * range)
    end

    local acc = 0
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.TGun == true) then acc = 0; return end
        local gun = equippedGun()
        if not gun then return end
        local target = nearestToMouse()
        if not target then return end
        bringToFront(target, F.TGunDist or 8)
        acc = acc + dt
        local interval = F.TGunUseWeaponRate ~= false
            and ((gun:FindFirstChild("Configuration") and gun.Configuration:FindFirstChild("FireRate") and gun.Configuration.FireRate.Value) or 0.2)
            or (F.TGunRate or 0.1)
        interval = math.max(interval, 0.05)
        if acc < interval then return end
        acc = 0
        local me = gun:FindFirstChild("MouseEvent")
        if me then pcall(function() me:FireServer(crosshairHit(gun)) end) end
    end)

    if U.Registry then
        U.Registry.Add("TargetGun", { Unload = function() if driver then driver:Disconnect() end end })
    end
end
