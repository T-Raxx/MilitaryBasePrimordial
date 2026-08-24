-- SpoofService: motor de desync server-pos por HOOK __index (port del Spoof.lua de LifeInPrisonPrimordial).
-- El server te ve en la fakeCF; tu cuerpo/camara reales NO se mueven (hook devuelve la CF real → AC-safe).
-- Reload-safe (getgenv guards). Consumido por TargetStrafe (ofensa) y ClientDesync (defensa).
return function(U)
    local Players    = game:GetService("Players")
    local Workspace  = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local hookmm = hookmetamethod
    local newcc  = newcclosure or function(f) return f end
    local sethidden = sethiddenproperty

    if not getgenv().__MBT_SP then
        getgenv().__MBT_SP = { spoofOn = false, cachedRoot = nil, spoofRealCF = nil, spoofRestore = nil, spoofFakePos = nil, spoofVel = nil, connRep = false }
    end
    local SP = getgenv().__MBT_SP
    local Spoof = { state = SP }

    local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    Spoof.myRoot = myRoot

    ------------------------------------------------------------------ __index hook (una vez)
    if not getgenv().__MBT_IDX and typeof(hookmm) == "function" then
        local orig
        local ok = pcall(function()
            orig = hookmm(game, "__index", newcc(function(self, key)
                local D = getgenv().__MBT_SP
                if D and D.spoofOn and self == D.cachedRoot and D.spoofRealCF then
                    if key == "CFrame" then return D.spoofRealCF end
                    if key == "Position" then return D.spoofRealCF.Position end
                end
                return orig(self, key)
            end))
        end)
        if ok then getgenv().__MBT_IDX = true; getgenv().__MBT_ORIG_INDEX = orig end
    end
    local function trueCF(root) local o = getgenv().__MBT_ORIG_INDEX; return (o and o(root, "CFrame")) or root.CFrame end
    Spoof.trueCF = trueCF
    function Spoof.captureReal(root)
        local tc = trueCF(root)
        if SP.spoofOn and SP.spoofRealCF then
            local last = SP.spoofRealCF
            if (tc.Position - last.Position).Magnitude > 400 then return last end
            if SP.spoofFakePos and (tc.Position - SP.spoofFakePos).Magnitude < 30 then return last end
        end
        return tc
    end

    ------------------------------------------------------------------ camara anclada a pos real (sin teleport visual)
    local function camAnchor()
        local a = getgenv().__MBT_CamAnchor
        if not a or not a.Parent then
            a = Instance.new("Part")
            a.Name = "MBT_CamAnchor"; a.Anchored = true; a.CanCollide = false; a.Transparency = 1; a.Size = Vector3.new(2, 2, 1)
            pcall(function() a.Parent = Workspace end)
            getgenv().__MBT_CamAnchor = a
        end
        return a
    end
    function Spoof.camToLocal(cam, realCF)
        local a = camAnchor()
        pcall(function()
            a.CFrame = realCF + Vector3.new(0, 2.5, 0)
            if cam.CameraSubject ~= a then cam.CameraSubject = a end
        end)
    end
    function Spoof.camToChar(cam)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() if cam.CameraSubject ~= hum then cam.CameraSubject = hum end end) end
    end

    ------------------------------------------------------------------ connection weld exploit (PhysicsRepRootPart, sin Weld)
    function Spoof.setPhysRep(targetHRP)
        local r = myRoot()
        if r and sethidden and targetHRP and targetHRP.Parent then
            pcall(function() sethidden(r, "PhysicsRepRootPart", targetHRP) end)
            SP.connRep = true
        end
    end
    function Spoof.unweld()
        SP.connRep = false
        if sethidden then
            task.spawn(function()
                for _ = 1, 10 do
                    local rr = myRoot()
                    if rr then pcall(function() sethidden(rr, "PhysicsRepRootPart", rr) end) end
                    task.wait()
                end
            end)
        end
    end

    ------------------------------------------------------------------ restore loop (una vez)
    if not getgenv().__MBT_RESTORE then
        getgenv().__MBT_RESTORE = true
        getgenv().__MBT_RESTORE_CONN = RunService.RenderStepped:Connect(function()
            local D = getgenv().__MBT_SP
            if not D then return end
            local root = D.cachedRoot
            if root and root.Parent and D.spoofRestore then
                pcall(function()
                    root.CFrame = D.spoofRestore
                    if D.spoofVel then root.AssemblyLinearVelocity = D.spoofVel end
                end)
                D.spoofRestore = nil
            end
        end)
    end

    ------------------------------------------------------------------ API alto nivel
    -- desyncTo: el server te ve en fakeCF; cuerpo/camara reales quedan. camLock=true ancla la camara a la pos real.
    function Spoof.desyncTo(fakeCF, camLock)
        local root = myRoot(); if not root then return end
        local cam = Workspace.CurrentCamera
        if SP.connRep then Spoof.unweld() end
        local realCF = Spoof.captureReal(root)
        SP.cachedRoot = root; SP.spoofRealCF = realCF; SP.spoofOn = true; SP.spoofFakePos = fakeCF.Position
        SP.spoofVel = root.AssemblyLinearVelocity; SP.spoofRestore = realCF
        if camLock and cam then Spoof.camToLocal(cam, realCF) end
        pcall(function() root.CFrame = fakeCF end)
    end
    -- weldTo: connection weld point-blank al target (PhysicsRepRootPart), SIN escribir CFrame ni desync.
    function Spoof.weldTo(targetHRP)
        Spoof.setPhysRep(targetHRP)
        SP.spoofFakePos = targetHRP and targetHRP.Position
        SP.spoofOn = false; SP.spoofRealCF = nil; SP.spoofRestore = nil
    end
    function Spoof.stop()
        local cam = Workspace.CurrentCamera
        if SP.spoofOn then
            local r = myRoot()
            if r and SP.spoofRealCF then pcall(function() r.CFrame = SP.spoofRealCF end) end
        end
        if SP.connRep then Spoof.unweld() end
        SP.spoofOn = false; SP.spoofRealCF = nil; SP.spoofRestore = nil; SP.spoofFakePos = nil; SP.spoofVel = nil
        if cam then Spoof.camToChar(cam) end
    end
    function Spoof.fakePos() return SP.spoofFakePos end
    function Spoof.isActive() return SP.spoofOn or SP.connRep end

    function Spoof.Unload()
        local rc = getgenv().__MBT_RESTORE_CONN
        if rc then rc:Disconnect() end
        getgenv().__MBT_RESTORE = nil
        Spoof.stop()
        local a = getgenv().__MBT_CamAnchor
        if a then pcall(function() a:Destroy() end); getgenv().__MBT_CamAnchor = nil end
    end

    U.Services.Spoof = Spoof
end
