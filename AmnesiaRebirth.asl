state("AmnesiaRebirth","Steam 1.31/1.04")
{
	int 	 loading	: 0x009E2BF8, 0x130;
	string50 mapName	: 0x009DCBC8, 0x1F8, 0x0;
	byte	 parisWall	: 0x009DCBC8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

isLoading{ return current.loading == 0; }

start{ return current.mapName == "01_01_plane_wreckage.hpm" && current.loading != 0 && old.loading == 0; }

//reset{ return old.mapName != current.mapName && current.mapName == "01_01_plane_wreckage.hpm"; }

split
{
	// Paris ending, splits on final stage of wall breaking
	if(old.mapName == current.mapName && current.mapName == "04_04_paris.hpm") return current.parisWall == 3 && old.parisWall == 2;
	// Level changes, excluding loading to/from main menu
	return old.mapName != current.mapName && old.mapName != "main_menu.hpm" && current.mapName != "main_menu.hpm";
}
