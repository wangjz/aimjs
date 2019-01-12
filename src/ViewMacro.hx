#if macro
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
	static var preConExpr:EReg = ~/con=[_A-Za-z0-9\.]+;con=[_A-Za-z0-9\.]+;/;
	static var reConExpr:EReg = ~/con=[_A-Za-z0-9\.]+;/;
	static var codeStack:Array<String>;
	static var arrayStack:Array<{exp:String,indexName:String,indexVar:String,fn:String,bindSource:String,indexed:Bool,isClsBindVar:Bool,bindVar:String,id:Int}>;
	public macro static function build(path:String): Array<Field>{
		codeStack = [];
		arrayStack = [];
		var v = generateClass(path);
		var fields = Context.getBuildFields();
		fields.push({
			name:"render",
			access:[AOverride],
			kind:FieldType.FFun(v),
			pos:Context.currentPos()
		});
		var func = macro function localClassName(){
			return $v{Context.getLocalClass().toString()};
		}
		switch($v{func}.expr)
		{
			case ExprDef.EFunction(n, f):
				fields.push({name:"localClassName",access:[APublic,AInline,AStatic], kind:FieldType.FFun(f), pos:Context.currentPos()});
				default:
		}
		return fields;
	}
	
	static function getFieldPathInfo(path:String):{scope:String,field:String,localScope:String,chains:String}
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
		var localScope = scope;
		if (localScope == "this"){
			localScope = "";
		}
		
		var chains = "null";
		if (localScope.length > 0){
			var paths = localScope.split(".");
			if (paths.length >1){
				chains = "[";
				for (i in 0...paths.length-1)
				{
					chains += (i == 0?"":",") +paths.slice(0, i + 1).join(".");
				}
				chains += "]";
			}
		}
		return {scope:scope, field:name,localScope:localScope,chains:chains};
	}
	
	static function parseAttributeExpr(codeBlocks:Array<TBlock>,expr:String,token:String,pos:Int=0):{v:String, isCode:Bool, binds:Array<String>}
	{
		if (expr.length == 0 || StringTools.trim(expr).length == 0) return {v:expr, isCode:false, binds:null};
		var startTag = "<" + token + ">";
		var codeLeftInx = expr.indexOf(startTag);
		if (codeLeftInx !=-1){
			var endTag = "</" + token + ">";
			var codeRightInx = expr.indexOf(endTag);
			if (codeRightInx !=-1 && codeRightInx > codeLeftInx){
				var binds:Array<String> = null;
				var code = "";
				if (codeLeftInx > 0){
					var s = expr.substring(0, codeLeftInx);
					s = StringTools.replace(s, '"', '\\"');
					code = '"$s"';
				}
				var codeInx = Std.parseInt(expr.substring(codeLeftInx + token.length + 2, codeRightInx));
				var block = codeBlocks[codeInx];
				switch(block){
					case printBlock(s):
						//trace(s);
						code = code+(code.length == 0?"":"+") + '$s';
					case literal(s):
						//trace(s);
						//s = StringTools.replace(s, "\r", "\\r");
						//s = StringTools.replace(s, "\n", "\\n");
						//s = StringTools.replace(s, "\t", "\\t");
						//s = StringTools.replace(s, '"', '\\"');
						code = code+(code.length == 0?"":"+") + '$s';
					case codeBlock(s):
						//trace(code);
						//trace(s);
						if (variableChar.match(s)){//bind
							if (binds == null) binds = [];
							if (binds.indexOf(s) ==-1) binds.push(s);
							code = code+(code.length == 0?"":"+") + '$s';
						}
						else{
							if (s.indexOf("for") == 0 || s.indexOf("while") == 0){
								Context.error("can't use this expr at attribute value", Context.currentPos());
							}
							var lastCodeChar = code.length > 0?code.charAt(code.length - 1):"";
							if (s.charAt(0) == "}"){
								if (lastCodeChar == '"' || lastCodeChar == "'"){
									code+= ";";
								}
								else if (code.length == 0){
									code = '"";';
								}
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
							//trace(code);
							//trace(s);
							var sStart = s.charAt(0);
							var sEnd = s.charAt(s.length - 1);
							var isEnclose = !isIf && (sStart != "(" && sEnd != ")" && sStart != "}" && sEnd != "{");
							var codeEndChar = code.length > 0? code.charAt(code.length - 1):"";
							//trace(sStart);
							//trace(sEnd);
							//trace(isEnclose);
							//trace(codeEndChar);
							code = code+((sStart== "}" || sEnd== "{")?(codeEndChar == '"' || codeEndChar == "'" || codeEndChar == "}"?"+":""):( code.length == 0?"":"+")) +(isEnclose?'($s)':'$s');
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
					if (nextExpr.isCode){
						var endChar = s.charAt(s.length - 1);
						var startChar = s.charAt(0);
						var codeEndChar = code.length > 0? code.charAt(code.length - 1):"";
						//trace(code);
						//trace(s);
						code = code+
						(code.length == 0?"":
							(endChar == "}" || endChar == "{")?
							(
							((s.indexOf("if(") == 0 || s.indexOf("for(") == 0 || s.indexOf("while(") == 0) || ((startChar == "'" || startChar == '"') && codeEndChar != "{" ))?"+":""
							)
							:(StringTools.endsWith(code,"}else{")||StringTools.startsWith(code,"if(")?"":"+")
						) + '$s';
					}
					else{
						var endChar = code.charAt(code.length - 1);
						//trace(code);
						//trace(s);
						code = code+( endChar == "}" || endChar == "{"?"+": "") + '"$s"'; //(code.length == 0?"":"+")
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
						var code = 'var __${nameId.id} = Txt(cast $s);con.appendChild(__${nameId.id});';//Txt(this,cast $s)
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
							var code = 'var __${nameId.id} = Text("$s");con.appendChild(__${nameId.id});';//Txt(this,"$s")
							nameId.id += 1;
							return code;
						}
						return "";
					}
					case codeBlock(s):{
						if (variableChar.match(s)){
							var bindInfo = getFieldPathInfo(s);
							//Txt(this,cast $s)
							var code = 'var __${nameId.id} = Txt(cast $s);con.appendChild(__${nameId.id});bindM(this,cast ${bindInfo.scope},"${bindInfo.localScope}","${bindInfo.field}", function(cur){__${nameId.id}.textContent = cur;},${bindInfo.chains},${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar},${arrayStack[arrayStack.length - 1].bindSource}':"-1"});';
							nameId.id += 1;
							return code;
						}
						//trace(s);
						if (s.charAt(0) == "}"){
							var code = codeStack.pop();
							//trace(code);
							if (code.indexOf("for#") == 0){
								var arrInfo = arrayStack.pop();
								var for_s = arrInfo.exp;
								var argName = arrInfo.indexName;
								var bindSource = arrInfo.bindSource;
								var isClsBindVar = arrInfo.isClsBindVar;
								var bindVar = arrInfo.bindVar;
								var isInxed = arrInfo.indexed;
								var indexVar = arrInfo.indexVar;
								var fn = arrInfo.fn;
								var bindInfo = getFieldPathInfo(bindSource);
								code = '${isClsBindVar?'if ($bindVar == null)$bindVar = []; ':'var $bindVar = []; '}${!isInxed?'var $indexVar = 0; ':""}var __tmp_l;$for_s var __tmp_con=$fn($argName,$indexVar); __tmp_l=[];while(__tmp_con.firstChild!=null){__tmp_l.push(con.appendChild(__tmp_con.firstChild));}$bindVar.push(__tmp_l);${!isInxed?'$indexVar++; ':""}}bindArr(this,$bindSource,"${bindInfo.localScope}",$bindVar,$fn,$isInxed,con,${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar}':"-1"});';
								return "return topCon;" + s + code;
							}
						}
						if (s.charAt(s.length - 1) == "{"){
							//trace(s);
							codeStack.push(s);
						}
						if (s.indexOf("for#") == 0){
							var expInx = s.indexOf("(");
							var for_s = "for" + s.substr(expInx);
							var inInx = s.indexOf(" in ");
							var argName = s.substring(expInx + 1, inInx);
							
							var indexedInx = s.indexOf("...");
							var bindSource = s.substring(inInx + 4, s.indexOf(")"));
							if (indexedInx !=-1){
								bindSource = bindSource.substr(bindSource.indexOf("...") + 3);
								var lastDotInx = bindSource.lastIndexOf(".");
								if (lastDotInx ==-1) Context.error("invalid bind source:" + s, Context.currentPos());
								bindSource = bindSource.substring(0, lastDotInx);
							}
							if (!variableChar.match(bindSource))Context.error("invalid bind source:" + s, Context.currentPos());
							var bindVar = s.substring(4, expInx);
							var isClsBindVar = false;
							if (StringTools.trim(bindVar).length == 0){
								bindVar = '__bind_seq_${nameId.id}';
							}
							else if (bindVar.charAt(0) == "."){
								isClsBindVar = true;
								bindVar = bindVar.substr(1);
							}
							var indexVar = indexedInx !=-1?argName:'__a_i_${nameId.id}';
							var fn = '__a_fn_${nameId.id}';
							arrayStack.push({exp:for_s, indexName:argName, indexVar:indexVar, fn:fn, bindSource:bindSource, indexed:indexedInx !=-1, isClsBindVar:isClsBindVar, bindVar:bindVar, id:nameId.id});
							//保存当前容器
							var code = 'var $fn=function($argName,$indexVar){var con:Dynamic = document.createDocumentFragment();var topCon=con;';
							nameId.id += 1;
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
					var hasChild = node.nodes != null && node.nodes.length > 0;
					var hasAttr = node.attributes != null && node.attributes.length > 0;
					var varName = "__" +nameId.id;
					var isClassVar = false;
					if (hasAttr && node.hasAttribute("a-var")){
						varName = node.getAttribute("a-var");
						if (varName.indexOf(".") == 0){
							isClassVar = true;
							varName = varName.substr(1);
						}
					}
					var code = '${hasChild?'var __prev${nameId.id} = con;':""}${isClassVar?'if($varName==null)$varName':'var $varName'}=cast aimjs.Component.createComponent("${node.name}");';
					if (hasAttr){
						for (attr in node.attributes){
							if (attr.name.indexOf("a-") == 0 && (attr.name == "a-var" || attr.name == "a-only" || attr.name == "a-to")) continue;
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
									var bindFun = 'function(cur){$varName.$onevent=$value;}';
									for (f in result.binds){
										var bindInfo = getFieldPathInfo(f);
										code+= 'bindM(this,cast ${bindInfo.scope},"${bindInfo.localScope}","${bindInfo.field}",$bindFun,${bindInfo.chains},${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar},${arrayStack[arrayStack.length - 1].bindSource}':"-1"});';
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
									code+= '$varName.${attr.name}=cast $value;';
								}
								//如果有绑定
								if (result.binds != null){
									var bindFun = 'function(cur){${result.isCode?'$varName.${attr.name}=$value;':'$varName.${attr.name}="$value";'}}';
									for (f in result.binds){
										var bindInfo = getFieldPathInfo(f);
										code+= 'bindM(this,cast ${bindInfo.scope},"${bindInfo.localScope}","${bindInfo.field}",$bindFun,${bindInfo.chains},${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar},${arrayStack[arrayStack.length - 1].bindSource}':"-1"});';
									}
								}
							}
						}
					}
					//code+= 'this.add($varName,con);';
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
					return code;
					//nameId.id += 1;
					//return code;
				}
				else{
					var hasChild = node.nodes != null && node.nodes.length > 0;
					var hasAttr = node.attributes != null && node.attributes.length > 0;
					var isSlot = node.name == "slot";
					var varName = "__" +nameId.id;
					if (isSlot){
						if (hasAttr == false || node.hasAttribute("a-to") == false) Context.error("slot need target name,please set a-to attr", Context.currentPos());
						varName = node.getAttribute("a-to");
					}
					var isClassVar = false;
					if (hasAttr && node.hasAttribute("a-var")){
						varName = node.getAttribute("a-var");
					}
					if (varName.indexOf(".") == 0){
						isClassVar = true;
						varName = varName.substr(1);
					}
					var isOnlyNode = node.hasAttribute("a-only");
					var onlyStartCode = "";
					var onlyEndCode = "";
					if (isOnlyNode){
						onlyStartCode = 'if(!hasOnlyNode(localClass,"$varName")){';
						onlyEndCode = 'recordOnly(localClass,"$varName",$varName);}';
					}
					var code = "";
					if (isSlot){
						code = '${hasChild?'var __prev${nameId.id} = con; var __${nameId.id} = untyped $varName; ':""}';
						varName = "__" +nameId.id;
					}
					else{
						code = '${hasChild?'var __prev${nameId.id} = con;':""}${isClassVar?'if($varName==null)$varName':'var $varName'}=${isClassVar?"cast ":""}Ele("${node.name}"${isOnlyNode?",localClass":""});';//Ele(this,"${node.name}"${isOnlyNode?",localClass":""})
					}
					if (hasAttr){
						for (attr in node.attributes){
							if (attr.name.indexOf("a-") == 0 && ( attr.name == "a-var" || attr.name == "a-only" || attr.name == "a-to")) continue;
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
									var bindFun = 'function(cur){$varName.$onevent=$value;}';
									for (f in result.binds){
										var bindInfo = getFieldPathInfo(f);
										code+= 'bindM(this,cast ${bindInfo.scope},"${bindInfo.localScope}","${bindInfo.field}",$bindFun,${bindInfo.chains},${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar},${arrayStack[arrayStack.length - 1].bindSource}':"-1"});';
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
									var bindFun = 'function(cur){$varName.setAttribute("${attr.name}",cast $value);}';
									for (f in result.binds){
										var bindInfo = getFieldPathInfo(f);
										code+= 'bindM(this,cast ${bindInfo.scope},"${bindInfo.localScope}","${bindInfo.field}",$bindFun,${bindInfo.chains},${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar},${arrayStack[arrayStack.length - 1].bindSource}':"-1"});';
									}
								}
							}
						}
					}
					if (isOnlyNode&&(node.name == "script" || node.name == "style")){
						code+= 'document.head.appendChild($varName);';
					}
					else{
						code+= 'con.appendChild($varName);';
					}
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
				//Txt(this,${isCode?s:'"$s"'})
				var code = 'var __${nameId.id} =Txt(${isCode?s:'"$s"'});con.appendChild(__${nameId.id});';
				if (binds != null){
					var bindFun = 'function(cur){__${nameId.id}.textContent=$s;}';
					for (f in binds){
						var bindInfo = getFieldPathInfo(f);
						code+= 'bindM(this,cast ${bindInfo.scope},"${bindInfo.localScope}","${bindInfo.field}",$bindFun,${bindInfo.chains},${arrayStack.length>0?'${arrayStack[arrayStack.length - 1].indexVar},${arrayStack[arrayStack.length - 1].bindSource}':"-1"});';
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
		var localClass = Context.getLocalClass().toString();
		var className = StringTools.replace(localClass, ".", "-");
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
		var code = 'super.render();var window=js.Browser.window;var document = window.document;var localClass="$localClass";var con:aimjs.Slot=this;';
		var nameId = {id:0};
		for (node in htmlNodes){
			code+= parseNode(codeBlocks, node, token, nameId);
		}
		//简单优化
		var opFun = function(re:EReg)
		{
			var s = re.matched(0).split(";")[1] + ";";
			if (StringTools.endsWith(code,s)) return "";
			return s;
		}
		while (preConExpr.match(code)){
			code = preConExpr.map(code, opFun);
		}
		var inx = code.lastIndexOf(";", code.length - 2);
		if (inx !=-1){
			var s = code.substring(inx + 1);
			if (reConExpr.match(s)){
				code = code.substring(0, inx + 1);
			}
		}
		//trace(code);
		func.expr = Context.parseInlineString("{"+code+"}", Context.currentPos());
		return func;
  }
}
#end