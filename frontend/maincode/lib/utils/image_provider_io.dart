// Mobile implementation — builds an ImageProvider from a local file path using FileImage.
import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider buildLocalFileImage(String path) => FileImage(File(path));
