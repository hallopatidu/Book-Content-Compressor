package halloboard.api.math 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	import halloboard.api.controls.GenericFlow;
	
	/**
	 * Defragment
	 * 1. Track objects inside others.
	 * 2. Remove them.
	 * 
	 * Fragment
	 * 1. Determine which points where the corners of the generated rectangles could be.
	 * 2. Remove all duplicates from this list of points.
	 * 3. Check all rectangles that could theoretically be drawn where the rect would have all 4 corners in the list of point.
	 * 4. Filter out all invalid rectangles (it intersects with one of our original rectangles etc.)
	 * 5. Reduce all valid rectangles to the minimum amount needed (if a valid rectangle contains another valid rectangle the "child" is removed.
	 * 
	 */
	public class OptimizePieces 
	{
		private static const MAX_COUNT:int = 500;
		private static var instance:OptimizePieces;
		
		public function OptimizePieces() 
		{
			//throw new Error("Do not create instance !")
		}
		
		 /**
		  * Phân mảnh
		  * Chia các piece lớn hơn thành các piece nhỏ hơn nếu chứa piece khác nằm trong nó.
		  * Bước 1: Phân nhóm các rect con nằm trong các rect lớn.
		  * Bước 2: Phân mảnh từng rect lớn dựa vào các rect con nằm trong các nhóm được phân loại bên trên.
		  * Bước 3: Tổng hợp các rects đã được phân mảnh và bỏ những rect lớn đã bị phân mảnh.
		  * 
		  * @param	originRects		Các
		  * @param	callBack
		  * @return
		  */
		public static function fragment (originRects:Array, callBack:Function = null):Array
		{
			if (!instance) {
				instance = new OptimizePieces();
			}
			//	
			var outputRects:Array = [];
			var delayTime:int = (callBack != null) ? 10 : 0;
			GenericFlow.progress(function(next:Function):void { 
									// Phân nhóm các rect chứa các rect khác.
									outputRects = instance.classificationRectBlocks.apply(instance, originRects);
									next(outputRects);
								},
								function(outputRects:Array, next:Function):void {
									// Phân mảnh các nhóm trên.
									instance.excecuteFragment(outputRects, originRects, next);
								},
								function(outputRects:Array):void {
									// Tổng hợp các rects được phân mảnh và rects ban đầu.
									outputRects = instance.aggregateRects(outputRects, originRects);
									// Gọi callBack khi hoàn thành.
									if (callBack != null) {
										callBack(outputRects);
									}
									//	
								}, delayTime);
			//			
			return outputRects;
		}
		
		
		/**
		 * Chống phân mảnh
		 * Gỡ bỏ các Piece nằm trong các piece to hơn.
		 * 
		 * @param	originPieceInfos
		 * @return	Array of Piece.
		 */
		public static function defragment(...originRects):Array
		{
			if (!instance) {
				instance = new OptimizePieces();
			}
			//
			var outputRects:Array = [];
			//	Loai bỏ các rect nằm trong rect. Mục tiêu là optimize số lượng texture.
			var trackBlocks:Array = instance.trackRectInsideRect.apply(instance, originRects);
			//	Update vào pieceInfos.
			for (var i:int = 0; i < trackBlocks.length; i ++) {
				if (trackBlocks[i] == true) {
					if(originRects[i]){
						outputRects.push(originRects[i]);
					}
				}
			}
			//	
			return outputRects;
		}
		
		//------------------- DEFRAGMENT --------------------
		
		/**
		 * Đánh dấu cac object có rect không nằm trong rect khác.
		 * Sư dụng trong defragment.
		 * @param	...rects
		 * @return	Array of Rectangles
		 */
		private function trackRectInsideRect(...originRects):Array
		{
			var trackBlocks:Array = [];
			//	
			for (var i:int = 0 ; i < originRects.length; i++) {
				var selectedRect1:Rectangle = originRects[i] as Rectangle;				
				if (selectedRect1) {
					//	
					if (trackBlocks[i] != false) {
						trackBlocks[i] = true;
					}
					//					
					for (var j:int = i + 1 ; j < originRects.length; j++) {
						var selectedRect2:Rectangle = originRects[j] as Rectangle;
						if (selectedRect2) {						
							//if (isContainedIn(selectedRect1, selectedRect2)) {
							if (selectedRect1.containsRect(selectedRect2)) {
								// selectedRect1 contains selectedRect2
								trackBlocks[j] = false;
							//}else if (isContainedIn(selectedRect2, selectedRect1)) {
							}else if (selectedRect2.containsRect(selectedRect1)) {
								// selectedRect2 contains selectedRect1
								trackBlocks[i] = false;
							}
							
						}else {
							trackBlocks[j] = false;
						}
						
					}
					//	
				}
				//	
			}
			//	
			return trackBlocks;
		}
		
		//---------------------- FRAGMENT -----------------
		
		/**
		 * Phân nhóm các rect chứa các rect khác. 
		 * Nếu rect A có id trong originRects là i thì các rect con nằm trong A sẽ là mảng thuộc
		 * phần tử thứ y trong giá trị trả về
		 * @param	...originRects			// Array of Rectangle.
		 * @return	Array of Array
		 */
		private function classificationRectBlocks(...originRects:Array):Array
		{
			//
			var outputRects:Array = [];
			//
			for (var i:int = 0 ; i < originRects.length; i++) {
				var selectedRect1:Rectangle = originRects[i] as Rectangle;				
				if (selectedRect1) {
					//					
					for (var j:int = i + 1 ; j < originRects.length; j++) {
						var selectedRect2:Rectangle = originRects[j] as Rectangle;
						if(selectedRect2){
							//
							if (selectedRect1.containsRect(selectedRect2)) {
								// selectedRect1 contains selectedRect2
								if (!outputRects[i]) {
									outputRects[i] = [];
								}
								(outputRects[i] as Array).push(j);
								//	
							}else if (selectedRect2.containsRect(selectedRect1)) {
								// selectedRect2 contains selectedRect1
								if (!outputRects[j]) {
									outputRects[j] = [];
								}
								(outputRects[j] as Array).push(i);
								//	
							}
							
						}else {
							//
						}
						//
					}
					//	
				}
				//	
			}
			//
			return outputRects;
		}
		
		
		/**
		 * Thực hiện phân mảnh thành các rects.
		 * Hàm thiết kế dưới dạng continuos
		 * @param	blocks
		 * @param	originRects
		 * @param	callBack		Nếu có hàm call back thì giá trị trả về sẽ gửi qua callBack(returnArray)
		 * @return
		 */
		private function excecuteFragment(blocks:Array, originRects:Array, callBack:Function = null):Array
		{			
			//
			trace("\n excecuteFragment(...) " + i);
			var i:int = 0;
			var timeLoop:int = 10;
			fragmentLoop();
			//
			function fragmentLoop():void{
				if (i < blocks.length) {
					if (blocks[i]) 
					{						
						//	Tạo tham số cho hàm calculate.
						var blockRects:Array = blocks[i];
						var parentRect:Rectangle = originRects[i] as Rectangle;
						var childRects:Vector.<Rectangle> = new Vector.<Rectangle>();
						//	
						for (var j:int = 0 ; j < blockRects.length; j++) {
							var itemRect:Rectangle = originRects[int(blockRects[j])] as Rectangle;
							childRects.push(itemRect);
						}
						//	
						instance.calculate(parentRect, childRects, function(childBlockList:Vector.<Rectangle>):void {
																		blocks[i] = childBlockList;
																		i++;
																		setTimeout(fragmentLoop, timeLoop);
																	});
					}else{
						//	
						i++;
						setTimeout(fragmentLoop, timeLoop);
					}
					//	
				}else {
					trace("excecuteFragment::loop:done \n");
					if (callBack != null) {
						callBack(blocks);
					}
				}
				//	
			}
			//
			return blocks;
		}
		
		
		/**
		 * Tổng hợp các rects.
		 * @param	originPieceInfos
		 * @param	blocks
		 * @return
		 */
		private function aggregateRects(blocks:Array, originRects:Array):Array
		{
			var outputRects:Array = [];			
			for (var i:int = 0 ; i < originRects.length; i++) {
				if (originRects[i]) {
					if (blocks[i]) {
						var blockRectList:Vector.<Rectangle> = blocks[i] as Vector.<Rectangle>;
						for (var j:int = 0 ; j < blockRectList.length; j++) {
							if(blockRectList[j]){
								var rect:Rectangle = blockRectList[j] as Rectangle;
								outputRects.push(rect);
							}
							//
						}
						//	
					}else {
						//	
						outputRects.push(originRects[i] as Rectangle);
					}
					//
				}
				//	
			}
			//	
			return outputRects;
			//	
		}
		
		
		/**
		 * Đếm từng object. 
		 * Nếu số lượng object nhiều hơn MAX_COUNT thì parentRect sẽ bị cắt thành nhiều đoạn dưới 500 object.
		 * @param	parentRect
		 * @param	childRects
		 * @param	callBack
		 * @return
		 */
		private function calculate(parentRect:Rectangle, childRects:Vector.<Rectangle>, callBack:Function = null ):Vector.<Rectangle>
		{
			//
			var outputRects:Vector.<Rectangle> = partialCalculate(parentRect, childRects);			
			//	Nối childRects vào mảng kết quả.
			outputRects = outputRects.concat(childRects);
			//	
			if (callBack != null) {
				callBack(outputRects);
			}
			//	
            return outputRects;	
		}
		
		
		
		
		/**
		 * 
		 * @param	parentRect
		 * @param	childRects
		 * @return
		 */
		private function partialCalculate(parentRect:Rectangle, childRects:Vector.<Rectangle>):Vector.<Rectangle>
		{
			var outputRects:Vector.<Rectangle>;// = new Vector.<Rectangle>();
			var axis:Object = parseToAxis(parentRect, childRects);			
			//
			removeDuplicateAndSortElement(axis["X"]);
			removeDuplicateAndSortElement(axis["Y"]);
			//			
			outputRects = calculateRects(parentRect, childRects, axis);
			if (outputRects.length > MAX_COUNT) {
				trace("Nhom cac rect !");
				outputRects = calculateRects(parentRect, childRects, axis, false);		
				outputRects = partialCalculate(parentRect, outputRects);
			}
			//	
            return outputRects;	
		}
		
				
				/**
				 * 
				 * @param	parentRect
				 * @param	childRects
				 * @return
				 */
				private function parseToAxis(parentRect:Rectangle, childRects:Vector.<Rectangle>):Object
				{
					var xAxis:Vector.<Number> = new Vector.<Number>();
						xAxis.push(parentRect.right);
					var yAxis:Vector.<Number> = new Vector.<Number>();
						yAxis.push(parentRect.bottom);
					//	
					for (var i:int = 0; i < childRects.length; i++) 
					{
						var sourceRect:Rectangle = childRects[i] as Rectangle;
						//	source rect is completely outside of the room, we shoud ignore it
						if (!parentRect.containsRect(sourceRect) && !parentRect.intersects(sourceRect)) {
							continue;
						}
						//	
						if(sourceRect.x > parentRect.x){
							xAxis.push(sourceRect.x);
						}
						if(sourceRect.right < parentRect.right){
							xAxis.push(sourceRect.right);
						}
						//	
						if(sourceRect.y > parentRect.y){
							yAxis.push(sourceRect.y);
						}
						if(sourceRect.bottom < parentRect.bottom){
							yAxis.push(sourceRect.bottom);
						}
						//	
					}
					
					return { X:xAxis, Y:yAxis };
				}
				
				
				/**
				 * Hàm sử dụng trong calculate.
				 * Tạo danh sách các
				 */
				private function calculateRects(parentRect:Rectangle, childRects:Vector.<Rectangle>, axis:Object, useOutsideRects:Boolean = true):Vector.<Rectangle>
				{					
					var outputRects:Vector.<Rectangle> = new Vector.<Rectangle>();
					var xAxis:Vector.<Number> = axis["X"] as Vector.<Number>;
					var yAxis:Vector.<Number> = axis["Y"] as Vector.<Number>;
					var nextY:Number = parentRect.y;
					//
					for (var i:int = 0; i < yAxis.length; i++) 
					{
						var nextX:Number = parentRect.x;
						var hRect:Number = yAxis[i] - nextY;
						//	
						for (var j:int = 0; j < xAxis.length; j++)
						{
							var wRect:Number = xAxis[j] - nextX;
							var genRect:Rectangle = new Rectangle(nextX, nextY, wRect, hRect);
							nextX = xAxis[j];
							// Bỏ qua những rect nằm trong hoặc va chạm vào một trong các rect trong childRects.
							if(childRects.some(function(rect:Rectangle, currentIndex:int, theEntireArray:Vector.<Rectangle>):Boolean
												{
													if (genRect.containsRect(rect) || genRect.intersects(rect)) {												
														return true;
													}
													return false;
												}, this) )
							{
								//	Cho vao nhom
								if (!useOutsideRects) {
									// Nếu useOutsideRects == false thì gộp tất cả các rect va chạm hoặc chứa genRect 
									// thành một rect lớn nếu các rect đó cách nhau một khoảng minMargin.
									var minMargin:Number = 12;
									var isUpdated:Boolean = false;
									// 
									mix: for (var k:int = 0 ; k < outputRects.length; k++) {
										if (outputRects[k]) {
											var originRect:Rectangle = outputRects[k] as Rectangle;
											// Vẽ một bound rect lớn hơn originRect một khoảng minMargin để kiểm tra 
											// va chạm với genRect.
											var boundRect:Rectangle = originRect.clone();
											boundRect.x -= minMargin;
											boundRect.y -= minMargin;
											boundRect.width = boundRect.width + 2*minMargin;
											boundRect.height = boundRect.height + 2 * minMargin;
											//
											if (boundRect.containsRect(genRect) || boundRect.intersects(genRect)) {												
												originRect.left = Math.min(originRect.left, genRect.left);
												originRect.right = Math.max(originRect.right, genRect.right);
												originRect.top = Math.min(originRect.top, genRect.top);
												originRect.bottom = Math.max(originRect.bottom, genRect.bottom);
												outputRects[k] = originRect;
												isUpdated = true;
												break mix;
											}
											//
										}
									}
									//
									if (!isUpdated) {
										outputRects.push(genRect);
									}
								}
								continue;
							}else {
								if(useOutsideRects){
									outputRects.push(genRect);
								}
							}
							//	
						}
						//
						nextY = yAxis[i];
						//
					}				
					//
					return outputRects//.concat(childRects);
				}
		
		
		/**
		 * Gỡ các point trùng nhau và sắp xếp theo tọa độ tăng dần.
		 * @param	axis
		 */
		private function removeDuplicateAndSortElement(axis:Vector.<Number>):void
		{
			var usedElements:Object = [];
			for (var i : int = 0; i < axis.length; i++) {
                if (usedElements[axis[i]]) {
                    axis.splice(i, 1);
                    i--;
                } else {
                    usedElements[axis[i]] = true;
                }
            }
			//
			axis.sort(function (a:Number, b:Number):int 
						{
							return (a < b) ? -1 : 1;
						});
			//
		}
		
		
		//---------------------
		
		/**
		 * 
		 */
		private function calculate2(parentRect:Rectangle, childRects:Vector.<Rectangle>, callBack:Function = null ):Vector.<Rectangle>
		{
            // list of y coords for horisontal lines,
            // which are interesting when determining which rectangles to generate
            var lines : Vector.<int> = new Vector.<int>();
			var linesX : Vector.<int> = new Vector.<int>();
			
            // list of all points which are interesting
            // when determining where the corners of the generated rect could be
            var points : Vector.<Point> = new Vector.<Point>();
				// add the 4 corners of the room to interesting points
				points.push(new Point(parentRect.left, parentRect.top));
				points.push(new Point(parentRect.right, parentRect.top));
				points.push(new Point(parentRect.left, parentRect.bottom));
				points.push(new Point(parentRect.right, parentRect.bottom));
			//
			var outputRects : Vector.<Rectangle> = new Vector.<Rectangle>();
			var pointsHash : Object = { };
			var i:int = 0;
			var a:int = 0;
			var intersect:Rectangle;
			//
			GenericFlow.progress(
				recordLinesAndFirstCornerPoints,
				addMoreChildPoints,
				recordPointHash,
				generateOutputRects,
				clearnupRects, 100
			)
			
			//
			function recordLinesAndFirstCornerPoints(next:Function):void
			{
				trace("calculate::recordLinesAndFirstCornerPoints");
				for (i = 0; i < childRects.length; i++) {
					var sourceRect : Rectangle = childRects[i];

					// source rect is completely outside of the room, we shoud ignore it
					if (!parentRect.containsRect(sourceRect) && !parentRect.intersects(sourceRect)) {
						continue;
					}

					// push the y coord of the rect's top edge to the list of lines if it's not already been added
					if (linesX.indexOf(sourceRect.x) == -1) {
						linesX.push(sourceRect.x);
						if (lines.indexOf(sourceRect.y) == -1) {
							lines.push(sourceRect.y);
							
						}
						
					}
					
					// push the y coord of the rect's bottom edge to the list of lines if it's not already been added
					if (linesX.indexOf(sourceRect.right) == -1) {
						linesX.push(sourceRect.right);
						if (lines.indexOf(sourceRect.bottom) == -1) {
							lines.push(sourceRect.bottom);						
						}
					}

					// add the 4 corners of the source rect to the list of interesting points
					addCornerPoints(points, sourceRect);

					// find the intersections between source rectangles and add those points
					for (var j:int = 0; j < childRects.length; j++) {
						if (j != i) {
							intersect = childRects[i].intersection(childRects[j]);
							if (intersect.width != 0 && intersect.height != 0) {
								addCornerPoints(points, intersect);
							}
						}
					}
				}
				//
				next();
			}
			
			//
			
			/**
			 * 
			 * @param	next
			 */
			function addMoreChildPoints(next:Function):void
			{
				trace("calculate::addMoreChildPoints");
				for (i = 0; i < lines.length; i++) {
					 // add the points where the horisontal lines intersect with the room's left and right edges
					points.push(new Point(parentRect.x, lines[i]));				// left                
					points.push(new Point(parentRect.right, lines[i]));			// right
					//
					var lineRect:Rectangle = new Rectangle(parentRect.x, parentRect.y, parentRect.width, lines[i] - parentRect.y);
					
					// add all points where the horisontal lines intersect with the source rectangles
					for (a = 0; a < childRects.length;a++) {
						intersect = childRects[a].intersection(lineRect);
						if (intersect.width != 0 && intersect.height != 0) {
							addCornerPoints(points, intersect);
						}
					}
					//----
					points.push(new Point(linesX[i], parentRect.y));				// top                
					points.push(new Point(linesX[i], parentRect.bottom));			// bottom
					var lineRectX:Rectangle = new Rectangle(parentRect.x, parentRect.y, linesX[i] - parentRect.x, parentRect.height );

					// add all points where the horisontal lines intersect with the source rectangles
					for (a = 0; a < childRects.length;a++) {
						intersect = childRects[a].intersection(lineRectX);
						if (intersect.width != 0 && intersect.height != 0) {
							addCornerPoints(points, intersect);
						}
					}
				}
				//
				next();
			}
			
			//
			function recordPointHash(next:Function):void
			{
				trace("calculate::recordPointHash");
				// clamp all points that are outside of the room to the room edges
				for (i = 0; i < points.length; i++) {
					points[i].x = Math.min(Math.max(parentRect.left, points[i].x), parentRect.right);
					points[i].y = Math.min(Math.max(parentRect.top, points[i].y), parentRect.bottom);
				}
				//
				trace("points before:: " + points.length);
				removeDuplicatePoints(points);
				trace("points after:: " + points.length);
				//
				for (a = 0; a < points.length; a++) {
					pointsHash[points[a].x + "_" + points[a].y] = true;
				}
				//
				next();
			}
			//
			
			function generateOutputRects(next:Function):void
			{
				trace("calculate::generateOutputRects:point_length " + points.length);
				for (var a:int = 0; a < points.length; a++) 
				{
					for (var b:int = 0; b < points.length; b++) 
					{					
						if (b != a && points[b].x > points[a].x && points[b].y == points[a].y) 
						{
							//
							for (var c:int = 0; c < points.length; c++) 
							{							
								// generate a rectangle that has its four corners in our points of interest
								if (c != b && c != a && points[c].y > points[b].y && points[c].x == points[b].x) {
									var r : Rectangle = new Rectangle(points[a].x, points[a].y, points[b].x - points[a].x, points[c].y - points[b].y);
									// make sure the rect has the bottom left corner in one of our points
									if (pointsHash[r.left + "_" + r.bottom]) 
									{
										var containsOrIntersectsWithSource : Boolean = false;
										for (i = 0; i < childRects.length; i++) 
										{
											if (r.containsRect(childRects[i]) || r.intersects(childRects[i])) {
												containsOrIntersectsWithSource = true;
												break;
											}
										}

										// we don't add any rectangles that either intersects with a source rect
										// or completely contains a source rect
										if (!containsOrIntersectsWithSource) {
											outputRects.push(r);
										}
										//
									}
									//
								}
								//
							}
							//
						}
						//
					}
					//
				}
				//
				next();
			}
			
			//
			function clearnupRects():void
			{
				trace("calculate::clearnupRects");
				//trace("outputRects before cleanup:", outputRects.length);
				combineOutputRects(outputRects);
				//trace("outputRects after cleanup", outputRects.length);
				if (callBack != null) {
					callBack(outputRects);
				}
			}
			//
            return outputRects;
        }
		
		
		/**
		 * 
		 * @param	points
		 * @param	rect
		 */
		private function addCornerPoints(points:Vector.<Point>, rect : Rectangle):void
		{
            points.push(new Point(rect.left, rect.top));
            points.push(new Point(rect.right, rect.top));
            points.push(new Point(rect.left, rect.bottom));
            points.push(new Point(rect.right, rect.bottom));
        }
		
		
		/**
		 * removes all rectangle that are already contained in another rectangle
		 * @param	outputRects
		 * @return
		 */
        private function combineOutputRects(outputRects : Vector.<Rectangle>):Boolean 
		{
            for (var a : int = 0; a < outputRects.length; a++) {
                for (var b : int = 0; b < outputRects.length; b++) {
                    if (b != a) {
                        if (outputRects[a].containsRect(outputRects[b])) {
                            //trace("\tremoved rect " + outputRects[b] + ", it was contained in " + outputRects[a]);
                            outputRects.splice(b, 1);
                            b--;
                            a = 0;
                        }
                    }
                }
            }
            return false;
        }
		
		/**
		 * 
		 * @param	points
		 */
        private function removeDuplicatePoints(points : Vector.<Point>):void
		{
            var usedPoints : Object = {};
            for (var i : int = 0; i < points.length; i++) {
                if (usedPoints[points[i].toString()]) {
                    points.splice(i, 1);
                    i--;
                } else {
                    usedPoints[points[i].toString()] = true;
                }
            }
        }
		
		
		/**
		 *  This is really simple since our rectangles are described
		 * 	by a point (A) and positive width and height.
		 * 	we only need to determine if points A’ and D’ are inside ABCD
		 * 	but we don’t even have to do full point inside rect checks
		 * 	just ensure that A <= A’  and D’ <= D 
		 * 	NOTE: contains does not check for the rectangle being empty
		 * 	however, if the rectangle has no width or height, it equates to the point in rectangle test
		 *  A _________B
         *   |A’____B’ |
         *   | |    |  |
         *   | |____|  |
         *   |C’    D’ |            
         *   |_________|
         *  C          D
		 * @param	rect
		 * @return
		 */
		/*private function isContainedIn(parentRect1:Rectangle, childRect2:Rectangle):Boolean
		{            
            if(   (parentRect1.x <= childRect2.x && parentRect1.y <= childRect2.y) //A <= A’
                &&((childRect2.x + childRect2.width) <= (parentRect1.x + parentRect1.width)) //D’.x <= D.x 
                &&((childRect2.y + childRect2.height) <= (parentRect1.y + parentRect1.height))){//D’.y <= D.y
                return true;
            }
            
            return false;
        }*/
		
	}

}