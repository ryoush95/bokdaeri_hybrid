import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bokdaeri_hybrid/module/common.dart';
import 'package:bokdaeri_hybrid/module/config.dart';
import 'package:bokdaeri_hybrid/module/page_event_connector.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get_storage/get_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  late dynamic params;

  HomePage({Key? key, this.params}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  InAppWebViewController? _webViewController;
  bool _loadingVisible = true;
  
  static const platform = const MethodChannel('intent');

  @override
  void initState() {
    super.initState();
    print('################## initState HOME PAGE ${widget.params}');

    requestPermission(context);

    //포그라운드 메세지 네이티브 alert
    PageEventConnector().foregroundFirebaseMessageHandler =
        (String title, String content, String url) {
      _showAlertDialog(context, title, content, url);
    };
  }

  Future<bool> requestPermission(BuildContext context) async {
    PermissionStatus status = await Permission.storage.status;
    String? token = await FirebaseMessaging.instance.getToken();
    print(token);
    if (status.isGranted == true) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses =
        await [Permission.storage].request();
    // var status = await requestCameraPermission(context);

    if (statuses[Permission.storage]!.isGranted == false) {
      // 허용이 안된 경우
      if (Platform.isAndroid) {
        openAppSettings();
      }
      print("permission denied by user");
      return false;
    }
    print("permission ok");

    return true;
  }

  @override
  Widget build(BuildContext context) {
    print('################## build HOME PAGE ${widget.params}');

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        //키보드 스크롤 컨트롤
        // resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest:
                    URLRequest(url: Uri.parse(_makeInitialUrl())),
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(
                      javaScriptEnabled: true,
                      clearCache: false,
                      mediaPlaybackRequiresUserGesture: false,
                      useShouldOverrideUrlLoading: true,
                      useOnDownloadStart: true),
                  android: AndroidInAppWebViewOptions(
                    useHybridComposition: true,
                  ),
                  ios: IOSInAppWebViewOptions(
                    allowsInlineMediaPlayback: true,
                  ),
                ),
                onWebViewCreated: (controller) {
                  _webViewController ??= controller;
                  // https://inappwebview.dev/docs/javascript/communication/
                  controller.addJavaScriptHandler(
                      handlerName: 'webviewJavaScriptHandler',
                      callback: (args) async {
                        if (args[0] == 'setUserId') {
                          String userId = args[1]['userId'];
                          GetStorage().write('userId', userId);
                          print('@addJavaScriptHandler userId $userId');
                          return await _getPushToken();
                        }
                      });
                  //_loadWebViewUrl();
                },
                shouldOverrideUrlLoading: (controller, NavigationAction navigation) async{
                  var uri = navigation.request.url!;
                  if(uri.scheme == 'intent'){
                    try {
                      var result = await platform.invokeMethod('launchKakaoTalk', {'url': uri.toString()});
                      if(result != null ){
                        await _webViewController?.loadUrl(urlRequest: URLRequest(url: Uri.parse(result)));
                      }
                    }catch (e){
                      print('url fail $e');
                    }
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onLoadStart: (InAppWebViewController controller, url) async {
                  print('@@@@@@@@@ onLoadStart ${url.toString()}');
                  if(url.toString().contains("kakaolink://send")){
                    if(Platform.isIOS){
                      print('################${url!.scheme}');
                      await launchUrl(url);
                    }
                  }
                  setState(() {
                    _loadingVisible = true;
                  });
                },
                onLoadStop: (InAppWebViewController controller, url) async {
                  print('@@@@@@@@@ onLoadStop ${url.toString()}');
                  setState(() {
                    _loadingVisible = false;
                  });
                },
                onDownloadStart: (controller, url) async {
                  print("onDownloadStart $url");

                  showTopSnackBar(
                    context,
                    const CustomSnackBar.info(
                      message: '파일 다운로드를 시작합니다.',
                    ),
                  );

                  String tempPath = await Common.makeDownloadPath(
                      DateTime.now().millisecondsSinceEpoch.toString());
                  print('>>>>>>>>>>>>>>>>>>>>>>> $tempPath');
                  Dio dio = Dio();
                  dio.options.headers = {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) FlutterInAppWebView/5.3.2',
                  };

                  bool isComplete = false;
                  var response = await dio.download(
                    url.toString(),
                    tempPath,
                    onReceiveProgress: (int received, int total) {
                      print('>>>>>>> $received / $total');
                      // showTopSnackBar(
                      //   context,
                      //   CustomSnackBar.info(
                      //     message: '파일 다운로드를 진행중입니다.',
                      //   ),
                      // );
                      if (received == total) {
                        isComplete = true;
                      }
                    },
                  );
                  if (isComplete) {
                    String fileName = await parseFileName(
                        response.headers.map['content-disposition']);
                    showTopSnackBar(
                      context,
                      CustomSnackBar.success(
                        message: '파일 다운로드를 완료했습니다. $fileName',
                      ),
                    );
                    Timer(const Duration(milliseconds: 1000), () async {
                      if (fileName.isNotEmpty) {
                        String filePath =
                            await Common.makeDownloadPath(fileName);
                        File(tempPath).renameSync(filePath);
                        OpenFile.open(filePath);
                      } else {
                        OpenFile.open(tempPath);
                      }
                    });
                  } else {
                    showTopSnackBar(
                      context,
                      const CustomSnackBar.error(
                        message: '파일 다운로드를 실패했습니다.',
                      ),
                    );
                  }
                },
              ),
              Visibility(
                visible: _loadingVisible,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    print('>>>>>>>>> exit app');
    //return Future(() => false);
    if (await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    }

    bool quit = await Common.showConfirmDialog(context, '앱을 종료하시겠습니까?');
    return quit;
  }

  Future<String?> _getPushToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
    String? token = await messaging.getToken();
    print("토큰 : $token");
    return token;
  }

  Future<String> parseFileName(List<String>? list) async {
    if (list == null) {
      return '';
    }

    for (int i = 0; i < list.length; i++) {
      List<String> l = list[i].split(';');
      for (int j = 0; j < l.length; j++) {
        if (l[j].toLowerCase().contains('filename=')) {
          String name = l[j].split('=')[1];
          print('///////////// $name');
          String dec = utf8.decode(name.codeUnits).trim();
          print('///////////// $dec');
          return dec.replaceAll('"', '');
        }
      }
    }
    return '';
  }

  dynamic _showAlertDialog(
      BuildContext context, String title, String content, String url) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          url.isEmpty
              ? const SizedBox.shrink()
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: const Color.fromRGBO(192, 192, 192, 1),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('취소'),
                ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                //primary: const Color.fromRGBO(115, 173, 73, 1),
                ),
            onPressed: () {
              if (url.isNotEmpty) {
                _webViewController!
                    .loadUrl(urlRequest: URLRequest(url: Uri.parse(url)));
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _makeInitialUrl() {
    String? userId = GetStorage().read('userId');
    print('@userId $userId');
    if (userId != null && userId.isNotEmpty) {
      print('@userId AAA');
      return '${Config.homeUrl}/bbs/autoLogin.php?t=${DateTime.now().millisecondsSinceEpoch}&userId=$userId';
    } else {
      print('@userId BBB');
      return '${Config.homeUrl}/?t=${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
