-- AimService: WorldToScreen/Center/Visible + AimCamera/AimMouse. Copiado de UniversalPrimordial.
-- Aimbot mueve la VISTA al target (aim real) -> el click del user manda una posicion que el server acepta.
return function(U)
    local atan2 = math.atan2 or function(y, x)
        if x > 0 then return math.atan(y / x)
        elseif x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi)
        else return (y >= 0 and math.pi/2 or -math.pi/2) end
    end
    local function cam() return workspace.CurrentCamera end
    local Aim = {}

    function Aim.WorldToScreen(pos)
        local c = cam(); if not c then return Vector2.zero, false, 0 end
        local v, on = c:WorldToViewportPoint(pos)
        return Vector2.new(v.X, v.Y), (on and v.Z > 0), v.Z
    end

    function Aim.Center()
        local c = cam()
        local vp = (c and c.ViewportSize) or Vector2.new(1920, 1080)
        return vp / 2
    end

    function Aim.Visible(origin, targetPos, ignore)
        local c = cam()
        origin = origin or (c and c.CFrame.Position)
        if not origin then return true end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignore or {}
        local res = workspace:Raycast(origin, targetPos - origin, params)
        return res == nil or (res.Position - targetPos).Magnitude < 2
    end

    local function yawPitch(look)
        return atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
    end

    function Aim.AimCamera(aimPoint, smoothX, smoothY)
        local c = cam(); if not c then return end
        local pos = c.CFrame.Position
        local ax = math.clamp(1 - (smoothX or 0), 0.01, 1)
        local ay = math.clamp(1 - (smoothY or 0), 0.01, 1)
        local cy, cp = yawPitch(c.CFrame.LookVector)
        local gy, gp = yawPitch((aimPoint - pos).Unit)
        local dy = (gy - cy + math.pi) % (2 * math.pi) - math.pi -- camino angular corto
        local ny = cy + dy * ax
        local np = cp + (gp - cp) * ay
        local nl = Vector3.new(-math.sin(ny) * math.cos(np), math.sin(np), -math.cos(ny) * math.cos(np))
        c.CFrame = CFrame.lookAt(pos, pos + nl)
    end

    function Aim.CanMouse() return typeof(mousemoverel) == "function" end

    function Aim.AimMouse(delta, smoothX, smoothY)
        if not Aim.CanMouse() then return false end
        local fx = math.clamp(1 - (smoothX or 0), 0.01, 1)
        local fy = math.clamp(1 - (smoothY or 0), 0.01, 1)
        mousemoverel(delta.X * fx, delta.Y * fy)
        return true
    end

    U.Services.Aim = Aim
end
