import 'dart:convert';
import 'dart:typed_data';

import 'package:beacon/data/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class ElevenLabsService {
  ElevenLabsService._();
  static final ElevenLabsService instance = ElevenLabsService._();

  final _player = AudioPlayer();

  // Default English multi-lingual model and a popular voice (replace with your Voice ID)
  static const String defaultModel = 'eleven_multilingual_v2';
  static const String defaultVoiceId = '21m00Tcm4TlvDq8ikWAM'; // Rachel (example)

  String? get _apiKey => dotenv.maybeGet(ELEVEN_LABS_API_KEY_ENV) ?? const String.fromEnvironment(ELEVEN_LABS_API_KEY_ENV);

  Future<void> initEnv() async {
    if (dotenv.isInitialized) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // ignore if .env missing; rely on --dart-define
    }
  }

  // Simple in-memory cache to avoid re-fetching the same audio for identical text
  final Map<String, Uint8List> _cache = {};

  Future<void> speakText(
    String text, {
    BuildContext? context,
    String? voiceId,
    String? modelId,
    double stability = 0.5,
    double similarityBoost = 0.75,
    String outputFormat = 'mp3_44100_128',
    Duration timeout = const Duration(seconds: 20),
  }) async {
    await initEnv();
    final key = _apiKey;
    if (text.trim().isEmpty) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to read')),
        );
      }
      return;
    }
    if (key == null || key.isEmpty) {
      debugPrint('ELEVENLABS_API_KEY not set. Provide via --dart-define or .env');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice disabled: missing ElevenLabs API key')),
        );
      }
      return;
    }

    final vid = voiceId ?? defaultVoiceId;
    final mid = modelId ?? defaultModel;

    final uri = Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$vid');
    final headers = {
      'xi-api-key': key,
      'accept': 'audio/mpeg',
      'content-type': 'application/json',
    };
    final payload = jsonEncode({
      'text': text,
      'model_id': mid,
      'output_format': outputFormat,
      'voice_settings': {
        'stability': stability,
        'similarity_boost': similarityBoost,
      }
    });

    try {
      // Serve from cache if available
      if (_cache.containsKey(text)) {
        await _playBytes(_cache[text]!);
        return;
      }

      final resp = await http.post(uri, headers: headers, body: payload).timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final bytes = resp.bodyBytes;
        _cache[text] = bytes;
        await _playBytes(bytes);
      } else {
        final msg = 'TTS error ${resp.statusCode}';
        debugPrint('ElevenLabs TTS error ${resp.statusCode}: ${resp.body}');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice error: $msg')),
          );
        }
      }
    } on Exception catch (e) {
      debugPrint('TTS request failed: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error while generating speech')),
        );
      }
    }
  }

  Future<void> _playBytes(Uint8List bytes) async {
    try {
      await _player.stop();
      await _player.setAudioSource(BytesAudioSource(bytes));
      await _player.play();
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }
}

/// Simple in-memory bytes audio source for just_audio
class BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final s = start ?? 0;
    final e = end ?? _bytes.length;
    final slice = _bytes.sublist(s, e);
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: slice.length,
      offset: s,
      stream: Stream.value(slice),
      contentType: 'audio/mpeg',
    );
  }
}
