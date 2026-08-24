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
