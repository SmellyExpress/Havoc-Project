UI.AddTab("Havoc", function(tab)
    local Esp = tab:Section("Esp", "Left", {"Visuals", "World"})
    if Esp.page == 0 then
        Esp:Toggle("esp_enabled", "Enable ESP")
    elseif Esp.page == 1 then
        Esp:Toggle("world_enabled", "Enable World ESP")
    end
end)
