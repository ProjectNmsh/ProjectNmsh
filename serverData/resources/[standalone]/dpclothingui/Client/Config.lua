Config = {
	Language = "en",					-- You can change the language here. I translated some with a tool online so they might not be 100% accurate. Let me know!
	ExtrasEnabled = true,				-- This toggles the extra commands (Shirt, Pants) in case you dont want your players stripping their clothes for whatever reason.
	Debug = false,						-- Enables logging and on screen display of what your character is wearing.
	NUI = {
		AllowInCars = false,			-- Allow the GUI in cars?
		AllowWhenRagdolled = false,			-- Allow the GUI when ragdolled?
		DefultKey = 'Y', 				-- Change the GUI key here.
		Sound = true,					-- You can disable sound in the GUI here.
		Camera = true,					-- You can disable sound in the GUI here.
		keybinds = 'none',
	}
}


--[[
		Here are the commands to be generated, this is the layout.

		["commandname"] = {
			Func = Function that gets triggered.
			Sprite = You probably shouldnt change this.
			Desc = Description to be added in chat.
			Button = The position of the button in the GUI.
			Name = The display string for the GUI, we grab this with the Lang function, so they can be changed above.
		},

		You can change the command name if you wish, do so in the language file Locales/LANGUAGE.lua,
		Some alternatives i thought of were :

			Top   : Jacket, Hoodie.
			Hair  : Bun, Ponytail, Hairdown.
			Visor : Brim, Cap.

		And then for the props you can change em to something real short to make it easy for people to use.

			Glasses : G.
			Hat : H.
			Mask : M.
			Visor : V.
]]--

Config.Commands = {
	[Lang("TOP")] = {
		Func = function() ToggleClothing("Top") end,
		Sprite = "top",
		Desc = Lang("Top2"),
		Button = 1,
		Name = Lang("Top")
	},
	[Lang("GLOVES")] = {
		Func = function() ToggleClothing("Gloves") end,
		Sprite = "gloves",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Gloves"))),
		Button = 2,
		Name = Lang("Gloves")
	},
	[Lang("VISOR")] = {
		Func = function() ToggleProps("Visor") end,
		Sprite = "visor",
		Desc = Lang("Visor2"),
		Button = 3,
		Name = Lang("Visor")
	},
	[Lang("BAG")] = {
		Func = function() ToggleClothing("Bag") end,
		Sprite = "bag",
		Desc = Lang("Bag2"),
		Button = 8,
		Name = Lang("Bag")
	},
	[Lang("SHOES")] = {
		Func = function() ToggleClothing("Shoes") end,
		Sprite = "shoes",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Shoes"))),
		Button = 5,
		Name = Lang("Shoes")
	},
	[Lang("VEST")] = {
		Func = function() ToggleClothing("Vest") end,
		Sprite = "vest",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Vest"))),
		Button = 14,
		Name = Lang("Vest")
	},
	[Lang("HAIR")] = {
		Func = function() ToggleClothing("Hair") end,
		Sprite = "hair",
		Desc = Lang("Hair2"),
		Button = 7,
		Name = Lang("Hair")
	},
	[Lang("HAT")] = {
		Func = function() ToggleProps("Hat") end,
		Sprite = "hat",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Hat"))),
		Button = 4,
		Name = Lang("Hat")
	},
	[Lang("GLASSES")] = {
		Func = function() ToggleProps("Glasses") end,
		Sprite = "glasses",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Glasses"))),
		Button = 9,
		Name = Lang("Glasses")
	},
	[Lang("EAR")] = {
		Func = function() ToggleProps("Ear") end,
		Sprite = "ear",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Ear2"))),
		Button = 10,
		Name = Lang("Ear")
	},
	[Lang("NECK")] = {
		Func = function() ToggleClothing("Neck") end,
		Sprite = "neck",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Neck2"))),
		Button = 11,
		Name = Lang("Neck")
	},
	[Lang("WATCH")] = {
		Func = function() ToggleProps("Watch") end,
		Sprite = "watch",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Watch"))),
		Button = 12,
		Name = Lang("Watch"),
		Rotation = 5.0
	},
	[Lang("BRACELET")] = {
		Func = function() ToggleProps("Bracelet") end,
		Sprite = "bracelet",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Bracelet"))),
		Button = 13,
		Name = Lang("Bracelet")
	},
	[Lang("MASK")] = {
		Func = function() ToggleClothing("Mask") end,
		Sprite = "mask",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Mask"))),
		Button = 6,
		Name = Lang("Mask")
	}
}

Config.ExtraCommands = {
	[Lang("PANTS")] = {
		Func = function() ToggleClothing("Pants", true) end,
		Sprite = "pants",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Pants"))),
		Name = Lang("Pants"),
		OffsetX = -0.04,
		OffsetY = 0.0,
	},
	[Lang("SHIRT")] = {
		Func = function() ToggleClothing("Shirt", true) end,
		Sprite = "shirt",
		Desc = string.format(Lang("TakeOffOn"), string.lower(Lang("Shirt"))),
		Name = Lang("Shirt"),
		OffsetX = 0.04,
		OffsetY = 0.0,
	},
	[Lang("RESET")] = {
		Func = function() if not ResetClothing() then Notify(Lang("AlreadyWearing")) end end,
		Sprite = "reset",
		Desc = Lang("Reset2"),
		Name = Lang("Reset"),
		OffsetX = 0.12,
		OffsetY = 0.2,
	},
}