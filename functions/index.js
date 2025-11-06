const { onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');

initializeApp();

// Deploy this function to asia-northeast1
exports.testPushNotification = onRequest(
  { region: ['asia-northeast1'] },
  async (req, res) => {
    const { FCM_Token, title, body } = req.body;

    if (!FCM_Token || !title || !body) {
      res.status(400).send('Missing required fields: FCM_Token, title, body');
      return;
    }


    const payload = {
      notification: {
        title: title,
        body: body,
        image: 'https://png.pngtree.com/png-clipart/20230926/original/pngtree-minimalist-vector-of-couple-hugging-in-single-line-art-vector-png-image_12871561.png',
      },
      android: {
        notification: {
          channelId: 'high_importance_channel', 
          sound: 'sound', 
          defaultSound: true,
          priority: 'high',
          notificationCount: 1,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            alert: {
              title: title,
              body: body,
            },
          },
        },
      },
      token: FCM_Token,
    };


    try {
      const response = await getMessaging().send(payload);
      logger.info('Notification sent:', response);
      res.status(200).send('Notification sent successfully!');
    } catch (error) {
      logger.error('Error sending notification:', error);
      res.status(500).send('Notification failed: ' + error.message);
    }
  }
);
