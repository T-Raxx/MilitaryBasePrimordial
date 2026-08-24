-- AutoBuy: teleporta el HRP sobre cada boton asequible (toque real = server valida posicion OK).
-- firetouchinterest/RequestPurch remotos NO compran (server valida posicion real). Este juego NO
-- tiene AC de desplazamiento -> teleport seguro. Compra confirmada cuando Head.Transparency->1.
return function(U)
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Tycoon = U.Tabs.Tycoon
    local F = U.Flags

    local Sec = Tycoon:AddSection("Auto Buy", "Teleporta a los botones y compra")
    local Pan = Sec:AddPanel("Auto Buy", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("AutoBuy", { Text = "Auto Buy", Default = false,
        Tooltip = "Teleporta a cada boton asequible. Usar en base/seguro (te mueve)" })
    Pan:AddSlider("AutoBuyRate", { Text = "Buys / sec", Min = 1, Max = 15, Default = 6 })
    Pan:AddSlider("AutoBuyMaxPrice", { Text = "Max Price", Min = 0, Max = 100000000, Default = 0, OffAtMin = true, Tooltip = "0 = sin limite" })
    Pan:AddSlider("AutoBuyTimeout", { Text = "Confirm Timeout", Min = 0.1, Max = 1, Default = 0.4, Decimals = 2, Suffix = "s",
        Tooltip = "Espera a que el server confirme la compra antes del siguiente" })
    Pan:AddToggle("AutoBuyReturn", { Text = "Return To Start", Default = true, Tooltip = "Vuelve a tu posicion al terminar/apagar" })
    Pan:AddToggle("AutoBuyCashOnly", { Text = "Cash Only (skip R$/Rebirth)", Default = true,
        Tooltip = "Salta botones robux (R$), rebirth/renacimiento y VIP/gamepass" })

    -- botones que NO son compra de cash normal (no comprar con AutoBuy)
    local SPECIAL = { "r%$", "robux", "rebirth", "renacimiento", "vip", "gamepass" }
    local function isSpecial(name)
        local n = name:lower()
        for _, pat in ipairs(SPECIAL) do if n:find(pat) then return true end end
        return false
    end

    -- mi plot = inner Model (BrickColor) con Owner==LP dentro de workspace.Tycoons.<Color>
    local function myPlot()
        local T = workspace:FindFirstChild("Tycoons")
        if not T then return nil end
        for _, plot in ipairs(T:GetChildren()) do
            local inner = plot:FindFirstChildWhichIsA("Model")
            local owner = inner and inner:FindFirstChild("Owner")
            if owner and owner.Value == LP and inner:FindFirstChild("Buttons") and inner:FindFirstChild("Cash") then
                return inner
            end
        end
        return nil
    end

    local function pickButton(plot, cash, maxp)
        local best, bestP
        for _, btn in ipairs(plot.Buttons:GetChildren()) do
            local head = btn:FindFirstChild("Head")
            local price = btn:FindFirstChild("Price")
            if head and price and price.Value > 0
                and head.Transparency < 1 and head.CanTouch ~= false
                and price.Value <= cash and (maxp == 0 or price.Value <= maxp)
                and not (F.AutoBuyCashOnly ~= false and isSpecial(btn.Name)) then
                if not bestP or price.Value < bestP then best, bestP = head, price.Value end
            end
        end
        return best
    end

    local state = { alive = true, running = false, startCF = nil }

    local function hrpOf()
        local char = LP.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function run()
        if state.running then return end
        state.running = true
        task.spawn(function()
            state.startCF = (hrpOf() and hrpOf().CFrame) or state.startCF
            while F.AutoBuy and state.alive do
                local hrp = hrpOf()
                local plot = myPlot()
                if hrp and plot then
                    local head = pickButton(plot, plot.Cash.Value, F.AutoBuyMaxPrice or 0)
                    if head then
                        hrp.CFrame = CFrame.new(head.Position)
                        -- espera confirmacion del server (Transparency->1) o timeout
                        local deadline = os.clock() + (F.AutoBuyTimeout or 0.4)
                        repeat
                            task.wait()
                        until head.Transparency >= 1 or head.CanTouch == false or os.clock() > deadline or not F.AutoBuy
                    else
                        task.wait(0.3) -- nada asequible: esperar que suba el cash
                    end
                else
                    task.wait(0.3)
                end
                local rate = math.clamp(F.AutoBuyRate or 6, 1, 15)
                task.wait(1 / rate)
            end
            -- volver a la posicion inicial
            if F.AutoBuyReturn and state.startCF then
                local hrp = hrpOf()
                if hrp then pcall(function() hrp.CFrame = state.startCF end) end
            end
            state.running = false
        end)
    end

    -- arranca el loop cuando el flag se enciende (watcher liviano)
    local RunService = game:GetService("RunService")
    local watch = RunService.Heartbeat:Connect(function()
        if F.AutoBuy and not state.running then run() end
    end)

    if U.Registry then
        U.Registry.Add("AutoBuy", { Unload = function()
            state.alive = false
            if watch then watch:Disconnect() end
        end })
    end
end
