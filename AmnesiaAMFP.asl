state("aamfp")
{
	float 	gameTime : 0x74CA04, 0x84, 0x2D0, 0x60;
	string9 mapName	 : 0x74CA04, 0x5C, 0x60, 0x38;
}

isLoading {return true;}

start
{
	// Reset the variables while not in a run
	vars.nonSingleSegmentgameTime = 0;
	vars.lastValidMap = " ";
	
	// Use backwards-compatible start if offset isn't 00:00
	if(timer.Run.GameName.ToLower().Contains("pig") && timer.Run.Offset.ToString() != "00:00:00"){
		// Set the start offset to -1:16 if it isn't already
		if(timer.Run.Offset.ToString() != vars.startOffset) timer.Run.Offset = TimeSpan.Parse(vars.startOffset);
		return current.gameTime > 0 && old.gameTime == 0 && current.mapName == "Mansion01";
	}
	else return current.gameTime >= 76.00 && old.gameTime < 76.00 && current.mapName == "Mansion01";
}

init 
{ 
	// Backwards-compatible start offset
	vars.startOffset = "-00:01:16";
	// Stores previous game time for RTA runs
	vars.nonSingleSegmentgameTime = 0; 
	// Stores previous map for RTA runs
	vars.lastValidMap = " ";
}

update 
{ 
	// We are currently ingame for at least one tick
	if (old.gameTime > 0)
	{
		// Store the last valid map for RTA/Splitting
		if (old.mapName != null && old.mapName != "") vars.lastValidMap = old.mapName;
	
		// We just came from the menu, save the old times for RTA
		if (current.gameTime == 0) vars.nonSingleSegmentgameTime += old.gameTime;
	}
}

gameTime
{
	// Gametime is current game time plus any previous game time in the case of RTA
	// Subtract 87 seconds for backwards support with run timing
    return TimeSpan.FromSeconds(current.gameTime + vars.nonSingleSegmentgameTime - 76);
}

split
{
	if (current.mapName != null && current.mapName != "" && vars.lastValidMap != current.mapName)
		print("CURRENT: "+current.mapName+" VALID: "+vars.lastValidMap);
	
	return current.mapName != null && current.mapName != "" && vars.lastValidMap != current.mapName;
}
