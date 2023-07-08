function test()
     TriggerServerEvent('nmsh-paycheck:server:increase_moeny')
end

CreateThread(function()
     Wait(1000)
     test()
end)
