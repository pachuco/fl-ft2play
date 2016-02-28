import flash.utils.ByteArray;
import flash.utils.Endian;
import ft2play.Tools;

package ft2play.struct 
{

public class InstrHeaderTyp implements PACKED
{
    
    public var
        InstrSize:int,                      //int32_t            
        Name:String,                        //char[22]           
        Typ:uint,                           //uint8_t            
        AntSamp:uint,                       //uint16_t           
        SampleSize:int,                     //int32_t            
        TA:Vector.<uint>,                   //uint8_t[96]        
        EnvVP:Vector.<int>,                 //int16_t[12][2]     
        EnvPP:Vector.<int>,                 //int16_t[12][2]     
        EnvVPAnt:uint,                      //uint8_t            
        EnvPPAnt:uint,                      //uint8_t            
        EnvVSust:uint,                      //uint8_t            
        EnvVRepS:uint,                      //uint8_t            
        EnvVRepE:uint,                      //uint8_t            
        EnvPSust:uint,                      //uint8_t            
        EnvPRepS:uint,                      //uint8_t            
        EnvPRepE:uint,                      //uint8_t            
        EnvVTyp:uint,                       //uint8_t            
        EnvPTyp:uint,                       //uint8_t            
        VibTyp:uint,                        //uint8_t            
        VibSweep:uint,                      //uint8_t            
        VibDepth:uint,                      //uint8_t            
        VibRate:uint,                       //uint8_t            
        FadeOut:uint,                       //uint16_t           
        MIDIOn:uint,                        //uint8_t            
        MIDIChannel:uint,                   //uint8_t            
        MIDIProgram:int,                    //int16_t            
        MIDIBend:int,                       //int16_t            
        Mute:int,                           //int8_t             
        Reserved:Vector.<uint>,             //uint8_t[15]        
        Samp:Vector.<SampleHeaderTyp>;      //SampleHeaderTyp[32]
    
    
    public static function SIZEOF():uint {return 1543;}
    
    public function MREAD(ba:ByteArray):void
    {
        var pos = ba.position;
        var i:int;
        ba.endian = Endian.LITTLE_ENDIAN;
        
        InstrSize   = ba.readInt();
        Name        = ba.readMultiByte(22, "US-ASCII");       
        Typ         = ba.readUnsignedByte();
        AntSamp     = ba.readUnsignedShort();
        SampleSize  = ba.readInt();
        for(i=0; i<96;   ++i) TA[i]     = ba.readUnsignedByte();
        for(i=0; i<12*2; ++i) EnvVP[i]  = ba.readShort();
        for(i=0; i<12*2; ++i) EnvPP[i]  = ba.readShort();
        EnvVPAnt    = ba.readUnsignedByte();
        EnvPPAnt    = ba.readUnsignedByte();
        EnvVSust    = ba.readUnsignedByte();
        EnvVRepS    = ba.readUnsignedByte();
        EnvVRepE    = ba.readUnsignedByte();
        EnvPSust    = ba.readUnsignedByte();
        EnvPRepS    = ba.readUnsignedByte();
        EnvPRepE    = ba.readUnsignedByte();
        EnvVTyp     = ba.readUnsignedByte();
        EnvPTyp     = ba.readUnsignedByte();
        VibTyp      = ba.readUnsignedByte();
        VibSweep    = ba.readUnsignedByte();
        VibDepth    = ba.readUnsignedByte();
        VibRate     = ba.readUnsignedByte();
        FadeOut     = ba.readUnsignedShort();
        MIDIOn      = ba.readUnsignedByte();
        MIDIChannel = ba.readUnsignedByte();
        MIDIProgram = ba.readShort();
        MIDIBend    = ba.readShort();
        Mute        = ba.readByte();
        for(i=0; i<15;   ++i) Reserved[i] = ba.readUnsignedByte();
        for(i=0; i<32;   ++i) Samp[i].MREAD(ba);
        
        Tools.assert(pos == ba.position - SIZEOF());
    }
        
    
    public function InstrHeaderTyp() 
    {
        var i:int;
        TA          = new Vector.<uint>(96, true);
        EnvVP       = new Vector.<int>(12*2. true);
        EnvPP       = new Vector.<int>(12*2. true);
        Reserved    = new Vector.<uint>(15, true);
        Samp        = new Vector.<SampleHeaderTyp>(32, true);
        for (i = 0; i < 32; ++i) Samp[i] = new SampleHeaderTyp();
    }
    
}

}