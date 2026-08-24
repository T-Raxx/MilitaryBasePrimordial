-- VelocityService: velocidad suavizada (median) + resolver de posicion. Copiado de UniversalPrimordial.
-- SilentAim usa Vel.Get(key) para lead = vel * (dist/BulletSpeed). Requiere Vel.Enabled=true.
return function(U)
    local RunService = game:GetService("RunService")
    local N = 6
    local Vel = { _e = {}, MaxSpeed = 0, YClamp = 0, Enabled = false } -- 0 = sin cap (la mediana atenua flings)

    local function median(h)
        local n = #h; if n == 0 then return 0 end
        local s = {}; for i=1,n do s[i] = h[i] end
        table.sort(s)
        if n % 2 == 1 then return s[(n+1)//2] else return (s[n//2] + s[n//2+1]) / 2 end
    end
    local function push(h, v) h[#h+1] = v; if #h > N then table.remove(h, 1) end end

    function Vel.Update(key, pos, now)
        local e = Vel._e[key]
        if not e then
            Vel._e[key] = { last = pos, t = now, hx = {}, hy = {}, hz = {}, res = Vector3.zero, ps = { pos }, pt = { now } }
            return
        end
        local dt = now - e.t
        if dt <= 0 then return end
        local v = (pos - e.last) / dt
        e.last = pos; e.t = now
        push(e.hx, v.X); push(e.hy, v.Y); push(e.hz, v.Z)
        local res = Vector3.new(median(e.hx), median(e.hy), median(e.hz))
        if Vel.MaxSpeed > 0 and res.Magnitude > Vel.MaxSpeed then res = res.Unit * Vel.MaxSpeed end
        if Vel.YClamp > 0 then res = Vector3.new(res.X, math.clamp(res.Y, -Vel.YClamp, Vel.YClamp), res.Z) end
        e.res = res
        local pn = #e.ps
        local pdt = now - e.pt[pn]
        if not (pdt > 0 and (pos - e.ps[pn]).Magnitude / pdt > 300) then
            e.ps[pn + 1] = pos; e.pt[pn + 1] = now
            if #e.ps > 48 then table.remove(e.ps, 1); table.remove(e.pt, 1) end
        end
    end

    function Vel.Get(key) local e = Vel._e[key]; return e and e.res or Vector3.zero end
    function Vel.Reset(key) Vel._e[key] = nil end

    Vel._conn = RunService.Heartbeat:Connect(function()
        if not Vel.Enabled then return end
        local Ent = U.Services.Entity
        if not Ent then return end
        local now = os.clock()
        local seen = {}
        local ok, ents = pcall(Ent.GetTargets, { teamCheck = false, aliveCheck = true })
        if ok and ents then
            for _, ent in ipairs(ents) do
                local part = ent.hrpPart or ent.aimPart
                if part then
                    seen[ent.key] = true
                    pcall(Vel.Update, ent.key, part.Position, now)
                end
            end
        end
        for k, e in pairs(Vel._e) do if not seen[k] and (now - e.t) > 2 then Vel._e[k] = nil end end
    end)

    function Vel.Unload() if Vel._conn then Vel._conn:Disconnect() end end

    function Vel.TargetVel(key)
        local e = Vel._e[key]; local n = e and #e.ps or 0
        if n < 2 then return Vector3.zero end
        local dt = math.max(e.pt[n] - e.pt[n - 1], 1 / 240)
        return (e.ps[n] - e.ps[n - 1]) / dt
    end

    U.Services.Velocity = Vel
end
