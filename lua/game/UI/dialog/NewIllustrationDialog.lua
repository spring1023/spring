local SData = GMethod.loadScript("data.StaticData");
local const = GMethod.loadScript("game.GameLogic.Const");


-- 图鉴界面
local IllustrationDialog = class(DialogViewLayout)

local pages = {NHero = 1,SRHero = 2,URHero = 3,Equip = 4}

local function _sortHeroImages(a, b)
    local context = GameLogic.getUserContext()
    local aNum = context:getItem(const.ItemFragment, a[1])
    local bNum = context:getItem(const.ItemFragment, b[1])
    if aNum > 0 and aNum >= a[2].fragNum then
        a[2].order = 9
    end
    if bNum > 0 and bNum >= b[2].fragNum then
        b[2].order = 9
    end
    local _orderA = (a[2].order or 0) * 100000 + (a[2].displayColor or a[2].color) * 10000 + a[2].rating * 1000
    local _orderB = (b[2].order or 0) * 100000 + (b[2].displayColor or b[2].color) * 10000 + b[2].rating * 1000
    if _orderA ~= _orderB then
        return _orderA > _orderB
    elseif a[2].fragNum~=b[2].fragNum then
        return a[2].fragNum>b[2].fragNum
    else
        return a[1]>b[1]
    end
end

local function _sortHeroImages2(a, b)
    local aNum = GameLogic.getUserContext():getItem(const.ItemEquipFrag, a.eid)
    local bNum = GameLogic.getUserContext():getItem(const.ItemEquipFrag, b.eid)
    local aOrder = a[2].order
    local bOrder = b[2].order
    if aNum > 0 and aNum >= a[2].fragNum then
        aOrder = a[2].order/10
    end
    if bNum > 0 and bNum >= b[2].fragNum then
        bOrder = b[2].order/10
    end
    return aOrder < bOrder
end

function IllustrationDialog:ctor(params)
    print("----------IllustrationDialog:ctor----------------")
    self.priority=display.getDialogPri()+1
    
    self:initData()
    -- self:initUI()
    -- display.showDialog(self,false,true);
end

function IllustrationDialog:onCreate()
    self:setLayout("zhiyuan.json")
    self:loadViewsTo()
end

function IllustrationDialog:initData( ... )
    self.context = GameLogic.getUserContext()

    local hinfos = SData.getData("hinfos")
    local myHeros = self.context.heroData:getAllHeros()
    local myEquips = self.context.equipData:getAllEquips()
    local isGet = false
    self.tabHids = {{},{},{},{}}
    for hid, hinfo in pairs(hinfos) do
        if hid<=6000 then
            if hid%1000==0 then
            else
                local otherInfo = SData.getData("heroInfoNew",hid)

                for i,v in ipairs(myHeros) do
                    if v.hid == hid then
                        isGet = true
                        break
                    end
                end

                if hinfo.color <= 3 then                         --N英雄
                    table.insert(self.tabHids[pages.NHero], {hid,hinfo,otherInfo,isGet})
                elseif hinfo.displayColor and hinfo.displayColor == 5 then              --UR英雄
                    table.insert(self.tabHids[pages.URHero], {hid,hinfo,otherInfo,isGet})
                else                                             --R\SR\SSR英雄
                    table.insert(self.tabHids[pages.SRHero], {hid,hinfo,otherInfo,isGet})
                end
            end
        end
    end

    local edata = self.context.equipData
    for eid=2001,2009 do
        if eid~=2004 then
            local equip = edata:makeEquip(eid)
            local infoNew = SData.getData("equipInfoNew", eid)
            local mfrag = SData.getData("elevels",eid,1).mfrag

            for i,v in ipairs(myEquips) do                
                if v.eid == eid then
                    isGet = true
                    break
                end
            end
            equip.order = infoNew.order
            equip.fragNum = mfrag
            table.insert(self.tabHids[pages.Equip], {eid, equip, isGet})
        end
    end


    for i, hids in ipairs(self.tabHids) do
        if i~=pages.Equip then
            table.sort(hids, _sortHeroImages)
        else
            table.sort(hids, _sortHeroImages2)
        end
    end

    dump(self.tabHids[4],"myEquips")

    self:selectPage(1)
end


function IllustrationDialog:selectPage(pageidx)
    if self.page == pageidx then
        return
    end
    self.page = pageidx
    self:refreshScrollCard()
end

function IllustrationDialog:initUI()
    self.btn_close.btn_cloceFirst:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))
    local layout = self.layout_tag
    layout:removeAllChildren()

    for i=1, #pages do
        local cell = layout:createItem(1)
        cell:loadViewsTo()
        layout:addChild(cell)
        cell:setScriptCallback(ButtonHandler(self.selectPage,self,i))
    end

    self.selectPage(pages.URHero)
end

function IllustrationDialog:refreshScrollCard( ... )
    local pageInfos = self.tabHids[self.page]
    -- dump(pageInfos,"pageInfos")
    -- local scroll = self.scroll_card
    -- scroll:setLazyTableData(pageInfos, Handler(self.cardCallCell, self))
    self:selectCardInfo(pageInfos[1])
end

-- 
function IllustrationDialog:cardCallCell(cell, scroll, info)
    if not cell then
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end
    cell:setScriptCallback(ButtonHandler(selectCardInfo),info)
end

function IllustrationDialog:selectCardInfo( info )
    -- dump(info,"info")

    -- self:refreshLeft(info)
    -- self:refreshBgStory()
    -- self:refreshSkillIcon()
    -- self:refreshAttribute()
    -- self:refreshGetWay()
end


function IllustrationDialog:refreshLeft( ... )
    -- body
end

function IllustrationDialog:refreshBgStory( ... )
    -- body
end

function IllustrationDialog:refreshSkillIcon( ... )
    -- body
end

function IllustrationDialog:refreshGetWay( ... )
    -- body
end

return IllustrationDialog;
