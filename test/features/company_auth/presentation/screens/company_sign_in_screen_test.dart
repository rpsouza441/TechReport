import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techreport/app/theme/metric_slate_theme.dart';
import 'package:techreport/features/company_auth/presentation/screens/company_sign_in_screen.dart';
import 'package:techreport/features/company_auth/presentation/view_models/company_sign_in_view_model.dart';
import 'package:techreport/features/company_auth/domain/usecases/sign_in_company.dart';
import 'package:techreport/features/company_auth/domain/repositories/auth_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/remote_session_repository.dart';
import 'package:techreport/features/company_auth/domain/repositories/app_mode_repository.dart';

void main() {
  testWidgets('CompanySignInScreen exibe card piloto e campos', (tester) async {
    final viewModel = CompanySignInViewModel(
      signInCompany: SignInCompany(
        authRepository: _ThrowingAuthRepository(),
        remoteSessionRepository: _NoopRemoteSessionRepository(),
        appModeRepository: _NoopAppModeRepository(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MetricSlateTheme.light(),
        home: CompanySignInScreen(
          viewModel: viewModel,
          onSignedIn: (_) {},
          onCancel: () {},
        ),
      ),
    );

    expect(find.text('TechReport'), findsOneWidget);
    expect(find.text('Acesso corporativo'), findsOneWidget);
    expect(find.text('E-mail corporativo'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sair do modo empresa'), findsOneWidget);
  });

  testWidgets('CompanySignInScreen mostra erro em card', (tester) async {
    final viewModel = CompanySignInViewModel(
      signInCompany: SignInCompany(
        authRepository: _ThrowingAuthRepository(),
        remoteSessionRepository: _NoopRemoteSessionRepository(),
        appModeRepository: _NoopAppModeRepository(),
      ),
    );
    viewModel.errorMessage = 'Credenciais inválidas';
    viewModel.notifyListeners();

    await tester.pumpWidget(
      MaterialApp(
        theme: MetricSlateTheme.light(),
        home: CompanySignInScreen(viewModel: viewModel, onSignedIn: (_) {}),
      ),
    );
    await tester.pump();

    expect(find.text('Credenciais inválidas'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}

// Stubs mínimos — não usados nos testes de UI acima.

class _ThrowingAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopRemoteSessionRepository implements RemoteSessionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopAppModeRepository implements AppModeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
