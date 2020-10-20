/* application.vala
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
 */

namespace Sagittarius {
	public class Application : Gtk.Application {
		private const ActionEntry[] actions = {
			{ "about", show_about_dialog },
			{ "history", show_history_window },
			{ "plugins", manage_plugins },
			{ "quit", quit },
		};

		private History history;
		internal History bookmarks;

		internal Peas.ExtensionSet extensions;
		internal Settings settings;

		internal Application () {
			Object(application_id: "tk.thatlittlegit.sagittarius",
				flags : ApplicationFlags.HANDLES_OPEN);
		}

		construct {
			add_action_entries(actions, this);

			startup.connect(() => {
				settings = new Settings("tk.thatlittlegit.sagittarius");
			});

			startup.connect(keyboard_shortcuts);
			startup.connect(initialize_history);
			startup.connect(init_loaders);
			startup.connect(init_renderers);
			startup.connect(configure_plugin_engine);

			activate.connect(() => {
				new Window(this, history).present ();
				((Window) active_window).create_tab ();
			});
			open.connect(open_file);
		}

		private void keyboard_shortcuts () {
			set_accels_for_action("app.about", { "<Control><Shift>A" });
			set_accels_for_action("app.history", { "<Control><Shift>H" });
			set_accels_for_action("app.plugins", { "<Control><Shift>L" });
			set_accels_for_action("app.quit", { "<Alt>F4" });

			set_accels_for_action("tab.back", { "<Control>Left" });
			set_accels_for_action("tab.close", { "<Control>W" });
			set_accels_for_action("tab.forward", { "<Control>Right" });
			set_accels_for_action("tab.reload", { "<Control>R" });

			set_accels_for_action("win.new-tab", { "<Control>T" });
			set_accels_for_action("win.enter-uri", { "<Control>L" });
		}

		private void initialize_history () {
			try {
				var history_file = File.new_build_filename(
					Environment.get_user_data_dir (), "sagittarius",
					"history.csv");
				var bookmarks_file = File.new_build_filename(
					Environment.get_user_data_dir (), "sagittarius",
					"bookmarks.csv");

				try {
					history_file.create(FileCreateFlags.NONE).write("".data);
				} catch (IOError err) {
					if (err.code != IOError.EXISTS) {
						throw err;
					}
				}

				try {
					bookmarks_file.create(FileCreateFlags.NONE).write("".data);
				} catch (IOError err) {
					if (err.code != IOError.EXISTS) {
						throw err;
					}
				}

				history = new History.with_file(null, history_file);
				bookmarks = new History.with_file(null, bookmarks_file);
			} catch (Error err) {
				error(err.message);
			}
		}

		private void open_file (File[] files, string hint) {
			if (active_window == null) {
				new Window(this, history).present ();
			}

			foreach (var file in files) {
				((Window) active_window).create_tab(file.get_uri ());
			}
		}

		public void show_about_dialog () {
			var dialog = new Gtk.AboutDialog ();
			dialog.modal = true;
			dialog.authors = { "thatlittlegit" };
			dialog.comments = _("A browser for Gemini");
			dialog.copyright = "© 2020 thatlittlegit.";
			dialog.license_type = Gtk.License.GPL_3_0_ONLY;
			dialog.logo_icon_name = "tk.thatlittlegit.sagittarius.gnome";
			dialog.program_name = _("Sagittarius");
			dialog.website = "https://github.com/thatlittlegit/sagittarius";
			dialog.run ();
			dialog.destroy ();
		}

		public void show_history_window () {
			new LibraryWindow(history, bookmarks).present ();
		}

		private void manage_plugins () {
			new PluginsWindow ().present ();
		}
	}
}
