local ItemProperties = {}

function ItemProperties.EquipsInstantly(item)
	return item.DataTable:GetProperty("EquipSpeed") == nil
end

function ItemProperties.UnequipsInstantly(item)
	return item.DataTable:GetProperty("UnequipSpeed") == nil
end

return ItemProperties
