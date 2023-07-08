fx_version 'cerulean'
game 'gta5'

author 'Mercy'
description 'Duty Vehicles'

lua54 'yes'

files {
	-- // Sirens
	'metas/Sirens/carcols.meta',
	-- // Police
	'metas/[Police]/**/handling.meta',
	'metas/[Police]/**/carcols.meta',
	'metas/[Police]/**/vehicles.meta',
	'metas/[Police]/**/carvariations.meta',
	'metas/[Police]/**/vehiclelayouts.meta',
	-- // Ambulance
	'metas/[Ems]/**/handling.meta',
	'metas/[Ems]/**/carcols.meta',
	'metas/[Ems]/**/vehicles.meta',
	'metas/[Ems]/**/carvariations.meta',
	'metas/[Ems]/**/vehiclelayouts.meta'
}

client_script 'vehicle_names.lua'

-- // Sirens
data_file 'CARCOLS_FILE' 'metas/Sirens/carcols.meta'

-- // Police
data_file 'HANDLING_FILE' 'metas/[Police]/**/handling.meta'
data_file 'CARCOLS_FILE' 'metas/[Police]/**/carcols.meta'
data_file 'VEHICLE_METADATA_FILE' 'metas/[Police]/**/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'metas/[Police]/**/carvariations.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'metas/[Police]/**/vehiclelayouts.meta'
-- // Ambulance
data_file 'HANDLING_FILE' 'metas/[Ems]/**/handling.meta'
data_file 'CARCOLS_FILE' 'metas/[Ems]/**/carcols.meta'
data_file 'VEHICLE_METADATA_FILE' 'metas/[Ems]/**/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'metas/[Ems]/**/carvariations.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'metas/[Ems]/**/vehiclelayouts.meta'