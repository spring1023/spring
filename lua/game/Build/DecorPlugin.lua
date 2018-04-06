-- @Date: 2016/07/30
-- @Create By: lion
-- @Describe: 装饰物逻辑

local const = GMethod.loadScript("game.GameLogic.Const")

local DecorPlugin = {}

function DecorPlugin:addMenuButs(buts, item)
    if item=="sell" then
        table.insert(buts, {key="sell", callback = self.onSell, cp1=self})
    end
end

function DecorPlugin:onSell(force)
    if not force then
        local dl = AlertDialog.new(3,Localize("labelAffirmSell"),Localizef("stringAffirmSell",
                {a = BU.getBuildName(self.bid), b = self.data.produce}), {callback=Handler(self.onSell, self, true)})
        display.showDialog(dl)
    else
        music.play("sounds/sell.mp3")
        local context = GameLogic.getUserContext()
        context:changeResWithMax(const.ResGold,self.data.produce)
        context.buildData:sellBuild(self)
        self:removeFromScene()
    end
end

function DecorPlugin:onReloadView()
    local vstate = self.vstate
    if vstate and not vstate.rankName and self.vconfig and self.vconfig.hasTitle then
        local x = vstate.upNode:getContentSize().width/2
        local y = self:getHeight()
        vstate.rankName = ui.label(BU.getBuildName(self.bid), General.font1, 60)
        display.adapt(vstate.rankName, x, y, GConst.Anchor.Center)
        vstate.upNode:addChild(vstate.rankName)
    end
end

return DecorPlugin
