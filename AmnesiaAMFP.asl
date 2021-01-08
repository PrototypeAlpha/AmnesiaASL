state("aamfp","Steam 1.01")
{
	string9 map			 : 0x74EA04, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74EA04, 0x84, 0x58;
}

state("aamfp","NoDRM 1.01")
{
	string9 map			 : 0x74CA04, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74CA04, 0x84, 0x58;
}

state("aamfp_nosteam","NoSteam 1.01")
{
	string9 map			 : 0x74CA04, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74CA04, 0x84, 0x58;
}

state("aamfp","NoDRM 1.03")
{
	string9 map			 : 0x74FB84, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74FB84, 0x84, 0x58;
}

state("aamfp_NoSteam","NoSteam 1.03")
{
	string9 map			 : 0x74FB84, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x74FB84, 0x84, 0x58;
}

state("aamfp","Steam 1.03")
{
	string9 map			 : 0x754CD4, 0x5C, 0x60, 0x38;
	bool 	pActive		 : 0x754CD4, 0x84, 0x58;
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
		var newBytes = new List<byte>(new byte[] { 0xC6, 0x05 });
		
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
	
	vars.sigGametime = new SigScanTarget(0, "8B 8E ?? 00 00 00 C6 45 D3 01");	// AOB signature for Gametime. Use the address at 8B
	vars.sigMapload  = new SigScanTarget(3, "89 45 ?? A1 ?? ?? ?? ?? 8B 88");	// AOB signature for Mapload. Use the address at A1
	vars.sigMenuload = new SigScanTarget(0, "8B ?? 70 8B ?? 30 6?");			// AOB signature for Menu. Use the address at 8B
}

shutdown
{
	if(game != null && vars.injected)
	{
		// Replace injected code with the original code
		game.Suspend();
		vars.log("DEBUG","Restoring original code");
		
		vars.CopyMemory(game, (IntPtr) vars.origGametime, 6, (IntPtr) vars.ptrGametime);
		vars.log("DEBUG","Bytes at Gametime address: "+BitConverter.ToString(game.ReadBytes((IntPtr) vars.ptrGametime, 6)).Replace("-"," "));
		
		vars.CopyMemory(game, (IntPtr) vars.origMapload, 5, (IntPtr) vars.ptrMapload);
		vars.log("DEBUG","Bytes at Mapload address: "+BitConverter.ToString(game.ReadBytes((IntPtr) vars.ptrMapload, 5)).Replace("-"," "));
		
		vars.CopyMemory(game, (IntPtr) vars.origMenu, 6, (IntPtr) vars.ptrMenuload);
		vars.log("DEBUG","Bytes at Menu address: "+BitConverter.ToString(game.ReadBytes((IntPtr) vars.ptrMenuload, 6)).Replace("-"," "));
		
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
	
    switch(size)
    {
		case 8585216:
			version = name == "aamfp.exe" ? "NoDRM 1.01" : "NoSteam 1.01";
			break;
		case 8593408:
			version = "Steam 1.01";
			break;
		case 8597504:
			version = name == "aamfp.exe" ? "NoDRM 1.03" : "NoSteam 1.03";
			break;
		case 8871936:
			version = "Steam 1.03";
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
	vars.log("INFO",size+" = " + version);
	
	var scanner = new SignatureScanner(game, baseAddr, size);
	
	// Scan memory for Gametime signature
	IntPtr staticGametime	=	vars.ptrGametime	=	scanner.Scan((SigScanTarget) vars.sigGametime);
	// Scan memory for Mapload signature
	IntPtr staticMapload	=	vars.ptrMapload		=	scanner.Scan((SigScanTarget) vars.sigMapload);
	// Scan memory for Menuload signature
	IntPtr staticMenuload	=	vars.ptrMenuload	=	scanner.Scan((SigScanTarget) vars.sigMenuload);
	
	// Allocate memory for our code instead of looking for a code cave
	vars.log("DEBUG","Allocating memory...");
	var aslMem = vars.aslMem = game.AllocateMemory(32);
	
	var addrMem = BitConverter.GetBytes((int) aslMem).Reverse().ToArray();
	vars.log("DEBUG","aslMem address: "+BitConverter.ToString(addrMem).Replace("-",""));
	
	if(staticGametime == IntPtr.Zero || staticMapload == IntPtr.Zero || staticMenuload == IntPtr.Zero){
		vars.log("ERROR","Can't find signatures. Unknown game version?");
		game.FreeMemory((IntPtr) aslMem);
		MessageBox.Show(
			"Can't find signatures.\n"+
			"\nstaticGametime = "+staticGametime+
			"\nstaticMapload = "+staticMapload+
			"\nstaticMenuload = "+staticMenuload,
			vars.aslName+" | LiveSplit",
			MessageBoxButtons.OK,MessageBoxIcon.Error
		);
	}
	else
	{
		vars.log("INFO","Starting inject");
		game.Suspend();
		
		// Set loading var to 1 in case we're just starting up the game
		game.WriteBytes((IntPtr)aslMem, new byte[] {1});
		
		var addrGametime = BitConverter.GetBytes((int) staticGametime).Reverse().ToArray();
		vars.log("DEBUG","Gametime address: "+BitConverter.ToString(addrGametime).Replace("-",""));
		vars.log("DEBUG","Original bytes at Gametime address: "+BitConverter.ToString(game.ReadBytes(staticGametime, 6)).Replace("-"," "));
		
		IntPtr codeGametime = aslMem+1;
		vars.WriteMov(game, codeGametime, 6, aslMem, new byte[] {0});	// Write instruction to set isLoading to 0
		vars.CopyMemory(game, staticGametime, 6, codeGametime+7);		// Write original code
		game.WriteJumpInstruction(codeGametime+7+6, staticGametime+6);	// Write jump out
		game.WriteJumpInstruction(staticGametime, codeGametime);		// Write jump in
		
		var addrMapload = BitConverter.GetBytes((int) staticMapload).Reverse().ToArray();
		vars.log("DEBUG","staticMapload address: "+BitConverter.ToString(addrMapload).Replace("-",""));
		vars.log("DEBUG","Original bytes at staticMapload address: "+BitConverter.ToString(game.ReadBytes(staticMapload, 5)).Replace("-"," "));
		
		IntPtr codeMapload = codeGametime+7+6+5;
		vars.WriteMov(game, codeMapload, 7, aslMem, new byte[] {1});	// Write instruction to set isLoading to 1
		vars.CopyMemory(game, staticMapload, 5, codeMapload+7);			// Write original code
		game.WriteJumpInstruction(codeMapload+7+5, staticMapload+5);	// Write jump out
		game.WriteJumpInstruction(staticMapload, codeMapload);			// Write jump in
		
		var addrMenuload = BitConverter.GetBytes((int) staticMenuload).Reverse().ToArray();
		vars.log("DEBUG","Menu address: "+BitConverter.ToString(addrMenuload).Replace("-",""));
		vars.log("DEBUG","Original bytes at Menu address: "+BitConverter.ToString(game.ReadBytes(staticMenuload, 6)).Replace("-"," "));
		
		IntPtr codeMenuload = codeMapload+7+5+5;
		vars.WriteMov(game, codeMenuload, 6, aslMem, new byte[] {1});	// Write instruction to set isLoading to 1
		vars.CopyMemory(game, staticMenuload, 6, codeMenuload+7);		// Write original code
		game.WriteJumpInstruction(codeMenuload+7+6, staticMenuload+6);	// Write jump out
		game.WriteJumpInstruction(staticMenuload, codeMenuload);		// Write jump in
		
		vars.injected = true;
		
		vars.origGametime = codeGametime+7;
		vars.origMapload  = codeMapload+7;
		vars.origMenu     = codeMenuload+7;
		
		vars.log("INFO","Finished injecting");
		game.Resume();
	}
	
	vars.isLoading = new MemoryWatcher<bool>(aslMem);
}

isLoading{ return vars.isLoading.Current; }

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

update
{
	vars.isLoading.Update(game);
	if(current.map != vars.lastMap && old.map != null && old.map != "") vars.lastMap = old.map;
}

split
{
	if(current.map != old.map && current.map == "Mansion01") return;
	if(current.map == "Temple" && settings["autoend"]) return !current.pActive && old.pActive;
	// Prevent splitting when loading from menu
	//if(current.loading1 != current.loading2) return;
	
	//if(current.map != null && current.map != "" && vars.lastMap != "" && vars.lastMap != current.map)
	//	vars.log("MAP",current.map+", was "+vars.lastMap);
	
	if(settings["fullSplit"] && current.map != null && current.map != "" && vars.lastMap != ""){
		if(old.map != null && old.map != "" )
			 return old.map != current.map;
		else return vars.lastMap != current.map;
	}
	
}
