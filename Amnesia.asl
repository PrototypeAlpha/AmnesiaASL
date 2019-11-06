state("Amnesia")
{
	// Found by Tarados
	int First_loading 	: 0x781320,0x84,0x7C,0x04;
	int Second_loading 	: 0x781320,0x84,0x7C;	
	int Dialogue		: 0x768C54,0x58,0x3C,0x54,0x10;
	int menu			: 0x768C54,0x80,0x130;
	// From JDev's DLL
	bool isLoading		: 0xC7BE2;
}

init
{
	Thread.Sleep(1000);
	
	// Suspend game threads while writing memory to avoid potential crashing
	game.Suspend();
	
	// Amnesia.exe + UNUSED_BYTE_OFFSET is the location where we put our isLoading var
	// To find a new location for the isloading var, look for a place in memory with a lot of CC bytes and use the address
	// of the start of those CC bytes
	int UNUSED_BYTE_OFFSET = 0xC7BE2;
	
	byte[] addrBytes = BitConverter.GetBytes((int)modules.First().BaseAddress+UNUSED_BYTE_OFFSET);
	print("[AmnesiaASL] addrBytes: "+BitConverter.ToString(addrBytes).Replace("-"," "));

	// Overwrite unused alignment byte and initialize it as our isLoading var
	game.WriteBytes(modules.First().BaseAddress+UNUSED_BYTE_OFFSET, new byte[] {0});
	// Enable write access to our isLoading var
	game.VirtualProtect((IntPtr) modules.First().BaseAddress+UNUSED_BYTE_OFFSET, 1, MemPageProtect.PAGE_EXECUTE_READWRITE);
	
	// This payload is responsible for setting our isLoading var to 1
	// We overwrite useless code that is used for debug/error logging
	// Search for following bytes in memory: 83 7D E8 10 C6 45 FC 00 72 0C 8B 55 D4
	// Use the address where the 83 byte is located
	var payload1 = new List<byte>(new byte[] { 0xC6, 0x05 });
	payload1.AddRange(addrBytes);
	payload1.AddRange(new byte[] { 0x01, 0x90, 0xEB });
	print("[AmnesiaASL] payload1: "+BitConverter.ToString(payload1.ToArray()).Replace("-"," "));
	game.WriteBytes(modules.First().BaseAddress+0xC7884, payload1.ToArray());
	
	// This payload is responsible for setting our isLoading var to 0
	// We overwrite useless code that is used for debug/error logging
	// Search for following bytes in memory: FF 50 6A 02 C6 45 FC 04 E8 6A DC
	// Use the address where the 45 byte is located
	var payload2 = new List<byte>(new byte[] { 0x05 });
	payload2.AddRange(addrBytes);
	payload2.AddRange(new byte[] { 0x00, 0x90, 0x90 });
	print("[AmnesiaASL] payload2: "+BitConverter.ToString(payload2.ToArray()).Replace("-"," "));
	game.WriteBytes(modules.First().BaseAddress+0xC7A6E, payload2.ToArray());
	
	Thread.Sleep(1000);
	game.Resume();
}

isLoading{return current.isLoading || current.First_loading != current.Second_loading;}

start{return current.Dialogue == 88 && old.Dialogue != 88;}
split{return current.Dialogue == 13 && old.Dialogue != 13;}
reset{return current.menu == 6 && old.menu != 6;}
