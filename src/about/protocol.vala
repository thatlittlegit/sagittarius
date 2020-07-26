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
	public class AboutProtocol : Plugin, UriLoader, Renderer {
		construct {
			add_loader("about", this);
			add_renderer("application/x-sagittarius-welcome", this);
		}

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PEAS_TYPE_ACTIVATABLE,
				new AboutProtocol ().get_type ()
				);
		}

		public async Content fetch (HashTable<string, Object ? > state,
			Upg.Uri _uri) {
			var uri = shift_uri(_uri);
			Content ret = { UriLoadOutcome.SUCCESS, _uri, new GMime.ContentType(
				"text", "gemini") };

			switch (uri.host) {
			case "blank":
				ret.data = new Bytes({});
				break;
			case "home":
				if (uri.query_str == null) {
					uri.query_str = "Home";
				}

				ret.data = new Bytes(Uri.unescape_string(uri.query_str).data);
				ret.content_type = new GMime.ContentType("application",
					"x-sagittarius-welcome");
				break;
			case "":
				if (uri.query_str == "dlg") {
					Idle.add(() => {
						Application.show_about_dialog ();
						return false;
					});
				}

				ret.data = new Bytes.take("# %s\n%s\n=> ?dlg %s %s"
					 .printf(_("Sagittarius"),
						_("A browser for the Gemini protocol"),
						_("_About").substring(1),
						_("Sagittarius")).data);
				break;
			default:
				ret.outcome = UriLoadOutcome.NOT_FOUND;
				ret.data =
					new Bytes(_(
						"The page you looked up isn't a valid about: URI.").data);
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

		public async RenderingOutcome render (HashTable<string,
														Object ? > state,
			NavigateFunc ? nav,
			Content content) {
			var widget = new Dazzle.EmptyState ();
			widget.title = _("Welcome to Sagittarius!");
			widget.subtitle = _("Start by typing a URL in the address bar.");
			return { bytes_to_string(content.data), widget };
		}
	}
}
