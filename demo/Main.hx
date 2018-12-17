package;
//import aimjs.Component;
import aimjs.Model;
import component.Hello;
import haxe.DynamicAccess;
import haxe.DynamicAccess;
import haxe.DynamicAccess;
import haxe.DynamicAccess;
import haxe.ds.StringMap;
//import js.html.DivElement;
//import component.Test2;
//import component.Test;
import component.Todo;
import js.Browser;
//import htmlparser.HtmlParser;
//import aimjs.BindArray;
import aimjs.Component;
//import aimjs.parser.Parser;
class Main 
{
	
	static function main() 
	{
		Component.registerComponent("test:todo", function(){
			return new Todo();
		});
		
		var hello = new Hello();
		//hello.name = "hello";
		hello.attach(Browser.document.body);
		
		//var doc = Browser.document.createDocumentFragment();
		//doc.appendChild(Browser.document.createDivElement());
		//doc.appendChild(Browser.document.createDivElement());
		//trace(doc.childElementCount);
		//for (node in doc.childNodes){
			//trace(node);
		//}
		//trace(doc.childNodes);
		//Browser.document.body.appendChild(doc);
		
		//trace(doc.childElementCount);
		//var hello2 = new Hello2();
		//hello2.name = "hihihi";
		//hello2.attach(Browser.document.body);
		
		//var l = [1,2,3];
		//hello.list = l;
		//hello.list[0] = 3;
		//var a = new BindArray<Int>([]);
		//var doc = Browser.document;
		//doc.createElement("div").appendChild(
		
		//var nodes = HtmlParser.run("<div t=0></div>");
		//trace(nodes);
		//hello.list.push(1);
		//hello.list[0] = 2;
		//trace(hello.list[0]);
		//var arr:Array<Int> = hello.list;
		//arr[0] = 1;
		//var parsedBlocks = new Parser().parse("@if(success){done!<div>@a @:b</div>}else{fail!<span>ggg@@www.com@@b</span>}");
		//trace(parsedBlocks);
	}
}

/*
package;
import haxe.DynamicAccess;
import haxe.macro.Expr;
class Test{
	public function new(){
		name = "test";
	}
	public var name(default, default):String;
}
class Main {
	
	static function main() {
		
		var smap:StringMap = ['firstName' => 'Skial', 'lastName' => 'Bainn'];
		trace( smap.lastName, smap.firstName ); // Bainn, Skial
		
		var mmap:MacroMap = cast smap;
		trace( mmap.lastName, mmap.firstName ); // Bainn, Skial
		var obj:MacroOjb<Test> =new Test();
		trace(obj.name);
		obj.name = "hello";
	}
	
}


abstract StringMap(Map<String, String>) from Map<String, String> {
	
	@:resolve
	private inline function resolve(name:String) {
		return this.get( name );
	}
	
}

abstract MacroMap(Map<String, String>) from Map<String, String> {
	
	@:op(a.b)
	private static macro function resolve(ethis:Expr, name:String) {
		var result = switch (name) {
			case 'firstName': 'Skial';
			case 'lastName': 'Bainn';
			case _: '';
		}
		return macro $v { result };
	}
}

abstract MacroOjb<T>(T) from T {
	public function new(o)
	{
		this = o;
	}
	
	@:arrayAccess
	public inline function get(key:String):Null<T> {
		return untyped this[key];
	}

	@:arrayAccess
	public inline function set(key:String, value:T):T {
		return untyped this[key] = value;
	}
	
	@:op(a.b)
	private static macro function resolve(ethis:Expr, name:String) {
		return macro untyped $ethis[$i{"\""+name+"\""}];
	}
}
*/