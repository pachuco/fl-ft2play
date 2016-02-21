package ft2play.struct 
{

public class PatternHeaderTyp implements _CStruct
{
    public var
        PatternHeaderSize:int,  //int32_t  
        Typ:uint,               //uint8_t  
        PattLen:uint,           //uint16_t 
        DataLen:uint;           //uint16_t 
    
    public function PatternHeaderTyp() 
    {
        
    }
    
}

}