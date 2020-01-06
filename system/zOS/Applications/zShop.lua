local function main()
    local w, h = term.getSize()
    local home
    local apps
    local menu = 1
    local lang = multishell.getLanguage()
    local theme = multishell.loadTheme()

    multishell.setTitle(multishell.getFocus(), lang.applications.zShop.name)
    local m = term.current()

    local function getURLcontents(src)
        local ok, err = pcall(function()
            local h = http.get(src)
            data = h.readAll()
            h.close()
        end)
        if not ok then
            return false
        else
            return data
        end

    end

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

    local function changeLoadScreen(text)
        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
        term.clear()
        term.setCursorPos(w/2-string.len(text)/2, h/2)
        term.write(text)
    end

    local function updateLoading(data)
        term.setCursorPos(1,h)
        term.setTextColor(colors.lightGray)
        term.write(data)
    end

    changeLoadScreen(lang.applications.zShop.loading.settingUp)
    local data = http.get("https://znepb.github.io/zShop/version.txt")
    if not data then
        term.setBackgroundColor(colors.white)
        term.clear()
        term.setTextColor(colors.red)
        local function center(t, p)
            term.setCursorPos(w/2-string.len(t)/2, p)
            term.write(t)
        end

        center(lang.applications.zShop.noInternet.title, h/2-2)
        term.setTextColor(colors.gray)
        center(lang.applications.zShop.noInternet.couldNotConnect, h/2)
        center(lang.applications.zShop.noInternet.checkConnection, h/2+1)
        center(lang.applications.zShop.noInternet.pressKey, h/2+3)

        os.pullEvent("char")
        os.queueEvent("Terminate")
    end
    sleep(0.1)
    if not fs.exists("/User/Application Data/.temp/") then
        fs.makeDir("/User/Application Data/.temp/")
    end

    if not fs.exists("/User/Application Data/zShop/") then
        fs.makeDir("/User/Application Data/zShop/")
    end

    changeLoadScreen(lang.applications.zShop.loading.api)

    changeLoadScreen(lang.applications.zShop.loading.jsonApi)
    if fs.exists("/User/Application Data/zShop/json.lua") then fs.delete("/User/Application Data/zShop/json.lua") end
    saveDataToFile( getURLcontents( "https://pastebin.com/raw/4nRg9CHU" ), "/User/Application Data/zShop/json.lua" )

    changeLoadScreen(lang.applications.zShop.loading.downloadShopInfo)

    changeLoadScreen(lang.applications.zShop.loading.downloadApps)
    saveDataToFile(getURLcontents("https://znepb.github.io/zShop/apps.json"), "/User/Application Data/zShop/apps.json")
        
    changeLoadScreen(lang.applications.zShop.loading.downloadHomepage)
    saveDataToFile(getURLcontents("https://znepb.github.io/zShop/home.json"), "/User/Application Data/zShop/home.json")

    changeLoadScreen(lang.applications.zShop.loading.downloadVersionData)
    saveDataToFile(getURLcontents("https://znepb.github.io/zShop/version.txt"), "/User/Application Data/zShop/shopDataVersion.txt")

    changeLoadScreen(lang.applications.zShop.loading.complete)
    sleep(0.5)

    local loading = {
        {"\153\153\153\153\153\153\153\153\153", "333333333", "bbbbbbbbb"},
        {"\153\153\153\153\153\153\153\153\153", "bbbbbbbbb", "333333333"},
        {"\153\153\153\153\153\153\153\153\153", "333333333", "bbbbbbbbb"},
        {"\153\153\153\153\153\153\153\153\153", "bbbbbbbbb", "333333333"}
    }

    local error = {
        {"\153\153\153\153\153\153\153\153\153", "666666666", "eeeeeeeee"},
        {"\153\153\153\153\153\153\153\153\153", "eeeeeeeee", "666666666"},
        {"\153\153\153\153\153\153\153\153\153", "666666666", "eeeeeeeee"},
        {"\153\153\153\153\153\153\153\153\153", "eeeeeeeee", "666666666"}
    }

    home = getFileContents("/User/Application Data/zShop/home.json")
    apps = getFileContents("/User/Application Data/zShop/apps.json")
    os.loadAPI("/zOS/System/API/zif.lua")
    os.loadAPI("/User/Application Data/zShop/json.lua")
    term.setBackgroundColor(colors.white)
    term.clear()

    local apps = {}
    local sID

    local function drawApp(id)
        menu = 2
        sID = apps[id].id
        term.setCursorPos(2,2)
        term.setBackgroundColor(theme.background)
        term.clear()
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.write(" "..lang.applications.zShop.app.back.." ")
        zif.drawImageTable(2, 4, apps[id][1])
        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
        term.setCursorPos(12,4)
        term.write(apps[id].name)
        term.setCursorPos(12,5)
        term.write(string.format(lang.applications.zShop.app.by, apps[id].author))
        if not fs.exists("/zOS/Applications/"..sID..".lua") then
            term.setCursorPos(12,7)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
            term.write(" "..lang.applications.zShop.app.install.." ")
            
        else
            term.setCursorPos(18,7)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
            term.write(" "..lang.applications.zShop.app.uninstall.." ")
            term.setCursorPos(12,7)
            term.setBackgroundColor(colors.gray)
            term.setTextColor(colors.lightGray)
            term.write(" "..lang.applications.zShop.app.run.." ")
        end

        local w = window.create(term.current(),2,9,w-2,h-9)
        local m = term.current()
        w.setBackgroundColor(theme.background)
        w.setTextColor(theme.text)
        w.clear()
        term.redirect(w)
        print(apps[id].desc)
        term.redirect(m)
    end


    local function loadHomeScreen()
        term.setCursorPos(2,2)
        term.setTextColor(theme.text)
        term.setBackgroundColor(theme.background)
        term.clear()
        term.write(lang.applications.zShop.home.featured)
        term.setCursorPos(2,10)
        term.setTextColor(theme.text)
        term.setBackgroundColor(theme.background)
        term.write(lang.applications.zShop.home.newest)
        local p = 2
        for i, v in pairs(json.decode(getFileContents("/User/Application Data/zShop/home.json")).Featured) do
            zif.drawImageTable(p,4,loading)
            term.setCursorPos(p,8)
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)
            term.write(json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].name)
            table.insert(apps, {id = v, desc = json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].description, name = json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].name, author = json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].author, x = p, y = 4, selected = false})
            p = p + 10
        end

        local p = 2
        for i, v in pairs(json.decode(getFileContents("/User/Application Data/zShop/home.json")).Newest) do
            zif.drawImageTable(p,12,loading)
            term.setCursorPos(p,16)
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)
            term.write(json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].name)
            table.insert(apps, {id = v, desc = json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].description, name = json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].name, author = json.decode(getFileContents("/User/Application Data/zShop/apps.json"))[v].author, x = p, y = 12, selected = false})
            p = p + 10
        end

        local p = 2
        local item = 1
        for i, v in pairs(json.decode(getFileContents("/User/Application Data/zShop/home.json")).Featured) do
            updateLoading(string.format(lang.applications.zShop.home.dataLoading, v))
            if pcall(function()zif.drawImageTable(p,4,textutils.unserialize(getURLcontents("https://znepb.github.io/zShop/icons/"..v..".zif")))end) then 

                table.insert(apps[item], textutils.unserialize(getURLcontents("https://znepb.github.io/zShop/icons/"..v..".zif")))
                
            else 
                zif.drawImageTable(p,4,error)
                table.insert(apps[item], error)
            end
            
            item = item + 1
            p = p + 10
        end

        local p = 2
        for i, v in pairs(json.decode(getFileContents("/User/Application Data/zShop/home.json")).Newest) do
            updateLoading(string.format(lang.applications.zShop.home.dataLoading, v))
            if pcall(function()zif.drawImageTable(p,12,textutils.unserialize(getURLcontents("https://znepb.github.io/zShop/icons/"..v..".zif")))end) then 

                table.insert(apps[item], textutils.unserialize(getURLcontents("https://znepb.github.io/zShop/icons/"..v..".zif")))
                
            else 
                zif.drawImageTable(p,12,error)
                table.insert(apps[item], error)
            end
            
            item = item + 1
            p = p + 10
        end
        updateLoading(string.rep(" ", w))
    
    end

    local function buttons()
        while true do
            local e, m, x, y = os.pullEvent("mouse_click")
            if menu == 2 then
                if x >= 2 and x <= 9 and y == 2 then
                    menu = 1
                    loadHomeScreen()
                end
                if not fs.exists("/zOS/Applications/"..sID..".lua") then
                    if x >= 12 and x <= 20 and y == 7 then
                        term.setBackgroundColor(theme.background)
                        term.setTextColor(theme.text)
                        term.setCursorPos(12,7)
                        term.write(lang.applications.zShop.app.downloading)
                        saveDataToFile(getURLcontents("https://znepb.github.io/zShop/apps/"..sID..".lua"), "/zOS/Applications/"..sID..".lua")
                        local data = textutils.unserialize(getFileContents("/zOS/Applications/applications.txt"))
                        local t = {}
                        for i, v in pairs(apps) do
                            if v.id == sID then
                                t = v
                            end
                        end
                        table.insert(data,{
                            filePath = "/zOS/Applications/"..sID..".lua",
                            fileIconName = "idkifthissduibhg.zif",
                            zShopId = sID,
                            fileName = t.name,
                            version = 1.0,
                        })
                        term.setCursorPos(12,7)
                        saveDataToFile(textutils.serialize(data), "/zOS/Applications/applications.txt")
                        term.write(lang.applications.zShop.app.complete.."                 ")
                        multishell.sendNotification('zShop', string.format(lang.applications.zShop.app.doneNotification, t.name))
                    end
                else
                    if x >= 12 and x <= 16 and y == 7 then
                        multishell.setFocus(multishell.launch({
                            ['shell'] = shell,
                            ['multishell'] = multishell,
                        }, "/zOS/Applications/"..sID..".lua"))
                    elseif x >= 18 and x <= 28 and y == 7 then
                        term.setCursorPos(12,7)
                        term.setBackgroundColor(theme.background)
                        term.setTextColor(theme.text)
                        term.write(lang.applications.zShop.app.removing)
                        fs.delete("/zOS/Applications/"..sID..".lua")
                        local data = textutils.unserialize(getFileContents("/zOS/Applications/applications.txt"))
                        for i, v in pairs(data) do
                            if v.zShopId then
                                if v.zShopId == sID then
                                    table.remove(data, i)
                                end
                            end
                        end
                        saveDataToFile(textutils.serialize(data), "/zOS/Applications/applications.txt")
                        term.setCursorPos(12,7)
                        term.write(lang.applications.zShop.app.complete.."                 ")
                    end
                end
            end
            for i, v in pairs(apps) do
                if menu == 1 then
                    if x >= v.x and y >= v.y and x <= v.x+9 and y <= v.y+8 then
                        if v.selected == false then
                            zif.drawImageTable(v.x, v.y, v[1])
                            term.setCursorPos(v.x, v.y+4)
                            term.setBackgroundColor(theme.selectionBackground)
                            term.setTextColor(theme.text)
                            term.write(v.name)
                            v.selected = true
                        else
                            drawApp(i)
                        end
                    else
                        zif.drawImageTable(v.x, v.y, apps[1])
                        term.setCursorPos(v.x, v.y+4)
                        term.setBackgroundColor(theme.background)
                        term.setTextColor(theme.text)
                        term.write(v.name)
                        v.selected = false
                    end
                end
            end
        end
    end

    parallel.waitForAll(loadHomeScreen, buttons)
end

local ok, err = pcall(main)

if not ok then
	if err ~= 'Terminated' then
		local w, h = term.getSize()
		paintutils.drawFilledBox(w/2-15,h/2-4,w/2+16,h/2+4,colors.white)
		paintutils.drawBox(w/2-15,h/2-4,w/2+16,h/2+4,colors.lightGray)
		paintutils.drawLine(w/2-15,h/2-4,w/2+16,h/2-4,colors.gray)
		term.setCursorPos(w/2-14,h/2-4)
		term.setTextColor(colors.lightGray)
		term.write("Application error")
		local lineChar = 1
        local str = "An application error has occured and the program you were using has been forced to close. Here's the error: ".. err
		local line = ""
		term.setTextColor(colors.gray)
		term.setBackgroundColor(colors.white)
		pos = h/2-3
        for i = 1, string.len(str) do
            if lineChar == 31 then
                lineChar = 1
                line = ""
                pos = pos + 1
            end
            line = line .. string.sub(str, i, i)
            term.setCursorPos(w/2-14, pos)
            term.write(line)
            lineChar = lineChar + 1
		end
		term.setCursorPos(w/2-14,h/2+3)
		term.write('Press any key to exit')
		sleep(0.5)
		os.pullEvent('char')
	end
	
end