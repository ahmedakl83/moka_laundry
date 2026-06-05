#!/bin/bash

flutterfire configure --project=moka-car-wash

flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_auth
flutter pub get
