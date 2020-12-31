module.exports = (str) => {
	let radix = 10;

	if(str.startsWith("0x")){
		// 0xhex
		radix = 16;
		str = str.substring(2);

	} else if (str.startsWith("$")) {
		// $hex
		radix = 16;
		str = str.substring(1);

	} else if (str.startsWith("%")) {
		// %bin
		radix = 2;
		str = str.substring(1);

	} else if (str.startsWith("0b")) {
		// 0bbin
		radix = 2;
		str = str.substring(2);
	}

	// parse number
	return parseInt(str, radix);
};
