package halloboard.api.page.interfaces
{
	
	/**
	 * ...
	 * @author Hallopatidu@gmail.com
	 */
	public interface IPageFormat 
	{
		function get name():String
		function get setting():Object
		function set setting(data:Object):void
		function record(fieldName:String, data:Object):void
		function exports():Object
		
		function parse(content:String):void
		function element(index:int, type:String):Object
		function get numElement():int
		function get content():String
	}
	
}