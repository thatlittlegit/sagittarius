/* proto-about.vala
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Sagittarius;

namespace Sagittarius.AboutProtocol {
	public class AboutProtocol : Object, Peas.Activatable {
		public Object object { owned get; construct; }
		public UriLoader about_loader;

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PEAS_TYPE_ACTIVATABLE,
				new AboutProtocol ().get_type ()
				);
		}

		public void activate () {
			about_loader = new AboutLoader ();
			add_loader("about", about_loader);
			add_loader("sagittarius", about_loader);
		}

		public void deactivate () {
			remove_loader("about", about_loader);
		}

		public void update_state () {
		}
	}

	public class AboutLoader : Object, UriLoader {
		public AboutLoader () {
		}

		public async Content fetch (Upg.Uri _uri) {
			var uri = shift_uri(_uri);
			Content ret = { _uri, GeminiCode.SUCCESS, new GMime.ContentType("text", "gemini") };

			switch (uri.host) {
			case "blank":
				ret.text = "";
				break;
			case "":
				if (uri.query_str == "dlg") {
					Idle.add(() => {
						Application.show_about_dialog ();
						return false;
					});
				}

				ret.text = "# %s\n%s\n=> ?dlg %s %s"
							.printf(_("Sagittarius"),
									_("A browser for the Gemini protocol"),
									_("_About").substring(1),
									_("Sagittarius"));
				break;
			default:
				ret.code = GeminiCode.NOT_FOUND;
				ret.text = _("The page you looked up isn't a valid about: URI.");
				break;
			}

			return ret;
		}

		private Upg.Uri shift_uri (Upg.Uri uri) {
			if (uri.host == null) {
				if (uri.path != null) {
					uri.host = uri.path_str.next_char ();

					if (uri.path.length () > 0) {
						uri.path = uri.path.nth(1);
					}
				} else {
					uri.host = "";
				}
			}

			return uri;
		}
	}
}
