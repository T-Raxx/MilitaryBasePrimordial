-- MeleeAura: melee farm hit-safe. Un toggle: (auto-)equip melee + void spoof (unhittable) + gather nearest
-- pocos a rango del tool (CanCollide=false = sin fling) + spam del fire remote. Fire = single-target (mata 1/swing).
-- Weapon select (Knife/Katana). Fire remote generico = el RemoteEvent del tool != PlayerCheck (KnifeFire/KatanaFire).
-- Soldados = clientside (daño en tu pos real). Avatar mini = hitbox chica -> traer soldados mas cerca (GatherDist).
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Tab = U.Tabs.Tycoon
    local F = U.Flags
    local LP = Players.LocalPlayer
    local Spoof = U.Services.Spoof

    local Sec = Tab:AddSection("Soldier Farm", "Knife/Katana farm unhittable (void + gather)")
    local Pan = Sec:AddPanel("Soldier Farm", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("MeleeAura", { Text = "Enabled", Default = false,
        Tooltip = "Todo-en-uno: equip + void spoof + gather + fire" })
        :AddKeybind({ Default = Enum.KeyCode.V })
    Pan:AddDropdown("MeleeWeapon", { Text = "Weapon", Values = { "Knife", "Katana" }, Default = "Knife" })
    Pan:AddToggle("MeleeAutoEquip", { Text = "Auto-Equip", Default = true, Tooltip = "Off = equipas el melee vos" })
    Pan:AddToggle("MeleeVoidSpoof", { Text = "Void Spoof (unhittable)", Default = true })
    Pan:AddLabel("Gather", { Header = true })
    Pan:AddToggle("MeleeGather", { Text = "Gather Soldiers", Default = true,
        Tooltip = "Trae nearest a rango del tool (CanCollide off = sin fling)" })
    Pan:AddSlider("MeleeGatherCount", { Text = "Gather Count", Min = 1, Max = 8, Default = 3, Suffix = "npc" })
    Pan:AddSlider("MeleeGatherDist", { Text = "Distance To Tool", Min = 0, Max = 12, Default = 2, Decimals = 1, Suffix = "studs",
        Tooltip = "Que tan cerca traer los soldados (avatar mini = mas cerca)" })
    Pan:AddSlider("MeleeRange", { Text = "Search Range", Min = 20, Max = 1000, Default = 300, Suffix = "studs" })
    Pan:AddSlider("MeleeRate", { Text = "Swing Interval", Min = 0.1, Max = 1, Default = 0.5, Decimals = 2, Suffix = "s" })

    local brng = 135797531
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end
    local function voidCF()
        local B = 2147483647
        local y = math.abs(rndS() * B); if y < 30 then y = 30 + y end
        return CFrame.new(rndS() * B, y, rndS() * B)
    end

    local function meleeTool()
        local name = F.MeleeWeapon or "Knife"
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
        return char and char:FindFirstChild(F.MeleeWeapon or "Knife")
    end
    -- fire remote generico: el RemoteEvent del tool que no es PlayerCheck (KnifeFire / KatanaFire / etc)
    local function fireRemote(tool)
        for _, c in ipairs(tool:GetChildren()) do
            if c:IsA("RemoteEvent") and c.Name ~= "PlayerCheck" then return c end
        end
    end

    local function nearestSoldiers(count, range)
        local NPCs = workspace:FindFirstChild("NPCs")
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not (NPCs and hrp) then return {} end
        local list = {}
        for _, m in ipairs(NPCs:GetChildren()) do
            local r = m:FindFirstChild("HumanoidRootPart")
            local h = m:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                if d <= range then list[#list + 1] = { m = m, r = r, d = d } end
            end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        while #list > count do table.remove(list) end
        return list
    end
    local function gather(count, range, dist)
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local point = hrp.Position + hrp.CFrame.LookVector * dist
        for _, e in ipairs(nearestSoldiers(count, range)) do
            pcall(function()
                for _, p in ipairs(e.m:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                e.r.CFrame = CFrame.new(point)
            end)
        end
    end

    local acc = 0
    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function(dt)
        if not (F.MeleeAura == true) then
            if wasActive then wasActive = false; pcall(Spoof.stop) end
            return
        end
        local tool = (F.MeleeAutoEquip ~= false and equipMelee()) or meleeTool()
        if not tool then return end
        if F.MeleeVoidSpoof ~= false then Spoof.desyncTo(voidCF(), false) end
        if F.MeleeGather ~= false then gather(math.floor(F.MeleeGatherCount or 3), F.MeleeRange or 300, F.MeleeGatherDist or 2) end
        wasActive = true
        acc = acc + dt
        local interval = math.max(F.MeleeRate or 0.5, 0.1)
        if acc < interval then return end
        acc = 0
        local fr = fireRemote(tool)
        if fr then pcall(function() fr:FireServer() end) end
    end)

    if U.Registry then
        U.Registry.Add("SoldierFarm", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
        end })
    end
end
