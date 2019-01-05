package aimjs;

/**
 * ...
 * @author wangjz
 */
@:forward(length, indexOf, toString, iterator, map, filter, get)
@:allow(aimjs.Component)
abstract ComponentList(BindArray<Component>) //from Array<Component>
{
	inline public function new(a:Array<Component>) 
	{
		this = new BindArray(a);
	}
	
	function push(x : Component) : Int
	{
		return this.push(x);
	}
	
	function remove( x : Component ) : Bool
	{
		return this.remove(x);
	}
}