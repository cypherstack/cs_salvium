#include "include/cs_salvium_flutter_libs_linux/cs_salvium_flutter_libs_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "cs_salvium_flutter_libs_linux_plugin_private.h"

#define cs_salvium_flutter_libs_linux_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), cs_salvium_flutter_libs_linux_plugin_get_type(), \
                              CsSalviumFlutterLibsLinuxPlugin))

struct _CsSalviumFlutterLibsLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(CsSalviumFlutterLibsLinuxPlugin, cs_salvium_flutter_libs_linux_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void cs_salvium_flutter_libs_linux_plugin_handle_method_call(
    CsSalviumFlutterLibsLinuxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void cs_salvium_flutter_libs_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(cs_salvium_flutter_libs_linux_plugin_parent_class)->dispose(object);
}

static void cs_salvium_flutter_libs_linux_plugin_class_init(CsSalviumFlutterLibsLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = cs_salvium_flutter_libs_linux_plugin_dispose;
}

static void cs_salvium_flutter_libs_linux_plugin_init(CsSalviumFlutterLibsLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  CsSalviumFlutterLibsLinuxPlugin* plugin = cs_salvium_flutter_libs_linux_PLUGIN(user_data);
  cs_salvium_flutter_libs_linux_plugin_handle_method_call(plugin, method_call);
}

void cs_salvium_flutter_libs_linux_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  CsSalviumFlutterLibsLinuxPlugin* plugin = cs_salvium_flutter_libs_linux_PLUGIN(
      g_object_new(cs_salvium_flutter_libs_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "cs_salvium_flutter_libs_linux",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
