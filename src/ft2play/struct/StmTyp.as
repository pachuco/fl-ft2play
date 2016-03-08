package ft2play.struct 
{

public class StmTyp implements interf.MEMCPY, interf.MSET_zero
{
    
    public var
        InstrOfs:SampleTyp,         //SampleTyp
        InstrSeg:InstrTyp,          //InstrTyp
        FinalVol:Number,            //float
        OutVol:int,                 //int8_t
        RealVol:int,                //int8_t
        RelTonNr:int,               //int8_t
        FineTune:int,               //int8_t
        OutPan:int,                 //int16_t
        RealPeriod:int,             //int16_t
        FadeOutAmp:int,             //int32_t
        EnvVIPValue:int,            //int16_t
        EnvPIPValue:int,            //int16_t
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
    
    public function MCPY_to(dest:StmTyp)
    {
        //var dest:StmTyp = (StmTyp)_dest;
        
        InstrOfs.MCPY_to(dest.InstrOfs);
        InstrSeg.MCPY_to(dest.InstrSeg);
        dest.FinalVol               = FinalVol;
        dest.OutVol                 = OutVol;
        dest.RealVol                = RealVol;
        dest.RelTonNr               = RelTonNr;
        dest.FineTune               = FineTune;
        dest.OutPan                 = OutPan;
        dest.RealPeriod             = RealPeriod;
        dest.FadeOutAmp             = FadeOutAmp;
        dest.EnvVIPValue            = EnvVIPValue;
        dest.EnvPIPValue            = EnvPIPValue;
        dest.OldVol                 = OldVol;
        dest.OldPan                 = OldPan;
        dest.OutPeriod              = OutPeriod;
        dest.FinalPan               = FinalPan;
        dest.FinalPeriod            = FinalPeriod;
        dest.EnvSustainActive       = EnvSustainActive;
        dest.SmpStartPos            = SmpStartPos;
        dest.InstrNr                = InstrNr;
        dest.ToneType               = ToneType;
        dest.EffTyp                 = EffTyp;
        dest.Eff                    = Eff;
        dest.SmpOffset              = SmpOffset;
        dest.WantPeriod             = WantPeriod;
        dest.WaveCtrl               = WaveCtrl;
        dest.Status                 = Status;
        dest.PortaDir               = PortaDir;
        dest.GlissFunk              = GlissFunk;
        dest.PortaSpeed             = PortaSpeed;
        dest.VibPos                 = VibPos;
        dest.TremPos                = TremPos;
        dest.VibSpeed               = VibSpeed;
        dest.VibDepth               = VibDepth;
        dest.TremSpeed              = TremSpeed;
        dest.TremDepth              = TremDepth;
        dest.PattPos                = PattPos;
        dest.LoopCnt                = LoopCnt;
        dest.VolSlideSpeed          = VolSlideSpeed;
        dest.FVolSlideUpSpeed       = FVolSlideUpSpeed;
        dest.FVolSlideDownSpeed     = FVolSlideDownSpeed;
        dest.FPortaUpSpeed          = FPortaUpSpeed;
        dest.FPortaDownSpeed        = FPortaDownSpeed;
        dest.EPortaUpSpeed          = EPortaUpSpeed;
        dest.EPortaDownSpeed        = EPortaDownSpeed;
        dest.PortaUpSpeed           = PortaUpSpeed;
        dest.PortaDownSpeed         = PortaDownSpeed;
        dest.RetrigSpeed            = RetrigSpeed;
        dest.RetrigCnt              = RetrigCnt;
        dest.RetrigVol              = RetrigVol;
        dest.VolKolVol              = VolKolVol;
        dest.TonNr                  = TonNr;
        dest.FadeOutSpeed           = FadeOutSpeed;
        dest.EnvVCnt                = EnvVCnt;
        dest.EnvVPos                = EnvVPos;
        dest.EnvVAmp                = EnvVAmp;
        dest.EnvPCnt                = EnvPCnt;
        dest.EnvPPos                = EnvPPos;
        dest.EnvPAmp                = EnvPAmp;
        dest.EVibPos                = EVibPos;
        dest.EVibAmp                = EVibAmp;
        dest.EVibSweep              = EVibSweep;
        dest.TremorSave             = TremorSave;
        dest.TremorPos              = TremorPos;
        dest.GlobVolSlideSpeed      = GlobVolSlideSpeed;
        dest.PanningSlideSpeed      = PanningSlideSpeed;
        dest.Mute                   = Mute;
        dest.Nr                     = Nr;
    }
    
    public function MSET_to0()
    {
        InstrOfs.MSET_to0();
        InstrSeg.MSET_to0();
        FinalVol               = 0.0;
        OutVol                 = 0;
        RealVol                = 0;
        RelTonNr               = 0;
        FineTune               = 0;
        OutPan                 = 0;
        RealPeriod             = 0;
        FadeOutAmp             = 0;
        EnvVIPValue            = 0;
        EnvPIPValue            = 0;
        OldVol                 = 0;
        OldPan                 = 0;
        OutPeriod              = 0;
        FinalPan               = 0;
        FinalPeriod            = 0;
        EnvSustainActive       = 0;
        SmpStartPos            = 0;
        InstrNr                = 0;
        ToneType               = 0;
        EffTyp                 = 0;
        Eff                    = 0;
        SmpOffset              = 0;
        WantPeriod             = 0;
        WaveCtrl               = 0;
        Status                 = 0;
        PortaDir               = 0;
        GlissFunk              = 0;
        PortaSpeed             = 0;
        VibPos                 = 0;
        TremPos                = 0;
        VibSpeed               = 0;
        VibDepth               = 0;
        TremSpeed              = 0;
        TremDepth              = 0;
        PattPos                = 0;
        LoopCnt                = 0;
        VolSlideSpeed          = 0;
        FVolSlideUpSpeed       = 0;
        FVolSlideDownSpeed     = 0;
        FPortaUpSpeed          = 0;
        FPortaDownSpeed        = 0;
        EPortaUpSpeed          = 0;
        EPortaDownSpeed        = 0;
        PortaUpSpeed           = 0;
        PortaDownSpeed         = 0;
        RetrigSpeed            = 0;
        RetrigCnt              = 0;
        RetrigVol              = 0;
        VolKolVol              = 0;
        TonNr                  = 0;
        FadeOutSpeed           = 0;
        EnvVCnt                = 0;
        EnvVPos                = 0;
        EnvVAmp                = 0;
        EnvPCnt                = 0;
        EnvPPos                = 0;
        EnvPAmp                = 0;
        EVibPos                = 0;
        EVibAmp                = 0;
        EVibSweep              = 0;
        TremorSave             = 0;
        TremorPos              = 0;
        GlobVolSlideSpeed      = 0;
        PanningSlideSpeed      = 0;
        Mute                   = 0;
        Nr                     = 0;
    }
    
    public function MCPY_from(src:StmTyp)
    {
        src.MCPY_to(this);
    }
    
    public function StmTyp() 
    {
        InstrOfs = new SampleTyp();
        InstrSeg = new InstrTyp();
    }
    
}

}