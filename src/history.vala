/* history.vala
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
	public class HistoryEntry : Object {
		public DateTime date;
		public Upg.Uri uri;
		public string title;

		public HistoryEntry (DateTime ? a, Upg.Uri b, string ? c) {
			date = a ?? new DateTime.from_unix_utc(0);
			uri = b;
			title = c ?? b.to_string ();
		}
	}

	public class History {
		private List<HistoryEntry> queue;
		private int current = -1;
		private History ? parent;

		// FIXME we should use an OutputStream, but it gets closed too early
		// 'cause Vala can't figure out that the OS is a substream of the IOS.
		private IOStream file;

		public History (History ? parent) {
			this.parent = parent;
		}

		public History.with_file(History ? parent, IOStream backed) {
			this.parent = parent;
			this.file = backed;

			read_from_file(backed.get_input_stream ());
		}

		public List<HistoryEntry> history {
			get {
				return queue;
			}
		}

		public int pos {
			get {
				return current;
			}
			set {
				if (value < queue.length ()) {
					current = value;
				}
			}
		}

		public bool can_go_back {
			get {
				return current > 0;
			}
		}

		public bool can_go_forward {
			get {
				return current + 1 < queue.length ();
			}
		}

		public void back () {
			current--;
		}

		public void forward () {
			if (current + 1 < queue.length ()) {
				current++;
			}
		}

		public HistoryEntry top () {
			return queue.nth_data(current);
		}

		public void navigate (Upg.Uri full_uri) {
			remove_all_after(current);
			current++;
			queue.append(new HistoryEntry(null, full_uri, null));

			if (parent != null) {
				parent.navigate(full_uri);
			}
		}

		public void record (DateTime now, Upg.Uri full_uri, string title) throws IOError {
			record_entry(new HistoryEntry(now, full_uri, title));
		}

		public void record_entry (HistoryEntry entry) throws IOError {
			if (parent != null) {
				parent.record_entry(entry);
				return;
			}

			if (file != null) {
				file.get_output_stream ().write(entry.date.format("%FT%TZ").data);
				file.get_output_stream ().write("\t".data);
				file.get_output_stream ().write(entry.uri.to_string ().data);
				file.get_output_stream ().write("\t".data);
				file.get_output_stream ().write(entry.title.data);
				file.get_output_stream ().write("\n".data);
			}
		}

		public void set_top (HistoryEntry entry) {
			var top = queue.nth_data(current < 0 ? 0 : current);
			top.date = entry.date;
			top.uri = entry.uri;
			top.title = entry.title;
		}

		private void remove_all_after (int current) {
			while (current + 1 < queue.length ()) {
				queue.remove_link(queue.last ());
			}
		}

		private void read_from_file (InputStream _stream) {
			var stream = new DataInputStream(_stream);

			string line;
			try {
				while (true) {
					line = stream.read_line_utf8 ();

					if (line == null) {
						break;
					}

					if (line.strip () == "" || line.has_prefix("#")) {
						continue;
					}

					var parts = line.split("\t", 3);
					queue.append(new HistoryEntry(new DateTime.from_iso8601(parts[0], new TimeZone.utc ()),
												  new Upg.Uri(parts[1]),
												  parts[2]));
				}
			} catch (Error err) {
				warning(err.message);
			}
		}
	}

	public class HistorySuggestionModel : Object, ListModel {
		private History associated;
		private List<Dazzle.Suggestion> visible;

		public HistorySuggestionModel (History assoc) {
			associated = assoc;
			visible = new List<Dazzle.Suggestion>();
		}

		public Object ? get_item(uint position) {
			return visible.nth_data(position);
		}

		public Type get_item_type () {
			return new Dazzle.Suggestion ().get_type ();
		}

		public uint get_n_items () {
			return visible.length ();
		}

		public void filter (string query) {
			var original_list_len = visible.length ();
			var filtering = new List<Dazzle.Suggestion>();

			foreach (var entry in associated.history) {
				var levenshtein = Dazzle.levenshtein(query, entry.title);
				var suggestion = new Dazzle.Suggestion ();
				suggestion.title = entry.title;
				suggestion.subtitle = entry.uri.to_string ();
				suggestion.set_data<int>("weight", levenshtein);
				suggestion.set_data<Upg.Uri>("uri", entry.uri);
				filtering.prepend(suggestion);
			}
			filtering.sort((a, b) => {
				return a.get_data<int>("weight") - b.get_data<int>("weight");
			});

			var counter = 0;
			visible = new List<Dazzle.Suggestion>();
			foreach (var entry in filtering) {
				var ok = true;
				foreach (var already_visible in visible) {
					if (already_visible.title == entry.title && already_visible.subtitle == entry.subtitle) {
						ok = false;
						break;
					}
				}

				if (counter < 10 && ok) {
					visible.append(entry);
				}
				counter++;
			}

			items_changed(0, original_list_len, visible.length ());
		}
	}
}
