state("Amnesia")
{
	byte loading1 	: 0x350D3C,0x38,0x78,0x04;
	byte loading2	: 0x350D3C,0x38,0x78;
	byte dialogue	: 0x33745C,0x58,0x3C,0x58,0x14;
	// From Fatalis' DLL
	bool isLoading	: 0x9DE12;
}

startup{
	vars.timerModel = new TimerModel{CurrentState = timer};
	var baseDir = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments)+"\\Amnesia\\Main1.2\\";
	var aslLog = baseDir+"asl.log";
	var hplLog = baseDir+"hpl.log";
	vars.selfLog = false;
	vars.readLog = false;
	
	Action<string,string> debug = (lvl,text) => {
		print("[AmnesiaASL] "+lvl+": "+text); 
		if(vars.selfLog && lvl!="DEBUG") vars.aslWriter.WriteLine("[{0}] {1}: {2}",DateTime.Now,lvl,text);
	};
	vars.debug = debug;
	
	try{ // Create our log file
		var aslStream = new FileStream(aslLog, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
		vars.aslWriter = new StreamWriter(aslStream);
		debug("INFO","Successfully opened or created log file");
		vars.selfLog = true;
		vars.aslWriter.AutoFlush = true;
		vars.aslWriter.Write("----- AmnesiaASL 1.2 log {0} -----\r\n",DateTime.Now);
	} catch(Exception e){
		debug("WARN","Unable to create log file at: "+aslLog);
		debug("WARN",""+e);
		debug("WARN","Self log file will be unavailable");
	}
	
	debug("INFO","HPL Log path: "+hplLog);
	
	try{ // Open game log file for reading
		var hplStream = new FileStream(hplLog, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.ReadWrite);
		hplStream.SetLength(0);
		vars.hplReader = new StreamReader(hplStream);
		vars.readLog = true;
		debug("INFO","Successfully opened game log file");
	} catch(Exception e){
		debug("WARN","Unable to open game log file");
		debug("WARN",""+e);
		debug("WARN","Automatic features will be unavailable");
		MessageBox.Show(
			"Unable to open game log file"+"\n\n"+e+
			"\n\n"+"Automatic features will be unavailable",
			"AmnesiaASL | LiveSplit",MessageBoxButtons.OK,MessageBoxIcon.Warning
		);
	}
	
	settings.Add("fullReset",true,"Automatically save and reset splits when starting a new run after a completed one");
}

shutdown{
	if(vars.selfLog){
		vars.debug("INFO","Closing log file");
		vars.aslWriter.Flush();
		vars.aslWriter.Close();
		vars.selfLog = false;
		vars.debug("INFO","Closed log file");
	}
}

init
{
	vars.debug("INFO","Connecting to game...");
	current.map = "menu_bg.map";
	vars.prevMap = null;
	vars.line = null;
	
	if(vars.readLog && settings.SplitEnabled) vars.debug("INFO","Autosplitting enabled");
	
	// Amnesia.exe + UNUSED_BYTE_OFFSET is the location where we put our isLoading var
	// To find a new location for the isloading var, look for a place in memory with a lot of CC bytes and use the address
	// of the start of those CC bytes
	int UNUSED_BYTE_OFFSET = 0x9DE12;
	int ADDR_1 			   = 0x9DEE3;
	int ADDR_2 			   = 0x9E0B2;
	
	if(game.ReadBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1)[0] == 204)
	{
		// Get address of our isLoading var so we can use it as part of our AOB injection later
		byte[] addrBytes = BitConverter.GetBytes((int)modules.First().BaseAddress+UNUSED_BYTE_OFFSET);
		vars.debug("DEBUG","addrBytes: "+BitConverter.ToString(addrBytes).Replace("-"," "));
		
		// Suspend game threads while writing memory to avoid potential crashing
		game.Suspend();
		
		// Overwrite unused alignment byte and initialize it as our isLoading var
		if(game.WriteBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, new byte[] {0})){
			// Enable write access to our isLoading var
			game.VirtualProtect((IntPtr) modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1, MemPageProtect.PAGE_EXECUTE_READWRITE);
		}
		
		// This payload is responsible for setting our isLoading var to 1
		// We overwrite useless code that is used for debug/error logging
		// Search for following bytes in memory: C7 44 24 64 00 00 00 00 FF 15 08 32 6C
		// Use the address where the C7 byte is located
		var payload1 = new List<byte>(new byte[] { 0xC6, 0x05, 0x01, 0x90 });
		payload1.InsertRange(2,addrBytes);
		vars.debug("DEBUG","payload1: "+BitConverter.ToString(payload1.ToArray()).Replace("-"," "));
		if(game.WriteBytes(modules.First().BaseAddress+ADDR_1, payload1.ToArray())){vars.debug("INFO","payload1 injected");}
		
		// This payload is responsible for setting our isLoading var to 0
		// We overwrite useless code that is used for debug/error logging
		// Search for following bytes in memory: 44 24 70 04 E8 45 30 F6 FF 83 C4
		// Use the address where the 44 byte is located
		var payload2 = new List<byte>(new byte[] { 0x05, 0x00, 0x90, 0x90, 0x90 });
		payload2.InsertRange(1,addrBytes);
		vars.debug("DEBUG","payload2: "+BitConverter.ToString(payload2.ToArray()).Replace("-"," "));
		if(game.WriteBytes(modules.First().BaseAddress+ADDR_2, payload2.ToArray())){vars.debug("INFO","payload2 injected");}
		
		game.Resume();
	} else vars.debug("WARN","Already injected isLoading var or unsupported game version");
	vars.debug("INFO","Connected!");
}

exit{
	try{vars.hplReader.Close();}
	finally{vars.debug("INFO","Disconnected from game and closed game log file");}
}

isLoading{return current.isLoading || current.loading1 != current.loading2;}

reset{
	if(vars.readLog && (current.map == "00_rainy_hall.map" || current.map == "01_cells.map") && old.map.Contains("menu")){
		vars.debug("RUN","Resetting "+timer.Run.GetExtendedName()+" run at "+DateTime.Now);
		return (current.map == "00_rainy_hall.map" || current.map == "01_cells.map") && old.map.Contains("menu");
	}
}

start{
	if(vars.readLog){
		if((current.map == "00_rainy_hall.map" && current.dialogue == 88 && old.dialogue == 0)||
		   (current.map == "01_cells.map" && old.loading1 != current.loading1 && current.loading1 == current.loading2)){
			vars.debug("RUN","Starting "+timer.Run.GetExtendedName()+" run at "+DateTime.Now);
			return (current.dialogue == 88 && old.dialogue == 0)||
				   (current.map == "01_cells.map" && old.loading1 != current.loading1 && current.loading1 == current.loading2);
		}
	}
}

split{
	if(!vars.readLog || current.map.Contains("menu") || old.map.Contains("menu"))
				return;
	else if(current.map == "29_orb_chamber.map" && old.map == current.map){
			if( (current.dialogue == 13 && old.dialogue != 13)||
				(current.dialogue == 21 && old.dialogue != 21)||
				(current.dialogue == 33 && old.dialogue != 33)){
				vars.debug("RUN","Finishing "+timer.Run.GetExtendedName()+" run at "+DateTime.Now);
				return (current.dialogue == 13 && old.dialogue != 13)||	// Daniel ending
					   (current.dialogue == 21 && old.dialogue != 21)||	// Alexander ending
					   (current.dialogue == 33 && old.dialogue != 33);	// Agrippa ending
			}
	}
	else if(current.map == "04_final.map" && old.map == current.map &&
			current.dialogue == 66 && old.dialogue != 66){
				vars.debug("RUN","Finishing "+timer.Run.GetExtendedName()+" run at "+DateTime.Now);
				return  current.dialogue == 66 && old.dialogue != 66;	// Justine ending
	}
	else 		return  current.map != old.map;							// Split on level changes
}

update{
	if(vars.readLog){
		vars.line = vars.hplReader.ReadLine();
		if (vars.line != null && vars.line.Contains("Loading map")){
			vars.line = vars.line.Split("'".ToCharArray())[1];
			if(current.map != vars.line){
				current.map = vars.line;
				vars.debug("MAP",current.map+", was "+old.map);
			}
		}
		// Automatically reset the timer in the normal place after a completed run
		if(timer.CurrentPhase == TimerPhase.Ended && settings.ResetEnabled && settings["fullReset"]){
			if((current.map == "00_rainy_hall.map" || current.map == "01_cells.map") && old.map.Contains("menu")){
				vars.debug("RUN","Saving and resetting completed "+timer.Run.GetExtendedName()+" run at "+DateTime.Now);
				vars.timerModel.Reset();
			}
		}
	}
	/*if(current.isLoading != old.isLoading) vars.debug("DEBUG","isLoading = "+current.isLoading);
	if(current.loading1 != old.loading1) vars.debug("DEBUG","loading1 = "+current.loading1+", loading2 = "+current.loading2);*/
}
