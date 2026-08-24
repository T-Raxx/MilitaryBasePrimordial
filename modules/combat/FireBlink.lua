-- FireBlink: packet blink hook-level. Mante la tecla -> encola los FireServer (weapon o todos)
-- SIN enviarlos (movimiento = engine, sigue replicando -> tu posicion real replica y valida OK).
-- Soltas o a los 3s (limite outbound) -> flush burst = todos los tiros juntos ANTES del rate-check
-- del server = daño acumulado / one-shot. Hook unico reload-safe (getgenv().__MBT_BLINK_HOOK).
return function(U)
    local RunService = game:GetService("RunService")
    local Combat = U.Tabs.Combat
    local F = U.Flags

    local Sec = Combat:AddSection("Fire Blink", "Encola disparos, libera en burst")
    local Pan = Sec:AddPanel("Fire Blink", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("BlinkEnable", { Text = "Enabled", Default = false })
    Pan:AddKeybind("BlinkKey", { Text = "Hold to Blink", Mode = "Hold", Default = Enum.KeyCode.V })
    Pan:AddDropdown("BlinkScope", { Text = "Scope", Values = { "Weapon Only", "All Remotes" }, Default = "Weapon Only",
        Tooltip = "Weapon = solo MouseEvent (seguro). All = todos los FireServer (blink real)" })
    Pan:AddSlider("BlinkMaxTime", { Text = "Max Hold", Min = 0.5, Max = 3, Default = 3, Decimals = 1, Suffix = "s",
        Tooltip = "Auto-flush (margen del outbound timeout ~3s)" })
    Pan:AddSlider("BlinkReleaseGap", { Text = "Release Gap", Min = 0, Max = 100, Default = 0, Suffix = "ms",
        Tooltip = "0 = todo el burst en 1 frame (max daño). >0 = espaciado" })
    Pan:AddToggle("BlinkShowHUD", { Text = "Show Indicator", Default = true })

    -- estado global compartido con el hook unico
    if not getgenv().__MBT_BLINK then getgenv().__MBT_BLINK = { active = false, scope = "Weapon Only", queue = {} } end

    -- hook unico (reload-safe): swallow FireServer cuando active y matchea scope
    if not getgenv().__MBT_BLINK_HOOK and typeof(hookmetamethod) == "function" then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local S = getgenv().__MBT_BLINK
            if S and S.active and typeof(self) == "Instance" then
                local isSelf = (typeof(checkcaller) == "function") and checkcaller() or false
                if not isSelf then
                    local ok, m = pcall(getnamecallmethod)
                    if ok and m == "FireServer" then
                        if S.scope == "All Remotes" or self.Name == "MouseEvent" then
                            S.queue[#S.queue + 1] = { remote = self, args = table.pack(...) }
                            return -- swallow: encolado, no se envia
                        end
                    end
                end
            end
            return old(self, ...)
        end)
        getgenv().__MBT_BLINK_HOOK = true
        getgenv().__MBT_BLINK_OLD = old
    end

    local function flush()
        local S = getgenv().__MBT_BLINK
        local old = getgenv().__MBT_BLINK_OLD
        S.active = false
        if not old then S.queue = {}; return end
        local q = S.queue
        S.queue = {}
        local gap = (F.BlinkReleaseGap or 0) / 1000
        for i = 1, #q do
            local it = q[i]
            if it.remote and it.remote.Parent then
                pcall(old, it.remote, table.unpack(it.args, 1, it.args.n))
            end
            if gap > 0 then task.wait(gap) end
        end
    end

    local hud
    if Drawing then hud = Drawing.new("Text"); hud.Size = 18; hud.Center = true; hud.Outline = true; hud.Visible = false end

    local blinkStart = 0
    local conn = RunService.RenderStepped:Connect(function()
        local S = getgenv().__MBT_BLINK
        if not S then return end
        S.scope = F.BlinkScope or "Weapon Only"
        local held = (F.BlinkEnable == true) and (F.BlinkKeyActive == true)
        if held and not S.active then
            S.active = true; blinkStart = os.clock()
        elseif S.active then
            local elapsed = os.clock() - blinkStart
            if (not held) or elapsed >= (F.BlinkMaxTime or 3) then
                task.spawn(flush)
            end
        end
        if hud then
            hud.Visible = (F.BlinkEnable and F.BlinkShowHUD and S.active) == true
            if hud.Visible then
                local vp = workspace.CurrentCamera.ViewportSize
                local remain = math.max(0, (F.BlinkMaxTime or 3) - (os.clock() - blinkStart))
                hud.Text = string.format("BLINK %.1fs  [%d]", remain, #S.queue)
                hud.Position = Vector2.new(vp.X / 2, vp.Y / 2 + 45)
                hud.Color = remain < 0.6 and Color3.fromRGB(235, 60, 60) or Color3.fromRGB(202, 151, 161)
            end
        end
    end)

    if U.Registry then
        U.Registry.Add("FireBlink", { Unload = function()
            local S = getgenv().__MBT_BLINK
            if S then S.active = false; S.queue = {} end -- desarma (hook queda inerte)
            if conn then conn:Disconnect() end
            if hud then hud:Remove() end
        end })
    end
end
