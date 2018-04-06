local const = GMethod.loadScript("game.GameLogic.Const")
--系统设置对话框
local PushInfoDialog = class(DialogViewLayout);

function PushInfoDialog:ctor()
	self.dialogDepth = display.getDialogPri()+1
    self.priority= self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function PushInfoDialog:onCreate()
    self:setLayout("userInfo_push_dialog.json");
    self:loadViewsTo()
end

function PushInfoDialog:initUI()
    -- 关闭按钮
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority));
	
    local infos={}
    --第一条显示
    for i=2,const.pushNum do
        -- 不显示联盟战推送
        if i ~= 3 then
            table.insert(infos,{id=i})
        end
    end
    -- 1-6
    local code = GameLogic.getUserContext():getInfoItem(const.InfoPush)
    self.tab = GameLogic.dnumber(code,const.pushNum)

    local scroll = self.scroll_btns
    scroll:setLazyTableData(infos,Handler(self.callCell,self),0)
end

function PushInfoDialog:callCell(cell, scroll, info)
    if not cell then
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end

    cell:setVisible(info.id ~= 5);  -- 屏蔽第五个
    cell.lb_pushDes:setString(Localize("dataPushName"..info.id))
    cell.push_open:setVisible(self.tab[info.id] == 1)
    cell.push_close:setVisible(self.tab[info.id] == 0)
    cell.btn_push:changePriority(-10)
    cell.btn_push:setScriptCallback(ButtonHandler(function()
        if self.tab[info.id] == 1 then
            self.tab[info.id] = 0
        else
            self.tab[info.id] = 1
        end
        cell.push_open:setVisible(self.tab[info.id] == 1)
        cell.push_close:setVisible(self.tab[info.id] == 0)       
    end))
    return cell
end

function PushInfoDialog:canExit()
    -- print("exit---");
    local context = GameLogic.getUserContext()
    local code = GameLogic.enumber(self.tab)
    if code ~= context:getInfoItem(const.InfoPush) then
        self:changesetting(code)
        context:setInfoItem(const.InfoPush,code)
    end
    return true
end

function PushInfoDialog:changesetting(code)
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdSetChange,code})
end

return PushInfoDialog