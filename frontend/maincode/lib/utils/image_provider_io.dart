import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider buildLocalFileImage(String path) => FileImage(File(path));
