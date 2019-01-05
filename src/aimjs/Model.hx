package aimjs;
import js.Lib;
import js.html.Node;
import js.html.DocumentFragment;
import haxe.DynamicAccess;
/**
 * ...
 * @author wangjz
 */
@:allow(aimjs.Component,aimjs.BindArray)
@:structInit
class Model
{
	var _sub_coms:Array<Int>;
	var _coms:Array<Int>;
	var _fields:Array<{id:Int,fields:DynamicAccess<Array<String>>}>;
	function onPropertyChange(name:String,oldValue:Dynamic,newValue:Dynamic):Bool
	{
		return true;
	}
	
	static function onListNewValue(m:Model,f:String,old:Dynamic,cur:Dynamic)
	{
		if (old == null) return;
		old.onUpdate(function(com:Component,v:{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Node, inArrInx:Int},cur:BindArray<Dynamic>){
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
			var binds = com._binds;
			var objectId = com.objectId;
			if (binds != null){
				var bv;
				var key;
				var keys = binds.keys();
				for (k in 0...keys.length){
					key = keys[k];
					bv = com._binds.get(key);
					if (bv.inArrInx !=-1 && bv.array == old){
						Model.unbind(bv.model, objectId, bv.field, key);
						com._binds.remove(key);
					}
				}
			}
			nodes = [];
			v.nodes = nodes;
			//添加新的
			if (cur.length > 0){
				var func = v.func;
				var isInx = v.isIndex;
				var parent = v.parent;
				var tmps;
				for (i in 0...cur.length)
				{
					tmps = [];
					var con:DocumentFragment = func(isInx?i:cur[i], i);
					while (con.firstChild != null){
						tmps.push(parent.appendChild(con.firstChild));
					}
					nodes.push(tmps);
				}
			}
		}, [null, null]);
		cur._parents.push(m);
		cur._paths.push(f);
		old._parents.remove(m);
		old._paths.remove(f);
		cur._a_fields = old._a_fields;
		old._a_fields = null;
	}
	
	
	
	static function onNewValue(m:Model,f:String,old:Dynamic,cur:Dynamic):Void
	{
		if (Std.is(cur, Model)){
			var _sub_coms = m._sub_coms;
			var isCom = Std.is(m, Component);
			var com:Component;
			if (isCom){
				com = cast m;
				if (com._binds!=null&&(_sub_coms==null || _sub_coms.indexOf(com.objectId) ==-1)){
					onSubUpdate(com, m, f, old, cur);
				}
			}
			if (_sub_coms!=null){
				for (i in 0..._sub_coms.length){
					com = Component.getComponent(_sub_coms[i]);
					if (com == null) continue;
					onSubUpdate(com, m, f, old, cur);
				}
			}
		}
		var _fields = m._fields;
		if (_fields == null || _fields.length == 0) return;
		for (i in 0... _fields.length){
			var objectId = _fields[i].id;
			var com = Component.getComponent(objectId);
			if (com == null) continue;
			var v;
			var fields = _fields[i].fields;
			var keys = fields.get(f);
			if (keys == null)continue;
			for (k in 0...keys.length){
				v = com._binds.get(keys[k]);
				v.fn(cur);
			}
		}
	}
	
	static function bind(model:Model,objectId:Int,field:String,key:String)
	{
		if (model._coms == null){
			model._coms = [];
			model._fields = [];
		}
		var _coms = model._coms;
		var _fields = model._fields;
		var v:Int = _coms[objectId];
		if (v != Lib.undefined && v != null){
			var fields = _fields[v].fields;
			var keys = fields.get(field);
			if (keys == null){
				fields.set(field, [key]);
			}
			else{
				if (keys.indexOf(key) ==-1) keys.push(key);
			}
		}
		else{
			var obj:{id:Int, fields:DynamicAccess<Array<String>>} = {id:objectId, fields:{}};
			obj.fields.set(field, [key]);
			_fields.push(obj);
			_coms[objectId] = _fields.length - 1;
		}
	}
	
	static function unbind(model:Model,objectId:Int,field:String, key:String):Void
	{
		var _coms = model._coms;
		if (_coms == null) return;
		var v:Int = _coms[objectId];
		if (v == Lib.undefined || v == null) return;
		var fields = model._fields[v].fields;
		var keys = fields.get(field);
		if (keys == null) return;
		keys.remove(key);
		if (keys.length == 0){
			fields.remove(field);
			if (fields.keys().length == 0){
				model._fields.splice(v, 1);
				if (model._fields.length == 0)_coms.splice(objectId, 1);
			}
		}
	}
	
	static function clearBind(model:Model,objectId:Int)
	{
		var _coms = model._coms;
		var _fields = model._fields;
		if (_coms == null) return;
		if (_fields == null) return;
		var v:Int = _coms[objectId];
		_coms.splice(objectId, 1);
		if (v == Lib.undefined || v == null) return;
		_fields.splice(v, 1);
	}
	
	static function clearArrayBind(com:Component,array:BindArray<Dynamic>,index:Int)
	{
		var binds = com._binds;
		var objectId = com.objectId;
		if (binds != null){
			var bv;
			var key;
			var keys = binds.keys();
			for (k in 0...keys.length){
				key = keys[k];
				bv = com._binds.get(key);
				if (bv.inArrInx !=-1&&bv.inArrInx==index && bv.array ==array){
					Model.unbind(bv.model, objectId, bv.field, key);
					com._binds.remove(key);
				}
			}
		}
	}
	
	static function setSubBind(model:Model,objectId:Int)
	{
		if (model._sub_coms == null){
			model._sub_coms = [];
		}
		var _coms = model._sub_coms;
		if (_coms.indexOf(objectId) ==-1)_coms.push(objectId);
	}
	
	static function removeSubBind(model:Model,objectId:Int)
	{
		if (model._sub_coms == null || model._sub_coms.length == 0) return;
		model._sub_coms.remove(objectId);
	}
	
	static function onSubUpdate(com:Component, model:Model,field:String,old:Model,cur:Model)
	{
		var objectId = com.objectId;
		var v;
		var key;
		var keys = com._binds.keys();
		for (i in 0...keys.length){
			key = keys[i];
			v = com._binds.get(key);
			if (v.chains == null && v.paths == null){
				continue;
			}else if (v.chains == null && v.paths != null){
				if (v.model == old && untyped com[v.paths[0]] == cur){
					if (old != null){
						unbind(old, objectId, v.field, key);
						removeSubBind(old, objectId);
					}
					v.model = cur;
					if (cur != null){
						bind(cur, objectId, v.field, key);
						setSubBind(cur, objectId);
						v.fn(untyped cur[v.field]);
					}
				}
			}
			else{
				var curPathInx = v.paths.length - 1;
				var curParentInx = v.chains.length - 1;
				var parent:DynamicAccess<Dynamic> = cast v.chains[curParentInx];
				var path = v.paths[curPathInx];
				if (v.model == old && parent[path] == cur){
					if (old != null){
						unbind(old, objectId, v.field, key);
						removeSubBind(old, objectId);
					}
					v.model = cur;
					if (cur != null){
						bind(cur, objectId, v.field, key);
						setSubBind(cur, objectId);
						v.fn(untyped cur[v.field]);
					}
				}
				else{
					//多级
					var curOld:Model;
					while (true){
						curPathInx = curPathInx - 1;
						curParentInx = curParentInx - 1;
						if (curPathInx < 0) break;
						path = v.paths[curPathInx];
						curOld =cast parent;
						parent = curParentInx ==-1?cast com:v.chains[curParentInx];
						if (curOld == old && parent[path] == cur){
							var old = v.model;
							var prev;
							var now;
							//修改链条
							while (curPathInx < v.paths.length - 1){
								prev = v.chains[curParentInx + 1];
								now = parent[path];
								removeSubBind(prev, objectId);
								setSubBind(now, objectId);
								v.chains[curParentInx + 1] = now;
								curParentInx += 1;
								curPathInx += 1;
								parent = v.chains[curParentInx];
								path = v.paths[curPathInx];
							}
							
							if (old != null && Std.is(old, Model)){
								unbind(old, objectId, v.field, key);
								removeSubBind(old, objectId);
							}
							v.model = parent[path];
							if (v.model != null&& Std.is(v.model, Model)){
								bind(v.model, objectId, v.field, key);
								setSubBind(v.model, objectId);
								v.fn(untyped v.model[v.field]);
							}
							break;
						}
					}
				}
			}
		}
	}
}