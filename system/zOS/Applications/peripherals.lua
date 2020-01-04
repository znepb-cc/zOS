local function main()

    -- Varitables

    local w, h = term.getSize()
    local lang = multishell.getLanguage()
    local theme = multishell.loadTheme()
    local peripheralList = peripheral.getNames()
    local formattedPeripheralList = {}
    local menu = 0
    local selectedId = 0
    local selected = 0
    local selectedPeripheral = 0
    local listX
    local listY
    local selectedList
    local listMaxX
    local dropdown = false

    multishell.setTitle(multishell.getFocus(), lang.applications.peripherals.title)

    local function searchPeripheralsForName(name)
        for i, v in pairs(formattedPeripheralList) do
            if v.name == name then
                return i
            end
        end
        return nil
    end

    local function findInTable(tbl, name)
        for i, v in pairs(tbl) do
            if v == name then
                return i
            end
        end
        return nil
    end

    local function setSetting(name, value)
		local f = fs.open("/zOS/Configuration/configuration.txt", "r")
		local configData = textutils.unserialize(f.readAll())
		f.close()

		local f = fs.open("/zOS/Configuration/configuration.txt", "w")
		configData[name] = value
		f.write(textutils.serialize(configData))
		f.close()

		return true
	end

    local function updateFormattedPeripheralList()
        -- Load peripherals file
        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
        formattedPeripheralList = textutils.unserialize(peripheralsFile.readAll())
        peripheralsFile.close()
        local updateRequest = {}
        local newTable = {}
        peripheralList = peripheral.getNames()
        for i, v in pairs(peripheralList) do 
            table.insert(updateRequest, v)
        end
        for i, v in pairs(formattedPeripheralList) do
            if not findInTable(peripheralList, v.name) then 
                table.insert(updateRequest, v.name)
            end
        end


        for i, v in pairs(updateRequest) do
            local tbl = {}
            local item = searchPeripheralsForName(v)
            if formattedPeripheralList[item] == nil then
                tbl = {
                    name = v,
                    customName = v,
                    type = peripheral.getType(v),
                    connected = true,
                }
            else
                tbl = {
                    name = v,
                    customName = formattedPeripheralList[item].customName,
                    type = peripheral.getType(v) or formattedPeripheralList[item].type,
                    connected = true,
                }

                if peripheral.getType(v) == nil or peripheral.getType(v) == "nil" or peripheral.getType(v) == "" then
                    tbl = {
                        name = v,
                        customName = formattedPeripheralList[item].customName,
                        type = formattedPeripheralList[item].type,
                        connected = false,
                    }

                    if tbl.type == "computer" or tbl.type == "turtle" and tbl.connected == false then
                        tbl.id = formattedPeripheralList[item].id
                        tbl.label = formattedPeripheralList[item].label
                        tbl.isOn = formattedPeripheralList[item].isOn
                    elseif tbl.type == "drive" and tbl.connected == true then
                        if formattedPeripheralList[item].diskType == "Audio" then
                            tbl.diskType = "Audio"
                            tbl.label = formattedPeripheralList[item].label
                        elseif formattedPeripheralList[item].diskType == "Data" then
                            tbl.diskType = "Data"
                            tbl.id = formattedPeripheralList[item].id
                            tbl.label = formattedPeripheralList[item].label
                            tbl.mountPath = formattedPeripheralList[item].mountPath
                        elseif formattedPeripheralList[item].diskType == "No disk" then
                            tbl.diskType = "No disk"
                        end
                    end
                else
                    tbl = formattedPeripheralList[item]
                end
            end

            -- comupters

            if tbl.type == "computer" and tbl.connected == true or tbl.type == "turtle" and tbl.connected == true then
                local computer = peripheral.wrap(tbl.name)
                tbl.id = computer.getID()
                tbl.label = computer.getLabel() or "None"
                tbl.isOn = computer.isOn()
            elseif tbl.type == "drive" and tbl.connected == true then
                local drive = peripheral.wrap(tbl.name)
                if drive.hasAudio() then
                    tbl.diskType = "Audio"
                    tbl.label = drive.getAudioTitle()
                elseif drive.hasData() then
                    tbl.diskType = "Data"
                    tbl.id = drive.getDiskID()
                    tbl.label = drive.getDiskLabel() or "None"
                    tbl.mountPath = drive.getMountPath()
                elseif drive.isDiskPresent() == false then
                    tbl.diskType = "No disk"
                end
            elseif tbl.type == "monitor" and tbl.connected == true then
                if tbl.primary == nil then
                    tbl.primary = false
                end
                if tbl.textScale == nil then
                    tbl.textScale = 1
                end
            end

            newTable[i] = tbl
        end

        -- Save peripherals file
        local formattedPeripheralsString = textutils.serialize(newTable)
        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "w")
        peripheralsFile.write(formattedPeripheralsString)
        peripheralsFile.close()
        formattedPeripheralList = newTable
    end

    local function removeDisconnectedPeripheral(id)
        -- Load peripherals file
        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
        formattedPeripheralList = textutils.unserialize(peripheralsFile.readAll())
        peripheralsFile.close()

        local newTable = formattedPeripheralList
        newTable[id] = nil

        -- Save peripherals file
        local formattedPeripheralsString = textutils.serialize(newTable)
        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "w")
        peripheralsFile.write(formattedPeripheralsString)
        peripheralsFile.close()
        formattedPeripheralList = newTable

        updateFormattedPeripheralList()
    end

    local function renamePeripheral(id, name)
        -- Load peripherals file
        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
        newFPL = textutils.unserialize(peripheralsFile.readAll())
        peripheralsFile.close()

        local newTable = newFPL
        newTable[id].customName = name

        -- Save peripherals file
        local formattedPeripheralsString = textutils.serialize(newTable)
        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "w")
        peripheralsFile.write(formattedPeripheralsString)
        peripheralsFile.close()
        formattedPeripheralList = newTable
    end

    local function draw(selected)
        menu = 1

        term.setBackgroundColor(theme.background)
        term.clear()

        peripheralList = peripheral.getNames() -- Update in case any new peripherals were added since last draw
        updateFormattedPeripheralList()

        -- Draw top

        term.setCursorPos(1,1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.clearLine()
        if selected == 1 then 
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.gray)
        end
        write(lang.applications.peripherals.peripheralDD.name)
        term.setCursorPos(1+string.len(lang.applications.peripherals.peripheralDD.name),1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        if selected == 2 then
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.gray)
        end
        write(lang.applications.peripherals.monitorDD.name)

        -- Draw key

        term.setCursorPos(2,2)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.clearLine()
        term.write(lang.applications.peripherals.key.name)
        term.setCursorPos(w/2,2)
        term.write(lang.applications.peripherals.key.type)
        term.setTextColor(theme.text)

        -- Draw peripheral list

        for i, v in pairs(formattedPeripheralList) do
            term.setCursorPos(2,i+2)
            term.setBackgroundColor(theme.background)
            if selectedPeripheral == i then
                term.setBackgroundColor(colors.lightGray)
            end
            term.setTextColor(theme.text)
            if v.primary == true then
                term.setTextColor(colors.green)
            end
            term.clearLine()
            if v.connected == false then
                term.setTextColor(colors.red)
            end
            term.write(v.customName)
            term.setCursorPos(w/2,i+2)
            term.write(v.type)
        end
    end

    local function drawDropdown(x,y,list,selected)
        menu = 1
        listX = x
        listY = y
        selectedList = list
        dropdown = true
        draw(selected)
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

    local function loadPeripheral(id)
        term.setBackgroundColor(theme.background)
        term.clear()
        menu = 2
        selectedId = id
        local data = formattedPeripheralList[id]

        -- Draw topbar

        term.setCursorPos(2,1)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.lightGray)
        term.clearLine()
        term.write(data.type.." "..data.name)
        term.setCursorPos(w-1, 1)
        term.setTextColor(colors.white)
        term.write("\215")

        local posAdd = 0

        -- Check if peripheral is not currently connected

        term.setBackgroundColor(theme.background)

        if data.connected == false then
            posAdd = 3
            term.setCursorPos(2,3)
            term.setTextColor(colors.red)
            term.write(lang.applications.peripherals.itemMenu.peripheralNotConnected)
            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)
            term.setCursorPos(2,4)
            term.write(lang.applications.peripherals.itemMenu.removeButton)
        end

        -- Draw application information

        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
        term.setCursorPos(2,3+posAdd)
        term.write(lang.applications.peripherals.itemMenu.name:format(data.name))
        term.setCursorPos(2,4+posAdd)
        term.write(lang.applications.peripherals.itemMenu.type:format(data.type))

        -- Stuff for computers

        if data.type == "computer" or data.type == "turtle" then

            -- Draw computer information

            term.setCursorPos(2,5+posAdd)
            term.write(lang.applications.peripherals.itemMenu.computer.id:format(data.id))
            term.setCursorPos(2,6+posAdd)
            term.write(lang.applications.peripherals.itemMenu.computer.label:format(data.label))
            term.setCursorPos(2,7+posAdd)
            term.write(lang.applications.peripherals.itemMenu.computer.isOn:format(tostring(data.isOn)))

            -- Draw buttons
            if data.connected == true then
                if data.isOn == true then
                    -- Code for computers that are on

                    -- Reboot
                    term.setCursorPos(2,9+posAdd)
                    term.setTextColor(colors.black)
                    term.setBackgroundColor(colors.orange)
                    term.write(lang.applications.peripherals.itemMenu.computer.reboot)

                    -- Shutdown
                    term.setCursorPos(3+string.len(lang.applications.peripherals.itemMenu.computer.reboot), 9+posAdd)
                    term.setBackgroundColor(colors.red)
                    term.setTextColor(colors.white)
                    term.write(lang.applications.peripherals.itemMenu.computer.shutdown)
                elseif data.isOn == false then
                    -- Code for computers that are off

                    -- Turn on
                    term.setCursorPos(2,9+posAdd)
                    term.setTextColor(colors.black)
                    term.setBackgroundColor(colors.lime)
                    term.write(lang.applications.peripherals.itemMenu.computer.turnOn)
                end
            end
        elseif data.type == "drive" then
            if data.diskType == "No disk" then
                term.setCursorPos(2,5+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.noDisk)
            elseif data.diskType == "Data" then
                term.setCursorPos(2,5+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.diskType:format(data.diskType))
                term.setCursorPos(2,6+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.id:format(data.id))
                term.setCursorPos(2,7+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.label:format(data.label))
                term.setCursorPos(2,8+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.mountPath:format(data.mountPath))

                -- Eject
                term.setCursorPos(2,10+posAdd)
                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.red)
                term.write(lang.applications.peripherals.itemMenu.drive.eject)

                -- Open in files
                term.setCursorPos(3+string.len(lang.applications.peripherals.itemMenu.drive.eject), 10+posAdd)
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.lightGray)
                term.write(lang.applications.peripherals.itemMenu.drive.openInFiles)
            elseif data.diskType == "Audio" then
                term.setCursorPos(2,5+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.diskType:format(data.diskType))
                term.setCursorPos(2,6+posAdd)
                term.write(lang.applications.peripherals.itemMenu.drive.songName:format(data.label))

                -- Eject
                term.setCursorPos(2,8+posAdd)
                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.red)
                term.write(lang.applications.peripherals.itemMenu.drive.eject)

                -- Play
                term.setCursorPos(3+string.len(lang.applications.peripherals.itemMenu.drive.eject), 8+posAdd)
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.lightGray)
                term.write(lang.applications.peripherals.itemMenu.drive.play)

                -- Stop
                term.setCursorPos(4+string.len(lang.applications.peripherals.itemMenu.drive.eject)+string.len(lang.applications.peripherals.itemMenu.drive.play), 8+posAdd)
                term.setBackgroundColor(colors.gray)
                term.setTextColor(colors.lightGray)
                term.write(lang.applications.peripherals.itemMenu.drive.stop)
            end
        elseif data.type == "monitor" then
            term.setCursorPos(2,6)
            term.write("Text Scale")
            term.setCursorPos(2,7)
            term.setBackgroundColor(colors.lightGray)
            term.setTextColor(colors.gray)
            term.write(" - ")
            term.setCursorPos(8,7)
            term.write(" + ")
            if string.len(tostring(data.textScale)) == 3 then
                term.setCursorPos(5,7)
                term.write(data.textScale)
            elseif string.len(tostring(data.textScale)) == 1 then
                term.setCursorPos(5,7)
                term.write(" "..data.textScale.." ")
            end
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
        return text
    end

    local peripheralDropdown = {
        {
            text = lang.applications.peripherals.peripheralDD.rename,
            condition = function() return selectedPeripheral ~= 0 end,
            action = function()
                if selectedPeripheral ~= 0 then
                    local name = textDialog("Rename", "Enter a new name for the peripheral")
                    renamePeripheral(selectedPeripheral, name)
                    updateFormattedPeripheralList()
                    draw()
                end
            end
        },
        {
            text = lang.applications.peripherals.peripheralDD.remove,
            condition = function() return selectedPeripheral ~= 0 and formattedPeripheralList[selectedPeripheral].connected == false end,
            action = function()
                if selectedPeripheral ~= 0 then
                    if formattedPeripheralList[selectedPeripheral].connected == false then
                        removeDisconnectedPeripheral(selectedPeripheral)
                        selectedPeripheral = 0
                        draw()
                    end
                end
            end
        },
        {
            text = lang.applications.peripherals.peripheralDD.resetName,
            condition = function() return selectedPeripheral ~= 0 and formattedPeripheralList[selectedPeripheral].name ~= formattedPeripheralList[selectedPeripheral].customName end,
            action = function()
                if selectedPeripheral ~= 0 then
                    if formattedPeripheralList[selectedPeripheral].name ~= formattedPeripheralList[selectedPeripheral].customName then
                        renamePeripheral(selectedPeripheral, formattedPeripheralList[selectedPeripheral].name)
                        updateFormattedPeripheralList()
                        draw()
                    end
                end
            end
        },
    }

    local monitorDropdown = {
        {
            text = lang.applications.peripherals.monitorDD.setPrimary,
            condition = function() if selectedPeripheral ~= 0 then return formattedPeripheralList[selectedPeripheral].type == "monitor" and formattedPeripheralList[selectedPeripheral].connected == true and formattedPeripheralList[selectedPeripheral].primary == false else return false end end,
            action = function()
                if selectedPeripheral ~= 0 then
                    if formattedPeripheralList[selectedPeripheral].type == "monitor" and formattedPeripheralList[selectedPeripheral].connected == true and formattedPeripheralList[selectedPeripheral].primary == false then
                        -- Load peripherals file
                        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
                        newFPL = textutils.unserialize(peripheralsFile.readAll())
                        peripheralsFile.close()

                        for i, v in pairs(newFPL) do
                            if v.type == "monitor" then
                                if v.primary == true then
                                    v.primary = false
                                end
                            end
                        end

                        newFPL[selectedPeripheral].primary = true

                        -- Save peripherals file
                        local formattedPeripheralsString = textutils.serialize(newFPL)
                        local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "w")
                        peripheralsFile.write(formattedPeripheralsString)
                        peripheralsFile.close()
                        formattedPeripheralList = newFPL

                        draw()
                    end
                end
            end
        },
        {
            text = ddText,
            condition = function() return true end,
            action = function()
                if multishell.getSetting('bootToMonitor') == true then
                    setSetting('bootToMonitor', false)
                elseif multishell.getSetting('bootToMonitor') == false then
                    setSetting('bootToMonitor', true)
                end
                draw()
            end
        }
    }

    draw()
    

    -- Application loop

    while true do 
        local e = {os.pullEvent()}

        if e[1] == 'mouse_click' then
            local m, x, y = e[2], e[3], e[4]


            if menu == 1 then
                if dropdown == true then
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
                        --draw()
                    end
                end

                for i, v in pairs(formattedPeripheralList) do
                    if y == i+2 and dropdown == false then
                        if selectedPeripheral == i then
                            loadPeripheral(i)
                            selectedPeripheral = 0
                        else 
                            selectedPeripheral = i
                            draw()
                        end
                    end
                end
                
                if y == 1 and x >= 1 and x <= string.len(lang.applications.peripherals.peripheralDD.name) then
                    drawDropdown(1,2,peripheralDropdown, 1)
                elseif y == 1 and x >= string.len(lang.applications.peripherals.peripheralDD.name) and x <= string.len(lang.applications.peripherals.peripheralDD.name)+string.len(lang.applications.peripherals.monitorDD.name) then
                    if multishell.getSetting('bootToMonitor') == true then
                        monitorDropdown[2].text = lang.applications.peripherals.monitorDD.bootToMonitorEnabled
                    else
                        monitorDropdown[2].text = lang.applications.peripherals.monitorDD.bootToMonitorDisabled
                    end
                    drawDropdown(string.len(lang.applications.peripherals.peripheralDD.name),2,monitorDropdown, 2)
                end
            elseif menu == 2 then
                local data = formattedPeripheralList[selectedId]
                if x == w-1 and y == 1 then
                    draw()
                elseif data.connected == true then
                    if data.type == "computer" or data.type == "turtle" then
                        if data.isOn == true then
                            if x >= 2 and x <= 2+string.len(lang.applications.peripherals.itemMenu.computer.reboot) and y == 9 then
                                local computer = peripheral.wrap(data.name)
                                computer.reboot()
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            elseif x >= 3+string.len(lang.applications.peripherals.itemMenu.computer.reboot) and x <= 3+string.len(lang.applications.peripherals.itemMenu.computer.reboot)+string.len(lang.applications.peripherals.itemMenu.computer.shutdown) and y == 9 then
                                local computer = peripheral.wrap(data.name)
                                computer.shutdown()
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            end
                        elseif data.isOn == false then
                            if x >= 2 and x <= 2+string.len(lang.applications.peripherals.itemMenu.computer.turnOn) and y == 9 then
                                local computer = peripheral.wrap(data.name)
                                computer.turnOn()
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            end
                        end
                    elseif data.type == "drive" then
                        if data.diskType == "Audio" then
                            if x >= 2 and x <= string.len(lang.applications.peripherals.itemMenu.drive.eject) and y == 8 then
                                peripheral.call(data.name, "ejectDisk")
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            elseif x >= 3+string.len(lang.applications.peripherals.itemMenu.drive.eject) and x <= 3+string.len(lang.applications.peripherals.itemMenu.drive.eject)+string.len(lang.applications.peripherals.itemMenu.drive.play) and y == 8 then
                                peripheral.call(data.name, "playAudio")
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            elseif x >= 4+string.len(lang.applications.peripherals.itemMenu.drive.eject)+string.len(lang.applications.peripherals.itemMenu.drive.openInFiles) and x <= 4+string.len(lang.applications.peripherals.itemMenu.drive.eject)+string.len(lang.applications.peripherals.itemMenu.drive.play)+string.len(lang.applications.peripherals.itemMenu.drive.stop) and y == 8 then
                                peripheral.call(data.name, "stopAudio")
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            end
                        elseif data.diskType == "Data" then
                            if x >= 2 and x <= string.len(lang.applications.peripherals.itemMenu.drive.eject) and y == 10 then
                                peripheral.call(data.name, "ejectDisk")
                                sleep(0.1)
                                peripheralList = peripheral.getNames()
                                updateFormattedPeripheralList()
                                loadPeripheral(selectedId)
                            elseif x >= 3+string.len(lang.applications.peripherals.itemMenu.drive.eject) and x <= 3+string.len(lang.applications.peripherals.itemMenu.drive.eject)+string.len(lang.applications.peripherals.itemMenu.drive.openInFiles) and y == 10 then
                                multishell.setFocus(multishell.launch({
                                    ['shell'] = shell,
                                    ['multishell'] = multishell,
                                }, "/zOS/Applications/zFile.lua", "/"..data.mountPath.."/"))
                                os.queueEvent('multishell_redraw')
                            end
                        end
                    elseif data.type == "monitor" then
                        if x >= 2 and x <= 4 and y == 7 then
                            if data.textScale ~= 0.5 then
                                term.setBackgroundColor(colors.gray)
                                term.setTextColor(colors.lightGray)
                                term.setCursorPos(2,7)
                                term.write(" - ")
                                -- Load peripherals file
                                local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
                                newFPL = textutils.unserialize(peripheralsFile.readAll())
                                peripheralsFile.close()

                                for i, v in pairs(newFPL) do
                                    if i == selectedId then
                                        v.textScale = v.textScale - 0.5
                                    end
                                end

                                -- Save peripherals file
                                local formattedPeripheralsString = textutils.serialize(newFPL)
                                local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "w")
                                peripheralsFile.write(formattedPeripheralsString)
                                peripheralsFile.close()
                                formattedPeripheralList = newFPL
                                sleep(0.1)
                                loadPeripheral(selectedId)
                            end
                        elseif x >= 8 and x <= 10 and y == 7 then
                            if data.textScale ~= 5 then
                                term.setBackgroundColor(colors.gray)
                                term.setTextColor(colors.lightGray)
                                term.setCursorPos(8,7)
                                term.write(" + ")
                                -- Load peripherals file
                                local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "r")
                                newFPL = textutils.unserialize(peripheralsFile.readAll())
                                peripheralsFile.close()

                                for i, v in pairs(newFPL) do
                                    if i == selectedId then
                                        v.textScale = v.textScale + 0.5
                                    end
                                end

                                -- Save peripherals file
                                local formattedPeripheralsString = textutils.serialize(newFPL)
                                local peripheralsFile = fs.open('zOS/Configuration/peripherals.txt', "w")
                                peripheralsFile.write(formattedPeripheralsString)
                                peripheralsFile.close()
                                formattedPeripheralList = newFPL
                                sleep(0.1)
                                loadPeripheral(selectedId)
                            end
                        end
                    end
                elseif data.connected == false then
                    if x >= 2 and x <= 2+string.len(lang.applications.peripherals.itemMenu.removeButton) and y == 4 then
                        draw()
                        removeDisconnectedPeripheral(selectedId)
                        draw()
                    end
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