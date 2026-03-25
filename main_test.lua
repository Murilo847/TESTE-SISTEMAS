-- NEXUS MANAGEMENT TEST SCRIPT 
-- ESTE SCRIPT SIMULA O FLOPHUB SENDO VIGIADO PELO NEXUS EM TEMPO REAL

local PROXY_URL = "https://flophub-testmuriloworkersdev.flophub.workers.dev/"
local NEXUS_KEY = "FLOP_SECRET_2024_XYZ789"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Identidade
local hwid = "N/A"
pcall(function() if gethwid then hwid = gethwid() elseif identifyexecutor then hwid = identifyexecutor() end end)
local userIdent = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"

-- Assinatura
local TimeOffset = 0
pcall(function()
    local sTime = tonumber(game:HttpGet(PROXY_URL .. "?q=time"))
    if sTime then TimeOffset = sTime - os.time() end
end)

local function GetSignature()
    local window = math.floor((os.time() + TimeOffset) / 15)
    local data = tostring(LocalPlayer.UserId) .. ":" .. tostring(window) .. ":" .. NEXUS_KEY
    local hash = 0
    for i = 1, #data do 
        hash = (hash * 31 + string.byte(data, i)) % 2147483647 
    end
    return string.format("%x", hash)
end

-- ===============================================
-- 🛡️ LOADER-LEVEL BAN CHECK
-- ===============================================
local function CheckBanimento()
    local statusOk = true
    pcall(function()
        local req = (syn and syn.request) or http_request or request
        local urlParams = string.format("?q=nexus_start&user=%s&hwid=%s&userId=%s&status=on&nocache=%s",
            HttpService:UrlEncode(userIdent), HttpService:UrlEncode(hwid), LocalPlayer.UserId, tostring(tick())
        )
        
        if req then
            local res = req({
                Url = PROXY_URL .. urlParams,
                Method = "GET",
                Headers = { ["X-Nexus-Signature"] = GetSignature() }
            })
            
            if res and res.Body then
                local data = HttpService:JSONDecode(res.Body)
                if data.ban == true then
                    LocalPlayer:Kick("🛡️ NEXUS SECURITY\nVocê está BANIDO permanentemente.\nMotivo: " .. (data.reason or "Sistema"))
                    statusOk = false
                end
            end
        end
    end)
    return statusOk
end

-- ===============================================
-- 💓 NEXUS HEARTBEAT (A CADA 3 SEGUNDOS)
-- ===============================================
local function StartNexusHeartbeat()
    task.spawn(function()
        while task.wait(3) do
            pcall(function()
                local req = (syn and syn.request) or http_request or request
                local urlParams = string.format("?q=nexus_sync&user=%s&hwid=%s&userId=%s&status=on&nocache=%s",
                    HttpService:UrlEncode(userIdent), HttpService:UrlEncode(hwid), LocalPlayer.UserId, tostring(tick())
                )
                
                if req then
                    local res = req({
                        Url = PROXY_URL .. urlParams,
                        Method = "GET",
                        Headers = { ["X-Nexus-Signature"] = GetSignature() }
                    })
                    
                    if res and res.Body then
                        local data = HttpService:JSONDecode(res.Body)
                        
                        -- Se o admin marcou Ban:
                        if data.ban == true then
                            LocalPlayer:Kick("🛡️ NEXUS SECURITY\nVocê foi BANIDO em tempo real.\nMotivo: " .. (data.reason or "Sistema"))
                        end
                        -- Se o admin marcou Kick:
                        if data.kick == true then
                            LocalPlayer:Kick("⚠️ NEXUS SECURITY\nVocê foi KICKADO pelo admin.\nMotivo: " .. (data.reason or "Sistema"))
                        end
                    end
                end
            end)
        end
    end)
end

-- ===============================================
-- 🚀 INÍCIO DO SCRIPT
-- ===============================================
print("[NEXUS] Comunicando com o Servidor Root...")
if CheckBanimento() then
    print("[NEXUS] Status OK! Acesso Permitido.")
    print("[NEXUS] Iniciando sistema de Heartbeat asíncrono...")
    
    StartNexusHeartbeat()
    
    -- UI Visual Básica de Monitoramento
    local sg = Instance.new("ScreenGui", game.CoreGui)
    local tx = Instance.new("TextLabel", sg)
    tx.Size = UDim2.new(0, 300, 0, 50)
    tx.Position = UDim2.new(0.5, -150, 0, 20)
    tx.BackgroundColor3 = Color3.fromRGB(20,20,20)
    tx.TextColor3 = Color3.fromRGB(0, 255, 100)
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 14
    tx.Text = "🛡️ NEXUS CONNECTED - Monitoring..."
end
