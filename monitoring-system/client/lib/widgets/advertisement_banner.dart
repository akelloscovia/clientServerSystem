import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/kiosk_service.dart';

class AdvertisementBanner extends StatefulWidget {
  const AdvertisementBanner({super.key});

  @override
  State<AdvertisementBanner> createState() => _AdvertisementBannerState();
}

class _AdvertisementBannerState extends State<AdvertisementBanner> {
  final _kiosk = KioskService();
  List<Advertisement> _ads = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ads = await _kiosk.getAdvertisements();
      if (mounted) setState(() => _ads = ads);
    } catch (_) {
      // The TV remains usable if the optional advert feed is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('Advertise with us',
              style: TextStyle(
                  color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
        ),
      );
    }

    final ad = _ads[_index % _ads.length];
    return Container(
      height: 92,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: _ads.length > 1
            ? () => setState(() => _index = (_index + 1) % _ads.length)
            : null,
        child: Row(
          children: [
            if (ad.imageData.isNotEmpty)
              SizedBox(
                width: 150,
                height: double.infinity,
                child: Image.memory(base64Decode(ad.imageData.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ad.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      if (ad.description.isNotEmpty)
                        Text(ad.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
