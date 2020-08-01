/* text.vala
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

namespace Sagittarius.Text {
	public class TextPlugin : Plugin, Renderer {
		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PluginType,
				new TextPlugin ().get_type ()
				);
		}

		construct {
			add_renderer("text/plain", this);
			add_renderer("text/x-perl", this);
			Gtk.Sourceinit ();
		}

		public async RenderingOutcome render (HashTable<string,
														Object ? > state,
			NavigateFunc ? nav,
			Content content) {
			var buffer = new Gtk.SourceBuffer(null);
			buffer.highlight_syntax = true;
			buffer.language =
				Gtk.SourceLanguageManager.get_default ().guess_language(null,
					content.content_type.get_mime_type ());
			buffer.set_text(bytes_to_string(content.data));

			var widget = new Gtk.SourceView.with_buffer(buffer);
			widget.monospace = true;
			widget.editable = false;
			widget.top_margin = widget.left_margin = widget.right_margin =
				widget.bottom_margin = 16;
			widget.cursor_visible = false;

			return {
					   null,
					   widget,
			};
		}
	}
}
