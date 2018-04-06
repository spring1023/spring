-- Module ID：coz2_3
-- Depiction：英雄获得界面
-- Author：XiaoGangMu
-- Create Date：2017-2-17
NewShowHeroDialog = class(DialogViewLayout)

-- 使用好对话框的事件来实现更灵活的功能制定
function NewShowHeroDialog:onExit()
    if self.callfunc then
        self.callfunc()
    end
end

function NewShowHeroDialog:canExit()
    if self.enterTime and socket.gettime()-self.enterTime > 1.5 then
        self.enterTime = nil
        return true
    end
end

function NewShowHeroDialog:onEnter()
    self.enterTime = socket.gettime()
end

function NewShowHeroDialog:onInitDialog()
    self:setLayout("NewShowHeroDialog.json")
    self:loadViewsTo()
    self.btnBackground:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    local cbut = self.nodeContent.view
    if not self.rtype then
        self.rtype = const.ItemHero
    end
    -------------------

    local node, action
    --这里修改装备的特效or self.rhero.info.type == 1
    if self.rhero.info.rating <= 2 then
        UIeffectsManage:showEffect_ShiLianChou(0,cbut,0,0,3)
        UIeffectsManage:showEffect_ShiLianChou(4,cbut,1024,768,3,{hid=self.rhero.hid,name=self.rhero:getName(),rating=self.rhero.info.rating})
    else
        ---------------
        local csbPathbj,csbPathrw,beganTime,endTime,rating
        rating = self.rhero.info.rating
        if self.rhero.info.displayColor and self.rhero.info.displayColor == 5 then
            rating = 5
        end
        local temp
        if rating == 3 then
            csbPathbj = "UICsb/sr_bj.csb"
            csbPathrw = "UICsb/sr_rw.csb"
            beganTime = 0
            endTime      = 225
        elseif rating == 4 then
            csbPathbj = "UICsb/ssr_bj.csb"
            csbPathrw = "UICsb/ssr_rw.csb"
            beganTime = 0
            endTime      = 230
        elseif rating == 5 then
            csbPathbj = "UICsb/ssr_bj.csb"
            csbPathrw = "UICsb/ssr_rw.csb"
            beganTime = 0
            endTime      = 235
        end
        node = ui.csbNode(csbPathbj)
        display.adapt(node,1024,768,GConst.Anchor.Center)
        cbut:addChild(node)
        action = ui.csbTimeLine(csbPathbj)
        node:runAction(action)
        action:gotoFrameAndPlay(beganTime,endTime,true)

        temp = ui.node()
        temp:setScale(1.333)
        display.adapt(temp, 1024, 768)
        cbut:addChild(temp)

        node = ui.csbNode(csbPathrw)
        display.adapt(node,0,0,GConst.Anchor.Center)
        temp:addChild(node)

        -- 增加特写
        local tmpnode = node:getChildByName("heroFeatureNode")
        if self.rtype == const.ItemEquip then
            local _tmp = GameUI.addEquipFeature(tmpnode, self.rhero.hid, 1, 0, 0)

            _tmp:runAction(ui.action.sequence({{"delay",1.0},{"call",function ()
                -- body
                if self.rhero.hid==2005 then
                    UIeffectsManage:showEffect_busizhixin(_tmp,300,320)
                elseif self.rhero.hid==2006  then
                    UIeffectsManage:showEffect_zhanzhengwange(_tmp,300,300,0,1.2)
                elseif self.rhero.hid==2007 then
                    UIeffectsManage:showEffect_kuangbao(_tmp,390,370,0,1.3)
                end
            end}}))
        else
            GameUI.addHeroFeature(tmpnode, self.rhero.hid, 1, 0, 0, 1, true)
        end


        tmpnode = node:getChildByName("nodeHeroName")
        local newLayout = self:addLayout("HeroNameBlock", tmpnode)
        newLayout:loadViewsTo(self)
        self.heroName:setString(self.rhero:getName())

        --确定按钮
        local okBtn = ui.button({300, 107}, display.closeDialog, {cp1 = self.priority,image="images/btnGreen.png"})
        okBtn:setHValue(114)
        display.adapt(okBtn, 0, 0, GConst.Anchor.Center)
        self.okBtnPos:addChild(okBtn)
        local okLabel = ui.label(Localize("btnYes"), General.font1, 47)
        display.adapt(okLabel, 150, 65, GConst.Anchor.Center)
        okBtn:getDrawNode():addChild(okLabel)

        --分享按钮
        if self.shareIdx then
            UIeffectsManage:showEffect_share(self.shareBtnPos.view, 0, 0, 1, self.shareIdx, self.rhero.hid)
        end
        action = ui.csbTimeLine(csbPathrw)
        node:runAction(action)
        action:gotoFrameAndPlay(0,false)
        --加头上Tips和SSR

        local lan = General.language
        if lan ~= "CN" and lan ~= "EN" and lan ~= "HK" and lan ~= "IR" then
            lan = "EN"
        end
        local ltype = self.rtype
        if self.rhero.info.displayColor and self.rhero.info.displayColor == 5 then
            ltype = 5
            if self.shareIdx and self.shareIdx <= 4 then
                GameEvent.sendEvent("RefreshBarrage")
            end
        end
        local _tips = "images/uieffectGet" .. lan .. ltype .. ".png"
        local x,y = 0,1536/2-400
        local _getHeroTips = ui.sprite(_tips,{800,300})
        display.adapt(_getHeroTips,x,y,GConst.Anchor.Center)
        temp:addChild(_getHeroTips)
        -- local _tips = "titleGetHeroTips"
        -- if self.rtype == const.ItemEquip then
        --     _tips = "titleGetItemTips"
        -- end
        -- tmpnode = node:getChildByName("label1Node")
        -- temp = ui.label(Localize(_tips), General.font1, 70, {color={249,135,0},fontW=500,fontH=150})
        -- display.adapt(temp, 0, 0, GConst.Anchor.Center)
        -- tmpnode:addChild(temp)
        if self.rtype == const.ItemHero then
            local rating = self.rhero.info.rating
            if self.rhero.info.displayColor and self.rhero.info.displayColor == 5 then
                rating = 5
            end
            local node = ui.node()
            display.adapt(node,x+230,y)
            temp:addChild(node)
            GameUI.addSSR(node,rating,1,0,0,0,GConst.Anchor.Left)
        end
    end
    display.showDialog(self,false,true)
end
