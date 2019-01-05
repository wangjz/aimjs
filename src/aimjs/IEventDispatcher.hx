package aimjs;

/**
 * @author wangjz
 */
interface IEventDispatcher 
{
	function addEventListener(eventName:String,  listener:Event->Void, ?priority:Int=0):Void; 
 
    function removeEventListener(eventName:String,  listener:Event->Void):Void;
 
    function dispatchEvent(eventName:String, ?value:Dynamic = null):Bool;
 
    function hasEventListener(eventName:String):Bool;
}