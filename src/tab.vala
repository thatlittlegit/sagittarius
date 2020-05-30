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
	public class Tab : Gtk.Stack {
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
		private Gtk.TextView text_view;

		public Tab () {
			history = new History ();

			errorview = new ErrorMessage ();
			errorview.show ();
			add(errorview);

			scrolled_text_view = new Gtk.ScrolledWindow(null, null);
			text_view = new Gtk.TextView ();
			text_view.margin = 16;
			text_view.editable = false;
			scrolled_text_view.add(text_view);
			text_view.show ();
			add(scrolled_text_view);
			scrolled_text_view.show ();
			visible_child = scrolled_text_view;

			text_view.buffer.create_tag("pre", "family", "monospace");
			text_view.buffer.create_tag("h1", "weight", 600, "size-points", 26.0, "size-set", true);
			text_view.buffer.create_tag("h2", "weight", 500, "size-points", 22.0, "size-set", true);
			text_view.buffer.create_tag("h3", "weight", 400, "size-points", 18.0, "size-set", true);
			text_view.buffer.create_tag("ul", "tabs", new Pango.TabArray.with_positions(2, true,
																						Pango.TabAlign.LEFT, 8,
																						Pango.TabAlign.LEFT, 16
																						));
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
			try {
				var uri = parse_uri(old_uri ?? "gemini://unknown_host.test", new_uri);
				history.navigate(uri);
				fetch_and_view(uri);
			} catch (UriError err) {
				warning("UriError: %s", err.message);
				internal_error ();
			}
		}

		private void fetch_and_view (string full_uri) {
			uri = full_uri;

			get_gemini.begin(uri, (_, ctx) => {
				try {
					view(uri, get_gemini.end(ctx));
				} catch (Error err) {
					internal_error ();
				} finally {
					on_navigate(this);
				}
			});
		}

		private void view (string uri, Content document) {
			if (document.code == SUCCESS) {
				text_view = parse_markup(uri, document.text, text_view, navigate);
				visible_child = scrolled_text_view;
				return;
			}

			errorview.set_message_for_response(navigate, document);
			visible_child = errorview;
		}

		public void internal_error () {
			errorview.internal_error ();
			visible_child = errorview;
		}

		public signal void on_navigate (Tab tab);
	}
}
