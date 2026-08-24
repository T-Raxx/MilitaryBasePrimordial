-- ClientDesync: desync de TU pos (defensa anti-ragebot). El server te ve orbitando/saltando alrededor
-- de tu pos real; tu cuerpo/camara reales quedan quietos (camLock). Separado del Target Strafe (ofensa).
return function(U)
    local RunService = game:GetService("RunService")
    local Workspace  = game:GetService("Workspace")
    local Misc = U.Tabs.Misc
    local F = U.Flags
    local Spoof = U.Services.Spoof

    local Sec = Misc:AddSection("Client Desync", "Desync propio (anti-ragebot)")
    local Pan = Sec:AddPanel("Client Desync", { Column = 1 })
    Pan:AddLabel("Master", { Header = true })
    Pan:AddToggle("DesyncEnable", { Text = "Enabled", Default = false,
        Tooltip = "El server te ve desincronizado de tu pos real; te quedas quieto en pantalla" })
        :AddKeybind({ Mode = "Toggle", Default = Enum.KeyCode.X })
    Pan:AddDropdown("DesyncMode", { Text = "Mode", Values = { "Orbit", "Random", "Static Up" }, Default = "Random",
        Tooltip = "Random = XYZ random/frame en el rango (mas dificil de resolver)" })
    Pan:AddSlider("DesyncRadius", { Text = "Radius", Min = 2, Max = 100, Default = 20, Suffix = "studs" })
    Pan:AddSlider("DesyncSpeed", { Text = "Speed", Min = 1, Max = 40, Default = 16 })
    Pan:AddSlider("DesyncHeight", { Text = "Height", Min = -20, Max = 20, Default = 0, Suffix = "studs" })
    Pan:AddToggle("DesyncMarker", { Text = "Show Marker", Default = true })
        :AddColorPicker("DesyncMarkerColor", { Default = Color3.fromRGB(120, 170, 255) })

    local brng = 424242123
    local function rnd() brng = (brng * 1103515245 + 12345) % 2147483648; return brng / 2147483648 end
    local function rndS() return rnd() * 2 - 1 end

    local seed = 0
    local function fakePosFrom(realPos)
        local R, spd, h = F.DesyncRadius or 20, F.DesyncSpeed or 16, F.DesyncHeight or 0
        local mode = F.DesyncMode or "Random"
        if mode == "Static Up" then
            return realPos + Vector3.new(0, R, 0)
        elseif mode == "Random" then
            return realPos + Vector3.new(rndS() * R, h + rndS() * R, rndS() * R)
        else -- Orbit
            seed = seed + spd * 0.05
            return realPos + Vector3.new(math.cos(seed) * R, h, math.sin(seed) * R)
        end
    end

    local mC, mT, mL
    if Drawing then
        mC = Drawing.new("Circle"); mC.Thickness = 2; mC.NumSides = 32; mC.Filled = false; mC.Radius = 7; mC.Visible = false
        mT = Drawing.new("Text"); mT.Size = 14; mT.Center = true; mT.Outline = true; mT.Visible = false
        mL = Drawing.new("Line"); mL.Thickness = 1; mL.Visible = false
    end
    local UIS = game:GetService("UserInputService")
    local function hideMarker() if mC then mC.Visible = false; mT.Visible = false; mL.Visible = false end end
    local function drawMarker(pos)
        if not mC or not pos then return end
        local cam = Workspace.CurrentCamera
        local v = cam:WorldToViewportPoint(pos); local on = v.Z > 0
        mC.Visible = on; mT.Visible = on; mL.Visible = on
        if on then
            local col = F.DesyncMarkerColor or Color3.fromRGB(120, 170, 255)
            local p = Vector2.new(v.X, v.Y)
            mC.Position = p; mC.Color = col
            mT.Position = p + Vector2.new(0, 10); mT.Text = "DESYNC"; mT.Color = col
            mL.From = UIS:GetMouseLocation(); mL.To = p; mL.Color = col
        end
    end

    local wasActive = false
    local driver = RunService.Heartbeat:Connect(function()
        if not (F.DesyncEnable == true) then
            if wasActive then wasActive = false; Spoof.stop() end
            hideMarker()
            return
        end
        local root = Spoof.myRoot(); if not root then return end
        local realCF = Spoof.captureReal(root)
        local fakePos = fakePosFrom(realCF.Position)
        Spoof.desyncTo(CFrame.new(fakePos) * realCF.Rotation, true) -- camLock: te quedas quieto en pantalla
        if F.DesyncMarker and Drawing then drawMarker(Spoof.fakePos()) else hideMarker() end
        wasActive = true
    end)

    if U.Registry then
        U.Registry.Add("ClientDesync", { Unload = function()
            if driver then driver:Disconnect() end
            pcall(Spoof.stop)
            hideMarker()
            for _, d in ipairs({ mC, mT, mL }) do if d then pcall(function() d:Remove() end) end end
        end })
    end
end
