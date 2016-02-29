package ft2play.struct 
{

public class SampleTyp implements interf.MEMCPY
{
    
    public var
        Len:int,     //int32_t 
        RepS:int,    //int32_t 
        RepL:int,    //int32_t 
        Vol:uint,    //uint8_t 
        Fine:int,    //int8_t  
        Typ:uint,    //uint8_t 
        Pan:uint,    //uint8_t 
        RelTon:int,  //int8_t  
        skrap:uint,  //uint8_t 
        Name:String, //char[22]
        Pek:int;     //*int8_t
    
    public function MCPY_to(dest:SampleTyp)
    {
        //var dest:SampleTyp = (SampleTyp)_dest;
        
        dest.Len    = Len;
        dest.RepS   = RepS;
        dest.RepL   = RepL;
        dest.Vol    = Vol;
        dest.Fine   = Fine;
        dest.Typ    = Typ;
        dest.Pan    = Pan;
        dest.RelTon = RelTon;
        dest.skrap  = skrap;
        dest.Name   = Name;
        dest.Pek    = Pek;
    }
    
    public function MCPY_from(_src:SampleTyp)
    {
        src.MCPY_to(this);
    }
    
    public function SampleTyp() 
    {
        
    }
    
}

}