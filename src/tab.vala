/* tab.vala
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

public delegate void NavigateFunc (string ? old, string newfound);

namespace Sagittarius {
	public class Tab : Granite.Widgets.Tab {
		public int current_history_pos {
			get {
				return history.pos;
			}
		}

		public List<string> history_uris {
			get {
				return history.history;
			}
		}

		public bool can_go_back {
			get {
				return history.can_go_back;
			}
		}

		public bool can_go_forward {
			get {
				return history.can_go_forward;
			}
		}

		public string uri { get; private set; }

		private History history;

		private ErrorMessage errorview;
		private Gtk.ScrolledWindow scrolled_text_view;
		private Gtk.Box content_box;
		private Gtk.Stack stack;

		private Window window;

		public Tab (Window _window) {
			window = _window;
			history = new History ();

			stack = new Gtk.Stack ();
			page = stack;

			errorview = new ErrorMessage ();
			errorview.show ();
			stack.add(errorview);

			scrolled_text_view = new Gtk.ScrolledWindow(null, null);
			content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			scrolled_text_view.add(content_box);
			stack.add(scrolled_text_view);
			scrolled_text_view.show_all ();

			var welcome = new Granite.Widgets.Welcome(_("Sagittarius"), _("Welcome to Sagittarius!"));
			welcome.append("input-keyboard", _("Enter a URI"), _("Type a URL in the address bar to navigate."));
			welcome.show ();
			welcome.activated.connect((index) => {
				switch (index) {
				case 0:
					window.select_address_bar ();
					break;
				}
			});
			stack.add(welcome);
			stack.visible_child = welcome;

			label = _("New Tab");

			stack.show_all ();
		}

		public void go_to_history_pos (int pos) {
			history.pos = pos;
			fetch_and_view(history.top ());
		}

		public void back () {
			history.back ();
			fetch_and_view(history.top ());
		}

		public void forward () {
			history.forward ();
			fetch_and_view(history.top ());
		}

		public void reload () {
			fetch_and_view(history.top ());
		}

		public void navigate (string ? old_uri, string new_uri) {
			working = true;
			try {
				var uri = parse_uri(old_uri ?? "gemini://unknown_host.test", new_uri);
				history.navigate(uri);
				fetch_and_view(uri);
			} catch (UriError err) {
				warning("UriError: %s", err.message);
				internal_error ();
			}
		}

		private void fetch_and_view (string uri) {
			try {
				fetch_and_view_uri(uri_struct(uri));
			} catch (UriError err) {
				critical("unexpected UriError");
			}
		}

		private void fetch_and_view_uri (Uri full_uri) {
			uri = uri_to_string(full_uri);

			fetch.begin(full_uri, (_, ctx) => {
				fetch.end(ctx);
			});
		}

		private async void fetch (Uri uri) {
			try {
				view(uri, yield fetch_uri(uri));
			} catch (Error err) {
				internal_error ();
			} finally {
				on_navigate(this);
			}
		}

		private void view (Uri uri, Content document) {
			if (document.code == SUCCESS) {
				var markup = parse_markup(uri, document.text);
				var new_textview = display_markup(markup, navigate);
				content_box.remove(content_box.get_children ().nth_data(0));
				content_box.add(new_textview);
				stack.visible_child = scrolled_text_view;

				label = markup.title ?? uri_to_string(uri);
				working = false;
				return;
			}

			errorview.set_message_for_response(navigate, document);
			working = false;
			stack.visible_child = errorview;
		}

		public void internal_error () {
			working = false;
			errorview.internal_error ();
			stack.visible_child = errorview;
		}

		public signal void on_navigate (Tab tab);
	}
}
