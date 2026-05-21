import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/app_module.dart';
import 'package:librarymanagementsystem/app_widget.dart';
import 'package:librarymanagementsystem/src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();

  await Modular.configure(
    appModule: AppModule(),
    initialRoute: "/",
    debugLogDiagnostics: true,
    debugLogDiagnosticsGoRouter: true,
    debugLogEventBus: true,
  );

  runApp(const AppWidget());
}
