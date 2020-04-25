state("Amnesia_NoSteam","NoSteam 1.4")
{
	bool 	 isLoading	  : 0xD2081;
	byte 	 loading1 	  : 0x7131C0, 0x84, 0x7C, 0x04;
	byte 	 loading2	  : 0x7131C0, 0x84, 0x7C;
	
	string32 audio	 	  : 0x7131A8, 0x48, 0x38, 0x4, 0x8, 0x4, 0x0;
	string14 audio2		  : 0x7131A8, 0x48, 0x38, 0x4, 0x8, 0x4;
	string24 map		  : 0x6FA874, 0x5C, 0x60, 0x38;
	
}

state("Amnesia","Steam 1.4")
{
	bool 	 isLoading	  : 0x9A851;
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
	byte[]	BYTE_J 				= new byte[5],
			BYTE_1				= new byte[5];
	
	if	 (version=="Steam 1.4"){
			UNUSED_BYTE_OFFSET 	= 0x9A851;
			ADDR_C 			   	= 0x9A852;
			ADDR_1 			   	= 0xC78A2;
			ADDR_2 			   	= 0xC7A6D;
			BYTE_J 				= new byte[] { 0xE9, 0x44, 0xD0, 0x02, 0x00 };
			BYTE_1 				= new byte[] { 0xE9, 0xAB, 0x2F, 0xFD, 0xFF };
	}
	else/*version=="NoSteam 1.4"*/
	{
			UNUSED_BYTE_OFFSET 	= 0xD2081;
			ADDR_C 			   	= 0xD2082;
			ADDR_1 			   	= 0x8BBFD;
			ADDR_2 			   	= 0x8BDF8;
			BYTE_J 				= new byte[] { 0xE9, 0x6F, 0x9B, 0xFB, 0xFF };
			BYTE_1				= new byte[] { 0xE9, 0x80, 0x64, 0x04, 0x00 };
	}
	
	 // Check if first byte at our isLoading address is CC
	var ADDR_0 = game.ReadBytes(baseAddr+(UNUSED_BYTE_OFFSET),1)[0];
	
	if(ADDR_0 < 2) vars.log("INFO","Already injected!");
	else if(ADDR_0 == 204)
	{
		vars.log("INFO","Starting injections");
		// Get address of our isLoading var so we can use it as part of our AOB injection later
		byte[] addrBytes = BitConverter.GetBytes((int) baseAddr+UNUSED_BYTE_OFFSET);
		//vars.log("DEBUG","addrBytes: "+BitConverter.ToString(addrBytes));
		
		// Suspend game threads while writing memory to avoid potential crashing
		game.Suspend();
		
		// Overwrite unused alignment byte and initialize it as our isLoading var
		if(game.WriteBytes(baseAddr+UNUSED_BYTE_OFFSET, new byte[] {0})){
			// Enable write access to our isLoading var
			game.VirtualProtect((IntPtr) baseAddr+UNUSED_BYTE_OFFSET, 1, MemPageProtect.PAGE_EXECUTE_READWRITE);
		}
		
		// The original code at our 1st injection address
		byte[] originalCode = game.ReadBytes(baseAddr+ADDR_1, 5);
		//vars.log("DEBUG","originalCode: "+BitConverter.ToString(originalCode));
		
		// The code cave
		// We overwrite CC bytes 2 bytes after our isLoading var,
		// then include the original code after ours and a jump back to the original flow
		// C6 05 [addrBytes] 01 [originalCode] [jump]
		var cave = new List<byte>(new byte[] { 0xC6, 0x05, 0x01});
		cave.InsertRange(2,addrBytes);
		cave.AddRange(originalCode);
		cave.AddRange(BYTE_J);
		//vars.log("DEBUG","cave: "+BitConverter.ToString(cave.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_C, cave.ToArray())){vars.log("INFO","cave injected");}
		
		// This payload is responsible for setting our isLoading var to 1
		// We overwrite the existing code and jump to the code in our cave
		//var payload1 = new List<byte>(new byte[] { 0xE9 });
		//payload1.AddRange(BYTE_1);
		vars.log("DEBUG","payload1: "+BitConverter.ToString(BYTE_1));
		
		if(game.WriteBytes(baseAddr+ADDR_1, BYTE_1)){vars.log("INFO","payload1 injected");}
		
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
	
	return (current.map == "RainyHall" || current.map == "L01Cells") &&
		   (old.audio == null || old.audio == "") && old.audio != current.audio;
}

reset
{
	return (current.map == "L01Cells" || current.map == "RainyHall") && old.map != current.map;
}

update{ if(current.map != vars.lastMap && old.map != null && old.map != "") vars.lastMap = old.map; }

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