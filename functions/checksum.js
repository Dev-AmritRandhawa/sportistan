const functions = require('firebase-functions');
const axios = require('axios');
const express = require('express');
const app = express();
app.use(express.json());

exports.initiatePayment = functions.https.onRequest(async (req, res) => {
    try {



        const paytmParams = {
            body: {
                "requestType": "Payment",
                "mid": "SPORTS33075460479694",
                "websiteName": "DEFAULT",
                "orderId": randomOrderId,
                "callbackUrl": 'https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=${randomOrderId}',
                "txnAmount": {
                    "value": customAmount,
                    "currency": "INR",
                },
                "userInfo": {
                    "custId": "CUST455545454d01",
                },
            }
        };

        // Generate checksum
        const checksum = await PaytmChecksum.generateSignature(JSON.stringify(paytmParams.body), "IvfU#eX&#G4BBxYY");

        paytmParams.head = {
            "signature": checksum
        };

        const post_data = JSON.stringify(paytmParams);

        const options = {
            hostname: 'securegw.paytm.in',
            port: 443,
            path: `/theia/api/v1/initiateTransaction?mid=SPORTS33075460479694&orderId=${randomOrderId}`,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': post_data.length
            }
        };

        // Make the request
        const response = await axios.post(`https://${options.hostname}${options.path}`, post_data, {
            headers: options.headers
        });

        console.log('Final Response:', response.data);

        res.status(200).send(response.data);
    } catch (error) {
        console.error('Error:', error);
        res.status(500).send('Internal Server Error');
    }
});
