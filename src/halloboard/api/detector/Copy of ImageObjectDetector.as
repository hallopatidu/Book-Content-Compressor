package halloboard.api.detector 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.ConvolutionFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	import halloboard.api.controls.GenericFlow;
	import halloboard.api.math.OptimizePieces;
	import halloboard.api.vo.Piece;
	
	/**
	 * ...
	 * @author Hallopatidu@gmail.com
	 */
	public class ImageObjectDetector
	{		
		private var _pieceInfos:Array;		// Array of Piece
		private var _minimumArea:Number = 10;		// diện tích nhỏ nhất để tạo object
		
		
		public function ImageObjectDetector() 
		{
			_pieceInfos = [];
		}
		
		
		/**
		 * Mổ xẻ để tìm ra đối tượng.
		 * @param	pattern
		 * @return
		 */
		public function dissect(pattern:BitmapData, callBack:Function = null):ImageObjectDetector
		{			
			var _this:ImageObjectDetector = this;
			var outputRects:Array;
			var delayTime:int = (callBack != null) ? 10 : 0;
			GenericFlow.progress(function(next:Function):void {
									trace("Tạo pattern !");
									outputRects = _this.generateRects(pattern);	// array of rects
									trace("Số lượng mảnh tạo ra " + outputRects.length );
									next(outputRects);
								},
								function(outputRects:Array, next:Function):void {
									trace("Phân mảnh !");
									// Phan manh
									outputRects = OptimizePieces.fragment(outputRects, next);
									//next(outputRects);
								},
								function(outputRects:Array, next:Function):void { 
									trace("Tạo các piece chứa dữ. Số lượng sau phân mảnh: " + outputRects.length);
									// Kiem tra xem số lượng mảnh có quá lớn không ?
									// Nếu > 1000 phải phân ra
									_this.generatePieces(pattern, outputRects, next);
									//next();
								},
								function(outputRects:Array):void {
									trace("Số lượng pieces được tạo ra: " + outputRects.length);
									_pieceInfos = outputRects;
									if (callBack != null) {
										callBack(_this);
									}
									trace("end");
								}, delayTime);
			//	
			return this;
		}
		
		
		//-----------------------------------------
		
		/**
		 * Xác định các vùng đối tượng trong một bức ảnh.
		 * @param	pattern
		 * @return
		 */
		private function generateRects(pattern:BitmapData, maxLoop:int = 1000):Array
		{
			var i:uint = 0;
			var rect:Rectangle;
			var childRect:Rectangle;
			var outputRects:Array = [];
			var size:uint;	// Dien tich.
			//
			var diffImageSource:BitmapData = convertToDiffImage(pattern);
			//
			while (true) 
			{
				i++;
				if (i > maxLoop) {				
					break;
				}
				//
				rect = diffImageSource.getColorBoundsRect(0xffffffff, 0xffffffff);
				if (rect.isEmpty()) {
					break;
				}
				//
				var rectX:Number = rect.x;
				for (var rectY:uint = rect.y; rectY < rect.y + rect.height; rectY++) 
				{
					if (diffImageSource.getPixel32(rectX, rectY) == 0xffffffff) {
						//
						diffImageSource.floodFill(rectX, rectY, 0xffff00ff);
						//
						childRect = diffImageSource.getColorBoundsRect(0xffffffff, 0xffff00ff);
						size = childRect.width * childRect.height;
						// Tạo piece có kích thước lớn hơn kích thước nhỏ nhất quy định trong biến _minimumArea.
						if (size > _minimumArea) {
							outputRects.push(childRect);
						}
						//
						diffImageSource.floodFill(rectX, rectY, 0xff00ffff);
						//
					}
				}			
				//
			}
			//	
			return outputRects;
		}
		
		
		/**
		 * Tạo ra các Pieces từ danh sách rects.
		 * @param	rects
		 * @return
		 */
		private function generatePieces(pattern:BitmapData, rects:Array, callback:Function = null):Array
		{
			var piece:Piece;
			//var childRect:Rectangle;
			var outputRects:Array = [];
			//
			chooseRightBitmapRects(pattern, rects, 0, function():void {												
														if(callback != null){
															callback(outputRects);
														}														
													}, function(itemRect:Rectangle):void {
														piece = new Piece();						
														piece.bmpd = new BitmapData(itemRect.width, itemRect.height, true, 0xFFFFFFFF);					
														piece.bmpd.copyPixels(pattern, itemRect, new Point(0, 0));						
														piece.rect = itemRect;
														outputRects.push(piece);
													} );
			
				
			//
			/*if (startIndex < rects.length) {
				//
				childRect = rects[startIndex] as Rectangle;
				var pieceBmd:BitmapData = new BitmapData(childRect.width, childRect.height, true, 0xFFFFFFFF);
					pieceBmd.copyPixels(pattern, childRect, new Point(0, 0));
				var newRects:Array = generateRects(pieceBmd, 100);
				if (newRects.length) {
					//	
					trace("generatePieces::rects: " + newRects.length + " - " +  int((startIndex / rects.length) * 100) + "%");
					//	
					for (var i:int = 0; i < newRects.length; i++ ) {
						var itemRect:Rectangle = newRects[i] as Rectangle;						
						piece = new Piece();						
						piece.bmpd = new BitmapData(itemRect.width, itemRect.height, true, 0xFFFFFFFF);					
						piece.bmpd.copyPixels(pieceBmd, itemRect, new Point(0, 0));	
						itemRect.x = itemRect.x + childRect.x;
						itemRect.y = itemRect.y + childRect.y;
						piece.rect = itemRect;
						outputRects.push(piece);
					}
					//	
				}
				//	
				setTimeout(function():void { 							
								var nextIndex:int = startIndex + 1;				
								generatePieces(pattern, rects, function(output:Array):void{
																	outputRects = outputRects.concat(output);																
																	if(callback != null){
																		callback(outputRects);
																	}
																	
																}, nextIndex);
							}, 10);
				//
			}else{
				//
				if(callback != null){
					callback(outputRects);
				}
			}*/
			//	
			return outputRects;
		}
		
		/**
		 * Chọn ra các rects đã bỏ qua vùng trắng.
		 * @param	pattern
		 * @param	rects
		 * @param	startIndex
		 * @param	complete
		 * @param	progress
		 * @return
		 */
		private function chooseRightBitmapRects(pattern:BitmapData, rects:Array, startIndex:int = 0, complete:Function = null, progress:Function = null):void
		{
			//var piece:Piece;
			var childRect:Rectangle;
			//var outputRects:Array = [];
			//
			if (startIndex < rects.length) {
				//
				childRect = rects[startIndex] as Rectangle;
				var pieceBmd:BitmapData = new BitmapData(childRect.width, childRect.height, true, 0xFFFFFFFF);
					pieceBmd.copyPixels(pattern, childRect, new Point(0, 0));
				// Lấy các rects con nằm trong childRect
				var newRects:Array = generateRects(pieceBmd, 100);
				// Không tìm được newRects nào thì rõ ràng bên trong chỉ toàn khoảng trắng => bỏ qua.
				if (newRects.length) {
					//	
					trace("generatePieces::rects: " + newRects.length + " - " +  int((startIndex / rects.length) * 100) + "%");
					//	
					for (var i:int = 0; i < newRects.length; i++ ) {
						var itemRect:Rectangle = newRects[i] as Rectangle;
						itemRect.x = itemRect.x + childRect.x;
						itemRect.y = itemRect.y + childRect.y;
						//piece = new Piece();						
						/*piece.bmpd = new BitmapData(itemRect.width, itemRect.height, true, 0xFFFFFFFF);					
						piece.bmpd.copyPixels(pieceBmd, itemRect, new Point(0, 0));	*/						
						//piece.rect = itemRect;
						progress(itemRect);
						//outputRects.push(piece);
					}
					//	
				}
				//	
				setTimeout(function():void {
								var nextIndex:int = startIndex + 1;				
								chooseRightBitmapRects(pattern, rects, nextIndex, complete, progress);
							}, 10);
				//
			}else{
				//
				if(complete != null){
					complete();
				}
			}
			//	
		}
		
		//-------------------------------------------
		
		/**
		 * 
		 * @return
		 */
		public function getRects():Array
		{
			var rectList:Array = [];
			if (_pieceInfos.length) {
				//	
				for (var i:int = 0; i < _pieceInfos.length; i ++) {
					if (_pieceInfos[i]) {
						var piece:Piece = _pieceInfos[i] as Piece;						
						if (piece.rect) {
							rectList.push((piece.rect as Rectangle).clone());
						}
					}
				}
				//
			}
			//
			return rectList;
			//
		}
		
		/**
		 * 
		 * @param	id
		 * @return
		 */
		public function getRectById(id:int):Rectangle
		{
			var piece:Piece = _pieceInfos[id] as Piece;
			if(piece){
				if (piece.rect) {
					return (piece.rect as Rectangle).clone();
				}
			}
			return null;
		}
		
		/**
		 * 
		 * @return
		 */
		public function getBitmapDatas():Vector.<BitmapData>
		{
			var bmdtList:Vector.<BitmapData> = new Vector.<BitmapData>();
			if(_pieceInfos.length){
				//	
				for (var i:int = 0; i < _pieceInfos.length; i ++) {
					if (_pieceInfos[i]) {
						var piece:Piece = _pieceInfos[i] as Piece
						if (piece.bmpd) {
							bmdtList.push((piece.bmpd as BitmapData).clone());
						}
					}
				}
				//
			}
			//
			return bmdtList;
		}
		
		
		/**
		 * 
		 * @return
		 */
		public function getBitmaps():Vector.<Bitmap>
		{
			var bmList:Vector.<Bitmap> = new Vector.<Bitmap>();
			if(_pieceInfos.length){
				//	
				for (var i:int = 0; i < _pieceInfos.length; i ++) {
					if (_pieceInfos[i]) {
						var piece:Piece = _pieceInfos[i] as Piece
						if (piece.bmpd) {
							var bitmap:Bitmap = new Bitmap(piece.bmpd);
							bmList.push(bitmap);
						}
					}
				}
				//
			}
			//
			return bmList;
		}
		
		
		public function dispose():void
		{
			_pieceInfos = [];
		}
		
		//------------------------------- 
		
		public function set minimumArea(value:Number):void 
		{
			_minimumArea = value;
		}
		
		
		//------------------------------- 
		
		/**
		 * Chuyển ảnh thành dạng có thể phân tích.
		 * @param	source
		 * @return
		 */
		protected function convertToDiffImage(source:BitmapData):BitmapData
		{
			var tempSource:BitmapData = source.clone();
			var r:BitmapData = new BitmapData(tempSource.width,tempSource.height,true, 0xFFFFFFFF);
			var r2:BitmapData = new BitmapData(tempSource.width,tempSource.height,true, 0xFFFFFFFF);
			var rect:Rectangle = new Rectangle(0,0,tempSource.width,tempSource.height);
			
			//	Chuyen ve den trang cho de nhan dang
			var rc:Number = 1/3;
			var gc:Number = 1/3;
			var bc:Number = 1/3;
			var cmf:ColorMatrixFilter = new ColorMatrixFilter([rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, 0, 0, 0, 1, 0]);			
			tempSource.applyFilter( tempSource, new Rectangle( 0,0,tempSource.width,tempSource.height ), new Point(0,0), cmf );
			//	
			var pt:Point = new Point(0,0);
			var mtx:Matrix = new Matrix();
				mtx.translate(2,0);
			r.draw(tempSource, mtx, new ColorTransform(), BlendMode.DIFFERENCE);
				mtx.translate(-2,2);
			r2.draw(tempSource, mtx, new ColorTransform(), BlendMode.DIFFERENCE);
			r.copyPixels(r, new Rectangle(2, 0, 2, tempSource.height), pt);			
			r2.copyPixels(r2, new Rectangle(0,2,tempSource.width,2), pt);
			r.draw(r2, new Matrix(), new ColorTransform(), BlendMode.ADD);
			//
			var filter:ConvolutionFilter = new ConvolutionFilter(3,3,
																	[0.1,0.1,0.1,
																	0.1,0.1,0.1,
																	0.1, 0.1, 0.1]);
			//
			r.applyFilter(r,rect,pt,filter);
			r.threshold(r, rect, pt, "<", 0xff111111, 0xff000000);
			r.threshold(r, rect, pt, "!=", 0xff000000, 0xffffffff);
			//
			return r;
		}
			
		/*final protected function isContainedIn(a:Rectangle, b:Rectangle):Boolean
		{
			return a.x >= b.x && a.y >= b.y && a.x + a.width <= b.x + b.width && a.y + a.height <= b.y + b.height;
		}*/
		
	}
	
}