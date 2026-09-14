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
        height: 92,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/advertise_with_us_logo.jpg',
                height: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const Expanded(
              child: Text('Advertise with us',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
            ),
          ],
        ),
      );
    }

    final ad = _ads[_index % _ads.length];
    return Container(
      height: 160,
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
                width: 260,
                height: double.infinity,
                child: Image.memory(base64Decode(ad.imageData.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ad.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                      if (ad.description.isNotEmpty)
                        Text(ad.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
