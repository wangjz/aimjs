package aimjs;

/**
 * ...
 * @author wangjz
 */
@:allow(aimjs.BindArray,aimjs.Model)
class ArrayModel<T> extends Model
{
	@:isVar
	var _a_fields:Array<{id:Int,keys:Array<String>}>=null;
	
	@:isVar
	var arr:Array<T> = null;
	
	@:isVar
	public var length(get, null):Int;
	
	function new(a:Array<T>)
	{
		arr = a == null?new Array<T>():a;
		length = a.length;
	}
	
	function get_length():Int
	{
		return arr.length;
	}
}