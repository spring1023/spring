--注意：BaseView是一个node；它的优点是作为node可以像使用CCNode一样去使用它
--但是如果希望把View和Model分开，即对话框可以先把数据准备好，而不直接初始化并显示，则应该使用其他方式来套用该类


--[[
    2017/3/2 更新
    @dnt
    添加 useOldConfig 开关，旧的界面仍采用BaseView，同时兼容creater导出的配置，方便换皮的同时进行优化
    2017/3/11 更新
    解决新旧配置同时存在引发报错bug，在creater配置中添加createrConfig字段
]]

local configDir = "configs/ui/"

--这里仿造android的格式写一个UI框架
View = class()
ViewLayout = class(View)
local ViewNode = class(View)
local ViewScroll = class(View)
local ViewButton = class(View)
local ViewImage = class(View)
local ViewLabel = class(View)

--一个提供给具体游戏来实现一些自定义的接口
local _viewTemplateFunc = nil
ViewUtil = {}
--设置View的模板，即由程序实现一些通用模板，省略重复性的无意义工作
function ViewUtil.setTemplateFunction(func)
    _viewTemplateFunc = func
end

function View:ctor(setting)
    self._setting = setting
    self._isLeaf = false
    self._weak_ref = {}
    setmetatable(self._weak_ref, {__mode = "v"})
    --区分新旧配置文件
    self._createrConfig = setting and type(setting) == "table" and setting.createrConfig
    self:onCreate()
    self:initLayout()
end

function View:addRelative(rview, setting)
    if not self._relatives then
        self._relatives = {}
    end
    self._relatives[rview] = setting
    rview._relateTo = self
    self:resetRelative(rview, setting)
end

function View:resetRelative(rview, setting)
    local visible = self.view:isVisible()
    if not visible then
        if not setting.dir then
            return
        end
        local rview2 = self._relateTo
        if rview2 then
            rview2:resetRelative(rview, setting)
            return
        end
    end
    local size = self.size
    local view = rview.view
    if not setting.dir then
        rview:setPosition(size[1]*setting.px, size[2]*setting.py)
        if setting.psx and setting.psy then
            rview:setSize(size[1]*setting.psx, size[2]*setting.psy)
        end
    else
        local manchor = self.view:getAnchorPoint()
        local x, y = self.view:getPosition()
        local ox = setting.ox or 0
        local oy = setting.oy or 0
        local ax, ay = setting.dir[1], setting.dir[2]
        rview:setPosition(x+ox+(ax-manchor.x)*size[1], y+oy+(ay-manchor.y)*size[2])
    end
end

function View:setPositionX(x)
    self.view:setPositionX(x)
end

function View:setPositionY(y)
    self.view:setPositionY(y)
end

function View:setPosition(x, y)
    self.view:setPosition(x, y)
    self:onPositionChange()
end

function View:getPosition()
    return self.view:getPosition()
end

function View:getAnchorPoint()
    return self.view:getAnchorPoint()
end

function View:setAnchorPoint(anchor)
    return self.view:setAnchorPoint(anchor)
end

function View:runAction(action)
    self.view:runAction(action)
end

function View:setScale(sx,sy)
    return self.view:setScaleX(sx),self.view:setScaleY(sy)
end

function View:getScale()
    return self.view:getScaleX(),self.view:getScaleY()
end

function View:stopAllActions()
    if self.children then
        for i,v in ipairs(self.children) do
            v:stopAllActions()
        end
    end
    self.view:stopAllActions()
end

function View:computeWidget()
    local parent = self._weak_ref.parent
    local widget = self._setting and type(self._setting)=="table" and self._setting.widget
    if parent and widget then
        local sx, sy = parent.size[1], parent.size[2]
        local px, py = self:getPosition()
        local sizeChange = false
        if widget.osx then
            sx = sx + widget.osx
            sizeChange = true
        end
        if widget.osy then
            sy = sy + widget.osy
            sizeChange = true
        end
        if widget.ax then
            px = parent.size[1] * widget.ax + widget.ox
        end
        if widget.ay then
            py = parent.size[2] * widget.ay + widget.oy
        end
        self:setPosition(px, py)
        if sizeChange then
            self:setSize(sx, sy)
        end
    end

    if parent and self._setting and type(self._setting)=="table" and self._setting.scaleWidget then
        self.view:setScaleX(parent.size[1]/self.size[1])
        self.view:setScaleY(parent.size[2]/self.size[2])
    end
end

function View:addChild(view, z)
    if self._isLeaf then
        log.e("Cannot add child to a leaf node!")
        print(debug.traceback())
        return
    end
    local tview = view
    if type(tview)=="table" then
        tview = tview.view
        view._weak_ref.parent = self
        view:computeWidget()
        if self._setting and type(self._setting)=="table" and self._setting.layout then
            if not self.children then
                self.children = {}
            end
            table.insert(self.children, view)
            self:resetLayout()
        end
    end
    local mynode = self._view or self.view
    if z then
        tview:setLocalZOrder(z)
    end
    mynode:addChild(tview)
    self.zorder = tview:getLocalZOrder()
end

function View:removeChild(view,isRetain)
    if not isRetain then isRetain = false end
    if not view and self.children then
        view = self.children[#self.children]
    elseif not view then
        return
    end
    -- print("removeChild",view)
    if self.children then
        for i,v in ipairs(self.children) do
            if v.view == view.view then
                table.remove(self.children,i)

                self:resetLayout()
                break
            end
        end
    end
    local flag = true
    if isRetain then
        view.view:retain()
        flag = false
    end
    view.view:removeFromParent(flag)
end

function View:removeAllChildren(cleanup)
    if self._isLeaf then
        log.e("Cannot remove child from a leaf node!")
        return
    end
    local mynode = self._view or self.view
    mynode:removeAllChildren(cleanup)
    self.children = nil
end

function View:getChildren()
    return self.children or self.view:getChildren()
end

function View:setColor(r, g, b)
    local mynode = self._view or self.view
    if not g then
        r, g, b = r[1], r[2], r[3]
    end
    if mynode.setTextColor then
        mynode:setTextColor(cc.c4b(r, g, b, 255))
    elseif mynode.setColor then
        mynode:setColor(cc.c3b(r, g, b))
    end
end

function View:setOpacity(alpha)
    local mynode = self.view
    if mynode.setOpacity then
        mynode:setOpacity(alpha)
    end
end

function View:setSize(sx, sy)
    self.view:setContentSize(sx, sy)
    self.size = {sx, sy}
    self:onSizeChange()
end

function View:setVisible(visible)
    if visible~=self.view:isVisible() then
        -- 如果节点有特殊逻辑
        if visible and self._setting and self._setting.autoLoadVisible then
            if not self._autoLoaded then
                self._autoLoaded = true
                self:lazyload()
            end
        end
        self.view:setVisible(visible)
        self:onRectChange()
    end
end

function View:isVisible()
    return self.view:isVisible()
end

function View:onPositionChange()
    self:onRectChange()
end

function View:onSizeChange()
    self:onRectChange()
end

function View:onRectChange()
    local parent = self._weak_ref.parent
    if not self._createrConfig then
        if parent and self._mode then
            local x, y = self.view:getPosition()
            local size = self.size
            local anchor = self.view:getAnchorPoint()
            local box = {0, 0, 0, 0}
            box[1] = x+(0-anchor.x)*size[1]
            box[2] = y+(0-anchor.y)*size[2]
            box[3] = x+(1-anchor.x)*size[1]
            box[4] = y+(1-anchor.y)*size[2]
            local padding = self._padding or 0
            local psize = parent.size
            if self._mode>0 then
                local psx, psy = psize[1], psize[2]
                if self._mode%2==1 and box[3]+padding~=psx then
                    psx = box[3]+padding
                end
                if self._mode%4>=2 and box[4]+padding~=psy then
                    psy = box[4]+padding
                end
                if psx~=psize[1] or psy~=psize[2] then
                    parent:setSize(psx, psy)
                end
                if self._mode>=4 then
                    psx, psy = size[1], size[2]
                    if self._mode%8>=4 and box[1]-padding~=0 then
                        psx = psx+box[1]-padding
                    end
                    if self._mode%16>=8 and box[2]-padding~=0 then
                        psy = psy+box[2]-padding
                    end
                    if self._mode%32>=16 and box[3]+padding~=psize[1] then
                        psx = psx-(box[3]+padding-psize[1])
                    end
                    if self._mode%64>=32 and box[4]+padding~=psize[2] then
                        psy = psy-(box[4]+padding-psize[2])
                    end
                    if psx~=size[1] or psy~=size[2] then
                        return self:setSize(psx, psy)
                    end
                end
            end
        end
        if self._relatives then
            for rview, setting in pairs(self._relatives) do
                self:resetRelative(rview, setting)
            end
        end
    else
        if parent and parent._setting and type(parent._setting) == "table" and parent._setting.layout then
            parent:resetLayout()
        end
    end
end

function View:setContentSize(sx, sy)
    self:setSize(sx, sy)
end

function View:getContentSize()
    return self.size
end

function View:changeZorder(value)
    if not self.zorder then return end
    self.view:setLocalZOrder(self.zorder+value)
end

function View:setLaoutCentered()
    self.lyoutCentered = true
    self:resetLayout()
end

function View:initLayout()
    if not self._setting or type(self._setting) ~= "table" then
        return
    end
    local layout = self._setting.layout
    if not layout or layout.ltype == 0 then
        return
    end
    local ltype = layout.ltype  --布局类型：0 none 1 horizon 2 vertical 3 grid
    local off = {layout.ox, layout.oy}  --spacex spacey
    local p = layout.padding  --边缘距离（缩进）

    local rx = ltype
    local mSize = self.size
    if ltype == 3 then
        rx = layout.isX and 1 or 2
        local cellSize = layout.csize
        local i = 3 - rx
        local rowmax = math.floor((mSize[i] - 2*p + off[i]) / ( cellSize[i] + off[i] ))
        if rowmax < 1 then
            rowmax = 1
        end
        self._rowmax = rowmax
    else
        self._rowmax = 1
    end
    self._rollx = rx
end

function View:subResetLayout()
    return false
end

function View:resetLayout()
    if self:subResetLayout() then
        return
    end
    if self._inLoading or not self._setting or type(self._setting) ~= "table" then
        return
    end
    local layout = self._setting.layout
    local children = self.children
    if children and layout then
        local p = layout.padding  --边缘距离（缩进）
        local ltype = layout.ltype  --布局类型：0 none 1 horizon 2 vertical 3 grid
        if ltype == 0 then
            return
        end
        local resize = layout.resize --0 none 1 contenner 2 children
        local px, py
        local dx, dy = layout.dirx, layout.diry  -- horizon or vertical
        local off = {layout.ox, layout.oy}  --spacex spacey
        local rowmax = self._rowmax    -- （有限向）纵向列数 横向排数
        local odd --剩余不足一行
        local ss
        local rx = self._rollx
        if ltype == 3 then  --网格
            local i, j = 3-rx, rx --dir index
            local rows = math.ceil(#children / rowmax) --行或列数
            odd = #children % rowmax
            ss = 2*p + rows * layout.csize[j] + (rows - 1) * off[j]
            if ss < self.size[rx] then
                ss = self.size[rx]
            end
        end
        if resize == 1 then
            if ltype ~= 3 then
                ss = 2 * p
                for i, child in ipairs(children) do
                    if child.view:isVisible() then
                        ss = ss + child.size[ltype]
                        if i > 1 then
                            ss = ss + off[ltype]
                        end
                    end
                end
            end
            if rx == 1 then
                self:setContentSize(ss, self.size[2])
            else
                self:setContentSize(self.size[1], ss)
            end
        end
        local msize = self:getContentSize()
        for i, child in ipairs(children) do
            if child.view:isVisible() then
                local canchor = child.view:getAnchorPoint()
                local csize = child.size
                local stepx     --换行
                if ltype == 3 then
                    csize = layout.csize
                    if i % rowmax == 0 then
                        stepx = (rx == 1)
                    else
                        stepx = (rx ~= 1)
                    end
                elseif ltype == 1 then
                    stepx = true
                else
                    stepx = false
                end
                if dx then
                    if not px then
                        if dx == 0 then
                            px = p
                        else
                            px = msize[1] - p
                        end
                    end
                    if dx == 0 then
                        child:setPositionX(px + child.size[1] * canchor.x)
                    else
                        child:setPositionX(px - child.size[1] * (1-canchor.x))
                    end

                    if self.lyoutCentered and odd and i>#children-odd then
                        local lenoff = (csize[1] + off[1])*(rowmax-odd)/2
                        if dx == 0 then
                            child:setPositionX(px + child.size[1] * canchor.x + lenoff)
                        else
                            child:setPositionX(px - child.size[1] * (1-canchor.x) - lenoff)
                        end
                    end
                end
                if dy then
                    if not py then
                        if dy == 0 then
                            py = p
                        else
                            py = msize[2] - p
                        end
                    end
                    if dy == 0 then
                        child:setPositionY(py + child.size[2] * canchor.y)
                    else
                        child:setPositionY(py - child.size[2] * (1-canchor.y))
                    end

                    -- if ltype == 3 and i>#children-odd then
                    --     local lenoff = (csize[2] + off[2])*(rowmax-odd)/2
                    --     if dy == 0 then
                    --         child:setPositionY(py + child.size[2] * canchor.y + lenoff)
                    --     else
                    --         child:setPositionY(py - child.size[2] * (1-canchor.y) - lenoff)
                    --     end
                    -- end
                end
                if stepx then
                    if dx == 0 then
                        px = px + csize[1] + off[1]
                    else
                        px = px - csize[1] - off[1]
                    end
                else
                    if dy == 0 then
                        py = py + csize[2] + off[2]
                    else
                        py = py - csize[2] - off[2]
                    end
                end
                if ltype == 3 and i % rowmax == 0 then
                    if stepx then
                        py = nil
                    else
                        px = nil
                    end
                end
            end
        end
    end
--[[
    if self._relatives then
        for rview, setting in pairs(self._relatives) do
            self:resetRelative(rview, setting)
        end
    end
]]
end

function View:cleanup()
    -- dump("12345")
    -- dump(debug.traceback())
    if self.isHeroPage then
        log.e(debug.traceback())
    end
    if not self.reuse then
        self._setting = nil
        self._isLeaf = nil
        self._view = nil
        self._relateTo = nil
        if self._relatives then
            for k, v in pairs(self._relatives) do
                self._relatives[k] = nil
                k:cleanup()
            end
            self._relatives = nil
        end
        self.view = nil
        self.size = nil
    end
    self._weak_ref.parent = nil
end

function View:getSetting(k)
    return self._setting[k]
end

function View:setHValue(hvalue)
    if self.view and self.view.setHValue then
        self.view:setHValue(hvalue)
    end
end

function View:setSValue(svalue)
    if self.view and self.view.setSValue then
        self.view:setSValue(svalue)
    end
end

function View:setLValue(lvalue)
    if self.view and self.view.setLValue then
        self.view:setLValue(lvalue)
    end
end

local _excepts = {views=1, id=2}
function View:fillPrefab(setting)
    local configName = setting.prefab
    if configName then
        if not configName:find(".json") then
            configName = configName .. ".json"
        end
        local config = GMethod.loadConfig(configDir .. "templates/" .. configName)
        setting.type = config.type
        setting.lazyViews = config.views
        for k, v in pairs(config) do
            if not setting[k] and not _excepts[k] then
                setting[k] = v
            end
        end
    end
end

function View:loadPrefab()
    local prefab = self._setting.prefab
    -- if prefab == "ItemIcon" then print("真的有加载过啊") end
    if prefab then
        -- 标记为plazy的模板表示作为模板本身就是plazy的所以不需要addviews
        if not prefab:find("#plazy") then
            self:_addViews(self._setting.lazyViews)
            self:loadViewsTo()
            if self._setting.enum then
                self:changeEnum(self._setting.enum)
            end
        end
    end
end

function View:changeEnum(enum)
    if self.enum then
        if enum == self._enumValue then
            return
        end
        self.enum:removeAllChildren(true)
        self._enumValue = enum
        for _, eview in ipairs(self._setting.enumViews) do
            if eview.enum == enum then
                self.enum:_addViews({eview})
                return
            end
        end
    end
end

function View:lazyload(tab)
    self:_addViews(self._setting.lazyViews)
    self:loadViewsTo(tab)
end

function View:_addViews(views, toView)
    if not self._createrConfig then
        local layouts = self._layouts
        if views then
            for _, vsetting in ipairs (views) do
                local view=self:_initView(vsetting)
                if view then
                    if vsetting.id then
                        layouts[vsetting.id] = view
                    end
                    if vsetting.parent then
                        layouts[vsetting.parent]:addChild(view)
                    elseif toView then
                        toView:addChild(view)
                    else
                        self:addChild(view)
                    end
                    local vv = view.view
                    local anchor = vsetting.anchor or vsetting.datum
                    if anchor then
                        if type(anchor)=="string" then
                            anchor = GConst.Anchor[anchor]
                        end
                        vv:setAnchorPoint(cc.p(anchor[1], anchor[2]))
                    end
                    if vsetting.visible==false then
                        view:setVisible(false)
                    end
                    if vsetting.z then
                        vv:setLocalZOrder(vsetting.z)
                    end
                    if vsetting.gz then
                        vv:setGlobalZOrder(vsetting.gz)
                    end
                    --支持三种方式设置坐标点：
                    --1. 绝对坐标布局，即按物理坐标导出；不过支持使用datum来设置基准点
                    --2. 百分比坐标布局，即按百分比设置坐标；这个就不用datum了
                    --3. 相对坐标布局，即按照某个同层节点的位置进行相对偏移
                    --其中第一种是绝对坐标，不会因为位移和大小做调整
                    if vsetting.px and vsetting.py then
                        view._weak_ref.parent:addRelative(view, {px=vsetting.px, py=vsetting.py, psx=vsetting.psx, psy=vsetting.psy})
                    elseif vsetting.relative then
                        local r = vsetting.relative
                        local target = layouts[r.id]
                        if target then
                            target:addRelative(view, {dir=GConst.Anchor[r.dir or "Right"], ox=r.ox, oy=r.oy})
                        else
                            log.e("Couldn't find relative target:%s", r.id)
                        end
                    else
                        local scale = vsetting.scale or 1
                        if type(scale)=="string" then
                            scale = display.getScalePolicy()[GConst.Scale[scale]]
                        end
                        local x, y = (vsetting.x or 0)*scale, (vsetting.y or 0)*scale
                        if vsetting.datum then
                            local adatum = GConst.Anchor[vsetting.datum]
                            x = x+view._weak_ref.parent.size[1] * adatum[1]
                            y = y+view._weak_ref.parent.size[2] * adatum[2]
                        end
                        vv:setPosition(x, y)
                        if scale~=1 then
                            vv:setScaleX(vv:getScaleX()*scale)
                            vv:setScaleY(vv:getScaleY()*scale)
                        end
                    end
                    if vsetting.views then
                        self:_addViews(vsetting.views, view)
                    end
                end
            end
        end
    elseif views then
        if toView then
            toView._inLoading = true
        end
        for _, vsetting in ipairs (views) do
            local view = self:_initView(vsetting)
            if view then
                if vsetting.id then
                    self:setView({vid=vsetting.id,view=view})
                end
                if vsetting.parent then
                    self:getView(vsetting.parent):addChild(view)
                elseif toView then
                    toView:addChild(view)
                else
                    self:addChild(view)
                end
                if vsetting.views then
                    self:_addViews(vsetting.views, view)
                end
                if vsetting.prefab then
                    view:loadPrefab()
                end
            end
        end
        if toView then
            toView._inLoading = nil
            toView:resetLayout()
        end
    end
end

function View:_initView(layout,clip)
    local view
    local scale
    if not self._createrConfig then
        if layout.autofill then
            scale = ui.getUIScale2()
            if layout.psx then
                layout.sx = layout.psx*self.size[1]/scale
            end
            if layout.psy then
                layout.sy = layout.psy*self.size[2]/scale
            end
            layout.scale = scale
        end
        if layout.type=="image" then
            view = ViewImage.new(layout)
        elseif layout.type=="label" or layout.type=="scrollLabel" then
            view = ViewLabel.new(layout)
        elseif layout.type=="button" then
            view = ViewButton.new(layout)
            if self._inScroll then
                view.view:setTouchThrowProperty(true, true)
            end
        elseif layout.type=="node" then
            view = ViewNode.new(layout)
        end
        if not view then
            log.e("1 Error config with layout type:%s",layout.type)
            log.e(debug.traceback())
            return
        end
        if layout.mode then
            view._mode = layout.mode
            view._padding = layout.padding
        end
        if layout.color then
            view:setColor(layout.color)
        end
        if layout.opacity then
            view:setOpacity(layout.opacity)
        end
        if layout.rotation then
            view.view:setRotation(layout.rotation)
        end
    else
        --临时解决clippingnode显示问题
        if layout.id == "stencil" and not clip then
            return
        end
        self:fillPrefab(layout)
        if layout.type=="image" then
            view = ViewImage.new(layout)
        elseif layout.type=="label" then
            view = ViewLabel.new(layout)
        elseif layout.type=="button" then
            view = ViewButton.new(layout)
            view.view:setTouchThrowProperty(true, true)
        elseif layout.type == "scroll" then
            view = ViewScroll.new(layout)
        elseif layout.type=="node" then
            view = ViewNode.new(layout)
        end
        if not view then
            log.e("2 Error config with layout type:%s",layout.type)
            return
        end
        if layout.mode then
            view._mode = layout.mode
            view._padding = layout.padding
        end
        if layout.color then
            view:setColor(layout.color)
        end
        if layout.opacity then
            view:setOpacity(layout.opacity)
        end
        local vv = view.view
        if layout.rotation then
            vv:setRotation(layout.rotation)
        end
        local x, y = (layout.x or 0), (layout.y or 0)
        vv:setPosition(x, y)
        if layout.scaleX then
            vv:setScaleX(layout.scaleX * vv:getScaleX())
        end
        if layout.scaleY then
            vv:setScaleY(layout.scaleY * vv:getScaleY())
        end
        if layout.z then
            vv:setLocalZOrder(layout.z)
        end
        local anchor = layout.anchor
        if anchor then
            if type(anchor)=="string" then
                anchor = GConst.Anchor[anchor]
            end
            vv:setAnchorPoint(cc.p(anchor[1], anchor[2]))
        end

        if layout.visible == false then
            view:setVisible(false)
        end
    end
    return view
end


function View:loadViewsTo(tab)
    if not tab then
        tab = self
    end
    if self._layouts then
        for k,v in pairs(self._layouts) do
            if not tab[k] then
                tab[k] = v
            elseif tab[k] and tab[k]~=v then
                tab[k] = v
            end
        end
    end
end

function View:getView(vid)
    return self._layouts and self._layouts[vid]
end

function View:setView(params)
    if not self._createrConfig then
        self.size = params.size
        self.view = params.view
        self._layouts = {}
        if params.onLife then
            RegLife(self.view, Handler(self.onLifeCycle, self))
        end
    else
        if not self._layouts then
            self._layouts = {}
        end
        self._layouts[params.vid] = params.view
    end
end

function View:createItem(idx)
    local vsetting = self._setting.lazyViews[idx]
    if vsetting then
        local view = self:_initView(vsetting)
        if view then
            if not vsetting.delay then
                view:loadChildView()
                view.inited = true
            end
            return view
        end
    end
end

-- 对于部分单图的可以这么搞一下；主要是不想反复创建多个图片
function View:changeItemImage(item, idx)
    local vsetting = self._setting.lazyViews[idx]
    if vsetting then
        item._setting = vsetting
        item:setImage(vsetting.image, vsetting.s9edge, vsetting.sx, vsetting.sy)
        item:setPosition(vsetting.x, vsetting.y)
    end
end

function View:loadChildView()
    local vsetting = self._setting
    if vsetting.views then
        self:_addViews(vsetting.views, self)
    end
    if vsetting.prefab then
        self:loadPrefab()
    end
end

function View:createItemWithId(id)
    for idx, vsetting in ipairs(self._setting.lazyViews) do
        if vsetting.id == id then
            return self:createItem(idx)
        end
    end
end

function View:getRect()
    if self.view then
        local size = self.view:getContentSize()
        local anchor = self.view:getAnchorPoint()
        local pos = {self.view:getPosition()}
        -- dump(size)
        -- dump(anchor)
        -- dump(pos)
        return cc.rect(pos[1]-size.width*anchor.x,pos[2]-size.height*anchor.y,size.width,size.height)
    end
    return cc.rect(0,0,0,0)
end

function View:getWorldPos()
    --local x,y = self:getPosition()
    --return self.parent.view:convertToWorldSpace(ccp(x,y))
    return self.view:convertToWorldSpace(ccp(0,0))
end

function ViewNode:onCreate()
    local setting = self._setting
    local color = setting.color
    local touch = setting.touch
    local size = {0, 0}
    if setting.sx and setting.sy then
        size[1], size[2] = setting.sx, setting.sy
    end
    if setting and type(setting)=="table" and setting.clipping then
        local vsetting = setting.clipping[1]
        local ccnode = self:_initView(vsetting,true)
        if ccnode then
            if vsetting.views then
                ccnode:_addViews(vsetting.views, ccnode)
            end
            if vsetting.prefab then
                ccnode:loadPrefab()
            end
            ccnode._weak_ref.parent = self
            self.size = size
            ccnode:computeWidget()
        end
        self.view = ui.clippingNode(size, ccnode.view)
    elseif setting.useHSL then
        self.view = ui.shlNode(size)
    elseif touch then
        self.view = ui.touchNode(size, 0, true)
    elseif not color then
        self.view = ui.node(size, true)
        self.view:setCascadeColorEnabled(true)
    else
		self.view = ui.colorNode(size, color)
	end
    if not setting or not setting.layout then
        self.view:setCascadeColorEnabled(true)
    end
    if setting.vs then
        self.view:setScale(setting.vs)
        size[1] = size[1]*setting.vs
        size[2] = size[2]*setting.vs
    end
    self.size = size
    if setting.template and _viewTemplateFunc then
        self.templateParams = setting.template
        if setting.template[2]>0 then
            self._templateView = _viewTemplateFunc(self, 0, setting.template)
        end
    end
end

function ViewNode:setTemplateValue(value)
    if self.templateParams then
        if value~=self.templateParams[2] then
            self:removeAllChildren(true)
            self.templateParams[2] = value
            if value>0 then
                self._templateView = _viewTemplateFunc(self, 0, self.templateParams)
            end
        end
    end
end

function ViewNode:loadTableView(infos, updateFunc)
    self:removeAllChildren(true)
    local ts = self:getSetting("tableSetting")
    local size = self.size
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=infos, cellUpdate=updateFunc})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.view:addChild(tableView.view)
    return tableView
end


--[[
    --scrollview延时加载
    1，在creater中给需要延时加载的节点添加#pdelay字段
    2，使用时注册滑动回调事件，默认没有
       scroll.view:setScriptHandler(Script.createCObjectHandler    (scroll))
    3，设置cell数据及刷新回调方法
       scroll:setDatas({datas = self.storeInfos,cellUpdate =        cellUpdate,target = self})
    4，添加cell节点是使用scroll:addCell(cell) 方法
]]
function ViewScroll:onCreate()
    local setting = self._setting
    local scroll = setting.scroll
    local size = {setting.sx, setting.sy}
    self.size = size
    self._isX = scroll.isX
    self.oldpx=0
    self.oldpy=0
    self.cellNum = 0
    self.initedCellNum = 0
    local sseting = {scroll=true, inertia=scroll.inertial, clip=setting.mask, elastic=scroll.elastic}
    local view = ui.scrollNode(size, setting.pri or -1, scroll.isX, not scroll.isX, sseting)
    self.view = view
    view:setTouchThrowProperty(true, true)
    view:setScaleEnable(false, 1, 1, 1, 1)
    self._view = self.view:getScrollNode()
    self:setContentSize(size[1], size[2])

    --view:setScriptHandler(Script.createCObjectHandler(self))
end

function ViewScroll:setEnable(val)
    self.view:setScrollEnable(val)
end

function ViewScroll:scrollBy(x,y,speed,endCall)
    -- print(" ViewScroll:scrollBy",x,y,speed)
    local moveMax = math.abs((x==0 and y or x))
    if not speed then speed = moveMax end
    local schedule
    local moveLen = 0
    --这个写法有问题；如果self.view在时间范围内已移除，则会报错（虽然可能不影响什么）
    --因此应该改成调用action的方式
    --[[
    schedule = GFunc_schedule(function(diff)
        moveLen = moveLen + speed
        if moveLen >= moveMax then
            GFunc_unschedule(schedule)
            return
        else
            x = x==0 and 0 or speed*x/math.abs(x)
            y = y==0 and 0 or speed*y/math.abs(y)

            self.view:scrollBy(x,y)

            self.oldpx = self.oldpx+x
            self.oldpy = self.oldpy+y

            if self.initedCellNum<self.cellNum then
                self:initCell()
            end
        end
    end,0.01,false)
    --]]
    local actionTag = 15001
    local runFunc = function()
        moveLen = moveLen + speed
        if moveLen >= moveMax then
            self.view:stopActionByTag(actionTag)
            if endCall then
                endCall()
            end
            return
        else
            x = x==0 and 0 or speed*x/math.abs(x)
            y = y==0 and 0 or speed*y/math.abs(y)
            self.view:scrollBy(x,y)

            if self.initedCellNum<self.cellNum then
                self:initCell()
            end
        end
    end
    local runAction = ui.action.arepeat({"sequence", {{"delay", 0.025}, {"call", runFunc}}})
    runAction:setTag(actionTag)
    self.view:runAction(runAction)
end

function ViewScroll:ajustPosition(cell,speed,topLen,botLen,endCall)
    if not cell then
        if self._isX then
            self.view:scrollTo(0,0)
        else
            local size = self:getContentSize()
            self.view:scrollTo(0,self.size[2]-size[2])
        end
    else
        if not botLen then botLen = topLen end

        local pos = cell:getWorldPos()
        local size = {self.size[1]*self.view:getScale(),self.size[2]*self.view:getScale()}
        local csize = cell:getContentSize()
        local nodePos = ui.getNodePos(self.view,pos)
        if not self._isX then
            --if math.abs(nodePos.y)<csize[2] then
            --    self:scrollBy(0,botLen+csize[2]-math.abs(pos.y),speed)
            --elseif math.abs(nodePos.y)+csize[2]>size[2] then
            --    self:scrollBy(0,size[2]-csize[2]-topLen-math.abs(nodePos.y),speed)
            if nodePos.y<botLen then
                self:scrollBy(0,botLen-nodePos.y,speed,endCall)
            elseif nodePos.y>size[2]-topLen then
                self:scrollBy(0,size[2]-topLen-nodePos.y,speed,endCall)
            elseif endCall then
                endCall()
            end
        else
            --if math.abs(nodePos.x)<csize[1] then
            --    self:scrollBy(botLen+csize[1]-math.abs(nodePos.x),0,speed)
            --elseif math.abs(nodePos.x)-csize[1]>size[1] then
            --    self:scrollBy(size[1]-csize[1]-topLen-math.abs(nodePos.x),0,speed)
            if nodePos.x<botLen then
                self:scrollBy(botLen-nodePos.x,0,speed,endCall)
            elseif nodePos.x>size[1]-topLen then
                self:scrollBy(size[1]-topLen-nodePos.x,0,speed,endCall)
            elseif endCall then
                endCall()
            end
        end
    end
end
-- 由于目前reuseCell 的index 和 实际children的index 并不一致
-- 使用时应该 修改一下
function ViewScroll:locationIndex(index,speed)
    if not self.children or index > #self.children then
        return
    end
    log.d("locationIndex")
    local cell = self.children[index]
    local x,y = cell:getPosition()
    local size = self.size
    x = self._isX and size[1]/2 - x or 0
    y = self._isX and 0 or size[2]/2-y
    if speed then
        self:scrollBy(x,y,speed or 10)
    else
        self.view:moveAndScaleToCenter(1,x,y,0.1)
    end

    -- if self.isX then
    --     self:onEvent("scrollTo", basePosxy-pos[1]+self.oldpx, 0)
    --     bg:setPositionX(basePosxy-pos[1])
    -- else
    --     self:onEvent("scrollTo", 0, basePosxy-pos[2]+self.oldpy)
    --     bg:setPositionY(basePosxy-pos[2])
    -- end
end

function ViewScroll:setTableData(infos, callback)
    self._scrollInfos = infos
    self._scrollCallback = callback
    for _, info in ipairs(infos) do
        if type(info) == "table" then
            if self._setting.lazyViews[1].type == "node" then
                self._setting.lazyViews[1].type = "button"
            end
            local view = self:createItem(1)
            view.view:setTouchThrowProperty(true, true)
            self:addChild(view)
            info.layout = view
            view:loadViewsTo(info)

            callback(view, self.view, info)
        end
    end
end

function ViewScroll:setDatas(cellSetting)
    self.cellSetting = cellSetting
end

function ViewScroll:isVisible(cell,isnew)
    local x,y = cell:getPosition()
    local layout = self._setting.layout
    local csize = layout.csize or cell:getContentSize()
    if self._isX then
        local rx = x + self.oldpx
        return rx >= 0 and rx <= self.size[1] + csize[1]
    else
        if isnew and not layout.isX then
            local p = layout.padding or 0
            local off = {layout.ox or 0, layout.oy or 0}
            local rowmax = math.floor((self.size[2] - 2*p + off[2]) / ( csize[2] + off[2] ))
            local listMax = math.floor((self.size[1] - 2*p + off[1]) / ( csize[1] + off[1] ))
            return self.cellNum <= (rowmax+1)*listMax
        else
            local ry = y + self.oldpy
            return ry <= self.size[2]+csize[2] and ry >= -csize[2]
        end
    end
end

function ViewScroll:initCell(cell,isnew,forceInit)
    cell = cell or self.children[self.initedCellNum + 1]
    if forceInit or self:isVisible(cell,isnew) then
        self.initedCellNum = self.initedCellNum + 1
        cell:loadChildView()
        cell.inited = true

        local setting = self.cellSetting
        if setting then
            local info = setting.datas[self.initedCellNum]
            if info then
                cell:loadViewsTo(setting.viewToinfo and info or nil)
                if setting.target then
                    setting.cellUpdate(setting.target,cell,self,info)
                else
                    setting.cellUpdate(cell,self,info)
                end
            end
        end
    end
end

function ViewScroll:addCell(cell,forceInit)
    self:addChild(cell)
    self.cellNum = self.cellNum + 1

    self:initCell(cell,true,forceInit)
end

function ViewScroll:getCellIdx(cell)
    if not self.children or table.nums(self.children) == 0 then
        return
    end
    for i,v in ipairs(self.children) do
        if v==cell then
            return i
        end
    end
    return -1
end

function ViewScroll:removeCell(idx, clean)
    if not self.children or table.nums(self.children) then
        return
    end
    local cell = self.children[idx]
    if not cell then
        return
    end
    if cell.inited then
        self.initedCellNum = self.initedCellNum - 1
    end
    local cleanup = clean or true
    cell.view:removeFromParent(cleanup)
    table.remove(self.children, idx)
    self.cellNum = self.cellNum - 1
end

function ViewScroll:setSize(sx, sy)
    self.size = {sx, sy}
    self.view:setContentSize(sx, sy)
    self:setContentSize(self._csize[1], self._csize[2])
    self:onSizeChange()
end

function ViewScroll:clearAll()
    if self.children then
        for k, v in pairs(self.children) do
            v.view:removeFromParent()
        end
        self.children = {}
        self.oldpx=0
        self.oldpy=0
        self.cellNum = 0
        self.initedCellNum = 0
    end
end

function ViewScroll:getSize()
    return self.size
end

function ViewScroll:setContentSize(sx, sy)
    local osize = self.size
    if sx < osize[1] then
        sx = osize[1]
    end
    if sy < osize[2] then
        sy = osize[2]
    end
    self._csize = {sx, sy}
    self._view:setContentSize(sx, sy)
    self.view:setScrollContentRect(cc.rect(0, 0, sx, sy))
    local px, py = 0, 0
    -- 如果大小发生了变化，则坐标和大小变化保持一致即可
    if self._reuseMode then
        local _oldCsize = self._oldCsize
        self._oldCsize = self._csize
        if _oldCsize then
            px, py = self._view:getPosition()
            -- TODO 弄个动画会不会效果更好？
            self._view:setPosition(px, py + _oldCsize[2] - self._csize[2])
            return
        end
    end
    local layout = self._setting.layout
    if layout then
        if layout.dirx == 1 and sx < self.size[1] then
            px = self.size[1] - sx
        end
        if layout.diry == 1 then
            py = self.size[2] - sy
        end
    end
    self._view:setPosition(px, py)
end

function ViewScroll:getContentSize()
    return self._csize
end

-- 假设
function ViewScroll:getReuseCellByIdx(idx)
    if self._reuseMode > 0 then
        if idx <= self._reuseSkip then
            return self._noreuseChilds[idx]
        end
        idx = idx - self._reuseSkip
        return self._reuseChilds[((idx-1)%self._reuseMode)+1]
    end
end

-- 需要研究预计算\缓存使用；因为需要计缓存，因此infos必须是一个从基础数据上生成的可更改的list
-- 先考虑实现固定格式的重用，后续再考虑不同类型的重用
--[[
    V1.1 Extended in 2017/06/30 BY Lion
    增加了reuseSkip，表示该tableView前几个显示是特别的，不复用
    一般用于标题型单元格
    V1.2 Extended in 2017/07/21 BY Lion
    又增加了refreshOnly，表示该tableView的刷新只是增加或删除了几个节点，不需要滚到最开始
--]]
function ViewScroll:setLazyTableData(infos, callback, reuseMode, reuseSkip, refreshOnly)
    -- reuseMode 设置为0时，启用动态重用模式（大概是猜测复用节点？）；设置为大于0时为固定的复用跨度。
    -- 例如最多同时存在两个节点，则跨度设成2
    self._scrollInfos = infos
    self._infoLength = #infos
    self._scrollCallback = callback
    self._reuseSkip = reuseSkip or 0
    if not self._reuseChilds then
        self.view:setScriptHandler(Script.createCObjectHandler(self))
        self._reuseMode = reuseMode -- 如果为0的话就会在subResetLayout 里计算应有的值, 建议设置为32(手动滑稽2的几次方)
        self._reuseChilds = {}
        self._noreuseChilds = {}
    else
        -- 如果已经加过了，则快速重新加载一遍
        if self.children then
            for _, child in ipairs(self.children) do
                child._realIdx = 99999
            end
        end
        self:subResetLayout()

        if self._reuseMode > 0 and (self._infoLength <= #(self._reuseChilds) or self._reuseMode <= #(self._reuseChilds) and self._reuseSkip <= #(self._noreuseChilds)) then
            self._currentStartIdx = 0
            self._currentEndIdx = 0
            -- 滚到初始位置
            local px, py = 0, 0
            local mSize = self:getContentSize()
            local oldCenter = self:getCurCenterPos()
            if refreshOnly then
                px, py = oldCenter[1], oldCenter[2]
            else
                if self._isX then
                    px = 0 + self.size[1] / 2
                else
                    py = mSize[2] - self.size[2] / 2
                end
            end
            self:onEvent("scrollTo", oldCenter[1], oldCenter[2])
            self.view:moveAndScaleToCenter(1, px, py, 0.1)
            return
        end
    end

    local index = 1
    while index <= self._infoLength do
        local info = infos[index]
        info._idx = index
        local item = self:getReuseCellByIdx(index)
        if not item then
            item = self._scrollCallback(false, self, info, index)
            item._realIdx = index
            self:addChild(item)
        else
            self._scrollCallback(item, self, info, index)
            item._realIdx = index
        end
        if index <= self._reuseSkip then
            self._noreuseChilds[index] = item
        else
            self._reuseChilds[index - self._reuseSkip] = item
        end
        index = index + 1
        if index > self._reuseMode + self._reuseSkip then
            break -- (初始创建的数量吧应该是)
        end
    end
    self._currentStartIdx = 1
    self._currentEndIdx = index - 1
    self:onEvent("scrollTo", self._view:getPositionX(), self._view:getPositionY())
end

-- 强制刷新当前页展示项
-- mode大多数都是0怎么玩?
function ViewScroll:refreshLazyTable()
    if self._reuseMode > 0 then
        --刷新队列长度和当前视图结束索引
        if self._scrollInfos then
            self._infoLength = #self._scrollInfos
            local endIdx = self._currentStartIdx + self._reuseMode - 1
            if endIdx>self._infoLength then
                endIdx = self._infoLength
            end
            if self._currentEndIdx ~= endIdx then
                self._currentEndIdx = endIdx
            end
        end

        for i = self._currentStartIdx, self._currentEndIdx do
            local item = self:getReuseCellByIdx(i)
            if item and item._realIdx == i then
                self._scrollCallback(item, self, self._scrollInfos[i], i)
            end
        end
    end
end

-- 获取当前中心点的位置
function ViewScroll:getCurCenterPos()
    local px, py = self._view:getPosition()
    local size = self.size
    return {size[1]/2 - px, size[2]/2 - py}
end

-- 滚动到指定中心点
function ViewScroll:setCurCenterPos(pos)
    if pos then
        self.view:moveAndScaleToCenter(1, pos[1], pos[2], 0.1)
    end
end

-- 设置如果数量不超过范围就不滚动且居中的模式; 要先调用
function ViewScroll:setCenterScrollMode(mode)
    self._centerMode = mode
end

function ViewScroll:onEvent(event, px, py)

    if not self.children or table.nums(self.children)==0 then
        return
    end
    if event=="scrollTo" then
        if self._reuseMode and self._reuseMode > 0 then
            local layout = self._setting.layout
            local children = self.children
            if not children[1] then
                return true
            end
            local xmin, ymin, xmax, ymax
            xmin = -px
            ymin = -py
            local size = self:getContentSize()
            xmax = xmin + self.size[1]
            ymax = ymin + self.size[2]
            local cellSize = children[1].size

            local ltype = layout.ltype  --布局类型：0 none 1 horizon 2 vertical 3 grid
            local off = {layout.ox, layout.oy}  --spacex spacey
            local p = layout.padding  --边缘距离（缩进）
            local curStartIdx, curEndIdx
            local rowmin -- 跟_rowMax 互为行列表示(跟上面的不一样)
            if self._rollx == 1 then
                if layout.dirx == 0 then
                    rowmin = math.ceil((xmin-p+off[1])/(cellSize[1]+off[1]))
                else
                    rowmin = math.ceil((size[1]-xmax-p+off[1])/(cellSize[1]+off[1]))
                end
            else
                if layout.diry == 0 then
                    rowmin = math.ceil((ymin-p+off[2])/(cellSize[2]+off[2]))
                else
                    rowmin = math.ceil((size[2]-ymax-p+off[2])/(cellSize[2]+off[2]))
                end
            end
            if rowmin < 1 then
                rowmin = 1
            end
            curStartIdx = (rowmin-1) * self._rowmax + 1
            curEndIdx = curStartIdx + self._reuseMode - 1 -- 为什么curEndIdx 要比curStarIdx小?为保证后面的判断不出错?
            if curEndIdx > self._infoLength then
                curEndIdx = self._infoLength
                curStartIdx = curEndIdx - self._reuseMode + 1
                if curStartIdx < 1 then
                    curStartIdx = 1
                end
            end
            if curStartIdx ~= self._currentStartIdx or curEndIdx ~= self._currentEndIdx then
                self._currentStartIdx = curStartIdx
                self._currentEndIdx = curEndIdx
                for i = curStartIdx, curEndIdx do
                    local item = self:getReuseCellByIdx(i)
                    if item._realIdx ~= i then
                        self._scrollCallback(item, self, self._scrollInfos[i], i)
                        item._realIdx = i
                    end
                end
                self:resetLayout()
            end
            for _, child in ipairs(self.children) do
                local cpx, cpy = child:getPosition()
                local canchor = child:getAnchorPoint()
                local csize = child.size
                local _xmin = cpx - csize[1]*canchor.x
                local _xmax = cpx + csize[1]*(1-canchor.x)
                local _ymin = cpy - csize[2]*canchor.y
                local _ymax = cpy + csize[2]*(1-canchor.y)
                if child._realIdx > self._currentEndIdx or _xmin > xmax or _xmax < xmin or _ymin > ymax or _ymax < ymin then
                    child:setVisible(false)
                else
                    child:setVisible(true)
                end
            end
        else
            self.oldpx = px
            self.oldpy = py

            if self.initedCellNum<self.cellNum then
                self:initCell()
            end
            if self.cellSetting and self.cellSetting.scrollCall then
                self.cellSetting.scrollCall(self.cellSetting.target,px,py)
            end
        end
    elseif event=="scrollEnd" then
    end
    if self._onEventCallback then
        self._onEventCallback(event, px, py)
    end
    -- local childrenNum = #self.children
    -- local reuseNum = #self._reuseChilds
    -- local noreuseNum = #self._noreuseChilds
    -- dump({childrenNum, reuseNum, noreuseNum}, "hehehehheheheCheck")
end

function ViewScroll:setScrollCallback(callback)
    self._onEventCallback = callback
end

-- 重用的节点布局；当使用重用模式时，布局方法略有不同
-- 重用模式目前只支持固定宽高的布局
function ViewScroll:subResetLayout()
    if not self._reuseMode then
        return false
    end
    local layout = self._setting.layout
    local children = self.children
    if not children or not layout or layout.ltype == 0 then
        return true
    end
    if layout.resize ~= 1 then
        return false
    end
    local ltype = layout.ltype  --布局类型：0 none 1 horizon 2 vertical 3 grid
    local off = {layout.ox, layout.oy}  --spacex spacey
    local p = layout.padding  --边缘距离（缩进）
    if children[1] then
        local cellSize = children[1]:getContentSize()
        local rx = self._rollx
        local mSize = self.size
        if self._computedLength ~= self._infoLength then
            self._computedLength = self._infoLength

            local rows = math.ceil(self._infoLength / self._rowmax) --行或列数
            local ss = 2 * p + rows * cellSize[rx] + (rows - 1) * off[rx] --可变向size
            if ss < mSize[rx] then
                if self._centerMode then
                    self._extendPadding = (mSize[rx] - ss)/2
                    self.view:setElastic(false)
                end
                ss = mSize[rx]
            else
                if self._centerMode then
                    self._extendPadding = 0
                    self.view:setElastic(true)
                end
            end
            if self._reuseMode == 0 then
                self._reuseMode = self._rowmax * (1 + math.ceil((mSize[rx] - off[rx]) / (cellSize[rx] + off[rx])))
            end
            if rx == 1 then
                self:setContentSize(ss, mSize[2])
            else
                self:setContentSize(mSize[1], ss)
            end
        end
        mSize = self:getContentSize()
        local dx, dy = layout.dirx, layout.diry
        local epx, epy = 0, 0
        if rx == 1 then
            epx = self._extendPadding or 0
        else
            epy = self._extendPadding or 0
        end
        for i, child in ipairs(children) do
            local realIdx = child._realIdx
            local realX = math.ceil(realIdx/self._rowmax)
            local realY = ((realIdx - 1) % self._rowmax) + 1
            if rx == 2 then
                realX, realY = realY, realX
            end
            local canchor = child.view:getAnchorPoint()
            if dx then
                if dx == 0 then
                    child:setPositionX(p + epx + (realX-1) * (cellSize[1] + off[1]) + child.size[1] * canchor.x)
                else
                    child:setPositionX(mSize[1] - p - epx - (realX-1) * (cellSize[1] + off[1]) - child.size[1] * (1-canchor.x))
                end
            end
            if dy then
                if dy == 0 then
                    child:setPositionY(p + epy + (realY-1) * (cellSize[2] + off[2]) + child.size[2] * canchor.y)
                else
                    child:setPositionY(mSize[2] - p - epy - (realY-1) * (cellSize[2] + off[2]) - child.size[2] * (1-canchor.y))
                end
            end
        end
    end
    return true
end

function ViewButton:onCreate()
    local setting = self._setting
    self.size = {setting.sx, setting.sy}
    local bsetting
    if setting.back and (setting.back == "images/btnClose.png" or setting.back == "images/btnClose5.png") then
        local ms = 1.6
        self.size[1]=self.size[1]*ms
        self.size[2]=self.size[2]*ms
        bsetting = {image=nil, scale9edge=setting.s9edge, actionType=setting.actionType, priority=setting.pri}
        self.view = ui.button(self.size, nil, bsetting)
        local back = ui.sprite(setting.back,{setting.sx,setting.sy})
        display.adapt(back,(self.size[1])/2,(self.size[2])/2,GConst.Anchor.Center)
        self.view:getDrawNode():addChild(back)
    else
        bsetting = {image=setting.back or nil, scale9edge=setting.s9edge, actionType=setting.actionType, priority=setting.pri}
        self.view = ui.button(self.size, nil, bsetting)
    end
    self._view = self.view:getDrawNode()
    if setting.flip then
        if setting.flip=="X" then
            self.view:setFlippedX(true)
        elseif setting.flip=="Y" then
            self.view:setFlippedY(true)
        elseif setting.flip=="XY" then
            self.view:setFlippedX(true)
            self.view:setFlippedY(true)
        end
    end
    if setting.sound then
        self.view:setBackgroundSound(setting.sound)
    end
    self.priority = self.view:getTouchPriority()
end

function ViewButton:setEnable(enable)
    self.view:setEnable(enable)
end

function ViewButton:changePriority(value)
    self.view:setTouchPriority(self.priority+value)
end

function ViewButton:setGray(gray)
    self.view:setGray(gray)
end

function ViewButton:setScriptCallback(callback, ...)
    if type(callback)=="function" then
        callback = ButtonHandler(callback, ...)
    end
    if self.view then
        self.view:setScriptCallback(callback)
    end
end

function ViewButton:setAutoHoldTime(time)
    self.view:setAutoHoldTime(time)
end

function ViewButton:setAutoHoldTimeTemp(time)
    self.view:setAutoHoldTimeTemp(time)
end

function ViewButton:setHoldScriptCallback(callback, ...)
    if type(callback)=="function" then
        callback = ButtonHandler(callback, ...)
    end
    self.view:setHoldHandler(callback)
end

function ViewButton:setPriority(val)
    self.view:setTouchPriority(val)
end

function ViewButton:setControlScriptCallback(callback, ...)
    if type(callback)=="function" then
        callback = ButtonHandler(callback, ...)
    end
    self.view:setControlHandler(callback)
end

--对齐方式
local _viewLabelAligns = {Left=0, Center=1, Right=2}
function ViewLabel:ctor()
    self._isLeaf = true
end

function ViewLabel:onCreate()
    local setting = self._setting
    local width = setting.sx or setting.width
    local height = setting.sy or setting.height
    self._limitSize = {width or 0, height or 0}
	if not self._createrConfig then
	    local labelScale = ui.getUIScale2()
	    if labelScale>1 then labelScale=1 end
	    local align = 1
	    if setting.align then
	        align = _viewLabelAligns[setting.align]
	    end
	    if width then
	        width = math.ceil(width*labelScale)
	    end
	    if height then
	        height = math.ceil(height*labelScale)
	    end
	    local fsize = math.ceil(setting.size*labelScale)
	    if setting.type=="scrollLabel" then
	        self.view= ui.scrollLabel("", General[setting.font],fsize, {width=width,height=height,align=align,color=setting.color})
	        self.view:setAnchorPoint2(setting.anchorX,setting.anchorY)
	    else
	        local params = {width=width, align=align}
	        if setting.fontW and setting.fontH then
	            params.fontW=math.ceil(setting.fontW*labelScale)
	            params.fontH=math.ceil(setting.fontH*labelScale)
	        end
	        self.view = ui.label("", General[setting.font], fsize, params)
	    end
	    self.view:setScale(setting.size/fsize)
	else
	    local align = setting.align or 1
	    local valign = setting.valign or 1
	    local fsize = math.ceil(setting.size)
        self.fsize = fsize
        local lineHeight = setting.lineHeight or fsize
	    local fontId = setting.font
        self.fontId = fontId
	    local params = {width=width, align=align, valign=valign,lh = lineHeight}
	    local overflow = setting.overflow or 0
	    if overflow == 2 then
	        params.height = height
            params.lh = nil
            params.lh = setting.lineHeight or setting.size * 1.1
	    else
	        if overflow == 0 then
	            width = 0
	            params.width = 0
	            self._limitSize[1] = 0
                params.lh = nil
	        end
	        if overflow ~= 1 then
	            self._limitSize[2] = 0
	        end
            if overflow == 3 then
                -- 由于字体或者引擎的问题 导致游戏字体SHRINK 高度与预想大小不一样 暂做 间隔处理
                params.lh = setting.lineHeight or setting.size*1.1
            end
	    end
	    self.view = ui.label("", fontId, fsize, params)
	    if setting.outlineColor then
	        local cctab = setting.outlineColor
	        self.view:setOutlineColor(cc.c4b(cctab[1], cctab[2], cctab[3], cctab[4]))
	    end
	end

    self._view = self.view
    self._labelSize = {0, 0}
    self.size = {0, 0}
    if setting.text then
        self:setString(Localize(setting.text))
    end
    if setting.r then
        self.view:setRotation(setting.r)
    end
end

function ViewLabel:setString(text)
    local label = self._view
    if not label then
        return
    end
    label:setString(text)
    self:resetLabelSize()

end

function ViewLabel:getString()
    return self._view:getString()
end

function ViewLabel:setSize(sx, sy)
    self._limitSize = {sx, sy}
    local labelScale = ui.getUIScale2()
    if labelScale>1 then labelScale=1 end
    local label = self._view
    if label.setDimensions then
        if sy > 0 and self._setting.overflow ~= 2 then
            sy = 0
        end
        label:setDimensions(sx*labelScale, sy*labelScale)
    end
    self:resetLabelSize(true)
end

function ViewLabel:resetLabelSize()
    local label = self._view
    self._labelSize = {label:getContentSize().width*label:getScaleX(), label:getContentSize().height*label:getScaleY()}
    local size = self._labelSize
    local limit = self._limitSize
    self.size = {size[1], size[2]}
    local overflow = self._setting.overflow or 0
    if not self._createrConfig or overflow == 1 then
        if limit[2]>0 and limit[2]<size[2] then
            self.size[2] = limit[2]
            --需要滚动
            if not self._inScroll then
                local scroll = ui.scrollNode(limit, self._setting.inScroll and -1 or 4, false, true, {scroll=true, clip=true, elastic=true, rect={0, 0, limit[1], size[2]}})
                local x, y = label:getPosition()
                local z = label:getLocalZOrder()
                local anchor = label:getAnchorPoint()
                scroll:setAnchorPoint(anchor)
                scroll:setPosition(x, y)
                scroll:setLocalZOrder(z)
                scroll:setScaleEnable(false, 1, 1, 1, 1)
                label:retain()
                local parent = label:getParent()
                if parent then
                    label:removeFromParent(false)
                    parent:addChild(scroll)
                end
                label:setPosition(0, 0)
                label:setAnchorPoint(GConst.Anchor.LeftBottom)
                scroll:getScrollNode():addChild(label)
                scroll:getScrollNode():setPosition(0, limit[2] - size[2])
                label:release()
                self.view = scroll
                self._inScroll = true
                scroll:setTouchThrowProperty(true, true)
            else
                self.view:setScrollContentRect(cc.rect(0, 0, size[1], size[2]))
                self.view:getScrollNode():setPosition(0, limit[2] - size[2])
            end
        else
            if self._inScroll then
                local x, y = self.view:getPosition()
                local z = self.view:getLocalZOrder()
                local anchor = self.view:getAnchorPoint()
                label:retain()
                label:removeFromParent(false)
                label:setAnchorPoint(anchor)
                label:setPosition(x, y)
                label:setLocalZOrder(z)
                local parent = self.view:getParent()
                if parent then
                    parent:addChild(label)
                    self.view:removeFromParent(true)
                end
                label:release()
                self.view = label
                self._inScroll = nil
            end
        end
    end
    self:onSizeChange()
    -- local debugNode = ui.colorNode(self.size, {255, 0, 0, 100})
    -- display.adapt(debugNode, 0, 0, GConst.Anchor.LeftBottom)
    -- self.view:addChild(debugNode)
end

function ViewImage:ctor()
    self._isLeaf = true
end

function ViewImage:onCreate()
    self:resetImage()
end

function ViewImage:resetImage()
    local setting = self._setting
    local size = nil
    if setting.sx and setting.sy then
        size = {setting.sx, setting.sy}
    end
    --预留接口改变图片文字语言
    local img = setting.image;
    if setting.language and General.language ~= "CN" and General.language ~= "HK" then
        local endIdx = string.find(img,".png")
        img = string.sub(img,1,endIdx-1).."_"..General.language..".png"
        size = nil;
    end
    if setting.plist then
        local frame = memory.getFrame(img,true)
        if not frame then
            memory.loadSpriteSheet(setting.plist)
        end
    end
    if setting.s9edge and (type(setting.s9edge) == "table" or setting.s9edge>0) then
        self._isScale9 = true
        self.view = ui.scale9(img, setting.s9edge, size)
    else
        self._isScale9 = false
		if not self._createrConfig and _viewTemplateFunc then
            self.view = _viewTemplateFunc("image", setting.image, size)
        else
            self.view = ui.sprite(img, size, nil, setting.lazy)
        end
        if not self.view then
            if setting.repeatMode then
                self.view = ui.sprite(img)
                local texture = self.view:getTexture()
                texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.REPEAT, gl.REPEAT)
                self.view:setTextureRect(cc.rect(0, 0, size[1], size[2]))
            else
                self.view = ui.sprite(img, size, nil, setting.lazy)
            end
        end
        if setting.flip then
            if setting.flip=="X" then
                self.view:setFlippedX(true)
            elseif setting.flip=="Y" then
                self.view:setFlippedY(true)
            end
        end
    end
    if setting.custom then
        for _, custom in ipairs(setting.custom) do
            self.view:setCustomPoint(custom[1], custom[2], custom[3], custom[4], custom[5])
        end
    end
    if setting.r then
        self.view:setRotation(setting.r)
    end
    if setting.hvalue then
        self.view:setHValue(setting.hvalue)
    end
    if setting.svalue then
        self.view:setSValue(setting.svalue)
    end
    if setting.lvalue then
        self.view:setLValue(setting.lvalue)
    end
    if size then
        self.size = size
    else
        self.size = {self.view:getContentSize().width, self.view:getContentSize().height}
    end
end

function ViewImage:getImage()
    return self._setting.image
end

function ViewImage:setImage(img, edge, sx, sy, keepScale)
    local setting = self._setting
    --预留接口改变图片文字语言
    if setting.language and General.language ~= "CN" and General.language ~= "HK" then
        local endIdx = string.find(img,".png")
        img = string.sub(img,1,endIdx-1).."_"..General.language..".png"
    end

    setting.image = img
    setting.s9edge = edge
    local schange = false
    if sx and sy then
        setting.sx = sx
        setting.sy = sy
        self.size = {sx, sy}
        schange = true
    end
    if (edge or 0)==0 and not self._isScale9 then
        ui.setFrame(self.view, img)
        self.view:setScaleContentSize(self.size[1], self.size[2], keepScale or false)
    else
        local oview = self.view
        self:resetImage()
        if oview then
            local x, y = oview:getPosition()
            local anchor = oview:getAnchorPoint()
            local z = oview:getLocalZOrder()
            local parent = oview:getParent()
            self.view:setAnchorPoint(anchor)
            self.view:setPosition(x, y)
            self.view:setLocalZOrder(z)
            if parent then
                oview:removeFromParent(true)
                parent:addChild(self.view)
            end
        end
    end
    self:onSizeChange()
end

-- 用于更换同一设计规格但尺寸不同的图片；该模式不适用scale9，因为scale9是没有设计尺寸这个概念的
function ViewImage:setImageKeepScale(img)
    local setting = self._setting

    --获取较大的一个scale
    local oscalex = self.view:getScaleX()
    local oscaley = self.view:getScaleY()
    if oscalex < oscaley then
        oscalex = oscaley
    end
    ui.setFrame(self.view, img)
    self.view:setScale(oscalex)
    local csize = self.view:getContentSize()
    self.size[1] = csize.width * oscalex
    self.size[2] = csize.height * oscalex
    self:onSizeChange()
end

function ViewImage:setSize(sx, sy)
    self.size = {sx, sy}
    if self._isScale9 then
        self.view:setContentSize(sx, sy)
    else
        self.view:setScaleContentSize(sx, sy, false)
    end
    self:onSizeChange()
end

function ViewImage:setScaleProcess(isX, process)
    if process<0 then
        process = 0
    elseif process>1 then
        process = 1
    end
    if isX then
        self.view:setScaleX(self.size[1]*process/self.view:getContentSize().width)
    else
        self.view:setScaleY(self.size[2]*process/self.view:getContentSize().height)
    end
end

function ViewImage:setProcess(isX, process)
    if self._isScale9 then
        self:setScaleProcess(isX, process)
    else
        self.view:setProcess(isX, process)
    end
end



function ViewLayout:onCreate()

end

function ViewLayout:onLifeCycle(event)
    if event=="enter" then
        self.deleted = nil
        self:onEnter()
    elseif event=="exit" then
        if self.reuse then
            return
        end
        self.deleted = true
        self:onExit()
    elseif event=="cleanup" then
        -- if self.isHeroPage then
        --     log.e(debug.traceback())
        -- end
        if self.reuse then
            return
        end
        self.deleted = true
        self:onDestroy()
        local layouts = self._layouts
        if layouts then
            for k, v in pairs(layouts) do
                layouts[k] = nil
                v:cleanup()
            end
        end
    end
end

function ViewLayout:onEnter()
end

function ViewLayout:onExit()
end

function ViewLayout:onDestroy()
end

function ViewLayout:setLayout(configName)
    local config
    if type(configName)=="string" then
        config = GMethod.loadConfig(configDir .. configName)
    else
        config = configName
    end
    --log.d("loadconfig:%s",configDir .. configName)
    local rawView
    if config then
        self._createrConfig = config.createrConfig
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
            if not self._createrConfig then
                display.adapt(rawView, 0, 0, GConst.Anchor.LeftBottom)
            else
                display.adapt(rawView, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
            end
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
        if config.template and _viewTemplateFunc then
            _viewTemplateFunc(self, config.template, config)
        end
        if config.views then
            self:_addViews(config.views)
        end
        self:loadViewsTo()
    else
        log.e("Couldn't find config:%s", configName)
    end
end

function ViewLayout:loadView(view, size, onLife)
    self.size = size
    self.view = view
    self._layouts = {}
    if onLife then
        RegLife(self.view, Handler(self.onLifeCycle, self))
    end
end

function ViewLayout:setInScroll(inScroll)
    self._inScroll = inScroll
end


function ViewLayout:addLayout(configName, toView)
    local config = nil
    if self._config then
        config = self._config[configName]
    end

    if not config then
        if not configName:find(".json") then
            configName = configName .. ".json"
        end
        config = GMethod.loadConfig(configDir .. configName)
    end


    if config then
        self._createrConfig = config.createrConfig
        local views = config.views or config
        if toView then
            local newLayout = ViewLayout.new()
            if config.isCell then
                newLayout:setInScroll(true)
            end
            local rawSize = toView:getContentSize()
            local size = {rawSize.width, rawSize.height}
            newLayout:loadView(toView, size, true)
            newLayout:_addViews(views)
            return newLayout
        else
            self:_addViews(views)
        end
    else
        log.e("Couldn't find config:%s", configName)
    end
end

function ViewLayout:getConfig(k)
    return self._config[k]
end

--一个通过json文件添加特效的控制器
EffectControl = class()
local _effectConfigPath = "configs/effects/"

function EffectControl:ctor(configFile, params)
    if not configFile:find(".json") then
        configFile = configFile .. ".json"
    end
    self.config = GMethod.loadConfig(_effectConfigPath .. configFile)
    self.params = params
end

function EffectControl:addEffect(bg)
    self.bg=bg
    local params = self.params or {}
    local config = self.config
    for i,item in ipairs(self.config) do
        -- dump(item.type)
        local view
        if item.type=="image" then
            view = self:addImageEffect(item)
        elseif item.type=="particle" then
            view = self:addParticleEffect(item)
        elseif item.type=="animate" then
            view = self:addAnimateEffect(item)
        elseif item.type == "node" then
            view = self:addNodeEffect(item)
        elseif item.type == "csb" then
            view = self:addCsbEffect(item)
        end
        view:setAnchorPoint(item.ax or 0.5, item.ay or 0.5)
        view:setPosition((item.x or 0)+(params.x or 0), (item.y or 0)+(params.y or 0))
        view:setRotation((item.r or 0)+(params.r or 0))
        view:setScaleX((item.scale or item.scaleX or 1)*(params.scale or params.scaleX or 1))
        view:setScaleY((item.scale or item.scaleY or 1)*(params.scale or params.scaleY or 1))
        bg:addChild(view, (item.z or 0)+(params.z or 0))
        if item.blend then
            ui.setBlend(view, item.blend)
        end
        if item.visible then
            view:setVisible(item.visible)
        end
        if item.action then
            view:runAction(ui.action.action(item.action))
        end
        if item.csbAction then
            view:runAction(item.csbAction)
            item.csbAction:gotoFrameAndPlay(0, false)
        end
        if item.gz then
            view:setGlobalZOrder(item.gz)
        end
    end
    self.params = params
    self.config = config
end
function EffectControl:addImageEffect(item)
    local temp
    if item.sx and item.sy then
        temp=ui.sprite(item.image or item.resPath,{item.sx,item.sy})
    else
        temp=ui.sprite(item.image or item.resPath)
    end
    if item.color then
        ui.setColor(temp,item.color)
    end
    if item.opacity then
        temp:setOpacity(item.opacity)
    end
    return temp
end
function EffectControl:addParticleEffect(item)
    local temp
    if item.plist or item.resPath then
        temp=cc.ParticleSystemQuad:create(item.plist or item.resPath)
    elseif item.json then
        temp= ui.particle(item.json,item.jsonParams)
    end
    return temp
end
function EffectControl:addAnimateEffect(item)                    --帧动画
    local temp = ui.animateSprite(item.time,params.name or item.name,item.frames,item.tab)
    return temp
end

function EffectControl:addNodeEffect(item)
    local temp = ui.node()
    if item.views then
        self.params = nil
        self.config = item.views
        self:addEffect(temp, self)
    end
    return temp
end

function EffectControl:addCsbEffect(item)
    local temp = ui.csbNode("UICsb/"..item.csb)
    local action = ui.csbTimeLine("UICsb/"..item.csb)
    item.csbAction = action
    return temp
end
