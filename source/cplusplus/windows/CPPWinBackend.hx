package cplusplus.windows;


@:cppInclude('iostream')
@:cppInclude('windows.h')
@:cppInclude('psapi.h')
@:dox('A class that does C++ shit to give you c++  usage on windows')

@:cppFileCode('#define WIN32_LEAN_AND_MEAN
#include <windows.h>

void EnsureThreadDpiAware() {
    HMODULE hUser32 = GetModuleHandle(TEXT("user32.dll"));
    if (!hUser32) return;

    // 1. Windows 10 (1703)+ : Per-Monitor V2 für den aktuellen Thread erzwingen.
    // Überschreibt eventuelle Sperren, die ein Framework (wie Lime/SDL) bereits gesetzt hat.
    typedef BOOL(WINAPI* SetThreadDpiAwarenessContextProc)(HANDLE);
    SetThreadDpiAwarenessContextProc pSetThreadDpi = 
        (SetThreadDpiAwarenessContextProc)GetProcAddress(hUser32, "SetThreadDpiAwarenessContext");
    
    if (pSetThreadDpi) {
        // (HANDLE)-4 entspricht DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
        pSetThreadDpi((HANDLE)-4);
        return; 
    }

    // 2. Windows 10 (Frühe Versionen): Prozess-Level Kontext
    typedef BOOL(WINAPI* SetProcessDpiAwarenessContextProc)(HANDLE);
    SetProcessDpiAwarenessContextProc pSetProcessCtx = 
        (SetProcessDpiAwarenessContextProc)GetProcAddress(hUser32, "SetProcessDpiAwarenessContext");
    
    if (pSetProcessCtx) {
        pSetProcessCtx((HANDLE)-4);
        return;
    }

    // 3. Windows 8.1 Fallback (via Shcore.dll)
    HMODULE hShcore = LoadLibrary(TEXT("shcore.dll"));
    if (hShcore) {
        typedef HRESULT(WINAPI* SetProcessDpiAwarenessProc)(int);
        SetProcessDpiAwarenessProc pSetAwareness = 
            (SetProcessDpiAwarenessProc)GetProcAddress(hShcore, "SetProcessDpiAwareness");
        
        if (pSetAwareness) {
            pSetAwareness(2); // 2 = PROCESS_PER_MONITOR_DPI_AWARE
        }
        FreeLibrary(hShcore);
        return;
    }

    // 4. Windows 7 / Vista Fallback (System-DPI)
    typedef BOOL(WINAPI* SetProcessDPIAwareProc)();
    SetProcessDPIAwareProc pSetDpiAware = 
        (SetProcessDPIAwareProc)GetProcAddress(hUser32, "SetProcessDPIAware");
    
    if (pSetDpiAware) {
        pSetDpiAware();
    }
}
')
class CPPWinBackend
{
    @:dox("The function that gives the class form (sorry rals, stole that line)")
	public static function getMemory():Int
	{
		var mem = 0;
		untyped __cpp__("
        PROCESS_MEMORY_COUNTERS pmc;

	if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
	{
		// WorkingSetSize = Der physische RAM, den deine App gerade belegt
		mem = static_cast<int>(pmc.WorkingSetSize);
	}
        ");
		return mem;
	}

	public static function makeDpiAware() {
		untyped __cpp__("EnsureThreadDpiAware();");
	}
}
