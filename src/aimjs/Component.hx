package aimjs;
import haxe.Constraints.Function;
import haxe.DynamicAccess;
import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.CSSStyleSheet;
import js.html.Node;
import js.html.Text;
import js.html.Element;
import js.Lib;
/**
 * ...
 * @author wangjz
 */
@:allow(aimjs.Model,aimjs.BindArray,aimjs.Slot)
class Component extends Model implements IEventDispatcher
{
	static var __obj_id = 0;
	var objectId = 0;
	@:isVar
	public var isAttached(default, null) = false;
	var localDoc:Node;
	var _doc:Dynamic;
	var doc(get, set):Dynamic;
	@:isVar
	public var container(default, null):Node;
	public var parent(default, null):Component;
	public var childs(default, null):ComponentList;
	private static var __tags:DynamicAccess<Void->Component>;
	static var __components = [];
	static var __com_counts:DynamicAccess<Int> = {};
	static var __onlytags:DynamicAccess<Dynamic> = {};
	var __bindId = 0;
	var __events:DynamicAccess<Array<{priority:Int,handle:haxe.Constraints.Function}>>;
	
	var _binds:DynamicAccess<{model:Model,path:String,paths:Array<String>, field:String, fn:Function,chains:Array<Dynamic>,inArrInx:Int,array:BindArray<Dynamic>}> = null;
	var _arr_binds:DynamicAccess<{nodes:Array<Array<Node>>, func:Dynamic->Int->Dynamic, isIndex:Bool, parent:Dynamic, inArrInx:Int,path:String} >= null;
	@:isVar
	var bindM:Function;
	@:isVar
	var bindArr:Function;
	@:isVar
	var hasOnlyNode:Function;
	@:isVar
	var recordOnly:Function;
	@:isVar
	var Txt:String->Text;
	@:isVar
	var Ele:String->?String->Element;
	@:isVar
	public var visible(default, set):Bool = true;
	static function __init__()
	{
		__tags = new DynamicAccess();
		setGlobalObj("getComponent", getComponent);
		setGlobalObj("getOwnComponent", getOwnComponent);
	}
	
	public function new()
	{
		__obj_id++;
		objectId = __obj_id;
		__components[objectId] = this;
		//if (__com_counts[localClsName] == null) __com_counts[localClsName] = 0;
		//__com_counts[localClsName] += 1;
		childs =new ComponentList([]);
		__events = {};
		bindM = bindModel;
		bindArr = bindArray;
		hasOnlyNode = hasOnlyNodeExist;
		recordOnly = recordOnlyNode;
		Txt = _Txt;
		Ele = _Ele;
	}
	
	public inline static function localClassName()
	{
		 return "aimjs.Component";
	}
	
	function set_doc(v)
	{
		_doc = v;
		return v;
	}
	
	function get_doc()
	{
		if (_doc == null) return null;
		if (isAttached&&_doc == localDoc){
			return Browser.document;
		}
		return _doc;
	}
	
	function getAttachContainer():Node
	{
		if (container == null) return localDoc;
		if (!isAttached) return container;
		var curRoot = container;
		if (parent!=null&&untyped __js__("{0} instanceof DocumentFragment",curRoot)){
			curRoot = parent.getAttachContainer();
		}
		return curRoot;
	}
	
	function onViewInit()
	{
		
	}
	
	function onReady()
	{
		
	}
	
	public function attach(root:Node)
	{
		if (isAttached){
			if (root == container) return;
			unattach();
		}
		container = root;
		var _ready = null;
		if (_doc == null){
			localDoc = Browser.document.createDocumentFragment();
			untyped localDoc.__aim_objid = objectId;
			_doc = localDoc;
			render();
			onViewInit();
			_ready = onReady;
		}
		for (child in childs){
			if (child.container.parentNode == null || child.container == this.container) child.attach(child.container);
		}
		root.appendChild(localDoc);
		isAttached = true;
		if (_ready != null)_ready();
	}
	
	public function unattach()
	{
		if (!isAttached) return;
		var nodes = getAttachContainer().childNodes;
		var len = nodes.length;
		var node;
		var i = 0;
		while (i<len){
			node = nodes[i];
			if (untyped node.__aim_objid == objectId){
				localDoc.appendChild(node);
				len = len - 1;
			}else{
				i++;
			}
		}
		for (child in childs){
			if (child.container.parentNode == null || child.container == this.container) child.unattach();
		}
		isAttached = false;
		doc = localDoc;
	}
	
	function set_visible(v:Bool):Bool
	{
		if (v == visible) return v;
		if (isAttached == false) return v;
		if (onPropertyChange("visible", visible, v)){
			var nodes = getAttachContainer().childNodes;
			for (node in nodes){
				if (node.nodeName == "STYLE") continue;
				if (untyped node.style != Lib.undefined && untyped node.__aim_objid == objectId){
					var style:CSSStyleDeclaration = untyped node.style;
					if (v){
						if (untyped node.__aim_display != Lib.undefined){
							style.setProperty("display",untyped node.__aim_display);
							untyped __js__("delete {0}.__aim_display", node);
						}
					}
					else{
						var css = style.getPropertyValue("display");
						if ( css != "none"){
							style.setProperty("display", "none");
							untyped node.__aim_display = css;
						}
					}
				}
			}
			for (child in childs){
				child.visible = v;
			}
			var old = visible;
			visible = v;
			aimjs.Model.onNewValue(this, "visible", old, v);
			return v;
		}
		return visible;
	}
	/*
	public function destroyAll()
	{
		destroy();
		if (__com_counts[className] == 0){
			untyped __js__("delete __com_counts[{0}]",className);
			var o_tags = __onlytags[className];
			if (o_tags != null){
				var keys = __onlytags.keys();
				for (key in keys){
					var node:Dynamic = untyped __js__("{0}[{1}]", o_tags,key);
					if (Std.is(node, Component)){
						var com:Component = cast node;
						if (com.parent != null) com.parent.remove(node);
						com.destroyAll();
					}
					else{
						if (node != null && node.parentNode != null)untyped node.parentNode.removeChild(node);
					}
				}
				untyped __js__("delete __onlytags[{0}]",className);
			}
		}
	}
	*/
	
	public function destroy()
	{
		Model.clearBind(this,objectId);
		unattach();
		for (child in childs){
			child.destroy();
		}
		container = null;
		localDoc = null;
		__events = null;
		childs = null;
		_binds = null;
		__components.splice(objectId, 1);
		//__com_counts[localClsName] -= 1;
	}
	
	public function appendChild(child:Dynamic):Dynamic
	{
		var con = getAttachContainer();
		if (Std.is(child, Component)){
			return add(child, con);
		}
		else{
			if (child.__aim_cls == Lib.undefined){
				child.__aim_objid = objectId;
			}
			return con.appendChild(child);
		}
	}
	
	public function add(child:Component,?attachTo:Node=null):Component
	{
		child.attach(attachTo == null?container:attachTo);
		child.parent = this;
		childs.push(child);
		return child;
	}
	
	public function remove(child:Component):Component
	{
		var b = childs.remove(child);
		if (b) {
			child.parent = null;
			child.unattach();
		}
		return b?child:null;
	}
	
	public function createText(data : String):Text
	{
		var text = Browser.document.createTextNode(data);
		untyped text.__aim_objid = objectId;
		return text;
	}
	
	public function createElement(localName : String,?className:String=null): Element
	{
		var ele = Browser.document.createElement(localName);
		if (className!=null) {
			untyped ele.__aim_cls = className;
		}
		else{
			untyped ele.__aim_objid = objectId;
		}
		return ele;
	}
	
	function render(){
		
	}

	function setGlobalLocalObj(name:String,obj:Dynamic)
	{
		var g = Lib.global;
		if (untyped !g.aimjs){
			 untyped g.aimjs = {};
		}
		if (untyped !g.aimjs["com" + objectId]){
			untyped g.aimjs["com" + objectId] = {};
		}
		untyped g.aimjs["com" + objectId][name] = obj;
	}
	
	function getGlobalLocalObj(name:String):Dynamic
	{
		var g = Lib.global;
		if (untyped !g.aimjs) return null;
		if (untyped !g.aimjs["com" + objectId]) return null;
		var obj =untyped g.aimjs["com" + objectId][name];
		untyped if (obj) return obj;
		return null;
	}
	
	function removeGlobalLocalObj(name:String)
	{
		var g = Lib.global;
		if (untyped !g.aimjs) return;
		if (untyped !g.aimjs["com" + objectId]) return;
		untyped __js__("delete {0}", g.aimjs["com" + objectId][name]);
	}
	
	function clearGlobalLocalObj()
	{
		var g = Lib.global;
		if (untyped !g.aimjs) return;
		if (untyped !g.aimjs["com" + objectId]) return;
		untyped __js__("delete {0}", g.aimjs["com" + objectId]);
	}
	
	public function addEventListener(eventName:String,  listener:Event->Void, ?priority:Int = 0):Void
	{
		var events = __events.get(eventName);
		if (events == null){
			events = [];
			__events.set(eventName, events);
		}
		if (priority == 0){
			events.push({priority:priority, handle:listener});
		}
		else{
			var inx =-1;
			for (i in 0...events.length){
				if (priority > events[i].priority){
					events.insert(i, {priority:priority, handle:listener});
					inx = i;
					break;
				}
			}
			if (inx ==-1) events.push({priority:priority, handle:listener});
		}
	}
 
    public function removeEventListener(eventName:String,  listener:Event->Void):Void
	{
		var events = __events.get(eventName);
		if (events == null) return;
		for (i in 0...events.length){
			if (events[i].handle==listener){
				events.splice(i, 1);
				return;
			}
		}
	}
 
    public function dispatchEvent(eventName:String, ?value:Dynamic = null):Bool
	{
		var events = __events.get(eventName);
		if (events == null || events.length == 0) return false;
		var event = new Event(eventName, this, value);
		for (e in events){
			e.handle(event);
		}
		return true;
	}
 
    public function hasEventListener(eventName:String):Bool
	{
		var events = __events.get(eventName);
		if (events == null || events.length == 0) return false;
		return true;
	}
	
	static function hasOnlyNodeExist(clsName:String,name:String):Bool
	{
		var obj = untyped __onlytags[clsName];
		if (untyped !obj){
			return false;
		}
		return untyped !!obj[name];
	}
	
	static function recordOnlyNode(clsName:String,name:String,node:Dynamic){
		untyped if (!__onlytags[clsName]) __onlytags[clsName] = {};
		untyped __onlytags[clsName][name] = node;
	}
	
	static function bindModel(com:Component, model:Model,path:String, field:String,fn:Function,chains:Array<Dynamic>,?inArrInx:Int=-1,?array:BindArray<Dynamic>=null)
	{
		if (model == null) throw "invalid bind model";
		if (com._binds == null) com._binds = {};
		var paths = null;
		if (path!=null&&path.length > 0){
			paths = path.split(".");
		}
		var _binds = com._binds;
		com.__bindId++;
		var key = "" + com.__bindId;
		var bindInfo = {model:model, path:path, paths:paths, field:field, fn:fn, inArrInx:inArrInx, array:array,chains:chains };
		_binds.set(key, bindInfo);
		Model.bind(model, com.objectId, field, key);
		if (chains != null){
			var chain;
			for (i in 0...chains.length){
				chain = chains[i];
				if (Std.is(chain, Model)){
					Model.setSubBind(chain, com.objectId);
				}
			}
		}
	}
	
	static function bindArray(com:Component,arr:BindArray<Dynamic>,path:String,nodes:Array<Array<Node>>,func:Dynamic->Int->Dynamic,isIndex:Bool,parent:Node,?inArrInx:Int=-1)
	{
		if (arr == null) throw "invalid bind array";
		if (com._arr_binds == null)com._arr_binds = {};
		com.__bindId++;
		var key = "" + com.__bindId;
		var bindInfo = {nodes:nodes, func:func, isIndex:isIndex, parent:parent, inArrInx:inArrInx, path:path};
		com._arr_binds.set(key, bindInfo);
		arr.bind(com.objectId, key);
	}
	
	public static function registerComponent(tag,creater:Void->Component)
	{
		__tags.set(tag, creater);
	}
	
	public static function createComponent(tag:String)
	{
		var creater = __tags.get(tag);
		if (creater == null) return null;
		return creater();
	}
	
	public static function getComponent(objectId:Int):Component
	{
		if (objectId <= 0) return null;
		if (objectId > __components.length) return null;
		var component = __components[objectId];
		if (component == Lib.undefined) return null;
		return component;
	}
	
	public static function getOwnComponent(node:Node):Component
	{
		var objId = untyped node.__aim_objid;
		if (objId == Lib.undefined || objId == null) return null;
		return getComponent(objId);
	}
	
	static function setGlobalObj(name:String,obj:Dynamic)
	{
		var g = Lib.global;
		if (untyped !g.__aimjs){
			 untyped g.__aimjs = {};
		}
		untyped g.__aimjs[name] = obj;
	}
	
	static function getGlobalObj(name:String):Dynamic
	{
		var g = Lib.global;
		if (untyped !g.__aimjs) return null;
		var obj = untyped g.__aimjs[name];
		untyped if (obj) return obj;
		return null;
	}
	
	static function removeLocalObj(name:String)
	{
		var g = Lib.global;
		if (untyped !g.aimjs) return;
		untyped __js__("delete {0}", g.aimjs[name]);
	}
	
	static function getObjectId(node:Node):Int{
		var objId = untyped node.__aim_objid;
		return objId == Lib.undefined?0:objId;
	}
	
	static function _Txt(data : String):Text{
		return Browser.document.createTextNode(data);
	}
	
	static function _Ele(localName : String,?className:String=null):Element
	{
		var ele = Browser.document.createElement(localName);
		if (className != null) {
			untyped ele.__aim_cls = className;
		}
		return ele;
	}
}