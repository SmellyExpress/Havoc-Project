UI.AddTab("Visuals", function(tab)
    local Esp = tab:Section("Esp", "Left", {"Targeting", "Silent"})
    if Esp.page == 0 then
        Esp:Toggle("esp_enabled", "Enable ESP")
    elseif Esp.page == 1 then
        Esp:Toggle("silent_enabled", "Enable Silent")
    end
end)
