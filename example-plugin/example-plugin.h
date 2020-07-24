/* example-plugin.h
 *
 * By thatlittlegit for the Sagittarius project.
 * This file is licensed under the CC0 license, with NO WARRANTY OR LIABILITY.
 * You should've recieved a copy of the CC0 license with this software; if you
 * didn't, visit <https://creativecommons.org/publicdomain/zero/1.0>.
 */

#ifndef EXAMPLE_PLUGIN_H
#define EXAMPLE_PLUGIN_H

#include <glib-object.h>
#include <sagittarius.h>

G_BEGIN_DECLS

#define EXAMPLE_TYPE_PLUGIN example_plugin_get_type()
G_DECLARE_FINAL_TYPE(ExamplePlugin, example_plugin, EXAMPLE, PLUGIN, SagittariusPlugin);

G_END_DECLS

#endif
