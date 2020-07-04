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

		private History history;

		Gtk.Notebook notebook;
		Tab current {
			get {
				return notebook.get_nth_page(notebook.page) as Tab;
			}
		}

		public Window (Sagittarius.Application app, History history) {
			Object(application: app);
			icon_name = "tk.thatlittlegit.sagittarius.gnome";

			this.history = history;

			var newTabAction = new SimpleAction("new-tab", null);
			newTabAction.activate.connect(() => this.create_tab ());
			add_action(newTabAction);

			var menu = new Menu ();
			var menu1 = new Menu ();
			menu.append_section(null, menu1);
			menu1.append(_("_Settings"), "app.settings");
			var menu2 = new Menu ();
			menu.append_section(null, menu2);
			menu2.append(_("_About"), "app.about");
			menu2.append(_("Quit"), "app.quit");
			menu_button.set_menu_model(menu);

			notebook = new Gtk.Notebook ();
			notebook.switch_page.connect((newfound) => {
				on_navigate_cb(newfound as Tab);
			});
			notebook.page_removed.connect(rethink_tab_visibility);
			notebook.page_added.connect(rethink_tab_visibility);
			notebook.show_tabs = false;
			notebook.scrollable = true;
			create_tab ();
			add(notebook);
			notebook.show ();
		}

		private void rethink_tab_visibility () {
			notebook.show_tabs = notebook.get_children ().length () > 1;
		}

		public Tab create_tab (string ? uri = null) {
			var tab = new Tab(this, history);
			notebook.set_current_page(notebook.append_page(tab, tab.label));
			tab.on_navigate.connect(on_navigate_cb);
			tab.close.connect((page) => notebook.remove_page(notebook.page_num(page)));

			notebook.set_tab_reorderable(tab, true);

			if (uri != null) {
				try {
					current.navigate(new Upg.Uri(uri));
				} catch (Error err) {
					current.internal_error ();
				}
			}
			return tab;
		}

		public void select_address_bar () {
			url_bar.has_focus = true;
		}

		private void on_navigate_cb (Tab tab) {
			forward_button.sensitive = tab.can_go_forward;
			back_button.sensitive = tab.can_go_back;
			url_bar.set_text(tab.uri ?? "");

			if (tab == current) {
				title = "%s - %s".printf(tab.label.text, _("Sagittarius"));
			}
		}

		[GtkCallback]
		private void navigate_cb (Gtk.Button unused) {
			try {
				var uri = url_bar.get_text ();

				var parsed = new Upg.Uri(uri);
				if (parsed.scheme != null || parsed.host != null) {
					current.navigate(parsed);
				} else {
					current.navigate(new Upg.Uri("gemini://%s".printf(uri)));
				}
			} catch (Error err) {
				current.internal_error ();
			}
		}

		[GtkCallback]
		private void reload (Gtk.Button unused) {
			current.reload ();
		}

		[GtkCallback]
		public void back (Gtk.Button unused) {
			current.back ();
		}

		[GtkCallback]
		private void forward (Gtk.Button unused) {
			current.forward ();
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
				item.text = current.history_uris.nth_data(i).to_string ();
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
