state("aamfp","Steam 1.01")
{
	byte 	loading1 	 : 0x7664E4, 0x38, 0x7C, 0x4;
	byte 	loading2	 : 0x7664E4, 0x38, 0x7C;
	
	string9 map			 : 0x74EA04, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74EA04, 0x84, 0x58;
	float 	loading		 : 0x74EA04, 0xAC, 0x164;
}

state("aamfp","NoDRM 1.01")
{
	byte 	loading1 	 : 0x7664E4, 0x38, 0x7C, 0x4;
	byte 	loading2	 : 0x7664E4, 0x38, 0x7C;
	
	string9 map			 : 0x74CA04, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74CA04, 0x84, 0x58;
	float 	loading		 : 0x74CA04, 0xAC, 0x164;
}

state("aamfp_NoSteam","NoSteam 1.03")
{
	byte 	loading1 	 : 0x76E99C, 0x38, 0x7C, 0x4;
	byte 	loading2	 : 0x76E99C, 0x38, 0x7C;
	
	string9 map			 : 0x74FB84, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74FB84, 0x84, 0x58;
	float 	loading		 : 0x74FB84, 0xAC, 0x164;
}

state("aamfp","Steam 1.03")
{
	byte 	loading1 	 : 0x76984C, 0x38, 0x7C, 0x4;
	byte 	loading2	 : 0x76984C, 0x38, 0x7C;
	
	string9 map			 : 0x754CD4, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x754CD4, 0x84, 0x58;
	float 	loading		 : 0x754CD4, 0xAC, 0x164;
}

startup{
	vars.aslName = "AmnesiaASL AMFP";
	if(timer.CurrentTimingMethod == TimingMethod.RealTime){
		
		var timingMessage = MessageBox.Show(
			"This game uses Game Time (time without loads) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (time INCLUDING loads).\n"+
			"Would you like the timing method to be set to Game Time for you?",
			vars.aslName+" | LiveSplit",
			MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		if (timingMessage == DialogResult.Yes)
			timer.CurrentTimingMethod = TimingMethod.GameTime;
	}
	
	// Stores previous map
	vars.lastMap = "";
	vars.injected = false;
	
	settings.Add("fullSplit",true,"Split on level changes (If disabled, will only auto-start and auto-end)");
	settings.Add("autoend",false,"[EXPERIMENTAL] Enable auto-end. Requires editing game files.");
	settings.Add("autoend2",false,"See: https://github.com/PrototypeAlpha/AmnesiaASL/commit/f2da42b093bbb255055c9ce1c73f8272843bf249","autoend");
	
	vars.log = (Action<string,string>)((lvl,text) => {
		print("["+vars.aslName+"] "+lvl+": "+text.Replace("-"," ")); 
	});
	
	// Copy bytes from one address to another
	// Params:  game process, address of bytes to copy, length of bytes to copy, address to copy bytes to
	// Returns: boolean result of WriteBytes
	vars.CopyMemory = (Func<Process, IntPtr, int, IntPtr, bool>)((proc, src, len, dest) =>
	{
        var bytes = proc.ReadBytes(src, len);
		return proc.WriteBytes(dest, bytes);
	});
	
	// Write MOV instruction
	// Params:  game process, address to write instruction to, length of bytes to overwrite, address to change byte at, byte to set
	// Returns: boolean result of WriteBytes
	vars.WriteMov = (Func<Process, IntPtr, int, IntPtr, byte[], bool>)((proc, src, len, dest, val) =>
	{
		var bytes = proc.ReadBytes(src, len);
		var newBytes = new List<byte>(new byte[] { 0xC7, 0x05 });
		
		var address = BitConverter.GetBytes((int) dest);
		
		newBytes.AddRange(address);
		newBytes.AddRange(val);
		
		// nop the leftover bytes
		int extraBytes = len - newBytes.Count();
		if (extraBytes > 0)
		{
			var nops = Enumerable.Repeat((byte) 0x90, extraBytes).ToArray();
			newBytes.AddRange(nops);
		}
		
		return proc.WriteBytes(src, newBytes.ToArray());
	});
	
	vars.sigLeave = new SigScanTarget(3, "89 45 ?? A1 ?? ?? ?? ?? 8B 88"); // AOB signature for OnLeave. Use the address at A1
}

shutdown
{
	if(game != null && vars.injected)
	{
		// Replace injected code with the original code
		game.Suspend();
		vars.log("DEBUG","Restoring original code");
		vars.CopyMemory(game, (IntPtr) vars.origLeave, 5, (IntPtr) vars.ptrLeave);
		game.FreeMemory((IntPtr) vars.aslMem);
		vars.injected = false;
		vars.log("DEBUG","Restored original code");
		game.Resume();
	}
}

init 
{	
	var module = modules.First();
	var name = module.ModuleName.ToLower();
	// Fix for rare occasions when NTDLL is loaded first
	if(!name.Contains("amfp")) return;
	
	var baseAddr = module.BaseAddress;
	var size = module.ModuleMemorySize;
	vars.lastMap = "";
	vars.injected = false;
	
	var loadPtrBase = 0x0;
	
    switch(size)
    {
		case 8585216:
			version = "NoDRM 1.01";
			loadPtrBase = 0x74CA04;
			break;
		case 8593408:
			version = "Steam 1.01";
			loadPtrBase = 0x74EA04;
			break;
		case 8597504:
			version = "NoSteam 1.03";
			loadPtrBase = 0x74FB84;
			break;
		case 8871936:
			version = "Steam 1.03";
			loadPtrBase = 0x754CD4;
			break;
		default:
			version = "Unknown";
			loadPtrBase = name == "amfp.exe" ? 0x74CA04 : 0x74FB84;
			break;
	};
	
	vars.log("INFO",size+" = " + version);
	
	if(version == "Unknown"){
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
	}
	
	var loadingPtr = IntPtr.Zero;
	new DeepPointer(loadPtrBase, 0xAC, 0x164).DerefOffsets(game, out loadingPtr);
	if(version != "Unknown" && loadingPtr == IntPtr.Zero){
		Thread.Sleep(2000);
		throw new Exception("Not fully connected to game "+name);
	}
	
	// Allocate memory for our code instead of looking for a code cave
	vars.log("DEBUG","Allocating memory...");
	var aslMem = vars.aslMem = game.AllocateMemory(32);
	
	vars.log("DEBUG","aslMem address: "+aslMem.ToString("X8"));
	
	var scanner = new SignatureScanner(game, baseAddr, size);
	
	// Scan memory for leave signature
	IntPtr scanLeave = scanner.Scan((SigScanTarget) vars.sigLeave);
	vars.ptrLeave = scanLeave;
	
	if(scanLeave == IntPtr.Zero)
		vars.log("ERROR","Can't find signatures. Unknown game version?");
	else
	{
			vars.log("INFO","Starting inject");
			var addrLeave = BitConverter.GetBytes((int) scanLeave).Reverse().ToArray();
			vars.log("DEBUG","Leave address: "+scanLeave.ToString("X8"));
			vars.log("DEBUG","Original bytes at Leave address: "+BitConverter.ToString(game.ReadBytes(scanLeave, 5)));
			
			var addr = BitConverter.GetBytes((int) loadingPtr).Reverse().ToArray();
			vars.log("DEBUG","loading float: "+BitConverter.ToString(addr));
			
			IntPtr codeLeave = aslMem;
			vars.WriteMov(game, codeLeave, 10, loadingPtr, new byte[] {0,0,0x80,0x3F});	// Write instruction to set loading to 1.0
			vars.CopyMemory(game, scanLeave, 5, codeLeave+10);			// Write original code
			game.WriteJumpInstruction(codeLeave+10+5, scanLeave+5);		// Write jump out
			game.WriteJumpInstruction(scanLeave, codeLeave);			// Write jump in
			
			vars.injected = true;
			vars.origLeave = codeLeave+10;
			vars.log("INFO","Finished injecting");
	}
}

isLoading{ return current.loading == 1 || current.loading1 != current.loading2; }

start
{
	vars.lastMap = "";
	
	// Set the start offset to 00:00 to force legacy timing (-01:16) to use the new timing
	if(timer.Run.Offset.ToString() != "00:00:00" &&
	  (timer.Run.GameName.ToLower().Contains("amfp") || timer.Run.GameName.ToLower().Contains("pig"))){
		timer.Run.Offset = TimeSpan.Parse("00:00:00");
	}
	if(current.map == "Mansion01") return current.pActive && !old.pActive;
}

reset{ return current.map == "Mansion01" && old.map != current.map; }

update{	if(old.map != null && old.map != "") vars.lastMap = old.map; }

split
{
	if(current.map == "Temple" && settings["autoend"]) return !current.pActive && old.pActive;
	// Prevent splitting when loading from menu
	if(current.loading1 != current.loading2) return;
	
	if(current.map != null && current.map != "" && vars.lastMap != "" && vars.lastMap != current.map)
		vars.log("MAP",current.map+", was "+vars.lastMap);
	
	if(current.map != null && current.map != "" && vars.lastMap != ""){
		if(old.map != null && old.map != "" )
			 return old.map != current.map;
		else return vars.lastMap != current.map;
	}
	
}
