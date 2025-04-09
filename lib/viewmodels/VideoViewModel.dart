import 'package:desafio_tecnico_spark/models/VideoModel.dart';
import 'package:desafio_tecnico_spark/services/VideoService.dart';
import 'package:flutter/material.dart';

class VideoViewModel extends ChangeNotifier {
  final List<VideoModel> _videos = [];
  final VideoService _service = VideoService();

  List<VideoModel> get videos => _videos;

  void startListening() {
    _service.listenToFirehose((newVideo) {
      if (_videos.length >= 10) return;
      _videos.add(newVideo);
      notifyListeners();
    });
  }
}
