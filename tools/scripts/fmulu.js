const maxbytes = 16;
const maxcycles = 50;

// helper function to generate move instructions
function move() {
	bytes += 2;
	cycles += 4;
	ln += "		move.\\0	\\dst,\\fre			; 4	; copy dst to fre\n";
}

// helper function to generate add instructions
function add(src, dst, tx) {
	bytes += 2;
	cycles += 4;
	ln += "		add.\\0	\\" + src + ",\\" + dst + "			; 4	; " + tx + "x the value\n";
}

// helper function to generate lsl instructions
function lsl(ct, dst, tx) {
	let cyc = 6 + (2 * ct);
	bytes += 2;
	cycles += cyc;
	ln += "		lsl.\\0	#" + ct + ",\\" + dst + "				; " + cyc + "	; " + tx + "x the value\n";
}

var cycles, bytes, ln;
let str = 
"=0		clr.\\0	\\dst					; clear\n"+
"=1								; no-op\n";

// loop between 2 and FFFF
for (let i = 2; i <= 0x100;i ++){
	ln = "="+ i;

	// check the number of bits that need to be shifting
	let sl = 0, fret = 1, dstt = 1, state = 0;
	cycles = 0; bytes = 0;

	for(let bit = 0;bit < 16;bit++){
		if((i & (1 << bit)) != 0){

			// bit is set, get the multiplication code
			switch(state) {
				case 0:
					// state=0: initial register offset
					++state;

					switch (sl) {
						case 0: break;
						case 2:
							add("dst", "dst", dstt <<= 1);

						case 1:
							add("dst", "dst", dstt <<= 1);
							break;

						case 3: case 4: case 5: case 6: case 7: case 8:
							lsl(sl, "dst", dstt <<= sl);
							break;

						default:
							break;
					}
					break;
				
				case 1:
					// state=1: without move
					move();
					fret = dstt;
					++state;
				
				case 2:
					// state=2: with move
					switch (sl) {
						case 2: case 3: case 4: case 5: case 6: case 7: 
							lsl(sl + 1, "fre", fret <<= (sl + 1));
							add("fre", "dst", dstt += fret);
							break;

						case 1:
							add("fre", "fre", fret <<= 1);

						case 0:
							add("fre", "fre", fret <<= 1);
							add("fre", "dst", dstt += fret);
							break;

						default:
							break;
					}
					break;
			}

			sl = 0;
		} else sl++;
	}

	if(cycles < maxcycles && bytes < maxbytes){
		// add to str
		str += "; --------------------------------------------------------------\n";
		str += "	; "+ cycles +" cycles, "+ bytes +" bytes\n";
		str += ln;
	}
}

console.log(str);