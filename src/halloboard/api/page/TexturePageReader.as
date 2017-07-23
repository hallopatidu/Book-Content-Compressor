package halloboard.api.page
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.net.URLRequest;	
	import flash.events.Event;	
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import halloboard.api.page.interfaces.IPageFormat;
	import org.osflash.signals.Signal;
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.textures.TextureAtlas;

	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	
	/**
	 * reader = new TexturePageReader();
	 * reader.registerPageFormat(pageFormat);
	 * reader.completed.addOnce(onParsingCompletedHandler);
	 * reader.load("image.zip");
	 * 
	 * @author Hallopatidu@gmail.com
	 */
	public class TexturePageReader
	{
		public static const INIT:uint = 0;
		public static const LOAD_COMPLETED:uint = 1;
		
		protected var _status:uint = INIT;
		private var pageName:String;		
		private var zipPackage:FZip;
		private var _pageFormats:Object
		private var formatName:String;
		private var atlasTexture:TextureAtlas;
		
		private var _completed:Signal;
		
		/**
		 * 
		 * @param	debugSprite		flash.display.Sprite
		 */
		public function TexturePageReader()
		{			
			
		}
		
		/**
		 * 
		 */
		public function get completed():Signal 
		{
			if (!_completed) {
				_completed = new Signal();
			}
			return _completed;
		}
		
		
		/**
		 * 
		 * @param	exportFormat
		 */
		public function registerPageFormat(format:IPageFormat):void
		{
			if(format.name){
				pageFormats[format.name] = format;
				//_formatLength ++;
			}else {
				trace("Đối tương " + format + " cần có name");
			}
		}
		
		/**
		 * 
		 * @param	url
		 */
		public function load(url:String):void
		{
			if (!zipPackage)
			{
				zipPackage = new FZip();
			}
			//	
			pageName = removeExtAndGetFileName(url);			
			zipPackage.addEventListener(Event.OPEN, onOpenFileHandler);
			zipPackage.addEventListener(Event.COMPLETE, onLoadCompletedHandler);
			zipPackage.load(new URLRequest(url));
			//	
		}
		
		/**
		 * 
		 */
		public function get pageFormats():Object 
		{
			if(!_pageFormats){
				_pageFormats = new Object();
			}
			return _pageFormats;
		}
		
		/**
		 * 
		 * @return
		 */
		public function getImages():Vector.<Image>
		{
			return null;
		}
		
		
		/**
		 * 
		 * @return
		 */
		public function getTextures():Vector.<Texture>
		{
			return null;
		}
		
		
		/**
		 * 
		 * @param	format
		 * @return
		 */
		public function getBitmaps(format:String = null):Vector.<Bitmap>
		{
			return null;
		}
		
		
		/**
		 * 
		 * @param	format
		 * @return
		 */
		public function getStarlingPage(pageFormatName:String = null):Sprite
		{
			var seletecFormatName:String = pageFormatName ? pageFormatName : this.formatName;
			if (seletecFormatName) 
			{
				//	
				if (pageFormats[seletecFormatName] && atlasTexture) 
				{						
					var format:IPageFormat = pageFormats[seletecFormatName];
					if(format.content){
						var canvasSize:Object = format.setting;
						var quad:Quad = new Quad(canvasSize.width, canvasSize.height);
						var page:Sprite = new Sprite();
							page.addChild(quad);
						//	
						var length:int = format.numElement;
						for (var i:int = 0 ; i < length; i++) 
						{
							var elementName:String = String(format.element(i, "NAME"));
							var elementInfo:Object = format.element(i, "BOUND");
							var classType:String = String(format.element(i, "CLASS"));
							var elementImg:DisplayObject = createElement(elementName, classType, elementInfo);
							if (elementImg) {
								
								page.addChild(elementImg);
								// hallo test
								page.scaleX = page.scaleY = 0.5
							}
						}
						//	
						//page.scaleY = page.scaleX = 0.5;
						return page;
					}
					//	
				}else {
					throw new Error("Không đủ điều kiện để lấy page");
				}
				//	
			}
			//	
			return null;
		}
		
		
		/**
		 * 
		 * @param	classType
		 * @param	info
		 * @return
		 */
		protected function createElement(elementName:String, classType:String, info:Object):DisplayObject
		{
			if (!atlasTexture) {
				trace("Chưa có texture atlas nên không lấy được texture " + elementName);
				return null
			}
			switch(classType) {
				case "starling.display.Image":
					var texture:Texture = atlasTexture.getTexture(elementName);
					var elementImg:Image = new Image(texture);
						elementImg.x = info.x;
						elementImg.y = info.y;
						elementImg.width = info.width;
						elementImg.height = info.height;
					return elementImg;	
					break;
			}
			return null;
		}
		
		//--------------------
		
				/**
				 * 
				 * @param	e
				 */
				private function onOpenFileHandler(e:Event = null):void 
				{					
					if (_status == LOAD_COMPLETED) {
						//
						var fileCount:int = zipPackage.getFileCount();
						var atlasParam:Array = [];
						var content:String;
						//	
						for (var i:int = 0 ; i < fileCount; i++) 
						{
							//	
							var zipFile:FZipFile = zipPackage.getFileAt(i) as FZipFile;
							var fileName:String = removeExtAndGetFileName(zipFile.filename);
							var extension:String = getFileExtension(zipFile.filename);
							// trace("filename:: " + zipFile.filename + " - ex: " + extension);
							switch(extension) {
								case "png":
									atlasParam[0] = zipFile.content;
									break;
								case "xml":
									atlasParam[1] = zipFile.getContentAsString();
									break;
								case "page":
									content = zipFile.getContentAsString();
									readPageFormat(fileName, content);
									break;
							}							
						}
						//
						buildTextureAtlas.apply(this, atlasParam);
						//
					}else {
						setTimeout(onOpenFileHandler, 100);
					}
					//
				}
		
		
				/**
				 * 
				 * @param	e
				 */
				private function onLoadCompletedHandler(evt:Event):void
				{
					_status = LOAD_COMPLETED;
				}
		
		//--------------------
		
		/**
		 * 	Sử dụng bytearray ảnh và xml
		 */
		private function buildTextureAtlas(png:ByteArray, xmlStr:String):void
		{
			//var _this:TexturePageReader = this;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteLoadBytesdHandler);
			loader.loadBytes(png);
			//
			function onCompleteLoadBytesdHandler(e:Event):void 
			{
				(e.currentTarget as LoaderInfo).removeEventListener(Event.COMPLETE, onCompleteLoadBytesdHandler);
				var bitmapData:Bitmap = (e.currentTarget as LoaderInfo).content as Bitmap;
				var texture:Texture = Texture.fromBitmap(bitmapData);
				atlasTexture = new TextureAtlas(texture, new XML(xmlStr));
				//	
				completed.dispatch();
				//	
			}
			//
		}
		
		
		/**
		 * Lưu và phân tích content vào format tương ứng.
		 * @param	formatName
		 * @param	content
		 */
		private function readPageFormat(formatName:String, content:String):void
		{			
			if (pageFormats[formatName]) {
				this.formatName = formatName;
				(pageFormats[formatName] as IPageFormat).parse(content);
			}
		}
		
		
		/**
		 * Lay ten cua một file từ một url. Bỏ đuôi file.
		 * @param	url
		 * @return
		 */
		private function removeExtAndGetFileName(url:String):String
		{
			var splashIndex:int = Math.max(url.lastIndexOf("/"), url.lastIndexOf("\\"));
			var extRemoved:String = url.slice(splashIndex + 1, url.lastIndexOf("."));
			return extRemoved;
		}
		
		
		/**
		 * Lấy mỗi extension của file (vd: .swf, .zip, .png ...).
		 * @param	url
		 * @return
		 */
		private function getFileExtension(url:String):String
		{			
			var fileExtensionPattern:RegExp = /(?!\/\w+\.)(\w+$)|(?!\/\w+\.)(\w+)(?=\?.*$)/g;
			return String(url.match(fileExtensionPattern)[0]);
		}
		
		
	
	}// end class

}// end package