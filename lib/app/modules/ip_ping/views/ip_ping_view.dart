import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../translations/app_translations.dart';
import '../controllers/ip_ping_controller.dart';

class IpPingView extends GetView<IpPingController> {
  const IpPingView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('IP ${LocaleKeys.connectTest.tr}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GetX<IpPingController>(
            init: IpPingController(),
            initState: (state) async {
              await state.controller!.getAllIP();
            },
            builder: (ctl) {
              return ctl.loadding.value
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      separatorBuilder: (context, index) => const Divider(
                        indent: 15,
                        endIndent: 15,
                      ),
                      itemCount: ctl.allIp.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () async {
                            await ctl.testConnection(ctl.allIp[index].mLanIp);
                          },
                          leading: const Icon(Icons.print),
                          title: Text(ctl.allIp[index].mName),
                          subtitle: Text(ctl.allIp[index].mLanIp),
                          trailing: TextButton(
                            onPressed: () async {
                              await ctl.testConnection(ctl.allIp[index].mLanIp);
                            },
                            child: Text(LocaleKeys.testConnect.tr),
                          ),
                        );
                      },
                    );
            },
          ),
        ),
      ),
    );
  }
}
