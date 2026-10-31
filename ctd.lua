local Folder = "WDMacro"

local HTTPS = game:GetService("HttpService")
local Players = game:GetService("Players")

-- make sure the macro folder exists so listfiles() doesn't error
if makefolder and isfolder and not isfolder(Folder) then
    pcall(makefolder, Folder)
end

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
local Tab3 = Window:Tab({Title = "Webhook", Icon = "sparkles", Locked = true})
Tab1:Select()

------------------------------------------------------------------ helpers

local function checkjson(file)
    return type(file) == "string" and file:lower():match("%.json$") ~= nil
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

-- executors expose their own request function; HttpService:RequestAsync
-- is blocked for discord.com inside Roblox
local httpRequest = request or http_request or (syn and syn.request)
    or (http and http.request) or (fluxus and fluxus.request)

local function sendWin(url, discordUserId, title, color, gain)
    if type(url) ~= "string" or url == "" then return end
    if not httpRequest then
        warn("No request function available in this executor")
        return
    end

    local id = tostring(discordUserId or ""):gsub("%s+", "")
    local content = ""
    if id:match("^%d+$") then content = "<@" .. id .. ">" end

    local payload = {
        content = content,
        embeds = {{
            title = "FACK HUB - " .. tostring(title),
            description = "Gain : " .. tostring(gain) .. " Coins",
            color = color,
        }},
        attachments = {},
    }

    local ok, result = pcall(httpRequest, {
        Url = (url:gsub("%s+", "")),
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HTTPS:JSONEncode(payload),
    })

    if not ok then
        warn("Webhook request failed:", result)
    elseif result and result.Success == false then
        warn("Webhook error:", result.StatusCode, result.Body)
    end
end

-- renamed from readfile(): the old name shadowed the executor's readfile
local function listJsonFiles()
    local all = {}
    local ok, files = pcall(listfiles, Folder)
    if not ok or type(files) ~= "table" then return all end
    for _, file in ipairs(files) do
        if file:lower():match("%.json$") then
            table.insert(all, (file:match("([^/\\]+)$")))
        end
    end
    return all
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

------------------------------------------------------------------ state

local Recordfile = nil
local Replayfile = nil
local pa = true  -- AutoPlayAgain
local ws = true  -- AFK (inverse of WhiteScreen toggle)
local replayStarted = false

local REPLAY_URL = "https://api.jnkie.com/api/v1/luascripts/public/7173100ba63bc37e17ce9c538fc9daeab551c58b0c0ad8cccf89bf9f795ea1ad/download"
local RECORD_URL = "https://api.jnkie.com/api/v1/luascripts/public/a177800f363abf29f55c35516a4e9422cb5cfb7e60c46760eb84acff5d529e2e/download"

local function startReplay()
    if replayStarted then return end
    if Replayfile == nil then
        noti("Error", "Please Select File Before Replay")
        return false
    end
    replayStarted = true
    getgenv().Config = {File = Replayfile, AFK = ws, AutoPlayAgain = pa}
    loadstring(game:HttpGet(REPLAY_URL))()
    return true
end

------------------------------------------------------------------ Record tab

Tab1:Section({Title = "Record"})

Tab1:Input({
    Title = "File",
    Desc = "name file to rec",
    Value = "",
    InputIcon = "",
    Type = "Input",
    Placeholder = "Enter text...",
    Callback = function(input)
        if checkjson(input) then
            Recordfile = input
            WindUI:Notify({
                Title = "Success",
                Content = "Correct File Type: " .. Recordfile,
                Duration = 3,
                Icon = "",
            })
        else
            noti("Error", "Please Use correct File Format.")
        end
    end
})

local Dropdown = Tab1:Dropdown({
    Title = "File",
    Desc = "Select File To Overwrite",
    Values = {},
    Value = "",
    Callback = function(option)
        if checkjson(option) then Recordfile = option end
    end
})
myConfig:Register("dd", Dropdown)

Tab1:Button({
    Title = "refresh",
    Color = Color3.fromHex("#2d2d2d"),
    Justify = "Center",
    IconAlign = "Left",
    Icon = "",
    Callback = function()
        Dropdown:Refresh(listJsonFiles())
    end
})

Tab1:Divider()

Tab1:Button({
    Title = "Recorder",
    Desc = "start Record",
    Locked = false,
    Callback = function()
        if checkjson(Recordfile) then
            getgenv().Config = {File_Name = Recordfile}
            loadstring(game:HttpGet(RECORD_URL))()
        else
            noti("Error", "Please Correct File Format")
        end
    end
})

Dropdown:Refresh(listJsonFiles())

------------------------------------------------------------------ Replay tab

Tab2:Section({Title = "Replay"})

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
    Values = {},
    Value = "",
    Callback = function(option)
        if checkjson(option) then
            Replayfile = option
            local f = fetchloadout(Folder .. "/" .. option)
            Paragraph1:SetDesc(f and table.concat(f, "\n") or "No loadout found")
        end
    end
})
-- registered BEFORE the replay toggle so the file is restored first on Load()
myConfig:Register("replayfile", Dropdown2)

Dropdown2:Refresh(listJsonFiles())

Tab2:Button({
    Title = "refresh",
    Color = Color3.fromHex("#2d2d2d"),
    Justify = "Center",
    IconAlign = "Left",
    Icon = "",
    Callback = function()
        local files = listJsonFiles()
        Dropdown:Refresh(files)
        Dropdown2:Refresh(files)
    end
})

local Toggle1 = Tab2:Toggle({
    Title = "Replay",
    Desc = "",
    Icon = "",
    Type = "Checkbox",
    Value = false,
    Callback = function(state)
        if not state then
            replayStarted = false -- allow starting again later
            return
        end
        if startReplay() == false then
            Toggle1:Set(false)
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

Tab2:Button({
    Title = "Save",
    Desc = "",
    Locked = false,
    Callback = function()
        myConfig:Save()
        noti("Success", "Saved")
    end
})


------------------------------------------------------------------ load config

myConfig:Load()
task.wait(0.5)

-- Load() normally fires the callbacks already; startReplay() has a guard
-- so it can't run twice
if Toggle1.Value == true then
    if startReplay() == false then
        Toggle1:Set(false)
    end
end
