import 'package:atproto/atproto.dart' as atp;
import 'package:desafio_tecnico_spark/models/VideoModel.dart';
import 'package:dio/dio.dart';

class VideoService {
  final Dio _dio = Dio();
  bool _listening = false;

  Future<void> listenToFirehose(Function(VideoModel) onNewVideo) async {
    if (_listening) {
      print('Firehose já está escutando, ignorando nova chamada.');
      return;
    }
    _listening = true;

    final session = await atp.createSession(
      identifier: 'email@gmail.com',
      password: 'PASSWORD',
    );

    final atproto = atp.ATProto.fromSession(session.data);
    _dio.options.headers['Authorization'] = 'Bearer ${session.data.accessJwt}';

    final subscription = await atproto.sync.subscribeRepos();

    await for (final event in subscription.data.stream) {
      event.when(
        commit: (data) async {
          final ops = data.ops;

          for (final op in ops) {
            if (op.action != atp.RepoAction.create &&
                op.action != atp.RepoAction.update) continue;

            final record = op.record;
            if (record == null) continue;

            Map<String, dynamic>? postData;

            if (record['\$type'] == 'app.bsky.feed.post') {
              postData = record;
            } else if (record['subject'] is Map &&
                record['subject']['uri'] != null) {
              final uri = record['subject']['uri'];
              final parts = uri.split('/');
              if (parts.length >= 5) {
                final repo = parts[2];
                final rkey = parts.last;

                final res = await _dio.get(
                  'https://bsky.social/xrpc/com.atproto.repo.getRecord',
                  queryParameters: {
                    'repo': repo,
                    'collection': 'app.bsky.feed.post',
                    'rkey': rkey,
                  },
                  options: Options(
                    validateStatus: (status) =>
                        status != null, // permite qualquer status
                  ),
                );
                if (res.statusCode == 200 &&
                    res.data is Map &&
                    res.data['value'] is Map) {
                  postData = res.data['value'];
                } else {
                  print(
                      'Resposta inesperada ao buscar post: ${res.statusCode} | ${res.data}');
                  continue;
                }
              }
            }

            if (postData == null) continue;
            final embed = postData['embed'];
            if (embed == null) continue;

            String? videoUrl;
            final authorDid = data.did;

            if (embed['\$type'] == 'app.bsky.embed.external') {
              videoUrl = "";
            } else if (embed['\$type'] == 'app.bsky.embed.video') {
              final videoData = embed['video'];
              final ref = videoData?['ref'];
              final cid = ref?['\$link'];
              if (cid != null) {
                final possibleUrl =
                    'https://bsky.social/xrpc/com.atproto.sync.getBlob?did=$authorDid&cid=$cid';

                final response = await _dio.head(
                  possibleUrl,
                  options: Options(
                    validateStatus: (status) => status != null,
                  ),
                );
                if (response.statusCode == 200) {
                  videoUrl = possibleUrl;
                } else {
                  print('Blob inválido: Status ${response.statusCode}');
                  continue;
                }
              }
            }

            if (videoUrl == null || videoUrl.isEmpty) {
              print('Nenhuma URL de vídeo válida encontrada.');
              continue;
            }

            final description = postData['text'] ?? '';

            final profile = await _getAuthorProfile(authorDid);

            final video = VideoModel(
              id: op.uri.toString(),
              url: videoUrl,
              description: description,
              authorName: profile['displayName'] ?? authorDid,
              authorAvatar: profile['avatar'] ?? '',
            );

            onNewVideo(video);
          }
        },
        handle: (_) {},
        migrate: (_) {},
        tombstone: (_) {},
        info: (_) {},
        unknown: (_) {},
        identity: (_) {},
        account: (_) {},
      );
    }
  }

  Future<Map<String, dynamic>> _getAuthorProfile(String did) async {
    try {
      final response = await _dio.get(
        'https://bsky.social/xrpc/app.bsky.actor.getProfile',
        queryParameters: {'actor': did},
      );
      return response.data;
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return {};
    }
  }
}
