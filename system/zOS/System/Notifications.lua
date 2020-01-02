local function main()
    local w, h = term.getSize()

    local lang = multishell.getLanguage()
    local theme = multishell.loadTheme()
    multishell.setTitle(multishell.getCurrent(), lang.notifications.name)

    local function draw()
        term.setBackgroundColor(theme.background)
        term.clear()
    end

    local closePositions = {}
    local scrollPos = 0
    local endingPosition = 0

    local function loadNotifications(scrollPos)
        local notificationList = multishell.getNotifications()
        closePositions = {}
        if not scrollPos then scrollPos = 0 end
        local fullPos = 4
        if #notificationList == 0 then
            term.setCursorPos(w/2-string.len(lang.notifications.noNotifications)/2, 4)
            term.setTextColor(theme.text)
            term.write(lang.notifications.noNotifications)
        else
            term.setCursorPos(w/2-string.len(string.format(lang.notifications.newNotifications, #notificationList))/2, 2+scrollPos)
            term.setTextColor(theme.text)
            term.write(string.format(lang.notifications.newNotifications, #notificationList))

            term.setCursorPos(w/2-string.len(lang.notifications.clear)/2, 3+scrollPos)
            term.setTextColor(colors.red)
            term.write(lang.notifications.clear)
            term.setTextColor(theme.text)
            local pos = 4+scrollPos
            
            local endi = 0
            for i, v in pairs(notificationList) do
                pos = pos + 1
                fullPos = fullPos + 1
                paintutils.drawFilledBox(w/2-16, pos, w/2+17, pos, theme.selectionBackground)
                pos = pos + 1
                fullPos = fullPos + 1
                paintutils.drawFilledBox(w/2-16, pos, w/2+17, pos, theme.selectionBackground)
                term.setCursorPos(w/2-15, pos)
                term.write(v.application)
                term.setCursorPos(w/2+16, pos)
                term.write('\215') -- ×

                term.setCursorPos(w/2+15-string.len(textutils.formatTime(v.time, getSetting('use24hrTime'))), pos)
                term.write(textutils.formatTime(v.time, getSetting('use24hrTime')))
                table.insert(closePositions, {x = w/2+16, y = pos, id = i})
                pos = pos + 1
                fullPos = fullPos + 1
                local lineChar = 1
                local str = v.message
                local line = ""
                paintutils.drawFilledBox(w/2-16, pos, w/2+17, pos, theme.selectionBackground)
                for i = 1, string.len(str) do
                    if lineChar == 33 then
                        lineChar = 1
                        fullPos = fullPos + 1
                        line = ""
                        pos = pos + 1
                        fullPos = fullPos + 1
                        paintutils.drawFilledBox(w/2-16, pos, w/2+17, pos, theme.selectionBackground)
                    end
                    line = line .. string.sub(str, i, i)
                    term.setCursorPos(w/2-15, pos)
                    term.write(line)
                    lineChar = lineChar + 1
                end
                
                pos = pos + 1
                fullPos = fullPos + 1
                paintutils.drawFilledBox(w/2-16, pos, w/2+17, pos, theme.selectionBackground)
                pos = pos + 1
                fullPos = fullPos + 1
                endi = i
                
            end
            endingPosition = fullPos-h-endi
            paintutils.drawLine(w,1,w,h, colors.lightGray)
            paintutils.drawPixel(w,(math.abs(scrollPos)/endingPosition)*h+1,colors.gray)
            if (math.abs(scrollPos)/endingPosition)*h+1 >= h then
                paintutils.drawPixel(w,h,colors.gray)
            end
        end
    end

    draw()
    loadNotifications()

    while true do
        local e = {os.pullEvent()}
        if e[1] == "mouse_click" then
            local clickedOnce = false
            local m, x, y = e[2], e[3], e[4]
            for i, v in pairs(closePositions) do
                if x == math.floor(v.x) and y == math.floor(v.y) then
                    multishell.dismissNotification(v.id)
                    draw()
                    loadNotifications(scrollPos)
                end
            end

            if x >= math.floor(w/2-string.len(lang.notifications.clear)/2) and x <= math.ceil(w/2+string.len(lang.notifications.clear)/2) and y == 3+scrollPos then
                repeat
                    for i, v in pairs(multishell.getNotifications()) do
                        multishell.dismissNotification(i)
                    end
                until #multishell.getNotifications() == 0
                draw()
                loadNotifications(scrollPos)
            end

            if x == w then
                scrollPos = 0-math.floor((math.abs(y)/h)*endingPosition-1)
                if y == 1 then
                    scrollPos = 0
                elseif y == h then
                    scrollPos = 0-endingPosition
                end
                draw()
                loadNotifications(scrollPos)
                
            end
        elseif e[1] == "mouse_drag" then
            local m, x, y = e[2], e[3], e[4]
            if x == w then
                scrollPos = 0-math.floor((math.abs(y)/h)*endingPosition-1)
                if y == 1 then
                    scrollPos = 0
                elseif y == h then
                    scrollPos = 0-endingPosition
                end
                draw()
                loadNotifications(scrollPos)
                
            end
        elseif e[1] == "mouse_scroll" then
            local d, x, y = e[2], e[3], e[4]
            if d == 1 then
                if math.abs(scrollPos) < endingPosition then
                    scrollPos = scrollPos - 1
                
                end
            elseif d == -1 then
                if scrollPos ~= 0 then
                    scrollPos = scrollPos + 1
                end
            end
            draw()
            loadNotifications(scrollPos)
        elseif e[1] == "zOS_notification" then
            draw()
            loadNotifications(scrollPos)
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