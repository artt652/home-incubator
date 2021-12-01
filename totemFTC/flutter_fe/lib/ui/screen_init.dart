import 'package:flutter/material.dart';
import 'package:flutter_fe/misc/initializer.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:logging/logging.dart';

class ScreenInit extends StatefulWidget {
  const ScreenInit({Key? key}) : super(key: key);

  @override
  State createState() => ScreenInitState();
}

class ScreenInitState extends State<ScreenInit> {
  late final Logger log/* = Logger('ScreenInit[$hashCode]')*/;

  ScreenInitState() {
    log = Logger('ScreenInit[$hashCode]');
  }

  @override
  void initState() {
    super.initState();
    log.finer('Wait for init ...');
    final initializer = Injector().get<Initializer>();
    initializer.future.then((value) {
      log.finer('Init completed. Redirect to login');
      Navigator.pushReplacementNamed(context, '/login');
    });
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Totem FC'),),
        body: Column(children: const [
          CircularProgressIndicator(),
          Text('Application initializing')
        ])
    );
  }
}
