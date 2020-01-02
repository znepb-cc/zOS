function main()
	local tFiles = {}
	local tFilePositions = {}
	local w, h = term.getSize()
	local currentPage = 1
	local selectedId = 0
	local dropdown = {}
	local dropdownSetting = ''
	local dropdownX, dropdownY, dropdownEndX = 0, 0, 0
	local languages = {"en-us","test-us"}
	local timeZoneOffsets = {["auto"] = "Auto", [0] = "UTC", [-4] = "EDT", [-5] = "EST", [-7] = "MST", [-6] = "MDT"}
	local timeZoneOffsetsOtherWay = {["Auto"] = "auto", ["UTC"] = 0, ["EDT"] = -4, ['EST'] = -5, ["MST"] = -7, ["MDT"] = -6 }
	local monitors
	local getSetting = multishell.getSetting

	local theme = multishell.loadTheme()
	local lang = multishell.getLanguage()
	multishell.setTitle(multishell.getCurrent(), lang.applications.settings.name)

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

	local function drawTop(selected)
		local tabs = {lang.applications.settings.tab.general.name, lang.applications.settings.tab.customization.name, lang.applications.settings.tab.security.name, lang.applications.settings.tab.info.name}
		term.setBackgroundColor(colors.gray)
		term.setCursorPos(1,1)
		term.clearLine()
		for i, v in pairs(tabs) do
			if selected == i then
				term.setBackgroundColor(colors.lightGray)
				term.setTextColor(colors.white)
			else
				term.setBackgroundColor(colors.gray)
				term.setTextColor(colors.lightGray)
			end
			term.write(" "..v.." ")
		end
		if multishell.zOSenabled == nil then
			term.setCursorPos(w-1,1)
			term.setBackgroundColor(colors.red)
			term.setTextColor(colors.white)
			term.write('\215')
		end
	end

	local function toggle(var)
		if var == true then
			return false
		else
			return true
		end
	end

	local function drawTileApplication(tData, nX, nY, nID)
		term.setBackgroundColor(theme.background)
		
		paintutils.drawFilledBox(nX,nY,nX+8,nY+3,tData.background)
		term.setCursorPos(nX+1,nY+1)
		term.setTextColor(tData.text)
		term.write("Text")

		term.setCursorPos(nX+1,nY+2)
		term.setBackgroundColor(tData.selectionBackground)
		term.write("Text")

		term.setBackgroundColor(theme.background)
		if nID == selectedId then
			term.setBackgroundColor(theme.selectionBackground)
		end
		term.setTextColor(theme.text)
		term.setCursorPos(nX, nY+4)
		
		term.write(tData.name)
	end

	local function loadThemes()
		local hApplicationsFile = fs.open("/zOS/Configuration/themes.txt", "r")
		tFiles = textutils.unserialize(hApplicationsFile.readAll())
		local x = 2
		local y = 5
		tFilePositions = {}
		
		for i, v in pairs(tFiles) do
			drawTileApplication(v, x, y, i)
			table.insert(tFilePositions, {x = x, y = y, path = v.filePath})
			if x >= w-11 then
				y = y + 6
				x = 2
			else
				x = x + 10
			end
			
		end
		
		hApplicationsFile.close()
	end

	local function drawDialog(text)
		local dialogWidth = string.len(text)+4
		local dialogPositionX = w/2-dialogWidth/2
		term.setBackgroundColor(colors.black)
		term.clear()
		paintutils.drawFilledBox(dialogPositionX, h/2-2, dialogPositionX+dialogWidth, h/2+3, theme.background)
		paintutils.drawLine(dialogPositionX, h/2-3, dialogPositionX+dialogWidth, h/2-3, colors.gray)
		term.setBackgroundColor(theme.background)
		term.setTextColor(theme.text)
		term.setCursorPos(dialogPositionX,h/2)
		term.write("  "..text.."  ")

		term.setCursorPos(w/2-string.len(" Okay ")/2,h/2+2)
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lightGray)
		term.write(" "..lang.applications.settings.dialogOk.." ")
	end

	local function drawToggle(x,y,selected)
		local slider, bg
		if selected then
			slider = colors.lime
			bg = colors.green
		else
			slider = colors.gray
			bg = colors.lightGray
		end

		if selected then
			paintutils.drawPixel(x,y,bg)
			paintutils.drawPixel(x+1,y,bg)
			paintutils.drawPixel(x+2,y,slider)
		else
			paintutils.drawPixel(x,y,slider)
			paintutils.drawPixel(x+1,y,bg)
			paintutils.drawPixel(x+2,y,bg)
		end
	end

	local function drawDropdown(x,y,values,selected)
		term.setCursorPos(x,y)
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lightGray)
		term.write(string.format(" %s \31 ", values[selected]))
	end

	local function drawDropdownSelection(x,y,values,selected,changeSetting)
		dropdownX = x
		dropdownY = y+1
		dropdown = values
		dropdownSetting = changeSetting
		term.setCursorPos(x,y)
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.gray)
		term.write(string.format(" %s \31 ", values[selected]))
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lightGray)
		local charLength = 0
		for i, v in pairs(values) do
			if string.len(v) > charLength then
				charLength = string.len(v)
			end
		end
		dropdownEndX = x+charLength+1
		local count = 1
		for i, v in pairs(values) do
			term.setCursorPos(x,y+count)
			term.write(" "..v.." "..string.rep(" ", charLength+1-string.len(v)))
			count = count + 1
		end

	end

	local function drawPage(page)
		currentPage = page
		term.setBackgroundColor(theme.background)
		term.clear()
		
		term.setBackgroundColor(theme.background)
		term.setTextColor(theme.text)
		local peripherals = peripheral.getNames()
		monitors = {}
		for i, v in pairs(peripherals) do
			if peripheral.getType(v) == 'monitor' then
				table.insert(monitors, v)
			end
		end
		drawTop(page)
		if page == 1 then
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.setCursorPos(2,3)
			term.write(lang.applications.settings.tab.general.title)
			term.setCursorPos(2,5)
			term.write(lang.applications.settings.tab.general.label1)
			term.setCursorPos(2,6)
			term.setTextColor(colors.lightGray)
			term.write(lang.applications.settings.tab.general.label2)
			term.setBackgroundColor(colors.gray)
			term.setCursorPos(w-string.len(" "..lang.applications.settings.tab.general.button1.." "), 5)
			term.write(" "..lang.applications.settings.tab.general.button1.." ")

			term.setCursorPos(2,8)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.general.label3)
			local selectedLanguage
			for i, v in pairs(languages) do
				if v == getSetting('language') then
					selectedLanguage = i
				end
			end
			drawDropdown(w-string.len(string.format(" %s \31 ", getSetting('language'))),8,languages,selectedLanguage)

			term.setCursorPos(2,10)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.general.label4)
			drawDropdown(w-string.len(string.format(" %s \31 ", timeZoneOffsets[getSetting('timeZone')])),10,timeZoneOffsets,getSetting('timeZone'))

			term.setCursorPos(2,12)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.general.label5)
			drawToggle(w-3,12,getSetting('use24hrTime'))

			term.setCursorPos(2,14)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.general.label6)
			drawToggle(w-3,14,getSetting('useAtOnLauncher'))

			term.setCursorPos(2,16)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.general.label7)
			drawToggle(w-3,16,getSetting('autoUpdate'))
		elseif page == 2 then
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.setCursorPos(2,3)
			term.write(lang.applications.settings.tab.customization.title)
			loadThemes()
		elseif page == 3 then
			term.setCursorPos(2,3)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.security.title)
			term.setCursorPos(2,5)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write(lang.applications.settings.tab.security.label1)
			local passwordEnabled = false
			if getSetting("password") ~= "" then
				passwordEnabled = true
			end
			drawToggle(w-3,5,passwordEnabled)
		elseif page == 4 then
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.setCursorPos(2,3)
			term.write(lang.applications.settings.tab.info.title)
			term.setCursorPos(2,5)
			local versionFile = fs.open('zOS/System/sysinfo.txt', "r")
			local version = textutils.unserialize(versionFile.readAll()).displayVersion
			versionFile.close()
			term.write(lang.applications.settings.tab.info.version:format(version))
			term.setCursorPos(2,6)
			term.write(lang.applications.settings.tab.info.branch:format(getSetting('branch')))

		elseif page == "dev" then
			term.setCursorPos(2,3)
			term.setBackgroundColor(theme.background)
			term.setTextColor(theme.text)
			term.write("Super secret deveolper settings")
			term.setCursorPos(2,4)
			print("Changing these settings could make your computer more vulurnable to hacks, and could even corrupt your files.")

			term.setCursorPos(2,8)
			term.write("Start logger in background on startup")
			drawToggle(w-3,8,false)
		end
	end
	drawPage(1)

	while true do
		local e = {os.pullEvent()}
		if e[1] == "mouse_click" then
			local m, x, y = e[2], e[3], e[4]
			if x >= 1 and x <= 9 and y == 1 then
				drawPage(1)
			elseif x >= 10 and x <= 16 and y == 1 then
				drawPage(2)
			elseif x >= 17 and x <= 23 and y == 1 then
				drawPage(3)
			elseif x >= 24 and x <= 29 and y == 1 then
				drawPage(4)
			elseif x == w-1 and y == 1 and multishell.zOSenabled == nil then
				os.reboot()
			elseif currentPage == 1 then
				if m == 1 and x >= w-8 and x <= w-1 and y == 5 then
					term.setBackgroundColor(theme.background)
					term.setCursorPos(2,5)
					term.write(string.rep(" ", 50))
					term.setCursorPos(2,6)
					term.write(string.rep(" ", 50))
					term.setCursorPos(2,5)
					term.setTextColor(theme.text)
					term.setBackgroundColor(theme.background)
					term.write(lang.applications.settings.tab.general.selectUsername.text)
					
					term.setCursorPos(2,7)
					term.setBackgroundColor(colors.gray)
					term.setTextColor(colors.lightGray)
					term.write(string.rep(" ", 26))
					term.setCursorPos(3,7)
					local input = read()
					drawPage(currentPage)
					term.setCursorPos(2,7)
					term.write(lang.applications.settings.loading)
					setSetting("username", input)
					drawPage(currentPage)
				elseif m == 1 and x >= w-3 and x <= w-1 and y == 12 then
					local value = toggle(getSetting("use24hrTime"))
					setSetting("use24hrTime", value)
					drawToggle(w-3,12,value)
					term.setCursorPos(2,h-1)
					term.setTextColor(theme.text)
					term.setBackgroundColor(theme.background)
				elseif m == 1 and x >= w-3 and x <= w-1 and y == 14 then
					local value = toggle(getSetting("useAtOnLauncher"))
					setSetting("useAtOnLauncher", value)
					drawToggle(w-3,14,value)
					term.setCursorPos(2,h-1)
					term.setTextColor(theme.text)
					term.setBackgroundColor(theme.background)
					term.write(lang.applications.settings.appliedOnReboot)
				elseif m == 1 and x >= w-string.len(string.format(" %s \31 ", getSetting('language'))) and x <= w-1 and y == 8 and dropdownSetting == '' then
					local selectedLanguage = 0
					for i, v in pairs(languages) do
						if v == getSetting('language') then
							selectedLanguage = i
						end
					end
					drawDropdownSelection(w-string.len(string.format(" %s \31 ", getSetting('language'))),8,languages,selectedLanguage,'language')
				elseif m == 1 and x >= w-string.len(string.format(" %s \31 ", timeZoneOffsets[getSetting('timeZone')])) and x <= w-1 and y == 10 and dropdownSetting == '' then
					drawDropdownSelection(w-string.len(string.format(" %s \31 ", timeZoneOffsets[getSetting('timeZone')])),10,timeZoneOffsets,getSetting('timeZone'),'timeZone')
				elseif m == 1 and x >= w-3 and x <= w-1 and y == 16 then
					local value = toggle(getSetting("autoupdate"))
					setSetting("autoupdate", value)
					drawToggle(w-3,16,value)
				else
					if dropdown ~= {} then
						local count = 1
						for i, v in pairs(dropdown) do
							if x >= dropdownX and x <= dropdownEndX and y == dropdownY+count-1 then
								if dropdownSetting == 'timeZone' then
									setSetting(dropdownSetting, timeZoneOffsetsOtherWay[v])
								else
									setSetting(dropdownSetting, dropdown[i])
								end 
								
							end
							count = count + 1
						end
						drawPage(1)
						dropdown = {}
						dropdownSetting = ''
					end
				end
			elseif currentPage == 2 then
				for i, v in pairs(tFilePositions) do
					if m == 1 and x >= v.x and x <= v.x+9 and y >= v.y and y <= v.y+5 then
						if selectedId == i then
							local filer = fs.open("/zOS/Configuration/configuration.txt", "r")
							local fData = filer.readAll()
							local data = textutils.unserialize(fData)
							filer.close()

							local file = fs.open("/zOS/Configuration/configuration.txt", "w")
							data.selectedTheme = selectedId
							file.write(textutils.serialize(data))
							file.close()

							selectedId = 0
							drawPage(currentPage)
							term.setCursorPos(2,h-1)
							term.setTextColor(theme.text)
							term.write(lang.applications.settings.appliedOnReboot)
						else
							selectedId = i
							drawPage(currentPage)
						end
					end
				end
			elseif currentPage == 3 then
				if m == 1 and x >= w-3 and x <= w-1 and y == 5 then
					local passwordEnabled = false
					if getSetting("password") ~= "" then
						passwordEnabled = true
					end
					
					if passwordEnabled == false then
						term.setCursorPos(2,7)
						term.setTextColor(theme.text)
						term.setBackgroundColor(theme.background)
						term.write(lang.applications.settings.tab.security.newPassword.text)
						term.setCursorPos(2,9)
						term.setBackgroundColor(colors.gray)
						term.setTextColor(colors.lightGray)
						term.write(string.rep(" ", 26))
						term.setCursorPos(3,9)
						local input = read("\7")
						drawPage(currentPage)
						term.setCursorPos(2,7)
						term.write("lang.applications.settings.loading")
						os.loadAPI("/zOS/System/API/aeslua")
						local out = aeslua.encrypt("zOS-super-secret-password-lol", input)
						setSetting("password", out)
						drawPage(currentPage)
						passwordEnabled = true
					else
						passwordEnabled = false
						setSetting("password", "")
						
					end

					drawToggle(w-3,5,passwordEnabled)
					term.setCursorPos(2,h-1)
					term.setTextColor(theme.text)
					term.setBackgroundColor(theme.background)
					term.write("This setting will be applied on reboot.")
					
				end
			elseif currentPage == 4 then
				if m == 1 and x >= w-string.len(string.format(" %s \31 ",  monitors[getSetting('monitor')])) and x <= w-1 and y == 5 and dropdownSetting == '' then
					drawDropdownSelection(w-string.len(string.format(" %s \31 ", monitors[getSetting('monitor')])),5,monitors,getSetting('monitor'), 'monitor')
				elseif m == 1 and x >= w-3 and x <= w-1 and y == 7 then
					local value = toggle(getSetting("alwaysBootToMonitor"))
					setSetting("alwaysBootToMonitor", value)
					drawToggle(w-3,7,value)
				elseif m == 1 and x >= w-3 and x <= w-1 and y == 9 then
					if getSetting("monitorScale") ~= 5 then
						setSetting("monitorScale", getSetting("monitorScale")+0.5)
						term.setCursorPos(w-9, 9)
						term.setBackgroundColor(colors.gray)
						term.setTextColor(colors.lightGray)
						term.write(" -     + ")
						if string.len(tostring(getSetting('monitorScale'))) == 1 then
							term.setCursorPos(w-5,9)
						elseif string.len(tostring(getSetting('monitorScale'))) == 3 then
							term.setCursorPos(w-6,9)
						end
						term.write(getSetting('monitorScale'))

						term.setCursorPos(w-3, 9)
						term.setBackgroundColor(colors.lightGray)
						term.setTextColor(colors.gray)
						term.write(" + ")
						
						sleep(0.1)

						term.setCursorPos(w-3, 9)
						term.setBackgroundColor(colors.gray)
						term.setTextColor(colors.lightGray)
						term.write(" + ")
					end
				elseif m == 1 and x >= w-9 and x <= w-7 and y == 9 then
					if getSetting("monitorScale") ~= 0.5 then
						setSetting("monitorScale", getSetting("monitorScale")-0.5)
						term.setCursorPos(w-9, 9)
						term.setBackgroundColor(colors.gray)
						term.setTextColor(colors.lightGray)
						term.write(" -     + ")
						if string.len(tostring(getSetting('monitorScale'))) == 1 then
							term.setCursorPos(w-5,9)
						elseif string.len(tostring(getSetting('monitorScale'))) == 3 then
							term.setCursorPos(w-6,9)
						end
						term.write(getSetting('monitorScale'))

						term.setCursorPos(w-9, 9)
						term.setBackgroundColor(colors.lightGray)
						term.setTextColor(colors.gray)
						term.write(" - ")
						
						sleep(0.1)

						term.setCursorPos(w-9, 9)
						term.setBackgroundColor(colors.gray)
						term.setTextColor(colors.lightGray)
						term.write(" - ")
					end
					
				else
					if dropdown ~= {} then
						local count = 1
						for i, v in pairs(dropdown) do
							if x >= dropdownX and x <= dropdownEndX and y == dropdownY+count-1 then
								setSetting(dropdownSetting, i)
								
							end
							count = count + 1
						end
						drawPage(4)
						dropdown = {}
						dropdownSetting = ''
					end
				end
			end
		elseif e[1] == "key" then
			if e[2] == keys.f1 then
				drawPage("dev")
				
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