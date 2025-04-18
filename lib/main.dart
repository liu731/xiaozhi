import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xiaozhi/bloc/chat/chat_bloc.dart';
import 'package:xiaozhi/bloc/ota/ota_bloc.dart';
import 'package:xiaozhi/l10n/generated/app_localizations.dart';
import 'package:xiaozhi/page/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ChatBloc()..add(ChatInitialEvent())),
        BlocProvider(create: (context) => OtaBloc()..add(OtaInitialEvent()))
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF002FA7)),
        ),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('zh')],
        home: const ChatPage(),
      ),
    ),
  );
}
