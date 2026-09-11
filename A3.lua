-- ============================================
-- グラブパレットラグドールキック v2.0
-- Solaris UI (XOCU使用) 版
-- ============================================

local Solaris = loadstring(game:HttpGet("https://raw.githubusercontent.com/sladkoeshkaogg-svg/XOCU/refs/heads/main/XOCU%20FAKELIBRORY.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- ウィンドウ作成
-- ============================================
local Window = Solaris:CreateWindow({
    Title = "グラブパレットラグドールキック",
    Theme = {
        Main = Color3.fromRGB(25, 25, 30),
        Second = Color3.fromRGB(35, 35, 40),
        Accent = Color3.fromRGB(255, 255, 255),
        ElementAccent = Color3.fromRGB(150, 0, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(170, 170, 170),
        Transparency = 0.25,
        Font = "Gotham",
    },
    ToggleKey = Enum.KeyCode.RightShift,
    Transparency = 0.25,
    ShowWatermark = {Enabled = true, Title = true, User = true, FPS = true, Duration = false, Ping = true},
    AutoSave = true,
    ConfigFolder = "PalletKick",
    UiScale = 1.0,
})

-- ============================================
-- サービス・リモート取得
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
    PALET_COUNT = 2,
    ATTACK_SPEED = 600,
    HEIGHT_OFFSET = 2,
    HIT_FRAMES = 1,
    CLAIM_RETRIES = 3,
    SKY_POS = CFrame.new(0, 800000, 0),
    EXCLUDE_FRIENDS = false,
    RAGDOLL_ONLY = true,
}

-- ============================================
-- パレットプール
-- ============================================
local palletPool = {}
local isRunning = false
local activeTargets = {}

-- ============================================
-- 高速所有権取得
-- ============================================
local function fastClaim(part)
    pcall(function()
        SetNetworkOwner:FireServer(part, part.CFrame)
        CreateGrabLine:FireServer(part, Vector3.zero, part.Position, false)
        DestroyGrabLine:FireServer(part)
    end)
end

-- ============================================
-- パレット作成
-- ============================================
local function createPallet()
    SpawnToy:InvokeServer("PalletLightBrown", CONFIG.SKY_POS, Vector3.zero)
    
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
    
    for i = 1, CONFIG.CLAIM_RETRIES do
        SetNetworkOwner:FireServer(mainPart, mainPart.CFrame)
    end
    
    mainPart.CanCollide = false
    mainPart.Anchored = false
    mainPart.Massless = true
    
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
-- パレットプール初期化
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
-- 単発叩きつけ
-- ============================================
local function strikePallet(pallet, targetPos)
    local part = pallet.part
    if not part or not part.Parent then return end
    
    part.CFrame = CFrame.new(targetPos.X, targetPos.Y + CONFIG.HEIGHT_OFFSET, targetPos.Z)
    part.AssemblyLinearVelocity = Vector3.new(0, -CONFIG.ATTACK_SPEED, 0)
    part.AssemblyAngularVelocity = Vector3.new(
        math.random(-30, 30),
        math.random(-30, 30),
        math.random(-30, 30)
    )
    
    fastClaim(part)
    
    part.CanCollide = true
    for i = 1, CONFIG.HIT_FRAMES do
        RunService.Heartbeat:Wait()
    end
    
    part.CanCollide = false
    part.CFrame = CONFIG.SKY_POS
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
end

-- ============================================
-- ターゲット攻撃ループ
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
            
            if CONFIG.RAGDOLL_ONLY then
                local ragdolled = humanoid:FindFirstChild("Ragdolled")
                if ragdolled and not ragdolled.Value then
                    RunService.Heartbeat:Wait()
                    continue
                end
            end
            
            local targetPos = rootPart.Position
            
            for i, pallet in ipairs(palletPool) do
                if not isRunning or not targetData.active then break end
                
                if pallet.part and pallet.part.Parent then
                    strikePallet(pallet, targetPos)
                    
                    if not pallet.part.Parent then
                        local newPallet = createPallet()
                        if newPallet then
                            palletPool[i] = newPallet
                        end
                    end
                else
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
local MainTab = Window:CreateTab("キック", true, "4483345998")

local MainBlock = MainTab:CreateBlock({Name = "メイン", Side = "Left"})
local SettingsBlock = MainTab:CreateBlock({Name = "設定", Side = "Right"})

-- ============================================
-- プレイヤーリスト
-- ============================================
local playerNameMap = {}
local selectedTargets = {}
local PlayerDropdown = nil

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
PlayerDropdown = MainBlock:CreateDropdown({
    Name = "ターゲット選択",
    Items = getPlayerList(),
    Default = "",
    Multiple = true,
    Callback = function(Options)
        selectedTargets = {}
        if type(Options) == "table" then
            for _, display in ipairs(Options) do
                local name = playerNameMap[display]
                if name then
                    table.insert(selectedTargets, name)
                end
            end
        else
            local name = playerNameMap[Options]
            if name then
                table.insert(selectedTargets, name)
            end
        end
    end
})

MainBlock:CreateButton({
    Name = "リスト更新",
    Callback = function()
        if PlayerDropdown then
            PlayerDropdown:Refresh(getPlayerList(), true)
        end
        Solaris:Notify({
            Title = "更新",
            Content = "プレイヤーリストを更新しました",
            Duration = 2
        })
    end
})

MainBlock:CreateToggle({
    Name = "グラブパレットラグドールキック",
    Default = false,
    Callback = function(Value)
        if Value then
            if #selectedTargets == 0 then
                Solaris:Notify({
                    Title = "エラー",
                    Content = "ターゲットを選択してください",
                    Duration = 3
                })
                return
            end
            
            isRunning = true
            
            task.spawn(function()
                initPalletPool()
                
                Solaris:Notify({
                    Title = "準備完了",
                    Content = CONFIG.PALET_COUNT .. "個のパレットを準備しました",
                    Duration = 2
                })
                
                for _, targetName in ipairs(selectedTargets) do
                    local targetPlayer = Players:FindFirstChild(targetName)
                    if targetPlayer then
                        attackTarget(targetPlayer)
                    end
                end
            end)
            
            Solaris:Notify({
                Title = "開始",
                Content = "グラブパレットラグドールキック開始",
                Duration = 2
            })
        else
            stopAll()
            Solaris:Notify({
                Title = "停止",
                Content = "グラブパレットラグドールキック停止",
                Duration = 2
            })
        end
    end
})

-- ============================================
-- 設定UI
-- ============================================
SettingsBlock:CreateSlider({
    Name = "叩きつけ速度",
    Min = 100,
    Max = 2000,
    Default = CONFIG.ATTACK_SPEED,
    Callback = function(Value)
        CONFIG.ATTACK_SPEED = Value
    end
})

SettingsBlock:CreateSlider({
    Name = "頭上オフセット",
    Min = 0,
    Max = 10,
    Default = CONFIG.HEIGHT_OFFSET,
    Callback = function(Value)
        CONFIG.HEIGHT_OFFSET = Value
    end
})

SettingsBlock:CreateSlider({
    Name = "パレット数",
    Min = 1,
    Max = 5,
    Default = CONFIG.PALET_COUNT,
    Callback = function(Value)
        CONFIG.PALET_COUNT = Value
    end
})

SettingsBlock:CreateToggle({
    Name = "フレンドを除外",
    Default = CONFIG.EXCLUDE_FRIENDS,
    Callback = function(Value)
        CONFIG.EXCLUDE_FRIENDS = Value
    end
})

SettingsBlock:CreateToggle({
    Name = "ラグドール状態のみ攻撃",
    Default = CONFIG.RAGDOLL_ONLY,
    Callback = function(Value)
        CONFIG.RAGDOLL_ONLY = Value
    end
})

-- ============================================
-- 情報タブ
-- ============================================
local InfoTab = Window:CreateTab("情報", true, "4370211644")

local InfoBlock = InfoTab:CreateBlock({Name = "使い方", Side = "Left"})

InfoBlock:CreateButton({
    Name = "使用方法",
    Callback = function()
        Solaris:Notify({
            Title = "使い方",
            Content = "1. ターゲットを選択\n2. トグルをON\n3. 自動でキック開始\n\n複数選択で同時攻撃可能！",
            Duration = 15
        })
    end
})

InfoBlock:CreateButton({
    Name = "仕組み",
    Callback = function()
        Solaris:Notify({
            Title = "仕組み",
            Content = CONFIG.PALET_COUNT .. "個のパレットを交互に叩きつけ\n超高速で連続攻撃\n所有権を奪って操作\n透明なパレットで見えない攻撃",
            Duration = 15
        })
    end
})

print("グラブパレットラグドールキック v2.0 (Solaris UI版) ロード完了")
