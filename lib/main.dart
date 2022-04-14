import 'dart:io';

import 'package:bokdaeri_hybrid/page/home_page.dart';
import 'package:bokdaeri_hybrid/module/page_event_connector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

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
  
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false, // Required to display a heads up notification
    badge: true,
    sound: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _addFirebaseMessageListener();

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
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    // 종료, 비활성 상태일 때 푸시가 "도착"하면 실행됨.
    // FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    // 활성 상태일 때 푸시가 "도착"하면 실행됨.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification notification = message.notification!;
      print(message.data);
      PageEventConnector().onForegroundFirebaseMessage(
          message.notification?.title,
          message.notification?.body,
          message.data['url']);
    });
  }
}
