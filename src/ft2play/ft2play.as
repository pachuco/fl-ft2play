package ft2play 
{

/*
** FT2PLAY v0.68 - 7th of November 2014
** ====================================
**
** Changelog from v0.67:
** - Bug in GetNewNote() (cmd 390 would fail - "unreal2 scirreal mix.xm" fix)
**
** Changelog from v0.66:
** - Auto-vibrato was wrong on every type except for sine
**
** Changelog from v0.65:
** - RelocateTon() was less accurate, changed back to the older one
**    and made it a little bit safer. This one is slower tho' :o(
** - Forgot to zero out the internal Stm channels in StopVoices().
**
** Changelog from v0.64:
** - Fixed a critical bug in the finetune calculation.
**
** C port of FastTracker II's replayer, by 8bitbubsy (Olav Sorensen)
** using the original pascal+asm source codes by Mr.H (Fredrik Huss)
** of Triton.
**
** This is by no means a piece of beautiful code, nor is it meant to be...
** It's just an accurate FastTracker II replayer port for people to enjoy.
**
** Also thanks to aciddose (and kode54) for coding the vol/sample ramp.
** The volume ramp is tuned to that of FT2 (5ms).
**
** (extreme) non-FT2 extensions:
** - Max 127 channels (was 32)
** - Non-even amount-of-channels number (FT2 supports *even* numbers only)
** - Max 256 instruments (was 128)
** - Max 32 samples per instrument (was 16)
** - Max 1024 rows per pattern (was 256)
** - Stereo samples
**
** These additions shouldn't break FT2 accuracy unless I'm wrong.
**
** You need to link winmm.lib for this to compile (-lwinmm)
**
** User functions:
**
** #include <stdint.h>
**
** int8_t ft2play_LoadModule(const uint8_t *moduleData, uint32_t dataLength);
** int8_t ft2play_Init(uint32_t outputFreq, int8_t lerpMixFlag);
** void ft2play_FreeSong(void);
** void ft2play_Close(void);
** void ft2play_PauseSong(int8_t pause);
** void ft2play_PlaySong(void);
*/


public class ft2play 
{
    
    private const USE_VOL_RAMP:int  = 1;
    private const SOUND_BUFFERS:int = 7;
    
    private var
        IS_Vol:int      = 1,
        IS_Period:int   = 2,
        IS_NyTon:int    = 4,
        
        //with vol ramping
        MAX_VOICES   = 127,
        TOTAL_VOICES = 254,
        SPARE_OFFSET = 127;
        
    private const InstrHeaderSize:uint = (InstrHeaderTyp._sizeof - (32 * SampleHeaderTyp._sizeof))
        
    public function ft2play() 
    {
        
    }
    
}

}