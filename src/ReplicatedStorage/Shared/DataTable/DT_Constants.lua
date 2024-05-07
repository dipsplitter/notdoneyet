local DT_Constants = {
	MaxClientDataTables = 2^16,
	--IdBits = 16,
	--BitstreamByteLengthBits = 15,
	
	StructureIdBits = 16,
	
	Events = {
		"DataTable",
		"EntitySnapshot",
	},
	
	IgnoreMainSendProcess = {
		EntitySnapshot = true,
	},
	
	IgnoreMainReceiveProcess = {
		EntitySnapshot = true,
	}
}

return DT_Constants
