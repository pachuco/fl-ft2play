import flash.utils.ByteArray;
import flash.utils.Endian;
import ft2play.Tools;

package ft2play.struct 
{

public class PatternHeaderTyp implements PACKED
{
    
    public var
        PatternHeaderSize:int,  //int32_t  
        Typ:uint,               //uint8_t  
        PattLen:uint,           //uint16_t 
        DataLen:uint;           //uint16_t 
    
    public static function SIZEOF():uint {return 9;}
    
    public function MREAD(ba:ByteArray):void
    {
        var pos = ba.position;
        ba.endian = Endian.LITTLE_ENDIAN;
        
        PatternHeaderSize   = ba.readInt();
        Typ                 = ba.readUnsignedByte();
        PattLen             = ba.readUnsignedShort();
        DataLen             = ba.readUnsignedShort();
        
        Tools.assert(pos == ba.position - SIZEOF());
    }
        
    public function PatternHeaderTyp() 
    {
        
    }
    
}

}