-- TargetMelee: perfect melee kill a un PLAYER (cheater) FULL SIGILO. Target = nearest-to-mouse (sin offscreen).
-- Void spoof (unhittable) + GRIP DECOUPLE: desconecta el grip weld + ancla el Handle en el target (Anchored+
-- Massless) -> el arma va al target SIN afectar el movimiento del personaje NI pelear con la void-spoof (sin
-- jitter/fling). El player NO se trae al frente = invisible. Fire remote generico. Single-target.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Combat:AddSection("Target Melee", "Perfect melee kill a cheaters (sigilo)")
    local Pan = Sec:AddPanel("Target Melee", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("TMelee", { Text = "Enabled", Default = false,
        Tooltip = "Ancla el arma al target + fire. El player NO se mueve = sigilo. El cuerpo no se ve afectado" })
        :AddKeybind({ Default = Enum.KeyCode.B })
    Pan:AddDropdown("TMWeapon", { Text = "Weapon", Values = { "Knife", "Katana" }, Default = "Knife" })
    Pan:AddToggle("TMAutoEquip", { Text = "Auto-Equip", Default = true })
    Pan:AddToggle("TMVoidSpoof", { Text = "Void Spoof (unhittable)", Default = true })
    Pan:AddToggle("TMTeamCheck", { Text = "Team Check", Default = false, Tooltip = "Off = cualquier player (cheaters)" })
    Pan:AddDropdown("TMHitbox", { Text = "Hitbox", Values = { "HumanoidRootPart", "Head", "UpperTorso" }, Default = "HumanoidRootPart" })
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

    -- target = player nearest al MOUSE, SIN check offscreen (Z ignorado)
    local function nearestToMouse()
        local cam = workspace.CurrentCamera
        local mp = UIS:GetMouseLocation()
        local part = F.TMHitbox or "HumanoidRootPart"
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
        if best then return (best:FindFirstChild(part) or best:FindFirstChild("HumanoidRootPart")) end
    end

    -- GRIP DECOUPLE: desconecta el grip weld + ancla el Handle. Guarda/restaura estado. NO toca el cuerpo.
    local gS = { weld = nil, enabled = nil, anchored = nil, massless = nil }
    local function gripWeld(handle)
        local char = LP.Character; if not char then return end
        local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
        if not hand then return end
        for _, w in ipairs(hand:GetChildren()) do
            if (w:IsA("Weld") or w:IsA("Motor6D")) and (w.Part1 == handle or w.Part0 == handle) then return w end
        end
    end
    local function grabHandle(tool)
        local handle = tool:FindFirstChild("Handle"); if not handle then return end
        local w = gripWeld(handle)
        if w and gS.weld ~= w then gS.weld, gS.enabled = w, w.Enabled end
        if w then pcall(function() w.Enabled = false end) end
        if gS.anchored == nil then gS.anchored, gS.massless = handle.Anchored, handle.Massless end
        pcall(function() handle.Anchored = true; handle.Massless = true; handle.CanCollide = false end)
        return handle
    end
    local function restoreHandle()
        local tool = meleeTool()
        local handle = tool and tool:FindFirstChild("Handle")
        if handle and gS.anchored ~= nil then
            pcall(function() handle.Anchored = gS.anchored; handle.Massless = gS.massless end)
        end
        if gS.weld and gS.weld.Parent then pcall(function() gS.weld.Enabled = gS.enabled end) end
        gS = { weld = nil, enabled = nil, anchored = nil, massless = nil }
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.TMelee == true) then
            if wasActive then wasActive = false; restoreHandle(); pcall(Spoof.stop) end
            return
        end
        local tool = (F.TMAutoEquip ~= false and equipMelee()) or meleeTool()
        if not tool then return end
        local tpart = nearestToMouse()
        if not tpart then restoreHandle(); return end
        if F.TMVoidSpoof ~= false then Spoof.desyncTo(voidCF(), false) end
        local handle = grabHandle(tool)                                   -- decouple + anchor
        if handle then pcall(function() handle.CFrame = CFrame.new(tpart.Position) end) end -- arma al target
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
            pcall(restoreHandle)
            pcall(Spoof.stop)
        end })
    end
end
