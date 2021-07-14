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

	private HashTable<string, Plugin> active_plugins;

	internal void configure_plugin_engine (GLib.Application app) {
		active_plugins = new HashTable<string, Plugin>(str_hash, str_equal);
		var application = (Application) app;
		application.extensions = new ExtensionSet(
			Engine.get_default (),
			typeof (Plugin),
			"application", application, null
			);

		bool starting_up = true;
		application.extensions.extension_added.connect((info,
														activatable) => {

			var settings =
				new Settings.with_path("tk.thatlittlegit.sagittarius.plugin",
					"/tk/thatlittlegit/sagittarius/%s/".printf(info.
						 get_module_name ()));

			if (activatable is Renderer) {
				foreach (var item in (info.get_external_data(
					"InternalContentTypes") ?? "").split(",")) {
					add_renderer(item.strip (), (Renderer) activatable);
				}

				if (settings.get_value(
					"content-types").get_strv ().length == 0) {
					var newval = new Array<string>();

					foreach (var item in ((info.get_external_data("ContentTypes")
										   ?? "").split(","))) {
						newval.append_val(item.strip ());
					}

					if (newval.length > 0) {
						settings.set_value("content-types", newval.data);
					}
				}

				var types = settings.get_value("content-types").dup_strv ();
				foreach (var item in types) {
					add_renderer(item, (Renderer) activatable);
				}
			}

			if (activatable is UriLoader) {
				foreach (var item in (info.get_external_data(
					"InternalUriSchemes") ?? "").split(",")) {
					add_loader(item.strip (), (UriLoader) activatable);
				}

				if (settings.get_value(
					"uri-schemes").get_strv ().length == 0) {
					var newval = new Array<string>();

					foreach (var item in ((info.get_external_data("UriSchemes")
										   ?? "").split(","))) {
						newval.append_val(item.strip ());
					}

					if (newval.length > 0) {
						settings.set_value("uri-schemes", newval.data);
					}
				}

				var schemes = settings.get_value("uri-schemes").dup_strv ();
				foreach (var item in schemes) {
					add_loader(item, (UriLoader) activatable);
				}
			}

			((Plugin) activatable).activate ();
			active_plugins.insert(
				info.get_module_name (), (Plugin) activatable);

			if (!starting_up) {
				application.settings.set_strv(
					"enabled-plugins",
					array_plus(application.settings.get_value("enabled-plugins")
						 .dup_strv (), info.get_module_name ())
					);
			}
		});
		application.extensions.extension_removed.connect((info,
														  activatable) => {
			remove_all_renderers_of_type(activatable.get_type ());
			((Plugin) activatable).deactivate ();
			active_plugins.remove(info.get_module_name ());

			// this is more for consistency, we don't disable plugins at startup
			if (!starting_up) {
				application.settings.set_strv(
					"enabled-plugins",
					array_sans(application.settings.get_value("enabled-plugins")
						 .dup_strv (), info.get_module_name ())
					);
			}
		});

		if (DEBUG == "true") {
			message("DEBUG is enabled (%s)", BUILT_PLUGINDIR);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "about"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "file"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "gemini"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "invincible"), null);
			Engine.get_default ().add_search_path(Path.build_path("/",
				BUILT_PLUGINDIR, "text"), null);
		}

		Engine.get_default ().add_search_path(PLUGINDIR, null);
		Engine.get_default ().add_search_path(
			Path.build_path("/", Environment.get_user_data_dir (),
				"sagittarius", "plugins"),
			null);

		Engine.get_default ().rescan_plugins ();

		var enabled =
			application.settings.get_value("enabled-plugins").dup_strv ();
		foreach (var plugin in Engine.get_default ().get_plugin_list ()) {
			foreach (var enable in enabled) {
				if (enable == plugin.get_module_name ()) {
					Engine.get_default ().load_plugin(plugin);
					break;
				}
			}
		}

		starting_up = false;
	}

	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/plugins.ui")]
	internal class PluginsWindow : Gtk.Window {
		[GtkChild]
		private unowned Gtk.HeaderBar headerbar;
		[GtkChild]
		private unowned Gtk.Stack content_stack;
		[GtkChild]
		private unowned Gtk.Box menu_box;
		[GtkChild]
		private unowned Gtk.Button properties_button;
		[GtkChild]
		private unowned Gtk.Button about_button;
		[GtkChild]
		private unowned Gtk.Button mime_button;
		[GtkChild]
		private unowned Gtk.Revealer back_button_revealer;
		[GtkChild]
		private unowned Gtk.Revealer forward_button_revealer;

		PluginManagerView manager;

		internal PluginsWindow () {
		}

		construct {
			manager = new PluginManagerView(Engine.get_default ());
			manager.get_selection ().changed.connect(
				() => { update_buttons (); });
			manager.get_selection ().mode = Gtk.SelectionMode.SINGLE;
			manager.button_press_event.connect(() => manager.unselect_all ());
			menu_box.pack_start(manager, true, true);
			content_stack.show_all ();
			content_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
		}

		private void update_title (string ? title = null,
			string ? subtitle = null) {
			if (title == null) {
				headerbar.title = _("Plugins");
				var installed =
					Engine.get_default ().get_plugin_list ().length ();
				headerbar.subtitle = ngettext("One plugin installed",
					"%u plugins installed",
					installed).printf(installed);
				return;
			}

			headerbar.title = title;
			headerbar.subtitle = subtitle;
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
				mime_button.sensitive = false;
				return;
			}

			if (Engine.get_default ().provides_extension(selected,
				typeof (PeasGtk.Configurable))) {
				properties_button.sensitive = false;
			} else {
				properties_button.sensitive = true;
			}

			mime_button.sensitive = true;
		}

		[GtkCallback]
		private void back_cb () {
			content_stack.visible_child_name = "manager";
			back_button_revealer.reveal_child = false;
			content_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
			update_title(null);

			// Removing it immediately looks glitchy
			Timeout.add(300, () => {
				content_stack.remove(content_stack.get_child_by_name(
					"properties"));
				return false;
			});
		}

		[GtkCallback]
		private void forward_cb () {
			content_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
			content_stack.visible_child_name = "manager";
			forward_button_revealer.reveal_child = false;
			update_title(null);

			Timeout.add(300, () => {
				content_stack.remove(content_stack.get_child_by_name("mime"));
				return false;
			});
		}

		[GtkCallback]
		private void open_properties_cb () {
			var selected = manager.get_selected_plugin ();

			content_stack.add_named(((PeasGtk.Configurable)Engine.get_default ()
									  .create_extension(manager.
										  get_selected_plugin (),
										 typeof (PeasGtk.Configurable)))
				 .create_configure_widget (), "properties");

			update_title(selected.get_name (), _("Configuration"));
			content_stack.visible_child_name = "properties";
			back_button_revealer.reveal_child = true;
			content_stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
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

		[GtkCallback]
		private void open_mime_cb () {
			var plugin = manager.get_selected_plugin ();
			var settings =
				new Settings.with_path("tk.thatlittlegit.sagittarius.plugin",
					"/tk/thatlittlegit/sagittarius/%s/".printf(plugin.
						 get_module_name ()));
			content_stack.add_named(new PluginConfiguration(plugin,
				settings), "mime");

			content_stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
			content_stack.visible_child_name = "mime";
			forward_button_revealer.reveal_child = true;
			update_title(plugin.get_name (), _("Configuration"));
		}
	}

	[GtkTemplate(ui =
			"/tk/thatlittlegit/sagittarius/plugin-configuration.ui")]
	private class PluginConfiguration : Gtk.Bin {
		private Array<string> schemes;
		private Array<string> types;
		public PluginInfo info { get; construct; }
		public Settings settings { get; construct; }
		private bool settings_lock = false;

		[GtkChild]
		private unowned Gtk.ListBox mime_type_listbox;
		[GtkChild]
		private unowned Gtk.ListBox uri_scheme_listbox;
		[GtkChild]
		private unowned Gtk.Entry add_entry;
		[GtkChild]
		private unowned Gtk.Notebook notebook;

		public PluginConfiguration (PluginInfo info, Settings settings) {
			Object(info: info, settings: settings);
		}

		construct {
			settings.changed.connect((name) => {
				if (name == "content-types" || name == "uri-schemes" &&
					!settings_lock) {
					synchronise_with_gsettings ();
				}
			});
			synchronise_with_gsettings ();
		}

		private Gtk.ListBoxRow create_config_entry_uri (string text) {
			var entry = new ConfigurationEntry(text);
			entry.deleted.connect(() => remove_uri_scheme(entry, text));
			entry.show_all ();
			return entry;
		}

		private Gtk.ListBoxRow create_config_entry_mime (string text) {
			var entry = new ConfigurationEntry(text);
			entry.deleted.connect(() => remove_content_type(entry, text));
			entry.show_all ();
			return entry;
		}

		private void synchronise_with_gsettings () {
			var obj = active_plugins.lookup(info.get_module_name ());
			if (obj == null) {
				return;
			}

			sync_uri_schemes((Plugin) obj);
			sync_content_types((Plugin) obj);
		}

		private void sync_uri_schemes (Plugin obj) {
			remove_all_loaders_of_type(obj.get_type ());

			var strv = settings.get_value("uri-schemes").dup_strv ();

			uri_scheme_listbox.foreach ((widget) => { uri_scheme_listbox.remove(
				widget); });
			schemes = new Array<string>.sized (true, true, sizeof (string),
				strv.length);

			foreach (var item in strv) {
				schemes.append_val(item);
				add_loader(item, (UriLoader) obj);
				uri_scheme_listbox.add(create_config_entry_uri(item));
			}
		}

		private void sync_content_types (Plugin obj) {
			remove_all_renderers_of_type(obj.get_type ());

			var strv = settings.get_value("content-types").dup_strv ();

			mime_type_listbox.foreach ((widget) => { mime_type_listbox.remove(
				widget); });
			types = new Array<string>.sized (true, true, sizeof (string),
				strv.length);

			foreach (var item in strv) {
				types.append_val(item);
				add_renderer(item, (Renderer) obj);
				mime_type_listbox.add(create_config_entry_mime(item));
			}
		}

		[GtkCallback]
		public void add_cb (Gtk.Button _btn) {
			if (notebook.page == 0) {
				add_uri_scheme(add_entry.text);
			} else {
				add_content_type(add_entry.text);
			}
			add_entry.text = "";
		}

		public void add_uri_scheme (string scheme) {
			schemes.append_val(scheme);
			uri_scheme_listbox.add(create_config_entry_uri(scheme));

			settings_lock = true;
			settings.set_value("uri-schemes", schemes.data);
			settings_lock = false;
		}

		public void add_content_type (string type) {
			types.append_val(type);
			mime_type_listbox.add(create_config_entry_mime(type));

			settings_lock = true;
			settings.set_value("content-types", types.data);
			settings_lock = false;
		}

		public void remove_uri_scheme (ConfigurationEntry entry,
			string type) {
			// TODO upon GLib 2.62 -> Array.binary_search
			for (var i = 0; i < schemes.length; i++) {
				if (schemes.data[i] == type) {
					schemes.remove_index(i);
					settings_lock = true;
					settings.set_value("uri-schemes", schemes.data);
					settings_lock = false;
					uri_scheme_listbox.remove(entry);
					break;
				}
			}
		}

		public void remove_content_type (ConfigurationEntry entry,
			string type) {
			// TODO upon GLib 2.62 -> Array.binary_search
			for (var i = 0; i < types.length; i++) {
				if (types.data[i] == type) {
					types.remove_index(i);
					settings_lock = true;
					settings.set_value("content-types", types.data);
					settings_lock = false;
					mime_type_listbox.remove(entry);
					break;
				}
			}
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
