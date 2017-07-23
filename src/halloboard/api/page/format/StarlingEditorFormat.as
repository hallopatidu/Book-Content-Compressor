package halloboard.api.page.format 
{
	import halloboard.api.page.interfaces.IPageFormat;
	
	/**
	 * Định nghĩa chuẩn đầu ra / đầu vào của page sau khi nén.
	 * Class này định nghĩa đầu ra theo chuẩn file project của stariling builder (http://wiki.starling-framework.org/builder/start)
	 * @author Hallopatidu@gmail.com
	 */
	public class StarlingEditorFormat implements IPageFormat
	{	
		private var childrenList:Array;
		private var canvasObj:Object;
		private var _content:String;
		
		public function StarlingEditorFormat() 
		{
			super();			
		}
		
		//----------------------------- IMPORT -----------------------
		
		
		public function parse(content:String):void
		{
			this._content = content;
			childrenList = [];
			var data:Object = JSON.parse(content)/*, function(key:String, value:Object):void
													{														
														switch(key) {
															case "createCanvasSize":
																createCanvasSize(value);
																break;
															
															case "params":
																addChildren(value);
																break;
															
														}
													});*/
			canvasObj = data.setting.createCanvasSize as Object;
			childrenList = data.layout.children as Array;
			//trace("data " + data)
		}
		
		
		public function element(index:int, type:String):Object
		{
			switch(type) {
				case "NAME":
					return (childrenList[index] as Object).params.name;
					break;
				case "BOUND":
					return (childrenList[index] as Object).params;
					break;	
				case "CLASS":
					return (childrenList[index] as Object).cls;
					break;
			}
			
			return null
		}
		
		
		public function get numElement():int
		{
			if (childrenList) {
				return childrenList.length;
			}
			return 0;
		}
		
		
		
		public function get content():String 
		{
			return _content;
		}
		
		//----------------------------- EXPORT -----------------------
		
		public function get name():String
		{
			return "starlingeditor";
		}
		
		/**
		 * Cấu hình page.
		 * @param	data
		 */
		public function set setting(data:Object):void
		{
			createCanvasSize(data);
		}
		
		/**
		 * 
		 */
		public function get setting():Object
		{
			return canvasObj;
		}
		
		
		/**
		 * 
		 * @param	fieldName
		 * @param	data
		 */
		public function record(fieldName:String, data:Object):void
		{
			switch(fieldName) {				
				case "ADD_CHILD":
					addChildren(data)
					break;
			}
		}
		
		
		/**
		 * 
		 * @return
		 */
		public function exports():Object
		{
			var exportObj:Object = {
				  layout:{
					children: childrenList,
					cls:"starling.display.Sprite",
					customParams:{},
					params:{
					  name:"root"
					}
				  },
				  setting:{
					createCanvasSize:canvasObj
				  },
				  version:"1.0"
				}
			//
			_content = JSON.stringify(exportObj);
			return _content;
		}
		
		//-----------------------------
		
		/**
		 * 
		 * @param	data
		 * @return
		 */
		private function addChildren(data:Object):void
		{
			if (!childrenList) {
				childrenList = [];				
			}
			
			var childrenNode:Object = {
				cls:"starling.display.Image",
				constructorParams:[
				  {
					cls:"starling.textures.Texture",
					textureName:String(data.name)
				  }
				],
				customParams:{},
				params: {
					name:String(data.name),
					width:Number(data.width),
					height:Number(data.height),
					x:Number(data.x),
					y:Number(data.y)
				}
			  }
			
			childrenList.push(childrenNode);			
		}
		
		//-----------------------------
		
		
		private function createCanvasSize(data:Object):void 
		{
			canvasObj = { x:data.width, y:data.height };
		}
		
		//-----------------------------
		
	}

}