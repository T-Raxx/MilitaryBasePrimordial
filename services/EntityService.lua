-- EntityService: enumera targets (players) con aimPart/head/hrp. Copiado de UniversalPrimordial.
-- SetSource permite inyectar NPCs a futuro (soldiers de workspace.NPCs).
return function(U)
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local Ent = { _source = nil, _cache = {} }
    local FALLBACK = { "UpperTorso", "Torso", "HumanoidRootPart" }

    function Ent.ResolveParts(char, partName)
        if not char then return nil end
        local aim
        if partName and partName ~= "Nearest" then aim = char:FindFirstChild(partName) end
        if not aim then
            for _, n in ipairs(FALLBACK) do
                if not aim then aim = char:FindFirstChild(n) end
            end
        end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        return aim or head or hrp, head, hrp
    end

    function Ent.SetSource(fn) Ent._source = fn end
    local function source()
        if Ent._source then return Ent._source() end
        return Players:GetPlayers()
    end

    function Ent.GetTargets(opts)
        opts = opts or {}
        local list = {}
        for _, plr in ipairs(source()) do
            if plr ~= LP then
                local okp, char = pcall(function() return plr.Character end)
                char = okp and char or nil
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local aim, head, hrp = Ent.ResolveParts(char, opts.partName)
                local ok = char ~= nil and aim ~= nil
                if ok and opts.aliveCheck ~= false then ok = hum ~= nil and hum.Health > 0 end
                if ok and opts.teamCheck and LP.Team then
                    ok = plr.Team ~= LP.Team
                end
                if ok then
                    list[#list+1] = {
                        key = plr.UserId or plr.Name, player = plr, character = char,
                        humanoid = hum, aimPart = aim, headPart = head, hrpPart = hrp,
                    }
                end
            end
        end
        Ent._cache = list
        return list
    end

    function Ent.Current() return Ent._cache end
    U.Services.Entity = Ent
end
