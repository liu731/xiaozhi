import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xiaozhi/bloc/chat/chat_bloc.dart';
import 'package:xiaozhi/bloc/ota/ota_bloc.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/l10n/generated/app_localizations.dart';
import 'package:xiaozhi/widget/hold_to_talk_widget.dart';

import 'call_page.dart';
import 'setting_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late RefreshController _refreshController;

  final GlobalKey<HoldToTalkWidgetState> holdToTalkKey =
      GlobalKey<HoldToTalkWidgetState>();

  bool _isPressing = false;

  late ChatBloc chatBloc;

  @override
  void initState() {
    _refreshController = RefreshController();
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  clearUp() async {
    chatBloc.add(ChatStopListenEvent());
    holdToTalkKey.currentState!.setSpeaking(false);
    if (_isPressing && mounted) {
      setState(() {
        _isPressing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    OtaBloc otaBloc = BlocProvider.of<OtaBloc>(context);

    chatBloc = BlocProvider.of<ChatBloc>(context);

    return BlocListener(
      bloc: otaBloc,
      listener: (context, OtaState otaState) {
        if (otaState is OtaNotActivatedState) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.deviceActivation),
                content: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.pin_rounded,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      size: 60,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.deviceActivationDescription,
                        ),
                        SizedBox(height: XConst.spacer),
                        Text(
                          otaState.code,
                          style: TextStyle(
                            fontSize: XConst.spacer * 4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (null != otaState.url)
                          Text(
                            otaState.url!,
                            //text underline
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                      ],
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
                          try {
                            await Clipboard.setData(
                              ClipboardData(text: otaState.code),
                            );
                            if (null != otaState.url) {
                              await launchUrl(Uri.parse(otaState.url!));
                            }
                          } catch (_) {}
                        },
                        child: Text(AppLocalizations.of(context)!.ok),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        }
      },
      child: BlocConsumer(
        bloc: chatBloc,
        listener: (context, ChatState chatState) {
          if (chatState is ChatNoMicrophonePermissionState) {
            clearUp();

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

          if (chatState is ChatInitialState) {
            if (chatState.hasMore) {
              _refreshController.loadComplete();
            } else {
              _refreshController.loadNoData();
            }

            if (chatState.messageList.isNotEmpty &&
                chatState.messageList.first.sendByMe) {
              clearUp();
            }
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
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (context) => CallPage()));
                  },
                  icon: Icon(Icons.call_rounded),
                ),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SmartRefresher(
                        enablePullDown: false,
                        enablePullUp: true,
                        controller: _refreshController,
                        footer: CustomFooter(
                          builder: (BuildContext context, LoadStatus? mode) {
                            String text;
                            switch (mode) {
                              case LoadStatus.loading:
                                text = AppLocalizations.of(context)!.loading;
                                break;
                              default:
                                text = AppLocalizations.of(context)!.noMoreData;
                            }
                            return Center(
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                        onLoading: () {
                          chatBloc.add(ChatLoadMoreEvent());
                        },
                        child: ListView(
                          reverse: true,
                          padding: EdgeInsets.all(XConst.spacer),
                          children:
                              chatState.messageList
                                  .map(
                                    (e) => Row(
                                      mainAxisAlignment:
                                          e.sendByMe
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                mediaQuery.size.width * 0.75,
                                          ),
                                          margin: EdgeInsets.only(
                                            top: XConst.spacer,
                                          ),
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
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .tertiaryContainer,
                                          ),
                                          child: Text(
                                            e.text,
                                            style: TextStyle(
                                              color:
                                                  e.sendByMe
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onTertiaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(XConst.spacer).copyWith(
                        bottom: 12 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: GestureDetector(
                        onTapDown: (_) {
                          holdToTalkKey.currentState!.setCancelTapUp(false);
                          if (!_isPressing) {
                            setState(() {
                              _isPressing = true;
                            });
                          }
                        },
                        onTapUp: (_) {
                          holdToTalkKey.currentState!.setCancelTapUp(false);
                          clearUp();
                        },
                        onTapCancel: () {
                          holdToTalkKey.currentState!.setCancelTapUp(false);
                          clearUp();
                        },
                        onLongPressStart: (_) async {
                          holdToTalkKey.currentState!.setSpeaking(true);
                          if (!_isPressing) {
                            setState(() {
                              _isPressing = true;
                            });
                          }
                          chatBloc.add(ChatStartListenEvent());
                        },
                        onLongPressEnd: (detail) async {
                          clearUp();
                        },
                        onLongPressCancel: () {
                          holdToTalkKey.currentState!.setCancelTapUp(false);
                          clearUp();
                        },
                        onLongPressMoveUpdate: (detail) {
                          if ((mediaQuery.size.height -
                                  detail.globalPosition.dy) <
                              (XConst.holdToTalkResponseAreaHeight +
                                  mediaQuery.padding.bottom)) {
                            holdToTalkKey.currentState!.setCancelTapUp(false);
                          } else {
                            holdToTalkKey.currentState!.setCancelTapUp(true);
                          }
                          if (mounted) setState(() {});
                        },
                        child: FilledButton(
                          onPressed: () {},
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
                    ),
                  ],
                ),
                HoldToTalkWidget(key: holdToTalkKey),
              ],
            ),
          );
        },
      ),
    );
  }
}
