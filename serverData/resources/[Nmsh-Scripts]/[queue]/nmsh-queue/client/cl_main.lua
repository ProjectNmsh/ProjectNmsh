-- Threads

CreateThread(function()
	while true do 
		Wait(0);
		if NetworkIsSessionStarted() then 
			TriggerServerEvent('nmsh-queue/server/activated'); -- They got past queue, deactivate them in it
			return 
		end
	end
end)