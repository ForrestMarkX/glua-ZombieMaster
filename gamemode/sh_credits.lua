GM.Credits = {
	{
		Name = "Forrest Mark X", 
		SteamID = "STEAM_0:0:18807892", 
		Website = "http://steamcommunity.com/id/ForrestMarkX/", 
		Description = "Programmer"
	},
	{
		Name = "William \"JetBoom\" Moodhe", 
		SteamID = "STEAM_0:1:3307510", 
		Website = "http://www.noxiousnet.com", 
		Description = "Code snippets from Zombie Survival"
	},
	{
		Name = "Chewgum", 
		SteamID = "STEAM_0:0:8232794", 
		Website = "", 
		Description = "Vestige gamemode code"
	},
	{
		Name = "Mka0207", 
		SteamID = "STEAM_0:0:18000855", 
		Website = "http://steamcommunity.com/id/mka0207/myworkshopfiles", 
		Description = "Building the base and icon work"
	},
	{
		Name = "AzoNa, Gabil", 
		SteamID = "", 
		Website = "", 
		Description = "French translation"
	},
	{
		Name = "FoxHound", 
		SteamID = "STEAM_0:0:54424319",
		Website = "", 
		Description = "English (UK) translation"
	},
	{
		Name = "plianes766", 
		SteamID = "STEAM_0:1:77685948", 
		Website = "", 
		Description = "Chinese (Traditional) translation"
	},
	{
		Name = "Navi", 
		SteamID = "STEAM_0:1:19573596", 
		Website = "", 
		Description = "Korean translation"
	},
	{
		Name = "Kit Ballard, RS689", 
		SteamID = "", 
		Website = "", 
		Description = "German translation"
	},
	{
		Name = "Brendan Tan", 
		SteamID = "STEAM_0:1:52431091", 
		Website = "", 
		Description = "Chinese (Simplified) translation"
	},
	{
		Name = "Marco", 
		SteamID = "STEAM_0:0:7621671", 
		Website = "", 
		Description = "Swedish translation"
	},
	{
		Name = "Der eisenballs", 
		SteamID = "", 
		Website = "", 
		Description = "Hebrew translation"
	},
	{
		Name = "Comic King", 
		SteamID = "", 
		Website = "", 
		Description = "Croatian & Serbian translation"
	},
	{
		Name = "Gabi", 
		SteamID = "STEAM_0:0:35752130", 
		Website = "", 
		Description = "Spanish translation"
	},
	{
		Name = "zamboni", 
		SteamID = "STEAM_0:1:48113854", 
		Website = "", 
		Description = "HL2 Quick Info code"
	}
}

GM.ContributorList = {}
for _, credit in ipairs(GM.Credits) do
	GM.ContributorList[credit.SteamID] = credit.Name
end