import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../theme/app_theme.dart';

/// Error boundary widget that catches and displays errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    
    // Capture errors in this widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error(
        'Flutter error caught by ErrorBoundary',
        details.exception,
        details.stack,
      );
      
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
      
      widget.onError?.call(details.exception, details.stack);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error!, _stackTrace);
      }
      
      return DefaultErrorWidget(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }
}

/// Default error widget displayed when an error occurs
class DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const DefaultErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.pureBlack : AppTheme.offWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.gray800 : AppTheme.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                  ),
                ),
                
                const SizedBox(height: AppTheme.space24),
                
                // Error title
                Text(
                  '發生錯誤',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.space12),
                
                // Error message
                Text(
                  _getErrorMessage(error),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.space32),
                
                // Retry button
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('重試'),
                  ),
                
                const SizedBox(height: AppTheme.space16),
                
                // Details button (debug mode)
                if (stackTrace != null)
                  TextButton(
                    onPressed: () => _showErrorDetails(context),
                    child: const Text('查看詳情'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '應用程式遇到了一個問題，請稍後再試';
  }

  void _showErrorDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.gray900 : AppTheme.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('錯誤詳情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '錯誤訊息：',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              if (stackTrace != null) ...[
                const SizedBox(height: AppTheme.space16),
                Text(
                  '堆疊追蹤：',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  stackTrace.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}

/// Compact error widget for inline errors
class CompactErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const CompactErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.gray850 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  _getErrorMessage(error),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.space12),
            TextButton(
              onPressed: onRetry,
              child: const Text('重試'),
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '載入失敗';
  }
}
