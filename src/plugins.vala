/* plugins.vala
 *
 * Copyright 2020 thatlittlegit <personal@thatlittlegit.tk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Peas;
using PeasGtk;

namespace Sagittarius {
	public abstract class Plugin : Object {
		public Application application { protected owned get; construct; }

		public virtual void activate () {
		}

		public virtual void deactivate () {
		}
	}

	[CCode(cname = "SAGITTARIUS_TYPE_PLUGIN")]
	public extern Type PluginType;

	internal void configure_plugin_engine (GLib.Application app) {
		var application = (Application) app;
		application.extensions = new ExtensionSet(
			Engine.get_default (),
			PluginType,
			"application", application, null
			);
		application.extensions.extension_added.connect((info,
														activatable) => ((Plugin)
																		 activatable).activate ());
		application.extensions.extension_removed.connect((info,
														  activatable) => ((
																			   Plugin)
																		   activatable).deactivate ());

		Engine.get_default ().add_search_path(PLUGINDIR, null);
		Engine.get_default ().add_search_path(
			Path.build_path("/", Environment.get_user_data_dir (),
				"sagittarius", "plugins"),
			null);

		if (DEBUG == "true") {
			message("DEBUG is enabled (%s)", BUILT_PLUGINDIR);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "about"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "gemini"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "invincible"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "text"), null);
		}

		Engine.get_default ().rescan_plugins ();

		foreach (var plugin in Engine.get_default ().get_plugin_list ()) {
			if (plugin.get_external_data("Default") != null) {
				Engine.get_default ().load_plugin(plugin);
			}
		}
	}

	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/plugins.ui")]
	internal class PluginsWindow : Gtk.Window {
		[GtkChild]
		Gtk.HeaderBar headerbar;
		[GtkChild]
		Gtk.Stack content_stack;
		[GtkChild]
		Gtk.Button properties_button;
		[GtkChild]
		Gtk.Button about_button;
		[GtkChild]
		Gtk.Revealer back_button_revealer;

		PluginManagerView manager;

		internal PluginsWindow () {
		}

		construct {
			var installed = Engine.get_default ().get_plugin_list ().length ();
			headerbar.subtitle = ngettext("One plugin installed",
				"%u plugins installed",
				installed).printf(installed);

			manager = new PluginManagerView(Engine.get_default ());
			manager.get_selection ().changed.connect(
				() => { update_buttons (); });
			manager.get_selection ().mode = Gtk.SelectionMode.SINGLE;
			manager.button_press_event.connect(() => manager.unselect_all ());
			content_stack.add_named(manager, "manager");
			content_stack.show_all ();
		}

		private void update_buttons () {
			var selected = manager.get_selected_plugin ();

			if (selected == null) {
				properties_button.sensitive = false;
				about_button.sensitive = false;
				return;
			}

			about_button.sensitive = true;

			if (!selected.is_loaded ()) {
				properties_button.sensitive = false;
				return;
			}

			var extension = Engine.get_default ().create_extension(selected,
				PEAS_GTK_TYPE_CONFIGURABLE);

			if (extension == null) {
				properties_button.sensitive = false;
			} else {
				properties_button.sensitive = true;
			}
		}

		[GtkCallback]
		private void back_cb () {
			content_stack.visible_child_name = "manager";
			back_button_revealer.reveal_child = false;
			content_stack.remove(content_stack.get_child_by_name("properties"));
		}

		[GtkCallback]
		private void open_properties_cb () {
			content_stack.add_named(((PeasGtk.Configurable)Engine.get_default ()
									  .create_extension(manager.
										  get_selected_plugin (),
										 PEAS_GTK_TYPE_CONFIGURABLE))
				 .create_configure_widget (), "properties");
			content_stack.visible_child_name = "properties";
			back_button_revealer.reveal_child = true;
		}

		[GtkCallback]
		private void open_about_cb () {
			var dialog = new Gtk.AboutDialog ();
			var plugin = manager.get_selected_plugin ();

			dialog.program_name = plugin.get_name ();
			dialog.logo_icon_name = plugin.get_icon_name () ?? "extension";
			dialog.comments = plugin.get_description ();
			dialog.authors = plugin.get_authors ();
			dialog.copyright = plugin.get_copyright ();
			dialog.version = plugin.get_version ();

			dialog.license_type =
				decode_license(plugin.get_external_data("License"));
			if (dialog.license_type == Gtk.License.CUSTOM) {
				dialog.license = plugin.get_external_data("License-Data") ??
								 "This plugin is proprietary.";
			}

			dialog.run ();
			dialog.destroy ();
		}
	}

	public Gtk.License decode_license (string ? spdx) {
		if (spdx == "CUSTOM" || spdx == "PROPRIETARY") {
			return Gtk.License.CUSTOM;
		} else if (spdx == "GPL-2.0-or-later") {
			return Gtk.License.GPL_2_0;
		} else if (spdx == "GPL-2.0-only") {
			return Gtk.License.GPL_2_0_ONLY;
		} else if (spdx == "GPL-3.0-or-later") {
			return Gtk.License.GPL_3_0;
		} else if (spdx == "GPL-3.0-only") {
			return Gtk.License.GPL_3_0_ONLY;
		} else if (spdx == "LGPL-2.1-or-later") {
			return Gtk.License.LGPL_2_1;
		} else if (spdx == "LGPL-2.1-only") {
			return Gtk.License.LGPL_2_1_ONLY;
		} else if (spdx == "AGPL-3.0-or-later") {
			return Gtk.License.AGPL_3_0;
		} else if (spdx == "AGPL-3.0-only") {
			return Gtk.License.AGPL_3_0_ONLY;
		} else if (spdx == "X11" || spdx == "MIT") {
			return Gtk.License.MIT_X11;
		} else if (spdx == "BSD-2-Clause") {
			return Gtk.License.BSD;
		} else if (spdx == "Artistic-2.0") {
			return Gtk.License.ARTISTIC;
		} else if (spdx == "BSD-3-Clause") {
			//return Gtk.License.BSD_3;
		} else if (spdx == "Apache-2.0") {
			//	return Gtk.License.APACHE_2_0;
		} else if (spdx == "MPL-2.0") {
			//		return Gtk.License.MPL_2_0;
		}

		return Gtk.License.UNKNOWN;
	}
}
