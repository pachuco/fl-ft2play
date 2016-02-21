package ft2play.struct 
{

public class SongHeaderTyp implements _CStruct
{
    public var
        Sig:String,           //char[17]
        Name:String,          //char[21]
        ProggName:String,     //char[20]
        Ver:uint,             //uint16_t
        HeaderSize:int,       //int32_t 
        Len:uint,             //uint16_t
        RepS:uint,            //uint16_t
        AntChn:uint,          //uint16_t
        AntPtn:uint,          //uint16_t
        AntInstrs:uint,       //uint16_t
        Flags:uint,           //uint16_t
        DefTempo:uint,        //uint16_t
        DefSpeed:uint,        //uint16_t
        SongTab:ByteArray;    //uint8_t[256]
    
    public function SongHeaderTyp() 
    {
        
    }
    
}

}