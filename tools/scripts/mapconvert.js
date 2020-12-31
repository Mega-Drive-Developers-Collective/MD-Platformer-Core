const Parser = require("./lib/parsemaps.js");
global.ParseNum = require("./lib/parsenumber.js");
global.NumToBytes = require("./lib/numtobytes.js");
const fs = require("fs");

if (process.argv.length < 6){
	console.log("node mapconvert.js informat type input.asm output.asm");
	console.log();
	console.log("informat must be:");
	console.log("1 = Sonic 1");
	console.log("2 = Sonic 2 (not implemented will not work)");
	console.log("3 = Sonic 3K (not implemented will not work)");
	console.log("4 = Sonic 3K Players");
	console.log();
	console.log("type must be:");
	console.log("sprite = normal object mappings");
	console.log("dyn = dynamic art mappings");
	return;
}

// convert type parameter
let type =	process.argv[3].toLowerCase() == "sprite" ? true : 
			process.argv[3].toLowerCase() == "dyn" ? false : null;

if (type === null) {
	console.log("Invalid type parameter, use 'sprite' or 'dyn'.");
	return;
}

// convert informat parameter
let format = null;

switch (parseInt(process.argv[2])) {
	case 1: case 2: case 3: case 4:
		format = parseInt(process.argv[2]);
		break;
}

if (format === null) {
	console.log("Invalid informat parameter, use '1', '2', '3' or '4'.");
	return;
}

// ASM
Parser.parseFile(0, process.argv[4]).then((data) => {
	// prepare varaibles
	let frames = [];
	let addr = 0xFFFFFFFF;

	// loop for all frames
	while (frames.length * 2 < addr){
		let a = (data[frames.length * 2] << 8) | (data[frames.length * 2 + 1]);
		if (addr > a) addr = a;

		// add the converted frame data
		frames.push(global[type ? "_convertMaps" : "_convertDPLC"](data, a));
	}

	// convert into asm
	let label = ".map", head = label, body = "", frame = 1;

	for(let f of frames) {
		if(f.length == 0) {
			head += "\t\tdc.w 0\n";
			continue;
		}

		// normal frame
		head += "\t\tdc.w .f"+ frame +"-"+ label +"\n";
		body += "\n.f" + frame++;

		// convert every argument
		for (let i = 0; i < f.length; i++) {
			let last = i + 1 == f.length;

			if(type){
				// sprite mappings
				body += "\t\tsprit" + (last ? "t" : "e") + " $" + hex(f[i].tile, 4) + ", " + (((f[i].size & 0xC) >> 2) + 1) + ", " + ((f[i].size & 0x3) + 1) + ", $" + hex(f[i].x, 4) + ", $" + hex(f[i].y, 4) +"\n";

			} else {
				// dynamic mappings
				body += "\t\tdynpc $" + hex(f[i].tile, 3) + ", " + f[i].length +"\n";
				if (last) body += "\t\tdynpe\n";
			}
		}
	}

	// print to file
	fs.writeFile(process.argv[5], head + body, (err) => {
		if (err) throw err;
		console.log("completed!");
	});

}).catch((ex) => { throw ex; });

// function to print a hex string
function hex(val, len) {
	return (val >= 0 ? val : 0x10000 + val).toString(16).toUpperCase().padStart(len, '0');
}

// function to convert DPLC data into appropriate format
global._convertDPLC = (data, addr) => {
	let out = [];
	let entries = 0;

	// convert num of entries
	switch (format) {
		case 1: // byte
			entries = data[addr++];
			break;

		default: // word
			entries = (data[addr++] << 8) | data[addr++];
			break;
	}

	// loop for every entry
	for (; entries > 0; --entries) {
		switch (format) {
			case 1: // Sonic 1
			case 4: // Sonic 3K Player
				let d = (data[addr++] << 8) | data[addr++];
				out.push({ full: d, length: ((d & 0xF000) >> 12) + 1, tile: (d & 0xFFF)  });
				break;
		}
	}

	return out;
};

// function to convert map data into appropriate format
global._convertMaps = (data, addr) => {
	let out = [];
	let entries = 0;

	// convert num of entries
	switch (format) {
		case 1: // byte
			entries = data[addr++];
			break;

		default: // word
			entries = (data[addr++] << 8) | data[addr++];
			break;
	}

	// loop for every entry
	for (; entries > 0; --entries) {
		switch (format) {
			case 1: // Sonic 1
				out.push({ y: _sex(data[addr++]), size: data[addr++], tile: (data[addr++] << 8) | data[addr++], x: _sex(data[addr++]) });
				break;

			case 3: case 4: // Sonic 3K
				out.push({ y: _sex(data[addr++]), size: data[addr++], tile: (data[addr++] << 8) | data[addr++], x: _sign((data[addr++] << 8) | data[addr++]) });
				break;
		}
	}

	return out;
};

// sign extend from byte to word
const _sex = (data) => data >= 0x80 ? -(0x100 - data) : data;

// change unsigned word to signed word
const _sign = (data) => data >= 0x8000 ? -(0x10000 - data) : data;