import 'dart:io';

void fixImports(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Check if it uses context.pop or context.go but doesn't import go_router
    if ((content.contains('context.pop(') || content.contains('context.go(') || content.contains('context.canPop('))) {
      if (!content.contains('package:go_router/go_router.dart')) {
        // Find the last import statment to insert after it, or just prepend
        // Prepending is easiest
        content = "import 'package:go_router/go_router.dart';\n$content";
        file.writeAsStringSync(content);
        print('Fixed imports in ${file.path}');
      }
    }
  }
}

void main() {
  fixImports(r'd:\MCA PROJECT\career-advisor\career_advisor_admin\lib\screens');
  fixImports(r'd:\MCA PROJECT\career-advisor\career_advisor_flutter\lib\screens');
  print('Done fixing imports');
}
