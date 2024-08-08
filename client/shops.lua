shopTable = {}
function tvRP.reset()
    shopTable = nil
end
function DrawText3D(x,y,z, text, scl) 

    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
 
    local scale = (1/dist)*scl
    local fov = (1/GetGameplayCamFov())*100
    local scale = scale*fov
   
    if onScreen then
        SetTextScale(0.0*scale, 1.1*scale)
        SetTextFont(0)
        SetTextProportional(1)
        -- SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end
Citizen.CreateThread(function()
	while true do
		local pos = GetEntityCoords(GetPlayerPed(-1), true)

		for k,v in pairs(shopTable)do
			shopid = v.id
            ownedby = v.ownedby
            x = v.x
            y = v.y
            z = v.z
            resellprice = v.price
            username = v.username

			if(Vdist(pos.x, pos.y, pos.z, x, y, z) < 5.0)then
                if username == 'Nobody' or username == 'unknown' then

                    username = 'SERVER'
                    DrawMarker(29, x, y, z-0.7, 0, 0, 0, 0, 0, 0, 1.0001, 1.0001, 1.2001, 0, 255, 0, 255, 0, 0, 0, true)
                    DrawText3D(x,y,z+0.1, "~w~ 24/7 Shop", 1.5)
                    DrawText3D(x,y,z-0.2, "~w~Owned by: ~y~"..username, 1)
                    DrawText3D(x,y,z-0.4, "~w~You can buy this for: $~y~"..resellprice, 1)
                    DrawText3D(x,y,z-0.6, "~w~Press ~y~[Y]~w~ to open the Shop", 1)
                    if IsControlJustReleased(1,51) then
                        TriggerServerEvent('server:tryBuyShop',shopid,resellprice)
                    end
                    if IsControlJustReleased(1,246) then
                        TriggerServerEvent('server:OpenShop',shopid)
                    end
                elseif username == NetworkPlayerGetName(PlayerId()) then
                    DrawMarker(29, x, y, z-0.7, 0, 0, 0, 0, 0, 0, 1.0001, 1.0001, 1.2001, 0, 255, 0, 255, 0, 0, 0, true)
                    DrawText3D(x,y,z+0.23, "~w~ 24/7 Shop", 1.5)
                    DrawText3D(x,y,z-0.2, "~w~Owned by: ~y~"..username, 1)
                    DrawText3D(x,y,z-0.4, "~w~Press ~y~[G]~w~ to acces the menu: ~y~", 1)
                    DrawText3D(x,y,z-0.6, "~w~Press ~y~[Y]~w~ to open the Shop", 1)
                    if IsControlJustReleased(1,47) then
                        TriggerServerEvent('server:accesshop',shopid)
                    end
                    if IsControlJustReleased(1,246) then
                        TriggerServerEvent('server:OpenShop',shopid)
                    end
                end
			end
		end
		Citizen.Wait(0)
	end
end)

function tvRP.spawnShopss(shops)	
	shopTable = shops
end

RegisterCommand('createshop',function(source,args,rawCommand)
    local forsale = tostring(args[1]) -- if no then can't be bought, if yes, can be bought by players
    local args2 = tonumber(args[2])
    if forsale == 'Yes' or forsale == 'yes' or forsale == 'No' or forsale == 'no' then
        if args2 ~= nil then
            TriggerServerEvent('server:createShop',forsale,args2)
        else
            tvRP.notify("~r~Invalid price number!")
        end
    else
        tvRP.notify("~r~You didn't specify if it is for sale or not! TRY AGAIN!")
    end
end)

RegisterCommand('aprovizionare',function(source,args,rawCommand)
    if tostring(args[1]) == 'delete' then
        DeleteEntity(created_ped)
        DeleteEntity(GetHashKey("mule"))
        print('delete')
    else
        clientAprovizionare()
    end
end)

local created_vehicle
local propcreated
local created_ped
local anim
local aajuns = false
local aajuns2 = false
local aajuns3 = false
local aintratinmasina = false
RegisterNetEvent('client:Aprovizionare')
AddEventHandler('client:Aprovizionare',function()
--function clientAprovizionare()
    local pedhash = GetHashKey("ig_ramp_gang")
    local car = GetHashKey("mule")
    while not HasModelLoaded(pedhash) do
        Citizen.Wait(110)
        RequestModel(pedhash) 
    end
    while not HasModelLoaded(car) do
        Citizen.Wait(110)
        RequestModel(car) 
    end
    pedcoordsvec = vector3(1106.4110107422,-368.77651977539,67.084602355957)
    created_ped = CreatePed(1, pedhash, pedcoordsvec.x, pedcoordsvec.y, pedcoordsvec.z, 51.722648620605, true, true)
	SetEntityInvincible(created_ped,true)
    SetBlockingOfNonTemporaryEvents(created_ped,true)
    created_vehicle =CreateVehicle(car , pedcoordsvec.x , pedcoordsvec.y , pedcoordsvec.z , 51 , true , true )
    SetPedIntoVehicle(created_ped,created_vehicle,-1)
	SetEntityInvincible(created_vehicle,true)
    TaskGoToCoordAnyMeans(
        created_ped , 
        1157.5653076172 , 
        -332.2414855957 , 
        68.808860778809 , 
	1 , 
	created_vehicle , 
	true , 
	1 , 
	1 
) 
AddBlipForEntity(created_ped)
    while not aajuns do
        Citizen.Wait(201)
        posped = vector3(GetEntityCoords(created_ped))
        if GetDistanceBetweenCoords(posped.x,posped.y,posped.z,1157.5653076172,-332.2414855957,68.808860778809,true) < 5 then 
            aajuns = true
        end
    end 
    if aajuns then
            if GetDistanceBetweenCoords(posped.x,posped.y,posped.z,1157.5653076172,-332.2414855957,68.808860778809,true) < 8 then
            FreezeEntityPosition(created_vehicle,true)
            TaskLeaveVehicle(created_ped,GetVehiclePedIsIn(created_ped),0)
            prop = 'prop_fib_clipboard'
            anim = 'missfam4'
            while not HasModelLoaded(prop) do
                Citizen.Wait(0)
                RequestModel(prop) 
            end
            while not HasAnimDictLoaded(anim) do
                Citizen.Wait(0)
                RequestAnimDict(anim) 
            end
            bone = GetPedBoneIndex(created_ped, 36029)
            propcreated = CreateObject(prop,1157.5653076172,-332.2414855957,68.808860778809,true,true,false)
            TaskPlayAnim(created_ped,anim,'base',2.0,2.0,-1,51,0,false,false,false)
            AttachEntityToEntity(propcreated, created_ped, bone, 0.16, 0.08, 0.1, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
            FreezeEntityPosition(created_vehicle,false)
            TaskFollowNavMeshToCoord(created_ped, 1163.3328857422,-322.37588500977,69.205146789551, 1.0, 20000, 1.0, true, 1.0)
            while not aajuns2 do
                Citizen.Wait(100)
                posped = vector3(GetEntityCoords(created_ped))
                poscar = vector3(GetEntityCoords(created_vehicle))
                if GetDistanceBetweenCoords(posped.x,posped.y,posped.z,1163.3328857422,-322.37588500977,69.205146789551,true) < 1 then
                    aajuns2 = true 
                end
            end
            if aajuns2 then
                Wait(2000)
                TaskFollowNavMeshToCoord(created_ped, poscar.x,poscar.y,poscar.z, 1.0, 20000, 1.0, true, 1.0)
            end
            while not aajuns3 do
                Citizen.Wait(100)
                posped = vector3(GetEntityCoords(created_ped))
                poscar = vector3(GetEntityCoords(created_vehicle))
                if GetDistanceBetweenCoords(posped.x,posped.y,posped.z,poscar.x,poscar.y,poscar.z,true) < 2.5 then
                    aajuns3 = true 
                    aintratinmasina = true
                end
            end
            if aajuns3 then
                TaskEnterVehicle(created_ped,created_vehicle,20000,-1,1.5,1,0)
                
            end
            while aintratinmasina do 
                Citizen.Wait(500)
                if IsPedInVehicle(created_ped , created_vehicle , false ) then
                Wait(2000)
                    TaskGoToCoordAnyMeans(
                    created_ped , 
                    1234.2214355469 , 
                    -1391.83984375 , 
                    35.179874420166 , 
                    1 , 
                    created_vehicle , 
                    true, 
                    1, 
                    1 
                ) aintratinmasina = false
                    Wait(60000) 
                    SetEntityInvincible(created_ped,false)
                    SetModelAsNoLongerNeeded(pedhash)
                    SetModelAsNoLongerNeeded(car)
                    deleteVehiclePedIsIn(created_ped)
                    DeleteEntity(created_ped)
                    DeleteEntity(created_vehicle)
                    DeleteEntity(propcreated)
                end
            end
        end
    end
end)

function deleteVehiclePedIsIn(nume)
	local v = GetVehiclePedIsIn(nume,false)
	SetVehicleHasBeenOwnedByPlayer(v,false)
	Citizen.InvokeNative(0xAD738C3085FE7E11, v, false, true) -- set not as mission entity
	SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(v))
	Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(v))
end
