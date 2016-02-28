package ft2play.struct 
{

public class VOICE 
{
    
    public var
        sampleData:int,          //*const int8_t   
        loopEnabled:int,         //int8_t          
        sixteenBit:int,          //int8_t          
        stereo:int,              //int8_t          
        loopBidi:int,            //int8_t          
        loopingForward:int,      //int8_t          
        sampleLength:int,        //int32_t         
        sampleLoopBegin:int,     //int32_t         
        sampleLoopEnd:int,       //int32_t         
        samplePosition:int,      //int32_t         
        sampleLoopLength:int,    //int32_t         
        
        incRate:Number,          //float           
        frac:Number,             //float           
        volumeL:Number,          //float           
        volumeR:Number,          //float           

    //#ifdef USE_VOL_RAMP
        targetVolL:Number,       //float           
        targetVolR:Number,       //float           
        volDeltaL:Number,        //float           
        volDeltaR:Number,        //float           
        fader:Number,            //float           
        faderDelta:Number,       //float           
        faderDest:Number;        //float           
    //#endif
    
    public function VOICE() 
    {
        
    }
    
}

}