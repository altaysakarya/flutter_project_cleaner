#!/usr/bin/env dart
import 'dart:io';

Future<void> main(List<String> args) async {
  final stopwatch = Stopwatch()..start();
  
  // Default to current directory if no argument is passed
  final rootPath = args.isNotEmpty ? args.first : Directory.current.path;
  final rootDir = Directory(rootPath);

  if (!rootDir.existsSync()) {
    print("❌ Directory does not exist: $rootPath");
    exit(1);
  }

  print("🔍 Scanning for Flutter projects in $rootPath...");
  
  int projectsFound = 0;
  int spacesSaved = 0;
  List<String> cleanedProjects = [];

  Future<void> processDirectory(Directory dir) async {
    try {
      final pubspec = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        // Simple check to ensure it's a flutter project
        if (content.contains('flutter:')) {
          projectsFound++;
          cleanedProjects.add(dir.path);
          print("\n🧹 Cleaning: ${dir.path}");
          
          final dirsToDelete = [
            'build',
            '.dart_tool',
            'ios/Pods',
            'macos/Pods',
            '.symlinks',
          ];
          
          for (final targetPath in dirsToDelete) {
            // using path separator correctly
            final target = targetPath.replaceAll('/', Platform.pathSeparator);
            final targetDir = Directory('${dir.path}${Platform.pathSeparator}$target');
            
            if (targetDir.existsSync()) {
              final sizeNode = await getDirSize(targetDir);
              spacesSaved += sizeNode;
              try {
                targetDir.deleteSync(recursive: true);
                print("  ✅ Deleted $target (${formatBytes(sizeNode)})");
              } catch (e) {
                print("  ❌ Failed to delete $target: $e");
              }
            }
          }
        }
      }

      // Read entries but skip known heavy/blacklisted directories
      final entries = dir.listSync(followLinks: false);
      for (final entity in entries) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          
          // Skip known heavy or irrelevant directories to speed up the scan
          if (name == 'build' || 
              name == '.dart_tool' || 
              name == '.git' || 
              name == 'Pods' || 
              name == 'node_modules' ||
              name == '.symlinks' ||
              name == '.idea' || 
              name == '.vscode') {
            continue;
          }
          await processDirectory(entity);
        }
      }
    } catch (e) {
      // Ignore permission or access errors silently to continue traversal
    }
  }

  await processDirectory(rootDir);

  stopwatch.stop();
  print("\n========================================================");
  print("🎉 Cleanup Complete!");
  print("⏱️  Time taken: ${stopwatch.elapsed.inSeconds} seconds");
  print("📂 Projects cleaned: $projectsFound");
  print("💾 Total space saved: ${formatBytes(spacesSaved)}");
  print("========================================================");
}

Future<int> getDirSize(Directory dir) async {
  int size = 0;
  try {
    if (dir.existsSync()) {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          size += entity.lengthSync();
        }
      }
    }
  } catch (e) {
    // Ignore errors for individual files
  }
  return size;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
