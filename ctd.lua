local Folder = "WDMacro"

local HTTPS = game:GetService('HttpService')

local WindUI = loadstring(game:HttpGet(
                              "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "MACRO",
    Icon = "pencil",
    Author = "FACKHUB",
    Folder = "FH",
    Size = UDim2.fromOffset(200, 200)
})

Window:Tag({
    Title = "BETA",
    Icon = "lucide:triangle-alert",
    Color = Color3.fromHex("#e6ef38"),
    Radius = 10
})

Window:EditOpenButton({
    Title = "Macro",
    Icon = "",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    OnlyMobile = false,
    Enabled = true,
    Draggable = true
})

WindUI:AddTheme({
    Name = "Void",
    Accent = Color3.fromHex("#8b5cf6"),
    Background = Color3.fromHex("#07060d"),
    Outline = Color3.fromHex("#2a2140"),
    Text = Color3.fromHex("#ede9fe"),
    Placeholder = Color3.fromHex("#6b6486"),
    Button = Color3.fromHex("#1a1428"),
    Icon = Color3.fromHex("#a78bfa")
})
WindUI:SetTheme("Void")
Window:IsResizable(false)
Window:DisableTopbarButtons({"Fullscreen"})

local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("FConfig")

local Tab1 = Window:Tab({Title = "Record", Icon = "video", Locked = false})
local Tab2 = Window:Tab({Title = "Replay", Icon = "sparkles", Locked = false})
local Tab3 = Window:Tab({Title = "Wenhook", Icon = "sparkles", Locked = false})
Tab1:Select() -- Select Tab
local function checkjson(file)
    if file:lower():match("%.json$") then return true end
    return false
end

local function sendWin(Token,discordUserId, wol , color , Value)
	
	local id = tostring(discordUserId or ""):gsub("%s+", "")

	local content = ""
	if id:match("^%d+$") then
		content = "<@" .. id .. ">"
	end

	local payload = {
		content = content,
         
		embeds = {
			{
                title  = "FACK HUB",
				description = "\n\nGain : " .. tostring(Value)..'Coins',
				color = color,
			},
		},
		attachments = {},
	}

	local ok, result = pcall(function()
		return HTTPS:RequestAsync({
			Url = Token:gsub("%s+", ""),
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HTTPS:JSONEncode(payload),
		})
	end)

	if not ok then
		warn("Webhook request failed:", result)
	elseif not result.Success then
		warn("Webhook error:", result.StatusCode, result.Body)
	end
end


local function noti(t, c)
    WindUI:Popup({
        Title = t,
        Icon = "info",
        Content = c,
        Buttons = {
            {Title = "Okay", Callback = function() end, Variant = "Primary"}

        }
    })
end

local function fetchloadout(file)
    local ok, contents = pcall(readfile, file)
    if not ok or type(contents) ~= "string" then return nil end

    local result = {}

    local function collect(data)
        if type(data) ~= "table" or data.Loadout == nil then return false end
        local lo = data.Loadout
        if type(lo) == "table" then
            for _, name in ipairs(lo) do
                table.insert(result, tostring(name))
            end
        else
            table.insert(result, tostring(lo))
        end
        return true
    end

    local succ, data = pcall(HTTPS.JSONDecode, HTTPS, contents)
    if succ and collect(data) then return #result > 0 and result or nil end

    for _, line in ipairs(contents:split("\n")) do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
            local ok2, d = pcall(HTTPS.JSONDecode, HTTPS, line)
            if ok2 and collect(d) then break end
        end
    end

    return #result > 0 and result or nil
end

local Recordfile = nil
local Replayfile = nil

local function readfile()
    local allfile = {}
    table.clear(allfile)
    for _, file in ipairs(listfiles(Folder)) do
        if file:lower():match("%.json$") then
            table.insert(allfile, file:match("([^/\\]+)$"))
        end
    end
    return allfile
end
local Section = Tab1:Section({Title = "Recorder"})
local loadout = fetchloadout("loadout.json")

local Section = Tab1:Section({Title = "Record"})
local Input = Tab1:Input({
    Title = "File",
    Desc = "name file to rec",
    Value = "",
    InputIcon = "",
    Type = "Input", -- or "Textarea"
    Placeholder = "Enter text...",
    Callback = function(input)
        local check = checkjson(input)
        if check then
            Recordfile = input
            WindUI:Notify({
    Title = "Success",
    Content = "Correct File Type"..Recordfile,
    Duration = 3, -- 3 seconds
    Icon = "",
})
            print(Recordfile)
        else
             noti("Error", "Please Use correct File Format.")
        end
    end
})

local Dropdown = Tab1:Dropdown({
    Title = "File",
    Desc = "Select File To Overwrite",
    Values = nil,
    Value = "",
    Callback = function(option)
        local check = checkjson(option)
        if check then Recordfile = option end
    end
})

myConfig:Register("dd", Dropdown)

local Button = Tab1:Button({
    Title = "refresh",
    Color = Color3.fromHex("#2d2d2d"), -- paint the button
    Justify = "Center", -- align items in the center (Center or Between or Left or Right)
    IconAlign = "Left", -- Left or Right of the text
    Icon = "", -- removing icon
    Callback = function()
        readfile()
        Dropdown:Refresh(readfile())
    end
})

Tab1:Divider()

local Button1 = Tab1:Button({
    Title = "Recorder",
    Desc = "start Record",
    Locked = false,
    Callback = function()

        local check = checkjson(Recordfile)
        if check then
            getgenv().Config = {File_Name = Recordfile}
            loadstring(game:HttpGet(
                           "https://api.jnkie.com/api/v1/luascripts/public/a177800f363abf29f55c35516a4e9422cb5cfb7e60c46760eb84acff5d529e2e/download"))()
        else
            noti("Error", "Please Correct File Format")
        end

    end
})

local Section = Tab2:Section({Title = "Replay"})

local Paragraph1 = Tab2:Paragraph({
    Title = "Loadout",
    Desc = "",
    Image = "",
    ImageSize = 0,
    Thumbnail = "",
    ThumbnailSize = 80,
    Locked = false
})

local Dropdown2 = Tab2:Dropdown({
    Title = "File",
    Desc = "Select File To Replay",
    Values = nil,
    Value = "",
    Callback = function(option)
        local check = checkjson(option)
        if check then
            Replayfile = option

            local f = fetchloadout(Folder .. "/" .. option)
            Paragraph1:SetDesc(f and table.concat(f, "\n") or "No loadout found")
            print(f and #f)

        end
    end
})

Dropdown2:Refresh(readfile())

local Button = Tab2:Button({
    Title = "refresh",
    Color = Color3.fromHex("#2d2d2d"), -- paint the button
    Justify = "Center", -- align items in the center (Center or Between or Left or Right)
    IconAlign = "Left", -- Left or Right of the text
    Icon = "", -- removing icon
    Callback = function()
        readfile()
        Dropdown:Refresh(readfile())
    end
})
local pa = true
local ws = true
local Toggle1 = Tab2:Toggle({
    Title = "Replay",
    Desc = "",
    Icon = "",
    Type = "Checkbox",
    Value = false, -- default value
    Callback = function(state) 
        
     if Replayfile == nil then
        noti("Error", "Please Select File Before Replay")
    else
        getgenv().Config = {File = Replayfile, AFK = ws, AutoPlayAgain = pa}
        loadstring(game:HttpGet(
                       "https://api.jnkie.com/api/v1/luascripts/public/7173100ba63bc37e17ce9c538fc9daeab551c58b0c0ad8cccf89bf9f795ea1ad/download"))()
    end
    
    
    end
})

myConfig:Register("ReplatToggle", Toggle1)

Tab2:Divider()


local Toggle4 = Tab2:Toggle({
    Title = "WhiteScreen",
    Desc = "",
    Icon = "",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) ws = not state end
})

myConfig:Register("ws", Toggle4)


local Toggle5 = Tab2:Toggle({
    Title = "PlayAgain",
    Desc = "",
    Icon = "",
    Type = "Checkbox",
    Value = true,
    Callback = function(state) pa = state end
})

myConfig:Register("pa", Toggle5)

Tab2:Divider()
local Button3 = Tab2:Button({
    Title = "Save",
    Desc = "",
    Locked = false,
    Callback = function()
        myConfig:Save()
        noti("Success", "Saved")
    end
})


local Toggle4 = Tab2:Toggle({
    Title = "WhiteScreen",
    Desc = "",
    Icon = "",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) ws = not state end
})


_G.WB = false
local WBTK = ""
local did = ""

local Inputa = Tab3:Input({
    Title = "WEBHOOK TOKEN",
    Desc = "",
    Value = "",
    InputIcon = "",
    Type = "Input", -- or "Textarea"
    Placeholder = "Enter text...",
    Callback = function(input) 
        if not input:lower():match("^https?://[%w%-%.]+%.[%a]+") then return end
        WBTK = input
    end
})
myConfig:Register("tk", Inputa)

local Input22 = Tab3:Input({
    Title = "ID",
    Desc = "",
    Value = "",
    InputIcon = "",
    Type = "Input", -- or "Textarea"
    Placeholder = "Enter text...",
    Callback = function(input) 
        if type(input) ~= 'number' then return end
        did = input
    end
})
myConfig:Register("ID", Input22)

local Toggle5 = Tab3:Toggle({
    Title = "Webhook",
    Desc = "Send Webhook Atfer You Win",
    Icon = "",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) 
        
        _G.WB = state
        if _G.WB then
            
            task.spawn(function()
                local gameui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("GameUI"):WaitForChild("FinalUI")
            local is = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("GameUI"):WaitForChild("FinalUI"):WaitForChild("Content"):WaitForChild("Stats"):WaitForChild("FrameMoney_Clone")
            local total = is:WaitForChild("Holder"):WaitForChild("Template"):WaitForChild("CoinAmount")

            local content =  game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("GameUI"):WaitForChild("FinalUI"):WaitForChild("Content"):WaitForChild("Content")

            while _G.WB  do
                task.wait(3)
                if gameui.Visible == true then
                    if content.Text == "You Win!" then
                        sendWin(WBTK,did, "You Win!" , 5439232 , content.Text)
                    elseif content.Text == "You Lost!" then
                        sendWin(WBTK,did, "You Lost!" , 16724736 , content.Text)
                    
                    end
                end
            end

            end)
        end
    end
})
myConfig:Register("WbToggle", Toggle5)

myConfig:Load()
task.wait(.5)

if Toggle1.Value == true then
    if Replayfile == nil then
        Toggle1:Set(false)
        noti("Error", "Please Select File Before Replay")
    else
        getgenv().Config = {File = Replayfile, AFK = ws, AutoPlayAgain = pa}
        loadstring(game:HttpGet(
                       "https://api.jnkie.com/api/v1/luascripts/public/7173100ba63bc37e17ce9c538fc9daeab551c58b0c0ad8cccf89bf9f795ea1ad/download"))()
    end

end
