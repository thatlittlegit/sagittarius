/* plugin.vala
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

namespace Sagittarius.Gemini {
	public class GeminiPlugin : Plugin, UriLoader, Sagittarius.Renderer {
		internal Protocol protocol;
		internal Renderer renderer;
		internal CryptographyMessageViewer cmv;

		construct {
			protocol = new Protocol ();
			renderer = new Renderer ();
			cmv = new CryptographyMessageViewer ();
		}

		public async Content fetch (Upg.Uri uri, Cancellable ? cancel) throws Error {
			return yield protocol.fetch (uri, cancel);
		}

		public async Gtk.Widget render (NavigateFunc ? nav, Content content, Cancellable ? cancel, LoadingTrigger ? trigger) throws Error {
			if (content.content_type.subtype ==
				"x-gemini-certificate-response") {
				return yield cmv.render (nav, content, cancel, trigger);
			}

			return yield renderer.render (nav, content, cancel, trigger);
		}

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				typeof (Plugin),
				typeof (GeminiPlugin)
				);
		}
	}
}
