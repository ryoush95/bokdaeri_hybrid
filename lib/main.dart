import 'dart:io';

import 'package:bokdaeri_hybrid/page/home_page.dart';
import 'package:bokdaeri_hybrid/module/page_event_connector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  await GetStorage.init();

  // Firebase
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: false,
  );

  if(Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false, // Required to display a heads up notification
      badge: true,
      sound: true,
    );
  }

  runApp(const MyApp());
}

Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.notification?.title}");
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _addFirebaseMessageListener();
    // 세로 위쪽 방향 고정
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return GetMaterialApp(
      title: 'bok',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }

  void _addFirebaseMessageListener() async {
    // 종료, 비활성 상태일 때 푸시가 "도착"하면 실행됨.
    //FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // 종료 상태에서, 푸시 알림을 "클릭"하면 실행됨.
    RemoteMessage? message =
    await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      PageEventConnector().onBackgroundFirebaseMessage(
        message.notification?.title,
        message.notification?.body,
        message.data['url'],
      );
    }

    // 활성, 비활성 상태에서, 푸시 알림을 "클릭"하면 실행됨.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PageEventConnector().onBackgroundFirebaseMessage(
        message.notification?.title,
        message.notification?.body,
        message.data['url'],
      );
    });

    // 활성 상태일 때 푸시가 "도착"하면 실행됨.
    FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) async {
        PageEventConnector().onForegroundFirebaseMessage(
          message.notification?.title,
          message.notification?.body,
          message.data['url'],
        );
      },
    );
  }
}
