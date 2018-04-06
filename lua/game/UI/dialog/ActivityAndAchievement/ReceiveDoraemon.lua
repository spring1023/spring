local ReceiveDoraemon = class(DialogViewLayout)
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

--引导管卡紫色恐怖2后,弹出的机器猫领取界面
function ReceiveDoraemon:onInitDialog()
    self.context = GameLogic.getUserContext()
    self:initUI()
    self:initData()
    GEngine.setConfig("OpenReceiveDoraemon"..GameLogic.getUserContext().uid,1,true)
    GEngine.saveConfig()
end

function ReceiveDoraemon:initUI()
    self:setLayout("Doraemon.json")
    self:loadViewsTo()
    self.lab_tittle:setString(Localize("btnGetReward"))
    self.lab_desc1:setString(Localize("receiceDoraemonDesc1"))
    self.lab_desc2:setString(Localize("receiceDoraemonDesc2"))
    self.lab_receive:setString(Localize("btnReceive"))
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btn_receive:setScriptCallback(ButtonHandler(self.OnReceiveClick, self))
    ViewTemplates.setImplements(self.layout, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell, self), withIdx=false})
end

function ReceiveDoraemon:initData()
    self:showReward()
    local cellSize = self.node_heroFeature.size
    GameUI.addHeroFeature(self.node_heroFeature, self.heroId, 0.8, cellSize[1]/2, cellSize[2]/2, 0, true)
    self.lab_name:setString(Localize("dataHeroName"..self.heroId))
    local hinfo = SData.getData("hinfos", self.heroId)
    local _scale = 0.6
    GameUI.addSSR(self.node_Quality, hinfo.displayColor and hinfo.displayColor >= 5 and 5 or hinfo.rating, _scale, 160, 40, 10, GConst.Anchor.Right)
end

function ReceiveDoraemon:OnReceiveClick()
    local heroData = GameLogic.getUserContext().heroData
    if heroData:getHeroNum()>=heroData:getHeroMax() then
        display.pushNotice(Localize("noticeHeroPlaceFull"))
        return
    end
    heroData:receiveHero(self.heroId)
    local _hero = heroData:makeHero(self.heroId)
    display.closeDialog(self.priority)
    NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
end

function ReceiveDoraemon:onUpdateItemsCell(reuseCell, layout, item)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    if item.resID ~= reuseCell.displayId or item.resMode ~= reuseCell.displayMode then
        reuseCell.displayMode = item.resMode
        reuseCell.displayId = item.resID
        reuseCell.itemPic:removeAllChildren()
        local cellSize = reuseCell.itemPic.size
        GameUI.addItemIcon(reuseCell.itemPic, item.resMode, item.resID, cellSize[2]/200,cellSize[1]/2, cellSize[2]/2, true, false)
        GameUI.registerTipsAction(reuseCell, self.view, item.resMode,  item.resID)
    end
    reuseCell.itemNum:setString("X"..item.resNum)
    return reuseCell
end

function ReceiveDoraemon:showReward()
    local Reward = {}
    local rwds = {{gtype = 9, gid = 4001, gnum = 1}}
    if GameLogic.useTalentMatch then
        rwds = {{gtype = 9, gid = 3005, gnum = 1}}
    end
    for i=1,#rwds do
        local rwd = rwds[i]
        if rwd.gtype == 9 then
            self.heroId = rwd.gid
        end
        table.insert(Reward, {resMode = rwd.gtype, resID = rwd.gid, resNum = rwd.gnum})
    end
    self.Reward = Reward
    self.layout:setLayoutDatas(Reward)
end

return ReceiveDoraemon
