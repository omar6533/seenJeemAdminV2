import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../models/question_model.dart';
import '../models/seenjeem_question_model.dart';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';

class ExcelService {
  Future<List<QuestionModel>?> importQuestionsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.bytes != null) {
        var bytes = result.files.single.bytes!;
        var excel = Excel.decodeBytes(bytes);

        List<QuestionModel> questions = [];

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;

          for (var i = 1; i < sheet.maxRows; i++) {
            var row = sheet.row(i);

            if (row.isEmpty || row[0]?.value == null) continue;

            final categoryId = row[0]?.value?.toString() ?? '';
            final question = row[1]?.value?.toString() ?? '';
            final option1 = row[2]?.value?.toString() ?? '';
            final option2 = row[3]?.value?.toString() ?? '';
            final option3 = row[4]?.value?.toString() ?? '';
            final option4 = row[5]?.value?.toString() ?? '';
            final correctAnswer =
                int.tryParse(row[6]?.value?.toString() ?? '0') ?? 0;
            final difficulty = row[7]?.value?.toString() ?? 'medium';

            questions.add(QuestionModel(
              id: '',
              categoryId: categoryId,
              question: question,
              options: [option1, option2, option3, option4],
              correctAnswer: correctAnswer,
              difficulty: difficulty,
              isActive: true,
              createdAt: DateTime.now(),
            ));
          }
        }

        return questions;
      }
    } catch (e) {
      print('Error importing Excel: $e');
    }
    return null;
  }

  Future<void> exportQuestionsToExcel(List<QuestionModel> questions) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Questions'];

    sheetObject.appendRow([
      TextCellValue('Category ID'),
      TextCellValue('Question'),
      TextCellValue('Option 1'),
      TextCellValue('Option 2'),
      TextCellValue('Option 3'),
      TextCellValue('Option 4'),
      TextCellValue('Correct Answer'),
      TextCellValue('Difficulty'),
    ]);

    for (var question in questions) {
      sheetObject.appendRow([
        TextCellValue(question.categoryId),
        TextCellValue(question.question),
        TextCellValue(question.options.isNotEmpty ? question.options[0] : ''),
        TextCellValue(question.options.length > 1 ? question.options[1] : ''),
        TextCellValue(question.options.length > 2 ? question.options[2] : ''),
        TextCellValue(question.options.length > 3 ? question.options[3] : ''),
        IntCellValue(question.correctAnswer),
        TextCellValue(question.difficulty),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      print('Excel file created successfully');
    }
  }

  Future<List<Map<String, dynamic>>> parseExcelFile(Uint8List bytes) async {
    try {
      var excel = Excel.decodeBytes(bytes);
      List<Map<String, dynamic>> rows = [];

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;

        // Get headers from first row
        if (sheet.maxRows == 0) continue;
        var headerRow = sheet.row(0);
        List<String> headers = [];
        for (var cell in headerRow) {
          headers.add(cell?.value?.toString() ?? '');
        }

        // Parse data rows
        for (var i = 1; i < sheet.maxRows; i++) {
          var row = sheet.row(i);
          if (row.isEmpty || row[0]?.value == null) continue;

          Map<String, dynamic> rowData = {};
          for (var j = 0; j < headers.length && j < row.length; j++) {
            rowData[headers[j]] = row[j]?.value?.toString() ?? '';
          }
          rows.add(rowData);
        }
      }

      return rows;
    } catch (e) {
      throw Exception('Error parsing Excel file: $e');
    }
  }

  void downloadTemplate(String type) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Template'];

    if (type == 'questions') {
      sheetObject.appendRow([
        TextCellValue('main_category_name_ar'),
        TextCellValue('sub_category_name_ar'),
        TextCellValue('question_text_ar'),
        TextCellValue('answer_text_ar'),
        TextCellValue('points'),
        TextCellValue('question_media_url'),
        TextCellValue('answer_media_url'),
        TextCellValue('status'),
      ]);
    } else if (type == 'main-categories') {
      sheetObject.appendRow([
        TextCellValue('name_ar'),
        TextCellValue('display_order'),
        TextCellValue('is_active'),
        TextCellValue('media_url'),
      ]);
    } else if (type == 'sub-categories') {
      sheetObject.appendRow([
        TextCellValue('main_category_name_ar'),
        TextCellValue('name_ar'),
        TextCellValue('display_order'),
        TextCellValue('is_active'),
        TextCellValue('media_url'),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      // In a real implementation, you would trigger a download here
      // For web, you might use html package or similar
      print('Template created successfully');
    }
  }

  void exportQuestions(List<SeenjeemQuestionModel> questions) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Questions'];

    sheetObject.appendRow([
      TextCellValue('main_category_name_ar'),
      TextCellValue('sub_category_name_ar'),
      TextCellValue('question_text_ar'),
      TextCellValue('answer_text_ar'),
      TextCellValue('points'),
      TextCellValue('question_media_url'),
      TextCellValue('answer_media_url'),
      TextCellValue('status'),
    ]);

    for (var question in questions) {
      sheetObject.appendRow([
        TextCellValue(question.subCategoryNameAr ?? ''),
        TextCellValue(question.subCategoryNameAr ?? ''),
        TextCellValue(question.questionTextAr),
        TextCellValue(question.answerTextAr),
        IntCellValue(question.points),
        TextCellValue(question.questionMediaUrl ?? ''),
        TextCellValue(question.answerMediaUrl ?? ''),
        TextCellValue(question.status),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      print('Questions exported successfully');
    }
  }

  void exportMainCategories(List<MainCategoryModel> categories) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Main Categories'];

    sheetObject.appendRow([
      TextCellValue('name_ar'),
      TextCellValue('display_order'),
      TextCellValue('is_active'),
      TextCellValue('media_url'),
    ]);

    for (var category in categories) {
      sheetObject.appendRow([
        TextCellValue(category.nameAr),
        IntCellValue(category.displayOrder),
        TextCellValue(category.isActive ? 'true' : 'false'),
        TextCellValue(category.mediaUrl ?? ''),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      print('Main categories exported successfully');
    }
  }

  void exportSubCategories(List<SubCategoryModel> categories) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sub Categories'];

    sheetObject.appendRow([
      TextCellValue('main_category_name_ar'),
      TextCellValue('name_ar'),
      TextCellValue('display_order'),
      TextCellValue('is_active'),
      TextCellValue('media_url'),
    ]);

    for (var category in categories) {
      sheetObject.appendRow([
        TextCellValue(category.mainCategoryNameAr ?? ''),
        TextCellValue(category.nameAr),
        IntCellValue(category.displayOrder),
        TextCellValue(category.isActive ? 'true' : 'false'),
        TextCellValue(category.mediaUrl),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      print('Sub categories exported successfully');
    }
  }
}
