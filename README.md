# Book Content Compressor
An API written in ActionScript 3 - Adobe AIR, used to compress book page content by removing whitespace. And optimize book page area by rearranging the position of letters and pictures on the book page so that the page size. books are the smallest. The goal is to save texture when using on mobile.

![screenshot](http://i.imgur.com/zR1lXkL.png)


Setup
------------
- Pls, Using FlashDevelop to develop. If not, install FD at:: http://www.flashdevelop.org/downloads/releases/FlashDevelop-5.2.0.exe
- Ctr + Enter or F5 to compile.

The Main Class
------------

|Class|Description|
|---|---|
|PageConvertor| Used with GhostScript Tool. Use convert pdf file then compress|
|TexturePageGenerator| Using for book content compression. Use PNG files|
|TexturePageReader| Used to read compressed files and display book pages |

Note: Classes are architected for easy inheritance and plugin implementation

Quick Start
-----------

Compress book pages from pdf files
```shell
	var pageFormat:IPageFormat = new StarlingEditorFormat();
	var targetFile:File = File.applicationDirectory.resolvePath("input.pdf");			
	var convertor:PageConvertor = new PageConvertor(this);
	// Neu khong dang ky pageFormat thi chi convert thong thuong. Khong sinh ra texture page.
	//convertor.registerPageFormat(pageFormat);
	// Cho phep sinh ra page image ben canh pdf.
	convertor.allowConvertPageImages = true;
	convertor.completed.addOnce(function():void { 
						trace("All page is converted !");
					});
	convertor.eachCompleted.add(function(currentPage:int):void {
						trace("Success converting : " + currentPage);
					})

	//convertor.broswerPDF(2,6,7,8,9); // Compress pages: 2,6,7,8,9
	//convertor.broswerPDF(2, 6, [7, 9], 21, 23); // Compress pages: 2, 6,  7,8,9  , 21 và 23
	convertor.broswerPDF(1);  // Only compress page 1
```

Compress a book-page PNG file to texture put in a compressed file.
```shell
	var pageFormat:IPageFormat = new StarlingEditorFormat();
	var generator:TexturePageGenerator = new TexturePageGenerator(this);
	generator.registerPageFormat(pageFormat);
	  /*
	// Execute the Dispatching when each page is completed. Dispatching before saving as file.
	generator.pagingCompleted.addOnce(...)
	  // The analysis page, which returns the % of objects analyzed out of the total number of objects.
	generator.pagingProgress.addOnce(...)
	  // Checking % number of bytes which is loaded from sample page
	generator.loading.addOnce(...)
	  */
	  // Dispatch when saving the file is done. This is the final stage of the process.
	  generator.saveCompleted.addOnce(function():void { trace("save thanh cong !!!") } );

	  //generator.loadAndBuild("image.png");
	  generator.loadAndBuild("PAGE3.png");
```

Read and reconstruct a compressed file.
```shell
	var pageFormat:IPageFormat = new StarlingEditorFormat();
        var reader:TexturePageReader = new TexturePageReader();
            reader.registerPageFormat(pageFormat);
            reader.completed.addOnce(onParsingCompletedHandler);
            reader.load("image.zip");
     
        function onParsingCompletedHandler():void {
            starling.stage.addChild(reader.getStarlingPage());
        }
```


Algorithms and AS3 libraries used
------------
- Simple object detector (Identify objects in an image on a white background)
- Object Fragment / Defragment (Optimize the number of objects after identification. Make sure the texture area is the smallest)
- Rectangle Packer (Performance upgrade from an opensource class. Used to arrange objects to take up the least amount of texture space)
- FZIP 
- SIGNAL 
- Starling 
- Promise (AS3 version)
- Ghost Script (Converter Tool)
 
Issues that need upgrading
------------
- Optimize the removal of whitespace in case there is a border on the whole page
- Use Worker to optimize compress time.
- Switch to the server side.
- Replace Simple Object Detection with Cascade Object Detection (Viola-Jones Algorithm) or just use Tensorflow Object Detection.



@Author: Hallopatidu@gmail.com
