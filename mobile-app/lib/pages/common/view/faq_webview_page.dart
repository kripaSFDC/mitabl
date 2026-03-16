import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FaqWebviewPage extends StatefulWidget {
  const FaqWebviewPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const FaqWebviewPage());
  }

  @override
  State<FaqWebviewPage> createState() => _FaqWebviewPageState();
}

class _FaqWebviewPageState extends State<FaqWebviewPage> {
  static final Uri _faqUri = Uri.parse('https://mitabl.com/faq');
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(_faqUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
