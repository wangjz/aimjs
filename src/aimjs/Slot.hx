package aimjs;
import js.Lib;
import js.html.Node;
import js.html.Text;
import js.Browser;
import js.html.Element;
/**
 * ...
 * @author wangjz
 */
@:allow(aimjs.Component)
abstract Slot(Dynamic) from Dynamic to Dynamic
{
	function appendChild(node:Dynamic):Dynamic
	{
		var isMeNode = false;
		if (this.isAttached == Lib.undefined) isMeNode = true;
		if (isMeNode && node.isAttached != Lib.undefined){
			var objectId = this.__aim_objid;
			var com:Component = cast node;
			var _node:Node = cast this;
			if (objectId != Lib.undefined){
				var parent:Component = Component.getComponent(objectId);
				if (this == parent.localDoc){
					return parent.appendChild(com);
				}
				return parent.add(com, this);
			}
			else{
				com.attach(_node);
			}
			return node;
		}
		if (isMeNode)
		{
			if (this.__aim_objid != Lib.undefined) node.__aim_objid = this.__aim_objid;
		}
		return this.appendChild(node);
	}
	
	function removeChild(node:Dynamic){
		this.removeChild(node);
	}
}