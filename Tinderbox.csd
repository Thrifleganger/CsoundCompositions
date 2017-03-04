; Tinderbox
; Written by Thrifleganger
<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1.0

gaSendL, gaSendR init  	0
giNoteMap	ftgen		1, 0, -9, -2, 53, 60, 65, 72, 67, 88 - 12, 89 - 12, 84, 81
giRandNote5	ftgen		2, 0, -5, -2, 84, 65, 67, 69, 79, 70, 74

giNoteMap2	ftgen		3, 0, -7, -2, 55, 62, 65, 72, 69, 88 - 12, 89 - 12
giRandNote2	ftgen		4, 0, -5, -2, 84, 65, 72, 70, 74;, 74, 70

giCos		ftgen		0, 0, 131072, 11, 1
giHanning	ftgen		0, 0, 4096,   20, 2, 1
giBuzz		ftgen		0, 0, 131072, 11, 80, 1, 0.7

giFRatio	ftgen		90, 0, -4, -2, 1, 2, 3, 4

;Main synth trigger
instr 1
; p4 - Note table
; p5 - Attack
; p6 - Duration
; p7 - Release
; p8 - Instant of time of volume swell

kRandNote 	init		0
kIndex		init		0
kCycle		init		0
kRatioInd 	init		0

; Scale and random value table selection
if p4 == 1 then			
	iNoteMap	=			1
	iRandMap	=			2
elseif p4 == 2 then
	iNoteMap  	=			3
	iRandMap	=			4
endif

kGlobVol	linseg		0, p5, 1, p6, 1, p7, 0 
kPitch		table 		kIndex, iNoteMap
kTrig 		metro 		7

kIndexEnv	rspline		.1, 5, .2,.8
kIndexEnv 	limit		kIndexEnv, .1, 5
kRatioSend	table		int(kRatioInd), giFRatio     	    		 		
kRatioInd	randomh		-1, 4, .05
kPan		random		0, 1
kPitchCent	random		-5, 5
kTimeDelay	random		.0001, .05		
kIndVol		linseg 		.2, p8 - 1, .2, 2, .35, 2, .2, 1, .2    		 		

kisOdd		=			kCycle % 4
printks		"Values: %d %d %d", 1, kIndex, kCycle, kisOdd
if kTrig == 1 then
	if kIndex == 4 then
		kRandNote	random		-1, 5
		kPitch		table		int(kRandNote), iRandMap
	endif
	event		"i", 2, 0, 1, kPitch - 12, kIndexEnv, kRatioSend, kPan, kGlobVol, kIndVol
;	event		"i", 2, kTimeDelay, 1, kPitch, kIndexEnv/2 , kRatioSend, kPan
	
	if kIndex == 0 then
		kCycle	+=			1
		kRandNote		random	2, 7
	endif
	
	printk2 	int(kRandNote)
	kIndex		+=		1
	if kisOdd == 1 then
		kIndex		wrap	kIndex, 0, 7
	elseif kisOdd == 2 then
		kIndex		wrap	kIndex, 0, 4
	elseif kisOdd == 3 then
		kIndex		wrap	kIndex, 0, 7
	else
		kIndex		wrap	kIndex, 0, 3
	endif
endif

endin

; FM Synth Instrument
instr 2 
; p4 - Midi Note Pitch
; p5 - Index of modulatiion
; p6 - Frequency ratio of modulation
; p7 - Pan
; p8 - Global Volume
; p9 - Individual note Volume

kFreq		=			cpsmidinn(p4)
kIndex		expseg 		p5, 1, .2
kRatio		=			p6
kVolEnv		expseg		1, 1, 0.01

aMod		poscil		kFreq*kIndex, kFreq*kRatio
aCarr		poscil		p9, kFreq + aMod

aOut		=			aCarr*kVolEnv
			outs		aOut * p7 * p8, aOut * (1 - p7) * p8
			
kReverb		=			.73
gaSendL		=			gaSendL + (aOut * kReverb * p7 * p8)
gaSendR		=			gaSendR + (aOut * kReverb * (1 - p7) * p8)
endin


;Reverser Trigger
instr 3
; p4 - Attack
; p5 - Duration
; p6 - Relase
; p7 - Note bank
; p8 - Global Volume

kFIndex1 	random		0, 6.99
kFIndex2	random		0, 6.99
kFIndex3	random		0, 8.99
iNoteMap	=			p7

kPitch1		table 		int(kFIndex1), iNoteMap
kPitch2		table		int(kFIndex2), iNoteMap
kPitch3		table		int(kFIndex3), iNoteMap

kGlobVol	linseg		0, p4, 1, p5, 1, p6, 0
kStartTime	rspline 	.0001, .08, .2, .8
kFRatio		rspline		1, 5, .2, 1
kTrigFreq	rspline		.1, 3, .2, 2
kDur		random		.2, 6
kVol 		random		.05, .2
kPan		random		0, 1

kTrig		metro		kTrigFreq
if kTrig == 1 then
	event	"i", 4, 0, 5, kPitch1, kDur, kVol * kGlobVol*p8, kPan, kStartTime, int(kFRatio)
	event	"i", 4, 0, 5, kPitch2, kDur, kVol * kGlobVol*p8, kPan, kStartTime, int(kFRatio)
	event	"i", 4, 0, 5, kPitch3, kDur, kVol * kGlobVol*p8, kPan, kStartTime, int(kFRatio)
endif

endin

;Reverser
instr 4
; p4 - Pitch
; p5 - Duration of note
; p6 - Volume of note
; p7 - Pan position
; p8 - Start volume
; p9 - Frequency index ratio

iDur		=			p5 
iFreq 		=			cpsmidinn(p4)	

aVolEnv		expseg		p8, iDur, .1, .1, 0.01
aIndexEnv	expseg		p8, iDur, 5, .1, 0.01
iFreqRatio	=		    p9

aMod		poscil		iFreq * aIndexEnv, iFreq * iFreqRatio
aCarr		poscil		aVolEnv, iFreq + aMod
			outs		aCarr * p6 * p7, aCarr * p6 * (1 - p7)

endin


;Pad Chords Trigger
instr 5
; p4 - Attack
; p5 - Duration
; p6 - Release

kFIndex1 	random		0, 6.99
kFIndex2	random		0, 6.99
kFIndex3	random		0, 8.99
iNoteMap	=			1
kGlobVol	linseg		0, p4, 1, p5, 1, p6, 0  

kPitch1		table 		int(kFIndex1), iNoteMap
kPitch2		table		int(kFIndex2), iNoteMap
kPitch3		table		int(kFIndex3), iNoteMap

kVolStart	rspline 	.1, .25, .2, .8
kIndStart	rspline		.1, 1, .2, .8 
kFRatio		rspline		1, 5, .2, 1
kTrigFreq	rspline		.1, 1.5, .2, 2
kDur		random		.6, 6
kVol 		random		.05, .2
kPan		random		0, 1
kModCents	rspline		0, 30, .2, .8
kModFreq	rspline		.2, 2, .2, .8

kTrig		metro		kTrigFreq
if kTrig == 1 then
	event	"i", 6, 0, 5, kPitch1, kDur, kVol * kGlobVol, kPan, kVolStart, kIndStart, int(kFRatio), kModCents, kModFreq
	event	"i", 6, 0, 5, kPitch2, kDur, kVol * kGlobVol, kPan, kVolStart, kIndStart, int(kFRatio), kModCents, kModFreq
	event	"i", 6, 0, 5, kPitch3, kDur, kVol * kGlobVol, kPan, kVolStart, kIndStart, int(kFRatio), kModCents, kModFreq	
endif

endin

;Pad Chords Instrument
instr 6
; p4 - Midi Note Pitch
; p5 - Duration of note
; p6 - Volume
; p7 - Pan
; p8 - Start Value of volume
; p9 - Start value of Index of modulation
; p10 - Frequency ratio of modulation
; p11 - Pitch LFO cent amplitude
; p12 - Pitch LFO frequency

seed 0

iDur		=			p5 
iFreq 		=			cpsmidinn(p4)	

aVolEnv		expseg		.01, .02, p8, iDur, 0.01
aIndexEnv	expseg		p9, iDur, p9+.5, .1, 0.01
iFreqRatio	=		    p10

aLFO		poscil		p11, p12
aMod		poscil		iFreq * aIndexEnv, iFreq * iFreqRatio
aCarr		poscil		aVolEnv, (iFreq + aMod * aLFO/p11) * cent(aLFO)
;aCarr		*=			1.5

			outs		aCarr * p6 * p7, aCarr * p6 * (1 - p7)

endin

instr 7

iAtt		=			p7			
iDur		=			p8
iRel		=			p9
iWhen		=			p6
iDec		=			.4

iModFreq	random		0, .4
iModAmp		random		0, .1

kTrans		linseg		cpsmidinn(p4), iWhen, cpsmidinn(p4), iDec, cpsmidinn(p5) 
kGlobVol	expseg		.001, iAtt, 1, iDur, 1, iRel, .001

kDensity	= 			200
kAmpOff		=			.05
kFreqOff	=			3.2
kGDur		=			.1

;High density granular synthesis for generating rich strings. Slight freqoff for quiver
aSig 		grain 		.01, kTrans, kDensity, kAmpOff, kFreqOff, kGDur, giBuzz, giHanning, 1, 0
aSig		=			aSig * kGlobVol * p10
			outs		aSig, aSig

kReverb		= 			.7
gaSendL		=			gaSendL + (aSig*kReverb)
gaSendR		=			gaSendR + (aSig*kReverb)
endin

; Evolution instrument
instr 14

iGain		=			p5
iFreq		=			cpsmidinn(p4)
kModifier 	= 			.1
kLevel 		= 			0.9
kPartials	=			30		;Determines the overall brightness of sound
kModCents	rspline		0, 20, .2, .8
kModFreq	rspline		.5, 1.5, .2, .8

kLongEnv 	expsegr 	.01, 20, .8, 20, .001

kVary		jspline		10,0.05,0.2			;Slight frequency randomness
kMultiply	rspline 	0.3,0.8,0.1,0.4		;Amplitude coefficient determines brightness in higher partials

;Remove:
kModifier   linseg		1, p6 -2, 1, 2, 1.5, 2, 1
kModifier	limit		kMultiply^2 * kModifier, 0, 1
aLFO		poscil		kModCents, kModFreq
aSig		gbuzz 		0.1, iFreq * cent(kVary) * cent(aLFO), kPartials, 1, kModifier, giCos
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

;Global Reverb unit
instr	99	
 
kfb			expseg		.83, p4, .83, 10, .96, 1 , .96
printk  1, kfb
aL,aR		reverbsc	gaSendL,gaSendR,kfb,6000
 			outs		aL,aR
 			clear		gaSendL,gaSendR
endin

</CsInstruments>
<CsScore>
;a 0 0 1000
; #		start	dur		startN	endN	when	att		dur		rel		vol		
i 7 	80	 	40		53		53		20		16		8		16		.7
i 7 	.	 	.		57		58		.		.		.		.		.
i 7 	.	 	.		60		62		.		.		.		.		.
i 7 	.	 	.		72		70		.		.		.		.		.
 	
;a 0 0 80
; FM synth
; #		start	dur		bank	att		dur		rel		when	value
i 1 	40		100 	1		10		50		0		60
i 1 	100		80		2		0.1		60		10		3

; Pad Chords
; #		start	dur		att		dur		rel
i 5 	0 		100		10		30		15	 

; Reverser
; # 	start	dur		att		dur		rel		bank	vol
i 3 	60 		100		10		30		5		1		1
i 3 	120		60		10		10		15		2		.2

; #		start	dur		note	vol		when
i 14 	10 		100		53		.6		90
i . . . 57 .
i . . . 60 . 
i . . . 65 .
i . . . 72 .
i . . . 69 .

; #		start	dur		note	vol
i 14 	90 		60		53		.7
i . . . 58 .
i . . . 62 .
i . . . 70 .

;Reverb
i 99 0 180 155

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
