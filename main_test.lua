-- FLOP HUB SECURITY TEST SCRIPT 
-- ESTE SCRIPT SIMULA O FLOPHUB SENDO VIGIADO EM TEMPO REAL

local PROXY_URL = "https://flophub-testmuriloworkersdev.flophub.workers.dev/"
local FLOP_KEY = "FLOP_SECRET_2024_XYZ789"

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
    local data = tostring(LocalPlayer.UserId) .. ":" .. tostring(window) .. ":" .. FLOP_KEY
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
        -- Usando o prefixo flop_ em vez de nexus_
        local urlParams = string.format("?q=flop_start&user=%s&hwid=%s&userId=%s&key=%s&status=on&nocache=%s",
            HttpService:UrlEncode(userIdent), HttpService:UrlEncode(hwid), LocalPlayer.UserId, HttpService:UrlEncode("SUA_CHAVE_AQUI"), tostring(tick())
        )
        
        if req then
            local res = req({
                Url = PROXY_URL .. urlParams,
                Method = "GET",
                Headers = { ["X-Flop-Signature"] = GetSignature() }
            })
            
            if res and res.Body then
                local data = HttpService:JSONDecode(res.Body)
                if data.ban == true then
                    LocalPlayer:Kick("🛡️ FLOP HUB SECURITY\nVocê está BANIDO permanentemente.\nMotivo: " .. (data.reason or "Sistema"))
                    statusOk = false
                end
                if data.kick == true then
                    LocalPlayer:Kick("⚠️ FLOP HUB SECURITY\nSeu acesso foi recusado.\nMotivo: " .. (data.reason or "Sistema"))
                    statusOk = false
                end
            end
        end
    end)
    return statusOk
end

-- ===============================================
-- 💓 FLOP HUB HEARTBEAT (A CADA 3 SEGUNDOS)
-- ===============================================
local function StartHeartbeat()
    task.spawn(function()
        while task.wait(3) do
            pcall(function()
                local req = (syn and syn.request) or http_request or request
                local urlParams = string.format("?q=flop_sync&user=%s&hwid=%s&userId=%s&key=%s&status=on&nocache=%s",
                    HttpService:UrlEncode(userIdent), HttpService:UrlEncode(hwid), LocalPlayer.UserId, HttpService:UrlEncode("SUA_CHAVE_AQUI"), tostring(tick())
                )
                
                if req then
                    local res = req({
                        Url = PROXY_URL .. urlParams,
                        Method = "GET",
                        Headers = { ["X-Flop-Signature"] = GetSignature() }
                    })
                    
                    if res and res.Body then
                        local data = HttpService:JSONDecode(res.Body)
                        
                        -- ATUALIZAÇÃO SILENCIOSA DE KEY (TESTE)
                        if data.new_key and data.new_key ~= "" then
                            print("[FLOP HUB] Sua key foi alterada silenciosamente para: " .. data.new_key)
                            if writefile then pcall(function() writefile("FlopHub_Key_TESTE.txt", data.new_key) end) end
                        end

                        -- Se o admin marcou Ban:
                        if data.ban == true then
                            LocalPlayer:Kick("🛡️ FLOP HUB SECURITY\nVocê foi BANIDO em tempo real.\nMotivo: " .. (data.reason or "Sistema"))
                        end
                        -- Se o admin marcou Kick:
                        if data.kick == true then
                            LocalPlayer:Kick("⚠️ FLOP HUB SECURITY\nVocê foi KICKADO pelo admin.\nMotivo: " .. (data.reason or "Sistema"))
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
print("[FLOP HUB] Comunicando com o Banco de Dados...")
if CheckBanimento() then
    print("[FLOP HUB] Status OK! Acesso Permitido.")
    print("[FLOP HUB] Iniciando sistema de Heartbeat asíncrono...")
    
    StartHeartbeat()
    
    -- UI Visual Básica de Monitoramento
    local sg = Instance.new("ScreenGui", game.CoreGui)
    local tx = Instance.new("TextLabel", sg)
    tx.Size = UDim2.new(0, 300, 0, 50)
    tx.Position = UDim2.new(0.5, -150, 0, 20)
    tx.BackgroundColor3 = Color3.fromRGB(20,20,20)
    tx.TextColor3 = Color3.fromRGB(0, 255, 100)
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 14
    tx.Text = "🛡️ FLOP HUB CONNECTED - Monitoring..."
end
