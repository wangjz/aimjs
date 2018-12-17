package aimjs;

/**
 * ...
 * @author wangjz
 */
//import haxe.Constraints;
import js.html.Node;
import js.html.DocumentFragment;
import js.Browser;
class Model
{
	var _binds:Dynamic = null;
	/*
	@:generic
	public static function fromObject<T:Constructible<Void->Void>>(obj:Dynamic):T
	{
		var m = new T();
		untyped __js__("for (var o  in {0}){", m);
		var f:String = untyped __js__("o");
		if (f.indexOf("set_") == 0){
			var n = f.substring(4);
			var v = untyped obj[n];
			untyped if (v == undefined) v = null;
			untyped m[o](v);
		}
		untyped __js__("}");
		return m;
	}
	*/
	
	function getListBindProp(field:String):Array<{nodes:Array<Array<Node>>, func:Dynamic->DocumentFragment, isIndex:Bool, parent:Node}>
	{
		if (_binds == null) return null;
		var b =untyped _binds[field];
		if (untyped b) return b;
		return null;
	}
	
	function onListPop(field:String, v:Dynamic):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (v in props){
			var nodes = v.nodes.pop();
			if (nodes != null && nodes.length > 0) {
				for (node in nodes){
					if(node!=null&&node.parentNode != null) node.parentNode.removeChild(node);
				}
			}
		}
	}
	
	function onListPush(field:String,index:Int,v:Dynamic):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var nodes = prop.nodes;
			var func = prop.func;
			var isInx = prop.isIndex;
			var parent = prop.parent;
			if (nodes == null){
				nodes = [];
				prop.nodes = nodes;
			}
			var con:DocumentFragment = func(isInx?index:v);
			var tmps = [];
			while (con.firstChild != null){
				tmps.push(parent.appendChild(con.firstChild));
			}
			nodes.push(tmps);
		}
	}
	
	function onListReverse(field:String):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var list = prop.nodes;
			if (list != null && list.length > 0){
				list.reverse();
				var news = [];
				var tmps=[];
				for (nodes in list){
					if (nodes != null && nodes.length > 0){
						var parent = nodes[0].parentNode;
						var con:DocumentFragment = Browser.document.createDocumentFragment();
						for (node in nodes){
							con.appendChild(node);
						}
						tmps.push({con:con,parent:parent});
					}
					else{
						tmps.push(null);
					}
				}
				var tmp;
				for (item in tmps){
					var con = item.con;
					var parent = item.parent;
					tmp = [];
					while (con.firstChild != null){
						tmp.push(parent.appendChild(con.firstChild));
					}
					news.push(tmp);
				}
				prop.nodes = news;
			}
		}
	}
	
	function onListShift(field:String, v:Dynamic):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var list = prop.nodes;
			if (list != null && list.length > 0){
				var dels = list.shift();
				if (dels != null && dels.length > 0){
					for (node in dels){
						if (node != null && node.parentNode != null) node.parentNode.removeChild(node);
					}
				}
			}
		}
	}
	
	function onListSort(field:String,f:Dynamic->Dynamic->Int):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			
		}
	}
	
	function onListSplice(field:String,pos:Int, len:Int, v:Array<Dynamic>):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var _list = prop.nodes;
			if (_list != null && _list.length > 0){
				var dels = _list.splice(pos, len);
				if (dels != null && dels.length > 0){
					for (nodes in dels){
						for (node in nodes){
							if (node != null && node.parentNode != null) node.parentNode.removeChild(node);
						}
					}
				}
			}
		}
	}
	
	function onListUnshift(field:String,x:Dynamic):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var _list = prop.nodes;
			if (_list == null){
				_list = [];
				prop.nodes = _list;
			}
			var func = prop.func;
			var isInx = prop.isIndex;
			var con = func(isInx?0:x);
			var firstNode = _list.length == 0? null:_list[0][0];
			var parent = firstNode != null?firstNode.parentNode: prop.parent;
			var tmp = [];
			while (con.firstChild != null){
				tmp.push(parent.insertBefore(con.firstChild, firstNode));
			}
			_list.unshift(tmp);
		}
	}
	
	function onListInsert(field:String,pos:Int,x:Dynamic):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var _list = prop.nodes;
			if (_list == null){
				_list = [];
				prop.nodes = _list;
			}
			var func = prop.func;
			var isInx = prop.isIndex;
			var con = func(isInx?pos:x);
			var posNodes = _list[pos];
			var posNode = posNodes == null || posNodes.length == 0?null: _list[pos][0];
			var parent = posNode != null?posNode.parentNode: prop.parent;
			var tmp = [];
			while (con.firstChild != null){
				tmp.push(parent.insertBefore(con.firstChild, posNode));
			}
			_list.insert(pos, tmp);
		}
	}
	
	function onListRemove(field:String,inx:Int,x:Dynamic):Void
	{
		var props = getListBindProp(field);
		if (props == null) return;
		for (prop in props){
			var _list = prop.nodes;
			if (_list != null && _list.length > 0){
				var dels = _list.splice(inx, 1);
				if (dels != null && dels.length > 0){
					var nodes = dels[0];
					for (node in nodes){
						if (node != null && node.parentNode != null) node.parentNode.removeChild(node);
					}
				}
			}
		}
	}
	
	function onListSet(field:String,index:Int,old:Dynamic,v:Dynamic):Void
	{
		if (v == old) return;
		var props = getListBindProp(field);
		if (props == null) return;
		onListRemove(field, index, old);
		onListInsert(field, index, v);
	}
	
	function onListNewValue(f:String,old:Dynamic,cur:Dynamic)
	{
		if (cur == old) return;
		var props = getListBindProp(f);
		if (props == null) return;
		for (v in props){
			//删除老的
			var nodes = v.nodes;
			if (nodes != null && nodes.length > 0){
				for (_nodes in nodes){
					if (_nodes != null && _nodes.length > 0){
						for (node in _nodes){
							if (node.parentNode != null) node.parentNode.removeChild(node);
						}
					}
				}
			}
			nodes = [];
			v.nodes = nodes;
			//添加新的
			if (cur != null && cur.length > 0){
				var func = v.func;
				var isInx = v.isIndex;
				var parent = v.parent;
				var tmps;
				for (i in 0...cur.length)
				{
					tmps = [];
					var con:DocumentFragment = func(isInx?i:cur[i]);
					while (con.firstChild != null){
						tmps.push(parent.appendChild(con.firstChild));
					}
					nodes.push(tmps);
				}
			}
		}
	}
	
	public function bind(field:String,func:Dynamic->Dynamic->Void):Void
	{
		if (_binds == null) _binds = untyped {};
		untyped if (!_binds[field]) _binds[field] = [];
		untyped _binds[field].push(func);
	}
	
	public function bindSeq(field:String,nodes:Array<Array<Node>>,func:Dynamic->Dynamic,isIndex:Bool,parent:Node):Void
	{
		if (_binds == null) _binds = untyped {};
		untyped if (!_binds[field]) _binds[field] = [];
		untyped _binds[field].push({nodes:nodes, func:func, isIndex:isIndex, parent:parent});
	}
	
	function onNewValue(f:String,old:Dynamic,cur:Dynamic):Void
	{
		if (_binds == null) return;
		var b =untyped _binds[f];
		if (untyped b){
			for (i in 0...untyped b.length){
				untyped b[i](old,cur);
			}
		}
	}
}