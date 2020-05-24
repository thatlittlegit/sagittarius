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
	public class Application : Gtk.Application {
		private const ActionEntry[] actions = {
			{ "quit", quit },
			{ "about", show_about_dialog },
		};

		public Application () {
			Object(application_id: "tk.thatlittlegit.sagittarius", flags : ApplicationFlags.FLAGS_NONE);
			add_action_entries(actions, this);
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
		[GtkChild]
		Gtk.MenuButton menu_button;
		[GtkChild]
		Gtk.Button back_button;
		[GtkChild]
		Gtk.Button forward_button;

		Granite.Widgets.OverlayBar overlaybar;

		List<string> history;
		int _current_history_pos = -1;
		int current_history_pos {
			get {
				return _current_history_pos;
			}
			set {
				_current_history_pos = value;
				back_button.sensitive = value != -1;
				forward_button.sensitive = value != history.length() - 1;
			}
		}

		public Window (Sagittarius.Application app) {
			Object(application: app);
			icon_name = "tk.thatlittlegit.sagittarius.gnome";

			// TODO when Granite adds a Glade catalog, use that instead
			overlaybar = new Granite.Widgets.OverlayBar(overlay);
			overlaybar.show_all ();
			overlaybar.label = _("Welcome to Sagittarius!");

			var menu = new Menu ();
			var menu1 = new Menu ();
			menu.append_section(null, menu1);
			menu1.append(_("_Settings"), "app.settings");
			var menu2 = new Menu ();
			menu.append_section(null, menu2);
			menu2.append(_("_About"), "app.about");
			menu2.append(_("Quit"), "app.quit");
			menu_button.set_menu_model(menu);
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
			if (current_history_pos + 1 != history.length()) {
				for (int i = current_history_pos; i < history.length(); i++) {
					history.remove(history.nth_data(i));
				}
			}

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

			history_menu_box.forall(item => history_menu_box.remove(item));

			if (current_history_pos == -1) {
				var label = new Gtk.Label("no history yet :(");
				label.show ();
				history_menu_box.pack_end(label);
			}

			for (int i = 0; i < history.length (); i++) {
				var item = new Gtk.ModelButton ();
				item.text = history.nth_data(i);
				item.sensitive = i != current_history_pos;
				item.set_data<int>("history_pos", i);

				item.clicked.connect(() => {
					current_history_pos = item.get_data<int>("history_pos");
					load_uri(history.nth_data(current_history_pos));
				});

				item.show ();
				history_menu_box.pack_end(item);
			}

			history_menu.relative_to = relative_to;
			history_menu.popup ();
			return true;
		}
	}
}
