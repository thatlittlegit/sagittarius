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

namespace Sagittarius.GeminiRenderer {
	public class GeminiRendererPlugin : Object, Peas.Activatable {
		public Object object { owned get; construct; }
		public Renderer gemini_renderer;

		[CCode(cname = "peas_register_types")]
		public static void peas_register_types (Peas.ObjectModule module) {
			module.register_extension_type(
				PEAS_TYPE_ACTIVATABLE,
				new GeminiRendererPlugin ().get_type ()
				);
		}

		public void activate () {
			gemini_renderer = new GeminiRenderer ();
			add_renderer("text/gemini", gemini_renderer);
		}

		public void deactivate () {
			remove_renderer("text/gemini", gemini_renderer);
		}

		public void update_state () {
		}
	}

	public class GeminiRenderer : Object, Renderer {
		public async RenderingOutcome render (NavigateFunc ? nav, Content content) {
			var markup = yield parse_markup (content.original_uri, content.data);

			var widget = yield display_markup (markup, nav);

			RenderingOutcome ret = {};
			ret.title = markup.title ?? content.original_uri.to_string ();
			ret.widget = widget;
			return ret;
		}
	}

	enum TagType {
		TEXT,
		H1,
		H2,
		H3,
		PREFORMATTED,
		LIST_ITEM,
		LINK,
		BROKEN_LINK,
		BLOCKQUOTE,
	}

	struct Tag {
		TagType type;
		string contents;
		Upg.Uri ? target;
		string ? auxillary;
	}

	class Document {
		public string ? title;
		public List<Tag ? > tags;
	}

	Gtk.TextView make_new_textview () {
		var text_view = new Gtk.TextView ();
		text_view.wrap_mode = Gtk.WrapMode.WORD;
		var tabstops = new Pango.TabArray.with_positions(2, true, Pango.TabAlign.LEFT, 8, Pango.TabAlign.LEFT, 16);
		text_view.buffer.create_tag("pre", "family", "monospace", "wrap-mode", Gtk.WrapMode.NONE);
		text_view.buffer.create_tag("h1", "weight", 600, "size-points", 26.0, "size-set", true);
		text_view.buffer.create_tag("h2", "weight", 500, "size-points", 22.0, "size-set", true);
		text_view.buffer.create_tag("h3", "weight", 400, "size-points", 18.0, "size-set", true);
		text_view.buffer.create_tag("ul", "tabs", tabstops);
		text_view.buffer.create_tag("blockquote", "family", "cursive",
									"style", Pango.Style.ITALIC, "left-margin", 64, "left-margin-set", true);
		text_view.top_margin = text_view.bottom_margin = text_view.right_margin = text_view.left_margin = 16;
		text_view.editable = false;
		return text_view;
	}

	Gtk.TextIter get_iter (Gtk.TextBuffer buf) {
		Gtk.TextIter iter;
		buf.get_end_iter(out iter);
		return iter;
	}

	async Gtk.TextView display_markup (Document markup, NavigateFunc nav) {
		var view = make_new_textview ();
		var preformatted = view.buffer.tag_table.lookup("pre");
		var h1 = view.buffer.tag_table.lookup("h1");
		var h2 = view.buffer.tag_table.lookup("h2");
		var h3 = view.buffer.tag_table.lookup("h3");
		var ul = view.buffer.tag_table.lookup("ul");
		var blockquote = view.buffer.tag_table.lookup("blockquote");

		bool first = true;
		foreach (var tag in markup.tags) {
			var iter = get_iter(view.buffer);

			if (!first) {
				view.buffer.insert(ref iter, "\n", -1);
				iter = get_iter(view.buffer);
			} else {
				first = false;
			}

			switch (tag.type) {
			case TagType.TEXT:
				view.buffer.insert(ref iter, tag.contents, -1);
				break;
			case TagType.PREFORMATTED:
				view.buffer.insert_with_tags(ref iter, tag.contents, -1, preformatted);
				break;
			case TagType.H1:
				view.buffer.insert_with_tags(ref iter, tag.contents, -1, h1);
				break;
			case TagType.H2:
				view.buffer.insert_with_tags(ref iter, tag.contents, -1, h2);
				break;
			case TagType.H3:
				view.buffer.insert_with_tags(ref iter, tag.contents, -1, h3);
				break;
			case TagType.LIST_ITEM:
				view.buffer.insert_with_tags(ref iter, "\t\u2022\t%s".printf(tag.contents), -1, ul);
				break;
			case TagType.LINK:
			case TagType.BROKEN_LINK:
				var btn = new Gtk.LinkButton.with_label(tag.contents, tag.auxillary);
				btn.activate_link.connect((button) => {
					nav(tag.target);
					return true;
				});

				if (tag.type == TagType.BROKEN_LINK) {
					btn.sensitive = false;
				}

				view.add_child_at_anchor(btn, view.buffer.create_child_anchor(iter));
				btn.show ();
				break;
			case TagType.BLOCKQUOTE:
				view.buffer.insert_with_tags(ref iter, tag.contents, -1, blockquote);
				break;
			}
		}

		return view;
	}

	async Document parse_markup (Upg.Uri original_uri, Bytes _markup) {
		Document output = new Document ();
		var markup = bytes_to_string(_markup);
		var lines = markup.split("\n");

		bool preformatting = false;
		foreach (var _line in lines) {
			var line = _line.strip ();

			if (line.has_prefix("```")) {
				preformatting = !preformatting;
			} else if (preformatting) {
				output.tags.prepend({ TagType.PREFORMATTED, line, null });
			} else if (line.has_prefix("=>")) {
				var line_parts = line.split("=>", 2)[1].strip ().split_set(" \t", 2);

				try {
					var destination = original_uri.apply_reference(line_parts[0]);
					output.tags.prepend({ TagType.LINK, "", destination, line_parts[1] ?? line_parts[0] });
				} catch (Error err) {
					output.tags.prepend({ TagType.BROKEN_LINK, "", null, line_parts[1] });
				}
			} else if (line.has_prefix("# ")) {
				if (output.title == null) {
					output.title = line.substring(2);
				}
				output.tags.prepend({ TagType.H1, line.substring(2) });
			} else if (line.has_prefix("## ")) {
				output.tags.prepend({ TagType.H2, line.substring(3) });
			} else if (line.has_prefix("###")) {
				output.tags.prepend({ TagType.H3, line.substring(4) });
			} else if (line.has_prefix("*")) {
				output.tags.prepend({ TagType.LIST_ITEM, line.substring(1).strip () });
			} else if (line.has_prefix(">")) {
				output.tags.prepend({ TagType.BLOCKQUOTE, line.substring(1).strip () });
			} else {
				output.tags.prepend({ TagType.TEXT, line });
			}
		}
		output.tags.reverse ();

		return output;
	}
}
