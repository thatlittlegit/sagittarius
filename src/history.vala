/* history.vala
 *
 * Copyright 2020-2021 thatlittlegit <personal@thatlittlegit.tk>
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

		public HistoryEntry ? parent;

		public HistoryEntry (HistoryEntry ? a, DateTime ? b, Upg.Uri c, string ? d) {
			parent = a;
			date = b ?? new DateTime.from_unix_utc(0);
			uri = c;
			title = d ?? c.to_string ();
		}
	}

	internal class History : Object {
		public Library library { private get; construct; }

		internal History (Library library) {
			Object(library: library);
		}

		public HistoryEntry current { get; private set; }
		private HistoryEntry top;

		public List<HistoryEntry> history {
			owned get {
				var list = new List<HistoryEntry>();
				this.@foreach((entry) => list.prepend(entry));
				list.reverse ();
				return (owned) list;
			}
		}

		public int position {
			get {
				var count = 0;

				foreach (var entry in history) {
					if (entry == current) {
						break;
					}

					count++;
				}

				return count;
			}
			set {
				current = history.nth_data(value);
			}
		}

		public bool can_go_back {
			get {
				return current != null && current.parent != null;
			}
		}

		public bool can_go_forward {
			get {
				return top != current;
			}
		}

		private void @foreach (Func<HistoryEntry> func) {
			if (top == null) {
				return;
			}

			HistoryEntry processing = top;
			do {
				func(processing);
			} while ((processing = processing.parent) != null);
		}

		public void back () {
			if (current != null) {
				current = current.parent;
			}
		}

		public void forward () {
			foreach (var entry in history) {
				if (entry.parent == current) {
					current = entry;
					break;
				}
			}
		}

		public void navigate (Upg.Uri uri) {
			var date = new DateTime.now ();

			var entry = new HistoryEntry(current, date, uri, null);
			top = current = entry;

			library.add_entry(new LibraryEntry(date, uri, null));
		}
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
				var entry = (LibraryEntry) associated.get_item(i);

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
