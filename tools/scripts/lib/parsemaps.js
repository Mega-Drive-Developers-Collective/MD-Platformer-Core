const fs = require('fs');

// various regexes for parsing
const rexLabel = new RegExp("^(\\s*(\\.?\\@?[A-z0-9_]+):)", "i");
const rexLabel2 = new RegExp("^((\\.?\\@?[A-z0-9_]+):?)", "i");

const rexData = new RegExp("^\\s*dc(\\.[bwl])?((\\s*(\\$[A-F0-9]{1,4}|[0-9][A-F0-9]{0,4}h|\\d{1,6}),?)+)\\s*$", "i");
const rexData2 = new RegExp("\\$?[A-F0-9]+h?", "gi");
const rexOffs = new RegExp("^\\s*dc(\\.w)?((\\s*(([A-Z0-9_\\.]+)-([A-Z0-9_\\.]+)|\\$[0-9A-F]+|\\d+),?)+)\\s*$", "i");
const rexOffs2 = new RegExp("[^-,]+(?=-[^-,]+)", "g");

// function to parse mappings data into binary
const parse = (type, data) => {
	if (!ParseNum) throw { error: "Define global.ParseNum as parsenumber.js" };
	if (!NumToBytes) throw { error: "Define global.NumToBytes as numtobytes.js" };

	let obj = { "-list": [], "-order": [] };
	let label = null;

	for(let line of data.toString().split(/\r?\n/g)){
		// split the comment out
		let comment = line.indexOf(";");
		if (comment >= 0) line = line.substring(0, comment);

		// check if there is a label
		let rx = line.match(rexLabel);

		if (!rx || !rx.length)
			rx = line.match(rexLabel2);

		if (rx && rx.length) {
			// does contain a label
			label = rx[2];
			line = line.substring(rx[0].length);

			// create label data
			if (!obj[label])
				obj[label] = [];

			obj["-order"].push(label);
		}

		// check for data
		rx = line.match(rexData);

		if (rx && rx.length) {
			// does contain data
			line = line.substring(rx[0].length);

			// figure out the instruction size
			let size = 2, offset = 2;

			switch(rx[1].toLowerCase()){
				case ".w": break;
				case ".b": size = 1; break;
				case ".l": size = 4; break;
				default: offset--;
			}

			// process all the different bytes
			rx = rx[offset].match(rexData2);

			for(let i = 0;i < rx.length;i ++){
				// attempt to parse value
				let num = ParseNum(rx[i].trim());
				if(num == null || num !== num)
					throw { error: "Can not parse number", data: rx[i].trim() };

				// convert to bytes
				num = NumToBytes(num, size, true);
				if (!num)
					throw { error: "Can not convert to bytes", data: rx[i].trim() };

				// put all bytes in there
				num.forEach((b) => obj[label].push(b));
			}

		} else {
			// check for offset
			rx = line.match(rexOffs);

			if (rx && rx.length) {
				line = line.substring(rx[0].length);

				// process each label
				rx = rx[2].match(rexOffs2);

				for (let i = 0; i < rx.length; i ++) {
					// put the label in
					obj["-list"].push(rx[i].trim());
				}
			} 
		}

		// check for invalid data
		let extra = line.trim();
		if (extra.length > 0) {
			// check if this data is acceptable
			switch(extra.toLowerCase()){
				default:
					throw { error: "Invalid data detected", data: line.trim() };

				case "even": break;
			}
		}
	}

	// convert into data
	let hsz = obj["-list"].length * 2;
	let dat = [];

	// do header
	for (let i = 0; i < obj["-list"].length;i ++){
		let offs = 0;

		// find the offset in data where this pointer is at
		for (let x = 0; x < obj["-order"].length;x ++){
			if (obj["-order"][x] === obj["-list"][i])
				break;

			offs += obj[obj["-order"][x]].length;
		}

		// convert the offset
		let d = NumToBytes(offs + hsz, 2, true);
		if (!d) throw { error: "Can not convert table offset", data: offs + hsz };

		// put all bytes in there
		d.forEach((b) => dat.push(b));
	}

	// do data
	for(let x in obj){
		if (!x.startsWith("-")) {
			// put all bytes in there
			obj[x].forEach((b) => dat.push(b));
		}
	}

	return dat;
}

module.exports = {
	parse: parse,
	parseFile: (type, file) => {
		return new Promise((res, rej) => {
			// attempt to read the input file
			fs.readFile(file, (err, data) => {
				if(err) rej(err);

				try {
					// try to parse the data
					res(parse(type, data));

				} catch(ex){
					rej(ex);
				}
			});
		});
	}
};
