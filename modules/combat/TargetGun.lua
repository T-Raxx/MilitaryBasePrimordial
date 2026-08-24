-- TargetGun: ragebot gun (VERIFICADO live, hitmarkers verdes). Balas = daño SERVER-SIDE. Metodo inventado:
-- DESYNC tu server-pos AL target (offset LOS) + fire MouseEvent(target) point-blank valido -> la bala pega.
-- Cliente queda quieto (hook __index). Polish: prediction (lead move/fly) + sticky target (estabilidad).
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Combat:AddSection("Target Gun", "Ragebot gun (desync-to-target, balas serverside)")
    local Pan = Sec:AddPanel("Target Gun", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("TGun", { Text = "Enabled", Default = false,
        Tooltip = "Desync tu server-pos al target -> fire point-blank valido -> la bala pega. Vos quedas quieto" })
        :AddKeybind({ Default = Enum.KeyCode.N })
    Pan:AddDropdown("TGunSelect", { Text = "Selection", Values = { "Nearest Mouse", "Nearest Distance", "Lowest HP" }, Default = "Nearest Mouse" })
    Pan:AddDropdown("TGunHitbox", { Text = "Hitbox", Values = { "HumanoidRootPart", "Head", "UpperTorso" }, Default = "HumanoidRootPart" })
    Pan:AddToggle("TGunSticky", { Text = "Sticky Target", Default = true, Tooltip = "Manten el target lockeado (estable)" })
    Pan:AddToggle("TGunTeamCheck", { Text = "Team Check", Default = false })
    Pan:AddToggle("TGunFFCheck", { Text = "ForceField Check", Default = true })
    Pan:AddLabel("Fire", { Header = true })
    Pan:AddSlider("TGunRate", { Text = "Fire Interval", Min = 0.05, Max = 1, Default = 0.1, Decimals = 2, Suffix = "s" })
    Pan:AddToggle("TGunUseWeaponRate", { Text = "Use Weapon FireRate", Default = true })
    Pan:AddSlider("TGunOffset", { Text = "Offset From Target", Min = 0, Max = 15, Default = 4, Suffix = "studs" })
    Pan:AddLabel("Prediction", { Header = true })
    Pan:AddToggle("TGunPredict", { Text = "Prediction (lead)", Default = true, Tooltip = "Lidera al target (move/fly)" })
    Pan:AddToggle("TGunUsePing", { Text = "Auto Lead (ping)", Default = true, Tooltip = "Lead = tu ping. Off = slider" })
    Pan:AddSlider("TGunLead", { Text = "Lead Time", Min = 0, Max = 0.4, Default = 0.08, Decimals = 3, Suffix = "s" })
    Pan:AddDropdown("TGunResolver", { Text = "Resolver", Values = { "Off", "Cluster", "Density" }, Default = "Off",
        Tooltip = "Resuelve la pos real si el target anti-aimea (Cluster=juju, Density=sakura)" })

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

    local function valid(plr)
        local c = plr and plr.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local ff = F.TGunFFCheck ~= false and c and c:FindFirstChildOfClass("ForceField")
        return hrp and hum and hum.Health > 0 and not ff
            and not (F.TGunTeamCheck and LP.Team and plr.Team == LP.Team)
    end

    local lockedUID
    local function pickTarget()
        -- sticky: si el lockeado sigue valido, mantenelo
        if F.TGunSticky and lockedUID then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.UserId == lockedUID and valid(plr) then return plr end
            end
            lockedUID = nil
        end
        local cam = workspace.CurrentCamera
        local mp = UIS:GetMouseLocation()
        local mode = F.TGunSelect or "Nearest Mouse"
        local best, bestScore
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and valid(plr) then
                local hrp = plr.Character.HumanoidRootPart
                local score
                if mode == "Nearest Distance" then
                    score = cam and (cam.CFrame.Position - hrp.Position).Magnitude or 0
                elseif mode == "Lowest HP" then
                    score = plr.Character:FindFirstChildOfClass("Humanoid").Health
                else
                    local sp = cam:WorldToViewportPoint(hrp.Position)
                    score = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                end
                if not bestScore or score < bestScore then bestScore = score; best = plr end
            end
        end
        if best then lockedUID = best.UserId end
        return best
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.TGun == true) then
            if wasActive then wasActive = false; lockedUID = nil; pcall(Spoof.stop) end
            return
        end
        local gun = equippedGun()
        if not gun then return end
        local plr = pickTarget()
        local char = plr and plr.Character
        local hitbox = char and (char:FindFirstChild(F.TGunHitbox or "HumanoidRootPart") or char:FindFirstChild("HumanoidRootPart"))
        local thrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (hitbox and thrp) then return end
        -- prediccion (lead) para moviles/fly
        local lead = Vector3.zero
        if F.TGunPredict then
            local t = F.TGunLead or 0.08
            if F.TGunUsePing then
                local ok, ping = pcall(function() return LP:GetNetworkPing() end)
                if ok and type(ping) == "number" then t = ping end
            end
            lead = targetVel(plr) * t
        end
        local resolved = (U.Services.Resolver and U.Services.Resolver.resolvePos(plr, thrp.Position, F.TGunResolver)) or thrp.Position
        local aimPos = resolved + (hitbox.Position - thrp.Position) + lead
        local basePos = resolved + lead
        -- desync nuestra server-pos cerca del target (offset hacia la camara = LOS)
        local cam = workspace.CurrentCamera
        local dir = cam and (cam.CFrame.Position - basePos)
        dir = (dir and dir.Magnitude > 1 and dir.Unit) or Vector3.new(0, 0, 1)
        local spoofPos = basePos + dir * (F.TGunOffset or 4)
        Spoof.desyncTo(CFrame.lookAt(spoofPos, aimPos), false)
        wasActive = true
        acc = acc + dt
        local interval = F.TGunUseWeaponRate ~= false
            and ((gun:FindFirstChild("Configuration") and gun.Configuration:FindFirstChild("FireRate") and gun.Configuration.FireRate.Value) or 0.2)
            or (F.TGunRate or 0.1)
        interval = math.max(interval, 0.05)
        if acc < interval then return end
        acc = 0
        local me = gun:FindFirstChild("MouseEvent")
        if me then pcall(function() me:FireServer(aimPos) end) end
    end)

    if U.Registry then
        U.Registry.Add("TargetGun", { Unload = function()
            if driver then driver:Disconnect() end
            if velConn then velConn:Disconnect() end
            pcall(Spoof.stop)
        end })
    end
end
