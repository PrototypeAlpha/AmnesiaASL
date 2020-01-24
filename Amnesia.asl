state("Amnesia")
{
	// Found by Tarados
	byte loading1 	: 0x781320,0x84,0x7C,0x04;
	byte loading2	: 0x781320,0x84,0x7C;
	byte dialogue	: 0x768C54,0x58,0x3C,0x54,0x10;
	byte menu		: 0x768C54,0x80,0x130;
	// From JDev's DLL
	bool isLoading	: 0xC7BE2;
}

startup{
	vars.log = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)+"\\Amnesia\\Main\\hpl.log";
	print("[AmnesiaASL] Log path: "+vars.log);
}

init
{	
	current.map = "menu_bg.map";
	vars.line = null;
	
	try{
        FileStream fs = new FileStream(vars.log, FileMode.Open, FileAccess.Write, FileShare.ReadWrite);
        fs.SetLength(0);
        fs.Close();
	} catch{print("[AmnesiaASL] Unable to clear log file");}
	
	vars.reader = new StreamReader(new FileStream(vars.log, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));

	if(settings.SplitEnabled) print("[AmnesiaASL] Autosplitting enabled");
	
	// Amnesia.exe + UNUSED_BYTE_OFFSET is the location where we put our isLoading var
	// To find a new location for the isloading var, look for a place in memory with a lot of CC bytes and use the address
	// of the start of those CC bytes
	int UNUSED_BYTE_OFFSET = 0xC7BE2;
	int ADDR_1 			   = 0xC7884;
	int ADDR_2 			   = 0xC7A6E;
	
	if(game.ReadBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1)[0] == 204)
	{
		// Get address of our isLoading var so we can use it as part of our AOB injection later
		byte[] addrBytes = BitConverter.GetBytes((int)modules.First().BaseAddress+UNUSED_BYTE_OFFSET);
		print("[AmnesiaASL] addrBytes: "+BitConverter.ToString(addrBytes).Replace("-"," "));
		
		// Suspend game threads while writing memory to avoid potential crashing
		game.Suspend();
		
		// Overwrite unused alignment byte and initialize it as our isLoading var
		if(game.WriteBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, new byte[] {0})){
			// Enable write access to our isLoading var
			game.VirtualProtect((IntPtr) modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1, MemPageProtect.PAGE_EXECUTE_READWRITE);
		}
		
		// This payload is responsible for setting our isLoading var to 1
		// We overwrite useless code that is used for debug/error logging
		// Search for following bytes in memory: 83 7D E8 10 C6 45 FC 00 72 0C 8B 55 D4
		// Use the address where the 83 byte is located
		var payload1 = new List<byte>(new byte[] { 0xC6, 0x05, 0x01, 0x90, 0xEB });
		payload1.InsertRange(2,addrBytes);
		print("[AmnesiaASL] payload1: "+BitConverter.ToString(payload1.ToArray()).Replace("-"," "));
		if(game.WriteBytes(modules.First().BaseAddress+ADDR_1, payload1.ToArray())){print("[AmnesiaASL] payload1 injected");}
		
		// This payload is responsible for setting our isLoading var to 0
		// We overwrite useless code that is used for debug/error logging
		// Search for following bytes in memory: FF 50 6A 02 C6 45 FC 04 E8 6A DC
		// Use the address where the 45 byte is located
		var payload2 = new List<byte>(new byte[] { 0x05, 0x00, 0x90, 0x90 });
		payload2.InsertRange(1,addrBytes);
		print("[AmnesiaASL] payload2: "+BitConverter.ToString(payload2.ToArray()).Replace("-"," "));
		if(game.WriteBytes(modules.First().BaseAddress+ADDR_2, payload2.ToArray())){print("[AmnesiaASL] payload2 injected");}
		
		game.Resume();
	} else print("[AmnesiaASL] Already injected or unsupported game version");
}

exit{vars.reader.Close();}

isLoading{return current.isLoading || current.loading1 != current.loading2;}

reset{return current.map == "00_rainy_hall.map" && current.dialogue == 88 && old.dialogue == 0;}

start{return current.map == "00_rainy_hall.map" && current.dialogue == 88 && old.dialogue == 0;}

split{
	if(current.map == "00_rainy_hall.map")
		 return; //Prevent erronious splitting if timer is already running before the start time
	if(current.map == "29_orb_chamber.map" && old.map == current.map)
		 return (current.dialogue == 13 && old.dialogue != 13)|| //Daniel ending
				(current.dialogue == 21 && old.dialogue != 21)|| //Alexander ending
				(current.dialogue == 33 && old.dialogue != 33);  //Agrippa ending
	if(current.map == "04_final.map" && old.map == current.map)
		 return  current.dialogue == 66 && old.dialogue != 66;	 //Justine ending
	else return  current.map != old.map;						 //Split on level changes
}

update{
	vars.line = vars.reader.ReadLine();
	if (vars.line != null && vars.line.Contains("Loading map") && !vars.line.Contains("menu")){
		vars.line = vars.line.Split("'".ToCharArray())[1];
		if(current.map != vars.line){
			current.map = vars.line;
			print("[AmnesiaASL] Map is "+current.map+", was "+old.map);
		}
	}
}
