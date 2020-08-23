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
		Gtk.Box url_bar_box;
		[GtkChild]
		Gtk.PopoverMenu history_menu;
		[GtkChild]
		Gtk.Box history_menu_box;
		[GtkChild]
		Gtk.MenuButton menu_button;
		[GtkChild]
		Gtk.ToggleButton reload_button;

		private History history;
		private HistorySuggestionModel history_model;

		private bool ignore_changes = false;

		Dazzle.SuggestionEntry url_bar;

		Gtk.Notebook notebook;
		Tab current {
			get {
				return notebook.get_nth_page(notebook.page) as Tab;
			}
		}

		uint entry_updater;

		internal Window (Sagittarius.Application app, History history) {
			Object(application: app);
			icon_name = "tk.thatlittlegit.sagittarius.gnome";

			this.history = history;

			add_action(create_action("enter-uri",
				() => this.select_address_bar ()));
			add_action(create_action("new-tab", () => this.create_tab ()));

			var menu = new Menu ();
			var menu1 = new Menu ();
			menu.append_section(null, menu1);
			menu1.append(_("History"), "app.history");
			var menu2 = new Menu ();
			menu.append_section(null, menu2);
			menu2.append(_("_Settings"), "app.settings");
			menu2.append(_("_Plugins"), "app.plugins");
			var menu3 = new Menu ();
			menu.append_section(null, menu3);
			menu3.append(_("_About"), "app.about");
			menu3.append(_("Quit"), "app.quit");
			menu_button.set_menu_model(menu);

			url_bar = new Dazzle.SuggestionEntry ();
			url_bar_box.pack_start(url_bar, true, true, 0);
			url_bar.activate_suggestion.connect(() => {
				url_bar.hide_suggestions ();
				navigate_cb(new Gtk.Button ());
			});
			url_bar.suggestion_activated.connect((sugg) => {
				url_bar.hide_suggestions ();
				current.navigate(sugg.get_data<Upg.Uri>("uri"));
			});
			history_model = new HistorySuggestionModel(history);
			url_bar.model = history_model;
			url_bar.changed.connect(() => {
				if (!ignore_changes) {
					history_model.filter(url_bar.typed_text);
					url_bar.show_suggestions ();
				}
			});
			url_bar.grab_focus.connect(() => url_bar.show_suggestions ());
			url_bar.show_all ();

			notebook = new Gtk.Notebook ();
			notebook.switch_page.connect((newfound) => {
				on_navigate_cb(newfound as Tab, true);
			});
			notebook.page_removed.connect(rethink_tab_visibility);
			notebook.page_added.connect(rethink_tab_visibility);
			notebook.show_tabs = false;
			notebook.scrollable = true;
			create_tab ();
			add(notebook);
			notebook.show ();

			// FIXME a better solution is needed
			entry_updater = Timeout.add(100, () => {
				if (current.label.spinning) {
					url_bar.progress_pulse ();
				} else {
					url_bar.progress_fraction = 0;
				}

				return true;
			});
			destroy.connect(() => {
				Source.remove(entry_updater);
			});
		}

		private void rethink_tab_visibility () {
			notebook.show_tabs = notebook.get_children ().length () > 1;
		}

		public Tab create_tab (string ? uri = null) {
			var tab = new Tab(this, history);
			notebook.set_current_page(notebook.append_page(tab, tab.label));
			tab.on_navigate.connect((tab) => on_navigate_cb(tab));
			tab.close.connect((page) => notebook.remove_page(notebook.page_num(
				page)));

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

		private void on_navigate_cb (Tab tab, bool force = false) {
			if (tab == current || force) {
				insert_action_group("tab", tab.action_group);

				toggle_ign = true;
				if (tab.label.spinning) {
					reload_button.active = true;
				} else {
					url_bar.progress_fraction = 0;
					reload_button.active = false;
				}
				toggle_ign = false;

				ignore_changes = true;
				if (tab.uri ==
					"about://home?%s".printf(Uri.escape_string(_("New Tab")))) {
					url_bar.set_text("");
				} else {
					url_bar.set_text(tab.uri ?? "");
				}
				ignore_changes = false;

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

		private bool toggle_ign = false;
		[GtkCallback]
		private void reload (Gtk.ToggleButton btn) {
			if (toggle_ign) {
				return;
			}

			toggle_ign = true;
			// counterintuitive. when it is ACTIVE, it has just been pressed;
			// it was not active before. when it is NOT ACTIVE, it has just
			// been... uh... depressed? oh no
			if (btn.active) {
				current.reload ();
				btn.active = true;
			} else {
				current.stop ();
				btn.active = false;
			}
			toggle_ign = false;
		}

		[GtkCallback]
		private bool show_history_menu (Gtk.Widget relative_to,
			Gdk.EventButton button) {
			if (button.button != 3) return false;

			history_menu_box.forall(item => history_menu_box.remove(item));

			if (current.history_uris.length () == 0) {
				return false;
			}

			for (int i = 0; i < current.history_uris.length (); i++) {
				var item = new Gtk.ModelButton ();
				var entry = current.history_uris.nth_data(i);
				item.text = entry.title ?? entry.uri.to_string_ign(
					Upg.UriFatalRanking.NONFATAL_NULLABLE) ?? "???";
				item.sensitive = i != current.current_history_pos;
				item.set_data<int>("history_pos", i);

				item.clicked.connect(() => {
					current.go_to_history_pos(item.get_data<int>(
						"history_pos"));
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
