/* gemini-markup.vala
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

using Sagittarius;

namespace Sagittarius.Gemini {
	public class Renderer : Object, Sagittarius.Renderer {
		public async Gtk.Widget render (NavigateFunc ? nav, Content content, Cancellable ? cancel, LoadingTrigger ? trigger)
		throws Error {
			content.data = new ConverterInputStream(content.data,
				new CharsetConverter(content.content_type.charset ?? "utf-8",
					"utf-8"));

			var view = make_new_textview ();
			display_markup.begin(content, view, nav, cancel, trigger, (_, ctx) => {
				try {
					display_markup.end(
						ctx);
				} catch (IOError err) {
					trigger.warning(err.message);
				}
			});

			return view;
		}
	}

	Gtk.TextView make_new_textview () {
		var text_view = new Gtk.TextView ();
		text_view.wrap_mode = Gtk.WrapMode.WORD;
		var tabstops = new Pango.TabArray.with_positions(2, true,
			Pango.TabAlign.LEFT, 8,
			Pango.TabAlign.LEFT,
			16);
		text_view.buffer.create_tag("pre", "family", "monospace", "wrap-mode",
			Gtk.WrapMode.NONE);
		text_view.buffer.create_tag("h1", "weight", 600, "size-points", 26.0,
			"size-set", true);
		text_view.buffer.create_tag("h2", "weight", 500, "size-points", 22.0,
			"size-set", true);
		text_view.buffer.create_tag("h3", "weight", 400, "size-points", 18.0,
			"size-set", true);
		text_view.buffer.create_tag("ul", "tabs", tabstops);
		text_view.buffer.create_tag("blockquote", "family", "cursive",
			"style", Pango.Style.ITALIC, "left-margin", 64, "left-margin-set",
			true);
		text_view.top_margin = text_view.bottom_margin =
			text_view.right_margin = text_view.left_margin = 16;
		text_view.editable = false;
		return text_view;
	}

	Gtk.TextIter get_iter (Gtk.TextBuffer buf) {
		Gtk.TextIter iter;
		buf.get_end_iter(out iter);
		return iter;
	}

	private async void display_markup (Content markup, Gtk.TextView view,
		NavigateFunc nav, Cancellable ? cancel,
		LoadingTrigger ? trigger) throws IOError {
		var buffer = view.buffer;
		var preformatted = buffer.tag_table.lookup("pre");
		var h1 = buffer.tag_table.lookup("h1");
		var h2 = buffer.tag_table.lookup("h2");
		var h3 = buffer.tag_table.lookup("h3");
		var ul = buffer.tag_table.lookup("ul");
		var blockquote = buffer.tag_table.lookup("blockquote");

		string title = null;

		bool preformatting = false;
		var stream = new DataInputStream(markup.data);
		string line;
		while ((line =
					yield stream.read_line_utf8_async(100,
						cancel)) != null && !cancel.is_cancelled ()) {
			var iter = get_iter(buffer);

			if (line.has_prefix("```")) {
				preformatting = !preformatting;
			} else if (preformatting) {
				buffer.insert_with_tags(ref iter, line, -1,
					preformatted);
			} else if (line.has_prefix("=>")) {
				output_link(ref iter, line, view, markup.original_uri, nav);
			} else if (line.has_prefix("# ")) {
				if (title == null) {
					title = line.substring(2);
				}
				buffer.insert_with_tags(ref iter, line.substring(2), -1, h1);
			} else if (line.has_prefix("## ")) {
				buffer.insert_with_tags(ref iter, line.substring(3), -1, h2);
			} else if (line.has_prefix("###")) {
				buffer.insert_with_tags(ref iter, line.substring(4), -1, h3);
			} else if (line.has_prefix("*")) {
				buffer.insert_with_tags(ref iter,
					"\t\u2022\t%s".printf(line.substring(1).strip ()), -1, ul);
			} else if (line.has_prefix(">")) {
				buffer.insert_with_tags(ref iter, line.substring(
					1).strip (), -1,
					blockquote);
			} else {
				buffer.insert(ref iter, line, -1);
			}

			iter = get_iter(buffer);
			buffer.insert(ref iter, "\n", -1);
		}

		trigger.trigger(title);
	}

	private void output_link (ref Gtk.TextIter iter, string line,
		Gtk.TextView view, Upg.Uri uri,
		NavigateFunc nav) {
		var line_parts = line.split("=>", 2)[1].strip ().split_set(
			" \t", 2);

		var btn = new Gtk.LinkButton.with_label(line_parts[0],
			line_parts[1] ?? line_parts[0]);

		try {
			var destination =
				uri.apply_reference(line_parts[0]);

			btn.activate_link.connect((button) => {
				nav(destination);
				return true;
			});
		} catch (Error err) {
			btn.sensitive = false;
		}

		view.add_child_at_anchor(btn,
			view.buffer.create_child_anchor(iter));
		btn.show ();
	}
}
