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
			{ "quit", quit },
			{ "about", show_about_dialog },
			{ "plugins", manage_plugins },
		};

		private History history;

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

			startup.connect(initialize_history);
			startup.connect(init_loaders);
			startup.connect(init_renderers);
			startup.connect(configure_plugin_engine);

			activate.connect(() => {
				new Window(this, history).present ();
			});
			open.connect(open_file);
		}

		private void initialize_history () {
			try {
				var history_file = File.new_build_filename(
					Environment.get_user_data_dir (), "sagittarius",
					"history.csv");

				try {
					history_file.create(FileCreateFlags.NONE)
					 .write("# %s\n# %s\n#\n# %s\n".printf(
						_("history.csv: history file for Sagittarius"),
						_(
							"This file stores the history from your Sagittarius browsing."),
						_("DATE                  URI\t\tTITLE")
						).data);
				} catch (IOError err) {
					if (err.code != IOError.EXISTS) {
						throw err;
					}
				}

				history = new History.with_file(null,
					history_file.open_readwrite ());
			} catch (Error err) {
				error(err.message);
			}
		}

		private void open_file (File[] files, string hint) {
			foreach (var file in files) {
				// this *should* work, since activate is called before open?
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

		private void manage_plugins () {
			var plugin_window = new PluginsWindow ();
			plugin_window.show ();
		}
	}
}
