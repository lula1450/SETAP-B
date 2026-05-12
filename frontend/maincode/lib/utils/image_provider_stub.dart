// Web stub — builds an ImageProvider from a URL using NetworkImage.
import 'package:flutter/material.dart';

// On web, all non-network paths are blob URLs — NetworkImage handles both.
ImageProvider buildLocalFileImage(String path) => NetworkImage(path);
