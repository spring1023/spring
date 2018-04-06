UnionApplyLogDialog = class(DialogViewLayout)
function UnionApplyLogDialog:onInitDialog()
    self:setLayout("UnionApplyLogDialog.json")
    self:loadViewsTo()
    --帮助的文本
    self.title:setString(Localize("unionApplyLog"))
    self.context = GameLogic.getUserContext()
    self.mulNum = 1
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWelfare)
    if buffInfo[4]~=0 then
        self.mulNum = buffInfo[4]/20
    end
    self:showUI()
end

function UnionApplyLogDialog:showUI()
    -- body
    local data = self.params
    local info={}
    for k,v in ipairs(data) do
        table.insert(info,{id = k,uid = v[1],icon = v[3],level = v[4],name = v[5],vip = v[6],power = v[7],walfnum = v[8],walfTime = GameLogic.getSTime() - v[9]})
    end
    if next(info) then
        self.length=#info
        self.infos = info
        self.tabelView = GameUI.helpLoadTableView(self.sNode,info,Handler(self.cellCallBack,self))
        self.infos = info
    else
        display.pushNotice(Localize("labelApplyTip"))
    end
end
function UnionApplyLogDialog:refeshInfoId(info)
    if not next(info) then
        return
    end
    for k,v in ipairs(info) do
        if v and v.id then
            v.id = k
        end
    end
end


function UnionApplyLogDialog:cellCallBack(cell, tableView, info)
    -- body
     if not info.viewLayout then
        info.viewLayout = self:addLayout("scrollNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.view = cell
        self:updateUI(info)
    end
end

function UnionApplyLogDialog:refeshInfoId(info)
    if not next(info) then
        return
    end
    for k,v in ipairs(info) do
        if v and v.id then
            v.id = k
        end
    end
end
function UnionApplyLogDialog:updateUI(info)
    -- body
    --玩家名字
    info.lvname:setString("Lv:"..info.level.." "..info.name)
    --VIP
    GameUI.addVip(info.vipbg,info.vip,0,0)
    --战斗力
    info.powerNum:setString(tostring(Localize("propertyComb")..info.power))
    --头像
    local head = GameUI.addPlayHead(info.iconNode,{viplv=nil,id=info.icon,scale=1,x=0,y=0,z=1,blackBack = true})
    head:setTouchThrowProperty(true,true)
    --钻石数量
    info.diamondNum:setString(math.floor(self.mulNum*info.walfnum))
    --同意按钮
    info.btnOk:setScriptCallback(ButtonHandler(function ()
        -- body

        if not GameNetwork.lockRequest() then
            return
        end
        _G["GameNetwork"].request("jionleague",{jionleague={self.context.union.id,info.uid,2}},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                if data.code == 11 then
                    display.pushNotice(Localize("labelJoinUnionFail11"))
                    return
                elseif data.code == 2 then
                    display.pushNotice(Localize("noticeOutLeague"))
                elseif data.code == 0 then

                elseif data.code == 13 then
                    display.pushNotice(Localize("labelJoinUnionFail10"))
                elseif data.code == 15 then
                    display.pushNotice(Localize("labelJoinUnionFail13"))
                end
                GameEvent.sendEvent("removeChatRoomMsg",info.uid)
                GameEvent.sendEvent("applyUnion",0)
                self.tabelView:removeCell(info.id)
                self.length=self.length-1
                self:refeshInfoId(self.infos)
                if self.length<=0 then
                    display.closeDialog(display.getDialogPri())
                end
            end
        end)
    end,self))
    info.btnOk.view:setTouchThrowProperty(true, true)
    --拒绝按钮
    info.btnNo:setScriptCallback(ButtonHandler(function ()
        -- body
        if not GameNetwork.lockRequest() then
            return
        end
        _G["GameNetwork"].request("jionleague",{jionleague={self.context.union.id,info.uid,3}},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                self.tabelView:removeCell(info.id)
                self.length=self.length-1
                self:refeshInfoId(self.infos)
                if self.length<=0 then
                    display.closeDialog(display.getDialogPri())
                end
                GameEvent.sendEvent("removeChatRoomMsg",info.uid)
                GameEvent.sendEvent("applyUnion",0)
            end
        end)
    end,self))
    info.btnNo.view:setTouchThrowProperty(true, true)
    --最后登录时间
    info.lastTime:setString(Localizef("labelLastLogin",{a=Localizet(info.walfTime)}))
end


