local const = GMethod.loadScript("game.GameLogic.Const")
--头像
local LordHeadListDialog = GMethod.loadScript("game.UI.NewDialog.NewLordHeadListDialog");
--头像框
local LordHeadBackListDialog = GMethod.loadScript("game.UI.NewDialog.NewLordHeadBackListDialog");
-- 更换昵称
local RenameDialog = GMethod.loadScript("game.UI.NewDialog.NewRenameDialog");
-- 系统设置
local SystemSetDialog=GMethod.loadScript("game.UI.NewDialog.NewSystemSetDialog")
--领主头像对话框

local LordHeadDialog = class(DialogViewLayout);

function LordHeadDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function LordHeadDialog:onCreate()
    self:setLayout("userInfo_main_dialog.json")
    self:loadViewsTo()
end

function LordHeadDialog:initUI()
    -- 关闭按钮
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))

    -- 用户信息界面
    self.main:setVisible(true)
    self.name:setVisible(false)

    local context = GameLogic.getUserContext()

    -- 头像id
    self.headId = context:getInfoItem(const.InfoHead)
    -- 头像框id
    -- self.bkid = context:getInfoItem(const.InfoFrame)
    
    -- 初始化头像
    self:initHead()

    -- 更改昵称按钮
    self.btn_changeName:setScriptCallback(function()
        display.showDialog(RenameDialog.new({callback = function()
            self.lb_userName:setString(context:getInfoItem(const.InfoName))
        end}))
    end)

    self.lb_userName:setString(context:getInfoItem(const.InfoName))
    -- 账号ID
    self.lb_userId:setString(Localize("labelID")..context.uid)

    -- 领主等级
    self.lb_userLV:setString(Localize("labelLoadLv") .. "：" .. context:getInfoItem(const.InfoLevel))
    -- 领主经验
    local value,max = context:getRes(const.ResExp),context:getResMax(const.ResExp)
    if max == 0 then
        self.lb_userexpNum:setString(Localize("labelLevelMax"))
    else
        self.lb_userexpNum:setString(value .. "/" .. max)
    end

    self.img_progress_exp:setProcess(true, value/max);
    
    -- 服务器时间
    self.lb_serverTime:setString(Localize("labelServerTime")..GameLogic.getTimeFormat2(GameLogic.getSTime()));
    RegTimeUpdate(self.view, Handler(self.update, self), 0.2)

    -- 获取联盟信息
    self:setUnion()

    -- 修改头像按钮
    self.btn_changeHead:setScriptCallback(function()
        LordHeadListDialog.new({headBackId = self.bkid,callback = function(hid,awakeUp)
            if self.headId then
                self.headId = self.headId%10+hid*100+(awakeUp>0 and 1 or 0)*10
                if self.initHead then
                    self:initHead()
                end
            end
        end})
    end)

    -- 修改头像框按钮
    self.btn_changeHeadFrame:setScriptCallback(function()
        -- 创建头像背景框列表界面
        LordHeadBackListDialog.new({callback = function(bkid)
                self.headId = math.floor(self.headId/10)*10+bkid
                self:initHead()
            end})
    end)


    -- 系统设置按钮 (未改)
    self.btn_system:setScriptCallback(function()
        SystemSetDialog.new()
    end)

     -- 更改服务器按钮(就是跟退出登录啊)
    self.btn_serverChange:setScriptCallback(function()
        local otherSettings = {callback=function()
            local loginType=GEngine.getConfig("lastLoginMsg")[2]
            Plugins:logoutWithSdk(loginType)
            GEngine.setConfig("lastLoginMsg","",true)
            GEngine.restart()
        end,yesBut="labelQuYiYiJue",noBut="labelSheBuDe"}
        local dialog = AlertDialog.new(3,Localize("labelQuitGameMa"),Localize("stringQuitGameMa"),otherSettings)
        display.showDialog(dialog)
    end)
end

function LordHeadDialog:setUnion()
    -- print("刷新了没");
    local union = GameLogic.getUserContext().union
    
    if union then
        self.lb_unionBelong:setVisible(true);
        self.lb_unionID:setVisible(true);
        self.btn_leaveUnion:setVisible(true);
        self.btn_seeUnion:setVisible(true);
        -- 联盟名称
        self.lb_unionBelong:setString(Localize("labelUnionBelongTo").." "..union.name);
        -- 联盟ID
        self.lb_unionID:setString(Localize("labelUnionID").." "..union.id);


        -- 联盟退出按钮
        self.btn_leaveUnion:setScriptCallback(function()
            -- print("退出联盟")
            local otherSettings = {callback = function()
                if self.leaveleague then
                    self:leaveleague()
                end
            end}
            local dialog = AlertDialog.new(3,Localize("unionInfoNotice1"),Localize("unionInfoNotice2"),otherSettings)
            display.showDialog(dialog)
        end)


        -- 联盟查看按钮
        self.btn_seeUnion:setScriptCallback(function()
            -- 显示联盟界面
            GameEvent.registerEvent("updateUnionState",self,self.setUnion); --刷新联盟信息状态
            UnionInfoDialog.new()
        end);
    else
        self.lb_unionBelong:setVisible(false);
        self.lb_unionID:setVisible(false);
        self.btn_leaveUnion:setVisible(false);
        self.btn_seeUnion:setVisible(false);
    end
end

function LordHeadDialog:onEnter()
    -- dump("------------onEnter--------------");
end

function LordHeadDialog:initHead()
    local context = GameLogic.getUserContext()
    local viplv = context:getInfoItem(const.InfoVIPlv)
    local lv = context:getInfoItem(const.InfoLevel)
    -- 用户头像显示node
    local size = self.userHead:getContentSize()
    -- local x, y = self.head:getPosition();
    -- self.head = GameUI.addPlayHead(self.userHead,{id = self.headId,scale = 1,x=size[1]/2,y=size[2]/2})
    local headId = math.floor(self.headId/100)
    GameUI.addItemIcon(self.userHead,9,headId,0.8,size[1]/2,size[2]/2,true,nil,{lv = lv}) 
end
-- 当前界面退出前调用
function LordHeadDialog:canExit()
    if self.headId ~= GameLogic.getUserContext():getInfoItem(const.InfoHead) then
        self:changehead()
    end
    GameLogic.getUserContext():setInfoItem(const.InfoHead,self.headId)
    return true
end
------------------------------------------------------------------------------------
-- 退出联盟
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
                self.lb_unionBelong:setVisible(false);
                self.lb_unionID:setVisible(false);
                self.btn_leaveUnion:setVisible(false);
                self.btn_seeUnion:setVisible(false);
            end
            
        end
    end)
end
-- 修改头像
function LordHeadDialog:changehead()
    local context = GameLogic.getUserContext()
    GameLogic.getUserContext():setInfoItem(const.InfoHead,self.headId)
    -- GameLogic.getUserContext():setInfoItem(const.InfoFrame,self.bkid)
    -- dump(self.headId, self.bkid)
    context:addCmd({const.CmdHeadChange, self.headId, self.bkid})
end

function LordHeadDialog:changeheadback()
    local context = GameLogic.getUserContext()
    GameLogic.getUserContext():setInfoItem(const.InfoFrame,self.bkid)
    context:addCmd({const.CmdHeadChange, self.bkid})
end

-- 刷新时间label
function LordHeadDialog:update()
    self.lb_serverTime:setString(Localize("labelServerTime")..GameLogic.getTimeFormat2(GameLogic.getSTime()))
    if self.textBox then
        local name = self.textBox:getText()
        local str = string.trim(name)
        if str == "" then
            self.btn_ok:setGray(true)
            self.btn_ok:setEnable(false)
        else
            self.btn_ok:setGray(false)
            self.btn_ok:setEnable(true)
        end
    end
end

return LordHeadDialog















