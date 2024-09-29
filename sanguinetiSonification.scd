///*** POEM SONIFICATION ***///

(
/* SOUND EVENTS DEFINITION */

SynthDef(\latin, // latin alphabetic characters
	{
		|freq1 = 440, freq2 = 440, up = 0, stress = 0, stress_freq = 0, stress_dc = 0, double = 0, pos = 0, amp = 0|
		var num = 3;
		var sig = Mix.fill(num, {|i| // 3 signals mixed
			SinOsc.ar( // source
				(Line.ar(freq1, freq2, 0.25)) // frequency with possibility of linear increase/decrease
				*
				((i*up)+1) // lowercase -> 1 frequency VS uppercase -> 3 harmonics
				+
				LFPulse.kr(stress_freq, 0.9, stress_dc, freq1*stress),  // possibility of acciaccatura -> letters with diacritics
				mul:((freq1*0.05).cpsmidi).reciprocal*5/(num-i) // mul inversely proportional to frequency + directly proportional to harmonic number
			)
		});
		var envSig = (sig * LFPulse.kr(double, 0, 0.9)) * EnvGen.kr(Env.perc(0.001, 0.8, 1, -8), doneAction: 2); // signal * possibility of doubled sound (special foreign letters) * percussive envelope
		Out.ar(0, Pan2.ar(envSig, pos, amp.dbamp)); // multichannel expansion (stereo), position, amplitude control
	}
).add;


SynthDef(\greek, // greek alphabetic characters (lowercase only)
	{
		|freq1 = 440, freq2 = 440, up = 0, stress = 0, stress_freq = 0, stress_dc = 0, pos = 0, amp = 0|
		var num = 3;
		var sig = Mix.fill(num, {|i|
			Saw.ar( // same as latin alphabetic characters BUT different source
				(Line.ar(freq1, freq2, 0.25))
				*
				((i*up)+1)
				+
				LFPulse.kr(stress_freq, 0.9, stress_dc, freq1*stress), // acciaccatura for letters with diacritics
				mul:(freq1.cpsmidi).reciprocal*20/(num-i)
			)
		});
		var envSig = sig * EnvGen.kr(Env.perc(0.001, 0.8, 1, -8), doneAction: 2); // signal * percussive envelope
		Out.ar(0, Pan2.ar(envSig, pos, amp.dbamp));
	}
).add;


SynthDef(\number, // numeric characters
	{
		|freq = 48, pos = 0, amp = 0|
		var num = 3, up = 1.5, rq = 0.005;
		var sig = Mix.fill(num, {|i| // filter bank with 3 filters
			Normalizer.ar( // energy loss -> normalizer
				BPF.ar( // band pass filter
					PinkNoise.ar, //source
					freq.midicps*((i*up)+1), // central frequencies
					rq*(i+1)), // higher frequency -> lower resonance
				freq.reciprocal*20/(num-i) // mul inversely proportional to frequency + directly proportional to harmonic number
			)
		});
		var envSig = sig * EnvGen.kr(Env.perc(0.001, 0.8, 1, -8), doneAction: 2); //enveloped signal
		Out.ar(0, Pan2.ar(envSig, pos, amp.dbamp));
	}
).add;


SynthDef(\punct, // punctuation and mathematical characters + other symbols
	{
		|freq = 48, incr1 = 0, incr2 = 0, kfreq = 0, dc = 0.0, curve = 0, double = 0, pos = 0, amp = 0|
		var num = 3, rq = 0.005;
		var sig = Mix.fill(num, {|i| // filter bank with 3 filters
			Normalizer.ar(
				RHPF.ar( // resonant high pass filter
					Decay.ar( // exponential decay
						Impulse.ar(1), // source
						0.15, // decay time
						PinkNoise.ar), // mul
					(((freq+Line.ar(0, incr1, 0.25)).midicps)*(i+1)) // cutoff frequencies -> possibility of linear increase/decrease
					+
					LFPulse.kr(kfreq, 0.5, dc, freq*incr2), // possibility of acciaccatura
					rq*(i+1)),
				freq.reciprocal*30/(num-i)
			)
		});
		var envSig = (sig * LFPulse.kr(double, 0, 0.9)) * EnvGen.kr(Env.perc(0.01, 0.3, 1, curve), doneAction: 2);
		Out.ar(0, Pan2.ar(envSig, pos, amp.dbamp));
	}
).add;


SynthDef(\blank, // blank characters horizontal tab and newline
	{
		|freq = 110, rq = 0.05, delaytime = 0.04, pos = 0, amp = 0|
		var sig =
		AllpassN.ar( // Schroeder allpass delay line with no interpolation
			RHPF.ar(
				Decay.ar(Impulse.ar(1),	0.15, PinkNoise.ar),
				freq.midicps, rq), // cutoff frequency, resonance
			0.15, // max delay time
			delaytime,
			Line.ar(1, 1, 0.25, doneAction:2)); // deallocator as decay time
		Out.ar(0, Pan2.ar(sig, pos, amp.dbamp));
	}
).add;


SynthDef(\space, // blank characters space and carriage return
	{
		Out.ar(0, Silent.ar * Line.ar(1, 1, 0.25, doneAction:2)); // silence * deallocator
	}
).add;
)

(
/* DICTIONARIES */

// LETTERS
//  [  a,  b,  c,   d,   e,   f,   g,   h,   i,   j,   k,   l,   m,   n,   o,   p,   q,   r,   s,   t,   u,   v,   w,   x,   y,   z ]
// codes:
//  [ 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122 ] // lowercase
//  [ 65, 66, 67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  90 ] // uppercase
// pitches:
//  [ 60, 62, 64,  65,  67,  69,  71,  72,  74,  76,  77,  79,  81,  83,  84,  86,  88,  89,  91,  93,  95,  96,  98, 100, 101, 103 ]
~lowAlpha_codes = Array.series(26, 97, 1);
~codes = [~lowAlpha_codes, ~lowAlpha_codes-32]; // [lowercase, uppercase] codes
~pitches = Array.fill(4, {|i| [0, 2, 4, 5, 7, 9, 11]+60+(12*i)}).flat; // C major scale
~pitches.removeAllSuchThat({|item, index| index > (~lowAlpha_codes.size-1)}); // 7 pitches * 4 octaves = 28 -> only 26 codes -> remove extra pitches
~low = 0;
~up = 1.5; // uppercase factor
~noStress = 0; // stress factor 0
~noDouble = 0; // double factor 0
~double = 4; // 2 characters in 1 (œ, ß)

// letters from most to least common in Italian (for multilingual modality)
//  [  e,  i,  a,  o,  n,  r,  l,  t,  s,  d,  c,  u,  p,  m,  g,  v,  h,  f,  b,  q,  z,  j,  y,  x,  k,  w ]
// same codes order -> different pitches order + higher distance
//  [  a,  b,  c,  d,  e,  f,  g,  h,  i,   j,   k,  l,  m,  n,  o,  p,  q,  r,  s,  t,  u,  v,   w,   x,   y,   z ]
//  [ 64, 96, 80, 78, 60, 94, 88, 92, 62, 102, 108, 72, 86, 68, 66, 84, 98, 70, 76, 74, 82, 90, 110, 106, 104, 100 ]
~index = [4, 8, 0, 14, 13, 17, 11, 19, 18, 3, 2, 20, 15, 12, 6, 21, 7, 5, 1, 16, 25, 9, 24, 23, 10, 22];
~index_MULTI = ~index.collect({|item| ~pitches[item]}).order; // new pitches order
~pitches_new = Array.series(26, 60, 2); // new scale
~pitches_MULTI = ~index_MULTI.collect({|item| ~pitches_new[item]}); // new pitches in new order

// uppercase and lowercase dictionaries
~alpha_dict = ~codes.collect{|low_up, index|
	[low_up, [
		\alpha, \latin, ~pitches, ~pitches, [~low, ~up][index], ~noStress, ~noStress, ~noStress, ~noDouble
	].flop].lace(~lowAlpha_codes.size*2).asDict
}.flopDict;

// uppercase and lowercase dictionaries in multilingual modality
~alpha_dict_MULTI = ~codes.collect{|low_up, index|
	[low_up, [
		\alpha, \latin, ~pitches_MULTI, ~pitches_MULTI, [~low, ~up][index], ~noStress, ~noStress, ~noStress, ~noDouble
	].flop].lace(~lowAlpha_codes.size*2).asDict
}.flopDict;


~alpha_dictS = [~alpha_dict, ~alpha_dict_MULTI]; // alternative dictionaries


// LETTERS WITH DIACRITICS
// prefix -61
/*
grave       \stress, 2,  \stress_freq, 1,  \stress_dc, 0.8
acute       \stress, 4,  \stress_freq, 1,  \stress_dc, 0.8
circumflex  \stress, 4,  \stress_freq, 2,  \stress_dc, 0.2
tilde       \stress, 2,  \stress_freq, 2,  \stress_dc, 0.2
umlauts     \stress, 3,  \stress_freq, 10, \stress_dc, 0.8
cedilla     \stress, -2, \stress_freq, 1,  \stress_dc, 0.8
*/
~index_stress = [0, 4, 8, 14, 20]; // a, e, i, o, u indexes
~index_tilde = [0, 13, 14]; // a, n, o indexes

// codes (lowercase and uppercase)
~graveLowAlpha_codes = [-96, -88, -84, -78, -71]; // à, è, ì, ò, ù
~acuteLowAlpha_codes = ~graveLowAlpha_codes+1; // á, é, í, ó, ú [ -95, -87, -83, -77, -70 ]
~circLowAlpha_codes = ~graveLowAlpha_codes+2; // â, ê, î, ô, û [ -94, -86, -82, -76, -69 ]
~umlLowAlpha_codes = [-92, -85, -81, -74, -68]; // ä, ë, ï, ö, ü
~stressLow_codes = [~graveLowAlpha_codes, ~acuteLowAlpha_codes, ~circLowAlpha_codes, ~umlLowAlpha_codes];
// À, È, Ì, Ò, Ù [ -128, -120, -116, -110, -103 ]
// Á, É, Í, Ó, Ú [ -127, -119, -115, -109, -102 ]
// Â, Ê, Î, Ô, Û [ -126, -118, -114, -108, -101 ]
// Ä, Ë, Ï, Ö, Ü [ -124, -117, -113, -106, -100 ]
~stress_codes = [~stressLow_codes, ~stressLow_codes-32]; // [lowercase, uppercase] codes
~tildeLowAlpha_codes = [-93, -79, -75];  // ã, ñ, õ
// Ã, Ñ, Õ [ -125, -111, -107 ]
~tilde_codes = [~tildeLowAlpha_codes, ~tildeLowAlpha_codes-32];

// pitches (lowercase and uppercase)
~stress_pitches = ~index_stress.collect{|item| ~pitches[item]}; // find pitches through indexes
~tilde_pitches = ~index_tilde.collect{|item| ~pitches[item]};
// in multilingual modality
~stress_pitches_MULTI = ~index_stress.collect{|item| ~pitches_MULTI[item]};
~tilde_pitches_MULTI = ~index_tilde.collect{|item| ~pitches_MULTI[item]};

// diacritics variables
~stress_2 = 2;
~stress_3 = 3;
~stress_4 = 4;
~stress_2neg = -2;

~stressFreq_1 = 1;
~stressFreq_2 = 2;
~stressFreq_5 = 5;
~stressFreq_10 = 10;

~stressDc_02 = 0.2;
~stressDc_06 = 0.6;
~stressDc_08 = 0.8;


// with diacritics lowercase and uppercase dictionaries
~stressAlpha_dict = ~stress_codes.collect{|low_up, index|
	low_up.collect{|item, i|
		[item, [
			\alpha, \latin, ~stress_pitches, ~stress_pitches, [~low, ~up][index], [~stress_2, ~stress_4, ~stress_4, ~stress_3][i], [~stressFreq_1, ~stressFreq_1, ~stressFreq_2, ~stressFreq_10][i], [~stressDc_08, ~stressDc_08, ~stressDc_02, ~stressDc_08][i], ~noDouble
		].flop].lace(~index_stress.size*2).asDict
	}.flopDict
}.flopDict;

~tildeAlpha_dict = ~tilde_codes.collect{|low_up, index|
	[low_up, [
		\alpha, \latin, ~tilde_pitches, ~tilde_pitches, [~low, ~up][index], ~stress_2, ~stressFreq_2, ~stressDc_02, ~noDouble
	].flop].lace(~index_tilde.size*2).asDict
}.flopDict;

~stressAlpha_dict = (~stressAlpha_dict ++ ~tildeAlpha_dict)
.add(-89 -> [\alpha, \latin, ~pitches[2], ~pitches[2], ~low, ~stress_2neg, ~stressFreq_1, ~stressDc_06, ~noDouble]) // add ç...
.add(-97 -> [\alpha, \latin, ~pitches[18], ~pitches[18], ~low, ~noStress, ~noStress, ~noStress, ~double]); // ...and ß -> same prefix;


// with diacritics lowercase and uppercase dictionaries in multilingual modality
~stressAlpha_dict_MULTI = ~stress_codes.collect{|low_up, index|
	low_up.collect{|item, i|
		[item, [
			\alpha, \latin, ~stress_pitches_MULTI, ~stress_pitches_MULTI, [~low, ~up][index], [~stress_2, ~stress_4, ~stress_4, ~stress_3][i], [~stressFreq_1, ~stressFreq_1, ~stressFreq_2, ~stressFreq_10][i], [~stressDc_08, ~stressDc_08, ~stressDc_02, ~stressDc_08][i], ~noDouble
		].flop].lace(~index_stress.size*2).asDict
	}.flopDict
}.flopDict;

~tildeAlpha_dict_MULTI = ~tilde_codes.collect{|low_up, index|
	[low_up, [
		\alpha, \latin, ~tilde_pitches_MULTI, ~tilde_pitches_MULTI, [~low, ~up][index], ~stress_2, ~stressFreq_2, ~stressDc_02, ~noDouble
	].flop].lace(~index_tilde.size*2).asDict
}.flopDict;

~stressAlpha_dict_MULTI = (~stressAlpha_dict_MULTI ++ ~tildeAlpha_dict_MULTI)
.add(-89 -> [\alpha, \latin, ~pitches_MULTI[2], ~pitches_MULTI[2], ~low, ~stress_2neg, ~stressFreq_1, ~stressDc_06, ~noDouble])
.add(-97 -> [\alpha, \latin, ~pitches_MULTI[18], ~pitches_MULTI[18], ~low, ~noStress, ~noStress, ~noStress, ~double]);


~stressAlpha_dictS = [~stressAlpha_dict, ~stressAlpha_dict_MULTI];


// SPECIAL LETTER WITH PREFIX -59
// œ
~alpha59_dict = [-109 -> [\alpha, \latin, ~pitches[14], ~pitches[4], ~low, ~noStress, ~noStress, ~noStress, ~double]].asDict;
// in multilingual modality
~alpha59_dict_MULTI = [-109 -> [\alpha, \latin, ~pitches_MULTI[14], ~pitches_MULTI[4], ~low, ~noStress, ~noStress, ~noStress, ~double]].asDict;

~alpha59_dictS = [~alpha59_dict, ~alpha59_dict_MULTI];

//-------------------------------------------------------------------------------------------//

// GREEK LETTERS
// without diacritics
// [   α,   β,   γ,   δ,   ε,   ζ,   η,   θ,   ι,   κ,   λ,   μ,   ν,   ξ,   ο,    π,    ρ,    ς,    σ,    τ,    υ,    φ,    χ,    ψ,    ω ]
// codes:
// [ -79, -78, -77, -76, -75, -74, -73, -72, -71, -70, -69, -68, -67, -66, -65, -128, -127, -126, -125, -124, -123, -122, -121, -120, -119 ]
// |_____________________________prefix -50___________________________________||_______________________prefix -49__________________________|
// pitches:
// [  48,  50,  52,  53,  55,  57,  59,  60,  62,  64,  65,  67,  69,  71,  72,   74,   76,   77,   79,   81,   83,   84,   86,   88,   89 ]

/* with diacritics
ά -50 -84      \stress, 4, \stress_freq, 1, \stress_dc, 0.8
ί -50 -81      \stress, 4, \stress_freq, 1, \stress_dc, 0.8
ό -49 -116     \stress, 4, \stress_freq, 1, \stress_dc, 0.8

ῆ -31 -65 -122 \stress, 2, \stress_freq, 2, \stress_dc, 0.2
ῶ -31 -65 -74  \stress, 2, \stress_freq, 2, \stress_dc, 0.2

ὰ -31 -67 -80  \stress, 2, \stress_freq, 1, \stress_dc, 0.8
ὶ -31 -67 -74  \stress, 2, \stress_freq, 1, \stress_dc, 0.8

ἄ -31 -68 -124 \stress, 4, \stress_freq, 5, \stress_dc, 0.8
ἔ -31 -68 -108 \stress, 4, \stress_freq, 5, \stress_dc, 0.8
*/

// without diacritics
~greek50_codes = Array.series(15, -79, 1);
~greek49_codes = Array.series(10, -128, 1);
~greek_pitches = Array.fill(4, {|i| [0, 2, 4, 5, 7, 9, 11]+48+(12*i)}).flat;
~greek_pitches.removeAllSuchThat({|item, index| index > (((~greek50_codes ++ ~greek49_codes).size)-1)});

// without diacritics lowercase dictionaries -> 2 dictionaries (prefixes -50 and -49)
~greek_dict = [~greek50_codes, ~greek49_codes].collect{|item, index|
	[item, [
		\alpha, \greek, ~greek_pitch = [~greek_pitches.select{|item, index| index < ~greek50_codes.size}, ~greek_pitches.select{|item, index| index >= ~greek50_codes.size}][index], ~greek_pitch, ~low, ~noStress, ~noStress, ~noStress
	].flop].lace([(~greek50_codes.size*2), (~greek49_codes.size*2)][index]).asDict
};

// add letters with diacritics with prefix -50 or -49
~greek_dict[0] = ~greek_dict[0] ++ [-84, -81].collect{|item, index|
	[item, [
		\alpha, \greek, [~greek_pitches[0], ~greek_pitches[8]][index], [~greek_pitches[0], ~greek_pitches[8]][index], ~low, ~stress_4, ~stressFreq_1, ~stressDc_08
	].flop].lace(2).asDict
}.flopDict; // ά, ί
~greek_dict[1].add(-116 -> [\alpha, \greek, ~greek_pitches[14], ~greek_pitches[14], ~low, ~stress_4, ~stressFreq_1, ~stressDc_08]); // ό

// with diacritics
~greekStressed_codes = [[-122, -74], [-80, -74], [-124, -108]];
~greekStressed_pitches = [[~greek_pitches[6], ~greek_pitches[24]], [~greek_pitches[0], ~greek_pitches[8]], [~greek_pitches[0], ~greek_pitches[4]]];

// with diacritics lowercase dictionaries -> 3 dictionaries (prefixes -65, -67, -68)
~greekStress_dict = ~greekStressed_codes.collect{|stress, index|
	stress.collect{|item, i|
		[item, [
			\alpha, \greek, ~greekStressed_pitches[index][i], ~greekStressed_pitches[index][i], ~low, [~stress_2, ~stress_2, ~stress_4][index], [~stressFreq_2, ~stressFreq_1, ~stressFreq_5][index], [~stressDc_02, ~stressDc_08, ~stressDc_08][index]
		].flop].lace(~greekStressed_codes[0].size*2).asDict
	}.flopDict
};

//-------------------------------------------------------------------------------------------//

// NUMBERS
//  [  0,  1,  2,  3,  4,  5,  6,  7,  8,  9 ]
// codes:
//  [ 48, 49, 50, 51, 52, 53, 54, 55, 56, 57 ]
// pitches:
//  [ 48, 52, 55, 59, 62, 65, 69, 72, 76, 79 ]
~num_codes = Array.series(10, 48, 1);
~num_pitches = [0, 4, 7, 11, 14, 17, 21, 24, 28, 31]+48;

~num_dict = [~num_codes, [
	\extra, \number, ~num_pitches
].flop].lace(~num_codes.size*2).asDict; // numbers dictionary

// PUNCTUATION, MATHEMATICAL AND OTHER SYMBOLS
/*
! 33            \freq, 48,  \incr1, 24,  \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 7
" 34            \freq, 96,  \incr1, 0,   \incr2, 0.5, \kfreq, 1,  \dc, 0.6, \curve, 0,  \double, 7
% 37            \freq, 60,  \incr1, 24,  \incr2, 4,   \kfreq, 15, \dc, 0.3, \curve, -2, \double, 0
& 38            \freq, 67,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 0
' 39            \freq, 96,  \incr1, 0,   \incr2, 0.5, \kfreq, 1,  \dc, 0.6, \curve, -4, \double, 0
( 40            \freq, 50,  \incr1, 12,  \incr2, 1,   \kfreq, 1,  \dc, 0.3, \curve, -4, \double, 0
) 41            \freq, 62,  \incr1, -12, \incr2, 1,   \kfreq, 1,  \dc, 0.3, \curve, -4, \double, 0
+ 43            \freq, 80,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 0
, 44            \freq, 50,  \incr1, 0,   \incr2, 1,   \kfreq, 1,  \dc, 0.6, \curve, -4, \double, 0
- 45            \freq, 60,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 0
. 46            \freq, 48,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, -2, \double, 0
/ 47            \freq, 60,  \incr1, 40,  \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, -4, \double, 0
: 58            \freq, 48,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 7
; 59            \freq, 48,  \incr1, 2,   \incr2, 1,   \kfreq, 1,  \dc, 0.6, \curve, 0,  \double, 7
= 61            \freq, 60,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 7
? 63            \freq, 48,  \incr1, 12,  \incr2, 2.5, \kfreq, 1,  \dc, 0.6, \curve, 0,  \double, 7
° -62 -80       \freq, 84,  \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, -2, \double, 0
× -61 -105      \freq, 100, \incr1, 0,   \incr2, 0,   \kfreq, 0,  \dc, 0.0, \curve, 0,  \double, 0
… -30 -128 -90  \freq, 48,  \incr1, 0,   \incr2, 2,   \kfreq, 15, \dc, 0.3, \curve, -2, \double, 0
*/
~punct_codes = [33, 34, 37, 38, 39, 40, 41, 43, 44, 45, 46, 47, 58, 59, 61, 63];
~punct_pitches = [48, 96, 60, 67, 96, 50, 62, 80, 50, 60, 48, 60, 48, 48, 60, 48];
~punct_incr_1 = [24, 0, 24, 0, 0, 12, -12, 0, 0, 0, 0, 40, 0, 2, 0, 12];
~punct_incr_2 = [0, 0.5, 4, 0, 0.5, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 2.5];
~kfreq = [0, 1, 15, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1];
~dc = [0.0, 0.6, 0.3, 0.0, 0.6, 0.3, 0.3, 0.0, 0.6, 0.0, 0.0, 0.0, 0.0, 0.6, 0.0, 0.6];
~curve = [0, 0, -2, 0, -4, -4, -4, 0, -4, 0, -2, -4, 0, 0, 0, 0];
~punct_double = [7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7];

~punct_dict = [~punct_codes, [
	\extra, \punct, ~punct_pitches, ~punct_incr_1, ~punct_incr_2, ~kfreq, ~dc, ~curve, ~punct_double
].flop].lace(~punct_codes.size*2).asDict; // punctuation + mathematical symbols dictionary

// symbols with prefix -62 or -61 or -128
~punct62_dict = [-80 -> [\extra, \punct, 84, 0, 0, 0, 0.0, -2, 0]].asDict;
~punct61_dict = [-105 -> [\extra, \punct, 100, 0, 0, 0, 0.0, 0, 0]].asDict;
~punct128_dict = [-90 -> [\extra, \punct, 48, 0, 2, 15, 0.3, -2, 0]].asDict;

//-------------------------------------------------------------------------------------------//

// BLANK CHARACTERS
/*
horizontal tab    9   \freq, 110, \rq, 0.05, \delaytime, 0.04
newline          10   \freq, 50,  \rq, 1,    \delaytime, 0.15
carriage return  13   silence
space            32   silence
*/
~blank_codes = [9, 10, 13, 32];
~blank_freq = [110, 50, 0, 0];
~blank_rq = [0.05, 1, 0, 0];
~blank_dt = [0.04, 0.15, 0, 0];
~synthdef = [\blank, \blank, \space, \space];

~blank_dict = [~blank_codes, [
	\blank, ~synthdef, ~blank_freq, ~blank_rq, ~blank_dt
].flop].lace(~blank_codes.size*2).asDict; // blank characters dictionary


//-------------------------------------------------------------------------------------------//


// POEMS' PATHS
~sang_poem = [
	"Laborintus 15.txt".resolveRelative,
	"Laborintus 23.txt".resolveRelative,
	"Erotopaegnia 4.txt".resolveRelative,
	"Purgatorio de l'Inferno 1.txt".resolveRelative,
	"TAT 1.txt".resolveRelative,
	"Reisebilder 23.txt".resolveRelative,
	"Stracciafoglio 46.txt".resolveRelative,
	"FC Pièce en forme de cube.txt".resolveRelative,
	"FC Rompilingua scioglitesta.txt".resolveRelative,
	"FC Albedo.txt".resolveRelative,
	"FC per Tano Brancato.txt".resolveRelative,
	"Alfabeto apocalittico T.txt".resolveRelative,
	"EC Nespoleide 1.txt".resolveRelative,
	"FAN Opus 89.txt".resolveRelative,
	"Corollario 34.txt".resolveRelative,
	"VE La ginestra.txt".resolveRelative,
	"VE Scrabble.txt".resolveRelative,
	"VE Il suono del teatro (primo getto).txt".resolveRelative,
	"Omaggio a Dürer M4.txt".resolveRelative,
	"9FPL Girotondo.txt".resolveRelative
];

// POEM READER FUNCTION
~poem = {|path|
	var f = File(path, "r"); // read text from path
	var t = f.readAllString;
	f.close;
	t; // return text as string
};

/* SONIFICATION ALGORITHM */

~pos = [0, 0]; // alpha and extra position on speakers
~vol = [0, 0]; // alpha and extra volume in dB
~blank = [0, 0]; // blank pos and vol (separate from alpha and extra because of GUI design)
~time = 2.5; // speed on GUI (0.25s)
~multi = 0; // multilingual modality -> 0 off / 1 on

~player = Task({ // pausable process
	var char, val, dict;

	// dictionaries by prefix (prefixes as keys)
	var noPrefix_dict = ~alpha_dictS[~multi] ++ ~num_dict ++ ~punct_dict ++ ~blank_dict;
	var prefix128_dict = [-128 -> ~punct128_dict].asDict;
	var prefix68_dict = [-68 -> ~greekStress_dict[2]].asDict;
	var prefix67_dict = [-67 -> ~greekStress_dict[1]].asDict;
	var prefix65_dict = [-65 -> ~greekStress_dict[0]].asDict;
	var prefix62_dict = [-62 -> ~punct62_dict].asDict;
	var prefix61 = ~stressAlpha_dictS[~multi] ++ ~punct61_dict;
	var prefix61_dict = [-61 -> prefix61].asDict;
	var prefix59_dict = [-59 -> ~alpha59_dictS[~multi]].asDict;
	var prefix50_dict = [-50 -> ~greek_dict[0]].asDict;
	var prefix49_dict = [-49 -> ~greek_dict[1]].asDict;
	var prefix31 = prefix65_dict ++ prefix67_dict ++ prefix68_dict;
	var prefix31_dict = [-31 -> prefix31].asDict;
	var prefix30_dict = [-30 -> prefix128_dict].asDict;
	var prefix_dict = prefix62_dict ++ prefix61_dict ++ prefix59_dict ++ prefix50_dict ++ prefix49_dict;
	var prefixES_dict = prefix31_dict ++ prefix30_dict;

	~text.do{ // text reading character by character
		|item, index|

		item = item.asUnicode; // item conversion in Unicode value

		char = case // prefixes VS characters

		// if item == key in noPrefix_dict -> value []
		{noPrefix_dict.includesKey(item)} {val = noPrefix_dict[item]}
		// if item == -62 or -61 or -59 or -50 or -49 (characters with 1 prefix) -> dict
		{prefix_dict.includesKey(item)} {dict = prefix_dict[item]}
		// if item == -31 or -30 (characters with 2 prefixes) -> dict
		{prefixES_dict.includesKey(item)} {dict = prefixES_dict[item]}
		 // if previous item == -62 or -61 or -59 or -50 or -49 -> item == key in previous dict -> value []
		{prefix_dict.includesKey(~text[index-1].asUnicode)} {val = dict[item]}
		// if item == -68 or -67 or -65 or -128 && previous item == -31 or -30 -> dict
		{prefixES_dict.includesKey(~text[index-1].asUnicode)} {dict = dict[item]}
		// if previous item == -68 or -67 or -65 or -128 && the previous before == -31 or -30 -> item == key in previous dict -> value []
		{prefixES_dict.includesKey(~text[index-2].asUnicode)} {val = dict[item]};

		if (char == val) // only [] of values (characters)
		{
			case // alpha VS extra VS blank

			{char[0] === \alpha} // if [\alpha, ...] character -> \latin or \greek synth
			{Synth(char[1], [\freq1, char[2].midicps, \freq2, char[3].midicps, \up, char[4], \stress, char[5], \stress_freq, char[6], \stress_dc, char[7], \double, char[8], \pos, ~pos[0], \amp, ~vol[0]])}
			{char[0] === \extra} // if [\extra, ...] character -> \number or \punct synth
			{Synth(char[1], [\freq, char[2], \incr1, char[3], \incr2, char[4], \kfreq, char[5], \dc, char[6], \curve, char[7], \double, char[8], \pos, ~pos[1], \amp, ~vol[1]])}
			{char[0] === \blank} // if [\blank, ...] character -> \blank or \space synth
			{Synth(char[1], [\freq, char[2], \rq, char[3], \delaytime, char[4], \pos, ~blank[0], \amp, ~blank[1]])};

			(~time*0.1).wait; // time in seconds
		};
	};
});


//-------------------------------------------------------------------------------------------//


/* GUI */

// basic dimensions
~width = 400;
~height = ~width*1.5;
~width_new = ~width*2.8;
~step = ~width*0.05;
~font = ~width*0.030;
~tab_font = ~width*0.072;

// textview
~textview_x = ~width;
~textview_width = ~width_new-~width-~step;
~textview_height = ~height-(~step*2);

// menu
~menu_width = ~width-(~step*2);
~menu_height = ~width*0.1;
~menu_font = ~width*0.035;

// buttons
~button_width = (~width-(~step*4))/3;
~button_height = ~menu_height;

~multi_y = ~menu_height+(~step*2);

~canc_x = ~button_width+(~step*2);
~canc_y = ~multi_y;

~show_x = (~button_width*2)+(~step*3);
~show_y = ~canc_y;

~play_y = (~menu_height*2)+(~step*3);

~stop_x = ~canc_x;
~stop_y = ~play_y;

~pause_x = ~show_x;
~pause_y = ~play_y;

// speed slider
~slider_x = ~step+(~button_width*0.5);
~slider_y = ~pause_y+~button_height+~step;
~slider_width = ~width-~button_width-(~step*2);
~slider_height = ~button_height;

// speed label
~labels_font = ~width*0.03;
~slider_labels = ["SPEED", ~time.asString];
~slider_label_x = (~button_width*0.5)+~slider_width;
~slider_labels_y = ~slider_y;
~slider_labels_width = ~button_width*0.5;

// alpha and extra labels
~labels = ["ALPHA", "EXTRA"];
~labels_font_y = ~width*0.06;
~labels_x = ~width-(~step*3)-(~width*0.02);
~labels_y = (~menu_height*4)+(~step*9.4);

// alpha and extra pan controls
~pan_dim = (~width-(~step*5.5))/3;
~pan_x = ~width-(~pan_dim+(~step*4));
~pan_y = (~menu_height*4)+(~step*5);

// alpha and extra volume controls
~level_dim = ~pan_dim*1.3;
~level_x = ~width-(~step*2)-~level_dim;
~level_y = ~height-(~step)-~level_dim;

// volume label
~level_label_width = ~button_width;
~level_label_x = (~width*0.5)-(~level_label_width*0.5);
~level_label_y = ~height-(~step*2)-~labels_font;

// blank pan and volume controls
~blank_knobs_dim = ~pan_dim;
~blank_knobs_x = (~width*0.5)-(~blank_knobs_dim*0.5);
~blank_knobs_y = ~slider_y+~slider_height+(~step*1.5);

// blank label
~blank_label = "BLANK";
~blank_label_x = (~width*0.5)-(~step*2.7);
~blank_label_y = ~blank_knobs_y+~blank_knobs_dim+(~step*0.5);
~labels_font_x = ~labels_font_y;

// colors
~gray_dark = Color.gray(0.12);
~gray = Color.gray(0.2);
~gray_light = Color.gray(0.7);
~white = Color.white;
~green = Color.green;
~red = Color.red;
~yellow = Color.yellow;


w = Window("Player", Rect(50, 50, ~width, ~height))
.background_(~gray_dark)
.front;

// textview
t = TextView(w, Rect(~textview_x, ~step, ~textview_width, ~textview_height))
.font_(Font.monospace(~font))
.palette_(QPalette.dark)
.tabWidth_(~tab_font)
.editable_(false)
.hasVerticalScroller_(true)
.visible_(false); // press SHOW TEXT button for .visible_(true)


// menu
m = PopUpMenu(w, Rect(~step, ~step, ~menu_width, ~menu_height))
.items_([
	// poems' titles
	"Laborintus 15.",
	"Laborintus 23.",
	"Erotopaegnia 4.",
	"Purgatorio de l'Inferno 1.",
	"TAT 1.",
	"Reisebilder 23.",
	"Stracciafoglio 46.",
	"Pièce en forme de cube",
	"Rompilingua scioglitesta",
	"Albedo",
	"per Tano Brancato",
	"Alfabeto apocalittico - T",
	"Nespoleide 1.",
	"Opus 89",
	"Corollario 34.",
	"La ginestra",
	"Scrabble",
	"Il suono del teatro (primo getto)",
	"Omaggio a Dürer - M4",
	"Nove filastrocche per Luca - Girotondo"
])
.background_(~gray)
.stringColor_(~white)
.font_(Font.monospace(~menu_font, bold:true))
.value_(nil)
.action_({|me|
	// change text
	~text = ~poem.(~sang_poem[me.value]);
	t.string_(~text);
	t.refresh;
	// reset
	~player.stop;
	p.value_(0);
	~speed[0].valueAction_(2.5.linlin(1, 5, 0, 1));
	~pan.do{|pan|
		pan.valueAction_(0.linlin(-1, 1, 0, 1))
	};
	~blank_knobs[0].valueAction_(0.linlin(-1, 1, 0, 1));
	~level.do{|level|
		level[0].valueAction_(0.curvelin(-96, 0, 0, 1, -4))
	};
	~blank_knobs[1].valueAction_(0.curvelin(-96, 0, 0, 1, -4))
});

// highlighted text replace whole text -> possibility to listen to only some parts
t.mouseUpAction_({~text = t.selectedString});


// multilingual on/off
Button(w, Rect(~step, ~multi_y, ~button_width, ~menu_height))
.font_(Font("Arial", ~labels_font))
.states_([["MULTI OFF", ~white, ~gray], ["MULTI ON", ~white, ~gray]])
.action_({|me|
	if (~player.isPlaying == false && p.value == 0)	// change codes-pitches pairing only if player is not playing (but not during pause)
		{~multi = me.value}
		{me.value = ~multi}
});

// cancel selection
Button(w, Rect(~canc_x, ~canc_y, ~button_width, ~menu_height))
.font_(Font("Arial", ~labels_font))
.states_([["CANC SELECT", ~white, ~gray]])
.action_({if (m.value != nil) {~text = ~poem.(~sang_poem[m.value])}});
// click on textview -> text no more hightlighted BUT entire line selected -> need to be replaced with whole text

// show/hide text
Button(w, Rect(~show_x, ~show_y, ~button_width, ~menu_height))
.font_(Font("Arial", ~labels_font))
.states_([["SHOW TEXT", ~white, ~gray], ["HIDE TEXT", ~white, ~gray]])
.action_({|me|
	if (m.value != nil) // only after selecting text
	{
		if (me.value == 0)
		{w.setInnerExtent(~width, ~height); t.visible_(false)}
		{w.setInnerExtent(~width_new, ~height); t.visible_(true)} // bigger window + visible textview
	}
	{me.value_(0)} // otherwise nothing happens
});

// play
Button(w, Rect(~step, ~play_y, ~button_width, ~menu_height))
.font_(Font("Arial", ~labels_font))
.states_([["PLAY", ~green, ~gray]])
.action_({if (p.value == 0) {~player.start}}); // play sound from the start

// stop
Button(w, Rect(~stop_x, ~stop_y, ~button_width, ~menu_height))
.font_(Font("Arial", ~labels_font))
.states_([["STOP", ~red, ~gray]])
.action_({~player.stop; p.value_(0)}); // stop sound

// pause
p = Button(w, Rect(~pause_x, ~pause_y, ~button_width, ~menu_height))
.font_(Font("Arial", ~labels_font))
.states_([["PAUSE", ~yellow, ~gray], ["RESUME", ~gray, ~yellow]])
.action_({|me|
	if (me.value == 0)
	{~player.resume}
	{if (~player.isPlaying == true) {~player.pause} {me.value_(0)}} // pause sound and resume from that point
});


// speed slider
~speed = [
	Slider(w, Rect(~slider_x, ~slider_y, ~slider_width, ~slider_height))
	.knobColor_(~gray_dark)
	.background_(~gray)
	.value_(~time.linlin(1, 5, 0, 1)) // 2.5 default
	.step_(8.reciprocal), // higher to lower speed -> 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5

	// SPEED label  ||||slider||||  value label
	Array.fill(~slider_labels.size, {|i|
		StaticText(w, Rect(~step+(~slider_label_x*i), ~slider_labels_y, ~slider_labels_width, ~slider_height))
		.font_(Font("Arial", ~labels_font))
		.stringColor_(~white)
		.string_(~slider_labels[i])
		.align_(\center)
	})
];

~speed[0].action_({|me|
	~time = me.value.linlin(0, 1, 1, 5); // update time
	~speed[1][1].string_(~time.value.asString); // update value label
});


// alpha and extra labels
~labels.do{|label, ind|
	label.do{|letter, index|
		StaticText(w, Rect((~step*1.5)+(~labels_x*ind), ~labels_y+(~labels_font_y*index), ~labels_font, ~labels_font)) // vertical + spaced letters
		.font_(Font("Arial", ~labels_font))
		.stringColor_(~white)
		.string_(letter);
	}
};

// blank label
~blank_label.do{|letter, index|
	StaticText(w, Rect(~blank_label_x+(~labels_font_x*index), ~blank_label_y, ~labels_font, ~labels_font)) // horizontal + spaced letters
	.font_(Font("Arial", ~labels_font))
	.stringColor_(~white)
	.string_(letter)
};


// alpha and extra pan knobs
~pan = Array.fill(~pos.size, {|i|
	Knob(w, Rect((~step*2)+(~pan_x*i), ~pan_y, ~pan_dim, ~pan_dim))
	.color_([~gray_light, ~gray_dark, ~gray_dark, ~gray_dark])
	.value_(~pos[i].linlin(-1, 1, 0, 1)) // 0 default
	.action_({|me|
		~pos[i] = me.value.linlin(0, 1, -1, 1); // update pos
	})
});


// blank pan and volume knobs
~blank_knobs = Array.fill(~blank.size, {|i|
	Knob(w, Rect(~blank_knobs_x-(((~level_dim-~blank_knobs_dim)*0.5)*i), ~blank_knobs_y+(((~step*1.5)+~blank_knobs_dim)*i), ~blank_knobs_dim*(1+(0.3*i)), ~blank_knobs_dim*(1+(0.3*i))))
	// centered BUT not along the same horizontal line as alpaha and extra controls
});

// blank pan
~blank_knobs[0].color_([~gray_light, ~gray_dark, ~gray_dark, ~gray_dark]) // pan colors
.value_(~blank[0].linlin(-1, 1, 0, 1)) // 0 default
.action_({|me|
	~blank[0] = me.value.linlin(0, 1, -1, 1); // update pos
});
// blank volume
~blank_knobs[1].color_([~gray, ~gray_dark, ~gray_dark, ~gray_dark]) // volume colors
.value_(~blank[1].curvelin(-96, 0, 0, 1, -4)) // 0 default
.action_({|me|
	~blank[1] = me.value.lincurve(0, 1, -96, 0, -4); // update volume
});


// alpha and extra volume knobs
~level = Array.fill(~vol.size, {|i|
	[
		Knob(w, Rect(~step+(~level_x*i), ~level_y, ~level_dim, ~level_dim))
		.color_([~gray, ~gray_dark, ~gray_dark, ~gray_dark])
		.value_(~vol[i].curvelin(-96, 0, 0, 1, -4)), // 0 default

		// VOLUME label
		StaticText(w, Rect(~level_label_x, ~level_label_y, ~level_label_width, ~labels_font))
		.font_(Font("Arial", ~labels_font))
		.stringColor_(~white)
		.string_("VOLUME")
		.align_(\center)
	]
});

~level.do{|level, index|
	level[0].action_({|me|
		~vol[index] = me.value.lincurve(0, 1, -96, 0, -4); // update volume
	})
};


//when window is closed
w.onClose_({
	~player.stop; // stop sound
	~text = nil; // reset text selection
});
)