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
	public class GeminiPlugin : Plugin {
		/* This one is a bit complicated, since Protocol and Renderer are
		 * separate classes. We can't rely on normal refcounting; the objects
		 * would be invalidated too early.
		 */
		internal static Protocol proto;
		internal static Renderer renderer;
		internal static CryptographyMessageViewer certrender;

		public override void activate () {
			if (proto == null) {
				proto = new Protocol ();
			}

			if (renderer == null) {
				renderer = new Renderer ();
			}

			if (certrender == null) {
				certrender = new CryptographyMessageViewer ();
			}

			add_loader("gemini", proto);
			add_renderer("text/gemini", renderer);
			add_renderer("application/x-gemini-certificate-response",
				certrender);

			try {
				var certdirname = Path.build_path("/",
					Environment.get_user_data_dir (), "sagittarius",
					"certificates");
				var certdir = File.new_for_path(certdirname);
				var enumerator = certdir.enumerate_children("standard::name", 0,
					null);
				while (true) {
					var info = enumerator.next_file ();

					if (info == null) {
						break;
					}

					certrender.add_certificate(Path.build_path("/", certdirname,
						info.get_attribute_byte_string("standard::name")));
				}
			} catch (Error err) {
				warning("when loading certificates: %s", err.message);
			}
		}

		public override void deactivate () {
			remove_loader("gemini", proto);
			remove_renderer("text/gemini", renderer);
			remove_renderer("application/x-gemini-certificate-response",
				certrender);
		}

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PEAS_TYPE_ACTIVATABLE,
				new GeminiPlugin ().get_type ()
				);
		}
	}
}
