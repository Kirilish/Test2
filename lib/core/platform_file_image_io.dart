import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> platformFileImage(String path) {
  return FileImage(File(path));
}
