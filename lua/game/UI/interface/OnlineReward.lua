local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local OnlineReward = class2("OnlineReward",function()
    return ui.node({220,186},0,false)
end)
-- local zhiyuan = GMethod.loadScript("game.UI.dialog.zhiyuan")
local zhiyuan = GMethod.loadScript("game.UI.NewDialog.onlineReward_dialog")

function OnlineReward:ctor()
    self.state = 0  --不可领取  1可领取
    self:initAnimate()
    RegTimeUpdate(self, function()
        self:update()
    end, 1)
    self.context = GameLogic.getUserContext()
    local temp = ui.button({220,186},nil,{})
    display.adapt(temp,0,0,GConst.Anchor.LeftBottom)
    self:addChild(temp)
    temp:setTouchThrowProperty(true,true)
    temp:setListener(function()
        display.showDialog(zhiyuan.new({olr=self}))
    end)
end

-- 1-10是收宝箱的动作
-- 剩下两个休闲动作
-- 21-23是收一下爪子的动作
-- 31-38是没宝箱也在收宝箱的动作
-- 休闲动作播的时候随机播 尽量不要一只重复这两个动作 休息一下再动
function OnlineReward:loadAnimate1()
    local num = 10
    self.animateSp = ui.animateSprite(1,"onlineReward_",num,{beginNum = 1,isRepeat = true})
    display.adapt(self.animateSp,0,0,GConst.Anchor.LeftBottom)
    self:addChild(self.animateSp)
end

function OnlineReward:loadAnimate2()
    local num = 3
    local animate = {}
    animate[1] = ui.animate(0.1*num, "onlineReward_", num, {beginNum = 21})
    num = 8
    animate[2] = ui.animate(0.1*num, "onlineReward_", num, {beginNum = 31})
    self.animateSp = ui.sprite("onlineReward_1.png")
    display.adapt(self.animateSp,0,0,GConst.Anchor.LeftBottom)
    self:addChild(self.animateSp)
    local function run()
        local num = 3
        local animate = {}
        animate[1] = ui.animate(0.1*num, "onlineReward_", num, {beginNum = 21})
        num = 8
        animate[2] = ui.animate(0.1*num, "onlineReward_", num, {beginNum = 31})
        self.animateSp:runAction(ui.action.sequence({animate[math.random()>0.8 and 2 or 1],{"delay",2},{"call",run}}))
    end
    run()
end

function OnlineReward:initAnimate()
    if not self.animateBase then
        self.animateBase = ui.sprite("onlineReward_base.png")
        display.adapt(self.animateBase, 0, 0, GConst.Anchor.LeftBottom)
        self:addChild(self.animateBase)
    end
    if self.animateSp then
        self.animateSp:removeFromParent(true)
        self.animateSp = nil
    end
    local num = 5
    if self.state == 1 then
        self:loadAnimate1()
    else
        self:loadAnimate2()
    end
    if self.state == 1 then
        if not self.canGetIcon then
            self.canGetIcon = ui.button({210,234},nil,{image = "onlineBox.png"})
            display.adapt(self.canGetIcon,110,217,GConst.Anchor.Bottom)
            self:addChild(self.canGetIcon)
            self.canGetIcon:setTouchThrowProperty(true,true)
            self.canGetIcon:setListener(function()
            display.showDialog(zhiyuan.new({olr=self}))
            end)
            self.canGetIcon:runAction(ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({
                {"delay",2},{"rotateBy",0.1,-30},{"rotateBy",0.1,30},{"rotateBy",0.1,30},{"rotateBy",0.1,-30}
                ,{"rotateBy",0.1,-15},{"rotateBy",0.1,15},{"rotateBy",0.1,15},{"rotateBy",0.1,-15}
                }))))
        end
    else
        if self.canGetIcon then
            self.canGetIcon:removeFromParent(true)
            self.canGetIcon = nil
        end
    end
end

function OnlineReward:update()
    if not self.context then
        return
    end
    local num = self.context:getProperty(const.ProOnlineCount) --次数
    self.receiveNum = num
    local getTime = self.context:getProperty(const.ProOnlineTime)     --时间
    --计算跨天
    local stime = GameLogic.getSTime()
    if math.floor((stime-const.InitTime)/86400) > math.floor((getTime-const.InitTime)/86400) then
        num = 0
        getTime = 0
        self.state = 1
        self.context:setProperty(const.ProOnlineCount, 0)
        self.context:setProperty(const.ProOnlineTime, stime)
        self:initAnimate()
    end
    if self.state == 0 and num<#(SData.getData("olrwdt")) then
        local dtime = GameLogic.getTime()-getTime
        local ntime = SData.getData("olrwdt",num+1).time
        if ntime-dtime<=0 then
            self.state = 1
            self:initAnimate()
        else
            self.rtime = ntime-dtime
        end
    elseif self.state == 1 and num < #(SData.getData("olrwdt")) then
        local dtime = GameLogic.getTime()-getTime
        local ntime = SData.getData("olrwdt",num+1).time
        if ntime-dtime > 0 then
            self.state = 0
            self:initAnimate()
            self.rtime = ntime-dtime
        end
    elseif num == #(SData.getData("olrwdt")) then
        if self.canGetIcon then
            self.canGetIcon:removeFromParent(true)
            self.canGetIcon = nil
            self.state = 0
            self:initAnimate()
        end
    end

    if not self.rtimeLb then
        self.rtimeLb = ui.label(Localizet(self.rtime),General.font1,68,{color = {255,255,255}})
        display.adapt(self.rtimeLb,110,277,GConst.Anchor.Center)
        self:addChild(self.rtimeLb)
    end
    self.rtimeLb:setString(Localizet(self.rtime))
    if self.state == 0 and num<#(SData.getData("olrwdt")) then
        self.rtimeLb:setVisible(true)
    else
        self.rtimeLb:setVisible(false)
    end
    if self.receiveNum == #(SData.getData("olrwdt")) then
        self.rtimeLb:setVisible(false)
    end
end

return OnlineReward














