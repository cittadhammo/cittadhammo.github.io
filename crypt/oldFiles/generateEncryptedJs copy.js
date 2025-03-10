const fs = require('fs');
const readline = require('readline');
const CryptoJS = require('crypto-js');

// Set up readline interface for password input
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: true
});

rl.stdoutMuted = true;

// Prompt the user for the password
rl.question('Enter the password to encrypt the file: ', (password) => {
    // Specify the input Markdown file and the output JavaScript file paths
    const inputFilePath = 'input.md';  // Replace with your Markdown file path
    const outputJsFilePath = 'encryptedContent.js'; // Output JS file for encrypted content

    // Read the Markdown file
    fs.readFile(inputFilePath, 'utf8', (err, data) => {
        if (err) {
            console.error('Error reading the file:', err);
            rl.close();
            return;
        }

        // Encrypt the file content using the provided password
        const encrypted = CryptoJS.AES.encrypt(data, password).toString();

        // Generate the JS file content
        const jsContent = `const encryptedContent = "${encrypted}";`;

        // Write the content to the JS file
        fs.writeFile(outputJsFilePath, jsContent, (err) => {
            if (err) {
                console.error('Error writing the JS file:', err);
            } else {
                console.log('\nEncrypted content saved to', outputJsFilePath);
            }
            rl.close();
        });
    });
});

// Handle input masking (for password hiding)
rl._writeToOutput = function _writeToOutput(stringToWrite) {
    if (rl.stdoutMuted) {
        rl.output.write("*");
    } else {
        rl.output.write(stringToWrite);
    }
};
