-- MeleeAura: KnifeFire:FireServer() no manda args -> el daño a soldados (clientside) se aplica a tu pos
-- CLIENT real, mientras spoofeamos la server-pos al VOID (2^31 random XYZ) = UNHITTABLE + invisible.
-- Hallazgo del usuario: spoofeado lejos, el cuchillo igual registra kills en soldados, y a vos no te tocan.
-- Combo en un toggle: auto-equip knife + void spoof + KnifeFire spam.
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Combat = U.Tabs.Combat
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Combat:AddSection("Melee Aura", "Knife farm hit-safe + unhittable (void spoof)")
    local Pan = Sec:AddPanel("Melee Aura", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("MeleeAura", { Text = "Enabled", Default = false, Tooltip = "Spam KnifeFire; daño a soldados en tu pos client" })
        :AddKeybind({ Default = Enum.KeyCode.V })
    Pan:AddToggle("MeleeAutoEquip", { Text = "Auto-Equip Knife", Default = true })
    Pan:AddToggle("MeleeVoidSpoof", { Text = "Void Spoof (unhittable)", Default = true,
        Tooltip = "Server-pos al void 2^31 random = intocable + invisible mientras atacas" })
    Pan:AddSlider("MeleeRate", { Text = "Swing Interval", Min = 0.1, Max = 1, Default = 0.7, Decimals = 2, Suffix = "s",
        Tooltip = "0.7 = debounce del knife. Mas rapido = puede lockear/flagear el server" })
    Pan:AddToggle("MeleeOnlyWithTarget", { Text = "Only Swing With Target In Range", Default = false })
    Pan:AddSlider("MeleeRange", { Text = "Target Range", Min = 5, Max = 60, Default = 25, Suffix = "studs" })
    Pan:AddLabel("Mass Farm", { Header = true })
    Pan:AddToggle("MeleeGather", { Text = "Gather Soldiers (mass)", Default = false,
        Tooltip = "Trae los soldados (clientside) al punto de cluster -> KnifeFire los mata a todos" })
    Pan:AddDropdown("MeleeGatherMethod", { Text = "Gather Method", Values = { "To Me", "Cluster Far" }, Default = "Cluster Far",
        Tooltip = "To Me=en tu pos. Cluster Far=lejos + mueve el grip/Handle alla (no estorba la vista, full sigilo)" })
    Pan:AddSlider("MeleeGatherRange", { Text = "Gather Range", Min = 20, Max = 2000, Default = 500, Suffix = "studs" })
    Pan:AddSlider("MeleeClusterDist", { Text = "Cluster Distance", Min = 50, Max = 1000, Default = 300, Suffix = "studs" })

    -- LCG (Math.random bloqueado) para el void random
    local brng = 135797531
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end
    local function voidCF()
        local B = 2147483647
        local y = math.abs(rndS() * B); if y < 30 then y = 30 + y end
        return CFrame.new(rndS() * B, y, rndS() * B)
    end

    local function knife()
        for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
            if src then local k = src:FindFirstChild("Knife"); if k then return k end end
        end
    end
    local function equipKnife()
        local char = LP.Character; local k = knife()
        if char and k and k.Parent ~= char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then pcall(function() h:EquipTool(k) end) end
        end
        return char and char:FindFirstChild("Knife")
    end
    local function targetInRange(range)
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if r and h and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= range
                    and not (LP.Team and plr.Team == LP.Team) then return true end
            end
        end
        local NPCs = workspace:FindFirstChild("NPCs")
        if NPCs then
            for _, m in ipairs(NPCs:GetChildren()) do
                local r = m:FindFirstChild("HumanoidRootPart")
                local h = m:FindFirstChildOfClass("Humanoid")
                if r and h and h.Health > 0 and (r.Position - hrp.Position).Magnitude <= range then return true end
            end
        end
        return false
    end

    -- trae los soldados (clientside) al punto de cluster -> KnifeFire (daño clientside desde la tool) los mata.
    -- Method 1 "To Me" = en tu pos. Method 2 "Cluster Far" = lejos (arriba) + mueve el Handle del knife alla
    -- (el daño sale de la tool) = no estorba la vista + full sigilo (el knife no swingea en tu mano).
    local function gatherSoldiers(range, knifeTool)
        local NPCs = workspace:FindFirstChild("NPCs"); if not NPCs then return end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local myPos = hrp.Position -- el hook __index devuelve tu pos REAL aunque estes void-spoofed
        local center = myPos
        if F.MeleeGatherMethod == "Cluster Far" then
            center = myPos + Vector3.new(0, F.MeleeClusterDist or 300, 0) -- arriba, fuera de vista
            local handle = knifeTool and knifeTool:FindFirstChild("Handle")
            if handle then pcall(function() handle.CFrame = CFrame.new(center) end) end -- grip clientside al cluster
        end
        for _, m in ipairs(NPCs:GetChildren()) do
            local r = m:FindFirstChild("HumanoidRootPart")
            local h = m:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 and (r.Position - myPos).Magnitude <= range then
                pcall(function() r.CFrame = CFrame.new(center) end)
            end
        end
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.MeleeAura == true) then
            if wasActive then wasActive = false; pcall(Spoof.stop) end
            return
        end
        local k = (F.MeleeAutoEquip ~= false and equipKnife()) or knife()
        if not k then return end
        -- void spoof (server-pos intocable; el daño clientside usa tu pos real via el restore del hook)
        if F.MeleeVoidSpoof ~= false then Spoof.desyncTo(voidCF(), false) end
        if F.MeleeGather then gatherSoldiers(F.MeleeGatherRange or 500, k) end
        wasActive = true
        acc = acc + dt
        local interval = math.max(F.MeleeRate or 0.7, 0.1)
        if acc < interval then return end
        acc = 0
        if F.MeleeOnlyWithTarget and not targetInRange(F.MeleeRange or 25) then return end
        local kf = k:FindFirstChild("KnifeFire")
        if kf then pcall(function() kf:FireServer() end) end
    end)

    if U.Registry then
        U.Registry.Add("MeleeAura", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
        end })
    end
end
