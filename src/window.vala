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
		Gtk.Entry url_bar;
		[GtkChild]
		Gtk.PopoverMenu history_menu;
		[GtkChild]
		Gtk.Box history_menu_box;
		[GtkChild]
		Gtk.MenuButton menu_button;
		[GtkChild]
		Gtk.Button back_button;
		[GtkChild]
		Gtk.Button forward_button;

		Granite.Widgets.DynamicNotebook notebook;
		Tab current {
			get {
				return notebook.current.page as Tab;
			}
		}

		public Window (Sagittarius.Application app) {
			Object(application: app);
			icon_name = "tk.thatlittlegit.sagittarius.gnome";

			var menu = new Menu ();
			var menu1 = new Menu ();
			menu.append_section(null, menu1);
			menu1.append(_("_Settings"), "app.settings");
			var menu2 = new Menu ();
			menu.append_section(null, menu2);
			menu2.append(_("_About"), "app.about");
			menu2.append(_("Quit"), "app.quit");
			menu_button.set_menu_model(menu);

			notebook = new Granite.Widgets.DynamicNotebook();
			notebook.add_button_visible = true;
			notebook.tab_bar_behavior = Granite.Widgets.DynamicNotebook.TabBarBehavior.ALWAYS;
			notebook.new_tab_requested.connect(() => {
				create_tab();
			});
			notebook.tab_switched.connect((old, newfound) => {
				on_navigate_cb(newfound.page as Tab);
			});
			notebook.new_tab_requested();
			add(notebook);
			notebook.show();
		}

		public void navigate (string uri) {
			try {
				if (uri_struct(uri).scheme != "gemini") {
					AppInfo.launch_default_for_uri_async.begin(uri, null);
					return;
				}
			} catch (UriError err) {
			}

			url_bar.set_text (uri);
			current.navigate(null, uri);
		}

		public Tab create_tab () {
			var tab = new Tab();
			var gtab = new Granite.Widgets.Tab("Tab", null, tab);
			notebook.insert_tab(gtab, notebook.n_tabs - 1);
			notebook.current = gtab;
			tab.on_navigate.connect(on_navigate_cb);
			return tab;
		}

		private void on_navigate_cb (Tab tab) {
			forward_button.sensitive = tab.can_go_forward;
			back_button.sensitive = tab.can_go_back;
			url_bar.set_text(tab.uri ?? "");
		}

		[GtkCallback]
		private void navigate_cb (Gtk.Button unused) {
			string uri = url_bar.get_text();
			if (uri.has_prefix("//") || uri.contains("://")) {
				current.navigate(null, uri);
			} else {
				current.navigate(null, strdup("gemini://%s".printf(uri)));
			}
		}

		[GtkCallback]
		private void reload (Gtk.Button unused) {
			current.reload();
		}

		[GtkCallback]
		public void back (Gtk.Button unused) {
			current.back();
		}

		[GtkCallback]
		private void forward (Gtk.Button unused) {
			current.forward();
		}

		[GtkCallback]
		private bool show_history_menu (Gtk.Widget relative_to, Gdk.EventButton button) {
			if (button.button != 3) return false;

			history_menu_box.forall(item => history_menu_box.remove(item));

			if (!current.can_go_back && !current.can_go_forward) {
				return false;
			}

			for (int i = 0; i < current.history_uris.length (); i++) {
				var item = new Gtk.ModelButton ();
				item.text = current.history_uris.nth_data(i);
				item.sensitive = i != current.current_history_pos;
				item.set_data<int>("history_pos", i);

				item.clicked.connect(() => {
					current.go_to_history_pos(item.get_data<int>("history_pos"));
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
