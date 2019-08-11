import 'dart:io';

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
    setState(() {
      _faceImage = faceFile;
    });
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

  @override
  Widget build(BuildContext context) {
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
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    InkWell(
                      onTap: null,
                      child: _faceImage == null
                          ? Material(
                              color: Colors.purple,
                              child: Center(
                                child: Text("License Plate"),
                              ),
                            )
                          : Image.file(_faceImage),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      color: Colors.orange,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Image.file(_faceImage),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
