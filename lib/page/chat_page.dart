import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xiaozhi/bloc/chat/chat_bloc.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/l10n/generated/app_localizations.dart';

import 'setting_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final ChatBloc chatBloc = BlocProvider.of<ChatBloc>(context);

    return BlocConsumer(
      bloc: chatBloc,
      listener: (context, ChatState chatState) {
        if (chatState is ChatNoMicrophonePermissionState) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.requestPermission),
                content: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      size: 60,
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.requestPermissionDescription,
                    ),
                  ],
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.reject),
                      ),
                      FilledButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          chatBloc.add(
                            ChatStartListenEvent(
                              isRequestMicrophonePermission: true,
                            ),
                          );
                        },
                        child: Text(AppLocalizations.of(context)!.agree),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        }
      },
      builder: (context, ChatState chatState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.xiaozhi),
            leading: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => SettingPage()),
                    );
                  },
                  icon: Icon(Icons.menu_rounded),
                ),
              ],
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(XConst.spacer),
                  children:
                      chatState.messageList.reversed
                          .map(
                            (e) => Row(
                              mainAxisAlignment:
                                  e.sendByMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: mediaQuery.size.width * 0.75,
                                  ),
                                  margin: EdgeInsets.only(top: XConst.spacer),
                                  padding: EdgeInsets.symmetric(
                                    vertical: XConst.spacer * 0.8,
                                    horizontal: XConst.spacer,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      XConst.spacer * 1.5,
                                    ),
                                    color:
                                        e.sendByMe
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer
                                            : Theme.of(
                                              context,
                                            ).colorScheme.tertiaryContainer,
                                  ),
                                  child: Text(
                                    e.text,
                                    style: TextStyle(
                                      color:
                                          e.sendByMe
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer
                                              : Theme.of(
                                                context,
                                              ).colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(
                  XConst.spacer,
                ).copyWith(bottom: 12 + MediaQuery.of(context).padding.bottom),
                child: FilledButton(
                  onPressed: () {
                    chatBloc.add(ChatStartListenEvent());
                  },
                  onLongPress: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_rounded),
                      SizedBox(width: XConst.spacer),
                      Text(AppLocalizations.of(context)!.holdToTalk),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
