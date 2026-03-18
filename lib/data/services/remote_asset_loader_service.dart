import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 遠端資源載入服務
/// 
/// 使用 jsDelivr CDN 從 GitHub 載入大型資源檔案
/// 優點：
/// - 減少 APK 大小
/// - 免費無限流量
/// - 全球 CDN 加速
/// - 支援版本控制
class RemoteAssetLoaderService {
  final Logger _logger = Logger();
  final Dio _dio;
  
  // jsDelivr CDN 基礎 URL
  // 格式: https://cdn.jsdelivr.net/gh/用戶名/倉庫名@版本/檔案路徑
  static const String _cdnBaseUrl = 'https://cdn.jsdelivr.net/gh';
  
  // 你的 GitHub 倉庫資訊
  static const String _githubUser = 'Chancecmh1019';
  static const String _githubRepo = 'WayFinder-file';
  static const String _githubBranch = 'main'; // 或使用 tag 如 'v1.0.0'
  
  // 本地緩存設定
  static const String _cacheKeyPrefix = 'remote_asset_';
  static const Duration _cacheExpiration = Duration(days: 7);

  RemoteAssetLoaderService({Dio? dio}) 
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ));

  /// 載入遠端 gzip 壓縮的 JSON 檔案
  /// 
  /// [assetPath] 檔案在 GitHub 倉庫中的路徑，例如 'vocab.json.gz'
  /// [forceRefresh] 是否強制重新下載，忽略緩存
  Future<Map<String, dynamic>> loadGzipJson(
    String assetPath, {
    bool forceRefresh = false,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      _logger.i('[RemoteAssetLoader] 開始載入: $assetPath');

      // 檢查本地緩存
      if (!forceRefresh) {
        final cached = await _loadFromCache(assetPath);
        if (cached != null) {
          _logger.i('[RemoteAssetLoader] 從緩存載入: $assetPath');
          return cached;
        }
      }

      // 從 CDN 下載
      final url = _buildCdnUrl(assetPath);
      _logger.i('[RemoteAssetLoader] 下載 URL: $url');

      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            _logger.d('[RemoteAssetLoader] 下載進度: $progress% ($received/$total bytes)');
            onProgress?.call(received, total);
          }
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('下載失敗: HTTP ${response.statusCode}');
      }

      final bytes = Uint8List.fromList(response.data!);
      _logger.i('[RemoteAssetLoader] 已下載 ${bytes.length} bytes');

      // 解壓縮 gzip
      final decompressed = GZipDecoder().decodeBytes(bytes);
      final jsonString = utf8.decode(decompressed);
      _logger.i('[RemoteAssetLoader] 已解壓縮 ${decompressed.length} bytes');

      // 解析 JSON
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      _logger.i('[RemoteAssetLoader] JSON 解析完成');

      // 儲存到緩存
      await _saveToCache(assetPath, jsonData);

      return jsonData;
    } catch (e, stackTrace) {
      _logger.e('[RemoteAssetLoader] 載入失敗: $assetPath: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 載入遠端文字檔案
  Future<String> loadTextFile(
    String assetPath, {
    bool forceRefresh = false,
  }) async {
    try {
      final url = _buildCdnUrl(assetPath);
      _logger.i('[RemoteAssetLoader] 載入文字檔案: $url');

      final response = await _dio.get<String>(url);
      
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('下載失敗: HTTP ${response.statusCode}');
      }

      return response.data!;
    } catch (e, stackTrace) {
      _logger.e('[RemoteAssetLoader] 載入文字檔案失敗: $assetPath: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 下載檔案到本地儲存
  Future<File> downloadFile(
    String assetPath,
    String localFileName, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final url = _buildCdnUrl(assetPath);
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$localFileName';
      
      _logger.i('[RemoteAssetLoader] 下載檔案到: $filePath');

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
      );

      return File(filePath);
    } catch (e, stackTrace) {
      _logger.e('[RemoteAssetLoader] 下載檔案失敗: $assetPath: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 建立 CDN URL
  String _buildCdnUrl(String assetPath) {
    // jsDelivr URL 格式: 
    // https://cdn.jsdelivr.net/gh/user/repo@version/path/to/file
    return '$_cdnBaseUrl/$_githubUser/$_githubRepo@$_githubBranch/$assetPath';
  }

  /// 從本地緩存載入
  Future<Map<String, dynamic>?> _loadFromCache(String assetPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$assetPath';
      final timestampKey = '${cacheKey}_timestamp';

      // 檢查緩存是否過期
      final timestamp = prefs.getInt(timestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final age = DateTime.now().difference(cacheTime);
        
        if (age > _cacheExpiration) {
          _logger.d('[RemoteAssetLoader] 緩存已過期: $assetPath');
          return null;
        }
      }

      // 從檔案系統載入緩存
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/cache_$assetPath');
      
      if (!await cacheFile.exists()) {
        return null;
      }

      final jsonString = await cacheFile.readAsString();
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('[RemoteAssetLoader] 載入緩存失敗: $e');
      return null;
    }
  }

  /// 儲存到本地緩存
  Future<void> _saveToCache(
    String assetPath,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$assetPath';
      final timestampKey = '${cacheKey}_timestamp';

      // 儲存時間戳
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      // 儲存到檔案系統
      final dir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${dir.path}/cache_$assetPath');
      
      final jsonString = json.encode(data);
      await cacheFile.writeAsString(jsonString);

      _logger.d('[RemoteAssetLoader] 已儲存緩存: $assetPath');
    } catch (e) {
      _logger.w('[RemoteAssetLoader] 儲存緩存失敗: $e');
    }
  }

  /// 清除所有緩存
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
          .where((key) => key.startsWith(_cacheKeyPrefix))
          .toList();
      
      for (final key in keys) {
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }

      // 清除緩存檔案
      final dir = await getApplicationDocumentsDirectory();
      final cacheFiles = dir.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('cache_'));
      
      for (final file in cacheFiles) {
        await file.delete();
      }

      _logger.i('[RemoteAssetLoader] 緩存已清除');
    } catch (e) {
      _logger.w('[RemoteAssetLoader] 清除緩存失敗: $e');
    }
  }

  /// 檢查遠端檔案是否存在
  Future<bool> checkFileExists(String assetPath) async {
    try {
      final url = _buildCdnUrl(assetPath);
      final response = await _dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 取得緩存資訊
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheFiles = dir.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('cache_'))
          .toList();

      int totalSize = 0;
      for (final file in cacheFiles) {
        totalSize += await file.length();
      }

      return {
        'fileCount': cacheFiles.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      return {
        'fileCount': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': '0.00',
      };
    }
  }
}
