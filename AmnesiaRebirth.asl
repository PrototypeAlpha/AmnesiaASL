state("AmnesiaRebirth","Steam 1.31")
{
	string50 mapName	: 0x009DCBC8, 0x1F8, 0x0;
	byte	 parisWall	: 0x009DCBC8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

start{ return old.mapName != current.mapName && current.mapName == "01_01_plane_wreckage.hpm"; }

split
{
	if(old.mapName == current.mapName && current.mapName == "04_04_paris.hpm") return current.parisWall == 3 && old.parisWall == 2;
	
	return old.mapName != current.mapName && old.mapName != "main_menu.hpm" && current.mapName != "main_menu.hpm";
}
