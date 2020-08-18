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
	internal class TabLabel : Gtk.Box {
		private Gtk.Label label;
		private Gtk.Revealer revealer;
		private Gtk.Spinner spinner;
		private Gtk.Button close_button;

		internal bool spinning {
			get {
				return spinner.active;
			}
			set {
				revealer.reveal_child = value;
				spinner.active = value;
			}
		}

		internal string text {
			get {
				return label.get_text ();
			}
			set {
				label.set_text(value);
			}
		}

		construct {
			label = new Gtk.Label("");
			revealer = new Gtk.Revealer ();
			spinner = new Gtk.Spinner ();
			revealer.add(spinner);
			close_button =
				new Gtk.Button.from_icon_name("window-close-symbolic");

			label.ellipsize = Pango.EllipsizeMode.END;
			label.set_width_chars(10);

			close_button.get_style_context ().add_class("flat");
			close_button.clicked.connect(() => close ());

			set_orientation(Gtk.Orientation.HORIZONTAL);
			pack_start(revealer, false, false, 4);
			pack_end(close_button, false, false, 4);
			pack_end(label, false, false, 4);
		}

		internal TabLabel () {
		}

		internal signal void close ();
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

		internal ActionGroup action_group {
			get {
				return get_action_group("tab");
			}
		}

		public string uri { get; private set; }
		internal TabLabel label;

		private History history;

		private ErrorMessage errorview;
		private Gtk.ScrolledWindow scrolled_text_view;

		private Gtk.Stack stack;

		private Gtk.InfoBar warning_bar;
		private Gtk.Label warning_bar_label;

		private Window window;

		private Cancellable cancel;

		internal HashTable<string, Object ? > state { internal get; private set;
		}

		internal Tab (Window _window, History parent_history) {
			Object(orientation: Gtk.Orientation.VERTICAL);
			window = _window;
			history = new History(parent_history);

			state = new HashTable<string, Object ? >(str_hash, str_equal);

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

			label = new TabLabel ();
			label.text = _("New Tab");
			label.close.connect(() => close(this));
			label.show_all ();

			show_all ();

			try {
				navigate(new Upg.Uri("about:home?%s".printf(Uri.escape_string(_(
					"New Tab")))));
			} catch (Error err) {
				error(
					"this is impossible! failed to parse fixed homepage uri, file a bug please (%s)",
					err.message);
			}

			on_navigate.connect(() => {
				var group = (ActionMap) get_action_group("tab");
				((SimpleAction) group.lookup_action("back")).set_enabled(history
					 .can_go_back);
				((SimpleAction) group.lookup_action("forward")).set_enabled(
					history.can_go_forward);
			});

			insert_action_group("tab", prepare_actions ());
		}

		private ActionGroup prepare_actions () {
			var actions = new SimpleActionGroup ();

			actions.add_action(create_action("back", () => this.back ()));
			actions.add_action(create_action("forward", () => this.forward ()));
			actions.add_action(create_action("close", () => this.close(this)));
			actions.add_action(create_action("reload", () => this.reload ()));

			return actions;
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

		public void stop () {
			cancel.cancel ();
			cancel = null;
		}

		public void navigate (Upg.Uri uri) {
			this.uri =
				uri.to_string_ign(Upg.UriFatalRanking.NONFATAL_NEVERNULL);
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
				if (cancel != null) {
					cancel.cancel ();
				}

				cancel = new Cancellable ();
				label.spinning = true;
				on_navigate(this);
				var document = yield fetch_uri (state, uri, cancel);

				yield view (uri, document);
			} catch (Error err) {
				internal_error("%s: (%d) %s".printf(err.domain.to_string (),
					err.code, err.message));
			} finally {
				cancel = null;
				on_navigate(this);
			}
		}

		private async void view (Upg.Uri uri, Content document) throws Error {
			if (document.outcome == UriLoadOutcome.SUCCESS) {
				var loading_trigger = new LoadingTrigger ();

				loading_trigger.trigger.connect((title) => {
					label.spinning = false;
					label.text = title ??
								 uri.to_string_ign(
						Upg.UriFatalRanking.NONFATAL_NULLABLE) ?? "???";
					record_in_history(uri, label.text);
					on_navigate(this);
				});

				loading_trigger.warning.connect((message) => {
					warning("warning when rendering: %s", message);
					warning_bar_label.label = message;
					warning_bar.show_all ();
					warning_bar.revealed = true;
					loading_trigger.trigger(null);
				});

				var rendered = yield render_content (state, navigate, document,
					cancel, loading_trigger);

				if (scrolled_text_view.get_child () != null) {
					scrolled_text_view.remove(scrolled_text_view.get_child ());
				}
				scrolled_text_view.add(rendered);
				rendered.show_all ();

				stack.visible_child = scrolled_text_view;
			} else {
				var meta = bytes_to_string(document.data.read_bytes(1024));
				if (document.outcome == UriLoadOutcome.PERMANENT_REDIRECT ||
					document.outcome == UriLoadOutcome.TEMPORARY_REDIRECT) {
					try {
						var redirect_uri = meta;

						var redirectstr = redirect_uri.to_string ();
						var originalstr = document.original_uri.to_string ();
						if (originalstr.substring(0,
							originalstr.length - 1) == redirectstr ||
							redirectstr.substring(0,
								redirectstr.length - 1) == originalstr) {
							on_navigate(this);
							navigate(new Upg.Uri(redirect_uri));
							return;
						}
					} catch (Error err) {
					}
				}
				errorview.set_message_for_response(navigate, document.outcome,
					meta, document.original_uri);
				stack.visible_child = errorview;
				label.text = uri.to_string ();
				label.spinning = false;
				record_in_history(uri, uri.to_string ());
			}
		}

		private void record_in_history (Upg.Uri uri, string title) {
			try {
				var date = new DateTime.now_utc ();
				history.set_top(new HistoryEntry(date, uri, title));
				history.record(date, uri, title);
			} catch (Error err) {
				warning_bar_label.label = _(
					"We couldn't record this site in your history.");
				warning_bar.set_revealed(true);
			}
		}

		internal void internal_error (string ? message = null) {
			label.spinning = false;
			errorview.internal_error(message ?? "unknown error");
			stack.visible_child = errorview;
		}

		public signal void on_navigate (Tab tab);

		public signal void close (Tab tab);
	}
}
