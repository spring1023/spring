--联盟战邮件奖励对话框
local EmailUnionDialog = class2("EmailUnionDialog",function()
    return BaseView.new("EmailUnionDialog.json",true)
end)


function EmailUnionDialog:ctor(LogDialog,data)
    self.LogDialog=LogDialog
    self.data=data
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    local uid=GameLogic.uid
    local sid=GameLogic.getUserContext().sid or 1
    self.eKey="email_" .. uid .."_".. sid
    self:initUI()
    display.showDialog(self)
end

function EmailUnionDialog:initUI()
    self:loadView("backAndupViews")
    self:loadView("views")
    --GameUI.addResourceIcon(self, "7", 0.95, 837, 642)
    local unionImg = ui.sprite("images/addUnion.png",{140*0.95,79*0.95})
    display.adapt(unionImg,837,642,GConst.Anchor.Center)
    self:addChild(unionImg)
    local viewTab = self:getViewTab()
    self.viewTab=viewTab


    local data=self.data
    self.dataId=data.id
    local str=StringManager.getFormatString(data.rid.."_title",{a=data.title[1],b=data.title[2],c=data.title[3],d=data.title[4],e=data.title[5],f=data.title[6]})
    viewTab.title:setString(str)--标题

    local AunionFlag=GameUI.addUnionFlag(data.cont[3])
    display.adapt(AunionFlag, 573, 1107, GConst.Anchor.Center)
    AunionFlag:setScale(0.5)
    self:addChild(AunionFlag)
    local BunionFlag=GameUI.addUnionFlag(data.cont[7])
    display.adapt(BunionFlag, 755, 1107, GConst.Anchor.Center)
    BunionFlag:setScale(0.5)
    self:addChild(BunionFlag)

    viewTab.AunionName:setString(Localize(data.cont[1]))
    viewTab.AScore:setString(data.cont[2])
    viewTab.BunionName:setString(Localize(data.cont[5]))
    viewTab.BScore:setString(data.cont[6])

    if data.cont[9]==1 then
        viewTab.labelResult:setString(Localize("labelResultVictory"))
        viewTab.labelResult:setColor(cc.c3b(57,242,0))
    else
        viewTab.labelResult:setString(Localize("labelResultFail"))
        viewTab.labelResult:setColor(cc.c3b(255,70,70))
    end
    viewTab.unionGetNum:setString(data.cont[10])
    viewTab.labelContributionPonit:setString(Localizef("labelContributionPonit",{a=data.cont[11]}))

    local function closeDialog()
        local showId=0
        if self.LogDialog.getEmailShowId then
            showId=self.LogDialog:getEmailShowId(data)
        end
        if data.icon==2 then
            data.icon=0
            self.dataId=data.id
            self:sendDeleteEmail()
            if self.LogDialog.Inbox then
                local datas=self.LogDialog:getEmailDatas(data)
                self.LogDialog.inboxTableView:removeCell(showId)
                if #datas==0 then
                    self.LogDialog:Inbox()
                end
            end
        end
        display.closeDialog(self.priority)
    end
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(closeDialog))
    viewTab.butClose2:setScriptCallback(Script.createCallbackHandler(closeDialog))
end

function EmailUnionDialog:sendDeleteEmail()
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdEmailDel,self.dataId})
end

return EmailUnionDialog
