state("aamfp","NoDRM 1.01")
{
	bool 	isLoading	 : 0x1DF7D8;
	byte 	loading1 	 : 0x7664E4, 0x38, 0x7C, 0x0;
	byte 	loading2	 : 0x7664E4, 0x38, 0x7C;
	
	string9 map			 : 0x74CA04, 0x5C, 0x60, 0x38;
	bool 	playerActive : 0x74CA04, 0x84, 0x58;
}

state("aamfp_NoSteam","NoSteam 1.03")
{
	bool 	isLoading	 : 0x1DF7D8;
	byte 	loading1 	 : 0x76E99C, 0x38, 0x7C, 0x0;
	byte 	loading2	 : 0x76E99C, 0x38, 0x7C;
	
	string9 map			 : 0x74FB84, 0x5C, 0x60, 0x38;
	bool 	playerActive : 0x74FB84, 0x84, 0x58;
}

state("aamfp","Steam 1.03")
{
	bool 	isLoading	 : 0x1DF7D8;
	byte 	loading1 	 : 0x76984C, 0x38, 0x7C, 0x0;
	byte 	loading2	 : 0x76984C, 0x38, 0x7C;
	
	string9 map			 : 0x754CD4, 0x5C, 0x60, 0x38;
	bool 	playerActive : 0x754CD4, 0x84, 0x58;
}

startup{
	// Stores previous map
	vars.lastMap = " ";
	
	vars.log = (Action<string,string>)( (lvl,text) => {
		print("[AmnesiaASL AMFP] "+lvl+": "+text.Replace("-"," "));
	});
	
	settings.Add("autoend",false,"[EXPERIMENTAL] Enable auto-end. Requires editing game files.");
	settings.Add("autoend2",false,"See: https://github.com/PrototypeAlpha/AmnesiaASL/commit/f2da42b093bbb255055c9ce1c73f8272843bf249","autoend");
}

init 
{ 
	// Fix for rare occasions when NTDLL is loaded first
	if(!modules.First().ModuleName.ToLower().Contains("aamfp")) return;
	
	var size = modules.First().ModuleMemorySize;
	
	//aamfp.exe: 8617984  steam
	//aamfp_nosteam.exe: 8597504
	//aamfp.exe: 8585216
	
    switch(size)
    {
		case 8585216: 
			version = "NoDRM 1.01";
			break;
		case 8597504:
			version = "NoSteam 1.03";
			break;
		case 8871936:
			version = "Steam 1.03";
			break;
		default:
			version = "Unknown";
			break;
    }
	vars.log("INFO",size+" = "+version);
	
	// Stores previous map
	vars.lastMap = " ";
	
	var baseAddr = modules.First().BaseAddress;
	// aamfp.exe + UNUSED_BYTE_OFFSET is the location where we put our isLoading var
	// To find a new location for the isloading var, look for a place in memory with a lot of CC bytes
	// and use the first 2byte-aligned address of those CC bytes
	// For the code cave, use the next 2byte-aligned address
	int 	UNUSED_BYTE_OFFSET,	//isLoading
			ADDR_C,				//Cave
			ADDR_1,				//OnLeave
			ADDR_2;				//OnEnter
	byte[]	BYTE_J 				= new byte[3],
			BYTE_1				= new byte[3];
	
	if(version=="NoSteam 1.03"){
			UNUSED_BYTE_OFFSET 	= 0x1BBF28;
			ADDR_C 			   	= 0x1BBF2A;
			ADDR_1 			   	= 0xCB2BA;
			ADDR_2 			   	= 0xCB4FA;
			BYTE_J 				= new byte[] { 0x84, 0xF3, 0xF0 };
			BYTE_1 				= new byte[] { 0x6B, 0x0C, 0x0F };
	}
	else if(version=="Steam 1.03"){
			UNUSED_BYTE_OFFSET 	= 0x1C0F6B;
			ADDR_C 			   	= 0x1C0F6D;
			ADDR_1 			   	= 0xCE68A;
			ADDR_2 			   	= 0xCE8CA;
			BYTE_J 				= new byte[] { 0x11, 0xD7, 0xF0 };
			BYTE_1 				= new byte[] { 0xDE, 0x28, 0x0F };
	}
	else  /*version=="NoDRM 1.01"*/
	{
			UNUSED_BYTE_OFFSET 	= 0x1DF7D8;
			ADDR_C 			   	= 0x1DF7DA;
			ADDR_1 			   	= 0xCA25A;
			ADDR_2 			   	= 0xCA3B4;
			BYTE_J 				= new byte[] { 0x74, 0xAA, 0xEE };
			BYTE_1				= new byte[] { 0x7B, 0x55, 0x11 };
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
		// NoSteam 1.03: E9 84 F3 F0 FF
		// Steam 1.03:	 E9 11 D7 F0 FF
		// NoDRM 1.01:   E9 74 AA EE FF
		// E9 baseAddr+(ADDR_1+0x5) FF?
		var jump = new List<byte>(new byte[] { 0xE9, 0xFF });
		jump.InsertRange(1, BYTE_J);
		vars.log("DEBUG","jump: "+BitConverter.ToString(jump.ToArray()));
		
		// The code cave
		// We overwrite CC bytes 2 bytes after our isLoading var,
		// then include the original code after ours and a jump back to the original flow
		// 		               [addrBytes]    [originalCode] [    jump    ]
		// NoSteam 1.03: C6 05 28 BF 4F 01 01 A1 84 FB A8 01 E9 84 F3 F0 FF
		// Steam 1.03:	 C6 05 6B 0F 3D 01 01 A1 D4 4C 96 01 E9 11 D7 F0 FF
		// NoDRM 1.01:   C6 05 D8 F7 56 01 01 A1 04 CA AD 01 E9 74 AA EE FF
		var cave = new List<byte>(new byte[] { 0xC6, 0x05, 0x01});
		cave.InsertRange(2,addrBytes);
		cave.AddRange(originalCode);
		cave.AddRange(jump);
		vars.log("DEBUG","cave: "+BitConverter.ToString(cave.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_C, cave.ToArray())){vars.log("INFO","cave injected");}
		
		// This payload is responsible for setting our isLoading var to 1
		// We overwrite the existing code and jump to the code in our cave
		// NoSteam 1.03: E9 6B 0C 0F 00
		// Steam 1.03:	 E9 DE 28 0F 00
		// NoDRM 1.01:   E9 7B 55 11 00
		var payload1 = new List<byte>(new byte[] { 0xE9, 0x00 });
		payload1.InsertRange(1, BYTE_1);
		vars.log("DEBUG","payload1: "+BitConverter.ToString(payload1.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_1, payload1.ToArray())){vars.log("INFO","payload1 injected");}
		
		// This payload is responsible for setting our isLoading var to 0
		// We overwrite the existing code and set our isLoading var
		//                     [addrBytes]
		// NoSteam 1.03: C6 05 28 BF 4F 01 00 90 90
		// Steam 1.03:	 C6 05 6B 0F 3D 01 00 90 90
		// NoDRM 1.01:   C6 05 D8 F7 56 01 00 90 90
		var payload2 = new List<byte>(new byte[] { 0xC6, 0x05, 0x00, 0x90, 0x90 });
		payload2.InsertRange(2,addrBytes);
		vars.log("DEBUG","payload2: "+BitConverter.ToString(payload2.ToArray()));
		
		if(game.WriteBytes(baseAddr+ADDR_2, payload2.ToArray())){vars.log("INFO","payload2 injected");}
		
		game.Resume();
	}
	else vars.log("WARN","Unknown or unsupported game version");
	vars.keepLoading = false;
}

isLoading{ return current.isLoading || vars.keepLoading || current.loading1 != current.loading2; }

start
{
	vars.lastMap = " ";
	if(current.map != "Mansion01") return;
	
	// Set the start offset to 00:00 to force legacy timing (-01:16) to use the new timing
	if(timer.Run.Offset.ToString() != "00:00:00" &&
	  (timer.Run.GameName.ToLower().Contains("amfp") || timer.Run.GameName.ToLower().Contains("pig"))){
		timer.Run.Offset = TimeSpan.Parse("00:00:00");
	}
	return current.playerActive && !old.playerActive;
}

reset{ return current.map == "Mansion01" && old.map != current.map; }

update{
	
	if(old.map != null && old.map != "") vars.lastMap = old.map;
	
	// Fix the timer unpausing during the part of loading where the text moves up,
	// since you don't regain control until the text starts fading out (unlike in TDD)
	if(!current.isLoading && old.isLoading){
		vars.keepLoading = true;
		vars.log("LOAD","Staying paused until we can move again");
	}
	if(vars.keepLoading && current.loading1 != current.loading2){
		vars.keepLoading = false;
		vars.log("LOAD","We can move again, unpausing");
	}
}

split
{
	if(current.map != null && current.map != "" && vars.lastMap != current.map)
		vars.log("MAP",current.map+", was "+vars.lastMap);
	
	if(current.map == "Temple" && settings["autoend"]) return !current.playerActive && old.playerActive;
	
	if(current.map != null && current.map != ""){
		if(old.map != null && old.map != "" )
			 return old.map != current.map;
		else return vars.lastMap != current.map;
	}
	
}
