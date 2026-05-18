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

//TODO: Number of copies of book
//TODO: Add category 5
//TODO: List of books that borrow
//TODO: Remove Approved status on students
//TODO: Librarian can set due date time or set day when approving borrow request
