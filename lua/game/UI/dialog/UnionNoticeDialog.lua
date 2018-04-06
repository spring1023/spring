
local const = GMethod.loadScript("game.GameLogic.Const")
--联盟公告
local UnionNoticeDialog = class2("UnionNoticeDialog",function()
    return BaseView.new("UnionNoticeDialog.json")
end)

function UnionNoticeDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function UnionNoticeDialog:initUI()
    self.context = GameLogic.getUserContext()
    self.strArr = {}
    for i=1,4 do
        self.strArr[i] = Localizef("dataUnionNotice" .. i, {name = self.context.union.name})
    end
    self.strIdx = 1
    self.selectNode = {}

    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("downViews")
    self:showCenterView()
    self:insertViewTo()
    self.btnReleaseNum:setString(const.NoticeCost)
    self.butRelease:setListener(function()
        if not self.isSend then
            if GameLogic.getUserContext():getRes(const.ResCrystal)< const.NoticeCost then
                local otherSettings = {yesBut="btnEnterShop",callback = function()
                            StoreDialog.new({id=1})
                    end}
                local dl = AlertDialog.new(2, Localize("alertTitleBuyCrystal"), Localize("alertTextBuyCrystal"),otherSettings)
                display.showDialog(dl)
            else
                self.isSend = true
                self:sendMsg()
                display.closeDialog(0)
            end
        end
    end)
end

function UnionNoticeDialog:sendMsg()
    local union = self.context.union
    local ug = {lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel),flag = union.flag,
                cid = union.id,cname = union.name,cup = union.cup, textId=self.strIdx,headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
    local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
        local uid = GameLogic.getUserContext().uid            
    local msg = {uid=uid,cid=0,text=self.strArr[self.strIdx],name=name,ug=json.encode(ug),mtype=5}
    local scene = GMethod.loadScript("game.View.Scene")
    scene.menu.chatRoom:send(msg)
end

function UnionNoticeDialog:showCenterView()
    local noticeNodePos={{50,590},{734,590},{50,282},{734,282}}
    for i=1,4 do
        local pos=noticeNodePos[i]
        local noticeNode=ui.button({662,274},nil,{})
        display.adapt(noticeNode, pos[1], pos[2], GConst.Anchor.LeftBottom)
        self:addChild(noticeNode)
        self:loadView("centerNodeViews",noticeNode)
        self:insertViewTo()
        self.labelNotice:setString(self.strArr[i])
        self.selectNode[i] = ui.node()
        noticeNode:addChild(self.selectNode[i])
        self:loadView("selectedStateViews",self.selectNode[i])
        GameUI.addHaveGet(self.selectNode[i],Localize("labelSelection"),276/317,536,60,3)
        noticeNode:setListener(function()
            self.strIdx = i
            self:select()
        end)
    end
    self:select()
end

function UnionNoticeDialog:select()
    for i,v in ipairs(self.selectNode) do
        if i == self.strIdx then
            v:setVisible(true)
        else
            v:setVisible(false)
        end
    end
end

return UnionNoticeDialog











