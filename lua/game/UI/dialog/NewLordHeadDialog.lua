
local const = GMethod.loadScript("game.GameLogic.Const")
--领主头像对话框
local LordHeadDialog = class2("LordHeadDialog",function()
    return BaseView.new("LordHeadDialog.json",true)
end)

function LordHeadDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initData()
    self:initUI()
    display.showDialog(self)
end

function LordHeadDialog:initData( ... )
    local context = GameLogic.getUserContext()
    self.headId = context:getInfoItem(const.InfoHead)
end

function LordHeadDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("upViews")
    self:loadView("bottomViews")
    self:insertViewTo()
    local context = GameLogic.getUserContext()
    self.headId = context:getInfoItem(const.InfoHead)
    self:initHead()
    self.butReplaceIcon:setListener(function()
        LordHeadListDialog.new(function(hid,awakeUp)
            if self.headId then
                self.headId = self.headId%10+hid*100+(awakeUp>0 and 1 or 0)*10
                if self.initHead then
                    self:initHead()
                end
            end
        end)
    end)
    self.butReplaceIconBack:setListener(function()
        display.sendIntent({class="game.UI.dialog.LordHeadBackListDialog",
            params = {callback = function(bkid)
                self.headId = math.floor(self.headId/10)*10+bkid
                self:initHead()
            end
        }})
    end)
    self.labelPlayerName:setString(context:getInfoItem(const.InfoName))
    self.labelLoadLv:setString(Localize("labelLoadLv") .. "：" .. context:getInfoItem(const.InfoLevel))
    local value,max = context:getRes(const.ResExp),context:getResMax(const.ResExp)
    if max == 0 then
        -- value = 186456
        -- max = 186456
        self.labelExpNumValue:setString(Localize("labelLevelMax"))
    else
        self.labelExpNumValue:setString(value .. "/" .. max)
    end
    self.expProcess:setProcess(true,value/max)
    self.labelIDValue:setString(context.uid)
    self.labelServerTimeValue:setString(GameLogic.getTimeFormat2(GameLogic.getSTime()))
    RegTimeUpdate(self, Handler(self.update, self), 0.2)
    -- self.butSystemSet:setListener(function()
    --     SystemSetDialog.new()
    -- end)
    self.butChangeServer:setListener(function()
        local otherSettings = {callback=function()
            local loginType=GEngine.getConfig("lastLoginMsg")[2]
            Plugins:logoutWithSdk(loginType)
            GEngine.setConfig("lastLoginMsg","",true)
            GEngine.restart()
        end,yesBut="labelQuYiYiJue",noBut="labelSheBuDe"}
        local dialog = AlertDialog.new(3,Localize("labelQuitGameMa"),Localize("stringQuitGameMa"),otherSettings)
        display.showDialog(dialog)
    end)
    self.btnRename:setListener(function()
        display.showDialog(RenameDialog.new())
    end)
    local union = GameLogic.getUserContext().union
    if union then
        self.unionNode = ui.node()
        self:addChild(self.unionNode)
        self:loadView("centerViews",self.unionNode)
        self:insertViewTo()
        self.labelUnionName:setString(union.name)
        self.labelUnionId:setString(Localize("labelUnionID") .. union.id)
        self.butUnionQuit:setListener(function()
            print("退出联盟")
            local otherSettings = {callback = function()
                if self.leaveleague then
                    self:leaveleague()
                end
            end}
            local dialog = AlertDialog.new(3,Localize("unionInfoNotice1"),Localize("unionInfoNotice2"),otherSettings)
            display.showDialog(dialog)
        end)
        self.butUnionSee:setListener(function()
            print("查看联盟")
            UnionInfoDialog.new()
        end)
    end
end

function LordHeadDialog:initHead()
    if self.headNode then
        self.headNode:removeFromParent(true)
        self.headNode = nil
    end
    local context = GameLogic.getUserContext()
    local viplv = context:getInfoItem(const.InfoVIPlv)
    local lv = context:getInfoItem(const.InfoLevel)
    self.headNode = GameUI.addPlayHead(self,{id = self.headId,scale = 1.5,x=321,y=1011})
end

function LordHeadDialog:canExit()
    if self.headId ~= GameLogic.getUserContext():getInfoItem(const.InfoHead) then
        self:changehead()
    end
    GameLogic.getUserContext():setInfoItem(const.InfoHead,self.headId)
    return true
end
------------------------------------------------------------------------------------
function LordHeadDialog:leaveleague()
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("leaveleague",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            local ucontext = GameLogic.getUserContext()
            local name = ucontext:getInfoItem(const.InfoName)
            local uid = ucontext.uid
            if ucontext.union then
                local cid = ucontext.union.id
                local ug = {lv = ucontext:getInfoItem(const.InfoLevel)}
                ug.isOut = true
                local msg = {uid=uid,cid = cid,text="加加加",name=name,ug=json.encode(ug),mtype=1}
                scene = GMethod.loadScript("game.View.Scene")
                scene.menu.chatRoom:send(msg)
                display.pushNotice(Localize("unionInfoNotice3"))
                ucontext.union = nil
            end
            if self.unionNode then
                self.unionNode:setVisible(false)
            end
        end
    end)
end

function LordHeadDialog:changehead()
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdHeadChange,self.headId})
end

function LordHeadDialog:update()
    self.labelServerTimeValue:setString(GameLogic.getTimeFormat2(GameLogic.getSTime()))
end

return LordHeadDialog















