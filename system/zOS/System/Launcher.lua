local w, h = term.getSize()
os.loadAPI("/zOS/System/API/zif.lua")

local tFiles = {}
local tFilePositions = {}
local selectedId = 0
local theme = {}
local internetOkay = false

local function getSetting(name)
	local f = fs.open("/zOS/Configuration/configuration.txt", "r")
	local configData = textutils.unserialize(f.readAll())
	local data = configData[name]
	f.close()
	return data
end

local function getLanguageData(language)
	local f = fs.open("/zOS/Language/"..language..".txt", "r")
	local data = textutils.unserialize(f.readAll())
	print(language)
	f.close()
	return data
end

local lang = getLanguageData(getSetting('language'))
multishell.setTitle(1, lang.launcher.name)
local username = getSetting("username")

local function loadTheme()
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

theme = loadTheme()

local menu = 1

local function printCenter(sText, nYpos)
	term.setCursorPos(w/2-string.len(sText)/2, nYpos)
	term.write(sText)
end

local function drawContentMenuStructure(xPos, yPos, width, height)
	term.setCursorPos(xPos,yPos)
	term.setTextColor(theme.dropdownOutline)
	term.setBackgroundColor(theme.dropdownBackground)
	term.write("\151"..string.rep("\131", width))
	term.setTextColor(theme.dropdownBackground)
	term.setBackgroundColor(theme.dropdownOutline)
	term.write("\148")
	for i = yPos+1, yPos+height do
		term.setTextColor(theme.dropdownOutline)
		term.setBackgroundColor(theme.dropdownBackground)
		term.setCursorPos(xPos,i)
		term.write("\149"..string.rep(" ", width))
		term.setTextColor(theme.dropdownBackground)
		term.setBackgroundColor(theme.dropdownOutline)
		term.write("\149")
	end
	term.setCursorPos(xPos,yPos+height)
	term.setTextColor(theme.dropdownOutline)
	term.setBackgroundColor(theme.dropdownBackground)
	term.write("\141"..string.rep("\140", width))
				
	term.write("\142")
end

local function drawTileApplication(tData, nX, nY, nID)
	if fs.exists("/zOS/Applications/Icons/"..tData.fileIconName) then
		
		zif.drawImage(nX,nY,"/zOS/Applications/Icons/"..tData.fileIconName)
		term.setBackgroundColor(theme.background)
		term.setCursorPos(nX, nY+4)
	else
		zif.drawImage(nX,nY,"/zOS/Applications/Icons/default.zif")
		term.setBackgroundColor(theme.background)
		term.setCursorPos(nX, nY+4)
	end
	if nID == selectedId then
		term.setBackgroundColor(theme.selectionBackground)
	end
	if tData.nameType == 'default' or tData.nameType == nil then
		term.write(tData.fileName)
	elseif tData.nameType == 'lang' then
		term.write(lang.applications[tData.fileName].name)
	end
end

local function loadApplications()
	local hApplicationsFile = fs.open("/zOS/Applications/applications.txt", "r")
	tFiles = textutils.unserialize(hApplicationsFile.readAll())
	local x = 2
	local y = 4
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

local function drawMenu()
	term.setBackgroundColor(theme.background)
	term.clear()
	term.setCursorPos(2,2)
	term.setTextColor(theme.text)
	term.write(username.." \31")

	term.setBackgroundColor(theme.background)
	term.setTextColor(theme.text)
	printCenter(lang.launcher.welcome, 2)

	term.setCursorPos(w-1,2)
	term.write("%")
	
	term.setCursorPos(w-3,2)
	if internetOkay == false then
		term.setTextColor(colors.red)
		term.write("\7")
	else
		term.setTextColor(colors.lime)
		term.write("\7")
	end
	term.setTextColor(theme.text)
	
	loadApplications()
end


drawMenu()

-- Main application event loop
local function events()
	while true do
		local e = {os.pullEventRaw()}
		if e[1] == "mouse_click" then
			local clickedOnce = false
			local m, x, y = e[2], e[3], e[4]
			if x >= 2 and x <= string.len(username)+3 and y == 2 and menu == 1 then
				drawContentMenuStructure(2,3,10,4)
				term.setTextColor(theme.dropdownText)
				term.setCursorPos(3,4)
				term.write(lang.launcher.shutdown)
				term.setCursorPos(3,5)
				term.write(lang.launcher.reboot)
				term.setCursorPos(3,6)
				term.write(lang.launcher.logout)
				term.setCursorPos(2,2)
				term.setTextColor(theme.text)
				term.setBackgroundColor(theme.selectionBackground)
				term.write(username.." \31")
				menu = 2
			elseif x == w-1 and y == 2 and menu == 1 then
				drawMenu()
				term.setCursorPos(w-1, 2)
				term.setBackgroundColor(theme.selectionBackground)
				term.setTextColor(theme.text)
				term.write('%')
				sleep(0.15)
				term.setBackgroundColor(theme.background)
				term.setTextColor(theme.text)
				term.setCursorPos(w-1, 2)
				term.write('%')
			elseif menu == 2 then
				

				if x >= 2 and x <= 12 and y == 4 then
					term.setBackgroundColor(colors.black)
					term.clear()
					sleep(0.5)
					os.shutdown()
				elseif x == w-2 and y == 2 then
					drawMenu()
				elseif x >= 2 and x <= 12 and y == 5 then
					term.setBackgroundColor(colors.black)
					term.clear()
					sleep(0.5)
					os.reboot()
				elseif x >= 2 and x <= 12 and y == 6 then
					
				else
					menu = 1
					drawMenu()
				end
			else
				for i, v in pairs(tFilePositions) do
					if m == 1 and x >= v.x and x <= v.x+9 and y >= v.y and y <= v.y+5 then
						if selectedId == i then
							selectedId = 0
							multishell.setFocus(multishell.launch({
								['shell'] = shell,
								['multishell'] = multishell,
							}, v.path))
							
						else
							selectedId = i
							drawMenu()
							clickedOnce = true
						end
						
					end
				end
			end

			if selectedId ~= 0 and clickedOnce == false then
				selectedId = 0
				drawMenu()
				menu = 1
			end
		end
	end
end

-- Internet testing function

local function internetTest()
	sleep(1)
	-- Checking internet: #
	-- Disconnected: !
	-- Online: •
	while true do
		term.setCursorPos(w-3,2)
		term.setTextColor(colors.yellow)
		term.write("\7")
		term.setTextColor(theme.text)
		local data = http.get("https://cc.znepb.me/zOS/internet-test.txt")
		if not data then
			internetOkay = false
			term.setTextColor(colors.red)
			term.setCursorPos(w-3,2)
			term.write("\7")
		else
			internetOkay = true
			term.setTextColor(colors.lime)
			term.setCursorPos(w-3,2)
			term.write("\7")
		end
		term.setTextColor(theme.text)
		if not data then sleep(5) else sleep(30) end
	end
end

parallel.waitForAll(internetTest, events)