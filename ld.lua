if game.PlaceId == 132929771812494 then

    getgenv().Replaying = false

    local HTTPS = game:GetService("HttpService")
    local RunService = game:GetService("RunService")

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
    local myConfig = ConfigManager:CreateConfig("FHConfig")

    ----------------------------------------------------------------
    -- Helpers
    ----------------------------------------------------------------
    local Folder = "WDMacro"
    if not isfolder(Folder) then makefolder(Folder) end

    -- Auto Load (เก็บแยกจาก myConfig เพราะต้องรู้ค่าก่อนจะ Load)
    local AutoLoadPath = Folder .. "/_autoload.txt" -- ไม่ใช่ .json เลยไม่โผล่ใน dropdown

    local function readAutoLoad()
        if isfile(AutoLoadPath) then
            local ok, v = pcall(readfile, AutoLoadPath)
            return ok and v == "1"
        end
        return false
    end

    local function writeAutoLoad(state)
        pcall(writefile, AutoLoadPath, state and "1" or "0")
    end

    local autoLoadEnabled = readAutoLoad()

    local files = {}

    local function refresh()
        table.clear(files)
        for _, f in ipairs(listfiles(Folder)) do
            if f:lower():match("%.json$") then
                table.insert(files, f:match("([^/\\]+)$"))
            end
        end
    end
    refresh()

    local function popup(title, content)
        WindUI:Popup({
            Title = title,
            Icon = "info",
            Content = content,
            Buttons = {
                {
                    Title = "Okay",
                    Icon = "arrow-right",
                    Callback = function() end,
                    Variant = "Primary"
                }
            }
        })
    end

    local function isJson(s)
        return type(s) == "string" and s ~= "" and s:lower():match("%.json$") ~=
                   nil
    end

    local function dropdownValue(v)
        if type(v) == "table" then v = v[1] end
        return v
    end

    -- state
    local selectedFile -- Tab1 (record / overwrite)
    local Replay = nil -- Tab2 (replay)
    local AP = false
    local FileLO = {}

    local loading = true -- true ระหว่าง myConfig:Load()
    local pendingReplay = false -- จำว่า Replay เคยเปิดไว้ตอนเซฟ

    ----------------------------------------------------------------
    -- Tab 1 : Recorder
    ----------------------------------------------------------------
    local Tab1 = Window:Tab({
        Title = "Recorder",
        Icon = "camera",
        Locked = false
    })

    Tab1:Input({
        Title = "File",
        Desc = "Name this file",
        Value = "example.json",
        InputIcon = "",
        Type = "Input",
        Placeholder = "Enter text...",
        Callback = function(input)
            if not isJson(input) then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please enter correct file format type",
                    Duration = 3,
                    Icon = ""
                })
                return
            end
            selectedFile = input
        end
    })

    local RecDropdown = Tab1:Dropdown({
        Title = "File",
        Desc = "select file to overwrite",
        Values = files,
        Value = "",
        Callback = function(option)
            option = dropdownValue(option)
            if not isJson(option) then return end
            selectedFile = option
        end
    })

    Tab1:Button({
        Title = "Refresh",
        Justify = "Center",
        IconAlign = "Left",
        Icon = "",
        Callback = function()
            refresh()
            RecDropdown:Refresh(files)
        end
    })

    Tab1:Divider()

    Tab1:Button({
        Title = "Record",
        Desc = "Press this button start record",
        Locked = false,
        Callback = function()
            if getgenv().Replaying == true then
                popup("Error", "SCRIPT IS RUNNING")
                return
            end

            if not isJson(selectedFile) then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please enter correct file format type",
                    Duration = 3,
                    Icon = ""
                })
                return
            end

            getgenv().Config = {File_Name = selectedFile}

            loadstring(game:HttpGet(
                           "https://api.jnkie.com/api/v1/luascripts/public/a177800f363abf29f55c35516a4e9422cb5cfb7e60c46760eb84acff5d529e2e/download"))()
        end
    })

    ----------------------------------------------------------------
    -- Tab 2 : Replay
    ----------------------------------------------------------------
    local Tab2 = Window:Tab({
        Title = "Replay",
        Icon = "refresh-ccw",
        Locked = false
    })

    local Paragraph = Tab2:Paragraph({Title = "Loadout", Desc = "-"})

    local function getloadout(File)
        table.clear(FileLO)

        if not isJson(File) then return false end
        local path = Folder .. "/" .. File
        if not isfile(path) then return false end

        local ok, content = pcall(readfile, path)
        if not ok or type(content) ~= "string" then return false end

        for _, line in ipairs(content:split("\n")) do
            if line ~= "" then
                local succ, data = pcall(HTTPS.JSONDecode, HTTPS, line)
                if succ and type(data) == "table" and data.Loadout then
                    local lo = data.Loadout
                    if type(lo) == "table" then
                        for _, name in ipairs(lo) do
                            table.insert(FileLO, tostring(name))
                        end
                    else
                        table.insert(FileLO, tostring(lo))
                    end
                    break -- เจอ Loadout แล้วพอ
                end
            end
        end
        return true
    end

    local function updateLoadoutText()
        if #FileLO == 0 then
            Paragraph:SetDesc("no loadout")
            return
        end

        local lines = {}
        for i, name in ipairs(FileLO) do lines[i] = i .. ". " .. name end
        Paragraph:SetDesc(table.concat(lines, "\n"))
    end

    -- ตั้งค่าไฟล์ replay แบบเงียบ ๆ (ไม่มี popup)
    local function setReplayFile(name)
        name = dropdownValue(name)
        if not isJson(name) or not isfile(Folder .. "/" .. name) then
            Replay = nil
            return false
        end
        Replay = name
        if getloadout(name) then updateLoadoutText() end
        return true
    end

    local ReplayDropdown = Tab2:Dropdown({
        Title = "File",
        Desc = "select file to Play",
        Values = files,
        Value = "",
        Callback = function(option) setReplayFile(option) end
    })
    myConfig:Register("FileREplay", ReplayDropdown)

    Tab2:Button({
        Title = "Refresh",
        Justify = "Center",
        IconAlign = "Left",
        Icon = "",
        Callback = function()
            refresh()
            ReplayDropdown:Refresh(files)
        end
    })

    Tab2:Divider()

    local ReplayToggle -- forward declare

    local function startReplay()
        if getgenv().Replaying == true then
            popup("Error", "SCRIPT IS RUNNING")
            return
        end

        if not isJson(Replay) then
            popup("Error", "Please select a valid .json file")
            ReplayToggle:Set(false)
            return
        end

        getgenv().Replaying = true
        getgenv().Config = {File_Name = Replay, AutoPlayAgain = AP}

        -- TODO: ใส่ loadstring ของสคริปต์ replay ตรงนี้
        loadstring(game:HttpGet(
                       "https://api.jnkie.com/api/v1/luascripts/public/7173100ba63bc37e17ce9c538fc9daeab551c58b0c0ad8cccf89bf9f795ea1ad/download"))()
    end

    ReplayToggle = Tab2:Toggle({
        Title = "Replay",
        Desc = "",
        Type = "Checkbox",
        Value = false,
        Callback = function(Value)
            if loading then
                pendingReplay = Value -- แค่จำไว้ ยังไม่รัน
                return
            end
            if not Value then return end
            startReplay()
        end
    })
    myConfig:Register("Replay", ReplayToggle)

    Tab2:Divider()

    local APToggle = Tab2:Toggle({
        Title = "Auto PlayAgain",
        Desc = "",
        Icon = "",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            AP = state
            if getgenv().Config then
                getgenv().Config.AutoPlayAgain = state
            end
        end
    })
    myConfig:Register("AP", APToggle)

    local WSToggle = Tab2:Toggle({
        Title = "WhiteScreen",
        Desc = "",
        Icon = "",
        Type = "Checkbox",
        Value = false,
        Callback = function(state)
            RunService:Set3dRenderingEnabled(not state)
        end
    })
    myConfig:Register("WS", WSToggle)

    Tab2:Divider()

    Tab2:Button({
        Title = "Save",
        Color = Color3.fromHex("#fff700"),
        Justify = "Center",
        IconAlign = "Left",
        Icon = "",
        Callback = function() myConfig:Save() end
    })

    Tab2:Toggle({
        Title = "Auto Load",
        Desc = "",
        Icon = "",
        Type = "Checkbox",
        Value = autoLoadEnabled,
        Callback = function(state)
            autoLoadEnabled = state
            writeAutoLoad(state)
        end
    })

    ----------------------------------------------------------------
    -- Load config (ท้ายสุด หลังสร้าง element ครบ)
    ----------------------------------------------------------------
    if autoLoadEnabled then
        pcall(function() myConfig:Load() end)
        task.wait(0.5) -- ให้ element ทุกตัวตั้งค่าเสร็จ
    end

    -- sync ไฟล์ replay จาก dropdown เอง (ไม่ขึ้น error ถ้าไฟล์หาย)
    setReplayFile(ReplayDropdown.Value)

    loading = false

    -- ถ้าตอนเซฟ Replay เปิดอยู่ ค่อยรันตอนนี้
    if pendingReplay then
        if Replay then
            startReplay()
        else
            ReplayToggle:Set(false) -- ไม่มีไฟล์ ปิดเงียบ ๆ
        end
    end
elseif game.PlaceId == 434343 then

end
