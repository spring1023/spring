
local path = "game.Person.Hero."
_G["AvtControler"] = GMethod.loadScript('game.Person.AvtControler')
_G["Avater"] = GMethod.loadScript('game.Person.Avater')
_G["AvtInfo"] = GMethod.loadScript('game.Person.AvtInfo')
GodBeast = GMethod.loadScript("game.Person.GodBeast")

--此处先临时添加一些人物的动画插件
local BuilderV = {}

local BUILDING_ACTION = {{8,-18,1},{18,-6,1},{8,6,-1},{-8,6,-1},{-18,-6,1},{-8,-18,1}}
function BuilderV:showSkillEffect()
    local ainfo = BUILDING_ACTION[self.direction]
    local x,y = self.personView:getPosition()
    local builderEffect = ui.animateSprite(1.1, "weixiu_g", 11, {isRepeat=true, plist="effects/weixiu_guang.plist"})
    display.adapt(builderEffect, x+ainfo[1], y+ainfo[2], GConst.Anchor.Center)
    self.view:addChild(builderEffect, ainfo[3])
    local blend = {src=770, dst=772}
    builderEffect:setBlendFunc(blend)
    -- builderEffect:runAction(ui.action.sequence({{"delay", self.allActionTime-self.actionTime}, "remove"}))
    self.effectView = builderEffect
end

local NpcFemaleV = {}
function NpcFemaleV:showSkillEffect()
    local dir = self.direction
    local x, y = self.view:getPosition()
    local effect = EffectControl.new("npc4.json", {x=x, y=y, scaleX=dir > 3 and 1 or -1})
    effect:addEffect(self.scene.effects)
end

local NpcMaleV = {}
function NpcMaleV:showSkillEffect()
    local x, y = self.view:getPosition()
    local effect = EffectControl.new("npc5.json", {x=x, y=y})
    effect:addEffect(self.scene.effects)
end

PersonUtil = {}
local cset = {
    [1] = {AvtInfo, BuilderV, AvtControler},
    [4] = {AvtInfo, NpcFemaleV, AvtControler},
    [5] = {AvtInfo, NpcMaleV, AvtControler},
    [1001] = GMethod.loadScript(path.."Swat"),    --巨警神盾
    [1002] = GMethod.loadScript(path.."Sniper"),    --特种狙击手
    [1003] = GMethod.loadScript(path.."HealthCare"),    --特效医护

    [2001] = GMethod.loadScript(path.."Metalman"),    --金属人
    [2002] = GMethod.loadScript(path.."Vampire"),    --吸血鬼
    [2003] = GMethod.loadScript(path.."Scissorhand"),    --剪刀手
    [2004] = GMethod.loadScript(path.."Swordwoman"),    --女剑仙
    [2005] = GMethod.loadScript(path.."Catwoman"),    --猫女

    [3001] = GMethod.loadScript(path.."KingKongWolf"),    --金刚狼
    [3002] = GMethod.loadScript(path.."Captain"),    --美国队长
    [3003] = GMethod.loadScript(path.."Spiderman"),    --蜘蛛侠
    [3004] = GMethod.loadScript(path.."FutureWarrior"),    --未来战士
    [3005] = GMethod.loadScript(path.."StormFemale"),    --风暴女
    [3006] = GMethod.loadScript(path.."Batman"),    --蝙蝠侠
    [3007] = GMethod.loadScript(path.."Jakiro"),    --双头龙
    [3008] = GMethod.loadScript(path.."Beek"),    --比克神

    [4001] = GMethod.loadScript(path.."Doraemon"), --哆啦A梦    @@@@@@@@
    [4002] = GMethod.loadScript(path.."SaintSeiya"),  --圣斗士
    [4003] = GMethod.loadScript(path.."EVA"),  --EVA
    [4004] = GMethod.loadScript(path.."Saiyan"),  --赛亚人        @@@@@@@@
    [4005] = GMethod.loadScript(path.."Minister"),  --牧师
    [4006] = GMethod.loadScript(path.."Baymax"), --大白
    [4007] = GMethod.loadScript(path.."Panda"),  --熊猫
    [4008] = GMethod.loadScript(path.."Warlock"),    --术士
    [4009] = GMethod.loadScript(path.."Athena"),    --雅典娜       @@@@@@@@
    [4010] = GMethod.loadScript(path.."Thor"),  --雷神            @@@@@@@@
    [4011] = GMethod.loadScript(path.."Magneto"),    --万磁王     @@@@@@@@
    [4012] = GMethod.loadScript(path.."HouYi"),    --后羿         @@@@@@@@
    [4013] = GMethod.loadScript(path.."Gouda"),    --高达         @@@@@@@@
    [4014] = GMethod.loadScript(path.."Naruto"),    --旋涡鸣人      @@@@@@@@
    [4015] = GMethod.loadScript(path.."Uchiha"),    --宇智波       @@@@@@@@
    [4016] = GMethod.loadScript(path.."Zeus"),    --宙斯         @@@@@@@@
    [4017] = GMethod.loadScript(path.."Superman"),    --超人
    [4018] = GMethod.loadScript(path.."Ironman"),    --钢铁侠     @@@@@@@@
    [4019] = GMethod.loadScript(path.."Traxex"),   --黑弓         @@@@@@@@
    [4020] = GMethod.loadScript(path.."DragonTurtle"),    --龙龟  @@@@@@@@
    [4021] = GMethod.loadScript(path.."Shaman"),   --萨满         @@@@@@@@
    [4022] = GMethod.loadScript(path.."Kurosaki"),   --死神       @@@@@@@@
    [4023] = GMethod.loadScript(path.."Hulk"),    --绿巨人         @@@@@@@@
    [4024] = GMethod.loadScript(path.."Goku"),   --齐天大圣         @@@@@@@@
    [4030] = GMethod.loadScript(path.."Cleopatra"),   --埃及艳后         @@@@@@@@
    [4031] = GMethod.loadScript(path.."Chopper"),   --乔巴         @@@@@@@@
    [4032] = GMethod.loadScript(path.."Deadpool"),   --死侍         @@@@@@@@
    [4033] = GMethod.loadScript(path.."Heibao"),    --黑豹         @@@@@@@@

    [9001] = GMethod.loadScript(path.."MacGunZb"),   --机枪僵尸
    [9002] = GMethod.loadScript(path.."MissileZb"),   --导弹僵尸
    [9003] = GMethod.loadScript(path.."HammerZb"),   --铁锤僵尸
    [9004] = GMethod.loadScript(path.."ButcherZb"),   --屠夫僵尸
    [9005] = GMethod.loadScript(path.."TriangleZb"),   --三角头僵尸
    [9006] = GMethod.loadScript(path.."ChaserZb"),   --追击者
}

--cset[4002] = Goku
local function isBeast(id)
    if not id  then
        return
    end
    if 8000<id and id<9000 then
        return 3
    elseif 800<id and id<820 then
        return 1
    end
end

function PersonUtil.newPersonData(...)
    local ret = {}
    local params = {...}
    for _, info in ipairs(params) do
        for k, v in KTPairs(info) do
            ret[k] = v
        end
    end
    return ret
end

function PersonUtil.M(...)
    local instance
    local params = {...}

    if params.person and cset[params[1].person.id] then
        instance = cset[params[1].person.id][1].new(...)
    elseif isBeast(params[1].person.id) then
        local id = params[1].person.id
        if id<1000 then
            id = id*10
        end
        local gtype = math.floor((id-8000)/10)
        local path = "game.Person.GodBeast."
        GEngine.lockG(false)
        instance = GMethod.loadScript(path.."Beast"..gtype)[1].new(...)
        GEngine.lockG(true)
    else
        instance = AvtInfo.new(...)
    end
    return instance
end

function PersonUtil.V(...)

    local instance = Avater.new(...)
    local params = {...}
    if cset[params[1]] then
        for k, v in pairs(cset[params[1]][2]) do
            instance[k] = v
        end
    elseif isBeast(params[1]) then
        local id = params[1]
        if id<1000 then
            id = id*10
        end
        local gtype = math.floor((id-8000)/10)
        local path = "game.Person.GodBeast."
        GEngine.lockG(false)
        for k, v in pairs(GMethod.loadScript(path.."Beast"..gtype)[2]) do
            instance[k] = v
        end
        GEngine.lockG(true)
    end
    return instance
end

function PersonUtil.C(params)

    --params.person.id = 9001
    local instance
    if params.person and cset[params.person.id] then
        instance = cset[params.person.id][3].new(params)
    elseif isBeast(params.person and params.person.id) then       --尾兽
        local id = params.person.id
        if id<1000 then
            id = id*10
        end
        local gtype = math.floor((id-8000)/10)
        local path = "game.Person.GodBeast."
        GEngine.lockG(false)
        instance = GMethod.loadScript(path.."Beast"..gtype)[3].new(params)
        GEngine.lockG(true)
    else
        instance = AvtControler.new(params)
    end
    return instance
end

















