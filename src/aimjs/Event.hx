package aimjs;

/**
 * ...
 * @author wangjz
 */
class Event
{
	/**
		The name of the event
	**/
	public var type(default,null) : String;
	
	/**
		A reference to the target to which the event was originally dispatched.
	**/
	public var target(default,null) : IEventDispatcher;
	
	/**
		A Boolean indicating whether the event is cancelable.
	**/
	//public var cancelable(default, null) : Bool;
	
	/**
	   attach value
	**/
	public var value(default, null):Dynamic;

	public function new(type:String,target:IEventDispatcher,?value:Dynamic=null) //, ?cancelable:Bool=false
	{
		this.type = type;
		this.target = target;
		this.value = value;
		//this.cancelable = cancelable;
	}
}