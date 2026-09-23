-- // Uncanny Vintage Camera Shader v3.2 COMPLETE
-- タイルバトルHUB風UI + 演出全部 + 全バグ修正 + 明るさ拡張
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

if PlayerGui:FindFirstChild("UncannyCamGUI") then PlayerGui.UncannyCamGUI:Destroy() end
if PlayerGui:FindFirstChild("UncannyShaderOverlay") then PlayerGui.UncannyShaderOverlay:Destroy() end
if PlayerGui:FindFirstChild("UncannyPixelNoise") then PlayerGui.UncannyPixelNoise:Destroy() end

-- ==========================================
-- 元の状態を退避
-- ==========================================
local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogColor = Lighting.FogColor,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
    EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}

-- ==========================================
-- 設定値（v3.2: 明るさ範囲拡張）
-- ==========================================
local CFG = {
    enabled = false,
    -- 世界
    darkLevel = 0.25,
    brightness = 1.0,             -- ★デフォルト上げた（0.7 → 1.0）
    exposure = 0,                 -- ★デフォルト上げた（-0.4 → 0）
    saturation = -0.2,
    contrast = 0.15,
    ambient = Color3.fromRGB(60, 60, 70),        -- ★少し明るく
    outdoorAmbient = Color3.fromRGB(50, 50, 60), -- ★少し明るく
    fogEnd = 120,
    -- RGB
    rgbEnabled = true,
    rgbOffset = 6,
    rgbSpeed = 0.5,
    rgbPulse = false,
    rgbVertical = true,
    rgbVerticalOffset = 4,
    -- 3D形状RGB分離
    rgbGeometryEnabled = false,
    rgbGeometryOffset = 0.15,
    rgbGeometryUpdateRate = 0.05,
    -- ピクセルノイズ
    pixelNoiseEnabled = true,
    pixelCount = 400,
    pixelMinSize = 1,
    pixelMaxSize = 4,
    pixelRefreshRate = 0.05,
    pixelAlpha = 0.7,
    pixelColorful = false,
    -- 走査線
    scanEnabled = true,
    scanDensity = 25,
    -- グリッド
    gridEnabled = true,
    gridDensity = 15,
    -- ヴィネット
    vignetteDensity = 60,
    -- ブラー
    blurEnabled = true,
    blurAmount = 4,
    blurLayers = 2,
    -- ブルーム
    bloomEnabled = true,
    bloomIntensity = 0.4,
    -- カメラ
    shakeEnabled = false,
    shakeAmount = 0.3,
    shakeSpeed = 15,
    tiltEnabled = false,
    tiltAmount = 2,
    -- VHS
    vhsEnabled = false,
    vhsChance = 0.02,
    vhsAmount = 15,
    -- フリッカー
    flickerEnabled = false,
    flickerAmount = 0.08,
    flickerSpeed = 12,
    -- HUD
    recHudEnabled = true,
    recBlink = true,
    timestampEnabled = true,
    -- 演出
    damageFlashEnabled = true,
    damageFlashAmount = 0.5,
    rewindEnabled = true,
    rewindDuration = 2.0,
    stutterEnabled = false,
    stutterChance = 0.05,
    stutterDuration = 0.1,
    filmFrameEnabled = false,
    filmFrameThickness = 0.1,
    lensFlareEnabled = false,
    lensFlareOpacity = 0.4,
    borderPulseEnabled = false,
    borderPulseAmount = 0.15,
    recordingDotJitter = false,
    ghostFrameEnabled = false,
    ghostFrameAmount = 0.3,
    lensDirtEnabled = false,
    lensDirtDensity = 30,
    audioEnabled = false,
    audioVolume = 0.3,
}

-- ==========================================
-- 1. 世界
-- ==========================================
local function applyWorld()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("PostEffect") then
            obj:Destroy()
        end
    end

    local sky = Instance.new("Sky")
    sky.SkyboxBk = ""
    sky.SkyboxDn = ""
    sky.SkyboxFt = ""
    sky.SkyboxLf = ""
    sky.SkyboxRt = ""
    sky.SkyboxUp = ""
    sky.StarCount = 0
    sky.SunAngularSize = 0
    sky.MoonAngularSize = 0
    sky.Parent = Lighting

    local atmo = Instance.new("Atmosphere")
    atmo.Density = 0.7
    atmo.Offset = 0
    atmo.Color = Color3.new(0, 0, 0)
    atmo.Decay = Color3.new(0, 0, 0)
    atmo.Glare = 0
    atmo.Haze = 8
    atmo.Parent = Lighting

    Lighting.EnvironmentDiffuseScale = 0.3
    Lighting.EnvironmentSpecularScale = 0.3
    Lighting.Ambient = CFG.ambient
    Lighting.OutdoorAmbient = CFG.outdoorAmbient
    Lighting.Brightness = CFG.brightness
    Lighting.ClockTime = 0
    Lighting.GlobalShadows = true
    Lighting.ExposureCompensation = CFG.exposure
    Lighting.FogColor = Color3.fromRGB(15, 15, 20)
    Lighting.FogStart = 5
    Lighting.FogEnd = CFG.fogEnd

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.02
    cc.Contrast = CFG.contrast
    cc.Saturation = CFG.saturation
    cc.TintColor = Color3.fromRGB(180, 200, 200)
    cc.Name = "UncannyCC"
    cc.Parent = Lighting

    if CFG.blurEnabled then
        for i = 1, CFG.blurLayers do
            local blur = Instance.new("BlurEffect")
            blur.Size = CFG.blurAmount / i
            blur.Name = "UncannyBlur" .. i
            blur.Parent = Lighting
        end
    end

    if CFG.bloomEnabled then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = CFG.bloomIntensity
        bloom.Size = 16
        bloom.Threshold = 1.8
        bloom.Name = "UncannyBloom"
        bloom.Parent = Lighting
    end

    local dof = Instance.new("DepthOfFieldEffect")
    dof.FarIntensity = 0.15
    dof.FocusDistance = 25
    dof.InFocusRadius = 15
    dof.NearIntensity = 0
    dof.Name = "UncannyDOF"
    dof.Parent = Lighting
end

-- ==========================================
-- 2. オーバーレイ（★横線バグ修正済み）
-- ==========================================
local overlayGui = nil
local refs = {}
local pixelGui = nil
local pixelFrames = {}
local rgbHighlights = {}

local SCAN_ID = "rbxassetid://152855355"
local VIGNETTE_ID = "rbxassetid://889875927"
local GRID_ID = "rbxassetid://7184195296"
local LENS_ID = "rbxassetid://5284533999"
local FLARE_ID = "rbxassetid://5325118025"

local function makeOverlay()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UncannyShaderOverlay"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999998
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if gethui then gui.Parent = gethui() else gui.Parent = PlayerGui end

    -- RGB 赤
    local red = Instance.new("Frame")
    red.Name = "RedTint"
    red.Size = UDim2.new(1, 0, 1, 0)
    red.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    red.BackgroundTransparency = 0.9
    red.BorderSizePixel = 0
    red.ZIndex = 1
    red.Parent = gui

    -- RGB 青
    local blue = Instance.new("Frame")
    blue.Name = "BlueTint"
    blue.Size = UDim2.new(1, 0, 1, 0)
    blue.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    blue.BackgroundTransparency = 0.9
    blue.BorderSizePixel = 0
    blue.ZIndex = 3
    blue.Parent = gui

    -- 走査線
    local scan = Instance.new("ImageLabel")
    scan.Name = "Scanlines"
    scan.Size = UDim2.new(1, 0, 1, 0)
    scan.BackgroundTransparency = 1
    scan.Image = SCAN_ID
    scan.ImageColor3 = Color3.new(0, 0, 0)
    scan.ImageTransparency = 1 - CFG.scanDensity/100
    scan.ScaleType = Enum.ScaleType.Tile
    scan.TileSize = UDim2.new(0, 4, 0, 4)
    scan.ZIndex = 5
    scan.Parent = gui

    -- グリッド
    local grid = Instance.new("ImageLabel")
    grid.Name = "PixelGrid"
    grid.Size = UDim2.new(1, 0, 1, 0)
    grid.BackgroundTransparency = 1
    grid.Image = GRID_ID
    grid.ImageColor3 = Color3.new(0, 0, 0)
    grid.ImageTransparency = 1 - CFG.gridDensity/100
    grid.ScaleType = Enum.ScaleType.Tile
    grid.TileSize = UDim2.new(0, 3, 0, 3)
    grid.ZIndex = 6
    grid.Parent = gui

    -- ヴィネット
    local vignette = Instance.new("ImageLabel")
    vignette.Name = "Vignette"
    vignette.Size = UDim2.new(1, 0, 1, 0)
    vignette.BackgroundTransparency = 1
    vignette.Image = VIGNETTE_ID
    vignette.ImageColor3 = Color3.new(0, 0, 0)
    vignette.ImageTransparency = 1 - CFG.vignetteDensity/100
    vignette.ScaleType = Enum.ScaleType.Stretch
    vignette.ZIndex = 7
    vignette.Parent = gui

    -- レンズ汚れ
    local lens = Instance.new("ImageLabel")
    lens.Name = "LensDirt"
    lens.Size = UDim2.new(1, 0, 1, 0)
    lens.BackgroundTransparency = 1
    lens.Image = LENS_ID
    lens.ImageColor3 = Color3.fromRGB(255, 255, 255)
    lens.ImageTransparency = 1 - CFG.lensDirtDensity/100
    lens.ScaleType = Enum.ScaleType.Stretch
    lens.Visible = CFG.lensDirtEnabled
    lens.ZIndex = 8
    lens.Parent = gui

    -- レンズフレア
    local flare = Instance.new("ImageLabel")
    flare.Name = "LensFlare"
    flare.Size = UDim2.new(1, 0, 1, 0)
    flare.BackgroundTransparency = 1
    flare.Image = FLARE_ID
    flare.ImageColor3 = Color3.fromRGB(255, 220, 180)
    flare.ImageTransparency = 1 - CFG.lensFlareOpacity
    flare.ScaleType = Enum.ScaleType.Stretch
    flare.Visible = CFG.lensFlareEnabled
    flare.ZIndex = 9
    flare.Parent = gui

    -- 全体暗さ
    local darken = Instance.new("Frame")
    darken.Name = "Darken"
    darken.Size = UDim2.new(1, 0, 1, 0)
    darken.BackgroundColor3 = Color3.new(0, 0, 0)
    darken.BackgroundTransparency = 1 - CFG.darkLevel
    darken.BorderSizePixel = 0
    darken.ZIndex = 10
    darken.Parent = gui

    -- フィルム枠
    local filmFrame = Instance.new("Frame")
    filmFrame.Name = "FilmFrame"
    filmFrame.Size = UDim2.new(1, 0, 1, 0)
    filmFrame.BackgroundTransparency = 1
    filmFrame.Visible = CFG.filmFrameEnabled
    filmFrame.ZIndex = 11
    filmFrame.Parent = gui

    local topBar = Instance.new("Frame", filmFrame)
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, CFG.filmFrameThickness, 0)
    topBar.BackgroundColor3 = Color3.new(0, 0, 0)
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 12

    local bottomBar = Instance.new("Frame", filmFrame)
    bottomBar.Name = "BottomBar"
    bottomBar.Size = UDim2.new(1, 0, CFG.filmFrameThickness, 0)
    bottomBar.Position = UDim2.new(0, 0, 1 - CFG.filmFrameThickness, 0)
    bottomBar.BackgroundColor3 = Color3.new(0, 0, 0)
    bottomBar.BorderSizePixel = 0
    bottomBar.ZIndex = 12

    -- ダメージ赤
    local damageFlash = Instance.new("Frame")
    damageFlash.Name = "DamageFlash"
    damageFlash.Size = UDim2.new(1, 0, 1, 0)
    damageFlash.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    damageFlash.BackgroundTransparency = 1
    damageFlash.BorderSizePixel = 0
    damageFlash.ZIndex = 13
    damageFlash.Parent = gui

    -- ★巻き戻し（修正：初期完全非表示）
    local rewind = Instance.new("Frame")
    rewind.Name = "Rewind"
    rewind.Size = UDim2.new(1, 0, 1, 0)
    rewind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    rewind.BackgroundTransparency = 1
    rewind.BorderSizePixel = 0
    rewind.Visible = false          -- ★ 追加
    rewind.ZIndex = 14
    rewind.Parent = gui

    local rewindLines = Instance.new("Frame", rewind)
    rewindLines.Name = "Lines"
    rewindLines.Size = UDim2.new(1, 0, 1, 0)
    rewindLines.BackgroundTransparency = 1
    rewindLines.Visible = false     -- ★ 追加
    rewindLines.ZIndex = 15
    for i = 1, 20 do
        local line = Instance.new("Frame", rewindLines)
        line.Name = "Line" .. i
        line.Size = UDim2.new(1, 0, 0, 2)
        line.Position = UDim2.new(0, 0, (i-1)/20, 0)
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BackgroundTransparency = 1   -- ★ 0.5 → 1
        line.BorderSizePixel = 0
        line.ZIndex = 15
    end

    -- 残像
    local ghost = Instance.new("Frame")
    ghost.Name = "Ghost"
    ghost.Size = UDim2.new(1, 0, 1, 0)
    ghost.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ghost.BackgroundTransparency = 1
    ghost.BorderSizePixel = 0
    ghost.ZIndex = 16
    ghost.Parent = gui

    -- フリッカー
    local flicker = Instance.new("Frame")
    flicker.Name = "Flicker"
    flicker.Size = UDim2.new(1, 0, 1, 0)
    flicker.BackgroundColor3 = Color3.new(0, 0, 0)
    flicker.BackgroundTransparency = 1
    flicker.BorderSizePixel = 0
    flicker.ZIndex = 17
    flicker.Parent = gui

    -- 画面端脈動
    local borderPulse = Instance.new("Frame")
    borderPulse.Name = "BorderPulse"
    borderPulse.Size = UDim2.new(1, 0, 1, 0)
    borderPulse.BackgroundTransparency = 1
    borderPulse.Visible = CFG.borderPulseEnabled
    borderPulse.ZIndex = 18
    borderPulse.Parent = gui
    local bpStroke = Instance.new("UIStroke", borderPulse)
    bpStroke.Thickness = 30
    bpStroke.Color = Color3.new(0, 0, 0)
    bpStroke.Transparency = 1

    -- 低FPS
    local stutter = Instance.new("Frame")
    stutter.Name = "Stutter"
    stutter.Size = UDim2.new(1, 0, 1, 0)
    stutter.BackgroundColor3 = Color3.new(0, 0, 0)
    stutter.BackgroundTransparency = 1
    stutter.BorderSizePixel = 0
    stutter.ZIndex = 19
    stutter.Parent = gui

    -- REC HUD
    local recHud = Instance.new("Frame")
    recHud.Name = "RecHud"
    recHud.Size = UDim2.new(0, 120, 0, 30)
    recHud.Position = UDim2.new(0, 20, 0, 20)
    recHud.BackgroundTransparency = 1
    recHud.Visible = CFG.recHudEnabled
    recHud.ZIndex = 21
    recHud.Parent = gui

    local recDot = Instance.new("Frame")
    recDot.Name = "Dot"
    recDot.Size = UDim2.new(0, 12, 0, 12)
    recDot.Position = UDim2.new(0, 0, 0.5, -6)
    recDot.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
    recDot.BorderSizePixel = 0
    recDot.ZIndex = 22
    recDot.Parent = recHud
    Instance.new("UICorner", recDot).CornerRadius = UDim.new(1, 0)

    local recText = Instance.new("TextLabel")
    recText.Name = "Text"
    recText.Size = UDim2.new(0, 80, 1, 0)
    recText.Position = UDim2.new(0, 18, 0, 0)
    recText.BackgroundTransparency = 1
    recText.Text = "REC"
    recText.TextColor3 = Color3.fromRGB(255, 255, 255)
    recText.Font = Enum.Font.Code
    recText.TextSize = 16
    recText.TextXAlignment = Enum.TextXAlignment.Left
    recText.TextStrokeTransparency = 0.3
    recText.ZIndex = 22
    recText.Parent = recHud

    local timestamp = Instance.new("TextLabel")
    timestamp.Name = "Timestamp"
    timestamp.Size = UDim2.new(0, 300, 0, 24)
    timestamp.Position = UDim2.new(1, -320, 0, 20)
    timestamp.BackgroundTransparency = 1
    timestamp.Text = ""
    timestamp.TextColor3 = Color3.fromRGB(255, 255, 255)
    timestamp.Font = Enum.Font.Code
    timestamp.TextSize = 14
    timestamp.TextXAlignment = Enum.TextXAlignment.Right
    timestamp.TextStrokeTransparency = 0.3
    timestamp.Visible = CFG.timestampEnabled
    timestamp.ZIndex = 21
    timestamp.Parent = gui

    refs = {
        gui = gui,
        red = red, blue = blue,
        scan = scan, grid = grid, vignette = vignette,
        lens = lens, flare = flare, darken = darken,
        filmFrame = filmFrame, topBar = topBar, bottomBar = bottomBar,
        damageFlash = damageFlash,
        rewind = rewind, rewindLines = rewindLines,
        ghost = ghost, flicker = flicker,
        borderPulse = borderPulse, bpStroke = bpStroke,
        stutter = stutter,
        recHud = recHud, recDot = recDot, recText = recText,
        timestamp = timestamp,
    }
    return gui
end

-- ==========================================
-- 3. ピクセルノイズ
-- ==========================================
local function makePixelNoise()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UncannyPixelNoise"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999997
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if gethui then gui.Parent = gethui() else gui.Parent = PlayerGui end

    pixelFrames = {}
    for i = 1, CFG.pixelCount do
        local px = Instance.new("Frame")
        px.Name = "Px" .. i
        px.BackgroundColor3 = Color3.new(1, 1, 1)
        px.BackgroundTransparency = 1
        px.BorderSizePixel = 0
        px.ZIndex = 1
        px.Parent = gui
        pixelFrames[i] = px
    end
    pixelGui = gui
    return gui
end

local function updatePixelNoise()
    if not pixelGui or not pixelGui.Parent then return end
    local screen = Camera.ViewportSize
    for i, px in ipairs(pixelFrames) do
        if math.random() < 0.7 then
            local size = math.random(CFG.pixelMinSize, CFG.pixelMaxSize)
            px.Size = UDim2.new(0, size, 0, size)
            px.Position = UDim2.new(0, math.random(0, screen.X - size), 0, math.random(0, screen.Y - size))
            px.BackgroundTransparency = 1 - CFG.pixelAlpha * (0.5 + math.random() * 0.5)
            if CFG.pixelColorful then
                px.BackgroundColor3 = Color3.fromHSV(math.random(), 1, 1)
            else
                local v = 0.7 + math.random() * 0.3
                px.BackgroundColor3 = Color3.new(v, v, v)
            end
        else
            px.BackgroundTransparency = 1
        end
    end
end

-- ==========================================
-- 4. 3D形状RGB分離
-- ==========================================
local function cleanupRGBHighlights()
    for _, hl in pairs(rgbHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    rgbHighlights = {}
end

local function updateRGBGeometry()
    if not CFG.rgbGeometryEnabled then
        if next(rgbHighlights) then cleanupRGBHighlights() end
        return
    end
    local seen = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency < 0.95 and obj.Parent then
            seen[obj] = true
            local hlRed = rgbHighlights[obj]
            if not hlRed or not hlRed.Parent then
                hlRed = Instance.new("Highlight")
                hlRed.Name = "UncannyRGBRed"
                hlRed.FillColor = Color3.fromRGB(255, 0, 0)
                hlRed.OutlineColor = Color3.fromRGB(255, 0, 0)
                hlRed.FillTransparency = 0.7
                hlRed.OutlineTransparency = 0.3
                hlRed.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hlRed.Adornee = obj
                hlRed.Parent = obj
                rgbHighlights[obj] = hlRed
            end
            local hlBlue = rgbHighlights[obj .. "_b"]
            if not hlBlue or not hlBlue.Parent then
                hlBlue = Instance.new("Highlight")
                hlBlue.Name = "UncannyRGBBlue"
                hlBlue.FillColor = Color3.fromRGB(0, 0, 255)
                hlBlue.OutlineColor = Color3.fromRGB(0, 0, 255)
                hlBlue.FillTransparency = 0.7
                hlBlue.OutlineTransparency = 0.3
                hlBlue.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hlBlue.Adornee = obj
                hlBlue.Parent = obj
                rgbHighlights[obj .. "_b"] = hlBlue
            end
        end
    end
    for k, hl in pairs(rgbHighlights) do
        if not hl or not hl.Parent then
            rgbHighlights[k] = nil
        end
    end
end

-- ==========================================
-- 5. 音響
-- ==========================================
local filmSound, humSound
local function setupAudio()
    if not CFG.audioEnabled then
        if filmSound then filmSound:Destroy() filmSound = nil end
        if humSound then humSound:Destroy() humSound = nil end
        return
    end
    if not filmSound then
        filmSound = Instance.new("Sound")
        filmSound.Name = "UncannyFilmSound"
        filmSound.SoundId = "rbxassetid://9114436197"
        filmSound.Looped = true
        filmSound.Volume = CFG.audioVolume
        filmSound.Parent = SoundService
        filmSound:Play()
    end
    if not humSound then
        humSound = Instance.new("Sound")
        humSound.Name = "UncannyHumSound"
        humSound.SoundId = "rbxassetid://90469938598537"
        humSound.Looped = true
        humSound.Volume = CFG.audioVolume * 0.6
        humSound.Parent = SoundService
        humSound:Play()
    end
end

-- ==========================================
-- 6. 演出トリガー
-- ==========================================
local damageFlashAlpha = 0
local rewindAlpha = 0
local ghostAlpha = 0
local stutterTimer = 0
local pixelFrame = 0
local vhsActive = 0
local rgbGeoFrame = 0

local function triggerDamageFlash()
    damageFlashAlpha = CFG.damageFlashAmount
end

local function triggerRewind()
    if not CFG.rewindEnabled then return end
    rewindAlpha = 1
    if refs.rewind then refs.rewind.Visible = true end
    if refs.rewindLines then refs.rewindLines.Visible = true end
end

local function triggerGhost()
    ghostAlpha = CFG.ghostFrameAmount
end

local lastHealth = 100
task.spawn(function()
    while true do
        task.wait(0.1)
        if CFG.enabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health < lastHealth and CFG.damageFlashEnabled then
                    triggerDamageFlash()
                end
                if hum.Health <= 0 and lastHealth > 0 then
                    triggerRewind()
                end
                lastHealth = hum.Health
            end
        else
            lastHealth = 100
        end
    end
end)

-- ==========================================
-- 7. メインループ
-- ==========================================
RunService.RenderStepped:Connect(function(dt)
    if not CFG.enabled then return end
    if not refs.gui or not refs.gui.Parent then return end
    local t = tick()

    if CFG.shakeEnabled then
        local s = CFG.shakeAmount
        local sp = CFG.shakeSpeed
        local ox = math.sin(t * sp) * s + (math.random() - 0.5) * s * 0.5
        local oy = math.cos(t * sp * 1.3) * s + (math.random() - 0.5) * s * 0.5
        Camera.CFrame = Camera.CFrame * CFrame.new(ox, oy, 0) * CFrame.Angles(ox * 0.005, oy * 0.005, ox * 0.01)
    end

    if CFG.tiltEnabled then
        local tiltRad = math.rad(CFG.tiltAmount)
        local jitter = math.sin(t * 0.5) * math.rad(CFG.tiltAmount * 0.3)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, tiltRad + jitter)
    end

    if CFG.rgbEnabled then
        local baseOffset = CFG.rgbOffset
        if CFG.rgbPulse then
            baseOffset = baseOffset * (1 + math.sin(t * 3) * 0.5)
        end
        local jitter = math.sin(t * CFG.rgbSpeed) * baseOffset
        local vJitter = 0
        if CFG.rgbVertical then
            vJitter = math.sin(t * CFG.rgbSpeed * 1.7) * CFG.rgbVerticalOffset
        end
        refs.red.Position = UDim2.new(0, jitter, 0, vJitter)
        refs.blue.Position = UDim2.new(0, -jitter, 0, -vJitter)
    end

    if CFG.pixelNoiseEnabled then
        pixelFrame = pixelFrame + dt
        if pixelFrame > CFG.pixelRefreshRate then
            pixelFrame = 0
            updatePixelNoise()
        end
    end

    if CFG.rgbGeometryEnabled then
        rgbGeoFrame = rgbGeoFrame + dt
        if rgbGeoFrame > CFG.rgbGeometryUpdateRate then
            rgbGeoFrame = 0
            task.spawn(updateRGBGeometry)
        end
    end

    if CFG.vhsEnabled and math.random() < CFG.vhsChance then
        vhsActive = 3
    end
    if vhsActive > 0 then
        local jx = (math.random() - 0.5) * CFG.vhsAmount
        refs.red.Position = UDim2.new(0, jx, 0, 0)
        refs.blue.Position = UDim2.new(0, -jx, 0, 0)
        refs.scan.Position = UDim2.new(0, jx, 0, 0)
        vhsActive = vhsActive - 1
    end

    if CFG.flickerEnabled then
        local f = (math.sin(t * CFG.flickerSpeed) + 1) * 0.5
        refs.flicker.BackgroundTransparency = 1 - (f * CFG.flickerAmount)
    else
        refs.flicker.BackgroundTransparency = 1
    end

    if damageFlashAlpha > 0 then
        damageFlashAlpha = damageFlashAlpha - dt * 1.5
        if damageFlashAlpha < 0 then damageFlashAlpha = 0 end
    end
    refs.damageFlash.BackgroundTransparency = 1 - damageFlashAlpha

    -- ★巻き戻し（修正済み）
    if rewindAlpha > 0 then
        rewindAlpha = rewindAlpha - dt * (1 / CFG.rewindDuration)
        if rewindAlpha < 0 then rewindAlpha = 0 end
        if refs.rewind then
            refs.rewind.BackgroundTransparency = 1 - rewindAlpha * 0.7
            refs.rewind.Visible = true
        end
        if refs.rewindLines then
            refs.rewindLines.Visible = true
            for i, line in ipairs(refs.rewindLines:GetChildren()) do
                if line:IsA("Frame") then
                    local base = (i-1) / 20
                    local scroll = (base + t * 2) % 1
                    line.Position = UDim2.new(0, 0, scroll, 0)
                    line.BackgroundTransparency = 1 - rewindAlpha * 0.5
                end
            end
        end
    else
        if refs.rewind then
            refs.rewind.BackgroundTransparency = 1
            refs.rewind.Visible = false
        end
        if refs.rewindLines then
            refs.rewindLines.Visible = false
        end
    end

    if ghostAlpha > 0 then
        ghostAlpha = ghostAlpha - dt * 2
        if ghostAlpha < 0 then ghostAlpha = 0 end
        refs.ghost.BackgroundTransparency = 1 - ghostAlpha
    else
        refs.ghost.BackgroundTransparency = 1
    end

    if CFG.stutterEnabled and math.random() < CFG.stutterChance then
        stutterTimer = CFG.stutterDuration    end
    if stutterTimer > 0 then
        stutterTimer = stutterTimer - dt
        refs.stutter.BackgroundTransparency = 1 - math.random() * 0.3
    else
        refs.stutter.BackgroundTransparency = 1
    end

    if CFG.borderPulseEnabled then
        local pulse = (math.sin(t * 2) + 1) * 0.5
        refs.bpStroke.Transparency = 1 - pulse * CFG.borderPulseAmount
    else
        refs.bpStroke.Transparency = 1
    end

    if CFG.recHudEnabled and CFG.recBlink then
        local blink
        if CFG.recordingDotJitter then
            blink = math.random() > 0.3 and 1 or 0.2
        else
            blink = (math.sin(t * 4) > 0) and 1 or 0.2
        end
        refs.recDot.BackgroundTransparency = 1 - blink
    end

    if CFG.timestampEnabled then
        refs.timestamp.Text = os.date("%Y.%m.%d  %H:%M:%S")
    end
end)

-- ==========================================
-- 8. 有効/無効
-- ==========================================
local function enableShader()
    if CFG.enabled then return end
    CFG.enabled = true
    applyWorld()
    overlayGui = makeOverlay()
    makePixelNoise()
    setupAudio()
end

local function disableShader()
    CFG.enabled = false
    for k, v in pairs(originalLighting) do
        pcall(function() Lighting[k] = v end)
    end
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            obj:Destroy()
        end
    end
    if overlayGui then overlayGui:Destroy() overlayGui = nil end
    if pixelGui then pixelGui:Destroy() pixelGui = nil end
    pixelFrames = {}
    cleanupRGBHighlights()
    refs = {}
    if filmSound then filmSound:Destroy() filmSound = nil end
    if humSound then humSound:Destroy() humSound = nil end
end

-- ==========================================
-- 9. UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "UncannyCamGUI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 560)
MainFrame.Position = UDim2.new(0, 20, 0.5, -280)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("TextLabel", MainFrame)
TitleBar.Size = UDim2.new(1, -35, 0, 28)
TitleBar.Text = "不気味カメラ v3.2"
TitleBar.TextColor3 = Color3.fromRGB(100, 255, 150)
TitleBar.Font = Enum.Font.Code
TitleBar.TextSize = 12
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UIPadding", TitleBar).PaddingLeft = UDim.new(0, 10)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local MinimizeBtn = Instance.new("TextButton", MainFrame)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 28)
MinimizeBtn.Position = UDim2.new(1, -32, 0, 0)
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.TextSize = 16
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.ZIndex = 2
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 8)

local ContentScroll = Instance.new("ScrollingFrame", MainFrame)
ContentScroll.Size = UDim2.new(1, -10, 1, -40)
ContentScroll.Position = UDim2.new(0, 5, 0, 34)
ContentScroll.BackgroundTransparency = 1
ContentScroll.BorderSizePixel = 0
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 255, 150)
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local layout = Instance.new("UIListLayout", ContentScroll)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", ContentScroll).PaddingTop = UDim.new(0, 4)

local orderCounter = 0
local function nextOrder()
    orderCounter = orderCounter + 1
    return orderCounter
end

local function makeSection(name)
    local label = Instance.new("TextLabel", ContentScroll)
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = "-- " .. name .. " --"
    label.TextColor3 = Color3.fromRGB(120, 200, 255)
    label.Font = Enum.Font.Code
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = nextOrder()
    Instance.new("UIPadding", label).PaddingLeft = UDim.new(0, 4)
end

local function makeToggle(name, def, callback)
    local btn = Instance.new("TextButton", ContentScroll)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.Text = (def and "[X] " or "[ ] ") .. name
    btn.BackgroundColor3 = def and Color3.fromRGB(30, 50, 30) or Color3.fromRGB(25, 25, 25)
    btn.TextColor3 = Color3.fromRGB(100, 255, 150)
    btn.Font = Enum.Font.Code
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = nextOrder()
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 8)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local on = def
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = (on and "[X] " or "[ ] ") .. name
        btn.BackgroundColor3 = on and Color3.fromRGB(30, 50, 30) or Color3.fromRGB(25, 25, 25)
        if callback then callback(on) end
    end)
    return btn
end

local function makeSlider(name, min, max, def, callback, isFloat)
    local label = Instance.new("TextLabel", ContentScroll)
    label.Size = UDim2.new(1, -8, 0, 12)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. def
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = nextOrder()
    Instance.new("UIPadding", label).PaddingLeft = UDim.new(0, 4)

    local bar = Instance.new("Frame", ContentScroll)
    bar.Size = UDim2.new(1, -16, 0, 6)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bar.BorderSizePixel = 0
    bar.LayoutOrder = nextOrder()
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

    local pct = (def - min) / (max - min)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local btn = Instance.new("TextButton", bar)
    btn.Size = UDim2.new(0, 14, 0, 14)
    btn.Position = UDim2.new(pct, -7, 0.5, -7)
    btn.AnchorPoint = Vector2.new(0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
    btn.Text = ""
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local val = def
    local hold = false
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hold = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hold = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if hold and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local p = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            btn.Position = UDim2.new(p, -7, 0.5, -7)
            fill.Size = UDim2.new(p, 0, 1, 0)
            val = min + p * (max - min)
            if isFloat then val = math.floor(val * 100) / 100 else val = math.floor(val) end
            label.Text = name .. ": " .. val
            if callback then callback(val) end
        end
    end)
end

local function makeButton(name, callback)
    local btn = Instance.new("TextButton", ContentScroll)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.TextColor3 = Color3.fromRGB(100, 255, 150)
    btn.Font = Enum.Font.Code
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = nextOrder()
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ==========================================
-- UI 構築（★明るさ範囲大幅拡張）
-- ==========================================
makeToggle("不気味カメラモード", CFG.enabled, function(v)
    if v then enableShader() else disableShader() end
end)

makeSection("世界 / 照明（★範囲拡張）")
makeSlider("暗さ(%)", 0, 95, CFG.darkLevel * 100, function(v)
    CFG.darkLevel = v / 100
    if refs.darken then refs.darken.BackgroundTransparency = 1 - CFG.darkLevel end
end)
makeSlider("明るさ", 0, 10, CFG.brightness, function(v)   -- ★ 0〜10 に拡張
    CFG.brightness = v
    Lighting.Brightness = v
end, true)
makeSlider("露出", -5, 5, CFG.exposure, function(v)        -- ★ -5〜5 に拡張
    CFG.exposure = v
    Lighting.ExposureCompensation = v
end, true)
makeSlider("環境光 R", 0, 255, CFG.ambient.R * 255, function(v)
    CFG.ambient = Color3.fromRGB(v, CFG.ambient.G * 255, CFG.ambient.B * 255)
    Lighting.Ambient = CFG.ambient
end)
makeSlider("環境光 G", 0, 255, CFG.ambient.G * 255, function(v)
    CFG.ambient = Color3.fromRGB(CFG.ambient.R * 255, v, CFG.ambient.B * 255)
    Lighting.Ambient = CFG.ambient
end)
makeSlider("環境光 B", 0, 255, CFG.ambient.B * 255, function(v)
    CFG.ambient = Color3.fromRGB(CFG.ambient.R * 255, CFG.ambient.G * 255, v)
    Lighting.Ambient = CFG.ambient
end)
makeSlider("彩度", -1, 1, CFG.saturation, function(v)
    CFG.saturation = v
    local cc = Lighting:FindFirstChild("UncannyCC")
    if cc then cc.Saturation = v end
end, true)
makeSlider("コントラスト", -1, 1, CFG.contrast, function(v)
    CFG.contrast = v
    local cc = Lighting:FindFirstChild("UncannyCC")
    if cc then cc.Contrast = v end
end, true)
makeSlider("フォグ距離", 10, 2000, CFG.fogEnd, function(v)   -- ★ 10〜2000 に拡張
    CFG.fogEnd = v
    Lighting.FogEnd = v
end)

makeSection("RGB色収差（オーバーレイ）")
makeToggle("RGBずれ 有効", CFG.rgbEnabled, function(v) CFG.rgbEnabled = v end)
makeSlider("ずれ量(px)", 0, 30, CFG.rgbOffset, function(v) CFG.rgbOffset = v end)  -- ★ 30に拡張
makeSlider("ずれ速度", 0, 5, CFG.rgbSpeed, function(v) CFG.rgbSpeed = v end, true)
makeToggle("パルス", CFG.rgbPulse, function(v) CFG.rgbPulse = v end)
makeToggle("垂直ずれ", CFG.rgbVertical, function(v) CFG.rgbVertical = v end)
makeSlider("垂直ずれ量(px)", 0, 30, CFG.rgbVerticalOffset, function(v) CFG.rgbVerticalOffset = v end)

makeSection("★3D形状RGB分離（重い）")
makeToggle("3D形状RGB分離 有効", CFG.rgbGeometryEnabled, function(v)
    CFG.rgbGeometryEnabled = v
    if not v then cleanupRGBHighlights() end
end)
makeSlider("形状ずれ量", 0, 1, CFG.rgbGeometryOffset, function(v) CFG.rgbGeometryOffset = v end, true)
makeSlider("更新レート(秒)", 0.02, 0.3, CFG.rgbGeometryUpdateRate, function(v) CFG.rgbGeometryUpdateRate = v end, true)

makeSection("★ランダムピクセルノイズ")
makeToggle("ピクセルノイズ 有効", CFG.pixelNoiseEnabled, function(v) CFG.pixelNoiseEnabled = v end)
makeSlider("ピクセル数", 10, 3000, CFG.pixelCount, function(v)   -- ★ 3000に拡張
    CFG.pixelCount = math.floor(v)
end)
makeSlider("ピクセル最小サイズ", 1, 10, CFG.pixelMinSize, function(v) CFG.pixelMinSize = math.floor(v) end)
makeSlider("ピクセル最大サイズ", 1, 20, CFG.pixelMaxSize, function(v) CFG.pixelMaxSize = math.floor(v) end)
makeSlider("ピクセル透明度(%)", 0, 100, CFG.pixelAlpha * 100, function(v) CFG.pixelAlpha = v / 100 end, true)
makeSlider("更新レート(秒)", 0.01, 0.3, CFG.pixelRefreshRate, function(v) CFG.pixelRefreshRate = v end, true)
makeToggle("多色ピクセル", CFG.pixelColorful, function(v) CFG.pixelColorful = v end)

makeSection("ノイズ / 走査線")
makeToggle("走査線 有効", CFG.scanEnabled, function(v)
    CFG.scanEnabled = v
    if refs.scan then refs.scan.Visible = v end
end)
makeSlider("走査線 濃度(%)", 0, 100, CFG.scanDensity, function(v)
    CFG.scanDensity = v
    if refs.scan then refs.scan.ImageTransparency = 1 - v/100 end
end)
makeToggle("ピクセルグリッド", CFG.gridEnabled, function(v)
    CFG.gridEnabled = v
    if refs.grid then refs.grid.Visible = v end
end)
makeSlider("グリッド強度(%)", 0, 100, CFG.gridDensity, function(v)
    CFG.gridDensity = v
    if refs.grid then refs.grid.ImageTransparency = 1 - v/100 end
end)
makeSlider("ヴィネット強度(%)", 0, 100, CFG.vignetteDensity, function(v)
    CFG.vignetteDensity = v
    if refs.vignette then refs.vignette.ImageTransparency = 1 - v/100 end
end)

makeSection("★ブラー / ブルーム")
makeToggle("ブラー 有効", CFG.blurEnabled, function(v) CFG.blurEnabled = v end)
makeSlider("ブラー量", 0, 56, CFG.blurAmount, function(v)   -- ★ 56に拡張
    CFG.blurAmount = v
    for i = 1, 3 do
        local b = Lighting:FindFirstChild("UncannyBlur" .. i)
        if b then b.Size = v / i end
    end
end)
makeSlider("ブラーレイヤー数", 1, 3, CFG.blurLayers, function(v)
    CFG.blurLayers = math.floor(v)
    if CFG.enabled then disableShader() task.wait(0.05) enableShader() end
end)
makeSlider("ブルーム強度", 0, 10, CFG.bloomIntensity, function(v)  -- ★ 10に拡張
    CFG.bloomIntensity = v
    local b = Lighting:FindFirstChild("UncannyBloom")
    if b then b.Intensity = v end
end, true)

makeSection("カメラ演出")
makeToggle("カメラシェイク", CFG.shakeEnabled, function(v) CFG.shakeEnabled = v end)
makeSlider("シェイク量", 0, 5, CFG.shakeAmount, function(v) CFG.shakeAmount = v end, true)
makeSlider("シェイク速度", 1, 100, CFG.shakeSpeed, function(v) CFG.shakeSpeed = v end)
makeToggle("カメラの傾き", CFG.tiltEnabled, function(v) CFG.tiltEnabled = v end)
makeSlider("傾き角度(度)", 0, 45, CFG.tiltAmount, function(v) CFG.tiltAmount = v end, true)

makeSection("VHS / グリッチ")
makeToggle("VHSジャンプ", CFG.vhsEnabled, function(v) CFG.vhsEnabled = v end)
makeSlider("発生確率(‰)", 0, 500, CFG.vhsChance * 1000, function(v) CFG.vhsChance = v / 1000 end, true)
makeSlider("ジャンプ量(px)", 0, 200, CFG.vhsAmount, function(v) CFG.vhsAmount = v end)
makeToggle("フリッカー", CFG.flickerEnabled, function(v) CFG.flickerEnabled = v end)
makeSlider("フリッカー幅", 0, 1, CFG.flickerAmount, function(v) CFG.flickerAmount = v end, true)
makeSlider("フリッカー速度", 1, 100, CFG.flickerSpeed, function(v) CFG.flickerSpeed = v end)

makeSection("演出系")
makeToggle("ダメージ赤フラッシュ", CFG.damageFlashEnabled, function(v) CFG.damageFlashEnabled = v end)
makeSlider("赤フラッシュ強度", 0, 1, CFG.damageFlashAmount, function(v) CFG.damageFlashAmount = v end, true)
makeToggle("死亡時巻き戻し", CFG.rewindEnabled, function(v) CFG.rewindEnabled = v end)
makeSlider("巻き戻し秒数", 0.5, 10, CFG.rewindDuration, function(v) CFG.rewindDuration = v end, true)
makeToggle("低FPS風カクつき", CFG.stutterEnabled, function(v) CFG.stutterEnabled = v end)
makeSlider("カクつき発生率(‰)", 0, 1000, CFG.stutterChance * 1000, function(v) CFG.stutterChance = v / 1000 end, true)
makeToggle("残像フレーム", CFG.ghostFrameEnabled, function(v) CFG.ghostFrameEnabled = v end)
makeSlider("残像強度", 0, 1, CFG.ghostFrameAmount, function(v) CFG.ghostFrameAmount = v end, true)
makeToggle("画面端の脈動", CFG.borderPulseEnabled, function(v)
    CFG.borderPulseEnabled = v
    if refs.borderPulse then refs.borderPulse.Visible = v end
end)
makeSlider("脈動強度", 0, 1, CFG.borderPulseAmount, function(v) CFG.borderPulseAmount = v end, true)

makeSection("フィルム枠 / レンズ")
makeToggle("フィルム枠 有効", CFG.filmFrameEnabled, function(v)
    CFG.filmFrameEnabled = v
    if refs.filmFrame then refs.filmFrame.Visible = v end
end)
makeButton("スタイル: 8mm（上下10%）", function()
    if refs.topBar then refs.topBar.Size = UDim2.new(1, 0, 0.1, 0) end
    if refs.bottomBar then refs.bottomBar.Size = UDim2.new(1, 0, 0.1, 0) refs.bottomBar.Position = UDim2.new(0, 0, 0.9, 0) end
end)
makeButton("スタイル: 16mm（上下5%）", function()
    if refs.topBar then refs.topBar.Size = UDim2.new(1, 0, 0.05, 0) end
    if refs.bottomBar then refs.bottomBar.Size = UDim2.new(1, 0, 0.05, 0) refs.bottomBar.Position = UDim2.new(0, 0, 0.95, 0) end
end)
makeButton("スタイル: VHS（上下3%）", function()
    if refs.topBar then refs.topBar.Size = UDim2.new(1, 0, 0.03, 0) end
    if refs.bottomBar then refs.bottomBar.Size = UDim2.new(1, 0, 0.03, 0) refs.bottomBar.Position = UDim2.new(0, 0, 0.97, 0) end
end)
makeToggle("レンズフレア", CFG.lensFlareEnabled, function(v)
    CFG.lensFlareEnabled = v
    if refs.flare then refs.flare.Visible = v end
end)
makeSlider("フレア透明度(%)", 0, 100, CFG.lensFlareOpacity * 100, function(v)
    CFG.lensFlareOpacity = v / 100
    if refs.flare then refs.flare.ImageTransparency = 1 - CFG.lensFlareOpacity end
end)
makeToggle("レンズ汚れ", CFG.lensDirtEnabled, function(v)
    CFG.lensDirtEnabled = v
    if refs.lens then refs.lens.Visible = v end
end)
makeSlider("レンズ汚れ濃度(%)", 0, 100, CFG.lensDirtDensity, function(v)
    CFG.lensDirtDensity = v
    if refs.lens then refs.lens.ImageTransparency = 1 - v/100 end
end)

makeSection("HUD")
makeToggle("REC表示", CFG.recHudEnabled, function(v)
    CFG.recHudEnabled = v
    if refs.recHud then refs.recHud.Visible = v end
end)
makeToggle("REC点滅", CFG.recBlink, function(v) CFG.recBlink = v end)
makeToggle("RECドット ランダム点滅", CFG.recordingDotJitter, function(v) CFG.recordingDotJitter = v end)
makeToggle("タイムスタンプ", CFG.timestampEnabled, function(v)
    CFG.timestampEnabled = v
    if refs.timestamp then refs.timestamp.Visible = v end
end)

makeSection("音響")
makeToggle("音響 有効", CFG.audioEnabled, function(v)
    CFG.audioEnabled = v
    setupAudio()
end)
makeSlider("音量(%)", 0, 100, CFG.audioVolume * 100, function(v)
    CFG.audioVolume = v / 100
    if filmSound then filmSound.Volume = CFG.audioVolume end
    if humSound then humSound.Volume = CFG.audioVolume * 0.6 end
end)

makeSection("プリセット")
makeButton("▶ 標準不気味", function()
    CFG.darkLevel = 0.25 CFG.brightness = 1.0 CFG.exposure = 0
    CFG.saturation = -0.2 CFG.rgbOffset = 6 CFG.pixelCount = 400
    CFG.scanDensity = 25 CFG.gridDensity = 15 CFG.blurAmount = 4
    CFG.shakeEnabled = false CFG.tiltEnabled = false
    CFG.vhsEnabled = false CFG.flickerEnabled = false
    CFG.rgbGeometryEnabled = false CFG.pixelColorful = false
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("▶ VHSホラー", function()
    CFG.darkLevel = 0.45 CFG.brightness = 0.7 CFG.exposure = -0.4
    CFG.saturation = -0.4 CFG.rgbOffset = 10 CFG.rgbVerticalOffset = 6
    CFG.pixelCount = 800 CFG.pixelAlpha = 0.8
    CFG.scanDensity = 35 CFG.gridDensity = 25 CFG.blurAmount = 6
    CFG.shakeEnabled = true CFG.shakeAmount = 0.4
    CFG.tiltEnabled = true CFG.tiltAmount = 3
    CFG.vhsEnabled = true CFG.vhsChance = 0.03 CFG.flickerEnabled = true
    CFG.filmFrameEnabled = true CFG.lensFlareEnabled = true CFG.audioEnabled = true
    CFG.rgbGeometryEnabled = false
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("▶ ホラー映画", function()
    CFG.darkLevel = 0.5 CFG.brightness = 0.5 CFG.exposure = -0.6
    CFG.saturation = -0.6 CFG.rgbOffset = 4
    CFG.pixelCount = 200 CFG.pixelAlpha = 0.5
    CFG.scanDensity = 15 CFG.gridDensity = 8 CFG.blurAmount = 8
    CFG.shakeEnabled = true CFG.shakeAmount = 0.2
    CFG.tiltEnabled = true CFG.tiltAmount = 5
    CFG.flickerEnabled = true CFG.filmFrameEnabled = true CFG.audioEnabled = true
    CFG.rgbGeometryEnabled = false
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("▶ セピア古写真", function()
    CFG.darkLevel = 0.3 CFG.brightness = 1.2 CFG.exposure = 0
    CFG.saturation = -0.8 CFG.rgbOffset = 2
    CFG.pixelCount = 600 CFG.pixelAlpha = 0.6
    CFG.scanDensity = 15 CFG.gridDensity = 20 CFG.blurAmount = 3
    CFG.tiltEnabled = true CFG.tiltAmount = 1.5
    CFG.filmFrameEnabled = true CFG.lensDirtEnabled = true
    CFG.rgbGeometryEnabled = false
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("▶ サイバーグリッチ", function()
    CFG.darkLevel = 0.35 CFG.brightness = 0.9 CFG.exposure = -0.2
    CFG.saturation = 0.2 CFG.rgbOffset = 14 CFG.rgbVertical = true
    CFG.rgbVerticalOffset = 10 CFG.pixelCount = 1500 CFG.pixelColorful = true
    CFG.pixelAlpha = 0.9 CFG.scanDensity = 40 CFG.gridDensity = 25
    CFG.blurAmount = 2 CFG.vhsEnabled = true CFG.vhsChance = 0.05
    CFG.flickerEnabled = true CFG.rgbGeometryEnabled = true
    CFG.rgbGeometryOffset = 0.3
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("▶ 明るい昼（★ブライト）", function()
    CFG.darkLevel = 0 CFG.brightness = 3.5 CFG.exposure = 1.5
    CFG.saturation = 0 CFG.rgbOffset = 3 CFG.pixelCount = 200
    CFG.pixelAlpha = 0.5 CFG.scanDensity = 10 CFG.gridDensity = 5
    CFG.blurAmount = 2 CFG.shakeEnabled = false CFG.tiltEnabled = false
    CFG.vhsEnabled = false CFG.flickerEnabled = false
    CFG.ambient = Color3.fromRGB(140, 140, 150)
    CFG.outdoorAmbient = Color3.fromRGB(120, 120, 130)
    Lighting.Ambient = CFG.ambient
    Lighting.OutdoorAmbient = CFG.outdoorAmbient
    CFG.rgbGeometryEnabled = false
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("▶ 完全真っ昼（視認性最大）", function()
    CFG.darkLevel = 0 CFG.brightness = 8 CFG.exposure = 4
    CFG.saturation = 0.2 CFG.rgbOffset = 1 CFG.pixelCount = 50
    CFG.pixelAlpha = 0.3 CFG.scanDensity = 0 CFG.gridDensity = 0
    CFG.blurAmount = 0 CFG.shakeEnabled = false CFG.tiltEnabled = false
    CFG.vhsEnabled = false CFG.flickerEnabled = false
    CFG.ambient = Color3.fromRGB(200, 200, 210)
    CFG.outdoorAmbient = Color3.fromRGB(180, 180, 190)
    Lighting.Ambient = CFG.ambient
    Lighting.OutdoorAmbient = CFG.outdoorAmbient
    CFG.rgbGeometryEnabled = false
    if CFG.enabled then disableShader() task.wait(0.1) enableShader() end
end)
makeButton("■ 完全解除（元に戻す）", function()
    disableShader()
end)

makeSection("テスト")
makeButton("ダメージフラッシュ テスト", function() triggerDamageFlash() end)
makeButton("巻き戻し テスト", function() triggerRewind() end)
makeButton("残像 テスト", function() triggerGhost() end)

-- ==========================================
-- 最小化
-- ==========================================
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 280, 0, 28)
        MinimizeBtn.Text = "+"
        ContentScroll.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 280, 0, 560)
        MinimizeBtn.Text = "_"
        ContentScroll.Visible = true
    end
end)

-- ドラッグ
local function makeDraggable(gui, handle)
    local dragging, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            ds = i.Position
            sp = gui.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            gui.Position = UDim2.new(
                0,
                math.clamp(sp.X.Offset + d.X, 0, Camera.ViewportSize.X - gui.AbsoluteSize.X),
                0,
                math.clamp(sp.Y.Offset + d.Y, 0, Camera.ViewportSize.Y - gui.AbsoluteSize.Y)
            )
        end
    end)
end
makeDraggable(MainFrame, TitleBar)
