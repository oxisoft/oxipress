import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pluggable folder picker. Tests substitute a fake to short-circuit the
/// native dialog.
abstract interface class FolderPicker {
  Future<String?> pickFolder();
}

class RealFolderPicker implements FolderPicker {
  const RealFolderPicker();

  @override
  Future<String?> pickFolder() => FilePicker.getDirectoryPath();
}

final folderPickerProvider = Provider<FolderPicker>(
  (ref) => const RealFolderPicker(),
);
