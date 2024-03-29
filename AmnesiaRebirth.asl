// Alternative update method:
// Increase or decrease the previous version's base offsets in increments of 1000 until you find a working base address
// (Also try increments of 20 if you don't find anything within +E000)
// If all else fails, then follow the instructions below

// Updating: 
// 1) Open binary in Ghidra
// 2) Analyze the binary (Can skip if you want to do math.. but I am lazy)
// 3) Search > For Instruction Pattern
// 4) Enter Bytes Manually, paste AOB, apply
// 5) Press the O (Mask all operands)
// 6) Search all
// 7) Rip out updated base offset

// loading: 
// First function that used the address was the one I chose
// AOB: 40 53 48 83 ec 20 8b d1 48 8b 0d a9 bd 31 00
// Last instruction, pointer in the MOV

// mapName/parisWall:
// AOB: 48 8b 05 31 ae 98 00 48 8b 90 68 01 00 00 48 8b 82 80 00 00 00 48 85 c0 74 27 80 b8 0c 03 00 00 00
// First instruction, pointer in the MOV
// Note: I suspect you can find the first two offsets for the parisWall here too (168 and 80 at the time of this note)

// Steam
state("AmnesiaRebirth","Steam 1.32")
{
	int 	 loading	: 0x009EAD58, 0x130;
	string32 mapNameS	: 0x009E4D08, 0x1F8;
	string32 mapNameL	: 0x009E4D08, 0x1F8, 0x0;
	byte	 parisWall	: 0x009E4D08, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","Steam 1.23")
{
	int 	 loading	: 0x009E6D58, 0x130;
	string32 mapNameS	: 0x009E0D08, 0x1F8;
	string32 mapNameL	: 0x009E0D08, 0x1F8, 0x0;
	byte	 parisWall	: 0x009E0D08, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","Steam 1.22")
{
	int 	 loading	: 0x009E4D38, 0x130;
	string32 mapNameS	: 0x009DED08, 0x1F8;
	string32 mapNameL	: 0x009DED08, 0x1F8, 0x0;
	byte	 parisWall	: 0x009DED08, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","Steam 1.32/1.04")
{
	int 	 loading	: 0x009E2BF8, 0x130;
	string32 mapNameS	: 0x009DCBC8, 0x1F8;
	string32 mapNameL	: 0x009DCBC8, 0x1F8, 0x0;
	byte	 parisWall	: 0x009DCBC8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

// NoSteam
state("AmnesiaRebirth_NoSteam","NoSteam 1.32")
{
	int 	 loading	: 0x0095C988, 0x130;
	string32 mapNameS	: 0x00956938, 0x1F8;
	string32 mapNameL	: 0x00956938, 0x1F8, 0x0;
	byte	 parisWall	: 0x00956938, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth_NoSteam","NoSteam 1.23")
{
	int 	 loading	: 0x00957988, 0x130;
	string32 mapNameS	: 0x00951938, 0x1F8;
	string32 mapNameL	: 0x00951938, 0x1F8, 0x0;
	byte	 parisWall	: 0x00951938, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth_NoSteam","NoSteam 1.22")
{
	int 	 loading	: 0x00955968, 0x130;
	string32 mapNameS	: 0x0094F938, 0x1F8;
	string32 mapNameL	: 0x0094F938, 0x1F8, 0x0;
	byte	 parisWall	: 0x0094F938, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

// DRM-free
state("AmnesiaRebirth","DRM-free 1.32")
{
	int 	 loading	: 0x0095C988, 0x130;
	string32 mapNameS	: 0x00956938, 0x1F8;
	string32 mapNameL	: 0x00956938, 0x1F8, 0x0;
	byte	 parisWall	: 0x00956938, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","DRM-free 1.23")
{
	int 	 loading	: 0x00957988, 0x130;
	string32 mapNameS	: 0x00951938, 0x1F8;
	string32 mapNameL	: 0x00951938, 0x1F8, 0x0;
	byte	 parisWall	: 0x00951938, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","DRM-free 1.22")
{
	int 	 loading	: 0x00955968, 0x130;
	string32 mapNameS	: 0x0094F938, 0x1F8;
	string32 mapNameL	: 0x0094F938, 0x1F8, 0x0;
	byte	 parisWall	: 0x0094F938, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","DRM-free 1.06")
{
	int 	 loading	: 0x00954818, 0x130;
	string32 mapNameS	: 0x0094E7E8, 0x1F8;
	string32 mapNameL	: 0x0094E7E8, 0x1F8, 0x0;
	byte	 parisWall	: 0x0094E7E8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}
state("AmnesiaRebirth","DRM-free 1.04")
{
	int 	 loading	: 0x00956818, 0x130;
	string32 mapNameS	: 0x009507E8, 0x1F8;
	string32 mapNameL	: 0x009507E8, 0x1F8, 0x0;
	byte	 parisWall	: 0x009507E8, 0x168, 0x80, 0xC8, 0x90, 0x2C;
}

startup
{
	vars.aslName = "AmnesiaASL Rebirth";
	if(timer.CurrentTimingMethod == TimingMethod.RealTime){
		
		var timingMessage = MessageBox.Show(
			"This game uses Game Time (time without loads) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (time INCLUDING loads).\n"+
			"Would you like the timing method to be set to Game Time for you?",
			vars.aslName+" | LiveSplit",
			MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		if (timingMessage == DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
	}
	settings.Add("fullSplit",true,"Split on level changes (If disabled, will only auto-start and auto-end)");
}

init
{
	var module	 = modules.First();
	var name	 = module.ModuleName;
	var size	 = module.ModuleMemorySize;
	
	byte[] exeBytes = new byte[0];
    using (var md5 = System.Security.Cryptography.MD5.Create())
    {
        using (var exe = File.Open(module.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
        {
            exeBytes = md5.ComputeHash(exe); 
        } 
    }
    var hash = exeBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
	
	switch(hash)
	{
		// Steam
		case "1B90C1BB5886341BB0242F35358D142B": version = "Steam 1.32";															break;
		case "7EA8456BACBBACDB00F4B3B813C17C1F": version = "Steam 1.31";															break;
		case "B250AE6785BFE73624B9C2437BAE7330": version = "Steam 1.30";															break;
		case "12412704AD2AB24E934B834DBDA4919A": version = "Steam 1.23";															break;
		case "94A270F2C8BDC42F05B9E95C86C979E8": version = "Steam 1.22";															break;
		case "22F100279E1FA34CD69D4CCCBE59755C": version = "Steam 1.21";															break;
		case "93A53FB004E1B9C1B88F738FCB47DD22": version = "Steam 1.02/1.20";														break;
		case "0A61A4B88CEF7945B52A93980DEF0E74": version = "Steam 1.01/1.10";														break;
		case "A184A26F27A960E7A210BF4B308E83E9": version = "Steam 1.32/1.04";														break;
		case "BF15BF71C2F6780878C0D6370302E6AE": version = "Steam 1.31/1.03";														break;
		// DRM-free
		case "3CA0BD0E3FB85B7D79AC8716E80B1B63": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.32" : "NoSteam 1.32";			break;
		case "739D0189FF71C851B8251F9D043686A3": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.31" : "NoSteam 1.31";			break;
		case "79249DBA396764B4716C3B14E71CD524": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.30" : "NoSteam 1.30";			break;
		case "ADFA03BB715ECD2C7A5BE71E8C2D2984": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.23" : "NoSteam 1.23";			break;
		case "FD5B1F596261E7761FCBE07DFFC8E22F": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.22" : "NoSteam 1.22";			break;
		case "8045F461648FBF756BC63AE00223536A": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.21" : "NoSteam 1.21";			break;
		case "8849E1D792FA56E629230A79603D1717": version = name == "AmnesiaRebirth.exe" ? "DRM-free 1.20" : "NoSteam 1.02/1.20";	break;
		
		case "AFEFC36F4EBEB560B684D7B441B69EDE": version = "NoSteam 1.01/1.10";														break;
		case "F6AF6853CB4C5C7D73B5B80E35A0793E": version = "DRM-free 1.10/1.11";													break;
		case "99409759B72E9A4B3D3E4131DF837758": version = "DRM-free 1.06";															break;
		case "92BAA3E8DCA3D09B1457A9AABFC2906F": version = "DRM-free 1.04";															break;
		default:
			var gameMessageText = name+","+size+","+hash;
			var gameMessage = MessageBox.Show(
				"It appears you're running an unknown version of the game.\n\n"+
				"Please @PrototypeAlpha#7561 on the HPL Games Speedrunning discord with "+
				"the following:\n"+gameMessageText+"\n\n"+
				"Press OK to copy the above info to the clipboard and close this message.",
				vars.aslName+" | LiveSplit",
				MessageBoxButtons.OKCancel,MessageBoxIcon.Warning
			);
			if (gameMessage == DialogResult.OK) Clipboard.SetText(gameMessageText);
			version = "Unknown"; break;
	}
	print("["+vars.aslName+"] name = "+name);
	print("["+vars.aslName+"] size = "+size);
	print("["+vars.aslName+"] md5 = "+hash);
	print("["+vars.aslName+"] version = "+version);
	
}

update{ current.mapName = current.mapNameS != null && current.mapNameS.EndsWith(".hpm") ? current.mapNameS : current.mapNameL; }

isLoading{ return version != "Unknown" && current.loading == 0; }

start{ return current.mapName == "01_01_plane_wreckage.hpm" && current.loading > old.loading; }

//reset{ return old.mapName != current.mapName && current.mapName == "01_01_plane_wreckage.hpm"; }

split
{
	// Paris ending, splits on final stage of wall breaking
	if(old.mapName == current.mapName && current.mapName == "04_04_paris.hpm") return current.parisWall == 3 && old.parisWall == 2;
	// Level changes, excluding loading to/from main menu
	return settings["fullSplit"] && old.mapName != current.mapName && old.mapName != "main_menu.hpm" && current.mapName != "main_menu.hpm";
}