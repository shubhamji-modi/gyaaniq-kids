import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/appcolors.dart';

class GoogleMeetWebViewScreen extends StatefulWidget {
  const GoogleMeetWebViewScreen({
    super.key,
    required this.meetUrl,
    required this.title,
  });

  final String meetUrl;
  final String title;

  @override
  State<GoogleMeetWebViewScreen> createState() =>
      _GoogleMeetWebViewScreenState();
}

class _GoogleMeetWebViewScreenState extends State<GoogleMeetWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _prepareMeetWebView();
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    if (_controller == null) {
      await _prepareMeetWebView();
      return;
    }
    await _controller!.reload();
  }

  Future<void> _prepareMeetWebView() async {
    final permissionGranted = await _requestMeetPermissions();
    if (!mounted) {
      return;
    }
    if (!permissionGranted) {
      setState(() {
        _isLoading = false;
        _error = 'Camera and microphone permission are required to join Meet.';
      });
      return;
    }

    final controller =
        WebViewController(
            onPermissionRequest: (request) {
              request.grant();
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          // ..setUserAgent(
          //   'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
          //   '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          // )
          ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (url) {
                  print("PAGE STARTED => $url");
                },
                onPageFinished: (url) {
                  print("PAGE FINISHED => $url");
                },
                onNavigationRequest: (request) {
                  print("NAVIGATION => ${request.url}");
                  return NavigationDecision.navigate;
                },
                onWebResourceError: (error) {
                  print("ERROR CODE => ${error.errorCode}");
                  print("ERROR DESC => ${error.description}");
                },
              )
          );

    setState(() {
      _controller = controller;
      _isLoading = true;
      _error = '';
    });
    await controller.loadRequest(_meetUri);
  }

  Future<bool> _requestMeetPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    } on MissingPluginException {
      return true;
    } catch (_) {
      return true;
    }
  }

  Uri get _meetUri {
    final uri = Uri.parse(widget.meetUrl.trim());
    final params = Map<String, String>.from(uri.queryParameters);
    params.putIfAbsent('authuser', () => '0');
    return uri.replace(queryParameters: params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.headerBorder),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textBlueDark,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textBlueDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textBlueDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_controller != null)
                    WebViewWidget(controller: _controller!),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _reload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
