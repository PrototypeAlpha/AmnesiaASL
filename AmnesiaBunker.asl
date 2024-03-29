// Updating (proto's way, required for game pass):
// 1) Open process in Cheat Engine if it isn't already, then click Memory View
// 2) View > Referenced Strings, then choose Yes to the prompt to run the Code Dissector
// 3) After the scan is completed, search for the string
// 4) Keep pressing F3 until the required string is highlighted
// 5) Double click the address on the right and go back to the Memory Viewer window
// 6) Find the address in the Opcode column

// Updating (sy's way): 
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
// Possible Signature: 48 83 ec 28 8b d1 48 8b 0d 8b c9 27 00 e8 9e a1 cc ff 48 8b c8 48 83 78 18 10 72 03
// Search > Instruction Patterns > O (Mask all operands) > Search. Address in 2nd MOV

// base:
// In Ghidra, search for string "LuxAchievementHandler" and select the reference at the top of the list
// Address will be in a MOV below
// TODO Find SigScan target so we can automate grabbing the new address
// Possible Signature: 48 8b 0d cd 05 94 00 e8 40 15 09 00 84 c0 74 28 48 8b 0d bd 05 94 00 e8 60 15 09 00
// Search > Instruction Patterns > O (Mask all operands) > Search. Address in first MOV

// Steam
state("AmnesiaTheBunker","Steam 1.31")
{
	int 	 menuLoad   : 0x009A6D18, 0x130;
	bool 	 streamLoad : 0x009928F8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x009928F8, 0x178, 0x268;
	string32 mapNameL   : 0x009928F8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x009928F8, 0x800, 0x78, 0xC8, 0x90, 0x1BC; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","Steam 1.3")
{
	int 	 menuLoad   : 0x009A6D18, 0x130;
	bool 	 streamLoad : 0x009928F8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x009928F8, 0x178, 0x268;
	string32 mapNameL   : 0x009928F8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x009928F8, 0x800, 0x78, 0xC8, 0x90, 0x1BC; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","Steam 1.22")
{
	int 	 menuLoad   : 0x009A5D18, 0x130;
	bool 	 streamLoad : 0x009918F8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x009918F8, 0x178, 0x268;
	string32 mapNameL   : 0x009918F8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x009918F8, 0x800, 0x78, 0xC8, 0x90, 0x1B4; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","Steam 1.10")
{
	int 	 menuLoad   : 0x009A1CA8, 0x130;
	bool 	 streamLoad : 0x0098D888, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0098D888, 0x178, 0x268;
	string32 mapNameL   : 0x0098D888, 0x178, 0x268, 0x0;
	int      pBodyState : 0x0098D888, 0x7D0, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","Steam 1.09")
{
	int 	 menuLoad   : 0x009A2CA8, 0x130;
	bool 	 streamLoad : 0x0098E888, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0098E888, 0x180, 0x268;
	string32 mapNameL   : 0x0098E888, 0x180, 0x268, 0x0;
	int      pBodyState : 0x0098E888, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
// NoSteam
state("AmnesiaTheBunker_NoSteam","NoSteam 1.3")
{
	int 	 menuLoad   : 0x0096F8D8, 0x130;
	bool 	 streamLoad : 0x0095B4B8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0095B4B8, 0x178, 0x268;
	string32 mapNameL   : 0x0095B4B8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x0095B4B8, 0x800, 0x78, 0xC8, 0x90, 0x1BC; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker_NoSteam","NoSteam 1.31")
{
	int 	 menuLoad   : 0x0096F8D8, 0x130;
	bool 	 streamLoad : 0x0095B4B8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0095B4B8, 0x178, 0x268;
	string32 mapNameL   : 0x0095B4B8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x0095B4B8, 0x800, 0x78, 0xC8, 0x90, 0x1BC; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker_NoSteam","NoSteam 1.22")
{
	int 	 menuLoad   : 0x0096E8D8, 0x130;
	bool 	 streamLoad : 0x0095A4B8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0095A4B8, 0x178, 0x268;
	string32 mapNameL   : 0x0095A4B8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x0095A4B8, 0x800, 0x78, 0xC8, 0x90, 0x1B4; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker_NoSteam","NoSteam 1.10")
{
	int 	 menuLoad   : 0x0096A868, 0x130;
	bool 	 streamLoad : 0x00956448, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00956448, 0x178, 0x268;
	string32 mapNameL   : 0x00956448, 0x178, 0x268, 0x0;
	int      pBodyState : 0x00956448, 0x7D0, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker_NoSteam","NoSteam 1.09")
{
	int 	 menuLoad   : 0x0096A868, 0x130;
	bool 	 streamLoad : 0x00956448, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00956448, 0x180, 0x268;
	string32 mapNameL   : 0x00956448, 0x180, 0x268, 0x0;
	int      pBodyState : 0x00956448, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
// DRM-free
state("AmnesiaTheBunker","DRM-free 1.31")
{
	int 	 menuLoad   : 0x0096F8D8, 0x130;
	bool 	 streamLoad : 0x0095B4B8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0095B4B8, 0x178, 0x268;
	string32 mapNameL   : 0x0095B4B8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x0095B4B8, 0x800, 0x78, 0xC8, 0x90, 0x1BC; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","DRM-free 1.3")
{
	int 	 menuLoad   : 0x0096F8D8, 0x130;
	bool 	 streamLoad : 0x0095B4B8, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x0095B4B8, 0x178, 0x268;
	string32 mapNameL   : 0x0095B4B8, 0x178, 0x268, 0x0;
	int      pBodyState : 0x0095B4B8, 0x800, 0x78, 0xC8, 0x90, 0x1BC; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","DRM-free 1.22")
{
	int 	 menuLoad   : 0x0096D888, 0x130;
	bool 	 streamLoad : 0x00959468, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00959468, 0x178, 0x268;
	string32 mapNameL   : 0x00959468, 0x178, 0x268, 0x0;
	int      pBodyState : 0x00959468, 0x800, 0x78, 0xC8, 0x90, 0x1B4; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","DRM-free 1.10")
{
	int 	 menuLoad   : 0x0096A868, 0x130;
	bool 	 streamLoad : 0x00956448, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00956448, 0x178, 0x268;
	string32 mapNameL   : 0x00956448, 0x178, 0x268, 0x0;
	int      pBodyState : 0x00956448, 0x7D0, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
state("AmnesiaTheBunker","DRM-free 1.09")
{
	int 	 menuLoad   : 0x0096A868, 0x130;
	bool 	 streamLoad : 0x00956448, 0x180, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00956448, 0x180, 0x268;
	string32 mapNameL   : 0x00956448, 0x180, 0x268, 0x0;
	int      pBodyState : 0x00956448, 0x7D8, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
}
// Game Pass
state("XBO_AmnesiaTheBunker","Game Pass 1.10 (2023-09-05)")
{
	int 	 menuLoad   : 0x00AA3DF0, 0x130;
	bool 	 streamLoad : 0x00A8ED28, 0x178, 0x260; // 1 = loading, 0 = not loading
	string32 mapNameS   : 0x00A8ED28, 0x178, 0x268;
	string32 mapNameL   : 0x00A8ED28, 0x178, 0x268, 0x0;
	int      pBodyState : 0x00A8ED28, 0x7D0, 0x78, 0xC8, 0x90, 0x1B0; // See ePlayerBodyAnimationState in PlayerBodyAnimationStates.hps (first value is 0)
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
		case "2F055874CE9296CF8C7B82A6F9DB8396":
			version = "Steam 1.31"; break;
		
		case "FB528108E601E5BF247B4F143729EFF7":
			version = "Steam 1.3"; break;
		
		case "74BFA5392A9DED6958D15F02B887B5BC":
			version = "Steam 1.22"; break;
		
		case "166FB9890E70EB764059B97638AA49E3":
			version = "Steam 1.11"; break;
		
		case "B8804E3E74973FB26E3C9E1BAE591153":
		case "6B3F294B0653A34FAC4E6B4698F96376":
			version = "Steam 1.10"; break;
		
		case "FEE703BBCBFB627B7AD9BD06EC5176D7":
			version = "Steam 1.09"; break;
		// DRM-free
		case "2A8F3C4FD2F9E324280EF32666D5A1CD":
			version = name == "AmnesiaTheBunker.exe" ? "DRM-free 1.31" : "NoSteam 1.31"; break;
		
		case "8BC01851D3232F274A01BDF31C10DB91":
			version = name == "AmnesiaTheBunker.exe" ? "DRM-free 1.3" : "NoSteam 1.3"; break;
		
		case "282991FA31873B2F271BCC7D6CECDF76":
			version = "NoSteam 1.22"; break;
		
		case "76F7D4CC0D94BE149366D99F18DC163F":
			version = "DRM-free 1.22"; break;
		
		case "2DD1D4CAF404B20A2E4C33A5794B5E67":
			version = name == "AmnesiaTheBunker.exe" ? "DRM-free 1.10" : "NoSteam 1.11"; break;
		
		case "5F5D16452F87E6AB4676919A49E45BD6":
		case "354658E840A742F63125DC676D0ECDE6":
			version = name == "AmnesiaTheBunker.exe" ? "DRM-free 1.10" : "NoSteam 1.10"; break;
		
		case "81DEC8D42F539E7A2FB8C55F685ABF11":
			version = name == "AmnesiaTheBunker.exe" ? "DRM-free 1.09" : "NoSteam 1.09"; break;
		// Game Pass
		case "XBO_12443648":
			version = "Game Pass 1.10 (2023-09-05)"; break;
		
		default:
			var gameMessageText = name+","+size+","+hash;
			var gameMessage = MessageBox.Show(
				"It appears you're running an unknown version of the game.\n"+
				"Some features of the autosplitter may not work.\n\n"+
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
		//print("["+vars.aslName+"] "+vars.prevMap+" -> "+current.mapName);
	}
}

isLoading
{
	if(version == "Unknown")
		return false;
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
