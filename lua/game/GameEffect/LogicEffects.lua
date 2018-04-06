local ui = _G["ui"]
local newSprite = ui.sprite

--资源收集效果
local ResourceCollectionEffect= class2("ResourceCollectionEffect",function()
    return ui.node()
end)

GEngine.export("ResourceCollectionEffect", ResourceCollectionEffect)

function ResourceCollectionEffect:ctor(num)
    self.number = num or 5
    self:runAnimation()
end

function ResourceCollectionEffect:runAnimation()
    local sceneType=GMethod.loadScript("game.View.Scene").sceneType
    if sceneType=="operation" then
        music.play("sounds/coin_get.mp3")
    else
        music.play("sounds/shot_coin_01.mp3")
    end
    local function createRes()
        local temp=ui.animateSprite(0.6, "resMoney_", 7, {isRepeat=true,plist="images/resMoney.plist"})
        temp:setPosition(0,0)
        self:addChild(temp)
        local speedX=80
        local g=700
        local t=math.random()+0.4
        if t>0.8 then
            t=0.8
        end
        if math.random(4)==1 then
            speedX=20
        end
        local w=speedX*t
        local h=0.5*g*t*t
        if math.random(2)==2 then
            w=-w
        end
        local spawn1=ui.action.spawn({ui.action.moveBy(t,w,0),ui.action.easeSineOut(ui.action.moveBy(t,0,h))})

        local t2=math.random()+0.2
        if t2>0.6 then
            t2=0.6
        end
        local w2 = speedX*t2
        if w>0 then
            w=w2
        else
            w=-w2
        end
        h=-0.5*g*t2*t2
         local spawn2=ui.action.spawn({ui.action.moveBy(t2,w,0),ui.action.easeSineIn(ui.action.moveBy(t2,0,h))})
        temp:runAction(ui.action.sequence({spawn1,spawn2,"remove"}))
        temp:setOpacity(0.8*255)
        temp:runAction(ui.action.sequence({{"fadeTo",t*0.2,255},{"delay",(t+t2)*0.8},{"fadeOut",t2*0.2},"remove"}))
        
        self:runAction(ui.action.sequence({{"delay",t+t2+1},"remove"}))
    end
    local rep=ui.action.arepeat(ui.action.sequence({{"call",createRes},{"delay",0.1}}),self.number)
    self:runAction(rep)
end
--显示资源数量
function ResourceCollectionEffect:displayNumber(number,rate)
    if rate then
        number = number..'X'..rate
    end
    local temp = ui.label(StringManager.getString(number), General.font1, 47, {color={246,249,9}})
    display.adapt(temp, 0, 40, GConst.Anchor.Center)
    self:addChild(temp,2)
    temp:runAction(ui.action.sequence({{"delay",0.4},{"fadeTo",0.4,0}}))
    temp:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(0.8,0,200)),"remove"}))
end

--特别处理一下部分音效

local _soundCache = {}
local function _onSpecialMusic(sound, clearTime, maxTime, disTime)
    if not _soundCache[sound] then
        -- 当前同时存在的ID数量、ID列表、清零倒计时、最大倒计时列表、间隔时间
        _soundCache[sound] = {0, {}, 0, {}, 0}
    end
    local cache = _soundCache[sound]
    cache[3] = clearTime
    if cache[5] <= 0 then
        local efId = music.play(sound)
        if efId then
            cache[5] = disTime
            cache[1] = cache[1] + 1
            table.insert(cache[2], efId)
            table.insert(cache[4], maxTime)
        end
    end
end

local function _updateSpecialMusic(diff)
    for k, v in pairs(_soundCache) do
        if v[1] > 0 then
            v[3] = v[3] - diff
            if v[3] <= 0 then
                for i=1, v[1] do
                    music.stop(v[2][i])
                end
                v[1] = 0
                v[2] = {}
                v[3] = 0
                v[4] = {}
                v[5] = 0
            else
                for i=v[1], 1, -1 do
                    v[4][i] = v[4][i] - diff
                    if v[4][i] <= 0 then
                        v[1] = v[1] - 1
                        table.remove(v[2], i)
                        table.remove(v[4], i)
                    end
                end
                v[5] = v[5] - diff
            end
        end
    end
end

local function _stopAllSpecial()
    for k, v in pairs(_soundCache) do
        if v[1] > 0 then
            for i=1, v[1] do
                music.stop(v[2][i])
            end
        end
    end
    _soundCache = {}
end

--所有逻辑动画

local _effectBuffer = {}
local _effectBufferUpdateId = nil
local _effectManager = EffectMaker:getInstance()

local function addEffectBuffer(effect, ...)
    table.insert(_effectBuffer, {effect, ...})
end

local function updateEffectBuffer(diff)
    local max = 10
    local buffer = _effectBuffer
    while buffer[1] and max > 0 do
        buffer[1][1].doAnimation(unpack(buffer[1]))
        max = max - 1
        table.remove(buffer, 1)
    end
    _updateSpecialMusic(diff)
end

local function bufferedRunAnimate(self, ...)
    if _effectBufferUpdateId then
        addEffectBuffer(self, ...)
    else
        self:doAnimation(...)
    end
end

local LogicEffects = {}
GEngine.export("LogicEffects", LogicEffects)

LogicEffects.onSpecialMusic = _onSpecialMusic

function LogicEffects.setBufferUse(enable)
    _effectBuffer = {}
    if enable then
        if not _effectBufferUpdateId then
            _effectBufferUpdateId = GMethod.schedule(updateEffectBuffer, 0, false)
        end
    else
        if _effectBufferUpdateId then
            GMethod.unschedule(_effectBufferUpdateId)
            _effectBufferUpdateId = nil
            _stopAllSpecial()
        end
    end
end

--建筑爆炸效果

local _bombItems = {7, 4, 3}
local BombEffect = {runAnimation = bufferedRunAnimate}

BombEffect.effectId3 = _effectManager:registerAction("[\"spawn\",[[\"sequence\",[[\"easeSineOut\",[\"moveBy\",0.25,0,235]],[\"easeSineIn\",[\"moveBy\",0.15,0,-235]],[\"easeSineOut\",[\"moveBy\",0.11,0,13]],[\"easeSineIn\",[\"moveBy\",0.1,0,-13]]]],[\"sequence\",[[\"delay\",0.61],[\"fadeOut\",0.5]]]]]")
BombEffect.effectId2 = _effectManager:registerAction("[\"spawn\",[[\"sequence\",[[\"easeSineOut\",[\"moveBy\",0.25,0,213]],[\"easeSineIn\",[\"moveBy\",0.21,0,-213]],[\"easeSineOut\",[\"moveBy\",0.11,0,33]],[\"easeSineIn\",[\"moveBy\",0.1,0,-33]],[\"easeSineOut\",[\"moveBy\",0.08,0,11]],[\"easeSineIn\",[\"moveBy\",0.08,0,-11]]]],[\"sequence\",[[\"delay\",0.683],[\"fadeOut\",0.5]]]]]")
BombEffect.effectId1 = _effectManager:registerAction("[\"spawn\",[[\"sequence\",[[\"easeSineOut\",[\"moveBy\",0.25,0,155]],[\"easeSineIn\",[\"moveBy\",0.25,0,-155]],[\"easeSineOut\",[\"moveBy\",0.18,0,47]],[\"easeSineIn\",[\"moveBy\",0.08,0,-47]],[\"easeSineOut\",[\"moveBy\",0.08,0,19]],[\"easeSineIn\",[\"moveBy\",0.08,0,-19]]]],[\"sequence\",[[\"delay\",0.92],[\"fadeOut\",0.5]]]]]")
function BombEffect:doAnimation(view, cx, cy, cr, seed, num, tflag)
    music.play("sounds/destroy.mp3")
    seed = math.floor(seed)
    local rd = RdUtil.new(seed)
    local bg = ui.node()
    display.adapt(bg, cx, cy)
    view:addChild(bg, 4000 - cy)
    if not tflag then
        tflag = 7
    end
    local rtypes = {}
    local ti = 0
    while tflag > 0 do
        ti = ti+1
        if tflag % 2 == 1 then
            tflag = tflag - 1
            table.insert(rtypes, ti)
        end
        tflag = tflag / 2
    end
    local rtypenum = #rtypes
    local snum = 0

    local temp
    temp = ui.particle("particles/partiBuildBomb.json")
    temp:setGlobalZOrder(0)
    display.adapt(temp, cx, cy)
    view:addChild(temp, 4000)
    if cr > 2 then
        temp:setScale(cr*0.6)
    end
    local effectManager = _effectManager
    -- local baseAngle = rd:randomInt(360)
    -- local deltaAngle = 360/num
    for i=1, num do
        local rtype = rtypes[rd:randomInt(rtypenum)]
        local rid = rd:randomInt(_bombItems[rtype])
        if rtype == 2 and rid == 3 then
            snum = snum + 1
            if snum >= 2 then
                rid = 1
            end
        end
        temp = newSprite("bombItem" .. rtype .. "_" .. rid .. ".png")
        -- baseAngle = baseAngle + deltaAngle * (rd:random()*100+50)/100
        -- local angle = math.rad(baseAngle)
        local angle = math.rad(rd:randomInt(360))
        local rinit = rd:randomInt(360)
        local dinit = (rd:random() + 0.5) * (cr/4)
        local asin = math.sin(angle)
        local acos = math.cos(angle)
        -- local dpercent = rd:randomInt(70)+10
        -- local hpercent = math.sqrt(10000 - dpercent*dpercent)
        -- local hinit = hpercent/100*cr*69
        -- local htotal = hinit * 2
        if temp then
            temp:setRotation(rinit)
            display.adapt(temp, dinit*asin*92, dinit*acos*69, GConst.Anchor.Center)
            bg:addChild(temp)
            if rtype == 3 then
                effectManager:runActionById(temp, BombEffect.effectId3)
                local dmov = rd:random()*2 + 2 - dinit
                temp:runAction(ui.action.moveBy(0.61, dmov * asin * 92, dmov * acos * 69))
                temp:runAction(ui.action.rotateBy(0.61, asin * 360))
            elseif rtype == 2 then
                effectManager:runActionById(temp, BombEffect.effectId2)
                local dmov = rd:random()*3 + 2 - dinit
                temp:runAction(ui.action.moveBy(0.83, dmov * asin * 92, dmov * acos * 69))
                temp:runAction(ui.action.rotateBy(0.83, asin * 360))
            else
                effectManager:runActionById(temp, BombEffect.effectId1)
                local dmov = rd:random()*2 + 3 - dinit
                temp:runAction(ui.action.moveBy(0.92, dmov * asin * 92, dmov * acos * 69))
            end
        end
    end
    bg:runAction(ui.action.sequence({{"delay", 2}, "remove"}))
end

LogicEffects.Bomb = BombEffect

local SPFontEffect = {runAnimation = bufferedRunAnimate}

--0 文字 1 扣血 2 加血 3 MISS 4 大字扣血

function SPFontEffect:doAnimation(view, x, y, text, ftype)
    local label
    if ftype == 0 then
        label = ui.label(text, General.font1, 48)
        ui.setColor(label, {91, 181, 243})
        display.adapt(label, x+164, y, GConst.Anchor.Center)
        label:setSkewX(30)
        label:setScaleX(0.7)
        label:setScaleY(0.9)
        label:runAction(ui.action.sequence({
            {"spawn", {{"skewBy", 0.083, -40, 0}, {"scaleTo", 0.083, 1, 0.82}, {"moveBy", 0.083, -178, 0}}},
            {"spawn", {{"skewBy", 0.083, 10, 0}, {"scaleTo", 0.083, 1, 1}, {"moveBy", 0.083, 14, 0}}},
            {"delay", 0.25},
            {"fadeOut", 0.33},
            "remove"
        }))
        view:addChild(label, 4000 - y)
    else
        label = ui.node()
        local temp
        local bs = 1
        if ftype == 3 then
            temp = newSprite("spfont_miss_r.png")
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            label:addChild(temp)
            label:setContentSize(temp:getContentSize())
        else
            local sprefix = "spfont_red_"
            local width = 0
            local height = 95
            if ftype == 2 then
                sprefix = "spfont_green_"
                height = 59
            elseif ftype == 1 then
                bs = 0.62
            end
            local tb = {}
            local num = math.floor(tonumber(text))
            while num>0 do
                local n = num%10
                table.insert(tb, n)
                num = (num - n) / 10
            end

            for i=#tb,1,-1 do
                local n = tb[i]
                temp = newSprite(sprefix .. n .. ".png")
                display.adapt(temp, width, 0, GConst.Anchor.LeftBottom)
                label:addChild(temp)
                local size = temp:getContentSize()
                width = width + size.width
                if i>1 then
                    width = width + height/20
                end
            end
            label:setContentSize(width, height)
        end
        display.adapt(label, x, y, GConst.Anchor.Center)
        label:setOpacity(0)
        if ftype == 2 then
            label:setScale(3.5 * bs)
            label:runAction(ui.action.sequence({
                {"spawn", {{"fadeIn", 0.167}, {"scaleTo", 0.167, 0.85 * bs, 0.85 * bs}}},
                {"scaleTo", 0.117, 1.5 * bs, 1.5*bs},
                {"scaleTo", 0.133, bs, bs},
                {"delay", 0.25},
                {"spawn", {{"fadeOut", 0.25}, {"moveBy", 0.25, 0, 40}}},
                "remove"
            }))
            view:addChild(label, 12000 - y)
        else
            label:setScale(3 * bs)
            label:runAction(ui.action.sequence({
                {"spawn", {{"fadeIn", 0.1}, {"scaleTo", 0.1, 0.9 * bs, 0.9 * bs}}},
                {"scaleTo", 0.08, 1.3 * bs, 1.3*bs},
                {"scaleTo", 0.08, bs, bs},
                {"delay", 0.25},
                {"spawn", {{"fadeOut", 0.25}, {"moveBy", 0.25, 0, 40}}},
                "remove"
            }))
            if ftype == 1 then
                view:addChild(label, 8000 - y)
            else
                view:addChild(label, 16000 - y)
            end
        end
    end
end

LogicEffects.SPFont = SPFontEffect

local DeathNormal = {runAnimation = bufferedRunAnimate}
function DeathNormal:doAnimation(bg, x, y)
    local effectManager = _effectManager
    local effectId = effectManager:registerGameEffect("game/GameEffect/effectsConfig/DeathEffect.json")
                
    effectManager:addGameEffect(bg, effectId, "normalDeath", x, y, 0)
end
LogicEffects.DeathNormal = DeathNormal

local DeathZombie = {runAnimation = bufferedRunAnimate}
function DeathZombie:doAnimation(bg, x, y)
    local effectManager = _effectManager
    local effectId = effectManager:registerGameEffect("game/GameEffect/effectsConfig/DeathEffect.json")
                
    effectManager:addGameEffect(bg, effectId, "zombieDeath", x, y, 0)
end
LogicEffects.DeathZombie = DeathZombie

local DeathGod = {runAnimation = bufferedRunAnimate}
function DeathGod:doAnimation(bg, x, y, scal)
    local effectManager = _effectManager
    local effectId = effectManager:registerGameEffect("game/GameEffect/effectsConfig/DeathEffect.json")

    local upNode = ui.node()
    upNode:setPosition(x, y)
    bg:addChild(upNode)
    upNode:setScale(scal or 1)

    effectManager:addGameEffect(upNode, effectId, "godDeath", 0, 0, 0)
    upNode:runAction(ui.action.sequence({{"delay",54/60},"remove"}))
end
LogicEffects.DeathGod = DeathGod

local HeroEffect = {runAnimation = bufferedRunAnimate}
function HeroEffect:doAnimation(effectClass, attacker, defencer, params)
    if attacker and attacker.deleted or defencer and defencer.deleted then
        return
    end
    effectClass.new(params)
end
LogicEffects.HeroEffect = HeroEffect
