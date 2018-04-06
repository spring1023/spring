local DataCache = class()

function DataCache:ctor()
	self.allCahce = {}
	GMethod.schedule(function()
		self:update()
	end,10,false)
end

function DataCache:add(key,data,time)
	if self.allCahce[key] then
		print("key error")
	else
		self.allCahce[key] = {data,os.time(),time}
	end
	self:update()
end

function DataCache:get(key)
	if self.allCahce[key] then
		return self.allCahce[key][1]
	end
end

function DataCache:remove(key)
	if self.allCahce[key] then
		self.allCahce[key] = nil
	end
end

function DataCache:removeAll()
	self.allCahce = {}
end

function DataCache:update()
	for k,v in pairs(self.allCahce) do
		if v[3] and os.time()-v[2]>v[3] then
			self.allCahce[k] = nil
		end
	end
	--如果是活动数据 要根据时间更新
	local activeData = self:get("activeData")
	if activeData then
		for k,v in pairs(activeData) do
			local rtime = GameLogic.getRtime()
			if rtime+v[5]<GameLogic.getTime() then
				if k == 12 then  --每日登陆
					v[4] = 0
					if v[4] == 0 then
						v[5] = GameLogic.getTime()
					else
						v[3] = v[3]+1
						v[4] = 0
						v[5] = GameLogic.getTime()
					end
				else
					table.remove(activeData,k)
				end
			end
		end
	end
	
end

dataCache = DataCache.new()



