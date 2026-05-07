-- ============================================================================
-- main.lua - 主入口，负责初始化、游戏状态和主界面（含暂停功能）
-- ============================================================================

-- 简单的定时器系统
Timer = {
    tasks = {}
}

function Timer.after(delay, callback)
    table.insert(Timer.tasks, {
        time = delay,
        callback = callback
    })
end

function Timer.update(dt)
    for i = #Timer.tasks, 1, -1 do
        local task = Timer.tasks[i]
        task.time = task.time - dt
        if task.time <= 0 then
            task.callback()
            table.remove(Timer.tasks, i)
        end
    end
end

-- 占位函数（将在其他模块中定义）
applyDifficulty = applyDifficulty or function() end
startWave = startWave or function() end
updateWaveAndEnemies = updateWaveAndEnemies or function() end
drawEnemies = drawEnemies or function() end
updateEnemyBullets = updateEnemyBullets or function() end
updateWeaponReload = updateWeaponReload or function() end
shootWeapon = shootWeapon or function() end
updateBullets = updateBullets or function() end
updateCooldowns = updateCooldowns or function() end
handleWeaponKeys = handleWeaponKeys or function() end
getCurrentWeapon = getCurrentWeapon or function() return nil end
loadWeaponSounds = loadWeaponSounds or function() end
applyBagToWeapons = applyBagToWeapons or function() end
reloadWeapon = reloadWeapon or function() end

-- 调试函数声明
toggleDebugMode = function() print("WARNING: toggleDebugMode not loaded yet") end
handleDebugKeys = function(key) print("WARNING: handleDebugKeys not loaded yet, key=" .. key) end
drawDebugInfo = function() end

-- 加载其他模块（顺序重要）
require("shop")
require("weapon")
require("enemy")
require("datastore")
require("bestiary")
require("inventory")
require("info")
require("ability")
require("throwable")

-- ===== 全局变量定义 =====
-- 窗口尺寸
winW = 800
winH = 600

-- 移动端检测
isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

-- 游戏状态管理
gameState = "menu"          -- "menu", "difficulty", "playing", "inventory", "bestiary", "shop"
difficultySelect = false
selectedDifficulty = "easy" -- "easy", "medium", "hard", "endless", "bossrush"

-- 比特系统（钱包和成就）
bits = 0
maxBits = 0

-- 暂停状态
paused = false               -- <-- 新增

-- 初始地图边界（1000x1000，中心在(0,0)）
mapWidth = 1000
mapHeight = 1000
mapMinX = -mapWidth/2
mapMaxX = mapWidth/2
mapMinY = -mapHeight/2
mapMaxY = mapHeight/2

-- 障碍物（仅在地图扩展后启用）
obstacle = { x = 0, y = 0, w = 300, h = 300 }
mapExpanded = false          -- 标记地图是否已扩展至1750x1750

-- 玩家数据
player = {
    x = 0, y = 0,
    RunSystem = {
        Stamina = 100,
        StaminaMax = 100,
        Runspeed = 250,
        Walkspeed = 125
    },
    HealthSystem = {
        Health = 100,
        HealthMax = 100
    },
    speed = 150,
    isDead = false,
    deathTimer = 0,
    blinkTimer = 0,

    weapon = {                    -- 当前装备的武器（根据槽位切换）
        equipped = false,
        type = nil
    },
    
    -- 武器槽：1-4号槽
    weaponSlots = { nil, nil, nil, nil },
    
    -- 噬魂充能（需要500点才能发射）
    soulReaperCharge = 0,
    
    -- 激光枪充能和最后射击时间
    laserGunCharge = 50,
    lastLaserShotTime = 0,
    
    weaponStates = {
        pistol = {
            name = "Pistol",
            damage = 10,
            bulletSpeed = 800,
            bulletSize = 5,
            cooldownMax = 0.3,
            ammo = 7,
            maxAmmo = 7,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 2,
            distance = 15,
            size = 15,
            color = {1,1,1},
            shootSoundPath = "sound/pistol_shot.wav",
            reloadSoundPath = "sound/pistol_reload.wav",
            pierce = false
        },
        rifle = {
            name = "Rifle",
            damage = 6,
            bulletSpeed = 1500,
            bulletSize = 7,
            cooldownMax = 0.1,
            ammo = 35,
            maxAmmo = 35,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 3.4,
            distance = 20,
            size = 20,
            color = {1,0.8,0},
            shootSoundPath = "sound/rifle_shot.wav",
            reloadSoundPath = "sound/rifle_reload.wav",
            pierce = false
        },
        sniper = {
            name = "Sniper",
            damage = 40,
            bulletSpeed = 3000,
            bulletSize = 10,
            cooldownMax = 1.0,
            ammo = 5,
            maxAmmo = 5,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 4.0,
            distance = 25,
            size = 25,
            color = {0.5,0.8,1},
            shootSoundPath = "sound/sniper_shot.mp3",
            reloadSoundPath = "sound/sniper_reload.mp3",
            pierce = false
        },
        soulreaper = {
            name = "Soul Reaper",
            damage = 1000,
            bulletSpeed = 3000,
            bulletSize = 20,
            cooldownMax = 5.0,
            ammo = 1,
            maxAmmo = 1,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 5.0,
            distance = 30,
            size = 30,
            color = {0.5, 0, 0.5},
            shootSoundPath = "sound/soulreaper_shot.wav",
            reloadSoundPath = "sound/soulreaper_reload.wav",
            pierce = false,
            maxPierce = 0,
            requiresCharge = true
        },
        lasergun = {
            name = "Laser Gun",
            damage = 15,
            bulletSpeed = 0,
            bulletSize = 5,
            cooldownMax = 0.1,
            ammo = 50,
            maxAmmo = 50,
            maxCharge = 50,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 0,
            distance = 30,
            size = 20,
            color = {1, 0, 0},
            shootSoundPath = "sound/lasergun_shot.wav",
            reloadSoundPath = "",
            pierce = false,
            isLaser = true
        },
        feast = {
            name = "Feast",
            damage = 25,
            bulletSpeed = 100,
            bulletSize = 30,
            cooldownMax = 1.5,
            ammo = 1,
            maxAmmo = 1,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 4.0,
            distance = 30,
            size = 35,
            color = {1, 0.5, 0},
            shootSoundPath = "sound/feast_shot.mp3",
            reloadSoundPath = "sound/feast_reload.ogg",
            pierce = false,
            isFeast = true,
            feastDamagePerSecond = 25,
            feastExplosionDamage = 1000,
            feastDuration = 5.0,
            feastRadius = 80
        },

        lifedrain = {
            name = "Life Drain",
            damage = 10,
            bulletSpeed = 1750,
            bulletSize = 8,
            cooldownMax = 1.0,
            ammo = 30,
            maxAmmo = 30,
            isReloading = false,
            reloadTimer = 0,
            reloadTime = 4.0,
            distance = 20,
            size = 20,
            color = {1, 0.2, 0.2},
            shootSoundPath = "sound/lifedrain_shot.wav",
            reloadSoundPath = "sound/lifedrain_reload.wav",
            pierce = false,
            isLifedrain = true,
            burstCount = 3,
            burstDelay = 0.05,
            permanentDamageBonus = 0,
            maxHealthBonusCounter = 0
        }
    },

    Bag = {
        hasPistol = true,
        hasRifle = false,
        hasSniper = false,
        hasSoulReaper = false,
        hasLaserGun = false,
        hasFeast = false,
        hasLifedrain = false,
        pistolMods = { fastMag = false, extMag = false, damage = false },
        rifleMods = { fastMag = false, extMag = false, damage = false },
        sniperMods = { damage = false, pierce = false },
        soulReaperMods = { pierce = false, damage = false },
        laserGunMods = { capacity = false },
        feastMods = { dualCore = false, highExplosive = false },
        lifedrainMods = { extendedMag = false, soulNourish = false },
        characterMods = { speedWalk = false, speedRun = false }
    },
    -- 技能系统（Q/E/Z/X按键）
    abilities = {
        owned = {},
        activeSlots = { nil, nil, nil, nil },
        activeCooldowns = { 0, 0, 0, 0 },
        activeKeys = { "q", "e", "z", "x" },
        passiveSlots = { nil, nil },
        siphonActive = false,
        siphonTimer = 0,
        passive = {
            dragonslayer = false,
            bloodthirst = false,
            constantMotion = false
        }
    },
    
    -- 投掷物系统
    throwables = {
        owned = {},
        slots = { nil, nil, nil },
        charges = { 0, 0, 0 },
        lastUsedRound = { 0, 0, 0 }
    }
}

-- 杂项全局列表
trails = {}
staminaBar = { currentWidth = 0, targetWidth = 0, smoothSpeed = 8 }
healthBar = { currentWidth = 0, targetWidth = 0, smoothSpeed = 8 }
bullets = {}
sounds = {}
throwableFields = {}  -- 投掷物效果列表

-- 其他杂项
lastruntime = 0
staminaTimer = 0
recoveryDelayTimer = 0
canRecover = true
currentCooldown = 0
currentAngle = 0
openInfo = false
frameCounter = 0
frameTimes = {}

-- ===== 移动端触摸控制变量 =====
touchActive = false
touchX = 0
touchY = 0
autoShoot = false
-- 移动端UI按钮区域定义（屏幕坐标）
mobileButtons = {
    reload = { x = 0, y = 0, w = 60, h = 60, active = true },
    nextWeapon = { x = 0, y = 0, w = 60, h = 60, active = true },
    prevWeapon = { x = 0, y = 0, w = 60, h = 60, active = true },
}

-- ===== love.load =====
function love.load()
    print("Game loaded")

    -- 字体设置
    uiFont = love.graphics.newFont("fonts/Noto_Sans_SC/NotoSansSC-VariableFont_wght.ttf", 20)
    titleFont = love.graphics.newFont("fonts/Noto_Sans_SC/NotoSansSC-VariableFont_wght.ttf", 40)
    if not uiFont then
        uiFont = love.graphics.newFont(20)
        titleFont = love.graphics.newFont(40)
    end

    love.window.setTitle("Purge")
    love.window.setMode(winW, winH)

    -- 初始化各模块
    loadWeaponSounds()
    ShopSystem:init()
    AbilitySystem:init()
    ThrowableSystem:init()
    loadHighScore()
    applyBagToWeapons()

    if isMobile then
        print("Mobile device detected")
        -- 初始化移动端按钮位置（右下角）
        local w, h = love.graphics.getDimensions()
        local btnSize = 60
        local margin = 20
        mobileButtons.reload.x = w - btnSize - margin
        mobileButtons.reload.y = h - btnSize - margin
        mobileButtons.nextWeapon.x = w - btnSize*2 - margin*2
        mobileButtons.nextWeapon.y = h - btnSize - margin
        mobileButtons.prevWeapon.x = w - btnSize*3 - margin*3
        mobileButtons.prevWeapon.y = h - btnSize - margin
    end

    collectgarbage("setpause", 200)
    collectgarbage("setstepmul", 200)
end

-- ===== love.update =====
function love.update(dt)
    lastFrameTime = love.timer.getTime()
    
    Timer.update(dt)
    if gameState == "menu" or gameState == "difficulty" then return end

    if gameState == "playing" then
        if not paused then            -- <-- 新增：仅当未暂停时更新游戏逻辑
            updateGamePlaying(dt)
            ThrowableSystem:update(dt)
        end
    elseif gameState == "shop" then
        ShopSystem:update(dt)
        AbilitySystem:update(dt)
    end
    
    frameCounter = frameCounter + 1
    if frameCounter >= 60 then
        frameCounter = 0
        collectgarbage("step", 100)
    end
    
    local now = love.timer.getTime()
    local dt2 = now - lastFrameTime
    table.insert(frameTimes, dt2)
    if #frameTimes > 60 then
        table.remove(frameTimes, 1)
    end
end

function love.draw()
    if gameState == "menu" then
        drawMenu()
    elseif gameState == "difficulty" then
        drawDifficulty()
    elseif gameState == "playing" then
        drawGamePlaying()
        if isMobile then drawMobileUI() end
        -- 暂停菜单绘制（半透明遮罩 + 菜单）
        if paused then
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            drawPauseMenu()
        end
    elseif gameState == "inventory" then
        drawInventory()
    elseif gameState == "bestiary" then
        drawBestiary()
    elseif gameState == "shop" then
        ShopSystem:draw()
    end

    if drawDebugInfo then
        drawDebugInfo()
    end
end

-- ===== 菜单绘制 =====
function drawMenu()
    local w, h = love.graphics.getDimensions()
    local bw, bh, startY = 200, 50, h/2 - 100
    love.graphics.setBackgroundColor(0,0,0)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1)
    local tw = titleFont:getWidth("PURGE")
    love.graphics.print("PURGE", (w-tw)/2, 100)
    love.graphics.setFont(uiFont)
    local buttons = {
        { text = "Play", y = startY },
        { text = "Inventory", y = startY + 70 },
        { text = "Bestiary", y = startY + 140 },
        { text = "Shop", y = startY + 210 }
    }

    for i, btn in ipairs(buttons) do
        local x = (w - bw)/2
        local y = btn.y
        local mx, my = love.mouse.getPosition()
        local hover = not isMobile and mx >= x and mx <= x+bw and my >= y and my <= y+bh
        love.graphics.setColor(hover and 0.8 or 0.6, hover and 0.8 or 0.6, 1)
        love.graphics.rectangle("fill", x, y, bw, bh, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(btn.text, x, y + 5, bw, "center")
    end
    love.graphics.setColor(1,1,0)
    love.graphics.print("Bit: " .. maxBits, 10, 0)
end

function drawDifficulty()
    local w, h = love.graphics.getDimensions()
    local bw, bh, startY = 200, 50, h/2 - 120
    love.graphics.setBackgroundColor(0,0,0)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1)
    local tw = titleFont:getWidth("SELECT DIFFICULTY")
    love.graphics.print("SELECT DIFFICULTY", (w-tw)/2, 100)
    love.graphics.setFont(uiFont)
    local difficulties = {
        { text = "EASY", y = startY },
        { text = "MEDIUM", y = startY + 60 },
        { text = "HARD", y = startY + 120 },
        { text = "ENDLESS", y = startY + 180 },
        { text = "BOSS RUSH", y = startY + 240 }
    }
    for i, d in ipairs(difficulties) do
        local x = (w - bw)/2
        local y = d.y
        local mx, my = love.mouse.getPosition()
        local hover = not isMobile and mx >= x and mx <= x+bw and my >= y and my <= y+bh
        love.graphics.setColor(hover and 0.8 or 0.6, hover and 0.8 or 0.6, 1)
        love.graphics.rectangle("fill", x, y, bw, bh, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(d.text, x, y+5, bw, "center")
    end
    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.print("Press ESC to return", 10, h-30)
end

function drawInventory() handledrawInventory() end
function drawBestiary() handledrawBestiary() end

function drawGamePlaying()
    love.graphics.push()
    local w, h = love.graphics.getDimensions()
    love.graphics.translate(w/2 - player.x, h/2 - player.y)

    drawMapBoundary()

    -- 绘制玩家子弹
    for _, b in ipairs(bullets) do
        love.graphics.setColor(b.color)
        love.graphics.circle("fill", b.x, b.y, b.size)
    end

    -- 绘制激光
    if player.weapon.equipped and player.weapon.type == "lasergun" and not player.isDead then
        local wep = getCurrentWeapon()
        if wep then
            local mx, my = love.mouse.getPosition()
            local worldX = mx + player.x - w/2
            local worldY = my + player.y - h/2
            
            love.graphics.setColor(1, 0, 0, 0.5)
            love.graphics.setLineWidth(3)
            love.graphics.line(player.x + 10, player.y + 10, worldX, worldY)
            
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("fill", worldX, worldY, 5)
        end
    end

    -- 绘制敌人子弹
    for _, b in ipairs(enemyBullets) do
        love.graphics.setColor(b.color)
        love.graphics.circle("fill", b.x, b.y, b.size)
    end

    drawEnemies()

    -- 绘制投掷物效果（世界坐标）
    ThrowableSystem:draw()

    -- 绘制玩家残影
    for _, t in ipairs(trails) do
        love.graphics.setColor(1,1,1, 1 - t.time/t.maxTime)
        love.graphics.rectangle("line", t.x, t.y, 20, 20)
    end

    -- 绘制玩家
    if player.isDead then
        if player.blinkTimer < 0.1 then
            love.graphics.setColor(1,0,0,0.7)
        else
            love.graphics.setColor(1,1,1,0.3)
        end
        love.graphics.setLineWidth(4)
    else
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", player.x, player.y, 20, 20)

    -- 绘制武器
    if player.weapon.equipped and not player.isDead then
        local wep = getCurrentWeapon()
        if wep and player.weapon.type ~= "lasergun" then
            local wx = player.x + 10 + math.cos(currentAngle) * wep.distance
            local wy = player.y + 10 + math.sin(currentAngle) * wep.distance
            love.graphics.push()
            love.graphics.translate(wx, wy)
            love.graphics.rotate(currentAngle)
            love.graphics.setColor(wep.color)
            if player.weapon.type == "rifle" then
                love.graphics.rectangle("fill", 0, -4, wep.size, 8)
                love.graphics.circle("fill", -3, 0, 5)
                love.graphics.setColor(0.5,0.5,0.5)
                love.graphics.circle("fill", 2, 0, 2)
            elseif player.weapon.type == "sniper" then
                love.graphics.rectangle("fill", 0, -5, wep.size+5, 10)
                love.graphics.circle("fill", -4, 0, 6)
                love.graphics.setColor(0.5,0.5,0.5)
                love.graphics.circle("fill", 5, 0, 2)
            elseif player.weapon.type == "soulreaper" then
                love.graphics.setColor(0.5, 0, 0.5)
                love.graphics.rectangle("fill", 0, -5, wep.size, 10)
                love.graphics.circle("fill", -3, 0, 6)
                love.graphics.setColor(1, 1, 0)
                love.graphics.circle("fill", wep.size/2, 0, 3)
            elseif player.weapon.type == "feast" then
                love.graphics.setColor(1, 0.5, 0)
                love.graphics.rectangle("fill", 0, -8, wep.size+5, 16)
                love.graphics.circle("fill", -5, 0, 8)
                love.graphics.setColor(1, 1, 0)
                love.graphics.circle("fill", wep.size/2, 0, 4)
            elseif player.weapon.type == "lifedrain" then
                love.graphics.setColor(1, 0.2, 0.2)
                love.graphics.rectangle("fill", 0, -5, wep.size, 10)
                love.graphics.circle("fill", -4, 0, 6)
                love.graphics.setColor(1, 0.5, 0.5)
                love.graphics.circle("fill", 4, 0, 2)
            else
                love.graphics.rectangle("fill", 0, -3, wep.size, 6)
                love.graphics.circle("fill", -2, 0, 4)
            end
            love.graphics.pop()
        end
    end

    love.graphics.pop()

    -- ===== UI 绘制（屏幕坐标）=====
    love.graphics.setFont(uiFont)
    local margin = 30
    local healthBarY = love.graphics.getHeight() - 35*2 - 10 - margin
    drawHealthBar(margin, healthBarY)
    drawStaminaBar(margin, love.graphics.getHeight() - 35 - margin)

    love.graphics.setColor(1,1,1)
    if wave.isActive then
        love.graphics.print("WAVE " .. wave.current .. (wave.isBossWave and " BOSS" or ""), margin, 20)
        love.graphics.print("Enemies: " .. #enemies .. "/" .. wave.enemiesToSpawn, margin, 45)
    else
        if wave.current <= wave.maxWaves[wave.mode] then
            love.graphics.print("NEXT WAVE: " .. math.ceil(wave.waveTimer) .. "s", margin, 20)
        else
            love.graphics.print("GAME COMPLETE!", margin, 20)
        end
    end
    love.graphics.setColor(0.5,0.5,1)
    love.graphics.print("Map: " .. mapWidth .. "x" .. mapHeight, margin, 70)

    love.graphics.setFont(love.graphics.newFont(30))
    love.graphics.setColor(1,1,0)
    love.graphics.print("Bits: " .. bits, love.graphics.getWidth()-250, 20)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.print("Wallet: " .. maxBits, love.graphics.getWidth()-250, 60)

    -- 绘制技能和投掷物UI
    drawAbilityUI()
    drawThrowableUI()

    -- ===== 武器UI显示 =====
    local wep = getCurrentWeapon()
    if wep then
        love.graphics.setColor(wep.color)
        love.graphics.print(wep.name .. " equipped", margin, love.graphics.getHeight()-260)
        
        if player.weapon.type == "soulreaper" then
            love.graphics.setColor(1, 1, 0)
            love.graphics.print("Soul Charge: " .. math.floor(player.soulReaperCharge) .. "/500", margin, love.graphics.getHeight()-230)
            if player.soulReaperCharge < 500 then
                love.graphics.setColor(1, 0, 0)
                love.graphics.print("NOT READY", margin, love.graphics.getHeight()-200)
            else
                love.graphics.setColor(0, 1, 0)
                love.graphics.print("READY TO FIRE", margin, love.graphics.getHeight()-200)
            end
            
        elseif player.weapon.type == "lasergun" then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("Laser Charge: " .. math.floor(player.laserGunCharge) .. "/" .. wep.maxCharge, margin, love.graphics.getHeight()-230)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print("Auto-recharges after 4s", margin, love.graphics.getHeight()-200)
            
        elseif player.weapon.type == "feast" then
            love.graphics.setColor(1, 0.5, 0)
            love.graphics.print("Feast Ammo: " .. math.floor(wep.ammo) .. "/" .. math.floor(wep.maxAmmo), margin, love.graphics.getHeight()-230)
            if wep.isReloading then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("RELOADING... " .. string.format("%.1f", wep.reloadTimer) .. "s", margin, love.graphics.getHeight()-200)
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print("Attracts enemies | Explodes after 5s", margin, love.graphics.getHeight()-200)
            end
            
        elseif player.weapon.type == "lifedrain" then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.print("Life Drain Ammo: " .. math.floor(wep.ammo) .. "/" .. math.floor(wep.maxAmmo), margin, love.graphics.getHeight()-230)
            if wep.isReloading then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("RELOADING... " .. string.format("%.1f", wep.reloadTimer) .. "s", margin, love.graphics.getHeight()-200)
            else
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print("Permanent DMG: +" .. (player.lifedrainDamageBonus or 0), margin, love.graphics.getHeight()-200)
            end
            
        else
            -- 普通武器（手枪、步枪、狙击）
            if wep.isReloading then
                love.graphics.setColor(1, 1, 0)
                love.graphics.print("RELOADING... " .. string.format("%.1f", wep.reloadTimer) .. "s", margin, love.graphics.getHeight()-230)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("Ammo: " .. math.floor(wep.ammo) .. "/" .. math.floor(wep.maxAmmo), margin, love.graphics.getHeight()-230)
            end
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print("Press R to reload", margin, love.graphics.getHeight()-200)
        end
    else
        love.graphics.setColor(0.5,0.5,0.5)
        love.graphics.print("Press 1-4 for weapons", margin, love.graphics.getHeight()-260)
        love.graphics.print("R to reload", margin, love.graphics.getHeight()-230)
    end

    if player.isDead then
        love.graphics.setColor(1,0,0)
        love.graphics.setFont(love.graphics.newFont(30))
        local tw = love.graphics.getFont():getWidth("YOU DIED")
        love.graphics.print("YOU DIED", (love.graphics.getWidth()-tw)/2, love.graphics.getHeight()/2-70)
        love.graphics.setFont(love.graphics.newFont(20))
        local rw = love.graphics.getFont():getWidth("Press X to restart")
        love.graphics.print("Press X to restart", (love.graphics.getWidth()-rw)/2, love.graphics.getHeight()/2+10)
        love.graphics.setFont(uiFont)
    end

    drawInfoPanel()
    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.print("Press M for menu", 10, love.graphics.getHeight()-30)
end

-- 绘制技能UI
function drawAbilityUI()
    local screenW, screenH = love.graphics.getDimensions()
    local slotSize = 40
    local spacing = 10
    local padding = 20
    
    local totalActiveWidth = slotSize * 4 + spacing * 3
    local totalPassiveWidth = slotSize * 2 + spacing
    local maxWidth = math.max(totalActiveWidth, totalPassiveWidth)
    
    local x = screenW - maxWidth - padding - 20
    local y = screenH - 200
    
    -- 主动技能槽位
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", x - 10, y - 10, totalActiveWidth + 20, slotSize + 20, 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(uiFont)
    love.graphics.print("主动技能 (Q/E/Z/X)", x, y - 25)
    
    local keys = {"Q", "E", "Z", "X"}
    for i = 1, 4 do
        local slotX = x + (i-1) * (slotSize + spacing)
        local abilityId = player.abilities.activeSlots[i]
        local cooldown = player.abilities.activeCooldowns[i]
        
        if abilityId then
            local ability = AbilitySystem.abilities[abilityId]
            love.graphics.setColor(ability.color[1], ability.color[2], ability.color[3], 0.7)
        else
            love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", slotX, y, slotSize, slotSize, 5)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", slotX, y, slotSize, slotSize, 5)
        
        if abilityId then
            local ability = AbilitySystem.abilities[abilityId]
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print(ability.icon, slotX + 10, y + 8)
            
            if cooldown > 0 then
                local percent = cooldown / ability.cooldown
                love.graphics.setColor(0, 0, 0, 0.5)
                love.graphics.rectangle("fill", slotX, y, slotSize, slotSize * percent, 5)
                love.graphics.setColor(1, 1, 0)
                love.graphics.setFont(love.graphics.newFont(16))
                love.graphics.print(math.ceil(cooldown), slotX + 12, y + 12)
            end
            
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print(keys[i], slotX + 15, y - 15)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print("?", slotX + 15, y + 8)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print(keys[i], slotX + 15, y - 15)
        end
    end
    
    -- 被动技能槽位
    y = y + slotSize + 30
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", x - 10, y - 10, totalPassiveWidth + 20, slotSize + 20, 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(uiFont)
    love.graphics.print("被动技能", x, y - 25)
    
    for i = 1, 2 do
        local slotX = x + (i-1) * (slotSize + spacing)
        local abilityId = player.abilities.passiveSlots[i]
        
        if abilityId then
            local ability = AbilitySystem.abilities[abilityId]
            love.graphics.setColor(ability.color[1], ability.color[2], ability.color[3], 0.7)
        else
            love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", slotX, y, slotSize, slotSize, 5)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", slotX, y, slotSize, slotSize, 5)
        
        if abilityId then
            local ability = AbilitySystem.abilities[abilityId]
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print(ability.icon, slotX + 10, y + 8)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print("P" .. i, slotX + 15, y - 15)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print("?", slotX + 15, y + 8)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print("P" .. i, slotX + 15, y - 15)
        end
    end
    
    if player.abilities.siphonActive then
        love.graphics.setColor(0.5, 0, 1, 0.5 + 0.5 * math.sin(love.timer.getTime() * 5))
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.print("虹吸激活: " .. math.ceil(player.abilities.siphonTimer) .. "s", x, y + 50)
    end
    
    love.graphics.setFont(uiFont)
end

-- ===== 绘制投掷物UI =====
function drawThrowableUI()
    local screenW, screenH = love.graphics.getDimensions()
    local slotSize = 40
    local spacing = 10
    local padding = 20
    
    local totalWidth = slotSize * 3 + spacing * 2
    local x = screenW - totalWidth - padding - 20
    local y = screenH - 270
    
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    love.graphics.rectangle("fill", x - 10, y - 10, totalWidth + 20, slotSize + 20, 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(uiFont)
    love.graphics.print("投掷物 (5-7)", x, y - 25)
    
    for i = 1, 3 do
        local slotX = x + (i-1) * (slotSize + spacing)
        local throwableId = player.throwables.slots[i]
        local charge = player.throwables.charges[i]
        
        if throwableId then
            local throwable = ThrowableSystem.throwables[throwableId]
            love.graphics.setColor(throwable.color[1], throwable.color[2], throwable.color[3], 0.7)
        else
            love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        end
        love.graphics.rectangle("fill", slotX, y, slotSize, slotSize, 5)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", slotX, y, slotSize, slotSize, 5)
        
        if throwableId then
            local throwable = ThrowableSystem.throwables[throwableId]
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print(throwable.icon, slotX + 10, y + 8)
            
            if charge > 0 then
                love.graphics.setColor(0, 1, 0)
                love.graphics.circle("fill", slotX + slotSize - 8, y + 8, 4)
            else
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle("fill", slotX + slotSize - 8, y + 8, 4)
            end
            
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print(i + 4, slotX + 15, y - 15)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print("?", slotX + 15, y + 8)
            
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.print(i + 4, slotX + 15, y - 15)
        end
    end
    
    love.graphics.setFont(uiFont)
end

-- ===== 移动端UI绘制 =====
function drawMobileUI()
    -- 绘制虚拟按钮（重装、武器切换）
    local btn = mobileButtons
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.circle("fill", btn.reload.x + btn.reload.w/2, btn.reload.y + btn.reload.h/2, btn.reload.w/2)
    love.graphics.setColor(1,1,1)
    love.graphics.print("R", btn.reload.x + btn.reload.w/2 - 8, btn.reload.y + btn.reload.h/2 - 10)
    
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.circle("fill", btn.nextWeapon.x + btn.nextWeapon.w/2, btn.nextWeapon.y + btn.nextWeapon.h/2, btn.nextWeapon.w/2)
    love.graphics.setColor(1,1,1)
    love.graphics.print(">", btn.nextWeapon.x + btn.nextWeapon.w/2 - 5, btn.nextWeapon.y + btn.nextWeapon.h/2 - 10)
    
    love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
    love.graphics.circle("fill", btn.prevWeapon.x + btn.prevWeapon.w/2, btn.prevWeapon.y + btn.prevWeapon.h/2, btn.prevWeapon.w/2)
    love.graphics.setColor(1,1,1)
    love.graphics.print("<", btn.prevWeapon.x + btn.prevWeapon.w/2 - 5, btn.prevWeapon.y + btn.prevWeapon.h/2 - 10)
    
    -- 触摸指示器（显示当前触摸点，帮助玩家了解移动目标）
    if touchActive then
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.circle("fill", touchX, touchY, 15)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("line", touchX, touchY, 15)
    end
end

function drawInfoPanel()
    if not openInfo then return end
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(uiFont)
    love.graphics.print("Version: 0.3.2", 10,10)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10,35)
    love.graphics.print("Player: (" .. math.floor(player.x) .. ", " .. math.floor(player.y) .. ")", 10,60)
    love.graphics.print("Stamina: " .. math.floor(player.RunSystem.Stamina), 10,85)
    love.graphics.print("Health: " .. math.floor(player.HealthSystem.Health), 10,110)
    love.graphics.print("Enemies: " .. #enemies, 10,135)
    love.graphics.print("Bits: " .. bits, 10,160)
    love.graphics.print("Wallet: " .. maxBits, 10,185)
    love.graphics.print("Wave: " .. wave.current .. "/" .. wave.maxWaves[wave.mode], 10,210)
    love.graphics.print("Diff: " .. selectedDifficulty, 10,235)
    if player.Bag.hasSoulReaper then
        love.graphics.print("Soul Charge: " .. math.floor(player.soulReaperCharge) .. "/500", 10,260)
    end
    if player.Bag.hasLaserGun then
        love.graphics.print("Laser Charge: " .. math.floor(player.laserGunCharge) .. "/" .. (player.weaponStates.lasergun.maxCharge or 50), 10,285)
    end
    
    if player.abilities.passive.dragonslayer then
        love.graphics.print("屠龙者: 对Boss伤害+10%", 10,310)
    end
    if player.abilities.passive.bloodthirst then
        love.graphics.print("嗜血: 击杀回血", 10,335)
    end
    if player.abilities.passive.constantMotion then
        love.graphics.print("恒动: 速度260", 10,360)
    end
    
    local yPos = 385
    for i = 1, 3 do
        local throwableId = player.throwables.slots[i]
        if throwableId then
            local throwable = ThrowableSystem.throwables[throwableId]
            local charge = player.throwables.charges[i]
            love.graphics.print(throwable.name .. ": " .. (charge > 0 and "可用" or "冷却中"), 10, yPos)
            yPos = yPos + 25
        end
    end
    
    if #frameTimes > 0 then
        local avg = 0
        for _, t in ipairs(frameTimes) do
            avg = avg + t
        end
        avg = avg / #frameTimes
        love.graphics.print(string.format("Frame time: %.2f ms", avg * 1000), 10, yPos)
    end
end

-- ===== 移动端触摸事件 =====
function love.touchpressed(id, x, y, dx, dy, pressure)
    if not isMobile then return end
    if gameState == "playing" and not player.isDead then
        -- 检测是否点击了UI按钮
        local btn = mobileButtons
        if x >= btn.reload.x and x <= btn.reload.x + btn.reload.w and y >= btn.reload.y and y <= btn.reload.y + btn.reload.h then
            reloadWeapon()
            return
        elseif x >= btn.nextWeapon.x and x <= btn.nextWeapon.x + btn.nextWeapon.w and y >= btn.nextWeapon.y and y <= btn.nextWeapon.y + btn.nextWeapon.h then
            -- 切换武器：查找下一个可用武器槽
            local nextSlot = nil
            for i = 1, 4 do
                if player.weaponSlots[i] then
                    if not nextSlot or i > (player.weaponSlots[player.weapon.type] or 0) then
                        nextSlot = i
                    end
                end
            end
            if nextSlot then
                local weaponType = player.weaponSlots[nextSlot]
                if weaponType then
                    if player.weapon.equipped and player.weapon.type == weaponType then
                        player.weaponStates[player.weapon.type].isReloading = false
                        player.weapon.equipped = false
                        player.weapon.type = nil
                    else
                        if player.weapon.equipped then
                            player.weaponStates[player.weapon.type].isReloading = false
                        end
                        player.weapon.equipped = true
                        player.weapon.type = weaponType
                        currentCooldown = 0
                    end
                end
            end
            return
        elseif x >= btn.prevWeapon.x and x <= btn.prevWeapon.x + btn.prevWeapon.w and y >= btn.prevWeapon.y and y <= btn.prevWeapon.y + btn.prevWeapon.h then
            -- 切换武器：查找上一个可用武器槽
            local prevSlot = nil
            for i = 4, 1, -1 do
                if player.weaponSlots[i] then
                    if not prevSlot or i < (player.weaponSlots[player.weapon.type] or 5) then
                        prevSlot = i
                    end
                end
            end
            if prevSlot then
                local weaponType = player.weaponSlots[prevSlot]
                if weaponType then
                    if player.weapon.equipped and player.weapon.type == weaponType then
                        player.weaponStates[player.weapon.type].isReloading = false
                        player.weapon.equipped = false
                        player.weapon.type = nil
                    else
                        if player.weapon.equipped then
                            player.weaponStates[player.weapon.type].isReloading = false
                        end
                        player.weapon.equipped = true
                        player.weapon.type = weaponType
                        currentCooldown = 0
                    end
                end
            end
            return
        else
            -- 触摸屏幕任意位置：激活移动控制
            touchActive = true
            -- 将触摸点屏幕坐标转换为世界坐标
            local w, h = love.graphics.getDimensions()
            touchX = x + player.x - w/2
            touchY = y + player.y - h/2
        end
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if not isMobile then return end
    if touchActive and gameState == "playing" and not player.isDead then
        local w, h = love.graphics.getDimensions()
        touchX = x + player.x - w/2
        touchY = y + player.y - h/2
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if not isMobile then return end
    if touchActive then
        touchActive = false
    end
end

function love.keypressed(key)
    if isMobile then return end  -- 移动端禁用键盘
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen()) end
    if key == "f10" then openInfo = not openInfo end

    if key == "f9" then
        print("F9 pressed - toggling debug mode")
        if toggleDebugMode then
            toggleDebugMode()
        else
            print("ERROR: toggleDebugMode not defined")
        end
        return true
    end

    if key == "f6" or key == "f7" or key == "f8" then
        print("Debug key pressed: " .. key)
        if handleDebugKeys then
            handleDebugKeys(key)
            return true
        else
            print("ERROR: handleDebugKeys not defined")
        end
    end

    -- ===== ESC 键统一处理 =====
    if key == "escape" then
        if gameState == "playing" then
            -- 游戏中：切换暂停
            paused = not paused
            print(paused and "Game paused" or "Game resumed")
            return true
        elseif gameState == "menu" then
            -- 主菜单中：退出游戏
            saveHighScore()
            love.event.quit()
            return true
        else
            -- 其他状态（difficulty, inventory, bestiary, shop）：返回主菜单
            gameState = "menu"
            -- 清理可能存在的绑定状态
            if inventoryState then
                inventoryState.bindingWeapon = nil
                inventoryState.bindingSkill = nil
                inventoryState.throwableBinding = nil
            end
            paused = false   -- 确保暂停标志重置
            return true
        end
    end

    -- 以下为游戏内和其他状态的按键处理（不再有重复的 ESC 分支）
    if gameState == "playing" then
        if player.isDead and key == "x" then
            resetGame()
            return
        end

        if key == "p" then
            paused = not paused
            print(paused and "Game paused" or "Game resumed")
            return
        end

        if paused then
            -- 暂停菜单的键盘控制
            if key == "return" or key == "space" then
                paused = false
                return
            elseif key == "m" then
                gameState = "menu"
                paused = false
                return
            end
            return  -- 暂停时其他按键无效
        end

        if key == "m" then
            gameState = "menu"
            return
        end

        if not player.isDead then
            local slotNumber = tonumber(key)
            if slotNumber and slotNumber >= 1 and slotNumber <= 4 then
                local weaponType = player.weaponSlots[slotNumber]
                if weaponType then
                    if player.weapon.equipped and player.weapon.type == weaponType then
                        player.weaponStates[player.weapon.type].isReloading = false
                        player.weapon.equipped = false
                        player.weapon.type = nil
                        print("Weapon holstered")
                    else
                        if player.weapon.equipped then
                            player.weaponStates[player.weapon.type].isReloading = false
                        end
                        player.weapon.equipped = true
                        player.weapon.type = weaponType
                        currentCooldown = 0
                        print("Switched to " .. weaponType)
                    end
                end
                return
            end

            if slotNumber and slotNumber >= 5 and slotNumber <= 7 then
                ThrowableSystem:handleKey(key)
                return
            end

            if key == "q" or key == "e" or key == "z" or key == "x" then
                AbilitySystem:handleKey(key)
                return
            end

            if key == "7" then
                if ThrowableSystem:handleBeaconTrigger() then
                    print("Phase beacon triggered!")
                end
                return
            end

            if key == "r" then
                reloadWeapon()
                return
            end
        end
    end

    -- 其他游戏状态的处理（difficulty, inventory, bestiary, shop）
    if gameState == "difficulty" then
        -- ESC 已由全局处理，此处无需额外代码
        return
    elseif gameState == "inventory" then
        handleInventoryKeys(key)
        if key == "escape" then
            -- 已由全局处理返回菜单，这里仅清理状态
            inventoryState.bindingWeapon = nil
            inventoryState.bindingSkill = nil
            inventoryState.throwableBinding = nil
        end
    elseif gameState == "bestiary" then
        -- ESC 已由全局处理
        return
    elseif gameState == "shop" then
        -- ESC 已由全局处理
        return
    end

    return false
end

function love.mousepressed(x, y, button)
    if isMobile then return end
    
    -- 处理暂停菜单点击（如果游戏在 playing 且暂停）
    if gameState == "playing" and paused then
        local mx, my = x, y
        if love.graphics.pauseMenuItems then
            if love.graphics.pauseMenuItems["Resume"] and 
               mx >= love.graphics.pauseMenuItems["Resume"].x and 
               mx <= love.graphics.pauseMenuItems["Resume"].x + love.graphics.pauseMenuItems["Resume"].w and
               my >= love.graphics.pauseMenuItems["Resume"].y and 
               my <= love.graphics.pauseMenuItems["Resume"].y + love.graphics.pauseMenuItems["Resume"].h then
                paused = false
                return
            elseif love.graphics.pauseMenuItems["Main Menu"] and 
                   mx >= love.graphics.pauseMenuItems["Main Menu"].x and 
                   mx <= love.graphics.pauseMenuItems["Main Menu"].x + love.graphics.pauseMenuItems["Main Menu"].w and
                   my >= love.graphics.pauseMenuItems["Main Menu"].y and 
                   my <= love.graphics.pauseMenuItems["Main Menu"].y + love.graphics.pauseMenuItems["Main Menu"].h then
                gameState = "menu"
                paused = false
                return
            elseif love.graphics.pauseMenuItems["Quit"] and 
                   mx >= love.graphics.pauseMenuItems["Quit"].x and 
                   mx <= love.graphics.pauseMenuItems["Quit"].x + love.graphics.pauseMenuItems["Quit"].w and
                   my >= love.graphics.pauseMenuItems["Quit"].y and 
                   my <= love.graphics.pauseMenuItems["Quit"].y + love.graphics.pauseMenuItems["Quit"].h then
                saveHighScore()
                love.event.quit()
                return
            end
        end
    end
    
    -- 原有鼠标处理（不变）
    if gameState == "menu" and button == 1 then
        local currentW, currentH = love.graphics.getDimensions()
        local bw, bh, startY = 200, 50, currentH/2 - 100
        if x >= (currentW-bw)/2 and x <= (currentW-bw)/2 + bw then
            if y >= startY and y <= startY+bh then
                gameState = "difficulty"
            elseif y >= startY+70 and y <= startY+70+bh then
                gameState = "inventory"
            elseif y >= startY+140 and y <= startY+140+bh then
                gameState = "bestiary"
            elseif y >= startY+210 and y <= startY+210+bh then
                gameState = "shop"
            end
        end

    elseif gameState == "difficulty" and button == 1 then
        local currentW, currentH = love.graphics.getDimensions()
        local bw, bh, startY = 200, 50, currentH/2 - 120
        if x >= (currentW-bw)/2 and x <= (currentW-bw)/2 + bw then
            if y >= startY and y <= startY+bh then
                selectedDifficulty = "easy"
                startNewGame()
            elseif y >= startY+60 and y <= startY+60+bh then
                selectedDifficulty = "medium"
                startNewGame()
            elseif y >= startY+120 and y <= startY+120+bh then
                selectedDifficulty = "hard"
                startNewGame()
            elseif y >= startY+180 and y <= startY+180+bh then
                selectedDifficulty = "endless"
                startNewGame()
            elseif y >= startY+240 and y <= startY+240+bh then
                selectedDifficulty = "bossrush"
                startNewGame()
            end
        end

    elseif gameState == "inventory" then
        handleInventoryMouse(x, y, button)
    elseif gameState == "bestiary" then
        handleBestiaryMouse(x, y, button)
    elseif gameState == "shop" then
        ShopSystem:mousepressed(x, y, button)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    -- 已在上面单独实现
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    -- 已在上面单独实现
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    -- 已在上面单独实现
end

function love.wheelmoved(x, y)
    if gameState == "bestiary" then
        handleBestiaryWheel(y)
    elseif gameState == "shop" then
        ShopSystem:wheelmoved(y)
    elseif gameState == "inventory" then
        handleInventoryWheel(y)
    end
end

function startNewGame()
    print("=== STARTING NEW GAME (" .. string.upper(selectedDifficulty) .. ") ===")
    applyDifficulty(selectedDifficulty)

    player.x, player.y = 0, 0
    player.isDead = false
    player.deathTimer, player.blinkTimer = 0, 0
    player.HealthSystem.Health = player.HealthSystem.HealthMax
    player.RunSystem.Stamina = player.RunSystem.StaminaMax
    
    player.weapon.equipped = false
    player.weapon.type = nil

    for _, w in pairs(player.weaponStates) do
        w.ammo = w.maxAmmo
        w.isReloading = false
        w.reloadTimer = 0
    end
    
    player.soulReaperCharge = 0
    player.laserGunCharge = player.weaponStates.lasergun.maxCharge or 50
    player.lastLaserShotTime = 0
    
    player.lifedrainDamageBonus = 0
    player.lifedrainKillCounter = 0

    for i = 1, 4 do
        player.abilities.activeCooldowns[i] = 0
    end
    player.abilities.siphonActive = false
    player.abilities.siphonTimer = 0

    for i = 1, 3 do
        if player.throwables.slots[i] then
            player.throwables.charges[i] = 1
        else
            player.throwables.charges[i] = 0
        end
        player.throwables.lastUsedRound[i] = 0
    end

    local hasAnySlot = false
    for i = 1, 4 do
        if player.weaponSlots[i] then
            hasAnySlot = true
            break
        end
    end
    if not hasAnySlot and player.Bag.hasPistol then
        player.weaponSlots[1] = "pistol"
        print("Default bind: Pistol to slot 1")
        saveHighScore()
    end

    for i = 1, 4 do
        if player.weaponSlots[i] then
            player.weapon.equipped = true
            player.weapon.type = player.weaponSlots[i]
            break
        end
    end

    trails = {}
    bullets = {}
    enemies = {}
    enemyBullets = {}
    throwableFields = {}

    enemySpawnTimer = 0
    lastruntime = 0
    staminaTimer = 0
    recoveryDelayTimer = 0
    canRecover = true
    currentCooldown = 0
    currentAngle = 0
    bits = 0

    mapWidth = 1000
    mapHeight = 1000
    mapMinX = -mapWidth/2
    mapMaxX = mapWidth/2
    mapMinY = -mapHeight/2
    mapMaxY = mapHeight/2
    mapExpanded = false

    wave.mode = selectedDifficulty
    startWave(1, wave.mode)

    gameState = "playing"
    paused = false  -- 新游戏确保未暂停
    
    print("Game started! Equipped weapons: " .. (player.weapon.type or "none"))
    print("Throwable slots:")
    for i = 1, 3 do
        if player.throwables.slots[i] then
            print("  Slot " .. (i+4) .. ": " .. player.throwables.slots[i] .. " (charge: " .. player.throwables.charges[i] .. ")")
        end
    end
end

function resetGame()
    print("=== GAME RESTARTED ===")
    saveHighScore()
    startNewGame()
end

function expandMap()
    if mapExpanded then return end
    mapWidth = 1750
    mapHeight = 1750
    mapMinX = -mapWidth/2
    mapMaxX = mapWidth/2
    mapMinY = -mapHeight/2
    mapMaxY = mapHeight/2

    player.x = 0
    player.y = 250

    mapExpanded = true
    print("Map expanded to 1750x1750 with central obstacle!")
end

function drawMapBoundary()
    love.graphics.setColor(1,1,1,0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", mapMinX, mapMinY, mapWidth, mapHeight)
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.circle("fill", mapMinX, mapMinY, 5)
    love.graphics.circle("fill", mapMaxX, mapMinY, 5)
    love.graphics.circle("fill", mapMinX, mapMaxY, 5)
    love.graphics.circle("fill", mapMaxX, mapMaxY, 5)

    if mapExpanded then
        love.graphics.setColor(0.5,0.5,0.5,0.5)
        love.graphics.rectangle("fill", obstacle.x - obstacle.w/2, obstacle.y - obstacle.h/2, obstacle.w, obstacle.h)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", obstacle.x - obstacle.w/2, obstacle.y - obstacle.h/2, obstacle.w, obstacle.h)
    end
end

function drawStaminaBar(barX, barY)
    local barWidth, barHeight, padding = 300, 35, 5
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    local fillX, fillY = barX+padding, barY+padding
    local fillH = barHeight - 2*padding
    if player.RunSystem.Stamina < 30 then
        love.graphics.setColor(1,0.5,0.5)
    else
        love.graphics.setColor(1,1,1)
    end
    love.graphics.rectangle("fill", fillX, fillY, staminaBar.currentWidth, fillH)
    love.graphics.setColor(1,1,1)
    love.graphics.print(math.floor(player.RunSystem.Stamina) .. "/" .. player.RunSystem.StaminaMax, barX+barWidth+10, barY)
end

function drawHealthBar(barX, barY)
    local barWidth, barHeight, padding = 300, 35, 5
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    local fillX, fillY = barX+padding, barY+padding
    local fillH = barHeight - 2*padding
    local hp = player.HealthSystem.Health / player.HealthSystem.HealthMax
    if hp < 0.3 then
        love.graphics.setColor(1,0.3,0.3)
    elseif hp < 0.6 then
        love.graphics.setColor(1,0.8,0.3)
    else
        love.graphics.setColor(0.3,1,0.3)
    end
    love.graphics.rectangle("fill", fillX, fillY, healthBar.currentWidth, fillH)
    love.graphics.setColor(1,1,1)
    love.graphics.print(math.floor(player.HealthSystem.Health) .. "/" .. player.HealthSystem.HealthMax, barX+barWidth+10, barY)
end

function clampPlayerToMap()
    player.x = math.max(mapMinX, math.min(mapMaxX, player.x))
    player.y = math.max(mapMinY, math.min(mapMaxY, player.y))
    
    if mapExpanded then
        local left = obstacle.x - obstacle.w/2
        local right = obstacle.x + obstacle.w/2
        local top = obstacle.y - obstacle.h/2
        local bottom = obstacle.y + obstacle.h/2
        if player.x >= left and player.x <= right and player.y >= top and player.y <= bottom then
            local leftDist = math.abs(player.x - left)
            local rightDist = math.abs(player.x - right)
            local topDist = math.abs(player.y - top)
            local bottomDist = math.abs(player.y - bottom)
            local minDist = math.min(leftDist, rightDist, topDist, bottomDist)
            if minDist == leftDist then player.x = left - 1
            elseif minDist == rightDist then player.x = right + 1
            elseif minDist == topDist then player.y = top - 1
            else player.y = bottom + 1 end
        end
    end
end

function updateGamePlaying(dt)
    if player.HealthSystem.Health <= 0 and not player.isDead then
        player.isDead = true
        player.deathTimer = 2.0
        saveHighScore()
        print("Player died! Final bits: " .. bits .. " | Wallet: " .. maxBits)
        return
    end
    if player.isDead then
        player.deathTimer = player.deathTimer - dt
        player.blinkTimer = player.blinkTimer + dt
        if player.blinkTimer >= 0.2 then player.blinkTimer = 0 end
        return
    end

    if wave.current >= 30 and not mapExpanded then
        expandMap()
    end

    if player.Bag.hasLaserGun then
        local currentTime = love.timer.getTime()
        if currentTime - player.lastLaserShotTime > 4.0 then
            player.laserGunCharge = math.min(player.weaponStates.lasergun.maxCharge, player.laserGunCharge + 10 * dt)
        end
    end

    -- ===== 移动端触摸控制 =====
    if isMobile and not player.isDead then
        -- 触摸移动
        if touchActive then
            local dx = touchX - (player.x + 10)
            local dy = touchY - (player.y + 10)
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 10 then
                local dirX = dx / dist
                local dirY = dy / dist
                player.x = player.x + dirX * player.speed * dt
                player.y = player.y + dirY * player.speed * dt
                clampPlayerToMap()
            end
        end

        -- 自动射击：找到最近的敌人
        local nearestEnemy = nil
        local nearestDist = math.huge
        local playerCenterX = player.x + 10
        local playerCenterY = player.y + 10
        for _, enemy in ipairs(enemies) do
            local ex = enemy.x + enemy.size/2
            local ey = enemy.y + enemy.size/2
            local dist = math.sqrt((ex - playerCenterX)^2 + (ey - playerCenterY)^2)
            if dist < nearestDist then
                nearestDist = dist
                nearestEnemy = enemy
            end
        end
        if nearestEnemy then
            -- 计算射击方向
            local ex = nearestEnemy.x + nearestEnemy.size/2
            local ey = nearestEnemy.y + nearestEnemy.size/2
            local dx = ex - playerCenterX
            local dy = ey - playerCenterY
            if dx ~= 0 or dy ~= 0 then
                currentAngle = math.atan2(dy, dx)
            end
            -- 自动射击（受冷却限制）
            if love.timer.getTime() - (lastAutoShot or 0) > 0.05 then
                shootWeapon()
                lastAutoShot = love.timer.getTime()
            end
        end
    end

    -- PC模式鼠标射击
    if not isMobile and love.mouse.isDown(1) and player.weapon.equipped then
        shootWeapon()
    end

    updateWeaponReload(dt)
    updateWaveAndEnemies(dt)
    updateBullets(dt)
    
    if updateEnemyBullets then
        updateEnemyBullets(dt)
    end

    updateCooldowns(dt)
    AbilitySystem:update(dt)

    -- PC模式鼠标方向
    if not isMobile and player.weapon.equipped and player.weapon.type ~= "lasergun" then
        local mx, my = love.mouse.getPosition()
        local currentW, currentH = love.graphics.getDimensions()
        local worldX = mx + player.x - currentW/2
        local worldY = my + player.y - currentH/2
        local dx = worldX - (player.x + 10)
        local dy = worldY - (player.y + 10)
        currentAngle = math.atan2(dy, dx)
    end

    -- 体力与移动（PC模式使用键盘，移动端已处理移动）
    if not isMobile then
        local shiftPressed = love.keyboard.isDown("lshift")
        local moving = love.keyboard.isDown("up") or love.keyboard.isDown("w") or
                       love.keyboard.isDown("down") or love.keyboard.isDown("s") or
                       love.keyboard.isDown("left") or love.keyboard.isDown("a") or
                       love.keyboard.isDown("right") or love.keyboard.isDown("d")
        
        if player.abilities.passive.constantMotion then
            player.speed = 260
            if canRecover then
                staminaTimer = staminaTimer + dt
                if staminaTimer >= 0.025 then
                    staminaTimer = 0
                    player.RunSystem.Stamina = math.min(player.RunSystem.Stamina + 1, player.RunSystem.StaminaMax)
                end
            end
        else
            if shiftPressed and moving then
                player.RunSystem.Stamina = player.RunSystem.Stamina - 20 * dt
                if player.RunSystem.Stamina < 0 then player.RunSystem.Stamina = 0 end
                recoveryDelayTimer = 0
                canRecover = false
            end
            if not (shiftPressed and moving) then
                if not canRecover then
                    recoveryDelayTimer = recoveryDelayTimer + dt
                    if recoveryDelayTimer >= 1.0 then canRecover = true; recoveryDelayTimer = 0 end
                end
                if canRecover then
                    staminaTimer = staminaTimer + dt
                    if staminaTimer >= 0.025 then
                        staminaTimer = 0
                        player.RunSystem.Stamina = math.min(player.RunSystem.Stamina + 1, player.RunSystem.StaminaMax)
                    end
                end
            end

            if shiftPressed and moving and player.RunSystem.Stamina > 0 then
                player.speed = player.RunSystem.Runspeed
            else
                player.speed = player.RunSystem.Walkspeed
            end
        end

        if love.keyboard.isDown("up") or love.keyboard.isDown("w") then player.y = player.y - player.speed * dt end
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then player.y = player.y + player.speed * dt end
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then player.x = player.x - player.speed * dt end
        if love.keyboard.isDown("right") or love.keyboard.isDown("d") then player.x = player.x + player.speed * dt end
        clampPlayerToMap()

        if player.speed == player.RunSystem.Runspeed and not player.abilities.passive.constantMotion then
            if love.timer.getTime() - lastruntime >= 0.1 then
                lastruntime = love.timer.getTime()
                table.insert(trails, { x = player.x, y = player.y, time = 0, maxTime = 1 })
            end
        end
        for i = #trails, 1, -1 do
            trails[i].time = trails[i].time + dt
            if trails[i].time >= trails[i].maxTime then table.remove(trails, i) end
        end
    end

    staminaBar.targetWidth = (300 - 10) * (player.RunSystem.Stamina / player.RunSystem.StaminaMax)
    staminaBar.currentWidth = staminaBar.currentWidth + (staminaBar.targetWidth - staminaBar.currentWidth) * staminaBar.smoothSpeed * dt
    healthBar.targetWidth = (300 - 10) * (player.HealthSystem.Health / player.HealthSystem.HealthMax)
    healthBar.currentWidth = healthBar.currentWidth + (healthBar.targetWidth - healthBar.currentWidth) * healthBar.smoothSpeed * dt
end

-- ===== 新增：暂停菜单绘制函数 =====
function drawPauseMenu()
    local screenW, screenH = love.graphics.getDimensions()
    local font = love.graphics.newFont(30)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    local title = "PAUSED"
    local titleW = font:getWidth(title)
    love.graphics.print(title, (screenW - titleW) / 2, screenH/2 - 100)

    local menuItems = {
        { text = "Resume", y = screenH/2 - 20 },
        { text = "Main Menu", y = screenH/2 + 20 },
        { text = "Quit", y = screenH/2 + 60 }
    }

    local mouseX, mouseY = love.mouse.getPosition()
    love.graphics.pauseMenuItems = {}
    for _, item in ipairs(menuItems) do
        local textW = font:getWidth(item.text)
        local x = (screenW - textW) / 2
        local y = item.y
        local hover = mouseX >= x and mouseX <= x + textW and mouseY >= y and mouseY <= y + font:getHeight()
        love.graphics.setColor(hover and 0.8 or 1, hover and 0.8 or 1, hover and 0.8 or 1)
        love.graphics.print(item.text, x, y)
        -- 存储矩形区域供鼠标点击
        love.graphics.pauseMenuItems[item.text] = { x = x, y = y, w = textW, h = font:getHeight() }
    end
    love.graphics.setFont(uiFont)
end