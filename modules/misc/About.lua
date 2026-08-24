-- About: contenido visible para verificar el pipeline UI + módulos vivo
return function(U)
    local Misc = U.Tabs.Misc
    local Sec = Misc:AddSection("About", "Base Militar Tycoon suite")
    local Pan = Sec:AddPanel("Info", { Column = 1 })
    Pan:AddLabel("MilitaryBasePrimordial", { Header = true })
    Pan:AddLabel("place 23380021 · Base Militar Tycoon")
    Pan:AddLabel("v0 · scaffold")
    Pan:AddDivider()
    Pan:AddLabel("Toggle UI: RightShift", { Header = true })
end
