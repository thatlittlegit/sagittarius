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

	public class Tab : Gtk.Box {
		public int current_history_pos {
			get {
				return history.pos;
			}
		}

		public List<HistoryEntry> history_uris {
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

		private Gtk.Stack stack;

		private Gtk.InfoBar warning_bar;
		private Gtk.Label warning_bar_label;

		private Window window;

		public Tab (Window _window, History parent_history) {
			Object(orientation: Gtk.Orientation.VERTICAL);
			window = _window;
			history = new History(parent_history);

			warning_bar = new Gtk.InfoBar ();
			warning_bar_label = new Gtk.Label(_("Text currently unset."));
			warning_bar.revealed = false;
			warning_bar.show_close_button = true;
			warning_bar.response.connect(() => warning_bar.set_revealed(false));
			warning_bar.get_content_area ().add(warning_bar_label);
			warning_bar.message_type = Gtk.MessageType.WARNING;
			warning_bar.show_all ();
			pack_start(warning_bar, false, false, 0);

			stack = new Gtk.Stack ();
			pack_end(stack, true, true, 0);

			errorview = new ErrorMessage ();
			errorview.show ();
			stack.add_named(errorview, "error");

			scrolled_text_view = new Gtk.ScrolledWindow(null, null);
			stack.add_named(scrolled_text_view, "content");
			scrolled_text_view.show_all ();

			var welcome = new Dazzle.EmptyState ();
			welcome.title = _("Welcome to Sagittarius!");
			welcome.subtitle = _("Start by typing a URL in the address bar.");
			welcome.show ();
			stack.add_named(welcome, "welcome");
			stack.visible_child = welcome;

			label = new TabLabel ();
			label.text = _("New Tab");
			label.close.connect(() => close(this));
			label.show_all ();

			show_all ();
		}

		public void go_to_history_pos (int pos) {
			history.pos = pos;
			fetch_and_view(history.top ().uri);
		}

		public void back () {
			history.back ();
			fetch_and_view(history.top ().uri);
		}

		public void forward () {
			history.forward ();
			fetch_and_view(history.top ().uri);
		}

		public void reload () {
			fetch_and_view(history.top ().uri);
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

				yield view (uri, document);
			} catch (Error err) {
				internal_error(err.message);
			} finally {
				on_navigate(this);
			}
		}

		private async void view (Upg.Uri uri, Content document) {
			string title;
			if (document.content_type.get_parameter("code") == "20") {
				var markup = yield parse_markup (uri, document.data);

				var displayed = yield display_markup (markup, navigate);

				if (scrolled_text_view.get_child () != null) {
					scrolled_text_view.remove(scrolled_text_view.get_child ());
				}
				scrolled_text_view.add(displayed);

				stack.visible_child = scrolled_text_view;

				title = markup.title ?? uri.to_string ();
			} else {
				errorview.set_message_for_response(navigate, document);
				stack.visible_child = errorview;
				title = uri.to_string ();
			}
			label.spinning = false;
			label.text = title;

			try {
				var date = new DateTime.now_utc ();
				history.set_top(new HistoryEntry(date, uri, title));
				history.record(date, uri, title);
			} catch (IOError err) {
				warning_bar_label.label = _("We couldn't record this site in your history.");
				warning_bar.set_revealed(true);
			}
		}

		public void internal_error (string ? message = null) {
			label.spinning = false;
			errorview.internal_error(message ?? "unknown error");
			stack.visible_child = errorview;
		}

		public signal void on_navigate (Tab tab);
		public signal void close (Tab tab);
	}
}
