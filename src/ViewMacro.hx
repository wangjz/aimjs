#if macro
import haxe.Utf8;
import htmlparser.HtmlParser;
import htmlparser.HtmlNodeElement;
import htmlparser.HtmlNodeText;
import htmlparser.HtmlNode;
import sys.io.File;
import haxe.macro.Expr;
import haxe.macro.Context;
import aimjs.parser.Parser;
import aimjs.parser.TBlock;
/**
 * ...
 * @author wangjz
 */
class ViewMacro
{
	private static var variableChar : EReg = ~/^[_A-Za-z0-9\.\[\]]+$/;
	static var codeStack:Array<String>;
	public macro static function build(path:String): Array<Field>{
		codeStack = [];
		var v = generateClass(path);
		var fields = Context.getBuildFields();
		fields.push({
			name:"render",
			access:[AOverride],
			kind:FieldType.FFun(v),
			pos:Context.currentPos()
		});
		return fields;
	}
	
	static function getFieldPathInfo(path:String):{path:String,scope:String,field:String}
	{
		var name = path;
		var isThis = path.indexOf("this.") == 0;
		if (isThis){
			name = name.substr(5);
		}
		var scope = "this";
		var lstDot = name.lastIndexOf(".");
		if (lstDot !=-1){
			scope = name.substring(0, lstDot);
			name=name.substring(lstDot+1);
		}
		return {path:path, scope:scope, field:name};
	}
	
	static function parseAttributeExpr(codeBlocks:Array<TBlock>,expr:String,token:String,pos:Int=0):{v:String, isCode:Bool, binds:Array<String>}
	{
		if (expr.length==0||StringTools.trim(expr).length==0) return {v:expr, isCode:false, binds:null};
		var codeLeftInx = expr.indexOf("<" + token+">");
		if (codeLeftInx !=-1){
			var endTag = "</" + token + ">";
			var codeRightInx = expr.indexOf(endTag);
			if (codeRightInx !=-1 && codeRightInx > codeLeftInx){
				var binds:Array<String> = null;
				var code = "";
				if (codeLeftInx > 0){
					var s = expr.substring(0, codeLeftInx);
					var startChar = s.charAt(0);
					var endChar = s.charAt(s.length - 1);
					if (endChar == ";"&& (startChar == "'" || startChar == '"') &&pos>0){
						code = '$s';
					}
					else{
						s = StringTools.replace(s, "\r", "\\r");
						s = StringTools.replace(s, "\n", "\\n");
						s = StringTools.replace(s, "\t", "\\t");
						s = StringTools.replace(s, '"', '\\"');
						code = '"$s"';
					}
				}
				var codeInx = Std.parseInt(expr.substring(codeLeftInx + token.length + 2, codeRightInx));
				var block = codeBlocks[codeInx];
				//trace(code);
				switch(block){
					case printBlock(s):
						code = code+(code.length == 0?"":"+") + '$s';
					case literal(s):
						//s = StringTools.replace(s, "\r", "\\r");
						//s = StringTools.replace(s, "\n", "\\n");
						//s = StringTools.replace(s, "\t", "\\t");
						//s = StringTools.replace(s, '"', '\\"');
						code = code+(code.length == 0?"":"+") + '$s';
					case codeBlock(s):
						//trace(s);
						//trace(code);
						if (variableChar.match(s)){//bind
							if (binds == null) binds = [];
							if (binds.indexOf(s) ==-1) binds.push(s);
							code = code+(code.length == 0?"":"+") + '$s';
						}
						else{
							if (s.indexOf("for") == 0 || s.indexOf("while") == 0){
								Context.error("can't use this expr at attribute value", Context.currentPos());
							}
							var isIf = s.indexOf("if") == 0;
							if (isIf&&s.indexOf("if#") == 0){
								var expInx = s.indexOf("(");
								var bindVars = expInx > 3? s.substring(3, expInx).split(","):null;
								s = "if" + s.substr(expInx);
								if (bindVars != null){
									if (binds == null) binds = [];
									for (f in bindVars){
										if (binds.indexOf(f) ==-1) binds.push(f);
									}
								}
							}
							else if (s.indexOf("#")==0)
							{
								var expInx = s.indexOf("#", 1);
								if (expInx !=-1){
									var bindVars = s.substring(1, expInx).split(",");
									s = s.substr(expInx+1);
									if (bindVars != null){
										if (binds == null) binds = [];
										for (f in bindVars){
											if (binds.indexOf(f) ==-1) binds.push(f);
										}
									}
								}
							}
							var isEnclose = !isIf && (s.charAt(0) != "(" || s.charAt(s.length - 1) != ")");
							var codeEndChar = code.length > 0? code.charAt(code.length - 1):"";
							code = code+((s.charAt(0) == "}" || s.charAt(s.length - 1) == "{")?(codeEndChar == '"' || codeEndChar == "'" || codeEndChar == "}"?"+":""):( code.length == 0?"":"+")) +(isEnclose?'($s)':'$s');
						}
				}
				//trace(code);
				var endInx = codeRightInx + endTag.length;
				if (endInx < expr.length){
					var nextExpr = parseAttributeExpr(codeBlocks, expr.substring(endInx), token, pos + endInx);
					if (nextExpr.binds != null){
						if (binds == null) binds = [];
						for (f in nextExpr.binds){
							if (binds.indexOf(f) ==-1) binds.push(f);
						}
					}
					var s = nextExpr.v;
					//trace(code);
					//trace(s);
					if (nextExpr.isCode){
						var endChar = s.charAt(s.length - 1);
						var startChar = s.charAt(0);
						var codeEndChar = code.length > 0? code.charAt(code.length - 1):"";
						code = code+(code.length == 0?"":( endChar == "}" || endChar == "{"?(((s.indexOf("if(") == 0 || s.indexOf("for(") == 0 || s.indexOf("while(") == 0) || ((startChar == "'" || startChar == '"') && codeEndChar != "{" ))?"+":""):"+")) + '$s';
					}
					else{
						var endChar = code.charAt(code.length - 1);
						//trace(code);
						//trace(s);
						code = code+( endChar == "}" || endChar == "{"?"": (code.length == 0?"":"+")) + '"$s"';
					}
				}
				//trace(code);
				return {v:code, isCode:true, binds:binds};
			}
		}
		//trace(expr);
		var s = expr;
		s = StringTools.replace(s, "\\", "\\\\");
		s = StringTools.replace(s, "\r", "\\r");
		s = StringTools.replace(s, "\n", "\\n");
		s = StringTools.replace(s, "\t", "\\t");
		s = StringTools.replace(s, '"', '\\"');
		s = StringTools.replace(s, "&nbsp;", "\u00A0");
		s = StringTools.replace(s, "&lt;", "\u003C");
		s = StringTools.replace(s, "&gt;", "\u003E");
		s = StringTools.replace(s, "&quot;", "\u0022");
		s = StringTools.replace(s, "&amp;", "\u0026");
		s = StringTools.replace(s, "&#64;", "\u0040");
		s = StringTools.replace(s, "&#37;", "\u0025");
		return {v:s, isCode:false, binds:null};
	}
	
	static function parseNode(codeBlocks:Array<TBlock>,_node:HtmlNode,token:String,nameId:{id:Int})
	{
		if (Std.is(_node, HtmlNodeElement)){
			var node = cast(_node, HtmlNodeElement);
			if (node.name == token){
				var block = codeBlocks[Std.parseInt(node.innerText)];
				switch(block){
					case printBlock(s):{
						//trace(s);
						var code = 'var __${nameId.id} = Txt(cast $s);con.appendChild(__${nameId.id});';
						nameId.id += 1;
						return code;
					};
					case literal(s):{
						if (StringTools.trim(s).length > 0){
							s = StringTools.replace(s, "\\", "\\\\");
							s = StringTools.replace(s, "\r", "\\r");
							s = StringTools.replace(s, "\n", "\\n");
							s = StringTools.replace(s, "\t", "\\t");
							s = StringTools.replace(s, '"', '\\"');
							s = StringTools.replace(s, "&nbsp;", "\u00A0");
							s = StringTools.replace(s, "&lt;", "\u003C");
							s = StringTools.replace(s, "&gt;", "\u003E");
							s = StringTools.replace(s, "&quot;", "\u0022");
							s = StringTools.replace(s, "&amp;", "\u0026");
							s = StringTools.replace(s, "&#64;", "\u0040");
							s = StringTools.replace(s, "&#37;", "\u0025");
							var code = 'var __${nameId.id} = Txt("$s");con.appendChild(__${nameId.id});';
							nameId.id += 1;
							return code;
						}
						return "";
					}
					case codeBlock(s):{
						if (variableChar.match(s)){
							var bindInfo = getFieldPathInfo(s);
							var code = 'var __${nameId.id} = Txt(cast $s);con.appendChild(__${nameId.id});${bindInfo.scope}.bind("${bindInfo.field}", function(old,cur){__${nameId.id}.textContent = cur;});';
							nameId.id += 1;
							return code;
						}
						//trace(s);
						if (s.charAt(0) == "}"){
							var code = codeStack.pop();
							//trace(code);
							if (code.indexOf("for#") == 0){
								var expInx = code.indexOf("(");
								var for_s = "for" + code.substr(expInx);
								var inInx = code.indexOf(" in ");
								var argName = code.substring(expInx + 1, inInx);
								var indexedInx = code.indexOf("...");
								var bindSource = code.substring(inInx + 4, code.indexOf(")"));
								if (indexedInx !=-1){
									bindSource = bindSource.substr(bindSource.indexOf("...") + 3);
									var lastDotInx = bindSource.lastIndexOf(".");
									if (lastDotInx ==-1) Context.error("invalid bind source:" + code, Context.currentPos());
									bindSource = bindSource.substring(0, lastDotInx);
								}
								if (!variableChar.match(bindSource))Context.error("invalid bind source:" + code, Context.currentPos());
								var bindVar = code.substring(4, expInx);//.seq
								var isClsBindVar = false;
								if (StringTools.trim(bindVar).length == 0){
									bindVar = '__bind_seq_${nameId.id}';
								}
								else if (bindVar.charAt(0) == "."){
									isClsBindVar = true;
									bindVar = bindVar.substr(1);
								}
								code = '${isClsBindVar?'if ($bindVar == null)$bindVar = []; ':'var $bindVar = []; '}var __tmp_l;$for_s var __tmp_con=__f_${codeStack.length+1}($argName); __tmp_l=[];while(__tmp_con.firstChild!=null){__tmp_l.push(con.appendChild(__tmp_con.firstChild));}$bindVar.push(__tmp_l);}bindSeq("$bindSource",$bindVar,__f_${codeStack.length+1},${indexedInx==-1?"false":"true"},con==localDoc?getRealRoot():con);';
								return "return topCon;"+s+code;
							}
						}
						if (s.charAt(s.length - 1) == "{"){
							//trace(s);
							codeStack.push(s);
						}
						if (s.indexOf("for#") == 0){
							var expInx = s.indexOf("(");
							var inInx = s.indexOf(" in ");
							var argName = s.substring(expInx+1, inInx);
							//保存当前容器
							var code = 'var __f_${codeStack.length}=function($argName){var con:Dynamic = document.createDocumentFragment();var topCon=con;';
							return code;
						}
						else if (s.indexOf("if#") == 0){
							var expInx = s.indexOf("(");
							var bindVars = s.substring(3, expInx).split(",");
							//trace(bindVars);
							s = "if"+s.substr(expInx);
						}
						return s;
					}
				}
			}else{
				if (node.name.indexOf(":") !=-1){
					var hasAttr = node.attributes != null && node.attributes.length > 0;
					var varName = "__" +nameId.id;
					var isClassVar = false;
					if (hasAttr && node.hasAttribute("a-id")){
						varName = node.getAttribute("a-id");
						if (varName.indexOf(".") == 0){
							isClassVar = true;
							varName = varName.substr(1);
						}
					}
					var code = '${isClassVar?'if($varName==null)$varName':'var $varName'}=aimjs.Component.createComponent("${node.name}");';
					if (hasAttr){
						for (attr in node.attributes){
							if (attr.name != "a-id"&&attr.name!="a-only"){
								var value = attr.value;
								if (value == null){
									//code+= '$varName.setAttribute("${attr.name}","");';
									code+= '$varName.${attr.name}=null;';
									continue;
								}
								var result = parseAttributeExpr(codeBlocks, value, token);
								value = result.v;
								if (attr.name.indexOf("a-on") == 0&&attr.name.length>4){
									var onevent = attr.name.substr(2);
									code+= '$varName.$onevent=$value;';
									if (result.binds != null){
										var bindFun = 'function(old,cur){$varName.$onevent=$value;}';
										for (f in result.binds){
											var bindInfo = getFieldPathInfo(f);
											code+= '${bindInfo.scope}.bind("${bindInfo.field}",$bindFun);';
										}
									}
								}
								else{
									if (result.isCode == false){
										//code+= '$varName.setAttribute("${attr.name}","$value");';
										code+= '$varName.${attr.name}="$value";';
									}
									else{
										//code+= '$varName.setAttribute("${attr.name}",$value);';
										code+= '$varName.${attr.name}=$value;';
									}
									//如果有绑定
									if (result.binds != null){
										var bindFun = 'function(old,cur){${result.isCode?'$varName.${attr.name}=$value;':'$varName.${attr.name}="$value";'}}';
										for (f in result.binds){
											var bindInfo = getFieldPathInfo(f);
											code+= '${bindInfo.scope}.bind("${bindInfo.field}",$bindFun);';
										}
									}
								}
							}
						}
					}
					code+= '$varName.parent=this;$varName.attach(con);';
					nameId.id += 1;
					return code;
				}
				else{
					var hasChild = node.nodes != null && node.nodes.length > 0;
					var hasAttr = node.attributes != null && node.attributes.length > 0;
					var varName = "__" +nameId.id;
					var isClassVar = false;
					if (hasAttr && node.hasAttribute("a-id")){
						varName = node.getAttribute("a-id");
						if (varName.indexOf(".") == 0){
							isClassVar = true;
							varName = varName.substr(1);
						}
					}
					var isOnlyNode = node.hasAttribute("a-only");
					var onlyStartCode = "";
					var onlyEndCode = "";
					if (isOnlyNode){
						onlyStartCode = 'if(!hasOnlyNodeExist("$varName")){';
						onlyEndCode = 'recordOnlyNode("$varName");}';
					}
					var code = '${hasChild?'var __prev${nameId.id} = con; ':""}${isClassVar?'if($varName==null)$varName':'var $varName'}=${isClassVar?"cast ":""}Ele("${node.name}"${isOnlyNode?",true":""});';
					if (hasAttr){
						for (attr in node.attributes){
							if (attr.name != "a-id"&&attr.name!="a-only"){
								var value = attr.value;
								if (value == null){
									code+= '$varName.setAttribute("${attr.name}","");';
									continue;
								}
								var result = parseAttributeExpr(codeBlocks, value, token);
								value = result.v;
								if (attr.name.indexOf("a-on") == 0&&attr.name.length>4){
									var onevent = attr.name.substr(2);
									code+= '$varName.$onevent=$value;';
									if (result.binds != null){
										var bindFun = 'function(old,cur){$varName.$onevent=$value;}';
										for (f in result.binds){
											var bindInfo = getFieldPathInfo(f);
											code+= '${bindInfo.scope}.bind("${bindInfo.field}",$bindFun);';
										}
									}
								}else{
									if (result.isCode == false){
										code+= '$varName.setAttribute("${attr.name}","$value");';
									}
									else{
										code+= '$varName.setAttribute("${attr.name}",cast $value);';
									}
									if (result.binds != null){
										var bindFun = 'function(old,cur){$varName.setAttribute("${attr.name}",cast $value);}';
										for (f in result.binds){
											var bindInfo = getFieldPathInfo(f);
											code+= '${bindInfo.scope}.bind("${bindInfo.field}",$bindFun);';
										}
									}
								}
							}
						}
					}
					code+= 'con.appendChild($varName);';
					if (hasChild) code+= 'con=$varName;';
					var cid = nameId.id;
					nameId.id += 1;
					if (hasChild){
						for (chidren in node.nodes){
							code+= parseNode(codeBlocks, chidren, token, nameId);
						}
					}
					if(hasChild)code+= 'con=__prev$cid;';
					return onlyStartCode+code+onlyEndCode;
				}
			}
		}else{
			var node = cast(_node, HtmlNodeText);
			var s = StringTools.trim(node.text);
			if (s.length > 0){
				s = node.text;
				if (StringTools.startsWith(s, "<!--") && StringTools.endsWith(s, "-->")) return "";
				var isCode = false;
				var binds = null;
				if (node.parent != null && (node.parent.name == "style" || node.parent.name == "script")){
					var result = parseAttributeExpr(codeBlocks, s, token);
					isCode = result.isCode;
					binds = result.binds;
					s = result.v;
				}
				else{
					s = StringTools.replace(s, "\\", "\\\\");
					s = StringTools.replace(s, "\r", "\\r");
					s = StringTools.replace(s, "\n", "\\n");
					s = StringTools.replace(s, "\t", "\\t");
					s = StringTools.replace(s, '"', '\\"');
					s = StringTools.replace(s, "&nbsp;", "\u00A0");
					s = StringTools.replace(s, "&lt;", "\u003C");
					s = StringTools.replace(s, "&gt;", "\u003E");
					s = StringTools.replace(s, "&quot;", "\u0022");
					s = StringTools.replace(s, "&amp;", "\u0026");
					s = StringTools.replace(s, "&#64;", "\u0040");
					s = StringTools.replace(s, "&#37;", "\u0025");
				}
				var code = 'var __${nameId.id} =Txt(${isCode?s:'"$s"'});con.appendChild(__${nameId.id});';
				if (binds != null){
					var bindFun = 'function(old,cur){__${nameId.id}.textContent=$s;}';
					for (f in binds){
						var bindInfo = getFieldPathInfo(f);
						code+= '${bindInfo.scope}.bind("${bindInfo.field}",$bindFun);';
					}
				}
				nameId.id += 1;
				return code;
			}
			return "";
		}
	}
	
	static function generateClass(path:String) {
		var cwd = Sys.getCwd();
		var fullPath = cwd + path;
		var content = File.getContent(fullPath);
		//content=Utf8.encode(content);
		var className = Context.getLocalClass().toString();
		className = StringTools.replace(className, ".", "-");
		content = StringTools.replace(content, "%class%", className);
		var parsedBlocks = new Parser().parse(content);
		//trace(parsedBlocks);
		var random = Std.random(114748364) + 100000000;
		var token = "code"+ Std.string(random);
		content = "";
		var codeBlocks = [];
		for (parseBlock in parsedBlocks)
		{
			switch(parseBlock){
				case printBlock(s):{
					content += ("<" + token + ">" +codeBlocks.length + "</" + token + ">");
					codeBlocks.push(parseBlock);
				};
				case literal(s):{
					content += s;
				};
				case codeBlock(s):{
					content += ("<" + token + ">" +codeBlocks.length + "</" + token + ">");
					codeBlocks.push(parseBlock);
				}
				default:
			}
		}
		//trace(content);
		var htmlNodes = HtmlParser.run(content);
		//trace(htmlNodes);		
		var func:Function = {args:[], ret:null, expr:null};
		var code = "super.render();var window=js.Browser.window;var document = window.document;var location=js.Browser.location;var navigator=js.Browser.navigator;var console=js.Browser.console;var con=localDoc;";
		var nameId = {id:0};
		for (node in htmlNodes){
			code+= parseNode(codeBlocks, node, token, nameId);
		}
		//trace(code);
		func.expr = Context.parseInlineString("{"+code+"}", Context.currentPos());
		return func;
  }
}
#end