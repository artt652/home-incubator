import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_fe/blocs/crud_api.dart';
import 'package:flutter_fe/blocs/crud_user.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../misc/configuration.dart';
import '../misc/utils.dart';
import 'bloc_provider.dart';
import 'login_helper.dart' if (dart.library.js) 'login_helper_js.dart' as login_helper;

part 'session.g.dart';

class Session {
  static final Logger log = Logger('Session');

  final Configuration _configuration;
  final CrudApi _backend;

  CrudEntityUser _user = emptyUser;
  CrudEntityUser get user => _user;

  Session(Injector injector):
        _configuration = injector.get<Configuration>(),
        _backend = injector.get<CrudApi>();

  /// In order to provide better user experience and reduce latency we process all urls on client side.
  /// For web-based client we use {@link web/login-callback.html} as redirect URL
  /// For native client we use site url + deep linking + site/.well-known in order to confirm ownership and get call back in router (still TBD;)
  Future<CrudEntityUser?> login(LoginProvider provider, {SessionBloc? sessionBloc}) async {
    return _login(provider, false, sessionBloc: sessionBloc);
  }

  Future<CrudEntityUser?> link(LoginProvider provider, {SessionBloc? sessionBloc}) {
    return _login(provider, true, sessionBloc: sessionBloc);
  }

  Future<CrudEntityUser?> _login(LoginProvider provider, bool link, {SessionBloc? sessionBloc}) {
    final completer = Completer<CrudEntityUser?>();
    final redirectUrl = _configuration.loginRedirectUrl();
    final clientId = _configuration.loginProviderClientId(provider.name);
    // client_id=<client_id>&redirect_uri=<redirect_uri>&state=<state>&response_type=code&scope=<scope>&nonce=<nonce>
    final url = provider.url
        + (provider.url.contains('?') ? '&' : '?')
        + 'client_id=' + clientId
        + '&state=state_client_flutter'
            '&response_type=code'
            '&scope=' + provider.scopes.join('+')
        + '&nonce=' + getRandomString(10)
        + '&redirect_uri=' + Uri.encodeComponent(redirectUrl);
    log.info('Launch login ${provider.name} $url');
    login_helper.showLoginWindow(url, (loginParams) =>
        onLoginCallback(loginParams, provider, link, sessionBloc: sessionBloc)
            .then((value) => completer.complete(value))
    );
    return completer.future;
  }

  Future<CrudEntityUser?> onLoginCallback(String loginParams, LoginProvider provider, bool link, {SessionBloc? sessionBloc}) async {
    if (loginParams.contains('error')) {
      sessionBloc?.state = LoginStateInfo(LoginState.error, loginParams);
      return null;
    }
    sessionBloc?.state = LoginStateInfo(LoginState.inProgress);
    try {
      var login = EntityLogin.fromJson(jsonDecode(await _backend.requestJson('GET', '${_configuration.backendUrl()}/api/login/${link ? 'linkCallback' : 'loginCallback'}/${provider.name}$loginParams', params: {'client': _configuration.clientId()}, auth: link)));
      if (!link) {
        _configuration.sessionId = login.sessionId;
      }
      final user = await loadUser();
      sessionBloc?.state = LoginStateInfo(LoginState.done);
      return user;
    } catch (e) {
      sessionBloc?.state = LoginStateInfo(LoginState.error, 'Error $e');
    }
  }

  Future<void> logout() async {
    await _backend.request('GET', '/api/user');
    _configuration.sessionId = '';
  }

  bool isLoggedIn() {
    return _configuration.sessionId.isNotEmpty;
  }

  Future<CrudEntityUser> loadUser() async {
    var json = await _backend.requestJson('GET', '/api/user');
    _user = CrudEntityUser.fromJson(json);
    return _user;
  }

}

const loginProviders = <LoginProvider>[
  LoginProvider("facebook", "https://www.facebook.com/dialog/oauth", ["openid", "email", "public_profile", "user_gender", "user_link", "user_birthday", "user_location"], Icon(MdiIcons.facebook), true),
  LoginProvider("google", "https://accounts.google.com/o/oauth2/v2/auth", ["openid", "email", "profile"], Icon(MdiIcons.google), true),
  // ?force_confirm=yes
  LoginProvider("yandex", "https://oauth.yandex.ru/authorize", ["login:birthday", "login:email", "login:info", "login:avatar"], Icon(MdiIcons.alphaYCircle), true),
];

class SessionBloc extends BlocBaseState<LoginStateInfo> {
  StreamSubscription? _loginStateSubscription;

  SessionBloc([LoginState initialState = LoginState.none]): super(LoginStateInfo(initialState));

  listenLoginState(Function(LoginStateInfo loginStateInfo) onData) {
    cancelSubscription();
    _loginStateSubscription = stateOut.listen(onData);
  }

  Future<CrudEntityUser?> login(LoginProvider provider) {
    return session.login(provider, sessionBloc: this);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void cancelSubscription() {
    _loginStateSubscription?.cancel();
    _loginStateSubscription = null;
  }

  void reset() {
    state = LoginStateInfo(LoginState.none);
  }
}

class LoginProvider {
  final String name;
  final String url;
  final List<String> scopes;
  final Icon icon;
  final bool warning;

  const LoginProvider(this.name, this.url, this.scopes, this.icon, this.warning);
}

class LoginStateInfo {

  LoginState state;
  String? description;

  LoginStateInfo(this.state, [this.description]);
}

enum LoginState {
  none, inProgress, error, done
}

@JsonSerializable()
class EntityLogin {
  String sessionId;
  EntityLoginUserType userType;

  EntityLogin({required this.sessionId, required this.userType});
  factory EntityLogin.fromJson(Map<String, dynamic> json) => _$EntityLoginFromJson(json);
  Map<String, dynamic> toJson() => _$EntityLoginToJson(this);
}

enum EntityLoginUserType {
 newUser, existing
}

