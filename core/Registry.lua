-- registro de modulos: cada uno registra su Unload para el cleanup global
return function(U)
    local Reg = { _mods = {} }
    function Reg.Add(name, ctrl) Reg._mods[name] = ctrl end
    function Reg.Get(name) return Reg._mods[name] end
    function Reg.UnloadAll()
        for _, ctrl in pairs(Reg._mods) do
            if ctrl and ctrl.Unload then pcall(ctrl.Unload) end
        end
        Reg._mods = {}
    end
    U.Registry = Reg
end
