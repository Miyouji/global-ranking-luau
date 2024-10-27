local dataStoreService = game:GetService("DataStoreService")
local store_ = "test"

local maxDecimalPercision = 6

local module = {}

-- for items table format is : 
-- {UserId, Score}

function toJsonEncode(t)
	return game:GetService("HttpService"):JSONEncode(t)
end

function bringToListeners(data,store)
	task.spawn(function()
		for _,i in game:GetDescendants() do
			if i:IsA("BindableEvent") or i:IsA("RemoteEvent") and i.Name == ("GlobalRankingDataListener_" .. store) then
				if i:IsA("BindableEvent") then
					i:Fire(data, store)
				elseif i:IsA("RemoteEvent") then
					--warn("fired")
					i:FireAllClients(data, store)
				end
			end
		end
	end)
end

function SetData(t,requestedStore)
	local store = dataStoreService:GetGlobalDataStore(requestedStore)
	local data = store:SetAsync(requestedStore,t)

	bringToListeners(t,requestedStore)
	return module.CorrectData(data)
end

function module.GetData(requestedStore)
	local store = dataStoreService:GetGlobalDataStore(requestedStore)
	local data = store:GetAsync(requestedStore)
	
	bringToListeners(data,requestedStore)
	return module.CorrectData(data)
end

function module.CorrectData(data)
	local d = data
	if type(d) ~= "table" or not d then
		d = {}
	end
	
	for rank,data_ in d do
		data_[2] = math.floor(data_[2]*(10^maxDecimalPercision))/(10^maxDecimalPercision)
	end
	
	table.sort(d, function(one, two)
		return (if one[2] == two[2] then one[1] < two[1] else one[2] > two[2])
	end)
	
	return d
end

function module.RemoveScores(items,store)
	local t = module.GetData(store)
	--warn(toJsonEncode(t))

	for _,item in items do
		local found = false
		for rank,data in t do
			if data[1] == item then
				table.remove(t, rank)
			end
		end
	end

	t = module.CorrectData(t)
	--warn(toJsonEncode(t))
	SetData(t,store)
end

function module.SetScores(items,store)
	local t = module.GetData(store)
	--warn(toJsonEncode(t))
	
	for _,item in items do
		local found = false
		for rank,data in t do
			if data[1] == item[1] then
				data[2] = item[2]
				found = true
			end
		end
		
		--warn(found, item[1],item[2])
		if not found then
			table.insert(t, {item[1],item[2]})
		end
	end
	
	t = module.CorrectData(t)
	--warn(toJsonEncode(t))
	SetData(t,store)

	local r = {}

	for _,item in items do
		for rank,data in t do
			if data[1] == item[1] then
				table.insert(r, {data[1],rank})
			end
		end
	end

	--warn(toJsonEncode(r))
	return r
end

function module.GetRank(uids, t, store)
	local t = (if t then t else module.GetData(store))
	local r = {}

	for _,item in uids do
		for rank,data in t do
			if data[1] == item then
				local percentile = math.abs(100-(((#data-rank)/(#data-1))*100))
				table.insert(r, {data[1],rank,percentile})
			end
		end
	end
	
	return r
end

return module
