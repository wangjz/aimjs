package component;

import aimjs.BindArray;
import aimjs.Component;
import js.Browser;
import js.html.ButtonElement;
import js.html.Element;
import js.html.Node;
/**
 * ...
 * @author wangjz
 */
@:build(ViewMacro.build("assets/hello.html"))
class Hello extends Component
{
	@:isVar
	public var name(default, set):String = "hello";
	
	@:isVar
	public var list(default, set):BindArray<Int>;
	
	//var btn:ButtonElement;
	var li_list:Array<Array<Node>>;
	public function new()
	{
		super();
		list = [];
	}
	
	function get_name():String
	{
		return name;
	}
	
	function set_name(v:String):String
	{
		var old = name;
		name = v;
		onNewValue("name", old, v);
		return v;
	}
	
	function set_list(v:BindArray<Int>):BindArray<Int>
	{
		var old = list;
		list = v;
		onListNewValue("list",untyped old,untyped v);
		untyped v.__f = "list";
		untyped v.__c = this;
		return v;
	}
	
	public function getMessage()
	{
		return "message";
	}
	
	function click()
	{
		name = "click";
	}
}