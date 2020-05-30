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
	public class ErrorMessage : Granite.Widgets.AlertView {
		private const string WARNING_ICON = "dialog-warning";
		private const string QUESTION_ICON = "dialog-question";
		private const string ERROR_ICON = "dialog-error";
		private const string SCRIPT_ICON = "text-x-script";
		private const string NETWORK_ERROR_ICON = "network-error";
		private const string NETWORK_WARNING_ICON = "network-offline";
		private const string PASSWORD_ICON = "input-keyboard";

		private Gtk.Entry text_entry = new Gtk.Entry ();
		private Gtk.Button action_button;

		public ErrorMessage () {
			Object(title: "title", description: "description", icon_name: QUESTION_ICON);

			var grid = get_children ().nth_data(0) as Gtk.Grid;
			action_button = (grid.get_child_at(2, 3) as Gtk.Revealer).get_child () as Gtk.Button;
			grid.insert_row(3);
			grid.attach(text_entry, 2, 3, 2, 1);
		}

		public void set_message_for_response (NavigateFunc navigate, Content response) {
			hide_action ();
			text_entry.hide ();
			action_button.sensitive = true;

			switch (response.code) {
			case GeminiCode.INPUT:
				icon_name = PASSWORD_ICON;
				title = _("Input wanted");
				description = _("The site asks:\n%s").printf(response.text);
				text_entry.show ();
				show_action(_("Go"));
				action_activated.connect(() => {
					try {
						var uri = uri_with_query(response.original_uri, text_entry.text);
						navigate(uri, "");
					} catch (UriError err) {
						internal_error ();
					}
				});
				return;
			case GeminiCode.PERMANENT_REDIRECT:
			case GeminiCode.TEMPORARY_REDIRECT:
				icon_name = QUESTION_ICON;
				title = _("You are being redirected");
				description = _("The website is trying to send you to %s. Would you like to go there?%s")
							   .printf(response.text, response.code == GeminiCode.PERMANENT_REDIRECT ? "\n<i>The browser will remember your decision.</i>" : "");
				show_action(_("Redirect"));
				action_activated.connect(() => { navigate(response.text, ""); });
				return;
			case GeminiCode.TEMPORARY_ERROR:
				icon_name = WARNING_ICON;
				title = _("Temporary failure");
				description = _("Something went wrong on the website. Try again later.");
				break;
			case GeminiCode.SERVER_UNAVAILABLE:
				icon_name = ERROR_ICON;
				title = _("Server unavailable");
				description = _("The server is unavailable due to overload, maintenance, or some other problem.");
				break;
			case GeminiCode.CGI_ERROR:
				icon_name = SCRIPT_ICON;
				title = _("Server script error");
				description = _("The server encountered an error when processing the request.");
				break;
			case GeminiCode.PROXY_ERROR:
				icon_name = NETWORK_ERROR_ICON;
				title = _("Proxy error");
				description = _("The server wasn't able to proxy your request.");
				break;
			case GeminiCode.SLOW_DOWN:
				icon_name = "alarm"; // XXX
				title = _("Slow down!");
				description = _("You're sending requests too fast.");
				action_button.sensitive = false;
				show_action(_("Go"));
				action_activated.connect(() => { navigate(null, response.original_uri); });

				// XXX I'm sure there's a better way to do this...
				uint64 time = get_monotonic_time () + 5000000;
				Idle.add(() => {
					if (time > get_monotonic_time ()) {
						return true;
					}

					action_button.sensitive = true;
					return false;
				});
				break;
			case GeminiCode.PERMANENT_ERROR:
				icon_name = ERROR_ICON;
				title = _("Permanent error");
				description = _("Something went wrong, and it will never work again. :(");
				break;
			case GeminiCode.NOT_FOUND:
				icon_name = WARNING_ICON;
				title = _("File not found");
				description = _("We searched far and wide\nBut it we could not find.\nIt could not be found.");
				break;
			case GeminiCode.GONE:
				icon_name = ERROR_ICON;
				title = _("G O N E");
				description = _("The file is gone.\nIt will never be back.\nWas it ever there?\nIs life but a dream?");
				break;
			case GeminiCode.PROXY_REQUEST_REFUSED:
				icon_name = NETWORK_ERROR_ICON;
				title = _("Proxy request refused");
				description = _("You asked the server to proxy a request for you, and it won't ever happen.");
				break;
			case GeminiCode.BAD_REQUEST:
				icon_name = ERROR_ICON;
				title = _("Bad request");
				description = _("Something went wrong, and the request was invalid?");
				break;
			}

			if (response.text != "") {
				description += _("\n\nThe site says: %s").printf(response.text);
			}
		}

		public void internal_error () {
			icon_name = ERROR_ICON;
			title = _("Internal Error");
			description = _("An error has occurred inside the browser, and the page could not be displayed. You might be able to go back or refresh, but you might want to restart.");
		}
	}
}
