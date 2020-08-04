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
	public class TextPlugin : Plugin, PeasGtk.Configurable, Renderer {
		private Settings settings;

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				typeof (Plugin),
				typeof (TextPlugin)
				);
			module.register_extension_type(
				typeof (PeasGtk.Configurable),
				typeof (TextPlugin)
				);
		}

		construct {
			settings = new Settings(this);
			Gtk.Sourceinit ();
		}

		public Gtk.Widget create_configure_widget () {
			return settings;
		}

		public async RenderingOutcome render (HashTable<string,
														Object ? > state,
			NavigateFunc ? nav,
			Content content) {
			var buffer = new Gtk.SourceBuffer(null);
			buffer.highlight_syntax = true;
			buffer.language =
				Gtk.SourceLanguageManager.get_default ().guess_language(null,
					content.content_type.to_simple_string ());

			stream_into_buffer.begin(content, buffer, (_, ctx) => {
				try {
					stream_into_buffer.end(ctx);
				} catch (IOError err) {
					warning("%s", err.message);
				}
			});

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

		private async void stream_into_buffer (Content content,
			Gtk.TextBuffer buffer) throws
		IOError {
			var stream = new DataInputStream(content.data);
			string line;
			while ((line = yield stream.read_line_utf8_async ()) != null) {
				Gtk.TextIter iter;
				buffer.get_end_iter(out iter);
				buffer.insert(ref iter, "%s\n".printf(line), -1);
			}
		}
	}
}
