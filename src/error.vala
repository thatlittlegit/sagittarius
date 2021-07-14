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
		private unowned Gtk.Image image;
		[GtkChild]
		private unowned Gtk.Label title;
		[GtkChild]
		private unowned Gtk.Label description;
		[GtkChild]
		private unowned Gtk.Box site_says_box;
		[GtkChild]
		private unowned Gtk.Label site_says_text;
		[GtkChild]
		private unowned Gtk.Label site_says;
		[GtkChild]
		private unowned Gtk.Button button { get; private set; }
		[GtkChild]
		private unowned Gtk.Box prebutton_box;

		public ErrorMessage () {
		}

		private ulong last_handler = 0;

		public void set_message_for_response (NavigateFunc navigate,
			int code, string meta, Upg.Uri uri) {
			prebutton_box.hide ();
			button.hide ();
			button.sensitive = true;
			site_says_text.show ();

			if (last_handler != 0) {
				SignalHandler.disconnect(button, last_handler);
			}

			switch (code) {
			case UriLoadOutcome.TEXT_INPUT_WANTED:
			case UriLoadOutcome.SENSITIVE_INPUT_WANTED:
				set_message(PASSWORD_ICON, _("Input wanted"), null, meta);
				button.show ();
				button.label = _("Go");
				Gtk.Entry text_entry = new Gtk.Entry ();
				if (code == UriLoadOutcome.SENSITIVE_INPUT_WANTED) {
					text_entry.visibility = false;
					text_entry.input_purpose = Gtk.InputPurpose.PASSWORD;
				}
				set_prebutton_widget(text_entry);
				last_handler = button.clicked.connect(() => {
					uri.query_str = text_entry.text;
					button.sensitive = false;
					navigate(uri);
				});
				break;
			case UriLoadOutcome.SUCCESS:
				set_message("weather-clear", _("Success!"),
					_("Everything worked, except the programmer's brain when they were writing this."));
				break;
			case UriLoadOutcome.PERMANENT_REDIRECT:
			case UriLoadOutcome.TEMPORARY_REDIRECT:
				set_message(QUESTION_ICON,
					_("You are being redirected"),
					_("The website is trying to send you to %s. Would you like to go there?").printf(meta),
					meta);

				Upg.Uri destination;
				try {
					destination = uri.apply_reference(meta);
				} catch (Error err) {
					internal_error(err.message);
					return;
				}

				button.show ();
				button.label = _("Redirect");
				last_handler = button.clicked.connect(() => navigate(destination));
				return;
			case UriLoadOutcome.TEMPORARY_ERROR:
				set_message(WARNING_ICON, _("Temporary failure"),
					_("Something went wrong with the website. Try again later."),
					meta);
				break;
			case UriLoadOutcome.SERVER_UNAVAILABLE:
				set_message(ERROR_ICON, _("Server unavailable"),
					_("The server is unavailable due to overload, maintenance, or some other problem. Try again later."),
					meta);
				break;
			case UriLoadOutcome.CGI_ERROR:
				set_message(SCRIPT_ICON, _("Server script error"),
					_("The server encountered an error when processing your request."),
					meta);
				break;
			case UriLoadOutcome.PROXY_ERROR:
				set_message(NETWORK_ERROR_ICON, _("Proxy error"),
					_("The server wasn't able to proxy your request."), meta);
				break;
			case UriLoadOutcome.SLOW_DOWN:
				set_message(ALARM_ICON, _("Slow down!"),
					_("You're sending requests too fast."), meta);
				button.show ();
				button.sensitive = false;
				button.label = _("Go");
				last_handler = button.clicked.connect(() => navigate(uri));

				Timeout.add(5000, () => {
					button.sensitive = true;
					return false;
				});
				break;
			case UriLoadOutcome.PERMANENT_ERROR:
				set_message(ERROR_ICON, _("Permanent error"),
					_("Something went wrong, and it will never work again. :("),
					meta);
				break;
			case UriLoadOutcome.NOT_FOUND:
				set_message(WARNING_ICON,
					_("File not found"),
					_("We searched far and wide\nBut it we could not find.\nIt could not be found."),
					meta);
				break;
			case UriLoadOutcome.GONE:
				set_message(ERROR_ICON, _("G O N E"),
					_("The file is gone.\nIt will never be back.\nWas it ever there?\nIs life but a dream?"),
					meta);
				break;
			case UriLoadOutcome.PROXY_REQUEST_REFUSED:
				set_message(NETWORK_ERROR_ICON, _("Proxy request refused"),
					_("You asked the server to proxy a request for you, but the server won't do that."),
					meta);
				break;
			case UriLoadOutcome.BAD_REQUEST:
				set_message(ERROR_ICON, _("Bad request"),
					_("Something went wrong, and the request was invalid?"),
					meta);
				break;
			case UriLoadOutcome.UNKNOWN_SCHEME:
				// TODO in future, might be nice to have a proper app chooser
				set_message(INFO_ICON, _("Huh?"),
					_("We don't know how to open this URI, but you can try opening it with something else."));
				button.show ();
				button.label = _("Launch");
				last_handler =
					button.clicked.connect(() => AppInfo.launch_default_for_uri_async.begin(uri.to_string (), null));
				break;
			}
		}

		public void internal_error (string message) {
			prebutton_box.hide ();
			button.hide ();
			set_message(ERROR_ICON,
				_("Uh-oh!"),
				_("Something went wrong when displaying this page."));
			site_says_box.show ();
			site_says.label = message;
			site_says_text.hide ();
		}

		public void set_message (string icon, string _title, string ? _description = null,
			string ? site_says_contents = null) {
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
