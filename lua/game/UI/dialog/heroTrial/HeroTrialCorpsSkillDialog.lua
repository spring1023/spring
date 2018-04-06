local const = GMethod.loadScript("game.GameLogic.Const")

--英雄试炼战队技能对话框
local HeroTrialCorpsSkillDialog = class2("HeroTrialCorpsSkillDialog",function()
    return BaseView.new("HeroTrialCorpsSkillDialog.json")
end)

function HeroTrialCorpsSkillDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self,true,true)
    self:initBack()
    GameEvent.bindEvent(self,"refreshDialog",self,function()
        if self.initBack then
            self:initBack()
        end
    end)
end

function HeroTrialCorpsSkillDialog:initBack()
    self:removeAllChildren(true)
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setListener(function()
        display.closeDialog()
    end)
    viewTab.butBack:setListener(function()
        display.closeDialog(0)
    end)
    self:loadView("topViews")
    self:loadView("downViews")
    self:insertViewTo()
    self.butHeroTrialShop:setListener(function()
        StoreDialog.new({stype="equip",idx=3,pri=display.getDialogPri()+1})
    end)

    self.butSureChose:setListener(function()
        print("确认选择")
        if equalTable(self.useSkill,self.aheadUserSkill) then
            display.pushNotice(Localize("stringNoChangeTskill"))
        else
            self:savepvtskill()
            display.closeDialog(0)
        end
    end)
    self:skillView()
end

function HeroTrialCorpsSkillDialog:exit(num)
    if equalTable(self.useSkill,self.aheadUserSkill) then
        display.closeDialog(num)
    else
        local otherSettings = {callback = function()
            display.closeDialog(num)
        end}
        local dl = AlertDialog.new(3,Localize("alertTitleNormal"),Localize("stringNoSaveTskill"),otherSettings)
        display.showDialog(dl)
    end
end

function HeroTrialCorpsSkillDialog:canExit(pri)
    if self.sureExit then
        return true
    end
    if equalTable(self.useSkill,self.aheadUserSkill) then
        return true
    else
        local otherSettings = {callback = function()
            self.sureExit = true
            display.closeDialog(pri)
        end}
        local dl = AlertDialog.new(3,Localize("alertTitleNormal"),Localize("stringNoSaveTskill"),otherSettings)
        display.showDialog(dl)
    end
end

function HeroTrialCorpsSkillDialog:skillView()
    local infos={}
    for i=1,6 do 
        infos[i]={id=i}
    end

    local pvtdata = GameLogic.getUserContext().pvtdata
    self.useSkill = {}
    self.aheadUserSkill = {}
    self.useNum = 0
    for i,v in ipairs(pvtdata.skills) do
        if GameLogic.getUserContext():getItem(12,v)>0 then
            self.useSkill[v] = true
            self.aheadUserSkill[v] = true
            self.useNum = self.useNum+1
        end
    end

    self:addTableViewProperty("skillTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("skillTableView")
    self:isChange()
end

function HeroTrialCorpsSkillDialog:callcell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(true)

    local frontNode = ui.node()
    local backNode = ui.node()
    local frontNode2 = ui.node()
    local backNode2 = ui.node()
    self:loadView("cellBackView",frontNode)
    self:insertViewTo()
    local cellBack1 = self.cellBack
    self:loadView("cellBackView",backNode)
    self:insertViewTo()
    local cellBack2 = self.cellBack
    backNode2:setVisible(false)
    frontNode2:setPosition(298,0)
    backNode2:setPosition(298,0)
    bg:addChild(frontNode2)
    bg:addChild(backNode2)
    frontNode:setPosition(-298,0)
    backNode:setPosition(-298,0)
    frontNode2:addChild(frontNode)
    backNode2:addChild(backNode)

    self:loadView("skillViews1",frontNode)
    --local skillIcon=GameUI.addSkillIcon(frontNode,"passiveAddition3",{size={307,307},x=124,y=314})
    local skillIcon = GameUI.addItemIcon(frontNode,12,info.id,1.5,277,467)
    if not self.gouArr then
        self.gouArr = {}
    end
    
    self:loadView("skillViews2",backNode)
    self:insertViewTo()

    self.labelCorpsSkillName2:setString(Localize("dataItemName12_" .. info.id))
    self.labelCorpsSkillTips:setString(Localize("dataItemInfo12_" .. info.id))

    local name = GameLogic.getItemName(12,info.id)
    self.labelCorpsSkillName1:setString(name)

    local num = GameLogic.getUserContext():getItem(12,info.id)

    self.labelHaveCorpsSkill:setString(Localizef("labelHaveCorpsSkill",{num=num}))
    self.butSmallHelp:setListener(function()
        frontNode2:runAction(ui.action.sequence({{"scaleTo",0.1,0,1},{"call",function()
            frontNode2:setVisible(false)
            backNode2:setVisible(true)
            backNode2:runAction(ui.action.scaleTo(0.1,1,1))
        end}}))
    end)
    cell:setScriptCallback(Script.createCallbackHandler(function()
        if frontNode2:isVisible() then
            if self.gouArr[info.id] then
                if self.gouArr[info.id]:isVisible() then
                    self.gouArr[info.id]:setVisible(false)
                    self.useSkill[info.id] = nil
                    self.useNum = self.useNum-1
                else
                    if self.useNum>=3 then
                        display.pushNotice(Localize("stringTrialSkill"))
                    else
                        self.useNum = self.useNum+1
                        self.useSkill[info.id] = true
                        self.gouArr[info.id]:setVisible(true)
                    end
                end
            else
                display.pushNotice(Localize("stringNotHaveSkill"))
            end
        else
            backNode2:runAction(ui.action.sequence({{"scaleTo",0.1,0,1},{"call",function()
                backNode2:setVisible(false)
                frontNode2:setVisible(true)
                frontNode2:runAction(ui.action.scaleTo(0.1,1,1))
            end}}))
        end
        self:isChange()
    end))

    --置灰
    if num<=0 then
        cellBack1:setSValue(-100)
        cellBack2:setSValue(-100)
        skillIcon:setSValue(-100)
    else
        self:loadView("gouView",frontNode)
        self:insertViewTo()
        self.gouArr[info.id] = self.xuanzhongGou
        self.xuanzhongGou:setVisible(false)
    end

    if self.useSkill[info.id] then
        self.xuanzhongGou:setVisible(true)
    end

end

function HeroTrialCorpsSkillDialog:isChange()
    if equalTable(self.useSkill,self.aheadUserSkill) then
        self.butSureChose:setGray(true)
    else
        self.butSureChose:setGray(false)
    end
end

function HeroTrialCorpsSkillDialog:savepvtskill()
    self.aheadUserSkill = self.useSkill
    local sdp = {}
    for k,v in pairs(self.useSkill) do
        table.insert(sdp,k)
    end
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdPvtSkill,sdp})
    display.pushNotice(Localize("stringTrialSkill2"))
    GameLogic.getUserContext().pvtdata.skills = sdp
    GameEvent.sendEvent("refreshHeroTrailSkillRedNum")
end



return HeroTrialCorpsSkillDialog






