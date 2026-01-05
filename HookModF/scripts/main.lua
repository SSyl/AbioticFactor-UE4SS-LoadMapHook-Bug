local modName = "[Hook Mod F] "
local mapHooksEnabled = true
local initHooksEnabled = true

print(modName.."Loading...\n")

if mapHooksEnabled then
    local success, err = pcall(function()
        RegisterLoadMapPreHook(function(Engine, WorldContext, URL, PendingGame, Error)
            print(string.format("%sRegisterLoadMapPreHook fired!\n", modName))
        end)
    end)
    print(string.format("%sRegisterLoadMapPreHook %s\n", modName, success and "pcall success" or ("FAILED: "..tostring(err))))

    local success, err = pcall(function()
        RegisterLoadMapPostHook(function(Engine, WorldContext, URL, PendingGame, Error)
            print(string.format("%sRegisterLoadMapPostHook fired!\n", modName))
        end)
    end)
    print(string.format("%sRegisterLoadMapPostHook %s\n", modName, success and "pcall success" or ("FAILED: "..tostring(err))))
end

if initHooksEnabled then
    local success, err = pcall(function()
        RegisterInitGameStatePreHook(function(Context)
            print(string.format("%sRegisterInitGameStatePreHook fired!\n", modName))
        end)
    end)
    print(string.format("%sRegisterInitGameStatePreHook %s\n", modName, success and "pcall success" or ("FAILED: "..tostring(err))))

    local success, err = pcall(function()
        RegisterInitGameStatePostHook(function(Context)
            print(string.format("%sRegisterInitGameStatePostHook fired!\n", modName))
        end)
    end)
    print(string.format("%sRegisterInitGameStatePostHook %s\n", modName, success and "pcall success" or ("FAILED: "..tostring(err))))
end

print(modName.."Mod loaded\n")
