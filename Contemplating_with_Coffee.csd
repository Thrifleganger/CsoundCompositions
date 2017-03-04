;Contemplating with coffee
;Written by Thrifleganger

<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 128
nchnls = 2
0dbfs = 1.0

;GlobalVariables:
gaSendL,gaSendR		init	0
giBTempo = .5

;Instrument List:
giChumeTrig		=	1
giBassDrumTrig	=	2
giRumbleTrig	=	3
giChimeInstr	=	10	
giWind			=	11
giRain			=	12
giSoftPad		=	13
giEvolution		=	14
giBassDrumInstr	=	15
giRumbleInstr	=	16
giStrings		=	17
giChaosMachine	=	18
giRainDrop		=	19
giDropSplash	=	20
giReverb		=	99


;Global function tables:
giSawRaw	ftgen		0, 0, 131072, 7, -1, 131072, 1					
giSine		ftgen		0, 0, 131072, 10, 1
giCos		ftgen		0, 0, 131072, 11, 1
giBuzz		ftgen		0, 0, 131072, 11, 80, 1, 0.7
giSaw		ftgen		0, 0, 131072, 30, giSawRaw, 1, (sr/2)/1000
giHanning	ftgen		0, 0, 4096,   20, 2, 1	
giMorph		ftgen		0, 0, 131072,-10, 1
giTabNums	ftgen		0, 0, 2,     -2,  giBuzz, giSine


;Instrument for triggering wind chimes
instr 1
seed 0

iGain		=			p4
kLongEnv	expsegr		0.01, 10, 1, 10, .01
;Frequency table for wind chime note selection
iFNum		=			6
iOct		=			5
giFreqTab	ftgen		0, 0, -iFNum, -2, 244, 278, 312, 330, 371, 415

;Tracker is used for randomly picking values from giFreqTab
kTracker	random		-1, iFNum 		
kFreq		tab			kTracker, giFreqTab
;Two triggers are used since at any hit, atleast 2 chime bells are hit by the striker
kTracker2	random		-1, iFNum 		
kFreq2		tab			kTracker2, giFreqTab

;Rate of trigger of chime
iRateLow	=			.1	
iRateHigh	=			4
kRate 		rspline		iRateLow, iRateHigh, .2, 5

;Strength of chime (amplitude)
;A direct relationship exists between rate of chime trigger and its volume
;We calculate volume of chime by converting the range of rate to a volume range
iStrLow		=			-40
iStrHigh	=			-5
ioldRange 	= 			iRateHigh - iRateLow
inewRange 	= 			iStrHigh - iStrLow
kStrength 	= 			(((kRate - iRateLow)*inewRange) /ioldRange)+iStrLow

kFRatio		random		2, 3.5					;Frequency ratio ffor modulation
kDeviate	rspline		.05, .3, .2, 1			;Deviation time in seconds for the second trigger
kPan		random		0, 1					;Random pan values
kGain		=			ampdb(kStrength)*kLongEnv

kTrig		metro		kRate
if kTrig == 1 then
			;i  p1 			  p1 		p3 p4			p5		 p6					  p7
	event  	"i",giChimeInstr, 0, 		3, kFreq*iOct,	kFRatio, kGain * iGain,  	  kPan
	event 	"i",giChimeInstr, kDeviate, 2, kFreq2*iOct,	kFRatio, kGain * iGain * .25, kPan	;2nd hit is generally quieter
endif
endin

;Bass thump trigger
instr 2

;p4 - Gain
;p5 - Start gain
;p6 - Attack time
;p7 - End gain
;p8 - Hold time

iGain		=			p4
kVolEnv		linseg		p5, p6, p7, p8, p7
kAmp 		=			iGain * kVolEnv
kDur		=			3				

;Determine rate of trigger
iTempo		=			giBTempo
kTrig		metro		iTempo


if (kTrig == 1) then
			;				 p1				  p2 p3    p4
			event	 	"i", giBassDrumInstr, 0, kDur, kAmp 
endif
endin

;Bass rumble trigger
instr 3
;p4 - Pitch
;p5 - Start gain
;p6 - Attack time
;p7 - End gain
;p8 - Hold time

iPitch		=			p4
kLongEnv	linseg		p5, p6, p7, p8, p7

;Determine rate of trigger. Twice as long as bass drum kick.
iTempo		=			giBTempo
iTime		=			1/iTempo

kTrig		metro		iTempo/2
if (kTrig == 1) then
			;		    	 p1				p2 p3 p4  	  p5
			event	 	"i", giRumbleInstr, 0, 5, iPitch, kLongEnv
endif

endin


;Instrument for producing wind chime sounds
instr 10

;p4 - Frequency
;p5 - Modulation ratio of frequency
;p6 - Amplitude of hit
;p7 - Pan value
kFreq 		=			p4;
kIndex		expon		2, p3, .01
kFRatio		expon		2.7, p3, 2.7
kEnv		expon		1, p3, 0.01

;Frequency modulation to produce rich inharmoic sound
aMod		poscil		kFreq*kIndex, kFreq*kFRatio
aCarr		poscil		.2*kEnv*p6, kFreq + aMod

			out			aCarr*p7, aCarr*(1-p7)
endin

;Instrument for wind generation
instr 11
seed 0
iGain		=			p4
;Envelopes
kLongEnv	expsegr		0.01, 10, 1, 10, .01
kVolSwing	rspline		.2, 1, .1, .5

aPink		pinkish		.5 * iGain				;Pink noise for source
kSweep		rspline		100, 600, .1, .5		;Sweeping center frequency to simulate wind
aFilt		butbp		aPink, kSweep, 50		;Narrow band bass filter
aMix		=			(aFilt+aPink*.02)*kLongEnv*kVolSwing	;Some of the source is mixed in as background noise
			outs		aMix, aMix

endin

;Instrument for rain generation
instr 12
seed 0
iPan		=			.2
iGain		=			p4
aSig 		init		0

;Envelopes
kLongEnv	expsegr		0.01, 10, .7, 10, .5, 10, 0.01
kVolSwing	rspline		.2, 1, .1, .5		;Simulate volume changes

aNoise		rand		.8 * iGain			;Broadbank noise as source 	
aJitter		rspline		0, .3, 200, 500		;Irregularities in volume	
aFilt		butbp		aNoise, 1000, 500	;Filtering 2 high frequency bands 
aFilt2		butbp		aNoise, 2000, 600

aSig		=			aFilt*aJitter*kLongEnv*kVolSwing + aFilt2*aJitter*kLongEnv*.5*kVolSwing
			outs		aSig*iPan, aSig*(1-iPan)

			;Reverb send to smooth out the signal
kReverb		= 			.5
gaSendL		=			gaSendL + (aSig*iPan*kReverb)
gaSendR		=			gaSendR + (aSig*(1-iPan)*kReverb)

endin


;Soft drone pad
instr 13
seed 0

iFreq		=			cpspch(p4)
iPan		=			p5
iGain		=			p6

;Envelopes
kLongEnv	expsegr		0.01, 20, .5, 10, .001

kLFORate1	rspline		.1, .5, .2, .5
kLFORate2   rspline		.1, .6, .2, .5
kLFO1		poscil 		300, kLFORate1		;2 LFOs for filter frequency modulation
kLFO2		poscil		100, kLFORate2			

;3 closely related frequency oscilators mixed for natural beating
aPad1		poscil		0.8 * iGain, iFreq * 0.998, giSaw
aPad2		poscil		0.8 * iGain, iFreq * 1.002, giSaw
aPad3		poscil		0.7 * iGain, iFreq * 1.000, giBuzz
aMix		= 			aPad1 + aPad2 + aPad3

;Apply dynamic filtering
aMix		butlp		aMix, kLFO1 + 1000
aMix		buthp		aMix, kLFO2 + 200

aMix		*= 			kLongEnv 
			outs		aMix*iPan, aMix*(1-iPan)
			
			;Reverb send to smooth out the signal
kReverb		= 			.3
gaSendL		=			gaSendL + (aMix*iPan*kReverb)
gaSendR		=			gaSendR + (aMix*(1-iPan)*kReverb)

endin

;Evolution instrument

instr 14

seed 0 

iGain		=			p5
iFreq		=			cpsmidinn(p4)
kModifier 	= 			.1
kLevel 		= 			0.9
kPartials	=			30		;Determines the overall brightness of sound

kLongEnv 	expsegr 	.01, 20, .8, 20, .001

kVary		jspline		10,0.05,0.2			;Slight frequency randomness
kMultiply	rspline 	0.3,0.8,0.1,0.4		;Amplitude coefficient determines brightness in higher partials

aSig		gbuzz 		0.1, iFreq * cent(kVary), kPartials, 1, kMultiply^2, giCos
aSig 		buthp 		aSig, 100

aSig	=	aSig * kLevel * kLongEnv * iGain

;Randomly add delay to either Left or right channel 
iSide		random		0,1
iDelTim		random		0.001,0.1
if iSide > 0.5 then
  	aL			delay		aSig, iDelTim
  	aR			=			aSig
else
  	aR			delay		aSig, iDelTim
 	aL			=			aSig	
endif
			outs 		aL, aR
	
			;Reverb send to smooth out the signal
kReverb		= 			.5
gaSendL		=			gaSendL + (aL*kReverb)
gaSendR		=			gaSendR + (aR*kReverb)

endin

;Bass thump
instr 15

iAmp		=			p4
iDur		=			.5

;Morph between Sawtooth and Sine wave within each hit
kIndex		linseg		0, iDur, 1
			ftmorf 		kIndex, giTabNums, giMorph
			
;Envelopes
kVEnv		expseg		1, iDur, .2
kPEnv		linseg		1, .1, .2

;3 bass oscilators to add depth and low end power. Morph for grunge
aBass		poscil		1, 100*kPEnv, giMorph 
aBass2 		poscil		.4, 195*kPEnv, giMorph
aBass3		poscil		.5, 293*kPEnv

aMix		=			aBass + aBass2 + aBass3
aMix		butlp		aMix, 500	;Low pass for retaining on low frequencies
			outs		aMix * kVEnv * p4, aMix * kVEnv * p4		
endin

;Bass rumble
instr 16

;p4 - Pitch
;p5 - Gain

;Time between consequent bass drum hit
iTime		=			1/giBTempo
kGDurEnv	expseg		.04, iTime-.2, .17, .4, .04, 1, .04
kVolEnv		expseg		.01, iTime-1, .7, 1, .7,  .4, .01 

kPitch		=			p4
kDensity	=			230
kAmpOff		=			.3
kFreqOff	=			0

;Granular synthesis for getting hazy to gritty shift of sound by modulating grain duration
aOut 		grain 		.01, kPitch, kDensity, kAmpOff, kFreqOff, kGDurEnv, giBuzz, giHanning, 1, 0
aOut		buthp		aOut, 40
aout		butlp		aOut, 1000
			outs		aOut * kVolEnv * p5, aOut * kVolEnv * p5


endin

;Strings
instr 17

kLongEnv	expsegr		.01, 20, 1, 20, .001

kPitch 		=			cpsmidinn(p4)
kDensity	= 			3000
kAmpOff		=			.05
kFreqOff	=			3.2
kGDur		=			.08

;High density granular synthesis for generating rich strings. Slight freqoff for quiver
aOut 		grain 		.01, kPitch, kDensity, kAmpOff, kFreqOff, kGDur, giBuzz, giHanning, 1, 0

			outs	 	aOut * p5 * kLongEnv, aOut * p5 * kLongEnv

endin


;Chaos Machine
instr 18

kLongEnv	expsegr		.01, 6, 1, 10, .001

kPitch 		=			50
kDensity	= 			400
kAmpOff		=			.17
kGDur		=			.08
kFreqOff	linseg		48, 2, 48, p4, 1000 

;Granular synthesis with freqOff modulation to get get chaotic sound. 
aOut 		grain 		.01, kPitch, kDensity, kAmpOff, kFreqOff, kGDur, giBuzz, giHanning, 1, 0
aOut		dcblock2	aOut
			outs	 	aOut * p5 * kLongEnv, aOut * p5 * kLongEnv

endin

;Rain droplet
instr 19
;p4 - Amplitude
;p5 - pan

iDur 		= 			.2
;Envelopes
kVol		expseg		.3, iDur, .01
kPitch		expseg		1000, iDur, 2000, .1, 2000 	;A sharp pitch increase

;A single sine oscillator to simulate a water droplet dropping
aSig		poscil		kVol * p4 * .5, kPitch	
			outs		aSig * p5, aSig * (1-p5) 

kReverb		= 			.3
gaSendL		=			gaSendL + (aSig * p5 * kReverb)
gaSendR		=			gaSendR + (aSig * (1-p5) * kReverb)

endin

;Rain droplet splash
instr 20
;p4 - Amplitude
iDur 		= 			p3
kVol		expseg 		1, iDur, .001

;Broadband noise used to simulate water splashing.
aNoise		rand		1 * kVol * p4
klfo		poscil		1, 2
aFilt		butbp		aNoise * klfo, 3000, 200 

			outs 		aFilt, aFilt

;Large reverb send amount to make it natural
kReverb		= 			.8
gaSendL		=			gaSendL + (aFilt * kReverb)
gaSendR		=			gaSendR + (aFilt * kReverb)

endin

;Global Reverb unit
instr	99	
 
aL,aR		reverbsc	gaSendL,gaSendR,0.83,6000
 			outs		aL,aR
 			clear		gaSendL,gaSendR
endin

</CsInstruments>
<CsScore>
;Chime bells:
; i 	Start	Dur		Gain
i 1  	0 		80		1
i 1		80		250		.4

;Wind:
; i 	Start	Dur		Gain
i 11 	10 		70		1
i 11 	80		30		.5
i 11 	280		50		.08

;Rain:
; i 	Start	Dur		Gain
i 12 	20 		60		1
i 12 	80		30		.5

;Soft Pad:
; i 	Start	Dur		Pitch	Pan		Gain
i 13 	40 		50  	6.02 	.1 		.1
i .  	.  		.   	6.09 	.9 		.1
i .	 	70 		210 	6.02 	.1 		.1

;Evolution:
; i 	Start	Dur		Pitch	Gain
i 14 	70 		140		60		1
i .  	. 		. 		63 		.
i .  	. 		. 		65		.
i .  	. 		. 		67		.
i .  	. 		. 		70		.
i .  	. 		. 		73		.

;Bass thump
; i 	Start	Dur		Gain	StartAmp Attack	EndAmp	Hold	 
i 2		120		162 	.6		.05		 60		1		50	

;Bass rumble
; i 	Start	Dur		Pitch	StartAmp Attack	EndAmp	Hold
i 3		120		160 	73		.05		 60		1		50

;Strings
; i 	Start	Dur		Pitch	Gain
i 17 	190 	90	 	58 		.4 
i . 	.		. 	    63 		.6
i . 	. 		.  		65 		.3

i . 	210 	70  	69 		.1
i . 	215 	65 		73 		.3
i . 	220 	60 		75 		.1

;Chaos Machine
; i 	Start	Dur		Length	Gain
i 18	250		30		30		.8

;Rain drops
; i 	Start	Dur		Amp		Pan
i 19 	300		.4		.1		.1
i 20 	300.15 	.2		.2
i 19 	303		.4		.15		.9
i 20 	303.15 	.2		.3
i 19 	304		.4		.05		.5
i 20 	304.15 	.2		.2

i 19 	306.1	.4		.05		.1
i 20 	306.3 	.2		.2

i 19 	313.1	.4		.2		.9
i 20 	313.25 	.2		.3
i 19 	313.7	.4		.08		.1
i 20 	313.85 	.2		.2

;Reverb
i 99 	0 		330
</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
