package aimjs;
import haxe.DynamicAccess;
import js.Browser;
import js.html.Node;
import js.Lib;
import js.html.Text;
import js.html.Element;
/**
 * ...
 * @author wangjz
 */
class Component extends Model
{
	static var __obj_id = 0;
	var objectId = 0;
	var isAttached = false;
	var localDoc:Node;
	var _doc = null;
	var doc(get, set):Dynamic;
	var _root = null;
	public var root(get, set):Node;
	public var parent(default, null):Component;
	private static var tags:DynamicAccess<Void->Component>;
	static var __components = new Array<Component>();
	var className:String;
	static function __init__()
	{
		tags = new DynamicAccess();
		setGlobalObj("getComponent", getComponent);
		setGlobalObj("getOwnComponent", getOwnComponent);
		setGlobalObj("__tags__", {});
	}
	
	public function new()
	{
		__obj_id++;
		objectId = __obj_id;
		__components[objectId] = this;
		className = Type.getClassName(Type.getClass(this));
	}
	
	function set_doc(v)
	{
		_doc = v;
		return v;
	}
	
	function get_doc()
	{
		if (isAttached&&_doc == localDoc){
			_doc = Browser.document;
		}
		return _doc;
	}
	
	function set_root(v)
	{
		_root = v;
		return v;
	}
	
	function get_root()
	{
		if (_root == null) return localDoc;
		if (isAttached&&parent!=null && untyped __js__("this._root instanceof DocumentFragment")){
			_root = parent.root;
		}
		return _root;
	}
	
	function getRealRoot()
	{
		if (_root == null) return localDoc;
		var curRoot = _root;
		if (parent!=null&&untyped __js__("{0} instanceof DocumentFragment",curRoot)){
			curRoot = parent.getRealRoot();
		}
		return curRoot;
	}
	
	function onViewInit()
	{
		
	}
	
	public static function registerComponent(tag,creater:Void->Component)
	{
		tags.set(tag, creater);
	}
	
	public static function createComponent(tag:String)
	{
		var creater = tags.get(tag);
		if (creater == null) return null;
		return creater();
	}
	
	public function attach(root:Node)
	{
		if (isAttached) unattach();
		_root = root;
		if (_doc == null){
			localDoc = Browser.document.createDocumentFragment();
			_doc = localDoc;
			render();
			onViewInit();
		}
		_root.appendChild(localDoc);
		isAttached = true;
	}
	
	public function unattach()
	{
		if (!isAttached) return;
		var nodes = Browser.document.body.childNodes;
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
		isAttached = false;
		if (parent != null){
			parent.remove(this);
			parent = null;
		}
		_root = null;
		_doc = localDoc;
	}
	
	public function destroy()
	{
		unattach();
		__components.splice(objectId, 1);
	}
	
	public function remove(child:Component)
	{
		
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
	
	static function setGlobalObj(name:String,obj:Dynamic)
	{
		var g = Lib.global;
		if (untyped !g.aimjs){
			 untyped g.aimjs = {};
		}
		untyped g.aimjs[name] = obj;
	}
	
	static function getGlobalObj(name:String):Dynamic
	{
		var g = Lib.global;
		if (untyped !g.aimjs) return null;
		var obj = untyped g.aimjs[name];
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
		return untyped node.__aim_objid;
	}
	
	function Txt(data : String):Text
	{
		var text = Browser.document.createTextNode(data);
		untyped text.__aim_objid = objectId;
		return text;
	}
	
	function Ele(localName : String,isOnly:Bool=false): Element
	{
		var ele = Browser.document.createElement(localName);
		if (!isOnly) {
			untyped ele.__aim_cls = className;
		}
		else{
			untyped ele.__aim_objid = objectId;
			
		}
		return ele;
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
		if (objId == Lib.undefined||objId==null) return null;
		return getComponent(objId);
	}
	
	function hasOnlyNodeExist(name:String):Bool
	{
		var tags = getGlobalObj("__tags__");
		var obj = untyped tags[className];
		if (untyped !obj) return false;
		var v = untyped obj[name];
		if (untyped !v) return false;
		return v;
	}
	
	function recordOnlyNode(name:String){
		var tags = getGlobalObj("__tags__");
		untyped if (!tags[className]) tags[className] = {};
		untyped tags[className][name] = true;
	}
}