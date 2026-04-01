import 'dart:io';

String removeDuplicatesFromBlock(String block) {
  // Find all named arguments in this block
  // We care about leading: and automaticallyImplyLeading:
  
  // This is a bit complex for a regex, but we can search for the keys.
  final keys = ['leading:', 'automaticallyImplyLeading:'];
  String result = block;
  
  for (final key in keys) {
    int firstIdx = result.indexOf(key);
    if (firstIdx == -1) continue;
    
    // While there's a second occurrence
    while (true) {
      int secondIdx = result.indexOf(key, firstIdx + key.length);
      if (secondIdx == -1) break;
      
      // Found a duplicate. We need to remove it.
      // We need to find the extent of the second occurrence.
      // For automaticallyImplyLeading, it's until the next comma or closing paren.
      // For leading, it's the IconButton(...) call.
      
      int endIdx;
      if (key == 'automaticallyImplyLeading:') {
        endIdx = result.indexOf(',', secondIdx);
        if (endIdx == -1 || endIdx > result.indexOf(')', secondIdx)) {
           endIdx = result.indexOf('\n', secondIdx);
        } else {
           endIdx += 1; // include comma
        }
      } else {
        // leading: IconButton(...)
        // balance parentheses?
        int parenLevel = 0;
        int i = result.indexOf('(', secondIdx);
        if (i == -1) {
           // simple one-liner?
           endIdx = result.indexOf(',', secondIdx) + 1;
        } else {
          parenLevel = 1;
          for (i = i + 1; i < result.length; i++) {
            if (result[i] == '(') parenLevel++;
            else if (result[i] == ')') parenLevel--;
            if (parenLevel == 0) break;
          }
          endIdx = result.indexOf(',', i);
          if (endIdx == -1 || endIdx > result.indexOf('\n', i) + 10) {
             endIdx = i + 1;
          } else {
             endIdx += 1;
          }
        }
      }
      
      if (endIdx != -1) {
        result = result.substring(0, secondIdx) + result.substring(endIdx);
      } else {
        break;
      }
    }
  }
  return result;
}

void processFile(File file) {
  String content = file.readAsStringSync();
  String newContent = content;
  
  final regex = RegExp(r'(AppBar|SliverAppBar)\([\s\S]*?\)');
  
  newContent = content.replaceAllMapped(regex, (match) {
    return removeDuplicatesFromBlock(match.group(0)!);
  });
  
  if (content != newContent) {
    file.writeAsStringSync(newContent);
    print('Surgically fixed ${file.path}');
  }
}

void main() {
  final adminScreens = Directory(r'd:\MCA PROJECT\career-advisor\career_advisor_admin\lib\screens');
  final userScreens = Directory(r'd:\MCA PROJECT\career-advisor\career_advisor_flutter\lib\screens');
  
  for (final dir in [adminScreens, userScreens]) {
    if (dir.existsSync()) {
      dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).forEach(processFile);
    }
  }
  print('Done surgical fix');
}
