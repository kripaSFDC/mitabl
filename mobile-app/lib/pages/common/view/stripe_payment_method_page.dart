import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StripePaymentMethodPage extends StatefulWidget {
  const StripePaymentMethodPage({super.key, required this.initialUrl});

  final String initialUrl;

  static Future<String?> present(
    BuildContext context, {
    required String initialUrl,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => StripePaymentMethodPage(initialUrl: initialUrl),
      ),
    );
  }

  @override
  State<StripePaymentMethodPage> createState() =>
      _StripePaymentMethodPageState();
}

class _StripePaymentMethodPageState extends State<StripePaymentMethodPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.scheme == 'mitabl' &&
                uri.host == 'payment-method-complete') {
              Navigator.of(
                context,
              ).pop(uri.queryParameters['payment_method_id']);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('One-time card')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
