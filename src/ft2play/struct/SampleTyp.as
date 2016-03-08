package ft2play.struct 
{

public class SampleTyp implements interf.MEMCPY, interf.MSET_zero
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
    
    public function MSET_to0()
    {
        Len    = 0;
        RepS   = 0;
        RepL   = 0;
        Vol    = 0;
        Fine   = 0;
        Typ    = 0;
        Pan    = 0;
        RelTon = 0;
        skrap  = 0;
        Name   = "";
        Pek    = -1;    //*NULL
    }
    
    public function SampleTyp() 
    {
        
    }
    
}

}