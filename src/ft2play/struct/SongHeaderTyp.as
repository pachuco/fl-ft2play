import flash.utils.ByteArray;
import flash.utils.Endian;
import ft2play.Tools;

package ft2play.struct 
{

public class SongHeaderTyp implements interf.PACKED, interf.MSET_zero
{
    
    public var
        Sig:String,             //char[17]
        Name:String,            //char[21]
        ProggName:String,       //char[20]
        Ver:uint,               //uint16_t
        HeaderSize:int,         //int32_t 
        Len:uint,               //uint16_t
        RepS:uint,              //uint16_t
        AntChn:uint,            //uint16_t
        AntPtn:uint,            //uint16_t
        AntInstrs:uint,         //uint16_t
        Flags:uint,             //uint16_t
        DefTempo:uint,          //uint16_t
        DefSpeed:uint,          //uint16_t
        SongTab:Vector.<uint>;  //uint8_t[256]
    
    public static function SIZEOF():uint {return 336;}
    
    public function MREAD(ba:ByteArray):void
    {
        var pos = ba.position;
        var i:int;
        ba.endian = Endian.LITTLE_ENDIAN;
        
        Sig         = ba.readMultiByte(17, "US-ASCII");
        Name        = ba.readMultiByte(21, "US-ASCII");
        ProggName   = ba.readMultiByte(20, "US-ASCII");
        Ver         = ba.readUnsignedShort();
        HeaderSize  = ba.readInt();
        Len         = ba.readUnsignedShort();
        RepS        = ba.readUnsignedShort();
        AntChn      = ba.readUnsignedShort();
        AntPtn      = ba.readUnsignedShort();
        AntInstrs   = ba.readUnsignedShort();
        Flags       = ba.readUnsignedShort();
        DefTempo    = ba.readUnsignedShort();
        DefSpeed    = ba.readUnsignedShort();
        for(i=0; i<256; ++i) SongTab[i] = ba.readUnsignedByte();
        
        Tools.assert(pos == ba.position - SIZEOF());
    }
    
    public function MSET_to0()
    {
        var i:int;
        
        Sig         = "";
        Name        = "";
        ProggName   = "";
        Ver         = 0;
        HeaderSize  = 0;
        Len         = 0;
        RepS        = 0;
        AntChn      = 0;
        AntPtn      = 0;
        AntInstrs   = 0;
        Flags       = 0;
        DefTempo    = 0;
        DefSpeed    = 0;
        for(i=0; i<256; ++i) SongTab[i] = 0;
    }
    
    public function SongHeaderTyp() 
    {
        SongTab = new Vector.<uint>(256, true);
    }
    
}

}