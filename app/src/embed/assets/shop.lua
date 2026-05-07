-- ============================================================================
-- shop.lua - 管理商店、购买、物品定义
-- ============================================================================

ShopSystem = ShopSystem or {}

-- 初始化商店
function ShopSystem:init()
    -- 商店物品定义
    self.items = {
        -- 武器
        rifle = {
            name = "Rifle",
            type = "weapon",
            price = 750,
            description = "Damage: 6 | Fire rate: 10/s",
            icon = "R",
            color = {1,0.8,0},
            onPurchase = function()
                player.Bag.hasRifle = true
                print("✓ Rifle unlocked!")
            end,
            canPurchase = function()
                return not player.Bag.hasRifle
            end
        },
        sniper = {
            name = "Sniper",
            type = "weapon",
            price = 2000,
            description = "Damage: 25 | Fire rate: 1/s",
            icon = "S",
            color = {0.5,0.8,1},
            onPurchase = function()
                player.Bag.hasSniper = true
                print("✓ Sniper unlocked!")
            end,
            canPurchase = function()
                return not player.Bag.hasSniper
            end
        },
        soulreaper = {
            name = "Soul Reaper",
            type = "weapon",
            price = 4000,
            description = "Dmg:750 | CD:5s | Charge:500",
            icon = "SR",
            color = {0.5, 0, 0.5},
            onPurchase = function()
                player.Bag.hasSoulReaper = true
                for i = 1, 4 do
                    if not player.weaponSlots[i] then
                        player.weaponSlots[i] = "soulreaper"
                        break
                    end
                end
                print("✓ Soul Reaper unlocked!")
            end,
            canPurchase = function()
                return not player.Bag.hasSoulReaper
            end
        },
        lasergun = {
            name = "Laser Gun",
            type = "weapon",
            price = 7500,
            description = "Dmg:15 | 10/s | Charge:50",
            icon = "L",
            color = {1, 0, 0},
            onPurchase = function()
                player.Bag.hasLaserGun = true
                for i = 1, 4 do
                    if not player.weaponSlots[i] then
                        player.weaponSlots[i] = "lasergun"
                        break
                    end
                end
                print("✓ Laser Gun unlocked!")
            end,
            canPurchase = function()
                return not player.Bag.hasLaserGun
            end
        },
        -- 饕宴武器
        feast = {
            name = "Feast",
            type = "weapon",
            price = 75000,
            description = "Dmg:25 | 1.5s CD | 5s explosion | 1000 dmg",
            icon = "FT",
            color = {1, 0.5, 0},
            onPurchase = function()
                player.Bag.hasFeast = true
                for i = 1, 4 do
                    if not player.weaponSlots[i] then
                        player.weaponSlots[i] = "feast"
                        break
                    end
                end
                print("✓ Feast unlocked!")
            end,
            canPurchase = function()
                return not player.Bag.hasFeast
            end
        },
        -- 噬命武器
        lifedrain = {
            name = "Life Drain",
            type = "weapon",
            price = 35000,
            description = "Dmg:10 | Triple burst | Permanent dmg per kill",
            icon = "LD",
            color = {1, 0.2, 0.2},
            onPurchase = function()
                player.Bag.hasLifedrain = true
                for i = 1, 4 do
                    if not player.weaponSlots[i] then
                        player.weaponSlots[i] = "lifedrain"
                        break
                    end
                end
                print("✓ Life Drain unlocked!")
            end,
            canPurchase = function()
                return not player.Bag.hasLifedrain
            end
        },
        
        -- 手枪模组
        pistolFastMag = {
            name = "Fast Pistol Mag",
            type = "mod",
            weapon = "pistol",
            price = 1000,
            description = "Ammo +3",
            icon = "FM",
            color = {0.8,0.8,0.8},
            onPurchase = function()
                player.Bag.pistolMods.fastMag = true
                player.weaponStates.pistol.maxAmmo = player.weaponStates.pistol.maxAmmo + 3
                player.weaponStates.pistol.ammo = player.weaponStates.pistol.ammo + 3
                print("✓ Fast Pistol Mag equipped!")
            end,
            canPurchase = function()
                return not player.Bag.pistolMods.fastMag
            end
        },
        pistolExtMag = {
            name = "Extended Pistol Mag",
            type = "mod",
            weapon = "pistol",
            price = 1000,
            description = "Reload -0.5s",
            icon = "EM",
            color = {0.8,0.8,0.8},
            onPurchase = function()
                player.Bag.pistolMods.extMag = true
                player.weaponStates.pistol.reloadTime = math.max(0.5, player.weaponStates.pistol.reloadTime - 0.5)
                print("✓ Extended Pistol Mag equipped!")
            end,
            canPurchase = function()
                return not player.Bag.pistolMods.extMag
            end
        },
        pistolDamage = {
            name = "Pistol Damage +3",
            type = "mod",
            weapon = "pistol",
            price = 3000,
            description = "Damage +3",
            icon = "D3",
            color = {0.8,0.8,0.8},
            onPurchase = function()
                player.Bag.pistolMods.damage = true
                player.weaponStates.pistol.damage = player.weaponStates.pistol.damage + 3
                print("✓ Pistol Damage +3 equipped!")
            end,
            canPurchase = function()
                return not player.Bag.pistolMods.damage
            end
        },
        
        -- 步枪模组
        rifleFastMag = {
            name = "Fast Rifle Mag",
            type = "mod",
            weapon = "rifle",
            price = 3500,
            description = "Ammo +15",
            icon = "FM",
            color = {1,0.8,0},
            onPurchase = function()
                player.Bag.rifleMods.fastMag = true
                player.weaponStates.rifle.maxAmmo = player.weaponStates.rifle.maxAmmo + 15
                player.weaponStates.rifle.ammo = player.weaponStates.rifle.ammo + 15
                print("✓ Fast Rifle Mag equipped!")
            end,
            canPurchase = function()
                return not player.Bag.rifleMods.fastMag
            end
        },
        rifleExtMag = {
            name = "Extended Rifle Mag",
            type = "mod",
            weapon = "rifle",
            price = 3000,
            description = "Reload -0.5s",
            icon = "EM",
            color = {1,0.8,0},
            onPurchase = function()
                player.Bag.rifleMods.extMag = true
                player.weaponStates.rifle.reloadTime = math.max(0.5, player.weaponStates.rifle.reloadTime - 0.5)
                print("✓ Extended Rifle Mag equipped!")
            end,
            canPurchase = function()
                return not player.Bag.rifleMods.extMag
            end
        },
        rifleDamage = {
            name = "Rifle Damage +2",
            type = "mod",
            weapon = "rifle",
            price = 3000,
            description = "Damage +2",
            icon = "D2",
            color = {1,0.8,0},
            onPurchase = function()
                player.Bag.rifleMods.damage = true
                player.weaponStates.rifle.damage = player.weaponStates.rifle.damage + 2
                print("✓ Rifle Damage +2 equipped!")
            end,
            canPurchase = function()
                return not player.Bag.rifleMods.damage
            end
        },
        
        -- 狙击枪模组
        sniperDamage = {
            name = "Sniper Damage +10",
            type = "mod",
            weapon = "sniper",
            price = 3500,
            description = "Damage +10",
            icon = "D10",
            color = {0.5,0.8,1},
            onPurchase = function()
                player.Bag.sniperMods.damage = true
                player.weaponStates.sniper.damage = player.weaponStates.sniper.damage + 10
                print("✓ Sniper Damage +10 equipped!")
            end,
            canPurchase = function()
                return not player.Bag.sniperMods.damage
            end
        },
        sniperPierce = {
            name = "Piercing Round",
            type = "mod",
            weapon = "sniper",
            price = 6000,
            description = "Pierce 1 enemy",
            icon = "PR",
            color = {0.5,0.8,1},
            onPurchase = function()
                player.Bag.sniperMods.pierce = true
                player.weaponStates.sniper.pierce = true
                print("✓ Piercing Round equipped!")
            end,
            canPurchase = function()
                return not player.Bag.sniperMods.pierce
            end
        },
        
        -- 噬魂模组
        soulreaperPierce = {
            name = "Soul Reaper Pierce",
            type = "mod",
            weapon = "soulreaper",
            price = 3000,
            description = "Pierce 3 enemies, damage halved",
            icon = "PP",
            color = {0.5,0,0.5},
            onPurchase = function()
                if not player.Bag.soulReaperMods then
                    player.Bag.soulReaperMods = {}
                end
                player.Bag.soulReaperMods.pierce = true
                player.weaponStates.soulreaper.pierce = true
                player.weaponStates.soulreaper.maxPierce = 3
                print("✓ Soul Reaper Pierce equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.soulReaperMods and player.Bag.soulReaperMods.pierce)
            end
        },
        soulreaperDamage = {
            name = "Soul Reaper Damage +750",
            type = "mod",
            weapon = "soulreaper",
            price = 5000,
            description = "Damage +750",
            icon = "D750",
            color = {0.5,0,0.5},
            onPurchase = function()
                if not player.Bag.soulReaperMods then
                    player.Bag.soulReaperMods = {}
                end
                player.Bag.soulReaperMods.damage = true
                player.weaponStates.soulreaper.damage = player.weaponStates.soulreaper.damage + 750
                print("✓ Soul Reaper Damage +750 equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.soulReaperMods and player.Bag.soulReaperMods.damage)
            end
        },
        
        -- 激光枪模组
        lasergunCapacity = {
            name = "Laser Gun Capacity",
            type = "mod",
            weapon = "lasergun",
            price = 5000,
            description = "Max charge +25",
            icon = "LC",
            color = {1,0,0},
            onPurchase = function()
                if not player.Bag.laserGunMods then
                    player.Bag.laserGunMods = {}
                end
                player.Bag.laserGunMods.capacity = true
                player.weaponStates.lasergun.maxCharge = player.weaponStates.lasergun.maxCharge + 25
                player.laserGunCharge = player.weaponStates.lasergun.maxCharge
                print("✓ Laser Gun Capacity +25 equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.laserGunMods and player.Bag.laserGunMods.capacity)
            end
        },
        
        -- 饕宴模组
        feastDualCore = {
            name = "Dual Core",
            type = "mod",
            weapon = "feast",
            price = 50000,
            description = "Ammo becomes 2",
            icon = "DC",
            color = {1,0.5,0},
            onPurchase = function()
                if not player.Bag.feastMods then
                    player.Bag.feastMods = {}
                end
                player.Bag.feastMods.dualCore = true
                player.weaponStates.feast.maxAmmo = 2
                player.weaponStates.feast.ammo = 2
                print("✓ Dual Core equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.feastMods and player.Bag.feastMods.dualCore)
            end
        },
        feastHighExplosive = {
            name = "High Explosive",
            type = "mod",
            weapon = "feast",
            price = 50000,
            description = "DoT 40/s | Explosion 2222 dmg",
            icon = "HE",
            color = {1,0.3,0},
            onPurchase = function()
                if not player.Bag.feastMods then
                    player.Bag.feastMods = {}
                end
                player.Bag.feastMods.highExplosive = true
                player.weaponStates.feast.feastDamagePerSecond = 40
                player.weaponStates.feast.feastExplosionDamage = 2222
                print("✓ High Explosive equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.feastMods and player.Bag.feastMods.highExplosive)
            end
        },
        
        -- 噬命模组
        lifedrainExtendedMag = {
            name = "Extended Mag",
            type = "mod",
            weapon = "lifedrain",
            price = 50000,
            description = "Ammo becomes 50",
            icon = "EM",
            color = {1,0.2,0.2},
            onPurchase = function()
                if not player.Bag.lifedrainMods then
                    player.Bag.lifedrainMods = {}
                end
                player.Bag.lifedrainMods.extendedMag = true
                player.weaponStates.lifedrain.maxAmmo = 50
                player.weaponStates.lifedrain.ammo = 50
                print("✓ Extended Mag equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.lifedrainMods and player.Bag.lifedrainMods.extendedMag)
            end
        },
        lifedrainSoulNourish = {
            name = "Soul Nourish",
            type = "mod",
            weapon = "lifedrain",
            price = 60000,
            description = "30% chance heal 5 HP on kill, +1 max HP if full",
            icon = "SN",
            color = {1,0.5,0.5},
            onPurchase = function()
                if not player.Bag.lifedrainMods then
                    player.Bag.lifedrainMods = {}
                end
                player.Bag.lifedrainMods.soulNourish = true
                print("✓ Soul Nourish equipped!")
            end,
            canPurchase = function()
                return not (player.Bag.lifedrainMods and player.Bag.lifedrainMods.soulNourish)
            end
        },
        
        -- 角色模组
        speedWalk = {
            name = "Speed Walk",
            type = "mod",
            weapon = "character",
            price = 1500,
            description = "Walk speed +50",
            icon = "SW",
            color = {0.5,1,0.5},
            onPurchase = function()
                player.Bag.characterMods.speedWalk = true
                player.RunSystem.Walkspeed = player.RunSystem.Walkspeed + 50
                print("✓ Speed Walk equipped!")
            end,
            canPurchase = function()
                return not player.Bag.characterMods.speedWalk
            end
        },
        speedRun = {
            name = "Speed Run",
            type = "mod",
            weapon = "character",
            price = 2000,
            description = "Run speed +75",
            icon = "SR",
            color = {0.5,1,0.5},
            onPurchase = function()
                player.Bag.characterMods.speedRun = true
                player.RunSystem.Runspeed = player.RunSystem.Runspeed + 75
                print("✓ Speed Run equipped!")
            end,
            canPurchase = function()
                return not player.Bag.characterMods.speedRun
            end
        },
        
        -- 主动技能
        heal = {
            name = "Heal",
            type = "ability",
            abilityType = "active",
            price = 1500,
            description = "Heal 25 HP | CD:30s",
            icon = "HP",
            color = {0, 1, 0},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["heal"] = true
                print("✓ Heal skill unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["heal"])
            end
        },
        harvest = {
            name = "Harvest",
            type = "ability",
            abilityType = "active",
            price = 4000,
            description = "Execute low HP enemies | CD:90s",
            icon = "HV",
            color = {1, 0.5, 0},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["harvest"] = true
                print("✓ Harvest skill unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["harvest"])
            end
        },
        siphon = {
            name = "Siphon",
            type = "ability",
            abilityType = "active",
            price = 6000,
            description = "50% life steal for 10s | CD:80s",
            icon = "SH",
            color = {0.5, 0, 1},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["siphon"] = true
                print("✓ Siphon skill unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["siphon"])
            end
        },
        forcefield = {
            name = "Force Field",
            type = "ability",
            abilityType = "active",
            price = 2000,
            description = "Knockback & stun nearby enemies | CD:30s",
            icon = "FF",
            color = {0, 0.5, 1},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["forcefield"] = true
                print("✓ Force Field skill unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["forcefield"])
            end
        },
        degradation = {
            name = "Degradation",
            type = "ability",
            abilityType = "active",
            price = 100000,
            description = "Transform all enemies into weaker forms | CD:150s",
            icon = "DG",
            color = {0.8, 0.2, 0.2},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["degradation"] = true
                print("✓ Degradation skill unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["degradation"])
            end
        },
        
        -- 被动技能
        dragonslayer = {
            name = "Dragon Slayer",
            type = "ability",
            abilityType = "passive",
            price = 3000,
            description = "+10% damage to bosses",
            icon = "DS",
            color = {1, 0.8, 0},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["dragonslayer"] = true
                print("✓ Dragon Slayer passive unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["dragonslayer"])
            end
        },
        bloodthirst = {
            name = "Bloodthirst",
            type = "ability",
            abilityType = "passive",
            price = 8000,
            description = "Kill heals 1 HP, bosses heal 20 HP",
            icon = "BT",
            color = {1, 0, 0},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["bloodthirst"] = true
                print("✓ Bloodthirst passive unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["bloodthirst"])
            end
        },
        constant = {
            name = "Constant Motion",
            type = "ability",
            abilityType = "passive",
            price = 3000,
            description = "Speed 260, no stamina consumption",
            icon = "CM",
            color = {1, 1, 0},
            onPurchase = function()
                if not player.abilities.owned then
                    player.abilities.owned = {}
                end
                player.abilities.owned["constant"] = true
                print("✓ Constant Motion passive unlocked!")
            end,
            canPurchase = function()
                return not (player.abilities.owned and player.abilities.owned["constant"])
            end
        },
        
        -- 投掷物
        gravityAnchor = {
            name = "Gravity Anchor",
            type = "throwable",
            price = 1000,
            description = "Creates a slow field, enemies -50% speed\nCooldown: 2 rounds",
            icon = "GA",
            color = {0.5, 0, 1},
            onPurchase = function()
                if not player.throwables.owned then
                    player.throwables.owned = {}
                end
                player.throwables.owned["gravityAnchor"] = true
                print("✓ Gravity Anchor unlocked!")
            end,
            canPurchase = function()
                return not (player.throwables.owned and player.throwables.owned["gravityAnchor"])
            end
        },
        soulShard = {
            name = "Soul Shard",
            type = "throwable",
            price = 3000,
            description = "Deals 300 area damage\nCooldown: 1 round",
            icon = "SS",
            color = {0.5, 0, 0.5},
            onPurchase = function()
                if not player.throwables.owned then
                    player.throwables.owned = {}
                end
                player.throwables.owned["soulShard"] = true
                print("✓ Soul Shard unlocked!")
            end,
            canPurchase = function()
                return not (player.throwables.owned and player.throwables.owned["soulShard"])
            end
        },
        phaseBeacon = {
            name = "Phase Beacon",
            type = "throwable",
            price = 2750,
            description = "Teleports back to beacon after 5s\nPress 7 near beacon to teleport early\nCooldown: 1 round",
            icon = "PB",
            color = {0, 1, 1},
            onPurchase = function()
                if not player.throwables.owned then
                    player.throwables.owned = {}
                end
                player.throwables.owned["phaseBeacon"] = true
                print("✓ Phase Beacon unlocked!")
            end,
            canPurchase = function()
                return not (player.throwables.owned and player.throwables.owned["phaseBeacon"])
            end
        }
    }
    
    -- 商店界面状态
    self.selectedCategory = "weapons"
    self.selectedWeapon = "pistol"
    self.selectedAbilityType = "active"
    self.scrollOffset = 0
    self.message = ""
    self.messageTimer = 0
    
    print("✓ ShopSystem initialized")
end

-- 尝试购买物品
function ShopSystem:purchase(itemId)
    local item = self.items[itemId]
    if not item then return false end
    
    if not item.canPurchase() then
        self:showMessage("Already owned!", 2)
        return false
    end
    
    if maxBits < item.price then
        self:showMessage("Not enough Bits! Need " .. item.price, 2)
        return false
    end
    
    maxBits = maxBits - item.price
    addBits(0)
    
    item.onPurchase()
    
    self:showMessage("Purchased: " .. item.name, 2)
    saveHighScore()
    
    return true
end

function ShopSystem:showMessage(msg, duration)
    self.message = msg
    self.messageTimer = duration or 2
end

function ShopSystem:update(dt)
    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then self.message = "" end
    end
end

function ShopSystem:isMouseOver(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- 处理鼠标滚轮
function ShopSystem:wheelmoved(y)
    local items = self:getCurrentItems()
    if not items then return end
    
    local visibleItems = self:getVisibleItemCount()
    local maxScroll = math.max(0, #items - visibleItems)
    
    if y > 0 then
        self.scrollOffset = math.max(0, self.scrollOffset - 1)
    elseif y < 0 then
        self.scrollOffset = math.min(maxScroll, self.scrollOffset + 1)
    end
end

-- 获取当前分类的物品列表
function ShopSystem:getCurrentItems()
    if self.selectedCategory == "weapons" then
        local weapons = {}
        for id, item in pairs(self.items) do
            if item.type == "weapon" then
                table.insert(weapons, {id = id, data = item})
            end
        end
        table.sort(weapons, function(a, b) return a.data.price < b.data.price end)
        return weapons
        
    elseif self.selectedCategory == "mods" then
        local mods = {}
        for id, item in pairs(self.items) do
            if item.type == "mod" and item.weapon == self.selectedWeapon then
                table.insert(mods, {id = id, data = item})
            end
        end
        table.sort(mods, function(a, b) return a.data.price < b.data.price end)
        return mods
        
    elseif self.selectedCategory == "abilities" then
        local abilities = {}
        for id, item in pairs(self.items) do
            if item.type == "ability" and item.abilityType == self.selectedAbilityType then
                table.insert(abilities, {id = id, data = item})
            end
        end
        table.sort(abilities, function(a, b) return a.data.price < b.data.price end)
        return abilities
        
    elseif self.selectedCategory == "throwables" then
        local throwables = {}
        for id, item in pairs(self.items) do
            if item.type == "throwable" then
                table.insert(throwables, {id = id, data = item})
            end
        end
        table.sort(throwables, function(a, b) return a.data.price < b.data.price end)
        return throwables
    end
    return {}
end

-- 获取可见物品数量
function ShopSystem:getVisibleItemCount()
    local currentH = love.graphics.getHeight()
    local itemHeight = 90
    return math.floor((currentH - 300) / itemHeight)
end

-- 绘制商店界面
function ShopSystem:draw()
    local currentW, currentH = love.graphics.getDimensions()
    
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local title = "SHOP"
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (currentW - titleWidth)/2, 30)
    
    love.graphics.setFont(uiFont)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("Bits: " .. maxBits, 20, 20)
    
    -- 分类标签
    local tabWidth, tabHeight, tabY = 120, 40, 80
    local spacing = 10
    local totalWidth = tabWidth * 4 + spacing * 3
    local firstX = (currentW - totalWidth) / 2
    
    local categories = {
        { name = "WEAPONS", cat = "weapons", x = firstX },
        { name = "MODS", cat = "mods", x = firstX + tabWidth + spacing },
        { name = "ABILITIES", cat = "abilities", x = firstX + (tabWidth + spacing) * 2 },
        { name = "THROWABLES", cat = "throwables", x = firstX + (tabWidth + spacing) * 3 }
    }
    
    for _, cat in ipairs(categories) do
        local hover = self:isMouseOver(cat.x, tabY, tabWidth, tabHeight)
        love.graphics.setColor(self.selectedCategory == cat.cat and 0.8 or (hover and 0.6 or 0.4),
                              self.selectedCategory == cat.cat and 0.8 or (hover and 0.6 or 0.4), 1)
        love.graphics.rectangle("fill", cat.x, tabY, tabWidth, tabHeight, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(cat.name, cat.x, tabY + 10, tabWidth, "center")
    end
    
    -- 子分类标签
    local subY = tabY + 50
    if self.selectedCategory == "mods" then
        self:drawWeaponTabs(currentW, subY)
    elseif self.selectedCategory == "abilities" then
        self:drawAbilityTabs(currentW, subY)
    end
    
    -- 物品列表
    local items = self:getCurrentItems()
    local startY = subY + 50
    local itemHeight = 90
    local visibleItems = self:getVisibleItemCount()
    local listHeight = visibleItems * (itemHeight + 10)
    
    -- 绘制滚动条
    if #items > visibleItems then
        local scrollBarHeight = listHeight * (visibleItems / #items)
        local scrollBarY = startY + (self.scrollOffset / (#items - visibleItems)) * (listHeight - scrollBarHeight)
        love.graphics.setColor(0.5, 0.5, 0.7)
        love.graphics.rectangle("fill", currentW - 30, scrollBarY, 10, scrollBarHeight, 5)
    end
    
    -- 绘制物品
    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + visibleItems - 1, #items)
    
    for i = startIdx, endIdx do
        local item = items[i]
        if item then
            local y = startY + (i - startIdx) * (itemHeight + 10)
            
            if self.selectedCategory == "weapons" then
                self:drawWeaponItem(currentW, y, item)
            elseif self.selectedCategory == "mods" then
                self:drawModItem(currentW, y, item)
            elseif self.selectedCategory == "abilities" then
                self:drawAbilityItem(currentW, y, item)
            elseif self.selectedCategory == "throwables" then
                self:drawThrowableItem(currentW, y, item)
            end
        end
    end
    
    -- 提示信息
    love.graphics.setColor(0.5,0.5,0.5)
    love.graphics.setFont(uiFont)
    love.graphics.print("ESC: Return | Mouse wheel: Scroll", 20, currentH - 30)
    
    -- 消息提示
    if self.messageTimer > 0 and self.message ~= "" then
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1,1,0,0.8)
        local msgWidth = love.graphics.getFont():getWidth(self.message)
        love.graphics.print(self.message, (currentW - msgWidth)/2, currentH - 80)
    end
end

function ShopSystem:drawWeaponItem(currentW, y, item)
    local itemWidth = 500
    local startX = (currentW - itemWidth) / 2
    local data = item.data
    local owned = false
    
    if item.id == "rifle" then
        owned = player.Bag.hasRifle
    elseif item.id == "sniper" then
        owned = player.Bag.hasSniper
    elseif item.id == "soulreaper" then
        owned = player.Bag.hasSoulReaper
    elseif item.id == "lasergun" then
        owned = player.Bag.hasLaserGun
    elseif item.id == "feast" then
        owned = player.Bag.hasFeast
    elseif item.id == "lifedrain" then
        owned = player.Bag.hasLifedrain
    end
    
    local hover = self:isMouseOver(startX, y, itemWidth, 80) and not owned
    
    love.graphics.setColor(data.color[1], data.color[2], data.color[3], owned and 0.3 or (hover and 0.8 or 0.5))
    love.graphics.rectangle("fill", startX, y, itemWidth, 80, 10)
    
    if hover then
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", startX, y, itemWidth, 80, 10)
    end
    
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(data.icon, startX + 15, y + 25)
    
    love.graphics.setFont(uiFont)
    love.graphics.print(data.name, startX + 60, y + 15)
    
    if owned then
        love.graphics.setColor(0,1,0)
        love.graphics.print("OWNED", startX + itemWidth - 100, y + 30)
    else
        love.graphics.setColor(1,1,0)
        love.graphics.print(data.price .. " Bits", startX + itemWidth - 120, y + 30)
    end
    
    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(data.description, startX + 60, y + 45, itemWidth - 200, "left")
end

function ShopSystem:drawModItem(currentW, y, item)
    local itemWidth = 500
    local startX = (currentW - itemWidth) / 2
    local data = item.data
    local owned = false
    
    if data.weapon == "pistol" then
        if item.id == "pistolFastMag" then owned = player.Bag.pistolMods.fastMag
        elseif item.id == "pistolExtMag" then owned = player.Bag.pistolMods.extMag
        elseif item.id == "pistolDamage" then owned = player.Bag.pistolMods.damage end
    elseif data.weapon == "rifle" then
        if item.id == "rifleFastMag" then owned = player.Bag.rifleMods.fastMag
        elseif item.id == "rifleExtMag" then owned = player.Bag.rifleMods.extMag
        elseif item.id == "rifleDamage" then owned = player.Bag.rifleMods.damage end
    elseif data.weapon == "sniper" then
        if item.id == "sniperDamage" then owned = player.Bag.sniperMods.damage
        elseif item.id == "sniperPierce" then owned = player.Bag.sniperMods.pierce end
    elseif data.weapon == "soulreaper" then
        if item.id == "soulreaperPierce" then owned = player.Bag.soulReaperMods and player.Bag.soulReaperMods.pierce
        elseif item.id == "soulreaperDamage" then owned = player.Bag.soulReaperMods and player.Bag.soulReaperMods.damage end
    elseif data.weapon == "lasergun" then
        if item.id == "lasergunCapacity" then owned = player.Bag.laserGunMods and player.Bag.laserGunMods.capacity end
    elseif data.weapon == "feast" then
        if item.id == "feastDualCore" then owned = player.Bag.feastMods and player.Bag.feastMods.dualCore
        elseif item.id == "feastHighExplosive" then owned = player.Bag.feastMods and player.Bag.feastMods.highExplosive end
    elseif data.weapon == "lifedrain" then
        if item.id == "lifedrainExtendedMag" then owned = player.Bag.lifedrainMods and player.Bag.lifedrainMods.extendedMag
        elseif item.id == "lifedrainSoulNourish" then owned = player.Bag.lifedrainMods and player.Bag.lifedrainMods.soulNourish end
    elseif data.weapon == "character" then
        if item.id == "speedWalk" then owned = player.Bag.characterMods.speedWalk
        elseif item.id == "speedRun" then owned = player.Bag.characterMods.speedRun end
    end
    
    local hover = self:isMouseOver(startX, y, itemWidth, 80) and not owned
    
    love.graphics.setColor(data.color[1], data.color[2], data.color[3], owned and 0.3 or (hover and 0.8 or 0.5))
    love.graphics.rectangle("fill", startX, y, itemWidth, 80, 10)
    
    if hover then
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", startX, y, itemWidth, 80, 10)
    end
    
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(data.icon, startX + 15, y + 25)
    
    love.graphics.setFont(uiFont)
    love.graphics.print(data.name, startX + 60, y + 15)
    
    if owned then
        love.graphics.setColor(0,1,0)
        love.graphics.print("OWNED", startX + itemWidth - 100, y + 30)
    else
        love.graphics.setColor(1,1,0)
        love.graphics.print(data.price .. " Bits", startX + itemWidth - 120, y + 30)
    end
    
    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(data.description, startX + 60, y + 45, itemWidth - 200, "left")
end

function ShopSystem:drawAbilityItem(currentW, y, item)
    local itemWidth = 500
    local startX = (currentW - itemWidth) / 2
    local data = item.data
    local owned = player.abilities.owned and player.abilities.owned[item.id]
    
    local hover = self:isMouseOver(startX, y, itemWidth, 80) and not owned
    
    love.graphics.setColor(data.color[1], data.color[2], data.color[3], owned and 0.3 or (hover and 0.8 or 0.5))
    love.graphics.rectangle("fill", startX, y, itemWidth, 80, 10)
    
    if hover then
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", startX, y, itemWidth, 80, 10)
    end
    
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(data.icon, startX + 15, y + 25)
    
    love.graphics.setFont(uiFont)
    love.graphics.print(data.name, startX + 60, y + 15)
    
    if owned then
        love.graphics.setColor(0,1,0)
        love.graphics.print("OWNED", startX + itemWidth - 100, y + 30)
    else
        love.graphics.setColor(1,1,0)
        love.graphics.print(data.price .. " Bits", startX + itemWidth - 120, y + 30)
    end
    
    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(data.description, startX + 60, y + 45, itemWidth - 200, "left")
end

function ShopSystem:drawThrowableItem(currentW, y, item)
    local itemWidth = 500
    local startX = (currentW - itemWidth) / 2
    local data = item.data
    local owned = player.throwables.owned and player.throwables.owned[item.id]
    
    local hover = self:isMouseOver(startX, y, itemWidth, 80) and not owned
    
    love.graphics.setColor(data.color[1], data.color[2], data.color[3], owned and 0.3 or (hover and 0.8 or 0.5))
    love.graphics.rectangle("fill", startX, y, itemWidth, 80, 10)
    
    if hover then
        love.graphics.setColor(1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", startX, y, itemWidth, 80, 10)
    end
    
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(data.icon, startX + 15, y + 25)
    
    love.graphics.setFont(uiFont)
    love.graphics.print(data.name, startX + 60, y + 15)
    
    if owned then
        love.graphics.setColor(0,1,0)
        love.graphics.print("OWNED", startX + itemWidth - 100, y + 30)
    else
        love.graphics.setColor(1,1,0)
        love.graphics.print(data.price .. " Bits", startX + itemWidth - 120, y + 30)
    end
    
    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.setFont(love.graphics.newFont(16))
    -- 使用多行显示描述
    local lines = {}
    for line in string.gmatch(data.description, "[^\n]+") do
        table.insert(lines, line)
    end
    local descY = y + 45
    for _, line in ipairs(lines) do
        love.graphics.printf(line, startX + 60, descY, itemWidth - 200, "left")
        descY = descY + 18
    end
end

function ShopSystem:drawWeaponTabs(currentW, startY)
    local tabWidth, tabHeight, spacing = 80, 30, 5
    local totalWidth = tabWidth * 8 + spacing * 7
    local firstX = (currentW - totalWidth) / 2
    
    local tabs = {
        { name = "PISTOL", weapon = "pistol", x = firstX },
        { name = "RIFLE", weapon = "rifle", x = firstX + tabWidth + spacing },
        { name = "SNIPER", weapon = "sniper", x = firstX + (tabWidth + spacing) * 2 },
        { name = "SOUL", weapon = "soulreaper", x = firstX + (tabWidth + spacing) * 3 },
        { name = "LASER", weapon = "lasergun", x = firstX + (tabWidth + spacing) * 4 },
        { name = "FEAST", weapon = "feast", x = firstX + (tabWidth + spacing) * 5 },
        { name = "LIFE", weapon = "lifedrain", x = firstX + (tabWidth + spacing) * 6 },
        { name = "CHAR", weapon = "character", x = firstX + (tabWidth + spacing) * 7 }
    }
    
    for _, tab in ipairs(tabs) do
        local hover = self:isMouseOver(tab.x, startY, tabWidth, tabHeight)
        love.graphics.setColor(self.selectedWeapon == tab.weapon and 0.7 or (hover and 0.5 or 0.3),
                              self.selectedWeapon == tab.weapon and 0.7 or (hover and 0.5 or 0.3), 1)
        love.graphics.rectangle("fill", tab.x, startY, tabWidth, tabHeight, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(tab.name, tab.x, startY + 5, tabWidth, "center")
    end
end

function ShopSystem:drawAbilityTabs(currentW, startY)
    local tabWidth, tabHeight, spacing = 150, 30, 20
    local totalWidth = tabWidth * 2 + spacing
    local firstX = (currentW - totalWidth) / 2
    
    local tabs = {
        { name = "ACTIVE", type = "active", x = firstX },
        { name = "PASSIVE", type = "passive", x = firstX + tabWidth + spacing }
    }
    
    for _, tab in ipairs(tabs) do
        local hover = self:isMouseOver(tab.x, startY, tabWidth, tabHeight)
        love.graphics.setColor(self.selectedAbilityType == tab.type and 0.7 or (hover and 0.5 or 0.3),
                              self.selectedAbilityType == tab.type and 0.7 or (hover and 0.5 or 0.3), 1)
        love.graphics.rectangle("fill", tab.x, startY, tabWidth, tabHeight, 5)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(tab.name, tab.x, startY + 5, tabWidth, "center")
    end
end

function ShopSystem:mousepressed(x, y, button)
    if button ~= 1 then return end
    local currentW, currentH = love.graphics.getDimensions()
    
    -- 主分类标签
    local tabWidth, tabHeight, tabY = 120, 40, 80
    local spacing = 10
    local totalWidth = tabWidth * 4 + spacing * 3
    local firstX = (currentW - totalWidth) / 2
    
    if self:isMouseOver(firstX, tabY, tabWidth, tabHeight) then
        self.selectedCategory = "weapons"
        self.scrollOffset = 0
        return
    elseif self:isMouseOver(firstX + tabWidth + spacing, tabY, tabWidth, tabHeight) then
        self.selectedCategory = "mods"
        self.scrollOffset = 0
        return
    elseif self:isMouseOver(firstX + (tabWidth + spacing) * 2, tabY, tabWidth, tabHeight) then
        self.selectedCategory = "abilities"
        self.scrollOffset = 0
        return
    elseif self:isMouseOver(firstX + (tabWidth + spacing) * 3, tabY, tabWidth, tabHeight) then
        self.selectedCategory = "throwables"
        self.scrollOffset = 0
        return
    end
    
    -- 子分类标签
    local subY = tabY + 50
    if self.selectedCategory == "mods" then
        local subTabWidth, subTabHeight = 80, 30
        local subSpacing = 5
        local subTotalWidth = subTabWidth * 8 + subSpacing * 7
        local subFirstX = (currentW - subTotalWidth) / 2
        
        local subTabs = {
            { weapon = "pistol", x = subFirstX },
            { weapon = "rifle", x = subFirstX + subTabWidth + subSpacing },
            { weapon = "sniper", x = subFirstX + (subTabWidth + subSpacing) * 2 },
            { weapon = "soulreaper", x = subFirstX + (subTabWidth + subSpacing) * 3 },
            { weapon = "lasergun", x = subFirstX + (subTabWidth + subSpacing) * 4 },
            { weapon = "feast", x = subFirstX + (subTabWidth + subSpacing) * 5 },
            { weapon = "lifedrain", x = subFirstX + (subTabWidth + subSpacing) * 6 },
            { weapon = "character", x = subFirstX + (subTabWidth + subSpacing) * 7 }
        }
        
        for _, tab in ipairs(subTabs) do
            if self:isMouseOver(tab.x, subY, subTabWidth, subTabHeight) then
                self.selectedWeapon = tab.weapon
                self.scrollOffset = 0
                return
            end
        end
        
    elseif self.selectedCategory == "abilities" then
        local subTabWidth, subTabHeight = 150, 30
        local subSpacing = 20
        local subTotalWidth = subTabWidth * 2 + subSpacing
        local subFirstX = (currentW - subTotalWidth) / 2
        
        if self:isMouseOver(subFirstX, subY, subTabWidth, subTabHeight) then
            self.selectedAbilityType = "active"
            self.scrollOffset = 0
            return
        elseif self:isMouseOver(subFirstX + subTabWidth + subSpacing, subY, subTabWidth, subTabHeight) then
            self.selectedAbilityType = "passive"
            self.scrollOffset = 0
            return
        end
    end
    
    -- 购买物品
    local items = self:getCurrentItems()
    local startY = subY + 50
    local itemHeight = 90
    local visibleItems = self:getVisibleItemCount()
    local startIdx = self.scrollOffset + 1
    local endIdx = math.min(startIdx + visibleItems - 1, #items)
    
    for i = startIdx, endIdx do
        local item = items[i]
        if item then
            local itemY = startY + (i - startIdx) * (itemHeight + 10)
            local itemWidth = 500
            local itemX = (currentW - itemWidth) / 2
            
            if self:isMouseOver(itemX, itemY, itemWidth, 80) then
                self:purchase(item.id)
                return
            end
        end
    end
end

print("✓ shop.lua loaded")
return ShopSystem