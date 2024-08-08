local antreprenor = {}

RegisterNetEvent('server:tryBuyShop')
AddEventHandler('server:tryBuyShop',function(shopid,price)
    local player = vRP.getUserSource(source)
    local user = vRP.getUserId(player)
    local shopID = shopid
    vRP.prompt(player,"Are you sure you want to buy for :"..price,"Type yes",function(player,args)
        args = tostring(args)
        if(args == nil) or (args == "")then
            vRPclient.notify(player,{"~y~You don't want the shop!"})
        elseif (args == 'yes') or (args == 'YES') then
            if vRP.tryFullPayment(user,tonumber(price)) then
                MySQL.Async.execute('UPDATE vrp_shops SET ownedby = @user, username = @username WHERE id = @shopID',{user = user, shopID= shopID,username = vRP.getPlayerName(player)},function(data)end)
                vRPclient.notify(player,{"~g~You bought the shop for "..price.."$, let's celebrate!"})
                users = vRP.getUsers({})
                for i, v in pairs(users) do
                    tvRP.spawnShops(v)
                    Wait(1000)
                    tvRP.spawnShops(v)
                end
            else
                vRPclient.notify(player,{"~r~You don't have enough money!"})
            end
        end
    end)
end)

RegisterCommand("spawnshops", function(source)
	users = vRP.getUsers({})
	for i, v in pairs(users) do
		tvRP.spawnShops(v)
	end
end)

function tvRP.spawnShops(source)
    MySQL.Async.fetchAll('SELECT * FROM vrp_shops',{},function(rows)
		if #rows > 0 then
			vRPclient.spawnShopss(source,{rows})
		end
    end)
end
RegisterNetEvent('server:accesshop')
AddEventHandler('server:accesshop',function(idshop)
    idshop = tonumber(idshop)
    local player = vRP.getUserSource(source)
    local user_id = vRP.getUserId(player)
    local menu = {name='Menu',css={top="75px", header_color="rgba(0,125,255,0.75)"}}
	MySQL.Async.fetchAll('SELECT * FROM vrp_markets WHERE idmarket = @idmarket',{idmarket = idshop},function(theVehicles)
		for i, v in pairs(theVehicles) do
            menu['Items For Sale'] = {function() ch_pula(player,user_id,idshop) end, "items"}
            menu['Cash Register'] = {function() cashRegisterMoney(idshop,v.cashregister) end, "Current Cash Register <font color='yellow'>"..v.cashregister.."</font>"}
        end
        vRP.openMenu(player,menu)
    end)
end)
RegisterNetEvent('server:OpenShop')
AddEventHandler('server:OpenShop',function(idshop)
    idshop = tonumber(idshop)
    local player = vRP.getUserSource(source)
    local user_id = vRP.getUserId(player)
    local menu = {name='Menu',css={top="75px", header_color="rgba(0,125,255,0.75)"}}
	MySQL.Async.fetchAll('SELECT * FROM vrp_markets WHERE idmarket = @idmarket',{idmarket = idshop},function(theVehicles)
		for i, v in pairs(theVehicles) do
            menu[v.item] = {function() selectitem(player,user_id,v.item,v.price,v.stock,idshop)end, "Price for "..v.item.." is "..v.price.." !\n Current stock: "..v.stock}
        end
        vRP.openMenu(player,menu)
    end)
end)
function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  end
function withdrawMoney(amount,shopid)
    local player = vRP.getUserSource(source)
    local user_id = vRP.getUserId(player)
    local newamount = 0.08 *tonumber(amount)
    newamount = tonumber(newamount)
    print(amount)
    newamount = round(newamount)
    print(newamount)
    vRP.prompt(player,"Maximum amount you can withdraw "..amount,"Total tax is: "..newamount,function(player,args)
        if args == nil or args == "" then
        else
            args = tonumber(args)
            if args > amount then
                vRPclient.notify(player,{"You don't have that much money!"})
            else
                local impozitat = 0.08 * args
                vRP.giveBankMoney(user_id,args)
                vRP.tryBankPayment(user_id,impozitat)
                vRPclient.notify(player,{'You withdrawed '..args.." / Total tax: "..round(impozitat)})
                MySQL.Async.execute("UPDATE vrp_markets SET cashregister = @value WHERE idmarket = @value2",{["@value"] = amount - args,["@value2"] = shopid},function(data)end)
            end
        end
    end)
end

function selectitem(player,user_id,item,price,stock,idshop)
    vRP.prompt(player,"How many :"..item.." do you want to buy? \nPrice per pice: "..price,"",function(player,args)
        if args == nil or args == "" then
            vRPclient.notify(player,{"Put a number!"})
        else
            args = tonumber(args)
            if args < 0 then
                vRPclient.notify(player,{'The number should be higher than 0'})
            else
                if args > stock then
                    vRPclient.notify(player,{'Stock for this item is max ~y~'..stock})
                else
                    inventarUser = vRP.getInventoryMaxWeight(user_id)
                    weightItem = vRP.getItemWeight(item)
                    weightItem = weightItem*args
                    if inventarUser == weightItem or inventarUser > weightItem then
                        if vRP.tryFullPayment(user_id,price*args) then
                            vRP.giveInventoryItem(user_id,item,args,true)
                            removeStock(item,stock,args,idshop)
                        else
                            vRPclient.notify(player,{"You don't have enough money!"})
                        end
                    else
                        print('Nu ai loc in inventar')
                    end
                end
            end
        end
    end)
end

function depositMoney(shopid,cashregister)
    local player = vRP.getUserSource(source)
    local user_id = vRP.getUserId(player)
    cashregister = tonumber(cashregister)
    vRP.prompt(player,"How much money would you like to deposit?","Type in the amount!",function(player,args)
        args = tonumber(args)
        if args < 0 then
            vRPclient.notify(player,{'The deposit should be above 0!'})
        else
            if vRP.tryFullPayment(user_id,args) then
                MySQL.Async.execute("UPDATE vrp_markets SET cashregister = @value WHERE idmarket = @value2",{["@value"] = cashregister + args,["@value2"] = shopid},function(data)end)
            else
                vRPclient.notify(player,{"You don't have this much money!"})
            end
        end
    end)
end

function cashRegisterMoney(shopid,cashregister)
    local player = vRP.getUserSource(source) -- de facut sql aici ca e bug
    local check_menu3 = {name="Cash Register",css={top="75px", header_color="rgba(0,125,255,0.75)"}}
    check_menu3["Withdraw Money"] = {function(player,choice) withdrawMoney(cashregister,shopid) end, "Be careful it's a %8% <font color='red'>STATE TAX!</font>"}
    check_menu3["Deposit Money"] = {function(player,choice) depositMoney(shopid,cashregister) end, "Deposit money to your shop to order stocks"}
    vRP.closeMenu(player)
    SetTimeout(200, function()
        vRP.openMenu(player, check_menu3)
    end)
end

function optionsForItems(item,idshop,cashregister)
    local player = vRP.getUserSource(source) -- de facut sql aici ca e bug
    local check_menu4 = {name="Items Stock",css={top="75px", header_color="rgba(0,125,255,0.75)"}}
    check_menu4["Add Stock"] = {function(player,choice) adaugaStock(item,idshop,cashregister) end, "Be careful it's a <font color='red'>STATE TAX!</font>"}
    check_menu4["Change Price"] = {function(player,choice) depositMoney(shopid,v.item) end, "Deposit money to your shop to order stocks"}
    vRP.closeMenu(player)
    SetTimeout(200, function()
        vRP.openMenu(player, check_menu4)
    end)
end

function ch_pula(player,user_id,idshop)
	check_menu2 = {name="Vehicule",css={top="75px", header_color="rgba(0,125,255,0.75)"}}
	MySQL.Async.fetchAll('SELECT * FROM vrp_markets WHERE idmarket = @idmarket',{idmarket = idshop},function(theVehicles)
		for i, v in pairs(theVehicles) do
			check_menu2[tostring(v.item)] = {function(player, choice) optionsForItems(v.item,idshop,v.cashregister) --[[adaugaStock(v.item,idshop,v.cashregister)]] end, "Item: <font color='green'>"..v.item.."<br>Stock: <font color='yellow'>"..v.stock}
			vRP.closeMenu(player)
			SetTimeout(200, function()
				vRP.openMenu(player, check_menu2)
			end)
		end
	end)
end

function businessPay()

end

function adaugaStock(itemSelected,idMarket,cashregisterMoney)
    local player = vRP.getUserSource(source)
    local user_id = vRP.getUserId(player)
    cashregisterMoney = tonumber(cashregisterMoney)
    vRP.prompt(player,"[ORDER STOCK]How many do you want to add? Price per one is $5:","Type a number",function(player,args)
        args = tonumber(args)
        if(args == nil) or (args == "")then
            vRPclient.notify(player,{"~r~Wrong!"})
        else
            local paidue = args*5 -- de reparat sqlu
            if cashregisterMoney >= paidue then --vRP.tryGetInventoryItem(user_id,tostring(itemSelected),args,true) then
                TriggerClientEvent('client:Aprovizionare',player)
                MySQL.Async.fetchAll('SELECT * FROM vrp_markets WHERE idmarket = @idmarket AND item = @item',{idmarket = idMarket,item = itemSelected},function(rows)
                    for k,v in pairs(rows) do
                        if #rows > 0 then
                            Citizen.Wait(45000)
                            MySQL.Async.execute('UPDATE vrp_markets SET stock = @value AND cashregister = @value4 WHERE item = @value2 AND idmarket = @value3',{ ['@value'] = v.stock + args,['@value2'] = itemSelected,['@value3'] = idMarket,['@value4'] = cashregisterMoney - paidue},function(data)end)
                            vRPclient.notify(player,{"~r~You've added "..tonumber(args).." stock to "..itemSelected})
                            vRP.closeMenu(player)
                            vRP.closeMenu(player)
                        end
                    end
                end)
            else
                vRPclient.notify(player,{"~r~You don't have "..tonumber(args).." "..itemSelected})
            end
        end
    end)
end

RegisterNetEvent('server:createShop')
AddEventHandler('server:createShop',function(args,args2)
    local player = vRP.getUserSource(source)
    local user = vRP.getUserId(player)
    vRPclient.getPosition(player,{},function(x,y,z)
        local forsale = args
        local ownedby = "Nobody"
        local username = "Nobody"
        MySQL.Async.execute("INSERT IGNORE INTO vrp_shops(x, y, z, forsale, ownedby, createdby,price) VALUES(@x, @y, @z, @forsale, @ownedby, @user_id,@price)", {['x'] = x, ['y'] = y, ['z'] = z, ['forsale'] = forsale, ['ownedby'] = ownedby, ['user_id'] = user,['price'] = tonumber(args2)},function(data)end)
        MySQL.Async.fetchAll('SELECT * FROM vrp_shops WHERE x = @x',{x = x},function(rows)
            Wait(1000)
            MySQL.Async.execute("INSERT IGNORE INTO vrp_markets(idmarket, ownedby, username) VALUES(@id, @ownedby, @username)", {id = rows[1].id, ['ownedby'] = ownedby, ['username'] = username},function(data)end)
            vRPclient.notify(player,{"You've created a shop!"})
        end)
    end)
end)

function isUserAntreprenor(source)
    local player = vRP.getUserSource(source)
    local user_id = vRP.getUserId(player)
    MySQL.Async.fetchAll('SELECT * FROM vrp_shops WHERE ownedby = @ownedby',{ownedby = user_id},function(rows)
        if #rows > 0 then
            table.insert(antreprenor,{user_id = user_id,src = player})
            for a=1, #antreprenor do
                if antreprenor[a].user_id == user_id then
                    print('Jucatorul '..GetPlayerName(antreprenor[a].src)..' ['..vRP.getUserId({antreprenor[a].src})..'] Este antreprenor')
                    return true
                end
            end
        else
            return false
        end 
    end)
end

RegisterCommand('antreprenor',function(source,args)
    player = vRP.getUserSource(source)
    user_id = vRP.getUserId(player)
    check(user_id)
    print(tmp)
end)

function removeStock(item,stockvechi,amount,shopid)
    MySQL.Async.execute('UPDATE vrp_markets SET stock = @value WHERE item = @value2 AND idmarket = @value3 ',{ ['@value'] = stockvechi - amount,['@value2'] = item,['@value3'] = shopid},function(data)end)
end

local ch_createShop = {function(player,choice)
    vRP.prompt(player,"You want to create a Shop?","Type 'yes' if you want to create a shop",function(player,args)
        args = tostring(args)
            if args == "yes" or args == "Yes" or args == "YES" then
                vRP.prompt(player,"Price of selling this shop","Type in the price!",function(player,args2)
                    args2 = tonumber(args2)
                    if args2 < 0 then
                    else
                        vRPclient.getPosition(player,{},function(x,y,z)
                            local forsale = 1
                            local user = vRP.getUserId(player)
                            local ownedby = "Nobody"
                            local username = "Nobody"
                            MySQL.Async.execute("INSERT IGNORE INTO vrp_shops(x, y, z, forsale, ownedby, createdby,price) VALUES(@x, @y, @z, @forsale, @ownedby, @user_id,@price)", {['x'] = x, ['y'] = y, ['z'] = z, ['forsale'] = forsale, ['ownedby'] = ownedby, ['user_id'] = user,['price'] = args2},function(data)end)
                            MySQL.Async.fetchAll('SELECT * FROM vrp_shops WHERE x = @x',{x = x},function(rows)
                                Wait(1000)
                                MySQL.Async.execute("INSERT IGNORE INTO vrp_markets(idmarket, ownedby, username) VALUES(@id, @ownedby, @username)", {id = rows[1].id, ['ownedby'] = ownedby, ['username'] = username},function(data)end)
                                vRPclient.notify(player,{"You've created a shop!"})
                            end)
                        end)
                    end
                end)
            end
        --end
    end)
end, "Create Shop."}

vRP.registerMenuBuilder("admin", function(add, data)
    local user_id = vRP.getUserId(data.player)
    if user_id ~= nil then
      local choices = {}
      
      if vRP.hasPermission(user_id,"admin.createshop") then
        choices["Create Shop"] = ch_createShop 
      end
      
      add(choices)
    end
  end)
