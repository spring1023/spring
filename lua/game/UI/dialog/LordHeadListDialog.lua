--领主头像列表对话框
local LordHeadListDialog = class2("LordHeadListDialog",function()
    return BaseView.new("LordHeadListDialog.json",true)
end)

function LordHeadListDialog:ctor(callback)
    self.callback = callback
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self,nil,true)
end

function LordHeadListDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog))
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

    local SData = GMethod.loadScript("data.StaticData")
    local allHerosData = SData.getData("hinfos")
    --英雄已有表
    local heroMap = {}
    local context = GameLogic.getUserContext()
    local heros = context.heroData:getAllHeros()
    for k,v in pairs(heros) do
        if not heroMap[v.hid] or v.awakeUp > heroMap[v.hid] then
            heroMap[v.hid] = v.awakeUp
        end
    end

    -- 好像有些英雄没有觉醒版头像，排除一下
    local noAwakeHeros = {[4014]=0, [4015]=0, [4016]=0, [4019]=0, [4008]=0, [4031]=0}
    -- 初始开放英雄头像；纯走配置
    local initHeads = {}
    for i, hid in KTIPairs(SData.getData("constsNew", 4).data) do
        initHeads[hid] = 1
    end
    --英雄排序
    local heroOrder = {}

    local infos1 = {}
    local infos2 = {}
    local infos3 = {}
    for hid, hinfo in pairs(allHerosData) do
        -- 超过范围不是英雄
        if hid < 5000 and hid % 1000 ~= 0 then
            local order = (hinfo.displayColor or hinfo.color or 0) * 100000
                + (hinfo.rating or 0) * 10000 + hid
            if initHeads[hid] then
                table.insert(infos1, {id=hid, awakeUp=0, have=true, __order=order})
            elseif heroMap[hid] then
                table.insert(infos2, {id=hid, awakeUp=0, have=true, __order=order})
                if heroMap[hid] > 0 and not noAwakeHeros[hid] then
                    table.insert(infos3, {id=hid, awakeUp=1, have=true, __order=order})
                elseif hinfo.awake > 0 and not noAwakeHeros[hid] then
                    table.insert(infos3, {id=hid, awakeUp=1, have=false, __order=order - 10000000})
                end
            else
                order = order - 10000000
                table.insert(infos2, {id=hid, awakeUp=0, have=false, __order=order})
                if hinfo.awake > 0 and not noAwakeHeros[hid] then
                    table.insert(infos3, {id=hid, awakeUp=1, have=false, __order=order})
                end
            end
        end
    end

    GameLogic.mySort(infos1, "__order", true)
    GameLogic.mySort(infos2, "__order", true)
    GameLogic.mySort(infos3, "__order", true)

    local allInfos={{Localize("labelBaseHead"),infos1},{Localize("labelHeroHead"),infos2},{Localize("labelAwakeHead"),infos3}}
    local oy=0
    for i,item in ipairs(allInfos) do
        temp = ui.label(StringManager.getString(item[1]), General.font1, 57, {color={255,255,255}})
        display.adapt(temp, 910, -oy, GConst.Anchor.Top)
        viewsNode:addChild(temp)
        oy=oy+100
        for j,info in ipairs(item[2]) do
            local id = info.id
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
            local head = GameUI.addItemIcon(cellBut:getDrawNode(),9,id,238/200,119,114,true,nil,{lv = info.awakeUp})
            if k==6 then
                oy=oy+229+45
            end
            cellBut:setListener(function()
                if info.have then
                    self.callback(id,info.awakeUp)
                    display.closeDialog(0)
                else
                    display.pushNotice(Localize("stringNoHead"))
                end
            end)
            if not info.have then
                head:setSValue(-100)
            end
            cellBut:setTouchThrowProperty(true,true)
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

return LordHeadListDialog







