import 'dart:io';

Future<void> main(List<String> args) async {
  final stopwatch = Stopwatch()..start();

  final isDryRun = args.contains('--dry-run');
  final rootPath = args.where((a) => a != '--dry-run').isNotEmpty
      ? args.where((a) => a != '--dry-run').first
      : Directory.current.path;
  final rootDir = Directory(rootPath);

  if (!rootDir.existsSync()) {
    print("❌ Directory does not exist: $rootPath");
    exit(1);
  }

  stdout.write(
    "\n❓ Do you want to clean system caches (Gradle, Xcode, Docker) as well? (y/n): ",
  );
  final String? promptAnswer = stdin.readLineSync();
  final shouldCleanSystem = promptAnswer != null && promptAnswer.toLowerCase() == 'y';

  if (isDryRun) {
    print("\n🔍 DRY RUN MODE — no files will be deleted\n");
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
            final target = targetPath.replaceAll('/', Platform.pathSeparator);
            final targetDir = Directory(
              '${dir.path}${Platform.pathSeparator}$target',
            );

            if (targetDir.existsSync()) {
              final sizeNode = await getDirSize(targetDir);
              spacesSaved += sizeNode;
              if (isDryRun) {
                print("  🔍 Would delete $target (${formatBytes(sizeNode)})");
              } else {
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
      }

      final entries = dir.listSync(followLinks: false);
      for (final entity in entries) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;

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
    } catch (e) {}
  }

  await processDirectory(rootDir);

  if (shouldCleanSystem) {
    final systemSaved = await cleanSystemCaches(isDryRun: isDryRun);
    spacesSaved += systemSaved;
  } else {
    print("\n⏭️  Skipping system caches.");
  }

  stopwatch.stop();
  final modeLabel = isDryRun ? " (DRY RUN)" : "";
  print("\n========================================================");
  print("🎉 Cleanup Complete!$modeLabel");
  print("⏱️  Time taken: ${stopwatch.elapsed.inSeconds} seconds");
  print("📂 Projects cleaned: $projectsFound");
  print("💾 Total space saved: ${formatBytes(spacesSaved)}");
  print("========================================================");
}

Future<int> cleanSystemCaches({required bool isDryRun}) async {
  print("\n🧹 System Caches Cleaning...");
  int systemSaved = 0;

  final home = Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';

  final entries = <({String name, String command, Directory dir})>[
    (
      name: 'Gradle caches',
      command: 'rm -rf ~/.gradle/caches/*',
      dir: Directory('$home/.gradle/caches'),
    ),
    (
      name: 'Xcode DerivedData',
      command: 'rm -rf ~/Library/Developer/Xcode/DerivedData/*',
      dir: Directory('$home/Library/Developer/Xcode/DerivedData'),
    ),
    (
      name: 'Xcode iOS DeviceSupport',
      command: 'rm -rf ~/Library/Developer/Xcode/iOS\\ DeviceSupport/*',
      dir: Directory('$home/Library/Developer/Xcode/iOS DeviceSupport'),
    ),
    (
      name: 'Xcode Simulators',
      command: 'xcrun simctl delete unavailable',
      dir: Directory(''),
    ),
    (
      name: 'Docker system',
      command: 'docker system prune -a --volumes -f',
      dir: Directory(''),
    ),
  ];

  for (final entry in entries) {
    final isMeasurable = entry.dir.path.isNotEmpty;

    if (isMeasurable) {
      final size = await getDirSize(entry.dir);
      if (size == 0) {
        continue;
      }

      if (isDryRun) {
        print("  🔍 Would delete ${entry.name} (${formatBytes(size)})");
        systemSaved += size;
      } else {
        try {
          print("  ⏳ Deleting ${entry.name}...");
          await Process.run('sh', ['-c', entry.command]);
          print("  ✅ Deleted ${entry.name} (${formatBytes(size)})");
          systemSaved += size;
        } catch (e) {
          print("  ❌ Failed ${entry.name}: $e");
        }
      }
    } else if (entry.name == 'Docker system') {
      if (isDryRun) {
        print("  🔍 Would prune Docker system");
      } else {
        try {
          print("  ⏳ Pruning Docker system...");
          final result = await Process.run(
            'sh',
            ['-c', entry.command],
          );
          final output = result.stdout.toString();
          final reclaimMatch = RegExp(
            r'Total reclaimed space:\s*([\d.]+)\s*(\w+)',
          ).firstMatch(output);
          int dockerBytes = 0;
          if (reclaimMatch != null) {
            dockerBytes = _parseSizeToBytes(
              reclaimMatch.group(1)!,
              reclaimMatch.group(2)!,
            );
            systemSaved += dockerBytes;
            print("  ✅ Pruned Docker system (${formatBytes(dockerBytes)})");
          } else {
            print("  ✅ Pruned Docker system");
          }
        } catch (e) {
          print("  ❌ Failed Docker: $e");
        }
      }
    } else if (entry.name == 'Xcode Simulators') {
      if (isDryRun) {
        print("  🔍 Would delete unavailable simulators");
      } else {
        try {
          print("  ⏳ Deleting unavailable simulators...");
          await Process.run('sh', ['-c', entry.command]);
          print("  ✅ Deleted unavailable simulators");
        } catch (e) {
          print("  ❌ Failed simulators: $e");
        }
      }
    }
  }

  return systemSaved;
}

int _parseSizeToBytes(String value, String unit) {
  final v = double.parse(value);
  switch (unit.toUpperCase()) {
    case 'B':
      return v.round();
    case 'KB':
      return (v * 1024).round();
    case 'MB':
      return (v * 1024 * 1024).round();
    case 'GB':
      return (v * 1024 * 1024 * 1024).round();
    case 'TB':
      return (v * 1024 * 1024 * 1024 * 1024).round();
    default:
      return 0;
  }
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
  } catch (e) {}
  return size;
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
