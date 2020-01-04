local w, h = term.getSize()
local imagePos = h/2-7/2
local textPos = h/2+5
term.setBackgroundColor(colors.black)
term.clear()
paintutils.drawImage(paintutils.loadImage("/zOS/Images/zOS.nfp"),w/2-20/2,h/2-7/2)
paintutils.drawLine(w/2-20/2,textPos,w/2+20/2,textPos, colors.lightGray)

local function getSetting(name)
    local f = fs.open("/zOS/Configuration/configuration.txt", "r")
    local configData = textutils.unserialize(f.readAll())
    local data = configData[name]
    f.close()
    return data
end

if fs.exists("/zOS/System/n_Updater.lua") then
    fs.delete("/zOS/System/Updater.lua")
    fs.copy("/zOS/System/n_Updater.lua", "/zOS/System/Updater.lua")
    fs.delete("/zOS/System/n_Updater.lua")
end

local progress = 40
local files = 0
local cFile = 0
local function getAllFiles(path)
    for i, v in pairs(fs.list(path)) do
        if fs.isDir(path..v) then
            getAllFiles(path..v.."/")
        else
            files = files + 1
        end
        
    end
end

os.loadAPI("/zOS/System/API/aeslua")
local h = fs.open("/zOS/Configuration/configuration.txt", "r")
local data = textutils.unserialize(h.readAll())
h.close()
w, h = term.getSize()

if data.password ~= "" then
    str = aeslua.decrypt("zOS-super-secret-password-lol", data.password)
end

local function encryptFiles(path)
    for i, v in pairs(fs.list(path)) do
        if fs.isDir(path..v) then
            encryptFiles(path..v.."/")
        else
            local r = fs.open(path..v, "r")
            cipher = aeslua.encrypt(str, r.readAll())
            r.close()
            local w = fs.open(path..v, "w")
            w.write(cipher)
            w.close()
            cFile = cFile + 1
            progress = (cFile / files)*90
            w, h = term.getSize()
            paintutils.drawLine(w/2-20/2, textPos, w/2-20/2+((progress/100)*20), textPos, colors.lightBlue)
        end
    end
end

if not fs.exists("/User/thishasbeenoofed.txt") and data.password ~= "" then
    getAllFiles("/User/")
    encryptFiles("/User/")
    local w = fs.open("/User/thishasbeenoofed.txt", "w")
    w.write("OwO yes")
    w.close()
end
progress = 90
paintutils.drawLine(w/2-20/2, textPos, w/2-20/2+((progress/100)*20), textPos, colors.lightBlue)

if getSetting('autoUpdate') == true then
    local f = http.get("https://raw.githubusercontent.com/znepb/zOS/"..getSetting('branch').."/versions/current.txt")
    local data = f.readAll()
    f.close()
    local newVersion = tonumber(data)
    local currentVersionF = fs.open('zOS/Configuration/version.txt', "r")
    local currentVersion = tonumber(currentVersionF.readAll())
    currentVersionF.close()
    if newVersion > currentVersion then
        shell.run('zOS/System/Updater.lua')
    end
    progress = 100
    paintutils.drawLine(w/2-20/2, textPos, w/2-20/2+((progress/100)*20), textPos, colors.lightBlue)
end

term.setBackgroundColor(colors.black)

local ready = true

if getSetting('bootToMonitor') == true then
    local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
    newFPL = textutils.unserialize(peripheralsFile.readAll())
    peripheralsFile.close()

    for i, v in pairs(newFPL) do
        if v.primary == true then
            ready = false
            term.setBackgroundColor(colors.black)
            term.clear()
            paintutils.drawImage(paintutils.loadImage("/zOS/Images/monitor.nfp"),w/2-20/2,imagePos)
            term.setBackgroundColor(colors.black)
            term.setCursorPos(w/2-string.len("        zOS has booted to the monitor        ")/2,textPos)
            term.write("        zOS has booted to the monitor        ")
            term.setCursorPos(3,h-1)
            local m = peripheral.wrap(v.name)
            m.setTextScale(v.textScale)
            shell.run("monitor "..v.name.." /zOS/System/Login.lua")
            sleep(60*60*24*365)
        end
    end
elseif peripheral.find('monitor') then
    term.setCursorPos(w/2-string.len("        Press F1 to boot to monitor        ")/2,textPos)
    term.write("        Press F1 to boot to monitor        ")
else
    term.setCursorPos(w/2-string.len("        Press F2 for BIOS        ")/2,textPos)
    term.write("        Press F3 for BIOS        ")
end




local function findFirstOfType(tp)
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == tp then
            return name
        end
    end
end

parallel.waitForAny(function()
    while true do
        local e, k = os.pullEventRaw("key")
        if k == keys.f3 then
            ready = false
            shell.run("/zOS/System/BIOS.lua")
            sleep(60*60*24*365)
        elseif k == keys.f1 and peripheral.find('monitor') then
            local peripherals = peripheral.getNames()
            monitors = {}
            for i, v in pairs(peripherals) do
                if peripheral.getType(v) == 'monitor' then
                    table.insert(monitors, v)
                end
            end
            if monitors[getSetting('monitor')] then
                ready = false
                term.setBackgroundColor(colors.black)
                term.clear()
                paintutils.drawImage(paintutils.loadImage("/zOS/Images/monitor.nfp"),w/2-20/2,h/2-7/2)
                term.setBackgroundColor(colors.black)
                term.setCursorPos(w/2-string.len("        zOS has booted to the monitor        ")/2,h/2+2)
                term.write("        zOS has booted to the monitor        ")
                term.setCursorPos(3,h-1)
                local m = peripheral.wrap(monitors[getSetting('monitor')])
                m.setTextScale(getSetting('monitorScale'))
                shell.run("monitor "..monitors[getSetting('monitor')].." /zOS/System/Login.lua")
                sleep(60*60*24*365)
            else
                term.setCursorPos(w/2-string.len("Monitor "..getSetting('monitor').." not connected")/2,h/2+2)
                term.write("Monitor "..getSetting('monitor').." not connected")
            end
        end
		
    end
end,
function()
    for i = 0, 2, 0.05 do
        if ready == false then
            sleep(60*60*24*365)
        end
        sleep(0.05)
        
    end
end
)

shell.run("/zOS/System/Login.lua")