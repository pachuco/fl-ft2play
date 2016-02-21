package ft2play.struct 
{

public class InstrTyp implements _CStruct
{
    public var
    SampleSize:uint,            //uint32_t        
    TA:ByteArray,               //uint8_t[96]     
    EnvVP:Vector.<int>,         //int16_t[12][2]  
    EnvPP:Vector.<int>,         //int16_t[12][2]  
    EnvVPAnt:uint,              //uint8_t         
    EnvPPAnt:uint,              //uint8_t         
    EnvVSust:uint,              //uint8_t         
    EnvVRepS:uint,              //uint8_t         
    EnvVRepE:uint,              //uint8_t         
    EnvPSust:uint,              //uint8_t         
    EnvPRepS:uint,              //uint8_t         
    EnvPRepE:uint,              //uint8_t         
    EnvVTyp:uint,               //uint8_t         
    EnvPTyp:uint,               //uint8_t         
    VibTyp:uint,                //uint8_t         
    VibSweep:uint,              //uint8_t         
    VibDepth:uint,              //uint8_t         
    VibRate:uint,               //uint8_t         
    FadeOut:uint,               //uint16_t        
    MIDIOn:uint,                //uint8_t         
    MIDIChannel:uint,           //uint8_t         
    MIDIProgram:uint,           //uint16_t        
    MIDIBend:uint,              //uint16_t        
    Mute:uint,                  //uint8_t         
    Reserved:ByteArray,         //uint8_t[15]     
    AntSamp:uint,               //uint16_t        
    Samp:Vector.<SampleTyp>;    //SampleTyp[32]   
    
    public function InstrTyp() 
    {
        
    }
    
}

}