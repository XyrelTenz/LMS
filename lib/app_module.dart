import 'package:go_router_modular/go_router_modular.dart';
import 'package:librarymanagementsystem/view/auth/auth_module.dart';
import 'package:librarymanagementsystem/view/librarian/librarian_module.dart';
import 'package:librarymanagementsystem/view/student/student_module.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/librarian', module: LibrarianModule()),
    ModuleRoute('/student', module: StudentModule()),
  ];
}
