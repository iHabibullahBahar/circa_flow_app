import 'package:circa_flow_main/src/imports/imports.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Arguments for the WebView route.
class WebViewArgs {
  final String url;
  final String title;

  const WebViewArgs({required this.url, required this.title});
}

/// In-app browser for rendering custom links from the backend config.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = Get.arguments as WebViewArgs?;
    final url = args?.url ?? '';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onPageStarted: (_) => setState(() => _isLoading = true),
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as WebViewArgs?;
    final cs = context.contextTheme.colorScheme;

    return Scaffold(
      appBar: AppTopBar(title: args?.title ?? ''),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
        ],
      ),
    );
  }
}
