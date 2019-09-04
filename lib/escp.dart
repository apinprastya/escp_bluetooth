import "dart:typed_data";

class Escp {
  int width;
  int master = 0;
  List<Uint8List> _chunkData = [];

  Escp({this.width}) {
    _chunkData.add(Uint8List.fromList([0x1B, 0x40]));
  }

  Escp bold(bool bold) {
    if (bold)
      master = master | 8;
    else
      master = master & ~8;
    _chunkData.add(Uint8List.fromList([0x1B, 0x21, master]));
    return this;
  }

  Escp doubleHeight(bool doubleHeight) {
    if (doubleHeight)
      master = master | 16;
    else
      master = master & ~16;
    _chunkData.add(Uint8List.fromList([0x1B, 0x21, master]));
    return this;
  }

  Escp doubleWidth(bool doubleWidth) {
    if (doubleWidth)
      master = master | 16;
    else
      master = master & ~16;
    _chunkData.add(Uint8List.fromList([0x1B, 0x21, master]));
    return this;
  }

  Escp lineFeed({int line = 1}) {
    for (int i = 0; i < line; i++)
      _chunkData.add(Uint8List.fromList([0x0A, 0x10]));
    return this;
  }

  Escp left() {
    _chunkData.add(Uint8List.fromList([0x1B, 0x61, 0x0]));
    return this;
  }

  Escp right() {
    _chunkData.add(Uint8List.fromList([0x1B, 0x61, 0x2]));
    return this;
  }

  Escp center() {
    _chunkData.add(Uint8List.fromList([0x1B, 0x61, 0x1]));
    return this;
  }

  Escp text(String text) {
    _chunkData.add(Uint8List.fromList(text.codeUnits));
    return this;
  }

  Uint8List data() {
    int l = 0;
    _chunkData.forEach((v) => l += v.length);
    final list = Uint8List(l);
    int offset = 0;
    _chunkData.forEach((v) {
      list.setRange(offset, offset + v.length, v);
      offset += v.length;
    });
    return list;
  }
}
