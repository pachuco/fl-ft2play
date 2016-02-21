package ft2play.struct 
{

public class SampleHeaderTyp implements _CStruct
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
    
    
    public function SampleHeaderTyp() 
    {
        
    }
    
}

}