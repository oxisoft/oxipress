import 'package:oxipress/features/project/ui/folder_picker.dart';

class FakeFolderPicker implements FolderPicker {
  FakeFolderPicker({this.nextResult});

  String? nextResult;
  int callCount = 0;

  @override
  Future<String?> pickFolder() async {
    callCount++;
    return nextResult;
  }
}
