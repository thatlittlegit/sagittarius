/* protocol.vala
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

// not Sagittarius.File to avoid conflicts with GLib.File
namespace Sagittarius.FilePlugin {
	public class Protocol : Plugin, UriLoader {
		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(typeof (Plugin), typeof (Protocol));
		}

		public async Content fetch (Upg.Uri uri, Cancellable ? cancellable) throws Error {
			var file = File.new_for_path(uri.path_str);

			return {
					   UriLoadOutcome.SUCCESS,
					   uri,
					   new ContentType.parse((yield file.query_info_async(
						   FileAttribute.STANDARD_CONTENT_TYPE,
						   FileQueryInfoFlags.NONE,
						   100, cancellable)).get_content_type ()),
					   yield file.read_async (),
					   null
			};
		}
	}
}
