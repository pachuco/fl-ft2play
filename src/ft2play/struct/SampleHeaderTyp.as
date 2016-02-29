import flash.utils.ByteArray;
import flash.utils.Endian;
import ft2play.Tools;

package ft2play.struct 
{

public class SampleHeaderTyp implements interf.PACKED
{
    
    public var
        Len:int,     //int32_t  
        RepS:int,    //int32_t  
        RepL:int,    //int32_t  
        vol:uint,    //uint8_t  
        Fine:int,    //int8_t   
        Typ:uint,    //uint8_t  
        Pan:uint,    //uint8_t  
        RelTon:int,  //int8_t   
        skrap:uint,  //uint8_t  
        Name:String; //char[22]
    
    public static function SIZEOF():uint {return 40;}
    
    public function MREAD(ba:ByteArray):void
    {
        var pos = ba.position;
        ba.endian = Endian.LITTLE_ENDIAN;
        
        Len     = ba.readInt();
        RepS    = ba.readInt();
        RepL    = ba.readInt();
        vol     = ba.readUnsignedByte();
        Fine    = ba.readByte();
        Typ     = ba.readUnsignedByte();
        Pan     = ba.readUnsignedByte();
        RelTon  = ba.readByte();
        skrap   = ba.readUnsignedByte();
        Name    = ba.readMultiByte(22, "US-ASCII");
        
        Tools.assert(pos == ba.position - SIZEOF());
    }
    
    public function SampleHeaderTyp() 
    {
        
    }
    
}

}