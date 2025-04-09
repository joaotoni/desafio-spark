import 'package:desafio_tecnico_spark/viewmodels/VideoViewModel.dart';
import 'package:desafio_tecnico_spark/widgets/VideoItemWidget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Provider.of<VideoViewModel>(context, listen: false).startListening();
  }

  @override
  Widget build(BuildContext context) {
    final videos = context.watch<VideoViewModel>().videos;

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: videos.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (_, index) {
          final video = videos[index];
          return VideoItemWidget(
            key: ValueKey(video.url),
            video: video,
            play: index == _currentPage,
          );
        },
      ),
    );
  }
}
