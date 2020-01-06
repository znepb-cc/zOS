local w, h = term.getSize()
os.loadAPI("/zOS/System/API/zif.lua")

local lang = multishell.getLanguage()
multishell.setTitle(multishell.getCurrent(), lang.applications.createApp.appName)
local theme = multishell.loadTheme()
local selectedIcon = '/zOS/Applications/Icons/default.zif'
local name = ""
local path = ""
local ok = false

local function saveDataToFile(data, path)
    local h = fs.open(path, "w")
    h.write(data)
    h.close()
    return true
end

local function getFileContents(path)
    local h = fs.open(path, "r")
    local data = h.readAll()
    h.close()
    return data
end

local function draw()
    ok = false
    term.setBackgroundColor(theme.background)
    term.setTextColor(theme.text)
    term.clear()
    term.setCursorPos(4,2)
    term.write(lang.applications.createApp.icon)

    local imageOk = true

    if fs.exists(selectedIcon) then
		if selectedIcon:match("^.+(%..+)$") == ".zif" then
            zif.drawImage(2,3,selectedIcon)
            imageOk = true
		elseif selectedIcon:match("^.+(%..+)$") == ".nfp" then
            paintutils.drawImage(2,3,paintutils.loadImage(selectedIcon))
            imageOk = true
        elseif selectedIcon == "" then
            selectedIcon = '/zOS/Applications/Icons/default.zif'
            zif.drawImage(2,3,'/zOS/Applications/Icons/default.zif')
            imageOk = true
		else
            zif.drawImage(2,3,selectedIcon)
            term.setTextColor(colors.red)
            term.setCursorPos(12,12)
            term.write(lang.applications.createApp.errors.invalidFormat)
            zif.drawImage(2,3,'/zOS/Applications/Icons/default.zif')
            term.setTextColor(theme.text)
            imageOk = false
		end
    else
        term.setTextColor(colors.red)
        term.setCursorPos(12,12)
        term.write(lang.applications.createApp.errors.fileNotFound)
        zif.drawImage(2,3,'/zOS/Applications/Icons/default.zif')
        term.setTextColor(theme.text)
        imageOk = false
    end

    local pathOk = false

    if path == "" then
    elseif not fs.exists(path) then
        term.setTextColor(colors.red)
        term.setCursorPos(12,8)
        term.write(lang.applications.createApp.errors.fileNotFound)
        term.setTextColor(theme.text)
    else
        pathOk = true
    end

    local nameOk = false

    if name ~= "" then
        nameOk = true
    end

    term.setCursorPos(12,2)
    term.write(lang.applications.createApp.name)

    term.setCursorPos(12,6)
    term.write(lang.applications.createApp.path)

    term.setCursorPos(12,10)
    term.write(lang.applications.createApp.iconPath)

    if pathOk == true and imageOk == true and nameOk == true then ok = true end

    term.setCursorPos(12,14)
    if ok then
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
    else
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.gray)
    end
    term.write(lang.applications.createApp.create)

    paintutils.drawLine(12,3,w-2,3,colors.gray)
    paintutils.drawLine(12,7,w-2,7,colors.gray)
    paintutils.drawLine(12,11,w-2,11,colors.gray)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(13,3)
    term.write(name)

    term.setCursorPos(13,7)
    term.write(path)

    term.setCursorPos(13,11)
    term.write(selectedIcon)

   
end

draw()

while true do
    local e = {os.pullEvent()}
    if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], e[4]
        if x <= w-2 and x >= 12 and y <= 11 then
            if y == 3 then
                paintutils.drawLine(12,3,w-2,3,colors.gray)
                term.setCursorPos(13,3)
                name = read()
            elseif y == 7 then
                paintutils.drawLine(12,7,w-2,7,colors.gray)
                term.setCursorPos(13,7)
                path = read()
            elseif y == 11 then
                paintutils.drawLine(12,11,w-2,11,colors.gray)
                term.setCursorPos(13,11)
                selectedIcon = read()
            end
            draw()
        elseif x >= 12 and x <= 12+string.len(lang.applications.createApp.create) and y == 14 and ok == true then
            local data = textutils.unserialize(getFileContents("/zOS/Applications/applications.txt"))
            table.insert(data,{
                filePath = path,
                fileIconName = selectedIcon,
                fileName = name,
                version = 1.0,
            })
            saveDataToFile(textutils.serialize(data), "/zOS/Applications/applications.txt")
            error('created')
        end
    end
end