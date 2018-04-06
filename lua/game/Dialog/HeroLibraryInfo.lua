HeroLibraryInfo = class2("HeroLibraryInfo",function()
    return BaseView.new("HeroLibraryInfo.json",true)
end)
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

function HeroLibraryInfo:ctor(id)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self.id = id
    self:initUI()
    display.showDialog(self,nil,true)
end

function HeroLibraryInfo:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local function closeDialog()
       display.closeDialog(0)
    end
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(closeDialog))
    viewTab.butBack:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    local scNode=ScrollNode:create(cc.size(1820,1080), -self.dialogDepth, false, true)
    scNode:setScrollEnable(true)
    scNode:setInertia(true)
    scNode:setElastic(true)
    scNode:setClip(true)
    scNode:setScaleEnable(true, 1, 1, 1, 1)
    display.adapt(scNode, 56, 54, GConst.Anchor.LeftBottom)
    self:addChild(scNode,1)
    local viewsNode=ui.node()
    display.adapt(viewsNode, 0, 1080-10)
    scNode:getScrollNode():addChild(viewsNode,1)
    self.viewsNode=viewsNode
    local allInfos = {}
    local heroLibrary = SData.getData("heroLibrary",self.id)
    for i=1,KTLen(heroLibrary) do
        local a = KTLen(heroLibrary)+1-i
        if KTLen(heroLibrary[a]) > 0 then
            table.insert(allInfos,{a,heroLibrary[a]})
        end
    end
    local oy=0
    for i,item in ipairs(allInfos) do
        -- temp = ui.label(StringManager.getString(item[1]), General.font1, 57, {color={255,255,255}})
        -- display.adapt(temp, 910, -oy, GConst.Anchor.Top)
        -- viewsNode:addChild(temp)
        oy=oy+120
        GameUI.addSSR(viewsNode,item[1],0.75,800,-oy,0 )
        oy=oy+100
        for j,info in ipairs(item[2]) do
            local id = info
            local k=j
            if j>6 then
                k=j%6
                if k==0 then
                  k=6
                end
            end
            local cellBut = ui.button({238, 229} ,nil, {image=nil})
            display.adapt(cellBut, 68+(238+45)*(k-1), -oy, GConst.Anchor.LeftTop)
            viewsNode:addChild(cellBut)
            local head = GameUI.addItemIcon(cellBut:getDrawNode(),9,id,238/200,119,114,true,nil)
            if k==6 then
                oy=oy+229+45
            end
            -- local hero = GameLogic.getUserContext().heroData:makeHero(id)
            -- local word1, word2, word3
            -- if hero.info.range>10 then
            --     word1 = Localize("enumRType2")
            -- else
            --     word1 = Localize("enumRType1")
            -- end
            -- word2 = Localize("enumUType" .. hero.info.utype)
            -- word3 = Localize("dataHeroType" .. (hero.info.htype or hero.info.job or 6))
            -- local str = word1 .. "\n" .. word2 .. "\n" .. word3 .. "\n" .. hero:getSkillDesc(1, true)
            GameUI.registerTipsAction(cellBut, self.view, const.ItemHero, id)
            -- cellBut:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self, cellBut:getDrawNode(), cellBut:getContentSize().width/2, cellBut:getContentSize().height/2, str}))
            cellBut:setTouchThrowProperty(true, true)
        end
        if #item[2]<6 or (#item[2]>6 and #item[2]%6>0)then
            oy=oy+229+45
        end
        oy=oy+48
    end
    local scy=oy-48
    if scy>1080 then
        scNode:setScrollContentRect(cc.rect(0,1080-scy,0,scy))
    end

end






