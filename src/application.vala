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
		private Window main_window;
		private const ActionEntry[] actions = {
			{ "quit", quit },
			{ "about", show_about_dialog },
		};

		public Application () {
			Object(application_id: "tk.thatlittlegit.sagittarius", flags : ApplicationFlags.HANDLES_OPEN);
			add_action_entries(actions, this);
			activate.connect(create_window);
			open.connect(open_file);
		}

		private void create_window() {
			if (main_window != null) {
				return;
			}

			main_window = new Window(this);
			main_window.present ();
		}

		private void open_file (File[] files, string hint) {
			if (main_window == null) {
				create_window ();
			}

			// TODO when tabs are supported, load up *all* files
			main_window.navigate(files[0].get_uri ());
		}

		private void show_about_dialog () {
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
	}
}
