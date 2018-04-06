GMethod.loadScript("game.NewView")
DialogTemplates = {}

local closeButMore = 1.6
--小对话框优先级默认为5
function DialogTemplates.loadSmallTemplate(dialog)
    local bg,temp
	bg = ui.touchNode({866, 577}, 0, true)
    display.adapt(bg, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
    dialog.view=bg
    dialog.priority = 10
    temp = GameUI.createDialogShadow({887, 604})
    display.adapt(temp, 10, -27, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    --temp = ui.sprite("images/dialogBackSmall.png",{866,576},nil,false)
    temp = GameUI.createDialogBack("images/dialogBackSmall.png",{866,576})
    display.adapt(temp,0, 0, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.label("", General.font1, 55, {color={255,255,255}, fontW = 860, fontH = 80})
    display.adapt(temp, 433, 521, GConst.Anchor.Center)
    bg:addChild(temp)
    dialog.title = temp
    temp = ui.button({71*closeButMore,69*closeButMore},display.closeDialog, {cp1=dialog.priority})
    display.adapt(temp,798, 513, GConst.Anchor.Center)
    bg:addChild(temp)
    local back = ui.sprite("images/btnClose.png",{71,69})
    display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
    temp:getDrawNode():addChild(back)
    temp:setBackgroundSound("sounds/close.mp3")
    dialog.closeBut = temp
end

--普通对话框默认优先级为1
function DialogTemplates.loadDefaultTemplate(dialog, dtype, depth, size)
    local bg, temp
    if not depth then
        depth = 1
    end
    dialog.priority = depth
    if dtype==1 then
        if not size then
            size = {1380, 1021}
        end
        bg = ui.touchNode(size, 0, true)
        display.adapt(bg, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})

        temp = GameUI.createDialogShadow({size[1]+57, size[2]+73})
        display.adapt(temp,  -14, -53, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack1.png",size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBack1.png",size)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.sprite("images/dialogBackWhite2.png",{size[1]-66, (size[2]-109)/2},nil,false)
        display.adapt(temp, 33, 36, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        dialog.white = temp

        temp = ui.button({71*closeButMore, 69*closeButMore}, display.closeDialog, {cp1=0})
        display.adapt(temp, size[1]-63, size[2]-66, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{71,69})
        display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        dialog.closeBut = temp
        temp = ui.label("", General.font1, 60, {color={255,255,255}, fontW = 1200, fontH = 100})
        display.adapt(temp, size[1]/2, size[2]-59, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    elseif dtype==2 then
        if not size then
            size = {1534, 1021}
        end
        bg = ui.touchNode(size, 0, true)
        display.adapt(bg, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
        temp = GameUI.createDialogShadow({size[1]+49, size[2]+73},nil,false)
        display.adapt(temp, 1, -53, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack1.png",size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBack1.png",size)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        temp = ui.button({71*closeButMore, 69*closeButMore},display.closeDialog,{cp1=0})
        display.adapt(temp, size[1]-63, size[2]-66, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{71,69})
        display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        temp = ui.label("", General.font1, 66, {color={255,255,255}})
        display.adapt(temp, size[1]/2, size[2]-59, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    elseif dtype==3 then
        if not size then
            size = {1124, 1214}
        end
        bg = ui.touchNode(size, 0, true)
        display.adapt(bg, 0,0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})

        temp = GameUI.createDialogShadow({size[1]+39, size[2]+67})
        display.adapt(temp,  -8, -57, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack2.png",size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBack2.png",size)
        display.adapt(temp,0,0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        temp = ui.button({71*closeButMore, 69*closeButMore},display.closeDialog,{cp1=0})
        display.adapt(temp,  size[1]-63, size[2]-66, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{71,69})
        display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        temp = ui.label("", General.font1, 73, {color={255,255,255}, fontW = 1200, fontH = 100})
        display.adapt(temp, size[1]/2, size[2]-62, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    elseif dtype==4 then
        bg = ui.touchNode({2048, 1536}, 0, true)
        display.adapt(bg, 0,0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})

        temp = GameUI.createDialogShadow({2087, 1603})
        display.adapt(temp,  -8, -57, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack2.png",{2048, 1536},nil,false)
        temp = GameUI.createDialogBack("images/dialogBack2.png",{2048, 1536})
        display.adapt(temp,0,0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        temp = ui.button({95*closeButMore, 93*closeButMore},display.closeDialog,{cp1=0})
        display.adapt(temp, 1947, 1447, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{95,93})
        display.adapt(back,(95*closeButMore)/2,(93*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        temp = ui.button({77,100},nil,{image="images/btnBack.png"})
        display.adapt(temp, 90, 1453, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.backBut = temp
        dialog.backBut:setVisible(false)
        temp = ui.button({65,90},nil,{image="images/btnQuestion.png"})
        display.adapt(temp, 1809, 1450, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.questionBut = temp
        dialog.questionBut:setVisible(false)
        temp = ui.label("", General.font1, 80, {color={255,255,255}})
        display.adapt(temp, 1024, 1455, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    end
    dialog.view = bg
    if dialog.questionBut and dialog.onQuestion then
        dialog.questionBut:setScriptCallback(ButtonHandler(dialog.onQuestion, dialog))
        dialog.questionBut:setVisible(true)
    end
end

function DialogTemplates.loadViewTemplate(bg, sx, sy, config)
    if config[1]=="res" then
        return GameUI.addResourceIcon(bg, config[2], config[3] or 1, (config[4] or 0)+sx/2, (config[5] or 0)+sy/2)
    elseif config[1]=="astage" then
        return GameUI.addArenaStageIcon(bg, config[2], config[3] or 1, (config[4] or 0)+sx/2, (config[5] or 0)+sy/2)
    elseif config[1] == "feature" then
        local feature = GameUI.addHeroFeature(bg, config[2], config[3] or 1, sx/2, sy/2, 0, true, config[4])
        if config[5] and feature then
            feature:setFlippedX(true)
        end
    elseif config[1] == "equip" then
        local feature = GameUI.addEquipFeature(bg, config[2], config[3] or 1, sx/2, sy/2)
        if config[5] and feature then
            feature:setFlippedX(true)
        end
    elseif config[1] == "itemIcon" then
        return GameUI.addItemIcon(bg,config[2],config[3],config[4],0,0)
    elseif config[1] == "lanImg" then
        -- 根据语言适配的图片
        local img = ui.sprite(string.format(config[3], General.language))
        if not img then
            img = ui.sprite(string.format(config[3], "EN"))
        end
        if img then
            img:setScale(config[2])
            display.adapt(img, sx/2, sy/2, GConst.Anchor.Center)
            bg:addChild(img)
        end
        return img
    elseif config[1] == "dialogBack" then
        local node = GameUI.createRealDialogBack({sx, sy}, {config[2],config[3],config[4],config[5]})
        display.adapt(node, 0, 0)
        bg:addChild(node)
        return node
    end
end

function DialogTemplates.loadTemplate(dialog, dtype, config)
    if dialog == "image" then
        if dtype == "images/dialogBack0.png" or dtype == "images/dialogBack1.png" or dtype == "images/dialogBack2.png" or dtype == "images/dialogBackSmall.png" then
            return GameUI.createDialogBack(dtype, config)
        elseif dtype == "images/dialogBackShadow.png" then
            return GameUI.createDialogShadow(config)
        end
        return
    end
    local bg, temp
    local size = dialog.size
    local sx, sy = size[1], size[2]
    bg = dialog.view
    if dtype==0 then
        return DialogTemplates.loadViewTemplate(bg, sx, sy, config)
    elseif dtype==1 then
        temp=GameUI.createDialogShadow({sx+57, sy+73})
        display.adapt(temp, -14, -53, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack1.png",dialog.size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBack1.png",dialog.size)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.sprite("images/dialogBackWhite2.png",{sx-66, (sy-109)/2},nil,false)
        display.adapt(temp, 33, 36, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        dialog.white = temp
        temp:setVisible(false)

        temp = ui.button({71*closeButMore, 69*closeButMore}, display.closeDialog, {cp1=0})
        display.adapt(temp, sx-63, sy-66, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{71,69})
        display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        dialog.closeBut = temp
        temp = ui.label("", General.font1, 60, {color={255,255,255}})
        display.adapt(temp, sx/2, sy-59, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    elseif dtype==2 then
        temp = GameUI.createDialogShadow({sx+39, sy+67})
        display.adapt(temp,  -8, -57, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack2.png",size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBack2.png",size)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        temp = ui.button({71*closeButMore, 69*closeButMore},display.closeDialog,{cp1=0})
        display.adapt(temp,  sx-63, sy-66, GConst.Anchor.Center)
        bg:addChild(temp)
        local back = ui.sprite("images/btnClose.png",{71,69})
        display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        temp:setBackgroundSound("sounds/close.mp3")
        dialog.closeBut = temp
        temp = ui.label("", General.font1, 73, {color={255,255,255}})
        display.adapt(temp, sx/2, sy-62, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    elseif dtype==3 then
        temp = GameUI.createDialogShadow({sx+39, sy+67})
        display.adapt(temp,  -8, -57, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBack2.png",size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBack2.png",size)
        display.adapt(temp,0,0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        temp = ui.button({95*closeButMore, 93*closeButMore},display.closeDialog,{cp1=0})
        display.adapt(temp, sx-101, sy-86, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{95,93})
        display.adapt(back,(95*closeButMore)/2,(93*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        dialog.closeBut = temp
        temp = ui.button({77,100},nil,{image="images/btnBack.png"})
        display.adapt(temp, 90, sy-86, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.backBut = temp
        dialog.backBut:setVisible(false)
        temp = ui.button({65,90},nil,{image="images/btnQuestion.png"})
        display.adapt(temp, sx-239, sy-86, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.questionBut = temp
        dialog.questionBut:setVisible(false)
        temp = ui.label("", General.font1, 80, {color={255,255,255}})
        display.adapt(temp, sx/2, sy-82, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    elseif dtype==4 then
        temp = GameUI.createDialogShadow({sx+21, sy+27})
        display.adapt(temp, 10, -27, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        --temp = ui.sprite("images/dialogBackSmall.png", size,nil,false)
        temp = GameUI.createDialogBack("images/dialogBackSmall.png",size)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label("", General.font1, 55, {color={255,255,255}})
        display.adapt(temp, sx/2, sy-56, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
        temp = ui.button({71*closeButMore,69*closeButMore}, display.closeDialog, {cp1=0})
        display.adapt(temp, sx-68, sy-64, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{71,69})
        display.adapt(back,(71*closeButMore)/2,(69*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        dialog.closeBut = temp
    elseif dtype==5 then
        --新的英雄装备详情页面，重新做了一个自定义背景图片的模板
        temp = ui.sprite("images/dialogBackHero2.png",{sx+39, sy+67})
        display.adapt(temp,-8, -57, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        dialog.bgImage = temp

        temp = ui.button({95*closeButMore, 93*closeButMore},display.closeDialog,{cp1=0})
        display.adapt(temp, sx-101, sy-86, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/close.mp3")
        local back = ui.sprite("images/btnClose.png",{95,93})
        display.adapt(back,(95*closeButMore)/2,(93*closeButMore)/2,GConst.Anchor.Center)
        temp:getDrawNode():addChild(back)
        dialog.closeBut = temp
        temp = ui.button({77,100},nil,{image="images/btnBack.png"})
        display.adapt(temp, 90, sy-86, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.backBut = temp
        dialog.backBut:setVisible(false)
        temp = ui.button({65,90},nil,{image="images/btnQuestion.png"})
        display.adapt(temp, sx-239, sy-86, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.questionBut = temp
        dialog.questionBut:setVisible(false)
        temp = ui.label("", General.font1, 80, {color={255,255,255}})
        display.adapt(temp, sx/2, sy-82, GConst.Anchor.Center)
        bg:addChild(temp)
        dialog.title = temp
    -- 增加新类型模板
    elseif dtype >= 1011 then
        local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
        dialog:addLayout(_allTemplates["template" .. dtype])
        dialog:loadViewsTo()
        dialog.closeBut:setScriptCallback(ButtonHandler(display.closeDialog, dialog.priority))
    end
    if dialog.questionBut and dialog.onQuestion then
        dialog.questionBut:setScriptCallback(ButtonHandler(dialog.onQuestion, dialog))
        dialog.questionBut:setVisible(true)
    end
end

ViewUtil.setTemplateFunction(DialogTemplates.loadTemplate)

DialogTab = class()

function DialogTab:ctor(parent)
    self.parent = parent
end

function DialogTab:getDialog()
    local ret = self
    while not ret.context and ret.parent do
        ret = ret.parent
    end
    if not ret.context then
        ret = {deleted=true}
    end
    return ret
end

function DialogTab:getContext()
    return self:getDialog().context
end

function DialogTab:getParam()
    return self:getDialog().dialogParam
end

function DialogTab:create()
    local bg = ui.node(nil, true)
    self.view = bg
    return bg
end

function DialogTab:destroy()
    if self.view then
        self.view:removeFromParent(true)
        self.view = nil
    end
    for k, v in pairs(self) do
        self[k] = nil
    end
end

DialogTabLayout = class(ViewLayout)

function DialogTabLayout:ctor(parent)
    self.parent = parent
    self._setting = nil
end

function DialogTabLayout:getDialog()
    local ret = self
    while not ret.context and ret.parent do
        ret = ret.parent
    end
    if not ret.context then
        ret = {deleted=true}
    end
    return ret
end

function DialogTabLayout:getContext()
    return self:getDialog().context
end

function DialogTabLayout:getParam()
    return self:getDialog().dialogParam
end

function DialogTabLayout:create()
    local bg = ui.node(nil, true)
    self.view = bg
    return bg
end

function DialogTabLayout:destroy()
    if self.view then
        self.view:removeFromParent(true)
        self.view = nil
    end
    for k, v in pairs(self) do
        self[k] = nil
    end
end

local DTTabView = class()

function DTTabView:ctor(bg, tabTitles, tabs, tabSetting, otherSetting)
    local temp
    self.view = ui.node({0,0},true)
    bg:addChild(self.view)
    if tabs and type(tabs)=="table" then
        self.tabView = ui.createTabView({0,0})
        for i, tab in ipairs(tabs) do
            self.tabView:addTab(tab)
        end
    else
        self.tabCallback = tabs
    end
    self.curIndex = 0
    self.tabButs = {}
    self.tabLabels = {}
    self.tabBacks = {}
    self.tabs = tabs
    self.setting = tabSetting
    self.extend = otherSetting or {}
    for i, tab in ipairs(tabTitles) do
        temp = ui.button({tabSetting[1], tabSetting[2]}, self.changeTab, {cp1=self, cp2=i, anchor=GConst.Anchor.Bottom, actionType=self.extend.actionType})
        display.adapt(temp, tabSetting[3]*i-tabSetting[5], tabSetting[4], GConst.Anchor.Bottom)
        self.view:addChild(temp, i)
        temp:setBackgroundSound("sounds/switch.mp3")
        self.tabButs[i] = temp
        temp = ui.label(StringManager.getString(tab), General.font1, tabSetting[7],{width = tabSetting[1]-150, align=GConst.Align.Center,fontW=tabSetting[1]-150,fontH=tabSetting[2]-20})
        display.adapt(temp, tabSetting[8], tabSetting[9], GConst.Anchor.Center)
        self.tabButs[i]:getDrawNode():addChild(temp,2)
        self.tabLabels[i] = temp

        local image = tabSetting[6]
        if self.extend.tabType~=2 then
            image = image .. "2.png"
        end
        temp = ui.sprite(image, {tabSetting[1], tabSetting[2]})
        if self.extend.tabType==2 then
            temp:setSValue(-100)
        end
        display.adapt(temp, 0, 0)
        self.tabButs[i]:getDrawNode():addChild(temp, -1)
        self.tabBacks[i] = temp
    end

    temp = ui.colorNode({tabSetting[10], tabSetting[11]},{237,218,183})
    display.adapt(temp, tabSetting[12], tabSetting[13]-5)
    self.view:addChild(temp,#tabTitles+2)
    if self.extend.viewBg then
        bg = self.extend.viewBg
    end
    if self.tabView then
        bg:addChild(self.tabView.view)
    end
end

function DTTabView:changeTab(idx)
    local tabNode = self.view
    local buts = self.tabButs
    local backs = self.tabBacks
    local tabSetting = self.setting
    local curTab = self.curIndex
    if curTab~=idx then
        if buts[curTab] then
            if self.extend.tabType==2 then
                backs[curTab]:setSValue(-100)
            else
                backs[curTab]:removeFromParent(true)
                backs[curTab] = ui.sprite(tabSetting[6] .. "2.png", {tabSetting[1], tabSetting[2]})
                display.adapt(backs[curTab], 0, 0)
                buts[curTab]:getDrawNode():addChild(backs[curTab], -1)
            end
            buts[curTab]:setEnable(true)
            tabNode:reorderChild(buts[curTab],curTab)
        end
        self.curIndex = idx
        if buts[idx] then
            if self.extend.tabType==2 then
                backs[idx]:setSValue(0)
            else
                backs[idx]:removeFromParent(true)
                backs[idx] = ui.sprite(tabSetting[6] .. "1.png", {tabSetting[1], tabSetting[2]})
                display.adapt(backs[idx], 0, 0)
                buts[idx]:getDrawNode():addChild(backs[idx], -1)
            end
            buts[idx]:setEnable(false)
            tabNode:reorderChild(buts[idx],#buts+1)
            if curTab>0 then
                local image = tabSetting[6]
                if self.extend.tabType~=2 then
                    image = image .. "1.png"
                end
                local node=ui.sprite(image,{tabSetting[1],tabSetting[2]})
                display.adapt(node, 0, 0)
                buts[idx]:getDrawNode():addChild(node, -1)
                node:setLValue(20)
                node:setOpacity(0.6*255)
                node:runAction(ui.action.fadeTo(0.4,0))
                node:runAction(ui.action.sequence({{"delay",0.4},"remove"}))
            end
        end
        if self.tabView then
            self.tabView:changeTab(idx)
        elseif self.tabCallback then
            self.tabCallback(idx)
        end
    end
end

function DialogTemplates.createTabView(bg, tabTitles, tabs, tabSetting, otherSetting)
    return DTTabView.new(bg, tabTitles, tabs, tabSetting, otherSetting)
end

--这个用于实现标准对话框的常规逻辑
DialogViewLayout = class(ViewLayout)

function DialogViewLayout:onCreate()
    local setting = self._setting
    if setting then
        for k, v in pairs(setting) do
            if not self[k] then
                self[k] = v
            end
        end
    end
    if not self.context then
        self.context = GameLogic.getUserContext()
    end
    if self.parent then
        if self.parent.priority then
            self.priority = self.parent.priority+1
        else
            self.priority = (self.parent.getDialog and self.parent:getDialog().priority or display.getDialogPri())+1
        end
    else
        self.priority=display.getDialogPri()+1
    end
    self:onInitDialog()
end

function DialogViewLayout:onQuestion()
    if self.questionTag then
        HelpDialog.new(self.questionTag)
        return
    end
    display.pushNotice(Localize("noticeNotSupport"))
end

DialogViewLayout2 = class(DialogViewLayout)

function DialogViewLayout2:setLayout(config)
    local rawView
    if config then
        local size = {config.sx or 0, config.sy or 0}
        if config.type=="dialog" then
            local isFullScreen = false
            if size[1]==0 or size[2]==0 then
                size[1], size[2] = display.winSize[1], display.winSize[2]
                isFullScreen = true
            end
            rawView = ui.touchNode(size, 0, true)
            if not isFullScreen then
                display.adapt(rawView, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
            else
                display.adapt(rawView, 0, 0, GConst.Anchor.LeftBottom)
            end
        elseif config.type=="menu" then
            size[1], size[2] = display.winSize[1], display.winSize[2]
            rawView = ui.touchNode(size, 0, false)
            display.adapt(rawView, 0, 0, GConst.Anchor.LeftBottom)
        else
            rawView = ui.node(size,true)
            if config.type=="cell" then
                self._inScroll = true
            end
        end
        self.size = size
        self.view = rawView
        self._config = config
        self._layouts = {}
        RegLife(self.view, Handler(self.onLifeCycle, self))
        if config.template then
            DialogTemplates.loadTemplate(self, config.template, config)
        end
        if config.views then
            self:_addViews(config.views)
        end
    end
end

function DialogViewLayout2:addLayout(configName, toView)
    local config = nil
    if type(configName) == "table" then
        config = configName
    else
        if self._config then
            config = self._config[configName]
        end
    end
    if config then
        local views = config.views or config
        if toView then
            local newLayout = ViewLayout.new()
            if views and views[1] and views[1].createrConfig then
                newLayout._createrConfig = true
            end
            if config.isCell then
                newLayout:setInScroll(true)
            end
            local rawSize = toView:getContentSize()
            local size = {rawSize.width, rawSize.height}
            newLayout:setView(toView, size, true)
            newLayout:_addViews(views)
            return newLayout
        else
            self:_addViews(views)
        end
    else
        log.e("Couldn't find config:%s", configName)
    end
end

--进一步实现对话框的tab化，帮助一个对话框在不同层级间切换
DialogTabViewLayout = class(DialogViewLayout)

function DialogTabViewLayout:onInitDialog()
    self:setLayout("DefaultTabDialog.json")
    self:loadViewsTo()
end

function DialogTabViewLayout:onEnter()
    self.context.curDialog = self
    self.backBut:setScriptCallback(ButtonHandler(self.popTab, self))
    if not self.stackTab then
        self:pushTab(self.initTag or "main")
    end
end

function DialogTabViewLayout:onExit()
    self.context.curDialog = nil
    if self.reuseTabs then
        for k, tab in pairs(self.reuseTabs) do
            tab.view:release()
        end
        self.reuseTabs = nil
    end
end

--内部重用；关闭后则一起销毁
function DialogTabViewLayout:addReuseTab(tag, tab)
    if not self.reuseTabs then
        self.reuseTabs = {}
    end
    self.reuseTabs[tag] = tab
    tab.reuse = true
    tab.view:retain()
end

function DialogTabViewLayout:getReuseTab(tag)
    return self.reuseTabs and self.reuseTabs[tag]
end

function DialogTabViewLayout:onDestroy()
    self:cleanTab()
    self.stacks = nil
end

function DialogTabViewLayout:cleanTab()
    if self.stackTab then
        if self.stackTab.reuse then
            self.stackTab.view:removeFromParent(false)
        else
            self.stackTab.deleted = true
            self.stackTab:destroy()
        end
        self.stackTab = nil
    end
end

function DialogTabViewLayout:reloadTab(tag)
    self:cleanTab()
    local context = self.context
    local newTab = self:getReuseTab(tag)
    if newTab then
        newTab.parent = self
        if newTab.reloadTab then
            newTab:reloadTab(tag)
        end
    else
        --具体的tab由对话框自己实现
        newTab = self:getTab(tag)
    end
    self.view:addChild(newTab.view)
    self.stackTab = newTab
end

function DialogTabViewLayout:pushTab(tag, param)
    if self.deleted then
        return
    end
    if param then
        self.dialogParam = param
    end
    if not self.stacks then
        self.stacks = {}
    end
    local depth = #(self.stacks)
    if depth>=1 then
        self.backBut:setVisible(true)
    end
    self.stacks[depth+1] = tag
    self:reloadTab(tag)
end

function DialogTabViewLayout:changeTabTag(tag)
    local depth = #(self.stacks)
    self.stacks[depth] = tag
end

function DialogTabViewLayout:popTab(param)
    if self.deleted then
        return
    end
    if param then
        self.dialogParam = param
    end
    table.remove(self.stacks)
    local depth = #(self.stacks)
    if depth == 0 then
        display.closeDialog(self.priority)
        return
    end
    local tag = self.stacks[depth]
    if depth==1 then
        self.backBut:setVisible(false)
    end
    self:reloadTab(tag)
end

GMethod.loadScript("game.Dialog.RewardDialog")
GMethod.loadScript("game.Dialog.RewardListDialog")
GMethod.loadScript("game.Dialog.AlertDialog")
GMethod.loadScript("game.Dialog.ItemUseDialog")
GMethod.loadScript("game.Dialog.StoreDialog")
GMethod.loadScript("game.Dialog.InfoDialog")
GMethod.loadScript("game.Dialog.RenameDialog")
GMethod.loadScript("game.Dialog.PlanDialog")
GMethod.loadScript("game.Dialog.AccDialog")
GMethod.loadScript("game.Dialog.SkillUpgradeDialog")
GMethod.loadScript("game.Dialog.HeroMicDetailsDialog")
GMethod.loadScript("game.Dialog.HeroAwakeDialog")
GMethod.loadScript("game.Dialog.HeroSoldierDialog")
GMethod.loadScript("game.Dialog.HeroMainSkillDialog")
GMethod.loadScript("game.Dialog.HeroBSkillDialog")
GMethod.loadScript("game.Dialog.HeroMainDialog")
GMethod.loadScript("game.Dialog.EquipDialog")
GMethod.loadScript("game.Dialog.LuckyLotteryDialog")
GMethod.loadScript("game.Dialog.BeercupDialog")
GMethod.loadScript("game.Dialog.WeaponProduceDialog")
GMethod.loadScript("game.Dialog.WeaponUpgradeDialog")
GMethod.loadScript("game.Dialog.ArenaDialog")
GMethod.loadScript("game.Dialog.ArenaRewardDialog")
GMethod.loadScript("game.Dialog.PvhRewardDialog")
GMethod.loadScript("game.Dialog.PvhStoreDialog")
GMethod.loadScript("game.Dialog.PvhDialog")
GMethod.loadScript("game.Dialog.PvhMapDialog")
GMethod.loadScript("game.Dialog.PvhSettlementDialog")
GMethod.loadScript("game.Dialog.PlayInterfaceDialog")
GMethod.loadScript("game.Dialog.BattleResultDialog")
GMethod.loadScript("game.Dialog.StoryDialog")
GMethod.loadScript("game.Dialog.UnionPetsDialog")

GMethod.loadScript("game.Dialog.ActivityListDialog")

GMethod.loadScript("game.Dialog.EvaluateDialog")
GMethod.loadScript("game.Dialog.NewShowHeroDialog")
GMethod.loadScript("game.Dialog.EveryDayWelfareDialog")
GMethod.loadScript("game.Dialog.ShowHeroDialog")
GMethod.loadScript("game.Dialog.HeroLibraryInfo")

GMethod.loadScript("game.Dialog.PveInfoDialog")
GMethod.loadScript("game.Dialog.PrestigeDialog")
GMethod.loadScript("game.Dialog.StrongerDialog")

GMethod.loadScript("game.Dialog.ArenaHonorExcDialog")
GMethod.loadScript("game.Dialog.UnionApplyLogDialog")
GMethod.loadScript("game.Dialog.UnionWelfareLogDialog")
GMethod.loadScript("game.Dialog.UnionDonationLogDialog")
GMethod.loadScript("game.Dialog.MyWorshipDialog")
GMethod.loadScript("game.Dialog.WorshipToViewRewardDialog")
GMethod.loadScript("game.Dialog.HeroInfoNewDialog")
GMethod.loadScript("game.Dialog.EquipInfoNewDialog")
GMethod.loadScript("game.Dialog.TrigglesBagDialog")
GMethod.loadScript("game.Dialog.GemPoolDialog")
GMethod.loadScript("game.Dialog.HeroSpecialWash")
GMethod.loadScript("game.Dialog.VIPDialog")
GMethod.loadScript("game.Dialog.BeastInfoNewDialog")

