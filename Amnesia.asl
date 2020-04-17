state("Amnesia_NoSteam","NoSteam 1.4")
{
	bool 	 isLoading	  : 0x5D0C6E;
	byte 	 loading1 	  : 0x7131C0, 0x84, 0x7C, 0x04;
	byte 	 loading2	  : 0x7131C0, 0x84, 0x7C;
	
	string32 audio	 	  : 0x7131A8, 0x48, 0x38, 0x4, 0x8, 0x4, 0x0;
	string14 audio2		  : 0x7131A8, 0x48, 0x38, 0x4, 0x8, 0x4;
	string24 map		  : 0x6FA874, 0x5C, 0x60, 0x38;
	
}

state("Amnesia","Steam 1.4")
{
	bool 	 isLoading	  : 0x3A6C20;
	byte 	 loading1 	  : 0x781320, 0x84, 0x7C, 0x04;
	byte 	 loading2	  : 0x781320, 0x84, 0x7C;
	
	string32 audio		  : 0x781308, 0x48, 0x38, 0x4, 0x8, 0x4, 0x0;
	string14 audio2		  : 0x781308, 0x48, 0x38, 0x4, 0x8, 0x4;
	string24 map		  : 0x768C54, 0x5C, 0x60, 0x38;
}

startup
{
	// Stores previous map
	vars.lastMap = "";
	// Enables resetting the timer if the current run is completed
	vars.timerModel = new TimerModel{CurrentState = timer};
	
	vars.cues 		= new String[]{
		"CH01L00_DanielsMind01_01", 		//TDD run start
		"CH03L29_Alexander_Interrupt03_01", //TDD Daniel ending
		"CH03L29_Ending_Alexander_01",		//TDD Alexander ending
		"CH03L29_Alexander_AgrippaEnd_01",	//TDD Agrippa ending
		"ambience_hollow_tinker",			//Justine run start
		"clarice_end_01"					//Justine run end
	};
	
	vars.log = (Action<string,string>)( (lvl,text) => {
		print("[AmnesiaASL TDD] "+lvl+": "+text.Replace("-"," ")); 
	});
	
	settings.Add("fullSplit",true,"Split on level changes (If disabled, will only auto-start and auto-end)");
	settings.Add("fullReset",true,"Save completed run and reset timer when starting a new run");
}

init 
{ 
	// Fix for rare occasions when NTDLL is loaded first
	if(!modules.First().ModuleName.ToLower().Contains("amnesia")) return;
	
	var size = modules.First().ModuleMemorySize;
	
	//amnesia.exe: 8368128 steam
	//amnesia_nosteam.exe: 7872512
	
	switch(size)
    {
		case 7872512:
			version = "NoSteam 1.4";
			break;
		case 8368128:
			version = "Steam 1.4";
			break;
		default:
			version = "Unknown";
			break;
    }
	vars.log("INFO",size+" = "+version);
	
	// Stores previous map
	vars.lastMap = "";
	
	var 	baseAddr = modules.First().BaseAddress;
	
	int 	UNUSED_BYTE_OFFSET,	//isLoading
			ADDR_C,				//Cave
			ADDR_1,				//OnLeave
			ADDR_2;				//OnEnter
	byte[]	BYTE_J 				= new byte[3],
			BYTE_1				= new byte[3];
	
	if	 (version=="Steam 1.4"){
			UNUSED_BYTE_OFFSET 	= 0x3A6C20;
			ADDR_C 			   	= 0x3A6C21;
			ADDR_1 			   	= 0xC7842;
			ADDR_2 			   	= 0xC7A61;
			BYTE_J 				= new byte[] { 0x15, 0x0C, 0xD2 };
			BYTE_1 				= new byte[] { 0xDA, 0xF3, 0x2D };
	}
	else/*version=="NoSteam 1.4"*/
	{
			UNUSED_BYTE_OFFSET 	= 0x5D0C6E;
			ADDR_C 			   	= 0x5D0C6F;
			ADDR_1 			   	= 0x8BBFD;
			ADDR_2 			   	= 0x8BE62;
			BYTE_J 				= new byte[] { 0x82, 0xAF, 0xAB };
			BYTE_1				= new byte[] { 0x6D, 0x50, 0x54 };
	}
	
	 // Check if first byte at our isLoading address is CC
	var ADDR_0 = game.ReadBytes(baseAddr+(UNUSED_BYTE_OFFSET),1)[0];
	
	if(ADDR_0 < 2) vars.log("INFO","Already injected!");
	else if(ADDR_0 == 204)
	{
		vars.log("INFO","Starting injections");
		// Get address of our isLoading var so we can use it as part of our AOB injection later
		byte[] addrBytes = BitConverter.GetBytes((int) baseAddr+UNUSED_BYTE_OFFSET);
		vars.log("DEBUG","addrBytes: "+BitConverter.ToString(addrBytes));
		
		// Suspend game threads while writing memory to avoid potential crashing
		game.Suspend();
		
		// Overwrite unused alignment byte and initialize it as our isLoading var
		if(game.WriteBytes(baseAddr+UNUSED_BYTE_OFFSET, new byte[] {0})){
			// Enable write access to our isLoading var
			game.VirtualProtect((IntPtr) baseAddr+UNUSED_BYTE_OFFSET, 1, MemPageProtect.PAGE_EXECUTE_READWRITE);
		}
		
		// The original code at our 1st injection address
		byte[] originalCode = game.ReadBytes(baseAddr+ADDR_1, 5);
		vars.log("DEBUG","originalCode: "+BitConverter.ToString(originalCode));
		
		// The return jump
		var jump = new List<byte>(new byte[] { 0xE9, 0xFF });
		jump.InsertRange(1, BYTE_J);
		vars.log("DEBUG","jump: "+BitConverter.ToString(jump.ToArray()));
		
		// The code cave
		// We overwrite CC bytes 2 bytes after our isLoading var,
		// then include the original code after ours and a jump back to the original flow
		// C6 05 [addrBytes] 01 [originalCode] [jump]
		var cave = new List<byte>(new byte[] { 0xC6, 0x05, 0x01});
		cave.InsertRange(2,addrBytes);
		cave.AddRange(originalCode);
		cave.AddRange(jump);
		vars.log("DEBUG","cave: "+BitConverter.ToString(cave.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_C, cave.ToArray())){vars.log("INFO","cave injected");}
		
		// This payload is responsible for setting our isLoading var to 1
		// We overwrite the existing code and jump to the code in our cave
		var payload1 = new List<byte>(new byte[] { 0xE9, 0x00 });
		payload1.InsertRange(1, BYTE_1);
		vars.log("DEBUG","payload1: "+BitConverter.ToString(payload1.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_1, payload1.ToArray())){vars.log("INFO","payload1 injected");}
		
		// This payload is responsible for setting our isLoading var to 0
		// We overwrite the existing code and set our isLoading var
		// C6 05 [addrBytes] 00 90 90
		var payload2 = new List<byte>(new byte[] { 0xC6, 0x05, 0x00, 0x90, 0x90 });
		payload2.InsertRange(2,addrBytes);
		vars.log("DEBUG","payload2: "+BitConverter.ToString(payload2.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_2, payload2.ToArray())){vars.log("INFO","payload2 injected");}
		
		game.Resume();
	}
	else vars.log("WARN","Unknown or unsupported game version");
	
}

isLoading{ return current.isLoading || current.loading1 != current.loading2; }

start
{
	vars.lastMap = "";
	
	return (current.map == "RainyHall" || current.map == "Cells") &&
		   (old.audio == null || old.audio == "") && old.audio != current.audio;
}

reset
{
	return ((current.map == "Cells" && timer.Run.GameName.ToLower().Contains("justine")) ||
			 current.map == "RainyHall") && old.map != current.map;
}

update{
	if(current.map != vars.lastMap && old.map != null && old.map != "") vars.lastMap = old.map;
	
	// Automatically reset the timer in the normal place after a completed run
	if(timer.CurrentPhase == TimerPhase.Ended && settings.ResetEnabled && settings["fullReset"]){
		if((current.map == "RainyHall" || current.map == "Cells") && old.map != null){
			vars.timerModel.Reset();
		}
	}
}

split
{
	if(current.map != null && current.map != "" && vars.lastMap != current.map)
		vars.log("MAP","\""+current.map+"\", was \""+vars.lastMap+"\"");
	
	if((old.audio != current.audio || old.audio2 != current.audio2)&&
			(Array.IndexOf(vars.cues, current.audio) > 0 &&					// Split on TDD endings
			 Array.IndexOf(vars.cues, current.audio) < 4)||
			 current.audio2 == vars.cues[5])								// Split on Justine ending
	{ return old.audio != current.audio || old.audio2 != current.audio2; }	
	
		
	return current.map != null && current.map != "" &&						// Split on level changes
		   vars.lastMap != "" && vars.lastMap != current.map && settings["fullSplit"];
}