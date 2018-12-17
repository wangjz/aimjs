package;
import aimjs.Model;

/**
 * ...
 * @author wangjz
 */
class TodoModel extends Model
{
	@:isVar
	public var name(default, set):String = null;
	@:isVar
	public var thing(default, set):String="nothing";
	public function new() 
	{
		
	}
	
	function set_name(v:String):String
	{
		var old = name;
		name = v;
		onNewValue("name", old, v);
		return v;
	}
	
	function set_thing(v:String):String
	{
		var old = thing;
		thing = v;
		onNewValue("thing", old, v);
		return v;
	}
}