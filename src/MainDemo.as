package
{
	//import cc.cote.chromatracker.ChromaTracker;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.filesystem.File;
	import halloboard.api.page.interfaces.IPageFormat;
	import halloboard.api.page.PageConvertor;
	import halloboard.application.pagetool.MainTool;
	import starling.events.Event;
	import starling.utils.RectangleUtil;
	import starling.utils.ScaleMode;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import halloboard.api.page.format.StarlingEditorFormat;
	import halloboard.api.page.TexturePageGenerator;
	import halloboard.api.page.TexturePageReader;
	import halloboard.api.texture.TextureGenerator;
	import starling.core.Starling;
	
	/**
	 * Sau khi ctr + enter demo sẽ chạy luôn và chỉ hỏi nơi save kết quả. 
	 * @author Hallopatidu@gmail.com
	 */
	public class MainDemo extends Sprite
	{
		/*[Embed(source = "../bin/tool/gs.exe", mimeType = "application/octet-stream")]
		public const GS:Class*/
		
		private var image:Bitmap;
		private var sprite:Sprite;
		private var container:Sprite;
		private var starling:Starling;
		private var reader:TexturePageReader;
		
		public function MainDemo()
		{
			super();
			if (stage)
			{
				onInit(null);
			}
			else
			{
				addEventListener(flash.events.Event.ADDED_TO_STAGE, onInit);
			}
		
		}
		
		private function onInit(e:flash.events.Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onInit);
			//
			var iOS:Boolean = Capabilities.manufacturer.indexOf("iOS") != -1;
			Starling.multitouchEnabled = true;  // useful on mobile devices.
			Starling.handleLostContext = !iOS;  // not necessary on iOS. Saves a lot of memory!
			Starling.handleLostContext = false;
			
			var viewPort:Rectangle = RectangleUtil.fit(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), ScaleMode.NONE, iOS);
			//
			starling = new Starling(MainTool, stage);	// 
			starling.antiAliasing = 0;
			starling.simulateMultitouch = false;
			starling.stage.stageWidth = stage.stageWidth; // <- same size on all devices !
			starling.stage.stageHeight = stage.stageHeight; // <- same size on all devices !
			starling.addEventListener(Event.ROOT_CREATED, onRootCreatedHandler);
			starling.start();
			//	
		}
				
				/**
				 * 
				 * @param	e
				 */
				private function onRootCreatedHandler(e:Event):void 
				{
					starling.removeEventListener(Event.ROOT_CREATED, onRootCreatedHandler);
					//	Sử dụng format của Starling Builder
					var pageFormat:IPageFormat = new StarlingEditorFormat();
					//	
					generation(pageFormat);
					//player(pageFormat);
					//convertion(pageFormat);
					//	
				}
		
		// ----------------------------- Sinh trực tiếp từ file pdf chứa nội dung sách ----------------------
				
		/**
		 * Convert một file pdf bất kì sang các trang sách đã được nén.
		 * Lưu ý: Class PageConvertor sử dụng tool GhostScript trong thư mục /tools để convert.
		 */
		private function convertion(pageFormat:IPageFormat):void 
		{
			var targetFile:File = File.applicationDirectory.resolvePath("input.pdf");
			var convertor:PageConvertor = new PageConvertor();
			convertor.registerPageFormat(pageFormat);
			convertor.completed.addOnce(function():void { 
													trace("Convert thanh cong !");
												});
			convertor.eachCompleted.add(function(currentPage:int):void {
													trace("Convert xong page " + currentPage);
												})
			//convertor.convert(targetFile.nativePath, 1, 1);
			//convertor.broswerPDF(2,6,7,8,9);
			convertor.broswerPDF(2,6,[7,9],21,23);
		}
		
		// --------------------------------- Sinh đơn lẻ file ảnh chứa nội dung trang sách -----------------
		
		/**
		 * Nén một file ảnh trang sách sang png. Hiện mới hỗ trợ PNG.
		 * @param	pageFormat
		 */
		private function generation(pageFormat:IPageFormat):void
		{
			var generator:TexturePageGenerator = new TexturePageGenerator(this);
				// Đăng kí định dạng 
			    generator.registerPageFormat(pageFormat);
				/*
				// dispatch khi moi qua trinh sinh page hoan thanh. Dispatch truoc khi save thanh file.
				generator.pagingCompleted.addOnce(...)
				
				// tien trinh phan tich page, tra ve % doi tuong duoc phan tich tren tong so doi tuong.
				generator.pagingProgress.addOnce(...)
				
				// tra ve % so byte duoc load tu page mau
				generator.loading.addOnce(...)
				*/
				// dispatch khi save file xong. Day là giai doan cuoi cung cua qua trinh.
				generator.saveCompleted.addOnce(function():void { trace("save thanh cong !!!") } );				
				
				generator.loadAndBuild("PAGE3.png");
				
		}
		
		
		//------------------------------  Dùng cho Player -----------------------------
			
		/**
		 * 
		 * @param	pageFormat
		 */
		private function player(pageFormat:IPageFormat):void
		{
			reader = new TexturePageReader();
			reader.registerPageFormat(pageFormat);
			reader.completed.addOnce(onParsingCompletedHandler);
			reader.load("dist/PAGE3.zip");			
		}
		
				/**
				 * 
				 */
				private function onParsingCompletedHandler():void 
				{
					/*var page:starling.display.Sprite = reader.getStarlingPage();
					page.scaleX = page.scaleY = 0.5*/
					starling.stage.addChild(reader.getStarlingPage());
				}
				
		
	
	}// end class

}// end package