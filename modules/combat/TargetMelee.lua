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
                if hrp and hum and hum.Health > 0 and not (F.TMTeamCheck and LP.Team and plr.Team == LP.Team) then
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
