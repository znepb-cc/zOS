local args = {...}
local function systemWorker()
    -- Setup process switching
    local parentTerm = term.current()
    local w,h = parentTerm.getSize()

    local function getSetting(name)
        local f = fs.open("/zOS/Configuration/configuration.txt", "r")
        local configData = textutils.unserialize(f.readAll())
        local data = configData[name]
        f.close()
        return data
    end

    local tProcesses = {}
    local nCurrentProcess = nil
    local nRunningProcess = nil
    local bShowMenu = false
    local bWindowsResized = false
    local nScrollPos = 1
    local bScrollRight = false
    local notifications = {}
    local bAltHeld = false

    local menuMainTextColor, menuMainBgColor, menuOtherTextColor, menuOtherBgColor
    if parentTerm.isColor() then
        menuMainTextColor, menuMainBgColor = colors.white, colors.lightGray
        menuOtherTextColor, menuOtherBgColor = colors.lightGray, colors.gray
    else
        menuMainTextColor, menuMainBgColor = colors.white, colors.black
        menuOtherTextColor, menuOtherBgColor = colors.black, colors.gray
    end

    local function redrawMenu()
        if bShowMenu then
            -- Draw menu
            parentTerm.setCursorPos( 1, 1 )
            parentTerm.setBackgroundColor( menuOtherBgColor )
            parentTerm.clearLine()
            local nCharCount = 0
            local nSize = parentTerm.getSize()-6
            local nSizeFull = parentTerm.getSize()
            if nScrollPos ~= 1 then
                parentTerm.setTextColor( menuOtherTextColor )
                parentTerm.setBackgroundColor( menuOtherBgColor )
                parentTerm.write( "<" )
                nCharCount = 1
            end
            for n=nScrollPos,#tProcesses do
                if n == nCurrentProcess then
                    parentTerm.setTextColor( menuMainTextColor )
                    parentTerm.setBackgroundColor( menuMainBgColor )
                else
                    parentTerm.setTextColor( menuOtherTextColor )
                    parentTerm.setBackgroundColor( menuOtherBgColor )
                end
                parentTerm.write( " " .. tProcesses[n].sTitle .. " " )
                nCharCount = nCharCount + #tProcesses[n].sTitle + 2
                if nCharCount > nSize then
                   
                    parentTerm.setBackgroundColor( menuOtherBgColor )
                    local text = '   '
                    if tProcesses[nCurrentProcess].sTitle ~= "@" then
                        if tProcesses[nCurrentProcess].sTitle ~= "Launcher.lua" then
                            if tProcesses[nCurrentProcess].sTitle ~= "Launcher" then
                                text = '     '
                            end
                        end
                    end
                    parentTerm.setCursorPos(nSizeFull-string.len(text), 1)
                    parentTerm.write(text)
                end
                
            end
            if nCharCount > nSize then
                parentTerm.setTextColor( menuOtherTextColor )
                parentTerm.setBackgroundColor( menuOtherBgColor )
                parentTerm.setCursorPos( nSizeFull, 1 )
                parentTerm.write( ">" )
                bScrollRight = true
            else
                bScrollRight = false
            end

            if nCurrentProcess ~= nil then
                parentTerm.setBackgroundColor(menuOtherBgColor)
                parentTerm.setTextColor(menuMainTextColor)
                if nCharCount > nSize then
                    local pos = w-2
                    if tProcesses[nCurrentProcess].sTitle ~= "@" then
                        if tProcesses[nCurrentProcess].sTitle ~= "Launcher.lua" then
                            if tProcesses[nCurrentProcess].sTitle ~= "Launcher" then
                                pos = w-4
                            end
                        end
                    end
                    parentTerm.setCursorPos(pos,1)
                    if #notifications >= 10 then 
                        parentTerm.setTextColor(colors.blue)
                    elseif #notifications < 10 and #notifications > 0 then
                        parentTerm.setTextColor(colors.lightBlue)
                    else
                        parentTerm.setTextColor(colors.lightGray)
                    end
                    parentTerm.write('\7')
                else
                    if #notifications >= 10 then
                        parentTerm.setCursorPos(w-2,1)
                        parentTerm.setTextColor(colors.blue)
                        parentTerm.write('\7')
                    
                        parentTerm.setCursorPos(w-1,1)
                        parentTerm.setTextColor(colors.white)
                        parentTerm.write('9+')
                    else
                        parentTerm.setCursorPos(w-1,1)
                        if #notifications >= 1 then 
                            parentTerm.setTextColor(colors.lightBlue)
                        else
                            parentTerm.setTextColor(colors.lightGray)
                        end
                        parentTerm.write('\7')
                    
                        parentTerm.setCursorPos(w,1)
                        parentTerm.setTextColor(colors.white)
                        parentTerm.write(#notifications)
                    end
                end
                if tProcesses[nCurrentProcess].sTitle then
                    if tProcesses[nCurrentProcess].sTitle ~= "@" then
                        if tProcesses[nCurrentProcess].sTitle ~= "Launcher.lua" then
                            if tProcesses[nCurrentProcess].sTitle ~= "Launcher" then
                                if bAltHeld then
                                    parentTerm.setTextColor(colors.red)
                                else
                                    parentTerm.setTextColor(menuMainTextColor)
                                end
                                parentTerm.setBackgroundColor(menuOtherBgColor)
                                
                                if nCharCount > nSize then
                                    parentTerm.setCursorPos(w-3,1)
                                    parentTerm.write(" \215 ")
                                else
                                    if #notifications >= 10 then
                                        parentTerm.setCursorPos(w-5,1)
                                        parentTerm.write(" \215 ")
                                    else
                                        parentTerm.setCursorPos(w-4,1)
                                        parentTerm.write(" \215 ")
                                    end
                                end
                            end
                        end
                    end
                    
                end
            end

            -- Put the cursor back where it should be
            local tProcess = tProcesses[ nCurrentProcess ]
            if tProcess then
                tProcess.window.restoreCursor()
            end
            
            
        end
    end

    local function selectProcess( n )
        if nCurrentProcess ~= n then
            if nCurrentProcess then
                local tOldProcess = tProcesses[ nCurrentProcess ]
                tOldProcess.window.setVisible( false )
            end
            nCurrentProcess = n
            if nCurrentProcess then
                local tNewProcess = tProcesses[ nCurrentProcess ]
                tNewProcess.window.setVisible( true )
                tNewProcess.bInteracted = true
            end
        end
    end

    local function setProcessTitle( n, sTitle )
        tProcesses[ n ].sTitle = sTitle
    end

    local function resumeProcess( nProcess, sEvent, ... )
        local tProcess = tProcesses[ nProcess ]
        local sFilter = tProcess.sFilter
        if sFilter == nil or sFilter == sEvent or sEvent == "terminate" then
            local nPreviousProcess = nRunningProcess
            nRunningProcess = nProcess
            term.redirect( tProcess.terminal )
            local ok, result = coroutine.resume( tProcess.co, sEvent, ... )
            tProcess.terminal = term.current()
            if ok then
                tProcess.sFilter = result
            else
                printError( result )
            end
            nRunningProcess = nPreviousProcess
        end
    end

    local function launchProcess( tProgramEnv, sProgramPath, ... )
        local tProgramArgs = table.pack( ... )
        local nProcess = #tProcesses + 1
        local tProcess = {}
        tProcess.sTitle = fs.getName( sProgramPath )
        if bShowMenu then
            tProcess.window = window.create( parentTerm, 1, 2, w, h-1, false )
        else
            tProcess.window = window.create( parentTerm, 1, 1, w, h, false )
        end
        tProcess.co = coroutine.create( function()
            os.run( tProgramEnv, sProgramPath, table.unpack( tProgramArgs, 1, tProgramArgs.n ) )
            term.setCursorBlink( false )
        end )
        tProcess.sFilter = nil
        tProcess.terminal = tProcess.window
        tProcess.bInteracted = false
        tProcesses[ nProcess ] = tProcess
        redrawMenu()
        return nProcess
    end

    local function cullProcess( nProcess )
        local tProcess = tProcesses[ nProcess ]
        if coroutine.status( tProcess.co ) == "dead" then
            if nCurrentProcess == nProcess then
                selectProcess( nil )
            end
            table.remove( tProcesses, nProcess )
            if nCurrentProcess == nil then
                if nProcess > 1 then
                    selectProcess( nProcess - 1 )
                elseif #tProcesses > 0 then
                    selectProcess( 1 )
                end
            end
            if nScrollPos ~= 1 then
                nScrollPos = nScrollPos - 1
            end
            return true
        end
        return false
    end

    local function cullProcesses()
        local culled = false
        for n=#tProcesses,1,-1 do
            culled = culled or cullProcess( n )
        end
        return culled
    end

    -- Setup the main menu


    local function resizeWindows()
        local windowY, windowHeight
        if bShowMenu then
            windowY = 2
            windowHeight = h-1
        else
            windowY = 1
            windowHeight = h
        end
        for n=1,#tProcesses do
            local tProcess = tProcesses[n]
            local window = tProcess.window
            local x,y = tProcess.window.getCursorPos()
            if y > windowHeight then
                tProcess.window.scroll( y - windowHeight )
                tProcess.window.setCursorPos( x, windowHeight )
            end
            tProcess.window.reposition( 1, windowY, w, windowHeight )
        end
        bWindowsResized = true
    end

    local function setMenuVisible( bVis )
        if bShowMenu ~= bVis then
            bShowMenu = bVis
            resizeWindows()
            redrawMenu()
        end
    end

    local multishell = {}

    multishell.zOSenabled = true

    function multishell.getFocus()
        return nCurrentProcess
    end

    function multishell.setFocus( n )
        if type( n ) ~= "number" then
            error( "bad argument #1 (expected number, got " .. type( n ) .. ")", 2 )
        end
        if n >= 1 and n <= #tProcesses then
            selectProcess( n )
            redrawMenu()
            return true
        end
        return false
    end

    function multishell.getTitle( n )
        if type( n ) ~= "number" then
            error( "bad argument #1 (expected number, got " .. type( n ) .. ")", 2 )
        end
        if n >= 1 and n <= #tProcesses then
            return tProcesses[n].sTitle
        end
        return nil
    end

    function multishell.setTitle( n, sTitle )
        if type( n ) ~= "number" then
            error( "bad argument #1 (expected number, got " .. type( n ) .. ")", 2 )
        end
        if type( sTitle ) ~= "string" then
            error( "bad argument #2 (expected string, got " .. type( sTitle ) .. ")", 2 )
        end
        if n >= 1 and n <= #tProcesses then
            setProcessTitle( n, sTitle )
            redrawMenu()
        end
    end

    function multishell.getCurrent()
        return nRunningProcess
    end

    function multishell.launch( tProgramEnv, sProgramPath, ... )
        if type( tProgramEnv ) ~= "table" then
            error( "bad argument #1 (expected table, got " .. type( tProgramEnv ) .. ")", 2 )
        end
        if type( sProgramPath ) ~= "string" then
            error( "bad argument #2 (expected string, got " .. type( sProgramPath ) .. ")", 2 )
        end
        local previousTerm = term.current()
        setMenuVisible( true )
        local nResult = launchProcess( tProgramEnv, sProgramPath, ... )
        redrawMenu()
        term.redirect( previousTerm )
        return nResult
    end

    function multishell.getCount()
        return #tProcesses
    end

    function multishell.removeProcess(n)
        local nLastProcess = n
        selectProcess(1)
        if bAltHeld == false then
            local tProcess = tProcesses[ nLastProcess ]
            local sFilter = tProcess.sFilter
            if sFilter == nil or sFilter == sEvent or sEvent == "terminate" then
                tProcess.terminal = nil
                tProcess.window = nil
                tProcess = nil
                tProcesses[nLastProcess] = nil
                os.queueEvent('multishell_redraw')
            end
        else
            local tProcess = tProcesses[ nLastProcess ]
            local sFilter = tProcess.sFilter
            if sFilter == nil or sFilter == sEvent or sEvent == "terminate" then
                local nPreviousProcess = nRunningProcess
                nRunningProcess = 1
                term.redirect( tProcess.terminal )
                local ok, result = coroutine.resume( tProcess.co, 'terminate' )
                tProcess = nil
                nRunningProcess = nPreviousProcess
                os.queueEvent('multishell_redraw')
            end
        end
    end

    function multishell.sendNotification(application, message)
        if peripheral.find('speaker') then
            local spk = peripheral.find('speaker')
            spk.playNote('bell',1,12)
        end
        local time 
        if getSetting('timeZone') == "auto" then
            time = os.time('local')
        elseif tonumber(getSetting('timeZone')) ~= nil then
            time = os.time('utc')+tonumber(getSetting('timeZone'))
        end
        table.insert(notifications, {
            application = application,
            time = time,
            message = message,
        })
        os.queueEvent('zOS_notification')
        redrawMenu()
        return #notifications
    end

    function multishell.dismissNotification(notiId)
        table.remove(notifications, notiId)
        redrawMenu()
        return true
    end

    function multishell.getNotifications()
        return notifications
    end

    function multishell.getSetting(name)
        local f = fs.open("/zOS/Configuration/configuration.txt", "r")
        local configData = textutils.unserialize(f.readAll())
        local data = configData[name]
        f.close()
        return data
    end

    function multishell.getLanguage()
        local f = fs.open("/zOS/Language/"..multishell.getSetting('language')..".txt", "r")
        local data = textutils.unserialize(f.readAll())
        print(language)
        f.close()
        return data
    end

    function multishell.loadTheme()
        local f = fs.open("/zOS/Configuration/configuration.txt", "r")
        local configData = textutils.unserialize(f.readAll())
        local sTheme = configData.selectedTheme
        if configData.useAtOnLauncher == false then
            local w, h = term.getSize()
            multishell.setTitle(1, lang.launcher.alternateName)
        end
        f.close()

        local f = fs.open("/zOS/Configuration/themes.txt", "r")
        local data = textutils.unserialize(f.readAll())[sTheme]
        f.close()
        
        return data
    end


    -- Begin
    parentTerm.clear()
    setMenuVisible( true )
    selectProcess( launchProcess( {
        ["shell"] = shell,
        ["multishell"] = multishell,
    }, args[1] ) )
    
    redrawMenu()
    os.queueEvent('multishell_redraw')

    -- Run processes
    while #tProcesses > 0 do
        -- Get the event
        local tEventData = table.pack( os.pullEventRaw() )
        local sEvent = tEventData[1]
        
        if sEvent == "term_resize" then
            -- Resize event
            w,h = parentTerm.getSize()
            resizeWindows()
            redrawMenu()

        elseif sEvent == "char" or sEvent == "key" or sEvent == "key_up" or sEvent == "paste" or sEvent == "terminate" then
            -- Keyboard event
            -- Passthrough to current process
            if sEvent == "key" then
                local k = tEventData[2]
                if k == keys.leftAlt then
                    bAltHeld = true
                    redrawMenu()
                end
            elseif sEvent == "key_up" then
                local k = tEventData[2]
                if k == keys.leftAlt then
                    bAltHeld = false
                    redrawMenu()
                end
            end
            resumeProcess( nCurrentProcess, table.unpack( tEventData, 1, tEventData.n ) )
            if cullProcess( nCurrentProcess ) then
                setMenuVisible( true )
                redrawMenu()
            end
        elseif sEvent == "mouse_click" then
            -- Click event
            local button, x, y = tEventData[2], tEventData[3], tEventData[4]
            if bShowMenu and y == 1 then
                -- Switch process
                if x == 1 and nScrollPos ~= 1 then
                    nScrollPos = nScrollPos - 1
                    redrawMenu()
                elseif x >= w-1 and x <= w and y == 1 and #notifications < 10 and not bScrollRight then
                    multishell.setFocus(multishell.launch({
                        ['shell'] = shell,
                        ['multishell'] = multishell,
                    }, "/zOS/System/Notifications.lua"))
                    os.queueEvent('multishell_redraw')
                elseif x >= w-2 and x <= w and y == 1 and #notifications >= 10 and not bScrollRight then
                    multishell.setFocus(multishell.launch({
                        ['shell'] = shell,
                        ['multishell'] = multishell,
                    }, "/zOS/System/Notifications.lua"))
                    os.queueEvent('multishell_redraw')
                elseif x == w-3 and y == 1 and bScrollRight then
                    multishell.setFocus(multishell.launch({
                        ['shell'] = shell,
                        ['multishell'] = multishell,
                    }, "/zOS/System/Notifications.lua"))
                    os.queueEvent('multishell_redraw')
                elseif x == w-3 and y == 1 and #notifications < 10 and not bScrollRight and nCurrentProcess ~= 1 then
                    multishell.removeProcess(nCurrentProcess)
                    
                    redrawMenu()
                elseif x == w-2 and y == 1 and bScrollRight and nCurrentProcess ~= 1 then
                    multishell.removeProcess(nCurrentProcess)
                    
                    redrawMenu()
                elseif x == w-4 and y == 1 and #notifications >= 10 and not bScrollRight and nCurrentProcess ~= 1 then
                    multishell.removeProcess(nCurrentProcess)
                    
                    redrawMenu()
                elseif bScrollRight and x == term.getSize() then
                    nScrollPos = nScrollPos + 1
                    redrawMenu()
                else
                    local tabStart = 1
                    if nScrollPos ~= 1 then
                        tabStart = 2
                    end
                    for n=nScrollPos,#tProcesses do
                        local tabEnd = tabStart + string.len( tProcesses[n].sTitle ) + 1
                        term.setBackgroundColor(colors.black)
                        term.setTextColor(colors.white)
                        if x >= tabStart and x <= tabEnd then
                            selectProcess( n )
                            redrawMenu()
                            break
                        end
                        tabStart = tabEnd + 1
                    end
                end
            else
                -- Passthrough to current process
                resumeProcess( nCurrentProcess, sEvent, button, x, (bShowMenu and y-1) or y )
                if cullProcess( nCurrentProcess ) then
                    setMenuVisible( true )
                    redrawMenu()
                end
            end

        elseif sEvent == "mouse_drag" or sEvent == "mouse_up" or sEvent == "mouse_scroll" then
            -- Other mouse event
            local p1, x, y = tEventData[2], tEventData[3], tEventData[4]
            if bShowMenu and sEvent == "mouse_scroll" and y == 1 then
                if p1 == -1 and nScrollPos ~= 1 then
                    nScrollPos = nScrollPos - 1
                    redrawMenu()
                elseif bScrollRight and p1 == 1 then
                    nScrollPos = nScrollPos + 1
                    redrawMenu()
                end
            elseif not (bShowMenu and y == 1) then
                -- Passthrough to current process
                resumeProcess( nCurrentProcess, sEvent, p1, x, (bShowMenu and y-1) or y )
                if cullProcess( nCurrentProcess ) then
                    setMenuVisible( true )
                    redrawMenu()
                end
            end

        else
            -- Other event
            -- Passthrough to all processes
            local nLimit = #tProcesses -- Storing this ensures any new things spawned don't get the event
            for n=1,nLimit do
                resumeProcess( n, table.unpack( tEventData, 1, tEventData.n ) )
            end
            if cullProcesses() then
                setMenuVisible( true )
                redrawMenu()
            end
        end

        if bWindowsResized then
            -- Pass term_resize to all processes
            local nLimit = #tProcesses -- Storing this ensures any new things spawned don't get the event
            for n=1,nLimit do
                resumeProcess( n, "term_resize" )
            end
            bWindowsResized = false
            if cullProcesses() then
                setMenuVisible( #tProcesses >= 2 )
                redrawMenu()
            end
        end
    end

    -- Shutdown
    term.redirect( parentTerm )
end

local ok, err = pcall(systemWorker)

if not ok then
    term.setBackgroundColor(colors.red)
    term.clear()
    local w, h = term.getSize()
    paintutils.drawFilledBox(1,3,w,5, colors.white)
    term.setCursorPos(w/2-string.len("SYSTEM CRASH")/2, 4)
    term.setTextColor(colors.red)
    term.write("SYSTEM CRASH")

    term.setCursorPos(w/2-string.len(err)/2, h/2)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.write(err)

    paintutils.drawFilledBox(1,h-4,w,h-2, colors.white)
    term.setCursorPos(w/2-string.len("Press any key to restart.")/2, h-3)
    term.setTextColor(colors.red)
    term.write("Press any key to restart.")

    os.pullEventRaw("key")
    os.reboot()
end
