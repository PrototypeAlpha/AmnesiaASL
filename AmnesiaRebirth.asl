state("AmnesiaRebirth","Steam 1.32/1.04")
{
	int 	 loading	: 0x009E2BF8, 0x130;
	string50 mapName	: 0x009DCBC8, 0x1F8, 0x0;
	byte	 parisWall	: 0x009DCBC8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

state("AmnesiaRebirth","GOG 1.04")
{
	int 	 loading	: 0x00956818, 0x130;
	string50 mapName	: 0x009507E8, 0x1F8, 0x0;
	byte	 parisWall	: 0x009507E8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

state("AmnesiaRebirth","GOG 1.06")
{
	int 	 loading	: 0x00954818, 0x130;
	string50 mapName	: 0x0094E7E8, 0x1F8, 0x0;
	byte	 parisWall	: 0x0094E7E8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

init
{
	var module	= modules.First();
	var name	= module.ModuleName.ToLower();
	var size	= module.ModuleMemorySize;
	
	switch(size)
	{
		case 11214848:
			version = "Steam 1.32/1.04";
			break;
		case 10444800:
			version = "GOG 1.04";
			break;
		case 10436608:
			version = "GOG 1.06";
			break;
		default:
			version = "Unknown";
			var gameMessageText = "Website/launcher you bought the game from\r\n"+name+"="+size;
			var gameMessage = MessageBox.Show(
				"It appears you're running an unknown version of the game.\n\n"+
				"Please @PrototypeAlpha#7561 on the HPL Games Speedrunning discord with "+
				"the following:\n"+gameMessageText+"\n\n"+
				"Press OK to copy the above info to the clipboard and close this message.",
				vars.aslName+" | LiveSplit",
				MessageBoxButtons.OKCancel,MessageBoxIcon.Warning
			);
			if (gameMessage == DialogResult.OK) Clipboard.SetText(gameMessageText);
			break;
	}
	//vars.log("INFO",size+" = " + version); Clipboard.SetText(""+size);
}

startup
{
	settings.Add("fullSplit",true,"Split on level changes (If disabled, will only auto-start and auto-end)");
}

isLoading{ return current.loading == 0; }

start{ return current.mapName == "01_01_plane_wreckage.hpm" && current.loading != 0 && old.loading == 0; }

//reset{ return old.mapName != current.mapName && current.mapName == "01_01_plane_wreckage.hpm"; }

split
{
	// Paris ending, splits on final stage of wall breaking
	if(old.mapName == current.mapName && current.mapName == "04_04_paris.hpm") return current.parisWall == 3 && old.parisWall == 2;
	// Level changes, excluding loading to/from main menu
	return settings["fullSplit"] && old.mapName != current.mapName && old.mapName != "main_menu.hpm" && current.mapName != "main_menu.hpm";
}