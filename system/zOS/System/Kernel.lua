-- not actually a kernel, just check zOS before starting
local ok = true

local files = {
    "/zOS/Applications/Icons/default.zif",
    "/zOS/Configuration/configuration.txt",
    "/zOS/Configuration/themes.txt",
    "/zOS/System/Launcher.lua",
    "/zOS/System/Updater.lua",
    "/zOS/System/Notifications.lua",
    "/zOS/System/Autorun.lua",
    "/zOS/System/Settings.lua",
}

sleep(0.1)

for i, v in pairs(files) do 
    if fs.exists(v) then
        term.setTextColor(colors.green)
        term.write("[OK] ")
        term.setTextColor(colors.white)
        print(v)
    else
        term.setTextColor(colors.red)
        term.write("[FAIL] ")
        term.setTextColor(colors.white)
        print(v)
        ok = false
    end
end

if ok == true then
    sleep(0.3)
    multishell.launch( {
        ["shell"] = shell,
        ["multishell"] = multishell,
    }, "/zOS/System/Launcher.lua" )
    multishell.launch( {
        ["shell"] = shell,
        ["multishell"] = multishell,
    }, "/zOS/System/Autorun.lua" )
    os.queueEvent('multishell_redraw')
end