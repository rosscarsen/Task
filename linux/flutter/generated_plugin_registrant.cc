//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_inappwebview_linux/flutter_inappwebview_linux_plugin.h>
#include <tray_manager/tray_manager_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_inappwebview_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterInappwebviewLinuxPlugin");
  flutter_inappwebview_linux_plugin_register_with_registrar(flutter_inappwebview_linux_registrar);
  g_autoptr(FlPluginRegistrar) tray_manager_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "TrayManagerPlugin");
  tray_manager_plugin_register_with_registrar(tray_manager_registrar);
}
