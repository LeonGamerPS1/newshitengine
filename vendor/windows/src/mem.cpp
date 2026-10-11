#include "mem.h"
#include <iostream>
#include <windows.h>
#include <psapi.h>

int Memory::getMemory()
{
	PROCESS_MEMORY_COUNTERS pmc;

	if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
	{
		// WorkingSetSize = Der physische RAM, den deine App gerade belegt
		return static_cast<int>(pmc.WorkingSetSize);
	}
	return 0;
}