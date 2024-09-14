import 'package:characters/characters.dart';

class EscHelper {
  /// 居中打印
  static String alignCenterPrint({required int width, required String content}) {
    String str = content.toString();
    int strLength = calculateWidth(str);
    int halfWidth = ((width - strLength) ~/ 2);
    StringBuffer buffer = StringBuffer();

    // 添加空格
    buffer.write(' ' * halfWidth);
    // 添加内容
    buffer.write(content);
    // 添加空格
    buffer.write(' ' * (width - strLength - halfWidth));

    return buffer.toString();
  }

  /// 列表打印 原本48 最大46 边距2
  /// content 内容
  /// width 宽度
  /// algin 对齐方式 0左对齐 1居中 2右对齐
  static String columnMaker({required String content, required int width, int align = 0}) {
    int contentWidth = calculateWidth(content);
    int spaceWidth = width - contentWidth;

    // 使用 StringBuffer 进行拼接
    StringBuffer buffer = StringBuffer();

    if (align == 0) {
      // 左对齐
      buffer.write(content);
      buffer.write(' ' * spaceWidth);
    } else if (align == 1) {
      // 居中对齐
      int halfWidth = spaceWidth ~/ 2;
      buffer.write(' ' * halfWidth);
      buffer.write(content);
      buffer.write(' ' * (spaceWidth - halfWidth));
    } else {
      // 右对齐
      buffer.write(' ' * spaceWidth);
      buffer.write(content);
    }

    return buffer.toString();
  }

  // 静态方法，用于生成指定长度的横线
  static String fillHr({required int length, String ch = '-'}) {
    // 直接通过 String * 操作符生成指定长度的字符串
    return ch * length;
  }

  // 计算字符串的宽度
  static int calculateWidth(String text) {
    // 初始化宽度为0
    int width = 0;
    // 遍历字符串中的每个字符
    for (var char in text.characters) {
      // 如果字符是汉字，宽度加2，否则加1
      width += (RegExp(r'[\u4E00-\u9FFF]').hasMatch(char)) ? 2 : 1;
    }
    // 返回计算出的宽度
    return width;
  }

  ///字符串转列表，按照每行的长度进行分割
  static List<String> strToList({required String str, required int splitLength}) {
    String content = str.trim();
    int strLength = content.length;

    int startIndex = 0;
    List<String> strList = [];

    while (startIndex < strLength) {
      int endIndex = startIndex + splitLength;
      if (endIndex >= strLength) {
        endIndex = strLength;
      }

      var subStr = content.substring(startIndex, endIndex);

      while (calculateWidth(subStr) > splitLength && endIndex > startIndex) {
        endIndex--;
        subStr = content.substring(startIndex, endIndex);
      }

      strList.add(subStr.trim());
      startIndex = endIndex;
    }

    return strList;
  }

  static List<String> strToList2({required String str, required int splitLength}) {
    List<String> strList = [];

    // 先按照换行符分割字符串
    List<String> lines = str.split('\n');

    // 对每一行应用分割逻辑
    for (String line in lines) {
      String content = line.trim();
      int strLength = content.length;

      int startIndex = 0;

      while (startIndex < strLength) {
        int endIndex = startIndex + splitLength;
        if (endIndex >= strLength) {
          endIndex = strLength;
        }

        var subStr = content.substring(startIndex, endIndex);

        // 确保分割的子字符串宽度不超过 splitLength
        while (calculateWidth(subStr) > splitLength && endIndex > startIndex) {
          endIndex--;
          subStr = content.substring(startIndex, endIndex);
        }

        strList.add(subStr.trim());
        startIndex = endIndex;
      }
    }

    return strList;
  }

  /// algin 对齐方式 0左对齐 1居中 2右对齐
  static String setAlign({int align = 0}) {
    StringBuffer buffer = StringBuffer();
    // 根据对齐类型选择相应的控制字符
    switch (align) {
      case 1:
        buffer.writeCharCode(27); // ASCII 27 (Escape)
        buffer.writeCharCode(97); // ASCII 97 (a) 作为对齐控制字符
        buffer.writeCharCode(1); // 对齐模式 1
        break;
      case 2:
        buffer.writeCharCode(27); // ASCII 27 (Escape)
        buffer.writeCharCode(97); // ASCII 97 (a) 作为对齐控制字符
        buffer.writeCharCode(2); // 对齐模式 2
        break;
      default:
        buffer.writeCharCode(27); // ASCII 27 (Escape)
        buffer.writeCharCode(97); // ASCII 97 (a) 作为对齐控制字符
        buffer.writeCharCode(0); // 默认对齐模式 0
        break;
    }

    return buffer.toString();
  }

  /// content 内容
  /// size 默认正常大小 1:两倍高 2:两倍宽 3:两倍大小 4:三倍高 5:三倍宽 6:三倍大小 7:四倍高 8:四倍宽 9:四倍大小 10:五倍高 11:五倍宽 12:五倍大小
  static String setSize({int size = 0}) {
    // 使用 StringBuffer 进行字符串拼接
    StringBuffer buffer = StringBuffer();

    // 固定的 ESC (ASCII 27) 和 GS (ASCII 29) 控制符
    buffer.writeCharCode(29); // ASCII 29 (Group Separator) 对应 "\x1D"
    buffer.writeCharCode(33); // ASCII 33 ("!" 的代码点) 对应 "\x21"

    // 根据 size 选择相应的控制字符
    switch (size) {
      case 1:
        buffer.writeCharCode(1); // "\x01"
        break;
      case 2:
        buffer.writeCharCode(16); // "\x10"
        break;
      case 3:
        buffer.writeCharCode(17); // "\x11"
        break;
      case 4:
        buffer.writeCharCode(2); // "\x02"
        break;
      case 5:
        buffer.writeCharCode(32); // "\x20"
        break;
      case 6:
        buffer.writeCharCode(34); // "\x22"
        break;
      case 7:
        buffer.writeCharCode(3); // "\x03"
        break;
      case 8:
        buffer.writeCharCode(48); // "\x30"
        break;
      case 9:
        buffer.writeCharCode(51); // "\x33"
        break;
      case 11:
        buffer.writeCharCode(4); // "\x04"
        break;
      case 12:
        buffer.writeCharCode(64); // "\x40"
        break;
      default:
        buffer.writeCharCode(0); // "\x00"
        break;
    }

    return buffer.toString();
  }

  ///设置走纸行数
  static String setLineSpace({required int line}) {
    StringBuffer buffer = StringBuffer();

    // 添加控制字符 ESC (ASCII 27) 和 D (ASCII 100) 以及行数
    buffer.writeCharCode(27); // ASCII 27 (Escape)
    buffer.writeCharCode(100); // ASCII 100 ('d')
    buffer.writeCharCode(line); // 行数作为字符
    return buffer.toString();
  }

  ///切纸
  static String cutPaper() {
    StringBuffer buffer = StringBuffer();

    // 添加控制字符 ESC (ASCII 27) 和 m (ASCII 109)
    buffer.writeCharCode(27); // ASCII 27 (Escape)
    buffer.writeCharCode(109); // ASCII 109 ('m')

    return buffer.toString();
  }

  /// 设置加粗
  static String setBold() {
    //\x1B\x01 \x1B\X45\x01
    StringBuffer buffer = StringBuffer();
    buffer.writeCharCode(27); // ASCII 27 (Escape)
    buffer.writeCharCode(69); // ASCII 69 ('E')
    buffer.writeCharCode(1); // ASCII 1

    return buffer.toString();
  }

  /// 取消加粗
  static String resetBold() {
    //\x1BE\x00 \x1B\X45\x00
    StringBuffer buffer = StringBuffer();
    buffer.writeCharCode(27); // ASCII 27 (Escape)
    buffer.writeCharCode(69); // ASCII 69 ('E')
    buffer.writeCharCode(0); // ASCII 0 (Null)
    return buffer.toString();
  }

  /// 打开钱箱
  static String openCashDrawer() {
    //return "\x1B\x70\x00\x19\xFA"; // ESC p m t1 t2 -> 打开钱箱

    StringBuffer buffer = StringBuffer();
    // 添加控制字符 ESC (ASCII 27), p (ASCII 112), 0 (ASCII 0), < (ASCII 60), 和 ￿ (ASCII 255)
    buffer.writeCharCode(27); // ASCII 27 (Escape)
    buffer.writeCharCode(112); // ASCII 112 ('p')
    buffer.writeCharCode(0); // ASCII 0 (Null)
    buffer.writeCharCode(60); // ASCII 60 ('<')
    buffer.writeCharCode(255); // ASCII 255 (ÿ)

    return buffer.toString();
  }

  ///分割字符串
  static List<String> splitString(String input, int lengthPerSegment) {
    // 定义一个空列表，用于存储分割后的字符串
    List<String> segments = [];
    // 将输入字符串转换为Characters对象
    Characters characters = input.characters;

    // 当Characters对象不为空时，循环执行以下操作
    while (characters.isNotEmpty) {
      // 从Characters对象中取出指定长度的字符串
      String segment = characters.take(lengthPerSegment).toString();
      // 将取出的字符串添加到segments列表中
      segments.add(segment);
      // 将Characters对象跳过指定长度的字符串
      characters = characters.skip(lengthPerSegment);
    }

    // 返回分割后的字符串列表
    return segments;
  }
}
