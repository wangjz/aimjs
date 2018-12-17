package component;
import aimjs.Component;
import aimjs.BindArray;
import js.Browser;
import js.Lib;
import js.html.AnchorElement;
import js.html.Element;
import js.html.InputElement;
import js.html.MouseEvent;
import js.html.Node;
import js.html.StyleElement;
using StringTools;
/**
 * ...
 * @author wangjz
 */
@:build(ViewMacro.build("assets/todo.html"))
class Todo extends Component
{
	@:isVar
	public var list(default, set):BindArray<TodoModel>;
	
	static var style:StyleElement;
	
	var input:InputElement;
	
	var todoNodes:Array<Array<Node>>;
	public function new() 
	{
		super();
		list = [];
	}
	
	function set_list(v:BindArray<TodoModel>):BindArray<TodoModel>{
		var old = list;
		list = v;
		onListNewValue("list", old, v);
		list.setBind("list", this);
		return v;
	}
	
	function onDel(e:MouseEvent)
	{
		var aNode = e.target;
		trace(aNode);
		var top:Element =cast aNode;
		while (top.getAttribute("row")!="todo"&&top.parentElement!=null){
			top = top.parentElement;
		}
		if (top == aNode || top.getAttribute("row") != "todo") return;
		for (i in 0...todoNodes.length){
			if (todoNodes[i][0] == top){
				list.splice(i, 1);
				break;
			}
		}
	}
	
	function onModify(e:MouseEvent)
	{
		var aNode = e.target;
		var top:Element =cast aNode;
		while (top.getAttribute("row")!="todo"&&top.parentElement!=null){
			top = top.parentElement;
		}
		if (top == aNode || top.getAttribute("row") != "todo") return;
		for (i in 0...todoNodes.length){
			if (todoNodes[i][0] == top){
				var input:InputElement = cast top.getElementsByTagName("input").item(0);
				list[i].name = input.value;
				break;
			}
		}
	}
	
	function onAdd()
	{
		var v = input.value;
		if(v.trim().length==0)
		{
			Browser.window.alert("请输入todo事项");
			return;
		}
		var todo = new TodoModel();
		todo.name = v;
		list.push( todo);
	}
}