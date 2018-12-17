package aimjs;

/**
 * ...
 * @author wangjz
 */
@:forward
abstract BindArray<T>(Array<T>) from Array<T>// to Array<T> 
{
	inline public function new(a:Array<T>) {
		this = a;
	}
	
	public function setBind(field:String,parent:Model)
	{
		untyped this.__f = field;
		untyped this.__c = parent;
	}
	
	public function pop() : Null<T>
	{
		var v = this.pop();
		untyped if (this.__f) this.__c.onListPop(this.__f, v);
		return v;
	}
	
	public function push(x : T) : Int
	{
		var i = this.push(x);
		untyped if (this.__f)  this.__c.onListPush(this.__f, i-1, x);
		return i;
	}
	
	public function reverse() : Void
	{
		if (this.length <= 1) return;
		this.reverse();
		untyped if (this.__f) this.__c.onListReverse(this.__f);
	}
	
	public function shift() : Null<T>
	{
		var v = this.shift();
		untyped if (this.__f) this.__c.onListShift(this.__f, v);
		return v;
	}
	
	public function sort( f : T -> T -> Int ) : Void
	{
		this.sort(f);
		untyped if (this.__f) this.__c.onListSort(this.__f, f);
	}
	
	public function splice( pos : Int, len : Int ) : Array<T>
	{
		var v = this.splice(pos, len);
		untyped if (this.__f) this.__c.onListSplice(this.__f, pos, len, v);
		return v;
	}
	
	public function unshift( x : T ) : Void
	{
		this.unshift(x);
		untyped if (this.__f) this.__c.onListUnshift(this.__f, x);
	}
	
	public function insert( pos : Int, x : T ) : Void
	{
		this.insert(pos, x);
		untyped if (this.__f) this.__c.onListInsert(this.__f, pos, x);
	}
	
	public function remove( x : T ) : Bool
	{
		var inx = this.indexOf(x);
		if (inx ==-1) return false;
		var r = this.splice(inx, 1);
		var v = r != null && r.length > 0;
		untyped if (v && this.__f) this.__c.onListRemove(this.__f, inx, x);
		return v;
	}
	
	/*
	@:to
	public function toArray():Array<T>{
		return this;
	}
	*/
	
	@:arrayAccess function get(i:Int){
		return this[i];
	}
	
	@:arrayAccess function set(i:Int, v:T):T{
		var old = this[i];
		this[i] = v;
		untyped if (this.__f) this.__c.onListSet(this.__f, i, old, v);
		return v;
	}
}