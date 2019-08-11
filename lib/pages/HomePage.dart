import 'dart:io';

import 'package:flutter/services.dart';
import './SubmissionPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File _faceImage;
  File _licensePlatesImage;
  List<Face> _faces;
  CameraController _controller;
  Directory _temporaryFolder;

  bool _bothPicturesTaken() {
    return this._faceImage != null && this._licensePlatesImage != null;
  }

  onPicturesTaken() {
    if (_bothPicturesTaken()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SubmissionPage(_faceImage, _licensePlatesImage),
        ),
      );
    }
  }

  Future<List<CameraDescription>> _getAvailableCameras() async {
    return availableCameras();
  }

  Future _loadCamera() async {
    List<CameraDescription> camDescriptions = (await _getAvailableCameras());
    CameraDescription cameraDescription = camDescriptions.first;
    _controller = CameraController(cameraDescription, ResolutionPreset.high);
    await _controller.initialize();
  }

  Future _initStorageInfo() async {
    _temporaryFolder = await getTemporaryDirectory();
  }

  Future _initSequence() async {
    await _loadCamera();
    await _initStorageInfo();
  }

  _getFacesFromCamera() async {
    File faceFile = File(_temporaryFolder.path + DateTime.now().toString());
    if (faceFile.existsSync()) {
      faceFile.deleteSync();
    }
    await _controller.takePicture(faceFile.path);
    if (mounted) {
      setState(() {
        _faceImage = faceFile;
      });
    }
    onPicturesTaken();
  }

  _getLicensePlateFromCamera() async {
    File licensePlateFile =
        File(_temporaryFolder.path + DateTime.now().toString());
    if (licensePlateFile.existsSync()) {
      licensePlateFile.deleteSync();
    }
    await _controller.takePicture(licensePlateFile.path);
    if (mounted) {
      setState(() {
        _licensePlatesImage = licensePlateFile;
      });
    }
    onPicturesTaken();
  }

  Widget _bottomIconFaceSegment() {
    return _faceImage == null
        ? IconButton(
            icon: Icon(
              Icons.camera,
              color: Colors.blue,
            ),
            onPressed: _getFacesFromCamera,
          )
        : IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.orange,
            ),
            onPressed: () {
              // TODO Delete the image from storage also
              setState(() {
                _faceImage.deleteSync();
                _faceImage = null;
              });
            },
          );
  }

  Widget _faceDataSegment() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        _faceImage == null
            ? CameraPreview(_controller)
            : Image.file(_faceImage),
        _bottomIconFaceSegment()
      ],
    );
  }

  Widget _bottomLicensePlateSegment() {
    return _licensePlatesImage == null
        ? IconButton(
            icon: Icon(
              Icons.camera,
              color: Colors.red,
            ),
            onPressed: _getLicensePlateFromCamera,
          )
        : IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.orange,
            ),
            onPressed: () {
              // TODO Delete the image from storage also
              setState(() {
                _licensePlatesImage.deleteSync();
                _licensePlatesImage = null;
              });
            },
          );
  }

  Widget _licensePlateDataSegment() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        _licensePlatesImage == null
            ? CameraPreview(_controller)
            : Image.file(_licensePlatesImage),
        _bottomLicensePlateSegment()
      ],
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      body: FutureBuilder(
        future: _initSequence(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return CircularProgressIndicator();
          }
          return Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width,
                child: _faceDataSegment(),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width,
                child: _licensePlateDataSegment(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _bothPicturesTaken()
          ? FloatingActionButton(
              child: Icon(Icons.send),
              onPressed: onPicturesTaken,
            )
          : Container(),
    );
  }
}
