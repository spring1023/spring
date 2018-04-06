TabView = {}
TabView.__index = TabView

function TabView.new(size)
    local bg = ui.node(size, true)
    local self = {view=bg, tabs={}, tabsNum=0, curTab=0, show=false}
    setmetatable(self, TabView)
    RegLife(bg, Handler(self.lifeCycle, self))
    return self
end

function TabView:addTab(tab)
    if not tab.create and tab.new then
        tab = tab.new()
    end
    if not tab.create then
        return false
    end
    self.tabsNum = self.tabsNum + 1
    self.tabs[self.tabsNum] = tab
    return true
end
        
function TabView:changeTab(index)
    if index <=0 then
        index = 1
    elseif index>self.tabsNum then
        index = self.tabsNum
    end
    local curTab = self.curTab
    local tabs = self.tabs
    if index ~= curTab then
        if tabs[curTab] then
            if tabs[curTab].view then
                tabs[curTab].view:removeFromParent(false)
            end
        end
        self.curTab = index
        if self.show then
            local tab = tabs[index]
            if not tab.view then
                tab.view = tab:create()
                tab.view:retain()
            end
            self.view:addChild(tab.view)
        end
    end
end
        
function TabView:lifeCycle(event)
    if self.tabsNum == 0 then
        return
    end
    local curTab = self.curTab
    local tabs = self.tabs
    if event=="enter" then
        self.show = true
        local tab = tabs[curTab]
        if tab then
            if not tab.view then
                tab.view = tab.create(tab)
                self.view:addChild(tab.view)
                tab.view:retain()
            elseif not tab.view:getParent() then
                self.view:addChild(tab.view)
            end
        end
    elseif event=="exit" then
        self.show = false
    elseif event=="cleanup" then
        for i = 1, self.tabsNum do
            if tabs[i] and tabs[i].view then
                tabs[i].view:release()
                tabs[i].view = nil
            end
        end
    end
end

return TabView
