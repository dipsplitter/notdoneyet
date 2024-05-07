--!native

local DataType_Numbers = {
	Boolean = {
		Write = function(bufferQueue, value)
			bufferQueue:writeu8(if value then 1 else 0)
		end,

		Read = function(targetBuffer, cursor)
			local bool = if buffer.readu8(targetBuffer, cursor) == 1 then true else false
			
			return bool, 1
		end,
	},
	
	UnsignedByte = {	
		Write = function(bufferQueue, value)
			bufferQueue:writeu8(value)
		end,
		
		Read = function(targetBuffer, cursor)
			return buffer.readu8(targetBuffer, cursor), 1
		end,
	},
	
	Byte = {
		Write = function(bufferQueue, value)
			bufferQueue:writei8(value)
		end,
		
		Read = function(targetBuffer, cursor)
			return buffer.readi8(targetBuffer, cursor), 1
		end,
	},
	
	UnsignedShort = {
		Write = function(bufferQueue, value)
			bufferQueue:writeu16(value)
		end,

		Read = function(targetBuffer, cursor)
			return buffer.readu16(targetBuffer, cursor), 2
		end,
	},
	
	Short = {
		Write = function(bufferQueue, value)
			bufferQueue:writei16(value)
		end,

		Read = function(targetBuffer, cursor)
			return buffer.readi16(targetBuffer, cursor), 2
		end,
	},
	
	UnsignedInteger = {	
		Write = function(bufferQueue, value)
			bufferQueue:writeu32(value)
		end,

		Read = function(targetBuffer, cursor)
			return buffer.readu32(targetBuffer, cursor), 4
		end,
	},
	
	Integer = {
		Write = function(bufferQueue, value)
			bufferQueue:writei32(value)
		end,

		Read = function(targetBuffer, cursor)
			return buffer.readi32(targetBuffer, cursor), 4
		end,
	},
	
	Float = {
		Write = function(bufferQueue, value)
			bufferQueue:writef32(value)
		end,

		Read = function(targetBuffer, cursor)
			return buffer.readf32(targetBuffer, cursor), 4
		end,
	},

	Double = {
		Write = function(bufferQueue, value)
			bufferQueue:writef64(value)
		end,

		Read = function(targetBuffer, cursor)
			return buffer.readf64(targetBuffer, cursor), 8
		end,
	},
	
	VariantInteger = {
		Write = function(bufferQueue, value)
			
		end,
		
		Read = function(targetBuffer, cursor)
			
		end,
	},
}

return DataType_Numbers
