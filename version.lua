-- CreateThread(function()
-- 	--version check with github latest version
-- 	PerformHttpRequest(
-- 		"https://raw.githubusercontent.com/ProjectNmsh/ProjectNmsh/main/fxmanifest.lua",
-- 		function(err, text, headers)
-- 			if err ~= 200 then
-- 				return
-- 			end
-- 			local version = GetResourceMetadata(GetCurrentResourceName(), "version")
-- 			local latestVersion = string.match(text, '%sversion \"(.-)\"')
-- 			if version ~= latestVersion then
-- 				print("Resource is outdated. Please update " .. GetCurrentResourceName() .. " to the newest version.")
-- 			end
-- 		end,
-- 		"GET"
-- 	)
-- end)