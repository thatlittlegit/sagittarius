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
		[GtkChild]
		Gtk.Stack content_stack;

		Granite.Widgets.OverlayBar overlaybar;
		Granite.Widgets.AlertView redirect_warning;
		Granite.Widgets.AlertView not_found_warning;

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

			text_view.buffer.create_tag("pre", "family", "monospace");
			text_view.buffer.create_tag("h1", "weight", 600, "size-points", 26.0, "size-set", true);
			text_view.buffer.create_tag("h2", "weight", 500, "size-points", 22.0, "size-set", true);
			text_view.buffer.create_tag("h3", "weight", 400, "size-points", 18.0, "size-set", true);
			text_view.buffer.create_tag("ul", "tabs", new Pango.TabArray.with_positions(2, true,
					Pango.TabAlign.LEFT, 8,
					Pango.TabAlign.LEFT, 16
				));

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

			redirect_warning = new Granite.Widgets.AlertView(
				_("You are being redirected"),
				"this is dummy text",
				"dialog-warning"
				);
			redirect_warning.action_activated.connect(() => {
				current_history_pos--;
				navigate(redirect_warning.get_data<string>("uri"));
			});
			redirect_warning.show_action(_("Proceed"));
			redirect_warning.show_all ();
			content_stack.add_named(redirect_warning, "redirect");

			not_found_warning = new Granite.Widgets.AlertView(
				_("File not found"),
				"this is dummy text",
				"dialog-error"
				);
			not_found_warning.show_all ();
			content_stack.add_named(not_found_warning, "notfound");
		}

		private void load_uri (string uri) {
			overlaybar.label = _("Loading %s…".printf(uri));
			overlaybar.active = true;

			get_gemini.begin(uri, (obj, res) => {
				try {
					var response = get_gemini.end(res);

					text_view = parse_markup(uri, response.text, text_view, this);
					overlaybar.label = _("Loaded page (MIME type %s)").printf(response.meta);
					overlaybar.active = false;
					content_stack.visible_child = text_view;
				} catch (GeminiCase res) {
					debug("GeminiCase handler (%d)".printf(res.code));
					switch (res.code) {
					case GeminiCase.PERMANENT_REDIRECT:
					// TODO cache if the user accepts
					case GeminiCase.TEMPORARY_REDIRECT:
						redirect_warning.description =
							_("The website is trying to send you to <b>%s</b>. Would you like to go there?")
							 .printf(res.message);
						redirect_warning.set_data<string>("uri", res.message);
						content_stack.visible_child = redirect_warning;
						break;
					case GeminiCase.NOT_FOUND:
						not_found_warning.description =
							_("<i>We searched far and wide\nBut it we could not find.\nIt could not be found.</i>\n<b>%s</b>")
							 .printf(res.message);
						content_stack.visible_child = not_found_warning;
						break;
					}
				} catch (Error err) {
					error(err.message);
				}
			});
		}

		[GtkCallback]
		private void navigate_cb (Gtk.Button unused) {
			history.append(url_bar.get_text ());
			current_history_pos++;
			navigate(history.nth_data(current_history_pos));
		}

		public void navigate (string uri) {
			if (current_history_pos + 1 != history.length ()) {
				for (int i = current_history_pos; i < history.length (); i++) {
					history.remove(history.nth_data(i));
				}
			}

			load_uri(uri);
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
