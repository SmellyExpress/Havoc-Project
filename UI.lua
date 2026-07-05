--Cleanup Previous runs
if _G.HavocCleanup then
    local success, errorMessage = pcall(_G.HavocCleanup)
    if not success then
        warn("failed to cleanup previous script instance: " ..tostring(errorMessage))
    end
end

local isScriptRunning = true

_G.HavocCleanup = function()
    isScriptRunning = false
    print("Cleaned up previous session.")
end
--Global Tables 
EntityCache = {
    NPCs = {}
}
--UI DEF
if typeof(UI) == "table" and UI.AddTab then
    UI.AddTab("Havoc", function(tab)
        local VisualSec = tab:Section("Visuals", "Left")
        VisualSec:Toggle("havoc_esp", "Esp", false)
    end)
else
    warn("UI Library not found")
end

--Cache
local function collectOnlyNpcs(inst, myChar, playerNames, outTable, depth)
    if depth > 8 then return end
    local ok, kids = pcall(function() return inst:GetChildren() end)
    if not ok or not kids then return end

    for _, child in ipairs(kids) do
        if child ~= myChar then
            local hum
            pcall(function() hum = child:FindFirstChildOfClass("Humanoid") end)
            
            if hum then
                local modelName = child.Name
                if not playerNames[modelName] then
                    local hrp = child:FindFirstChild("HumanoidRootPart")
                        or child:FindFirstChild("Torso")
                        or child:FindFirstChild("UpperTorso")
                        or child:FindFirstChild("Head")
                    if not hrp then
                        pcall(function() hrp = child:FindFirstChildWhichIsA("BasePart") end)
                    end
                    
                    if hrp then
                        table.insert(outTable, child)
                    end
                end
            else
                local cn = child.ClassName
                if cn == "Model" or cn == "Folder" then
                    collectOnlyNpcs(child, myChar, playerNames, outTable, depth + 1)
                end
            end
        end
    end
end

local function updateNpcCache()
    EntityCache.NPCs = {}

    local PlayersService = game:GetService("Players")
    if not PlayersService then return end

    local localPlayer = PlayersService.LocalPlayer
    local myChar = localPlayer and localPlayer.Character

    local playerNames = {}
    for _, p in ipairs(PlayersService:GetPlayers()) do
        playerNames[p.Name] = true
    end

    local folder = workspace:FindFirstChild("Characters")
    if folder then
        collectOnlyNpcs(folder, myChar, playerNames, EntityCache.NPCs, 0)
    else
        collectOnlyNpcs(workspace, myChar, playerNames, EntityCache.NPCs, 0)
    end
end

--Background thread
task.spawn(function()
    while isScriptRunning do
        pcall(updateNpcCache)
        task.wait(1)
    end
end)
    

--MainLoop
task.spawn(function()
    while isScriptRunning do
        if typeof(UI) == "table" and UI.GetValue then
            if UI.GetValue("havoc_esp") then
                print("--- [DEBUG] Tracked NPCs ---")
                
                if #EntityCache.NPCs == 0 then
                    print("No non-player NPCs found in workspace.")
                else
                    for index, npc in ipairs(EntityCache.NPCs) do
                        print(string.format("[%d] %s", index, npc.Name))
                    end
                end
                
                print("-----------------------------")
            end
        end

        task.wait(1)
    end

    print("Logic loop safely stopped.")
end)

print("[Havoc Project] Step 1 initialized successfully.")

    
        
