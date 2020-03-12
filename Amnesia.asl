state("Amnesia")
{
	byte protoload	: 0x781318,0x2C,0x2C;
	string32 audio	: 0x781308,0x48,0x38,0x4,0x8,0x4,0x0;
	string14 audio2	: 0x768C54,0x58,0x58,0xC,0x44,0x0;
	// Found by Tarados
	byte loading1 	: 0x781320,0x84,0x7C,0x04;
	byte loading2	: 0x781320,0x84,0x7C;
	// From JDev's DLL
	bool isLoading	: 0xC7BE2;
}

state("Amnesia_NoSteam")
{
	byte protoload	: 0x7131B8,0x2C,0x2C;
	string32 audio	: 0x7131A8,0x48,0x38,0x4,0x8,0x4,0x0;
	string14 audio2	: 0x7131B8,0xE8,0x34,0x34,0x8,0x4;
	
	byte loading1 	: 0x7131C0,0x84,0x7C,0x04;
	byte loading2	: 0x7131C0,0x84,0x7C;
	// Found by Sychotix
	bool isLoading	: 0xD2081;
}

startup{
	vars.timerModel = new TimerModel{CurrentState = timer};
	vars.baseDir 	= Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)+"\\Amnesia\\Main\\";
	vars.aslLog 	= vars.baseDir+"asl.log";
	vars.hplLog 	= vars.baseDir+"hpl.log";
	vars.selfLog 	= false;
	vars.readLog 	= false;
	
	vars.cues 		= new String[]{
		"CH01L00_DanielsMind01_01", 		//TDD run start
		"CH03L29_Alexander_Interrupt03_01", //TDD Daniel ending
		"CH03L29_Ending_Alexander_01",		//TDD Alexander ending
		"CH03L29_Alexander_AgrippaEnd_01",	//TDD Agrippa ending
		"ambience_hollow_tinker",			//Justine run start
		"clarice_end_01"					//Justine run end
	};
	
	vars.log = (Action<string,string>)( (lvl,text) => {
		print("[AmnesiaASL] "+lvl+": "+text); 
		if(vars.selfLog) vars.aslWriter.WriteLine("[{0}] {1}: {2}",DateTime.Now,lvl,text);
	});
	
	try{ // Create our log file
		if(File.Exists(vars.aslLog)){File.Copy(vars.aslLog,vars.baseDir+"asl.old.log",true);}
		
		var aslStream = new FileStream(vars.aslLog, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
		vars.aslWriter = new StreamWriter(aslStream);
		vars.log("INFO","Successfully created log file");
		vars.selfLog = true;
		vars.aslWriter.AutoFlush = true;
		vars.aslWriter.Write("----- AmnesiaASL log {0} -----\r\n",DateTime.Now);
	} catch(Exception e){
		vars.log("WARN","Unable to create log file at: "+vars.aslLog);
		vars.log("WARN",""+e);
		vars.log("WARN","Self log file will be unavailable");
	}
	
	vars.log("INFO","HPL Log path: "+vars.hplLog);
	
	vars.openGameLog = (Action)( () => {
		try{ // Open game log file for reading
			var hplStream = new FileStream(vars.hplLog, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
			hplStream.SetLength(0);
			vars.hplReader = new StreamReader(hplStream);
			vars.readLog = true;
			vars.log("INFO","Successfully opened game log file");
		} catch(Exception e){
			vars.log("WARN","Unable to open game log file");
			vars.log("WARN",""+e);
			vars.log("WARN","Most automatic features will be unavailable");
			MessageBox.Show(
				"Unable to open game log file"+"\n\n"+e+
				"\n\n"+"Most automatic features will be unavailable",
				"AmnesiaASL | LiveSplit",MessageBoxButtons.OK,MessageBoxIcon.Warning
			);
		}
	});
	
	settings.Add("fullSplit",true,"Split on level changes (If disabled, will only auto-start and auto-end)");
	settings.Add("fullReset",true,"Save and reset completed run when starting a new one");
	settings.Add("altLoad",false,"Alternative loading detection");
}

shutdown{
	if(vars.selfLog){
		vars.log("INFO","Closing log file");
		vars.aslWriter.Flush();
		vars.aslWriter.Close();
		vars.selfLog = false;
		vars.log("INFO","Closed log file");
	}
}

init
{
	vars.log("INFO","Connecting to game...");
	vars.openGameLog();
	
	if(timer.Run.GameName.Contains("Justine")) current.map = "ptest_menu.map";
	else current.map = "menu_bg.map";
	vars.prevMap = null;
	vars.line = null;
	
	if(vars.readLog && settings.SplitEnabled) vars.log("INFO","Autosplitting enabled");
	
	// Amnesia.exe + UNUSED_BYTE_OFFSET is the location where we put our isLoading var
	// To find a new location for the isloading var, look for a place in memory with a lot of CC bytes and use the address
	// of the start of those CC bytes
	int UNUSED_BYTE_OFFSET = 0xC7BE2;
	int ADDR_1 			   = 0xC7884;
	int ADDR_2 			   = 0xC7A6E;
	
	if(modules.First().ModuleName.Length > 11){
		UNUSED_BYTE_OFFSET = 0xD2081;
		ADDR_1 			   = 0x8BBFD;
		ADDR_2 			   = 0x8BDF8;
	}
	
	int ADDR_0			   = game.ReadBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1)[0];
	
	if(ADDR_0 == 204)
	{
		// Get address of our isLoading var so we can use it as part of our AOB injection later
		byte[] addrBytes = BitConverter.GetBytes((int)modules.First().BaseAddress+UNUSED_BYTE_OFFSET);
		vars.log("DEBUG","addrBytes: "+BitConverter.ToString(addrBytes).Replace("-"," "));
		
		// Suspend game threads while writing memory to avoid potential crashing
		game.Suspend();
		
		// Overwrite unused alignment byte and initialize it as our isLoading var
		if(game.WriteBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, new byte[] {0})){
			// Enable write access to our isLoading var
			game.VirtualProtect((IntPtr) modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1, MemPageProtect.PAGE_EXECUTE_READWRITE);
		}
		
		if(modules.First().ModuleName.Length > 11){
			vars.log("DEBUG","Injecting into NoSteam version");
			int ADDR_3 = 0xD2084;
			
			byte[] original = BitConverter.GetBytes((int)modules.First().BaseAddress+0x6FA874);
			vars.log("DEBUG","original: "+BitConverter.ToString(original).Replace("-"," "));
			
			// This payload is responsible for setting our isLoading var to 1
			// We overwrite CC bytes near our isLoading var and include the original code at the end
			var cave = new List<byte>(new byte[] { 0xC6, 0x05, 0x01, 0xA1, 0xE9, 0x6D, 0x9B, 0xFB, 0xFF });
			cave.InsertRange(4,original);
			cave.InsertRange(2,addrBytes);
			vars.log("DEBUG","cave: "+BitConverter.ToString(cave.ToArray()).Replace("-"," "));
			if(game.WriteBytes(modules.First().BaseAddress+ADDR_3, cave.ToArray())){vars.log("INFO","cave injected");}
			
			// This payload is responsible for setting our isLoading var to 1
			// We overwrite the existing code and jump to our own code
			var payload1 = new List<byte>(new byte[] { 0xE9, 0x82, 0x64, 0x04, 0x00 });
			vars.log("DEBUG","payload1: "+BitConverter.ToString(payload1.ToArray()).Replace("-"," "));
			if(game.WriteBytes(modules.First().BaseAddress+ADDR_1, payload1.ToArray())){vars.log("INFO","payload1 injected");}
			
			// This payload is responsible for setting our isLoading var to 0
			var payload2 = new List<byte>(new byte[] { 0xC6, 0x05, 0x00, 0x90, 0x90 });
			payload2.InsertRange(2,addrBytes);
			vars.log("DEBUG","payload2: "+BitConverter.ToString(payload2.ToArray()).Replace("-"," "));
			if(game.WriteBytes(modules.First().BaseAddress+ADDR_2, payload2.ToArray())){vars.log("INFO","payload2 injected");}
		}
		else{
			vars.log("DEBUG","Injecting into Steam version");
			// This payload is responsible for setting our isLoading var to 1
			// We overwrite useless code that is used for debug/error logging
			// Search for following bytes in memory: 83 7D E8 10 C6 45 FC 00 72 0C 8B 55 D4
			// Use the address where the 83 byte is located
			var payload1 = new List<byte>(new byte[] { 0xC6, 0x05, 0x01, 0x90, 0xEB });
			payload1.InsertRange(2,addrBytes);
			vars.log("DEBUG","payload1: "+BitConverter.ToString(payload1.ToArray()).Replace("-"," "));
			if(game.WriteBytes(modules.First().BaseAddress+ADDR_1, payload1.ToArray())){vars.log("INFO","payload1 injected");}
			
			// This payload is responsible for setting our isLoading var to 0
			// We overwrite useless code that is used for debug/error logging
			// Search for following bytes in memory: FF 50 6A 02 C6 45 FC 04 E8 6A DC
			// Use the address where the 45 byte is located
			var payload2 = new List<byte>(new byte[] { 0x05, 0x00, 0x90, 0x90 });
			payload2.InsertRange(1,addrBytes);
			vars.log("DEBUG","payload2: "+BitConverter.ToString(payload2.ToArray()).Replace("-"," "));
			if(game.WriteBytes(modules.First().BaseAddress+ADDR_2, payload2.ToArray())){vars.log("INFO","payload2 injected");}
		}
		
		game.Resume();
	}
	else if(ADDR_0==0||ADDR_0==1) vars.log("INFO","Already injected isLoading var");
	else if(settings["altLoad"]) vars.log("INFO","Using alternative loading detection");
	else vars.log("WARN","Unsupported game version");
	vars.log("INFO","Connected!");
}

exit{
	try{vars.hplReader.Close();}
	finally{vars.log("INFO","Disconnected from game and closed game log file");}
}

isLoading{
	if(settings["altLoad"])
		 return current.protoload != 1 || current.loading1 != current.loading2;
	else return current.isLoading || current.loading1 != current.loading2;
}

reset{
	if(vars.readLog && (current.map == "00_rainy_hall.map" || current.map == "01_cells.map") && old.map.Contains("menu")){
		vars.log("RUN","Resetting "+timer.Run.GetExtendedName()+" run at "+DateTime.Now);
		return (current.map == "00_rainy_hall.map" || current.map == "01_cells.map") && old.map.Contains("menu");
	}
}

start{
	if(old.audio != current.audio && (current.audio == vars.cues[0] ||
	  (current.audio == vars.cues[4]) && old.audio2 == "25_amb.ogg")){
		vars.log("RUN","- Starting "+timer.Run.GetExtendedName()+" run -");
		return old.audio != current.audio;
	}
}

split{
	if(vars.readLog && (current.map.Contains("menu") || old.map.Contains("menu"))) return;
	else if(vars.readLog && settings["fullSplit"] && current.map != old.map)
		return current.map != old.map;														// Split on level changes
	else if((old.audio != current.audio || old.audio2 != current.audio2)&&
			(Array.IndexOf(vars.cues, current.audio) > 0 &&									// Split on TDD endings
			 Array.IndexOf(vars.cues, current.audio) < 4)||
			 current.audio2 == vars.cues[5]){												// Split on Justine ending
		vars.log("RUN","- Finishing "+timer.Run.GetExtendedName()+" run -");
		vars.log("RUN","- Final time: "+timer.CurrentTime+" -");
		return old.audio != current.audio || old.audio2 != current.audio2;
	}
}

update{
	if(vars.readLog){
		vars.line = vars.hplReader.ReadLine();
		if (vars.line != null && vars.line.Contains("Loading map")){
			vars.line = vars.line.Split("'".ToCharArray())[1];
			if(current.map != vars.line){
				current.map = vars.line;
				vars.log("MAP",current.map+", was "+old.map);
			}
		}
		// Automatically reset the timer in the normal place after a completed run
		if(timer.CurrentPhase == TimerPhase.Ended && settings.ResetEnabled && settings["fullReset"]){
			if((current.map == "00_rainy_hall.map" || current.map == "01_cells.map") && old.map.Contains("menu")){
				vars.log("RUN","- Saving and resetting completed "+timer.Run.GetExtendedName()+" run -");
				vars.timerModel.Reset();
			}
		}
	}
}
