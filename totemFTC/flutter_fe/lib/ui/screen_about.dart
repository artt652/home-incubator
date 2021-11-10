import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import 'drawer.dart';
import 'widgets/scroll_list_selector.dart';
import 'widgets/ui_subscription.dart';
import 'widgets/ui_attend.dart';

class AboutScreen extends StatelessWidget {

  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Totem FC'),
      ),
      drawer: MyDrawer(),
      body: const Text('About'),
    );
  }
}