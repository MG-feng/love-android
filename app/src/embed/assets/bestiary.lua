-- ============================================================================
-- bestiary.lua - 管理游戏内所有可公开资料（敌人、武器、技能、模式等）
-- ============================================================================

-- 百科数据类型
bestiaryData = {
    enemies = {
        basic = {
            name = "Basic",
            description = "最常见的错误代码，攻击力一般，移动速度一般。",
            health = 30,
            damage = 10,
            speed = 180,
            score = 5,
            color = {1,0,0},
            icon = "□"
        },
        fast = {
            name = "Fast",
            description = "速度很快的错误代码，虽然血量较低但难以击中。",
            health = 20,
            damage = 8,
            speed = 300,
            score = 10,
            color = {1,0.5,0},
            icon = "▶"
        },
        tank = {
            name = "Tank",
            description = "高血量的重型错误代码，移动缓慢但伤害高。",
            health = 80,
            damage = 30,
            speed = 90,
            score = 20,
            color = {0.5,0,0},
            icon = "■"
        },
        elite = {
            name = "Elite",
            description = "精英级错误代码，中等难度中出现。各项属性均衡且较高。",
            health = 80,
            damage = 20,
            speed = 220,
            score = 30,
            color = {1,0,1},
            icon = "◆"
        },
        assault = {
            name = "Assault",
            description = "突击型错误代码，困难难度中出现。速度快且伤害高。",
            health = 50,
            damage = 15,
            speed = 280,
            score = 20,
            color = {1,0.2,0.2},
            icon = "▲"
        },
        suicider = {
            name = "Suicider",
            description = "快速冲向玩家并自爆，造成高额范围伤害。",
            health = 15,
            damage = 40,
            speed = 350,
            score = 15,
            color = {1,1,0},
            icon = "💣"
        },
        splitter = {
            name = "Splitter",
            description = "死亡时分裂成两个小分裂者。",
            health = 40,
            damage = 12,
            speed = 200,
            score = 20,
            color = {0,1,0.5},
            icon = "✂"
        },
        healer = {
            name = "Healer",
            description = "治疗周围友军，优先消灭。",
            health = 50,
            damage = 5,
            speed = 120,
            score = 30,
            color = {0,1,0},
            icon = "❤"
        },
        shielder = {
            name = "Shielder",
            description = "举起护盾减少正面受到的伤害。",
            health = 70,
            damage = 15,
            speed = 150,
            score = 25,
            color = {0.5,0.5,1},
            icon = "🛡"
        },
        sniper = {
            name = "Sniper",
            description = "远程狙击，伤害高但射速慢。",
            health = 40,
            damage = 35,
            speed = 80,
            score = 30,
            color = {0.8,0.2,0.8},
            icon = "🎯"
        },
        summoner = {
            name = "Summoner",
            description = "召唤小怪协助战斗。",
            health = 60,
            damage = 10,
            speed = 100,
            score = 40,
            color = {1,0.5,0},
            icon = "🐉"
        },
        ghost = {
            name = "Ghost",
            description = "周期性进入虚化状态，期间无法被攻击。",
            health = 30,
            damage = 12,
            speed = 180,
            score = 25,
            color = {0.8,0.8,1},
            icon = "👻"
        },
        boss_easy = {
            name = "ES-BOSS",
            description = "终极错误代码，第10波出现。拥有极高的血量和伤害，会发射追踪子弹。",
            health = 300,
            damage = 40,
            speed = 70,
            score = 75,
            color = {0.8,0,0.8},
            icon = "●"
        },
        boss_medium = {
            name = "MD-BOSS",
            description = "中等难度下的Boss，血量更高，会发射多颗子弹。",
            health = 700,
            damage = 60,
            speed = 65,
            score = 150,
            color = {0.9,0.2,0.9},
            icon = "●"
        },
        boss_hard = {
            name = "HD-BOSS",
            description = "困难难度Boss，拥有多阶段攻击模式。",
            health = 1500,
            damage = 80,
            speed = 60,
            score = 200,
            color = {1,0.3,0.3},
            icon = "●"
        },
        finalBoss_Phase1 = {
            name = "???",
            description = "最终Boss第一阶段，极其强大。",
            health = 5000,
            damage = 100,
            speed = 40,
            score = 1000,
            color = {0,0,0},
            icon = "★"
        },
        boss_summoner = {
            name = "Summoner Boss",
            description = "能够召唤精英和突击敌人的强大boss，小心被围攻。",
            health = 1200,
            damage = 30,
            speed = 50,
            score = 200,
            color = {0.8,0.2,0.8},
            icon = "S"
        },
        boss_sniper = {
            name = "Sniper Boss",
            description = "精准的狙击手，一次发射多颗高伤害子弹，保持移动！",
            health = 800,
            damage = 50,
            speed = 40,
            score = 200,
            color = {1,0.5,0},
            icon = "T"
        },
        boss_phantom = {
            name = "Phantom Boss",
            description = "能瞬间移动并短暂无敌，非常难以捕捉。",
            health = 1000,
            damage = 35,
            speed = 60,
            score = 250,
            color = {0.5,0.5,1},
            icon = "P"
        },
        boss_final_weakpoint = {
            name = "Core",
            description = "最终Boss的核心弱点，攻击造成5倍伤害。破坏后Boss损失10%最大生命值，10秒后重生。",
            health = 5000,
            damage = 0,
            speed = 0,
            score = 0,
            color = {1, 0.9, 0},
            icon = "⚡"
        },
        boss_final_phase2 = {
            name = "??? (Phase 2)",
            description = "最终Boss的第二形态，拥有5种技能，生命值低于30%进入狂暴。需攻击弱点造成伤害。",
            health = 400000,
            damage = 0,
            speed = 0,
            score = 5000,
            color = {0.2, 0.1, 0.3},
            icon = "★"
        }
    },
    weapons = {
        pistol = {
            name = "Pistol",
            description = "初始武器。射速快，弹药充足，适合清理小怪。",
            damage = 10,
            fireRate = "0.3秒 (≈3发/秒)",
            ammo = 7,
            bulletSpeed = 800,
            icon = "P",
            color = {1,1,1}
        },
        rifle = {
            name = "Rifle",
            description = "解锁武器。射速极快，适合对付群体敌人。",
            damage = 6,
            fireRate = "0.1秒 (≈10发/秒)",
            ammo = 35,
            bulletSpeed = 1500,
            icon = "R",
            color = {1,0.8,0}
        },
        sniper = {
            name = "Sniper",
            description = "解锁武器。单发伤害高，子弹速度快，适合对付精英和Boss。",
            damage = 25,
            fireRate = "1.0秒 (1发/秒)",
            ammo = 5,
            bulletSpeed = 2000,
            icon = "S",
            color = {0.5,0.8,1}
        },
        soulreaper = {
            name = "Soul Reaper",
            description = "终极收割武器。需要500点灵魂充能才能发射，每击杀一个敌人充能其最大生命值的一半。\n伤害：750 | 冷却：5秒 | 子弹速度：3000",
            damage = 750,
            fireRate = "5.0秒 (0.2发/秒)",
            ammo = "充能系统",
            bulletSpeed = 3000,
            icon = "SR",
            color = {0.5, 0, 0.5}
        },
        lasergun = {
            name = "Laser Gun",
            description = "高科技激光武器。发射即中激光，4秒不攻击后每秒恢复10点充能。\n伤害：15 | 射速：0.1秒 (10发/秒) | 充能：50",
            damage = 15,
            fireRate = "0.1秒 (10发/秒)",
            ammo = "充能50",
            bulletSpeed = "即时命中",
            icon = "L",
            color = {1, 0, 0}
        },
        feast = {
            name = "Feast",
            description = "饕宴武器。射出一个巨大的子弹，吸附附近敌人到中心，每秒造成25伤害，5秒后爆炸造成1000伤害。\n弹药：1 | 换弹：5秒 | 子弹缓慢移动",
            damage = 25,
            fireRate = "1.5秒 (0.67发/秒)",
            ammo = 1,
            bulletSpeed = 100,
            icon = "FT",
            color = {1, 0.5, 0}
        },
        lifedrain = {
            name = "Life Drain",
            description = "噬命武器。三连发，每击杀一名敌人永久提升1点伤害。每25击杀增加1点最大生命值。\n伤害：10 | 弹药：30 | 换弹：4秒 | 子弹速度：1750",
            damage = 10,
            fireRate = "1.0秒 (3连发)",
            ammo = 30,
            bulletSpeed = 1750,
            icon = "LD",
            color = {1, 0.2, 0.2}
        }
    },
    mods = {
        pistolFastMag = {
            name = "Fast Pistol Mag",
            weapon = "pistol",
            description = "手枪弹药+3",
            price = 1000,
            icon = "FM"
        },
        pistolExtMag = {
            name = "Extended Pistol Mag",
            weapon = "pistol",
            description = "手枪换弹时间-0.5秒",
            price = 1000,
            icon = "EM"
        },
        pistolDamage = {
            name = "Pistol Damage +3",
            weapon = "pistol",
            description = "手枪伤害+3",
            price = 3000,
            icon = "D3"
        },
        rifleFastMag = {
            name = "Fast Rifle Mag",
            weapon = "rifle",
            description = "步枪弹药+15",
            price = 3500,
            icon = "FM"
        },
        rifleExtMag = {
            name = "Extended Rifle Mag",
            weapon = "rifle",
            description = "步枪换弹时间-0.5秒",
            price = 3000,
            icon = "EM"
        },
        rifleDamage = {
            name = "Rifle Damage +2",
            weapon = "rifle",
            description = "步枪伤害+2",
            price = 3000,
            icon = "D2"
        },
        sniperDamage = {
            name = "Sniper Damage +10",
            weapon = "sniper",
            description = "狙击枪伤害+10",
            price = 3500,
            icon = "D10"
        },
        sniperPierce = {
            name = "Piercing Round",
            weapon = "sniper",
            description = "狙击子弹可穿透一个敌人",
            price = 6000,
            icon = "PR"
        },
        soulreaperPierce = {
            name = "Soul Reaper Pierce",
            weapon = "soulreaper",
            description = "子弹可穿透最多3名敌人，伤害每穿透一人减半",
            price = 3000,
            icon = "PP"
        },
        soulreaperDamage = {
            name = "Soul Reaper Damage +750",
            weapon = "soulreaper",
            description = "噬魂伤害增加750点",
            price = 5000,
            icon = "D750"
        },
        lasergunCapacity = {
            name = "Laser Gun Capacity",
            weapon = "lasergun",
            description = "激光枪充能上限+25",
            price = 5000,
            icon = "LC"
        },
        feastDualCore = {
            name = "双核核心",
            weapon = "feast",
            description = "饕宴弹药数量变为2",
            price = 50000,
            icon = "DC"
        },
        feastHighExplosive = {
            name = "高爆核心",
            weapon = "feast",
            description = "每秒持续伤害提升至40点，爆炸伤害提升至2222点",
            price = 50000,
            icon = "HE"
        },
        lifedrainExtendedMag = {
            name = "扩容弹匣",
            weapon = "lifedrain",
            description = "噬命弹药数量提升至50发",
            price = 50000,
            icon = "EM"
        },
        lifedrainSoulNourish = {
            name = "噬魂滋养",
            weapon = "lifedrain",
            description = "击杀敌人有30%概率回复5点生命值，满血则增加1点最大生命值",
            price = 60000,
            icon = "SN"
        },
        speedWalk = {
            name = "Speed Walk",
            weapon = "character",
            description = "走路速度+50",
            price = 1500,
            icon = "SW"
        },
        speedRun = {
            name = "Speed Run",
            weapon = "character",
            description = "跑步速度+75",
            price = 2000,
            icon = "SR"
        }
    },
    abilities = {
        heal = {
            name = "治疗",
            type = "主动技能",
            description = "使用后回复25点生命值\n冷却时间：30秒",
            price = 1500,
            icon = "HP",
            color = {0, 1, 0},
            cooldown = 30,
            effect = "立即回复25点生命值"
        },
        harvest = {
            name = "收割",
            type = "主动技能",
            description = "杀死血量低于5%的敌人，其他敌人受到等同于玩家血量的伤害\n冷却时间：90秒",
            price = 4000,
            icon = "HV",
            color = {1, 0.5, 0},
            cooldown = 90,
            effect = "处决低血量敌人，其余受玩家血量伤害"
        },
        siphon = {
            name = "虹吸",
            type = "主动技能",
            description = "10秒内，恢复所造成伤害的一半血量\n冷却时间：80秒",
            price = 6000,
            icon = "SH",
            color = {0.5, 0, 1},
            cooldown = 80,
            duration = 10,
            effect = "造成伤害的50%转化为生命值"
        },
        forcefield = {
            name = "禁闭立场",
            type = "主动技能",
            description = "弹开周围敌人并使其无法移动1.5秒\n冷却时间：30秒",
            price = 2000,
            icon = "FF",
            color = {0, 0.5, 1},
            cooldown = 30,
            effect = "击退并眩晕周围敌人"
        },
        degradation = {
            name = "降级打击",
            type = "主动技能",
            description = "将场上所有敌人转化为tank，Boss转化为easy_boss\n冷却时间：150秒",
            price = 10000,
            icon = "DG",
            color = {0.8, 0.2, 0.2},
            cooldown = 150,
            effect = "转化所有敌人类型"
        },
        dragonslayer = {
            name = "屠龙者",
            type = "被动技能",
            description = "对Boss造成的伤害+10%",
            price = 3000,
            icon = "DS",
            color = {1, 0.8, 0},
            effect = "对Boss伤害提高10%"
        },
        bloodthirst = {
            name = "嗜血",
            type = "被动技能",
            description = "每杀死一名敌人恢复1点血量，杀死Boss额外恢复19点",
            price = 8000,
            icon = "BT",
            color = {1, 0, 0},
            effect = "击杀回血，Boss给20点"
        },
        constant = {
            name = "恒动",
            type = "被动技能",
            description = "无法跑步，但速度提升至260，不消耗体力",
            price = 3000,
            icon = "CM",
            color = {1, 1, 0},
            effect = "恒定速度260，无体力消耗"
        }
    },
    difficulties = {
        easy = {
            name = "Easy",
            description = "适合新手。敌人属性基础，没有特殊单位。",
            enemyStats = "基础血量、速度",
            specialEnemies = "无",
            rewardMultiplier = "1x"
        },
        medium = {
            name = "Medium",
            description = "适合有一定经验的玩家。敌人更强，出现精英敌人。",
            enemyStats = "血量+50%，速度+10-20%",
            specialEnemies = "精英敌人 (Elite)",
            rewardMultiplier = "1.5x"
        },
        hard = {
            name = "Hard",
            description = "挑战模式。敌人大幅增强，出现突击敌人。",
            enemyStats = "血量+100%，速度+30%",
            specialEnemies = "精英、突击敌人",
            rewardMultiplier = "2x"
        }
    }
}

-- 百科当前查看的分类和索引
bestiaryState = {
    category = "enemies",
    index = 1,
    scroll = 0
}

-- ===== 获取当前分类的条目列表 =====
function getBestiaryList()
    local list = {}
    
    if bestiaryState.category == "enemies" then
        for k, v in pairs(bestiaryData.enemies) do
            table.insert(list, {id = k, data = v})
        end
    elseif bestiaryState.category == "weapons" then
        for k, v in pairs(bestiaryData.weapons) do
            table.insert(list, {id = k, data = v})
        end
    elseif bestiaryState.category == "mods" then
        for k, v in pairs(bestiaryData.mods) do
            table.insert(list, {id = k, data = v})
        end
    elseif bestiaryState.category == "abilities" then
        for k, v in pairs(bestiaryData.abilities) do
            table.insert(list, {id = k, data = v})
        end
    elseif bestiaryState.category == "difficulties" then
        for k, v in pairs(bestiaryData.difficulties) do
            table.insert(list, {id = k, data = v})
        end
    end
    
    -- 按名称排序
    table.sort(list, function(a, b) return a.data.name < b.data.name end)
    return list
end

-- ===== 获取当前显示的条目 =====
function getCurrentBestiaryEntry()
    local list = getBestiaryList()
    if #list == 0 then return nil end
    if bestiaryState.index < 1 then bestiaryState.index = 1 end
    if bestiaryState.index > #list then bestiaryState.index = #list end
    return list[bestiaryState.index]
end

-- ===== 绘制百科全书界面 =====
function handledrawBestiary()
    love.graphics.setFont(uiFont)

    local w, h = love.graphics.getDimensions()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    -- 标题
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local title = "BESTIARY"
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (w - titleWidth)/2, 10)
    
    -- 分类标签
    local tabWidth, tabHeight, startY = 100, 40, 90
    local spacing = 5
    local totalWidth = tabWidth * 5 + spacing * 4
    local firstX = math.max(10, (w - totalWidth) / 2)
    
    local categories = {
        { name = "ENEMIES", cat = "enemies", x = firstX },
        { name = "WEAPONS", cat = "weapons", x = firstX + tabWidth + spacing },
        { name = "MODS", cat = "mods", x = firstX + (tabWidth + spacing) * 2 },
        { name = "ABILITY", cat = "abilities", x = firstX + (tabWidth + spacing) * 3 },
        { name = "DIFF", cat = "difficulties", x = firstX + (tabWidth + spacing) * 4 }
    }
    
    love.graphics.setFont(uiFont)
    for _, cat in ipairs(categories) do
        local mx, my = love.mouse.getPosition()
        local hover = mx >= cat.x and mx <= cat.x + tabWidth and my >= startY and my <= startY + tabHeight
        
        if bestiaryState.category == cat.cat then
            love.graphics.setColor(0.8, 0.8, 1)
        elseif hover then
            love.graphics.setColor(0.6, 0.6, 0.9)
        else
            love.graphics.setColor(0.4, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", cat.x, startY, tabWidth, tabHeight, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(cat.name, cat.x, startY + 10, tabWidth, "center")
    end
    
    -- 左侧导航栏
    local listX, listY, listW, listH = 50, 150, 200, h - 200
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", listX, listY, listW, listH, 10)
    
    local list = getBestiaryList()
    local itemHeight = 30
    local visibleItems = math.floor(listH / itemHeight)
    
    if #list > visibleItems then
        local scrollBarHeight = listH * (visibleItems / #list)
        local scrollBarY = listY + (bestiaryState.scroll / (#list - visibleItems)) * (listH - scrollBarHeight)
        love.graphics.setColor(0.5, 0.5, 0.7)
        love.graphics.rectangle("fill", listX + listW - 10, scrollBarY, 8, scrollBarHeight, 4)
    end
    
    for i = 1, math.min(visibleItems, #list) do
        local idx = bestiaryState.scroll + i
        if idx <= #list then
            local entry = list[idx]
            if entry then
                local y = listY + (i-1) * itemHeight
                local isSelected = (idx == bestiaryState.index)
                
                if isSelected then
                    love.graphics.setColor(0.4, 0.4, 0.8)
                    love.graphics.rectangle("fill", listX + 5, y, listW - 15, itemHeight - 4, 5)
                end
                
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(uiFont)
                love.graphics.print(entry.data.name, listX + 10, y)
            end
        end
    end
    
    -- 右侧详情面板
    local detailX, detailY, detailW = 270, 150, w - 320
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", detailX, detailY, detailW, listH, 10)
    
    local currentEntry = getCurrentBestiaryEntry()
    if currentEntry and currentEntry.data then
        local data = currentEntry.data
        local x, y = detailX + 20, detailY + 20
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.print(data.name, x, y)
        
        love.graphics.setFont(uiFont)
        y = y + 50
        
        if bestiaryState.category == "enemies" then
            -- 敌人信息
            love.graphics.setColor(data.color[1], data.color[2], data.color[3])
            love.graphics.rectangle("fill", x, y, 30, 30)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Health: " .. data.health, x + 40, y)
            love.graphics.print("Damage: " .. data.damage, x + 40, y + 20)
            love.graphics.print("Speed: " .. data.speed, x + 40, y + 40)
            love.graphics.print("Score: " .. data.score, x + 40, y + 60)
            
            y = y + 90
            love.graphics.print("Description:", x, y)
            y = y + 25
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(data.description, x, y, detailW - 40)
            
        elseif bestiaryState.category == "weapons" then
            -- 武器信息
            love.graphics.setColor(data.color[1], data.color[2], data.color[3])
            love.graphics.rectangle("fill", x, y, 30, 30)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Damage: " .. data.damage, x + 40, y)
            love.graphics.print("Fire Rate: " .. data.fireRate, x + 40, y + 20)
            love.graphics.print("Ammo: " .. data.ammo, x + 40, y + 40)
            love.graphics.print("Bullet Speed: " .. data.bulletSpeed, x + 40, y + 60)
            
            y = y + 90
            love.graphics.print("Description:", x, y)
            y = y + 25
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(data.description, x, y, detailW - 40)
            
        elseif bestiaryState.category == "mods" then
            -- 模组信息
            love.graphics.print("Weapon: " .. string.upper(data.weapon), x, y)
            y = y + 30
            love.graphics.print("Effect: " .. data.description, x, y)
            y = y + 30
            love.graphics.print("Price: " .. data.price .. " Bits", x, y)
            
        elseif bestiaryState.category == "abilities" then
            -- 技能信息
            love.graphics.setColor(data.color[1], data.color[2], data.color[3])
            love.graphics.rectangle("fill", x, y, 30, 30)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(data.icon, x + 8, y + 5)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Type: " .. data.type, x + 40, y)
            love.graphics.print("Price: " .. data.price .. " Bits", x + 40, y + 20)
            
            y = y + 50
            if data.cooldown then
                love.graphics.print("Cooldown: " .. data.cooldown .. "秒", x, y)
                y = y + 25
            end
            if data.duration then
                love.graphics.print("Duration: " .. data.duration .. "秒", x, y)
                y = y + 25
            end
            love.graphics.print("Effect: " .. (data.effect or ""), x, y)
            y = y + 30
            love.graphics.print("Description:", x, y)
            y = y + 25
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(data.description, x, y, detailW - 40)
            
        elseif bestiaryState.category == "difficulties" then
            -- 难度信息
            love.graphics.print("Enemy Stats: " .. data.enemyStats, x, y)
            y = y + 30
            love.graphics.print("Special Enemies: " .. data.specialEnemies, x, y)
            y = y + 30
            love.graphics.print("Reward Multiplier: " .. data.rewardMultiplier, x, y)
            y = y + 40
            love.graphics.print("Description:", x, y)
            y = y + 25
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(data.description, x, y, detailW - 40)
        end
    end
    
    -- 返回提示
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(uiFont)
    love.graphics.print("Press ESC to return | Use ↑/↓ to navigate", 20, h - 30)
end

-- ===== 处理百科全书按键 =====
function handleBestiaryKeys(key)
    local list = getBestiaryList()
    if #list == 0 then return end
    
    if key == "up" then
        bestiaryState.index = bestiaryState.index - 1
        if bestiaryState.index < 1 then bestiaryState.index = 1 end
        
        local visibleItems = math.floor((love.graphics.getHeight() - 200) / 30)
        if bestiaryState.index < bestiaryState.scroll + 1 then
            bestiaryState.scroll = math.max(0, bestiaryState.index - 1)
        end
        
    elseif key == "down" then
        bestiaryState.index = bestiaryState.index + 1
        if bestiaryState.index > #list then bestiaryState.index = #list end
        
        local visibleItems = math.floor((love.graphics.getHeight() - 200) / 30)
        if bestiaryState.index > bestiaryState.scroll + visibleItems then
            bestiaryState.scroll = bestiaryState.index - visibleItems
        end
    end
end

-- ===== 处理百科全书鼠标点击 =====
function handleBestiaryMouse(x, y, button)
    if button ~= 1 then return end
    
    local w, h = love.graphics.getDimensions()
    
    -- 分类标签点击
    local tabWidth, tabHeight, startY = 100, 40, 90
    local spacing = 5
    local totalWidth = tabWidth * 5 + spacing * 4
    local firstX = math.max(10, (w - totalWidth) / 2)
    
    local categories = {
        { name = "ENEMIES", cat = "enemies", x = firstX },
        { name = "WEAPONS", cat = "weapons", x = firstX + tabWidth + spacing },
        { name = "MODS", cat = "mods", x = firstX + (tabWidth + spacing) * 2 },
        { name = "ABILITY", cat = "abilities", x = firstX + (tabWidth + spacing) * 3 },
        { name = "DIFF", cat = "difficulties", x = firstX + (tabWidth + spacing) * 4 }
    }
    
    for _, cat in ipairs(categories) do
        if x >= cat.x and x <= cat.x + tabWidth and y >= startY and y <= startY + tabHeight then
            bestiaryState.category = cat.cat
            bestiaryState.index = 1
            bestiaryState.scroll = 0
            return
        end
    end
    
    -- 左侧列表点击
    local listX, listY, listW, listH = 50, 150, 200, h - 200
    if x >= listX and x <= listX + listW and y >= listY and y <= listY + listH then
        local itemHeight = 30
        local relativeY = y - listY
        local itemIndex = math.floor(relativeY / itemHeight) + 1 + bestiaryState.scroll
        
        local list = getBestiaryList()
        if itemIndex >= 1 and itemIndex <= #list then
            bestiaryState.index = itemIndex
        end
    end
end

-- ===== 处理百科全书鼠标滚轮 =====
function handleBestiaryWheel(y)
    local list = getBestiaryList()
    local visibleItems = math.floor((love.graphics.getHeight() - 200) / 30)
    
    if y > 0 then
        bestiaryState.scroll = math.max(0, bestiaryState.scroll - 3)
    elseif y < 0 then
        bestiaryState.scroll = math.min(#list - visibleItems, bestiaryState.scroll + 3)
    end
end

function love.wheelmoved(x, y)
    if gameState == "bestiary" then
        handleBestiaryWheel(y)
    end
end

print("✓ bestiary.lua loaded")
return bestiaryData