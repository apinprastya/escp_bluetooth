import "dart:typed_data";

class Escp {
  int width;
  int master;
  Uint8List data;

  Escp({this.width}) {
    data = Uint8List.fromList([0x1B, 0x40]);
  }

  Escp bold(bool bold) {
    if (bold)
      master = master | 8;
    else
      master = master & ~8;
    data.addAll(Uint8List.fromList([0x1B, 0x21, master]));
    return this;
  }

  Escp doubleHeight(bool doubleHeight) {
    if (doubleHeight)
      master = master | 16;
    else
      master = master & ~16;
    data.addAll(Uint8List.fromList([0x1B, 0x21, master]));
    return this;
  }

  Escp doubleWidth(bool doubleWidth) {
    if (doubleWidth)
      master = master | 16;
    else
      master = master & ~16;
    data.addAll(Uint8List.fromList([0x1B, 0x21, master]));
    return this;
  }

  Escp lineFeed({int line = 1}) {
    for (int i = 0; i < line; i++)
      data.addAll(Uint8List.fromList([0x0A, 0x10]));
    return this;
  }

  Escp left() {
    data.addAll(Uint8List.fromList([0x1B, 0x27, 0x0]));
    return this;
  }

  Escp right() {
    data.addAll(Uint8List.fromList([0x1B, 0x27, 0x2]));
    return this;
  }

  Escp center() {
    data.addAll(Uint8List.fromList([0x1B, 0x27, 0x1]));
    return this;
  }

  Escp text(String text) {
    data.addAll(Uint8List.fromList(text.codeUnits));
    return this;
  }
}
