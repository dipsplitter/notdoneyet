local DataTypes = require(script.Parent.DataTypes.DataTypesList)

local Events = {
	[0] = {
		Name = "DataTable",
		Structure = "Middleware_DataTable",
		Process = "DataTable",
	},
	
	[1] = {
		Name = "DataTableCreate",
		Structure = {
			Id = DataTypes.UnsignedByte(),
			Action = DataTypes.Boolean(),
			Name = DataTypes.String(),
			Structure = DataTypes.UnsignedShort(),
		},
	},
	
	[2] = {
		Name = "Seed",
		Structure = {
			Seed = DataTypes.Double(),
		}
	},
	
	[3] = {
		Name = "ItemAction",
		Structure = "Middleware_ItemAction",
	},
	
	[4] = {
		Name = "ItemCreate",
		Structure = "Middleware_ItemCreate",
	},
	
	[5] = {
		Name = "Indicator",
		Structure = "Middleware_Indicator",
	},
	
	[6] = {
		Name = "ChangeClass",
		Structure = "Middleware_ChangeClass"
	},
	
	[7] = {
		Name = "CreateVisual",
		Structure = "Middleware_CreateVisual",
	},
	
	[8] = {
		Name = "VisualEvent",
		Structure = "Middleware_VisualEvent",
	},
	
	[9] = {
		Name = "Velocity",
		Structure = {
			Vector = DataTypes.Vector3(),
		},
	},
	
	[10] = {
		Name = "EntitySnapshot",
		Structure = "Middleware_EntitySnapshot",
		Process = "EntitySnapshot",
	},
	
	[11] = {
		Name = "Command",
		Structure = {
			Commands = DataTypes.Array(
				DataTypes.Struct({
					Id = DataTypes.UnsignedInteger(),
					Tick = DataTypes.UnsignedInteger(),
					LatestUpdateTick = DataTypes.UnsignedInteger(),
				})
		)},
		
		Reliability = "Unreliable",
	}
}

return Events
