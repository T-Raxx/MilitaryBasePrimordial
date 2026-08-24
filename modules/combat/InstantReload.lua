-- InstantReload: setea Configuration.ReloadTime=0 en toda arma (client-only, no replica).
-- Server gatea por RATE no por silencio de reload -> borrar la pausa de 1.8s es AC-safe.
-- Confirmado live por el usuario ("100% viable"). NO tocar FireRate/MaxAmmo (esos buguean).
return function(U)
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Combat = U.Tabs.Combat
    local F = U.Flags

    local Sec = Combat:AddSection("Weapon", "Reload & fire")
    local Pan = Sec:AddPanel("Reload", { Column = 1 })
    Pan:AddLabel("Instant Reload", { Header = true })

    -- guarda el valor original por cada NumberValue de ReloadTime (weak keys)
    local originals = setmetatable({}, { __mode = "k" })

    local function eachReloadValue(fn)
        local containers = { LP:FindFirstChildOfClass("Backpack"), LP.Character }
        for _, cont in ipairs(containers) do
            if cont then
                for _, t in ipairs(cont:GetChildren()) do
                    if t:IsA("Tool") then
                        local cfg = t:FindFirstChild("Configuration")
                        local rt = cfg and cfg:FindFirstChild("ReloadTime")
                        if rt then fn(rt) end
                    end
                end
            end
        end
    end

    local function restore()
        for rt, v in pairs(originals) do
            if typeof(rt) == "Instance" and rt.Parent then
                pcall(function() rt.Value = v end)
            end
        end
    end

    Pan:AddToggle("InstantReload", {
        Text = "Instant Reload", Default = false,
        Tooltip = "ReloadTime puesto a 0 en todas las armas",
        Callback = function(v)
            if not v then restore() end
        end,
    })

    -- scan throttled ~2.5Hz: cubre respawn + armas nuevas sin costo por-frame
    local acc = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        if not F.InstantReload then return end
        acc = acc + dt
        if acc < 0.4 then return end
        acc = 0
        eachReloadValue(function(rt)
            if originals[rt] == nil then originals[rt] = rt.Value end
            if rt.Value ~= 0 then rt.Value = 0 end
        end)
    end)

    if U.Registry then
        U.Registry.Add("InstantReload", { Unload = function()
            if conn then conn:Disconnect() end
            pcall(restore)
        end })
    end
end
