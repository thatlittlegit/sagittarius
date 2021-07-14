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

	internal class History : Object {
		private List<HistoryEntry> queue;
		private int current = -1;

		internal History (ListStore global, File backed) {
			this._global = global;
			this._file = backed;
			read_from_file(backed);
		}

		construct {
			this.notify.connect((pspec) => {
				if (pspec.name == "queue") {
					changed ();
				}
			});
		}

		private ListStore _global;
		internal ListStore global {
			get {
				return _global;
			}
		}

		private File _file;
		internal File file {
			get {
				return _file;
			}
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

		public void navigate (Upg.Uri full_uri) throws Error {
			remove_all_after(current);
			current++;

			var entry = new HistoryEntry(new DateTime.now (), full_uri, null);
			queue.append(entry);
			global.append(entry);

			record_entry(queue.last ().data, file);
		}

		public static void record_entry_to_stream (HistoryEntry entry,
			OutputStream output) throws
		Error {
			var line = "%s\t%s\t%s\n".printf(
				entry.date.format("%FT%TZ"),
				entry.uri.to_string (),
				entry.title
				);

			if (!line.validate(-1)) {
				warning("data is not valid UTF-8!");
			}

			output.write(line.data);
		}

		public static void record_entry (HistoryEntry entry,
			File file) throws Error {
			record_entry_to_stream(entry, file.append_to(0));
		}

		internal static void write_out_all (ListModel list,
			File file) throws Error {
			var append = file.replace(null, false, 0);
			for (var i = 0; i < list.get_n_items (); i++) {
				record_entry_to_stream((HistoryEntry) list.get_item(i), append);
			}
		}

		public void set_top (HistoryEntry entry) {
			if (current > queue.length ()) {
				current = (int) queue.length ();
			}

			var top = queue.nth_data(current <= 0 ? 0 : current - 1);
			top.date = entry.date;
			top.uri = entry.uri;
			top.title = entry.title;
		}

		private void remove_all_after (int current) {
			while (current + 1 < queue.length ()) {
				queue.remove_link(queue.last ());
			}
		}

		public static ListStore read_from_file (File _stream) {
			ListStore ret = new ListStore(typeof (HistoryEntry));

			InputStream readstream;
			try {
				readstream = _stream.read ();
			} catch (Error err) {
				warning("%s", err.message); // TODO
				return new ListStore(typeof (HistoryEntry));
			}
			var stream = new DataInputStream(readstream);

			while (true) {
				string line;
				try {
					line = stream.read_line_utf8 ();
				} catch (IOError error) {
					warning("IOError when reading: %s", error.message);
					continue;
				}

				if (line == null) {
					break;
				}

				if (line.strip () == "" || line.has_prefix("#")) {
					continue;
				}

				var parts = line.split("\t", 3);
				try {
					ret.append(new HistoryEntry(new DateTime.from_iso8601(
						parts[0], null),
						new Upg.Uri(parts[1]),
						parts[2]));
				} catch (Error err) {
					warning("failed to make HistoryEntry for %s: %s", parts[1],
						err.message);
				}
			}

			return ret;
		}

		public bool contains (string uri) {
			foreach (var entry in queue) {
				if (uri == entry.uri.to_string ()) {
					return true;
				}
			}

			return false;
		}

		public void remove_all (string uri) {
			foreach (var entry in queue) {
				if (uri == entry.uri.to_string ()) {
					queue.remove(entry);
				}
			}
			changed ();
		}

		public signal void changed ();
	}

	internal class HistorySuggestionModel : Object, ListModel {
		private ListModel associated;
		private List<Dazzle.Suggestion> visible;

		internal HistorySuggestionModel (ListModel assoc) {
			associated = assoc;
			visible = new List<Dazzle.Suggestion>();
		}

		internal Object ? get_item(uint position) {
			return visible.nth_data(position);
		}

		internal Type get_item_type () {
			return typeof (Dazzle.Suggestion);
		}

		internal uint get_n_items () {
			return visible.length ();
		}

		internal void filter (string query) {
			var original_list_len = visible.length ();
			var filtering = new List<Dazzle.Suggestion>();

			for (var i = 0; i < associated.get_n_items (); i++) {
				var entry = (HistoryEntry) associated.get_item(i);

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
					if (already_visible.title == entry.title &&
						already_visible.subtitle == entry.subtitle) {
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
