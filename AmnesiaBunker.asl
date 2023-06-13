// Updating: 
// 1) Open binary in Ghidra
// 2) Analyze the binary (Can skip if you want to do math.. but I am lazy)
// 3) Search > For Instruction Pattern
// 4) Enter Bytes Manually, paste AOB, apply
// 5) Press the O (Mask all operands)
// 6) Search all
// 7) Rip out updated base offset

// menuLoad:
// In Ghidra, search for string "cScript" and select the only reference in the list
// Address will be in a MOV above
// TODO Find SigScan target so we can automate grabbing the new address

// base:
// In Ghidra, search for string "LuxAchievementHandler" and select the reference at the top of the list
// Address will be in a MOV below
// TODO Find SigScan target so we can automate grabbing the new address

// Steam
state("AmnesiaTheBunker","Steam 1.09")
{
	int 	 menuLoad   : 0x009A2CA8, 0x130;
	bool 	 streamLoad : 0x0098E888, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0098E888, 0x180, 0x268;
	string32 mapNameL   : 0x0098E888, 0x180, 0x268, 0x0;
	int      pBodyState : 0x0098E888, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker_Demo_Steam","Demo")
{
	int 	 menuLoad   : 0x0099CB38, 0x130;
	bool 	 streamLoad : 0x00988718, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00988718, 0x180, 0x268;
	string32 mapNameL   : 0x00988718, 0x180, 0x268, 0x0;
	int      pBodyState : 0x00988718, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
// NoSteam
state("AmnesiaTheBunker_NoSteam","NoSteam 1.09")
{
	int 	 menuLoad   : 0x0096A868, 0x130;
	bool 	 streamLoad : 0x00956448, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00956448, 0x180, 0x268;
	string32 mapNameL   : 0x00956448, 0x180, 0x268, 0x0;
	int      pBodyState : 0x00956448, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
// DRM-free
state("AmnesiaTheBunker","DRM-free 1.09")
{
	int 	 menuLoad   : 0x0096A868, 0x130;
	bool 	 streamLoad : 0x00956448, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00956448, 0x180, 0x268;
	string32 mapNameL   : 0x00956448, 0x180, 0x268, 0x0;
	int      pBodyState : 0x00956448, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
// Game Pass
state("XBO_AmnesiaTheBunker","Game Pass 1.09")
{
	int 	 menuLoad   : 0x00AA4C90, 0x130;
	bool 	 streamLoad : 0x00A8FBC8, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00A8FBC8, 0x180, 0x268;
	string32 mapNameL   : 0x00A8FBC8, 0x180, 0x268, 0x0;
	int      pBodyState : 0x00A8FBC8, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}

startup
{
	vars.aslName = "AmnesiaASL Bunker";
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
	
	settings.Add("fullSplit",false,"Split on level changes (If disabled, will only auto-start and auto-end)");
}

init
{
	var module	 = modules.First();
	var name	 = module.ModuleName;
	var size	 = module.ModuleMemorySize;
	var hash	 = "";
	
	if(name == "XBO_AmnesiaTheBunker.exe"){ hash = "XBO_"+size; }
	else
	{
		byte[] exeBytes = new byte[0];
		using (var md5 = System.Security.Cryptography.MD5.Create())
		{
			using (var exe = File.Open(module.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
			{
				exeBytes = md5.ComputeHash(exe); 
			} 
		}
		hash = exeBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
	}
	
	switch(hash)
	{
		// Steam
		case "FEE703BBCBFB627B7AD9BD06EC5176D7": version = "Steam 1.09"; break;
		
		case "792B3D0370025556BD644DDDBB6E0BC3": version = "Demo 1.04.1"; break;
		case "C40D438D5B0C28A89660AAA805F0B65F": //Debug enabled
		case "A2670B4BFFD1391E92D62F68AED4B35C": version = "Demo 1.04.0"; break;
		// DRM-free
		case "81DEC8D42F539E7A2FB8C55F685ABF11": version = name == "AmnesiaTheBunker.exe" ? "DRM-free 1.09" : "NoSteam 1.09"; break;
		// Game Pass
		case "XBO_12447744": version = "Game Pass 1.09"; break;
		default:
			var gameMessageText = name+","+size+","+hash;
			var gameMessage = MessageBox.Show(
				"It appears you're running an unknown version of the game.\n\n"+
				"Please @PrototypeAlpha on the HPL Games Speedrunning discord with "+
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
	
	vars.prevMap = "";
}

update
{
	current.mapName = current.mapNameS != null && current.mapNameS.EndsWith(".hpm") ? current.mapNameS : current.mapNameL;
	
	if(vars.prevMap == "")
		vars.prevMap = current.mapName;
	if(current.mapName != old.mapName && current.mapName.EndsWith(".hpm"))
	{
		vars.prevMap = old.mapName;
		print("["+vars.aslName+"] "+vars.prevMap+" -> "+current.mapName);
	}
}

isLoading
{
	if(version == "Unknown")
		return;
	else 
		return current.menuLoad == 0 || current.streamLoad;
}

start
{
	// Start on loading into the bunker
	return vars.prevMap == "main_menu.hpm" && current.mapName == "officer_hub.hpm" && current.menuLoad > old.menuLoad;
}

//reset{ return old.mapName != current.mapName && current.mapName == "officer_hub.hpm"; }

split
{
	if(old.mapName == current.mapName && current.mapName == "arena.hpm") 
		return current.pBodyState == 7 && old.pBodyState == 2;
	
	// Level changes, excluding loading to/from main menu
	return settings["fullSplit"] && old.mapName != current.mapName && old.mapName != "main_menu.hpm" && current.mapName != "main_menu.hpm";
}
