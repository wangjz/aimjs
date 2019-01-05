#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

/**
 * ...
 * @author wangjz
 */
class ModelMacro
{
	public macro static function build(): Array<Field>{
		var fields = Context.getBuildFields();
		for (field in fields){
			switch(field.kind)
			{
				case FieldType.FProp(get, set, t, e):
				{
					var metas = field.meta;
					var bindMeta=Lambda.find(metas, function(t){
						return t.name == "bind";
					});
					if (bindMeta != null){
						//trace(field);
						field.meta.remove(bindMeta);
						if (set == "default"){
							field.kind = FieldType.FProp(get, "set", t, e);
							var name = field.name;
							var setName = "set_" + name;
							var tpath:TypePath=switch(t){
								case TPath(p):p;
								default:null;
							}
							var func;
							if (tpath.name == "BindArray"){
								func = macro function $setName(v){
									if (v == null) throw "invalid value";
									if ($i{name} == v) return v;
									if (onPropertyChange($v{name}, $i{name}, v)){
										var old = $i{name};
										$i{name} = v;
										aimjs.Model.onListNewValue(this, $v{name}, old, v);
										return v;
									}
									return $i{name};
								}
							}
							else{
								func = macro function $setName(v){
									if ($i{name} == v) return v;
									if (v == null) throw "invalid value";
									if (onPropertyChange($v{name}, $i{name}, v)){
										var old = $i{name};
										$i{name} = v;
										aimjs.Model.onNewValue(this, $v{name}, old, v);
										return v;
									}
									return $i{name};
								}
							}
							
							//trace($v{func}.expr);
							switch($v{func}.expr)
							{
								case ExprDef.EFunction(n, f):
									fields.push({name:setName, kind:FieldType.FFun(f), pos:Context.currentPos()});
									default:
							}
						}
					}
				}
				default:	
			}
		}
		//Context.error("err",Context.currentPos());
		return fields;
	}
	
}
#end