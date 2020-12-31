module.exports = (num, size, check) => {
	// check for NaN and floating point numbers
	if(num !== num || (num | 0) !== num)
		return null;

	let ret = [];

	// loop for each byte
	for (let x = size - 1; x >= 0; --x){
		let n = num & (0xFF << (x * 8));
		ret.push((n) >> (x * 8));
		num -= n;
	}
	
	// if there is extra data, indicate we failed
	if (check && num !== 0)
		return null;

	// return data
	return ret;
};
