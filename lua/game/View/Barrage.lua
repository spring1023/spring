--[[
@brief: 跑马灯效果
@author: aoyue
@date: 2017.12.27
@details:
--]]
local Barrage=class2("Barrage",function ()
    local bgView=ui.node()
    display.adapt(bgView,0,0,GConst.Anchor.Center)
    return bgView
end)
--[[
@brief: 构造函数 创建一个计时器 允许Barrage对象弹出弹幕
@author: aoyue
@date: 2018.1.2
--]]
function Barrage:ctor()
    self.retryTime = 0
    self.permitPush=true
    self.barrageList={}
    self.received=true      --防止重复发送请求
    self:requestBarrage()
    self.count=0

    GameEvent.bindEvent(self, "RefreshBarrage", self, self.updateBarrageForce)
end
--[[
@brief: 将接收到的Barrage参数加入堆栈
@author: aoyue
@date: 2017.12.27
--]]
function Barrage:addBarrage(params)
    table.insert(self.barrageList,params)
end
--[[
@brief: 检测，主要是为了防止多条跑马灯叠在一起的情况 将堆栈中的信息取出
@author: aoyue
@date: 2017.12.27
--]]
function Barrage:checkBarrage(diff)
    if not self.barrageList then
        return
    end
    self.len=#self.barrageList
    if self.len == 0 then
        return
    end
    if self.permitPush then
        self.permitPush=false
        local params=table.remove(self.barrageList,1)
        if params then
            self:updateBarrage(params)
        end
    end
end

--[[
@brief: 向view中加入跑马灯效果
@author: aoyue
@date: 2017.12.27
--]]
function Barrage:updateBarrage(params)

    local barrageNode=ui.node({0,0})
    if General.language == "AR" or General.language == "IR" then
        display.adapt(barrageNode,-900,0,GConst.Anchor.Center)
    else
        display.adapt(barrageNode,900,0,GConst.Anchor.Center)
    end
    self:addChild(barrageNode,2)

    local pStr=params.str or " "
    local type,userName,heroId=params.type or " ",params.userName or " ",params.heroId or " "
    --print(type,userName,heroId)
    if not self.barrageBg then
        local barrageBg = ui.sprite("images/choukaname2.png",{1224,58})
        barrageBg:setOpacity(190)
        display.adapt(barrageBg,0,0,GConst.Anchor.Center)
        self:addChild(barrageBg,1)
        self.barrageBg=barrageBg
    else
        self.barrageBg:setOpacity(190)
    end
    local heroName=GameLogic.getItemName(const.ItemHero, heroId)
    local str="你数数这是不是标准的十四个字"
    if type=="1" then
        --抽到ur英雄
        str=Localizef("extractHeroNewBroadCast",{userName=userName,heroName=heroName})
    elseif type=="2" then
        --合成英雄
        str=Localizef("mergeNewHeroBroadCast",{userName=userName,heroName=heroName})
    elseif type=="3" then
        --合成装备
        str=Localizef("mergeNewEquipBroadCast",{userName=userName,heroName=heroName})
    elseif type=="4" then
        --英雄觉醒
        str=Localizef("heroAwackBroadCast",{userName=userName,heroName=heroName})
    elseif type=="5" then
        --闯关站通关
        str=Localizef("heroPveBroadCast",{userName=userName,heroName=heroName})
    elseif type=="6" then
        --英雄试炼
        str=Localizef("heroTrailBroadCast",{userName=userName})
    elseif type=="7" then
        --英雄竞技场登顶
        str=Localizef("heroArenaBroadCast",{userName=userName})
    elseif type=="8" then
        --第一联盟盟主上线
        str=Localizef("bestUnionLordOnline",{userName=userName,unionName=heroId})
    elseif type=="9" then
        --最强玩家上线
        str=Localizef("yourBabiIsOnline",{userName=userName})
    end

    local barrageLabel=ui.label(str,General.font5,32,{color={255,255,255}})
    display.adapt(barrageLabel,0,0,GConst.Anchor.Center)
    barrageNode:addChild(barrageLabel)
    local tx = (General.language == "AR" or General.language == "IR") and 1250 or -1250
    barrageNode:runAction(ui.action.sequence{{"moveTo",9,tx,0},"remove",{"call",function()
        self.permitPush=true
        self:checkBarrage()
        if self.len == 0 then
            self.barrageBg:runAction(ui.action.fadeOut(1.5))
        end
    end}})
end
--==============================--
--desc:套用聊天室的接收逻辑
--time:2018-01-15 04:05:49
--@return
--==============================--
function Barrage:requestBarrage()
    if self.len and self.len > 0 then
        return
    end
    local since = self.since or GameLogic.getSTime()-40
    local cid = -3
    if self.received and self.retryTime < GameLogic.getSTime() then
        self.received = false
        self.since = since
        _G["GameNetwork"].request("recv",{cid = cid,since = since},function(isSuc,data)
            self.received = true
            if isSuc and data.messages and #(data.messages) > 0 then
                for i,v in ipairs(data.messages) do
                    self.since=v[4]
                    local ug = type(v[6]) == "string" and json.decode(v[6]) or v[6]
                    local msg = {uid = v[1],name = v[2],text = v[3],time = v[4],ug = ug,mtype = v[7],cid = cid}
                    self:addBarrage({type=msg.text,userName=msg.name,heroId=msg.ug})
                end
            else
                self.retryTime = GameLogic.getSTime() + 60
            end
        end)
    end
end

function Barrage:updateBarrageForce()
    self.retryTime = 0
end

return Barrage
