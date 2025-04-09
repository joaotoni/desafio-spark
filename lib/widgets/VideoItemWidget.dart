import 'package:desafio_tecnico_spark/models/VideoModel.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoItemWidget extends StatefulWidget {
  final VideoModel video;
  final bool play;

  const VideoItemWidget({
    Key? key,
    required this.video,
    required this.play,
  }) : super(key: key);

  @override
  State<VideoItemWidget> createState() => _VideoItemWidgetState();
}

class _VideoItemWidgetState extends State<VideoItemWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    if (widget.video.url.isEmpty) {
      return;
    }

    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
            ..initialize().then((_) {
              if (widget.play) _controller.play();
              setState(() {});
            })
            ..addListener(() {
              if (_controller.value.hasError) {
                print(
                    'Erro ao reproduzir vídeo: ${_controller.value.errorDescription}');
                setState(() {});
              }
            });
    } catch (e) {
      print('Erro ao inicializar VideoPlayerController: $e');
    }
  }

  @override
  void didUpdateWidget(covariant VideoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video.url != widget.video.url) {
      _controller.pause();
      _controller.dispose();

      _controller = VideoPlayerController.network(widget.video.url);
      _controller.initialize().then((_) {
        setState(() {
          if (widget.play) _controller.play();
        });
      });
    } else {
      if (widget.play && !_controller.value.isPlaying) {
        _controller.play();
      } else if (!widget.play && _controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _controller.value.isInitialized
            ? VideoPlayer(_controller)
            : const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.video.authorAvatar),
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.video.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
