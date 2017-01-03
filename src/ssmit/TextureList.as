/**
 * @author Shane Smit <Shane@DigitalLoom.org>
 */
package ssmit
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import starling.display.Image;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	// The list of textures created from a ConvertedMovieClip
	internal final class TextureList
	{
		internal static const PADDING		: int	= 1;	// Add padding pixels to avoid bleeding in mipmaps.
		
		private var _bitmapInfoList			: Vector.<BitmapInfo>;
		
		// Creates a TextureList.
		public function TextureList()
		{
			_bitmapInfoList = new <BitmapInfo>[];
		}
		
		// Disposes all the textures in the list.
		internal function dispose() : void
		{
			for each( var info:BitmapInfo in _bitmapInfoList )
				info.dispose();
			_bitmapInfoList = null;
		}
		
		// Gets (or creates) a BitmapInfo structure from a Flash DisplayObject.
		internal function getBitmapInfoFromDisplayObject( displayObject:DisplayObject ) : BitmapInfo
		{
			// Capture the shape into a BitmapData.
			var shapeRect:Rectangle = displayObject.getRect( displayObject.parent );
			var matrix:Matrix = new Matrix();
			matrix.translate( displayObject.x -shapeRect.left + PADDING, displayObject.y -shapeRect.top + PADDING );

			matrix.a = displayObject.transform.matrix.a;
			matrix.b = displayObject.transform.matrix.b;
			matrix.c = displayObject.transform.matrix.c;
			matrix.d = displayObject.transform.matrix.d;

			var bitmapData:BitmapData = new BitmapData( Math.ceil(displayObject.width) + (PADDING*2), Math.ceil(displayObject.height) + (PADDING*2), true, 0x00000000 );	// Assume transparency on everything.

			bitmapData.draw( displayObject, matrix );
			
			// Generate a CRC for the bitmap. (Could use MD5 here, but it's super slow... and the chances of a collision are pretty low.)
			var crc:uint = GraphicsUtils.getBitmapCRC(bitmapData);
			
			// Check if this bitmap has already been added..
			var info:BitmapInfo = findBitmapInfo( bitmapData.width, bitmapData.height, crc );
			if( info != null )
			{
				bitmapData.dispose();
				bitmapData = info._bitmapData;
			}
			else
			{
				// Create a new bitmap info and add it to the list.
				info = new BitmapInfo();
				info._bitmapData = bitmapData;
				info._crc = crc;
			        info._name = createBitmapInfoName(displayObject.name);

				_bitmapInfoList.push( info );
			}
			
			return info;
		}
		
		private function createBitmapInfoName(displayObjectName: String): String
		{
			var infoName: String = displayObjectName.slice();
			var index: uint = 0;

			while (hasBitmapInfoNamed(infoName)) {
				index += 1;
				infoName = displayObjectName + "$" + index;
			}
			return infoName;
		}

		private function hasBitmapInfoNamed(name: String): Boolean
		{
			for each (var bitmapInfo: BitmapInfo in _bitmapInfoList)
				if (bitmapInfo._name == name)
					return true;
			return false;
		}

		
		// Finds an existing bitmap given the width, height, and CRC.
		private function findBitmapInfo( width:int, height:int, crc:uint ) : BitmapInfo
		{
			for each( var info:BitmapInfo in _bitmapInfoList )
			{
				if( info._bitmapData.width == width && info._bitmapData.height == height && info._crc == crc )
					return info;
			}
			
			return null;
		}
		
		
		// Convert the list of bitmaps to Starling TextureAtlases.
		internal function createTextureAtlases( sortBitmaps:Boolean=true, generateMipMaps:Boolean=true ) : Vector.<TextureAtlas>
		{
			var bitmaps:Vector.<BitmapData> = TexturePacker.pack( _bitmapInfoList, sortBitmaps );
			
			// Create the Atlases from the packed bitmaps.
			var atlases:Vector.<TextureAtlas> = new Vector.<TextureAtlas>( bitmaps.length, true );
			for( var i:int=0; i<atlases.length; ++i )
			{
				var texture:Texture = Texture.fromBitmapData( bitmaps[ i ], generateMipMaps );
				atlases[ i ] = new TextureAtlas( texture );
			}
			
			// Add the texture regions to the atlases
			for each( info in _bitmapInfoList )
			{
				var atlas:TextureAtlas = atlases[ info._atlasIndex ];
				atlas.addRegion( info._name, new Rectangle( info._atlasX, info._atlasY, info._bitmapData.width, info._bitmapData.height ) );
			}
			
			// Assign the atlased textures to the images.
			for each( var info:BitmapInfo in _bitmapInfoList )
			{
				for each( var image:Image in info._imageList )
				{
					image.texture.dispose();	// Dispose the dummy texture.
					image.texture = atlases[ info._atlasIndex ].getTexture( info._name );
				}
			}
			
			return atlases;
		}
		
		
		internal function exportTextureAtlases( atlasesXML:XML, sortBitmaps:Boolean=true ) : Vector.<BitmapData>
		{
			var bitmaps:Vector.<BitmapData> = TexturePacker.pack( _bitmapInfoList, sortBitmaps );
			
			// Write region info:
			for( var i:int=0; i<bitmaps.length; ++i )
				atlasesXML.appendChild( <TextureAtlas /> );
			
			for each( var info:BitmapInfo in _bitmapInfoList )
			{
				var atlasXML:XML = atlasesXML.TextureAtlas[ info._atlasIndex ].appendChild( <SubTexture /> );
				var textureXML:XML = atlasXML.SubTexture[ atlasXML.SubTexture.length() - 1 ];
				textureXML.@name = info._name;
				textureXML.@x = info._atlasX;
				textureXML.@y = info._atlasY;
				textureXML.@width = info._bitmapData.width;
				textureXML.@height = info._bitmapData.height;
			}
			
			// Assign the atlased textures to the images.
			for each( info in _bitmapInfoList )
			{
				for each( var imageXML:XML in info._xmlList )
				{
					textureXML = <texture />;
					textureXML.@atlas = info._atlasIndex;
					textureXML.@region = info._name;
					imageXML.appendChild( textureXML );
				}
			}
			
			return bitmaps;
		}
	}
}
