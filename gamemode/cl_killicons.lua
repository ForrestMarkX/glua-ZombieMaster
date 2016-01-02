if not killicon.GetFont then
	killicon.OldAddFont = killicon.AddFont
	killicon.OldAddAlias = killicon.AddAlias
	killicon.OldAdd = killicon.Add

	local storedfonts = {}
	local storedicons = {}

	function killicon.AddFont(sClass, sFont, sLetter, cColor)
		storedfonts[sClass] = {sFont, sLetter, cColor}
		return killicon.OldAddFont(sClass, sFont, sLetter, cColor)
	end

	function killicon.Add(sClass, sTexture, cColor)
		storedicons[sClass] = {sTexture, cColor}
		return killicon.OldAdd(sClass, sTexture, cColor)
	end

	function killicon.AddAlias(sClass, sBaseClass)
		if storedfonts[sClass] then
			return killicon.AddFont(sBaseClass, storedfonts[sClass][1], storedfonts[sClass][2], storedfonts[sClass][3])
		elseif storedicons[sClass] then
			return killicon.Add(sBaseClass, storedicons[sClass][1], storedicons[sClass][2])
		end
	end

	function killicon.Get(sClass)
		return killicon.GetFont(sClass) or killicon.GetIcon(sClass)
	end

	function killicon.GetFont(sClass)
		return storedfonts[sClass]
	end

	function killicon.GetIcon(sClass)
		return storedicons[sClass]
	end
end

killicon.AddFont("weapon_zm_fists", "ZMDeathFonts", "c", color_white)
killicon.AddFont("weapon_zm_mac10", "ZMDeathFonts", "a", color_white)
killicon.AddFont("weapon_zm_molotov", "ZMDeathFonts", "k", color_white)
killicon.AddFont("weapon_zm_pistol", "ZMDeathFonts", "d", color_white)
killicon.AddFont("weapon_zm_revolver", "ZMDeathFonts", "e", color_white)
killicon.AddFont("weapon_zm_rifle", "ZMDeathFonts", "f", color_white)
killicon.AddFont("weapon_zm_shotgun", "ZMDeathFonts", "b", color_white)
killicon.AddFont("weapon_zm_sledge", "ZMDeathFonts", "i", color_white)
killicon.AddFont("weapon_zm_improvised", "ZMDeathFonts", "h", color_white)