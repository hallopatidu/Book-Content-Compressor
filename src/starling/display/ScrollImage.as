package starling.display {
    import flash.geom.Rectangle;
    import starling.textures.Texture;
     
    /**
     * An Image class that supports Scrolling and Clipping effortlessly (Finally!)
     * @author Pierre Chamberlain
     */
    public class ScrollImage extends Image {
         
        private var _scrollX:Number = 0;
        private var _scrollY:Number = 0;
         
        private var _clipMask:Rectangle;
         
        public function ScrollImage(texture:Texture) {
            //texture.repeat =    true;
            super(texture);
             
            _clipMask =     new Rectangle(0, 0, width, height);
        }
         
        public override function dispose():void {
            super.dispose();
             
            if (_clipMask) {
                _clipMask =     null;
            }
        }
         
        private function updateUVs():void {
            var ratioX:Number = 1 / texture.width;
            var ratioY:Number = 1 / texture.height;
             
            mVertexData.setPosition(0, _clipMask.left, _clipMask.top);
            mVertexData.setPosition(1, _clipMask.right, _clipMask.top);
            mVertexData.setPosition(2, _clipMask.left, _clipMask.bottom);
            mVertexData.setPosition(3, _clipMask.right, _clipMask.bottom);
             
            var scrollLeft:Number =     (_scrollX + _clipMask.left) * ratioX;
            var scrollTop:Number =      (_scrollY + _clipMask.top) * ratioY;
            var scrollRight:Number =    (_scrollX + _clipMask.right) * ratioX;
            var scrollBottom:Number =   (_scrollY + _clipMask.bottom) * ratioY;
            
            mVertexData.setTexCoords(0, scrollLeft, scrollTop);
            mVertexData.setTexCoords(1, scrollRight, scrollTop);
            mVertexData.setTexCoords(2, scrollLeft, scrollBottom);
            mVertexData.setTexCoords(3, scrollRight, scrollBottom);
            
            onVertexDataChanged();
        }
         
        public function get scrollX():int { return _scrollX; }
        public function set scrollX(value:int):void {
            _scrollX = value % texture.width;
             
            updateUVs();
        }
         
        public function get scrollY():int { return _scrollY; }
        public function set scrollY(value:int):void {
            _scrollY = value % texture.height;
            
            updateUVs();
        }
         
        public function get clipMaskLeft():Number { return _clipMask.left; }
        public function set clipMaskLeft(n:Number):void {
            _clipMask.left = n;
             
            updateUVs();
        }
         
        public function get clipMaskTop():Number { return _clipMask.top; }
        public function set clipMaskTop(n:Number):void {
            _clipMask.top = n;
             
            updateUVs();
        }
         
        public function get clipMaskRight():Number { return _clipMask.right; }
        public function set clipMaskRight(n:Number):void {
            _clipMask.right = n;
             
            updateUVs();
        }
         
        public function get clipMaskBottom():Number { return _clipMask.bottom; }
        public function set clipMaskBottom(n:Number):void {
            _clipMask.bottom = n;
             
            updateUVs();
        }
    }
}