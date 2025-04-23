import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xiaozhi/bloc/chat/chat_bloc.dart';
import 'package:xiaozhi/common/x_const.dart';
import 'package:xiaozhi/l10n/generated/app_localizations.dart';
import 'package:xiaozhi/util/shared_preferences_util.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late TextEditingController _otaUrlController;
  late TextEditingController _websocketUrlController;
  late TextEditingController _macAddressController;

  @override
  void initState() {
    _otaUrlController = TextEditingController();
    _websocketUrlController = TextEditingController();
    _macAddressController = TextEditingController();
    SharedPreferencesUtil().getOtaUrl().then((v) {
      if (null != v) {
        _otaUrlController.text = v;
      }
    });
    SharedPreferencesUtil().getWebsocketUrl().then((v) {
      if (null != v) {
        _websocketUrlController.text = v;
      }
    });
    SharedPreferencesUtil().getMacAddress().then((v) {
      if (null != v) {
        _macAddressController.text = v;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.setting),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await SharedPreferencesUtil().setOtaUrl(_otaUrlController.text);
                await SharedPreferencesUtil().setWebsocketUrl(
                  _websocketUrlController.text,
                );
                await SharedPreferencesUtil().setMacAddress(
                  _macAddressController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.saveSuccess),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                BlocProvider.of<ChatBloc>(context).add(ChatInitialEvent());
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.saveFailed),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: Icon(
              Icons.save_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(XConst.spacer),
        children: [
          TextField(
            controller: _otaUrlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.otaUrl,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cloud_download_rounded),
            ),
          ),
          SizedBox(height: XConst.spacer * 2),
          TextField(
            controller: _websocketUrlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.websocketUrl,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.connect_without_contact_rounded),
            ),
          ),
          SizedBox(height: XConst.spacer * 2),
          TextField(
            controller: _macAddressController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.macAddress,
              helperText: AppLocalizations.of(context)!.macAddressEditTips,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pin_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
