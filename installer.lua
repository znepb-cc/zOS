local baseURL = "https://raw.githubusercontent.com/znepb/zOS/master/"
local args = {...}
if args[1] == "--dev" then
    baseURL = "https://raw.githubusercontent.com/znepb/zOS/development/"
end

print('zOS Installer')
fs.makeDir('/.temp/')
print('Downloading JSON API...')
local data = http.get(baseURL.."/system/zOS/System/API/json.lua")
local jsonAPI = fs.open("/.temp/json.lua", "w")
jsonAPI.write(data.readAll())
jsonAPI.close()
os.loadAPI('/.temp/json.lua')
print('Loading installer-files.json...')
local data = http.get(baseURL.."/installer-files.json")
local installerInfo = json.decode(data.readAll())
data.close()

print('Required size: '.. installerInfo.requiredSpace)
print('Space available: ' .. fs.getFreeSpace('/'))

if installerInfo.requiredSpace < fs.getFreeSpace('/') then
    print('Space OK')
    sleep(0.5)
    local w, h = term.getSize()
    local progress = 0
    local function mainDraw()
        term.setBackgroundColor(colors.black)
        term.clear()
        if fs.exists("/zOS/Images/zOS.nfp") then
            paintutils.drawImage(paintutils.loadImage("/zOS/Images/zOS.nfp"),w/2-20/2,h/2-7/2*1.2)
        end
        term.setCursorPos(w/2+20/2-string.len("v. 0"),h/2-7/2*1.2+7)
        term.setBackgroundColor(colors.black)
    end

    local function updateLoadingBar(prog)
        progress = prog
        paintutils.drawLine(w/2-20/2, h/2*1.5, w/2+20/2+0.5, h/2*1.5, colors.lightGray)
        paintutils.drawLine(w/2-20/2, h/2*1.5, w/2-20/2+((progress/100)*20), h/2*1.5, colors.lightBlue)
    end

    local function updateText(text)
        term.setCursorPos(w/2-string.len(text)/2,h/2*1.5)
        term.write(text)
    end

    local function dlText(text)
        term.setCursorPos(w/2-string.len(text)/2,h/2*1.5+2)
        term.write(text)
    end

    local progress = 0
    mainDraw()
    updateText('Creating directories...')
    for i, v in pairs(installerInfo.createDirs) do
        fs.makeDir(v)
    end
    mainDraw()
    for i, v in pairs(installerInfo.downloadFiles) do
        mainDraw()
        updateLoadingBar(i/#installerInfo.downloadFiles*100)
        term.setBackgroundColor(colors.black)
        dlText('Downloading '..v)
        local data = http.get(baseURL.."/system"..v)
        local fileH = fs.open(v, "w")
        fileH.write(data.readAll())
        fileH.close()
    end
    
    mainDraw()
    updateText('Restarting...')
    sleep(0.5)
    os.reboot()
end