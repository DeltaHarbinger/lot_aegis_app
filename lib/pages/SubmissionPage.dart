import 'dart:io';

import 'package:flutter/services.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

class SubmissionPage extends StatefulWidget {
  File _faceImage;
  File _licensePlateImage;

  SubmissionPage(this._faceImage, this._licensePlateImage);

  @override
  _SubmissionPageState createState() =>
      _SubmissionPageState(_faceImage, _licensePlateImage);
}

class _SubmissionPageState extends State<SubmissionPage> {
  PageController _controller = PageController();
  File _faceImage;
  File _licensePlateImage;
  List<Face> _faces;
  List<String> _plateInfo;

  _SubmissionPageState(this._faceImage, this._licensePlateImage);

  Future _getFacesFromImage() async {
    final faceVisionImage = FirebaseVisionImage.fromFile(_faceImage);
    final faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(mode: FaceDetectorMode.accurate),
    );
    final faces = await faceDetector.detectInImage(faceVisionImage);
    _faces = faces;
    if (faces.length > 0) {
      print("\n\n");
      print("Image details");
      print("Location");
      print(faces.first.boundingBox);
      print("\n\n");
    }
  }

  Future _getLicensePlateInfo() async {
    final licensePlateVisionImage =
        FirebaseVisionImage.fromFile(_licensePlateImage);
    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();
    VisionText identifiedText =
        await textRecognizer.processImage(licensePlateVisionImage);
    print(
      "Text is " +
          (identifiedText.text.length == 0 ? "Unknown" : identifiedText.text),
    );
    for (TextBlock block in identifiedText.blocks) {
      print(block.boundingBox);
      for (TextLine line in block.lines) {
        print(line.boundingBox);
        print(line.text);
        // for (TextElement element in line.elements) {
        //   print(element.text);
        // }
      }
    }
  }

  Future _submitImages() async {
    _getFacesFromImage();
    _getLicensePlateInfo();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView(
        controller: _controller,
        children: <Widget>[
          Image.file(_faceImage),
          Image.file(_licensePlateImage),
        ],
        physics: NeverScrollableScrollPhysics(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_controller.page == 0) {
            _controller.animateToPage(
              1,
              duration: Duration(seconds: 1),
              curve: Curves.easeInOut,
            );
          } else {
            await _submitImages();
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
