package ft2play.struct 
{

public class InstrHeaderTyp implements _CStruct
{
    
    public var
        InstrSize:int,                      //int32_t            
        Name:String,                        //char[22]           
        Typ:uint,                           //uint8_t            
        AntSamp:uint,                       //uint16_t           
        SampleSize:int,                     //int32_t            
        TA:uint,                            //uint8_t[96]        
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
        Reserved:ByteArray,                 //uint8_t[15]        
        Samp:Vector.<SampleHeaderTyp_t>;    //SampleHeaderTyp[32]
    
    public function InstrHeaderTyp() 
    {
        
    }
    
}

}