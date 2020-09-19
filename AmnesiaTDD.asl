state("Amnesia","1.50")
{
	byte 	 	loading1	: 0x7131C0, 0x84, 0x7C, 0x04;
	byte 	 	loading2	: 0x7131C0, 0x84, 0x7C;
	
	string32	audio		: 0x7131A8, 0x48, 0x38, 0x04, 0x08, 0x04, 0x00;
	string15	audio2		: 0x7131A8, 0x48, 0x38, 0x04, 0x08, 0x04;
	string24	map			: 0x6FA874, 0x5C, 0x60, 0x38;
	bool 	 	pActive		: 0x6FA874, 0x84, 0x58;
	float 	 	pMSMul		: 0x6FA874, 0x84, 0xD4;
	float		pPosX		: 0x6FA874, 0x84, 0x54, 0x48;
}

state("Amnesia_NoSteam","1.50")
{
	byte 	 	loading1	: 0x7131C0, 0x84, 0x7C, 0x04;
	byte 	 	loading2	: 0x7131C0, 0x84, 0x7C;
	
	string32 	audio		: 0x7131A8, 0x48, 0x38, 0x04, 0x08, 0x04, 0x00;
	string15	audio2		: 0x7131A8, 0x48, 0x38, 0x04, 0x08, 0x04;
	string24 	map			: 0x6FA874, 0x5C, 0x60, 0x38;
	bool 	 	pActive		: 0x6FA874, 0x84, 0x58;
	float 	 	pMSMul		: 0x6FA874, 0x84, 0xD4;
	float		pPosX		: 0x6FA874, 0x84, 0x54, 0x48;
}

state("Amnesia","Steam 1.50")
{
	byte 	 	loading1	: 0x781320, 0x84, 0x7C, 0x04;
	byte 	 	loading2	: 0x781320, 0x84, 0x7C;
	
	string32 	audio		: 0x781308, 0x48, 0x38, 0x04, 0x08, 0x04, 0x00;
	string15	audio2		: 0x781308, 0x48, 0x38, 0x04, 0x08, 0x04;
	string24 	map			: 0x768C54, 0x5C, 0x60, 0x38;
	bool 	 	pActive		: 0x768C54, 0x84, 0x58;
	float 	 	pMSMul		: 0x768C54, 0x84, 0xD4;
	float		pPosX		: 0x768C54, 0x84, 0x54, 0x48;
}

startup
{
	vars.aslName = "AmnesiaASL TDD";
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
	
	// Stores previous map
	vars.lastMap = "";
	vars.injected = false;
	
	settings.Add("fullSplit",true,"Split on level changes (If disabled, will only auto-start and auto-end)");
	
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
	
	vars.sigLeave = new SigScanTarget(3, "89 45 ?? A1 ?? ?? ?? ?? 8B 88"); // AOB signature for OnLeave. Use the address at A1
	vars.sigEnter = new SigScanTarget(1, "02 C6 ?? ?? 04 E8 ?? ?? ?? FF"); // AOB signature for OnEnter. Use the address at C6
}

shutdown
{
	if(game != null && vars.injected)
	{
		// Replace injected code with the original code
		game.Suspend();
		vars.log("DEBUG","Restoring original code");
		vars.CopyMemory(game, (IntPtr) vars.origLeave, 5, (IntPtr) vars.ptrLeave);
		vars.CopyMemory(game, (IntPtr) vars.origEnter, 9, (IntPtr) vars.ptrEnter);
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
	if(!name.Contains("amnesia")) return;
	
	var baseAddr = module.BaseAddress;
	var size = module.ModuleMemorySize;
	vars.lastMap = "";
	vars.injected = false;
	
	switch(size)
	{
		case 7872512:
			version = name == "amnesia.exe" ? "DRM-free 1.50" : "NoSteam 1.50";
			break;
		case 8368128:
			version = "Steam 1.50";
			break;
		default:
			version = "Unknown";
			var gameMessageText = "Website/launcher you bought the game from\r\n"+name+"="+size;
			var gameMessage = MessageBox.Show(
				"It appears you're running an unknown version of the game.\n"+
				"Load removal MAY work, however the other features probably won't.\n\n"+
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
	
	// Allocate memory for our code instead of looking for a code cave
	vars.log("DEBUG","Allocating memory...");
	var aslMem = vars.aslMem = game.AllocateMemory(32);
	
	var addrMem = BitConverter.GetBytes((int) aslMem).Reverse().ToArray();
	vars.log("DEBUG","aslMem address: "+BitConverter.ToString(addrMem).Replace("-",""));
	
	var scanner = new SignatureScanner(game, baseAddr, size);
	
	// Scan memory for leave signature
	IntPtr scanLeave = scanner.Scan((SigScanTarget) vars.sigLeave);
	vars.ptrLeave = scanLeave;
	// Scan memory for enter signature
	IntPtr scanEnter = scanner.Scan((SigScanTarget) vars.sigEnter);
	vars.ptrEnter = scanEnter;
	
	if(scanLeave == IntPtr.Zero || scanEnter == IntPtr.Zero)
		vars.log("ERROR","Can't find signatures. Unknown game version?");
	else
	{
			vars.log("INFO","Starting inject");
			var addrLeave = BitConverter.GetBytes((int) scanLeave).Reverse().ToArray();
			vars.log("DEBUG","Leave address: "+BitConverter.ToString(addrLeave).Replace("-",""));
			vars.log("DEBUG","Original bytes at Leave address: "+BitConverter.ToString(game.ReadBytes(scanLeave, 5)).Replace("-"," "));
			
			IntPtr codeLeave = aslMem+1;
			vars.WriteMov(game, codeLeave, 7, aslMem, new byte[] {1});	// Write instruction to set isLoading to 1
			vars.CopyMemory(game, scanLeave, 5, codeLeave+7);			// Write original code
			game.WriteJumpInstruction(codeLeave+7+5, scanLeave+5);		// Write jump out
			game.WriteJumpInstruction(scanLeave, codeLeave);			// Write jump in
			
			var addrEnter = BitConverter.GetBytes((int) scanEnter).Reverse().ToArray();
			vars.log("DEBUG","Enter address: "+BitConverter.ToString(addrEnter).Replace("-",""));
			vars.log("DEBUG","Original bytes at Enter address: "+BitConverter.ToString(game.ReadBytes(scanEnter, 9)).Replace("-"," "));
			
			IntPtr codeEnter = codeLeave+7+5+5;
			
			vars.CopyMemory(game, scanEnter, 9, codeEnter);				// Write backup of original code
			vars.WriteMov(game, scanEnter, 9, aslMem, new byte[] {0});	// Write instruction to set isLoading to 0
			
			vars.injected = true;
			vars.origLeave = codeLeave+7;
			vars.origEnter = codeEnter;
			vars.log("INFO","Finished injecting");
	}
	
	vars.isLoading = new MemoryWatcher<bool>(aslMem);
}

isLoading{ return vars.isLoading.Current || current.loading1 != current.loading2; }

start
{
	vars.lastMap = "";
	
	// TDD run start
	if(current.map == "RainyHall")
		return old.audio != current.audio && current.audio == "CH01L00_DanielsMind01_01";
	// Justine run start
	if(current.map == "L01Cells")
		return current.loading1 == current.loading2 && old.loading1 != current.loading1;
}

reset
{
	if(current.map == "RainyHall")
		return current.audio2 == "23_amb.ogg" && old.audio2 == "game_menu.ogg" && current.loading1 == current.loading2;
	else
		return current.map != old.map && current.map == "L01Cells";
}

update
{
	vars.isLoading.Update(game);
	if(current.map != vars.lastMap && old.map != null && old.map != "") vars.lastMap = old.map;
}

split
{
	if(current.map != old.map &&  (current.map == "RainyHall" || current.map == "L01Cells")) return;
	//if(current.map != null && current.map != "" && vars.lastMap != current.map)
	//	vars.log("MAP","\""+current.map+"\", was \""+vars.lastMap+"\"");
	if(current.map == old.map){
		// TDD run end
		if(current.map == "OrbChamber" && old.audio != current.audio)
			return current.audio == "CH03L29_Alexander_Interrupt03_01"|| // TDD Daniel ending
				   current.audio == "CH03L29_Ending_Alexander_01"	  || // TDD Alexander ending
				   current.audio == "CH03L29_Alexander_AgrippaEnd_01";	 // TDD Agrippa ending
		// Justine run end
		if(current.map == "L04Final"){
			if(current.pActive && current.pPosX > 37.62f)
				return current.pActive && old.pPosX < 37.62f && current.pPosX > 37.62f;
			return !current.pActive && current.pMSMul == 0.3f && old.pMSMul == 0.4f;
		}
	}
	// Level changes	
	return current.map != null && current.map != "" && vars.lastMap != "" &&
		   vars.lastMap != current.map && settings["fullSplit"];
}