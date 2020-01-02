local args = { ... }

function main()
    local dir = "/"
    local dropdown = false
    local selectedList
    local listMaxX
    local listX
    local listY
    local scrollPos = 0
    local filesFormatted = {}
    local dirs = {}
    local selectionType
    local selected
    local w,h = term.getSize()
    local copiedPath
    local cutStatus
    local ctrlDown = false
    local menu = 1
    local sessionSharingPassword = "zf."..tostring(math.random(1000,9999))
    local recvTable

    if args[1] then
        dir = args[1]
    end

    local lang = multishell.getLanguage()
    local theme = multishell.loadTheme()
    multishell.setTitle(multishell.getCurrent(), lang.applications.zFile.name)
    
    local function drawNav(selected)
        term.setCursorPos(1,1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.clearLine()
        if selected == 1 then 
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.gray)
        end
        write(" "..lang.applications.zFile.nav.file.name.." ")
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        if selected == 2 then 
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.gray)
        end
        write(" "..lang.applications.zFile.nav.edit.name.." ")
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        if selected == 3 then 
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.gray)
        end
        write(" "..lang.applications.zFile.nav.send.name.." ")

        term.setCursorPos(1,2)
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.gray)
        term.clearLine()
        term.setCursorPos(5,2)
        term.write(dir)
        
        term.setCursorPos(1,2)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.write(" \24 ")
    end

    local function loadFiles()
        local files = fs.list(dir)
        term.setBackgroundColor(colors.white)
        term.setTextColor(theme.text)
        paintutils.drawFilledBox(1,3,w,h,theme.background)
        dirs = {}
        filesFormatted = {}

        for i, v in ipairs(files) do
            if fs.isDir(dir..v) then
                table.insert(dirs, {name = v, type = "Folder", size = "-"}) 
            else
                table.insert(filesFormatted, {name = v, type = "...", size = fs.getSize(dir..v)}) 
            end
        end

        for i, v in pairs(dirs) do
            term.setBackgroundColor(theme.background)
            term.setTextColor(colors.green)
            if string.sub(v.name, 1, 1) == "." then
                term.setTextColor(colors.lime)
            end
            term.setCursorPos(2,2+i+scrollPos)
            if selected then
                if selectionType == "dir" and selected == i then
                    term.setBackgroundColor(theme.selectionBackground)
                    term.clearLine()
                end
            end
            
            term.write(v.name)
        end

        for i, v in pairs(filesFormatted) do
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)
            if string.sub(v.name, 1, 1) == "." then
                term.setTextColor(colors.lightGray)
            end
            term.setCursorPos(2,2+i+scrollPos+#dirs)
            if selected then
                if selectionType == "file" and selected == i then
                    term.setBackgroundColor(theme.selectionBackground)
                    term.clearLine()
                end
            end
            term.write(v.name)
        end

    end

    local function draw()
        menu = 1
        term.setBackgroundColor(theme.background)
        term.clear()
        loadFiles()
        dropdown = nil
        drawNav()
    end

    local function drawMain()
        term.setBackgroundColor(theme.background)
        term.clear()
        drawNav()
    end
    
    local function drawDropdown(x,y,list,selected)
        menu = 2
        listX = x
        listY = y
        selectedList = list
        dropdown = true
        drawNav(selected)
        term.setCursorPos(x,y)
        local maxLength = 0
        
        for i, v in ipairs(list) do
            if string.len(v.text) > maxLength then
                maxLength = string.len(v.text)
            end
        end
        listMaxX = maxLength
        paintutils.drawFilledBox(x,y,x+maxLength+1,y+#list-1, colors.gray)
        
        for i, v in pairs(list) do
            term.setTextColor(colors.lightGray)
            if v.condition() == true then
                term.setTextColor(colors.white)
            end
            term.setCursorPos(x+1,y+i-1)
            print(v.text)
        end

    end

    local function textDialog(title,message)
        paintutils.drawFilledBox(w/2-15,h/2-4,w/2+16,h/2+4,colors.white)
		paintutils.drawBox(w/2-15,h/2-4,w/2+16,h/2+4,colors.lightGray)
		paintutils.drawLine(w/2-15,h/2-4,w/2+16,h/2-4,colors.gray)
		term.setCursorPos(w/2-14,h/2-4)
		term.setTextColor(colors.lightGray)
		term.write(title)
		local lineChar = 1
        local str = message
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
        paintutils.drawLine(w/2-13,h/2+2,w/2+14,h/2+2,colors.gray)
        term.setCursorPos(w/2-12,h/2+2)
        term.setTextColor(colors.lightGray)
        local text = read()
        draw()
        loadFiles()
        return text
    end

    local fileDropdown = {
        {
            text = lang.applications.zFile.nav.file.option.new,
            condition = function() return true end,
            action = function()
                fs.open(dir..textDialog(lang.applications.zFile.newFile.title, lang.applications.zFile.newFile.body)..".lua", "w").close()
                draw()
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.newFolder,
            condition = function() return true end,
            action = function()
                fs.makeDir(dir..textDialog(lang.applications.zFile.newFolder.title, lang.applications.zFile.newFolder.body))
                draw()
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.open,
            condition = function() return selected ~= nil end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        multishell.setFocus(multishell.launch({
                            ['shell'] = shell,
                            ['multishell'] = multishell,
                        }, dir..filesFormatted[selected].name))
                    elseif selectionType == "dir" then
                        dir = dir .. dirs[selected].name .. "/"
                    end
                end
                draw()
                selected = nil
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.edit,
            condition = function() return selected ~= nil and selectionType == "file" end,
            action = function()
                
                if selected then
                    if selectionType == "file" then
                        local ext = string.match(filesFormatted[selected].name, ".*(%..+)")
                        if ext == ".nfp" then
                            multishell.setFocus(multishell.launch({
                                ['shell'] = shell,
                                ['multishell'] = multishell,
                            }, "/rom/programs/fun/advanced/paint.lua", dir..filesFormatted[selected].name))
                        else
                            multishell.setFocus(multishell.launch({
                                ['shell'] = shell,
                                ['multishell'] = multishell,
                            }, "/rom/programs/edit.lua", dir..filesFormatted[selected].name))
                        end

                        
                    end
                end
                draw()
                selected = nil
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.saveToDisk,
            condition = function() return fs.exists('/disk/') and selected and selectedType == 'file' end,
            action = function()

            end
        }
    }

    local editDropdown = {
        {
            text = lang.applications.zFile.nav.edit.option.copy,
            condition = function() 
                if selected then 
                    return true 
                else 
                    return false 
                end
            end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        copiedPath = dir..filesFormatted[selected].name
                    elseif selectionType == "dir" then
                        copiedPath = dir..dirs[selected].name
                    end
                    
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.paste,
            condition = function() return copiedPath ~= nil end,
            action = function()
                if copiedPath ~= nil then
                    fs.copy(copiedPath, dir..fs.getName(copiedPath))
                    if cutStatus == "cut" then
                        cutStatus = nil
                        fs.delete(copiedPath)
                        copiedPath = nil
                    end
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.cut,
            condition = function() 
                if selected then 
                    return true 
                else 
                    return false 
                end
            end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        copiedPath = dir..filesFormatted[selected].name
                    elseif selectionType == "dir" then
                        copiedPath = dir..dirs[selected].name
                    end
                    cutStatus = "cut"
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.moveTo,
            condition = function() return selected ~= nil end,
            action = function()
                if selected ~= nil then
                    if selectionType == "file" then
                        fs.copy(dir..filesFormatted[selected].name, textDialog(lang.applications.zFile.moveTo.title, lang.applications.zFile.moveTo.body).."/"..filesFormatted[selected].name)
                        fs.delete(dir..filesFormatted[selected].name)
                    elseif selectionType == "dir" then
                        fs.copy(dir..dirs[selected].name, textDialog(lang.applications.zFile.moveTo.title, lang.applications.zFile.moveTo.body).."/"..dirs[selected].name)
                        fs.delete(dir..dirs[selected].name)
                    end
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.copyTo,
            condition = function() return selected ~= nil end,
            action = function()
                if selected ~= nil then
                    if selectionType == "file" then
                        fs.copy(dir..filesFormatted[selected].name, textDialog(lang.applications.zFile.copyTo.title, lang.applications.zFile.copyTo.body).."/"..filesFormatted[selected].name)
                    elseif selectionType == "dir" then
                        fs.copy(dir..dirs[selected].name, textDialog(lang.applications.zFile.moveTo.title, lang.applications.zFile.moveTo.body))
                    end
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.delete,
            condition = function() return selected ~= nil end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        fs.delete(dir..filesFormatted[selected].name)
                    elseif selectionType == "dir" then
                        fs.delete(dir..dirs[selected].name)
                    end
                end
                selected = nil
                draw()
               
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.rename,
            condition = function() return selected ~= nil end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        fs.move(dir..filesFormatted[selected].name, dir..textDialog(lang.applications.zFile.rename.title, lang.applications.zFile.rename.body))
                    elseif selectionType == "dir" then
                        fs.move(dir..dirs[selected].name, dir..textDialog(lang.applications.zFile.rename.title, lang.applications.zFile.rename.body))
                    end
                end
                draw()
                selected = nil
            end
        }
    }

    local shareDropdown = {
        {
            text = lang.applications.zFile.nav.send.option.openSharingMenu,
            condition = function() return true end,
            action = function()
                local modem = peripheral.find('modem')
                modem.open(2322)
                draw()
                menu = 3
                paintutils.drawFilledBox(w/2-15,h/2-5,w/2+16,h/2+5,colors.white)
                paintutils.drawBox(w/2-15,h/2-5,w/2+16,h/2+5,colors.lightGray)
                paintutils.drawLine(w/2-15,h/2-5,w/2+16,h/2-5,colors.gray)
                term.setCursorPos(w/2+12, h/2-5)
                term.setBackgroundColor(colors.red)
                term.setTextColor(colors.white)
                term.write(lang.applications.zFile.fileReceiveWaiting.exit)
                term.setCursorPos(w/2-14,h/2-5)
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.lightGray)
                term.write(lang.applications.zFile.fileReceiveWaiting.title)
                local lineChar = 1
                local str = lang.applications.zFile.fileReceiveWaiting.body
                local line = ""
                term.setTextColor(colors.gray)
                term.setBackgroundColor(colors.white)
                pos = h/2-4
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
                term.setCursorPos(w/2-12,h/2+2)
                term.write(lang.applications.zFile.fileReceiveWaiting.id..os.getComputerID())
                term.setCursorPos(w/2-12,h/2+3)
                term.write(lang.applications.zFile.fileReceiveWaiting.password..sessionSharingPassword)
            end
        },
        {
            text = lang.applications.zFile.nav.send.option.sendToPeer,
            condition = function() return selected ~= nil and selectionType == "file" end,
            action = function()
                if selected ~= nil and selectionType == "file" then
                    draw()
                    local id = textDialog(lang.applications.zFile.fileSend.title, lang.applications.zFile.fileSend.idBody)
                    local password = textDialog(lang.applications.zFile.fileSend.title, lang.applications.zFile.fileSend.passwordBody)
                    local modem = peripheral.find('modem')

                    local hData = fs.open(dir..filesFormatted[selected].name, 'r')
                    local data = hData.readAll()
                    hData.close()

                    modem.transmit(2322, 2323, {
                        id = id,
                        senderId = os.getComputerID(),
                        password = password,
                        fileName = filesFormatted[selected].name,
                        fileContents = data
                    })
                end
            end
        }
    }

    local rightClickMenu = {
        {
            text = lang.applications.zFile.nav.file.option.open,
            condition = function() return selected ~= nil end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        multishell.setFocus(multishell.launch({
                            ['shell'] = shell,
                            ['multishell'] = multishell,
                        }, dir..filesFormatted[selected].name))
                    elseif selectionType == "dir" then
                        dir = dir .. dirs[selected].name .. "/"
                    end
                end
                draw()
                selected = nil
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.edit,
            condition = function() return selected ~= nil and selectionType == "file" end,
            action = function()
                
                if selected then
                    if selectionType == "file" then
                        local ext = string.match(filesFormatted[selected].name, ".*(%..+)")
                        if ext == ".nfp" then
                            multishell.setFocus(multishell.launch({
                                ['shell'] = shell,
                                ['multishell'] = multishell,
                            }, "/rom/programs/fun/advanced/paint.lua", dir..filesFormatted[selected].name))
                        else
                            multishell.setFocus(multishell.launch({
                                ['shell'] = shell,
                                ['multishell'] = multishell,
                            }, "/rom/programs/edit.lua", dir..filesFormatted[selected].name))
                        end

                        
                    end
                end
                draw()
                selected = nil
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.new,
            condition = function() return true end,
            action = function()
                fs.open(dir..textDialog('New file', 'Enter a name for the new file')..".lua", "w").close()
                draw()
            end
        },
        {
            text = lang.applications.zFile.nav.file.option.newFolder,
            condition = function() return true end,
            action = function()
                fs.makeDir(dir..textDialog('New folder', 'Enter a name for the new folder'))
                draw()
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.copy,
            condition = function() 
                if selected then 
                    return true 
                else 
                    return false 
                end
            end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        copiedPath = dir..filesFormatted[selected].name
                    elseif selectionType == "dir" then
                        copiedPath = dir..dirs[selected].name
                    end
                    
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.paste,
            condition = function() return copiedPath ~= nil end,
            action = function()
                if copiedPath ~= nil then
                    fs.copy(copiedPath, dir..fs.getName(copiedPath))
                    if cutStatus == "cut" then
                        cutStatus = nil
                        fs.delete(copiedPath)
                        copiedPath = nil
                    end
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.cut,
            condition = function() 
                if selected then 
                    return true 
                else 
                    return false 
                end
            end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        copiedPath = dir..filesFormatted[selected].name
                    elseif selectionType == "dir" then
                        copiedPath = dir..dirs[selected].name
                    end
                    cutStatus = "cut"
                    draw()
                end
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.delete,
            condition = function() return selected ~= nil end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        fs.delete(dir..filesFormatted[selected].name)
                    elseif selectionType == "dir" then
                        fs.delete(dir..dirs[selected].name)
                    end
                end
                selected = nil
                draw()
               
            end
        },
        {
            text = lang.applications.zFile.nav.edit.option.rename,
            condition = function() return selected ~= nil end,
            action = function()
                if selected then
                    if selectionType == "file" then
                        fs.move(dir..filesFormatted[selected].name, dir..textDialog('Rename', 'Enter a new name for the new file'))
                    elseif selectionType == "dir" then
                        fs.move(dir..dirs[selected].name, dir..textDialog('Rename', 'Enter a new name for the new folder'))
                    end
                end
                draw()
                selected = nil
            end
        }
    }

    draw()
    menu = 1

    while true do
        local e = {os.pullEvent()}
        if e[1] == "mouse_click" then
            local m, x, y = e[2], e[3], e[4]
            term.setBackgroundColor(theme.background)
            term.setTextColor(theme.text)
            if m == 1 then
                if x >= 1 and x <= string.len(" "..lang.applications.zFile.nav.file.name.." ") and y == 1 and menu == 1 then
                    if dropdown == true then
                        draw()
                    end   
                    drawDropdown(1,2,fileDropdown, 1)
                elseif x >= string.len(" "..lang.applications.zFile.nav.file.name.." ")+1 and x <= string.len(" "..lang.applications.zFile.nav.file.name.." ")+string.len(" "..lang.applications.zFile.nav.edit.name.." ") and y == 1 and menu == 1  then
                    if dropdown == true then
                        draw()
                    end   
                    drawDropdown(string.len(" "..lang.applications.zFile.nav.file.name.." ")+1,2,editDropdown, 2)
                elseif x >= string.len(" "..lang.applications.zFile.nav.file.name.." ")+string.len(" "..lang.applications.zFile.nav.edit.name.." ")+1 and x <= string.len(" "..lang.applications.zFile.nav.file.name.." ")+string.len(" "..lang.applications.zFile.nav.edit.name.." ")+string.len(" "..lang.applications.zFile.nav.send.name.." ") and y == 1 and menu == 1  then
                    if dropdown == true then
                        draw()
                    end   
                    drawDropdown(string.len(" "..lang.applications.zFile.nav.file.name.." ")+string.len(" "..lang.applications.zFile.nav.edit.name.." ")+1,2,shareDropdown, 3)
                elseif x == 2 and y == 2 and menu == 1 then
                    if dir ~= "/" then
                        scrollPos = 0
                        dir = "/"..fs.getDir(dir).."/"
                        if dir == "//" then dir = "/" end 
                        draw()
                    end
                else
                    if dropdown == true and menu == 2 then
                        local found = false
                        for i, v in pairs(selectedList) do
                            if x >= listX and x <= listX+listMaxX and y == listY+i-1 then
                                v.action()
                                found = true
                                
                            end
                        end

                        if found == false then
                            dropdown = false
                            selectedList = nil
                            menu = 1
                            draw()
                        end
                    elseif menu == 1 then
                        local found = false
                        for i, v in pairs(dirs) do 
                            if y == 2+i+scrollPos and found == false then
                                if selected == i then
                                    dir = dir .. v.name .. "/"
                                    selected = nil
                                    selectionType = nil
                                    scrollPos = 0
                                    draw()
                                    found = true
                                else
                                    selected = i
                                    selectionType = "dir"
                                    draw()
                                    found = true
                                    
                                end
                                
                            end
                        end
                        for i, v in pairs(filesFormatted) do 
                            if y == 2+i+#dirs+scrollPos and found == false then
                                if selected == i then
                                    multishell.setFocus(multishell.launch({
                                        ['shell'] = shell,
                                        ['multishell'] = multishell,
                                    }, dir..v.name))
                                    selected = nil
                                    selectionType = nil
                                    scrollPos = 0
                                    draw()
                                    found = true
                                else
                                    selected = i
                                    selectionType = "file"
                                    draw()
                                    found = true
                                end
                            end
                        end

                        if found == false then
                            selected = nil
                            draw()
                        end
                    end
                end
                if menu == 3 then
                    if x >= w/2+12 and x <= w/2+16 and y == h/2-5 then
                        menu = 1
                        draw()
                        local modem = peripheral.find('modem')
                        modem.close(2322)
                    end
                elseif menu == 4 then
                    if x >= w/2-13 and x <= w/2-13+string.len(lang.applications.zFile.fileReceive.accept) and y == h/2+2 then
                        local hRecv = fs.open(dir..recvTable.fileName, "w")
                        hRecv.write(recvTable.fileContents)
                        hRecv.close()
                        recvTable = nil
                        menu = 1
                        draw()
                    elseif x >= w/2-12+string.len(lang.applications.zFile.fileReceive.accept) and x <= w/2-12+string.len(lang.applications.zFile.fileReceive.accept)+string.len(lang.applications.zFile.fileReceive.decline) and y == h/2+2 then
                        recvTable = nil
                        menu = 1
                        draw()
                    end
                end
            elseif m == 2 then
                if y > 2 then
                    for i, v in pairs(dirs) do 
                        if y == 2+i+scrollPos and found == false then
                            if selected == i then
                                dir = dir .. v.name .. "/"
                                selected = nil
                                selectionType = nil
                                scrollPos = 0
                                draw()
                                found = true
                            else
                                selected = i
                                selectionType = "dir"
                                draw()
                                found = true
                                
                            end
                            
                        end
                    end
                    for i, v in pairs(filesFormatted) do 
                        if y == 2+i+#dirs+scrollPos and found == false then
                            if selected == i then
                                multishell.setFocus(multishell.launch({
                                    ['shell'] = shell,
                                    ['multishell'] = multishell,
                                }, dir..v.name))
                                selected = nil
                                selectionType = nil
                                scrollPos = 0
                                draw()
                                found = true
                            else
                                selected = i
                                selectionType = "file"
                                draw()
                                found = true
                            end
                        end
                    end

                    if found == false then
                        selected = nil
                        draw()
                    end
                    
                    draw()
                    if y+#rightClickMenu > h then
                        drawDropdown(x,y-#rightClickMenu+1,rightClickMenu)
                    else
                        drawDropdown(x,y,rightClickMenu)
                    end
                    
                end
            end
        elseif e[1] == "key" then
            local k = e[2]
            if k == keys.leftCtrl then
                ctrlDown = true
            end
            if selected ~= nil then
                if k == keys.delete then
                    if selectionType == "file" then
                        fs.delete(dir..filesFormatted[selected].name)
                    elseif selectionType == "dir" then
                        fs.delete(dir..dirs[selected].name)
                    end
                    draw()
                elseif k == keys.c and ctrlDown then
                    if selectionType == "file" then
                        copiedPath = dir..filesFormatted[selected].name
                    elseif selectionType == "dir" then
                        copiedPath = dir..dirs[selected].name
                    end
                elseif k == keys.x and ctrlDown then
                    if selectionType == "file" then
                        copiedPath = dir..filesFormatted[selected].name
                    elseif selectionType == "dir" then
                        copiedPath = dir..dirs[selected].name
                    end
                    cutStatus = "cut"
                    draw()
                end
            end
            if k == keys.v and ctrlDown then
                if copiedPath ~= nil then
                    fs.copy(copiedPath, dir..fs.getName(copiedPath))
                    if cutStatus == "cut" then
                        cutStatus = nil
                        fs.delete(copiedPath)
                        copiedPath = nil
                    end
                    draw()
                end
            end
            
        elseif e[1] == "key_up" then
            local k = e[2]
            if k == keys.leftCtrl then
                ctrlDown = false
            end
        elseif e[1] == "mouse_scroll" then
            local d, x, y = e[2], e[3], e[4]
            if d == 1 then
                if math.abs(scrollPos) < #dirs+#filesFormatted-1 then
                    scrollPos = scrollPos - 1
                end
            elseif d == -1 then
                if scrollPos ~= 0 then
                    scrollPos = scrollPos + 1
                end
            end
            
            draw()

        elseif e[1] == "modem_message" then
            if menu == 3 then
                local s, sC, rC, m, sD = e[2], e[3], e[4], e[5], e[6]
                if tostring(m.password) == tostring(sessionSharingPassword) and tostring(m.id) == tostring(os.getComputerID()) then
                    recvTable = m
                    draw()
                    menu = 4
                    paintutils.drawFilledBox(w/2-15,h/2-5,w/2+16,h/2+4,colors.white)
                    paintutils.drawBox(w/2-15,h/2-5,w/2+16,h/2+4,colors.lightGray)
                    paintutils.drawLine(w/2-15,h/2-5,w/2+16,h/2-5,colors.gray)
                    term.setCursorPos(w/2-14,h/2-5)
                    term.setBackgroundColor(colors.gray)
                    term.setTextColor(colors.lightGray)
                    term.write(lang.applications.zFile.fileReceive.title)
                    local lineChar = 1
                    local str = string.format(lang.applications.zFile.fileReceive.body, tostring(m.id))
                    local line = ""
                    term.setTextColor(colors.gray)
                    term.setBackgroundColor(colors.white)
                    pos = h/2-4
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
                    term.setCursorPos(w/2-14,h/2-1)
                    term.write(string.format(lang.applications.zFile.fileReceive.fromId, tostring(m.id)))
                    term.setCursorPos(w/2-14,h/2)
                    term.write(string.format(lang.applications.zFile.fileReceive.fileName, m.fileName))
                    term.setCursorPos(w/2-13,h/2+2)
                    term.setBackgroundColor(colors.lime)
                    term.setTextColor(colors.gray)
                    term.write(lang.applications.zFile.fileReceive.accept)
                    term.setCursorPos(w/2-12+string.len(lang.applications.zFile.fileReceive.accept),h/2+2)
                    term.setBackgroundColor(colors.red)
                    term.setTextColor(colors.gray)
                    term.write(lang.applications.zFile.fileReceive.decline)
                end
            end
        end
    end
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