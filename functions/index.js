const functions = require('firebase-functions');
const crypto = require('crypto');

class PaytmChecksum {

    static async encrypt(input, key) {
        const cipher = crypto.createCipheriv('AES-128-CBC', key, PaytmChecksum.iv);
        let encrypted = cipher.update(input, 'binary', 'base64');
        encrypted += cipher.final('base64');
        return encrypted;
    }

    static async decrypt(encrypted, key) {
        const decipher = crypto.createDecipheriv('AES-128-CBC', key, PaytmChecksum.iv);
        let decrypted = decipher.update(encrypted, 'base64', 'binary');
        try {
            decrypted += decipher.final('binary');
        } catch (e) {
            console.log(e);
        }
        return decrypted;
    }

    static async generateSignature(params, key) {
        if (typeof params !== 'object' && typeof params !== 'string') {
            const error = 'string or object expected, ' + typeof params + ' given.';
            return Promise.reject(error);
        }
        if (typeof params !== 'string') {
            params = PaytmChecksum.getStringByParams(params);
        }
        return PaytmChecksum.generateSignatureByString(params, key);
    }

    static async verifySignature(params, key, checksum) {
        if (typeof params !== 'object' && typeof params !== 'string') {
            const error = 'string or object expected, ' + typeof params + ' given.';
            return Promise.reject(error);
        }
        if (params.hasOwnProperty('CHECKSUMHASH')) {
            delete params.CHECKSUMHASH;
        }
        if (typeof params !== 'string') {
            params = PaytmChecksum.getStringByParams(params);
        }
        return PaytmChecksum.verifySignatureByString(params, key, checksum);
    }

    static async generateSignatureByString(params, key) {
        const salt = await PaytmChecksum.generateRandomString(4);
        return PaytmChecksum.calculateChecksum(params, key, salt);
    }

    static async verifySignatureByString(params, key, checksum) {
        const paytm_hash = await PaytmChecksum.decrypt(checksum, key);
        const salt = paytm_hash.substr(paytm_hash.length - 4);
        return paytm_hash === PaytmChecksum.calculateHash(params, salt);
    }

    static async generateRandomString(length) {
        return new Promise((resolve, reject) => {
            crypto.randomBytes((length * 3.0) / 4.0, (err, buf) => {
                if (!err) {
                    const salt = buf.toString('base64');
                    resolve(salt);
                } else {
                    console.log('error occurred in generateRandomString: ' + err);
                    reject(err);
                }
            });
        });
    }

    static getStringByParams(params) {
        const data = {};
        Object.keys(params).sort().forEach((key) => {
            data[key] = params[key] !== null && params[key].toLowerCase() !== null ? params[key] : '';
        });
        return Object.values(data).join('|');
    }

    static calculateHash(params, salt) {
        const finalString = params + '|' + salt;
        return crypto.createHash('sha256').update(finalString).digest('hex') + salt;
    }

    static calculateChecksum(params, key, salt) {
        const hashString = PaytmChecksum.calculateHash(params, salt);
        return PaytmChecksum.encrypt(hashString, key);
    }
    static async generateOrderID() {
            // Generate a random order ID using timestamp and some randomness
            const timestamp = new Date().getTime();
            const randomValue = await PaytmChecksum.generateRandomString(8);
            return `ORDER_${timestamp}_${randomValue}`;
        }
}

PaytmChecksum.iv = '@@@@&&&&####$$$$';

// Firebase Cloud Function
exports.loginFunction = functions.https.onRequest(async (req, res) => {
    try {
        // Extract custom amount and order ID from the request or generate them
        const amount = req.body.amount || 1.00; // Replace 100.0 with your default amount
        const orderID = req.body.orderID || (await PaytmChecksum.generateOrderID());

        // Create paytmParams
        const paytmParams = {
            MID: "SPORTS33075460479694",
            ORDERID: orderID,
            // Add other required parameters as needed
        };

        // Generate signature
        const key = "IvfU#eX&#G4BBxYY"; // Replace with your Paytm key
        const signature = await PaytmChecksum.generateSignature(paytmParams, key);

        // Your logic to process the login with order ID, amount, paytmParams, and signature
        // For example, you might want to store this information in a database
        // or perform some authentication logic

        // Respond with the generated order ID, amount, paytmParams, and signature
        res.status(200).json({ orderID, amount, paytmParams, signature });
    } catch (error) {
        console.error(error);
        res.status(500).send('Internal Server Error');
    }
});