"use strict"
const {setGlobalOptions} = require("firebase-functions/v2");
setGlobalOptions({maxInstances: 10});
const https = require('https');
const crypto = require('crypto');
const {onRequest} = require("firebase-functions/v1/https");

class PaytmChecksum {

    static encrypt(input, key) {
        const cipher = crypto.createCipheriv('AES-128-CBC', key, PaytmChecksum.iv);
        let encrypted = cipher.update(input, 'binary', 'base64');
        encrypted += cipher.final('base64');
        return encrypted;
    }

    static decrypt(encrypted, key) {
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
        if (typeof params !== "object" && typeof params !== "string") {
            const error = "string or object expected, " + (typeof params) + " given.";
            return Promise.reject(error);
        }
        if (typeof params !== "string") {
            params = PaytmChecksum.getStringByParams(params);
        }
        return PaytmChecksum.generateSignatureByString(params, key);
    }


    static verifySignature(params, key, checksum) {
        if (typeof params !== "object" && typeof params !== "string") {
            const error = "string or object expected, " + (typeof params) + " given.";
            return Promise.reject(error);
        }
        if (params.hasOwnProperty("CHECKSUMHASH")) {
            delete params.CHECKSUMHASH
        }
        if (typeof params !== "string") {
            params = PaytmChecksum.getStringByParams(params);
        }
        return PaytmChecksum.verifySignatureByString(params, key, checksum);
    }

    static async generateSignatureByString(params, key) {
        const salt = await PaytmChecksum.generateRandomString(4);
        return PaytmChecksum.calculateChecksum(params, key, salt);
    }

    static verifySignatureByString(params, key, checksum) {
        const paytm_hash = PaytmChecksum.decrypt(checksum, key);
        const salt = paytm_hash.substr(paytm_hash.length - 4);
        return (paytm_hash === PaytmChecksum.calculateHash(params, salt));
    }

    static generateRandomString(length) {
        return new Promise(function (resolve, reject) {
            crypto.randomBytes((length * 3.0) / 4.0, function (err, buf) {
                if (!err) {
                    const salt = buf.toString("base64");
                    resolve(salt);
                } else {
                    console.log("error occurred in generateRandomString: " + err);
                    reject(err);
                }
            });
        });
    }

    static getStringByParams(params) {
        const data = {};
        Object.keys(params).sort().forEach(function (key) {
            data[key] = (params[key] !== null && params[key].toLowerCase() !== null) ? params[key] : "";
        });
        return Object.values(data).join('|');
    }

    static calculateHash(params, salt) {
        const finalString = params + "|" + salt;
        return crypto.createHash('sha256').update(finalString).digest('hex') + salt;
    }

    static calculateChecksum(params, key, salt) {
        const hashString = PaytmChecksum.calculateHash(params, salt);
        return PaytmChecksum.encrypt(hashString, key);
    }
}

PaytmChecksum.iv = '@@@@&&&&####$$$$';

exports.statusPaytmTransaction = onRequest(async (req, res) => {
    let post_req;
    try {
        // Assuming the request body contains the necessary parameters including amount
        const {mid} = req.body;
        const {orderId} = req.body;


        const paytmParams = {
            body: {
                "mid": mid,
                "orderId": orderId,
            },
        };

        const checksum = await PaytmChecksum.generateSignature(JSON.stringify(paytmParams.body), "IvfU#eX&#G4BBxYY");

        paytmParams.head = {
            "signature": checksum,
        };

        const post_data = JSON.stringify(paytmParams);

        const options = {
            hostname: 'securegw.paytm.in',
            port: 443,
            path: '/v3/order/status',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': post_data.length
            }
        };

        let response = "";

        post_req = https.request(options, function (post_res) {
            post_res.on('data', function (chunk) {
                response += chunk;
            });
            post_res.on('end', function () {
                res.status(200).send(response);
            });
        });
    } catch (error) {
        res.status(500).send('Internal Server Error' + error);
    } finally {
        post_req.end();
    }

});