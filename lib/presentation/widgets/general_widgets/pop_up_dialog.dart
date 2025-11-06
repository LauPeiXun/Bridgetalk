import 'package:flutter/material.dart';

class PopUpDialog extends StatelessWidget {
  final String imagePath;
  final String title;
  final String message;
  final VoidCallback? onDialogClosed;

  const PopUpDialog({
    super.key,
    required this.imagePath,
    required this.title,
    required this.message,
    this.onDialogClosed,
  });

  void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return build(context);
      },
    ).then((_) {
      if (onDialogClosed != null) {
        onDialogClosed!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, height: 150, width: 150),
          SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (message != '') ...[
            SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black),
            ),
          ],
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 100),
            ),
            child: Text(
              'Confirm',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
