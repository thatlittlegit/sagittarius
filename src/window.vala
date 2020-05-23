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
		Gtk.Entry url_bar;
		[GtkChild]
		Gtk.PopoverMenu history_menu;
		[GtkChild]
		Gtk.Box history_menu_box;
		[GtkChild]
		Gtk.Overlay overlay;

		Granite.Widgets.OverlayBar overlaybar;

		List<string> history;
		int current_history_pos = -1;

		public Window (Gtk.Application app) {
			Object(application: app);

			// TODO when Granite adds a Glade catalog, use that instead
			overlaybar = new Granite.Widgets.OverlayBar (overlay);
			overlaybar.show_all ();
			overlaybar.label = _("Welcome to Sagittarius!");
		}

		private void load_uri (string uri) {
			overlaybar.label = _("Loading %s…");
			overlaybar.active = true;

			get_gemini.begin(uri, (obj, res) => {
				try {
					var response = get_gemini.end(res);

					text_view.buffer.set_text(response.text);
					overlaybar.label = _("Loaded page (MIME type %s)").printf(response.meta);
					overlaybar.active = false;
				} catch (Error err) {
					error(err.message);
				}
			});
		}

		[GtkCallback]
		private void navigate (Gtk.Button unused) {
			history.append(url_bar.get_text ());
			current_history_pos++;
			load_uri(history.nth_data(current_history_pos));
		}

		[GtkCallback]
		private void reload (Gtk.Button unused) {
			load_uri(history.nth_data(current_history_pos));
		}

		[GtkCallback]
		private void back (Gtk.Button unused) {
			current_history_pos--;
			load_uri(history.nth_data(current_history_pos));
		}

		[GtkCallback]
		private void forward (Gtk.Button unused) {
			current_history_pos++;
			load_uri(history.nth_data(current_history_pos));
		}

		[GtkCallback]
		private bool show_history_menu (Gtk.Widget relative_to, Gdk.EventButton button) {
			if (button.button != 3) return false;

			if (current_history_pos == -1) {
				var label = new Gtk.Label("no history yet :(");
				label.show ();
				history_menu_box.pack_end(label);
			}

			for (int i = 0; i <= current_history_pos; i++) {
				var item = new Gtk.ModelButton ();
				item.text = history.nth_data(i);
				item.show ();
				history_menu_box.pack_end(item);
			}

			history_menu.relative_to = relative_to;
			history_menu.popup ();
			return true;
		}
	}
}
