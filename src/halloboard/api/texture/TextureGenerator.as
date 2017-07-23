package halloboard.api.texture
{
	import com.adobe.images.PNGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import halloboard.api.math.RectanglePacker;
	import org.osflash.signals.Signal;
	
	/**
	 * 
	 * @author Hallopatidu@gmail.com
	 */
	public class TextureGenerator
	{		
		static public const DEFAULT_IMAGE_EXTENSION:String = "png";
		static public const DEFAULT_XML_EXTENSION:String = "xml";
		
		protected var atlasName:String = "texture_";
		
		private var _texturePackage:Array;		
		private var mPacker:RectanglePacker;
		private var debugSprite:Sprite;
		private var sources:Vector.<BitmapData>;
		private var scale:Number;
		private var width:Number;
		private var height:Number;
		private var padding:int;
		
		private var _pagingCompleted:Signal;
		private var _pagingProgress:Signal;
		private var _error:Signal;
		private var savingFolder:File;
		
		public function TextureGenerator(debugSprite:Sprite = null)
		{
			super();
			this.debugSprite = debugSprite;
		}
		
		//---------------
		
		/**
		 * Hoàn thành việc tạo ra texture dạng bitmapdata
		 */
		public function get pagingCompleted():Signal 
		{
			if (!_pagingCompleted) _pagingCompleted = new Signal();
			return _pagingCompleted;
		}
		
		/**
		 * Tiến trình tạo bitmapdata của từng đổi tượng thành phần.
		 * function progressHandler(percent:Number):void
		 */
		public function get pagingProgress():Signal 
		{
			if (!_pagingProgress) _pagingProgress = new Signal();
			return _pagingProgress;
		}
		
		
		/**
		 * function errorHandler(message:String)
		 * 
		 */
		public function get error():Signal 
		{
			if (!_error) {
				_error	= new Signal();
			}
			return _error;
		}
		
		//---------------
		
		/**
		 * Tạo atlas và save. Hiện bảng hỏi save xong mới completed
		 * @param	textureName
		 * @param	sources
		 * @param	scale
		 * @param	padding
		 * @param	width
		 * @param	height
		 */
		public function createAndSaveAtlas(atlasName:String, sources:Vector.<BitmapData>, scale:Number = 1, padding:int = 1, width:Number = 1004, height:Number = 200):void
		{
			this.padding = padding;
			this.height = height;
			this.width = width;
			this.atlasName = atlasName;
			this.sources = sources;
			this.scale = scale;			
			generateMaxRectAtlas(createAndSaveTexturePackage);
		}
		
		
		/**
		 * Chỉ tạo atlas sau đó thông báo completed
		 * @param	textureName
		 * @param	sources
		 * @param	scale
		 * @param	padding
		 * @param	width
		 * @param	height
		 */
		public function createAtlas(atlasName:String, sources:Vector.<BitmapData>, scale:Number = 1, padding:int = 1, width:Number = 150, height:Number = 150):void
		{
			this.padding = padding;
			this.height = height;
			this.width = width;
			this.atlasName = atlasName;
			this.sources = sources;
			this.scale = scale;			
			generateMaxRectAtlas(createTexturePackage);
		}
		
		//-----------------------------------------------------------------
		
		/**
		 * Đóng gói các rectangle theo thuật toán Max Rect
		 * @param	callBackFunc
		 */
		private function generateMaxRectAtlas(callBackFunc:Function):void
		{
			if(sources){
				if (sources.length) {
					//	
					if (mPacker == null)
					{
						//	Xử lý trường hợp kích thước package nhỏ hơn kích thước của BitmapData đầu trong sources list.
						var lastSource:BitmapData = sources[sources.length - 1] as BitmapData;
						var initWidth:Number =	Math.max(width, lastSource.width);
						var initHeight:Number =	Math.max(height, lastSource.height);
						//	
						mPacker = new RectanglePacker(initWidth, initHeight, padding);
						//	
						if(callBackFunc != null){
							mPacker.packageCompleted = callBackFunc;
						}
						mPacker.packageProgess = packageProgress;
					}
					//
					for (var i:int = 0; i < sources.length; i++)
					{
						mPacker.insertRectangle(sources[i].width, sources[i].height, i);
					}
					//	
					mPacker.packRectangles();
					//	
				}
			}
		}
		
		/**
		 * 
		 * @param	percent
		 */
		protected function packageProgress(percent:Number):void 
		{
			pagingProgress.dispatch(percent);
		}
		
				
		/**
		 * Tạo gói texture bao gồm bitmapdata và XML config của atlas.
		 * Hàm sử dụng cho tham số callBackFunc của generateMaxRectAtlas(callBackFunc);
		 * @param	e
		 * @return	Array [BitmapData, XML String]
		 */
		private function createTexturePackage():Array 
		{	
			if(mPacker){
				if (mPacker.rectangleCount > 0)
				{
					var mBitmapData:BitmapData = new BitmapData(mPacker.packedWidth, mPacker.packedHeight, true, 0xFFFFFFFF);
					var matrix:Matrix = new Matrix();
					var rect:Rectangle = new Rectangle();
					var atlasText:String = "";
					
					for (var j:int = 0; j < mPacker.rectangleCount; j++)
					{
						//	
						var index:int = mPacker.getRectangleId(j);
						rect = mPacker.getRectangle(j, rect);
						// reset matrix
						matrix.identity();
						matrix.scale(scale, scale);
						matrix.translate(rect.x, rect.y);
						//
						drawBitmapData(index, mBitmapData, matrix);
						//	
						atlasText = atlasText + createSubText(index, rect);
						//	
					}
					//
					atlasText = '<TextureAtlas imagePath="' + atlasName + '.' + DEFAULT_IMAGE_EXTENSION + '">' + atlasText + "</TextureAtlas>";
					//
					//	Đóng gói thành mảng của bitmapdata và texture atlas.
					_texturePackage = [mBitmapData, atlasText];
					
					//	Reset các thông số của mPacker để sử dụng cho lần sau.
					mPacker.reset(mPacker.packedWidth, mPacker.packedHeight, mPacker.padding);
					pagingCompleted.dispatch();
					pagingCompleted.removeAll();
					pagingProgress.removeAll();
					//	
				}
				//	
				if (debugSprite) {
					if(mBitmapData){
						debugSprite.addChild(new Bitmap(mBitmapData));
						debugSprite.graphics.lineStyle(4, 0xFF0000, 1);
						debugSprite.graphics.drawRect(0, 0, mBitmapData.width, mBitmapData.height);
					}
				}
				//	
			}
			//	
			return _texturePackage;
			//	
		}
		
		//-------------------
		
		/**
		 * 
		 * Hàm sử dụng cho tham số callBackFunc của generateMaxRectAtlas(callBackFunc);
		 * @return
		 */
		private function createAndSaveTexturePackage():void 
		{			
			var atlasParam:Array = createTexturePackage();
			if (atlasParam) {
				if (savingFolder && savingFolder.exists) {
					saveAtlas(savingFolder, atlasParam[0], atlasParam[1]);
				}else{
					openBroswerToSave.apply(this, atlasParam);
				}				
			}
		}
		
		/**
		 * 
		 * @param	source
		 * @param	atlasXMLString
		 */
		private function openBroswerToSave(bitmapData:BitmapData, atlasXMLString:String):void
		{
			//var _this:TextureGenerator = this;
			var toFile:File = new File();
			toFile.browseForDirectory("Chọn thư mục chứa atlas");
			toFile.addEventListener(Event.SELECT, function onSelectedFileHandler(evt:Event):void {
														var selectedFile:File = evt.currentTarget as File;
															selectedFile.removeEventListener(Event.SELECT, onSelectedFileHandler);
														// Tao thu muc chua assets.
														savingFolder = selectedFile;
														//selectedFile = selectedFile.resolvePath(atlasName);
														//selectedFile.createDirectory();
														// Luu lai bytearray va xml cua atlas.
														saveAtlas(selectedFile, bitmapData, atlasXMLString);
													});
		}
		
		
		/**
		 * 
		 * @param	index
		 * @param	bitmapData
		 * @param	matrix
		 */
		protected function drawBitmapData(index:int, bitmapData:BitmapData, matrix:Matrix ):void
		{
			if (bitmapData && matrix) {
				var bitmapLength:int = sources.length;
				if(index < bitmapLength){
					// Vẽ bitmap data vào vị trí cần thiết theo matrix.
					bitmapData.draw(sources[index] as BitmapData, matrix);
				}else {
					trace("4: RangeError: Error #1125: The index " + index + " is out of range " + bitmapLength + ".");
				}
			}
		}
		
		/**
		 * 
		 * @param	atlasText
		 * @param	name
		 * @param	rect
		 * @return
		 */
		protected function createSubText(index:int, rect:Rectangle):String
		{
			//	Tạo alas XML
			var name:String = atlasName + index;
			var subText:String = '<SubTexture name="' + name + '" ' + 'x="' + rect.x + '" y="' + rect.y + '" width="' + rect.width + '" height="' + rect.height + '" frameX="0" frameY="0" ' + 'frameWidth="' + rect.width + '" frameHeight="' + rect.height + '"/>';			
			return subText;
		}
		
		/**
		 * 
		 * @param	source
		 * @param	atlasXMLString
		 */
		protected function saveAtlas(targetFolder:File, bitmapData:BitmapData, atlasXMLString:String):void
		{			
			if(targetFolder.exists){
				//	Write byte
				var bytesImage:ByteArray = PNGEncoder.encode(bitmapData);
				var bitmapFile:File 	 = targetFolder.resolvePath(atlasName + "." + DEFAULT_IMAGE_EXTENSION);
				var xmlFile:File 		 = targetFolder.resolvePath(atlasName+ "." + DEFAULT_XML_EXTENSION);
				//	
				var outStream:FileStream = new FileStream();
					outStream.open(bitmapFile, FileMode.WRITE);
					outStream.writeBytes(bytesImage);
					outStream.close();
					// Write xml
					outStream.open(xmlFile, FileMode.WRITE);
					outStream.writeMultiByte(atlasXMLString, "utf-8");
					outStream.close();
				//	
			}else {
				trace("Khong ton tai thu muc luu.Kiem tra lai thu muc luu.");
			}
		}
			
		//------------------------------------------------------------------
		
		
	
	}

}