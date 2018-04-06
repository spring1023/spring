local function squeeze(value, min, max)
    if min and value<min then
        return min
    elseif max and value>max then
        return max
    else
        return value
    end
end

local PageView = {}
PageView.__index = PageView

local MinLengthToMove = 300

function PageView.new(size,page,clomn,row,params,actionType)
	if not clomn then clomn = 1 end
	if not row then row = 1 end
	if not page then page = 1 end
    local scrollView = ScrollNode:create(cc.size(size[1], size[2]), 0, true, false)
    --scrollView:setScrollEnable(true)
    scrollView:setInertia(true)
    scrollView:setInertiaCoefficient(0.5)
    scrollView:setClip(true)
    scrollView:setElastic(true)
    scrollView:setScaleEnable(false,1,1,1,1)
        
    local off_min, off_max = 0, 0
    local state = {}
    local items = {}
    local self = {view = scrollView, bg=scrollView:getScrollNode(), items=items, state=state, off_max=off_max, off_min=off_min, isX=true, movable=true, oldpx=0, oldpy=0}
    setmetatable(self, PageView)
    scrollView:setScriptHandler(Script.createCObjectHandler(self))
    scrollView:setScrollContentRect(cc.rect(0,0,size[1],size[2]))
    self.size = size
    self.cellSize = {size[1]/clomn,size[2]/row}
    self.isX=true
	self.curPage = 1
	self.page = page
	self.clomn = clomn
	self.row = row
    self.moveEndSpeed = 2500
    self.Cell={}
    self.cellPos = {}
    self:initCellPos(size,page,clomn,row)
    self.cellActionType = actionType or 1
    MinLengthToMove = size[1]/10
    return self
end

function PageView:setEnable(val)
    self.view:setScrollEnable(val)
end

function PageView:initCellPos(size,page,clomn,row)
	local cellSize = {size[1]/clomn,size[2]/row}
	for p=1,page do
		for i=1,row do
			for j=1,clomn do
				table.insert(self.cellPos,{(p-1)*size[1] + (j-1)*cellSize[1] + cellSize[1]/2,size[2]-(i-1)*cellSize[2]-cellSize[2]/2})
		    end
		end
	end
end

function PageView:setDatas(cellsetting)
    self.cellSetting = cellsetting
end

function PageView:addCell(cell,params)
	local cellNum = #self.Cell
    local cellbg = ui.colorNode(self.cellSize,{0x2f,0x43,0x54,255})
    cellbg:setAnchorPoint(ccp(0.5,0.5))
    if cell then
        if params then
            display.adapt(cell, 0, 0, GConst.Anchor.Center, {datum = GConst.Anchor.Center})
        end
        cellbg:addChild(cell)
    else
        cell = cellbg
    end
	cellbg:setPosition(self.cellPos[cellNum+1][1],self.cellPos[cellNum+1][2])
	self.bg:addChild(cellbg)

	table.insert(self.Cell,cell)
	local fpage = #self.Cell/(self.row*self.clomn)
	self.page = fpage-math.floor(fpage)>=self.size[1]/self.clomn and math.floor(fpage)+1 or math.floor(fpage)

    self.contentSize = {self.page*self.size[1],self.size[2]}

	self.view:setScrollContentRect(cc.rect(-0.5*self.size[1],0,self.size[1]*(self.page+0.5),self.size[2]))
end
    
function PageView:refreshItem(direction, rectmin, rectmax)
    --print("PageView:refreshItem",direction, rectmin, rectmax)
end

local startTime = 0
local startPosX,startPosY = 0
function PageView:onEvent(event, p1, p2, p3)
    --print("PageView:onEvent",event, p1, p2, p3)
    if event=="single" then
        local px,py = p2,p3
        startTime = socket.gettime()
        startPosX,startPosY = self.bg:getPosition()
    elseif event=="scrollTo" then
        local px,py = p1,p2
        --供外部使用
        if self.cellSetting and self.cellSetting.scrollToCall then
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
        local px,py = p1,p2
        local delTime = socket.gettime()-startTime
        local dirx = px - startPosX
        local diry = py - startPosY
        self.oldpx = px
        self.oldpy = py
    	self:_pageLocation(delTime,dirx,diry)
    end
end

--设置定位
function PageView:setLocation(page,movTime)
    --print("PageView:setLocation",page,movTime)
    self.curPage = squeeze(page,1,self.page)
    self.xy = -(self.curPage-1)*self.size[1]
    self.moveTime = movTime
    if movTime then
        self:locationToPage(page,true)
    else
        local size = self.size
        
        local bg=self.bg
        local pos={bg:getPositionX(),bg:getPositionY()}
        local basePosxy=self.xy
        local moveL
        if self.isX then
            moveL=self.xy-pos[1]
            bg:setPositionX(self.xy)
        else
            moveL=self.xy-pos[2]
            bg:setPositionX(self.xy)
        end

        if self.cellSetting and self.cellSetting.locationEnd then
            self.cellSetting.locationEnd(page)
        end
    end
end

function PageView:locationToPage(page,isOut)
    --print("PageView:locationByI",page,isOut)
    if not self.xy then
        log.e("please call setLocation")
        return
    end
    self.curPage = squeeze(page,1,self.page)
    local bg=self.bg
    local pos={bg:getPositionX(),bg:getPositionY()}
    local basePosxy=self.xy
    local moveL
    local dt=0.01
    if self.isX then
        moveL=basePosxy-pos[1]
    else
        moveL=basePosxy-pos[2]
    end
    local movTime = self.moveTime or math.abs(moveL/self.moveEndSpeed)
    local schedule
    local function callScroll( ... )
        if isOut then
            local time = 0
            schedule = GFunc_schedule(function(diff)
                time = time + diff
                if time >= movTime then
                    GFunc_unschedule(schedule)
                    return
                else
                    if self.isX then
                        pos[1] = pos[1] + moveL*diff/movTime
                    else
                        pos[2] = pos[2] + moveL*diff/movTime
                    end

                    self:onEvent("scrollTo", pos[1], pos[2])
                end
            end,0.01,false)
        end
    end

    local function callEnd()
        GFunc_unschedule(schedule)
        if self.cellSetting and self.cellSetting.locationEnd then
            self.cellSetting.locationEnd(page)
        end
    end

    bg:runAction(ui.action.sequence({{"spawn",{{"moveBy",movTime,moveL,0},{"call",callScroll}}},{"call",callEnd}}))
end

function PageView:_pageLocation(delTime,dirx,diry)
    --print("PageView:_pageLocation deltime,dirx",delTime,dirx)
    local page = self.curPage
    if delTime>0.5 then
        local fpage = math.abs(self.oldpx)/self.size[1]
        print(fpage,math.floor(fpage))
        if fpage >= math.floor(fpage) + 0.5 then
            page = page-dirx/math.abs(dirx)
        else
            page = math.floor(fpage) + 1
        end
    else
        local movPage = (math.abs(dirx)>MinLengthToMove) and -dirx/math.abs(dirx) or 0
        if self.curPage == self.page and dirx < 0 then movPage = 0 end
        
        page = page + movPage
    end
	
    page = squeeze(page,1,self.page)
	self.xy = -(page-1)*self.size[1]

	self:locationToPage(page,true)
end

function PageView:removeAllCells( ... )
    for k,v in pairs(self.Cell) do
        v:removeFromParent(true)
    end
    table_clear(self.Cell)
end

function PageView:removeFromParent(val)
    table_clear(self.Cell)
    self.view:removeFromParent(val)
end

function PageView:moveToCenter(idx)
    --print("PageView:moveToCenter",idx)
    local size = self.view:getContentSize()
    local width = self.cellSetting.size.width
    local dx = self.cellSetting.disx
    local offx = self.cellSetting.offx
    local mx = offx+(idx-1)*width+(idx-1)*dx+width/2
    self.view:moveAndScaleToCenter(1,mx,size.height/2-self.oldpy, 0.25)
end

return PageView