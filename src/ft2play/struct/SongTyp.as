package ft2play.struct 
{

public class SongTyp
{
    
    public var
        Len:uint,                   //uint16_t     
        RepS:uint,                  //uint16_t     
        AntChn:uint,                //uint8_t      
        AntPtn:uint,                //uint16_t     
        AntInstrs:uint,             //uint16_t     
        SongPos:int,                //int16_t      
        PattNr:int,                 //int16_t      
        PattPos:int,                //int16_t      
        PattLen:int,                //int16_t      
        Speed:uint,                 //uint16_t     
        Tempo:uint,                 //uint16_t     
        InitSpeed:uint,             //uint16_t     
        InitTempo:uint,             //uint16_t     
        GlobVol:int,                //int16_t
        Timer:uint,                 //uint16_t     
        PattDelTime:uint,           //uint8_t      
        PattDelTime2:uint,          //uint8_t      
        PBreakFlag:uint,            //uint8_t      
        PBreakPos:uint,             //uint8_t      
        PosJumpFlag:uint,           //uint8_t      
        SongTab:Vector.<uint>,      //uint8_t[256] 
        Ver:uint,                   //uint16_t     
        Name:String,                //char[21]     
        ProgName:String,            //char[21]     
        InstrName:Vector.<String>;  //char[256][23]
        
        char InstrName[256][23];
    
    public function SongTyp() 
    {
        var i:int;
        
        SongTab     = new Vector.<uint>(256, true);
        InstrName   = new Vector.<String>(256, true);
        for(i=0; i<256; ++i) InstrName[i] = "";
    }
    
}

}