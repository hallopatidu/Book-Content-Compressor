package halloboard.api.controls 
{
	import flash.utils.setTimeout;
	/**
	 * ...
	 * @author Hallopatidu@gmail.com
	 */
	public class GenericFlow 
	{
		
		public function GenericFlow() 
		{
			
		}
		
		/**
		 * Goi function theo thứ tự lần lượt.
		 * GenericFlow.progress(function(next:Function):void {
		 * 							trace("first");
		 * 							next();
		 *						},
		 * 						function(next:Function):void { 
		 *							trace("second");
		 *							next();
		 *						},
		 *						function(next:Function):void { 
		 *							trace("third");
		 *							next();
		 *						},
		 *						function():void { 
		 *							trace("end");									
		 *						}, 1000);
		 * 
		 * Tham số next:Function luôn ở cuối trong mảng params.
		 * 
		 * @param	...callbacks	Tham số cuối cùng nếu là int thì là số time delay tính theo ms.
		 */
		public static function progress(...callbacks):void 
		{
			//clone the array
			var delayTime:int = 0;
			var lastparam:* = callbacks[callbacks.length - 1];
			if (lastparam is int) {
				delayTime = callbacks.pop();
			}
			//			
			var functions:Array = callbacks.slice();
			//
			processNext();			
			//
			function processNext(...params):void
			{			
				var func:Function = functions.shift();
				if(functions.length){
					params.push(processNext);
				}
				//
				if (delayTime) {
					params.unshift(delayTime);
					params.unshift(func);					
					setTimeout.apply(null, params);
				}else {					
					//
					func.apply(null, params);
				}
			}
			//
		}
		
		//----------------------------------
		
	}

}