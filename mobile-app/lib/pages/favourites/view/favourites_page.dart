import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key, this.repository});

  final FavouritesRepository? repository;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const FavouritesPage());
  }

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late final FavouritesRepository _repository;
  late final bool _ownsRepository;

  _ViewStatus _status = _ViewStatus.loading;
  List<Map<String, dynamic>> _favourites = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FavouritesRepository();
    _ownsRepository = widget.repository == null;
    _load();
  }

  @override
  void dispose() {
    if (_ownsRepository) {
      _repository.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _ViewStatus.loading);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel = userRepository.currentUser ?? await userRepository.getUser();
      final records = await _repository.fetchFavourites(userModel: userModel);
      if (!mounted) return;
      setState(() {
        _favourites = records;
        _status = _ViewStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _ViewStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('favourites')),
      body: switch (_status) {
        _ViewStatus.loading => const CommonProgressWidget(),
        _ViewStatus.error => OfflineErrorWidget(onRetry: _load),
        _ViewStatus.loaded => _favourites.isEmpty
            ? const NoDataWidget()
            : ListView.separated(
                itemCount: _favourites.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final favourite = _favourites[index];
                  final title =
                      (favourite['name'] ?? favourite['title'] ?? 'Favourite ${index + 1}')
                          .toString();
                  final subtitle =
                      (favourite['subtitle'] ?? favourite['description'] ?? 'Saved item')
                          .toString();
                  return ListTile(title: Text(title), subtitle: Text(subtitle));
                },
              ),
      },
    );
  }
}

enum _ViewStatus { loading, error, loaded }
