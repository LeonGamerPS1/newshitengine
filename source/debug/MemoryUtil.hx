package debug;

import openfl.system.System;

class MemoryUtil
{
	public static function getMemory()
	{
		#if (cpp && windows)
		return cplusplus.windows.CPPWinBackend.getMemory();
		#else
		return System.totalMemory;
		#end
	}
}
