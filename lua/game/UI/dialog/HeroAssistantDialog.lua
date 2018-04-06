--助战英雄对话框
local HeroAssistantDialog = class2("HeroAssistantDialog",function()
    return BaseView.new("HeroAssistantDialog.json")
end)

function HeroAssistantDialog:ctor(heros)
    self.heros = heros
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self,false)
end

function HeroAssistantDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butBack:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    local infos={}
    for i=1,#self.heros do
        infos[i]={id=i,hero = self.heros[i]}
    end
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("infoTableView")
end

function HeroAssistantDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local hero = info.hero
    cell:setEnable(false)
    self:loadView("infoCellviews",bg)
    self:insertViewTo()
    GameUI.updateHeroTemplate(self.headNode, {noLv = true}, hero)
    self.lvValue:setString("LV:" .. hero.level)
    self.stringAssistEffect:setString(Localizef("labelHelpNormalEffect" .. info.id,{num=hero:getNormalHelpValue(info.id)}))
    
    if hero.info.hsid and hero.info.hsid > 0 then
        GameUI.addSkillIcon(bg, 4, hero.info.hsid, 0.86, 1051+101, 112+101)
        self.labelSkillName:setString(hero:getHelpSkillFormatName(true))
        self.labelSkillDesc:setString(hero:getHelpSkillDesc(nil, true))
    else
        -- GameUI.addSkillIcon(bg, 4, hero.info.hsid, 0.86, 1051+101, 112+101)
        self.labelSkillName:setString("")
        self.labelSkillDesc:setString(Localize("labelNoHelpHero"))
    end
end

return HeroAssistantDialog