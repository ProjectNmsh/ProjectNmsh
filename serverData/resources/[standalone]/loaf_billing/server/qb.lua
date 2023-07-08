CreateThread(function()
    if Config.Framework ~= "qb" then
        return
    end

    local QBCore = exports["qb-core"]:GetCoreObject()

    function Notify(source, message)
        TriggerClientEvent("QBCore:Notify", source, message)
    end

    function GetPlayerFromIdentifier(identifier)
        return QBCore.Functions.GetPlayerByCitizenId(identifier)?.PlayerData.source
    end

    function GetIdentifier(source)
        return QBCore.Functions.GetPlayer(source)?.PlayerData.citizenid
    end

    function GetCompanyName(job)
        return job
    end

    function PayMoney(source, amount)
        local qPlayer = QBCore.Functions.GetPlayer(source)
        if qPlayer?.Functions.GetMoney("cash") >= amount then 
            qPlayer.Functions.RemoveMoney("cash", amount, "loaf-billing")
            return true
        elseif qPlayer?.Functions.GetMoney("bank") >= amount then 
            qPlayer.Functions.RemoveMoney("bank", amount, "loaf-billing")
            return true
        end
        
        return false
    end

    function GetName(source)
        local qPlayer = QBCore.Functions.GetPlayer(source)
        return ("%s %s"):format(qPlayer.PlayerData.charinfo.firstname, qPlayer.PlayerData.charinfo.lastname)
    end

    function HasJob(source, job)
        return QBCore.Functions.GetPlayer(source)?.PlayerData.job.name == job
    end

    function AddCompanyMoney(company, amount)
        if GetResourceState("nmsh-management") == "started" then
            exports["nmsh-management"]:AddMoney(company, amount)
        elseif GetResourceState("nmsh-bossmenu") == "started" then
            TriggerEvent("nmsh-bossmenu:server:addAccountMoney", company, amount)
        end
    end
end)