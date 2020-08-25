/* library.vala
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

namespace Sagittarius {
	[GtkTemplate(ui = "/tk/thatlittlegit/sagittarius/library.ui")]
	internal class LibraryWindow : Gtk.Window {
		public History history { private get; construct; }
		public History bookmarks { private get; construct; }

		[GtkChild]
		private Gtk.Stack listbox_stack;
		[GtkChild]
		private Gtk.Grid info_grid;
		[GtkChild]
		private Gtk.Label entry_title;
		[GtkChild]
		private Gtk.Entry uri;
		[GtkChild]
		private Gtk.Label visited_date;

		private UriListBox history_listbox;
		private UriListBox bookmarks_listbox;

		public LibraryWindow (History history, History bookmarks) {
			Object(history: history, bookmarks: bookmarks);
		}

		construct {
			history_listbox = new UriListBox(history);
			listbox_stack.add_titled(history_listbox, "history", _("History"));
			history_listbox.selection_changed.connect(selection_changed_handler);

			bookmarks_listbox = new UriListBox(bookmarks);
			listbox_stack.add_titled(bookmarks_listbox, "bookmarks", _(
				"Bookmarks"));
			bookmarks_listbox.selection_changed.connect(
				selection_changed_handler);
		}

		private void selection_changed_handler (Gtk.ListBoxRow ? selected_row) {
			if (selected_row == null) {
				info_grid.sensitive = false;
				entry_title.label = "";
				uri.text = "";
				visited_date.label = "";
				return;
			}

			var entry = selected_row.get_data<HistoryEntry>("entry");
			info_grid.sensitive = true;
			entry_title.label = entry.title;
			uri.text = entry.uri.to_string_ign(
				Upg.UriFatalRanking.NONFATAL_NULLABLE);
			visited_date.label = entry.date.format("%x %X%:z");
		}
	}

	private class UriListBox : Gtk.ListBox {
		public History list { private get; construct; }

		public UriListBox (History list) {
			Object(list: list);
		}

		construct {
			row_selected.connect(() => {
				selection_changed(get_selected_row ());
			});
			update ();

			list.changed.connect(() => update ());
		}

		public void update () {
			foreach (var child in get_children ()) {
				remove(child);
			}

			foreach (var entry in list.history.last ().nth_prev(uint.min(
				list.history.length () - 1, 100))) {
				var widget =
					new ConfigurationEntry(entry.uri.to_string_ign(Upg.
						 UriFatalRanking
						 .NONFATAL_NEVERNULL));

				var _entry = entry;
				widget.set_data<HistoryEntry>("entry", _entry);

				widget.deleted.connect(() => {
					// HACK valac bug, can't do list.history.remove
					unowned List<HistoryEntry> list_history = list.history;
					list_history.remove(
						_entry);

					try {
						list.write_out_all ();
					} catch (Error err) {
						warning("%s", err.message); // TODO
					}
					update ();
				});

				add(widget);
				((MainContext) null).iteration(false);
			}

			show_all ();
			selection_changed(get_selected_row ());
		}

		public signal void selection_changed (Gtk.ListBoxRow ? selected_row);
	}
}
