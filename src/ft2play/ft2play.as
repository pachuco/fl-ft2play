package ft2play 
{

/*
** FT2PLAY v0.71 - 13th of July 2015 - http://16-bits.org
** ======================================================
**
** Very accurate C port of FastTracker 2.09's replayer,
** by Olav "8bitbubsy" Sørensen. Using the original pascal+asm source
** codes by Fredrik "Mr.H" Huss (Triton).
**
** Thanks to aciddose (and kode54) for coding the vol/sample ramp.
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
** Alternatively, you can wrap around your own audio callback for using
** ft2play on other platforms.
**
** Changelog from v0.70:
** - Code cleanup
** - Proper check for memory allocations
**
** Changelog from v0.68:
** - Volume ramp didn't work correctly with LERP and some non-looping samples
** - One for-loop value was wrong (254 instead of 256)
** - Some mixer optimizations
** - Some visual code change/cleanup
**
** Changelog from v0.67:
** - Bug in GetNewNote() (cmd 390 would fail)
**
** Changelog from v0.66:
** - Auto-vibrato was wrong on every type except for sine
**
** Changelog from v0.65:
** - RelocateTon() was less accurate, changed back to the older one
**    and made it a little bit safer.
** - Forgot to zero out the internal Stm channels in StopVoices().
**
** Changelog from v0.64:
** - Fixed a critical bug in the finetune calculation.
**
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
    private function _LERP(x:int, y:int, z:Number):int {x + (y - x) * z;}

    //comment out this one to disable the FT2 volume ramp present in later FT2 versions
    private var USE_VOL_RAMP:int = 1;
    
    //don't change these two unless you know what you're doing...
    private var MIX_BUF_NUM:int = 7;
    private var MIX_BUF_LEN:int = 2048
    
    private var
        IS_Vol:int      = 1,
        IS_Period:int   = 2,
        IS_NyTon:int    = 4,
        
        //with vol ramping
        MAX_VOICES   = 127,
        TOTAL_VOICES = 254,
        SPARE_OFFSET = 127;
        
        //without ramping
        //MAX_VOICES   = 127,
        //TOTAL_VOICES = 127
        
    private var InstrHeaderSize:uint = (InstrHeaderTyp.SIZEOF - (32 * SampleHeaderTyp.SIZEOF));
    
    //TABLES AND VARIABLES
    private AmigaFinePeriod:Vector.<uint> = Vector.<uint>       //uint16_t[12*8]
    ([
        907,900,894,887,881,875,868,862,856,850,844,838,
        832,826,820,814,808,802,796,791,785,779,774,768,
        762,757,752,746,741,736,730,725,720,715,709,704,
        699,694,689,684,678,675,670,665,660,655,651,646,
        640,636,632,628,623,619,614,610,604,601,597,592,
        588,584,580,575,570,567,563,559,555,551,547,543,
        538,535,532,528,524,520,516,513,508,505,502,498,
        494,491,487,484,480,477,474,470,467,463,460,457
    ]);
    
    //this table is so small that generating it is almost as big
    private VibTab:Vector.<uint> = Vector.<uint>                //uint8_t[32]
    ([
        0,  24,  49, 74, 97,120,141,161,
        180,197,212,224,235,244,250,253,
        255,253,250,244,235,224,212,197,
        180,161,141,120, 97, 74, 49, 24
    ]);
    
    //TODO
static TonTyp *Patt[256];
static StmTyp Stm[MAX_VOICES];
static uint16_t PattLens[256];
static InstrTyp *Instr[255 + 1];
static VOICE voice[TOTAL_VOICES];
//static WAVEHDR waveBlocks[MIX_BUF_NUM];
//static HWAVEOUT _hWaveOut;
static int8_t samplingInterpolation;
static int32_t samplesLeft;
static volatile uint32_t samplesPerFrame;
static int8_t LinearFrqTab;
static uint32_t soundBufferSize;
static uint32_t audioFreq;
static SongTyp Song;
//static WAVEFORMATEX wfx;
static float f_audioFreq;
private var mixingMutex:int;    //int8_t
static volatile int8_t isMixing;

#ifdef USE_VOL_RAMP
float f_samplesPerFrame005;
float f_samplesPerFrame010;
#endif

/* pre-NULL'd pointers */
static int8_t *VibSineTab     = NULL;
static int16_t *linearPeriods = NULL;
static int16_t *amigaPeriods  = NULL;
static int16_t *Note2Period   = NULL;
static uint32_t *LogTab       = NULL;
static TonTyp *NilPatternLine = NULL;
static float *PanningTab      = NULL;
static float *masterBufferL   = NULL;
static float *masterBufferR   = NULL;
static int8_t *mixerBuffer    = NULL;

    //globally accessed
    private var ModuleLoaded:int  = 0;
    private var MusicPaused:int   = 0;
    private var Playing:int       = 0;
    private var numChannels:uint  = 32;
    
    //CODE START
    public function ft2play() 
    {
        
    }
    
    

    private function voiceIsActive(i:uint):int
    {
        return voice[i].sampleData >= 0;    //!= NULL
    }

    private function RetrigVolume(ch:StmTyp):void
    {
        ch.RealVol = ch.OldVol;
        ch.OutVol  = ch.OldVol;
        ch.OutPan  = ch.OldPan;
        ch.Status |= IS_Vol;
    }

    private function RetrigEnvelopeVibrato(StmTyp *ch):void
    {
        if (!(ch.WaveCtrl & 0x04)) ch.VibPos  = 0;
        if (!(ch.WaveCtrl & 0x40)) ch.TremPos = 0;

        ch.RetrigCnt = 0;
        ch.TremorPos = 0;

        ch.EnvSustainActive = 1;

        if (ch.InstrSeg.EnvVTyp & 1)
        {
            ch.EnvVCnt = 0xFFFF;
            ch.EnvVPos = 0;
        }

        if (ch.InstrSeg.EnvPTyp & 1)
        {
            ch.EnvPCnt = 0xFFFF;
            ch.EnvPPos = 0;
        }

        /* FT2 doesn't check if fadeout is more than 32768 */
        ch.FadeOutSpeed = ch.InstrSeg.FadeOut * 2;
        ch.FadeOutAmp   = 65536;

        if (ch.InstrSeg.VibDepth)
        {
            ch.EVibPos = 0;

            if (ch.InstrSeg.VibSweep)
            {
                ch.EVibAmp   = 0;
                ch.EVibSweep = (ch.InstrSeg.VibDepth * 256) / ch.InstrSeg.VibSweep;
            }
            else
            {
                ch.EVibAmp   = ch.InstrSeg.VibDepth * 256;
                ch.EVibSweep = 0;
            }
        }
    }

static void KeyOff(StmTyp *ch)
{
    ch->EnvSustainActive = 0;

    if (!(ch->InstrSeg.EnvPTyp & 1)) /* yes, FT2 does this (!) */
    {
        if (ch->EnvPCnt >= ch->InstrSeg.EnvPP[ch->EnvPPos][0])
            ch->EnvPCnt  = ch->InstrSeg.EnvPP[ch->EnvPPos][0] - 1;
    }

    if (ch->InstrSeg.EnvVTyp & 1)
    {
        if (ch->EnvVCnt >= ch->InstrSeg.EnvVP[ch->EnvVPos][0])
            ch->EnvVCnt  = ch->InstrSeg.EnvVP[ch->EnvVPos][0] - 1;
    }
    else
    {
        ch->RealVol = 0;
        ch->OutVol  = 0;
        ch->Status |= IS_Vol;
    }
}

static uint32_t GetFrequenceValue(uint16_t period)
{
    uint16_t index;

    if (!period) return (0);

    if (LinearFrqTab)
    {
        index = (12 * 192 * 4) - period;
        return (LogTab[index % (12 * 16 * 4)] >> ((14 - (index / (12 * 16 * 4))) & 0x1F));
    }
    else
    {
        return ((1712 * 8363) / period);
    }
}
    
    
}

}