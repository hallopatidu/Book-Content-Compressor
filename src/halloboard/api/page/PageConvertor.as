package halloboard.api.page 
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;	
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.setTimeout;
	import org.osflash.signals.Signal;
	
	/**
	 * 
	 * @author Hallopatidu@gmail.com
	 */
	public class PageConvertor extends TexturePageGenerator 
	{
		// Nhúng cả file gs64 vào swf để convert. Lưu ý chạy bằng quyền administrator.
		[Embed(source="tool/gs64c.exe", mimeType="application/octet-stream")]
		private const GS64C:Class;
		
		public static const PDF:String = "pdf";
		public static const PAGE:String = "page";
		
		private var _eachCompleted:Signal;
		private var _completed:Signal;
		
		private var nativeProcess:NativeProcess;
		private var _gs64c:File;
		private var totalPages:int = 0;
		
		private var _temlateImageFolder:File;
		private var _imageWaitList:Array;			// Danh sach cac image can convert trong List.
		private var staticPageName:String;			// Luu ten cua file convert
		private var _pageWaitList:Array;
		
		private var _currentPage:int = 0;			// 
		private var currentPath:String;
		private var currentType:String;
		
		/**
		 * Sử dụng kèm theo với tool GhotScript x64.
		 * @param	debugSprite
		 */
		public function PageConvertor(debugSprite:Sprite=null) 
		{
			super(debugSprite);
			if (!Capabilities.supports64BitProcesses) {
				throw new Error("Hiện tính năng convert của PageConvertor chỉ hỗ trợ window x64 !");
			}else if (!NativeProcess.isSupported)  {				
				throw new Error("PageConvertor không hỗ trợ cho AIR build cho các thiết bị mobile, TV. Hoặc chưa config đúng để chạy debug, vào AIR App Properties > Installation tag chọn tích Extended Desktop ");
			}
			
		}
		
		//-------------------------------------------------
		
		/**
		 * Hoàn thành quá trình convert pdf sang ảnh.
		 * function(currentpage:int){
		 * 		trace("Hoan thanh chuan bi convert voi so trang " + totalPages);
		 * }
		 */
		public function get eachCompleted():Signal 
		{
			if (!_eachCompleted) {
				_eachCompleted = new Signal();
			}
			return _eachCompleted;
		}
		
		/**
		 * Hoàn thành việc convert pdf sang ảnh
		 * function(){
		 * 		trace("Convert thanh cong !");
		 * }
		 */
		public function get completed():Signal 
		{
			if (!_completed) {
				_completed = new Signal();
			}
			return _completed;
		}
		
		//-------------------------------------------------
		
		/**
		 * Example: 
		 * broswerPDF(2,6,7,8,9);	// Convert lần lượt các trang 2,6,7,8,9
		 * broswerPDF([3, 10]);		// Convert từ trang 3 đến trang 10.
		 * broswerPDF(2 , [3,10], 15, 21, 23);	// Phối hợp 2 cách trên.
		 * 
		 * @param	...options		nếu options kiểu int, convert số trang tương ứng .
		 * 							nếu option kiểu Array hai phần tử, convert từ phần tử số trang trong phần tử 1 đến số trang phần tử 2.
		 * 							
		 */
		public function broswerPDF(...options):void
		{
			//
			FileReference
			//
			var pdfFile:File = new File();
				pdfFile.addEventListener(Event.SELECT, onSelelectedFileHandler);
				pdfFile.browseForOpen("Chọn file sách dạng PDF !",[new FileFilter("Portable Document Format","*.pdf") ]);
			//	
			function onSelelectedFileHandler(e:Event):void 
			{
				pdfFile.removeEventListener(Event.SELECT, onSelelectedFileHandler);
				//
				currentPath = pdfFile.nativePath;				
				_pageWaitList = options.slice();
				convertPageWaitList();
				//	
			}
			//	
		}
		
		
		/**
		 * Bắt đầu convert.
		 * @param	url
		 * @param	type = "pdf"
		 */
		public function convert(path:String, startIndex:int = 0, endIndex:int = 0, type:String = "pdf"):void
		{
			// Sau còn mở rộng nhiều kiểu file khác nữa nên hàm này làm nhiệm vụ factory là chính.
			_imageWaitList = [];
			totalPages = 0;
			currentPath = path;
			currentType = type;
			//	
			switch(type) {
				case PDF:
				default:
					convertPDF(currentPath, startIndex, endIndex);
					break;
			}
			//	
		}
		
		//--------------------------------
		
		/**
		 * Convert dinh dang pdf
		 * @param	url
		 * @param	startIndex
		 * @param	endIndex
		 */
		private function convertPDF(path:String, startIndex:int = 0, endIndex:int = 0):void
		{			
			//	
			if (!nativeProcess) {
				//
				staticPageName = removeExtAndGetFileName(path);
				//Remove non alpha numeric characters from a string
				staticPageName = staticPageName.replace(/[^a-zA-Z 0-9]+/g, "");	
				//
				var processArgs:Vector.<String> = new Vector.<String>();
					processArgs.push("-dNOPAUSE");
					processArgs.push("-dBATCH");
					processArgs.push("-sDEVICE=png16m");
				//			
				if (startIndex != 0) {					
					processArgs.push("-dFirstPage=" + startIndex);
					if ((endIndex != 0) && (endIndex > startIndex)) {
						processArgs.push("-dLastPage=" + endIndex);
					}else {
						processArgs.push("-dLastPage=" + startIndex);
					}
				}
				//
					processArgs.push("-sOutputFile=" + PAGE + "-t%d.png");	// -t%d  là quy ước đặt tên page của BookPlayer.
					processArgs.push("-r150");
					processArgs.push(path);
				//
				var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();				
					nativeProcessStartupInfo.executable = gs64c;
					nativeProcessStartupInfo.arguments = processArgs;
					nativeProcessStartupInfo.workingDirectory = temlateImageFolder;
				//	
				nativeProcess = new NativeProcess(); 
				nativeProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
				nativeProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				nativeProcess.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);				
				//	
			}
			//
			nativeProcess.start(nativeProcessStartupInfo);
			//
		}
		
		
		/**
		 * Convert PNG sang chuẩn PAGE.
		 * Lưu ý: hàm này đệ quy 2 nháy. một nháy để duyệt hết _imageWaitList, một nháy để duyệt hết _pageWaitList.
		 * @param	pages
		 */
		private function convertPages():void
		{
			if (_imageWaitList.length) {
				// Tên của file png trong templateFolder được đánh theo thứ tự. 
				// Vì vậy cần đổi tên sang tên tương ứng với số trang.
				// indexArr[0]   :  Số thứ tự file trong template.
				// indexArr[1]   :  Số thứ tự trang trong PDF.
				var indexArr:Array =  (_imageWaitList.shift() as String).split(":");
				// -t%d  là quy ước đặt tên page của BookPlayer.
				var templateFile:File = temlateImageFolder.resolvePath(PAGE + "-t" + indexArr[0] + ".png");
				//
				_currentPage = int(indexArr[1]);
				var convertFile:File = temlateImageFolder.resolvePath(staticPageName + "-t" + _currentPage + ".png");				
				templateFile.moveTo(convertFile, true);
				//var list:Array = temlateImageFolder.getDirectoryListing();
				if (convertFile.exists) {
					this.saveCompleted.addOnce(function checkToConvert():void
												{													
													eachCompleted.dispatch(_currentPage);
													// Delay lại một chút vì saveCompleted được dispath trước khi saveCompleted.removeAll()
													setTimeout(convertPages, 100);
												});
					this.loadAndBuild(convertFile.nativePath);
				}
				//
			}else {
				// Xoa cac page trong file template.
				_temlateImageFolder.deleteDirectory(true);
				
				// Check trường hợp còn các hàng đợi convert trong _pageWaitList. Nếu còn thì tiêp tục công việc.
				if (!convertPageWaitList()) {
					eachCompleted.removeAll();
					completed.dispatch();
					completed.removeAll();
				}
				//
			}
			//
		}
		
		
		/**
		 * Kiểm tra và chạy các page còn chờ convert trong _pageWaitList.
		 * @return
		 */
		private function convertPageWaitList():Boolean
		{
			if (_pageWaitList && _pageWaitList.length) {
				var firstOption:* = _pageWaitList.shift();
				if (firstOption is int) {
					//	convert lan luot tung page.						
					convert(currentPath, int(firstOption), int(firstOption), currentType);
					return true;
					//	
				}else if (firstOption is Array) {
					//	convert từ trang này đến trang kia. Lưu ý chỉ lấy phần tử đầu và cuối nên tốt nhất là mảng chỉ cần 2 phẩn tử.
					if ((firstOption as Array).length) {
						convert(currentPath, (firstOption as Array)[0], (firstOption as Array)[(firstOption as Array).length - 1], currentType);
						return true;
					}
					//	
				}
				//
			}
			return false;
		}
		
				/**
				 * 
				 */
				/*private function checkToConvert():void
				{					
					trace("Convert xong page " + _currentPage);
					eachCompleted.dispatch(_currentPage);
					// Delay lại một chút vì saveCompleted được dispath trước khi saveCompleted.removeAll()
					setTimeout(convertPages, 100);
				}*/
		
		
		/**
		 * 
		 */
		private function removeNativeProgress():void
		{
			if(nativeProcess){
				nativeProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
				nativeProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				nativeProcess.removeEventListener(NativeProcessExitEvent.EXIT, onExit);
				nativeProcess.removeEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
				nativeProcess.exit();
				nativeProcess = null
			}
		}
		
				/**
				 * 
				 * @param	e
				 */
				private function onIOError(event:IOErrorEvent):void 
				{
					trace(event.toString());					
				}
				
				/**
				 * 
				 * @param	event
				 */
				private function onExit(event:NativeProcessExitEvent):void 
				{									
					//
					removeNativeProgress();
					convertPages();
					//
				}
				
				/**
				 * 
				 * @param	event
				 */
				private function onErrorData(event:ProgressEvent):void 
				{
					trace("ERROR -", nativeProcess.standardError.readUTFBytes(nativeProcess.standardError.bytesAvailable)); 
				}				
				
				/**
				 * 
				 * @param	event
				 */
				private function onOutputData(event:ProgressEvent):void 
				{					
					var output:String = nativeProcess.standardOutput.readUTFBytes(nativeProcess.standardOutput.bytesAvailable);
					var indexOfPageStr:int = output.indexOf("Page ");
					if (indexOfPageStr != -1) {					
						var checkString:String = output.substr(indexOfPageStr);						
						var pageNumberLabel:String = checkString.replace(/[^\d.]/g, "");					
						totalPages++;
						_imageWaitList.push(totalPages + ":" + pageNumberLabel);
					}
				}
				
				/**
				 * goshscript convert tool.
				 */
				public function get gs64c():File 
				{
					if (_gs64c) {						
						if (_gs64c.exists) {
							return _gs64c;
						}else {
							_gs64c = File.createTempFile();
						}
					}else {
						_gs64c = File.createTempFile();
					}
					//
					var gs64cBytes:ByteArray = new GS64C();
					var fs:FileStream = new FileStream();
						fs.open(_gs64c, FileMode.WRITE);
						fs.writeBytes(gs64cBytes);
						fs.close();
					gs64cBytes.clear();
					//
					return _gs64c;
				}
				
				/**
				 * Thư mục chứa file ảnh sau convert
				 */
				public function get temlateImageFolder():File 
				{
					if (!_temlateImageFolder) {
						_temlateImageFolder = File.createTempDirectory();
					}else if (!_temlateImageFolder.exists) {
						_temlateImageFolder = File.createTempDirectory();
					}
					return _temlateImageFolder;
				}
		
		
	}//

}//