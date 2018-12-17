package view;
import aimjs.BindArray;
import aimjs.Component;
import aimjs.IView;
import js.Browser;
import js.html.Element;
import js.html.LIElement;
import js.html.Text;

/**
 * ...
 * @author wangjz
 */
class Hello implements IView
{
	public var component(default, null):Component;
	var h1:Element;
	var text:Text;
	var text1:Text;
	var list_bind:Array<LIElement>;
	public function new(component:Component) 
	{
		this.component = component;
		var doc = Browser.document;
		h1 = doc.createElement("h1");
		text = doc.createTextNode("hello ");
		text1 = doc.createTextNode(untyped component.name);
		var list:BindArray<Dynamic> = untyped component.list;
		if (list!=null)
		{
			list_bind = [];
			for (i in 0...list.length){
				var li = doc.createLIElement();
				var t = doc.createTextNode(list[i]);
				li.appendChild(t);
				list_bind[i] = li;
				component.bindListSetIndex("list", function(_i,old,cur){
					if (list_bind.indexOf(li) == _i)
					{
						t.textContent = cur;
					}
				});
			}
		}
		
		component.bindListPush("list", function(i,v){
			var li = doc.createLIElement();
			var t = doc.createTextNode(v);
			li.appendChild(t);
			t.textContent = v;
			component.container.appendChild(li);
			list_bind.push(li);
			component.bindListSetIndex("list", function(_i,old,cur){
				if (list_bind.indexOf(li) == _i)
				{
					t.textContent = cur;
				}
			});
		});
		
		component.bind("name", function(old,cur){
			text1.textContent = cur;
		});
		
		component.bind("list", function(old, cur){
			list = cur;
			if (cur != null)
			{
				list_bind = [];
				for (i in 0...list.length){
					var li = doc.createLIElement();
					var t = doc.createTextNode(list[i]);
					li.appendChild(t);
					list_bind[i] = li;
					component.bindListSetIndex("list", function(_i,old,cur){
						if (list_bind.indexOf(li) == _i)
						{
							t.textContent = cur;
						}
					});
					component.container.appendChild(li);
				}
			}
		});
	}
	
	public function mount()
	{
		h1.appendChild(text);
		h1.appendChild(text1);
		component.container.appendChild(h1);
		if (list_bind != null){
			for (i in 0...list_bind.length)
			{
				component.container.appendChild(list_bind[i]);
			}
		}
	}
	
	
	/*
	public function update(name:String, value:Dynamic) 
	{
		switch(name){
			case "name":
				text1.nodeValue =untyped value;
		}
	}
	*/
}


/*
		var f = macro function initView()
		{
			${v};
		}
		*/
		/*
		var func=switch(f.expr){
			case EFunction(name, _f):_f;
			case _:null;
		}
		*/
		/*
		var path = path.split('.')[0];
		var ps = path.split('/');
		var pack = [ps[0]];
		var cname:String = ps[1];
		cname = cname.charAt(0).toUpperCase() + (cname.length > 1?cname.substr(1):"");
		var baseType = Context.toComplexType(Context.getLocalType());// ComplexType.TPath({pack:["aimjs"], name:"Component"});
		var viewType:TypeDefinition = {
			pack:pack,
			name:cname, 
			pos:Context.currentPos(), 
			kind:TypeDefKind.TDAbstract(baseType, [baseType], [baseType]), 
			fields:[],
			meta:[
				{name:":forward", pos:Context.currentPos()}//,
				//{name:":access", pos:Context.currentPos(), params:[{expr:ExprDef.EBlock([macro component.Hello]), pos:Context.currentPos()}]}
			]
		};
		*/
		/*
		//var func_t = FieldType.FFun(func);
		//var render = {name:"render", access:[AOverride], kind:func_t, pos:Context.currentPos()};
		//viewType.fields.push(mount);
		//viewType.fields.push({name:"new", access:[APublic], kind:FieldType.FFun({args:[{name:"com", type:baseType}], ret:null, expr:macro{ this = com;untyped this.mount = mount; } }), pos:Context.currentPos()});
		//Context.defineType(viewType);
		//var typePath:TypePath = {pack:pack, name:cname};
		//return  macro new $typePath(this);
		*/