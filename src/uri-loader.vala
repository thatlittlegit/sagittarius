/* uri-loader.vala
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
	public struct Content {
		Upg.Uri original_uri;
		GeminiCode code;
		GMime.ContentType content_type;
		string ? text; // if content_type is recognized text
		uint8[] ? data; // if content_type is not recognized
	}

	const string[] supported = { "gemini", "about" };

	async Content open_with_glib (Upg.Uri uri) {
		AppInfo.launch_default_for_uri_async.begin(uri.to_string (), null);
		return {
				   uri,
				   (GeminiCode) 20,
				   new GMime.ContentType("text", "gemini"),
				   "# URI not recognized.\nYou should've been prompted for where to open it.",
				   null
		};
	}

	public async Content fetch_uri (Upg.Uri uri) throws Error {
		switch (uri.scheme) {
		case "gemini":
			return yield get_gemini (uri);

		case "about":
			return yield about_protocol (uri);

		default:
			return yield open_with_glib (uri);
		}
	}
}
