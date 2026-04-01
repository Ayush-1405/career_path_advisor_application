import 'dart:io';

void cleanup(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return;

  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Fix duplicate automaticallyImplyLeading: false,
    // We look for cases where it's followed by another one before the next 'AppBar(' or 'SliverAppBar('
    
    // A simpler way: just remove the second occurrence if they are very close.
    // Usually they are right next to each other or separated by 'leading: ...'
    
    // Pattern to find: automaticallyImplyLeading: false, (anything) automaticallyImplyLeading: false,
    // where (anything) doesn't contain AppBar or SliverAppBar.
    
    final pattern = RegExp(r'(automaticallyImplyLeading:\s*false,[\s\S]*?)automaticallyImplyLeading:\s*false,');
    
    String newContent = content;
    bool changed = false;
    
    // We loop because there might be multiple AppBars or multi-duplicates
    while (true) {
      final match = pattern.firstMatch(newContent);
      if (match == null) break;
      
      // Check if there's an AppBar between them
      final betweeen = match.group(1)!;
      if (betweeen.contains('AppBar(') || betweeen.contains('SliverAppBar(')) {
        // This match is across two different AppBars, skip it by advancing search?
        // Actually, RegExp.firstMatch only finds the first. We need to skip this one.
        // Let's use replaceFirst with a unique marker to avoid infinite loop or just handle it better.
        break; // Trivial implementation for now, let's refine.
      }
      
      newContent = newContent.replaceFirst('automaticallyImplyLeading: false,', '____TEMP____', match.start);
      newContent = newContent.replaceFirst('automaticallyImplyLeading: false,', '', match.start + 12);
      newContent = newContent.replaceFirst('____TEMP____', 'automaticallyImplyLeading: false,');
      changed = true;
    }

    // Fix duplicate leading: IconButton(...)
    // This is harder because the content varies.
    // But since I added a very specific one, I can look for it.
    
    final leadingPattern = RegExp(r'(leading:\s*IconButton\([\s\S]*?\),[\s\S]*?)leading:\s*IconButton\([\s\S]*?\),');
    while (true) {
      final match = leadingPattern.firstMatch(newContent);
      if (match == null) break;
      
      final between = match.group(1)!;
      if (between.contains('AppBar(') || between.contains('SliverAppBar(')) break;

      // Resolve duplicate leading
      // We want to keep the one I added (usually the first one now)
      // Actually, my script always inserted at the beginning.
      // So the duplicate is further down.
      
      // Let's just find the second one and remove it if it's the same or very similar.
      // For now, I'll trust my insertion and remove any subsequent 'leading:' in the same block.
      
      final firstLeadingIndex = newContent.indexOf('leading:', match.start);
      final secondLeadingIndex = newContent.indexOf('leading:', firstLeadingIndex + 8);
      
      if (secondLeadingIndex != -1) {
        // Find the end of this leading block (closing balance paren or next comma-separated arg)
        // This is complex. Let's just remove the first few lines of it if it's a duplicate.
        
        // Actually, if I created duplicates, they are identical in structure mostly.
        // Let's just use a more surgical approach.
      }
      break;
    }

    if (changed) {
      file.writeAsStringSync(newContent);
      print('Cleaned up ${file.path}');
    }
  }
}

void main() {
  cleanup(r'd:\MCA PROJECT\career-advisor\career_advisor_admin\lib\screens');
  cleanup(r'd:\MCA PROJECT\career-advisor\career_advisor_flutter\lib\screens');
}
