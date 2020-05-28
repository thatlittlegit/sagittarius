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
		Gtk.MenuButton menu_button;
		[GtkChild]
		Gtk.Button back_button;
		[GtkChild]
		Gtk.Button forward_button;
		[GtkChild]
		Gtk.Stack content_stack;
		[GtkChild]
		Gtk.ScrolledWindow text_view_scroll;

		ErrorMessage errorview;

		public string last_uri = "gemini://";

		List<string> history;
		private int _current_history_pos = -1;
		public int current_history_pos {
			get {
				return _current_history_pos;
			}
			set {
				_current_history_pos = value;
				back_button.sensitive = value != -1;
				forward_button.sensitive = value != history.length () - 1;
			}
		}

		public Window (Sagittarius.Application app) {
			Object(application: app);
			icon_name = "tk.thatlittlegit.sagittarius.gnome";

			text_view.buffer.create_tag("pre", "family", "monospace");
			text_view.buffer.create_tag("h1", "weight", 600, "size-points", 26.0, "size-set", true);
			text_view.buffer.create_tag("h2", "weight", 500, "size-points", 22.0, "size-set", true);
			text_view.buffer.create_tag("h3", "weight", 400, "size-points", 18.0, "size-set", true);
			text_view.buffer.create_tag("ul", "tabs", new Pango.TabArray.with_positions(2, true,
					Pango.TabAlign.LEFT, 8,
					Pango.TabAlign.LEFT, 16
				));

			var menu = new Menu ();
			var menu1 = new Menu ();
			menu.append_section(null, menu1);
			menu1.append(_("_Settings"), "app.settings");
			var menu2 = new Menu ();
			menu.append_section(null, menu2);
			menu2.append(_("_About"), "app.about");
			menu2.append(_("Quit"), "app.quit");
			menu_button.set_menu_model(menu);

			errorview = new ErrorMessage ();
			errorview.show_all ();
			content_stack.add(errorview);
		}

		private void load_uri (string uri) {
			try {
				if (uri_struct(uri).scheme != "gemini") {
					AppInfo.launch_default_for_uri_async.begin(uri, null);
					return;
				}
			} catch (UriError err) {
			}

			url_bar.set_text (uri);
			text_view_scroll.vadjustment.value = 0;
			text_view_scroll.hadjustment.value = 0;

			get_gemini.begin(uri, (obj, res) => {
				try {
					var response = get_gemini.end(res);

					if (response.code == GeminiCode.SUCCESS) {
						text_view = parse_markup(uri, response.text, text_view, this);
						content_stack.visible_child = text_view_scroll;
						return;
					}

					// TODO cache permanent redirects if the user accepts
					errorview.set_message_for_response(this, response);
					content_stack.visible_child = errorview;
				} catch (Error err) {
					error(err.message);
				} finally {
					last_uri = uri;
				}
			});
		}

		[GtkCallback]
		private void navigate_cb (Gtk.Button unused) {
			navigate(url_bar.get_text ());
		}

		public void navigate (string uri) {
			while (current_history_pos + 1 < history.length ()) {
				history.remove_link(history.last());
			}

			try {
				if (uri.has_prefix("//") || uri.contains("://")) {
					history.append(parse_uri(last_uri, uri));
				} else {
					history.append(parse_uri(last_uri, strdup("gemini://%s".printf(uri))));
				}
			} catch (UriError err) {
				warning("UriError: %s".printf(err.message));
				errorview.internal_error ();
				content_stack.visible_child = errorview;
			} finally {
				current_history_pos++;
			}

			load_uri(history.nth_data(current_history_pos));
		}

		[GtkCallback]
		private void reload (Gtk.Button unused) {
			load_uri(history.nth_data(current_history_pos));
		}

		[GtkCallback]
		public void back (Gtk.Button unused) {
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
