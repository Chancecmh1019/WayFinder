/// 統一的 TTS 服務介面
///
/// 所有 TTS 服務（FlutterTtsService、EdgeTtsService）均應遵守此介面，
/// 讓呼叫方無須依賴 dynamic 型別，取得完整型別安全。
abstract class TtsServiceInterface {
  /// 播放文字
  Future<bool> speak(String text);

  /// 停止播放
  Future<void> stop();

  /// 當前是否正在播放
  bool get isPlaying;

  /// 回調：播放完成時觸發
  void Function()? onComplete;
}
