# Book Content Compressor
Thư viện AS3 được sử dụng để nén nội dung trang sách bằng cách bỏ khoảng trắng.Và tối ưu diện tích trang sách bằng cách sắp xếp lại vị trí các chữ và hình trên trang sách sao cho kích thước trang sách là nhỏ nhất.

![screenshot](http://imgur.com/a/uz1zT)

Cài đặt
------------
- Sử dụng FlashDevelop. Nêu chưa có, cài đặt FD tại: http://www.flashdevelop.org/downloads/releases/FlashDevelop-5.2.0.exe
- Ctr + Enter hoặc F5 để biên dịch.

Các class chính
------------

|Class|Description|
|---|---|
|PageConvertor| Sử dụng kèm với GhotScript Tool. Dùng convert file pdf sau đó nén|
|TexturePageGenerator| Sử dụng nén nội dung sách. Dùng file PNG|
|TexturePageReader| Sử dụng để đọc file đã nén nội dung và hiển thị trang sách |

Quick Start
-----------

Nén trang sách từ file pdf
```shell
	var targetFile:File = File.applicationDirectory.resolvePath("input.pdf");			
	var convertor:PageConvertor = new PageConvertor(this);
	// Neu khong dang ky pageFormat thi chi convert thong thuong. Khong sinh ra texture page.
	//convertor.registerPageFormat(pageFormat);
	// Cho phep sinh ra page image ben canh pdf.
	convertor.allowConvertPageImages = true;
	convertor.completed.addOnce(function():void { 
						trace("Convert thanh cong !");
					});
	convertor.eachCompleted.add(function(currentPage:int):void {
						trace("Convert xong page " + currentPage);
					})

	//convertor.broswerPDF(2,6,7,8,9); // Compress các trang 2,6,7,8,9
	//convertor.broswerPDF(2, 6, [7, 9], 21, 23); // Compress các trang 2, 6,  7,8,9  , 21 và 23
	convertor.broswerPDF(1);  // Chỉ compress trang 1
```


Nén một file PNG dạng trang sách ra texture trong một file nén.
```shell
	var generator:TexturePageGenerator = new TexturePageGenerator(this);
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

	  //generator.loadAndBuild("image.png");
	  generator.loadAndBuild("PAGE3.png");
```

Đọc và tái hiện lại một file đã nén.
```shell
        var reader:TexturePageReader = new TexturePageReader();
            reader.registerPageFormat(pageFormat);
            reader.completed.addOnce(onParsingCompletedHandler);
            reader.load("image.zip");
     
        function onParsingCompletedHandler():void {
            starling.stage.addChild(reader.getStarlingPage());
        }
```


Một số thư viện sử dụng
------------
- Simple object detector (Nhận dạng các object có trong một bức ảnh trên nền trắng)
- Object Fragment / Defragment (Tối ưu số lượng các object sau khi nhận dạng)
- Rectangle Packer (Đã được nâng cấp từ thư viện opensource. Sử dụng để sắp xếp các object sao cho tốn ít diện tích nhất của texture)
- FZIP 
- SIGNAL 
- Starling 
- Promise (Phiên bản AS3)
- Ghost Script (Tool convert)
 


@Author: Hallopatidu@gmail.com
