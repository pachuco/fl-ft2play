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
/*//#ifdef USE_VOL_RAMP
        //with vol ramping
        MAX_VOICES   = 127,
        TOTAL_VOICES = 254,
        SPARE_OFFSET = 127;
*///#else        
        //without ramping
        MAX_VOICES   = 127,
        TOTAL_VOICES = 127;
//#endif
        
    private var InstrHeaderSize:uint = (InstrHeaderTyp.SIZEOF - (32 * SampleHeaderTyp.SIZEOF));
    
    //TABLES AND VARIABLES
    private var AmigaFinePeriod:Vector.<uint> = Vector.<uint>       //uint16_t[12*8]
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
    private var VibTab:Vector.<uint> = Vector.<uint>                //uint8_t[32]
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

/*//#ifdef USE_VOL_RAMP
    f_samplesPerFrame005:Number;
    f_samplesPerFrame010:Number;
*///#endif

//TODO
//pre-NULL'd pointers
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
        return (voice[i].sampleData >= 0);    //!= NULL
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

        //FT2 doesn't check if fadeout is more than 32768
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

    private function KeyOff(ch:StmTyp):void
    {
        //TODO: nested arrays to single array
        ch.EnvSustainActive = 0;

        if (!(ch.InstrSeg.EnvPTyp & 1)) //yes, FT2 does this (!)
        {
            if (ch.EnvPCnt >= ch.InstrSeg.EnvPP[ch.EnvPPos][0])
                ch.EnvPCnt  = ch.InstrSeg.EnvPP[ch.EnvPPos][0] - 1;
        }

        if (ch.InstrSeg.EnvVTyp & 1)
        {
            if (ch.EnvVCnt >= ch.InstrSeg.EnvVP[ch.EnvVPos][0])
                ch.EnvVCnt  = ch.InstrSeg.EnvVP[ch.EnvVPos][0] - 1;
        }
        else
        {
            ch.RealVol = 0;
            ch.OutVol  = 0;
            ch.Status |= IS_Vol;
        }
    }

    private function GetFrequenceValue(period:uint):uint
    {
    //TODO: nested arrays to single array
        var index:uint; //uint16_t

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
    
private function StartTone(Ton:uint, EffTyp:uint, Eff:uint, ch:StmTyp):void
{
    var s:SampleTyp;

    var tmpTon:uint;
    var samp:uint;
    var tonLookUp:uint;
    var tmpFTune:uint;

    //if we came from Rxy (retrig), we didn't check note (Ton) yet
    if (Ton == 97)
    {
        KeyOff(ch);
        return;
    }

    if (!Ton)
    {
        Ton = ch.TonNr;
        if (!Ton) return; //if still no note, return.
    }
    //------------------------------------------------------------

    ch.TonNr = Ton;

    if (Instr[ch.InstrNr] != null)
        Instr[ch.InstrNr].MCPY_to(ch.InstrSeg);
    else
        Instr[0].MCPY_to(ch.InstrSeg); //placeholder for invalid samples

    //non-FT2 security fix
    tonLookUp = Ton - 1;
    if (tonLookUp > 95) tonLookUp = 95;
    //--------------------

    ch.Mute = ch.InstrSeg.Mute;

    samp = ch.InstrSeg.TA[tonLookUp] & 0x1F;
    s = ch.InstrSeg.Samp[samp];

    s.MCPY_to(ch.InstrOfs);
    ch.RelTonNr = s.RelTon;

    Ton += ch.RelTonNr;
    if (Ton >= (12 * 10)) return;

    ch.OldVol = s.Vol;

    //FT2 doesn't do this, but we don't want to blow our eardrums
    //on malicious XMs...
    
    if (ch.OldVol > 64) ch.OldVol = 64;

    ch.OldPan = s.Pan;

    if ((EffTyp == 0x0E) && ((Eff & 0xF0) == 0x50))
        ch.FineTune = ((Eff & 0x0F) * 16) - 128; //result is now -128 .. 127
    else
        ch.FineTune = s.Fine;

    if (Ton > 0)
    {
        //"arithmetic shift right" on signed number simulation
        if (ch.FineTune >= 0)
            tmpFTune = ch.FineTune / (1 << 3);
        else    //TODO
            tmpFTune = 0xE0 | ((uint8_t)(ch.FineTune) >> 3); //0xE0 = 2^8 - 2^(8-3)

        tmpTon = ((Ton - 1) * 16) + ((tmpFTune + 16) & 0xFF);

        if (tmpTon < ((12 * 10 * 16) + 16)) //should never happen, but FT2 does this check
        {
            ch.RealPeriod = Note2Period[tmpTon];
            ch.OutPeriod  = ch.RealPeriod;
        }
    }

    ch.Status |= (IS_Period + IS_Vol + IS_NyTon);

    if (EffTyp == 9)
    {
        if (Eff)
            ch.SmpOffset = ch.Eff;

        ch.SmpStartPos = ch.SmpOffset * 256;
    }
    else
    {
        ch.SmpStartPos = 0;
    }
}

    private function MultiRetrig(ch:StmTyp):void
    {
        var cnt:uint;
        var vol:int;    //int16_t
        var cmd:int;

        cnt = ch.RetrigCnt + 1;
        if (cnt < ch.RetrigSpeed)
        {
            ch.RetrigCnt = cnt;
            return;
        }

        ch.RetrigCnt = 0;

        vol = ch.RealVol;
        cmd = ch.RetrigVol;

        //0x00 and 0x08 are not handled, ignore them

             if (cmd == 0x01) vol -= 1;
        else if (cmd == 0x02) vol -= 2;
        else if (cmd == 0x03) vol -= 4;
        else if (cmd == 0x04) vol -= 8;
        else if (cmd == 0x05) vol -= 16;
        else if (cmd == 0x06) vol  = (vol / 2) + (vol / 8) + (vol / 16);
        else if (cmd == 0x07) vol /= 2;
        else if (cmd == 0x09) vol += 1;
        else if (cmd == 0x0A) vol += 2;
        else if (cmd == 0x0B) vol += 4;
        else if (cmd == 0x0C) vol += 8;
        else if (cmd == 0x0D) vol += 16;
        else if (cmd == 0x0E) vol  = (vol / 2) + vol;
        else if (cmd == 0x0F) vol *= 2;

             if (vol <  0) vol =  0;
        else if (vol > 64) vol = 64;

        ch.RealVol = vol;   //(int8_t)
        ch.OutVol = ch.RealVol;

        if ((ch.VolKolVol >= 0x10) && (ch.VolKolVol <= 0x50))
        {
            ch.OutVol  = ch.VolKolVol - 0x10;
            ch.RealVol = ch.OutVol;
        }
        else if ((ch.VolKolVol >= 0xC0) && (ch.VolKolVol <= 0xCF))
        {
            ch.OutPan = (ch.VolKolVol & 0x0F) * 16;
        }

        StartTone(0, 0, 0, ch);
    }
    
    private function CheckEffects(ch:StmTyp):void
    {
        var envUpdate:int;
        uint8_t tmpEff;
        uint8_t tmpEffHi;
        int16_t newEnvPos;
        int16_t envPos;
        uint16_t i;

        //*** VOLUME COLUMN EFFECTS (TICK 0) ***

        //set volume
        if ((ch.VolKolVol >= 0x10) && (ch.VolKolVol <= 0x50))
        {
            ch.OutVol  = ch.VolKolVol - 0x10;
            ch.RealVol = ch.OutVol;

            ch.Status |= IS_Vol;
        }

        //fine volume slide down
        else if ((ch.VolKolVol & 0xF0) == 0x80)
        {
            ch.RealVol -= (ch.VolKolVol & 0x0F);
            if (ch.RealVol < 0) ch.RealVol = 0;

            ch.OutVol  = ch.RealVol;
            ch.Status |= IS_Vol;
        }

        //fine volume slide up
        else if ((ch.VolKolVol & 0xF0) == 0x90)
        {
            ch.RealVol += (ch.VolKolVol & 0x0F);
            if (ch.RealVol > 64) ch.RealVol = 64;

            ch.OutVol  = ch.RealVol;
            ch.Status |= IS_Vol;
        }

        //set vibrato speed
        else if ((ch.VolKolVol & 0xF0) == 0xA0)
            ch.VibSpeed = (ch.VolKolVol & 0x0F) * 4;

        //set panning
        else if ((ch.VolKolVol & 0xF0) == 0xC0)
        {
            ch.OutPan  = (ch.VolKolVol & 0x0F) * 16;
            ch.Status |= IS_Vol;
        }


        //*** MAIN EFFECTS (TICK 0) ***


        if ((ch.EffTyp == 0) && (ch.Eff == 0)) return;

        //8xx - set panning
        if (ch.EffTyp == 8)
        {
            ch.OutPan  = ch.Eff;
            ch.Status |= IS_Vol;
        }

        //Bxx - position jump
        else if (ch.EffTyp == 11)
        {
            Song.SongPos = ch.Eff - 1;
            Song.PBreakPos   = 0;
            Song.PosJumpFlag = 1;
        }

        //Cxx - set volume
        else if (ch.EffTyp == 12)
        {
            ch.RealVol = ch.Eff;
            if (ch.RealVol > 64) ch.RealVol = 64;

            ch.OutVol  = ch.RealVol;
            ch.Status |= IS_Vol;
        }

        //Dxx - pattern break
        else if (ch.EffTyp == 13)
        {
            Song.PosJumpFlag = 1;

            tmpEff = ((ch.Eff >> 4) * 10) + (ch.Eff & 0x0F);
            if (tmpEff <= 63)
                Song.PBreakPos = tmpEff;
            else
                Song.PBreakPos = 0;
        }

        //Exx - E effects
        else if (ch.EffTyp == 14)
        {
            //E1x - fine period slide up
            if ((ch.Eff & 0xF0) == 0x10)
            {
                tmpEff = ch.Eff & 0x0F;
                if (!tmpEff)
                    tmpEff = ch.FPortaUpSpeed;

                ch.FPortaUpSpeed = tmpEff;

                ch.RealPeriod -= (tmpEff * 4);
                if (ch.RealPeriod < 1) ch.RealPeriod = 1;

                ch.OutPeriod = ch.RealPeriod;
                ch.Status   |= IS_Period;
            }

            //E2x - fine period slide down
            else if ((ch.Eff & 0xF0) == 0x20)
            {
                tmpEff = ch.Eff & 0x0F;
                if (!tmpEff)
                    tmpEff = ch.FPortaDownSpeed;

                ch.FPortaDownSpeed = tmpEff;

                ch.RealPeriod += (tmpEff * 4);
                if (ch.RealPeriod > (32000 - 1)) ch.RealPeriod = 32000 - 1;

                ch.OutPeriod = ch.RealPeriod;
                ch.Status   |= IS_Period;
            }

            //E3x - set glissando type
            else if ((ch.Eff & 0xF0) == 0x30) ch.GlissFunk = ch.Eff & 0x0F;

            //E4x - set vibrato waveform
            else if ((ch.Eff & 0xF0) == 0x40) ch.WaveCtrl = (ch.WaveCtrl & 0xF0) | (ch.Eff & 0x0F);

            //E5x (set finetune) is handled in StartTone()

            //E6x - pattern loop
            else if ((ch.Eff & 0xF0) == 0x60)
            {
                if (ch.Eff == 0x60) //E60, empty param
                {
                    ch.PattPos = Song.PattPos & 0x00FF;
                }
                else
                {
                    if (!ch.LoopCnt)
                    {
                        ch.LoopCnt = ch.Eff & 0x0F;

                        Song.PBreakPos  = ch.PattPos;
                        Song.PBreakFlag = 1;
                    }
                    else
                    {
                        ch.LoopCnt--;
                        if (ch.LoopCnt)
                        {
                            Song.PBreakPos  = ch.PattPos;
                            Song.PBreakFlag = 1;
                        }
                    }
                }
            }

            //E7x - set tremolo waveform
            else if ((ch.Eff & 0xF0) == 0x70) ch.WaveCtrl = ((ch.Eff & 0x0F) << 4) | (ch.WaveCtrl & 0x0F);

            //E8x - set 4-bit panning (NON-FT2)
            else if ((ch.Eff & 0xF0) == 0x80)
            {
                ch.OutPan  = (ch.Eff & 0x0F) * 16;
                ch.Status |= IS_Vol;
            }

            //EAx - fine volume slide up
            else if ((ch.Eff & 0xF0) == 0xA0)
            {
                tmpEff = ch.Eff & 0x0F;
                if (!tmpEff)
                    tmpEff = ch.FVolSlideUpSpeed;

                ch.FVolSlideUpSpeed = tmpEff;

                ch.RealVol += tmpEff;
                if (ch.RealVol > 64) ch.RealVol = 64;

                ch.OutVol  = ch.RealVol;
                ch.Status |= IS_Vol;
            }

            //EBx - fine volume slide down
            else if ((ch.Eff & 0xF0) == 0xB0)
            {
                tmpEff = ch.Eff & 0x0F;
                if (!tmpEff)
                    tmpEff = ch.FVolSlideDownSpeed;

                ch.FVolSlideDownSpeed = tmpEff;

                ch.RealVol -= tmpEff;
                if (ch.RealVol < 0) ch.RealVol = 0;

                ch.OutVol = ch.RealVol;
                ch.Status |= IS_Vol;
            }

            //ECx - note cut
            else if ((ch.Eff & 0xF0) == 0xC0)
            {
                if (ch.Eff == 0xC0) //empty param
                {
                    ch.RealVol = 0;
                    ch.OutVol  = 0;
                    ch.Status |= IS_Vol;
                }
            }

            //EEx - pattern delay
            else if ((ch.Eff & 0xF0) == 0xE0)
            {
                if (!Song.PattDelTime2)
                    Song.PattDelTime = (ch.Eff & 0x0F) + 1;
            }
        }

        //Fxx - set speed/tempo
        else if (ch.EffTyp == 15)
        {
            if (ch.Eff >= 32)
            {
                Song.Speed = ch.Eff;
                setSamplesPerFrame((audioFreq * 5) / 2 / Song.Speed);
            }
            else
            {
                Song.Tempo = ch.Eff;
                Song.Timer = ch.Eff;
            }
        }

        //Gxx - set global volume
        else if (ch.EffTyp == 16)
        {
            Song.GlobVol = ch.Eff;
            if (Song.GlobVol > 64) Song.GlobVol = 64;

            for (i = 0; i < Song.AntChn; ++i)
                Stm[i].Status |= IS_Vol;
        }

        //Lxx - set vol and pan envelope position
        else if (ch.EffTyp == 21)
        {
            //*** VOLUME ENVELOPE ***
            if (ch.InstrSeg.EnvVTyp & 1)
            {
                ch.EnvVCnt = ch.Eff - 1;

                envPos    = 0;
                envUpdate = 1;
                newEnvPos = ch.Eff;

                if (ch.InstrSeg.EnvVPAnt > 1)
                {
                    envPos++;
                    for (i = 0; i < ch.InstrSeg.EnvVPAnt; ++i)
                    {
                        if (newEnvPos < ch.InstrSeg.EnvVP[envPos][0])
                        {
                            envPos--;

                            newEnvPos -= ch.InstrSeg.EnvVP[envPos][0];
                            if (newEnvPos == 0)
                            {
                                envUpdate = 0;
                                break;
                            }

                            if (ch.InstrSeg.EnvVP[envPos + 1][0] <= ch.InstrSeg.EnvVP[envPos][0])
                            {
                                envUpdate = 1;
                                break;
                            }

                            ch.EnvVIPValue = ((ch.InstrSeg.EnvVP[envPos + 1][1] - ch.InstrSeg.EnvVP[envPos][1]) & 0x00FF) * 256;
                            ch.EnvVIPValue /= (ch.InstrSeg.EnvVP[envPos + 1][0] - ch.InstrSeg.EnvVP[envPos][0]);

                            ch.EnvVAmp = (ch.EnvVIPValue * (newEnvPos - 1)) + ((ch.InstrSeg.EnvVP[envPos][1] & 0x00FF) * 256);

                            envPos++;

                            envUpdate = 0;
                            break;
                        }

                        envPos++;
                    }

                    if (envUpdate) envPos--;
                }

                if (envUpdate)
                {
                    ch.EnvVIPValue = 0;
                    ch.EnvVAmp = (ch.InstrSeg.EnvVP[envPos][1] & 0x00FF) * 256;
                }

                if (envPos >= ch.InstrSeg.EnvVPAnt)
                    envPos = (int16_t)(ch.InstrSeg.EnvVPAnt) - 1;

                ch.EnvVPos = (envPos < 0) ? 0 : (uint8_t)(envPos);
            }

            //*** PANNING ENVELOPE ***
            if (ch.InstrSeg.EnvVTyp & 2) //probably an FT2 bug
            {
                ch.EnvPCnt = ch.Eff - 1;

                envPos    = 0;
                envUpdate = 1;
                newEnvPos = ch.Eff;

                if (ch.InstrSeg.EnvPPAnt > 1)
                {
                    envPos++;
                    for (i = 0; i < ch.InstrSeg.EnvPPAnt; ++i)
                    {
                        if (newEnvPos < ch.InstrSeg.EnvPP[envPos][0])
                        {
                            envPos--;

                            newEnvPos -= ch.InstrSeg.EnvPP[envPos][0];
                            if (newEnvPos == 0)
                            {
                                envUpdate = 0;
                                break;
                            }

                            if (ch.InstrSeg.EnvPP[envPos + 1][0] <= ch.InstrSeg.EnvPP[envPos][0])
                            {
                                envUpdate = 1;
                                break;
                            }

                            ch.EnvPIPValue = ((ch.InstrSeg.EnvPP[envPos + 1][1] - ch.InstrSeg.EnvPP[envPos][1]) & 0x00FF) * 256;
                            ch.EnvPIPValue /= (ch.InstrSeg.EnvPP[envPos + 1][0] - ch.InstrSeg.EnvPP[envPos][0]);

                            ch.EnvPAmp = (ch.EnvPIPValue * (newEnvPos - 1)) + ((ch.InstrSeg.EnvPP[envPos][1] & 0x00FF) * 256);

                            envPos++;

                            envUpdate = 0;
                            break;
                        }

                        envPos++;
                    }

                    if (envUpdate) envPos--;
                }

                if (envUpdate)
                {
                    ch.EnvPIPValue = 0;
                    ch.EnvPAmp = (ch.InstrSeg.EnvPP[envPos][1] & 0x00FF) * 256;
                }

                if (envPos >= ch.InstrSeg.EnvPPAnt)
                    envPos = (int16_t)(ch.InstrSeg.EnvPPAnt) - 1;

                ch.EnvPPos = (envPos < 0) ? 0 : (uint8_t)(envPos);
            }
        }

        //Rxy - note multi retrigger
        else if (ch.EffTyp == 27)
        {
            tmpEff = ch.Eff & 0x0F;
            if (!tmpEff)
                tmpEff = ch.RetrigSpeed;

            ch.RetrigSpeed = tmpEff;

            tmpEffHi = ch.Eff >> 4;
            if (!tmpEffHi)
                tmpEffHi = ch.RetrigVol;

            ch.RetrigVol = tmpEffHi;

            if (!ch.VolKolVol) MultiRetrig(ch);
        }

        //X1x - extra fine period slide up
        else if ((ch.EffTyp == 33) && ((ch.Eff & 0xF0) == 0x10))
        {
            tmpEff = ch.Eff & 0x0F;
            if (!tmpEff)
                tmpEff = ch.EPortaUpSpeed;

            ch.EPortaUpSpeed = tmpEff;

            ch.RealPeriod -= tmpEff;
            if (ch.RealPeriod < 1) ch.RealPeriod = 1;

            ch.OutPeriod = ch.RealPeriod;
            ch.Status   |= IS_Period;
        }

        //X2x - extra fine period slide down
        else if ((ch.EffTyp == 33) && ((ch.Eff & 0xF0) == 0x20))
        {
            tmpEff = ch.Eff & 0x0F;
            if (!tmpEff)
                tmpEff = ch.EPortaDownSpeed;

            ch.EPortaDownSpeed = tmpEff;

            ch.RealPeriod += tmpEff;
            if (ch.RealPeriod > (32000 - 1)) ch.RealPeriod = 32000 - 1;

            ch.OutPeriod = ch.RealPeriod;
            ch.Status   |= IS_Period;
        }
    }
    
private function fixTonePorta(ch:StmTyp, p:TonTyp, inst:uint):void
{
    var portaTmp:uint;  //uint16_t
    var tmpFTune:uint;  //uint8_t

    if (p.Ton)
    {
        if (p.Ton == 97)
        {
            KeyOff(ch);
        }
        else
        {
            //"arithmetic shift right" on signed number simulation
            if (ch.FineTune >= 0)
                tmpFTune = ch.FineTune / (1 << 3);
            else
                //TODO
                tmpFTune = 0xE0 | ((uint8_t)(ch.FineTune) >> 3); //0xE0 = 2^8 - 2^(8-3)

            portaTmp = ((((p.Ton - 1) + ch.RelTonNr) & 0x00FF) * 16) + ((tmpFTune + 16) & 0x00FF);

            if (portaTmp < ((12 * 10 * 16) + 16))
            {
                ch.WantPeriod = Note2Period[portaTmp];

                     if (ch.WantPeriod == ch.RealPeriod) ch.PortaDir = 0;
                else if (ch.WantPeriod  > ch.RealPeriod) ch.PortaDir = 1;
                else                                       ch.PortaDir = 2;
            }
        }
    }

    if (inst)
    {
        RetrigVolume(ch);

        if (p.Ton != 97)
            RetrigEnvelopeVibrato(ch);
    }
}

    private function GetNewNote(ch:StmTyp, p:TonTyp):void
    {
        uint8_t inst;

        ch.VolKolVol = p.Vol;

        if (!ch.EffTyp)
        {
            if (ch.Eff)
            {
                //we have an arpeggio running, set period back
                ch.OutPeriod = ch.RealPeriod;
                ch.Status   |= IS_Period;
            }
        }
        else
        {
            if ((ch.EffTyp == 4) || (ch.EffTyp == 6))
            {
                //we have a vibrato running
                if ((p.EffTyp != 4) && (p.EffTyp != 6))
                {
                    //but it's ending at the next (this) row, so set period back
                    ch.OutPeriod = ch.RealPeriod;
                    ch.Status   |= IS_Period;
                }
            }
        }

        ch.EffTyp = p.EffTyp;
        ch.Eff    = p.Eff;
        ch.ToneType = (p.Instr << 8) | p.Ton;

        //'inst' var is used for later if checks...
        inst = p.Instr;
        if (inst)
        {
            if ((Song.AntInstrs > 128) || (inst <= 128)) //>128 insnum hack
                ch.InstrNr = inst;
            else
                inst = 0;
        }

        if (p.EffTyp == 0x0E)
        {
            if ((p.Eff >= 0xD1) && (p.Eff <= 0xDF))
                return; //we have a note delay (ED1..EDF)
        }

        if (!((p.EffTyp == 0x0E) && (p.Eff == 0x90))) //E90 is 'retrig' speed 0
        {
            if ((ch.VolKolVol & 0xF0) == 0xF0) //gxx
            {
                if (ch.VolKolVol & 0x0F)
                    ch.PortaSpeed = (ch.VolKolVol & 0x0F) * 64;

                fixTonePorta(ch, p, inst);

                CheckEffects(ch);
                return;
            }

            if ((p.EffTyp == 3) || (p.EffTyp == 5)) //3xx or 5xx
            {
                if ((p.EffTyp != 5) && p.Eff)
                    ch.PortaSpeed = p.Eff * 4;

                fixTonePorta(ch, p, inst);

                CheckEffects(ch);
                return;
            }

            if ((p.EffTyp == 0x14) && !p.Eff) //K00 (KeyOff)
            {
                KeyOff(ch);

                if (inst)
                    RetrigVolume(ch);

                CheckEffects(ch);
                return;
            }

            if (!p.Ton)
            {
                if (inst)
                {
                    RetrigVolume(ch);
                    RetrigEnvelopeVibrato(ch);
                }

                CheckEffects(ch);
                return;
            }
        }

        if (p.Ton == 97)
            KeyOff(ch);
        else
            StartTone(p.Ton, p.EffTyp, p.Eff, ch);

        if (inst)
        {
            RetrigVolume(ch);

            if (p.Ton != 97)
                RetrigEnvelopeVibrato(ch);
        }

        CheckEffects(ch);
    }

private function FixaEnvelopeVibrato(ch:StmTyp):void
{
//TODO: nested arrays to single array
    var envVal:uint;            //uint16_t
    var envPos;                 //uint8_t
    var envInterpolateFlag;     //int8_t
    var envDidInterpolate;      //int8_t
    var autoVibTmp;             //int16_t

    //*** FADEOUT ***
    if (!ch.EnvSustainActive)
    {
        ch.Status |= IS_Vol;

        ch.FadeOutAmp -= ch.FadeOutSpeed;
        if (ch.FadeOutAmp <= 0)
        {
            ch.FadeOutAmp   = 0;
            ch.FadeOutSpeed = 0;
        }
    }

    if (!ch.Mute)
    {
        //*** VOLUME ENVELOPE ***
        envInterpolateFlag = 1;
        envDidInterpolate  = 0;

        envVal = 0;

        if (ch.InstrSeg.EnvVTyp & 1)
        {
            envPos = ch.EnvVPos;

            ch.EnvVCnt++;
            if (ch.EnvVCnt == ch.InstrSeg.EnvVP[envPos][0])
            {
                ch.EnvVAmp = (ch.InstrSeg.EnvVP[envPos][1] & 0x00FF) * 256;

                envPos++;
                if (ch.InstrSeg.EnvVTyp & 4)
                {
                    envPos--;

                    if (envPos == ch.InstrSeg.EnvVRepE)
                    {
                        if (!(ch.InstrSeg.EnvVTyp & 2) || (envPos != ch.InstrSeg.EnvVSust) || ch.EnvSustainActive)
                        {
                            envPos = ch.InstrSeg.EnvVRepS;

                            ch.EnvVCnt =  ch.InstrSeg.EnvVP[envPos][0];
                            ch.EnvVAmp = (ch.InstrSeg.EnvVP[envPos][1] & 0x00FF) * 256;
                        }
                    }

                    envPos++;
                }

                ch.EnvVIPValue = 0;

                if (envPos < ch.InstrSeg.EnvVPAnt)
                {
                    if ((ch.InstrSeg.EnvVTyp & 2) && ch.EnvSustainActive)
                    {
                        envPos--;

                        if (envPos == ch.InstrSeg.EnvVSust)
                            envInterpolateFlag = 0;
                        else
                            envPos++;
                    }

                    if (envInterpolateFlag)
                    {
                        ch.EnvVPos = envPos;

                        if (ch.InstrSeg.EnvVP[envPos][0] > ch.InstrSeg.EnvVP[envPos - 1][0])
                        {
                            ch.EnvVIPValue = ((ch.InstrSeg.EnvVP[envPos][1] - ch.InstrSeg.EnvVP[envPos - 1][1]) & 0x00FF) * 256;
                            ch.EnvVIPValue /= (ch.InstrSeg.EnvVP[envPos][0] - ch.InstrSeg.EnvVP[envPos - 1][0]);

                            envVal = ch.EnvVAmp;
                            envDidInterpolate = 1;
                        }
                    }
                }
            }

            if (!envDidInterpolate)
            {
                ch.EnvVAmp += ch.EnvVIPValue;

                envVal = ch.EnvVAmp;
                if ((envVal & 0xFF00) > 16384)
                {
                    ch.EnvVIPValue = 0;
                    envVal = ((envVal & 0xFF00) > 32768) ? 0 : 16384;
                }
            }

            ch.FinalVol  =  (ch.OutVol) / 64.0;
            ch.FinalVol *= ((ch.FadeOutAmp) / 65536.0);
            ch.FinalVol *= ((envVal / 256) / 64.0);
            ch.FinalVol *= ((Song.GlobVol) / 64.0);

            ch.Status |= IS_Vol;
        }
        else
        {
            ch.FinalVol  =  (ch.OutVol) / 64.0;
            ch.FinalVol *= ((ch.FadeOutAmp) / 65536.0);
            ch.FinalVol *= ((Song.GlobVol) / 64.0);
        }
    }
    else
    {
        ch.FinalVol = 0;
    }

    //*** PANNING ENVELOPE ***
    envInterpolateFlag = 1;
    envDidInterpolate  = 0;

    envVal = 0;

    if (ch.InstrSeg.EnvPTyp & 1)
    {
        envPos = ch.EnvPPos;

        ch.EnvPCnt++;
        if (ch.EnvPCnt == ch.InstrSeg.EnvPP[envPos][0])
        {
            ch.EnvPAmp = (ch.InstrSeg.EnvPP[envPos][1] & 0x00FF) * 256;

            envPos++;
            if (ch.InstrSeg.EnvPTyp & 4)
            {
                envPos--;

                if (envPos == ch.InstrSeg.EnvPRepE)
                {
                    if (!(ch.InstrSeg.EnvPTyp & 2) || (envPos != ch.InstrSeg.EnvPSust) || ch.EnvSustainActive)
                    {
                        envPos = ch.InstrSeg.EnvPRepS;

                        ch.EnvPCnt =  ch.InstrSeg.EnvPP[envPos][0];
                        ch.EnvPAmp = (ch.InstrSeg.EnvPP[envPos][1] & 0x00FF) * 256;
                    }
                }

                envPos++;
            }

            ch.EnvPIPValue = 0;

            if (envPos < ch.InstrSeg.EnvPPAnt)
            {
                if ((ch.InstrSeg.EnvPTyp & 2) && ch.EnvSustainActive)
                {
                    envPos--;

                    if (envPos == ch.InstrSeg.EnvPSust)
                        envInterpolateFlag = 0;
                    else
                        envPos++;
                }

                if (envInterpolateFlag)
                {
                    ch.EnvPPos = envPos;

                    if (ch.InstrSeg.EnvPP[envPos][0] > ch.InstrSeg.EnvPP[envPos - 1][0])
                    {
                        ch.EnvPIPValue = ((ch.InstrSeg.EnvPP[envPos][1] - ch.InstrSeg.EnvPP[envPos - 1][1]) & 0x00FF) * 256;
                        ch.EnvPIPValue /= (ch.InstrSeg.EnvPP[envPos][0] - ch.InstrSeg.EnvPP[envPos - 1][0]);

                        envVal = ch.EnvPAmp;
                        envDidInterpolate = 1;
                    }
                }
            }
        }

        if (!envDidInterpolate)
        {
            ch.EnvPAmp += ch.EnvPIPValue;

            envVal = ch.EnvPAmp;
            if ((envVal & 0xFF00) > 16384)
            {
                ch.EnvPIPValue = 0;
                envVal = ((envVal & 0xFF00) > 32768) ? 0 : 16384;
            }
        }

        //TODO: int16_t -> uint8_t
        ch.FinalPan  = (uint8_t)(ch.OutPan);
        ch.FinalPan += (((envVal / 256) - 32) * (128 - Math.abs(ch.OutPan - 128)) / 32);

        ch.Status |= IS_Vol;
    }
    else
    {
        ch.FinalPan = (uint8_t)(ch.OutPan);
    }

    //*** AUTO VIBRATO ***
    if (ch.InstrSeg.VibDepth)
    {
        if (ch.EVibSweep)
        {
            if (ch.EnvSustainActive)
            {
                ch.EVibAmp += ch.EVibSweep;
                if ((ch.EVibAmp / 256) > ch.InstrSeg.VibDepth)
                {
                    ch.EVibAmp   = ch.InstrSeg.VibDepth * 256;
                    ch.EVibSweep = 0;
                }
            }
        }

        //square
        if (ch.InstrSeg.VibTyp == 1)
            autoVibTmp = (ch.EVibPos > 127) ? 64 : -64;

        //ramp up
        else if (ch.InstrSeg.VibTyp == 2)
            autoVibTmp = (((ch.EVibPos / 2) + 64) & 127) - 64;

        //ramp down
        else if (ch.InstrSeg.VibTyp == 3)
            autoVibTmp = (((0 - (ch.EVibPos / 2)) + 64) & 127) - 64;

        //sine
        else
            autoVibTmp = VibSineTab[ch.EVibPos];

        ch.FinalPeriod = ch.OutPeriod + ((autoVibTmp * ch.EVibAmp) / 16384);
        if (ch.FinalPeriod > (32000 - 1)) ch.FinalPeriod = 0; //yes, FT2 zeroes it out

        ch.Status  |= IS_Period;
        ch.EVibPos += ch.InstrSeg.VibRate;
    }
    else
    {
        ch.FinalPeriod = ch.OutPeriod;
    }
}
    
private function RelocateTon(inPeriod:int, int8_t addNote:int, ch:StmTyp):int
{
    var i:int;          //int8_t
    var fineTune:int;   //int8_t

    var oldPeriod:int;  //int16_t
    var addPeriod:int;  //int16_t

    var outPeriod:int;  //int32_t

    oldPeriod = 0;
    addPeriod = (8 * 12 * 16) * 2;

    //"arithmetic shift right" on signed number simulation
    if (ch.FineTune >= 0)
        fineTune = ch.FineTune / (1 << 3);
    else
        //TODO
        fineTune = 0xE0 | ((uint8_t)(ch.FineTune) >> 3); //0xE0 = 2^8 - 2^(8-3)

    fineTune *= 2;

    for (i = 0; i < 8; ++i)
    {
        outPeriod = (((oldPeriod + addPeriod) / 2) & 0xFFE0) + fineTune;
        if (outPeriod < fineTune)
            outPeriod += (1 << 8);

        if (outPeriod < 16)
            outPeriod = 16;

        if (inPeriod >= Note2Period[(outPeriod - 16) / 2])
        {
            outPeriod -= fineTune;
            if (outPeriod & 0x00010000)
                outPeriod = (outPeriod - (1 << 8)) & 0x0000FFE0;

                //TODO
            addPeriod = (int16_t)(outPeriod);
        }
        else
        {
            outPeriod -= fineTune;
            if (outPeriod & 0x00010000)
                outPeriod = (outPeriod - (1 << 8)) & 0x0000FFE0;

                //TODO
            oldPeriod = (int16_t)(outPeriod);
        }
    }

    outPeriod = oldPeriod + fineTune;
    if (outPeriod < fineTune)
        outPeriod += (1 << 8);

    if (outPeriod < 0)
        outPeriod = 0;

    outPeriod += (addNote * 32);
    if (outPeriod >= ((((8 * 12 * 16) + 15) * 2) - 1))
        outPeriod = ((8 * 12 * 16) + 15) * 2;

    return (Note2Period[outPeriod / 2]); //16-bit look-up, shift it down
}

    private function TonePorta(ch:StmTyp):void
    {
        if (ch.PortaDir)
        {
            if (ch.PortaDir > 1)
            {
                ch.RealPeriod -= ch.PortaSpeed;
                if (ch.RealPeriod <= ch.WantPeriod)
                {
                    ch.PortaDir   = 1;
                    ch.RealPeriod = ch.WantPeriod;
                }
            }
            else
            {
                ch.RealPeriod += ch.PortaSpeed;
                if (ch.RealPeriod >= ch.WantPeriod)
                {
                    ch.PortaDir   = 1;
                    ch.RealPeriod = ch.WantPeriod;
                }
            }

            if (ch.GlissFunk) //semi-tone slide flag
                ch.OutPeriod = RelocateTon(ch.RealPeriod, 0, ch);
            else
                ch.OutPeriod = ch.RealPeriod;

            ch.Status |= IS_Period;
        }
    }

    private function Volume(ch:StmTyp):void //actually volume slide
    {
        var tmpEff:uint;    //uint8_t

        tmpEff = ch.Eff;
        if (!tmpEff)
            tmpEff = ch.VolSlideSpeed;

        ch.VolSlideSpeed = tmpEff;

        if (!(tmpEff & 0xF0))
        {
            ch.RealVol -= tmpEff;
            if (ch.RealVol < 0) ch.RealVol = 0;
        }
        else
        {
            ch.RealVol += (tmpEff >> 4);
            if (ch.RealVol > 64) ch.RealVol = 64;
        }

        ch.OutVol  = ch.RealVol;
        ch.Status |= IS_Vol;
    }

    private function Vibrato2(ch:StmTyp):void
    {
        var tmpVib:uint;    //uint8_t

        tmpVib = (ch.VibPos / 4) & 0x1F;

        switch (ch.WaveCtrl & 0x03)
        {
            //0: sine
            case 0:
                tmpVib = VibTab[tmpVib];
                break;
            //1: ramp
            case 1:
                tmpVib *= 8;
                if (ch.VibPos >= 128) tmpVib ^= 0xFF;
                break;
            //2/3: square
            default:
                tmpVib = 255;
                break;
        }

        tmpVib = (tmpVib * ch.VibDepth) / 32;

        if (ch.VibPos >= 128)
            ch.OutPeriod = ch.RealPeriod - tmpVib;
        else
            ch.OutPeriod = ch.RealPeriod + tmpVib;

        ch.Status |= IS_Period;
        ch.VibPos += ch.VibSpeed;
    }

    private function Vibrato(ch:StmTyp):void
    {
        if (ch.Eff)
        {
            if (ch.Eff & 0x0F) ch.VibDepth = ch.Eff & 0x0F;
            if (ch.Eff & 0xF0) ch.VibSpeed = (ch.Eff >> 4) * 4;
        }

        Vibrato2(ch);
    }
    
    private function DoEffects(ch:StmTyp):void
    {
        var note:int;           //int8_t
        var tmpEff:uint;        //uint8_t
        var tremorData:uint;    //uint8_t
        var tremorSign:uint;    //uint8_t
        var tmpTrem:uint;       //uint8_t
        var i:uint;             //uint16_t
        var tick:uint;          //uint16_t

        //*** VOLUME COLUMN EFFECTS (TICKS >0) ***

        //volume slide down
        if ((ch.VolKolVol & 0xF0) == 0x60)
        {
            ch.RealVol -= (ch.VolKolVol & 0x0F);
            if (ch.RealVol < 0) ch.RealVol = 0;

            ch.OutVol  = ch.RealVol;
            ch.Status |= IS_Vol;
        }

        //volume slide up
        else if ((ch.VolKolVol & 0xF0) == 0x70)
        {
            ch.RealVol += (ch.VolKolVol & 0x0F);
            if (ch.RealVol > 64) ch.RealVol = 64;

            ch.OutVol  = ch.RealVol;
            ch.Status |= IS_Vol;
        }

        //vibrato (+ set vibrato depth)
        else if ((ch.VolKolVol & 0xF0) == 0xB0)
        {
            if (ch.VolKolVol != 0xB0)
                ch.VibDepth = ch.VolKolVol & 0x0F;

            Vibrato2(ch);
        }

        //pan slide left
        else if ((ch.VolKolVol & 0xF0) == 0xD0)
        {
            ch.OutPan -= (ch.VolKolVol & 0x0F);
            if (ch.OutPan < 0) ch.OutPan = 0;

            ch.Status |= IS_Vol;
        }

        //pan slide right
        else if ((ch.VolKolVol & 0xF0) == 0xE0)
        {
            ch.OutPan += (ch.VolKolVol & 0x0F);
            if (ch.OutPan > 255) ch.OutPan = 255;

            ch.Status |= IS_Vol;
        }

        //tone portamento
        else if ((ch.VolKolVol & 0xF0) == 0xF0) TonePorta(ch);

        //*** MAIN EFFECTS (TICKS >0) ***

        if (((ch.Eff == 0) && (ch.EffTyp == 0)) || (ch.EffTyp >= 36)) return;

        //0xy - Arpeggio
        if (ch.EffTyp == 0)
        {
            tick = Song.Timer;
            note = 0;

            //FT2 'out of boundary' arp LUT simulation
                 if (tick  > 16) tick  = 2;
            else if (tick == 15) tick  = 0;
            else                 tick %= 3;


            //this simulation doesn't work properly for >=128 tick arps,
            //but you'd need to hexedit the initial speed to get >31
           
            if (!tick)
            {
                ch.OutPeriod = ch.RealPeriod;
            }
            else
            {
                     if (tick == 1) note = ch.Eff >> 4;
                else if (tick == 2) note = ch.Eff & 0x0F;

                ch.OutPeriod = RelocateTon(ch.RealPeriod, note, ch);
            }

            ch.Status |= IS_Period;
        }

        //1xx - period slide up
        else if (ch.EffTyp == 1)
        {
            tmpEff = ch.Eff;
            if (!tmpEff)
                tmpEff = ch.PortaUpSpeed;

            ch.PortaUpSpeed = tmpEff;

            ch.RealPeriod -= (tmpEff * 4);
            if (ch.RealPeriod < 1) ch.RealPeriod = 1;

            ch.OutPeriod = ch.RealPeriod;
            ch.Status   |= IS_Period;
        }

        //2xx - period slide up
        else if (ch.EffTyp == 2)
        {
            tmpEff = ch.Eff;
            if (!tmpEff)
                tmpEff = ch.PortaUpSpeed;

            ch.PortaUpSpeed = tmpEff;

            ch.RealPeriod += (tmpEff * 4);
            if (ch.RealPeriod > (32000 - 1)) ch.RealPeriod = 32000 - 1;

            ch.OutPeriod = ch.RealPeriod;
            ch.Status   |= IS_Period;
        }

        //3xx - tone portamento
        else if (ch.EffTyp == 3) TonePorta(ch);

        //4xy - vibrato
        else if (ch.EffTyp == 4) Vibrato(ch);

        //5xy - tone portamento + volume slide
        else if (ch.EffTyp == 5)
        {
            TonePorta(ch);
            Volume(ch);
        }

        //6xy - vibrato + volume slide
        else if (ch.EffTyp == 6)
        {
            Vibrato2(ch);
            Volume(ch);
        }

        //7xy - tremolo
        else if (ch.EffTyp == 7)
        {
            tmpEff = ch.Eff;
            if (tmpEff)
            {
                if (tmpEff & 0x0F) ch.TremDepth = tmpEff & 0x0F;
                if (tmpEff & 0xF0) ch.TremSpeed = (tmpEff >> 4) * 4;
            }

            tmpTrem = (ch.TremPos / 4) & 0x1F;

            switch ((ch.WaveCtrl >> 4) & 3)
            {
                //0: sine
                case 0:
                    tmpTrem = VibTab[tmpTrem];
                    break;
                //1: ramp
                case 1:
                    tmpTrem *= 8;
                    if (ch.VibPos >= 128) tmpTrem ^= 0xFF; //FT2 bug, should've been TremPos
                    break;
                //2/3: square
                default:
                    tmpTrem = 255;
                    break;
            }

            tmpTrem = (tmpTrem * ch.TremDepth) / 64;

            if (ch.TremPos >= 128)
            {
                ch.OutVol = ch.RealVol - tmpTrem;
                if (ch.OutVol < 0) ch.OutVol = 0;
            }
            else
            {
                ch.OutVol = ch.RealVol + tmpTrem;
                if (ch.OutVol > 64) ch.OutVol = 64;
            }

            ch.TremPos += ch.TremSpeed;

            ch.Status |= IS_Vol;
        }

        //Axy - volume slide
        else if (ch.EffTyp == 10) Volume(ch); //actually volume slide

        //Exy - E effects
        else if (ch.EffTyp == 14)
        {
            //E9x - note retrigger
            if ((ch.Eff & 0xF0) == 0x90)
            {
                if (ch.Eff != 0x90) //E90 is handled in GetNewNote()
                {
                    if (!((Song.Tempo - Song.Timer) % (ch.Eff & 0x0F)))
                    {
                        StartTone(0, 0, 0, ch);
                        RetrigEnvelopeVibrato(ch);
                    }
                }
            }

            //ECx - note cut
            else if ((ch.Eff & 0xF0) == 0xC0)
            {
                if (((Song.Tempo - Song.Timer) & 0x00FF) == (ch.Eff & 0x0F))
                {
                    ch.OutVol  = 0;
                    ch.RealVol = 0;
                    ch.Status |= IS_Vol;
                }
            }

            //EDx - note delay
            else if ((ch.Eff & 0xF0) == 0xD0)
            {
                if (((Song.Tempo - Song.Timer) & 0x00FF) == (ch.Eff & 0x0F))
                {
                    StartTone(ch.ToneType & 0x00FF, 0, 0, ch);

                    if (ch.ToneType & 0xFF00)
                        RetrigVolume(ch);

                    RetrigEnvelopeVibrato(ch);

                    if ((ch.VolKolVol >= 0x10) && (ch.VolKolVol <= 0x50))
                    {
                        ch.OutVol  = ch.VolKolVol - 16;
                        ch.RealVol = ch.OutVol;
                    }
                    else if ((ch.VolKolVol >= 0xC0) && (ch.VolKolVol <= 0xCF))
                    {
                        ch.OutPan = (ch.VolKolVol & 0x0F) * 16;
                    }
                }
            }
        }

        //Hxy - global volume slide
        else if (ch.EffTyp == 17)
        {
            tmpEff = ch.Eff;
            if (!tmpEff)
                tmpEff = ch.GlobVolSlideSpeed;

            ch.GlobVolSlideSpeed = tmpEff;

            if (!(tmpEff & 0xF0))
            {
                Song.GlobVol -= tmpEff;
                if (Song.GlobVol < 0) Song.GlobVol = 0;
            }
            else
            {
                Song.GlobVol += (tmpEff >> 4);
                if (Song.GlobVol > 64) Song.GlobVol = 64;
            }

            for (i = 0; i < Song.AntChn; ++i)
                Stm[i].Status |= IS_Vol;
        }

        //Kxx - key off
        else if (ch.EffTyp == 20)
        {
            if (((Song.Tempo - Song.Timer) & 31) == (ch.Eff & 0x0F))
                KeyOff(ch);
        }

        //Pxy - panning slide
        else if (ch.EffTyp == 25)
        {
            tmpEff = ch.Eff;
            if (!tmpEff)
                tmpEff = ch.PanningSlideSpeed;

            ch.PanningSlideSpeed = tmpEff;

            if (!(ch.Eff & 0xF0))
            {
                ch.OutPan += (ch.Eff >> 4);
                if (ch.OutPan > 255) ch.OutPan = 255;
            }
            else
            {
                ch.OutPan -= (ch.Eff & 0x0F);
                if (ch.OutPan < 0) ch.OutPan = 0;
            }

            ch.Status |= IS_Vol;
        }

        //Rxy - multi note retrig
        else if (ch.EffTyp == 27) MultiRetrig(ch);

        //Txy - tremor
        else if (ch.EffTyp == 29)
        {
            tmpEff = ch.Eff;
            if (!tmpEff)
                tmpEff = ch.TremorSave;

            ch.TremorSave = tmpEff;

            tremorSign = ch.TremorPos & 0x80;
            tremorData = ch.TremorPos & 0x7F;

            tremorData--;
            if (tremorData & 0x80)
            {
                if (tremorSign == 0x80)
                {
                    tremorSign = 0x00;
                    tremorData = tmpEff & 0x0F;
                }
                else
                {
                    tremorSign = 0x80;
                    tremorData = tmpEff >> 4;
                }
            }

            ch.TremorPos = tremorData | tremorSign;

            ch.OutVol  = tremorSign ? ch.RealVol : 0;
            ch.Status |= IS_Vol;
        }
    }
    
void MainPlayer(void) //periodically called from mixer
{
    //TODO: memcpy shenanigans
    var ch:StmTyp;      //*StmTyp
    var s:SampleTyp;    //SampleTyp

    var tickzero:int;   //int8_t
    var i:uint;         //uint8_t
    var chNr:uint;      //uint8_t

    if (!MusicPaused && Playing)
    {
        tickzero = 0;

        if (--Song.Timer == 0)
        {
            Song.Timer = Song.Tempo;
            tickzero   = 1;
        }

        if (tickzero)
        {
            if (!Song.PattDelTime)
            {
                for (i = 0; i < Song.AntChn; ++i)
                {
                    if (Patt[Song.PattNr])
                    //TODO convert to offset
                        GetNewNote(&Stm[i], &Patt[Song.PattNr][(Song.PattPos * MAX_VOICES) + i]);
                    else
                        GetNewNote(&Stm[i], &NilPatternLine[(Song.PattPos * MAX_VOICES) + i]);

                    FixaEnvelopeVibrato(Stm[i]);
                }
            }
            else
            {
                for (i = 0; i < Song.AntChn; ++i)
                {
                    DoEffects(Stm[i]);
                    FixaEnvelopeVibrato(Stm[i]);
                }
            }
        }
        else
        {
            for (i = 0; i < Song.AntChn; ++i)
            {
                DoEffects(Stm[i]);
                FixaEnvelopeVibrato(Stm[i]);
            }
        }

        if (Song.Timer == 1)
        {
            Song.PattPos++;

            if (Song.PattDelTime)
            {
                Song.PattDelTime2 = Song.PattDelTime;
                Song.PattDelTime  = 0;
            }

            if (Song.PattDelTime2)
            {
                Song.PattDelTime2--;
                if (Song.PattDelTime2) Song.PattPos--;
            }

            if (Song.PBreakFlag)
            {
                Song.PBreakFlag = 0;
                Song.PattPos    = Song.PBreakPos;
            }

            if ((Song.PattPos >= Song.PattLen) || Song.PosJumpFlag)
            {
                Song.PattPos     = Song.PBreakPos;
                Song.PBreakPos   = 0;
                Song.PosJumpFlag = 0;

                Song.SongPos++;
                if (Song.SongPos >= Song.Len)
                    Song.SongPos  = Song.RepS;

                Song.PattNr  = Song.SongTab[Song.SongPos];
                Song.PattLen = PattLens[Song.PattNr];
            }
        }
    }
    else
    {
        for (i = 0; i < Song.AntChn; ++i)
            FixaEnvelopeVibrato(Stm[i]);
    }

    //update mixer
    for (i = 0; i < Song.AntChn; ++i)
    {
        ch   = Stm[i];
        chNr = ch.Nr;

        if (ch.Status & IS_NyTon)
        {
            ch.InstrOfs.MCPY_to(s);

/*//#ifdef USE_VOL_RAMP
            if (voiceIsActive(chNr))
            {
                memcpy(voice + SPARE_OFFSET + chNr, voice + chNr, sizeof (VOICE));

                voice[SPARE_OFFSET + chNr].faderDest  = 0.0f;
                voice[SPARE_OFFSET + chNr].faderDelta =
                    (voice[SPARE_OFFSET + chNr].faderDest - voice[SPARE_OFFSET + chNr].fader) * f_samplesPerFrame010;
            }
*///#endif
            voiceSetSource(chNr, s.Pek, s.Len, s.RepL, s.RepS + s.RepL, s.Typ & 3, s.Typ & 16, s.Typ & 32);
            voiceSetSamplePosition(chNr, ch.SmpStartPos);

/*//#ifdef USE_VOL_RAMP
            voice[chNr].fader      = 0.0f;
            voice[chNr].faderDest  = 1.0f;
            voice[chNr].faderDelta = (voice[chNr].faderDest - voice[chNr].fader) * f_samplesPerFrame005;
*///#endif
        }

        if (ch.Status & IS_Vol)
            voiceSetVolume(chNr, ch.FinalVol, ch.FinalPan);

        if (ch.Status & IS_Period)
            voiceSetSamplingFrequency(chNr, GetFrequenceValue(ch.FinalPeriod));

        ch.Status = 0;
    }
}
    
    private function StopVoices(void)
    {
        var i:uint;     //uint8_t
        var ch:StmTyp;  //*StmTyp

        for (i = 0; i < MAX_VOICES; ++i)
        {
            voice[i].MSET_to0();
            Stm[i].MSET_to0();
        }

        for (i = 0; i < MAX_VOICES; ++i)
        {
            ch = Stm[i];

            ch.Nr       = i;
            ch.ToneType = 0;
            ch.RelTonNr = 0;
            ch.InstrNr  = 0;
            Instr[0].MCPY_to(ch.InstrSeg);
            ch.Status   = IS_Vol;
            ch.RealVol  = 0;
            ch.OutVol   = 0;
            ch.OldVol   = 0;
            ch.FinalVol = 0.0;
            ch.OldPan   = 128;
            ch.OutPan   = 128;
            ch.FinalPan = 128;
            ch.VibDepth = 0;

            voiceSetVolume(i, ch.FinalVol, ch.FinalPan);
        }
    }


    
    
}

}