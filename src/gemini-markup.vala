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

public Gtk.TextView parse_markup (string uri, string markup, Gtk.TextView view, NavigateFunc navigate) {
	view.buffer.set_text("");
	var preformatted = view.buffer.tag_table.lookup("pre");
	var h1 = view.buffer.tag_table.lookup("h1");
	var h2 = view.buffer.tag_table.lookup("h2");
	var h3 = view.buffer.tag_table.lookup("h3");
	var ul = view.buffer.tag_table.lookup("ul");

	var lines = markup.split("\n");

	bool preformatting = false;
	bool first = true;
	foreach (var _line in lines) {
		var line = _line.strip ();
		Gtk.TextIter iter;
		if (!first) {
			view.buffer.get_end_iter(out iter);
			view.buffer.insert(ref iter, "\n", -1);
		} else {
			first = false;
		}
		view.buffer.get_end_iter(out iter);

		if (line.has_prefix("```")) {
			preformatting = !preformatting;
		} else if (preformatting) {
			view.buffer.insert_with_tags(ref iter, line, -1, preformatted);
		} else if (line.has_prefix("=>")) {
			var line_parts = line.split("=>", 2)[1].strip ().split_set(" \t", 2);
			Gtk.LinkButton link;

			try {
				if (line_parts.length == 2) {
					link = new Gtk.LinkButton.with_label(
						parse_uri(uri, line_parts[0]),
						line_parts[1]);
				} else if (line_parts.length == 1) {
					link = new Gtk.LinkButton(parse_uri(uri, line_parts[0]));
				} else {
					view.buffer.insert(ref iter, line, -1);
					continue;
				}

				link.set_data<string>("scheme", uri_struct(link.uri).scheme);
			} catch (UriError err) {
				view.buffer.insert(ref iter, line, -1);
				continue;
			}

			link.activate_link.connect(() => {
				if (link.get_data<string>("scheme") == "gemini" || link.get_data<string>("scheme") == "about") {
					navigate(uri, link.uri);
					return true;
				}
				return false;
			});
			link.show ();

			var anchor = view.buffer.create_child_anchor(iter);
			view.add_child_at_anchor(link, anchor);
		} else if (line.has_prefix("# ")) {
			view.buffer.insert_with_tags(ref iter, line.substring(2), -1, h1);
		} else if (line.has_prefix("## ")) {
			view.buffer.insert_with_tags(ref iter, line.substring(3), -1, h2);
		} else if (line.has_prefix("###")) {
			view.buffer.insert_with_tags(ref iter, line.substring(4), -1, h3);
		} else if (line.has_prefix("*")) {
			view.buffer.insert_with_tags(ref iter, "\t\u2022\t%s".printf(line.substring(1).strip ()), -1, ul);
		} else {
			view.buffer.insert(ref iter, line, -1);
		}
	}

	return view;
}
