-- bootstrap: crea la ventana + gate de auth (frontera para key system futuro)
return function(U)
    local Lib = U.Library
    -- cleanup de instancia previa: evita fugas de conexiones/Drawing al recargar
    if getgenv().__MBT_CLEANUP then pcall(getgenv().__MBT_CLEANUP) end
    local function AuthCheck() return true end -- reemplazable por HWID+key contra CF Workers
    if not AuthCheck() then return end
    U.Window = Lib:CreateWindow({ Title = "military base", Size = Vector2.new(834, 586) })
    U.Window:AddSettingsTab() -- UI de configs (Save/Load/Autoload) que ya trae la lib
    getgenv().__MBT = U
end
