/* error.vala
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

namespace Sagittarius {
	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/error.ui")]
	public class ErrorMessage : Gtk.Grid {
		private const string INFO_ICON = "dialog-information";
		private const string WARNING_ICON = "dialog-warning";
		private const string QUESTION_ICON = "dialog-question";
		private const string ERROR_ICON = "dialog-error";
		private const string SCRIPT_ICON = "text-x-script";
		private const string NETWORK_ERROR_ICON = "network-error";
		private const string NETWORK_WARNING_ICON = "network-offline";
		private const string PASSWORD_ICON = "input-keyboard";
		private const string ALARM_ICON = "alarm";

		[GtkChild]
		private Gtk.Image image;
		[GtkChild]
		private Gtk.Label title;
		[GtkChild]
		private Gtk.Label description;
		[GtkChild]
		private Gtk.Box site_says_box;
		[GtkChild]
		private Gtk.Label site_says_text;
		[GtkChild]
		private Gtk.Label site_says;
		[GtkChild]
		private Gtk.Button button_one;
		[GtkChild]
		private Gtk.Box prebutton_box;

		public Gtk.Button button {
			get {
				return button_one;
			}
		}

		public ErrorMessage () {
		}

		private ulong last_handler = 0;

		public void set_message_for_response (NavigateFunc navigate,
			int code, string meta, Upg.Uri uri) {
			prebutton_box.hide ();
			button_one.hide ();
			button_one.sensitive = true;
			site_says_text.show ();

			if (last_handler != 0) {
				SignalHandler.disconnect(button_one, last_handler);
			}

			switch (code) {
			case UriLoadOutcome.TEXT_INPUT_WANTED:
				set_message(PASSWORD_ICON, _("Input wanted"), null, meta);
				button_one.show ();
				button_one.label = _("Go");
				Gtk.Entry text_entry = new Gtk.Entry ();
				set_prebutton_widget(text_entry);
				last_handler = button_one.clicked.connect(() => {
					uri.query_str = text_entry.text;
					button_one.sensitive = false;
					navigate(uri);
				});
				break;
			case UriLoadOutcome.SUCCESS:
				set_message("weather-clear", _("Success!"),
					_(
						"Everything worked, except the programmer's brain when they were writing this."));
				break;
			case UriLoadOutcome.PERMANENT_REDIRECT:
			case UriLoadOutcome.TEMPORARY_REDIRECT:
				set_message(QUESTION_ICON,
					_("You are being redirected"),
					_(
						"The website is trying to send you to %s. Would you like to go there?").printf(
						meta),
					meta);

				Upg.Uri destination;
				try {
					destination = uri.apply_reference(meta);
				} catch (Error err) {
					internal_error(err.message);
					return;
				}

				button_one.show ();
				button_one.label = _("Redirect");
				last_handler =
					button_one.clicked.connect(() => navigate(destination));
				return;
			case UriLoadOutcome.TEMPORARY_ERROR:
				set_message(WARNING_ICON, _("Temporary failure"),
					_(
						"Something went wrong with the website. Try again later."),
					meta);
				break;
			case UriLoadOutcome.SERVER_UNAVAILABLE:
				set_message(ERROR_ICON, _("Server unavailable"),
					_(
						"The server is unavailable due to overload, maintenance, or some other problem. Try again later."),
					meta);
				break;
			case UriLoadOutcome.CGI_ERROR:
				set_message(SCRIPT_ICON, _("Server script error"),
					_(
						"The server encountered an error when processing your request."),
					meta);
				break;
			case UriLoadOutcome.PROXY_ERROR:
				set_message(NETWORK_ERROR_ICON, _("Proxy error"),
					_("The server wasn't able to proxy your request."), meta);
				break;
			case UriLoadOutcome.SLOW_DOWN:
				set_message(ALARM_ICON, _("Slow down!"),
					_("You're sending requests too fast."), meta);
				button_one.show ();
				button_one.sensitive = false;
				button_one.label = _("Go");
				last_handler =
					button_one.clicked.connect(() => navigate(uri));

				Timeout.add(5000, () => {
					button_one.sensitive = true;
					return false;
				});
				break;
			case UriLoadOutcome.PERMANENT_ERROR:
				set_message(ERROR_ICON, _("Permanent error"),
					_(
						"Something went wrong, and it will never work again. :("),
					meta);
				break;
			case UriLoadOutcome.NOT_FOUND:
				set_message(WARNING_ICON,
					_("File not found"),
					_(
						"We searched far and wide\nBut it we could not find.\nIt could not be found."),
					meta);
				break;
			case UriLoadOutcome.GONE:
				set_message(ERROR_ICON, _("G O N E"),
					_(
						"The file is gone.\nIt will never be back.\nWas it ever there?\nIs life but a dream?"),
					meta);
				break;
			case UriLoadOutcome.PROXY_REQUEST_REFUSED:
				set_message(NETWORK_ERROR_ICON, _("Proxy request refused"),
					_(
						"You asked the server to proxy a request for you, but the server won't do that."),
					meta);
				break;
			case UriLoadOutcome.BAD_REQUEST:
				set_message(ERROR_ICON, _("Bad request"),
					_(
						"Something went wrong, and the request was invalid?"),
					meta);
				break;
			case UriLoadOutcome.UNKNOWN_SCHEME:
				// TODO in future, might be nice to have a proper app chooser
				set_message(INFO_ICON, _("Huh?"),
					_(
						"We don't know how to open this URI, but you can try opening it with something else."),
					meta);
				button_one.show ();
				button_one.label = _("Launch");
				last_handler = button_one.clicked.connect(() =>
					AppInfo.launch_default_for_uri_async.begin(
						uri.to_string_ign(Upg.UriFatalRanking.
							 NONFATAL_NULLABLE), null));
				break;
			}
		}

		public void internal_error (string message) {
			prebutton_box.hide ();
			button_one.hide ();
			set_message(ERROR_ICON,
				_("Uh-oh!"),
				_("Something went wrong when displaying this page."));
			site_says_box.show ();
			site_says.label = message;
			site_says_text.hide ();
		}

		public void set_message (string icon, string _title,
			string ? _description = null, string ? site_says_contents = null) {
			image.icon_name = icon;
			title.label = _title;

			description.visible = _description != null;
			description.label = _description ?? "";

			if (site_says_contents != null) {
				site_says_box.show ();
				site_says.label = site_says_contents;
			} else {
				site_says_box.hide ();
			}
		}

		public void set_prebutton_widget (Gtk.Widget widget) {
			foreach (var child in prebutton_box.get_children ()) {
				prebutton_box.remove(child);
			}

			prebutton_box.pack_start(widget);
			prebutton_box.show_all ();
		}

		public override void show_all () {
			show ();
		}
	}
}
