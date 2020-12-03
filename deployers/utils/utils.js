const fs = require('fs');
const { resolve } = require('path');
const fsPromises = fs.promises;

async function getCurrentDir() {
	return resolve('./', '');
}

async function getFile(dir, filename) {
  const dirents = await fsPromises.readdir(dir, { withFileTypes: true });
  const files = await Promise.all(dirents.map((dirent) => {
    const res = resolve(dir, dirent.name);
    return dirent.isDirectory() ? getFile(res, filename) : res;
  }));
  const arr = Array.prototype.concat(...files);

  return arr.filter(s => s.includes(filename))
}

async function changeConstantInFile(dir, filename, variable, value) {
	const filepath = (await getFile(dir, filename))[0]

	const data = await fsPromises.readFile(filepath, 'utf8');

	const regexWithSpace = new RegExp(`${variable} =.*`, "g");
	const regexWithoutSpace = new RegExp(`${variable}=.*`, "g");

	let result = data.replace(regexWithSpace, `${variable} = ${value};`);
	result = result.replace(regexWithoutSpace, `${variable} = ${value};`);

  	await fsPromises.writeFile(filepath, result, 'utf8');
}

module.exports = {
	getFile,
	changeConstantInFile,
	getCurrentDir
}