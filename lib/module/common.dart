import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';

class Common {
  static Future<String> makeDownloadPath(String name) async {
    String dir = '';
    if (Platform.isAndroid) {
      //dir = '/storage/emulated/0/${Config.appName}Download';
      dir = '${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS)}/${Config.appName}';
      print('DOWNLOAD-DIR $dir');
      if (!Directory(dir).existsSync()) {
        try {
          Directory(dir).createSync();
        } catch (e) {
          dir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
        }
      }
    } else if (Platform.isIOS) {
      dir = (await getApplicationSupportDirectory()).path;
    } else {
      throw Exception('Unsupported OS.');
    }
    while (true) {
      String path = '$dir/$name';
      if (!File(path).existsSync()) {
        return path;
      }

      if (name.lastIndexOf('.') <= 0) {
        var matches = RegExp(r'\(\d+\)$').allMatches(name);
        if (matches.isEmpty) {
          name = '$name(1)';
        } else {
          RegExp(r'\(\d+\)$').allMatches(name).forEach((match) {
            String from = name.substring(match.start, match.end);
            int seq = int.parse(from.replaceAll(RegExp('[^0-9]'), ''));
            String to = '(${seq + 1})';
            name = name.replaceAll(RegExp(r'\(\d+\)$'), to);
          });
        }
      } else {
        String ext = name.split('.').last;
        var matches = RegExp(r'\(\d+\)' + '.$ext').allMatches(name);
        if (matches.isEmpty) {
          name = name.replaceAll(RegExp(r'.' + '$ext'), '(1).$ext');
        } else {
          RegExp(r'\(\d+\)' + '.$ext').allMatches(name).forEach((match) {
            String from = name.substring(match.start, match.end);
            int seq = int.parse(from.replaceAll(RegExp('[^0-9]'), ''));
            String to = '(${seq + 1})';
            name = name.replaceAll(RegExp(r'\(\d+\)' + '.$ext'), '$to.$ext');
          });
        }
      }
    }
  }

  static Future<bool> showConfirmDialog(
      BuildContext context, String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: const Color.fromRGBO(192, 192, 192, 1),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text(
              '아니오',
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              //primary: const Color.fromRGBO(115, 173, 73, 1),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }
}
