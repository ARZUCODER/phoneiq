class Phone {
  final String id;
  final String brand;
  final String model;
  final int priceUzs;
  final int ramGb;
  final int storageGb;
  final int batteryMah;
  final String display;
  final int mainCameraMp;
  final String chipset;
  final bool fiveG;
  final List<String> tags;
  final String bestFor;

  Phone({
    required this.id,
    required this.brand,
    required this.model,
    required this.priceUzs,
    required this.ramGb,
    required this.storageGb,
    required this.batteryMah,
    required this.display,
    required this.mainCameraMp,
    required this.chipset,
    required this.fiveG,
    required this.tags,
    required this.bestFor,
  });

  factory Phone.fromJson(Map<String, dynamic> j) {
    return Phone(
      id: j['id'] ?? '',
      brand: j['brand'] ?? '',
      model: j['model'] ?? '',
      priceUzs: (j['price_uzs'] ?? 0) as int,
      ramGb: (j['ram_gb'] ?? 0) as int,
      storageGb: (j['storage_gb'] ?? 0) as int,
      batteryMah: (j['battery_mah'] ?? 0) as int,
      display: j['display'] ?? '',
      mainCameraMp: (j['main_camera_mp'] ?? 0) as int,
      chipset: j['chipset'] ?? '',
      fiveG: (j['five_g'] ?? false) as bool,
      tags: List<String>.from(j['tags'] ?? const []),
      bestFor: j['best_for'] ?? '',
    );
  }

  String get priceLabel {
    final s = priceUzs.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(' ');
    }
    return '${buf.toString().split('').reversed.join()} so\'m';
  }
}

class ChatMessage {
  final String role;
  final String text;
  final List<Phone> phones;

  ChatMessage({required this.role, required this.text, this.phones = const []});
}
