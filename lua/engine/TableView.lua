local function squeeze(value, min, max)
    if min and value<min then
        return min
    elseif max and value>max then
        return max
    else
        return value
    end
end

local TableView = {}
TableView.__index = TableView

function TableView:addItem(node, setting)
    local params = setting or {}
    local offx, offy = params.offx or 0, params.offy or 0
    local disx, disy = params.disx or 0, params.disy or 0
    local index = (params.index  or 1) - 1
    local rowmax = params.rowmax or 1

    local off, length, endoff = 0, 0, 0
    local nsize = node:getContentSize()

    local x, y = 0, 0
    if self.isX then
        x = math.floor(index / rowmax) * (nsize.width + disx)
        y = (index % rowmax) * (nsize.height + disy)
        off = offx + x
        length = nsize.width
        endoff = disx/2
    else
        x = (index % rowmax) * (nsize.width + disx)
        y = math.floor(index / rowmax) * (nsize.height + disy)
        off = offy + y
        length = nsize.height
        endoff = disy/2
    end
    display.adapt(node, offx + x + nsize.width/2, self.view:getContentSize().height-(y + offy + nsize.height/2), GConst.Anchor.Center)
    node:setVisible(false)
    self.bg:addChild(node)
    local newItem = {off = off, length = length, endoff = endoff, view = node}
    self.items[1 + #self.items] = newItem
end

function TableView:prepare()
    local items = self.items
    local size = self.size
    local bg = self.bg
    local state = self.state

    local rectmin, rectmax = 0, 0
    if self.isX then
        self.off_max = 0
        rectmin = -bg:getPositionX()
        rectmax = rectmin + size[1]
    else
        self.off_min = 0
        rectmin = bg:getPositionY()
        rectmax = rectmin+size[2]
    end
    if not self.delayInitCell then
        table.sort(items, getSortFunction("off"))
        local itemsNum = #items
        local lastItem = items[itemsNum]
        if lastItem == nil then
            lastItem = {off=0, length=0, endoff=0}
        end
        -- if self.isX then
        --     self.off_min = squeeze(size[1] - (lastItem.off + lastItem.length + lastItem.endoff), nil, self.off_max)
        --     self.view:setScrollContentRect(cc.rect(0,0,size[1]-self.off_min,size[2]))
        -- else
        --     self.off_max = squeeze(lastItem.off + lastItem.length + lastItem.endoff - size[2], self.off_min)
        --     self.view:setScrollContentRect(cc.rect(0,-self.off_max,size[1],self.off_max+size[2]))
        -- end
        local index = 1
        while index<=itemsNum do
            local item = items[index]
            if item.off + item.length >= rectmin and item.off < rectmax then
                item.view:setVisible(true)
                if not state.first then state.first = index end
                state.last = index
            end
            index = index + 1
        end
        if #items == 0 then
            self.movable = false
        end
    else
        self.dataInitedLength = 0
        local index = 1
        local lastItem = {off=0, length=0, endoff=0}
        while index<=self.dataLength do
            local item = self:initCell(index)
            lastItem = item
            self.dataInitedLength = index
            if item.off + item.length < rectmin then
                item.view:setVisible(false)
            elseif item.off<rectmax then
                item.view:setVisible(true)
                if not state.first then state.first = index end
                state.last = index
            else
                item.view:setVisible(false)
                break
            end
            index = index + 1
        end

        -- if self.isX then
        --     self.off_min = squeeze(size[1] - (lastItem.off + lastItem.length + lastItem.endoff), nil, self.off_max)
        --     self.view:setScrollContentRect(cc.rect(0,0,size[1]-self.off_min,size[2]))
        -- else
        --     self.off_max = squeeze(lastItem.off + lastItem.length + lastItem.endoff - size[2], self.off_min)
        --     self.view:setScrollContentRect(cc.rect(0,-self.off_max,size[1],self.off_max+size[2]))
        -- end
        self.movable = (self.dataLength>0)
    end

end

function TableView:refreshItem(direction, rectmin, rectmax)
    local items = self.items
    local state = self.state
    local maxItem = nil
    if direction == -1 then
        while state.first<=#items and items[state.first].off + items[state.first].length < rectmin do
			if self.Cell[state.first] then
				items[state.first].view:setVisible(false)
			end
            state.first = state.first + 1
        end
        while state.last+1<=#items and items[state.last+1].off < rectmax do
			if self.Cell[state.last+1] then
				items[state.last+1].view:setVisible(true)
			end
            state.last = state.last + 1
        end
        if self.delayInitCell then
            while self.dataInitedLength<self.dataLength and state.last==self.dataInitedLength do
                self.dataInitedLength = self.dataInitedLength+1
                local item
                if self.items[self.dataInitedLength] then
                    item = self.items[self.dataInitedLength]
                else
                    item = self:initCell(self.dataInitedLength)
                end
                if item.off<rectmax then
                    item.view:setVisible(true)
                    state.last = state.last + 1
                else
                    item.view:setVisible(false)
                end
            end
        end
        maxItem = self.items[self.dataInitedLength]
    else
        while state.first-1>0 and items[state.first-1] and items[state.first-1].off + items[state.first-1].length > rectmin do
            if self.Cell[state.first-1] then
                items[state.first-1].view:setVisible(true)
            end
            state.first = state.first - 1
        end
        while state.last>0 and items[state.last] and items[state.last].off > rectmax do
            if self.Cell[state.last] then
                items[state.last].view:setVisible(false)
            end
            state.last = state.last - 1
        end
        maxItem = self.items[self.dataLength]
    end
    -- if maxItem then
    --     if self.isX then
    --         self.off_min = squeeze(self.size[1] - (maxItem.off + maxItem.length + maxItem.endoff), nil, self.off_max)
    --         self.view:setScrollContentRect(cc.rect(0,0,self.size[1]-self.off_min,self.size[2]))
    --     else
    --         self.off_max = squeeze(maxItem.off + maxItem.length + maxItem.endoff - self.size[2], self.off_min)
    --         self.view:setScrollContentRect(cc.rect(0,-self.off_max,self.size[1],self.off_max+self.size[2]))
    --     end
    -- end
end

function TableView:onEvent(event, px, py)
    if #(self.datas)==0 then
        return
    end
    if event=="scrollTo" then
        --供外部使用
        if self.cellSetting.scrollToCall then
            self.cellSetting.scrollToCall(px,py)
        end
        --if off == 0 then return end
        local rectmin, rectmax, direction = 0, 0, 1
        local bg = self.bg
        local size = self.view:getContentSize()
        if self.isX then
            rectmin = -px
            rectmax = rectmin + size.width
            if px<self.oldpx then direction = -1 end
        else
            rectmin = py
            rectmax = rectmin + size.height
            if py>self.oldpy then direction = -1 end
        end
        self.oldpx = px
        self.oldpy = py
        self:refreshItem(direction, rectmin, rectmax)
    elseif event=="scrollEnd" then
        if self.xy then--设置了定位
            self:_location()
        end
    end
end
--设置定位,TableView锚点为LeftBootm
function TableView:setLocation(xy)
   self.xy=xy
   local size = self.size
   local lastItem=self.rectItems[self.dataLength]
    if self.isX then
        self.off_min = squeeze(size[1] - (lastItem.off + lastItem.length + lastItem.endoff), nil, self.off_max)
        self.view:setScrollContentRect(cc.rect(-xy,0,size[1]-self.off_min+2*xy,size[2]))
    else
        self.off_max = squeeze(lastItem.off + lastItem.length + lastItem.endoff - size[2], self.off_min)
        self.view:setScrollContentRect(cc.rect(0,-self.off_max-xy,size[1],self.off_max+size[2]+xy))
    end
end
--起始定位到那个cell
function TableView:startLocation(i)
    if not self.xy then
        log.e("please call setLocation")
        return
    end

    local item=self.rectItems[i]
    local scrXY=item.off+item.length/2

    local bg=self.bg
    --local cell=self.Cell[i]
    --local pos={bg:getPositionX()+cell:getPositionX(),bg:getPositionY()+cell:getPositionY()}
    local itemPos=self.rectItems[i]
    local pos={itemPos.off+itemPos.length/2,self.view:getContentSize().height-(itemPos.off + itemPos.length/2)}
    local basePosxy=self.xy

    if self.isX then
        self:onEvent("scrollTo", basePosxy-pos[1]+self.oldpx, 0)
        bg:setPositionX(basePosxy-pos[1])
    else
        self:onEvent("scrollTo", 0, basePosxy-pos[2]+self.oldpy)
        bg:setPositionY(basePosxy-pos[2])
    end
end

function TableView:locationByI(i,isOut)
    if not self.xy then
        log.e("please call setLocation")
        return
    end
    local bg=self.bg
    local cell=self.Cell[i]
    local pos={bg:getPositionX()+cell:getPositionX(),bg:getPositionY()+cell:getPositionY()}
    local basePosxy=self.xy
    local moveSpeed=1200
    local moveL
    local function callEnd()
        if self.cellSetting.locationEnd then
            self.cellSetting.locationEnd(i)
        end
    end
    if self.isX then
        moveL=basePosxy-pos[1]
        local function callScroll( ... )
            if isOut then
                self:onEvent("scrollTo", moveL+self.oldpx, 0)
            end
        end
        local dt=0
        if moveL<0 then
            dt=math.abs(moveL/moveSpeed)
        end
        bg:runAction(ui.action.sequence({{"delay",dt/2},{"call",callScroll}}))
        bg:runAction(ui.action.sequence({{"moveBy",math.abs(moveL/moveSpeed),moveL,0},{"call",callEnd}}))
    else
        moveL=basePosxy-pos[2]
        local function callScroll( ... )
            if isOut then
                self:onEvent("scrollTo", 0, moveL+self.oldpy)
            end
        end
        local dt=0
        if moveL>0 then
            dt=math.abs(moveL/moveSpeed)
        end
        bg:runAction(ui.action.sequence({{"delay",dt/2},{"call",callScroll}}))
        bg:runAction(ui.action.sequence({{"moveBy",math.abs(moveL/moveSpeed),0,moveL},{"call",callEnd}}))
    end
end

function TableView:_location()
    local bg=self.bg
    local basePosxy=self.xy
    local cellSetting = self.cellSetting
    local i
    local offxy
    if self.isX then
        offxy=cellSetting.size.width+cellSetting.disx
    else
        offxy=cellSetting.size.height+cellSetting.disy
    end
    for k,cell in pairs(self.Cell) do
        local pos={bg:getPositionX()+cell:getPositionX(),bg:getPositionY()+cell:getPositionY()}
        local oxy
        if self.isX then
           oxy=math.abs(basePosxy-pos[1])
        else
           oxy=math.abs(basePosxy-pos[2])
        end
        if oxy<offxy then
            offxy=oxy
            i=k
        end
    end
    self:locationByI(i)
end

function TableView:moveView(dir,px, py)  --按钮调用

        local rectmin, rectmax, direction = 0, 0, 1
        local bg = self.bg
        local size = self.view:getContentSize()
        if self.isX then
            rectmin = -px
            rectmax = rectmin + size.width
            if px<self.oldpx then direction = -1 end
        else
            rectmin = py
            rectmax = rectmin + size.height
            if py>self.oldpy then direction = -1 end
        end
        self.oldpx = px
        self.oldpy = py
        self:refreshItem(direction, rectmin, rectmax)

        local size=self.cellSetting.size
        local moveL
        if self.isX then
            moveL=size.width
            bg:runAction(ui.action.moveBy(0.4,moveL,0))
        else
            moveL=size.height
            bg:runAction(ui.action.moveBy(0.4,0,moveL))
        end
end

function TableView.new(size, isX, priority,actionType)
    local scrollView = ScrollNode:create(cc.size(size[1], size[2]), priority or 0, isX, not isX)
    scrollView:setScrollEnable(true)
    scrollView:setInertia(true)
    scrollView:setClip(true)
    scrollView:setElastic(true)
    scrollView:setScaleEnable(false,1,1,1,1)

    local off_min, off_max = 0, 0
    local state = {}
    local items = {}
    local self = {view = scrollView, bg=scrollView:getScrollNode(), items=items, state=state, off_max=off_max, off_min=off_min, isX=isX, movable=true, oldpx=0, oldpy=0}
    setmetatable(self, TableView)
    scrollView:setScriptHandler(Script.createCObjectHandler(self))
    scrollView:setScrollContentRect(cc.rect(0,0,size[1],size[2]))
    self.size = size
    self.isX=isX
    self.Cell={}
    self.cellActionType = actionType
    return self
end

function TableView:initCell(dindex)
    if dindex>=1 and dindex<=self.dataLength then
        local data = self.datas[dindex]
        local cellSetting = self.cellSetting
        while data.isNewLine do
            cellSetting.offx = cellSetting.offx + (data.offx or 0)
            cellSetting.offy = cellSetting.offy + (data.offy or 0)
            table.remove(self.datas, dindex)
            self.dataLength = self.dataLength-1
            data = self.datas[dindex]
        end
        local cell = ButtonNode:create(cellSetting.size, 0, self.action or self.cellActionType or 1)
        cell:setTouchThrowProperty(true, true)
        cellSetting.cellUpdate(cell, self, data)
        table.insert(self.Cell,cell)
        local offx, offy = cellSetting.offx, cellSetting.offy
        local disx, disy = cellSetting.disx, cellSetting.disy
        local index = cellSetting.beginIndex +dindex - 1
        local rowmax = cellSetting.rowmax

        local off, length, endoff = 0, 0, 0
        local nsize = cellSetting.size

        local x, y = 0, 0
        if cellSetting.sizeChange then
            nsize = cell:getContentSize()
            local lastItem = self.items[dindex-1] or {length=0}
            if self.isX then
                x = (lastItem.off or cellSetting.offx) + lastItem.length - cellSetting.offx + cellSetting.disx
                y = 0
                off = cellSetting.offx + x
                length = nsize.width
                endoff = cellSetting.disx/2
            else
                x = 0
                y = (lastItem.off or cellSetting.offy) + lastItem.length - cellSetting.offy + cellSetting.disy
                off = cellSetting.offy + y
                length = nsize.height
                endoff = cellSetting.disy/2
            end
        else
            if self.isX then
                x = math.floor(index / rowmax) * (nsize.width + cellSetting.disx)
                y = (index % rowmax) * (nsize.height + cellSetting.disy)
                off = cellSetting.offx + x
                length = nsize.width
                endoff = cellSetting.disx/2
            else
                x = (index % rowmax) * (nsize.width + cellSetting.disx)
                y = math.floor(index / rowmax) * (nsize.height + cellSetting.disy)
                off = cellSetting.offy + y
                length = nsize.height
                endoff = cellSetting.disy/2
            end
        end
        if self.initAni then
            if self.isX then
                display.adapt(cell, cellSetting.offx + x + nsize.width/2 + (self.cellSetting.size.width+self.cellSetting.disx), self.view:getContentSize().height-(y + cellSetting.offy + nsize.height/2), GConst.Anchor.Center)
                cell:runAction(ui.action.moveBy(0.25,-(self.cellSetting.size.width+self.cellSetting.disx),0))
            else
                display.adapt(cell, cellSetting.offx + x + nsize.width/2, self.view:getContentSize().height-(y + cellSetting.offy + nsize.height/2) - (self.cellSetting.size.height+self.cellSetting.disy), GConst.Anchor.Center)
                cell:runAction(ui.action.moveBy(0.25,0,(self.cellSetting.size.height+self.cellSetting.disy)))
            end
        else
            display.adapt(cell, cellSetting.offx + x + nsize.width/2, self.view:getContentSize().height-(y + cellSetting.offy + nsize.height/2), GConst.Anchor.Center)
        end
        self.bg:addChild(cell)
        local newItem = {off = off, length = length, endoff = endoff, view = cell}
        self.items[dindex] = newItem
        return newItem
    end
end
function TableView:initScrollContentRect(dindex)
    if dindex>=1 and dindex<=self.dataLength then
        local cellSetting = self.cellSetting
        local offx, offy = cellSetting.offx, cellSetting.offy
        local disx, disy = cellSetting.disx, cellSetting.disy
        local index = cellSetting.beginIndex +dindex - 1
        local rowmax = cellSetting.rowmax

        local off, length, endoff = 0, 0, 0
        local nsize = cellSetting.size

        local x, y = 0, 0
        if cellSetting.sizeChange then
            local lastItem = self.rectItems[dindex-1] or {length=0}
            if self.isX then
                x = (lastItem.off or cellSetting.offx) + lastItem.length - cellSetting.offx + cellSetting.disx
                y = 0
                off = cellSetting.offx + x
                length = nsize.width
                endoff = cellSetting.disx/2
            else
                x = 0
                y = (lastItem.off or cellSetting.offy) + lastItem.length - cellSetting.offy + cellSetting.disy
                off = cellSetting.offy + y
                length = nsize.height
                endoff = cellSetting.disy/2
            end
        else
            if self.isX then
                x = math.floor(index / rowmax) * (nsize.width + cellSetting.disx)
                y = (index % rowmax) * (nsize.height + cellSetting.disy)
                off = cellSetting.offx + x
                length = nsize.width
                endoff = cellSetting.disx/2
            else
                x = (index % rowmax) * (nsize.width + cellSetting.disx)
                y = math.floor(index / rowmax) * (nsize.height + cellSetting.disy)
                off = cellSetting.offy + y
                length = nsize.height
                endoff = cellSetting.disy/2
            end
        end
        local newItem = {off = off, length = length, endoff = endoff}
        self.rectItems[dindex] = newItem

        local size = self.size
        if self.isX then
            self.off_min = squeeze(size[1] - (newItem.off + newItem.length + newItem.endoff), nil, self.off_max)
            self.view:setScrollContentRect(cc.rect(0,0,size[1]-self.off_min,size[2]))
            self.maxLength = -self.off_min
        else
            self.off_max = squeeze(newItem.off + newItem.length + newItem.endoff - size[2], self.off_min)
            self.view:setScrollContentRect(cc.rect(0,-self.off_max,size[1],self.off_max+size[2]))
            self.maxLength = self.off_max
        end
    end
end

function TableView:moveViewTo(dir,dis,speed)
    local size = self.size
    local bg = self.bg
    local maxLength = self.maxLength
    if not maxLength then
        return
    end
    if self.isX then
        dis = dis or size[1]*0.9
        dis = dis * dir
        local movedis = self.oldpx + dis
        if movedis>0 then
            local d = movedis
            dis = dis - d
        elseif movedis < -maxLength then
            local d = maxLength + movedis
            dis = dis - d
        end
        local function callScroll( ... )
            self:onEvent("scrollTo", dis+self.oldpx, 0)
        end
        local dt = 0.01
        if speed then
            dt = math.abs(dis/speed)
        end
        bg:runAction(ui.action.sequence({{"moveBy",dt,dis,0},{"call",callScroll}}))
    else
        dis = dis or size[2]*0.8
        dis = dis*dir
        local movedis = self.oldpy+dis
        if movedis<0 then
            dis = dis-movedis
            movedis = 0
        elseif movedis>maxLength then
            local d = movedis-maxLength
            dis = dis-d
            movedis = maxLength
        end
        local function callScroll( ... )
            self:onEvent("scrollTo", 0, movedis)
        end
        local dt = 0.01
        if speed then
            dt = math.abs(dis/speed)
        end
        bg:runAction(ui.action.sequence({{"moveBy",dt,0,dis},{"call",callScroll}}))
    end
end

function TableView:setDatas(cellSetting)
    self.cellSetting = cellSetting
    self.datas = cellSetting.infos
    self.dataLength = #(cellSetting.infos)
    self.delayInitCell = true

    cellSetting.beginIndex = cellSetting.beginIndex or 0
    cellSetting.offx = cellSetting.offx or 0
    cellSetting.offy = cellSetting.offy or 0
    cellSetting.disx = cellSetting.disx or 0
    cellSetting.disy = cellSetting.disy or 0
    cellSetting.rowmax = cellSetting.rowmax or 1

    self.rectItems={}
    for i=1,self.dataLength do
        self:initScrollContentRect(i)
    end
end

function TableView:removeCell(dindex)
	if self.Cell[dindex] then
	    self.Cell[dindex]:removeFromParent(true)
        table.remove(self.Cell, dindex)
        table.remove(self.items, dindex)
    end
    table.remove(self.datas, dindex)
    self.dataLength = self.dataLength-1
    self.dataInitedLength=self.dataInitedLength-1
    if dindex<=self.state.last then
        self.state.last = self.state.last-1
    end
    if dindex<self.state.first then
        self.state.first = self.state.first-1
    end
	for i=dindex, self.dataLength do
		if self.Cell[i] then
			if self.isX then
                self.Cell[i]:runAction(ui.action.moveBy(0.25,-(self.cellSetting.size.width+self.cellSetting.disx),0))
                self.items[i].off = self.items[i].off-(self.cellSetting.size.width+self.cellSetting.disx)
			else
				self.Cell[i]:runAction(ui.action.moveBy(0.25,0,(self.cellSetting.size.height+self.cellSetting.disy)))
                self.items[i].off = self.items[i].off-(self.cellSetting.size.height+self.cellSetting.disy)
			end
		end
	end
    local rectmin, rectmax, direction = 0, 0, 1
    local bg = self.bg
    local size = self.view:getContentSize()
    if self.isX then
        rectmin = -self.oldpx
        rectmax = rectmin + size.width
    else
        rectmin = self.oldpy
        rectmax = rectmin + size.height
    end
    self.initAni = true
    self:refreshItem(-1, rectmin, rectmax)
    self:refreshItem(1, rectmin, rectmax)
    self.view:moveAndScaleToCenter(1,size.width/2-self.oldpx,size.height/2-self.oldpy, 0.25)
    self.initAni = nil
    self:initScrollContentRect(self.dataLength)
end

function TableView:moveToCenter(idx)
    local size = self.view:getContentSize()
    local width = self.cellSetting.size.width
    local dx = self.cellSetting.disx
    local offx = self.cellSetting.offx
    local mx = offx+(idx-1)*width+(idx-1)*dx+width/2
    self.view:moveAndScaleToCenter(1,mx,size.height/2-self.oldpy, 0.25)
end

function TableView:addCell(tab)
	if tab then
	    self.dataLength=self.dataLength+1
		self.datas[self.dataLength]=tab
	else
		return
	end
    local rectmin, rectmax = 0, 0
    local size = self.view:getContentSize()
    if self.isX then
        rectmin = -self.oldpx
        rectmax = rectmin + size.width
    else
        rectmin = self.oldpy
        rectmax = rectmin + size.height
    end
    if self.dataLength==1 then
        self:prepare()
    end
    self:refreshItem(-1, rectmin, rectmax)
    self:refreshItem(1, rectmin, rectmax)
    self.view:moveAndScaleToCenter(1,size.width/2-self.oldpx,size.height/2-self.oldpy, 0.25)
    self:initScrollContentRect(self.dataLength)
end

--在cell,i后加节点
function TableView:addNode(i,sizeXY,z)
    if i<=0  then
        log.e ("addNode not i<=0")
        return
    end

    local bg=self.bg
    local cellSetting = self.cellSetting
    cellSetting.sizeChange=true
    local size = self.size

    local lastItem=self.rectItems[self.dataLength]

    local isX=self.isX
    if self.aNode then
        self.aNode:removeFromParent(true)
        for j,item in ipairs(self.rectItems) do
            if j>self.addNodeI and j<=self.dataInitedLength then
                local cell=self.Cell[j]
                if isX then
                    cell:setPositionX(cell:getPositionX()-self.sizeXY)
                    self.items[j].off=self.items[j].off-self.sizeXY
                else
                    cell:setPositionY(cell:getPositionY()+self.sizeXY)
                    self.items[j].off=self.items[j].off-self.sizeXY
                end
            end
        end
        if isX then
            self.off_min = squeeze(size[1] - (lastItem.off + lastItem.length + lastItem.endoff), nil, self.off_max)
            self.view:setScrollContentRect(cc.rect(0,0,size[1]-self.off_min-self.sizeXY,size[2]))
        else
            self.off_max = squeeze(lastItem.off + lastItem.length + lastItem.endoff - size[2], self.off_min)
            self.view:setScrollContentRect(cc.rect(0,-self.off_max+self.sizeXY,size[1],self.off_max+size[2]-self.sizeXY))
        end
    end

    local pos={self.Cell[i]:getPositionX(),self.Cell[i]:getPositionY()}
    if isX then
        pos[1]=pos[1]+cellSetting.size.width/2
    else
        pos[2]=pos[2]-cellSetting.size.height/2
    end
    --以第i个cell的右边或下边为该节点的位置
    local aNode=ui.node()
    display.adapt(aNode,pos[1],pos[2])
    bg:addChild(aNode,z or 0)

    for j,cell in ipairs(self.rectItems) do
        if j>i and j<=self.dataInitedLength then
            local cell=self.Cell[j]
            if isX then
                cell:setPositionX(cell:getPositionX()+sizeXY)
                self.items[j].off=self.items[j].off+sizeXY
            else
                cell:setPositionY(cell:getPositionY()-sizeXY)
                self.items[j].off=self.items[j].off+sizeXY
            end
        end
    end
    if isX then
        self.off_min = squeeze(size[1] - (lastItem.off + lastItem.length + lastItem.endoff), nil, self.off_max)
        self.view:setScrollContentRect(cc.rect(0,0,size[1]-self.off_min+sizeXY,size[2]))
    else
        self.off_max = squeeze(lastItem.off + lastItem.length + lastItem.endoff - size[2], self.off_min)
        self.view:setScrollContentRect(cc.rect(0,-self.off_max-sizeXY,size[1],self.off_max+size[2]+sizeXY))
    end
    self.addNodeI=i
    self.sizeXY=sizeXY
    self.aNode=aNode
    return aNode
end

return TableView
