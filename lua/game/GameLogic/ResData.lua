local const = GMethod.loadScript("game.GameLogic.Const")
local ResData = class()

function ResData:ctor(udata)
	self.storages = {}
    self.backs = {}
    self.udata = udata
end

function ResData:destroy()
	self.udata = nil
	self.backs = nil
	self.storages = nil
end

function ResData:addStorage(ctype, storage)
	local ss = self.storages[ctype]
	if not ss then
		ss = {}
		self.storages[ctype] = ss
	end
	ss[storage] = storage.extData
    ss = self.backs
    if not ss[storage] then
        ss[storage] = storage.extData[1]
    end
end

function ResData:removeStorage(ctype, storage)
	local ss = self.storages[ctype]
	if ss then
		ss[storage] = nil
	end
end

function ResData:getNum(ctype)
	local num = 0
	local ss = self.storages[ctype]
	if ss then
		for k,v in pairs(ss) do
			num = num + v[1]
		end
	end
	return num
end

function ResData:getMax(ctype)
	local max = 0
	local ss = self.storages[ctype]
	if ss then
		for k,v in pairs(ss) do
			max = max + v[2]
		end
	end
	return max
end

function ResData:changeNum(ctype,cvalue)
	local ss = self.storages[ctype]
	if not ss then
		return
	end

	local items = {}
	local len = 0
	for k,v in pairs(ss) do
		len = len+1
		items[len] = v
	end
	if len==0 then
		return
	end
	local remainChange = cvalue
	if cvalue>0 then
		for i=1,len do
			for j=1,len-i do
				if items[j][1]>items[j+1][1] then
					items[j],items[j+1] = items[j+1],items[j]
				end
			end
		end
		local tabChange = {}
		local index = 1
		local tabChangeLen = 0
		while index<=len do
			table.insert(tabChange, items[index])
			tabChangeLen = tabChangeLen+1
			while tabChangeLen>0 and remainChange~=0 do
				local max1 = nil
				if index<len then
					max1 = items[index+1][1]-tabChange[1][1]
					if max1==0 then
						break
					end
				end
				local max2 = max1
				for i, item in ipairs(tabChange) do
					if not max2 or item[2]-item[1]<max2 then
						max2 = item[2]-item[1]
					end
				end
				local todels = {}
				local allValue = remainChange
				if max2*tabChangeLen<remainChange then
					allValue = max2*tabChangeLen
				end
				local oneChange = math.ceil(allValue/tabChangeLen)
				for i, item in ipairs(tabChange) do
					if (oneChange-1)*(tabChangeLen-i+1)==remainChange then
						oneChange = oneChange-1
					end
					item[1] = item[1]+oneChange
					remainChange = remainChange-oneChange
					if item[1]==item[2] then
						table.insert(todels, i)
					end
				end
				for k=#todels, 1, -1 do
					table.remove(tabChange, todels[k])
					tabChangeLen = tabChangeLen-1
				end
			end
			index = index+1
		end
	else
		for i=1,len do
			for j=1,len-i do
				if items[j][1]<items[j+1][1] then
					items[j],items[j+1] = items[j+1],items[j]
				end
			end
		end
		local tabChange = {}
		local index = 1
		local tabChangeLen = 0
		while index<=len do
			table.insert(tabChange, items[index])
			tabChangeLen = tabChangeLen+1
			while tabChangeLen>0 and remainChange~=0 do
				local max2 = nil
				if index<len then
					max2 = tabChange[1][1]-items[index+1][1]
					if max2==0 then
						break
					end
				else
					max2 = tabChange[1][1]
				end
				local todels = {}
				local allValue = -remainChange
				if max2*tabChangeLen<allValue then
					allValue = max2*tabChangeLen
				end
				local oneChange = math.ceil(allValue/tabChangeLen)
				for i, item in ipairs(tabChange) do
					if (oneChange-1)*(tabChangeLen-i+1)==-remainChange then
						oneChange = oneChange-1
					end
					item[1] = item[1]-oneChange
					remainChange = remainChange+oneChange
					if item[1]==0 then
						table.insert(todels, i)
					end
				end
				for k=#todels, 1, -1 do
					table.remove(tabChange, todels[k])
					tabChangeLen = tabChangeLen-1
				end
			end
			index = index+1
		end
	end
end

function ResData:dumpExtChanges()
    local ret = {const.CmdBatchExts}
    local backs = self.backs
    local idx = 1
    for _, ss in pairs(self.storages) do
        for s, e in pairs(ss) do
            if backs[s] and backs[s]~=e[1] then
                ret[idx+1] = s.id
                ret[idx+2] = e[1]
                ret[idx+3] = e[2]
                backs[s] = e[1]
                idx = idx+3
            end
        end
    end
    if idx>1 then
        self.udata:addCmd(ret)
    end
end

return ResData
