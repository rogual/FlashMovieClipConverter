package ssmit
{
	import flash.utils.ByteArray;

	// Utility class to calculate a CRC.
	public class CRC
	{
		private static var _table	: Vector.<uint>;

		// Magic.
		private static function makeTable() : void
		{
			_table = new Vector.<uint>( 256, true );
			for( var i:int=0; i<256; ++i )
			{
				var c:uint = i;
				for( var j:int=8; j>=0; --j )
				{
					if( (c&1) != 0 )
						c = 0xedb88320 ^ (c >>> 1);
					else
						c >>>= 1;
				}
				_table[ i ] = c;
			}
		}

		// Calculates the CRC of a ByteArray.
		public static function getCRC( byteArray:ByteArray ) : uint
		{
			if( _table == null )
				makeTable();

			var crc:uint = 0;
			var index:uint = 0;
			var c:uint = ~crc;
			for( var i:int=byteArray.length; i>=0; --i )
			{
				c = _table[ (c ^ byteArray[index]) & 0xff ] ^ (c >>> 8);
				++index;
			}
			crc = ~c;

			return crc;
		}
	}
}
