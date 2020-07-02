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

public delegate void NavigateFunc (Upg.Uri uri);

namespace Sagittarius {
	public class TabLabel : Gtk.Box {
		private Gtk.Label label;
		private Gtk.Spinner spinner;
		private Gtk.Button close_button;

		public bool spinning {
			get {
				return spinner.active;
			}
			set {
				spinner.active = value;
			}
		}

		public string text {
			get {
				return label.get_text ();
			}
			set {
				label.set_text(value);
			}
		}

		construct {
			label = new Gtk.Label("");
			spinner = new Gtk.Spinner ();
			close_button = new Gtk.Button.from_icon_name("window-close-symbolic");

			label.ellipsize = Pango.EllipsizeMode.END;
			label.set_width_chars(10);

			close_button.get_style_context ().add_class("flat");
			close_button.clicked.connect(() => close ());

			set_orientation(Gtk.Orientation.HORIZONTAL);
			pack_start(spinner, false, false, 4);
			pack_end(close_button, false, false, 4);
			pack_end(label, false, false, 4);
		}

		public TabLabel () {
		}

		public signal void close ();
	}

	public class Tab : Gtk.Stack {
		public int current_history_pos {
			get {
				return history.pos;
			}
		}

		public List<Upg.Uri> history_uris {
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
		public TabLabel label { get; construct set; }

		private History history;

		private ErrorMessage errorview;
		private Gtk.ScrolledWindow scrolled_text_view;

		private Window window;

		public Tab (Window _window) {
			window = _window;
			history = new History ();

			errorview = new ErrorMessage ();
			errorview.show ();
			add(errorview);

			scrolled_text_view = new Gtk.ScrolledWindow(null, null);
			add(scrolled_text_view);
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
			add(welcome);
			visible_child = welcome;

			label = new TabLabel ();
			label.text = _("New Tab");
			label.close.connect(() => close(this));
			label.show_all ();

			show_all ();
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

		public void navigate (Upg.Uri uri) {
			label.spinning = true;
			this.uri = uri.to_string ();
			history.navigate(uri);
			fetch_and_view(uri);
		}

		private void fetch_and_view (Upg.Uri full_uri) {
			fetch_and_view_async.begin(full_uri, (_, ctx) => {
				fetch_and_view_async.end(ctx);
			});
		}

		private async void fetch_and_view_async (Upg.Uri uri) {
			try {
				var document = yield fetch_uri (uri);

				view(uri, document);
			} catch (Error err) {
				internal_error(err.message);
			} finally {
				on_navigate(this);
			}
		}

		private void view (Upg.Uri uri, Content document) {
			if (document.code == SUCCESS) {
				var markup = parse_markup(uri, document.text);

				if (scrolled_text_view.get_child () != null) {
					scrolled_text_view.remove(scrolled_text_view.get_child ());
				}
				scrolled_text_view.add(display_markup(markup, navigate));

				visible_child = scrolled_text_view;

				label.text = markup.title ?? uri.to_string ();
				label.spinning = false;
				return;
			}

			errorview.set_message_for_response(navigate, document);
			label.spinning = false;
			visible_child = errorview;
		}

		public void internal_error (string ? message = null) {
			label.spinning = false;
			errorview.internal_error(message ?? "unknown error");
			visible_child = errorview;
		}

		public signal void on_navigate (Tab tab);
		public signal void close (Tab tab);
	}
}
