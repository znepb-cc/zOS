local w, h = term.getSize()
local function mainDraw()
    term.setBackgroundColor(colors.black)
    term.clear()
    paintutils.drawImage(paintutils.loadImage("/zOS/Images/zOS.nfp"),w/2-20/2,h/2-7/2*1.2)
    term.setCursorPos(w/2+20/2-string.len("v. 0"),h/2-7/2*1.2+7)
    term.setBackgroundColor(colors.black)
end

os.loadAPI('zOS/System/API/json.lua')

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
updateText('Updating...')
local data = http.get("https://raw.githubusercontent.com/znepb/zOS/master/versions/current.txt")
local newV = data.readAll()
data.close()

local file = fs.open("/zOS/Configuration/version.txt", "w")
file.write(newV)
file.close()

updateText('Downloading update information...')
local data = http.get("https://raw.githubusercontent.com/znepb/zOS/master/versions/"..newV..".json")
local updateInformation = json.decode(data.readAll())
data.close()

mainDraw()

progress = 0
paintutils.drawLine(w/2-20/2, h/2*1.5, w/2+20/2-1, h/2*1.5, colors.lightGray)
paintutils.drawLine(w/2-20/2, h/2*1.5, w/2-20/2+((progress/100)*20), h/2*1.5, colors.lightBlue)
print(updateInformation.files[1])
for i, v in pairs(updateInformation.files) do
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.black)
    dlText("Downloading: "..v)
    local data = http.get("https://raw.githubusercontent.com/znepb/zOS/master/system/"..v)
    local fileInfo = data.readAll()
    data.close()
    local file = fs.open(v, "w")
    file.write(fileInfo)
    file.close()

    progress = (i/#updateInformation.files)*100
    paintutils.drawLine(w/2-20/2, h/2*1.5, w/2+20/2-1, h/2*1.5, colors.lightGray)
    paintutils.drawLine(w/2-20/2, h/2*1.5, w/2-20/2+((progress/100)*20)-1, h/2*1.5, colors.lightBlue)
    sleep(0.5)
end
progress = 100
paintutils.drawLine(w/2-20/2, h/2*1.5, w/2-20/2+((progress/100)*20), h/2*1.5, colors.lightBlue)
mainDraw()
os.reboot()