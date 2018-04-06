local Base = GMethod.loadScript("game.UI.dialog.ViewTemplates.BaseTemplate")

do
    -- 仿Scroll的layout实现，简化代码实现
    local LayoutImplement = {}
    Base.registerImplement("LayoutImplement", LayoutImplement)

    -- 加载
    function LayoutImplement:_static_load(data)
        self._scrollCallback = data.callback
        self._callbackWithIdx = data.withIdx
    end

    function LayoutImplement:setLayoutDatas(infos)
        local maxIdx = 0
        for i, info in ipairs(infos) do
            local cell
            if not self.children or not self.children[i] then
                if self._callbackWithIdx then
                    cell = self._scrollCallback(false, self, i, info)
                else
                    cell = self._scrollCallback(false, self, info)
                end
                self:addChild(cell)
            else
                cell = self.children[i]
                if self._callbackWithIdx then
                    self._scrollCallback(cell, self, i, info)
                else
                    self._scrollCallback(cell, self, info)
                end
            end
            cell:setVisible(true)
            maxIdx = i
        end
        while true do
            maxIdx = maxIdx + 1
            if self.children and self.children[maxIdx] then
                self.children[maxIdx]:setVisible(false)
            else
                break
            end
        end
    end

    function LayoutImplement:refreshLayoutCell(idx, info)
        local cell = self.children[idx]
        if self._callbackWithIdx then
            self._scrollCallback(cell, self, idx, info)
        else
            self._scrollCallback(cell, self, info)
        end
    end
end
