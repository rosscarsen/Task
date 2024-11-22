import 'package:characters/characters.dart';

class EscHelper {
  /// 居中打印
  /// 根据宽度 `width` 居中对齐 `content`
  static String alignCenterPrint({required int width, required String content}) {
    final strLength = calculateWidth(content);
    final halfWidth = ((width - strLength) ~/ 2);
    return ' ' * halfWidth + content + ' ' * (width - strLength - halfWidth);
  }

  /// 列表打印
  /// 根据对齐方式生成列内容
  /// [ASCII] ESC a n | [HEX] 0x1B 0x61 n | [DEC] 27 97 n
  /// `align` 对齐方式：0 左对齐 | 1 居中 | 2 右对齐
  static String columnMaker({
    required String content,
    required int width,
    int align = 0,
  }) {
    final contentWidth = calculateWidth(content);
    final spaceWidth = width - contentWidth;

    switch (align) {
      case 1:
        final halfWidth = spaceWidth ~/ 2;
        return ' ' * halfWidth + content + ' ' * (spaceWidth - halfWidth);
      case 2:
        return ' ' * spaceWidth + content;
      default:
        return content + ' ' * spaceWidth;
    }
  }

  /// 生成指定长度的分隔线
  static String fillHr({required int length, String ch = '-'}) => ch * length;

  /// 计算字符串宽度（汉字按宽度 2 计算）
  static int calculateWidth(String text) {
    return text.characters.fold(
        0, (width, char) => width + (RegExp(r'[\u4E00-\u9FFF\u3000-\u303F\uFF00-\uFFEF]').hasMatch(char) ? 2 : 1));
  }

  /// 分割字符串为指定宽度的列表
  /// 优先按换行符 `\n` 拆分，然后对每段内容按照指定宽度进行分割
  static List<String> splitString({required String str, required int splitLength}) {
    List<String> result = [];

    // 按换行符拆分字符串
    List<String> lines = str.split('\n');

    // 对每行字符串进行分割
    for (var line in lines) {
      Characters chars = line.trim().characters;
      while (chars.isNotEmpty) {
        String segment = chars.take(splitLength).toString();
        while (calculateWidth(segment) > splitLength && chars.length > 1) {
          chars = chars.skip(1);
          segment = chars.take(splitLength).toString();
        }
        result.add(segment);
        chars = chars.skip(segment.length);
      }
    }

    return result;
  }

  /// 设置对齐方式
  /// [ASCII] ESC a n | [HEX] 0x1B 0x61 n | [DEC] 27 97 n
  static String setAlign({int align = 0}) {
    return String.fromCharCodes([27, 97, align.clamp(0, 2)]);
  }

  /// 设置字符大小
  /// [ASCII] GS ! n | [HEX] 0x1D 0x21 n | [DEC] 29 33 n
  /// size 默认正常大小
  /// 1: 两倍高 | 2: 两倍宽 | 3: 两倍大小
  /// 4: 三倍高 | 5: 三倍宽 | 6: 三倍大小
  /// 7: 四倍高 | 8: 四倍宽 | 9: 四倍大小
  /// 10: 五倍高 | 11: 五倍宽 | 12: 五倍大小
  static String setSize({int size = 0}) {
    const sizes = [0, 1, 16, 17, 2, 32, 34, 3, 48, 51, 4, 64];
    return String.fromCharCodes([29, 33, sizes[size.clamp(0, sizes.length - 1)]]);
  }

  /// 设置走纸行数
  /// [ASCII] ESC d n | [HEX] 0x1B 0x64 n | [DEC] 27 100 n
  static String setLineSpace({required int line}) {
    return String.fromCharCodes([27, 100, line.clamp(0, 255)]);
  }

  /// 切纸
  /// [ASCII] ESC m | [HEX] 0x1B 0x6D | [DEC] 27 109
  static String cutPaper() => String.fromCharCodes([27, 109]);

  /// 设置加粗
  /// [ASCII] ESC E n | [HEX] 0x1B 0x45 n | [DEC] 27 69 n
  static String setBold({bool bold = true}) => String.fromCharCodes([27, 69, bold ? 1 : 0]);

  /// 打开钱箱
  /// [ASCII] ESC p m t1 t2 | [HEX] 0x1B 0x70 0 60 255 | [DEC] 27 112 0 60 255
  static String openCashDrawer() => String.fromCharCodes([27, 112, 0, 60, 255]);

  /// 设置打印机颜色
  /// [ASCII] ESC r n | [HEX] 0x1B 0x72 n | [DEC] 27 114 n
  static String setPrinterColor({bool color = false}) => String.fromCharCodes([27, 114, color ? 1 : 0]);

  /// 设置字符集
  /// [ASCII] ESC R n | [HEX] 0x1B 0x52 n | [DEC] 27 82 n
  static String setCharSet({bool isChinese = true}) => String.fromCharCodes([27, 82, isChinese ? 15 : 0]);

  /// 打印空行
  /// [ASCII] GS ! n | [HEX] 0x1D 0x21 n | [DEC] 29 33 n
  static String printLine({int pageWidth = 48, int lines = 1}) =>
      "${String.fromCharCodes([29, 33, 0])}${' ' * pageWidth * lines}\n";

  ///设置行间距
  /// [ASCII] ESC 3 n | [HEX] 0x1B 0x33 n | [DEC] 27 51 n

  static List<int> setLineHeight({int height = 3}) => [27, 51, height.clamp(0, 255)];
}
