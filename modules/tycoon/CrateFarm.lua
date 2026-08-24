-- CrateFarm: colecta las crates de workspace.Crates (Crate=Cash+XP, GunCrate=arma). Colección = TOUCH
-- (tienen TouchInterest, sin prompt/click). Metodo Touch = firetouchinterest(crate, HRP) dispara el .Touched
-- sin moverte. Si el server valida posicion (no colecta), usar Teleport To Crate (overlap real).
return function(U)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Tycoon = U.Tabs.Tycoon
    local F = U.Flags

    local Sec = Tycoon:AddSection("Crate Farm", "Colecta Crates/GunCrates (cash + armas)")
    local Pan = Sec:AddPanel("Crate Farm", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("CrateFarm", { Text = "Enabled", Default = false, Tooltip = "Colecta todas las crates en loop" })
        :AddKeybind({ Default = Enum.KeyCode.G })
    Pan:AddDropdown("CrateMethod", { Text = "Method", Values = { "Touch", "Teleport To Crate" }, Default = "Touch",
        Tooltip = "Touch=firetouchinterest sin moverte. Teleport=overlap real (si Touch no colecta)" })
    Pan:AddSlider("CrateRate", { Text = "Crates / sec", Min = 1, Max = 20, Default = 4 })
    Pan:AddToggle("CrateReturn", { Text = "Return To Start (teleport)", Default = true })

    if typeof(firetouchinterest) ~= "function" then
        Pan:AddLabel("firetouchinterest no soportado por tu executor", { Header = true })
    end

    local function hrpOf() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    local state = { alive = true, running = false, startCF = nil }
    -- dedupe: cada crate se colecta 1 SOLA vez (evita floodear loot = crash). Respawn = instancia nueva.
    local collected = setmetatable({}, { __mode = "k" })

    local function run()
        if state.running then return end
        state.running = true
        task.spawn(function()
            state.startCF = (hrpOf() and hrpOf().CFrame) or state.startCF
            while F.CrateFarm and state.alive do
                local Crates = workspace:FindFirstChild("Crates")
                local h = hrpOf()
                if Crates and h then
                    for _, c in ipairs(Crates:GetChildren()) do
                        if not (F.CrateFarm and state.alive) then break end
                        if c:IsA("BasePart") then
                            if F.CrateMethod == "Teleport To Crate" then
                                pcall(function() h.CFrame = CFrame.new(c.Position) end)
                                task.wait(1 / math.clamp(F.CrateRate or 4, 1, 20))
                            elseif not collected[c] then
                                collected[c] = true -- 1 sola vez por crate
                                pcall(function()
                                    firetouchinterest(c, h, 0)
                                    firetouchinterest(c, h, 1)
                                end)
                                task.wait(1 / math.clamp(F.CrateRate or 4, 1, 20))
                            end
                        end
                    end
                    if F.CrateMethod == "Teleport To Crate" and F.CrateReturn and state.startCF then
                        pcall(function() hrpOf().CFrame = state.startCF end)
                    end
                else
                    task.wait(0.3)
                end
            end
            state.running = false
        end)
    end

    local watch = RunService.Heartbeat:Connect(function()
        if F.CrateFarm and not state.running then run() end
    end)

    if U.Registry then
        U.Registry.Add("CrateFarm", { Unload = function()
            state.alive = false
            if watch then watch:Disconnect() end
        end })
    end
end
