-- TargetGun: ragebot gun. Las balas = daño SERVER-SIDE (proyectil desde tu muzzle server -> target server).
-- Silent redirect muere (server valida hitPos vs tu pos). Metodo inventado: en vez de mover el target, DESYNC
-- tu server-pos AL target -> el bullet spawnea desde tu muzzle spoofeado (en el target) + fire MouseEvent(target)
-- = point-blank VALIDO -> la bala pega. Cliente queda quieto (hook __index). Es el melee-gather al reves.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Combat:AddSection("Target Gun", "Ragebot gun: desync-to-target + fire (bullets serverside)")
    local Pan = Sec:AddPanel("Target Gun", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("TGun", { Text = "Enabled", Default = false,
        Tooltip = "Desync tu server-pos al target -> fire point-blank valido -> la bala pega. Vos quedas quieto" })
        :AddKeybind({ Default = Enum.KeyCode.N })
    Pan:AddDropdown("TGunSelect", { Text = "Selection", Values = { "Nearest Mouse", "Nearest Distance", "Lowest HP" }, Default = "Nearest Mouse" })
    Pan:AddDropdown("TGunHitbox", { Text = "Hitbox", Values = { "HumanoidRootPart", "Head", "UpperTorso" }, Default = "HumanoidRootPart" })
    Pan:AddToggle("TGunTeamCheck", { Text = "Team Check", Default = false })
    Pan:AddToggle("TGunFFCheck", { Text = "ForceField Check", Default = true })
    Pan:AddSlider("TGunRate", { Text = "Fire Interval", Min = 0.05, Max = 1, Default = 0.1, Decimals = 2, Suffix = "s" })
    Pan:AddToggle("TGunUseWeaponRate", { Text = "Use Weapon FireRate", Default = true })
    Pan:AddSlider("TGunOffset", { Text = "Offset From Target", Min = 0, Max = 15, Default = 4, Suffix = "studs",
        Tooltip = "Que tan lejos del target te spoofeas (0=dentro, chico=point-blank con LOS)" })

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

    -- target por Selection (Nearest Mouse SIN offscreen / Distance / Lowest HP). Devuelve char + hitbox part.
    local function pickTarget()
        local cam = workspace.CurrentCamera
        local mp = UIS:GetMouseLocation()
        local mode = F.TGunSelect or "Nearest Mouse"
        local part = F.TGunHitbox or "HumanoidRootPart"
        local best, bestScore, bestChar
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                local ff = F.TGunFFCheck ~= false and c and c:FindFirstChildOfClass("ForceField")
                if hrp and hum and hum.Health > 0 and not ff and not (F.TGunTeamCheck and LP.Team and plr.Team == LP.Team) then
                    local score
                    if mode == "Nearest Distance" then
                        score = cam and (cam.CFrame.Position - hrp.Position).Magnitude or 0
                    elseif mode == "Lowest HP" then
                        score = hum.Health
                    else
                        local sp = cam:WorldToViewportPoint(hrp.Position)
                        score = (Vector2.new(sp.X, sp.Y) - mp).Magnitude
                    end
                    if not bestScore or score < bestScore then
                        bestScore = score; bestChar = c; best = c:FindFirstChild(part) or hrp
                    end
                end
            end
        end
        return bestChar, best
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.TGun == true) then
            if wasActive then wasActive = false; pcall(Spoof.stop) end
            return
        end
        local gun = equippedGun()
        if not gun then return end
        local char, hitbox = pickTarget()
        if not (char and hitbox) then return end
        local thrp = char:FindFirstChild("HumanoidRootPart") or hitbox
        -- desync nuestra server-pos cerca del target (offset hacia la camara = LOS + point-blank)
        local cam = workspace.CurrentCamera
        local dir = cam and (cam.CFrame.Position - thrp.Position)
        dir = (dir and dir.Magnitude > 1 and dir.Unit) or Vector3.new(0, 0, 1)
        local spoofPos = thrp.Position + dir * (F.TGunOffset or 4)
        Spoof.desyncTo(CFrame.lookAt(spoofPos, hitbox.Position), false)
        wasActive = true
        acc = acc + dt
        local interval = F.TGunUseWeaponRate ~= false
            and ((gun:FindFirstChild("Configuration") and gun.Configuration:FindFirstChild("FireRate") and gun.Configuration.FireRate.Value) or 0.2)
            or (F.TGunRate or 0.1)
        interval = math.max(interval, 0.05)
        if acc < interval then return end
        acc = 0
        local me = gun:FindFirstChild("MouseEvent")
        if me then pcall(function() me:FireServer(hitbox.Position) end) end
    end)

    if U.Registry then
        U.Registry.Add("TargetGun", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
        end })
    end
end
