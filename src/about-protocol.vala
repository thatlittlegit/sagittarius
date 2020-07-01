/* about-protocol.vala
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

public async Sagittarius.Content about_protocol (Upg.Uri uri) {
	Sagittarius.Content response = { uri, (GeminiCode) 20, new GMime.ContentType("text", "gemini") };

	if (uri.host == null) {
		uri.host = uri.path_str.next_char ();

		if (uri.path.length () > 0) {
			uri.path = uri.path.nth(1);
		}
	}

	switch (uri.host) {
	case "blank":
		response.text = "";
		break;
	case "":
		if (uri.query_str == "dlg") {
			Idle.add(() => {
				Sagittarius.Application.show_about_dialog ();
				return false;
			});
		}
		response.text = "# %s\n%s\n\n%s"
						 .printf(_("Sagittarius"),
								 _("a browser for the Gemini protocol"),
								 _("=> about:///?dlg More Information"));
		break;
	default:
		response.code = (GeminiCode) 51;
		response.text = "Unknown URI";
		break;
	}

	return response;
}
