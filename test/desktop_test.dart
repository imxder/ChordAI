import 'package:chordai/models/app_theme.dart';
import 'package:chordai/screens/app_shell.dart';
import 'package:chordai/screens/chord_detail_screen.dart';
import 'package:chordai/screens/free_practice_screen.dart';
import 'package:chordai/screens/profile_screen.dart';
import 'package:chordai/screens/preferences_screen.dart';
import 'package:chordai/screens/home_screen.dart';
import 'package:chordai/screens/tuner_screen.dart';
import 'package:chordai/screens/guide_list_screen.dart';
import 'package:chordai/screens/settings_screen.dart';
import 'package:chordai/state/app_state.dart';
import 'package:chordai/theme/app_theme.dart';
import 'package:chordai/theme/glass_tokens.dart';
import 'package:chordai/theme/mac_style.dart';
import 'package:chordai/theme/platform_style.dart';
import 'package:chordai/theme/windows_style.dart';
import 'package:chordai/widgets/desktop_input.dart';
import 'package:chordai/widgets/page_parts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Abre o app como no computador (Windows), numa janela de [size].
Future<void> _abrir(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
  Widget home = const AppShell(),
  AppAppearance appearance = AppAppearance.paper,
}) async {
  setScreen(tester, size);
  await tester.pumpWidget(appUnderTest(home, appearance: appearance));
  await settle(tester);
}

/// Os testes do computador rodam como Windows.
final _windows = TargetPlatformVariant.only(TargetPlatform.windows);

Finder _aba(String nome) => find.byKey(ValueKey('aba $nome'));

/// Um texto dentro do Início. A barra lateral do computador também tem
/// "Reconhecer acorde" e "Guia do iniciante", então o texto sozinho aparece
/// duas vezes.
Finder _noInicio(String texto) =>
    find.descendant(of: find.byType(HomeScreen), matching: find.text(texto));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  setUp(() async {
    mockPlatform();
    await appState.loadProgress();
  });

  group('casca', () {
    testWidgets('no Windows tem barra lateral, sem a barra de abas', (
      tester,
    ) async {
      await _abrir(tester);
      expect(find.byKey(appSideBarKey), findsOneWidget);
      expect(find.byKey(appTabBarKey), findsNothing);
      for (final aba in [
        'Início',
        'Afinador',
        'Aprender acordes',
        'Reconhecer acorde',
        'Guia do iniciante',
        'Músicas',
        'Preferências',
        'Perfil',
      ]) {
        expect(_aba(aba), findsOneWidget);
      }
    }, variant: _windows);

    testWidgets('no celular continua a barra de abas, sem a lateral', (
      tester,
    ) async {
      setScreen(tester, const Size(390, 844));
      await tester.pumpWidget(appUnderTest(const AppShell()));
      await settle(tester);
      expect(find.byKey(appTabBarKey), findsOneWidget);
      expect(find.byKey(appSideBarKey), findsNothing);
    }, variant: TargetPlatformVariant.mobile());

    test('isDesktop só no Windows e no Mac', () {
      for (final plataforma in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = plataforma;
        expect(
          isDesktop,
          plataforma == TargetPlatform.windows ||
              plataforma == TargetPlatform.macOS,
          reason: plataforma.name,
        );
      }
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(desktopLook, DesktopLook.windows);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(desktopLook, DesktopLook.mac);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('trocar de aba pela barra lateral', (tester) async {
      await _abrir(tester);
      await tester.tap(_aba('Aprender acordes'));
      await settle(tester);
      expect(find.byType(ChordDetailScreen), findsOneWidget);
      await tester.tap(_aba('Perfil'));
      await settle(tester);
      expect(find.text('Seu nome'), findsOneWidget);
    }, variant: _windows);

    testWidgets('janela estreita recolhe a barra e o menu abre de novo', (
      tester,
    ) async {
      await _abrir(tester, size: const Size(800, 560));
      // Recolhida: só ícones, o nome das abas não aparece.
      expect(find.text('Músicas'), findsNothing);
      await tester.tap(find.byTooltip('Abrir o menu'));
      await settle(tester);
      expect(find.text('Músicas'), findsOneWidget);
      await tester.tap(find.byTooltip('Recolher o menu'));
      await settle(tester);
      expect(find.text('Músicas'), findsNothing);
    }, variant: _windows);

    testWidgets('a tela aberta fica do lado da barra, e Esc volta', (
      tester,
    ) async {
      await _abrir(tester);
      await tester.tap(_noInicio('Reconhecer acorde'));
      await settle(tester);
      expect(find.byType(FreePracticeScreen), findsOneWidget);
      expect(find.byKey(appSideBarKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.byType(FreePracticeScreen), findsNothing);

      // Na primeira tela da aba, Esc não faz nada.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(_noInicio('Guia do iniciante'), findsOneWidget);
    }, variant: _windows);

    testWidgets('o botão de voltar do cabeçalho volta', (tester) async {
      await _abrir(tester);
      await tester.tap(_noInicio('Reconhecer acorde'));
      await settle(tester);
      await tester.tap(find.byTooltip('Voltar'));
      await settle(tester);
      expect(find.byType(FreePracticeScreen), findsNothing);
    }, variant: _windows);

    testWidgets('clicar de novo na aba aberta volta pra primeira tela dela', (
      tester,
    ) async {
      await _abrir(tester);
      await tester.tap(_noInicio('Reconhecer acorde'));
      await settle(tester);
      await tester.tap(_aba('Início'));
      await settle(tester);
      expect(find.byType(FreePracticeScreen), findsNothing);
    }, variant: _windows);

    testWidgets('as abas se refazem quando o app muda', (tester) async {
      await _abrir(tester);
      await tester.tap(_aba('Perfil'));
      await settle(tester);
      await appState.setProfile(name: 'Alexandre');
      await settle(tester);
      expect(find.text('Alexandre'), findsOneWidget);
    }, variant: _windows);
  });

  group('colunas', () {
    testWidgets('acordes: clicar na lista troca o acorde do lado', (
      tester,
    ) async {
      await _abrir(tester);
      await tester.tap(_aba('Aprender acordes'));
      await settle(tester);
      final primeiro = appState.chordsInModel.first;
      final outro = appState.chordsInModel[1];
      expect(
        tester.widget<ChordDetailScreen>(find.byType(ChordDetailScreen)).chord,
        primeiro,
      );
      await tester.tap(find.text(outro).first);
      await settle(tester);
      expect(
        tester.widget<ChordDetailScreen>(find.byType(ChordDetailScreen)).chord,
        outro,
      );
    }, variant: _windows);

    testWidgets('a coluna de leitura é mais larga no computador', (
      tester,
    ) async {
      await _abrir(tester, home: const Placeholder());
      final context = tester.element(find.byType(Placeholder));
      // 1200 de janela, coluna de 720: sobram 240 de cada lado.
      expect(pagePadding(context).left, 240);
    }, variant: _windows);
  });

  group('mouse e teclado', () {
    testWidgets('espaço começa e para no computador', (tester) async {
      var vezes = 0;
      await _abrir(
        tester,
        home: SpaceToToggle(
          onToggle: () => vezes++,
          child: const Scaffold(body: Text('tela')),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(vezes, 2);
    }, variant: _windows);

    testWidgets('no celular o espaço não liga nada', (tester) async {
      var vezes = 0;
      await tester.pumpWidget(
        appUnderTest(
          SpaceToToggle(
            onToggle: () => vezes++,
            child: const Scaffold(body: Text('tela')),
          ),
        ),
      );
      expect(find.byType(CallbackShortcuts), findsNothing);
      expect(vezes, 0);
    });

    testWidgets('cursor de mão só no computador', (tester) async {
      await _abrir(tester, home: const ClickCursor(child: Text('clicável')));
      final region = tester.widget<MouseRegion>(
        find
            .ancestor(
              of: find.text('clicável'),
              matching: find.byType(MouseRegion),
            )
            .first,
      );
      expect(region.cursor, SystemMouseCursors.click);
    }, variant: _windows);

    testWidgets('bandeja vira diálogo no computador', (tester) async {
      await _abrir(
        tester,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showGlassSheet<void>(
              context,
              builder: (_) => const Text('conteúdo'),
            ),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('conteúdo'), findsOneWidget);
    }, variant: _windows);

    testWidgets('entrada de áudio pelo menu lateral', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.llfbandit.record/messages'),
            (call) async => call.method == 'listInputDevices'
                ? [
                    {'id': 'gt1', 'label': 'IN (2- GT-1)'},
                  ]
                : null,
          );
      await _abrir(tester);
      await tester.tap(find.byKey(const ValueKey('ação Entrada de áudio')));
      await settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.text('IN (2- GT-1)'));
      await settle(tester);
      expect(appState.inputDeviceId, 'gt1');
      await tester.tap(find.text('Pronto'));
      await settle(tester);
      expect(find.byType(Dialog), findsNothing);
    }, variant: _windows);
  });

  group('reconhecimento no computador', () {
    testWidgets('só tem o modelo no aparelho', (tester) async {
      await _abrir(tester, home: const SettingsScreen());
      expect(find.text('Reconhecimento de acordes'), findsNothing);
      expect(find.text('Endereço do servidor'), findsNothing);
      expect(find.text('Modelo no aparelho'), findsOneWidget);
    }, variant: _windows);
  });

  group('cara do Windows 11', () {
    test('fonte do Windows, menos nos acordes', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final theme = buildAppTheme(appThemeOptions.first);
      expect(theme.textTheme.bodyMedium?.fontFamily, windowsFont);
      expect(theme.textTheme.displayLarge?.fontFamily, fontChord);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final celular = buildAppTheme(appThemeOptions.first);
      expect(celular.textTheme.bodyMedium?.fontFamily, isNot(windowsFont));
      debugDefaultTargetPlatformOverride = null;
    });

    test('cantos menores no Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(GlassTokens.radiusXl, 8);
      expect(GlassTokens.radiusMd, 6);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(GlassTokens.radiusXl, 24);
      debugDefaultTargetPlatformOverride = null;
    });

    test('escuro do Windows é cinza, não preto', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final windows = buildAppTheme(
        appThemeOptions.first,
        appearance: AppAppearance.dark,
      );
      expect(windows.scaffoldBackgroundColor, const Color(0xFF202020));
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iphone = buildAppTheme(
        appThemeOptions.first,
        appearance: AppAppearance.dark,
      );
      expect(iphone.scaffoldBackgroundColor, const Color(0xFF000000));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('pede pra pintar a barra de título com a cor da barra', (
      tester,
    ) async {
      final pedidos = <Object?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('chordai/window'), (
            call,
          ) async {
            pedidos.add(call.arguments);
            return null;
          });
      await _abrir(
        tester,
        home: const WindowsTitleBarColor(child: Text('app')),
        appearance: AppAppearance.dark,
      );
      expect(pedidos, hasLength(1));
      final cor = (pedidos.single! as Map)['background'] as int;
      final theme = buildAppTheme(
        appThemeOptions.first,
        appearance: AppAppearance.dark,
      );
      expect(cor, windowsPaneColor(theme).toARGB32());
    }, variant: _windows);

    testWidgets('troca de tela do Windows é suave', (tester) async {
      await _abrir(tester);
      await tester.tap(_noInicio('Reconhecer acorde'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // No meio da troca a tela nova está aparecendo por cima.
      expect(find.byType(FadeTransition), findsWidgets);
      await settle(tester);
      expect(find.byType(FreePracticeScreen), findsOneWidget);
    }, variant: _windows);
  });

  group('cara do Mac', () {
    final mac = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets(
      'barra lateral do Finder: sem o ☰, com título pequeno e fundo transparente',
      (tester) async {
        await _abrir(tester);
        expect(find.byTooltip('Recolher o menu'), findsNothing);
        expect(find.text('ChordAI'), findsWidgets);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, Colors.transparent);
        expect(tester.getSize(_aba('Início')).height, 30);
      },
      variant: mac,
    );

    testWidgets('conteúdo começa abaixo dos botões da janela', (tester) async {
      await _abrir(tester);
      final titulo = tester.getTopLeft(find.text('ChordAI').last);
      expect(titulo.dy, greaterThanOrEqualTo(macTitleBarHeight));
      expect(
        tester.getTopLeft(_aba('Início')).dy,
        greaterThanOrEqualTo(macTitleBarHeight),
      );
    }, variant: mac);

    testWidgets('a janela do Mac segue o claro ou escuro do app', (
      tester,
    ) async {
      final pedidos = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('chordai/window'),
        (call) async {
          pedidos.add(call.arguments);
          return null;
        },
      );
      await _abrir(
        tester,
        appearance: AppAppearance.dark,
        home: const MacWindowAppearance(child: AppShell()),
      );
      expect(pedidos, [
        {'dark': true},
      ]);
    }, variant: mac);

    test('escuro do Mac é o cinza do macOS e os botões têm 32', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final escuro = buildAppTheme(
        appThemeOptions.first,
        appearance: AppAppearance.dark,
      );
      expect(escuro.scaffoldBackgroundColor, macDarkSurface);
      expect(
        escuro.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        32,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iphone = buildAppTheme(
        appThemeOptions.first,
        appearance: AppAppearance.dark,
      );
      expect(iphone.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(
        iphone.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        50,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final windows = buildAppTheme(
        appThemeOptions.first,
        appearance: AppAppearance.dark,
      );
      expect(windows.scaffoldBackgroundColor, const Color(0xFF202020));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('no Windows a barra continua com o ☰', (tester) async {
      await _abrir(tester);
      expect(find.byTooltip('Recolher o menu'), findsOneWidget);
    }, variant: _windows);
  });

  group('afinador, reconhecer e guia na barra lateral', () {
    for (final (nome, variante) in [
      ('Windows', TargetPlatformVariant.only(TargetPlatform.windows)),
      ('Mac', TargetPlatformVariant.only(TargetPlatform.macOS)),
    ]) {
      testWidgets('as três abas abrem as telas ($nome)', (tester) async {
        await _abrir(tester);
        for (final aba in [
          'Afinador',
          'Reconhecer acorde',
          'Guia do iniciante',
        ]) {
          expect(_aba(aba), findsOneWidget);
        }
        await tester.tap(_aba('Reconhecer acorde'));
        await settle(tester);
        expect(find.byType(FreePracticeScreen), findsOneWidget);
        await tester.tap(_aba('Guia do iniciante'));
        await settle(tester);
        expect(find.byType(GuideListScreen), findsOneWidget);
        expect(find.byType(FreePracticeScreen), findsNothing);
      }, variant: variante);
    }

    testWidgets('o afinador só fica montado enquanto a aba está escolhida', (
      tester,
    ) async {
      await _abrir(tester);
      expect(find.byType(TunerScreen, skipOffstage: false), findsNothing);
      await tester.tap(_aba('Afinador'));
      await settle(tester);
      expect(find.byType(TunerScreen), findsOneWidget);
      await tester.tap(_aba('Início'));
      await settle(tester);
      expect(find.byType(TunerScreen, skipOffstage: false), findsNothing);
    }, variant: _windows);

    testWidgets('no celular continuam as 4 abas de baixo', (tester) async {
      await _abrir(tester, size: const Size(390, 844));
      expect(_aba('Afinador'), findsNothing);
      expect(find.byKey(appTabBarKey), findsOneWidget);
    }, variant: TargetPlatformVariant.mobile());
  });

  group('ordem da barra, preferências e afinador sem rolar', () {
    testWidgets(
      'a barra segue a ordem combinada, com preferências e perfil no pé',
      (tester) async {
        await _abrir(tester);
        final ordem = [
          'Início',
          'Afinador',
          'Aprender acordes',
          'Reconhecer acorde',
          'Guia do iniciante',
          'Músicas',
        ];
        for (var i = 1; i < ordem.length; i++) {
          expect(
            tester.getTopLeft(_aba(ordem[i])).dy,
            greaterThan(tester.getTopLeft(_aba(ordem[i - 1])).dy),
            reason: '${ordem[i]} depois de ${ordem[i - 1]}',
          );
        }
        final entrada = tester
            .getTopLeft(find.byKey(const ValueKey('ação Entrada de áudio')))
            .dy;
        expect(
          entrada,
          greaterThan(tester.getTopLeft(_aba('Músicas')).dy + 100),
        );
        expect(
          tester.getTopLeft(_aba('Preferências')).dy,
          greaterThan(entrada),
        );
        expect(
          tester.getTopLeft(_aba('Perfil')).dy,
          greaterThan(tester.getTopLeft(_aba('Preferências')).dy),
        );
      },
      variant: _windows,
    );

    testWidgets('a engrenagem abre as preferências e o perfil fica sem elas', (
      tester,
    ) async {
      await _abrir(tester);
      await tester.tap(_aba('Preferências'));
      await settle(tester);
      expect(find.byType(PreferencesScreen), findsOneWidget);
      expect(find.text('Aparência'), findsOneWidget);
      await tester.tap(_aba('Perfil'));
      await settle(tester);
      expect(find.text('Seu nome'), findsOneWidget);
      expect(find.text('Aparência'), findsNothing);
    }, variant: _windows);

    testWidgets('no celular as preferências continuam no perfil', (
      tester,
    ) async {
      await _abrir(
        tester,
        size: const Size(390, 844),
        home: const ProfileScreen(),
      );
      await tester.scrollUntilVisible(
        find.text('Aparência'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Aparência'), findsOneWidget);
    }, variant: TargetPlatformVariant.mobile());

    for (final (nome, variante) in [
      ('Windows', TargetPlatformVariant.only(TargetPlatform.windows)),
      ('Mac', TargetPlatformVariant.only(TargetPlatform.macOS)),
    ]) {
      for (final janela in const [Size(1200, 800)]) {
        testWidgets(
          'afinador cabe sem rolar ($nome, ${janela.width.toInt()} x ${janela.height.toInt()})',
          (tester) async {
            await _abrir(tester, size: janela);
            await tester.tap(_aba('Afinador'));
            await settle(tester);
            expect(find.byType(TunerScreen), findsOneWidget);
            final rolagem = tester
                .stateList<ScrollableState>(
                  find.descendant(
                    of: find.byType(TunerScreen),
                    matching: find.byType(Scrollable),
                  ),
                )
                .first;
            expect(rolagem.position.maxScrollExtent, 0);
          },
          variant: variante,
        );
      }
    }
  });
}
