/* window.vala
 *
 * Copyright 2020 thatlittlegit
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
 */

namespace Sagittarius {
	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild]
		Gtk.TextView text_view;
		[GtkChild]
		Gtk.Box main_box;
		[GtkChild]
		Gtk.Entry url_bar;

		Gtk.Statusbar statusbar;
		uint main_context;

		public Window (Gtk.Application app) {
			Object(application: app);

			// XXX this can't be done in Glade?
			statusbar = new Gtk.Statusbar ();
			main_context = statusbar.get_context_id("Main browser activities");
			main_box.add(statusbar);
			statusbar.show ();

			statusbar.push(main_context, _("Welcome to Sagittarius!"));
		}

		[GtkCallback]
		private void load_uri (Gtk.Button unused) {
			get_gemini.begin(url_bar.get_text (), (obj, res) => {
				try {
					var response = get_gemini.end(res);

					text_view.buffer.set_text(response.text);
					statusbar.push(main_context, "Loaded page (MIME type %s)".printf(response.meta));
				} catch (Error err) {
					error(err.message);
				}
			});
		}
	}
}
