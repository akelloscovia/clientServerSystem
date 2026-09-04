import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/channel.dart';
import '../services/kiosk_service.dart';
import 'web_channel_player.dart';

/// TV channel switcher + player for the reception kiosk.
/// Direct video streams (HLS/mp4) play via video_player + chewie; YouTube
/// or other embeddable pages fall back to a WebView.
class TvChannelView extends StatefulWidget {
  const TvChannelView({super.key});

  @override
  State<TvChannelView> createState() => _TvChannelViewState();
}

class _TvChannelViewState extends State<TvChannelView> {
  final _kiosk = KioskService();

  List<Channel> _channels = [];
  Channel? _selected;
  bool _loading = true;
  String? _error;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  WebViewController? _webController;
  String? _webEmbedUrl; // web build: URL loaded in an <iframe>
  bool _playerLoading = false;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channels = await _kiosk.getChannels();
      if (!mounted) return;
      setState(() {
        _channels = channels;
        _loading = false;
      });
      if (channels.isNotEmpty) {
        _selectChannel(channels.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
    _webController = null;
    _webEmbedUrl = null;
  }

  Future<void> _selectChannel(Channel channel) async {
    _disposePlayer();
    setState(() {
      _selected = channel;
      _playerLoading = true;
      _playerError = null;
    });

    if (channel.playsInWebView) {
      if (kIsWeb) {
        // webview_flutter has no web build — load the channel in an
        // <iframe> instead (see _buildPlayer / web_channel_player.dart).
        if (!mounted) return;
        setState(() {
          _webEmbedUrl = channel.embedUrl;
          _playerLoading = false;
        });
        return;
      }
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(channel.streamUrl));
      if (!mounted) return;
      setState(() {
        _webController = controller;
        _playerLoading = false;
      });
      return;
    }

    try {
      final videoController =
          VideoPlayerController.networkUrl(Uri.parse(channel.streamUrl));
      await videoController.initialize();
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: true,
      );
      if (!mounted) return;
      setState(() {
        _videoController = videoController;
        _chewieController = chewieController;
        _playerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _playerError = 'Could not play this channel.';
        _playerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Color(0xFFfca5a5))),
      );
    }
    if (_channels.isEmpty) {
      return const Center(
        child: Text('No channels have been added yet.',
            style: TextStyle(color: Color(0xFF64748b))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _channels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final channel = _channels[i];
              final active = _selected?.id == channel.id;
              return GestureDetector(
                onTap: () => _selectChannel(channel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF3b82f6).withOpacity(0.2)
                        : const Color(0xFF1a2235),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF3b82f6)
                          : const Color(0x12FFFFFF),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      channel.name,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF60a5fa)
                            : const Color(0xFF94a3b8),
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPlayer(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayer() {
    if (_playerLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_playerError != null) {
      return Center(
        child: Text(_playerError!, style: const TextStyle(color: Colors.white70)),
      );
    }
    if (_webController != null) {
      return WebViewWidget(controller: _webController!);
    }
    if (_webEmbedUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          buildEmbeddedChannel(_webEmbedUrl!),
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => openChannelExternally(
                    _selected?.streamUrl ?? _webEmbedUrl!),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Open channel',
                          style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }
    return const Center(
      child: Text('Select a channel', style: TextStyle(color: Colors.white54)),
    );
  }
}
