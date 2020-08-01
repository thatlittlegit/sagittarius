/* example-plugin.c
 *
 * By thatlittlegit for the Sagittarius project.
 * This file is licensed under the CC0 license, with NO WARRANTY OR LIABILITY.
 * You should've recieved a copy of the CC0 license with this software; if you
 * didn't, visit <https://creativecommons.org/publicdomain/zero/1.0>.
 */
#include "example-plugin.h"
#include <libpeas/peas.h>

/* Forward declarations */
static void example_plugin_class_init (ExamplePluginClass * klass);

static void example_plugin_init (ExamplePlugin * plugin);

static void example_plugin_dispose (GObject * plugin);

static void example_plugin_finalize (GObject * plugin);

static void example_plugin_uriloader_interface_init (
	SagittariusUriLoaderIface * iface);

static void example_plugin_fetch (SagittariusUriLoader * self,
	GHashTable * state, UpgUri * uri,
	GAsyncReadyCallback cb, void * data);

static void example_plugin_fetch_finish (SagittariusUriLoader * self,
	GAsyncResult * uri,
	SagittariusContent * outcome,
	GError * * error);

/* This is the GObject boilerplate. We don't do much here: this is a very
 * simple plugin.
 */
struct _ExamplePlugin {
	SagittariusPlugin parent_instance;
	int counter;
};
G_DEFINE_TYPE_WITH_CODE(ExamplePlugin, example_plugin, SAGITTARIUS_TYPE_PLUGIN,
	G_IMPLEMENT_INTERFACE(SAGITTARIUS_TYPE_URI_LOADER,
		example_plugin_uriloader_interface_init))

/* Here we set up the class. In a complicated plugin you might have properties,
 * etc. --- here we just carry-up dispose/finalize.
 * TODO is doing that even necessary?
 */
static void example_plugin_class_init (ExamplePluginClass * klass) {
	GObjectClass * objklass = G_OBJECT_CLASS(klass);
	objklass->dispose = example_plugin_dispose;
	objklass->finalize = example_plugin_finalize;
}

/* This function does the task performed by 'construct {}' in Vala, even though
 * it's implemented quite differently and *is* quite different. However, in Vala
 * we use it as a glorified constructor, meaning this is actually the better
 * function.
 *
 * We simply tell Sagittarius to load us for example: URIs.
 */
static void example_plugin_init (ExamplePlugin * plugin) {
	EXAMPLE_PLUGIN(plugin)->counter = 0;
	sagittarius_add_loader("example", SAGITTARIUS_URI_LOADER(plugin));
}

/* Boring carry-up functions. See example_plugin_class_init() */
static void example_plugin_dispose (GObject * plugin) {
	G_OBJECT_CLASS(example_plugin_parent_class)->dispose(plugin);
}

/* Boring carry-up functions. See example_plugin_class_init() */
static void example_plugin_finalize (GObject * plugin) {
	G_OBJECT_CLASS(example_plugin_parent_class)->finalize(plugin);
}

/* Here we set up the interface for UriLoader. This means that Sagittarius will
 * be able to ask us to load URIs. (All this is is filling in a struct.)
 */
static void example_plugin_uriloader_interface_init (
	SagittariusUriLoaderIface * iface) {
	iface->fetch = example_plugin_fetch;
	iface->fetch_finish = example_plugin_fetch_finish;
}

/* These are two of the most important parts: fetch and fetch_finish.
 *
 * This example isn't really a good demonstration of how to do async properly,
 * given that we do no async here; nay, this shows their signatures and the
 * vague way to implement them.
 *
 * Read the GIO docs to learn how to do it properly.
 */
static void example_plugin_fetch (SagittariusUriLoader * self,
	GHashTable * state, UpgUri * uri,
	GAsyncReadyCallback cb, void * data) {
	EXAMPLE_PLUGIN(self)->counter++;
	g_object_ref(uri);
	cb(G_OBJECT(self), (GAsyncResult *) uri, data);
}

/* Implements fetch_finish, and wins the 'Worst GIO finish Function Ever' award.
 * My talents are finally being recognized! :'D
 */
static void example_plugin_fetch_finish (SagittariusUriLoader * self,
	GAsyncResult * uri,
	SagittariusContent * outcome,
	GError * * error) {
	char * payload = g_strdup_printf("# Counter! :D\n%d", EXAMPLE_PLUGIN(
		self)->counter);
	SagittariusContent content;
	content.data = g_bytes_new_take(payload, strlen(payload));
	content.original_uri = (UpgUri *) uri;
	content.content_type = g_mime_content_type_new("text", "gemini");
	content.outcome = SAGITTARIUS_URI_LOAD_OUTCOME_SUCCESS;
	*outcome = content;
	g_object_unref(uri);
}

/* This is the stranger function, and frankly the reason I went through all of
 * this torture.
 *
 * This function tells Peas to use our plugin. YOU NEED TO HAVE THIS, otherwise
 * Peas will load this file and maybe complain.
 */
void peas_register_types (PeasObjectModule * module) {
	peas_object_module_register_extension_type(module, SAGITTARIUS_TYPE_PLUGIN,
		EXAMPLE_TYPE_PLUGIN);
}

/* Yay, you're done! :D EOF */
