--服务器对话框
local ServerDialog = class2("ServerDialog",function()
    return BaseView.new("ServerDialog.json",true)
end)

function ServerDialog:ctor(loginData,callback)
    self.callback = callback
    self.loginData = loginData
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initBack()
    self:serverlist()
    display.showDialog(self)
end
function ServerDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    self:loadView("leftViews")
end

function ServerDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    self:loadView("leftCellViews",bg)
    local viewTab = self:getViewTab()
    self:insertViewTo()
    local text
    if info.uinfos then
        text = Localize("labelRecommend")
    else
        if info.sv.name then
            text = Localize("labelServer" .. info.sv.name)
        else
            local k = tonumber(info.key)
            local s = (k-1)*10+1
            text = s .. "-" .. s+9
            text = Localize("labelServer") .. text
        end
    end
    self.serverNameValue:setString(text)
    local function chose( ... )
        if self.leftChosed then
            self.leftChosed:removeFromParent(true)
            self.leftChosedLine:removeFromParent(true)
            self.leftLine:setVisible(true)
            self.chosedCell:setEnable(true)
        end
        local temp= ui.sprite("images/recommendedBack.png",{447, 100})
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        cell:getDrawNode():addChild(temp)
        self.leftChosed=temp

        temp= ui.sprite("images/serverChose1.png",{429, 57})
        display.adapt(temp, 223, -50, GConst.Anchor.Bottom)
        cell:getDrawNode():addChild(temp)
        self.leftChosedLine=temp

        self.leftLine=viewTab.cellBack
        self.leftLine:setVisible(false)
        self.chosedCell=cell
        self.chosedCell:setEnable(false)
    end
    if info.id==1 then
        chose()
        self:reloadRight(info)
    end
    ui.setListener(cell,function()
        chose()
        self:reloadRight(info)
    end)
end

function ServerDialog:initUI()
    local servers = self.params.servers
    local uinfos = self.params.uinfos
    local keyArr = {}
    local snum = 0
    for k,v in pairs(servers) do
        snum = snum+1
        table.insert(keyArr,tonumber(k))
    end
    keyArr = GameLogic.mySort(keyArr,nil,true)
    local cnum = snum
    local infos={}
    if uinfos and #uinfos>0 then
        cnum = cnum+1
        table.insert(infos,{id = 1, uinfos = uinfos})
    end
    for i=1,snum do
        table.insert(infos,{id = #infos+1, key = keyArr[i], sv = servers[tostring(keyArr[i])]})
    end
    self:loadView("rightBackViews")
    self:insertViewTo()
    self:addTableViewProperty("leftTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("leftTableView")
    if cnum>snum then
        self:loadView("rightUpViews")
        self:insertViewTo()
        self.labelLastLoginServer:setVisible(true)
        self.butLastLogin:setListener(function()
            self.callback(self.loginData.sver)
            display.closeDialog(0)
        end)
        local sver = self.loginData.sver
        self.serverName:setString(Localize("dataServerName" .. sver[1]))

        self.serverState:setString(Localize("labelServerState" .. sver[5]))
        GameLogic.setServerColor(self.serverName,sver[5])
        GameLogic.setServerColor(self.serverState,sver[5])
    else
        self:insertViewTo()
        self.labelLastLoginServer:setVisible(false)
    end
end

function ServerDialog:reloadRight(info)
    if self.rightNode then
        self.rightNode:removeFromParent(true)
        self.rightNode = nil
        self.rightChosed = nil
    end
    self.rightNode = ui.node()
    self:addChild(self.rightNode)
    local infos = {}
    if info.uinfos then
        self.rightTopTitle:setString(Localize("labelAllAccountInserver"))
        infos = info.uinfos
        self:addTableViewProperty("userTableViews",infos,Script.createBasicHandler(self.callCellUser,self))
        self:loadView("userTableViews",self.rightNode)
    else
        local k = tonumber(info.key)
        if info.sv.name then
            self.rightTopTitle:setString(Localize("labelServer" .. info.sv.name))
        else
            local s = (k-1)*10+1
            local text = s .. "-" .. s+9
            self.rightTopTitle:setString(Localize("labelServer") .. text)
        end
        local server = info.sv
        local keyArr = {}
        for k,v in pairs(server) do
            --服务器开启
            if k~="name" and GameLogic.compareTime(self.params.nowtime,v[5])>=0 then
                table.insert(keyArr,tonumber(k))
                v[10] = tonumber(k)
            end
        end
        keyArr = GameLogic.mySort(keyArr,nil)
        for i=1,#keyArr do
            table.insert(infos,{id = i, sv = server[tostring(keyArr[i])]})
        end
        self:addTableViewProperty("svTableViews",infos,Script.createBasicHandler(self.callCellSv,self))
        self:loadView("svTableViews",self.rightNode)
    end
end

function ServerDialog:callCellUser(cell, tableView, info)
    local bg = cell:getDrawNode()
    self:loadView("idNodeViews",bg)

    local headNode = ui.node()
    bg:addChild(headNode)
    headNode:setPosition(88,70)
    local info2 = {iconType=info[3], level=info[1], noBut=true}
    GameUI.updateUserHeadTemplate(headNode, info2)

    --local params = {id = info[3], x = 88, y = 70, scale = 1.1, blackBack = true, noBut = true}
    --GameUI.addPlayHead(bg,params)
    GameUI.addVip(bg,info[2],234,267-280,0,{scale=0.896})
    self:insertViewTo()
    self.serverNameEv:setString(Localize("dataServerName" .. info[5]))
    self.userNameEv:setString(info[4])
    local nsize = self.userNameEv:getContentSize()
    self.nBack:setContentSize(cc.size(nsize.width+14,52))
    local svcb
    for k,v in pairs(self.params.servers) do
        for id,sv in pairs(v) do
            if tonumber(id) == info[5] then
                svcb = sv
            end
        end
    end
    svcb = {info[5],svcb[1],svcb[2],svcb[3],svcb[4]}
    GameLogic.setServerColor(self.serverNameEv,svcb[5])
    ui.setListener(cell,function()
        self.callback(svcb)
        display.closeDialog(0)
    end)
end

function ServerDialog:callCellSv(cell, tableView, info)
    local bg = cell:getDrawNode()
    local sv = info.sv
    local line = ui.sprite("images/serverChose2.png",{670, 10})
    display.adapt(line, 336, -20, GConst.Anchor.Bottom)
    bg:addChild(line)

    local serverName = ui.label(Localize("dataServerName" .. sv[10]), General.font1, 45, {color={59,255,44}})
    display.adapt(serverName, 78, 50, GConst.Anchor.Left)

    bg:addChild(serverName,2)

    -- local serverState = ui.label(Localize("labelServerState" .. sv[4]), General.font1, 45, {color={59,255,44},fontW=200,fontH=100})
    -- display.adapt(serverState, 600, 50, GConst.Anchor.Right)
    --bg:addChild(serverState,2)

    GameLogic.setServerColor(serverName,sv[4])
    -- GameLogic.setServerColor(serverState,sv[4])

    local function chose( ... )
        if self.rightChosed then
            self.rightChosed:removeFromParent(true)
            self.rightChosedLine:removeFromParent(true)
            self.rightLine:setVisible(true)
            --self.chosedServerBut:setEnable(true)
        end
        local temp= ui.sprite("images/recommendedBack.png",{673, 100})
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        self.rightChosed=temp

        temp= ui.sprite("images/serverChose1.png",{670, 57})
        display.adapt(temp, 336, -50, GConst.Anchor.Bottom)
        bg:addChild(temp)
        self.rightChosedLine=temp

        self.rightLine=line
        self.rightLine:setVisible(false)
        -- self.chosedServerBut=cell
        -- self.chosedServerBut:setEnable(false)
    end
    if info.id == 1 then
        chose()
    end
    ui.setListener(cell,function()
        chose()
        local svcb = {sv[10],sv[1],sv[2],sv[3],sv[4]}
        self.callback(svcb)
        display.closeDialog(0)
    end)
end
-----------------------------------------------------------------
function ServerDialog:serverlist()
    if not GameNetwork.lockRequest() then
        return
    end
    local lgmsg = GEngine.getConfig("lastLoginMsg")
    lgmsg = json.decode(lgmsg)

    local deviceInfo = json.decode(Native:getDeviceInfo())
    local params = {account=lgmsg[1], mode=lgmsg[2], cv=GEngine.rawConfig.version, cc=GEngine.rawConfig.versionCode, channel=GEngine.rawConfig.channel, platform=deviceInfo.platform, device=deviceInfo.deviceId, language=General.language}

    GameNetwork.request("serverlist", params, function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            print_r(data)
            self.params = data
            if self.initUI then
                self:initUI()
            end
        end
    end)
end

return ServerDialog
