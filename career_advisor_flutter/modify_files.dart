import 'dart:io';

void processDir(String path, String fallback) {
  final dir = Directory(path);
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    if (content.contains('leading: IconButton(') && content.contains('Icons.arrow_back')) continue;

    final regex = RegExp(r'([ \t]*)automaticallyImplyLeading:\s*false,');
    final newContent = content.replaceAllMapped(regex, (match) {
      final indent = match.group(1);
      return '''${indent}automaticallyImplyLeading: false,
${indent}leading: IconButton(
$indent  icon: const Icon(Icons.arrow_back),
$indent  onPressed: () {
$indent    if (context.canPop()) {
$indent      context.pop();
$indent    } else {
$indent      context.go('$fallback');
$indent    }
$indent  },
$indent),''';
    });

    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Updated ${file.path}');
    }
  }
}

void main() {
  processDir(r'd:\MCA PROJECT\career-advisor\career_advisor_admin\lib\screens', '/dashboard');
  processDir(r'd:\MCA PROJECT\career-advisor\career_advisor_flutter\lib\screens', '/home');
  print('Done');
}
