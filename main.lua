-- 1
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local http_request = (syn and syn.request) or (http and http.request) or request

-- 2
getgenv().Config = {
    WebhookURL = "",
    Active = false,
    SecretPing = false,
    Toggles = {Epic=false, Legendary=false, Mythical=false, Secret=false}
}

-- 3
for _, v in pairs(getconnections(Players.LocalPlayer.Idled)) do v:Disable() end
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- 4
local Window = Fluent:CreateWindow({
    Title = "rennXvincent", SubTitle = "VVIP Webhook",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460), Theme = "Dark"
})

-- 5
local function CreateFloatingButton()
    local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
    sg.Name = "rennXvincentToggle"; sg.ResetOnSpawn = false
    local btn = Instance.new("ImageButton", sg)
    btn.Size = UDim2.new(0, 50, 0, 50); btn.Position = UDim2.new(0, 10, 0.5, -25)
    btn.BackgroundTransparency = 0.3; btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.Image = "rbxassetid://127722067073247"; btn.Draggable = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
end
CreateFloatingButton()

local Tabs = { Main = Window:AddTab({Title="Settings"}), Filters = Window:AddTab({Title="Filters"}) }

Tabs.Main:AddToggle("MT",{Title="Enable Logger", Default=false}):OnChanged(function(v) getgenv().Config.Active = v end)
Tabs.Main:AddToggle("SP",{Title="Secret Ping (@everyone)", Default=false}):OnChanged(function(v) getgenv().Config.SecretPing = v end)
Tabs.Main:AddInput("WH",{Title="Discord Webhook", Callback=function(v) getgenv().Config.WebhookURL = v end})

for r,_ in pairs(getgenv().Config.Toggles) do
    Tabs.Filters:AddToggle(r,{Title="Log "..r, Default=false}):OnChanged(function(v) getgenv().Config.Toggles[r] = v end)
end

-- 6
local function parseFishData(rawText)
    local clean = rawText:gsub("<[^>]*>", ""):gsub("%s+", " ")
    local player = clean:match("%[Server%]:%s*(.-)%s+obtained") or clean:match("^(.-)%s+obtained") or "Unknown"
    local fish = clean:match("obtained%s+an?%s+(.-)%s?%(") or clean:match("obtained%s+an?%s+(.-)$") or "Unknown"
    local weight = clean:match("%((.-)%)") or "N/A"
    local r,g,b = rawText:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
    local rarity = "Unknown"
    if r then
        r,g,b = tonumber(r),tonumber(g),tonumber(b)
        if r==179 and g==115 then rarity="Epic"
        elseif r==255 and g==185 then rarity="Legendary"
        elseif r>180 and g<100 then rarity="Mythical"
        elseif g>200 then rarity="Secret" end
    end
    return {Player=player, Name=fish, Weight=weight, Rarity=rarity}
end

local function SendWebhook(payload)
    if not http_request or getgenv().Config.WebhookURL == "" then return end
    pcall(function()
        http_request({
            Url = getgenv().Config.WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- 7
local function StartMonitoring(remote)
    if not remote:IsA("RemoteEvent") then return end
    remote.OnClientEvent:Connect(function(rawText)
        if not getgenv().Config.Active or getgenv().Config.WebhookURL == "" then return end
        if type(rawText) ~= "string" or not string.find(rawText, "obtained") then return end

        local data = parseFishData(rawText)
        if not getgenv().Config.Toggles[data.Rarity] then return end

        local colors = {Epic = 10040319, Legendary = 16766720, Mythical = 16711680, Secret = 65535}
        local mention = (data.Rarity == "Secret" and getgenv().Config.SecretPing) and "@everyone" or nil

        SendWebhook({
            content = mention,
            embeds = {{
                title = "🎣 rennXvincent Logger | Ikan Terangkat!",
                color = colors[data.Rarity],
                fields = {
                    {name="Player", value="```"..data.Player.."```", inline=true},
                    {name="Fish", value="```"..data.Name.."```", inline=true},
                    {name="Tier", value="```"..data.Rarity.."```", inline=true},
                    {name="Weight", value="```"..data.Weight.."```", inline=true}
                }
            }}
        })
    end)
end

-- 8
for _, v in pairs(game:GetDescendants()) do pcall(StartMonitoring, v) end
game.DescendantAdded:Connect(StartMonitoring)

Tabs.Main:AddButton({Title="Test Webhook", Callback=function() SendWebhook({content="✅ VVIP Webhook Ready!"}) end})
Window:SelectTab(1)
Fluent:Notify({Title="rennXvincent Logger", Content="VVIP Webhook", Duration=5})