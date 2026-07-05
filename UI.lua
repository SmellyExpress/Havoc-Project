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
-- =============================================================================
-- 4. RECURSIVE CACHE WORKER WITH LIVE DEBUGGING PRINTS
-- =============================================================================

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
                -- DEBUG: Print every single model with a humanoid we look at
                print("[CACHE DEBUG] Checking character model: " .. tostring(modelName))
                
                if playerNames[modelName] then
                    -- DEBUG: Log when we ignore a real human player
                    print("  -> SKIPPED: Match found in active player list.")
                else
                    local hrp = child:FindFirstChild("HumanoidRootPart")
                        or child:FindFirstChild("Torso")
                        or child:FindFirstChild("UpperTorso")
                        or child:FindFirstChild("Head")
                    if not hrp then
                        pcall(function() hrp = child:FindFirstChildWhichIsA("BasePart") end)
                    end
                    
                    if hrp then
                        -- DEBUG: Log when an NPC successfully passes all checks
                        print("  -> SUCCESS: Added NPC to tracking table.")
                        table.insert(outTable, child)
                    else
                        -- DEBUG: Log if an NPC has a humanoid but no base/root parts to track
                        print("  -> ERROR: Model has a Humanoid but no valid tracking parts.")
                    end
                end
            else
                local cn = child.ClassName
                if cn == "Model" or cn == "Folder" then
                    -- DEBUG: Trace whenever the script dives into a folder layer
                    print(string.format("[CACHE TRACE] Diving deeper into %s: '%s' (Depth: %d)", cn, child.Name, depth + 1))
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
        -- DEBUG: Log when the primary target folder is scanned
        print("[CACHE DEBUG] Scanning 'Characters' folder location...")
        collectOnlyNpcs(folder, myChar, playerNames, EntityCache.NPCs, 0)
    else
        -- DEBUG: Log when using the fallback top-level scan
        print("[CACHE DEBUG] 'Characters' folder not found. Falling back to entire Workspace scan...")
        collectOnlyNpcs(workspace, myChar, playerNames, EntityCache.NPCs, 0)
    end
    
    -- DEBUG: Final check showing total targets stored during this 1-second refresh cycle
    print(string.format("[CACHE SUMMARY] Loop complete. Total NPCs stored: %d", #EntityCache.NPCs))
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

    
        
