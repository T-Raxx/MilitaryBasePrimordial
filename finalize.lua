-- corre ultimo: envuelve Unload para limpiar modulos+servicios, watermark, notifica
return function(U)
    -- envuelve Lib:Unload para que el boton Unload/ToggleKey limpie modulos+servicios
    -- (Drawing/ESP + conexiones Heartbeat), que PrimordialUI no conoce
    local rawUnload = U.Library.Unload
    U.Library.Unload = function(self)
        if U.Registry then pcall(U.Registry.UnloadAll) end
        for _, s in pairs(U.Services) do
            if type(s) == "table" and s.Unload then pcall(s.Unload) end
        end
        return rawUnload(self)
    end
    -- cleanup global reutilizable: lo llama el proximo load (bootstrap) para no dejar fugas
    getgenv().__MBT_CLEANUP = function() pcall(function() U.Library:Unload() end) end
    -- defer: el Settings tab roba foco al crearse; forzamos Combat tras el frame
    task.defer(function() U.Window:SetActiveCategory(U.Tabs.Combat) end)
    U.Library:SetWatermark("military base | dev")
    U.Library:Notify({ Title = "MilitaryBasePrimordial", Description = "cargado", Time = 3 })
    print("[MBT] loaded")
end
