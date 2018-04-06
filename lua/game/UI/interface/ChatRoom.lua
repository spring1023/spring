
local const = GMethod.loadScript("game.GameLogic.Const")
--聊天室
local ChatRoom = class2("ChatRoom",function()
    local ret = ui.touchNode({891,display.winSize[2]/ui.getUIScale2()}, -1, false)
    ret:setGroupMode(true)
    ret:setGlobalZOrder(2.1)
    return ret
end)

function ChatRoom:ctor()
    self.context = GameLogic.getUserContext()
    self.state=false--打开，关闭状态
    self.chatRoomSate=2--世界，联盟状态
    self.offH=30
    self.leftViewsH=0
    self.rightViewsH=0
    self.backViewH = display.winSize[2]/ui.getUIScale2()
    self.scrollH= self.backViewH - 298 --可视高度,值不变
    self.leftPy=0
    self.rightPy=0
    self.leftParity=0
    self.rightParity=0
    self.worldInfos={}
    self.unionInfos={}
    self.msgTable={}
    self:initView()
    self.notReadNum = 0
    local unionMsg = GEngine.getConfig("unionMsg"..GameLogic.getUserContext().uid..GameLogic.getUserContext().sid)
    if unionMsg and GameLogic.getUserContext().union then
        local cid = GameLogic.getUserContext().union.id
        unionMsg = json.decode(unionMsg)
        for i,v in ipairs(unionMsg) do
            local ug = (type(v[6]) == "string" and json.decode(v[6]) or v[6])
            local msg = {uid = v[1],name = v[2],text = v[3],time = v[4],ug = ug,mtype = v[7],cid = cid, lid = cid}
            self.since = msg.time
            if self.context.union.enterTime<=msg.time then
                if msg.mtype == 10 then
                    self:deleteMsg(msg)
                elseif msg.mtype>10 then
                    local ug = msg.ug
                    if ug and ug.uid == self.context.uid then
                        self:doOther(msg)
                    end
                else
                    self:addInformation(msg,2)
                end
            end
        end
    end
    --轮询
    RegTimeUpdate(self.upNode, Handler(self.update, self), 1)
end

function ChatRoom:addInputBox(chatRoomSate)
    if chatRoomSate == 2 and not self.context.union then
        return
    end
    local textPos={{-867,self.backViewH/2 - 220},{-867, self.backViewH/2 - 178}}
    local pos=textPos[chatRoomSate]
    local upNode=self.upNode
    local textBox = ui.textBox({637, 68}, Localize("labelInputPlaceHolder"), General.font6, 45, {back = "images/inputBack.png", max=140})
    display.adapt(textBox, pos[1], pos[2], GConst.Anchor.LeftBottom)
    upNode:addChild(textBox)
    self.textBox = textBox
end
function ChatRoom:reset()
    local startBut=self.startBut
        startBut:setScrollEnable(true)
        self.notReadNum = 0
        self.px=0
        if self.state==false then
            -- if self.chatRoomSate~=2 and self.context.union then
            --     self:changChat(2)
            -- end
            self.but:setFlippedX(true)
            startBut:setPositionX(0)
            startBut:getScrollNode():setPositionX(0)
            startBut:setScrollContentRect(cc.rect(-891,0,90,295))
            self.bgView:setPositionX(0)
        elseif self.state==true then
            self.but:setFlippedX(false)
            startBut:setPositionX(891)
            startBut:getScrollNode():setPositionX(0)
            startBut:setScrollContentRect(cc.rect(0,0,90+891,295))
            self:setMsgTime(self.msgTime)
            self.bgView:setPositionX(891)
        end
end
function ChatRoom:moveView(px)
    local startBut=self.startBut
    local bgView=self.bgView
    startBut:setScrollEnable(false)
    local moveSpeed=3800
    if self.state==false then
        if px==0 or px>=891/3 or px<=20 then
            self.state=true
            local ox = 891-px
            bgView:runAction(ui.action.sequence({{"moveBy",ox/moveSpeed,ox,0},{"call",Script.createBasicHandler(self.reset,self)}}))
        else
            bgView:runAction(ui.action.sequence({{"moveBy",px/moveSpeed,-px,0},{"call",Script.createBasicHandler(self.reset,self)}}))
        end
    else
        if px==0 or px<=-891/3 or px>=-20 then
            self.state=false
            local ox = 891+px
            bgView:runAction(ui.action.sequence({{"moveBy",ox/moveSpeed,-ox,0},{"call",Script.createBasicHandler(self.reset,self)}}))
        else
            bgView:runAction(ui.action.sequence({{"moveBy",-px/moveSpeed,-px,0},{"call",Script.createBasicHandler(self.reset,self)}}))
        end
    end
end
function ChatRoom:initStartBut()
    local startBut = ScrollNode:create(cc.size(90,295), -1, true, false)
    startBut:setScrollEnable(true)
    startBut:setInertia(false)
    startBut:setElastic(false)
    startBut:setClip(false)
    startBut:setScaleEnable(true, 1, 1, 1, 1)
    display.adapt(startBut, 0, self.backViewH/2, GConst.Anchor.Left)
    self:addChild(startBut,1)
    self.startBut=startBut

    local bgView = ui.node()
    display.adapt(bgView, 0, self.backViewH/2, GConst.Anchor.Left)
    self:addChild(bgView)

    self.bgView=bgView
    local startButNode=ui.node({90,295})

    display.adapt(startButNode, 0, 0, GConst.Anchor.Left)
    bgView:addChild(startButNode)
    local temp = ui.sprite("images/chatRoomBtnBack.png",{90, 295})
    display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
    startButNode:addChild(temp)
    self.but=ui.sprite("images/chatRoomBtn.png",{27,58})
    display.adapt(self.but, 45,148, GConst.Anchor.Center)
    self.but:setFlippedX(true)
    startButNode:addChild(self.but)
    --信息提示框
    -- temp = ui.sprite("images/noticeBackRed.png",{66, 66})
    -- display.adapt(temp, 48, 184, GConst.Anchor.LeftBottom)
    -- startButNode:addChild(temp)
    -- temp = ui.label(StringManager.getString("8"), General.font1, 45, {color={255,255,255}})
    -- display.adapt(temp, 80, 220, GConst.Anchor.Center)
    -- startButNode:addChild(temp)
    self.redNum = GameUI.addRedNum(startButNode,48,184,0,1,10)
    self.redNum:setNum(0)

    self:reset()


    local butTable = {}
    function butTable.onEvent(event,...)
        if BU.getPlanDelegate() then
            return
        end
        local param = {...}
        if param[1]=="single" and param[2]=="begin" then
            startButNode:runAction(ui.action.scaleTo(0.1,0.9,0.9))
        elseif param[1]=="scrollTo" then
            self.px=param[2]
            if (self.state==false and self.px<=0) or (self.state==true and self.px>=0) then
                return
            end
            if self.px>=0 then
                bgView:setPositionX(self.px)
            else
                bgView:setPositionX(891+self.px)
            end
        elseif param[1]=="scrollEnd" then
            startButNode:runAction(ui.action.scaleTo(0.1,1,1))
            self:moveView(self.px)
        end
    end
    startBut:setScriptHandler(Script.createCObjectHandler(butTable))
end

function ChatRoom:onEventCallback(event)
    if event == GameEvent.EventStartPlan then
        local bgView = self.bgView
        self.state = false
        self.px = 0
        bgView:setPositionX(0)
        self:reset()
    end
end

function ChatRoom:initView()

    self:initStartBut()
    local bgView = self.bgView

    local BK = ui.button({891, self.backViewH}, nil, {})
    display.adapt(BK, 0,0, GConst.Anchor.Right)
    bgView:addChild(BK)
    local back=ui.colorNode({891, self.backViewH},{242,226,196})
    display.adapt(back, 0, 0, GConst.Anchor.Right)
    bgView:addChild(back)
    back = ui.scale9("images/bgWhiteGrid2.9.png", 20, {891, 298})
    ui.setColor(back, {61, 120, 149})
    display.adapt(back, 0, self.backViewH/2, GConst.Anchor.RightTop)
    bgView:addChild(back)
    back = ui.sprite("images/dialogBack_3_repeat.png")
    local texture = back:getTexture()
    texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.REPEAT, gl.REPEAT)
    back:setTextureRect(cc.rect(0, 0, 891/3, 298/3))
    back:setOpacity(25)
    --ui.setColor(back, {61, 120, 149})
    back:setScale(3)
    display.adapt(back, 0, self.backViewH/2, GConst.Anchor.RightTop)
    bgView:addChild(back)

    local back=ui.colorNode({891,89},{0,0,0,51})
    display.adapt(back, 0, self.backViewH/2, GConst.Anchor.RightTop)
    bgView:addChild(back,2)

    local temp=ui.button({445, 89},Script.createBasicHandler(self.changChat,self),{priority=-1,cp1=1,image=nil,actionType=0})
    display.adapt(temp, -891, self.backViewH/2 - 45, GConst.Anchor.Left)
    bgView:addChild(temp)
    self.leftBut=temp
    temp=ui.sprite("images/chatRoomSelectedState.png",{504, 89})
    display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
    self.leftBut:getDrawNode():addChild(temp)
    self.leftButBack=temp
    --temp:setFlippedY(true)
    temp = ui.label(StringManager.getString("labelWorld"), General.font1, 45, {color={255,255,255}})
    display.adapt(temp, 216, 45, GConst.Anchor.Center)
    self.leftBut:getDrawNode():addChild(temp,2)

    temp=ui.button({445, 89},Script.createBasicHandler(self.changChat,self),{priority=-1,cp1=2,image=nil,actionType=0})
    display.adapt(temp, 0, self.backViewH/2 - 45, GConst.Anchor.Right)
    bgView:addChild(temp)
    self.rightBut=temp
    temp=ui.sprite("images/chatRoomSelectedState.png",{504, 89})
    display.adapt(temp, -58, 0, GConst.Anchor.LeftBottom)
    --temp:setFlippedX(true)
    self.rightBut:getDrawNode():addChild(temp)
    self.rightButBack=temp
    temp = ui.label(StringManager.getString("titleUnion"), General.font1, 45, {color={255,255,255}})
    display.adapt(temp, 216, 45, GConst.Anchor.Center)
    self.rightBut:getDrawNode():addChild(temp,2)

    --上方增加层屏蔽
    local upTouchNode=ui.touchNode({891,298}, 0)
    display.adapt(upTouchNode, 0, self.backViewH/2, GConst.Anchor.RightTop)
    bgView:addChild(upTouchNode)
    local upNode=ui.node()
    display.adapt(upNode, 0, 0, GConst.Anchor.LeftBottom)
    bgView:addChild(upNode)
    self.upNode=upNode

    local eventNode = ui.node()
    GameEvent.bindEvent(eventNode, {GameEvent.EventStartPlan}, self, self.onEventCallback)
    bgView:addChild(eventNode)

    local scrollNode=ScrollNode:create(cc.size(891, self.backViewH - 298), -1, false, true)
    scrollNode:setScrollEnable(true)
    scrollNode:setElastic(true)
    scrollNode:setInertia(true)
    scrollNode:setInertiaCoefficient(0.99)--设置惯性系数
    scrollNode:setClip(true)
    scrollNode:setScaleEnable(true, 1, 1, 1, 1)
    scrollNode:setScrollContentRect(cc.rect(0,0,0, self.backViewH - 298))
    display.adapt(scrollNode, 0, -149, GConst.Anchor.Right)
    bgView:addChild(scrollNode)
    self.scrollNode=scrollNode
    scrollNode:setScriptHandler(Script.createCObjectHandler(self))

    local viewsNode=ui.node()
    display.adapt(viewsNode, 0, self.backViewH - 298 - self.offH, GConst.Anchor.LeftBottom)
    scrollNode:getScrollNode():addChild(viewsNode)
    self.leftViewsNode=viewsNode

    viewsNode=ui.node()
    display.adapt(viewsNode, 0, self.backViewH - 298 - self.offH, GConst.Anchor.LeftBottom)
    scrollNode:getScrollNode():addChild(viewsNode)
    self.rightViewsNode=viewsNode

    --默认切换
    if self.context.union then
        self:changChat(2)
    else
        self:changChat(1)
    end
end

function ChatRoom:changChat(chatRoomSate)
    self.chatRoomSate=chatRoomSate
    if chatRoomSate==1 then
       self.leftBut:setLocalZOrder(3)
       self.rightBut:setLocalZOrder(0)
       self.leftBut:setEnable(false)
       self.rightBut:setEnable(true)
       self.leftViewsNode:setVisible(true)
       self.rightViewsNode:setVisible(false)
       self.leftButBack:setFlippedX(false)
       self.leftButBack:setFlippedY(false)
       self.rightButBack:setFlippedX(true)
       self.rightButBack:setFlippedY(true)
    elseif chatRoomSate==2 then
       self.leftBut:setLocalZOrder(0)
       self.rightBut:setLocalZOrder(3)
       self.leftBut:setEnable(true)
       self.rightBut:setEnable(false)
       self.leftViewsNode:setVisible(false)
       self.rightViewsNode:setVisible(true)
       self.leftButBack:setFlippedX(false)
       self.leftButBack:setFlippedY(true)
       self.rightButBack:setFlippedX(true)
       self.rightButBack:setFlippedY(false)
    end
    self:_checkSetScrollContentRect()

    self:addUpNodeViews(chatRoomSate)
end

function ChatRoom:addUpNodeViews(chatRoomSate)
    if self.upNode then
        self.upNode:removeAllChildren(true)
        self.nd_visit = nil
    end
    local upNode=self.upNode

    if chatRoomSate==1 then--世界
        self:addInputBox(chatRoomSate)
        local  speakBut= ui.button({200, 78} ,Script.createBasicHandler(self.addInformation,self), {cp1=1,image="images/btnGreen.png"})
        display.adapt(speakBut, 780-891, self.backViewH/2 -186, GConst.Anchor.Center)
        upNode:addChild(speakBut)
        local send=ui.label(StringManager.getString("btnSend"), General.font1, 40, {color={255,255,255}})
        display.adapt(send, 100, 48, GConst.Anchor.Center)
        speakBut:getDrawNode():addChild(send)
        speakBut:setListener(function()
            local str = self.textBox:getText()
            str = string.gsub(str, "^%s*(.-)%s*$", "%1")
            if GameLogic.getStringLen(str)<=0 then
                display.pushNotice(Localize("labelCantSendNothing"))
                return
            end
            local lid
            if not GameLogic.isEmptyTable(self.context.union) then
                lid = self.context.union.id
            end
            local ug = {lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel),
                        flag = self.context.union and self.context.union.flag,
                        uname = self.context.union and self.context.union.name,
                        lid = lid,headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
            local channel = GEngine.rawConfig.channel
            local cid=0
            if channel == "com.bettergame.heroclash_ir3" then
                cid=-100
            elseif channel == "com.almuathir.zombies2" or channel == "com.almuathir.zombies2_ios" then
                cid=-200
            end
            local msg = {uid = self.context.uid,name = self.context:getInfoItem(const.InfoName),
            text = str,ug = json.encode(ug),mtype = 4,cid = cid}
            local uid = self.context.uid
            local sid = self.context.sid
            local key = sid .."c" .. uid .. "wctimes"
            local wcf = GEngine.getConfig(key) or "[0,0]"
            local lock = self.context:getVipPermission("chat")[1]
            wcf = json.decode(wcf)
            local dt = GameLogic.getSTime()-wcf[2]
            if dt>GameLogic.getRtime() then
                wcf = {0,0}
            end
            if self.wcold>0 then
                display.pushNotice(Localizef("labelWiteSend",{a = math.floor(self.wcold)}))
            -- elseif wcf[1]>= const.ChatNum and lock>0 then
            --     display.pushNotice(Localizef("stringUpChatTime",{a = lock}))
            else
                self:send(msg)
                self.textBox:setText("")
            end
        end)
    elseif chatRoomSate==2 then--联盟
        if not self.context.buildData:getBuild(2) then--还未有联盟建筑
            local temp = ui.label(StringManager.getString("labelNotUnionBuild"), General.font1, 40, {color={255,255,255}})
            display.adapt(temp, 144-891+300 ,self.backViewH/2 - 189, GConst.Anchor.Center)
            upNode:addChild(temp)
            self.rightViewsNode:setVisible(false)
            return
        end
        self:addInputBox(chatRoomSate)
        local union = self.context.union
        --local str = Localize("stringNotJoin")
        local str = Localize("")
        if union then
            local unionFlag=GameUI.addUnionFlag(union.flag)
            display.adapt(unionFlag, 39+35-891,self.backViewH/2 - 244, GConst.Anchor.Center)
            unionFlag:setScale(0.32)
            upNode:addChild(unionFlag)
            str = union.name
        end
        self.hasUnionUp = union
        local unionName = ui.label(StringManager.getString(str), General.font5, 40, {color={255,255,255}})
        display.adapt(unionName, 144-891 ,self.backViewH/2 - 239, GConst.Anchor.Left)
        upNode:addChild(unionName)
        if self.hasUnionUp then
            local  speakBut= ui.button({200, 78} ,Script.createBasicHandler(self.addInformation,self), {cp1=1,image="images/btnGreen.png"})
            display.adapt(speakBut, 780-891, self.backViewH/2 -144, GConst.Anchor.Center)
            upNode:addChild(speakBut)
            local send=ui.label(StringManager.getString("btnSend"), General.font1, 40, {color={255,255,255}})
            display.adapt(send, 100, 48, GConst.Anchor.Center)
            speakBut:getDrawNode():addChild(send)
            speakBut:setListener(function()
                local str = self.textBox:getText()
                if GameLogic.getStringLen(str)<=0 then
                    display.pushNotice(Localize("labelCantSendNothing"))
                    return
                end
                local ug = {lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel),job = union.job, lid = union.id,headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
                local msg = {uid = self.context.uid,name = self.context:getInfoItem(const.InfoName),
                text = str,ug = json.encode(ug),mtype = 4,cid = union.id, lid = union.id}
                self:send(msg)
                self.textBox:setText("")
            end)

            local searchBut = ui.button({79, 74} ,Script.createBasicHandler(self.addInformation,self), {cp1=2,image="images/btnInfo2.png"})
            display.adapt(searchBut, 833-891, self.backViewH/2 - 235, GConst.Anchor.Center)
            upNode:addChild(searchBut)
            searchBut:setListener(function()
                UnionInfoDialog.new()
            end)

            local hornBut = ui.button({79, 74} ,Script.createBasicHandler(self.addInformation,self), {cp1=1,image="images/chatRoombtnHorn.png"})
            display.adapt(hornBut, 739-891, self.backViewH/2 - 235, GConst.Anchor.Center)
            upNode:addChild(hornBut)
            hornBut:setListener(function()
                UnionNoticeDialog.new()
            end)
        else
            local notUnionNode=ui.node()
            display.adapt(notUnionNode, -891/2, -self.backViewH/2, GConst.Anchor.Bottom)
            upNode:addChild(notUnionNode)
            notUnionNode:setScale(0.8)

            local temp = ui.label(StringManager.getString("labelJoinUnionRemind"), General.font1, 40, {color={255,255,255}})
            display.adapt(temp, 435-891/2, 1181, GConst.Anchor.Top)
            notUnionNode:addChild(temp)
            temp = ui.sprite("images/iconChatRoomUnion.png",{539, 578})
            display.adapt(temp, 160-891/2, 374, GConst.Anchor.LeftBottom)
            notUnionNode:addChild(temp)
            local function showJoinUnion( )
                self.px=0
                self:moveView(self.px)
                UnionDialog.new()
            end
            temp = ui.button({340, 133} ,showJoinUnion, {image="images/btnGreen.png",priority=-10})
            display.adapt(temp, 430-891/2, 265, GConst.Anchor.Center)
            notUnionNode:addChild(temp)
            local cinBut=temp
            temp = ui.label(StringManager.getString("btnImmediatelyEnter"), General.font1, 45, {color={255,255,255}})
            display.adapt(temp, 170, 77, GConst.Anchor.Center)
            cinBut:getDrawNode():addChild(temp)

        end
    end
end

function ChatRoom:onEvent(event,px,py)
    if event=="scrollTo" then
        if self.chatRoomSate==1 then
            self.leftPy=py
        elseif self.chatRoomSate==2 then
            self.rightPy=py
        end
        self:resetNdVisit()
    end
end

function ChatRoom:_checkSetScrollContentRect()
    local py,viewsH
    --状态已经变了
    if self.chatRoomSate==1 then
        py=self.leftPy
        viewsH=self.leftViewsH
    elseif self.chatRoomSate==2 then
        py=self.rightPy
        viewsH=self.rightViewsH
    end
    self.scrollNode:getScrollNode():setPositionY(py)
    if viewsH>self.scrollH-self.offH then
        self.scrollNode:setElastic(true)
        self.scrollNode:setScrollContentRect(cc.rect(0,self.scrollH-viewsH-self.offH,0,viewsH+self.offH))
    else
        self.scrollNode:setElastic(false)
        self.scrollNode:setScrollContentRect(cc.rect(0,0,0,self.scrollH))
    end
end

function ChatRoom:_moveViews(moveL,endIdx,chatRoomSate)
    local infos
    if chatRoomSate==1 then
        infos=self.worldInfos
    elseif chatRoomSate==2 then
        infos=self.unionInfos
    end
    local moveTime=math.abs(moveL)/850
    endIdx = endIdx or 10000
    for i,cell in ipairs(infos) do
        if i>=endIdx then
            break
        end
        cell.view:runAction(ui.action.moveBy(moveTime,0,moveL))
    end
end

function ChatRoom:visitUnion(lid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getleagueinfo",{getleagueinfo={lid}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==2 then
                display.pushNotice(Localize("stringNOUnion"))
                return
            else
                data.isChatRoom = true
                UnionInfoDialog.new(data)
            end
        end
    end)
end

function ChatRoom:visitPlayer(uid)
    GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = uid})
end

function ChatRoom:givemonthcard(uid, params)
    local context = GameLogic.getUserContext()
    local num = context:getProperty(const.ProMonthCard)
    if num<=0 then
        local otherSettings = {callback = function()
            StoreDialog.new(1)
        end}
        local dl = AlertDialog.new(3,Localize("alertTitleNormal"),Localize("stringNoMonthCardSend"),otherSettings)
        display.showDialog(dl)
    else
        local otherSettings = {callback = function()
            print("赠送月卡")
            GameLogic.givemonthcard(uid, params)
        end}
        local dl = AlertDialog.new(3,Localize("labelAffirm"),Localize("stringAffiremSend"),otherSettings)
        display.showDialog(dl)
    end
end

function ChatRoom:resetNdVisit()
    if self.nd_visit then
        self.nd_visit:removeFromParent()
        self.nd_visit = nil
    end
end

function ChatRoom:addBtnOnView(cellView, info)
    local ucontext = GameLogic.getUserContext()
    local msg = info.msg
    local chatRoomSate = info.chatRoomSate
    if GameLogic.isEmptyTable(msg) then
        return
    end
    local cellW = info.cellW
    local cellH = info.cellH
    local function _btnViewFunc()
        if self.nd_visit then
            self:resetNdVisit()
            return
        end
        self:resetNdVisit()
        local uid = ucontext.uid--玩家自身id
        local _uid = msg.uid--查看对象id
        local lid = msg.ug.lid--查看对象联盟id
        local cid = msg.ug.cid--发公告者联盟id
        if not (uid == _uid) then
            local lb_name1 = Localize("btnVisit")
            local lb_name2
            if chatRoomSate == 1 then
                lb_name2 = Localize("labelLookUnion")
            elseif chatRoomSate == 2 then
                lb_name2 = Localize("power_give")
            end
            local pos=cellView:convertToWorldSpace(cc.p(0, 0- cellH/2))
            local pos=self.upNode:convertToNodeSpace(pos)
            if  chatRoomSate == 1 and cid then
                self:visitUnion(cid)
                return
            else
                local nd_visit, btn_visitPlayer, btn_visitUnion = GameUI.addVisitNode(self.upNode, 200-cellW, pos.y, {zorder = 10, priority = -2, lb_name1 = lb_name1, lb_name2 = lb_name2})
                self.nd_visit = nd_visit
                btn_visitPlayer:setListener(function()
                    self:visitPlayer(_uid)
                end)
                btn_visitUnion:setListener(function()
                    if chatRoomSate == 1 then
                        if lid then
                            self:visitUnion(lid)
                        else
                            display.pushNotice(Localize("stringNOUnion"))
                            return
                        end
                    elseif chatRoomSate == 2 then
                        self:givemonthcard(_uid)
                    end
                end)
            end
        end
    end
    -- local _colorNode =ui.colorNode({873,cellH},{255,0,0})
    -- display.adapt(_colorNode, 0, -cellH, GConst.Anchor.LeftBottom)
    -- cellView:addChild(_colorNode,-1)

    local btn_view = ui.button({873, cellH} ,_btnViewFunc, {})
    display.adapt(btn_view, 0, -cellH, GConst.Anchor.LeftBottom)
    cellView:addChild(btn_view)
    btn_view:setTouchThrowProperty(true, true)
    -- local btn=ui.button({1500,1500},function ( ... )
    --     btn_view:setVisible(false)
    -- end,{})
    -- display.adapt(btn, 0, -cellH, GConst.Anchor.LeftBottom)
    -- cellView:addChild(btn,-1)
    -- btn:setTouchThrowProperty(true,true)
end

function ChatRoom:_addCellView(msg, chatRoomSate)
    local mode = msg.mtype
    local cellView,cellH,key
    --对应添加信息
    if mode==1 then
        cellView, cellH=self:inforView1(msg)
    elseif mode==2 then
        cellView, cellH,key=self:inforView2(msg)
    elseif mode==4 then
        cellView, cellH=self:inforView4(msg)
    elseif mode==5 then
        cellView, cellH=self:inforView5(msg)
    elseif mode==6 then
        cellView, cellH = self:inforView6(msg)
    end
    self:addBtnOnView(cellView, {cellH = cellH, cellW = 873, msg = msg, chatRoomSate = chatRoomSate})
    return cellView,cellH,key
end

-- 预防错误数据
function ChatRoom:inTrueMode(mode)
    local modeArr = {1, 2, 4, 5, 6}
    local flag = false
    for k, v in pairs(modeArr) do
        if mode == v then
            flag = true
            break
        end
    end
    return flag
end

function ChatRoom:addInformation(msg,chatRoomSate)
    local mode = msg.mtype
    if not self:inTrueMode(mode) then
        return
    end
    local cellView,cellH,key=self:_addCellView(msg, chatRoomSate)
    local infos,viewsNode,viewsH,parity
    --状态已经变了
    if chatRoomSate==1 then
        infos=self.worldInfos
        viewsNode=self.leftViewsNode
        self.leftViewsH=self.leftViewsH+cellH
        viewsH=self.leftViewsH
        parity=self.leftParity
        self.leftParity=(self.leftParity+1)%2
    elseif chatRoomSate==2 then
        infos=self.unionInfos
        viewsNode=self.rightViewsNode
        self.rightViewsH=self.rightViewsH+cellH
        viewsH=self.rightViewsH
        parity=self.rightParity
        self.rightParity=(self.rightParity+1)%2
    end
    display.adapt(cellView, 0, cellH, GConst.Anchor.LeftBottom)
    viewsNode:addChild(cellView)
    if parity==1 then
        local temp =ui.colorNode({873,cellH},{218,204,173})
        display.adapt(temp, 0, -cellH, GConst.Anchor.LeftBottom)
        temp:setOpacity(0.5*255)
        cellView:addChild(temp,-1)
    end
    local info={view=cellView,viewH=cellH,msg = msg,key=key}
    table.insert(infos,info)
    self:_moveViews(-cellH,nil,chatRoomSate)

    if self.chatRoomSate == chatRoomSate then
        if viewsH>self.scrollH-self.offH then
            self.scrollNode:setElastic(true)
            self.scrollNode:setScrollContentRect(cc.rect(0,self.scrollH-viewsH-self.offH,0,viewsH+self.offH))
        else
            self.scrollNode:setElastic(false)
            self.scrollNode:setScrollContentRect(cc.rect(0,0,0,self.scrollH))
        end
    end
    self:_checkRemoveInformation(infos,chatRoomSate)
end

--信息数不超过30条,超过删除第一条
function ChatRoom:_checkRemoveInformation(infos,chatRoomSate)
    if #infos>30 then
        local temp=infos[1].view
        temp:removeFromParent(true)
        local viewH=infos[1].viewH
        local viewsH
        if chatRoomSate==1 then
            self.leftViewsH=self.leftViewsH-viewH
            viewsH=self.leftViewsH
        elseif chatRoomSate==2 then
            self.rightViewsH=self.rightViewsH-viewH
            viewsH=self.rightViewsH
        end
        if self.chatRoomSate == chatRoomSate then
            self.scrollNode:setScrollContentRect(cc.rect(0,self.scrollH-viewsH-self.offH,0,viewsH+self.offH))
        end
        table.remove(infos,1)
    end
end

--操作删除，接受，拒绝加入联盟请求
function ChatRoom:deleteInfoView(msg)
    local infos = self.unionInfos
    local idx
    local info
    for i,v in ipairs(infos) do
        --删除消息  是申请消息 用户ID对应 时间是小于删除消息时间
        if v.key==msg.dKey then
            idx = i
            info=v
            break
        end
    end
    if not idx then
        self:changChat(2)
        return
    end

    info.view:removeFromParent(true)
    local viewH = info.viewH
    self.rightViewsH = self.rightViewsH-viewH
    if self.chatRoomSate==2 then
        local viewsH = self.rightViewsH
        self.scrollNode:setScrollContentRect(cc.rect(0,self.scrollH-viewsH-self.offH,0,viewsH+self.offH))
    end
    table.remove(infos,idx)
    self:_moveViews(viewH,idx,2)
    self:delete(info.msg)
    self:deleteInfoView(msg)
end

--删除处理了的申请
function ChatRoom:deleteMsg(msg)
    local infos = self.unionInfos
    local idx
    for i,v in ipairs(infos) do
        --删除消息  是申请消息 用户ID对应 时间是小于删除消息时间
        if v.msg.mtype == 2 and v.msg.uid == msg.uid  and v.msg.time<msg.time then
            idx = i
            break
        end
    end
    if not idx then
        self:changChat(2)
        return
    end
    local temp = infos[idx].view
    temp:removeFromParent(true)
    local viewH = infos[idx].viewH
    self.rightViewsH = self.rightViewsH-viewH
    if self.chatRoomSate==2 then
        local viewsH = self.rightViewsH
        self.scrollNode:setScrollContentRect(cc.rect(0,self.scrollH-viewsH-self.offH,0,viewsH+self.offH))
    end
    table.remove(infos,idx)
    self:_moveViews(viewH,idx,2)
    --继续删除消息
    self:deleteMsg(msg)
end

function ChatRoom:deleteAllMsg()
    local infos = self.unionInfos
    for i,v in ipairs(infos) do
        v.view:removeFromParent(true)
        local viewH = infos[i].viewH
        self.rightViewsH = self.rightViewsH-viewH
    end
    self.unionInfos = {}
end

--加入或退出联盟
function ChatRoom:inforView1(msg)
    local bg=ui.node()
    local temp
    local ug = msg.ug
    local mode = ug.isOut
    local unionArray = ug.unionArray
    --以左上角为基点
    local viewH=185
    -- temp = ui.sprite("images/resExp_2.png",{64, 68})
    -- display.adapt(temp, 8, 100-175, GConst.Anchor.LeftBottom)
    -- bg:addChild(temp)
    local offx=0
    if GameLogic.useTalentMatch and msg.ug.headIcon then
        offx=80
        local headInfo={}
        local headBg=ui.node()
        display.adapt(headBg,75,-70)
        bg:addChild(headBg)
        GameUI.updateUserHeadTemplate(headBg,{iconType=msg.ug.headIcon,x=80,y=-80,z=0,blackBack=false, noBut=false,level=msg.ug.lv})
        headBg:setScale(0.65)
    else
        GameUI.addResourceIcon(bg,6, 0.64, offx+8+32,-68+34,0,2)
        temp = ui.label(tostring(ug.lv or ug.townLv or 0), General.font1, 30, {color={255,255,255}})
        display.adapt(temp, offx+40, -34, GConst.Anchor.Center)
        bg:addChild(temp)
    end

    local name = msg.name
    if msg.uid == self.context.uid then
        name = Localize("labelYou")
    end
    temp = ui.label(name or "", General.font5, 40, {color={255,255,255}})
    display.adapt(temp, offx+84, 134-175, GConst.Anchor.Left)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("stringAddingUnion"), General.font1, 40, {color={206,228,140}})
    display.adapt(temp, offx+83, 66-165, GConst.Anchor.Left)
    bg:addChild(temp)
    local text=temp
    if mode then
        text:setString(StringManager.getString("stringOutingUnion"))
        text:setColor(cc.c3b(255,151,108))
    end
    if unionArray then
        text:setString(Localize("teamSuccess"))
    end
    temp = ui.label("", General.font2, 35, {color={0,0,0}})
    display.adapt(temp, 768+74, 134-175, GConst.Anchor.Right)
    bg:addChild(temp)

    local time = GameLogic.getTime()-msg.time
    local timeStr = Localizef("timeAgo2",{time = Localizet(time)})
    if time<15 then
        timeStr = Localize("labelJustNow")
    end
    temp = ui.label(timeStr, General.font2, 30, {color={0,0,0}})
    display.adapt(temp, 851, 27-175-10, GConst.Anchor.Right)
    bg:addChild(temp)
    bg.timeLb = temp
    return bg ,viewH
end

function ChatRoom:getTimeStr(time)
    local time = GameLogic.getTime()-time
    local timeStr = Localizef("timeAgo2",{time = Localizet(time)})
    if time<15 then
        timeStr = Localize("labelJustNow")
    end
    return timeStr
end

function ChatRoom:inforView2(msg)
    local bg=ui.node()
    local temp
    local viewH=335

    -- temp = ui.sprite("images/resExp_2.png",{64, 68})
    -- display.adapt(temp, 8, -72, GConst.Anchor.LeftBottom)
    -- bg:addChild(temp)
    GameUI.addResourceIcon(bg, 6, 0.64, 8+32,-72+34,0,2)
    temp = ui.label(tostring(msg.ug.lv or 0), General.font1, 30, {color={255,255,255}})
    display.adapt(temp, 40, -38, GConst.Anchor.Center)
    bg:addChild(temp)

    local name = msg.name
    if msg.uid == self.context.uid then
        name = Localize("labelYou")
    end
    temp = ui.label(name, General.font5, 40, {color={255,255,255}})
    display.adapt(temp, 84, -38, GConst.Anchor.Left)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("stringIWantToJionYou"), General.font2, 35, {color={0,0,0}})
    display.adapt(temp, 84, -97, GConst.Anchor.Left)
    bg:addChild(temp)

    temp = ui.label(StringManager.getString("stringIWantToJionYou1"), General.font1, 35, {color={255,255,255}})
    display.adapt(temp, 453, -165, GConst.Anchor.Center)
    bg:addChild(temp)

    -- temp = ui.button({212, 82} ,nil, {image="images/btnOrange.png"})
    -- display.adapt(temp, 330, -271+20, GConst.Anchor.Center)
    -- bg:addChild(temp)

    local dKey="unionRqeust_"..msg.uid
    msg.dKey=dKey
    self.msgTable[msg.uid] = msg
    GameEvent.bindEvent(bg,"removeChatRoomMsg","",function(event,uid)
        if self.msgTable[uid] then
            if self.notReadNum > 0 then
                self.notReadNum = self.notReadNum - 1
            end
            self:delete(self.msgTable[uid])
            self:deleteInfoView(self.msgTable[uid])
        end
        end)
    temp = ui.button({212, 83} ,nil, {image="images/btnGreen.png"})
    display.adapt(temp, 891/2, -272+20, GConst.Anchor.Center)
    bg:addChild(temp)
    temp:setListener(function()
        print("前往")
        if GameLogic.getUserContext().union and GameLogic.getUserContext().union.job > 3 then
           UnionInfoDialog.new()
        end
    end)
    if GameLogic.getUserContext().union and GameLogic.getUserContext().union.job < 4 then
        temp:setVisible(false)
    end
    local centertBut=temp
    temp = ui.label(StringManager.getString("labelGo"), General.font1, 35, {color={255,255,255}})
    display.adapt(temp, 106, 50, GConst.Anchor.Center)
    centertBut:getDrawNode():addChild(temp)

    temp = ui.label("", General.font2, 35, {color={0,0,0}})
    display.adapt(temp, 842, -38, GConst.Anchor.Right)
    bg:addChild(temp)

    local time = GameLogic.getTime()-msg.time
    local timeStr = Localizef("timeAgo2",{time = Localizet(time)})
    if time<15 then
        timeStr = Localize("labelJustNow")
    end
    temp = ui.label(timeStr, General.font2, 30, {color={0,0,0}})
    display.adapt(temp, 851, -307-10, GConst.Anchor.Right)
    bg:addChild(temp)
    bg.timeLb = temp
    return bg ,viewH,dKey
end

function ChatRoom:inforView6(msg)
    local bg = ui.node()
    local temp
    local viewH = 126
    GameUI.addResourceIcon(bg, 6, 0.64, 8+32, -68+34, 0, 2)
    local dx = 0
    local name = msg.name
    temp = ui.label(StringManager.getString(name or ""), General.font1, 40, {color = {255, 255, 255}})
    display.adapt(temp, 84, -66, GConst.Anchor.left)
    bg:addChild(temp)

    local textH1 = temp:getContentSize().height
    local uname = msg.ug.uname
    local tempText = ui.label(Localizef(msg.text, {name = uname}), General.font2, 35, {color = {255, 255, 255}, width = 734, align = GConst.Align.Left })
    display.adapt(tempText, 84, -34-textH1, GConst.Anchor.LeftTop)
    bg:addChild(tempText, 10)
    local textH2 = tempText:getContentSize().height
    local addH = textH1 + textH2
    temp = ui.scale9("images/bgWhiteEdgeGray.9.png", 10, {761, textH2+20})
    display.adapt(temp, 63, -addH-34-10, GConst.Anchor.LeftBottom)
    bg:addChild(temp)

    local time = GameLogic.getTime()-msg.time
    local timeStr = Localizef("timeAgo2",{time = Localizet(time)})
    if time<15 then
        timeStr = Localize("labelJustNow")
    end
    temp = ui.label(timeStr, General.font2, 30, {color={0,0,0}})
    display.adapt(temp, 851, -78-addH, GConst.Anchor.Right)
    bg:addChild(temp)
    addH =  viewH + addH
    return bg, addH
end

function ChatRoom:inforView4(msg)
    local bg=ui.node()
    local temp
    local viewH=126
    -- temp = ui.sprite("images/resExp_2.png",{64, 68})
    -- display.adapt(temp, 8, -68, GConst.Anchor.LeftBottom)
    -- bg:addChild(temp)
    local offx=0
    --GameLogic.useTalentMatch and 
    if msg.ug.headIcon then
        offx=80
        local headInfo={}
        local headBg=ui.node()
        display.adapt(headBg,75,-70)
        bg:addChild(headBg)
        GameUI.updateUserHeadTemplate(headBg,{iconType=msg.ug.headIcon,x=80,y=-80,z=0,blackBack=false, noBut=false,level=msg.ug.lv})
        headBg:setScale(0.65)
    else
        GameUI.addResourceIcon(bg,6, 0.64, offx+8+32,-68+34,0,2)
        temp = ui.label(StringManager.getString(msg.ug.lv), General.font1, 30, {color={255,255,255}})
        display.adapt(temp, offx+40, -34, GConst.Anchor.Center)
        bg:addChild(temp)
    end
   

    local dx = 0
    if msg.ug.flag then
        local flag = GameUI.addUnionFlag(msg.ug.flag)
        flag:setScale(0.17)
        display.adapt(flag,offx+100,-40,GConst.Anchor.Center)
        bg:addChild(flag)
        dx = 60
    end
    local name = msg.name
    if msg.uid == self.context.uid then
        name = Localize("labelYou")
    end
    temp = ui.label(StringManager.getString(name or ""), General.font5, 40, {color={255,255,255}})
    display.adapt(temp, offx+84+dx, -34, GConst.Anchor.Left)
    bg:addChild(temp)
    local str = ""
    if msg.ug.job then
        str = Localize("labelCellJob" .. msg.ug.job)
    end
    temp = ui.label(str, General.font2, 36, {color={0,0,0}})
    display.adapt(temp, offx+842, -38, GConst.Anchor.Right)
    bg:addChild(temp)

    local unameH = 0
    if msg.ug.uname then
        temp = ui.label(msg.ug.uname, General.font5, 25, {color={255,255,255},width=740,align=GConst.Align.Left})
        display.adapt(temp, offx+76, -78, GConst.Anchor.LeftTop)
        bg:addChild(temp)
        unameH = 40
    end

    --晋升 降职 更改部落设置
    if msg.ug.mode then
        if msg.ug.mode==3 then
            temp = ui.label(Localize("labelUnionChat3"), General.font2, 40, {color={0,0,0},width=740,align=GConst.Align.Left})
        else
            temp = ui.label(Localizef("labelUnionChat" .. msg.ug.mode, {a=msg.infoName}), General.font2, 40, {color={0,0,0},width=740,align=GConst.Align.Left})
        end
        if msg.ug.mode==2 or msg.ug.mode==0 then
            temp:setColor(cc.c3b(255,151,108))
        else
            temp:setColor(cc.c3b(206,228,140))
        end
    else
        local str = string.gsub(msg.text, "^%s*(.-)%s*$", "%1")
        temp = ui.label(StringManager.getString(str), General.font6, 35, {color={0,0,0},width=740-offx,align=GConst.Align.Left})
    end
    display.adapt(temp, offx+84, -78-unameH, GConst.Anchor.LeftTop)
    bg:addChild(temp)

    local textH=temp:getContentSize().height
    local addWidth=textH+23+unameH
    local time = GameLogic.getTime()-msg.time
    local timeStr = Localizef("timeAgo2",{time = Localizet(time)})
    if time<15 then
        timeStr = Localize("labelJustNow")
    end
    temp = ui.label(timeStr, General.font2, 30, {color={0,0,0}})
    if GameLogic.useTalentMatch then
        display.adapt(temp, 851, -38, GConst.Anchor.Right)
        viewH=viewH-40
    else
        display.adapt(temp, 851, -78-addWidth, GConst.Anchor.Right)
    end
    bg:addChild(temp)
    bg.timeLb = temp
    viewH=viewH+addWidth
    return bg,viewH
end
--入会金杯限制
function ChatRoom:inforView5(msg)
    local bg=ui.node()
    local temp

    -- temp = ui.sprite("images/resExp_2.png",{64, 68})
    -- display.adapt(temp, 8, 430-175-335, GConst.Anchor.LeftBottom)
    -- bg:addChild(temp)
    local offx=0
    if GameLogic.useTalentMatch and msg.ug.headIcon then
        offx=80
        local headInfo={}
        local headBg=ui.node()
        display.adapt(headBg,75,-70)
        bg:addChild(headBg)
        GameUI.updateUserHeadTemplate(headBg,{iconType=msg.ug.headIcon,x=80,y=-80,z=0,blackBack=false, noBut=false,level=msg.ug.lv})
        headBg:setScale(0.65)
    else
        GameUI.addResourceIcon(bg,6, 0.64, offx+8+32,-68+34,0,2)
        temp = ui.label(StringManager.getString(msg.ug.lv), General.font1, 30, {color={255,255,255}})
        display.adapt(temp, offx+40, -34, GConst.Anchor.Center)
        bg:addChild(temp)
    end

    temp=GameUI.addUnionFlag(msg.ug.flag)
    display.adapt(temp, offx+116, 286-335, GConst.Anchor.LeftBottom)
    temp:setScale(0.22)
    bg:addChild(temp)

    temp = ui.label(StringManager.getString(msg.ug.cname), General.font5, 40, {color={255,255,255}})
    display.adapt(temp, offx+177, 467-175-335, GConst.Anchor.Left)
    bg:addChild(temp)
    local name = msg.name
    if msg.uid == self.context.uid then
        name = Localize("labelYou")
    end
    temp = ui.label(StringManager.getString(name), General.font5, 35, {color={255,255,255}})
    display.adapt(temp, offx+72, 397-175-335, GConst.Anchor.Left)
    bg:addChild(temp)
    if msg.ug.textId then
        local str = "dataUnionNotice" .. msg.ug.textId
        temp = ui.label(Localizef(str, {name = msg.ug.cname}), General.font2, 30, {color={255,255,255},width=740,align=GConst.Align.Left})
    else
        temp = ui.label(msg.text, General.font2, 30, {color={255,255,255},width=740,align=GConst.Align.Left})
    end
    display.adapt(temp, 77, 182-335, GConst.Anchor.LeftTop)
    bg:addChild(temp,2)
    local textH=temp:getContentSize().height+10
    -- temp = ui.label(Localize("labelTrophyLimit") .. msg.ug.cup, General.font2, 30, {color={255,255,255}})
    -- display.adapt(temp, 77, 182-textH-335, GConst.Anchor.LeftTop)
    -- bg:addChild(temp,2)
    local addWidth=textH-80
    temp = ui.button({761,140+addWidth+20},nil,{scale9edge=10,image = "images/bgWhiteEdgeGray.9.png",actionType = 0})
    display.adapt(temp, 63+380, 226-175+70-addWidth/2-335, GConst.Anchor.Center)
    bg:addChild(temp)
    temp:setListener(function()
        UnionInfoDialog.new(msg.ug.cid)
    end)
    temp:setTouchThrowProperty(true, true)

    local time = GameLogic.getTime()-msg.time
    local timeStr = Localizef("timeAgo2",{time = Localizet(time)})
    if time<15 then
        timeStr = Localize("labelJustNow")
    end
    temp = ui.label(StringManager.getString(timeStr), General.font2, 30, {color={0,0,0}})
    display.adapt(temp, 851, 203-175-addWidth-335-10, GConst.Anchor.Right)
    bg:addChild(temp)

    return bg ,335+addWidth+20
end

function ChatRoom:update(diff)
    --轮询 联盟聊天
    --联盟
    if GameLogic.inError then
        return
    end
    if not self.notReceive and self.context.union then
        self.notClearUnionInfos = nil
        if not self.pollTime then
            self.pollTime = 0
        end
        local dtime = 10
        if self.state and self.chatRoomSate == 2 then
            dtime = 3
        end
        self.pollTime = self.pollTime+diff
        if self.pollTime>=dtime then
            self.pollTime = 0
            self:recv2()
        end
    end
    if not self.context.union and not self.notClearUnionInfos then
        self.notClearUnionInfos = true
        self:deleteAllMsg()
        self:changChat(1)
    end

    --世界
    if self.chatRoomSate == 1 and self.state and not self.notReceive2 then
        if not self.pollTime2 then
            self.pollTime2 = 0
        end
        local dtime = 0
        self.pollTime2 = self.pollTime2+diff
        if self.pollTime2>=dtime then
            dtime = 3
            self.pollTime2 = 0
            self:recv1()
        end
    end

    if self.chatRoomSate == 2 then
        if self.context.union ~= self.hasUnionUp then
            self:addUpNodeViews(2)
        end
    end

    if not self.startTime then
        self.startTime = 0
    end
    self.wcold = self.startTime-GameLogic.getSTime()


    --刷新时间
    if not self.refreshTime then
        self.refreshTime = 0
    end
    self.refreshTime = self.refreshTime+diff
    if self.refreshTime>=60 then
        self.refreshTime = self.refreshTime - 60
        for _,v in pairs(self.unionInfos) do
            if v.view and v.view.timeLb then
                v.view.timeLb:setString(self:getTimeStr(v.msg.time))
            end
        end
        for _,v in pairs(self.worldInfos) do
            if v.view and v.view.timeLb then
                v.view.timeLb:setString(self:getTimeStr(v.msg.time))
            end
        end
    end

    --未读
    self.redNum:setNum(self.notReadNum)
end
function ChatRoom:doOther(msg)
    local context = GameLogic.getUserContext()
    local vips = context.vips
    if vips[4][2]-GameLogic.getSTime()>3*86400 or GameLogic.getSTime()-msg.time>3*86400 then
        return
    end
    display.pushNotice(Localizef("stringWhoGiveYouMonthCard",{a = msg.name}))
    if vips[4][2]>GameLogic.getSTime() then
        vips[4][2] = vips[4][2]+30*86400
        vips[5][2] = vips[5][2]+30*86400
    else
        vips[4][2] = GameLogic.getSTime()+30*86400
        if vips[5][2]>GameLogic.getSTime() then
            vips[5][2] = vips[5][2]+30*86400
        else
            vips[5][2] = GameLogic.getSTime()+30*86400
        end
    end
    context.activeData:finishAct(4)
end
------------------------------------------------------------------------------------------------------------------
function ChatRoom:recv1()
    local since = self.since2 or 0
    local channel = GEngine.rawConfig.channel
    local cid=0
    if channel == "com.bettergame.heroclash_ir3" then
        cid=-100
    elseif channel == "com.almuathir.zombies2" or channel == "com.almuathir.zombies2_ios" then
        cid=-200
    end
    self.notReceive2 = true
    _G["GameNetwork"].request("recv",{cid = cid,since = since},function(isSuc,data)
        self.notReceive2 = false
        if isSuc then
            if not self.recv1 then
                return
            end
            for i,v in ipairs(data.messages) do
                local ug = type(v[6]) == "string" and json.decode(v[6]) or v[6]
                local msg = {uid = v[1],name = v[2],text = v[3],time = v[4],ug = ug,mtype = v[7],cid = cid}
                self.since2 = msg.time
                self:addInformation(msg, 1)
            end
        end
    end)
end


function ChatRoom:recv2()
    local since = self.since or 0
    local cid = GameLogic.getUserContext().union and GameLogic.getUserContext().union.id
    self.notReceive = true
    _G["GameNetwork"].request("recv",{cid = cid,since = since},function(isSuc,data)
        self.notReceive = false
        if isSuc then
            if not self.recv2 then
                return
            end
            if not self.context.union then
                return
            end
            local msgTime = self:getMsgTime()
            local unionMsg = GEngine.getConfig("unionMsg"..GameLogic.getUserContext().uid..GameLogic.getUserContext().sid)
            if unionMsg then
                unionMsg = json.decode(unionMsg)
                for i,v in ipairs(data.messages) do
                    table.insert(unionMsg,v)
                    if #unionMsg>30 then
                        table.remove(unionMsg,1)
                    end
                end
                GEngine.setConfig("unionMsg"..GameLogic.getUserContext().uid..GameLogic.getUserContext().sid,json.encode(unionMsg),true)
            else
                for i=1,#data.messages do
                    if i>30 then
                        table.remove(data.messages,1)
                    end
                end
                GEngine.setConfig("unionMsg"..GameLogic.getUserContext().uid..GameLogic.getUserContext().sid,json.encode(data.messages),true)
            end
            for i,v in ipairs(data.messages) do
                local ug = (type(v[6]) == "string" and json.decode(v[6]) or v[6])
                local msg = {uid = v[1],name = v[2],text = v[3],time = v[4],ug = ug,mtype = v[7],cid = cid}
                self.since = msg.time
                if self.context.union.enterTime<=msg.time then
                    if msg.mtype == 10 then
                        self:deleteMsg(msg)
                    elseif msg.mtype>10 then
                        local ug = msg.ug
                        if ug and ug.uid == self.context.uid then
                            self:doOther(msg)
                        end
                    else
                        self:addInformation(msg,2)
                        if not self.state then
                            if msgTime<msg.time then
                                self.notReadNum = self.notReadNum+1
                                msgTime = msg.time
                            end
                        end
                        if msg.uid==self.context.uid and ug.isOut==false then
                            GameEvent.sendEvent("EventFreshUnionMenu")
                        end
                    end
                end
            end
            if self.state then
                self:setMsgTime(msgTime)
            else
                self.msgTime = msgTime
            end
        end
    end)
end

--已读聊天的时间
function ChatRoom:setMsgTime(t,mtype)
    local uid = self.context.uid
    local sid = self.context.sid
    local key = sid .. "c" .. uid .. "msgTime"
    GEngine.setConfig(key,t,true)
end

function ChatRoom:getMsgTime()
    local uid = self.context.uid
    local sid = self.context.sid
    local key = sid .. "c" .. uid .. "msgTime"
    local t = GEngine.getConfig(key)
    return t or 0
end

--5联盟公告  4 普通发言   2加入申请    1加入或退出信息 ug.isOut=ture是退出 如果有 ug.mode  1是晋升 2是降职 3是更改设置
--10删除消息  删除是text是time   要删除信息的时间

--11赠送月卡

function ChatRoom:send(msg)
    msg.text = filterSensitiveWords(msg.text)
    if self.banedInfos then
        local banedInfos=self.banedInfos
        if banedInfos.etime and banedInfos.etime>GameLogic.getSTime() then
            local banedText = banedInfos.reason.."，"..Localize("labelBattleEnd")..StringManager.getTimeString(banedInfos.etime-GameLogic.getSTime())
            display.pushNotice(banedText)
            return
        else
            self.banedInfos=nil
        end
    end
    msg.chatRoom=true
    _G["GameNetwork"].request("send",msg,function(isSuc,data)
        if isSuc then
            if not data or KTLen(data) == 0 then
                display.pushNotice(Localize("beenGag"))
                return
            end
            if data.result and data.result=="baned" then
                self.banedInfos={}
                local reason = data.reason
                self.banedInfos.reason=reason
                local etime = data.etime
                self.banedInfos.etime=etime
                local banedText = reason.."，"..Localize("labelBattleEnd")..StringManager.getTimeString(etime-GameLogic.getSTime())
                display.pushNotice(banedText)
                return
            end
            if msg.mtype == 2 then
                display.pushNotice(Localize("stringApplySucceed"))
            end
            local channel = GEngine.rawConfig.channel
            local cid=0
            if channel == "com.bettergame.heroclash_ir3" then
                cid=-100
            elseif channel == "com.almuathir.zombies2" or channel == "com.almuathir.zombies2_ios" then
                cid=-200
            end
            if msg.cid == cid and msg.mtype~=5 then
                self.startTime=const.ChatCold+GameLogic.getSTime()
                self.wcold = const.ChatCold
                local uid = self.context.uid
                local sid = self.context.sid
                local key = sid .."c" .. uid .. "wctimes"
                local wcf = GEngine.getConfig(key) or "[0,0]"
                wcf = json.decode(wcf)
                local dt = GameLogic.getSTime()-wcf[2]
                if dt>GameLogic.getRtime() then
                    wcf = {0,0}
                end
                wcf[1] = wcf[1]+1
                wcf[2] = GameLogic.getSTime()
                GEngine.setConfig(key,json.encode(wcf),true)
            end
            --公告扣宝石
            if msg.mtype == 5 then
                self:changChat(1)
                display.pushNotice(Localize("stringUNoticeSendSuc"))
                self.context:changeRes(const.ResCrystal, -const.NoticeCost)
                GameLogic.statCrystalCost("公告消耗",const.ResCrystal, -const.NoticeCost)
                GameLogic.getUserContext():addCmd({const.CmdCostNotice})
            end
        else
            display.pushNotice(Localize("beenGag"))
        end
    end)
end

function ChatRoom:jionleague(msg)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("jionleague",{jionleague={GameLogic.getUserContext().union.id,msg.uid,2}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            --self:delete(msg)
            if data.code==2 then
                -- GameLogic.getUserContext().union = nil
                -- display.pushNotice(Localize("noticeOutLeague"))
                return
            elseif data.code==11 then
                self:deleteInfoView(msg)
                display.pushNotice(Localize("labelJoinUnionFail11"))
                return
            elseif data.code==10 then
                self:deleteInfoView(msg)
                display.pushNotice(Localize("labelJoinUnionFail10"))
                return
            end
            self:deleteInfoView(msg)
            local ug = msg.ug
            ug.isOut = false
            local msg = {uid=msg.uid,cid=msg.cid,text="1234",name=msg.name,ug=json.encode(ug),mtype=1}
            self:send(msg)
        end
    end)
end

function ChatRoom:delete(msg)
    _G["GameNetwork"].request("delete",{mid = msg.time,cid = msg.cid,uid = msg.uid},function(isSuc,data)
        if data == 1 then
            print("删除成功")
        end
    end)
end

return ChatRoom











