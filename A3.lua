-- ============================================
-- グラブパレットラグドールキック 最強版 v2.0
-- デュアルパレット交互叩きつけ + Orion UI
-- ============================================

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- サービス・リモート取得（最適化：一度だけ）
-- ============================================
local GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents")
local SetNetworkOwner = GrabEvents:WaitForChild("SetNetworkOwner")
local CreateGrabLine = GrabEvents:WaitForChild("CreateGrabLine")
local DestroyGrabLine = GrabEvents:WaitForChild("DestroyGrabLine")
local SpawnToy = ReplicatedStorage.MenuToys:WaitForChild("SpawnToyRemoteFunction")
local DestroyToy = ReplicatedStorage.MenuToys:WaitForChild("DestroyToy")

-- ============================================
-- 設定
-- ============================================
local CONFIG = {
    PALET_COUNT = 2,           -- パレット数（2個交互）
    ATTACK_SPEED = 600,        -- 叩きつけ速度
    HEIGHT_OFFSET = 2,         -- 頭上オフセット
    HIT_FRAMES = 1,            -- 叩きつけフレーム数
    CLAIM_RETRIES = 3,         -- 所有権取得回数
    SKY_POS = CFrame.new(0, 800000, 0),
    EXCLUDE_FRIENDS = false,   -- フレンド除外
    RAGDOLL_ONLY = true,       -- ラグドール状態のみ攻撃
}

-- ============================================
-- パレットプール（事前準備・再利用）
-- ============================================
local palletPool = {}
local isRunning = false
local activeTargets = {}

-- ============================================
-- 高速所有権取得（最適化）
-- ============================================
local function fastClaim(part)
    pcall(function()
        SetNetworkOwner:FireServer(part, part.CFrame)
        CreateGrabLine:FireServer(part, Vector3.zero, part.Position, false)
        DestroyGrabLine:FireServer(part)
    end)
end

-- ============================================
-- パレット作成（1個）
-- ============================================
local function createPallet()
    SpawnToy:InvokeServer("PalletLightBrown", CONFIG.SKY_POS, Vector3.zero)
    
    -- 高速取得（最大0.3秒）
    local pallet
    local startTime = tick()
    repeat
        local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if folder then
            pallet = folder:FindFirstChild("PalletLightBrown")
        end
        RunService.Heartbeat:Wait()
    until pallet or tick() - startTime > 0.3
    
    if not pallet then return nil end
    
    local mainPart = pallet:FindFirstChild("SoundPart") or pallet:FindFirstChildWhichIsA("BasePart")
    if not mainPart then
        pcall(function() DestroyToy:FireServer(pallet) end)
        return nil
    end
    
    -- 所有権取得（高速3回）
    for i = 1, CONFIG.CLAIM_RETRIES do
        SetNetworkOwner:FireServer(mainPart, mainPart.CFrame)
    end
    
    -- 物理設定（最適化）
    mainPart.CanCollide = false
    mainPart.Anchored = false
    mainPart.Massless = true
    
    -- 透明化
    for _, part in ipairs(pallet:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
        end
    end
    
    return {
        model = pallet,
        part = mainPart,
        inUse = false
    }
end

-- ============================================
-- パレットプール初期化（起動時に2個用意）
-- ============================================
local function initPalletPool()
    for i = 1, CONFIG.PALET_COUNT do
        local pallet = createPallet()
        if pallet then
            table.insert(palletPool, pallet)
        end
    end
end

-- ============================================
-- 単発叩きつけ（超高速）
-- ============================================
local function strikePallet(pallet, targetPos)
    local part = pallet.part
    if not part or not part.Parent then return end
    
    -- 頭上に配置
    part.CFrame = CFrame.new(targetPos.X, targetPos.Y + CONFIG.HEIGHT_OFFSET, targetPos.Z)
    part.AssemblyLinearVelocity = Vector3.new(0, -CONFIG.ATTACK_SPEED, 0)
    part.AssemblyAngularVelocity = Vector3.new(
        math.random(-30, 30),
        math.random(-30, 30),
        math.random(-30, 30)
    )
    
    fastClaim(part)
    
    -- 叩きつけ
    part.CanCollide = true
    for i = 1, CONFIG.HIT_FRAMES do
        RunService.Heartbeat:Wait()
    end
    
    -- リセット
    part.CanCollide = false
    part.CFrame = CONFIG.SKY_POS
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
end

-- ============================================
-- ターゲット攻撃ループ（デュアル交互）
-- ============================================
local function attackTarget(targetPlayer)
    local targetData = {player = targetPlayer, active = true}
    activeTargets[targetPlayer] = targetData
    
    task.spawn(function()
        while isRunning and targetData.active do
            if not targetPlayer or not targetPlayer.Parent then break end
            
            local char = targetPlayer.Character
            if not char then
                RunService.Heartbeat:Wait()
                continue
            end
            
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            
            if not rootPart or not humanoid then
                RunService.Heartbeat:Wait()
                continue
            end
            
            -- ラグドール状態チェック
            if CONFIG.RAGDOLL_ONLY then
                local ragdolled = humanoid:FindFirstChild("Ragdolled")
                if ragdolled and not ragdolled.Value then
                    RunService.Heartbeat:Wait()
                    continue
                end
            end
            
            local targetPos = rootPart.Position
            
            -- ============================================
            -- デュアルパレット交互叩きつけ（超高速）
            -- ============================================
            for i, pallet in ipairs(palletPool) do
                if not isRunning or not targetData.active then break end
                
                if pallet.part and pallet.part.Parent then
                    strikePallet(pallet, targetPos)
                    
                    -- パレットが壊れてたら再作成
                    if not pallet.part.Parent then
                        local newPallet = createPallet()
                        if newPallet then
                            palletPool[i] = newPallet
                        end
                    end
                else
                    -- パレット再作成
                    local newPallet = createPallet()
                    if newPallet then
                        palletPool[i] = newPallet
                    end
                end
            end
        end
        
        activeTargets[targetPlayer] = nil
    end)
end

-- ============================================
-- 全停止
-- ============================================
local function stopAll()
    isRunning = false
    
    for _, data in pairs(activeTargets) do
        data.active = false
    end
    activeTargets = {}
    
    -- パレット削除
    for _, pallet in ipairs(palletPool) do
        if pallet.model and pallet.model.Parent then
            pcall(function() DestroyToy:FireServer(pallet.model) end)
            if pallet.model.Parent then
                pallet.model:Destroy()
            end
        end
    end
    palletPool = {}
end

-- ============================================
-- UI作成
-- ============================================
local Window = OrionLib:MakeWindow({
    Name = "グラブパレットラグドールキック",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "PalletKick"
})

local MainTab = Window:MakeTab({
    Name = "キック",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local SettingsTab = Window:MakeTab({
    Name = "設定",
    Icon = "rbxassetid://4370211644",
    PremiumOnly = false
})

-- ============================================
-- プレイヤーリスト
-- ============================================
local playerNameMap = {}
local selectedTargets = {}

local function getPlayerList()
    local list = {}
    playerNameMap = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local display = p.DisplayName .. " (@" .. p.Name .. ")"
            table.insert(list, display)
            playerNameMap[display] = p.Name
        end
    end
    
    return list
end

-- ============================================
-- メインUI
-- ============================================
MainTab:AddSection("ターゲット選択")

MainTab:AddDropdown({
    Name = "ターゲット（複数選択可）",
    Default = {},
    Options = getPlayerList(),
    MultipleOptions = true,
    Callback = function(Options)
        selectedTargets = {}
        for _, display in ipairs(Options) do
            local name = playerNameMap[display]
            if name then
                table.insert(selectedTargets, name)
            end
        end
    end
})

MainTab:AddButton({
    Name = "リスト更新",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "更新",
            Content = "プレイヤーリストを更新しました",
            Time = 2
        })
    end
})

MainTab:AddSection("実行")

MainTab:AddToggle({
    Name = "グラブパレットラグドールキック",
    Default = false,
    Callback = function(Value)
        if Value then
            if #selectedTargets == 0 then
                OrionLib:MakeNotification({
                    Name = "エラー",
                    Content = "ターゲットを選択してください",
                    Time = 3
                })
                return
            end
            
            isRunning = true
            
            -- パレットプール初期化
            task.spawn(function()
                initPalletPool()
                
                OrionLib:MakeNotification({
                    Name = "準備完了",
                    Content = CONFIG.PALET_COUNT .. "個のパレットを準備しました",
                    Time = 2
                })
                
                -- 各ターゲットを攻撃
                for _, targetName in ipairs(selectedTargets) do
                    local targetPlayer = Players:FindFirstChild(targetName)
                    if targetPlayer then
                        attackTarget(targetPlayer)
                    end
                end
            end)
            
            OrionLib:MakeNotification({
                Name = "開始",
                Content = "グラブパレットラグドールキック開始",
                Time = 2
            })
        else
            stopAll()
            OrionLib:MakeNotification({
                Name = "停止",
                Content = "グラブパレットラグドールキック停止",
                Time = 2
            })
        end
    end
})

-- ============================================
-- 設定UI
-- ============================================
SettingsTab:AddSection("攻撃設定")

SettingsTab:AddSlider({
    Name = "叩きつけ速度",
    Min = 100,
    Max = 2000,
    Default = CONFIG.ATTACK_SPEED,
    Callback = function(Value)
        CONFIG.ATTACK_SPEED = Value
    end
})

SettingsTab:AddSlider({
    Name = "頭上オフセット",
    Min = 0,
    Max = 10,
    Default = CONFIG.HEIGHT_OFFSET,
    Callback = function(Value)
        CONFIG.HEIGHT_OFFSET = Value
    end
})

SettingsTab:AddSlider({
    Name = "パレット数",
    Min = 1,
    Max = 5,
    Default = CONFIG.PALET_COUNT,
    Callback = function(Value)
        CONFIG.PALET_COUNT = Value
    end
})

SettingsTab:AddToggle({
    Name = "フレンドを除外",
    Default = CONFIG.EXCLUDE_FRIENDS,
    Callback = function(Value)
        CONFIG.EXCLUDE_FRIENDS = Value
    end
})

SettingsTab:AddToggle({
    Name = "ラグドール状態のみ攻撃",
    Default = CONFIG.RAGDOLL_ONLY,
    Callback = function(Value)
        CONFIG.RAGDOLL_ONLY = Value
    end
})

-- ============================================
-- 情報タブ
-- ============================================
local InfoTab = Window:MakeTab({
    Name = "情報",
    Icon = "rbxassetid://4370211644",
    PremiumOnly = false
})

InfoTab:AddParagraph("使い方", "1. ターゲットを選択\n2. トグルをON\n3. 自動でキック開始\n\n複数選択で同時攻撃可能！")

InfoTab:AddParagraph("仕組み", "・" .. CONFIG.PALET_COUNT .. "個のパレットを交互に叩きつけ\n・超高速で連続攻撃\n・所有権を奪って操作\n・透明なパレットで見えない攻撃")

OrionLib:Init()
