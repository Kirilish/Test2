import 'package:flutter/widgets.dart';

ImageProvider<Object> platformFileImage(String path) {
  return NetworkImage(path);
}
