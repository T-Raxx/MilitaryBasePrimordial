-- ResolverService: resuelve la pos REAL de un target que anti-aimea (spoofea su pos / void spam).
-- Port de LifeInPrisonPrimordial/Combat/Strafe.lua: Cluster (juju void_spam_resolver, histograma ponderado)
-- + Density (sakura/Unnamed, O(n^2) vecindario denso). El void (millones de studs) nunca clusteriza; la pos
-- real se re-visita -> gana peso/densidad. Samplea todos los players en Heartbeat. Reusable (TargetStrafe/Gun).
return function(U)
    local Players    = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LP = Players.LocalPlayer
    local R = {}

    R.RP  = { posWeight = 1.5, voidWeight = 0.2, forget = 80, distPenalty = 2.0, accuracy = 1.35, lerp = 0.1 }
    R.DEN = { forgiveness = 14.4, outOfVoidBonus = 13, distPenalty = 3.2, minMatches = 3, window = 3.0, voidManhattan = 7000 }
    R.histMax = 120

    local hist = {}   -- [player] = { s = {V3...}, t = {clock...} }
    local function sample(plr, pos, now)
        local h = hist[plr]; if not h then h = { s = {}, t = {} }; hist[plr] = h end
        h.s[#h.s + 1] = pos; h.t[#h.t + 1] = now
        if #h.s > R.histMax then table.remove(h.s, 1); table.remove(h.t, 1) end
    end
    R._conn = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local c = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then sample(plr, hrp.Position, now) end
            end
        end
        for plr in pairs(hist) do if not plr.Parent then hist[plr] = nil end end
    end)

    -- DENSITY (sakura/Unnamed): por cada muestra cuenta vecinos dentro de un radio chico (forgiveness);
    -- el void nunca clusteriza; la pos real (jitter chico) acumula vecinos. Radio encoge con la distancia.
    local function resolveDensity(plr, localPos)
        local D = R.DEN; local h = hist[plr]; local n = h and #h.s or 0
        if n < D.minMatches + 1 then return nil end
        local now = os.clock()
        local bestPos, bestCount = nil, D.minMatches - 1
        for i = 1, n do
            if now - h.t[i] <= D.window then
                local p1 = h.s[i]
                local inMap = (math.abs(p1.X) + math.abs(p1.Z)) < D.voidManhattan
                local forg = D.forgiveness + (inMap and D.outOfVoidBonus or 0)
                if localPos then forg = forg - ((localPos - p1).Magnitude / 100) * D.distPenalty end
                forg = math.clamp(forg, 1, 1000)
                local count, sum = 0, p1
                for j = 1, n do
                    if i ~= j and (now - h.t[j] <= D.window) and (p1 - h.s[j]).Magnitude <= forg then
                        count = count + 1; sum = sum + h.s[j]
                    end
                end
                if count >= D.minMatches and count > bestCount then bestCount = count; bestPos = sum / (count + 1) end
            end
        end
        return bestPos
    end

    -- CLUSTER (juju void_spam): histograma ponderado; void suma poco y se dispersa; la pos real gana peso*count.
    local clusters = {}
    local function resolveCluster(plr, hitbox, now, localPos)
        local RP = R.RP
        local t = clusters[plr]; if not t then t = { list = {} }; clusters[plr] = t end
        local dist = (localPos - hitbox).Magnitude
        local distPenalty = math.clamp(1 - (dist / 100) * (RP.distPenalty * 0.01), 0.25, 1)
        local mergeR = math.clamp(200 - dist * 0.4, 80, 200)
        local rate = RP.forget / 20
        local speed = 0
        if t.lastPos and t.lastT and (now - t.lastT) > 0 then speed = (hitbox - t.lastPos).Magnitude / (now - t.lastT) end
        t.lastPos = hitbox; t.lastT = now
        local lerpAmt = (hitbox.Magnitude >= 9e5 or speed > 150) and RP.lerp or math.clamp(RP.lerp * 3, RP.lerp, 0.6)
        local keep = {}
        for _, c in ipairs(t.list) do
            local dt = now - c.last
            if dt > 0 then
                local dm = (c.pos - hitbox).Magnitude > mergeR and 2.5 or 1
                c.weight = c.weight - dt * rate * dm; c.last = now
            end
            if c.weight >= 0.1 then keep[#keep + 1] = c end
        end
        t.list = keep
        local isVoid = hitbox.Magnitude >= 9e5
        local addW = (isVoid and RP.voidWeight or RP.posWeight) * distPenalty
        local merged = false
        for _, c in ipairs(t.list) do
            if (c.pos - hitbox).Magnitude <= mergeR then
                c.pos = c.pos:Lerp(hitbox, lerpAmt); c.weight = math.clamp(c.weight + addW, -1, 18); c.count = c.count + 1; c.last = now; merged = true; break
            end
        end
        if not merged then t.list[#t.list + 1] = { pos = hitbox, weight = addW, count = 1, last = now } end
        local best, bestScore = nil, 0
        for _, c in ipairs(t.list) do
            local s = c.weight * math.clamp(c.count * 0.25, 1, 3)
            if s > bestScore then bestScore = s; best = c end
        end
        return (best and best.pos) or hitbox
    end

    -- pos resuelta del player por metodo (Off/Cluster/Density). rawPos = hitbox crudo.
    function R.resolvePos(plr, rawPos, method)
        if not plr or method == "Off" or not method then return rawPos end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local loc = (hrp and hrp.Position) or rawPos
        if method == "Density" then
            return resolveDensity(plr, loc) or rawPos
        else
            return resolveCluster(plr, rawPos, os.clock(), loc)
        end
    end

    function R.Unload() if R._conn then R._conn:Disconnect() end end
    U.Services.Resolver = R
end
