"use strict"
const {onCall} = require("firebase-functions/v2/https");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {setGlobalOptions} = require("firebase-functions/v2");
setGlobalOptions({maxInstances: 10});
const https = require('https');
const crypto = require('crypto');

class PaytmChecksum {

	static encrypt(input, key) {
		var cipher = crypto.createCipheriv('AES-128-CBC', key, PaytmChecksum.iv);
		var encrypted = cipher.update(input, 'binary', 'base64');
		encrypted += cipher.final('base64');
		return encrypted;
	}
	static decrypt(encrypted, key) {
		var decipher = crypto.createDecipheriv('AES-128-CBC', key, PaytmChecksum.iv);
		var decrypted = decipher.update(encrypted, 'base64', 'binary');
		try {
			decrypted += decipher.final('binary');
		}
		catch (e) {
			console.log(e);
		}
		return decrypted;
	}
	static async generateSignature(params, key) {
		if (typeof params !== "object" && typeof params !== "string") {
			var error = "string or object expected, " + (typeof params) + " given.";
			return Promise.reject(error);
		}
		if (typeof params !== "string"){
			params = PaytmChecksum.getStringByParams(params);
		}
		return PaytmChecksum.generateSignatureByString(params, key);
	}


	static verifySignature(params, key, checksum) {
		if (typeof params !== "object" && typeof params !== "string") {
		   	var error = "string or object expected, " + (typeof params) + " given.";
			return Promise.reject(error);
		}
		if(params.hasOwnProperty("CHECKSUMHASH")){
			delete params.CHECKSUMHASH
		}
		if (typeof params !== "string"){
			params = PaytmChecksum.getStringByParams(params);
		}
		return PaytmChecksum.verifySignatureByString(params, key, checksum);
	}

	static async generateSignatureByString(params, key) {
		var salt = await PaytmChecksum.generateRandomString(4);
		return PaytmChecksum.calculateChecksum(params, key, salt);
	}

	static verifySignatureByString(params, key, checksum) {
		var paytm_hash = PaytmChecksum.decrypt(checksum, key);
		var salt = paytm_hash.substr(paytm_hash.length - 4);
		return (paytm_hash === PaytmChecksum.calculateHash(params, salt));
	}

	static generateRandomString(length) {
		return new Promise(function (resolve, reject) {
			crypto.randomBytes((length * 3.0) / 4.0, function (err, buf) {
				if (!err) {
					var salt = buf.toString("base64");
					resolve(salt);
				}
				else {
					console.log("error occurred in generateRandomString: " + err);
					reject(err);
				}
			});
		});
	}

	static getStringByParams(params) {
		var data = {};
		Object.keys(params).sort().forEach(function(key,value) {
			data[key] = (params[key] !== null && params[key].toLowerCase() !== null) ? params[key] : "";
		});
		return Object.values(data).join('|');
	}

	static calculateHash(params, salt) {
		var finalString = params + "|" + salt;
		return crypto.createHash('sha256').update(finalString).digest('hex') + salt;
	}
	static calculateChecksum(params, key, salt) {
		var hashString = PaytmChecksum.calculateHash(params, salt);
		return PaytmChecksum.encrypt(hashString,key);
	}
}
    PaytmChecksum.iv = '@@@@&&&&####$$$$';

    exports.statusPaytmTransaction = onRequest(async (req, res) => {
    try {
        // Assuming the request body contains the necessary parameters including amount
        const { mid } = req.body;
        const { orderId } = req.body;


        var paytmParams = {
            body: {
                "mid": mid,
                "orderId": orderId,
            },
        };

        const checksum = await PaytmChecksum.generateSignature(JSON.stringify(paytmParams.body), "IvfU#eX&#G4BBxYY");

        paytmParams.head = {
            "signature": checksum,
        };

        var post_data = JSON.stringify(paytmParams);

           var options = {
               hostname: 'securegw.paytm.in',
               port: 443,
               path: '/v3/order/status',
               method: 'POST',
               headers: {
                   'Content-Type': 'application/json',
                   'Content-Length': post_data.length
               }
           };

        var response = "";
        var post_req = https.request(options, function (post_res) {
            post_res.on('data', function (chunk) {
                response += chunk;
            });


            post_res.on('end', function () {
                res.status(200).send(response);
            });
        });

        post_req.write(post_data);
        post_req.end();
    } catch (error) {
        res.status(500).send('Internal Server Error'+error);
    }
});