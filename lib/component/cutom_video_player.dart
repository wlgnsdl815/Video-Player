import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final XFile video;
  final VoidCallback onNewVideoPressed;

  const CustomVideoPlayer({
    Key? key,
    required this.video,
    required this.onNewVideoPressed,
  }) : super(key: key);

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? videoController;
  Duration currentPosition =
      Duration(); // 현재 포지션을 매번 currentPosition에 저장 -> 슬라이더를 위해서
  bool showControls = false; // 탭 할 때에 컨트롤들이 보이게 하기 위한 변수

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initializeController();
  }

  @override
  void didUpdateWidget(covariant CustomVideoPlayer oldWidget) {
    // _CustomVideoPlayerState 이 State가 이미 실행되어 있을 때, 파라미터만 변경이 되었을 때 실행한다.
    super.didUpdateWidget(oldWidget);

    if (oldWidget.video.path != widget.video.path) {
      initializeController();
      // 컨트롤러를 초기화해주는 코드를 작성해주면된다.
    }
  }

  // 그냥 initailize는 async로 할 수 없기 때문에 새로운 함수를 만들어서 거기서 async로 만들어준다.
  initializeController() async {
    currentPosition = Duration();
    // 새로 영상을 선택하면, 현재 영상의 위치를 처음으로 돌려놔야 하는데 그게 맞지 않아서 오류가 뜬다.
    // 그래서 현재 포지션을 초기화 시켜주는 코드를 작성

    videoController = VideoPlayerController.file(
      File(widget.video
          .path), // XFile(image_picker에서 사용하는)을 File(flutter에서 사용하는)형태로 변환하는 코드
      // File을 불러 올때에는 무조건 dart.io를 불러야 앱에서 사용가능하다.
    );

    videoController!.addListener(() {
      // videoController의 값이 변경이 되면 실행이 된다. 슬라이더를 위한 작업
      final currentPosition = videoController!.value.position;

      setState(() {
        // 현재 실행되는 포지션을 변경해준다
        this.currentPosition = currentPosition;
      });
    });

    await videoController!.initialize();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 위의 initState()에서 initializeController가 끝나는 걸 기다려 주지 않기 때문에 빌드시에 널이 들어올 수도 있다.
    // 그래서 videoController가 널이면 로딩화면을 띄워준다.
    if (videoController == null) {
      return CircularProgressIndicator();
    }

    return AspectRatio(
      // 동영상의 화면 비율을 맞춰주기 위한 위젯이다.
      aspectRatio: videoController!.value.aspectRatio, // 이 코드를 넣어주면 비율이 맞춰진다.
      child: GestureDetector(
        // 화면을 탭할 때에 컨트롤들이 보이게
        onTap: () {
          setState(() {
            showControls = !showControls;
          });
        },
        child: Stack(
          children: [
            VideoPlayer(
              videoController!,
            ),
            if (showControls)
              _Controls(
                onReversePressed: onReversePressed,
                onPlayPressed: onPlayPressed,
                onForwardPressed: onForwardPressed,
                isPlaying: videoController!.value.isPlaying,
              ),
            if (showControls)
              _NewVideo(
                onPressed: widget.onNewVideoPressed,
              ),
            _SliderBottom(
                currentPosition: currentPosition,
                maxPosition: videoController!.value.duration,
                onSliderChanged: onSliderChanged)
          ],
        ),
      ),
    );
  }

  void onReversePressed() {
    // 뒤로 돌리기 위해서는 2가지가 필요하다
    // 현재 동영상의 위치
    final currentPosition = videoController!.value.position; // 동영상의 위치를 알 수 있다

    Duration position = Duration(); // 포지션은 기본 0초로 설정된다

    if (currentPosition.inSeconds > 3) {
      // 현재 포지션이 3초보다 길면
      position = currentPosition - Duration(seconds: 3); // 현재 위치에서 3초를 빼준다
    }

    videoController!.seekTo(position); // 어떤 위치로 부터 이동을 할 지 정할 수 있다
  }

  void onPlayPressed() {
    // 이미 실행중이면 중지
    // 실행중이 아니면 실행
    setState(() {
      // 빌드를 반영하기 위해서 setState를 해주어야 한다.
      if (videoController!.value.isPlaying) {
        videoController!.pause();
      } else {
        videoController!.play();
      }
    });
  }

  void onForwardPressed() {
    final maxPosition = videoController!.value.duration; // 최대 길이를 저장
    final currentPosition = videoController!.value.position;

    Duration position = maxPosition; // 포지션은 기본 최대로 설정

    if ((maxPosition - Duration(seconds: 3)).inSeconds >
        currentPosition.inSeconds) {
      // 전체 포지션(전체 영화의 길이)에서 3초를 뺀 것을 초로 가져왔을 때 그 길이가 현재 포지션보다 길다면
      position = currentPosition + Duration(seconds: 3); // 현재 위치에서 3초를 더해준다
    }

    videoController!.seekTo(position); // 어떤 위치로 부터 이동을 할 지 정할 수 있다
  }

  void onSliderChanged(double value) {
    videoController!.seekTo(
      // 이동한 포지션으로 Duration 값을 바꿀 수 있다
      Duration(
        seconds: value.toInt(),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  // 비디오 화면위에 버튼을 위한 위젯을 하나 만들었다

  final VoidCallback onPlayPressed;
  final VoidCallback onReversePressed;
  final VoidCallback onForwardPressed;
  final bool isPlaying;

  const _Controls({
    Key? key,
    required this.onPlayPressed,
    required this.onReversePressed,
    required this.onForwardPressed,
    required this.isPlaying,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5), // 배경을 투명 검정으로
      height: MediaQuery.of(context).size.height, // 아이콘들을 가운데 정렬하기 위해서
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          renderIconButton(
            onPressed: onReversePressed,
            iconData: Icons.rotate_left,
          ),
          renderIconButton(
            onPressed: onPlayPressed,
            iconData: isPlaying ? Icons.pause : Icons.play_arrow,
          ),
          renderIconButton(
            onPressed: onForwardPressed,
            iconData: Icons.rotate_right,
          ),
        ],
      ),
    );
  }

  Widget renderIconButton({
    // 아이콘 버튼을 위한 클래스를 하나 만들었다
    required VoidCallback onPressed,
    required IconData iconData,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: 30.0,
      color: Colors.white,
      icon: Icon(iconData),
    );
  }
}

class _NewVideo extends StatelessWidget {
  final VoidCallback onPressed;

  const _NewVideo({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // 위치을 정하는 위젯 Stack에서 자주 사용
      right: 0, // 오른쪽 끝에 위치
      child: IconButton(
        color: Colors.white,
        iconSize: 30.0,
        onPressed: onPressed,
        icon: Icon(Icons.photo_camera_back),
      ),
    );
  }
}

class _SliderBottom extends StatelessWidget {
  final Duration currentPosition;
  final Duration maxPosition;
  final ValueChanged<double> onSliderChanged;

  const _SliderBottom({
    Key? key,
    required this.currentPosition,
    required this.maxPosition,
    required this.onSliderChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0, // 왼쪽과 오른쪽에 0을 주면 슬라이더가 늘어난다
      left: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Text(
              // 슬라이더 옆에 숫자를 현재 위치(시간)을 나타내기 위함
              '${currentPosition.inMinutes}:${(currentPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              // inSeconds 를 60으로 나눈 나머지를 나타나게 해서 61초가 되는 것을 방지
              // 1분이 넘어가면 .inMinutes가 1이 올라가는데, inSecons를 60으로 나누지 않으면 같이 61로 넘어간다.
              // .toString()으로 변환후 .padLeft를 하면 첫번째 파라미터에 몇글자를 나타낼 것인지 넣을 수 있고 두번째 파라미터는
              // 만약 글자수가 부족하면 어떤 숫자로 채울 것인가 적을 수 있다.
              // 10초 이내 숫자들은 1, 2, 3, 4 -> 01, 02, 03, 04초로 나타냄
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Slider(
                max: maxPosition.inSeconds.toDouble(),
                min: 0,
                value: currentPosition.inSeconds.toDouble(),
                onChanged: onSliderChanged,
              ),
            ),
            Text(
              // 전체 길이를 나타내기 위한 텍스트위젯이다.
              '${maxPosition.inMinutes}:${(maxPosition.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
