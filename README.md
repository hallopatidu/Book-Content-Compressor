# Book-Content-Compressor
Một ActionScript 3 API được sử dụng để nén nội dung trang sách bằng cách bỏ khoảng trắng và tối ưu diện tích trang sách. 

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
- 
