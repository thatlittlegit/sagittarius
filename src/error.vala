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
		private Gtk.Label site_says;
		[GtkChild]
		private Gtk.Button button_one;
		[GtkChild]
		private Gtk.Entry text_entry;

		public ErrorMessage () {
		}

		private ulong last_handler = 0;

		public void set_message_for_response (NavigateFunc navigate, Content response) {
			text_entry.hide ();
			button_one.hide ();
			button_one.sensitive = true;

			if (last_handler != 0) {
				SignalHandler.disconnect(button_one, last_handler);
			}

			switch (response.outcome) {
			case UriLoadOutcome.TEXT_INPUT_WANTED:
				set_message(PASSWORD_ICON, _("Input wanted"), null);
				button_one.show ();
				button_one.label = _("Go");
				text_entry.show ();
				last_handler = button_one.clicked.connect(() => {
					response.original_uri.query_str = text_entry.text;
					navigate(response.original_uri);
				});
				break;
			case UriLoadOutcome.SUCCESS:
				set_message("weather-clear", _("Success!"), _("Everything worked, except the programmer's brain when they were writing this."));
				button_one.hide ();
				return;
			case UriLoadOutcome.PERMANENT_REDIRECT:
			case UriLoadOutcome.TEMPORARY_REDIRECT:
				set_message(QUESTION_ICON,
							_("You are being redirected"),
							_("The website is trying to send you to %s. Would you like to go there?").printf((string) Bytes.unref_to_data(response.data)));

				Upg.Uri destination;
				try {
					destination = response.original_uri.apply_reference((string) Bytes.unref_to_data(response.data));
				} catch (Error err) {
					internal_error(err.message);
					return;
				}

				button_one.show ();
				button_one.label = _("Redirect");
				last_handler = button_one.clicked.connect(() => navigate(destination));
				return;
			case UriLoadOutcome.TEMPORARY_ERROR:
				set_message(WARNING_ICON, _("Temporary failure"), _("Something went wrong with the website. Try again later."));
				break;
			case UriLoadOutcome.SERVER_UNAVAILABLE:
				set_message(ERROR_ICON, _("Server unavailable"),
							_("The server is unavailable due to overload, maintenance, or some other problem. Try again later."));
				break;
			case UriLoadOutcome.CGI_ERROR:
				set_message(SCRIPT_ICON, _("Server script error"),
							_("The server encountered an error when processing your request."));
				break;
			case UriLoadOutcome.PROXY_ERROR:
				set_message(NETWORK_ERROR_ICON, _("Proxy error"),
							_("The server wasn't able to proxy your request."));
				break;
			case UriLoadOutcome.SLOW_DOWN:
				set_message(ALARM_ICON, _("Slow down!"),
							_("You're sending requests too fast."));
				button_one.show ();
				button_one.sensitive = false;
				button_one.label = _("Go");
				last_handler = button_one.clicked.connect(() => navigate(response.original_uri));

				Timeout.add(5000, () => {
					button_one.sensitive = true;
					return false;
				});
				break;
			case UriLoadOutcome.PERMANENT_ERROR:
				set_message(ERROR_ICON, _("Permanent error"),
							_("Something went wrong, and it will never work again. :("));
				break;
			case UriLoadOutcome.NOT_FOUND:
				set_message(WARNING_ICON,
							_("File not found"),
							_("We searched far and wide\nBut it we could not find.\nIt could not be found."));
				break;
			case UriLoadOutcome.GONE:
				set_message(ERROR_ICON, _("G O N E"),
							_("The file is gone.\nIt will never be back.\nWas it ever there?\nIs life but a dream?"));
				break;
			case UriLoadOutcome.PROXY_REQUEST_REFUSED:
				set_message(NETWORK_ERROR_ICON, _("Proxy request refused"),
							_("You asked the server to proxy a request for you, but the server won't do that."));
				break;
			case UriLoadOutcome.BAD_REQUEST:
				set_message(ERROR_ICON, _("Bad request"),
							_("Something went wrong, and the request was invalid?"));
				break;
			}

			if (response.data.length > 0) {
				site_says_box.show ();
				site_says.label = (string) Bytes.unref_to_data(response.data);
			} else {
				site_says_box.hide ();
			}
		}

		public void internal_error (string message) {
			text_entry.hide ();
			button_one.hide ();
			set_message(ERROR_ICON,
						_("Internal Error"),
						_("An error has occurred inside the browser, and the page could not be displayed. You might be able to go back or refresh, but you might want to restart.\n\nThe error is: %s").printf(message));
		}

		private void set_message (string icon, string _title, string ? _description = null) {
			image.icon_name = icon;
			title.label = _title;

			description.visible = _description != null;
			description.label = _description ?? "";

			site_says_box.hide ();
		}
	}
}
