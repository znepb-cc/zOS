local biosrel = {
    ["Start CraftOS"] = { select = function() term.clear() term.setCursorPos(1,1) shell.run('shell') end },
    ["Open settings"] = { select = function() shell.run('zOS/System/Settings.lua') end },
    ["Exit"] = { select = function() os.reboot() end}
}


local data = http.get("https://cc.znepb.me/zOS/internet-test.txt")


local selected = 1

local function draw()
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.black)
    term.clear()
    print("zOS Boot Utility\n")
    if not data then
        term.setTextColor(colors.red)
        print("Warning: You are currently not connected to the internet. Please expect zOS to not run very well.\n")
    end
    term.setTextColor(colors.white)
    local count = 1
    for i, v in pairs(biosrel) do
        if count == selected then
            term.setBackgroundColor(colors.gray)
            print("> "..i)
        else
            term.setBackgroundColor(colors.black)
            print("  "..i)
        end
        count = count + 1
        
    end
end

draw()

while true do
    local e, k = os.pullEvent("key")
    if k == keys.down then
        if selected == #biosrel then
            selected = 1
        else
            selected = selected + 1
        end
        draw()
    elseif k == keys.up then
        if selected == 1 then
            selected = #biosrel
        else
            selected = selected - 1
        end
        draw()
    elseif k == keys.enter then
        local count = 1
        for i, v in pairs(biosrel) do
            if selected == count then
                v.select()
            end
            count = count + 1
        end
        
    end
end