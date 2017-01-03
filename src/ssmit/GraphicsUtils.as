package ssmit
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;

	public class GraphicsUtils
	{
		public static function getBitmapCRC(bitmapData: flash.display.BitmapData): uint
		{
			var w: uint = Math.min(bitmapData.width, 1000);
			var h: uint = Math.min(bitmapData.height, 1000);
			return CRC.getCRC(
				bitmapData.getPixels(
					new Rectangle(0, 0, w, h)
				)
			);
		}

		public static function getCRC(displayObject: flash.display.DisplayObject): uint
		{
			var r: Rectangle = displayObject.getRect(displayObject);
			var w: uint = Math.ceil(r.width);
			var h: uint = Math.ceil(r.height);
			var bitmapData: BitmapData = new BitmapData(w, h, true, 0);
			var matrix: Matrix = new Matrix();
			matrix.translate(-r.left, -r.top);
			bitmapData.draw(displayObject, matrix);
			var crc: uint = getBitmapCRC(bitmapData);

			bitmapData.dispose();
			return crc;
		}
	}

}
