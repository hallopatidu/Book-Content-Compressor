package halloboard.api.page 
{
	import com.adobe.images.PNGEncoder;
	import deng.fzip.FZip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import halloboard.api.detector.ImageObjectDetector;
	import halloboard.api.page.format.StarlingEditorFormat;
	import halloboard.api.page.interfaces.IPageFormat;
	import halloboard.api.texture.TextureGenerator;
	import org.osflash.signals.Signal;
	
	/**
	 * var pageFormat:IPageFormat = new StarlingEditorFormat();
	 * var generator:TexturePageGenerator = new TexturePageGenerator(this);
	 * generator.registerPageFormat(pageFormat);
	 * // dispatch khi moi qua trinh sinh page hoan thanh. Dispatch truoc khi save thanh file.
	 * generator.pagingCompleted.addOnce(...)
	 * // tien trinh phan tich page, tra ve % doi tuong duoc phan tich tren tong so doi tuong.
	 * generator.pagingProgress.addOnce(...);
	 * // tra ve % so byte duoc load tu page mau
	 * generator.loading.addOnce(...);
	 * // dispatch khi save file xong. Day là giai doan cuoi cung cua qua trinh.
	 * generator.saveCompleted.addOnce(...);
	 * // 
	 * generator.loadAndBuild("image.png");
	 * 
	 * @author Hallopatidu@gmail.com
	 */
	public class TexturePageGenerator extends TextureGenerator 
	{
		static public const DEFAULT_PAGE_EXTENSION:String = "page";
		
		private var debugSprite:Sprite;
		private var detector:ImageObjectDetector;
		private var loader:Loader;
		private var zipPackage:FZip;
		private var _exportFormatList:Vector.<IPageFormat>;
		
		private var _loading:Signal;		
		private var _saveCompleted:Signal;
		
		public function TexturePageGenerator(debugSprite:Sprite = null) 
		{
			super(debugSprite);
		}
		
		
		/**
		 * Sau khi file .zip được lưu lại.
		 */
		public function get saveCompleted():Signal 
		{
			if (!_saveCompleted) {
				_saveCompleted = new Signal();
			}
			return _saveCompleted;
		}
		
		
		/**
		 * Quá trình load page
		 * function loadingProgress(percent)
		 * if percent == 100 => Completed loading.
		 */
		public function get loading():Signal 
		{
			if (!_loading) {
				_loading = new Signal();
			}
			return _loading;
		}
		
		
		/**
		 * Đăng ký định dạng cho page. Đăng kí bao nhiêu thì xuất hiện bấy nhiêu file .page
		 * @param	exportFormat
		 */
		public function registerPageFormat(format:IPageFormat):void
		{			
			if(exportFormatList.indexOf(format) == -1){
				exportFormatList.push(format);
			}
		}
		
		
		/**
		 * Load và tạo page từ một bức ảnh png. Sử dụng loader từ url.
		 * @param	imageUrl
		 */
		public function loadAndBuild(imageUrl:String):void
		{
			if (!loader)
			{
				loader = new Loader();
			}
			//	
			atlasName = removeExtAndGetFileName(imageUrl);
			//	
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadCompletedHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadIOErrorHandler);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgressHandler);
			loader.load(new URLRequest(imageUrl));
			//
		}
		
				/**
				 * 
				 * @param	e
				 */
				private function onLoadProgressHandler(e:ProgressEvent):void 
				{
					var percent:Number = Math.floor( (e.bytesLoaded / e.bytesTotal) * 100);
					loading.dispatch(percent);
				}
				
				/**
				 * 
				 * @param	e
				 */
				private function onLoadIOErrorHandler(e:IOErrorEvent):void 
				{
					error.dispatch("ioerror: "+e.toString());
				}
			
				/**
				 * 
				 * @param	e
				 */
				private function onLoadCompletedHandler(evt:Event):void 
				{
					var loaderInfo:LoaderInfo = evt.currentTarget as LoaderInfo;
					loaderInfo.removeEventListener(Event.COMPLETE, onLoadCompletedHandler);
					loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoadIOErrorHandler);
					loaderInfo.removeEventListener(ProgressEvent.PROGRESS, onLoadProgressHandler);
					//	
					if (!detector) {
						detector = new ImageObjectDetector();
					}
					//	
					var imageBmp:Bitmap = (evt.currentTarget as LoaderInfo).content as Bitmap;
					for (var i:int = 0 ; i < exportFormatList.length; i++) {
						(exportFormatList[i] as IPageFormat).setting = { width:imageBmp.width, height:imageBmp.height };
					}
					//	
					detector.dissect(imageBmp.bitmapData, function(detector:ImageObjectDetector):void {
															trace("Tạo và save atlas !");
															var bitmapdataList:Vector.<BitmapData> = detector.getBitmapDatas();
															createAndSaveAtlas(atlasName, bitmapdataList);
															//saveCompleted.addOnce()
														});
					//	
					loading.dispatch(100);
					loading.removeAll();
					//	
				}
				
				
				
				
				/**
				 * Lay ten cua một file từ một url. Bỏ đuôi file.
				 * @param	url
				 * @return
				 */
				protected function removeExtAndGetFileName(url:String):String
				{
					var splashIndex:int = Math.max(url.lastIndexOf("/"), url.lastIndexOf("\\"));
						//splashIndex = (splashIndex != -1) ? splashIndex : 0;
					var extRemoved : String = url.slice(splashIndex + 1, url.lastIndexOf("."));
					return extRemoved;
				}
				
				
				/**
				 * 
				 */
				private function get exportFormatList():Vector.<IPageFormat> 
				{
					if (!_exportFormatList) {
						_exportFormatList = new Vector.<IPageFormat>();
					}
					return _exportFormatList;
				}
		
		
		
		/**
		 * 
		 * @param	name
		 * @param	rect
		 * @return
		 */
		override protected function createSubText(index:int, rect:Rectangle):String 
		{
			var name:String = atlasName + index;			
			var posRect:Rectangle = detector.getRectById(index) as Rectangle;
			var data:Object = new Object();
				data.name = name;
				data.x = posRect.x;
				data.y = posRect.y;
				data.width = posRect.width;
				data.height = posRect.height;
			//	
			for (var i:int = 0 ; i < exportFormatList.length; i++){
				(exportFormatList[i] as IPageFormat).record("ADD_CHILD", data);
			}			
			//	
			return super.createSubText(index, rect);
		}
		
		/**
		 * Save thành Atlas
		 * @param	targetFolder
		 * @param	bitmapData
		 * @param	atlasXMLString
		 */
		override protected function saveAtlas(targetFolder:File, bitmapData:BitmapData, atlasXMLString:String):void 
		{
			if (targetFolder.exists)
			{
				//
				if(!zipPackage){
					zipPackage = new FZip();
				}
				// Chuẩn bị bytearray tài nguyên để nén zip.
				var bytesImage:ByteArray = PNGEncoder.encode(bitmapData);
				zipPackage.addFile(atlasName + "." + DEFAULT_IMAGE_EXTENSION, bytesImage);
				//
				var bytesXML:ByteArray = new ByteArray();
					bytesXML.writeMultiByte(atlasXMLString, "utf-8");
					bytesXML.position = 0;
				zipPackage.addFile(atlasName + "." + DEFAULT_XML_EXTENSION, bytesXML);
				//
				for (var i:int = 0 ; i < exportFormatList.length; i++) 
				{
					var exportFormat:IPageFormat = exportFormatList[i] as IPageFormat;
					var jsonContent:String = String(exportFormat.exports());
					var bytesJSON:ByteArray = new ByteArray();
						bytesJSON.writeMultiByte(jsonContent, "utf-8");
						bytesJSON.position = 0;
					zipPackage.addFile(exportFormat.name + "." + DEFAULT_PAGE_EXTENSION, bytesJSON);
				}
				//
				var file:File = targetFolder.resolvePath(atlasName + ".zip");
				var stream:FileStream = new FileStream();
					stream.open(file, FileMode.WRITE);
				zipPackage.serialize(stream);
					stream.close();
				//	
				dispose();
				//	
				saveCompleted.dispatch();
				//	
				saveCompleted.removeAll();
				error.removeAll();
				//	
			}
			//
		}
		
		
		/**
		 * 
		 */
		public function dispose():void 
		{
			//	
			if (zipPackage) {
				zipPackage.close();	
				while (zipPackage.getFileCount()) {
					zipPackage.removeFileAt(0);
				}
			}	
			//	clear detector trước khi saveCompleted.dispatch
			detector.dispose();
		}
		
	}// end class
	
}// end package