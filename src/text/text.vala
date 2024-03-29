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
				typeof (Plugin),
				typeof (TextPlugin)
				);
		}

		construct {
			Gtk.Sourceinit ();
		}

		public async Gtk.Widget render (NavigateFunc ? nav, Content content, Cancellable ? cancel, LoadingTrigger ? trigger) {
			var buffer = new Gtk.SourceBuffer(null);
			buffer.highlight_syntax = true;
			buffer.language =
				Gtk.SourceLanguageManager.get_default ().guess_language(null,
					content.content_type.to_simple_string ());

			stream_into_buffer.begin(content, buffer, cancel, (_, ctx) => {
				try {
					stream_into_buffer.end(ctx);
					trigger.trigger ();
				} catch (IOError err) {
					trigger.warning(err.message);
				}
			});

			var widget = new Gtk.SourceView.with_buffer(buffer);
			widget.monospace = true;
			widget.editable = false;
			widget.top_margin = widget.left_margin = widget.right_margin =
				widget.bottom_margin = 16;
			widget.cursor_visible = false;

			return widget;
		}

		private async void stream_into_buffer (Content content,
			Gtk.TextBuffer buffer, Cancellable cancel) throws
		IOError {
			var stream = new DataInputStream(content.data);
			string line;
			while ((line =
						yield stream.read_line_utf8_async(100,
							cancel)) != null && !cancel.is_cancelled ()) {
				Gtk.TextIter iter;
				buffer.get_end_iter(out iter);
				buffer.insert(ref iter, "%s\n".printf(line), -1);
			}
		}
	}
}
