import 'dart:io';

void processDir(String path, String fallback) {
  final dir = Directory(path);
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content;

    // We look for AppBar( or SliverAppBar(
    // We only want to add it if it doesn't already have 'leading:'
    
    final appBarTypes = ['AppBar', 'SliverAppBar'];
    
    for (final type in appBarTypes) {
      final regex = RegExp('$type\\(\\s*');
      
      newContent = newContent.replaceAllMapped(regex, (match) {
        final fullMatch = match.group(0)!;
        
        // Check if leading is already here in the next few lines?
        // This is tricky with regex. Let's look at the substring after the match.
        final startIndex = match.end;
        // We'll search for 'leading:' before the next ')' or next 'AppBar'
        // This is a bit naive but usually works for standard Flutter code.
        final nextClosingParen = newContent.indexOf(')', startIndex);
        final sub = newContent.substring(startIndex, nextClosingParen != -1 ? nextClosingParen : startIndex + 500);
        
        if (sub.contains('leading:')) {
          return fullMatch; // Already has it
        }

        // If it doesn't have it, we insert it.
        // We also want to insert 'automaticallyImplyLeading: false' if missing.
        String insertion = '\n          automaticallyImplyLeading: false,\n          leading: IconButton(\n            icon: const Icon(Icons.arrow_back),\n            onPressed: () {\n              if (context.canPop()) {\n                context.pop();\n              } else {\n                context.go(\'$fallback\');\n              }\n            },\n          ),';
        
        if (sub.contains('automaticallyImplyLeading:')) {
          // If it has automaticallyImplyLeading but no leading, we just add leading
          insertion = '\n          leading: IconButton(\n            icon: const Icon(Icons.arrow_back),\n            onPressed: () {\n              if (context.canPop()) {\n                context.pop();\n              } else {\n                context.go(\'$fallback\');\n              }\n            },\n          ),';
        }

        return fullMatch + insertion;
      });
    }

    if (content != newContent) {
      if (!newContent.contains('package:go_router/go_router.dart')) {
        newContent = "import 'package:go_router/go_router.dart';\n" + newContent;
      }
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
