package ft2play.struct 
{

public class StmTyp implements _CStruct
{
    
    public var
        InstrOfs:SampleTyp,         //SampleTyp         /* read only */
        InstrSeg:InstrTyp,          //InstrTyp          /* read only */
        FinalVol:Number,            //float     
        OutVol:int,                 //int8_t            /* must be signed */
        RealVol:int,                //int8_t            /* must be signed */
        RelTonNr:int,               //int8_t            /* must be signed */
        FineTune:int,               //int8_t            /* must be signed */
        OutPan:int,                 //int16_t           /* must be signed */
        RealPeriod:int,             //int16_t           /* must be signed */
        FadeOutAmp:int,             //int32_t           /* must be signed */
        EnvVIPValue:int,            //int16_t           /* must be signed */
        EnvPIPValue:int,            //int16_t           /* must be signed */
        OldVol:uint,                //uint8_t   
        OldPan:uint,                //uint8_t   
        OutPeriod:uint,             //uint16_t  
        FinalPan:uint,              //uint8_t   
        FinalPeriod:uint,           //uint16_t  
        EnvSustainActive:uint,      //uint8_t   
        SmpStartPos:uint,           //uint16_t  
        InstrNr:uint,               //uint16_t  
        ToneType:uint,              //uint16_t  
        EffTyp:uint,                //uint8_t   
        Eff:uint,                   //uint8_t   
        SmpOffset:uint,             //uint8_t   
        WantPeriod:uint,            //uint16_t  
        WaveCtrl:uint,              //uint8_t   
        Status:uint,                //uint8_t   
        PortaDir:uint,              //uint8_t   
        GlissFunk:uint,             //uint8_t   
        PortaSpeed:uint,            //uint16_t  
        VibPos:uint,                //uint8_t   
        TremPos:uint,               //uint8_t   
        VibSpeed:uint,              //uint8_t   
        VibDepth:uint,              //uint8_t   
        TremSpeed:uint,             //uint8_t   
        TremDepth:uint,             //uint8_t   
        PattPos:uint,               //uint8_t   
        LoopCnt:uint,               //uint8_t   
        VolSlideSpeed:uint,         //uint8_t   
        FVolSlideUpSpeed:uint,      //uint8_t   
        FVolSlideDownSpeed:uint,    //uint8_t   
        FPortaUpSpeed:uint,         //uint8_t   
        FPortaDownSpeed:uint,       //uint8_t   
        EPortaUpSpeed:uint,         //uint8_t   
        EPortaDownSpeed:uint,       //uint8_t   
        PortaUpSpeed:uint,          //uint8_t   
        PortaDownSpeed:uint,        //uint8_t   
        RetrigSpeed:uint,           //uint8_t   
        RetrigCnt:uint,             //uint8_t   
        RetrigVol:uint,             //uint8_t   
        VolKolVol:uint,             //uint8_t   
        TonNr:uint,                 //uint8_t   
        FadeOutSpeed:uint,          //uint16_t  
        EnvVCnt:uint,               //uint16_t  
        EnvVPos:uint,               //uint8_t   
        EnvVAmp:uint,               //uint16_t  
        EnvPCnt:uint,               //uint16_t  
        EnvPPos:uint,               //uint8_t   
        EnvPAmp:uint,               //uint16_t  
        EVibPos:uint,               //uint8_t   
        EVibAmp:uint,               //uint16_t  
        EVibSweep:uint,             //uint16_t  
        TremorSave:uint,            //uint8_t   
        TremorPos:uint,             //uint8_t   
        GlobVolSlideSpeed:uint,     //uint8_t   
        PanningSlideSpeed:uint,     //uint8_t   
        Mute:uint,                  //uint8_t   
        Nr:uint;                    //uint8_t   
    
    public function StmTyp() 
    {
        
    }
    
}

}