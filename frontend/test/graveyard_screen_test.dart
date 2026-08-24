import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tilezhan/core/srs/srs_item.dart';
import 'package:tilezhan/features/graveyard/domain/graveyard_provider.dart';
import 'package:tilezhan/features/graveyard/presentation/graveyard_screen.dart';
import 'package:tilezhan/l10n/generated/app_localizations.dart';
import 'package:tilezhan/shared/models/tile_model.dart';

import 'test_utils.dart';

typedef _DueItem = (SrsItem, TileModel?);

const _emptySuitRates = <String, double>{
  'man': 0,
  'pin': 0,
  'sou': 0,
  'wind': 0,
  'dragon': 0,
};

class _ReviewProbe extends StatefulWidget {
  final Uri uri;
  final List<Uri> visits;

  const _ReviewProbe({
    required this.uri,
    required this.visits,
  });

  @override
  State<_ReviewProbe> createState() => _ReviewProbeState();
}

class _ReviewProbeState extends State<_ReviewProbe> {
  @override
  void initState() {
    super.initState();
    widget.visits.add(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(widget.uri.toString()),
          ElevatedButton(
            key: const Key('complete-review'),
            onPressed: () => context.pop(true),
            child: const Text('Complete review'),
          ),
          ElevatedButton(
            key: const Key('cancel-review'),
            onPressed: () => context.pop(),
            child: const Text('Cancel review'),
          ),
        ],
      ),
    );
  }
}

Widget _appWithReviewRoutes(
  List<_DueItem> dueItems,
  List<Uri> visits, {
  int? planTarget,
}) {
  Widget reviewBuilder(BuildContext context, GoRouterState state) {
    return _ReviewProbe(uri: state.uri, visits: visits);
  }

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => GraveyardScreen(planTarget: planTarget),
      ),
      GoRoute(path: '/flashcard', builder: reviewBuilder),
      GoRoute(path: '/nanikiru', builder: reviewBuilder),
      GoRoute(path: '/defense-training', builder: reviewBuilder),
      GoRoute(path: '/yaku-quiz', builder: reviewBuilder),
    ],
  );
  addTearDown(router.dispose);

  return ProviderScope(
    overrides: [
      graveyardDueProvider.overrideWithValue(dueItems),
      suitErrorRatesProvider.overrideWithValue(_emptySuitRates),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

SrsItem _item(String id, String type) => SrsItem(
      itemId: id,
      type: type,
      errors: 1,
    );

void _expectReviewUri(
  Uri uri, {
  required String path,
  required String contentId,
  String? suite,
}) {
  expect(uri.path, path);
  expect(uri.queryParameters['mode'], 'review');
  expect(uri.queryParameters['contentId'], contentId);
  expect(uri.queryParameters['suite'], suite);
}

void main() {
  group('GraveyardScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_appWithReviewRoutes(const [], []));
      await tester.pump();

      expect(find.byType(GraveyardScreen), findsOneWidget);
    });

    testWidgets('Review All follows due-item order with exact review routes',
        (tester) async {
      final visits = <Uri>[];
      final manTile = makeTile('man1', TileSuit.man, 'One Man');
      final dueItems = <_DueItem>[
        (_item('yaku.rule.dora_is_yaku.v1', 'yaku'), null),
        (_item('man1', 'flashcard'), manTile),
        (_item('nani.exact.2', 'nanikiru'), null),
        (_item('defense.suji.001.v1', 'defense'), null),
      ];

      await tester.pumpWidget(_appWithReviewRoutes(dueItems, visits));
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚡ Review All (4)'));
      await tester.pumpAndSettle();

      expect(visits, hasLength(1));
      _expectReviewUri(
        visits[0],
        path: '/yaku-quiz',
        contentId: 'yaku.rule.dora_is_yaku.v1',
      );

      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();
      expect(visits, hasLength(2));
      _expectReviewUri(
        visits[1],
        path: '/flashcard',
        contentId: 'man1',
        suite: 'man',
      );

      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();
      expect(visits, hasLength(3));
      _expectReviewUri(
        visits[2],
        path: '/nanikiru',
        contentId: 'nani.exact.2',
      );

      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();
      expect(visits, hasLength(4));
      _expectReviewUri(
        visits[3],
        path: '/defense-training',
        contentId: 'defense.suji.001.v1',
      );

      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();
      expect(find.byType(GraveyardScreen), findsOneWidget);
    });

    testWidgets('Review All stops when a review route is cancelled',
        (tester) async {
      final visits = <Uri>[];
      final pinTile = makeTile('pin3', TileSuit.pin, 'Three Pin');
      final dueItems = <_DueItem>[
        (_item('pin3', 'flashcard'), pinTile),
        (_item('nani.cancel.2', 'nanikiru'), null),
        (_item('yaku.must.not.start', 'yaku'), null),
      ];

      await tester.pumpWidget(_appWithReviewRoutes(dueItems, visits));
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚡ Review All (3)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();
      expect(visits.map((uri) => uri.path), ['/flashcard', '/nanikiru']);

      await tester.tap(find.byKey(const Key('cancel-review')));
      await tester.pumpAndSettle();

      expect(find.byType(GraveyardScreen), findsOneWidget);
      expect(visits.map((uri) => uri.path), ['/flashcard', '/nanikiru']);
      expect(
        visits.any(
          (uri) => uri.queryParameters['contentId'] == 'yaku.must.not.start',
        ),
        isFalse,
      );
    });

    testWidgets('today-plan Review All stops at the remaining target',
        (tester) async {
      final visits = <Uri>[];
      final dueItems = <_DueItem>[
        (_item('first', 'nanikiru'), null),
        (_item('second', 'defense'), null),
        (_item('third', 'yaku'), null),
      ];

      await tester.pumpWidget(
        _appWithReviewRoutes(dueItems, visits, planTarget: 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('⚡ Review All (2)'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('complete-review')));
      await tester.pumpAndSettle();

      expect(
        visits.map((uri) => uri.queryParameters['contentId']),
        ['first', 'second'],
      );
      expect(find.byType(GraveyardScreen), findsOneWidget);
    });
  });
}
