package macr;

class Cdef {
	public static var list(get, never):Map<String, Dynamic>;
	static inline function get_list():Map<String, Dynamic> return _get();

	static macro function _get() return macro $v{haxe.macro.Context.getDefines()};
}