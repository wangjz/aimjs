package aimjs;
import haxe.Constraints.Function;
import js.html.Node;
import js.html.DocumentFragment;
import js.Browser;
/**
 * ...
 * @author wangjz
 */
@:forward
@:allow(aimjs.Model,aimjs.Component,aimjs.ComponentList)
abstract BindArray<T>(ArrayModel<T>)
{
	inline public function new(a:Array<T>) {
		this = new ArrayModel(a);
	}
	
	public function pop():Null<T>
	{
		if (this.arr.length == 0) return null;
		var v = this.arr.pop();
		onUpdate(onPop, [null, null, v, this.arr.length]);
		return v;
	}
	
	public function push(x : T) : Int
	{
		var i = this.arr.push(x);
		onUpdate(onPush, [null,null, i-1, x]);
		return i;
	}
	
	public function reverse() : Void
	{
		if (this.length < 2) return;
		this.arr.reverse();
		onUpdate(onReverse, [null,null]);
	}
	
	public function shift() : Null<T>
	{
		if (this.arr.length == 0) return null;
		var v = this.arr.shift();
		onUpdate(onShift, [null,null, v]);
		return v;
	}
	
	/*
	public function sort( f : T -> T -> Int ) : Void
	{
		this.sort(f);
		//untyped if (this.__f) this.__c.onListSort(this.__f, f);
	}
	*/
	
	public function splice( pos : Int, len : Int ) : Array<T>
	{
		var srcLen = this.arr.length;
		if ( srcLen== 0) return [];
		var v = this.arr.splice(pos, len);
		onUpdate(onSplice, [null, null, pos, len, v, srcLen]);
		return v;
	}
	
	public function unshift( x : T ) : Void
	{
		this.arr.unshift(x);
		onUpdate(onUnshift, [null,null,x]);
	}
	
	public function insert( pos : Int, x : T ) : Void
	{
		this.arr.insert(pos, x);
		onUpdate(onInsert, [null,null,pos, x]);
	}
	
	public function remove( x : T ) : Bool
	{
		var inx = this.arr.indexOf(x);
		if (inx ==-1) return false;
		var r = this.arr.splice(inx, 1);
		var v = r != null && r.length > 0;
		onUpdate(onRemove, [null, null, inx, x]);
		return v;
	}
	
	@:arrayAccess
	public function get(i:Int){
		return this.arr[i];
	}
	
	@:arrayAccess
	public function set(i:Int, v:T):T{
		var old = this.arr[i];
		if (v == old) return v;
		this.arr[i] = v;
		onUpdate(onSet, [null,null, i, old, v]);
		return v;
	}
	
	function iterator() : Iterator<T> untyped{
		return {
			cur : 0,
			arr : this.arr,
			hasNext : function() {
				return __this__.cur < __this__.arr.length;
			},
			next : function() {
				return __this__.arr[__this__.cur++];
			}
		};
	}
	
	function getBindProps(com:Component):Array<{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int,path:String}>
	{
		var fields = this._a_fields;
		if (fields == null) return null;
		var cid;
		for (i in 0...fields.length){
			if (fields[i].id == com.objectId){
				var keys = fields[i].keys;
				if (keys == null || keys.length == 0) return null;
				var props=[];
				for (k in 0...keys.length){
					props.push(com._arr_binds.get(keys[k]));
				}
				return props;
			}
		}
		return null;
	}
	
	function onUpdate(fn:Function,args:Array<Dynamic>)
	{
		var fields = this._a_fields;
		if (fields == null) return;
		var cid;
		for (i in 0...fields.length){
			cid = fields[i].id;
			var keys = fields[i].keys;
			if (keys == null || keys.length == 0) continue;
			var com = Component.getComponent(cid);
			if (com == null) continue;
			var prop;
			for (k in 0...keys.length){
				prop = com._arr_binds.get(keys[k]);
				args[0] = com;
				args[1] = prop;
				Reflect.callMethod(null, fn, args);
			}
		}
	}
	
	function onPop(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int}, v:Dynamic,index:Int):Void
	{
		Model.clearArrayBind(com,cast this, index);
		var nodes = prop.nodes.pop();
		if (nodes != null && nodes.length > 0) {
			var node;
			for (n in 0...nodes.length){
				node = nodes[n];
				if(node!=null&&node.parentNode != null) node.parentNode.removeChild(node);
			}
		}
	}
	
	function onPush(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},index:Int,v:Dynamic):Void
	{
		var nodes = prop.nodes;
		var func = prop.func;
		var isInx = prop.isIndex;
		var parent = prop.parent;// prop.parent.parentNode == null? Component.getOwnComponent(prop.parent).getAttachContainer():prop.parent;
		if (nodes == null){
			nodes = [];
			prop.nodes = nodes;
		}
		var con:DocumentFragment = func(isInx?index:v, index);
		var tmps = [];
		while (con.firstChild != null){
			tmps.push(parent.appendChild(con.firstChild));
		}
		nodes.push(tmps);
	}
	
	function onReverse(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int}):Void
	{
		var len = this.length - 1;
		if (com._binds != null){
			var keys = com._binds.keys();
			var key;
			var v;
			for (i in 0...keys.length){
				key = keys[i];
				v = com._binds.get(key);
				if (v.inArrInx !=-1 && v.array == cast this){
					v.inArrInx = cast Math.abs(v.inArrInx - len);
				}
			}
		}
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
	
	function onShift(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},value:Dynamic):Void
	{
		Model.clearArrayBind(com, cast this, 0);
		if (com._binds != null){
			var keys = com._binds.keys();
			var key;
			var v;
			for (i in 0...keys.length){
				key = keys[i];
				v = com._binds.get(key);
				if (v.inArrInx !=-1 && v.array == cast this){
					v.inArrInx -= 1;
				}
			}
		}
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
	
	function onSplice(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},pos:Int, len:Int, v:Array<Dynamic>,srcLen:Int):Void
	{
		if (v.length > 0){
			if (pos < 0){
				pos = srcLen + pos;
				if (pos < 0) pos = 0;
			}
			var end = pos + v.length;
			for (i in pos...end){
				Model.clearArrayBind(com, cast this, i);
			}
			if (end < this.length&&com._binds != null){
				var keys = com._binds.keys();
				var key;
				var b;
				for (i in 0...keys.length){
					key = keys[i];
					b = com._binds.get(key);
					if (b.inArrInx>=end && (b.array == cast this)){
						b.inArrInx = b.inArrInx - v.length;
					}
				}
			}
		}
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
	
	function onUnshift(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},x:Dynamic):Void
	{
		if (com._binds != null){
			var keys = com._binds.keys();
			var key;
			var v;
			for (i in 0...keys.length){
				key = keys[i];
				v = com._binds.get(key);
				if (v.inArrInx !=-1 && v.array == cast this){
					v.inArrInx += 1;
				}
			}
		}
		var _list = prop.nodes;
		if (_list == null){
			_list = [];
			prop.nodes = _list;
		}
		var func = prop.func;
		var isInx = prop.isIndex;
		var con = func(isInx?0:x, 0);
		var firstNode = _list.length == 0? null:_list[0][0];
		var parent = firstNode != null?firstNode.parentNode:prop.parent;// (prop.parent.parentNode == null? Component.getOwnComponent(prop.parent).getAttachContainer():prop.parent);
		var tmp = [];
		while (con.firstChild != null){
			tmp.push(parent.insertBefore(con.firstChild, firstNode));
		}
		_list.unshift(tmp);
	}
	
	function onInsert(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},pos:Int,x:Dynamic):Void
	{
		var srcLen = this.length - 1;
		if (pos < 0){
			pos = srcLen + pos;
			if (pos < 0) pos = 0;
		}
		else if (pos > srcLen){
			pos = srcLen;
		}
		if (com._binds != null&&pos<srcLen){
			var keys = com._binds.keys();
			var key;
			var v;
			for (i in 0...keys.length){
				key = keys[i];
				v = com._binds.get(key);
				if (v.inArrInx>pos && v.array == cast this){
					v.inArrInx += 1;
				}
			}
		}
		var _list = prop.nodes;
		if (_list == null){
			_list = [];
			prop.nodes = _list;
		}
		var func = prop.func;
		var isInx = prop.isIndex;
		var con = func(isInx?pos:x, pos);
		var posNodes = _list[pos];
		var posNode = posNodes == null || posNodes.length == 0?null: _list[pos][0];
		var parent = posNode != null?posNode.parentNode: prop.parent; //(prop.parent.parentNode == null? Component.getOwnComponent(prop.parent).getAttachContainer():prop.parent)
		var tmp = [];
		while (con.firstChild != null){
			tmp.push(parent.insertBefore(con.firstChild, posNode));
		}
		_list.insert(pos, tmp);
	}
	
	function onRemove(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},inx:Int,x:Dynamic):Void
	{
		Model.clearArrayBind(com, cast this, inx);
		if (com._binds != null&&inx<this.length-1){
			var keys = com._binds.keys();
			var key;
			var v;
			for (i in 0...keys.length){
				key = keys[i];
				v = com._binds.get(key);
				if (v.inArrInx>inx && v.array == cast this){
					v.inArrInx -= 1;
				}
			}
		}
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
	
	function onSet(com:Component,prop:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int},index:Int,old:Dynamic,cur:Dynamic):Void
	{
		if (com._binds != null){
			var keys = com._binds.keys();
			var key;
			var v;
			for (i in 0...keys.length){
				key = keys[i];
				v = com._binds.get(key);
				if (v.model==old&& v.inArrInx==index && v.array == cast this){
					v.model = cur;
					v.fn(untyped cur[v.field]);
				}
			}
		}
	}
	
	function bind(objectId:Int, key:String):Void{
		if (this._a_fields == null) this._a_fields = [];
		var inx =-1;
		for (i in 0...this._a_fields.length){
			if (this._a_fields[i].id == objectId){
				inx = i;
				break;
			}
		}
		if (inx ==-1){
			this._a_fields.push({id:objectId, keys:[key]});
		}
		else{
			var keys = this._a_fields[inx].keys;
			keys.push(key);
		}
	}
	
	@:from
	static function fromArray<T>(a:Array<T>)
	{
		return new BindArray(a);
	}
	/*
	@:to
	function toArray():Array<T>{
		return this;
	}
	*/
}