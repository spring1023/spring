
local configDir = "configs/ui/dialogViewsConfig/"

local BaseView = class2("BaseView",function(configName,remain,sgType)
    if not string.find(configName,".json") then
        configName = configName..".json"
    end
    local config = GMethod.loadConfig(configDir .. configName)
    local instance
    if config then
        config.Type = sgType or config.type or config.Type
        if config.Type=="Dialog" then
            instance = ui.touchNode({config.sx,config.sy}, 0, true)
            display.adapt(instance, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
            instance.dialogSize={config.sx,config.sy}
        elseif config.Type=="FullDialog" then
            instance = ui.touchNode({display.winSize[1],display.winSize[2]}, 0, true)
            display.adapt(instance, display.winSize[1]/2, display.winSize[2]/2, GConst.Anchor.Center)
        elseif config.Type=="Menu" then
            instance = ui.touchNode({config.sx,config.sy}, 0, false)
            instance:setContentSize(cc.size(display.winSize[1], display.winSize[2]))
        elseif config.Type == "tab" then
            instance = ui.node({config.sx,config.sy},true)
        elseif config.Type == "interface" then
            instance = ui.touchNode({config.sx,config.sy}, -1, true)
            instance:setContentSize(cc.size(display.winSize[1], display.winSize[2]))
        elseif config.Type == "prefab" then
            instance = ui.shlNode({config.sx,config.sy})
        else
            print("this type need define")
            return
        end
    else

        print("not config")
    end
    instance._config = config
    return instance
end)

GEngine.export("BaseView", BaseView)

function BaseView:ctor(configName,remain)
    self._layoutViewTab = {config = {},view = {}}
    self._tableView={}
    self._relativeViewTab = {}
    if remain then
        local dialogDepth=display.getDialogPri()+1
        self.priority=dialogDepth
    end
end

function BaseView:loadView(viewsName,addtoNode)
    local config = self._config
    local layoutViewTab = self._layoutViewTab
    if config[viewsName] then
        for _,layout in ipairs (config[viewsName]) do
            if layout then
                local view=self:_addview(layout,viewsName)

                if layout.parentid then
                    if layoutViewTab.config[layout.parentid].type=="node" then
                        layoutViewTab.view[layout.parentid]:addChild(view)
                    elseif layoutViewTab.config[layout.parentid].type=="button" then
                        layoutViewTab.view[layout.parentid]:getDrawNode():addChild(view)
                    end
                elseif  addtoNode then
                    addtoNode:addChild(view)
                else
                    self:addChild(view)
                end
                if layout.id then
                    layoutViewTab.config[layout.id] = layout
                    layoutViewTab.view[layout.id] = view
                end
                if layout.gz then
                    view:setGlobalZOrder(layout.gz)
                end
            else
                print("not layou")
            end
        end
    else
        print("not this viewsName")
    end
end

function BaseView:addTableViewProperty(tableviewName,infos,updateCell)
    local config=self._config
    if config[tableviewName] then
        local layout=config[tableviewName][1]
        layout.celltab.infos=infos
        layout.celltab.updateCell=updateCell
    end
end
--添加回调函数
function BaseView:addTableViewCall(tableviewName,fName,func)
    local config=self._config
    if config[tableviewName] then
        local layout=config[tableviewName][1]
        layout.celltab[fName]=func
    end
end
function BaseView:addTableViewProperty2(tableviewName,infos,scrollToCall)
    local config=self._config
    if config[tableviewName] then
        local layout=config[tableviewName][1]
        layout.celltab.infos=infos
        layout.celltab.scrollToCall=scrollToCall
    end

end
function BaseView:getTableView(name)
    return self._tableView[name]
end
function BaseView:readConfig(cName)
    return self._config[cName]
end
function BaseView:findView(id)
    return self._layoutViewTab.view[id]
end

function BaseView:findConfig(id)
    return self._layoutViewTab.config[id]
end

function BaseView:getViewTab()
    return self._layoutViewTab.view
end

function BaseView:getConfigTab()
    return self._layoutViewTab.config
end

function BaseView:insertViewTo(tab)
    if not tab then
        tab = self
    end
    for k,v in pairs(self._layoutViewTab.view) do
        if not tab[k] then
            tab[k] = v
        elseif tab[k] and tab[k]~=v then
            tab[k] = v
            --print("warn the key:",k)
        end
    end
end

function BaseView:addTabView(tabTitles, tabSetting,tabID,bg)
    if not bg then
        bg=self
    end
    local temp
    local tabNode = ui.node({0,0},true)
    bg:addChild(tabNode)
    local tabView = ui.createTabView({0,0})
    bg:addChild(tabView.view)
    local tabButs = {}
    for i, tab in ipairs(tabTitles) do
        local function callBut()
            if self.canChangeTab then
                self:canChangeTab(function()
                    self:changeTabIdx(i,tabID)
                    return i
                end,i)
            else
                self:changeTabIdx(i,tabID)
            end
        end
        temp = ui.button({tabSetting[1], tabSetting[2]}, callBut, {anchor=GConst.Anchor.Bottom, image=tabSetting[6] .. "2.png"})
        display.adapt(temp, tabSetting[3]*i-tabSetting[5], tabSetting[4], GConst.Anchor.Bottom)
        tabNode:addChild(temp, i)
        tabButs[i] = temp
        temp:setBackgroundSound("sounds/switch.mp3")
        temp = ui.label(StringManager.getString(tab), General.font1, tabSetting[7], {width = tabSetting[1]-170, align=GConst.Align.Center,fontW=tabSetting[1]-170,fontH=tabSetting[2]-20})
        display.adapt(temp, tabSetting[8], tabSetting[9], GConst.Anchor.Center)
        tabButs[i]:getDrawNode():addChild(temp,2)
    end
    if not tabID then
        self.tab = {tabNode, tabButs, tabView, tabSetting, 0}
    else
        self.moreTab=self.moreTab or {}
        self.moreTab[tabID]={tabNode, tabButs, tabView, tabSetting, 0, tabID}
    end
    temp = ui.colorNode({tabSetting[10], tabSetting[11]},{237,218,183})
    display.adapt(temp, tabSetting[12], tabSetting[13]-5)
    tabNode:addChild(temp,#tabButs+2)
end

function BaseView:changeTabIdx(idx,tabID)
    local tab = self.tab or self.moreTab[tabID]
    local tabNode = tab[1]
    local buts = tab[2]
    local tabView = tab[3]
    local tabSetting = tab[4]
    local curTab = tab[5]
    if curTab~=idx then
            if buts[curTab] then
                buts[curTab]:setBackgroundImage(tabSetting[6] .. "2.png", 0)
                buts[curTab]:setEnable(true)
                tabNode:reorderChild(buts[curTab],curTab)
            end
            tab[5] = idx
            if buts[idx] then
                buts[idx]:setBackgroundImage(tabSetting[6] .. "1.png", 0)
                buts[idx]:setEnable(false)
                tabNode:reorderChild(buts[idx],#buts+1)
                local node=ui.sprite(tabSetting[6] .. "1.png",{tabSetting[1],tabSetting[2]})
                node:setPosition(tabSetting[1]/2,tabSetting[2]/2)
                node:setAnchorPoint(0.5,0.5)
                buts[idx]:getDrawNode():addChild(node)
                node:setLValue(20)
                node:setOpacity(0.6*255)
                node:runAction(ui.action.fadeTo(0.4,0))
                node:runAction(ui.action.sequence({{"delay",0.4},"remove"}))
            end
        if self.node then
            self.node:removeAllChildren(true) --移除按钮切换节点
        end
        tabView:changeTab(idx)
    end
end

function BaseView:_addview(layout,viewsName)
    if layout.type=="image" then
        return self:_addImage(layout)
    elseif layout.type=="colorNode" then
        return self:_addColorNode(layout)
    elseif layout.type=="label" then
        return self:_addLabel(layout)
    elseif layout.type=="scrollLabel" then
        return self:_addScrollLabel(layout)
    elseif layout.type=="button" then
        return self:_addButton(layout)
    elseif layout.type=="node" then
        return self:_addNode(layout)
    elseif layout.type=="tableview" then
        return self:_addTableView(layout,viewsName)
    end
end
function BaseView:_addImage(layout)
    local temp
    if layout.image=="images/dialogBack1.png" or layout.image=="images/dialogBack2.png" or layout.image=="images/dialogBackSmall.png" then
        temp = GameUI.createDialogBack(layout.image, {layout.sx,layout.sy})
    elseif layout.image == "images/dialogBackShadow.png" then
        temp = GameUI.createDialogShadow({layout.sx, layout.sy})
    else
        if layout.scale9 then
            temp = ui.scale9(layout.image, layout.scale9, {layout.sx,layout.sy})
        else
            if layout.sx and layout.sy then
                temp=ui.sprite(layout.image,{layout.sx,layout.sy},false,layout.async)
            else
                temp=ui.sprite(layout.image,nil,false,layout.async)
            end
        end
        if layout.custom then
            for _, custom in ipairs(layout.custom) do
                temp:setCustomPoint(custom[1], custom[2], custom[3], custom[4], custom[5])
            end
        end
    end
    if layout.relative then
        self:_relativeCompute(temp, layout)
    else
        if not temp then
            print("temp1!", layout.image)
        end
        display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
        self:_adaptDatum(temp,layout)
    end
    if layout.flip then
        if layout.flip=="X" then
            temp:setFlippedX(true)
        elseif layout.flip=="Y" then
            temp:setFlippedY(true)
        elseif layout.flip=="XY" then
            temp:setFlippedX(true)
            temp:setFlippedY(true)
        end

    end

    if layout.r then
        temp:setRotation(layout.r)
    end
    if layout.opacity then
        temp:setOpacity(layout.opacity)
    end
    if layout.color then
        ui.setColor(temp, layout.color)
    end
    if layout.hvalue then
        temp:setHValue(layout.hvalue)
    end
    if layout.svalue then
        temp:setSValue(layout.svalue)
    end
    if layout.lvalue then
        temp:setLValue(layout.lvalue)
    end
    if layout.visible and layout.visible=="false" then
        temp:setVisible(false)
    else
        temp:setVisible(true)
    end
    temp:setLocalZOrder(layout.z or 0)
    return temp
end
function BaseView:_addColorNode(layout)
    local temp
        temp=ui.colorNode({layout.sx,layout.sy},layout.color)
        if layout.relative then
           self:_relativeCompute(temp,layout)
        else
            display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
            self:_adaptDatum(temp,layout)
        end
        if layout.opacity then
            temp:setOpacity(layout.opacity)
        end
        if layout.visible and layout.visible=="false" then
            temp:setVisible(false)
        else
            temp:setVisible(true)
        end
        temp:setLocalZOrder(layout.z or 0)
    return temp
end
function BaseView:_addLabel(layout)
    local temp
        if layout.point then
            print_r(layout)
        end
        local setting={color=layout.color,width=layout.width,align=GConst.Align[layout.align or "Center"]}
        if layout.fontW and layout.fontH then
            setting.fontW=layout.fontW
            setting.fontH=layout.fontH
        end
        if layout.lh then
            setting.lh = layout.lh
        end
        temp= ui.label("", General[layout.font],layout.size, setting)
        if layout.relative then
            self:_relativeCompute(temp,layout)
        else
            display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
            self:_adaptDatum(temp,layout)
        end
        if layout.opacity then
            temp:setOpacity(layout.opacity)
        end
        if layout.r then
            temp:setRotation(layout.r)
        end
        if layout.visible and layout.visible=="false" then
            temp:setVisible(false)
        else
            temp:setVisible(true)
        end
        temp:setLocalZOrder(layout.z or 0)
        temp:setString(StringManager.getString(layout.text or layout.id))
    return temp
end
function BaseView:_addScrollLabel(layout)
    local temp
        temp= ui.scrollLabel(StringManager.getString(layout.id), General[layout.font],layout.size, {lh=layout.lh,color=layout.color,width=layout.width,height=layout.height,align=GConst.Align[layout.align or "Center"],offx=layout.offx or 0,offy=layout.offy or 0})

       if layout.relative then
            self:_relativeCompute(temp,layout)
        else
            display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
            temp:setAnchorPoint2(layout.anchorX,layout.anchorY)
            self:_adaptDatum(temp,layout)
        end
        if layout.opacity then
            temp:setOpacity(layout.opacity)
        end
        if layout.r then
            temp:setRotation(layout.r)
        end
        if layout.visible and layout.visible=="false" then
            temp:setVisible(false)
        else
            temp:setVisible(true)
        end
        temp:setLocalZOrder(layout.z or 0)
    return temp
end
function BaseView:_addButton(layout)
    local temp
        if layout.back and (layout.back == "images/btnClose.png" or layout.back == "images/btnClose5.png") then
            local ms = 1.6
            temp = ui.button({layout.sx*ms,layout.sy*ms},nil,{image=nil,actionType = layout.actionType or nil})
            local back = ui.sprite(layout.back,{layout.sx,layout.sy})
            display.adapt(back,(layout.sx*ms)/2,(layout.sy*ms)/2,GConst.Anchor.Center)
            temp:getDrawNode():addChild(back)
        else
            temp = ui.button({layout.sx,layout.sy},nil,{image=layout.back or nil,actionType = layout.actionType or nil})
        end
        if layout.back and (layout.back == "images/btnClose.png" or layout.back == "images/btnClose2.png" or layout.back == "images/btnClose3.png" or layout.back == "images/btnClose4.png" or layout.back == "images/btnClose.png") then
            temp:setBackgroundSound("sounds/close.mp3")
        end
        if layout.relative then
            self:_relativeCompute(temp,layout)
        else
            display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
            self:_adaptDatum(temp,layout)
        end
        if layout.flip then
            if layout.flip=="X" then
                temp:setFlippedX(true)
            elseif layout.flip=="Y" then
                temp:setFlippedY(true)
            end
        end
        if layout.opacity then
            temp:setOpacity(layout.opacity)
        end
        if layout.hvalue then
            temp:setHValue(layout.hvalue)
        end
        if layout.svalue then
            temp:setSValue(layout.svalue)
        end
        if layout.lvalue then
            temp:setLValue(layout.lvalue)
        end

        if layout.visible and layout.visible=="false" then
            temp:setVisible(false)
        else
            temp:setVisible(true)
        end
        if layout.sound then
            temp:setBackgroundSound(layout.sound)
        end
        temp:setLocalZOrder(layout.z or 0)
        if layout.back == "images/btnQuestion.png" then
            temp:setListener(function()
                temp:getParent():onQuestion()
            end)
        end
    return temp
end
function BaseView:_addNode(layout)
    local temp
        temp=ui.node({layout.sx or 0,layout.sy or 0})
        if layout.relative then
           self:_relativeCompute(temp,layout)
        else
            display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
            self:_adaptDatum(temp,layout)
        end
        if layout.visible and layout.visible=="false" then
            temp:setVisible(false)
        else
            temp:setVisible(true)
        end
        if layout.template then
            if layout.template[1]=="res" then
                GameUI.addResourceIcon(temp, layout.template[2], layout.template[3] or 1, 0, 0)
            end
        end
        temp:setLocalZOrder(layout.z or 0)
    return temp
end
function BaseView:_addTableView(layout,viewsName)

    local celltab=layout.celltab
    local tableview=ui.createTableView({layout.sx,layout.sy},layout.isX,{sizeChange=layout.sizeChange,size=cc.size(celltab.sx,celltab.sy),offx=celltab.ox, offy=celltab.oy, disx=celltab.dx, disy=celltab.dy, rowmax=celltab.rowmax, infos=celltab.infos, cellUpdate=celltab.updateCell,scrollToCall=celltab.scrollToCall,locationEnd=celltab.locationEnd},layout.actionType)
    local temp=tableview.view
    if layout.relative then
       self:_relativeCompute(temp,layout)
    else
        display.adapt(temp,layout.x,layout.y,GConst.Anchor[layout.anchor])
        self:_adaptDatum(temp,layout)
    end
    if layout.visible and layout.visible=="false" then
        temp:setVisible(false)
    else
        temp:setVisible(true)
    end
    temp:setLocalZOrder(layout.z or 0)

    local key = layout.id
    if not key then
        key = viewsName
    end
    self._tableView[key]=tableview
    return temp
end
function BaseView:_relativeCompute(temp,layout,again)
    local ox=nil
    local oy=nil
    local tab=layout.relative
    local anchor=self._layoutViewTab.config[tab.id].anchor
    local widthRate
    local heightRate

    --加入相对的列表中 现在只实现label的改变
    if not again then
        local view = self._layoutViewTab.view[tab.id]
        local config = self._layoutViewTab.config[tab.id]
        if config.type == "label" then
            local baseView = self
            function view:setString2(str)
                self:setString(str)
                baseView:_relativeCompute(temp,layout,true)
            end
        end
    end

    --水平方向
    if string.find(anchor,"Left") then
        widthRate=1
    elseif string.find(anchor,"Right") then
        widthRate=0
    else
        widthRate=0.5
    end
    --竖指方向
    if string.find(anchor,"Bottom") then
        heightRate=1
    elseif string.find(anchor,"Top") then
        heightRate=0
    else
        heightRate=0.5
    end

    if tab.ox then
        if tab.ox>=0 then
            ox=self._layoutViewTab.view[tab.id]:getContentSize().width*widthRate+tab.ox
        else
            ox=-self._layoutViewTab.view[tab.id]:getContentSize().width*(1-widthRate)+tab.ox
        end
    end
    if tab.oy then
        if tab.oy>=0 then
           oy=self._layoutViewTab.view[tab.id]:getContentSize().height*heightRate+tab.oy
        else
           oy=-self._layoutViewTab.view[tab.id]:getContentSize().height*(1-heightRate)+tab.oy
        end
    end

    local x,y=self._layoutViewTab.view[tab.id]:getPosition()

    local otherPs = nil
    if layout.datum then

    end
    display.adapt(temp,x+(ox or 0),y+(oy or 0),GConst.Anchor[layout.anchor])
    --self:_adaptDatum(temp,layout,x+(ox or 0),y+(oy or 0))
end

function BaseView:_adaptDatum(temp,layout,x,y)
    local adaptDatum = layout.adaptDatum
    if not layout.adaptDatum then
        return
    end
    local x,y = x or layout.x,y or layout.y
    if adaptDatum == "LeftTop" then
        y = y-1536
    elseif adaptDatum == "Top" then
        x,y = x-1024,y-1536
    elseif adaptDatum == "RightTop" then
        x,y = x-2048,y-1536
    elseif adaptDatum == "RightBottom" then
        x = x-2048
    elseif adaptDatum == "Bottom" then
        x = x-1024
    elseif adaptDatum == "Center" then
        x,y = x-1024,y-768
    end
    display.adapt(temp,x,y,GConst.Anchor[layout.anchor])
end
