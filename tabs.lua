-- tabs main del suite (Base Militar Tycoon, place 23380021)
return function(U)
    local Win = U.Window
    U.Tabs.Combat  = Win:AddCategory("Combat",  "crosshair")
    U.Tabs.Visuals = Win:AddCategory("Visuals", "eye")
    U.Tabs.Tycoon  = Win:AddCategory("Tycoon",  "coins")
    U.Tabs.Misc    = Win:AddCategory("Misc",    "settings")
end
